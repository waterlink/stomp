class CollisionSystem < Stomp::System
  DEFAULT_RESTITUTION = 0.8
  DEFAULT_MASS = 5

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
    circle_vs_circle(a, b)
  end

  # returns [normal_x, normal_y, penetration]
  def circle_vs_circle(a, b)
    return unless a[CircleShape] && b[CircleShape]
    return unless a[Position] && b[Position]

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

  def impulse_resolution(normal, a, b)
    return unless normal

    a[Velocity] ||= Velocity[0, 0]
    b[Velocity] ||= Velocity[0, 0]

    a[Restitution] ||= Restitution[DEFAULT_RESTITUTION]
    b[Restitution] ||= Restitution[DEFAULT_RESTITUTION]

    a[Mass] ||= Mass[DEFAULT_MASS]
    b[Mass] ||= Mass[DEFAULT_MASS]

    a[Mass].inverted ||= 1.0 / a[Mass].value
    b[Mass].inverted ||= 1.0 / b[Mass].value

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
  end
end
