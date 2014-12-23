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
        [x / d, y / d, *other]
      end

      def sign(x)
        return -1 if x < 0
        return 1 if x > 0
        0
      end

      def shape_from(vertices, angle)
        return vertices unless angle
        vertices.map { |p| Stomp::Math.rotate_vector(p, angle) }
      end

      def rotate_vector(v, angle)
        x, y = v
        cos = ::Math.cos(angle)
        sin = ::Math.sin(angle)
        [x * cos - y * sin,
         x * sin + y * cos]
      end

      def rotate_point(p, o, angle)
        x, y = p
        ox, oy = o
        x, y = rotate_vector([x - ox, y - oy], angle)
        [x + ox, y + oy]
      end

      def dot_product(v1, v2)
        x1, y1 = v1
        x2, y2 = v2
        x1 * x2 + y1 * y2
      end

      def vsub(v1, v2)
        x1, y1 = v1
        x2, y2 = v2
        [x1 - x2, y1 - y2]
      end

      def hypot2(a, b)
        (x1, y1), (x2, y2) = [a, b]
        (x1 - x2) ** 2 + (y1 - y2) ** 2
      end

      def squared_vector(v)
        dot_product(v, v)
      end

      def to_v(pos)
        [pos.x, pos.y]
      end

      def vadd(a, b)
        (x1, y1), (x2, y2) = [a, b]
        [x1 + x2, y1 + y2]
      end

      def vmul(a, k)
        x, y = a
        [x * k, y * k]
      end

      def fadd(face, v)
        v1, v2 = face
        [vadd(v1, v), vadd(v2, v)]
      end

      def vneg(v)
        vmul(v, -1)
      end

      def cross_product(v1, v2)
        (x1, y1), (x2, y2) = [v1, v2]
        x1 * y2 - x2 * y1
      end

      def cross_vmul(v, a)
        x, y = v
        [a * x, -a * y]
      end

      def vmul_cross(a, v)
        x, y = v
        [-a * x, a * y]
      end

      def inverted_mass(x)
        x == 0 ? 0 : 1.0 / x
      end

    end
  end
end
