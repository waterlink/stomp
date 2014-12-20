class ForceSystem < Stomp::System
  def update
    Stomp::Component.each_entity(ForceParts) do |entity|
      entity[Force] ||= Force[0, 0]
      add_forces(entity)
    end
  end

  private

  def add_forces(entity)
    entity[ForceParts].parts.each do |part|
      next unless part
      x, y = part
      entity[Force].x += x
      entity[Force].y += y
    end
  end
end
