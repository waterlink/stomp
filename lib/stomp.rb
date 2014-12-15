$:.unshift(File.expand_path(File.join(__FILE__, "..")))
$:.unshift(File.expand_path(File.join(__FILE__, "..", "..", "app")))

class Object
  def self.const_missing(name)
    Stomp.autoload(name)
  end
end

module Stomp
  class << self

    class AutoloadError < LoadError; end

    def autoload(name)
      reject_autoloading_in_process(name)
      autoload!(name)
    end

    private

    def autoload!(name)
      with_proper_autoloading_state(name) do
        require(snake_cased(name))
        Object.const_get(name)
      end
    end
    
    def snake_cased(string)
      string
        .to_s
        .gsub(/::/, "/")
        .gsub(/(.)([A-Z])/, "\1_\2")
        .downcase
    end

    def reject_autoloading_in_process(name)
      raise AutoloadError, "#{snake_cased(name)} failed to define #{name}" if autoloading?(name)
    end

    def with_proper_autoloading_state(name)
      autoloading_states[name] = true
      yield.tap { autoloading_states[name] = false }
    end

    def autoloading?(name)
      autoloading_states[name]
    end

    def autoloading_states
      Thread.current[:_stomp_autoloading] ||= {}
    end

  end
end
