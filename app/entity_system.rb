class EntitySystem < Stomp::System
  def update(dt)
    Stomp::Component.each_entity(AppendEntity) do |entity|
      Wrapper[AppendEntity, entity].call(dt)
    end
  end

  private

  class Wrapper < Struct.new(:entity_type, :entity)
    def call(_)
      append_to_entities
      remove_action
    end

    private

    def append_to_entities
      with_target(&method(:append_to_entity))
    end

    def remove_action
      entity.drop
    end

    def append_to_entity(target)
      target.with_hash_components(component_list)
    end

    def component_list
      action.component_list
    end

    def with_target(&blk)
      Stomp::Component.each_entity(target_type, &blk)
    end

    def target_type
      action.type
    end

    def action
      @_action ||= entity[entity_type]
    end

  end
end
