module Stomp
  class Math
    class << self

      def inside_bounding_box?(x, y, box_x, box_y, size_x, size_y)
        [
         x >= box_x - size_x / 2, x <= box_x + size_x / 2,
         y >= box_y - size_y / 2, y <= box_y + size_y / 2,
        ].all?
      end

    end
  end
end
