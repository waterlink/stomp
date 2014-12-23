class MagnetSystem < Stomp::System
  DEFAULT_MASS = 5

  def update(dt)
    Stomp::Component.each_entity(Magnet) do |entity|
      Stomp::Component.each_entity(Magnet) do |other|
        next if entity == other
        Wrapper[Magnet,
                ForceParts,
                ForceParts::MAGNET,
                entity,
                other].call(dt)
      end
    end
  end

  private

  class Wrapper < Struct.new(:type, :force_type, :force_index, :source, :target)
    def call(_)
      apply_force
    end

    private

    def apply_force
      target_forces[force_index] = force
    end

    def target_forces
      @_target_forces ||= _target_forces
    end

    def _target_forces
      target[force_type] ||= force_type[[]]
      target[force_type].parts
    end

    def force
      Stomp::Math.vmul(force_vector, force_value)
    end

    def force_vector
      Stomp::Math.vsub(source_position, target_position)
    end

    def force_value
      1.0 * source_mass * source_power / squared_distance
    end

    def source_position
      @_source_position ||= Stomp::Math.to_v(source[Position])
    end

    def target_position
      @_target_position ||= Stomp::Math.to_v(target[Position])
    end

    def source_mass
      @_source_mass ||= _source_mass
    end

    def _source_mass
      return 1.0 if source_infinite_mass?
      source_mass_component.value
    end

    def source_mass_component
      @_source_mass_component ||= _source_mass_component
    end

    def _source_mass_component
      source[Mass] ||= Mass[DEFAULT_MASS]
    end

    def source_infinite_mass?
      source_mass_component.value == 0
    end

    def source_power
      source_magnet.power
    end

    def source_magnet
      @_source_magnet ||= source[type]
    end

    def squared_distance
      Stomp::Math.squared_vector(force_vector)
    end

  end
end
