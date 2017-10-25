class Settings::MirrorsController < SettingsController
  before_action :set_mirror, only: [:show, :update]

  def index
  end

  def edit
  end

  def new
  end

  def show
  end

  # PATCH/PUT /
  def update
    # do some update calls here

    respond_to do |format|
      format.html { redirect_to settings_path, notice: 'Mirror was successfully updated.' }
    end
  end

  # DELETE /
  def destroy
    # do some update calls here

    respond_to do |format|
      format.html { redirect_to settings_path, notice: 'Mirror was successfully removed.' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_mirror
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def setting_params
      params.fetch(:mirror, {})
    end
end
