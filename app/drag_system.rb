class DragSystem < Stomp::System
  DRAG_FORCE_BASE = 5.0
  DEFAULT_MASS = 5

  def update(dt)
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
      entity[ForceParts].parts[ForceParts::DRAG] = nil
    end
  end

  private

  def move(entity, x, y)
    entity[Position] ||= Position[0, 0]
    entity[ForceParts] ||= ForceParts[[]]
    entity[Mass] ||= Mass[DEFAULT_MASS]

    mx, my = world_mouse(x, y, Stomp::World.from_name(entity.world))

    k = DRAG_FORCE_BASE * entity[Mass].value

    entity[ForceParts].parts[ForceParts::DRAG] = [(mx - entity[Position].x) * k,
                                                  (my - entity[Position].y) * k]
  end

  def start_dragging(entity, x, y)
    return unless inside_bounding_box?(x, y, entity)
    entity[DraggedByMouse] = DraggedByMouse[]
  end

  def inside_bounding_box?(x, y, entity)
    entity[Position] ||= Position[0, 0]
    entity[Size] ||= Size[0, 0]
    _inside_bounding_box?(x, y,
                          entity[Position], entity[Size],
                          Stomp::World.from_name(entity.world))
  end

  def _inside_bounding_box?(x, y, position, size, world)
    mx, my = world_mouse(x, y, world)
    Stomp::Math.inside_bounding_box?(mx, my,
                                     position.x, position.y,
                                     size.x, size.y)
  end

  def world_mouse(x, y, world)
    ox, oy = world.origin
    x_axis, y_axis = world.axes
    zoom = 1.0 * world.zoom

    [(x - ox) / zoom * x_axis,
     (y - oy) / zoom * y_axis]
  end
end
