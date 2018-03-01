require "rails_helper"

RSpec.describe Settings::RegistriesController, type: :controller do
  before do
    create(:registry)
  end

  describe "GET #index" do
    it "populates an array of registries" do
      get :index
      expect(assigns(:registries)).not_to be_empty
    end
  end

  describe "GET #new" do
    before do
      get :new
    end

    it "assigns a new Registry to @registry" do
      expect(assigns(:registry)).to be_a_new(Registry)
    end

    it "assigns a new Certificate to @cert" do
      expect(assigns(:cert)).to be_a_new(Certificate)
    end
  end

  describe "GET #edit" do
    let!(:certificate) { create(:certificate, certificate: "Cert") }
    let!(:registry) { create(:registry) }
    let!(:registry_with_cert) { create(:registry) }

    context "without certificate" do
      before do
        get :edit, id: registry.id
      end

      it "assigns registry to @registry" do
        expect(assigns(:registry)).not_to be_a_new(Registry)
      end

      it "assigns a new Certificate to @cert" do
        expect(assigns(:cert)).to be_a_new(Certificate)
      end
    end

    context "with certificate" do
      before do
        CertificateService.create!(service: registry_with_cert, certificate: certificate)
        get :edit, id: registry_with_cert.id
      end

      it "assigns registry to @registry" do
        expect(assigns(:registry)).not_to be_a_new(Registry)
      end

      it "assigns registry's certificate to @cert" do
        expect(assigns(:cert)).not_to be_a_new(Certificate)
      end
    end

    it "return 404 if registry does not exist" do
      expect do
        get :edit, id: Registry.last.id + 1
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST #create" do
    context "without certificate" do
      it "saves the new registry in the database" do
        post :create, registry: { name: "r1", url: "http://local.lan" }
        registry = Registry.find_by(name: "r1")
        expect(registry.name).to eq("r1")
        expect(registry.url).to eq("http://local.lan")
      end

      it "does not save in db and return unprocessable entity status when invalid" do
        expect do
          post :create, registry: { url: "invalid" }
        end.not_to change(Registry, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with certificate" do
      it "saves the new registry in the database" do
        post :create, registry: { name: "r1", url: "http://local.lan", certificate: "cert" }
        registry = Registry.find_by(name: "r1")
        expect(registry.name).to eq("r1")
        expect(registry.certificate.certificate).to eq("cert")
      end

      it "does not save in db and return unprocessable entity status when invalid" do
        expect do
          post :create, registry: { name: "", url: "invalid", certificate: "cert" }
        end.not_to change(Registry, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH #update" do
    let!(:certificate) { create(:certificate, certificate: "C1") }
    let!(:registry) { create(:registry) }
    let!(:registry_with_cert) { create(:registry) }

    before do
      CertificateService.create!(service: registry_with_cert, certificate: certificate)
    end

    it "updates a registry" do
      registry_params = { name: "updated name", url: registry.url }
      put :update, id: registry.id, registry: registry_params
      expect(Registry.find(registry.id).name).to eq("updated name")
    end

    it "creates a new certificate" do
      registry_params = { name: registry.name, url: registry.url, certificate: "cert" }
      put :update, id: registry.id, registry: registry_params
      expect(registry.certificate.certificate).to eq("cert")
    end

    # rubocop:disable RSpec/ExampleLength
    it "updates a certificate" do
      registry_params = {
        name:        registry_with_cert.name,
        url:         registry_with_cert.url,
        certificate: "cert"
      }

      put :update, id: registry_with_cert.id, registry: registry_params
      expect(registry_with_cert.reload.certificate.certificate).to eq("cert")
    end
    # rubocop:enable RSpec/ExampleLength

    it "drops a certificate" do
      registry_params = { name: registry_with_cert.name, url: registry_with_cert.url }
      expect do
        put :update, id: registry_with_cert.id, registry: registry_params
      end.to change(Certificate, :count).by(-1)
    end

    it "return unprocessable entity status when invalid" do
      registry_params = { name: registry.name, url: "invalid" }
      put :update, id: registry.id, registry: registry_params
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE #destroy" do
    it "deletes a Registry" do
      expect do
        delete :destroy, id: Registry.first
      end.to(change { Registry.count })
    end
  end
end
