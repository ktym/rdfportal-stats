#!/usr/bin/env ruby
#
# % git clone https://github.com/rdfportal/rdfportal-config.git
# % ruby -d rdfportal-stats.rb > rdfportal-stats.txt 2> rdfportal-stats.err
# Error: biosampleplus is not registered in endpoints
# Error: pbo is not registered in endpoints
#

require "rubygems"
require "net/http"
require "uri"
require "cgi"
require "json"  # gem install json
require 'yaml'

class SPARQL
  def initialize(url)
    @endpoint = url
    uri = URI.parse(url)

    @scheme = uri.scheme
    @host = uri.host
    @port = uri.port
    @path = uri.path

    @user = uri.user
    @pass = uri.password

    @prefix_hash = {}

    Net::HTTP.version_1_2
  end

  def query(sparql)
    result = ""
    use_ssl = @scheme == "https" ? true : false
    format = "application/sparql-results+json"

    Net::HTTP.start(@host, @port, :use_ssl => use_ssl) do |http|
      if timeout = ENV['SPARQL_TIMEOUT']
        http.read_timeout = timeout.to_i
      end
      path = "#{@path}?query=#{CGI.escape(sparql)}"
      req = Net::HTTP::Get.new(path, {"Accept" => "#{format}"})
      if @user and @pass
        req.basic_auth @user, @pass
      end
      http.request(req) { |res|
        result += res.body
      }
    end
    return JSON.parse(result)
  end
end

COUNT_SPARQL = "SELECT (count(*) as ?count) WHERE { GRAPH <@@> { ?s ?p ?o . } }"

datasets = {}

Dir.glob("rdfportal-config/endpoints/*.yml").each do |file|
  yaml = YAML.load(File.read(file))
  endpoint = File.basename(file, File.extname(file))
  yaml["load"]["datasets"].each do |hash|
    dataset = hash["name"]
    datasets[dataset] = {"endpoint" => "https://rdfportal.org/#{endpoint}/sparql"}
  end
end

Dir.glob("rdfportal-config/datasets/*/graph.tsv").each do |file|
  dataset = File.basename(File.dirname(file))
  graphs = []
  File.open(file).each do |line|
    next if line[/^pattern/]
    graph = line.strip.split("\t").last
    graphs << graph
  end
  if datasets[dataset]
    datasets[dataset].merge!({"graphs" => graphs})
  else
    $stderr.puts "Error: #{dataset} is not registered in endpoints"
  end
end

$stderr.puts datasets.inspect if $DEBUG

puts %w(endpoint dataset graph count).join("\t")

datasets.each do |dataset, hash|
  endpoint = hash["endpoint"]
  serv = SPARQL.new(endpoint)

  graphs = hash["graphs"]
  graphs.each do |graph|
    sparql = COUNT_SPARQL.sub("@@", graph)
    count = 0
    begin
      json = serv.query(sparql)
      count = json["results"]["bindings"].first["count"]["value"]
    rescue => e
      $stderr.puts [e.message, endpoint, dataset, graph, count].join("\t")
      $stderr.puts sparql if $DEBUG
      $stderr.puts response if $DEBUG
    ensure
      puts [endpoint, dataset, graph, count].join("\t")
    end
  end
end
