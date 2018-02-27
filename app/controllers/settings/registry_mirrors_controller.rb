class Settings::RegistryMirrorsController < SettingsController
  before_action :set_registry, only: %i[show edit update destroy]

  def index
    @grouped_mirrors = Registry.grouped_mirrors
  end

  def new
    @registry_mirror = RegistryMirror.new
  end

  def create
    @registry_mirror = RegistryMirror.new(registry_mirror_params.except(:certificate))

    if registry_mirror_params[:certificate].present?
      Certificate.where(certificate: registry_mirror_params[:certificate]).first_or_create
    end

    if @registry_mirror.save
      redirect_to [:settings, @registry_mirror], notice: "Mirror was successfully created."
    else
      render action: :new
    end
  ensure
    cert = Certificate.find_by(certificate: registry_mirror_params[:certificate])
    return unless cert
    CertificateService.where(service_id: @registry_mirror.id).first_or_initialize.tap do |s|
      s.certificate_id = cert.id
      s.service_type = @registry_mirror.class.name
      s.save
    end
  end

  def update
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

    unless @registry_mirror.update_attributes(registry_mirror_params.except(:certificate))
      errors << "Failed to update registry mirror"
    end

    msg = if errors.present?
      errors.join(", ")
    else
      "Mirror was successfully updated"
    end

    respond_to do |format|
      format.html { redirect_to @registry_mirror, notice: msg }
    end
  end

  def destroy
    @registry_mirror.destroy

    respond_to do |format|
      format.html { redirect_to settings_registry_mirrors_path, notice: 'Mirror was successfully removed.' }
    end
  end

  private

  def set_registry
    @registry_mirror = RegistryMirror.find(params[:id])
  end

  def registry_mirror_params
    params.require(:registry_mirror).permit(:name, :url, :certificate, :registry_id)
  end
end
