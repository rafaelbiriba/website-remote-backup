config = []
Dir[File.dirname(__FILE__) + "/servers/*.yml"].each do |file|
  config << YAML.load_file(file)
end

Server = hashes2ostruct(config)
