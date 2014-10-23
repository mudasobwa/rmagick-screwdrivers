# encoding: utf-8

# http:# www.tomgibara.com/computer-vision/CannyEdgeDetector.java
# @author Tom Gibara
# ported from java Alexei Matyushkin


require 'RMagick'
require 'date'
require 'ostruct'

module Magick
  module Screwdrivers
  	module Canny
		GAUSSIAN_CUT_OFF = 0.005
		MAGNITUDE_SCALE = 100.0
		MAGNITUDE_LIMIT = 1000.0
		MAGNITUDE_MAX = (MAGNITUDE_SCALE * MAGNITUDE_LIMIT).ceil

		def self.gaussian x, sigma
			Math.exp(-(x * x) / (2.0 * sigma * sigma))
		end

		def self.hypot x, y
			return Math.hypot x, y # x.abs + y.abs
		end

		def self.normalizeContrast data
			histogram = (0...256).map { 0 }
			for i in 0...data.length
				histogram[data[i]] += 1
			end
			remap = (0...256).map { 0 }
			sum = 0
			j = 0
			for i in 0...histogram.length
				sum += histogram[i]
				target = sum * (256 - 1) / data.length
				for k in (j + 1)..target
					remap[k] = i
				end
				j = target
			end
			for i in 0...data.length
				data[i] = remap[data[i]]
			end
			data
		end

		# NOTE: The elements of the method below (specifically the technique for
		# non-maximal suppression and the technique for gradient computation)
		# are derived from an implementation posted in the following forum (with the
		# clear intent of others using the code):
		#   http:# forum.java.sun.com/thread.jspa?threadID=546211&start=45&tstart=0
		# My code effectively mimics the algorithm exhibited above.
		# Since I don't know the providence of the code that was posted it is a
		# possibility (though I think a very remote one) that this code violates
		# someone's intellectual property rights. If this concerns you feel free to
		# contact me for an alternative, though less efficient, implementation.
		
		def self.computeGradients kernelRadius, kernelWidth, width, height, data
			xConv = (0...width*height).map { 0.0 }
			yConv = (0...width*height).map { 0.0 }

			xGradient = (0...width*height).map { 0.0 }
			yGradient = (0...width*height).map { 0.0 }

			magnitude = (0...width*height).map { 0 }

			# generate the gaussian convolution masks
			kernel = (0...kernelWidth).map { 0.0 }
			diffKernel = (0...kernelWidth).map { 0.0 }
			for kwidth in 0...kernelWidth
				g1 = self.gaussian(kwidth, kernelRadius)
				next if (g1 <= Canny::GAUSSIAN_CUT_OFF && kwidth >= 2)
				g2 = self.gaussian(kwidth - 0.5, kernelRadius)
				g3 = self.gaussian(kwidth + 0.5, kernelRadius)
				kernel[kwidth] = (g1 + g2 + g3) / 3.0 / (2.0 * Math::PI * kernelRadius * kernelRadius)
				diffKernel[kwidth] = g3 - g2
			end

			initX = kernelWidth - 1
			maxX = width - initX
			initY = width * (kernelWidth - 1)
			maxY = width * height - initY
		
			# perform convolution in x and y directions
			for x in initX...maxX
				(initY...maxY).step(width) { |y|
					index = x + y
					sumY = sumX = data[index] * kernel[0]
					xOffset = 1
					yOffset = width
					while xOffset < kernelWidth 
						sumY += kernel[xOffset] * (data[index - yOffset] + data[index + yOffset])
						sumX += kernel[xOffset] * (data[index - xOffset] + data[index + xOffset])
						yOffset += width
						xOffset += 1
					end
					yConv[index] = sumY
					xConv[index] = sumX
				}
			end
 
			for x in initX...maxX
				(initY...maxY).step(width) { |y|
					sum = 0.0
					index = x + y
					for i in 1...kernelWidth
						sum += diffKernel[i] * (yConv[index - i] - yConv[index + i])
					end
					xGradient[index] = sum
				}
			end

			for x in kernelWidth...(width - kernelWidth)
				(initY...maxY).step(width) { |y|
					sum = 0.0
					index = x + y
					yOffset = width
					for i in 1...kernelWidth
						sum += diffKernel[i] * (xConv[index - yOffset] - xConv[index + yOffset])
						yOffset += width
					end
					yGradient[index] = sum
				}
			end
 
			initX = kernelWidth
			maxX = width - kernelWidth
			initY = width * kernelWidth
			maxY = width * (height - kernelWidth)

			for x in initX...maxX
				(initY...maxY).step(width) { |y|
					index = x + y
					indexN = index - width
					indexS = index + width
					indexW = index - 1
					indexE = index + 1
					indexNW = indexN - 1
					indexNE = indexN + 1
					indexSW = indexS - 1
					indexSE = indexS + 1
					
					xGrad = xGradient[index]
					yGrad = yGradient[index]
					gradMag = self.hypot(xGrad, yGrad)

					# perform non-maximal supression
					nMag = self.hypot(xGradient[indexN], yGradient[indexN])
					sMag = self.hypot(xGradient[indexS], yGradient[indexS])
					wMag = self.hypot(xGradient[indexW], yGradient[indexW])
					eMag = self.hypot(xGradient[indexE], yGradient[indexE])
					neMag = self.hypot(xGradient[indexNE], yGradient[indexNE])
					seMag = self.hypot(xGradient[indexSE], yGradient[indexSE])
					swMag = self.hypot(xGradient[indexSW], yGradient[indexSW])
					nwMag = self.hypot(xGradient[indexNW], yGradient[indexNW])

					# please refer to http://www.tomgibara.com/computer-vision/CannyEdgeDetector.java for algorithm explanation
					if (xGrad * yGrad <= 0.0 ?
						  (xGrad).abs >= (yGrad).abs ?
							  (tmp = (xGrad * gradMag).abs) >= (yGrad * neMag - (xGrad + yGrad).abs * eMag) &&
								tmp > (yGrad * swMag - (xGrad + yGrad).abs * wMag) :
							  (tmp = (yGrad * gradMag).abs) >= (xGrad * neMag - (yGrad + xGrad).abs * nMag) &&
								tmp > (xGrad * swMag - (yGrad + xGrad).abs * sMag) :
						  (xGrad).abs >= (yGrad).abs ?
							  (tmp = (xGrad * gradMag).abs) >= (yGrad * seMag + (xGrad - yGrad).abs * eMag) &&
								tmp > (yGrad * nwMag + (xGrad - yGrad).abs * wMag) :
							  (tmp = (yGrad * gradMag).abs) >= (xGrad * seMag + (yGrad - xGrad).abs * sMag) &&
								tmp > (xGrad * nwMag + (yGrad - xGrad).abs * nMag)
						)
						magnitude[index] = gradMag >= Canny::MAGNITUDE_LIMIT ? Canny::MAGNITUDE_MAX : (MAGNITUDE_SCALE * gradMag).ceil
						# NOTE: The orientation of the edge is not employed by this
						# implementation. It is a simple matter to compute it at
						# this poas: Math.atan2(yGrad, xGrad)
					else
						magnitude[index] = 0
					end
				}
			end
			magnitude
		end

		def self.follow x1, y1, i1, threshold, width, height, data, magnitude
			x0 = x1 == 0 ? x1 : x1 - 1
			x2 = x1 == width - 1 ? x1 : x1 + 1
			y0 = y1 == 0 ? y1 : y1 - 1
			y2 = y1 == height - 1 ? y1 : y1 + 1
		
			data[i1] = magnitude[i1]
			for x in x0..x2
				for y in y0..y2
					i2 = x + y * width
					if ((y != y1 || x != x1) && data[i2] == 0 && magnitude[i2] >= threshold)
						self.follow x, y, i2, threshold, width, height, data, magnitude
						return
					end
				end
			end
		end
	end

    def self.canny file, options = OpenStruct.new
    	options.lowThreshold = 2.5 unless options.lowThreshold && options.lowThreshold >= 0
    	options.highThreshold = 7.5 unless options.highThreshold && options.highThreshold >= 0
    	options.kernelRadius = 2.0 unless options.kernelRadius && options.kernelRadius >= 0.1
    	options.kernelWidth = 16 unless options.kernelWidth && options.kernelWidth >= 2
    	options.color ||= 'black'
    	options.contrastNormalized = !!options.contrastNormalized

		begin
			orig = img_from_file(file)
		rescue
			warn(options.logger, "Skipping invalid file #{file}…")
			return nil
		end
	
		width = orig.columns
		height = orig.rows

		data = []

		for r in 0...height
			for c in 0...width
				data[r*width + c] = (orig.at(c, r) * 256 / Magick::QuantumRange).ceil
			end
		end

		data = Canny::normalizeContrast data if options.contrastNormalized

		magnitude = Canny::computeGradients options.kernelRadius, options.kernelWidth, width, height, data

		data = (0...width*height).map { 0.0 }
		offset = 0
		for y in 0...height
			for x in 0...width
				if (data[offset] == 0 && magnitude[offset] >= (options.highThreshold * Canny::MAGNITUDE_SCALE).ceil)
					Canny::follow(x, y, offset, (options.lowThreshold * Canny::MAGNITUDE_SCALE).ceil, width, height, data, magnitude)
				end
				offset += 1
			end
		end

		edge = Image.new(orig.columns, orig.rows) { 
			self.background_color = options.color 
		}

		for i in 0...data.length
			edge.pixel_color i % width, i / width, Pixel.from_color('white') if data[i] > 0
		end

		edge
	end
  end
end