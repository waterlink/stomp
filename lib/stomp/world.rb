module Stomp
  class World < Struct.new(:name)

    class << self
      attr_accessor :active_world, :common_world

      def setup(common_world: nil, active_world: nil)
        @common_world = common_world
        @active_world = active_world
      end

      def from_hash_list(list)
        list.each(&method(:from_hash))
      end

      def from_hash(hash)
        worlds[hash["name"]] ||= new(hash["name"])
          .with_hashed_entities(hash["entities"])
      end

      def active_world?(world_name)
        [active_world, common_world].include?(world_name)
      end

      private

      def worlds
        @_worlds ||= {}
      end
    end

    def with_hashed_entities(list)
      list.each { |hash| Entity.from_hash(hash, world: name) }
    end

  end
end
