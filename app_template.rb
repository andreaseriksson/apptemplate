
gem 'bootstrap-sass', '~> 3.1.1'
gem 'bootflat-rails'
gem 'font-awesome-rails'
gem 'simple_form'
gem 'bourbon'
gem 'bcrypt-ruby', '~> 3.1.2'
gem 'will_paginate-bootstrap'

gsub_file 'Gemfile', "gem 'turbolinks'", "# gem 'turbolinks'"
gsub_file 'Gemfile', "gem 'sass-rails'", "# gem 'sass-rails'"

gem 'sass-rails', git: 'https://github.com/zakelfassi/sass-rails'

#gem 'ancestry'
#gem 'acts_as_list'

gem "rspec-rails", group: [:test, :development]
gem_group :test do
  gem "factory_girl_rails"
  gem "capybara"
  gem "guard-rspec"
  #gem "faker"
  #gem "poltergeist"
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

inject_into_file "config/environments/development.rb", after: "config.assets.debug = true\n" do
%Q{
  
  config.action_mailer.default_url_options = { :host => "localhost:3000" }
  
}
end

remove_dir 'test'

git :init
append_file ".gitignore", "config/database.yml"
append_file ".gitignore", "config/application.yml"
append_file ".gitignore", "public/assets/*"
append_file ".gitignore", "public/uploads/*"

