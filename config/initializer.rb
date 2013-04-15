require "colored"
require "debugger"

Dir[File.dirname(__FILE__) + "/../lib/helper/*.rb"].each {|file| load file }
Dir[File.dirname(__FILE__) + "/../lib/recipes/*.rb"].each {|file| load file }

logger.level = Logger::IMPORTANT
STDOUT.sync

Config = hashes2ostruct YAML.load_file("#{File.dirname(__FILE__)}/../config/config.yml")
