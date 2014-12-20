class MovementSystem < Stomp::System
  DEFAULT_MASS = 5
  VELOCITY_LOSS = 0.97

  def update
    update_acceleration
    update_velocity
    lose_velocity
    update_position
  end

  private

  def update_position
    update_vector(Position, Velocity)
  end

  def update_velocity
    update_vector(Velocity, Acceleration)
  end

  def update_vector(dst_type, src_type)
    Stomp::Component.each_entity(src_type) do |entity|
      next if entity[Fixed]
      entity[dst_type] ||= dst_type[0, 0]
      entity[dst_type].x += entity[src_type].x
      entity[dst_type].y += entity[src_type].y
    end
  end

  def update_acceleration
    Stomp::Component.each_entity(Force) do |entity|
      next if entity[Fixed]
      entity[Mass] ||= Mass[DEFAULT_MASS]
      entity[Acceleration] ||= Acceleration[]
      entity[Acceleration].x = entity[Force].x / entity[Mass].value
      entity[Acceleration].y = entity[Force].y / entity[Mass].value
    end
  end

  def lose_velocity
    Stomp::Component.each_entity(Velocity) do |entity|
      next if entity[Fixed]
      entity[Velocity].x *= VELOCITY_LOSS
      entity[Velocity].y *= VELOCITY_LOSS
    end
  end
end
