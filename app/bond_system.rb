class BondSystem < Stomp::System
  BOND_FORCE_CAP = 500
  THRESHOLD = 0.5

  POSITIONAL_CORRECTION_PERCENTAGE = 0.8

  def update
    Stomp::Component.each_entity(Bond) do |entity|
      Stomp::Component.each_entity(Bond) do |other|
        next if entity == other || entity[Bond].id != other[Bond].id
        next unless entity[Position] && other[Position]
        apply_force(entity, other)
      end
    end
  end

  private

  def apply_force(entity, other)
    entity[ForceParts] ||= ForceParts[[]]
    entity[Force] ||= Force[0, 0]

    bx, by = entity[ForceParts].parts[ForceParts::BOND] ||= [0, 0]

    bond = entity[Bond]

    vx, vy = [entity[Position].x - other[Position].x,
              entity[Position].y - other[Position].y]

    d = Math.sqrt(vx ** 2 + vy ** 2)

    if d < bond.length
      entity[ForceParts].parts[ForceParts::BOND] = [0, 0]
      return
    end

    nx, ny = Stomp::Math.normalize_vector([vx, vy])

    force = entity[Force]
    fx, fy = [force.x - bx, force.y - by]

    tforce = nx * fx + ny * fy

    if bond.length < d
      tforce += (bond.spring - 1) * (d - bond.length)
    end

    if tforce < 0
      entity[ForceParts].parts[ForceParts::BOND] = [0, 0]
      fix_position(entity, nx, ny, d, bond)
      return
    end

    entity[ForceParts].parts[ForceParts::BOND] = [-tforce * nx, -tforce * ny]

    fix_position(entity, nx, ny, d, bond)
  end

  def fix_position(entity, nx, ny, d, bond)
    return if entity[Fixed]
    puts "fix_position#{[entity, nx, ny, d, bond]}"
    tension = d - bond.length
    c = 1.0 * tension * POSITIONAL_CORRECTION_PERCENTAGE
    cx, cy = [c * nx, c * ny]

    entity[Position].x -= cx
    entity[Position].y -= cy
  end
end
