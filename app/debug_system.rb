class DebugSystem < Stomp::System
  def keystroke(*args)
    got(:keystroke, with: args)
  end

  def mouse_click(*args)
    got(:mouse_click, with: args)
  end

  def mouse_move(*args)
    got(:mouse_move, with: args)
  end

  private

  def got(name, with: [])
    Stomp.logger.debug "event #{name}#{with}"
  end
end
