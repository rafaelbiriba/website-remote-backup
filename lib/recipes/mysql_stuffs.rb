desc "Create mysqldump password file in server"
namespace :mysql do
  task :prepare do
    print "Verificando hostname do servidor: "
    start_spinner
    server_name = capture("echo $CAPISTRANO:HOST$").strip
    stop_spinner
    puts "OK".green
    servers = Server.select{ |s| s.database.host == server_name && s.database.enable_database_backup == true}
    mysqlpassfile = ""
    puts "Preparando para criar o arquivo de senhas do mysql no host #{server_name.yellow}..."
    servers.each do |server|
      puts "Informações do database #{server.database.database_name.yellow}"
      db_user = Capistrano::CLI.ui.ask("Usuário do mysql: ")
      db_password = Capistrano::CLI.password_prompt("Senha do mysql: ")
      mysqlpassfile << "[mysqldump]\\nuser=#{db_user}\\npassword=#{db_password}\\n\\n[client]\\nuser=#{db_user}\\npassword=#{db_password}\\n\\n"
    end
    print "Salvando arquivo no server: "
    start_spinner
    run("cd ~/ && echo -e \"#{mysqlpassfile}\" > .my.cnf && chmod 600 .my.cnf")
    stop_spinner
    puts "OK".green
  end
  
  task :check do
    print "Testando comunicação com o mysql: "
    start_spinner
    databases = capture("mysqlshow")
    stop_spinner
    puts "OK".green
  end
end


after "mysql:prepare", "mysql:check"