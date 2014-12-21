class GravitySystem < Stomp::System
  def update(dt)
    Stomp::Component.each_entity(Mass) do |entity|
      next if entity[PlanetSurface] || already_applied?(entity)
      entity[ForceParts] ||= ForceParts[[]]
      entity[ForceParts].parts[ForceParts::GRAVITY] = [0, g_for(entity) * entity[Mass].value]
    end
  end

  private

  def g_for(entity)
    Stomp::World.from_name(entity.world).gravity
  end

  def already_applied?(entity)
    entity[ForceParts] && entity[ForceParts].parts[ForceParts::GRAVITY]
  end
end
