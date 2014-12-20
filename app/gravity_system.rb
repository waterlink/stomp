class GravitySystem < Stomp::System
  G = 1.96

  def update
    Stomp::Component.each_entity(Mass) do |entity|
      next if entity[PlanetSurface] || already_applied?(entity)
      entity[ForceParts] ||= ForceParts[[]]
      entity[ForceParts].parts[ForceParts::GRAVITY] = [0, G * entity[Mass].value]
    end
  end

  private

  def already_applied?(entity)
    entity[ForceParts] && entity[ForceParts].parts[ForceParts::GRAVITY]
  end
end
