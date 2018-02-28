require "rails_helper"

RSpec.describe Settings::RegistryMirrorsController, type: :controller do
  before do
    create(:registry)
    create(:registry_mirror)
  end

  describe "GET #index" do
    it "populates an array of registry mirrors" do
      get :index
      expect(assigns(:grouped_mirrors)).to be_present
    end
  end

  describe "GET #new" do
    it "assigns a new RegistryMirror to @registry_mirror" do
      get :new
      expect(assigns(:registry_mirror)).to be_a(RegistryMirror)
      expect(assigns(:cert)).to be_a(Certificate)
    end

    it "assigns a new Certificate to @cert" do
      get :new
      expect(assigns(:cert)).to be_a(Certificate)
    end
  end

  describe "POST #create" do
    let(:registry) { create(:registry) }
    let(:valid_registry_mirror_params) do
      {
        registry_mirror: {
          name:        "reggy_mirror",
          url:         "https://testing.reg.mirror.local",
          certificate: nil,
          registry_id: registry.id
        }
      }
    end

    context "with valid attributes" do
      it "saves the new registry in the database" do
        post :create, valid_registry_mirror_params
        expect(RegistryMirror.find_by(name: "reggy_mirror")).to be_a(RegistryMirror)
      end
    end

    context "with invalid attributes" do
      it "does not save the new registry in the database" do
        expect do
          post(:create,
               valid_registry_mirror_params.tap { |p| p[:registry_mirror][:url] = "invalid" })
        end.not_to(change { RegistryMirror.count })
      end
    end
  end

  describe "PATCH #update" do
    let(:registry) { Registry.first }
    let(:update_registry_mirror_params) do
      {
        name:        "updated_reggy_mirror",
        url:         "https://testing.reg.mirror.local",
        certificate: nil
      }
    end

    it "updates a registry mirror" do
      mirror = RegistryMirror.create(name: "reggy_mirror", url: "http://some.url",
                                     registry_id: registry.id)
      put :update, id: mirror.id, registry_mirror: update_registry_mirror_params
      expect(RegistryMirror.find(mirror.id).name).to eq("updated_reggy_mirror")
    end

    it "creates a new certificate" do
      mirror = RegistryMirror.create(name: "reggy_mirror2",
                                     url: "http://some2.other.url", registry_id: registry.id)
      put :update, id:              mirror.id,
                   registry_mirror: update_registry_mirror_params.tap { |p| p[:certificate] = "C2" }
      expect(mirror.certificate.certificate).to eq("C2")
    end

    it "updates a certificate" do
      mirror = RegistryMirror.create(
                 update_registry_mirror_params.merge(
                   registry_id: registry.id,
                   certificate: Certificate.new(certificate: "C3")
                 )
               )
      put :update, id:              mirror.id,
                   registry_mirror: update_registry_mirror_params.tap { |p| p[:certificate] = "C4" }
      expect(mirror.reload.certificate.certificate).to eq("C4")
    end

    # rubocop:disable RSpec/ExampleLength
    it "drops a certificate" do
      mirror = RegistryMirror.create(
                 name: "reggy_mirror4",
                 url: "http://some4.url",
                 registry_id: registry.id,
                 certificate: Certificate.new(certificate: "C4")
               )
      expect do
        put :update, id:              mirror.id,
                     registry_mirror: update_registry_mirror_params.except(:certificate)
      end.to(change { Certificate.count })
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe "DELETE #destroy" do
    it "deletes a RegistryMirror" do
      expect do
        delete :destroy, id: RegistryMirror.first
      end.to(change { RegistryMirror.count })
    end
  end
end
