module Stomp
  class Entity < Struct.new(:name, :world)
    def self.from_hash(hash, world: nil)
      new(hash["name"])
        .with_hash_components(hash["components"].flatten)
        .with_world(world)
    end

    def self.from_hash_list(list)
      list.map { |hash| from_hash(hash) }
    end

    def initialize(*args)
      super
      with_world(world || World.active_world)
    end

    def with_hash_components(components)
      Component.from_hash_list(components).each do |component|
        self[component.class] = component
      end
      self
    end

    def with_world(world)
      self.world = world
      self
    end

    def get_world
      World.from_name(world)
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

    def drop
      components.each do |type, id|
        unregister(type, id)
      end
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
