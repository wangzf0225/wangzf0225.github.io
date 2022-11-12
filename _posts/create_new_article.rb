#! /usr/bin/ruby

require 'time'
require 'getoptlong'

options = GetoptLong.new(
  ['--fname', GetoptLong::REQUIRED_ARGUMENT],
  ['--title', GetoptLong::OPTIONAL_ARGUMENT],
  ['--zzz', GetoptLong::NO_ARGUMENT]
)

optHash = {}
options.each do |option, argument|
	optHash.store(option.gsub('-',''),argument)
  # p [option, argument]
end


words = optHash["fname"].split(" ").join("-")

time = Time.new
fileName = time.localtime.strftime("%Y-%m-%d-")+words+'.md'


header = <<-HEAD
---
layout: post
title:  "#{optHash["title"]}"
date: #{time.localtime}
author : Mushen
categories: original
---
HEAD


file = File.new(fileName,'w')
file.puts header
file.close

puts "CREATED NEW FILE: #{fileName}"
puts "WITH A HEADER: #{header}"