require "rails_helper"
require "securerandom"

RSpec.describe InternalApi::V1::PillarsController, type: :controller do
  include ApiHelper

  render_views

  let(:certificate) { create(:certificate) }
  let(:expected_flat_pillars_response) do
    {
      dashboard:  "dashboard.example.com",
      registries: [
        url:  Registry::SUSE_REGISTRY_URL,
        cert: nil
      ]
    }
  end

  before do
    http_login
    request.accept = "application/json"
  end

  describe "GET /pillar" do
    before do
      Pillar.create pillar: "dashboard", value: "dashboard.example.com"
      create(:registry, name: Registry::SUSE_REGISTRY_NAME, url: Registry::SUSE_REGISTRY_URL)
    end

    it "has the expected response status" do
      get :show
      expect(response.status).to eq 200
    end

    it "has the expected contents" do
      get :show
      expect(json).to match expected_flat_pillars_response
    end
  end

  context "when contains registries" do
    let(:expected_registries_response) do
      {
        registries: [
          {
            url:  Registry::SUSE_REGISTRY_URL,
            cert: nil
          },
          {
            url:  "https://example.com",
            cert: nil
          },
          {
            url:     "https://remote.registry.com",
            cert:    nil,
            mirrors: [
              {
                url:  "https://mirror.local.lan",
                cert: certificate.certificate
              },
              {
                url:  "http://mirror2.local.lan",
                cert: nil
              }
            ]
          }
        ]
      }
    end

    before do
      create(:registry, name: Registry::SUSE_REGISTRY_NAME, url: Registry::SUSE_REGISTRY_URL)
      Registry.create(name: "example", url: "https://example.com")
      registry = Registry.create(name: "remote", url: "https://remote.registry.com")
      registry_mirror = RegistryMirror.create(url: "https://mirror.local.lan") do |m|
        m.name = "suse_testing_mirror"
        m.registry_id = registry.id
      end
      CertificateService.create(service: registry_mirror, certificate: certificate)
      RegistryMirror.create(url: "http://mirror2.local.lan") do |m|
        m.name = "suse_testing_mirror2"
        m.registry_id = registry.id
      end
    end

    it "has remote registries and respective mirrors" do
      get :show
      expect(json).to match expected_registries_response
    end
  end

  context "when in EC2 framework" do
    let(:custom_instance_type) { "custom-instance-type" }
    let(:subnet_id) { "subnet-9d4a7b6c" }
    let(:security_group_id) { "sg-903004f8" }

    let(:expected_response) do
      {
        registries: [],
        cloud:      {
          framework: "ec2",
          profiles:  {
            cluster_node: {
              size:               custom_instance_type,
              network_interfaces: [
                {
                  DeviceIndex:              0,
                  AssociatePublicIpAddress: false,
                  SubnetId:                 subnet_id,
                  SecurityGroupId:          security_group_id
                }
              ]
            }
          }
        }
      }
    end

    before do
      create(:ec2_pillar)
      create(
        :pillar,
        pillar: "cloud:profiles:cluster_node:size",
        value:  custom_instance_type
      )
      create(
        :pillar,
        pillar: "cloud:profiles:cluster_node:network_interfaces:SubnetId",
        value:  subnet_id
      )
      create(
        :pillar,
        pillar: "cloud:profiles:cluster_node:network_interfaces:SecurityGroupId",
        value:  security_group_id
      )
    end

    it "has cloud configuration" do
      get :show
      expect(json).to eq(expected_response)
    end
  end

  context "when in Azure framework" do
    # provider pillars
    let(:subscription_id) { SecureRandom.uuid }
    let(:tenant_id) { SecureRandom.uuid }
    let(:client_id) { SecureRandom.uuid }
    let(:secret) { SecureRandom.hex(16) }
    # profile pillars
    let(:custom_instance_type) { "CustomInstanceSize_v2" }
    let(:resource_group) { "azureresourcegroup" }
    let(:subnet_id) { "azuresubnetname" }
    let(:network_id) { "azurenetworkname" }

    let(:expected_response) do
      {
        registries: [],
        cloud:      {
          framework: "azure",
          providers: {
            azure: {
              subscription_id: subscription_id,
              tenant:          tenant_id,
              client_id:       client_id,
              secret:          secret
            }
          },
          profiles:  {
            cluster_node: {
              size:                   custom_instance_type,
              resource_group:         resource_group,
              network_resource_group: resource_group,
              network:                network_id,
              subnet:                 subnet_id
            }
          }
        }
      }
    end

    before do
      create(:azure_pillar)
      # provider pillars
      create(
        :pillar,
        pillar: "cloud:providers:azure:subscription_id",
        value:  subscription_id
      )
      create(
        :pillar,
        pillar: "cloud:providers:azure:tenant",
        value:  tenant_id
      )
      create(
        :pillar,
        pillar: "cloud:providers:azure:client_id",
        value:  client_id
      )
      create(
        :pillar,
        pillar: "cloud:providers:azure:secret",
        value:  secret
      )
      # profile pillars
      create(
        :pillar,
        pillar: "cloud:profiles:cluster_node:size",
        value:  custom_instance_type
      )
      create(
        :pillar,
        pillar: "cloud:profiles:cluster_node:network_interfaces:SubnetId",
        value:  subnet_id
      )
      create(
        :pillar,
        pillar: "cloud:profiles:cluster_node:network",
        value:  network_id
      )
      create(
        :pillar,
        pillar: "cloud:profiles:cluster_node:resourcegroup",
        value:  resource_group
      )
    end

    it "has cloud configuration" do
      get :show
      expect(json).to eq(expected_response)
    end
  end

  context "with Openstack provider" do
    let(:expected_response) do
      {
        registries: [],
        cloud:      {
          provider:  "openstack",
          openstack: {
            auth_url:       "http://keystone-test-host:5000/v3",
            username:       "testuser",
            password:       "pass",
            domain:         "test",
            project:        "prj",
            region:         "rspec",
            floating:       "9bc3e819-a6ca-648b-b5e3-c26c9e6c5e57",
            subnet:         "4b64b38d-0b38-40d0-a69f-ade7299ef4ab",
            bs_version:     "v2",
            lb_mon_retries: "3"
          }
        }
      }
    end

    before do
      create(:openstack_pillar)
      expected_response[:cloud][:openstack].each do |k, v|
        create(
          :pillar,
          pillar: "cloud:openstack:#{k}",
          value:  v
        )
      end
    end

    it "has cloud configuration" do
      get :show
      expect(json).to eq(expected_response)
    end
  end
end
