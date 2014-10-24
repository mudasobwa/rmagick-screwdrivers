# encoding: utf-8

require 'RMagick'

module Magick
  module Screwdrivers
    module Collage
      attr_reader :options 
      @options = {
        :columns       => 5,
        :scale_range   => 0.1,
        :thumb_width   => 120,
        :rotate_angle  => 20,
        :background    => 'white',
        :border        => '#DDDDDD',
      }
      def self.yo image_list, options = {}
        options = Magick::Screwdrivers.options.merge(@options).merge(OpenStruct === options ? options.to_h : options)
        
        # Here we’ll store our collage
        memo = ImageList.new
        # Blank image of the proper size to montage properly
        imgnull = Image.new(options[:thumb_width],options[:thumb_width]) { self.background_color = 'transparent' }
        # Handler for one image addition
        img_handler = Proc.new do |memo, img|
          unless img.nil?
            scale = (1.0 + options[:scale_range] * Random::rand(-1.0..1.0)) * options[:thumb_width] / [img.columns, img.rows].max
            memo << imgnull.dup if (memo.size % (options[:columns] + 2)).zero?
            memo << img.auto_orient.thumbnail(scale).polaroid(Random::rand(-options[:rotate_angle]..options[:rotate_angle]))
            memo << imgnull.dup if (memo.size % (options[:columns] + 2)) == options[:columns] + 1
          end
          memo
        end

        (options[:columns] + 2).times { memo << imgnull.dup } # fill first row
          
        case image_list
        when ImageList, Array 
          image_list.each { |img| img_handler.call memo, Magick::Screwdrivers.imagify(img, true) }
        when File, String
          Dir.glob("#{image_list}" + (File.directory?(image_list) ? "/*" : "")) { |img| # FIXME should find all images within dir
            img_handler.call memo, Magick::Screwdrivers.imagify(img, true)
          }
        else Magick::Screwdrivers.warn "Unknown type of #{image_list} ⇒ #{image_list.class}"
        end

        (2 * options[:columns] + 4 - (memo.size % (options[:columns] + 2))).times { memo << imgnull.dup } # fill last row
          
        Magick::Screwdrivers.info options[:logger], "Montaging image [#{options[:columns]}×#{memo.size / (options[:columns] + 2) - 2}], options: [#{options}]"
        memo.montage { 
          self.tile             = Magick::Geometry.new(options[:columns] + 2) 
          self.geometry         = "-#{options[:thumb_width]/5}-#{options[:thumb_width]/4}"
          self.background_color = options[:background]
        }.trim(true).border(10, 10, options[:background]).border(1, 1, options[:border])
      end
    end
    
    def self.collage files, options
      Collage::yo files, options
    end
  end

  class ImageList
    def collage options
      Screwdrivers::Collage::yo self, options
    end
  end
end
