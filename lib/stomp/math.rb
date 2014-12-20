module Stomp
  class Math
    class << self

      def inside_bounding_box?(x, y, box_x, box_y, size_x, size_y)
        [
         x >= box_x - size_x / 2, x <= box_x + size_x / 2,
         y >= box_y - size_y / 2, y <= box_y + size_y / 2,
        ].all?
      end

      def normalize_vector(v)
        return unless v
        x, y, *other = v
        d = x ** 2 + y ** 2
        return v if d == 0
        d = ::Math.sqrt(d)
        [x / d, y / d]
      end

      def sign(x)
        return -1 if x < 0
        return 1 if x > 0
        0
      end

    end
  end
end
