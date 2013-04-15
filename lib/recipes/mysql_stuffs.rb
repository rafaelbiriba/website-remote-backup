desc "Create mysqldump password file in server"
namespace :mysql do
  task :prepare do
    debugger
    puts "Preparando para criar o arquivo de senhas do mysql a ser salvo no server..."
    db_user = Capistrano::CLI.ui.ask("Usuário do mysql: ")
    db_password = Capistrano::CLI.password_prompt("Senha do mysql: ")
    print "Salvando no server: "
    start_spinner
    run("cd ~/ && echo -e \"[mysqldump]\\nuser=#{db_user}\\npassword=#{db_password}\\n\\n[client]\\nuser=#{db_user}\\npassword=#{db_password}\" > .my.cnf && chmod 600 .my.cnf")
    stop_spinner
    puts "Done.".green
  end
  
  task :check do
    print "Testando comunicação com o mysql: "
    start_spinner
    databases = capture("mysqlshow")
    stop_spinner
    puts "Done.".green
  end
end

after "mysql:prepare", "mysql:check"