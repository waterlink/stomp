class DamageSystem < Stomp::System
  DEFAULT_HEALTH = 1
  DEFAULT_DAMAGE_RESISTANCE = 0

  def update(dt)
    Stomp::Component.each_entity(InflictedDamage) do |entity|
      make_it_valid!(entity)
      inflict_damage(entity)
    end
  end

  private

  def make_it_valid!(entity)
    entity[Health] ||= Health[DEFAULT_HEALTH]
    entity[DamageResistance] ||= DamageResistance[DEFAULT_DAMAGE_RESISTANCE]
  end

  def inflict_damage(entity)
    return unless alive?(entity)
    _inflict_damage(entity)
    inflict_death(entity)
  end

  def _inflict_damage(entity)
    entity[Health].value -= damage(entity)
  end

  def inflict_death(entity)
    return if death_can_be_inflicted?(entity)
    _inflict_death(entity)
    entity.remove(OnDeath)
  end

  def _inflict_death(entity)
    entity.with_hash_components(entity[OnDeath].inflict_list)
  end

  def death_can_be_inflicted?(entity)
    alive?(entity) && entity[OnDeath]
  end

  def alive?(entity)
    entity[Health].value > 0
  end

  def damage(entity)
    _damage(entity[InflictedDamage].value, entity[DamageResistance].value)
  end

  def _damage(inflicted, resistance)
    inflicted * (1.0 - resistance)
  end
end