run "cp config/database.yml config/database.example.yml"
create_file "config/application.yml"
append_to_file 'config/application.yml' do
%Q{application_name: ''
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

generate :controller, "home index"
route "root to: 'home\#index'"

run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.css.scss"
prepend_to_file 'app/assets/stylesheets/application.css.scss' do
%Q{@import "bootstrap";
@import "font-awesome";
@import "bootflat";

}
end
append_to_file 'app/assets/stylesheets/application.css.scss', 'body{ padding-top: 50px; }'

gsub_file 'app/assets/javascripts/application.js', '//= require turbolinks', '//= require bootstrap'
inject_into_file "app/assets/javascripts/application.js", "//= require icheck.min\n", after: "//= require bootstrap\n"
append_to_file 'app/assets/javascripts/application.js' do
%Q{
  $('.checkbox input').iCheck({
    checkboxClass: 'icheckbox_flat',
    increaseArea: '20%'
  \});

  $('.radio input').iCheck({
    radioClass: 'iradio_flat',
    increaseArea: '20%'
  \});
}
end
# Main view
remove_file "app/views/layouts/application.html.erb"
create_file "app/views/layouts/application.html.erb"
append_to_file "app/views/layouts/application.html.erb" do
%Q{<!DOCTYPE html>
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
            <li class="active"><%= link_to 'Home', root_path %></li>
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
end

if yes? "Do you want to generate a admin area?[yes/no]"
  generate :model, "user email:string:index password_digest auth_token:string:index password_reset_token password_reset_sent_at:datetime"
  run "rake db:migrate && rake db:test:prepare"
  generate :mailer, "user_mailer password_reset"
  
  route "get 'login', to: 'sessions#new', as: 'login'"
  route "get 'logout', to: 'sessions#destroy', as: 'logout'"
  route "resources :sessions, only: [:new, :create, :destroy]"
  route "resources :password_resets, only: [:new, :create, :edit, :update]"
  

  inject_into_file "app/models/user.rb", after: "class User < ActiveRecord::Base\n" do
%Q{
  has_secure_password
  validates :email, :presence => true, :uniqueness => true  
  validates :password, presence: true, length: { in: 6..20 }, on: :create
  validates_confirmation_of :password
  
  before_create { generate_token(:auth_token) }
  
  def send_password_reset
	  generate_token(:password_reset_token)
	  self.password_reset_sent_at = Time.zone.now
	  save!
	  UserMailer.password_reset(self).deliver
	end

	def generate_token(column)
	  begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
	end

}
  end
  
  inject_into_file "app/controllers/application_controller.rb", after: "protect_from_forgery with: :exception\n" do
%Q{
  private
  
  def current_user
    @current_user ||= User.find_by_auth_token( cookies[:auth_token]) if cookies[:auth_token]
  end
  helper_method :current_user
  
  def authorize
    redirect_to login_url, alert: "Not authorized" if current_user.nil?
  end

}  
  end
  
  inject_into_file "app/views/layouts/application.html.erb", after: '<div class="container">\n' do
%Q{
  Smurf
}  
  end
    
  inject_into_file "app/views/layouts/application.html.erb", after: '</ul>\n' do
%Q{
          <p class="navbar-text navbar-right">
            <% if current_user %>
              Signed in as <%= current_user.email %> <%= link_to "Log Out", logout_path %>
            <% else %>
              <%= link_to "Sign In", login_path %>
            <% end %>
          </p>
}  
  end
  
  create_file "app/controllers/sessions_controller.rb"
  append_to_file "app/controllers/sessions_controller.rb" do
%Q{class SessionsController < ApplicationController
   
  def new
  end
  
  def create
    user = User.find_by_email(params[:email])
    
    if user && user.authenticate(params[:password])
      
      if params[:remember_me]
        cookies.permanent[:auth_token] = user.auth_token
      else
        cookies[:auth_token] =  { value: user.auth_token, expires: 1.hour.from_now }  
      end
      redirect_to root_path, notice: "Logged in!"
    else
      flash.now.alert = "Invalid email or password"
      render "new"
    end
  end

  def destroy
    cookies.delete(:auth_token)
    current_user = nil
    redirect_to login_path, notice: "Logged out!"
  end
  
end
}    
  end
  
  create_file "app/controllers/password_resets_controller.rb"
  append_to_file "app/controllers/password_resets_controller.rb" do
%Q{class PasswordResetsController < ApplicationController
  
  def new
  end
  
  def create
    user = User.find_by_email(params[:email])
    user.send_password_reset if user
    redirect_to login_url, notice: "Email sent with password reset instructions."
  end
  
  def edit
    @user = User.find_by_password_reset_token!(params[:id])
  end
  
  def update
    @user = User.find_by_password_reset_token!(params[:id])
    if @user.password_reset_sent_at < 2.hours.ago
      redirect_to new_password_reset_path, alert: "Password reset has expired."
    elsif @user.update_attributes(params[:user])
      redirect_to login_url, notice: "Password has been reset."
    else
      render :edit
    end
  end

end
}    
  end
  
  create_file "app/views/sessions/new.html.erb"
  append_to_file "app/views/sessions/new.html.erb" do
%Q{
<h1>Log In</h1>

<%= form_tag sessions_path do %>
  <div class="field">
    <%= label_tag :email %><br />
    <%= text_field_tag :email, params[:email] %>
  </div>
  <div class="field">
    <%= label_tag :password %><br />
    <%= password_field_tag :password %>
  </div>
  <p><%= link_to "forgotten password?", new_password_reset_path %></p>
  <div class="field">
    <%= check_box_tag :remember_me, 1, params[:remember_me] %>
    <%= label_tag :remember_me %>
  </div>
  <div class="actions"><%= submit_tag "Log In" %></div>
<% end %>
} 
  end
  
  create_file "app/views/password_resets/new.html.erb"
  append_to_file "app/views/password_resets/new.html.erb" do
%Q{
<%= form_tag password_resets_path, :method => :post do %>
  <div class="field">
    <%= label_tag :email %>
    <%= text_field_tag :email, params[:email] %>
  </div>
  <div class="actions"><%= submit_tag "Reset Password" %></div>
<% end %>
} 
  end
  
  create_file "app/views/password_resets/edit.html.erb"
  append_to_file "app/views/password_resets/edit.html.erb" do
%Q{
<%= form_for @user, url: password_reset_path(params[:id]) do |f| %>
  <% if @user.errors.any? %>
    <div class="error_messages">
      <h2>Form is invalid</h2>
      <ul>
        <% for message in @user.errors.full_messages %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>
  <div class="field">
    <%= f.label :password %>
    <%= f.password_field :password %>
  </div>
  <div class="field">
    <%= f.label :password_confirmation %>
    <%= f.password_field :password_confirmation %>
  </div>
  <div class="actions"><%= f.submit "Update Password" %></div>
<% end %>
} 
  end
  
  remove_file "app/mailers/user_mailer.rb"
  create_file "app/mailers/user_mailer.rb"
  append_to_file "app/mailers/user_mailer.rb" do
%Q{class UserMailer < ActionMailer::Base
  
  default from: CONFIG[:gmail_email]

  def password_reset(user)
    @user = user
    mail :to => user.email, :subject => "Password Reset"
  end

end

}  
  end
  
  remove_file "app/views/user_mailer/password_reset.text.erb"
  create_file "app/views/user_mailer/password_reset.text.erb"
  append_to_file "app/views/user_mailer/password_reset.text.erb" do
%Q{
To reset your password, click the URL below.
<%= edit_password_reset_url(@user.password_reset_token) %>
If you did not request your password to be reset, just ignore this email and your password will continue to stay the same.
}  
  end
  
  email = ask("Choose your signin email:").downcase
  password = ask("Choose your signin password (min 6 chars):")
  gsub_file 'config/application.yml', "seed_user_email: ''", "seed_user_email: '#{email}'"
  gsub_file 'config/application.yml', "seed_user_password: ''", "seed_user_password: '#{password}'"
  append_to_file "db/seeds.rb", "User.create(email: CONFIG[:seed_user_email], password: CONFIG[:seed_user_password], password_confirmation: CONFIG[:seed_user_password])"
  run "rake db:seed"
end

git add: ".", commit: "-m 'initial commit'"
