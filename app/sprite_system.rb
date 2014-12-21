class SpriteSystem < Stomp::System
  def draw
    Stomp::Component.each_entity(Sprite) do |entity|
      entity[Position] ||= Position[0, 0]
      entity[LayerIndex] ||= LayerIndex[0]
      entity[Size] ||= Size[0, 0]

      draw_sprite(entity[Sprite].path,
                  entity[Position].x,
                  entity[Position].y,
                  entity[Size].x,
                  entity[Size].y,
                  entity[LayerIndex].value,
                  world_for(entity))
    end
  end

  private

  def world_for(entity)
    Stomp::World.from_name(entity.world)
  end

  def draw_sprite(path, x, y, w, h, layer, world)
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
               sized)
  end

  def draw_image(path, x1, y1, x2, y2, z, sized)
    return draw_unsized_image(path, x1, y1, z) unless sized
    color = Gosu::Color::WHITE
    sprite(path).draw_as_quad(x1, y1, color,
                              x2, y1, color,
                              x2, y2, color,
                              x1, y2, color,
                              z)
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
