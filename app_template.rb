
gem 'bootstrap-sass', '~> 2.2.2.0'
gem 'haml'
gem 'simple_form'
gem 'bourbon'

gem "rspec-rails", group: [:test, :development]

gem "factory_girl_rails", group: [:test]
gem "capybara", group: [:test]
gem "guard-rspec", group: [:test]

gem "better_errors", group: [:development]
gem "binding_of_caller", group: [:development]

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

run "cp https://raw.github.com/andreaseriksson/apptemplate/master/_form.html.erb lib/templates/erb/scaffold/_form.html.erb"

git :init
append_file ".gitignore", "config/database.yml"
run "cp config/database.yml config/example_database.yml"
git add: ".", commit: "-m 'initial commit'"