
gem 'bootstrap-sass', '~> 2.3.1.0'
gem 'haml'
gem 'simple_form'
gem 'bourbon'
gem 'bcrypt-ruby', '~> 3.0.0'

gem "rspec-rails", group: [:test, :development]
gem_group :test do
  gem "factory_girl_rails"
  gem "capybara"
  gem "guard-rspec"
  gem "faker"
  gem "poltergeist"
end

gem_group :development do
  gem "better_errors"
  gem "binding_of_caller"
end

gem_group :production do
  gem "pg"
end

run "bundle install"
generate "rspec:install"
generate "simple_form:install --bootstrap"

run "guard init rspec"

if yes? "Do you want to generate a root controller?"
  name = ask("What should it be called?").underscore
  generate :controller, "#{name} index"
  route "root to: '#{name}\#index'"
  remove_file "public/index.html"
end

application do
  %Q{
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
  }
end

append_to_file 'config/application.rb' do
  %Q{
  CONFIG = YAML.load(File.read(File.expand_path('../application.yml', __FILE__)))
  CONFIG.merge! CONFIG.fetch(Rails.env, {})
  CONFIG.symbolize_keys!
  }
end


git :init
append_file ".gitignore", "config/database.yml"
append_file ".gitignore", "config/application.yml"
run "cp config/database.yml config/example_database.yml"
create_file "config/application.yml"
git add: ".", commit: "-m 'initial commit'"