# encoding: utf-8

require 'RMagick'
require 'date'

module Magick
  module Screwdrivers
    module Scale
      attr_reader :options 
      @options = {
        :widths            => 600,
        :date_in_watermark => false,
        :watermark         => nil,
        :color             => 'rgba(66%, 66%, 66%, 0.33)',
        :overlap           => nil,
      }

      def self.yo image, options = {}
        options = Magick::Screwdrivers.options.merge(@options).merge(OpenStruct === options ? options.to_h : options)

        options[:overlap] = options[:overlap] && Magick.constants.include?("#{options[:overlap].capitalize}CompositeOp".to_sym) ?
                     Magick.const_get("#{options[:overlap].capitalize}CompositeOp".to_sym) : Magick::ModulateCompositeOp

        img = Magick::Screwdrivers.imagify image

        date = img.get_exif_by_number(36867)[36867]
        date = Date.parse(date.gsub(/:/, '/')) if date
        date ||= Date.parse(img.properties['exif:DateTime'].gsub(/:/, '/')) if img.properties['exif:DateTime']
        date ||= Date.parse(img.properties['date:modify']) if img.properties['date:modify']
        date ||= Date.parse(img.properties['date:create']) if img.properties['date:create']
        date ||= Date.parse(img.properties['xap:CreateDate']) if img.properties['xap:CreateDate']
  
        options[:watermark] = ([
          options[:watermark], date.strftime('%y/%m/%d')] - [nil]
        ).join(' :: ').strip if options[:date_in_watermark]
  
        result = ImageList.new
  
        [*options[:widths]].each { |sz|
          unless Integer === sz && sz < img.columns && sz > 0
            warn options[:logger], "Invalid width #{sz} (original is #{img.columns}), skipping…"
            next
          end
  
          curr = img.resize_to_fit(sz)
  
          if will_wm = (options[:watermark] && curr.rows >= 400)
            mark = Magick::Image.new(curr.rows, curr.columns) do
              self.background_color = 'transparent'
            end
            draw = Magick::Draw.new
            draw.encoding = 'Unicode'
            draw.annotate(mark, 0, 0, 5, 2, options[:watermark]) do
              self.encoding = 'Unicode'
              self.gravity = Magick::SouthEastGravity
              self.fill = options[:color]
              self.stroke = 'transparent'
              self.pointsize = 2 + 2 * Math.log(sz, 3).to_i
              self.font_family = 'Comfortaa'
              self.font_weight = Magick::NormalWeight
              self.font_style = Magick::NormalStyle
            end
            curr = curr.composite(mark.rotate(-90), Magick::SouthEastGravity, options[:overlap] )
          end
  
          Magick::Screwdrivers.info options[:logger], "Scaling to width #{curr.rows}×#{curr.columns}, method: #{options[:overlap]}, watermark: “#{will_wm ? options[:watermark] : 'NONE'}”"
  
          result << curr
        }

        result
      end
    end

    def self.scale image, options
      Scale::yo image, options
    end
  end

  class Image
    def fan options
      Screwdrivers::Scale::yo self, options
    end
  end
end
