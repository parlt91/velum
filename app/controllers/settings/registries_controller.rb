class Settings::RegistriesController < SettingsController
  before_action :set_registry, only: %i[show edit update destroy]

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

        if registry_params[:certificate].present?
          @cert.save!
          CertificateService.create!(service: @registry, certificate: @cert)
        end

        @created = true
      rescue
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

  def update
    @cert = Certificate.find_or_initialize_by(certificate: certificate_param)

    ActiveRecord::Base.transaction do
      begin
        @registry.update_attributes!(registry_params.except(:certificate))

        # TODO try to simplify this
        if certificate_param.present?
          if @cert.new_record?
            @cert.save!
            CertificateService.create!(service: @registry, certificate: @cert)
          else
            @cert.update_attributes!(certificate: registry_params[:certificate])
          end
        elsif @registry.certificate.present?
          @registry.certificate.destroy!
        end

        @updated = true
      rescue
        raise ActiveRecord::Rollback
      end
    end

    if @updated
      redirect_to [:settings, @registry], notice: "Registry was successfully updated."
    else
      render action: :edit
    end
  end

  def destroy
    @registry.destroy
    redirect_to settings_registries_path, notice: 'Registry was successfully removed.'
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
end
