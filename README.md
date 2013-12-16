# Rmagick::Screwdrivers

[![Build Status](https://travis-ci.org/mudasobwa/rmagick-screwdrivers.png)](https://travis-ci.org/mudasobwa/rmagick-screwdrivers)
[![Gemnasium](https://gemnasium.com/mudasobwa/rmagick-screwdrivers.png?travis)](https://gemnasium.com/mudasobwa/rmagick-screwdrivers)
[![Gem Version](https://badge.fury.io/rb/rmagick-screwdrivers.png)](http://badge.fury.io/rb/rmagick-screwdrivers)

Simple set of classes and their binary wrappers to make routine operations
with RMagick pleasant:

* **scale** — to scale an image to a set of scaled images with optional
watermark (text and/or date) applied
  * method: `Magick::Screwdrivers.scale`
  * binary: `bin/rmagick_scale`

* **collage** — to produce a collage of a directory with images
  * method: `Magick::Screwdrivers.collage`
  * binary: `bin/rmagick_collage`

* **poster** — to produce a poster from an image (a.k.a demotivator)
  * method: `Magick::Screwdrivers.poster`
  * binary: `bin/rmagick_poster`

## Installation

Add this line to your application's Gemfile:

    gem 'rmagick-screwdrivers'

And then execute:

    $ bundle

Or simply install the gem for binary usage:

    gem install rmagick-screwdrivers

and make heavy use of it:

    $ magick_collage --help
    $ magick_poster -v --font DejaVuSans --type classic ~/img/img1.jpg 'Hello,' 'I’m a poster'

## Usage

    $ magick_poster --help
    $ magick_scale --help
    $ magick_collage --help

## [Ruhoh](http://ruhoh.com) [plugin](http://rocket-science.ru/rmagick-screwdrivers/use-with-ruhoh.html)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

