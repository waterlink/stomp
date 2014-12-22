class MenuSystem < Stomp::System
  def update(dt)
    each_menu_item do |entity|
      next if initialized?(entity)
      switch_states(entity, window.mouse_x, window.mouse_y)
    end
  end

  def mouse_move(_, _, x, y)
    each_menu_item do |entity|
      next unless has_bounding_box?(entity)
      switch_states(entity, x, y)
    end
  end

  def mouse_click(id, x, y)
    each_menu_item do |entity|
      apply_action(entity, x, y)
    end
  end

  private

  def each_menu_item(&blk)
    Stomp::Component.each_entity(MenuItem, &blk)
  end

  def switch_states(entity, x, y)
    apply_nonhover(entity, x, y)
    apply_hover(entity, x, y)
  end

  def apply_action(entity, x, y)
    return unless entity[MenuItem].hovered
    _apply_action(Stomp::Entity.new, entity[MenuItem].action)
  end

  def apply_nonhover(entity, x, y)
    return if inside_bounding_box?(x, y, entity) || nonhovered?(entity)
    apply_state(entity, false, entity[MenuItem].nonhover)
  end

  def apply_hover(entity, x, y)
    return if !inside_bounding_box?(x, y, entity) || hovered?(entity)
    apply_state(entity, true, entity[MenuItem].hover)
  end

  def apply_state(entity, hovered, hash_component)
    _apply_action(entity, hash_component)
    entity[MenuItem].hovered = hovered
  end

  def _apply_action(entity, hash_component)
    return unless hash_component
    entity.with_hash_components([hash_component])
  end

  def nonhovered?(entity)
    entity[MenuItem].hovered == false
  end

  def hovered?(entity)
    entity[MenuItem].hovered == true
  end

  def has_bounding_box?(entity)
    entity[Position] && entity[Size]
  end

  def initialized?(entity)
    !entity[MenuItem].hovered.nil?
  end

  def inside_bounding_box?(x, y, entity)
    px, py = entity.get_world.position(*(Stomp::Math.to_v(entity[Position])))
    w, h = entity.get_world.size(*(Stomp::Math.to_v(entity[Size])))

    Stomp::Math.inside_bounding_box?(x, y, px, py, w, h)
  end
end
