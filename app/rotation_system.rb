class RotationSystem < Stomp::System
  DEFAULT_MOMENT = 5
  ANGULAR_VELOCITY_LOSS = 0.99

  def update(dt)
    Stomp::Component.each_entity(AngularVelocity) do |entity|
      entity[Orient] ||= Orient[0]
      entity[Torque] ||= Torque[0]
      entity[Moment] ||= Moment[DEFAULT_MOMENT]
      entity[Moment].inverted ||= 1.0 / entity[Moment].value

      entity[AngularVelocity].value += entity[Torque].value * entity[Moment].inverted * dt
      entity[Orient].value += entity[AngularVelocity].value * dt

      entity[AngularVelocity].value *= ANGULAR_VELOCITY_LOSS
    end
  end
end
