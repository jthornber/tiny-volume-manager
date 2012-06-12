#!/usr/bin/env ruby

require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/utils'
require 'lib/fs'
require 'lib/git'
require 'lib/status'
require 'lib/tags'
require 'lib/thinp-mixin'
require 'lib/xml_format'
require 'lib/analysis'

#----------------------------------------------------------------

include XMLFormat

ARGV.each do |path|
  STDERR.puts "analysing #{path}"
  File.open(path, 'r') do |file|
    md = read_xml(file)
    analysis = MetadataAnalysis.new(md)
    #analysis.block_length_histograms
    analysis.fragmentations
  end
end

#----------------------------------------------------------------
