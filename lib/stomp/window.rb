module Stomp
  class Window < Gosu::Window
    def initialize(systems)
      super(width, height, fullscreen?)
    end

    def width
      @width ||= 800
    end

    def height
      @height ||= 600
    end

    def fullscreen?
      @fullscreen ||= false
    end

    def update
    end

    def draw
    end
  end
end
