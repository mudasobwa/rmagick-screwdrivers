# encoding: utf-8

Given(/^a folder "(.*?)" is given as the input$/) do |dir|
  @input = dir
end

Given(/^an image "(.*?)" is given as the input$/) do |file|
  @input = file
  @options = {}
end

Given(/^an output folder "(.*?)" is created$/) do |dir|
  Dir.mkdir dir rescue "Directory exists, continue…"
end

Given(/^everything is logged$/) do
  require 'logger'
  @logger = Logger.new STDOUT 
end

Given(/^"(.*?)" is given as poster type option$/) do |type|
  @options[:type] = type.to_sym
  @options[:stroke] = '#000000' if @options[:type] == :standard
end

# ===================================================================================

When(/^I call the collage method$/) do
  @output = Magick::Screwdrivers::collage @input, {:logger => @logger}
end

When(/^I call the scale method with widths (\d+),(\d+),(\d+)$/) do |arg1, arg2, arg3|
  opts = {
    :logger => @logger,
    :widths => [arg1.to_i,arg2.to_i,arg3.to_i],
    :date_in_watermark => true,
    :watermark => 'rmagick-screwdrivers'
  }
  @output = Magick::Screwdrivers::scale @input, opts
end

When(/^save file to "(.*?)"$/) do |file|
  @output.write File.join(file)
end

When(/^save files with origin "(.*?)"$/) do |orig|
  @output.each { |img|
    img.write("#{orig}-#{img.rows}.#{img.format.downcase}") { self.quality = 90 }
  }
end

When(/^I call the poster method with texts "(.*?)" and "(.*?)"$/) do |text1, text2|
  @options[:logger] = @logger
  @output = Magick::Screwdrivers::poster @input, text1, text2, @options
end


# ===================================================================================

Then(/^the result is created as "(.*?)"$/) do |img|
  expect(@output.inspect).to match(/#{img}/)
end

Then(/^the result is created as an array of size (\d+)$/) do |arg1|
  expect(@output.size).to eql(3)
end
