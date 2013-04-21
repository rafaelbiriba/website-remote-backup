namespace :website do
  task :create_backup_file, :roles => [:app] do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        print "Gerando arquivo de backup do servidor #{server.connection.host.yellow}: "
        start_spinner
        exclude = ""
        server.website.ignore.each do |ignore|
          exclude << " --exclude=\"#{ignore}\""
        end  
        tar_cmd = "cd #{server.website.site_path} && tar cvpzf #{backup_file(server)}#{exclude} ."
        run(tar_cmd, :hosts => s)
        stop_spinner
        puts "OK".green
      end
    end
  end
  
  # task :prepare_to_backup, :roles => [:db] do
  #   find_servers_for_task(current_task).each do |s|
  #     servers = Server.select{ |server| server.connection.host == s.host.to_s }
  #     servers.each do |server|
  #       db_name = server.database.database_name
  #       print "Preparando para fazer o download do backup do banco #{db_name.yellow}: "
  #       start_spinner
  #       db_path = local_backup_path(server, db_name)
  #       FileUtils.mkdir_p(db_path)
  #       `cd #{db_path} && if ! [ -d .git ]; then git init; fi;`
  #       stop_spinner
  #       puts "OK".green
  #     end
  #   end
  # end
  # 
  # task :backup, :roles => [:db] do
  #   find_servers_for_task(current_task).each do |s|
  #     servers = Server.select{ |server| server.connection.host == s.host.to_s }
  #     servers.each do |server|
  #       db_name = server.database.database_name
  #       code = Digest::MD5.hexdigest db_name
  #       @bar = ProgressBar.new(db_name, 1)
  #       puts "Baixando backup do banco #{db_name.yellow}:"
  #       file = "mysql-dump-#{db_name}-#{get_backup_date}.gz"
  #       download("#{file}", "#{local_backup_path(server, db_name)}/#{file}", :via => :scp, :hosts => s)
  #     end
  #   end
  # end
  # 
  # task :finish_backup, :roles => [:db] do
  #   find_servers_for_task(current_task).each do |s|
  #     servers = Server.select{ |server| server.connection.host == s.host.to_s }
  #     servers.each do |server|
  #       db_name = server.database.database_name
  #       db_path = local_backup_path(server, db_name)
  #       print "Finalizando o download do banco #{db_name.yellow}: "
  #       start_spinner
  #       `cd #{db_path} && gzip -df "mysql-dump-#{db_name}-#{get_backup_date}.gz"`
  #       `cd #{db_path} && mv "mysql-dump-#{db_name}-#{get_backup_date}" "mysql-dump-#{db_name}"`
  #       `cd #{db_path} && git add . && git commit -am 'Backup de banco - Data: #{get_backup_date}'`
  #       stop_spinner
  #       puts "OK".green
  #     end
  #   end
  # end
  # 
  task :remote_cleanup, :roles => [:app] do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        print "Limpando o servidor #{server.connection.host.yellow}: "
        start_spinner
        run("cd #{server.website.site_path} && rm #{backup_file(server)}", :hosts => s)
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


def local_backup_path(server)
  "#{server.configuration.local_backup_folder}/#{server.connection.host}/website"
end

def backup_file(server)
  "website-#{server.connection.host}-#{get_backup_date}.tar.gz"
end