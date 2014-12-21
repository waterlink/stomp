class BondSystem < Stomp::System
  BOND_FORCE_CAP = 500
  THRESHOLD = 0.5

  POSITIONAL_CORRECTION_PERCENTAGE = 0.5
  VELOCITY_CORRECTION_PERCENTAGE = 0.5
  ALLOW_SLOP = 0

  def self.[](*args)
    @_instance ||= super
  end

  def self.instance
    @_instance
  end

  def update(dt)
    handle_bond_links(BondThread, &method(:handle_threads))
  end

  def handle_bond_links(type, &blk)
    Stomp::Component.each_entity(type) do |entity|
      bond_link = entity[type]

      blk[bond_link,
          bond_with_id(bond_link.id1),
          bond_with_id(bond_link.id2)]

      blk[bond_link,
          bond_with_id(bond_link.id2),
          bond_with_id(bond_link.id1)]
    end
  end

  private

  def bond_with_id(id)
    invalidate_bond(id)
    bonds[id] ||= fetch_bond(id)
    bonds[id] && bonds[id].entity
  end

  def bonds
    @_bonds ||= {}
    @_bonds[Stomp::World.active_world] ||= {}
  end

  def invalidate_bond(id)
    return if bonds[id] && bonds[id].entity
    bonds[id] = nil
  end

  def fetch_bond(id)
    Stomp::Component.each_entity(Bond) do |entity|
      return entity[Bond] if entity[Bond].id == id
    end
    nil
  end

  def handle_threads(bond, entity, other, _fix_position: true)
    return unless bond && entity && other

    return if entity[Fixed] && other[Fixed]
    return handle_threads(bond, other, entity, _fix_position: _fix_position) if entity[Fixed]

    entity[ForceParts] ||= ForceParts[[]]
    entity[Force] ||= Force[0, 0]

    other[ForceParts] ||= ForceParts[[]]
    other[Force] ||= Force[0, 0]

    bx, by = entity[ForceParts].parts[ForceParts::BOND] ||= [0, 0]

    vx, vy = [entity[Position].x + entity[Bond].x - other[Position].x - other[Bond].x,
              entity[Position].y + entity[Bond].y - other[Position].y - other[Bond].y]

    d = Math.sqrt(vx ** 2 + vy ** 2)

    #if d < bond.length
    #  entity[ForceParts].parts[ForceParts::BOND] = [0, 0]
    #  return
    #end

    nx, ny = Stomp::Math.normalize_vector([vx, vy])

    if d < bond.length
      return
    end

    if _fix_position && other[Fixed]
      fix_position(entity, nx, ny, d, bond)
      handle_threads(bond, entity, other, _fix_position: false)
      return
    end

    force = entity[Force]
    other_force = other[Force]
    fx, fy = [force.x - bx - other_force.x, force.y - by - other_force.y]

    tforce = nx * fx + ny * fy

    if tforce < 0
      entity[ForceParts].parts[ForceParts::BOND] = [0, 0]
      fix_position(entity, nx, ny, d, bond)
      return
    end

    entity[ForceParts].parts[ForceParts::BOND] = [-0.5 * tforce * nx, -0.5 * tforce * ny]
    other[ForceParts].parts[ForceParts::BOND] = [0.5 * tforce * nx, 0.5 * tforce * ny]

    if _fix_position
      fix_position(entity, nx, ny, d, bond, fix_velocity: false)
    end
  end

  def fix_position(entity, nx, ny, d, bond, fix_velocity: true)
    return if entity[Fixed]
    entity[Velocity] ||= Velocity[0, 0]

    tension = d - bond.length * (1 + ALLOW_SLOP)
    c = 1.0 * tension * POSITIONAL_CORRECTION_PERCENTAGE
    cx, cy = [c * nx, c * ny]

    entity[Position].x -= cx
    entity[Position].y -= cy

    return unless fix_velocity
    v = entity[Velocity].x * nx + entity[Velocity].y * ny
    entity[Velocity].x -= v * nx * VELOCITY_CORRECTION_PERCENTAGE
    entity[Velocity].y -= v * ny * VELOCITY_CORRECTION_PERCENTAGE
  end
end
