module SettingsHelper
  def settings_path?
    request.fullpath.starts_with?(settings_path)
  end

  def settings_registries_path?
    request.fullpath.starts_with?(settings_registries_path)
  end

  def settings_mirrors_path?
    request.fullpath.starts_with?(settings_mirrors_path)
  end
end