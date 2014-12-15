$:.unshift(File.expand_path(File.join(__FILE__, "..")))
$:.unshift(File.expand_path(File.join(__FILE__, "..", "..", "app")))

require "logger"

module Stomp
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
