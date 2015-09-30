# encoding: utf-8

module Magick
  module Screwdrivers

    # ==============================================================
    # ==     Image preparation     =================================
    # ==============================================================

    def self.imagify image, silent = false
      img = case image
            when File, String then Magick::Image::read(image).first
            when Image then image
            end

      if img.nil?
        Magick::Screwdrivers.warn(options[:logger], "Skipping invalid image descriptor #{image}…")
        throw ArgumentError.new("Invalid argument in call to imagify descriptor [#{image}]") unless silent
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
