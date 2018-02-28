# Settings::RegistriesController is responsibe to manage all the requests
# related to the registries feature
class Settings::RegistriesController < SettingsController
  before_action :set_registry, only: [:show, :edit, :update, :destroy]

  def index
    @registries = Registry.all

    respond_to do |format|
      format.html
      format.json { render json: JSON.pretty_generate(Registry.expand_all) }
    end
  end

  def new
    @registry = Registry.new
    @cert = Certificate.new
  end

  def create
    @registry = Registry.new(registry_params.except(:certificate))
    @cert = Certificate.find_or_initialize_by(certificate: certificate_param)

    ActiveRecord::Base.transaction do
      begin
        @registry.save!
        create_or_update_certificate! if certificate_param.present?
        @created = true
      rescue StandardError
        raise ActiveRecord::Rollback
      end
    end

    if @created
      redirect_to [:settings, @registry], notice: "Registry was successfully created."
    else
      render action: :new
    end
  end

  def edit
    @cert = @registry.certificate || Certificate.new
  end

  # rubocop:disable Metrics/PerceivedComplexity
  def update
    @cert = @registry.certificate || Certificate.new(certificate: certificate_param)

    ActiveRecord::Base.transaction do
      begin
        @registry.update_attributes!(registry_params.except(:certificate))

        if certificate_param.present?
          create_or_update_certificate!
        elsif @registry.certificate.present?
          @registry.certificate.destroy!
        end

        @updated = true
      rescue StandardError
        raise ActiveRecord::Rollback
      end
    end

    if @updated
      redirect_to [:settings, @registry], notice: "Registry was successfully updated."
    else
      render action: :edit
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity

  def destroy
    @registry.destroy
    redirect_to settings_registries_path, notice: "Registry was successfully removed."
  end

  private

  def set_registry
    @registry = Registry.find(params[:id])
  end

  def certificate_param
    registry_params[:certificate].strip if registry_params[:certificate].present?
  end

  def registry_params
    params.require(:registry).permit(:name, :url, :certificate)
  end

  def create_or_update_certificate!
    if @cert.new_record?
      @cert.save!
      CertificateService.create!(service: @registry, certificate: @cert)
    else
      @cert.update_attributes!(certificate: certificate_param)
    end
  end
end
