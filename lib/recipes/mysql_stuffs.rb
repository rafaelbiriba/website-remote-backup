desc "Create mysqldump password file in server"
namespace :mysql do
  task :prepare do
    print "Verificando hostname do servidor: "
    start_spinner
    server_name = capture("echo $CAPISTRANO:HOST$").strip
    stop_spinner
    puts "OK".green
    servers = Server.select{ |s| s.database.host == server_name }
    mysqlpassfile_content = ""
    puts "Preparando para criar o arquivo de senhas do mysql no host #{server_name.yellow}..."
    databases = []
    servers.each_with_index do |server, i|
      databases << server.database.database_name
      puts "Informações do database #{server.database.database_name.yellow}"
      db_user = Capistrano::CLI.ui.ask("Usuário do mysql: ")
      db_password = Capistrano::CLI.password_prompt("Senha do mysql: ")
      mysqlpassfile_content << "[mysqldump#{i}]\\nuser=#{db_user}\\npassword=#{db_password}\\n\\n[client#{i}]\\nuser=#{db_user}\\npassword=#{db_password}\\n\\n"
    end
    print "Salvando arquivo de configuração no server: "
    start_spinner
    run("cd ~/ && echo -e \"#{mysqlpassfile_content}\" > .my.cnf && chmod 600 .my.cnf")
    stop_spinner
    puts "OK".green
    set :databases, databases
  end
  
  task :check do
    databases.each_with_index do |db, i|
      print "Testando comunicação com o banco #{db.yellow}: "
      start_spinner
      database = capture("mysqlshow --defaults-group-suffix=#{i}")
      stop_spinner
      raise Capistrano::Error if database.index(db).nil?
      puts "OK".green
    end
  end
end


after "mysql:prepare", "mysql:check"