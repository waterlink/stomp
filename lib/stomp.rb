$:.unshift(File.expand_path(File.join(__FILE__, "..", "..", "app")))
$:.unshift(File.expand_path(File.join(__FILE__, "..")))

require "yaml"
require "logger"

module Stomp
  def self.config
    @_config ||= YAML.load_file("config/config.yml")
  end

  def self.logger
    @_logger ||= Logger.new(STDOUT)
  end

  def self.run
    Window.new.show
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
  world
  math
  draw
).each do |part|
  require "stomp/#{part}"
end

require "components"
