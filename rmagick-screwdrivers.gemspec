$:.push File.expand_path("../lib", __FILE__)
require 'rmagick/screwdrivers/version'

Gem::Specification.new do |s|
  s.name = 'rmagick-screwdrivers'
  s.version = Magick::Screwdrivers::VERSION
  s.platform = Gem::Platform::RUBY
  s.license = 'MIT'
  s.date = '2013-10-26'
  s.authors = ['Alexei Matyushkin']
  s.email = 'am@mudasobwa.ru'
  s.homepage = 'http://github.com/mudasobwa/rmagick-screwdrivers'
  s.summary = %Q{RMagick addons for utilizing some common tasks}
  s.description = %Q{Creating collages, demotivators and other handy stuff with RMagick}
  s.extra_rdoc_files = [
    'LICENSE',
    'README.md',
  ]

  s.required_rubygems_version = Gem::Requirement.new('>= 1.3.7')
  s.rubygems_version = '1.3.7'
  s.specification_version = 3

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.bindir        = 'bin'
  s.executables   = ['magick_collage', 'magick_poster', 'magick_scale']
  s.require_paths = ['lib']

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'yard-cucumber'  
  s.add_development_dependency 'bueller'

  s.add_dependency 'rmagick'
  s.add_dependency 'ropencv'
end

