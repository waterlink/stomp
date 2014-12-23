class AnimationSystem < Stomp::System
  def update(dt)
    Stomp::Component.each_entity(Animation) do |entity|
      AnimationEntity[entity].animate(dt)
    end
  end

  private

  class AnimationEntity < Struct.new(:entity)

    def animate(dt)
      _animate
      advance_time(dt)
    end

    private

    def _animate
      entity.with_hash_components([frame])
    end

    def frame
      @_frame ||= frames[frame_number]
    end

    def frames
      animation.frames
    end

    def animation
      @_animation ||= entity[Animation]
    end

    def frame_number
      possible_frame_numbers.min
    end

    def frame_size
      1.0 * length / frames.count
    end

    def length
      animation.length
    end

    def time
      animation.time ||= 0
    end

    def supposed_frame_number
      (time / frame_size).to_i
    end

    def last_frame_number
      frames.count - 1
    end

    def possible_frame_numbers
      [supposed_frame_number, last_frame_number]
    end

    def advance_time(dt)
      animation.time += dt
    end

  end
end
