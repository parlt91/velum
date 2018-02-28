# Settings::RegistryMirrorsController is responsibe to manage all the requests
# related to the registry mirrors feature
class Settings::RegistryMirrorsController < SettingsController
  before_action :set_registry, only: [:show, :edit, :update, :destroy]

  def index
    @grouped_mirrors = Registry.grouped_mirrors
  end

  def new
    @registry_mirror = RegistryMirror.new
    @cert = Certificate.new
  end

  def create
    @registry = Registry.find(registry_mirror_params[:registry_id])
    registry_mirror_create_params = registry_mirror_params.except(:certificate, :registry_id)
    @registry_mirror = @registry.registry_mirrors.build(registry_mirror_create_params)
    @cert = Certificate.find_or_initialize_by(certificate: certificate_param)

    ActiveRecord::Base.transaction do
      begin
        @registry_mirror.save!

        create_or_update_certificate! if certificate_param.present?

        @created = true
      rescue StandardError
        raise ActiveRecord::Rollback
      end
    end

    if @created
      redirect_to [:settings, @registry_mirror], notice: "Mirror was successfully created."
    else
      render action: :new
    end
  end

  def edit
    @cert = @registry_mirror.certificate || Certificate.new
  end

  # rubocop:disable Metrics/PerceivedComplexity
  def update
    @cert = @registry_mirror.certificate || Certificate.new(certificate: certificate_param)

    ActiveRecord::Base.transaction do
      begin
        registry_mirror_update_params = registry_mirror_params.except(:certificate, :registry_id)
        @registry_mirror.update_attributes!(registry_mirror_update_params)

        if certificate_param.present?
          create_or_update_certificate!
        elsif @registry_mirror.certificate.present?
          @registry_mirror.certificate.destroy!
        end

        @updated = true
      rescue StandardError
        raise ActiveRecord::Rollback
      end
    end

    if @updated
      redirect_to [:settings, @registry_mirror], notice: "Mirror was successfully updated."
    else
      render action: :edit
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity

  def destroy
    @registry_mirror.destroy
    redirect_to settings_registry_mirrors_path, notice: "Mirror was successfully removed."
  end

  private

  def set_registry
    @registry_mirror = RegistryMirror.find(params[:id])
  end

  def certificate_param
    registry_mirror_params[:certificate].strip if registry_mirror_params[:certificate].present?
  end

  def registry_mirror_params
    params.require(:registry_mirror).permit(:name, :url, :certificate, :registry_id)
  end

  def create_or_update_certificate!
    if @cert.new_record?
      @cert.save!
      CertificateService.create!(service: @registry_mirror, certificate: @cert)
    else
      @cert.update_attributes!(certificate: certificate_param)
    end
  end
end
