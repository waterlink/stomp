class KeybindingSystem < Stomp::System
  ALLOWED_KEY_PREFIX = /^(Kb|Ms|Gp)/

  def keystroke(id)
    handler(Keybinding, id)
  end

  def key_up(id)
    handler(KeybindingUp, id)
  end

  private

  def handler(type, id)
    Stomp::Component.each_entity(type) do |entity|
      next unless key_matches?(entity[type], id)
      add_action(type, entity)
    end
  end

  def add_action(type, entity)
    Stomp::Entity
      .new(action_entity_name(entity))
      .with_hash_components([entity[type].action])
  end

  def key_matches?(keybinding, id)
    return unless ALLOWED_KEY_PREFIX.match(keybinding.key)
    Gosu.const_get(keybinding.key.to_sym) == id
  end

  def action_entity_name(entity)
    "#{entity.name}: Action"
  end
end
