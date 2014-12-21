class ExitSystem < Stomp::System
  def update(dt)
    Stomp::Component.each_entity(ExitAction) do |entity|
      window.close
    end
  end
end
