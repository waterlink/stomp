class DebugSystem < Stomp::System
  DEBUG_Z = 100000

  def keystroke(*args)
    got(:keystroke, with: args)
  end

  def mouse_click(*args)
    got(:mouse_click, with: args)
  end

  def mouse_move(*args)
    got(:mouse_move, with: args)
  end

  def update(dt)
    Stomp::Component.each_entity(UnderPlayerControl) do |entity|
      puts "Player Position: #{entity[Position]}"
    end
  end

  def draw
    draw_vectors(Position, Velocity, Gosu::Color::GREEN, Gosu::Color::RED, 5)
    draw_vectors(Position, Acceleration, Gosu::Color::BLUE, Gosu::Color::YELLOW, 1)
    draw_forces(Gosu::Color::YELLOW, Gosu::Color::WHITE, 0.05)
    #draw_circles(Position, CircleShape, Gosu::Color::WHITE)
    #draw_aabbs(Position, AabbShape, Gosu::Color::WHITE)

    draw_rigids(Gosu::Color::WHITE)

    if defined?(BondSystem) && BondSystem.instance
      BondSystem.instance.handle_bond_links(BondThread) { |_, a, b| draw_thread(a, b) }
    end
  end

  private

  def shape_from(entity)
    return [] unless entity[RigidShape]
    return entity[RigidShape].vertices unless entity[Orient]
    Stomp::Math.shape_from(entity[RigidShape].vertices, entity[Orient].value)
  end

  def draw_rigids(color)
    Stomp::Component.each_entity(RigidShape) do |entity|
      next unless entity[Position]

      ox, oy = entity.get_world.position(entity[Position].x, entity[Position].y)

      shape_from(entity).each_cons(2) do |v1, v2|

        x1, y1 = entity.get_world.relative_position(*v1)
        x2, y2 = entity.get_world.relative_position(*v2)

        (x1, y1), (x2, y2) = Stomp::Math.fadd([[x1, y1], [x2, y2]],
                                              [ox, oy])

        window.draw_line(x1, y1, color,
                         x2, y2, color,
                         DEBUG_Z)

      end
    end
  end

  def draw_vectors(origin, vector, color_a, color_b, scale)
    Stomp::Component.each_entity(vector) do |entity|
      next unless entity[origin]
      x, y = entity.get_world.position(entity[origin].x, entity[origin].y)
      vx, vy = entity.get_world.relative_position(entity[vector].x, entity[vector].y)
      window.draw_line(x,
                       y,
                       color_a,
                       x + vx * scale,
                       y + vy * scale,
                       color_b,
                       DEBUG_Z)
    end
  end

  def draw_forces(color_a, color_b, scale)
    Stomp::Component.each_entity(ForceParts) do |entity|
      next unless entity[Position]
      entity[ForceParts].parts.each do |part|
        next unless part
        x, y = entity.get_world.position(entity[Position].x, entity[Position].y)
        dx, dy = entity.get_world.relative_position(part[0], part[1])
        window.draw_line(x,
                         y,
                         color_a,
                         x + dx * scale,
                         y + dy * scale,
                         color_b,
                         DEBUG_Z)
      end
    end
  end

  def draw_circles(origin, shape, color)
    Stomp::Component.each_entity(shape) do |entity|
      next unless entity[origin]
      Stomp::Draw.circle(window,
                         entity[origin].x + entity[shape].x,
                         entity[origin].y + entity[shape].y,
                         DEBUG_Z,
                         entity[shape].r,
                         color)
    end
  end

  def draw_aabbs(origin, shape, color)
    Stomp::Component.each_entity(shape) do |entity|
      next unless entity[origin]
      draw_aabb(entity[origin], entity[shape], color)
    end
  end

  def draw_aabb(origin, shape, color)
    [[shape.min_x, shape.min_y],
     [shape.max_x, shape.min_y],
     [shape.max_x, shape.max_y],
     [shape.min_x, shape.max_y],
     [shape.min_x, shape.min_y]].each_cons(2) do |(x1, y1), (x2, y2)|
      window.draw_line(origin.x + x1,
                       origin.y + y1,
                       color,
                       origin.x + x2,
                       origin.y + y2,
                       color,
                       DEBUG_Z)
    end
  end

  def draw_thread(a, b)
    origin = Position
    vector = Bond
    color_b = color_a = Gosu::Color::WHITE

    entity = a
    ax, ay = entity.get_world
      .position(entity[origin].x + entity[vector].x, entity[origin].y + entity[vector].y)

    entity = b
    bx, by = entity.get_world
      .position(entity[origin].x + entity[vector].x, entity[origin].y + entity[vector].y)

    window.draw_line(ax,
                     ay,
                     color_a,
                     bx,
                     by,
                     color_b,
                     DEBUG_Z)
  end

  def got(name, with: [])
    Stomp.logger.debug "event #{name}#{with}"
  end
end
