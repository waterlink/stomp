module Stomp
  class Window < Gosu::Window
    def initialize
      super(width, height, fullscreen?)
      self.caption = title
      load_systems!
    end

    def update
      systems.each(&:update)
    end

    def draw
      systems.each(&:draw)
    end

    private

    def load_systems!
      systems.map! do |name|
        require(name)
        constantize(name)[self]
      end
    end

    def camel_cased(name)
      name
        .to_s
        .capitalize
        .gsub(/_([a-z])/) { $1.upcase }
    end

    def constantize(name)
      Object.const_get(camel_cased(name))
    end

    def title
      @_title ||= Stomp.config[:window][:title]
    end

    def width
      @_width ||= Stomp.config[:window][:width]
    end

    def height
      @_height ||= Stomp.config[:window][:height]
    end

    def fullscreen?
      @_fullscreen ||= Stomp.config[:window][:fullscreen]
    end

    def systems
      @_systems ||= Stomp.config[:systems]
    end
  end
end
