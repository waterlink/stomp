class SceneSystem < Stomp::System
  def update(dt)
    Stomp::Component.each_entity(Scene) do |entity|
      next if is_current_scene?(entity[Scene])
      return load_scene(entity)
    end
  end

  private

  def current_scene
    Stomp::Component.each_entity(CurrentScene) do |entity|
      return entity.value
    end
    nil
  end

  def is_current_scene?(scene)
    return false unless current_scene
    current_scene.path == scene.path
  end

  def load_scene(entity)
    drop_current_scene
    load_entities(scene(entity[Scene].path))
  end

  def load_entities(data)
    Stomp::World.from_hash_list(data["worlds"])
    switch_to(data["active_world"])
  end

  def switch_to(active_world)
    Stomp::World.active_world = active_world
  end

  def drop_current_scene
    Stomp::Component.each_entity(Scene) do |entity|
      next unless is_current_scene?(entity[Scene])
      entity.drop
    end
  end

  def scene(path)
    scenes[path] ||= YAML.load_file(scene_path(path))
  end

  def scene_path(path)
    "resources/scenes/#{path}"
  end

  def scenes
    @_scenes ||= {}
  end
end
