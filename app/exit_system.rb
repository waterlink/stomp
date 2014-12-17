class ExitSystem < Stomp::System
  def update
    Stomp::Component.each_entity(ExitAction) do |entity|
      window.close
    end
  end
end
