load "config/initializer"

set :user, Config.website.first.connection.ssh_user
ssh_password = Config.website.first.connection.ssh_password
set :password, ssh_password unless ssh_password.nil?
set :use_sudo, false
ssh_options[:port] = Config.website.first.connection.ssh_port

default_run_options[:pty] = true

role :app, Config.website.first.connection.host