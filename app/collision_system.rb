class CollisionSystem < Stomp::System
  DEFAULT_RESTITUTION = 1.0

  DEFAULT_MASS = 5
  DEFAULT_MOMENT = 25

  DEFAULT_STATIC_FRICTION = 0.7
  DEFAULT_DYNAMIC_FRICTION = 0.3

  POSITIONAL_CORRECTION_PERCENTAGE = 0.8
  POSITIONAL_CORRECTION_SLOP = 0.999999

  INFINITE_MASS_POSITIONAL_CORRECTION = 1.2
  DEFAULT_INFINITE_MASS_VS_FIXED_BOUNCE = 1.01

  EPS = 1e-7

  def update(dt)
    #Stomp::Component.each_entity(CollisionShape) do |entity|
    #  Stomp::Component.each_entity(CollisionShape) do |other|
    #    next if other == entity
    #    _resolve_collision(entity, other)
    #  end
    #end
    entities = []
    Stomp::Component.each_entity(CollisionShape) do |entity|
      entities << entity
    end
    sort_and_sweep(entities)
  end

  private

  def sort_and_sweep(entities)
    marks_x = marks_for_x(entities)
    marks_y = marks_for_y(entities)
    checks_x = checks_for(marks_x)
    checks_y = checks_for(marks_y)
    sweep_for(checks_x < checks_y ? marks_x : marks_y)
  end

  def sweep_for(marks)
    stack = []
    marks.each do |(x, type, entity)|
      case type
      when :open
        stack.each { |other| resolve_collision(entity, other) }
        stack << entity
      when :close
        stack.delete_if { |e| e == entity }
      end
    end
  end

  def checks_for(marks)
    stack = 0
    count = 0
    marks.each do |(x, type, entity)|
      case type
      when :open
        count += stack
        stack += 1
      when :close
        stack -= 1
      end
    end
    count
  end

  def marks_for_x(entities, aabb_type: BroadAabbShape, position_type: Position)
    marks = []
    entities.each do |e|
      e[aabb_type] ||= aabb_for(e, type: aabb_type)
      origin_x = e[position_type].x
      shape = e[aabb_type]
      open_x = shape.min_x + origin_x
      close_x = shape.max_x + origin_x
      marks << [open_x, :open, e]
      marks << [close_x, :close, e]
    end
    marks.sort
  end

  def marks_for_y(entities, aabb_type: BroadAabbShape, position_type: Position)
    marks = []
    entities.each do |e|
      e[aabb_type] ||= aabb_for(e, type: aabb_type)
      origin_y = e[position_type].y
      shape = e[aabb_type]
      open_y = shape.min_y + origin_y
      close_y = shape.max_y + origin_y
      marks << [open_y, :open, e]
      marks << [close_y, :close, e]
    end
    marks.sort
  end

  def resolve_collision(a, b)
    return if a == b
    return unless same_layer?(a, b)
    return if a[Fixed] && b[Fixed]
    _resolve_collision(a, b)
    _resolve_collision(b, a)
  end

  def _resolve_collision(a, b)
    return unless broad_aabb(a, b)
    with_callbacks(impulse_resolution(collision_normal(a, b), a, b), a, b)
  end

  def broad_aabb(a, b)
    a[BroadAabbShape] ||= aabb_for(a)
    b[BroadAabbShape] ||= aabb_for(b)
    !!aabb_vs_aabb(a, b, type: BroadAabbShape)
  end

  def aabb_for(x, type: BroadAabbShape)
    aabb_for_circle(x, type: type) ||
      aabb_for_aabb(x, type: type) ||
      aabb_for_rigid(x, type: type)
  end

  def aabb_for_circle(x, type: type)
    return unless x[CircleShape]
    shape = x[CircleShape]
    min_x, min_y, max_x, max_y = [shape.x - shape.r, shape.y - shape.r,
                                  shape.x + shape.r, shape.y + shape.r]
    type[min_x, min_y, max_x, max_y]
  end

  def aabb_for_aabb(x, type: type)
    return unless x[AabbShape]
    rigid_out_of_aabb(x)
    aabb_for_rigid(x, type: type)
  end


  def aabb_for_rigid(x, type: type)
    return unless x[RigidShape]
    x[Orient] ||= Orient[0]
    vertices = Stomp::Math.shape_from(x[RigidShape].vertices, x[Orient].value)

    min_x = vertices.map(&:first).min
    min_y = vertices.map(&:last).min

    max_x = vertices.map(&:first).max
    max_y = vertices.map(&:last).max

    type[min_x, min_y, max_x, max_y]
  end

  def with_callbacks(resolved, a, b)
    run_callbacks(a, b) if resolved
  end

  def run_callbacks(a, b)
    inflict_callback(a, b)
    inflict_callback(b, a)
    take_callback(a)
    take_callback(b)
  end

  def inflict_callback(src, target)
    return unless src[OnCollision]
    target.with_hash_components(src[OnCollision].inflict_list)
  end

  def take_callback(target)
    return unless target[OnCollision]
    target.with_hash_components(target[OnCollision].take_list)
  end

  def same_layer?(a, b)
    return true unless a[CollisionShape].layer && b[CollisionShape].layer
    a[CollisionShape].layer == b[CollisionShape].layer
  end

  def support_point(shape, direction)
    shape.map { |vertex| [Stomp::Math.dot_product(vertex, direction), vertex]}.max
  end

  def get_normal(face, origin)
    (x1, y1), (x2, y2) = face
    ox, oy = origin
    px, py = [ox - x1, oy - y1]
    vx, vy = [x2 - x1, y2 - y1]
    nx, ny = -vy, vx
    if Stomp::Math.dot_product([nx, ny], [px, py]) > 0
      nx, ny = [-nx, -ny]
    end
    normalize([nx, ny])
  end

  def axis_least_penetration(pos_a, shape_a, pos_b, shape_b)
    shape_a.each_cons(2).map { |face|
      nx, ny = get_normal(face, [0, 0])
      _, (sx, sy) = support_point(shape_b, [-nx, -ny])

      vx, vy = Stomp::Math.vmul(Stomp::Math.vadd(face[0],
                                                 face[1]),
                                0.5)
      vx, vy = Stomp::Math.vadd([vx, vy],
                                Stomp::Math.vsub(pos_a, pos_b))
      svx, svy = [sx - vx, sy - vy]
      d = Stomp::Math.dot_product([nx, ny], [svx, svy])
      [d, face]
    }.max
  end

  def shape_from(entity)
    return [] unless entity[RigidShape]
    return entity[RigidShape].vertices unless entity[Orient]
    Stomp::Math.shape_from(entity[RigidShape].vertices, entity[Orient].value)
  end

  def find_incident_face(ref_shape, inc_shape, ref_face)
    ref_normal = get_normal(ref_face, [0, 0])

    min_dot, inc_face = shape_from(inc_shape).each_cons(2).map do |face|
      normal = get_normal(face, [0, 0])
      dot = Stomp::Math.dot_product(ref_normal, normal)
      [dot, face]
    end.min

    Stomp::Math.fadd(inc_face, Stomp::Math.to_v(inc_shape[Position]))
  end

  # returns face
  def clip(n, c, face)
    count = 0

    new_face = []

    d1 = Stomp::Math.dot_product(n, face[0]) - c
    d2 = Stomp::Math.dot_product(n, face[1]) - c

    new_face << face[0] if d1 <= 0
    new_face << face[1] if d2 <= 0

    if d1 * d2 < 0
      alpha = d1 / (d1 - d2)

      # face.0 + (face.1 - face.0) * alpha
      new_face << Stomp::Math.vadd(face[0],
                                   Stomp::Math.vmul(Stomp::Math.vsub(face[1],
                                                                     face[0]),
                                                    alpha))
    end

    raise "UnreachableCode in CollisionSystem#clip (new_face.count > 2)" if new_face.count > 2

    new_face
  end

  def collision_normal(a, b)
    return unless a[Position] && b[Position]
    normalize(circle_vs_circle(a, b) ||
              circle_vs_rigid(a, b) ||
              rigid_vs_rigid(a, b))
  end

  def rigid_out_of_aabb(x)
    if x[AabbShape] && !x[RigidShape]
      s = x[AabbShape]
      x1, y1, x2, y2 = [s.min_x, s.min_y, s.max_x, s.max_y]
      x[RigidShape] ||= RigidShape[[[x1, y1],
                                    [x1, y2],
                                    [x2, y2],
                                    [x2, y1],
                                    [x1, y1]]]
    end
  end

  # returns [nx, ny, penetration, contacts]
  def circle_vs_rigid(a, b)
    rigid_out_of_aabb(b)

    return unless a[CircleShape] && b[RigidShape]

    cx, cy = [a[Position].x + a[CircleShape].x - b[Position].x,
              a[Position].y + a[CircleShape].y - b[Position].y]

    radius = a[CircleShape].r
    radius2 = radius ** 2

    s, face, normal = shape_from(b).each_cons(2).map { |face|
      v, _ = face
      vx, vy = v
      nx, ny = get_normal(face, [0, 0])
      dx, dy = [cx - vx, cy - vy] 
      s = Stomp::Math.dot_product([nx, ny], [dx, dy])
      [s, face, [nx, ny]]
    }.max

    return if s > radius

    v1, v2 = face

    if s < EPS
      nx, ny = normal
      nx, ny = [-nx, -ny]

      contacts = [[nx * a[CircleShape].r + a[CircleShape].x + a[Position].x,
                   ny * a[CircleShape].r + a[CircleShape].y + a[Position].y]]

      penetration = radius

      return [nx, ny, penetration, contacts]
    end

    c = [cx, cy]
    dot1 = Stomp::Math.dot_product(Stomp::Math.vsub(c, v1),
                                   Stomp::Math.vsub(v2, v1))
    dot2 = Stomp::Math.dot_product(Stomp::Math.vsub(c, v2),
                                   Stomp::Math.vsub(v1, v2))
    penetration = radius - s

    if dot1 <= 0

      return if Stomp::Math.hypot2(c, v1) > radius2

      nx, ny = Stomp::Math.vsub(v1, c)

      contacts = [Stomp::Math.vadd(v1, Stomp::Math.to_v(b[Position]))]

    elsif dot2 <= 0

      return if Stomp::Math.hypot2(c, v2) > radius2

      nx, ny = Stomp::Math.vsub(v2, c)

      contacts = [Stomp::Math.vadd(v2, Stomp::Math.to_v(b[Position]))]

    else

      return if Stomp::Math.dot_product(Stomp::Math.vsub(c, v1), normal) > radius

      nx, ny = normal
      nx, ny = [-nx, -ny]

      # a.position + normal * a.radius
      contacts = [Stomp::Math.vadd(Stomp::Math.vadd(Stomp::Math.to_v(a[Position]),
                                                    Stomp::Math.to_v(a[CircleShape])),
                                   Stomp::Math.vmul([nx, ny], radius))]
      
    end

    [nx, ny, penetration, contacts]
  end

  def bias_greater_than(a, b)
    bias_relative = 0.95
    bias_absolute = 0.01
    a >= b * bias_relative + a * bias_absolute
  end

  # returns [normal_x, normal_y, penetration]
  def rigid_vs_rigid(a, b)

    rigid_out_of_aabb(a)
    rigid_out_of_aabb(b)

    return unless a[RigidShape] && b[RigidShape]

    penetration_a, face_a = axis_least_penetration(Stomp::Math.to_v(a[Position]),
                                                   shape_from(a),
                                                   Stomp::Math.to_v(b[Position]),
                                                   shape_from(b))

    penetration_b, face_b = axis_least_penetration(Stomp::Math.to_v(b[Position]),
                                                   shape_from(b),
                                                   Stomp::Math.to_v(a[Position]),
                                                   shape_from(a))

    return if penetration_b >= 0 || penetration_a >= 0

    if bias_greater_than(penetration_a, penetration_b)

      ref_shape = a
      inc_shape = b
      ref_face = face_a
      flip = 1

    else

      ref_shape = b
      inc_shape = a
      ref_face = face_b
      flip = -1
      
    end

    inc_face = find_incident_face(ref_shape, inc_shape, ref_face)
    ref_face = Stomp::Math.fadd(ref_face, Stomp::Math.to_v(ref_shape[Position]))

    v1, v2 = ref_face

    side_plane_normal = normalize(Stomp::Math.vsub(v2, v1))

    ref_face_normal = orthogonalize(side_plane_normal)

    ref_c = Stomp::Math.dot_product(ref_face_normal, v1)
    neg_side = -Stomp::Math.dot_product(side_plane_normal, v1)
    pos_side = Stomp::Math.dot_product(side_plane_normal, v2)

    clips = [clip(Stomp::Math.vneg(side_plane_normal), neg_side, inc_face),
             clip(side_plane_normal, pos_side, inc_face)] 

    return if clips.any? { |c| c.count < 2 }

    normal = Stomp::Math.vmul(ref_face_normal, flip)

    separation = Stomp::Math.dot_product(ref_face_normal, inc_face[0]) - ref_c
    contacts = []

    penetration = 0

    if separation <= 0
      contacts << inc_face[0]
      penetration -= separation
    end

    separation = Stomp::Math.dot_product(ref_face_normal, inc_face[1]) - ref_c

    if separation <= 0
      contacts << inc_face[1]
      penetration -= separation

      penetration /= 1.0 * contacts.count if contacts.count > 1
    end

    nx, ny = normal

    [nx, ny, penetration, contacts]
  end

  def orthogonalize(v)
    return unless v
    x, y, *other = v
    [-y, x, *other]
  end

  # returns [normal_x, normal_y, penetration]
  def aabb_vs_aabb(a, b, type: AabbShape)
    return unless a[type] && b[type]

    nx, ny = [b[Position].x - a[Position].x,
              b[Position].y - a[Position].y]

    aex, aey = [(a[type].max_x - a[type].min_x) * 0.5,
                (a[type].max_y - a[type].min_y) * 0.5]

    bex, bey = [(b[type].max_x - b[type].min_x) * 0.5,
                (b[type].max_y - b[type].min_y) * 0.5]

    overx, overy = [aex + bex - nx.abs,
                    aey + bey - ny.abs]

    if overx > 0 && overy > 0
      if overx < overy

        if nx < 0
          [-1, 0, overx]
        else
          [1, 0, overx]
        end

      else

        if ny < 0
          [0, -1, overy]
        else
          [0, 1, overy]
        end

      end
    end
  end

  # returns [normal_x, normal_y, penetration]
  def aabb_vs_circle(a, b)
    return unless a[AabbShape] && b[CircleShape]

    nx, ny = [b[Position].x - a[Position].x - a[CircleShape].x,
              b[Position].y - a[Position].y - a[CircleShape].y]

    cx, cy = [nx, ny]

    ex, ey = [(a[AabbShape].max_x - a[AabbShape].min_x) * 0.5,
              (a[AabbShape].max_y - a[AabbShape].min_y) * 0.5]

    cx, cy = [clamp(cx, -ex, ex),
              clamp(cy, -ey, ey)]

    inside = false

    if [nx, ny] == [cx, cy]
      inside = true

      if nx.abs < ny.abs
        cx = cx > 0 ? ex : -ex
      else
        cy = cy > 0 ? ey : -ey
      end
    end

    norm_x, norm_y = [nx - cx,
                      ny - cy]

    d = norm_x ** 2 + norm_y ** 2
    r = b[CircleShape].r

    return if d > r ** 2 && !inside

    d = Math.sqrt(d)

    if inside
      [-norm_x, -norm_y, r + d]
    else
      [norm_x, norm_y, r - d]
    end
  end

  def clamp(x, min_x, max_x)
    return min_x if x < min_x
    return max_x if x > max_x
    x
  end

  # returns [normal_x, normal_y, penetration]
  def circle_vs_circle(a, b)
    return unless a[CircleShape] && b[CircleShape]

    nx, ny = [b[Position].x + b[CircleShape].x - a[Position].x - a[CircleShape].x,
              b[Position].y + b[CircleShape].x - a[Position].y - a[CircleShape].y]

    r = a[CircleShape].r + b[CircleShape].r
    r2 = r * r

    return if nx * nx + ny * ny > r2

    d = Math.sqrt(nx * nx + ny * ny)

    if d != 0
      contact = Stomp::Math.vadd(Stomp::Math.to_v(a[Position]),
                                 Stomp::Math.vmul([nx, ny], a[CircleShape].r))
      [nx / d, ny / d, r - d, [contact]]
    else
      [1, 0, a[CircleShape].r, [Stomp::Math.to_v(a[Position])]]
    end
  end

  def normalize(a)
    return unless a
    x, y, *other = a
    r = Math.sqrt(x ** 2 + y ** 2)
    return a if r == 0
    [x / r, y / r, *other]
  end

  def impulse_resolution(normal, a, b)
    return unless normal

    return infinite_mass_positional_correction(normal, a, b) if infinite_mass?(a) && infinite_mass?(b)

    a[Velocity] ||= Velocity[0, 0]
    b[Velocity] ||= Velocity[0, 0]

    a[AngularVelocity] ||= AngularVelocity[0]
    b[AngularVelocity] ||= AngularVelocity[0]

    a[Restitution] ||= Restitution[DEFAULT_RESTITUTION]
    b[Restitution] ||= Restitution[DEFAULT_RESTITUTION]

    a[Mass] ||= Mass[DEFAULT_MASS]
    b[Mass] ||= Mass[DEFAULT_MASS]

    a[Mass].inverted ||= a[Mass].value == 0 ? 0 : 1.0 / a[Mass].value
    b[Mass].inverted ||= b[Mass].value == 0 ? 0 : 1.0 / b[Mass].value

    a[Moment] ||= Moment[DEFAULT_MOMENT]
    b[Moment] ||= Moment[DEFAULT_MOMENT]

    a[Moment].inverted ||= a[Moment].value == 0 ? 0 : 1.0 / a[Moment].value
    b[Moment].inverted ||= b[Moment].value == 0 ? 0 : 1.0 / b[Moment].value

    # destructure normal
    nx, ny, _, contacts = normal

    contacts.each do |contact|

      # radius to contact points
      ra, rb = [normalize(Stomp::Math.vsub(contact, Stomp::Math.to_v(a[Position]))),
                normalize(Stomp::Math.vsub(contact, Stomp::Math.to_v(b[Position])))]

      # relative velocity
      #rvx, rvy = [b[Velocity].x - a[Velocity].y,
      #            b[Velocity].y - a[Velocity].y]
      # (b.velocity + cross[b.angular_velocity], rb) - (a.velocity + cross[a.angular_velocity, rb])

      rvx, rvy = Stomp::Math.vsub(Stomp::Math.vadd(Stomp::Math.to_v(b[Velocity]),
                                                   Stomp::Math.vmul_cross(b[AngularVelocity].value, rb)),

                                  Stomp::Math.vadd(Stomp::Math.to_v(a[Velocity]),
                                                   Stomp::Math.vmul_cross(b[AngularVelocity].value, ra)))

      # relative velocity projected on normal
      norm_vel = Stomp::Math.dot_product([rvx, rvy], [nx, ny])

      # do not resolve if objects are already separating
      return if norm_vel > 0

      # get restitution of collision
      e = [a[Restitution].value, b[Restitution].value].min

      ra_x_normal = Stomp::Math.cross_product((ra), [nx, ny])
      rb_x_normal = Stomp::Math.cross_product((rb), [nx, ny])

      inv_mass_sum = [a[Mass].inverted,
                      b[Mass].inverted,
                      a[Moment].inverted * (ra_x_normal ** 2),
                      b[Moment].inverted * (rb_x_normal ** 2)].inject(:+)

      # get impulse scalar
      j = -(1 + e) * norm_vel
      j /= 1.0 * inv_mass_sum * contacts.count

      # apply impulse
      ix, iy = [j * nx, j * ny]

      a[Velocity].x -= a[Mass].inverted * ix
      a[Velocity].y -= a[Mass].inverted * iy

      b[Velocity].x += b[Mass].inverted * ix
      b[Velocity].y += b[Mass].inverted * iy

      a[AngularVelocity].value -= a[Moment].inverted * Stomp::Math.cross_product(ra, [ix, iy])
      b[AngularVelocity].value += b[Moment].inverted * Stomp::Math.cross_product(rb, [ix, iy])

      #if Array === contacts
      #  contacts.each do |contact|
      #    contact_vector_a = Stomp::Math.vsub(Stomp::Math.to_v(a[Position]), contact)
      #    contact_vector_b = Stomp::Math.vsub(Stomp::Math.to_v(b[Position]), contact)
      #    a[AngularVelocity].value -= a[Moment].inverted * Stomp::Math.cross_product(contact_vector_b, [ix, iy])
      #    b[AngularVelocity].value += b[Moment].inverted * Stomp::Math.cross_product(contact_vector_b, [ix, iy])
      #  end
      #end

      apply_friction(normal, a, b, j, ra, rb, 1.0 * inv_mass_sum * contacts.count)

      positional_correction(normal, a, b)

    end

    contacts.count > 0

  end

  def apply_friction(normal, a, b, j, ra, rb, inv_mass_sum)
    a[StaticFriction] ||= StaticFriction[DEFAULT_STATIC_FRICTION]
    a[DynamicFriction] ||= DynamicFriction[DEFAULT_DYNAMIC_FRICTION]

    b[StaticFriction] ||= StaticFriction[DEFAULT_STATIC_FRICTION]
    b[DynamicFriction] ||= DynamicFriction[DEFAULT_DYNAMIC_FRICTION]

    nx, ny = normal

    rvx, rvy = Stomp::Math.vsub(Stomp::Math.vadd(Stomp::Math.to_v(b[Velocity]),
                                                 Stomp::Math.vmul_cross(b[AngularVelocity].value, rb)),

                                Stomp::Math.vadd(Stomp::Math.to_v(a[Velocity]),
                                                 Stomp::Math.vmul_cross(b[AngularVelocity].value, ra)))

    tx, ty = normalize([rvx - (rvx * nx + rvy * ny) * nx,
                        rvy - (rvx * nx + rvy * ny) * ny])

    jt = -(rvx * tx + rvy * ty)
    jt /= inv_mass_sum

    return if jt.abs < EPS

    mu = (a[StaticFriction].value + b[StaticFriction].value) * 0.5

    fix, fiy = if jt.abs < j * mu
                 [jt * tx, jt * ty]
               else
                 dmu = (a[DynamicFriction].value + b[DynamicFriction].value) * 0.5
                 [-j * tx * dmu, -j * ty * dmu]
               end

    a[Velocity].x -= a[Mass].inverted * fix
    a[Velocity].y -= a[Mass].inverted * fiy

    b[Velocity].x += b[Mass].inverted * fix
    b[Velocity].y += b[Mass].inverted * fiy

    a[AngularVelocity].value -= a[Moment].inverted * Stomp::Math.cross_product(ra, [fix, fiy])
    b[AngularVelocity].value += b[Moment].inverted * Stomp::Math.cross_product(rb, [fix, fiy])
  end

  def positional_correction(normal, a, b)
    nx, ny, penetration = normal

    inv_mass = a[Mass].inverted + b[Mass].inverted
    c = 1.0 * penetration * POSITIONAL_CORRECTION_SLOP / inv_mass * POSITIONAL_CORRECTION_PERCENTAGE
    cx, cy = [c * nx, c * ny]

    a[Position].x -= a[Mass].inverted * cx
    a[Position].y -= a[Mass].inverted * cy

    b[Position].x += b[Mass].inverted * cx
    b[Position].y += b[Mass].inverted * cy
  end

  def infinite_mass?(entity)
    entity[Mass] ||= Mass[DEFAULT_MASS]
    entity[Mass].inverted ||= Stomp::Math.inverted_mass(entity[Mass].value)
    entity[Mass].inverted == 0
  end

  def infinite_mass_positional_correction(normal, a, b)
    return infinite_vs_fixed_positional_correction(normal, a) if b[Fixed]
    return infinite_mass_positional_correction(normal, b, a) if a[Fixed]
    nx, ny, penetration = normal

    c = INFINITE_MASS_POSITIONAL_CORRECTION * penetration * 0.5
    cx, cy = [c * nx, c * ny]

    a[Position].x -= cx
    a[Position].y -= cy

    b[Position].x += cx
    b[Position].y += cy
  end

  def infinite_vs_fixed_positional_correction(normal, a)
    nx, ny, penetration = normal

    c = INFINITE_MASS_POSITIONAL_CORRECTION * penetration
    cx, cy = [c * nx, c * ny]

    a[Position].x -= cx
    a[Position].y -= cy

    a[InfiniteMassVsFixedBounce] ||= InfiniteMassVsFixedBounce[DEFAULT_INFINITE_MASS_VS_FIXED_BOUNCE]
    bounce = a[InfiniteMassVsFixedBounce].value

    v = Stomp::Math.to_v(a[Velocity])
    vrel = Stomp::Math.dot_product([nx, ny], v) * bounce
    dv = Stomp::Math.vmul([nx, ny], -vrel)

    a[Velocity].x += dv[0]
    a[Velocity].y += dv[1]
  end
end
