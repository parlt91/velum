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
    it "assigns a new Registry to @registry" do
      get :new
      expect(assigns(:registry)).to be_a(Registry)
      expect(assigns(:cert)).to be_a(Certificate)
    end

    it "assigns a new Certificate to @cert" do
      get :new
      expect(assigns(:cert)).to be_a(Certificate)
    end
  end

  describe "POST #create" do
    let(:valid_registry_params) do
      {
        registry: {
          name:        "reggy",
          url:         "https://testing.reg.url",
          certificate: nil
        }
      }
    end

    context "with valid attributes" do
      it "saves the new registry in the database" do
        post :create, valid_registry_params
        expect(Registry.find_by(name: "reggy")).to be_a(Registry)
      end
    end

    context "with invalid attributes" do
      it "does not save the new registry in the database" do
        expect do
          post(:create, valid_registry_params.tap { |p| p[:registry][:url] = "invalid" })
        end.not_to(change { Registry.count })
      end
    end
  end

  describe "PATCH #update" do
    let(:update_registry_params) do
      {
        name:        "updated_reggy",
        url:         "https://testing.reg.url",
        certificate: nil
      }
    end

    it "updates a registry" do
      reg = Registry.create(name: "reggy", url: "http://some.url")
      put :update, id: reg.id, registry: update_registry_params
      expect(Registry.find(reg.id).name).to eq("updated_reggy")
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
