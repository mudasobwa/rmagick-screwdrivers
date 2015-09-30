# encoding: utf-8

module Magick
  module Screwdrivers
    # based on http://blog.saush.com/2011/04/20/edge-detection-with-the-sobel-operator-in-ruby/
    module Sobel
      attr_reader :options
      @options = {
        :roughly       => false
      }
      def self.yo image, options = {}
        options = Magick::Screwdrivers.options.merge(@options).merge(OpenStruct === options ? options.to_h : options)

        orig = Magick::Screwdrivers.imagify image

        sobel_x = [[-1,0,1], [-2,0,2], [-1,0,1]]
        sobel_y = [[-1,-2,-1], [0,0,0], [1,2,1]]

        #                 500×375
        scale = Math.sqrt(187_500.0 / (orig.columns * orig.rows))
        # Would scale image to process quickier
        img = scale < 1 ? orig.scale(scale) : orig
        img = orig.quantize 256, Magick::GRAYColorspace unless options[:roughly]

        edge = Image.new(img.columns, img.rows) {
          self.background_color = 'transparent'
        }

        for x in 1..img.columns-2
          for y in 1..img.rows-2
            pixel_x = (sobel_x[0][0] * img.at(x-1,y-1)) + (sobel_x[0][1] * img.at(x,y-1)) + (sobel_x[0][2] * img.at(x+1,y-1)) +
                      (sobel_x[1][0] * img.at(x-1,y))   + (sobel_x[1][1] * img.at(x,y))   + (sobel_x[1][2] * img.at(x+1,y)) +
                      (sobel_x[2][0] * img.at(x-1,y+1)) + (sobel_x[2][1] * img.at(x,y+1)) + (sobel_x[2][2] * img.at(x+1,y+1))

            pixel_y = (sobel_y[0][0] * img.at(x-1,y-1)) + (sobel_y[0][1] * img.at(x,y-1)) + (sobel_y[0][2] * img.at(x+1,y-1)) +
                      (sobel_y[1][0] * img.at(x-1,y))   + (sobel_y[1][1] * img.at(x,y))   + (sobel_y[1][2] * img.at(x+1,y)) +
                      (sobel_y[2][0] * img.at(x-1,y+1)) + (sobel_y[2][1] * img.at(x,y+1)) + (sobel_y[2][2] * img.at(x+1,y+1))

            val = Math.sqrt((pixel_x * pixel_x) + (pixel_y * pixel_y)).ceil
            edge.pixel_color x, y, Pixel.new(val, val, val)
          end
        end

        # edge = edge.scale(orig.columns, orig.rows) if scale < 1

        case orig.orientation
        when Magick::RightTopOrientation
          edge.rotate!(90)
        when Magick::BottomRightOrientation
          edge.rotate!(180)
        when Magick::LeftBottomOrientation
          edge.rotate!(-90)
        end

        edge
      end
    end

    def self.sobel image, options
      Sobel::yo image, options
    end
  end

  class Image
    def sobel options
      Screwdrivers::Sobel::yo self, options
    end
  end
end
