# encoding: utf-8

require 'RMagick'

module Magick
  module Screwdrivers
    def self.poster file, text1, text2, options={}
      options = {
        :color        => '#FFFFFF',
        :stroke       => nil,
        :width        => 600,
        :type         => :classic, # :classic for black square around
        :lineheight   => 6,
        :background   => '#000000',
        :font         => '/usr/share/fonts/truetype/ubuntu-font-family/Ubuntu-B.ttf',
        :max_font_size => 48,
        :logger       => nil
      }.merge(options)

      text1 ||= ''
      text2 ||= ''
      options[:lineheight] = 3 if options[:lineheight] < 3

      img = img_from_file(file)
      img.thumbnail!(options[:width].to_f/img.columns.to_f)

      mark = Magick::Image.new(img.columns, img.rows) do
        self.background_color = options[:type] == :classic ? options[:background] : 'transparent'
      end

      gc = Magick::Draw.new

      pointsize = [img.columns, options[:max_font_size]].min
      classic_margin = 0

      loop do
        gc.pointsize = pointsize -= 1 + pointsize / 33

        m1 = gc.get_type_metrics(text1)
        w1 = m1.width
        h1 = (m1.bounds.y2 - m1.bounds.y1).round

        m2 = gc.get_type_metrics(text2)
        w2 = m2.width
        h2 = (m2.bounds.y2 - m2.bounds.y1).round

        if w1 < img.columns - 10*options[:lineheight] && w2 < img.columns - 10*options[:lineheight]
          if options[:type] == :classic
            classic_margin = h2
            mark.resize! img.columns+options[:lineheight]*14/3, img.rows+options[:lineheight]*8+h1+h2
            gc.stroke_width = options[:lineheight]/3
            gc.stroke = '#FFFFFF'
            gc.fill = options[:background]
            gc.rectangle(options[:lineheight]*7/6, options[:lineheight]*7/6, \
                         img.columns+options[:lineheight]*21/6, img.rows+options[:lineheight]*21/6)
            gc.composite(
              7*options[:lineheight]/3, 7*options[:lineheight]/3,
              0, 0,
              img, Magick::OverCompositeOp
            )
            gc.draw mark
          end
          break
        end
      end

      gc.fill = options[:color]
      gc.stroke = options[:stroke] || 'none'
      gc.stroke_width = 1
      gc.font = options[:font]

      case options[:type]
      when :classic
        gc.annotate(mark, 0, 0, 0, classic_margin+2*options[:lineheight], text1) do
          self.gravity = Magick::SouthGravity
        end
      else
        gc.annotate(mark, 0, 0, 0, 0, text1) do
          self.gravity = Magick::NorthGravity
        end
      end

      gc.annotate(mark, 0, 0, 0, 0, text2) do
        self.gravity = Magick::SouthGravity
      end

      case options[:type]
      when :classic
        mark
      when :negative
        img.composite(mark, Magick::SouthEastGravity, Magick::SubtractCompositeOp)
      when :standard
        img.composite(mark, Magick::SouthEastGravity, Magick::OverCompositeOp)
      else
        warn options[:logger], "Invalid type: #{options[:type]}"
      end
    end
  end
end
