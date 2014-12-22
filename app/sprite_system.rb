class SpriteSystem < Stomp::System
  def draw
    Stomp::Component.each_entity(Sprite) do |entity|
      entity[Position] ||= Position[0, 0]
      entity[LayerIndex] ||= LayerIndex[0]
      entity[Size] ||= Size[0, 0]
      entity[Orient] ||= Orient[0]

      draw_sprite(entity[Sprite].path,
                  entity[Position].x,
                  entity[Position].y,
                  entity[Size].x,
                  entity[Size].y,
                  entity[LayerIndex].value,
                  entity[Orient].value,
                  world_for(entity))
    end
  end

  private

  def world_for(entity)
    Stomp::World.from_name(entity.world)
  end

  def draw_sprite(path, x, y, w, h, layer, angle, world)
    x_axis, y_axis = world.axes
    ox, oy = world.origin
    zoom = world.zoom

    sized = w * h > 0

    draw_image(path,
               (x * x_axis - w / 2) * zoom + ox,
               (y * y_axis - h / 2) * zoom + oy,
               (x * x_axis + w / 2) * zoom + ox,
               (y * y_axis + h / 2) * zoom + oy,
               layer,
               angle,
               sized)
  end

  def draw_image(path, x1, y1, x2, y2, z, angle, sized)
    return draw_unsized_image(path, x1, y1, z) unless sized
    color = Gosu::Color::WHITE

    (x1, y1), (x2, y2), (x3, y3), (x4, y4) = rotate_rect(x1, y1, x2, y2, angle)

    sprite(path).draw_as_quad(x1, y1, color,
                              x2, y2, color,
                              x3, y3, color,
                              x4, y4, color,
                              z)
  end

  def rotate_rect(x1, y1, x2, y2, angle)
    o = [(x1 + x2) * 0.5, (y1 + y2) * 0.5]
    rx1, ry1 = Stomp::Math.rotate_point([x1, y1], o, angle)
    rx2, ry2 = Stomp::Math.rotate_point([x2, y1], o, angle)
    rx3, ry3 = Stomp::Math.rotate_point([x2, y2], o, angle)
    rx4, ry4 = Stomp::Math.rotate_point([x1, y2], o, angle)
    [[rx1, ry1],
     [rx2, ry2],
     [rx3, ry3],
     [rx4, ry4]]
  end

  def draw_unsized_image(path, x, y, z)
    sprite(path).draw(x, y, z)
  end

  def sprite(path)
    sprites[path] ||= load_sprite(sprite_path(path))
  end

  def load_sprite(path)
    ensure_sprite_exists(path)
    Gosu::Image.new(window, path, true)
  end

  def ensure_sprite_exists(path)
    return if File.exists?(path)
    raise LoadError, "Sprite #{path} not found"
  end

  def sprites
    @_sprites ||= {}
  end

  def sprite_path(path)
    "resources/sprites/#{path}"
  end
end
