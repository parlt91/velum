class Settings::RegistriesController < SettingsController
  before_action :set_registry, only: [:show, :update]

  def index
  end

  def edit
  end

  def new
  end

  def show
  end

  def update
    # do some update calls here

    respond_to do |format|
      format.html { redirect_to settings_path, notice: 'Registry was successfully updated.' }
    end
  end

  def destroy
    # do some update calls here

    respond_to do |format|
      format.html { redirect_to settings_path, notice: 'Registry was successfully removed.' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_registry
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def setting_params
      params.fetch(:registry, {})
    end
end
