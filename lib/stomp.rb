$:.unshift(File.expand_path(File.join(__FILE__, "..")))
$:.unshift(File.expand_path(File.join(__FILE__, "..", "..", "app")))

require "yaml"

module Stomp
  def self.config
    @_config ||= YAML.load_file("config/config.yml")
  end
end

%w(
  gosu
).each do |lib|
  require lib
end

%w(
  window
).each do |part|
  require "stomp/#{part}"
end
