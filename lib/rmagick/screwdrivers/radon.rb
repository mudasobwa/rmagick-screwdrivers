# encoding: utf-8

module Magick
  module Screwdrivers
    module Radon
      attr_reader :options
      @options = {
        :roughly            => false
      }

      # number of beams - odd number to ensure symmetry when centroid is projected on the middle beam
      HALFBEAMS = 25
      BEAMS     = 2 * HALFBEAMS + 1

      SQRT2 = Math.sqrt 2.0
      HALFSQRT2 = 0.5 * SQRT2
      HALFSQRT2DIVSIN22 = 0.5 * SQRT2 / Math.sin(Math::PI / 8.0)
      DOUBLESQRT2 = 2.0 * SQRT2
      COS45 = SQRT2 / 2.0
      SIN45 = COS45
      COS22 = Math.cos(Math::PI / 8.0)
      SIN22 = Math.sin(Math::PI / 8.0)
      SEC22 = 1.0 / COS22
      COS67 = Math.cos(3.0 * Math::PI / 8.0)
      SIN67 = Math.sin(3.0 * Math::PI / 8.0)

      # based on https:#dl.dropboxusercontent.com/u/18209754/Blog/radonTransformer.h
      def self.yo image, options = {}
        options = Magick::Screwdrivers.options.merge(@options).merge(OpenStruct === options ? options.to_h : options)

        orig = Magick::Screwdrivers.imagify  image
        #                 500×375
        scale = Math.sqrt(187_500.0 / (orig.columns * orig.rows))
        # Would scale image to process quickier
        img = scale < 1 ? orig.scale(scale) : orig
        img = img.quantize 256, Magick::GRAYColorspace unless options[:roughly]

        # Pixel Contributions Storage
        # sbTotals[8][100000];    # fixed size to avoid allocation of memory during each step (max 1000 sub-beams)
        # bTotals[8][beams];

        numPixels = img.columns * img.rows
        object = []
        for r in 0...img.rows
          for c in 0...img.columns
            object[r * img.columns + c] = { :x => c, :y => r, :c => (img.at(c, r) * 256 / Magick::QuantumRange).ceil }
          end
        end

        # prepare for projections
        centroid, radius = self.centroid_and_radius object

        #calculate sub-beams (estimation where there are 5 sub-beams per pixel)
        subBeams = 2 * ((10.0 * radius + HALFBEAMS + 1.0) / BEAMS).ceil + 1
        totalSubBeams = BEAMS * subBeams
        halfSubBeams = (totalSubBeams - 1) / 2

        # for each projection clear result storage
        sbTotals = Array.new(8, ((0...totalSubBeams).map { 0 }))
        bTotals = Array.new(8, ((0...BEAMS).map { 0 }))

        #calculate beam width
        beamWidth = radius / halfSubBeams

        # for each pixel
        for i in 0...numPixels
          project0degrees object[i], centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
          project22degrees object[i], centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
          project45degrees object[i], centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
          project67degrees object[i], centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
          project90degrees object[i], centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
          project112degrees object[i], centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
          project135degrees object[i], centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
          project157degrees object[i], centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
        end

        scalingFactor = beamWidth / numPixels

        #for each projection
        for h in 0...8
          #beam counter
          beam = 0

          #for each beam grouping
          (0...totalSubBeams).step(subBeams) { |i|
            sum = 0;

            #add all the beams together in grouping
            for j in i...(i + subBeams)
              sum += sbTotals[h][j]
            end

            #store in final result with scaling
            bTotals[h][beam] = sum * scalingFactor;
            beam += 1
          }
        end
        bTotals
      end

      def self.centroid_and_radius object
        # calculate centroid
        sumX = sumY = 0
        numPixels = object.length

        #sum all x and y values for all pixels
        for i in  0...numPixels
          sumX += object[i][:x]
          sumY += object[i][:y]
        end

        centroid = { :x => 1.0 * sumX / numPixels, :y => 1.0 * sumY / numPixels }

        radius = 0;
        # find the max length from centroid to a pixel
        for i in 0...numPixels
          # euclidian distance from pixel to centroid (no sqrt for performance reasons)
          len = Math.sqrt(
            (object[i][:x] - centroid[:x]) * (object[i][:x] - centroid[:x]) +
            (object[i][:y] - centroid[:y]) * (object[i][:y] - centroid[:y])
          )
          radius = [radius, len].max
        end

        #calculate radius (include missing sqrt from above) to a midpoint of a pixel
        #Note: since distance is to midpoint add SQRT2/2 (approximation)
        [centroid, radius + HALFSQRT2]
      end

      #*****************************************************************************************************************************************
      #* PROJECTION FUNCTIONS - 8 projections -> 0 to 157.5 degrees in 22.5 degree increments
      #*****************************************************************************************************************************************

      def self.project0degrees point, centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals #horizontal
        #projection of center of pixel on new axis
        c = (point[:x] - centroid[:x]) / beamWidth

        #rounded projected left and right corners of pixel
        l = ((c - 0.5 / beamWidth) + halfSubBeams).ceil
        r = (c + 0.5 / beamWidth).floor + halfSubBeams

        #add contributions to sub-beams
        for i in  l..r
          sbTotals[0][i] += 1;
        end
      end

      def self.project22degrees point, centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
        #projected left & right corners of pixel
        cl = ( (point[:y] - centroid[:y] - 0.5) * COS22 + (point[:x] - centroid[:x] - 0.5 ) * SIN22 ) / beamWidth
        cr = ( (point[:y] - centroid[:y] + 0.5) * COS22 + (point[:x] - centroid[:x] + 0.5 ) * SIN22 ) / beamWidth

        #average of cl and cr (center point of pixel)
        c = (cl + cr) / 2.0

        #rounded values - left and right sub-beams affected
        l = cl.ceil + halfSubBeams
        r = cr.floor + halfSubBeams

        #length of incline
        incl = (0.293 * (cr - cl + 1.0)).floor

        #add contributions to sub-beams
        for i in  l...(l+incl)
          sbTotals[1][i] += HALFSQRT2DIVSIN22 - DOUBLESQRT2 * (i - halfSubBeams - c).abs * beamWidth
        end

        for i in  (l+incl)..(r-incl)
          sbTotals[1][i] += SEC22
        end

        for i in  (r-incl+1)..r
          sbTotals[1][i] += HALFSQRT2DIVSIN22 - DOUBLESQRT2 * (i - halfSubBeams - c).abs * beamWidth
        end
      end

      def self.project45degrees point, centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
        #projected left & right corners of pixel
        cl = ( (point[:y] - centroid[:y] - 0.5) * COS45 + (point[:x] - centroid[:x] - 0.5 ) * SIN45 ) / beamWidth
        cr = ( (point[:y] - centroid[:y] + 0.5) * COS45 + (point[:x] - centroid[:x] + 0.5 ) * SIN45 ) / beamWidth

        #average of cl and cr (center point of pixel)
        c = (cl + cr) / 2.0

        #rounded values - left and right sub-beams affected
        l = cl.ceil + halfSubBeams
        r = cr.floor + halfSubBeams

        #add contributions to sub-beams
        for i in  l..r
          sbTotals[2][i] += SQRT2 - 2.0 *  (i - halfSubBeams - c).abs * beamWidth
        end
      end

      def self.project67degrees point, centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
        #projected left & right corners of pixel
        cl = ( (point[:y] - centroid[:y] - 0.5) * COS67 + (point[:x] - centroid[:x] - 0.5 ) * SIN67 ) / beamWidth
        cr = ( (point[:y] - centroid[:y] + 0.5) * COS67 + (point[:x] - centroid[:x] + 0.5 ) * SIN67 ) / beamWidth

        #average of cl and cr (center point of pixel)
        c = (cl + cr) / 2.0

        #rounded values - left and right sub-beams affected
        l = cl.ceil + halfSubBeams
        r = cr.floor + halfSubBeams

        #length of incline
        incl = (0.293 * (cr - cl + 1.0)).floor

        #add contributions to sub-beams
        for i in l...(l+incl)
          sbTotals[3][i] += HALFSQRT2DIVSIN22 - DOUBLESQRT2 * (i - halfSubBeams - c).abs * beamWidth
        end

        for i in (l+incl)..(r-incl)
          sbTotals[3][i] += SEC22;
        end

        for i in (r-incl+1)..r
          sbTotals[3][i] += HALFSQRT2DIVSIN22 - DOUBLESQRT2 * (i - halfSubBeams - c).abs * beamWidth
        end
      end

      def self.project90degrees point, centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
        #projection of center of pixel on new axis
        c = (point[:y] - centroid[:y]) / beamWidth

        #rounded projected left and right corners of pixel
        l = (c - 0.5 / beamWidth).ceil + halfSubBeams
        r = (c + 0.5 / beamWidth).floor + halfSubBeams

        #add contributions to sub-beams
        for i in  l..r
          sbTotals[4][i] += 1;
        end
      end

      def self.project112degrees point, centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
        #projected left & right corners of pixel
        cl = ( -(point[:y] - centroid[:y] + 0.5) * COS22 + (point[:x] - centroid[:x] - 0.5 ) * SIN22 ) / beamWidth
        cr = ( -(point[:y] - centroid[:y] - 0.5) * COS22 + (point[:x] - centroid[:x] + 0.5 ) * SIN22 ) / beamWidth

        #average of cl and cr (center point of pixel)
        c = (cl + cr) / 2.0

        #rounded values - left and right sub-beams affected
        l = cl.ceil + halfSubBeams
        r = cr.floor + halfSubBeams

        #length of incline
        incl = (0.293 * (cr - cl + 1.0)).floor

        #add contributions to sub-beams
        for i in l...(l+incl)
          sbTotals[5][i] += HALFSQRT2DIVSIN22 - DOUBLESQRT2 * (i - halfSubBeams - c).abs * beamWidth
        end

        for i in (l+incl)..(r-incl)
          sbTotals[5][i] += SEC22
        end

        for i in (r-incl+1)..r
          sbTotals[5][i] += HALFSQRT2DIVSIN22 - DOUBLESQRT2 * (i - halfSubBeams - c).abs * beamWidth
        end
      end

      def self.project135degrees point, centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
        #projected left & right corners of pixel
        cl = ( -(point[:y] - centroid[:y] + 0.5) * COS45 + (point[:x] - centroid[:x] - 0.5 ) * SIN45 ) / beamWidth
        cr = ( -(point[:y] - centroid[:y] - 0.5) * COS45 + (point[:x] - centroid[:x] + 0.5 ) * SIN45 ) / beamWidth

        #average of cl and cr (center point of pixel)
        c = (cl + cr) / 2.0

        #rounded values - left and right sub-beams affected
        l = cl.ceil + halfSubBeams
        r = cr.floor + halfSubBeams

        #add contributions to sub-beams
        for i in l..r
          sbTotals[6][i] += SQRT2 - 2 * (i - halfSubBeams - c).abs * beamWidth
        end
      end

      def self.project157degrees point, centroid, subBeams, totalSubBeams, halfSubBeams, beamWidth, sbTotals
        #projected left & right corners of pixel
        cl = ( -(point[:y] - centroid[:y] + 0.5) * COS67 + (point[:x] - centroid[:x] - 0.5 ) * SIN67 ) / beamWidth
        cr = ( -(point[:y] - centroid[:y] - 0.5) * COS67 + (point[:x] - centroid[:x] + 0.5 ) * SIN67 ) / beamWidth

        #average of cl and cr (center point of pixel)
        c = (cl + cr) / 2.0

        #rounded values - left and right sub-beams affected
        l = cl.ceil + halfSubBeams
        r = cr.floor + halfSubBeams

        #length of incline
        incl = (0.293 * (cr - cl + 1)).floor

        #add contributions to sub-beams
        for i in l...(l+incl)
          sbTotals[7][i] += HALFSQRT2DIVSIN22 - DOUBLESQRT2 * (i - halfSubBeams - c).abs * beamWidth
        end

        for i in (l+incl)..(r-incl)
          sbTotals[7][i] += SEC22
        end

        for i in (r-incl+1)..r
          sbTotals[7][i] += HALFSQRT2DIVSIN22 - DOUBLESQRT2 * (i - halfSubBeams - c).abs * beamWidth
        end
      end
    end

    def self.radon image, options
      Radon::yo image, options
    end
  end

  class Image
    def radon options
      Screwdrivers::Radon::yo self, options
    end
  end
end
