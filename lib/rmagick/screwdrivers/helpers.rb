# encoding: utf-8

require 'RMagick'

module Magick
  module Screwdrivers

    # ==============================================================
    # ==     Image preparation     =================================
    # ==============================================================

    def self.img_from_file file
      img = Magick::Image::read(file).first

      case img.orientation 
      when Magick::RightTopOrientation
        img.rotate!(90)
      when Magick::BottomRightOrientation
        img.rotate!(180)
      when Magick::LeftBottomOrientation
        img.rotate!(-90)
      end

      img
    end

    # ==============================================================
    # ==     Handy logging     =====================================
    # ==============================================================

    def self.warn logger = nil, msg = nil
      logger.warn(msg) if logger && logger.respond_to?(:warn)
    end
    def self.info logger = nil, msg = nil
      logger.info(msg) if logger && logger.respond_to?(:info)
    end
    def self.debug logger = nil, msg = nil
      logger.debug(msg) if logger && logger.respond_to?(:debug)
    end
  end
end
