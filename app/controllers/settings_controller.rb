class SettingsController < ApplicationController
  layout "settings"

  def index
    redirect_to settings_registries_path
  end
end
