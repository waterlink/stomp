class TimeoutSystem < Stomp::System
  def update(dt)
    Stomp::Component.each_entity(TimedAction) do |entity|
      Wrapper[TimedAction, entity].call(dt)
    end
  end

  private

  class Wrapper < Struct.new(:type, :entity)
    def call(dt)
      _call
      advance_time(dt)
    end

    private

    def _call
      return unless time_has_come?
      create_entity
      remove_action
    end

    def advance_time(dt)
      action.time += dt
    end

    def create_entity
      Stomp::Entity
        .new(name)
        .with_hash_components(component_list)
    end

    def remove_action
      entity.remove(type)
    end

    def time_has_come?
      time >= action.timeout
    end

    def time
      action.time ||= 0
    end

    def component_list
      [action.action]
    end

    def name
      "#{entity.name}: #{type.name}"
    end

    def action
      @_action ||= entity[type]
    end
  end
end
