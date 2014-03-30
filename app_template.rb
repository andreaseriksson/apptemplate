
gem 'bootstrap-sass', '~> 3.1.1'
gem 'font-awesome-rails'
gem 'simple_form'
gem 'bourbon'
gem 'bcrypt-ruby', '~> 3.1.2'
#gem 'ancestry'
#gem 'acts_as_list'

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
append_file ".gitignore", "public/assets/*"
append_file ".gitignore", "public/uploads/*"

run "cp config/database.yml config/database.example.yml"
create_file "config/application.yml"
append_to_file 'config/application.yml' do
%Q{
application_name: ''
seed_user_name: ''
seed_user_email: ''
seed_user_password: ''
application_creator: ''
gmail_email: ''
gmail_pass: ''
host: ''
}
end
run "cp config/application.yml config/application.example.yml"


if yes? "Do you want to generate a root controller?[yes/no]"
  name = ask("What should it be called?").underscore
  generate :controller, "#{name} index"
  route "root to: '#{name}\#index'"
end


if yes? "Do you want to generate a admin area?[yes/no]"
  generate :resource, "user email:string:index password_digest"
  run "rake db:migrate && rake db:test:prepare"
  generate :controller, "sessions index"

  inject_into_class "app/models/user.rb", User do
    "  hvalidates_uniqueness_of :email\n"
    "  attr_accessible :email, :password, :password_confirmation\n"
    "  has_secure_password\n"
  end
  
end


# Main view
remove_file "app/view/application.html.erb"
create_file "app/view/application.html.erb"
append_to_file "app/view/application.html.erb" do
%Q{
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="">
    <meta name="author" content="">

    <title></title>
    <%= stylesheet_link_tag "application", media: "all" %>
    <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
      <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
  </head>
  <body>
    <div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="#">Project name</a>
        </div>
        <div class="collapse navbar-collapse">
          <ul class="nav navbar-nav">
            <li class="active"><a href="#">Home</a></li>
            <li><a href="#about">About</a></li>
            <li><a href="#contact">Contact</a></li>
          </ul>
        </div><!--/.nav-collapse -->
      </div>
    </div>

    <div class="container">
      <%= yield %>
    </div><!-- /.container -->

    <%= javascript_include_tag "application" %>
    <%= csrf_meta_tags %>
  </body>
</html>
}


git add: ".", commit: "-m 'initial commit'"
