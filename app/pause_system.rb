class PauseSystem < Stomp::System
  def keystroke(id)
    return unless id == Gosu::KbP
    toggle_pause
  end

  private

  def toggle_pause
    return disable_pause if paused?
    enable_pause
  end

  def disable_pause
    Stomp::Component.each_entity(Pause) do |entity|
      entity.drop
    end
  end

  def enable_pause
    Stomp::Entity.new("Pause")[Pause] = Pause[]
  end

  def paused?
    Stomp::Component.each_entity(Pause) do |entity|
      return true
    end
    false
  end
end
