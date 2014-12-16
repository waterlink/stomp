class MouseArrowSystem < Stomp::System
  def mouse_move(_, _, x, y)
    move_arrow_to(x, y)
  end

  private

  def move_arrow_to(x, y)
    Stomp::Component.each_entity(MouseArrow) do |entity|
      entity[Position] ||= Position[0, 0]
      change_position(entity[Position], x, y)
    end
  end

  def change_position(position, x, y)
    position.x = x
    position.y = y
  end
end
