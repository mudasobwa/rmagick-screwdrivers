# encoding: utf-8

require 'RMagick'

module Magick
  module Screwdrivers
    def self.collage files, options={}
      options = {
        :columns       => 5,
        :scale_range   => 0.1,
        :thumb_width   => 120,
        :rotate_angle  => 20,
        :background    => 'white',
        :border        => '#DDDDDD',
        :logger        => nil
      }.merge(options)
      files = "#{files}/*" if File.directory?(files)
      imgs = ImageList.new
      imgnull = Image.new(options[:thumb_width],options[:thumb_width]) { 
        self.background_color = 'transparent' 
      }
      (options[:columns]+2).times { imgs << imgnull.dup }
      Dir.glob("#{files}") { |f|
        begin
          i = img_from_file(f)
        rescue
          warn(options[:logger], "Skipping invalid file #{f}…")
          next
        end
        scale = (1.0 + options[:scale_range]*Random::rand(-1.0..1.0))*options[:thumb_width]/[i.columns, i.rows].max
        imgs << imgnull.dup if (imgs.size % (options[:columns]+2)).zero?
        imgs << i.auto_orient.thumbnail(scale).polaroid(
          Random::rand(-options[:rotate_angle]..options[:rotate_angle])
        )
        imgs << imgnull.dup if (imgs.size % (options[:columns]+2)) == options[:columns]+1
      }
      (2*options[:columns]+4-(imgs.size % (options[:columns]+2))).times { imgs << imgnull.dup }
      info options[:logger], "Montaging image [#{options[:columns]}×#{imgs.size/(options[:columns]+2)-2}]"
      imgs.montage { 
        self.tile             = Magick::Geometry.new(options[:columns]+2) 
        self.geometry         = "-#{options[:thumb_width]/5}-#{options[:thumb_width]/4}"
        self.background_color = options[:background]
      }.trim(true).border(10,10,options[:background]).border(1,1,options[:border])
    end
  end
end
