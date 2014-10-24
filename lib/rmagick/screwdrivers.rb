require "rmagick/screwdrivers/version"
require "rmagick/screwdrivers/helpers"
require "rmagick/screwdrivers/poster"
require "rmagick/screwdrivers/collage"
require "rmagick/screwdrivers/scale"
require "rmagick/screwdrivers/hough"
require "rmagick/screwdrivers/sobel"
require "rmagick/screwdrivers/canny"
require "rmagick/screwdrivers/radon"

module Magick
  module Screwdrivers
    class << self
      attr_reader :options
    end
    @options = {
      :logger => nil
    }
  end
  class Image # monkeypatch
    # (0.299 * px.red + 0.587 * px.green + 0.114 * px.blue).ceil
    def at x, y
      self.pixel_color(x, y).intensity
    end
  end

end
