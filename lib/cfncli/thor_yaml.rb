module ThorYamlLoader
  def options
    original_options = super
    config_file = original_options['config_file']
    return original_options unless File.exists?(config_file)
    defaults = ::YAML::load_file(config_file) || {}
    Thor::CoreExt::HashWithIndifferentAccess.new(defaults.merge(original_options))
  end
end