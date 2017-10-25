# ApplicationHelper contains all the view helpers.
module ApplicationHelper
  # Render the user profile picture depending on the gravatar configuration.
  def user_image_tag(owner)
    email = owner.nil? ? nil : owner.email
    gravatar_image_tag(email)
  end

  def any_minion?
    Minion.any?
  end

  # setup means the setup phase was completed
  def setup_done?
    Pillar.exists? pillar: Pillar.all_pillars[:apiserver]
  end

  def active_class?(path_or_bool)
    case path_or_bool
    when String
      "active" if current_page?(path_or_bool)
    when TrueClass
      "active"
    end
  end
end
