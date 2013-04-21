require "colored"
require "debugger"
require 'capistrano-transfer_progress'
require 'terminal-notifier'
require 'digest/md5'
require 'fileutils'

Dir[File.dirname(__FILE__) + "/../lib/helper/*.rb"].each {|file| load file }
Dir[File.dirname(__FILE__) + "/../lib/recipes/*.rb"].each {|file| load file }

load File.dirname(__FILE__) + "/config.rb" 

logger.level = Logger::IMPORTANT
STDOUT.sync