class DragSystem < Stomp::System
  def update
    Stomp::Component.each_entity(DraggedByMouse) do |entity|
      move(entity, window.mouse_x, window.mouse_y)
    end
  end

  def mouse_down(id, x, y)
    Stomp::Component.each_entity(DragByMouse) do |entity|
      start_dragging(entity, x, y)
    end
  end

  def mouse_click(id, x, y)
    Stomp::Component.each_entity(DraggedByMouse) do |entity|
      entity.remove(DraggedByMouse)
      entity.remove(Force)
    end
  end

  private

  def move(entity, x, y)
    entity[Position] ||= Position[0, 0]
    entity[Force] ||= Force[]
    entity[Force].x = x - entity[Position].x
    entity[Force].y = y - entity[Position].y
  end

  def start_dragging(entity, x, y)
    return unless inside_bounding_box?(x, y, entity)
    entity[DraggedByMouse] = DraggedByMouse[]
  end

  def inside_bounding_box?(x, y, entity)
    entity[Position] ||= Position[0, 0]
    entity[Size] ||= Size[0, 0]
    _inside_bounding_box?(x, y, entity[Position], entity[Size])
  end

  def _inside_bounding_box?(x, y, position, size)
    Stomp::Math.inside_bounding_box?(x, y, position.x, position.y, size.x, size.y)
  end
end
