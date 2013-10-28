# encoding: utf-8

require 'RMagick'
require 'date'

module Magick
  module Screwdrivers
    def self.scale file, options={}
      options = {
        :widths            => 600,
        :date_in_watermark => false,
        :watermark         => nil,
        :logger            => nil
      }.merge(options)

      img = img_from_file file

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
            self.fill 'rgba(60%, 60%, 60%, 0.40)'
            self.stroke = 'none'
            self.pointsize = 1 + 2 * Math.log(sz, 3).to_i
            self.font_family = 'Comfortaa'
            self.font_weight = Magick::NormalWeight
            self.font_style = Magick::NormalStyle
          end
          curr = curr.composite(mark.rotate(-90), Magick::SouthEastGravity, Magick::SubtractCompositeOp)
        end

        info options[:logger], "Scaling to width #{curr.rows}×#{curr.columns}, watermark: “#{will_wm ? options[:watermark] : 'NONE'}”"

        result << curr
      }

      result
    end
  end
end
