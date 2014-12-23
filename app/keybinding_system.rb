class KeybindingSystem < Stomp::System
  ALLOWED_KEY_PREFIX = /^(Kb|Ms|Gp)/

  def keystroke(id)
    Stomp::Component.each_entity(Keybinding) do |entity|
      next unless key_matches?(entity[Keybinding], id)
      add_action(entity)
    end
  end

  private

  def add_action(entity)
    Stomp::Entity
      .new(action_entity_name(entity))
      .with_hash_components([entity[Keybinding].action])
  end

  def key_matches?(keybinding, id)
    return unless ALLOWED_KEY_PREFIX.match(keybinding.key)
    Gosu.const_get(keybinding.key.to_sym) == id
  end

  def action_entity_name(entity)
    "#{entity.name}: Action"
  end
end
