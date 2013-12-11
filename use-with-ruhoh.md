---
layout: page
title: 'Use Screwdrivers with Ruhoh'
---

[Ruhoh](http://ruhoh.com/) is the _static site generator_ made for publishing content on the Internet.
One addicted to [jekyll](http://jekyllrb.com/) should give a try to _ruhoh_ as well.

Ruhoh utilizes the same philosophy as jekill does. The user creates structured collection of text files,
using markdown, textile or another markup processor and the generator produces the static site.
Ruhoh supports `rsync` for deployment, uses `mustache` for templating and looks like a jekyll 2.0.

Anyway, I integrated `rmagick-screwdrivers` into ruhoh to make a life easier. The goal I tried to achieve:

* Easily create a post entry with, say, photo-report. Lets imagine you have visited North Pole and made
for about 1K of photos. Then you picked up the top-twenty and decided to share them with your friends.
My plugins to ruhoh come to rescue.

First of all, we definitely want to use HTML5 `figure` tags instead of simple `img`, since we have a couple
of words to say about every picture. To do so, create a file `plugins/converters/markdown.rb` in the
root folder of your ruhoh site with the following content:

    require "redcarpet"

    module Redcarpet
      module RenderHTML5
        # use html5-compliant figures instead of simple images
        # ![Alt text](/path/to/img.jpg "Optional title")
        class WithFigures < Redcarpet::Render::HTML
          def image(link, title, alt)
            "<figure><img src='#{link}' alt='#{alt}' />
               <figcaption><p>#{title}</p></figcaption>
             </figure>"
          end
        end
      end
    end

    class Ruhoh
      module Converter
        module Markdown

          def self.extensions
            ['.md', '.markdown']
          end

          def self.convert(content)
            require 'redcarpet'
            markdown = Redcarpet::Markdown.new(
              Redcarpet::RenderHTML5::WithFigures.new(
                :with_toc_data => true, :encoding => 'UTF-8'
              ),
              :autolink => true,
              :fenced_code_blocks => true,
              :encoding => 'UTF-8'
            )
            markdown.render(content)
          end
        end
      end
    end

Now all the `![Alt](http://path.to/img.jpg "Figure caption"` will be handled by this parser yielding
our images as captioned figures.

The other handy improvement is to generate proper scaffold for post entry. To do so we need:

* scale all the images to normal resolution (you know, these 100M cameras produce really huge jpegs.)
* put all the scaled images to the folder known to ruhoh.
* generate a template for out post with all the pictures inserted in.

The full code of respective `plugins/client_helpers.rb` file may be found at [this gist](https://gist.github.com/mudasobwa/7905881).
I would talk about new generator pattern:

    Help_Image = [
      {
        "command" => "image <img_file> <title>",
        "desc" => "Create a new post with image."
      }
    ]

    def image
      filename, title = filename_and_title @args[3]
      if File.directory?(@args[2])
        # Update summary when new image is to be added to existing folder
        sum_file = "#{File.basename(@args[2]).gsub(/\W/,'-')}.jpg"
        Magick::Screwdrivers.collage(@args[2]).write \
          File.join(@ruhoh.paths.base, "media", sum_file)
        create_template(filename, title, Dir.entries(@args[2]).map { |d|
          File.join(@args[2], d)
        }, sum_file)
      else
        update_template(filename, title, @args[2])
      end
    end

Here we added new default method to `bundle exec ruhoh`. Now we can execute (for _posts_ collection):

    bundle exec ruhoh posts image ~/NorthPole/BestPhotos/ 'North Pole Unleashed'

After a while we yield the new file created in the _posts_ collection and scaled images in `media`
folder. Scaling is customizable within common `config.yml` file:

    images :
      watermark :
        use : true
        date : true
        text : © North Pole Assoc
        min : 200
    scales : [400,600]

Since the processing is done, go edit the newly created file. There is an example of result may be found
[here](http://meme-me.ru/photos/%D0%94%D0%BE%D1%80%D0%BE%D0%B6%D0%BD%D1%8B%D0%B5-%D0%B7%D0%BD%D0%B0%D0%BA%D0%B8/).

