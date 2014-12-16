$:.unshift(File.expand_path(File.join(__FILE__, "..")))
$:.unshift(File.expand_path(File.join(__FILE__, "..", "..", "app")))

require "yaml"
require "logger"

module Stomp
  def self.config
    @_config ||= YAML.load_file("config/config.yml")
  end

  def self.logger
    @_logger ||= Logger.new(STDOUT)
  end
end

%w(
  gosu
).each do |lib|
  require lib
end

%w(
  system
  window
  component
  entity
).each do |part|
  require "stomp/#{part}"
end

require "components"
