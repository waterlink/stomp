class ConditionSystem < Stomp::System
  def update(dt)
    Stomp::Component.each_entity(Condition) do |entity|
      Wrapper[Condition, entity].call(dt)
    end
  end

  private

  class Wrapper < Struct.new(:type, :entity)
    def call(_)
      return unless met_expectation?
      create_action
    end

    private

    def met_expectation?
      expectation.met?(predicate)
    end

    def expectation
      Expectation[expectation_args]
    end

    def predicate
      Predicate[predicate_args]
    end

    def expectation_args
      action.expectation
    end

    def predicate_args
      action.predicate
    end

    def create_action
      Stomp::Entity
        .new(name)
        .with_hash_components([component])
    end

    def name
      "#{entity.name}: Action"
    end

    def component
      action.action
    end

    def action
      @_action ||= entity[type]
    end
  end

  class Expectation < Struct.new(:args)
    EXPECTATION_STRATEGIES = {
      eq: -> (x, y) { x == y },
      less: -> (x, y) { x < y },
      greater: -> (x, y) { x > y },
    }
    AVAILABLE_EXPECTATIONS = EXPECTATION_STRATEGIES.keys
    DEFAULT_STRATEGY = -> (*) { false }

    def met?(predicate)
      return unless predicate.valid?
      expect(predicate.call)
    end

    private

    def strategy
      @_strategy ||= EXPECTATION_STRATEGIES.fetch(name) {
        report_invalid_expectation
        DEFAULT_STRATEGY
      }
    end

    def name
      args.first.to_sym
    end

    def report_invalid_expectation
      Stomp
        .logger
        .error("ConditionSystem :: Invalid expectation '#{name}', must be one of #{AVAILABLE_EXPECTATIONS}")
    end

    def expect(value)
      strategy[value, *other_args]
    end

    def other_args
      args[1..-1]
    end
  end

  class Predicate < Struct.new(:args)
    PREDICATE_STRATEGIES = {
      count: -> (x) { Stomp::Component.count(x) },
    }
    AVAILABLE_PREDICATES = PREDICATE_STRATEGIES.keys

    def call
      strategy[*other_args]
    end

    def valid?
      !!strategy
    end

    private

    def strategy
      @_strategy ||= PREDICATE_STRATEGIES.fetch(name) {
        report_invalid_predicate
        nil
      }
    end

    def name
      args[0].to_sym
    end

    def report_invalid_predicate
      Stomp
        .logger
        .error("ConditionSystem :: Invalid predicate '#{name}', must be one of #{AVAILABLE_PREDICATES}")
    end

    def other_args
      args[1..-1]
    end
  end
end
