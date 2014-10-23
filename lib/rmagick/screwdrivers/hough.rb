# encoding: utf-8

require 'RMagick'

module Magick
  module Screwdrivers
    module Hough
      def self.is_dark? px
        px.red + px.green + px.blue < 40
      end

      def self.is_light? px
        px.red + px.green + px.blue > 600
      end
    end
 
    # based on http://jonathan-jackson.net/ruby-hough-hack.html
    def self.hough file, options={}
      options = {
        :roughly       => false,
        :logger        => nil
      }.merge(options)

      begin
        orig = img_from_file(file)
#        orig = orig.gaussian_blur 0, 3.0
        orig = orig.quantize 256, Magick::GRAYColorspace unless options[:roughly]
      rescue
        warn(options[:logger], "Skipping invalid file #{file}…")
        return nil
      end

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

      info options[:logger], 'Will print first 200 results:'
      hough.sort_by { |k,v| v }.take(200).each { |v|
        info options[:logger], v
      }
      at = hough.sort_by { |k,v| v }.inject(0.0) { |m,v| m + v[0][0] } / 20
      info options[:logger],  "Average theta: #{at}"

      orig.rotate at
    end

    # based on http://rosettacode.org/wiki/Hough_transform#Ruby
    def self.hough_transform file, options={}
      options = {
        :roughly       => false,
        :logger        => nil
      }.merge(options)

      begin
        orig = img_from_file(file)
#        orig = orig.gaussian_blur 0, 3.0
        orig = orig.quantize 256, Magick::GRAYColorspace unless options[:roughly]
      rescue
        warn(options[:logger], "Skipping invalid file #{file}…")
        return nil
      end

      mx, my = orig.columns * 0.5, orig.rows * 0.5
      max_d = Math.sqrt(mx * mx + my * my)
      min_d = -max_d
      hough = Hash.new(0)
      (0...orig.columns).each do |x|
        warn(options[:logger], "#{x} of #{orig.columns}")
        (0...orig.rows).each do |y|
          if orig.pixel_color(x,y).green > 32
            (0...180).each do |a|
              rad = a * (Math::PI / 180.0)
              d = (x - mx) * Math.cos(rad) + (y - my) * Math.sin(rad)
              hough["#{a.to_i}_#{d.to_i}"] = hough["#{a.to_i}_#{d.to_i}"] + 1
            end
          end
        end
      end

      max = hough.values.max

      houghed = Image.new(orig.columns, orig.rows) { 
        self.background_color = 'transparent' 
      }

      hough.each_pair do |k, v|
        a, d = k.split('_').map(&:to_i)
        c = (v / max) * 255
#        c = heat.get_pixel(c,0)
        houghed.pixel_color a, max_d + d, Pixel.new(c, c, c)
      end

      houghed
    end
 
  end
end
