class Settings::RegistriesController < SettingsController
  def index
    @registries = Registry.all

    respond_to do |format|
      format.html
      format.json { render json: JSON.pretty_generate(Registry.expand_all) }
    end
  end

  def edit
    @registry = Registry.find(params[:id])
  end

  def new
    @registry = Registry.new
  end

  def create
    if registry_params[:certificate].present?
      Certificate.where(certificate: registry_params[:certificate]).first_or_create
    end
    Registry.create(registry_params.except(:certificate))

    respond_to do |format|
      format.html { redirect_to settings_path }
    end
  end

  def show
    @registry = Registry.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def update
    @registry = Registry.find(params[:id])
    errors = []

    if registry_params[:certificate].present?
      cert = Certificate.where(certificate: registry_params[:certificate]).first_or_create
      # it could be that a certificate is not yet created, so we need to create the service
      CertificateService.where(certificate_id: cert.id).first_or_initialize.tap do |s|
        s.service_id = @registry.id
        s.service_type = @registry.class.name
        s.save
      end
      unless cert.update_attributes(registry_params.except(:url, :name))
        errors << "Failed to update certificate"
      end
    end

    unless @registry.update_attributes(registry_params.except(:certificate))
      errors << "Failed to update registry"
    end

    msg = if errors.present?
      errors.join(", ")
    else
      "Registry was successfully updated"
    end

    respond_to do |format|
      format.html { redirect_to settings_path, notice: msg }
    end
  end

  def destroy
    # do some update calls here
    Registry.destroy(params[:id])

    respond_to do |format|
      format.html { redirect_to settings_path, notice: 'Registry was successfully removed.' }
    end
  end

  private

  def registry_params
    params.require(:registry).permit(:name, :url, :certificate)
  end
end
