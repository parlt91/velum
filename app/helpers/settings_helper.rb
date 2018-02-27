module SettingsHelper
  def settings_path?
    request.fullpath.starts_with?(settings_path)
  end

  def settings_registries_path?
    request.fullpath.starts_with?(settings_registries_path)
  end

  def settings_registry_mirrors_path?
    request.fullpath.starts_with?(settings_registry_mirrors_path)
  end

  def selectable_registries
    Registry.all.collect { |r| [r.name, r.id] }
  end

  def display_registry_url(url)
    if is_url_secure?(url)
      content_tag(:i, nil, class: "fa fa-lock") + " " + url
    else
      url
    end
  end

  def is_url_secure?(url)
    url.starts_with?("https://") unless url.nil?
  end
end