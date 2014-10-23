# encoding: utf-8

require 'RMagick'

module Magick
  module Screwdrivers
    # based on http://blog.saush.com/2011/04/20/edge-detection-with-the-sobel-operator-in-ruby/
    def self.sobel file, options={}
      options = {
        :roughly       => false,
        :logger        => nil
      }.merge(options)

      sobel_x = [[-1,0,1], [-2,0,2], [-1,0,1]]
      sobel_y = [[-1,-2,-1], [0,0,0], [1,2,1]]

      begin
        orig = img_from_file(file)
        orig = orig.quantize 256, Magick::GRAYColorspace unless options[:roughly]
      rescue
        warn(options[:logger], "Skipping invalid file #{file}…")
        return nil
      end

      #                 500×375
      scale = Math.sqrt(187_500.0 / (orig.columns * orig.rows))

      info(options[:logger], "Original is [#{orig.columns}×#{orig.rows}] image")
      info(options[:logger], "Scale factor: [#{scale}]")
      img = scale < 1 ? orig.scale(scale) : orig

      info(options[:logger], "Will process [#{img.columns}×#{img.rows}] image")

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

      edge = edge.scale(orig.columns, orig.rows) if scale < 1

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
end
