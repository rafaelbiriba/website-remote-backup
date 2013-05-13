config = []
Dir[File.dirname(__FILE__) + "/servers/*.yml"].each do |file|
  config << YAML.load_file(file)
end

env_host = ENV["HOST"]
if env_host
  selected_host = config.select { |s| s["connection"]["host"] == env_host }
  if selected_host.empty?
    raise "Host #{env_host} não encontado!"
  else
    config = selected_host
  end
end

Server = hashes2ostruct(config)
