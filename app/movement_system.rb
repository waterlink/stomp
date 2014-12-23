class MovementSystem < Stomp::System
  DEFAULT_MASS = 5
  VELOCITY_LOSS = 0.998

  def update(dt)
    #debug_info(dt)
    set_acceleration(dt)
    update_acceleration(dt)
    update_scalar_acceleration(dt)
    update_velocity(dt)
    lose_velocity(dt)
    update_position(dt)
    @_tick = tick + 1
  end

  private

  def update_position(dt)
    update_vector(Position, Velocity, dt)
  end

  def update_velocity(dt)
    update_vector(Velocity, Acceleration, dt)
  end

  def set_acceleration(dt)
    Stomp::Component.each_entity(SetAcceleration) do |entity|
      source = entity[SetAcceleration]

      Stomp::Component.each_entity(source.component) do |target|
        target[Acceleration] ||= Acceleration[0, 0]
        target[Acceleration].x = source.x
        target[Acceleration].y = source.y
      end

      entity.drop
    end
  end

  def update_scalar_acceleration(dt)
    Stomp::Component.each_entity(ScalarAcceleration) do |entity|
      entity[Velocity] ||= Velocity[0, 0]

      # v' = v + norm(v) * scalar_acceleration * dt
      v = Stomp::Math.to_v(entity[Velocity])
      v_n = Stomp::Math.normalize_vector(v)
      v = Stomp::Math.vadd(v, Stomp::Math.vmul(v_n, entity[ScalarAcceleration].value * dt))

      entity[Velocity].x = v[0]
      entity[Velocity].y = v[1]
    end
  end

  def update_vector(dst_type, src_type, dt)
    Stomp::Component.each_entity(src_type) do |entity|
      next if entity[Fixed]
      entity[dst_type] ||= dst_type[0, 0]
      entity[dst_type].x += entity[src_type].x * dt
      entity[dst_type].y += entity[src_type].y * dt
    end
  end

  def update_acceleration(dt)
    Stomp::Component.each_entity(Force) do |entity|
      next if entity[Fixed]
      entity[Mass] ||= Mass[DEFAULT_MASS]
      entity[Mass].inverted ||= Stomp::Math.inverted_mass(entity[Mass].value)
      return if entity[Mass].value == 0
      entity[Acceleration] ||= Acceleration[]
      entity[Acceleration].x = entity[Force].x * entity[Mass].inverted
      entity[Acceleration].y = entity[Force].y * entity[Mass].inverted
    end
  end

  def lose_velocity(dt)
    Stomp::Component.each_entity(Velocity) do |entity|
      next if entity[Fixed]
      entity[Velocity].x *= VELOCITY_LOSS
      entity[Velocity].y *= VELOCITY_LOSS
    end
  end

  def debug_info(dt)
    Stomp::Component.each_entity(Velocity) do |e|
      next if e[Fixed]
      e[Acceleration] ||= Acceleration[0, 0]
      e[Force] ||= Force[0, 0]
      e[Mass] ||= Mass[DEFAULT_MASS]

      if tick % 100 == 0
        Stomp.logger.debug "entity#{[Time.now.to_i, dt, e.name, e[Position], e[Velocity], e[Acceleration], e[Force]]}"
        Stomp.logger.debug "entity#{[e[ForceParts]]}"
      end
    end
  end

  def tick
    @_tick ||= 0
  end
end
