class DecaySystem < Stomp::System
  def update(dt)
    Stomp::Component.each_entity(Decay) do |entity|
      advance_decay_timer(entity, dt)
      drop_entity(entity)
    end
  end

  private

  def advance_decay_timer(entity, dt)
    entity[Decay].time -= dt
  end

  def drop_entity(entity)
    return unless decayed?(entity)
    entity.drop
  end

  def decayed?(entity)
    entity[Decay].time <= 0
  end
end
