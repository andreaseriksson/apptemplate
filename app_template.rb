
gem 'bootstrap-sass', '~> 2.2.2.0'
gem 'haml'
gem 'simple_form'
gem 'bourbon'

gem "rspec-rails", group: [:test, :development]

group :test do
  gem "factory_girl_rails"
  gem "capybara"
  gem "guard-rspec"
end

group :development do
  gem "better_errors"
  gem "binding_of_caller"
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

git :init
append_file ".gitignore", "config/database.yml"
run "cp config/database.yml config/example_database.yml"
git add: ".", commit: "-m 'initial commit'"