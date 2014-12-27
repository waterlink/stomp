class ComponentSystem < Stomp::System
  def update(dt)
    generic_action(SetComponentWrapper, SetComponent, dt)
    generic_action(AddToComponentWrapper, AddToComponent, dt)
    generic_action(RemoveComponentWrapper, RemoveComponent, dt)
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
      return with_self(&blk) if target == "self"
      Stomp::Component.each_entity(target, &blk)
    end

    def with_self(&blk)
      blk[entity]
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

  class RemoveComponentWrapper < CommonWrapper

    private

    def adjust_component(target)
      remove_component(target, component)
      target.drop_if_empty
    end

    def remove_component(target, component)
      return remove_components(target, component) if Array === component
      target.remove(component)
    end

    def remove_components(target, components)
      components.each(&curry_method(target, &method(:remove_component)))
    end

    def curry_method(*args, &blk)
      -> (*other_args) { blk[*(args + other_args)] }
    end
  end

end
