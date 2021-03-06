class ForceSystem < Stomp::System
  def update(dt)
    Stomp::Component.each_entity(ForceParts) do |entity|
      entity[Force] ||= Force[0, 0]
      add_forces(entity)
    end
  end

  private

  def add_forces(entity)
    entity[Force].x = 0
    entity[Force].y = 0
    entity[ForceParts].parts.each do |part|
      next unless part
      x, y = part
      entity[Force].x += x
      entity[Force].y += y
    end
  end
end
