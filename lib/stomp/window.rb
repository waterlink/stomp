module Stomp
  class Window < Gosu::Window
    FPS = 120
    DT = 1.0 / FPS
    MAX_PASSED_TIME = 0.3

    def initialize
      super(width, height, fullscreen?)
      self.caption = title
      init_worlds
      load_systems!
    end

    def update
      full_systems_update
      propagate_mouse_move
      remember_mouse_position
    end

    def draw
      systems.each(&:draw)
    end

    def button_down(id)
      propagate_keystroke(id)
      propagate_mouse_down(id)
    end

    def button_up(id)
      propagate_key_up(id)
      propagate_mouse_click(id)
    end

    private

    attr_reader :old_mouse_x, :old_mouse_y, :previous_now

    def full_systems_update
      reset_time_passed
      passed = time_passed
      return first_systems_update unless passed
      while passed >= DT
        passed -= DT
        systems_update
      end
      remember_previous_now(passed)
    end

    def first_systems_update
      systems_update
      remember_previous_now(0)
    end

    def systems_update
      systems.each { |s| s.update(DT) }
    end

    def time_passed
      return unless previous_now
      @_time_passed ||= [now - previous_now, MAX_PASSED_TIME].min
    end

    def reset_time_passed
      @_time_passed = nil
    end

    def now
      Gosu.milliseconds / 1000.0
    end

    def remember_previous_now(correction)
      @previous_now = now - correction
    end

    def propagate_mouse_click(id)
      return unless mouse_button?(id)
      systems.each { |x| x.mouse_click(id, mouse_x, mouse_y) }
    end

    def propagate_mouse_down(id)
      return unless mouse_button?(id)
      systems.each { |x| x.mouse_down(id, mouse_x, mouse_y) }
    end

    def mouse_button?(id)
      id == Gosu::MsLeft
    end

    def propagate_keystroke(id)
      systems.each { |x| x.keystroke(id) }
    end

    def propagate_key_up(id)
      systems.each { |x| x.key_up(id) }
    end

    def propagate_mouse_move
      return unless mouse_moved?
      systems.each do |system|
        system.mouse_move(old_mouse_x, old_mouse_y, mouse_x, mouse_y)
      end
    end

    def mouse_moved?
      old_mouse_x && old_mouse_y &&
        [old_mouse_x, old_mouse_y] != [mouse_x, mouse_y]
    end

    def remember_mouse_position
      @old_mouse_x = mouse_x
      @old_mouse_y = mouse_y
    end

    def init_worlds
      Stomp::World.setup(common_world: common_world, active_world: default_world)
    end

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

    def default_world
      @_default_world ||= Stomp.config[:default_world]
    end

    def common_world
      @_common_world ||= Stomp.config[:common_world]
    end
  end
end
