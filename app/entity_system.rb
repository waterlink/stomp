class EntitySystem < Stomp::System
  def update(dt)
    generic_action(CreateAction, CreateEntity, dt)
    generic_action(AppendEntityAction, AppendEntity, dt)
    generic_action(DropAction, Drop, dt)
  end

  private

  def generic_action(action_type, type, dt)
    Stomp::Component.each_entity(type) do |entity|
      action_type[type, entity].call(dt)
    end
  end

  class CreateAction < Struct.new(:entity_type, :entity)
    def call(_)
      create_entities
      drop_component
    end

    private

    def create_entities
      entity_list.each_with_index(&method(:create_entity))
    end

    def create_entity(component_list, number)
      Stomp::Entity
        .new(name(number))
        .with_hash_components(component_list)
    end

    def drop_component
      entity.remove(entity_type)
      entity.drop_if_empty
    end

    def name(number)
      "#{entity.name}: CreateAction #{number}"
    end

    def entity_list
      action.entity_list
    end

    def action
      @_action ||= entity[entity_type]
    end
  end

  class DropAction < Struct.new(:entity_type, :entity)
    def call(_)
      drop_entities
      drop_component
    end

    private

    def drop_entities
      Stomp::Component.each_entity(target_type) do |entity|
        entity.drop
      end
    end

    def drop_component
      entity.remove(entity_type)
      entity.drop_if_empty
    end

    def target_type
      action.component
    end

    def action
      @_action ||= entity[entity_type]
    end
  end

  class AppendEntityAction < Struct.new(:entity_type, :entity)
    def call(_)
      append_to_entities
      drop_component
    end

    private

    def drop_component
      entity.remove(entity_type)
      entity.drop_if_empty
    end

    def append_to_entities
      with_target(&method(:append_to_entity))
    end

    def append_to_entity(target)
      target.with_hash_components(component_list)
    end

    def component_list
      action.component_list
    end

    def with_target(&blk)
      return with_target_for_options(&blk) if Array === target_type
      Stomp::Component.each_entity(target_type, &blk)
    end

    def with_target_for_options(&blk)
      option, type = target_type
      case option
      when "first"
        Stomp::Component.each_entity(type) do |target|
          return blk[target]
        end
      end
    end

    def target_type
      action.type
    end

    def action
      @_action ||= entity[entity_type]
    end

  end
end
