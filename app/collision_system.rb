class CollisionSystem < Stomp::System
  DEFAULT_RESTITUTION = 1.0
  DEFAULT_MASS = 5
  DEFAULT_STATIC_FRICTION = 0.7
  DEFAULT_DYNAMIC_FRICTION = 0.3

  POSITIONAL_CORRECTION_PERCENTAGE = 0.8
  POSITIONAL_CORRECTION_SLOP = 0.999999

  EPS = 1e-7

  def update(dt)
    Stomp::Component.each_entity(CollisionShape) do |entity|
      Stomp::Component.each_entity(CollisionShape) do |other|
        next if other == entity
        resolve_collision(entity, other)
      end
    end
  end

  private

  def resolve_collision(a, b)
    impulse_resolution(collision_normal(a, b), a, b)
  end

  def support_point(shape, direction)
    shape.map { |vertex| [Stomp::Math.dot_product(direction, vertex), vertex]}.max
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
      vx, vy = [vx + pos_a[0] - pos_b[0], vy + pos_a[1] - pos_b[1]]
      svx, svy = [sx - vx, sy - vy]
      d = Stomp::Math.dot_product([nx, ny], [svx, svy])
      [d, face]
    }.max
  end

  def find_incident_face(ref_shape, inc_shape, ref_face)
    ref_normal = get_normal(ref_face, [0, 0])

    min_dot, inc_face = inc_shape[RigidShape].vertices.each_cons(2).map do |face|
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

    #puts [n, c, face].inspect
    #puts [d1, d2].inspect

    return [face[0], face[1]] if (d1 - d2).abs < EPS

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
              circle_vs_rigid(b, a) ||
              rigid_vs_rigid(a, b) ||
              rigid_vs_rigid(b, a))
  end

  # returns [nx, ny, penetration, contacts]
  def circle_vs_rigid(a, b)
    if b[AabbShape] && !b[RigidShape]
      s = b[AabbShape]
      x1, y1, x2, y2 = [s.min_x, s.min_y, s.max_x, s.max_y]
      b[RigidShape] ||= RigidShape[[[x1, y1],
                                    [x1, y2],
                                    [x2, y2],
                                    [x2, y1],
                                    [x1, y1]]]
    end

    return unless a[CircleShape] && b[RigidShape]

    cx, cy = [a[Position].x + a[CircleShape].x - b[Position].x,
              a[Position].y + a[CircleShape].y - b[Position].y]

    radius = a[CircleShape].r
    radius2 = radius ** 2

    s, face, normal = b[RigidShape].vertices.each_cons(2).map { |face|
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

    if a[AabbShape] && !a[RigidShape]
      s = a[AabbShape]
      x1, y1, x2, y2 = [s.min_x, s.min_y, s.max_x, s.max_y]
      a[RigidShape] ||= RigidShape[[[x1, y1],
                                    [x1, y2],
                                    [x2, y2],
                                    [x2, y1],
                                    [x1, y1]]]
    end

    if b[AabbShape] && !b[RigidShape]
      s = b[AabbShape]
      x1, y1, x2, y2 = [s.min_x, s.min_y, s.max_x, s.max_y]
      b[RigidShape] ||= RigidShape[[[x1, y1],
                                    [x1, y2],
                                    [x2, y2],
                                    [x2, y1],
                                    [x1, y1]]]
    end

    return unless a[RigidShape] && b[RigidShape]

    penetration_a, face_a = axis_least_penetration(Stomp::Math.to_v(a[Position]),
                                                   a[RigidShape].vertices,
                                                   Stomp::Math.to_v(b[Position]),
                                                   b[RigidShape].vertices)

    penetration_b, face_b = axis_least_penetration(Stomp::Math.to_v(b[Position]),
                                                   b[RigidShape].vertices,
                                                   Stomp::Math.to_v(a[Position]),
                                                   a[RigidShape].vertices)

    return if penetration_b >= 0 ||
      penetration_a >= 0

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
  def aabb_vs_aabb(a, b)
    return unless a[AabbShape] && b[AabbShape]

    nx, ny = [b[Position].x - a[Position].x,
              b[Position].y - a[Position].y]

    aex, aey = [(a[AabbShape].max_x - a[AabbShape].min_x) * 0.5,
                (a[AabbShape].max_y - a[AabbShape].min_y) * 0.5]

    bex, bey = [(b[AabbShape].max_x - b[AabbShape].min_x) * 0.5,
                (b[AabbShape].max_y - b[AabbShape].min_y) * 0.5]

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
      [nx / d, ny / d, r - d]
    else
      [1, 0, a[CircleShape].r]
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

    a[Velocity] ||= Velocity[0, 0]
    b[Velocity] ||= Velocity[0, 0]

    a[Restitution] ||= Restitution[DEFAULT_RESTITUTION]
    b[Restitution] ||= Restitution[DEFAULT_RESTITUTION]

    a[Mass] ||= Mass[DEFAULT_MASS]
    b[Mass] ||= Mass[DEFAULT_MASS]

    a[Mass].inverted ||= a[Mass].value == 0 ? 0 : 1.0 / a[Mass].value
    b[Mass].inverted ||= b[Mass].value == 0 ? 0 : 1.0 / b[Mass].value

    # relative velocity
    rvx, rvy = [b[Velocity].x - a[Velocity].y,
                b[Velocity].y - a[Velocity].y]

    # destructure normal
    nx, ny = normal

    # relative velocity normalized
    norm_vel = rvx * nx + rvy * ny

    # do not resolve if objects are already separating
    return if norm_vel > 0

    # get restitution of collision
    e = [a[Restitution].value, b[Restitution].value].min

    # get impulse scalar
    j = -(1 + e) * norm_vel
    j /= a[Mass].inverted + b[Mass].inverted

    # apply impulse
    ix, iy = [j * nx,
              j * ny]

    a[Velocity].x -= a[Mass].inverted * ix
    a[Velocity].y -= a[Mass].inverted * iy

    b[Velocity].x += b[Mass].inverted * ix
    b[Velocity].y += b[Mass].inverted * iy

    apply_friction(normal, a, b, j)

    positional_correction(normal, a, b)

  end

  def apply_friction(normal, a, b, j)
    a[StaticFriction] ||= StaticFriction[DEFAULT_STATIC_FRICTION]
    a[DynamicFriction] ||= DynamicFriction[DEFAULT_DYNAMIC_FRICTION]

    b[StaticFriction] ||= StaticFriction[DEFAULT_STATIC_FRICTION]
    b[DynamicFriction] ||= DynamicFriction[DEFAULT_DYNAMIC_FRICTION]

    nx, ny = normal

    rvx, rvy = [b[Velocity].x - a[Velocity].x,
                b[Velocity].y - a[Velocity].y]

    tx, ty = normalize([rvx - (rvx * nx + rvy * ny) * nx,
                        rvy - (rvx * nx + rvy * ny) * ny])

    jt = -(rvx * tx + rvy * ty)
    jt /= a[Mass].inverted + b[Mass].inverted

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
  end

  def positional_correction(normal, a, b)
    nx, ny, penetration = normal

    puts "penetration: #{penetration}"

    inv_mass = a[Mass].inverted + b[Mass].inverted
    c = 1.0 * penetration * POSITIONAL_CORRECTION_SLOP / inv_mass * POSITIONAL_CORRECTION_PERCENTAGE
    cx, cy = [c * nx, c * ny]

    puts "correction by #{[cx, cy]}"

    a[Position].x -= a[Mass].inverted * cx
    a[Position].y -= a[Mass].inverted * cy

    b[Position].x += b[Mass].inverted * cx
    b[Position].y += b[Mass].inverted * cy
  end
end
