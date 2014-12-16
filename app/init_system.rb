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
    entities.each do |hash|
      Stomp::Entity.from_hash(hash)
    end
  end

  def initialized!
    @initialized = true
  end

  def entities
    data["entities"]
  end

  def data
    @_data ||= YAML.load_file(DATA_PATH)
  end
end
