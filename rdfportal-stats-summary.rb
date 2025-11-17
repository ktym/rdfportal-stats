#!/usr/bin/env ruby
#
# % ruby rdfportal-stats-summary.rb rdfportal-stats.txt > rdfportal-stats-summary.txt
#

summary = Hash.new(0)

File.open(ARGV.shift) do |f|
  f.gets # header
  f.each_line
   .map(&:chomp)
   .sort
   .uniq
   .each do |line|
     endpoint, dataset, graph, count = line.split("\t")
     summary[dataset] += count.to_i 
   end
end

summary.sort_by{|k, v| -v}.each do |dataset, count|
  puts [dataset, count].join("\t")
end


