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

  def draw
    draw_vectors(Position, Velocity, Gosu::Color::GREEN, Gosu::Color::RED, 20)
    draw_vectors(Position, Acceleration, Gosu::Color::BLUE, Gosu::Color::YELLOW, 50)
    draw_forces(Gosu::Color::YELLOW, Gosu::Color::WHITE, 0.5)
    draw_circles(Position, CircleShape, Gosu::Color::WHITE)
    draw_aabbs(Position, AabbShape, Gosu::Color::WHITE)

    if defined?(BondSystem) && BondSystem.instance
      BondSystem.instance.handle_bond_links(BondThread) { |_, a, b| draw_thread(a, b) }
    end
  end

  private

  def draw_vectors(origin, vector, color_a, color_b, scale)
    Stomp::Component.each_entity(vector) do |entity|
      next unless entity[origin]
      window.draw_line(entity[origin].x,
                       entity[origin].y,
                       color_a,
                       entity[origin].x + entity[vector].x * scale,
                       entity[origin].y + entity[vector].y * scale,
                       color_b,
                       DEBUG_Z)
    end
  end

  def draw_forces(color_a, color_b, scale)
    Stomp::Component.each_entity(ForceParts) do |entity|
      next unless entity[Position]
      entity[ForceParts].parts.each do |part|
        next unless part
        window.draw_line(entity[Position].x,
                         entity[Position].y,
                         color_a,
                         entity[Position].x + part[0] * scale,
                         entity[Position].y + part[1] * scale,
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

    puts "draw_thread#{[a[Bond], b[Bond]]}"

    window.draw_line(a[origin].x + a[vector].x,
                     a[origin].y + a[vector].y,
                     color_a,
                     b[origin].x + b[vector].x,
                     b[origin].y + b[vector].y,
                     color_b,
                     DEBUG_Z)
  end

  def got(name, with: [])
    Stomp.logger.debug "event #{name}#{with}"
  end
end
