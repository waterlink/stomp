class WorldSystem < Stomp::System
  def update(dt)
    switch_world_action
    switch_world_back_action
  end

  private

  def switch_world_action
    with_action_value(SwitchWorld) do |world|
      switch_world(world)
    end
  end

  def switch_world_back_action
    with_action_value(SwitchWorldBack) do |_|
      restore_world
    end
  end

  def switch_world(name)
    return unless world_exists?(name)
    push_world
    set_world(name)
  end

  def restore_world
    return if empty_world_history?
    set_world(pop_last_world)
  end

  def set_world(name)
    Stomp::World.active_world = name
  end

  def with_action_value(type, &blk)
    Stomp::Component.each_entity(type) do |entity|
      blk[action_value(type, entity)]
      entity.drop
    end
  end

  def action_value(type, entity)
    entity[type].respond_to?(:value) &&
      entity[type].value
  end

  def world_exists?(name)
    !!Stomp::World.from_name(name)
  end

  def empty_world_history?
    world_history.empty?
  end

  def push_world
    world_history << active_world
  end

  def active_world
    Stomp::World.active_world
  end

  def pop_last_world
    world_history.pop
  end

  def world_history
    @_world_history ||= []
  end
end
