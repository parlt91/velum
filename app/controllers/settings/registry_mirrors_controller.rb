class Settings::RegistryMirrorsController < SettingsController
  def index
    @grouped_mirrors = Registry.grouped_mirrors
  end

  def edit
    @registry_mirror = RegistryMirror.find(params[:id])
  end

  def new
    @registry_mirror = RegistryMirror.new
  end

  def create
    if registry_mirror_params[:certificate].present?
      Certificate.where(certificate: registry_mirror_params[:certificate]).first_or_create
    end
    RegistryMirror.create(registry_mirror_params.except(:certificate))

    respond_to do |format|
      format.html { redirect_to settings_path }
    end
  ensure
    mirror = RegistryMirror.find_by(name: registry_mirror_params[:name])
    cert = Certificate.find_by(certificate: registry_mirror_params[:certificate])
    CertificateService.where(service_id: mirror.id).first_or_initialize.tap do |s|
      s.certificate_id = cert.id
      s.service_type = mirror.class.name
      s.save
    end
  end

  def show
    @registry_mirror = RegistryMirror.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def update
    @registry_mirror = RegistryMirror.find(params[:id])
    errors = []

    if registry_mirror_params[:certificate].present?
      cert = Certificate.where(certificate: registry_mirror_params[:certificate]).first_or_create
      # it could be that a certificate is not yet created, so we need to create the service
      CertificateService.where(certificate_id: cert.id).first_or_initialize.tap do |s|
        s.service_id = @registry_mirror.id
        s.service_type = @registry_mirror.class.name
        s.save
      end
      unless cert.update_attributes(registry_mirror_params.except(:url, :name, :registry_id))
        errors << "Failed to update certificate"
      end
    end

    unless @registry.update_attributes(registry_mirror_params.except(:certificate))
      errors << "Failed to update registry mirror"
    end

    msg = if errors.present?
      errors.join(", ")
    else
      "Registry Mirror was successfully updated"
    end

    respond_to do |format|
      format.html { redirect_to settings_path, notice: msg }
    end
  end

  def destroy
    RegistryMirror.destroy(params[:id])

    respond_to do |format|
      format.html { redirect_to settings_path, notice: 'Mirror was successfully removed.' }
    end
  end

  private

  def registry_mirror_params
    params.require(:registry_mirror).permit(:name, :url, :certificate, :registry_id)
  end
end
