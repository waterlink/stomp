class SpriteSystem < Stomp::System
  def draw
    Stomp::Component.each_entity(Sprite) do |entity|
      next if entity[PauseOnly] && paused?

      entity[Position] ||= Position[0, 0]
      entity[LayerIndex] ||= LayerIndex[0]
      entity[Size] ||= Size[0, 0]

      draw_sprite(entity[Sprite].path,
                  entity[Position].x,
                  entity[Position].y,
                  entity[Size].x,
                  entity[Size].y,
                  entity[LayerIndex].value)
    end
  end

  private

  def draw_sprite(path, x, y, w, h, layer)
    sprite(path).draw(x - w / 2, y - h / 2, layer)
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

  def paused?
    
  end

  def sprites
    @_sprites ||= {}
  end

  def sprite_path(path)
    "resources/sprites/#{path}"
  end
end
