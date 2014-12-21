class MovementSystem < Stomp::System
  DEFAULT_MASS = 5
  VELOCITY_LOSS = 0.97

  FPS = 100
  DT = 1.0 / FPS

  def update(dt)
    update_acceleration(dt)
    update_velocity(dt)
    #lose_velocity(dt)
    update_position(dt)
  end

  private

  def update_position(dt)
    update_vector(Position, Velocity, dt)
  end

  def update_velocity(dt)
    update_vector(Velocity, Acceleration, dt)
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
      entity[Acceleration] ||= Acceleration[]
      entity[Acceleration].x = entity[Force].x / entity[Mass].value
      entity[Acceleration].y = entity[Force].y / entity[Mass].value
    end
  end

  def lose_velocity(dt)
    Stomp::Component.each_entity(Velocity) do |entity|
      next if entity[Fixed]
      entity[Velocity].x *= velocity_loss_for(dt)
      entity[Velocity].y *= velocity_loss_for(dt)
    end
  end

  def velocity_loss_for(dt)
    1 - (1 - VELOCITY_LOSS) * (dt / DT)
  end
end
