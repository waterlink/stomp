module Stomp
  def self.component(name, *properties)
    properties = [:_] if properties.empty?

    Struct.new(*properties) do
      attr_accessor :entity

      class << self
        def from_hash(hash)
          from_values(hash["values"]) ||
            from_value(hash["value"])
        end

        private

        def from_values(values)
          return unless values
          new(*values)
        end

        def from_value(value)
          new(value)
        end
      end

    end.tap do |type|
      Component.register_type(name, type)
    end
  end

  class Component
    class << self

      def each_entity(type)
        each_component(auto_type(type)) do |component|
          yield(component.entity) if block_given?
        end
      end

      def count(type)
        count = 0
        each_entity(type) do |entity|
          count += 1
        end
        count
      end

      def register_type(name, type)
        types << type
        type_names[name] = type
      end

      def from_hash_list(list)
        list.map(&method(:from_hash))
      end

      def register(entity, type, component)
        assign_entity(component, entity)
        handle_custom_component(component)
        register_to_free_pool(type, component) ||
          register_as_new(type, component)
      end

      def unregister(type, id)
        unassign_entity(components_of(type)[id])
        unassign_component(type, id)
      end

      def fetch(type, id)
        components_of(type)[id]
      end

      def auto_type(type)
        return type_from_name(type) if String === type
        type
      end

      private

      def handle_custom_component(component)
        return unless custom?(component)
        Stomp.component(component.name, :value)
      end

      def custom?(component)
        Custom === component
      end

      def assign_entity(component, entity)
        component.entity = entity
      end

      def unassign_entity(component)
        component.entity = nil
      end

      def unassign_component(type, id)
        components_of(type)[id] = nil
        pool_of(type) << id
      end

      def register_to_free_pool(type, component)
        return if pool_of(type).empty?
        assign_to_id(type, pool_of(type).pop, component)
      end

      def register_as_new(type, component)
        components_of(type) << component
        components_of(type).count - 1
      end

      def assign_to_id(type, id, component)
        components_of(type)[id] = component
        id
      end

      def from_hash(hash)
        type_from_name(hash["type"]).from_hash(hash)
      end

      def type_from_name(name)
        type_names.fetch(name) do
          raise ArgumentError, "unknown component type #{name}, known types: #{type_names.keys}"
        end
      end

      def each_component(type, &blk)
        components_of(type).each do |component|
          next unless component && active_component?(component)
          blk[component]
        end
      end

      def active_component?(component)
        return unless component.entity
        World.active_world?(component.entity.world)
      end

      def components_of(type)
        components[type] ||= []
      end

      def pool_of(type)
        pools[type] ||= []
      end

      def components
        @_components ||= {}
      end

      def pools
        @_pools ||= {}
      end

      def types
        @_types ||= []
      end

      def type_names
        @_type_names ||= {}
      end

    end
    
    Custom = Stomp.component("Custom", :name)

  end
end
