require 'digest/md5'

desc "Create mysqldump password file in server"
namespace :mysql do
  task :prepare, :roles => [:db] do
    
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      mysqlpassfile_content = ""

      servers.each do |server|
        puts "Preparando para criar o arquivo de senhas do mysql no host #{server.connection.host.yellow}..."
        db_name = server.database.database_name
        puts "Informações do database #{db_name.yellow}"
        db_user = Capistrano::CLI.ui.ask("Usuário do mysql: ")
        db_password = Capistrano::CLI.password_prompt("Senha do mysql: ")
        code = Digest::MD5.hexdigest db_name
        mysqlpassfile_content << "[mysqldump#{code}]\\nuser=#{db_user}\\npassword=#{db_password}\\n\\n[client#{code}]\\nuser=#{db_user}\\npassword=#{db_password}\\n\\n"
      end
      
      print "Salvando arquivo de configuração no server: "
      start_spinner
      run("cd ~/ && echo -e \"#{mysqlpassfile_content}\" > .my.cnf && chmod 600 .my.cnf", :hosts => s)
      stop_spinner
      puts "OK".green
    end  
  end
  
  task :check, :roles => [:db] do
    
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        db_name = server.database.database_name
        code = Digest::MD5.hexdigest db_name
        print "Testando comunicação com o banco #{db_name.yellow}: "
        start_spinner
        run("mysqlshow --defaults-group-suffix=\"#{code}\" #{db_name}", :hosts => s)
        stop_spinner
        puts "OK".green
      end
      
    end
  end
end


after "mysql:prepare", "mysql:check"