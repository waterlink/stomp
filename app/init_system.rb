class InitSystem < Stomp::System
  DATA_PATH = "resources/common.yml"

  def update
    return if initialized?
    load_entities!
    initialized!
  end

  private

  attr_reader :initialized
  alias_method :initialized?, :initialized

  def load_entities!
    Stomp::World.from_hash_list(worlds)
  end

  def initialized!
    @initialized = true
  end

  def worlds
    data["worlds"]
  end

  def data
    @_data ||= YAML.load_file(DATA_PATH)
  end
end
