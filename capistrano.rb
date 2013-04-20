load "config/initializer"
set :use_sudo, false
default_run_options[:pty] = true
default_run_options[:max_hosts] = 1

Server.each do |s|
  host = s.connection.host
  next unless find_servers.select{ |s| s.host == host }.empty?
  
  ssh_password = s.connection.ssh_password
  
  params = {
    user: s.connection.ssh_user,
    ssh_options: { port: s.connection.ssh_port }
  }
  
  params.merge!( password: ssh_password ) unless ssh_password.nil?
  
  server host, :db, params unless s.database.nil?
  server host, :app, params unless s.website.nil?
end