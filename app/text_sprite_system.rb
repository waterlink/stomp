class TextSpriteSystem < Stomp::System
  def draw
    with_entity do |entity|
      draw_sprite(entity)
    end
  end

  private

  def with_entity(&blk)
    Stomp::Component.each_entity(TextSprite, &blk)
  end

  def draw_sprite(entity)
    TextSpriteWrapper[entity, window].draw
  end

  class TextSpriteWrapper < Struct.new(:entity, :window)
    def draw
      each_letter(&method(:draw_letter))
    end

    private

    def each_letter(&blk)
      letters.each_char.each_with_index(&blk)
    end

    def draw_letter(letter, index)
      specific_letter_sprite(letter, index, size).draw
    end

    def specific_letter_sprite(letter, index, size)
      letter_sprite
        .with_letter(letter, index, size)
        .within(window)
    end

    def letter_sprite
      @_letter_sprite ||= LetterSprite[entity]
    end

    def letters
      value.to_s
    end

    def size
      letters.size
    end

    def value
      target.value
    end

    def target
      @_target ||= entity[component]
    end

    def component
      sprite_definition.component
    end

    def sprite_definition
      @_sprite_definition ||= entity[TextSprite]
    end
  end

  class LetterSprite < Struct.new(:entity, :letter, :index, :size, :window)
    ALIGNED_OFFSET_STRATEGIES = {
      "left" => -> (index, size) { index },
      "right" => -> (index, size) { index - size },
    }

    def self.sprite(window, path)
      sprites[path] ||= load_sprite(window, path)
    end

    def self.sprites
      @_sprites ||= {}
    end

    def self.load_sprite(window, path)
      ensure_sprite_exists(path)
      Gosu::Image.new(window, path, true)
    end

    def self.ensure_sprite_exists(path)
      return if File.exists?(path)
      raise LoadError, "Sprite #{path} not found"
    end

    def draw
      draw_sprite
    end

    def with_letter(letter, index, size)
      self.letter = letter
      self.index = index
      self.size = size
      self
    end

    def within(window)
      self.window = window
      self
    end

    private

    def draw_sprite
      color = Gosu::Color::WHITE
      (x1, y1), (x2, y2), (x3, y3), (x4, y4) = aabb

      sprite.draw_as_quad(x1, y1, color,
                          x2, y2, color,
                          x3, y3, color,
                          x4, y4, color,
                          layer)
    end

    def sprite
      self.class.sprite(window, path)
    end

    def path
      paths[letter] ||= path_from_local_rule || path_from_global_rule
    end

    def paths
      @_paths ||= {}
    end

    def path_from_local_rule
      local_rules.rules[letter]
    end

    def path_from_global_rule
      with_global_rule do |path|
        return sprite_path(path) if path
      end
      nil
    end

    def sprite_path(path)
      "resources/sprites/#{path}"
    end

    def with_global_rule(&blk)
      Stomp::Component.each_entity(TextRenderingRules) do |e|
        blk[e[TextRenderingRules].rules[letter]]
      end
    end

    def local_rules
      @_local_rules ||= entity[TextRenderingRules] ||= TextRenderingRules[{}]
    end

    def aabb
      min_x, min_y = entity_position
      min_x += aligned_offset
      w, h = format_size
      max_x, max_y = Stomp::Math.vadd([min_x, min_y], [w, h])
      Stomp::Math.rotate_rect(min_x, min_y, max_x, max_y, entity_angle, entity_position)
    end

    def format_size
      format.size
    end

    def format
      @_format ||= entity[TextFormat]
    end

    def aligned_offset
      full_format_size * ALIGNED_OFFSET_STRATEGIES[format_align][index, size]
    end

    def full_format_size
      format_size[0] + format_margin
    end

    def format_margin
      format.margin
    end

    def format_align
      format.align
    end

    def entity_position
      @_entity_position ||= Stomp::Math.to_v(entity[Position])
    end

    def entity_angle
      @_entity_angle ||= (entity[Orient] ||= Orient[0]).value
    end

    def layer
      @_entity_layer ||= entity[LayerIndex].value
    end

  end
end
