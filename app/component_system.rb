class ComponentSystem < Stomp::System
  def update(dt)
    generic_action(SetComponentWrapper, SetComponent, dt)
    generic_action(AddToComponentWrapper, AddToComponent, dt)
  end

  private

  def generic_action(wrapper, type, dt)
    Stomp::Component.each_entity(type) do |entity|
      wrapper[type, entity].call(dt)
    end
  end

  class CommonWrapper < Struct.new(:type, :entity)
    def call(_)
      adjust_components
      remove_action
    end

    private

    def adjust_components
      with_target do |target|
        adjust_component(target)
      end
    end

    def remove_action
      entity.remove(type)
      entity.drop_if_empty
    end

    def with_target(&blk)
      Stomp::Component.each_entity(target, &blk)
    end

    def target
      action.target
    end

    def component
      action.component
    end

    def value
      action.value
    end

    def action
      @_action ||= entity[type]
    end
  end

  class SetComponentWrapper < CommonWrapper

    private

    def adjust_component(target)
      target[component].value = value
    end
  end

  class AddToComponentWrapper < CommonWrapper

    private

    def adjust_component(target)
      target[component].value += value
    end
  end
end
