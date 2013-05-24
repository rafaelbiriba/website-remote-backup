namespace :website do
  task :create_backup_file, :roles => [:app] do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        print "Gerando arquivo de backup do servidor #{server.connection.host.yellow}: "
        start_spinner
        exclude = ""
        unless server.website.ignore.nil?
          server.website.ignore.each do |ignore|
            exclude << " --exclude=\"#{ignore}\""
          end
        end
        run("mkdir -p #{remote_backup_path(server)}", :hosts => s)
        tar_cmd = "cd #{server.website.site_path} && tar cvpzf #{backup_file_path(server)}#{exclude} ."
        run(tar_cmd, :hosts => s)
        stop_spinner
        puts "OK".green
      end
    end
  end

  task :prepare_to_backup, :roles => [:app] do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        print "Preparando para fazer o backup dos arquivos do #{server.connection.host.yellow}: "
        start_spinner
        path = local_backup_path(server)
        FileUtils.mkdir_p(path)
        `cd #{path} && if ! [ -d .git ]; then git init; fi;`
        stop_spinner
        puts "OK".green
      end
    end
  end

  task :backup, :roles => [:app] do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        puts "Baixando backup do #{server.connection.host.yellow}:"
        download(backup_file_path(server), "#{local_backup_path(server)}/#{backup_file(server)}", :via => :scp, :hosts => s)
      end
    end
  end

  task :finish_backup, :roles => [:app] do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        path = local_backup_path(server)
        print "Finalizando o backup do #{server.connection.host.yellow}: "
        start_spinner
        `cd #{path} && tar -zxvf #{backup_file(server)} 2>&1`
        `cd #{path} && rm -rf #{backup_file(server)}`
        `cd #{path} && git add . && git commit -am 'Backup - Data: #{get_backup_date}'`
        stop_spinner
        puts "OK".green
      end
    end
  end

  task :local_cleanup, :roles => [:db] do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        path = local_backup_path(server)
        `cd #{path} && rm -f "website-#{server.connection.host}-*.gz"`
      end
    end
  end

  task :remote_cleanup, :roles => [:app] do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        print "Limpando o servidor #{server.connection.host.yellow}: "
        start_spinner
        run("rm -rf #{remote_backup_path(server)}", :hosts => s)
        stop_spinner
        puts "OK".green
      end
    end
  end

  task :create_or_update_backup_date do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        path = local_backup_path(server)
        `cd #{path} && echo "#{get_backup_date}" > backup.date`
      end
    end
  end

  task :check_for_last_backup_date do
    find_servers_for_task(current_task).each do |s|
      servers = Server.select{ |server| server.connection.host == s.host.to_s }
      servers.each do |server|
        path = local_backup_path(server)
        frequency = server.configuration.frequency
        date = File.read("#{path}/backup.date") if File.exists? "#{path}/backup.date"
        if !date.nil? && !date.empty?
          date = DateTime.strptime(date, get_backup_date_format)
          raise "Backup realizado a menos de #{frequency} dia" unless (DateTime.now-date).to_i >= 1
        end
      end
    end
  end

end

before "website:create_backup_file", "website:check_for_last_backup_date"
before "website:backup", "website:create_backup_file"
before "website:create_backup_file", "website:local_cleanup"
before "website:backup", "website:prepare_to_backup"
before "website:finish_backup", "website:create_or_update_backup_date"

after "website:backup", "website:finish_backup"
after "website:backup", "website:remote_cleanup"
after "website:remote_cleanup", "website:local_cleanup"


def local_backup_path(server)
  "#{server.configuration.local_backup_folder}/#{server.connection.host}/website"
end

def backup_file(server)
  "website-#{server.connection.host}-#{get_backup_date}.tar.gz"
end

def remote_backup_path(server)
  server.configuration.remote_temporary_backup_folder
end

def backup_file_path(server)
  "#{remote_backup_path(server)}/#{backup_file(server)}"
end
