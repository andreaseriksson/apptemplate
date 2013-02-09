# ./config/application.rb
config.generators.stylesheets = false
config.generators.javascripts = false
config.generators.helper      = false


config.generators do |g|
  g.test_framework :rspec,
    :fixtures => true,
    :view_specs => false,
    :helper_specs => false,
    :routing_specs => false,
    :controller_specs => true,
    :request_specs => true
  g.fixture_replacement :factory_girl, :dir => "spec/factories"
end




CONFIG = YAML.load(File.read(File.expand_path('../application.yml', __FILE__)))
CONFIG.merge! CONFIG.fetch(Rails.env, {})
CONFIG.symbolize_keys!




lib > templates > erb > scaffold > _form.html.erb