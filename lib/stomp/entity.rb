module Stomp
  class Entity < Struct.new(:name, :world)
    include Enumerable

    def self.from_hash(hash, world: nil)
      new(hash["name"])
        .with_hash_components(hash["components"])
        .with_world(world)
    end

    def self.from_hash_list(list)
      list.map { |hash| from_hash(hash) }
    end

    def initialize(*args)
      super
      with_world(world || World.active_world)
    end

    def ==(other)
      return false unless self.class === other
      self.object_id == other.object_id
    end

    def <=>(other)
      self.object_id <=> other.object_id
    end

    def with_hash_components(components)
      Component.from_hash_list(components.flatten).each do |component|
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
      type = auto(type)
      remove(type)
      register(type, component)
    end

    def [](type)
      type = auto(type)
      fetch(type, components[type])
    end

    def remove(type)
      type = auto(type)
      unregister(type, components[type])
    end

    def drop
      components.each do |type, id|
        unregister(type, id)
      end
    end

    def drop_if_empty
      return unless empty?
      drop
    end

    private

    def auto(type)
      Component.auto_type(type)
    end

    def empty?
      components.values.none?
    end

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
