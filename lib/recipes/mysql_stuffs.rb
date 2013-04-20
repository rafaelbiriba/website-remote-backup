require 'digest/md5'
require 'fileutils'

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
  
  task :dump, :roles => [:db] do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        db_name = server.database.database_name
        code = Digest::MD5.hexdigest db_name
        print "Gerando backup do banco #{db_name.yellow}: "
        start_spinner
        run("cd ~/ && mysqldump --defaults-group-suffix=\"#{code}\" #{db_name} | gzip -v > mysql-dump-#{db_name}-#{get_backup_date}.gz", :hosts => s)
        stop_spinner
        puts "OK".green
      end
    end
  end
  
  task :prepare_to_backup, :roles => [:db] do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        db_name = server.database.database_name
        print "Preparando para fazer o download do backup do banco #{db_name.yellow}: "
        start_spinner
        db_path = local_backup_path(server, db_name)
        FileUtils.mkdir_p(db_path)
        `cd #{db_path} && if ! [ -d .git ]; then git init; fi;`
        stop_spinner
        puts "OK".green
      end
    end
  end
  
  task :backup, :roles => [:db] do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        db_name = server.database.database_name
        code = Digest::MD5.hexdigest db_name
        @bar = ProgressBar.new(db_name, 1)
        puts "Baixando backup do banco #{db_name.yellow}:"
        file = "mysql-dump-#{db_name}-#{get_backup_date}.gz"
        download("#{file}", "#{local_backup_path(server, db_name)}/#{file}", :via => :scp, :hosts => s)
      end
    end
  end
  
  task :finish_backup, :roles => [:db] do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        db_name = server.database.database_name
        db_path = local_backup_path(server, db_name)
        print "Finalizando o download do banco #{db_name.yellow}: "
        start_spinner
        `cd #{db_path} && gzip -df "mysql-dump-#{db_name}-#{get_backup_date}.gz"`
        `cd #{db_path} && git add . && git commit -am 'Backup de banco - Data: #{get_backup_date}'`
        stop_spinner
        puts "OK".green
      end
    end
  end
  
  task :remote_cleanup, :roles => [:db] do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        db_name = server.database.database_name
        code = Digest::MD5.hexdigest db_name
        print "Limpando o servidor #{server.connection.host.yellow}: "
        start_spinner
        run("rm -f ~/mysql-dump-#{db_name}-#{get_backup_date}.gz", :hosts => s)
        stop_spinner
        puts "OK".green
      end
    end
  end
  
end

before "mysql:backup", "mysql:dump"
before "mysql:dump", "mysql:check"
before "mysql:backup", "mysql:prepare_to_backup"

after "mysql:backup", "mysql:finish_backup"
after "mysql:backup", "mysql:remote_cleanup"
after "mysql:prepare", "mysql:check"

def local_backup_path(server, db_name)
  "#{server.configuration.local_backup_folder}/#{server.connection.host}/databases/#{db_name}"
end

def get_backup_date
  @backup_date ||= Time.now.strftime("%d/%m/%Y-%H_%M")
end