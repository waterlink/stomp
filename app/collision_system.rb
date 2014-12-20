class CollisionSystem < Stomp::System
  DEFAULT_RESTITUTION = 0.9
  DEFAULT_MASS = 5
  DEFAULT_STATIC_FRICTION = 0.7
  DEFAULT_DYNAMIC_FRICTION = 0.3

  POSITIONAL_CORRECTION_PERCENTAGE = 0.8
  POSITIONAL_CORRECTION_SLOP = 0.999999

  def update
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

  def collision_normal(a, b)
    return unless a[Position] && b[Position]
    normalize(circle_vs_circle(a, b) ||
              aabb_vs_circle(a, b))
  end

  # returns [normal_x, normal_y, penetration]
  def aabb_vs_circle(a, b)
    return unless a[AabbShape] && b[CircleShape]

    nx, ny = [b[Position].x - a[Position].x,
              b[Position].y - a[Position].y]

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

    nx, ny = [b[Position].x - a[Position].x,
              b[Position].y - a[Position].y]

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
    puts normal.inspect
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

    puts normal.inspect

    inv_mass = a[Mass].inverted + b[Mass].inverted
    c = [1.0 * penetration * POSITIONAL_CORRECTION_SLOP, 0.0].max / inv_mass * POSITIONAL_CORRECTION_PERCENTAGE
    cx, cy = [c * nx, c * ny]

    a[Position].x -= a[Mass].inverted * cx
    a[Position].y -= a[Mass].inverted * cy

    b[Position].x += b[Mass].inverted * cx
    b[Position].y += b[Mass].inverted * cy
  end
end
