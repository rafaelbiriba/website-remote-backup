load "config/initializer"

set :user, Server.first.connection.ssh_user
ssh_password = Server.first.connection.ssh_password
set :password, ssh_password unless ssh_password.nil?
set :use_sudo, false
ssh_options[:port] = Server.first.connection.ssh_port

default_run_options[:pty] = true

role :app, Server.first.connection.host