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
    draw_circles(Position, CircleShape, Gosu::Color::WHITE)
  end

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

  private

  def got(name, with: [])
    Stomp.logger.debug "event #{name}#{with}"
  end
end
