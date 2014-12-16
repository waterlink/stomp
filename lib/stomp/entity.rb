module Stomp
  class Entity < Struct.new(:name)
    def self.from_hash(hash)
      new(hash["name"])
        .with_hash_components(hash["components"])
    end

    def with_hash_components(components)
      Component.from_hash_list(components).each do |component|
        self[component.class] = component
      end
      self
    end

    def []=(type, component)
      remove(type)
      register(type, component)
    end

    def [](type)
      fetch(type, components[type])
    end

    def remove(type)
      unregister(type, components[type])
    end

    private

    def register(type, component)
      components[type] = Component.register(self, type, component)
    end

    def unregister(type, id)
      return unless id
      Component.unregister(type, id)
      components[type] = nil
    end

    def fetch(type, id)
      return unless id
      Component.fetch(type, id)
    end

    def components
      @_components ||= {}
    end
  end
end
