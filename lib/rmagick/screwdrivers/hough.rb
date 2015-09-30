# encoding: utf-8

module Magick
  module Screwdrivers
    module Hough
      attr_reader :options
      @options = {
        :roughly            => false
      }

      def self.is_dark? px
        px.red + px.green + px.blue < 40
      end

      def self.is_light? px
        px.red + px.green + px.blue > 600
      end

      # based on http://jonathan-jackson.net/ruby-hough-hack.html
      def self.yo image, options = {}
        options = Magick::Screwdrivers.options.merge(@options).merge(OpenStruct === options ? options.to_h : options)

        orig = Magick::Screwdrivers.imagify  image

        orig = orig.quantize 256, Magick::GRAYColorspace unless options[:roughly]

        trigons = { :cos => [], :sin => [] }
        hough = Hash.new(0)
        (orig.rows - 1).times do |y|
          orig.columns.times do |x|
            if Hough::is_dark?(orig.pixel_color(x,y)) && Hough::is_light?(orig.pixel_color(x,y + 1))
              (0..Math::PI).step(0.1).each do |theta|
                trigons[:cos][theta] ||= Math.cos(theta)
                trigons[:sin][theta] ||= Math.sin(theta)
                distance = (x * trigons[:cos][theta] + y * trigons[:sin][theta]).to_i
                hough[[theta, distance]] += 1 if distance >= 0
              end
            end
          end
        end

        hough.sort_by { |k,v| v }
      end
    end

    def self.hough image, options
      Hough::yo image, options
    end
  end

  class Image
    def hough options
      Screwdrivers::Hough::yo self, options
    end
  end
end
