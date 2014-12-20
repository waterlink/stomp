module Stomp
  module Draw
    class << self

      def circle(window, x, y, z, r, color)
        circle_sprite(window, r, color).draw(x - r, y - r, z)
      end

      private

      def circle_sprite(window, r, color)
        sprites[[:circle, r, color]] ||= Gosu::Image.new(window, generate_circle(r, color), false)
      end

      def generate_circle(r, color)
        columns = rows = r * 2
        lower_half = (0...r).map do |y|
          x = ::Math.sqrt(r ** 2 - y ** 2).round
          right_half = "#{0.chr * (x - 1)}#{color.alpha.chr * 1}#{0.chr * (r - x)}"
          "#{right_half.reverse}#{right_half}"
        end.join

        blob = lower_half.reverse + lower_half
        blob.gsub!(/./) { |alpha| "#{color.red.chr}#{color.green.chr}#{color.blue.chr}#{alpha}"  }
        Blob[columns, rows, blob].tap { |x| Stomp.logger.debug "got Blob: #{x}" }
      end

      def sprites
        @_sprites ||= {}
      end

    end

    Blob = Struct.new(:columns, :rows, :to_blob)
  end
end
