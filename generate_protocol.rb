#!/usr/local/bin/ruby

require "json"
require "erb"
require "fileutils"

template = <<-RUBY
module Chromiebara
  module Protocol
    module <%= domain.name %>
      extend self<% domain.commands.each do |command| %>

<% command.description.lines.each do |line| %>      # <%= line %><% end %>
      # <% if command.has_parameter_descriptions? then %><% command.parameters_with_descriptions.each do |parameter| %>
      # <%= parameter.yard_doc %><% end %><% end %>
      #
      def <%= underscore(command.name) %><%= command.parameters_header %>
        {
          method: "<%= domain.name %>.<%= command.name %>"<% if command.has_parameters? then %>,
          params: { <%= command.parameters_body %> }.compact<% end %>
        }
      end<% end %>
    end
  end
end
RUBY

protocol_template = <<-RUBY
module Chromiebara
  module Protocol<% protocol.domains.each do |domain| %>
      autoload :<%= domain.name %>, "chromiebara/protocol/<%= underscore(domain.name)%>.rb"<% end %>
  end
end
RUBY

Protocol = Struct.new(:domains) do
  def self.from_json(json)
    new(json["domains"].map { |domain| Domain.from_json domain })
  end
end
Domain = Struct.new(:name, :commands) do
  def self.from_json(json)
    new(
      json["domain"],
      json["commands"].map { |command| Command.from_json command }
    )
  end
end
Command = Struct.new(:name, :parameters, :returns, :description, :experimental) do
  def self.from_json(json)
    new(
      json["name"],
      json.fetch("parameters", []).map { |parameter| Parameter.from_json parameter },
      [], # TODO returns
      json["description"] || "",
      json["experimental"]
    )
  end

  def has_description?
    !description.nil?
  end

  def has_parameter_descriptions?
    !parameters_with_descriptions.empty?
  end

  def parameters_with_descriptions
    parameters.select(&:has_description?)
  end

  def has_parameters?
    !parameters.empty?
  end

  def parameters_header
    return '' unless has_parameters?

  "(#{parameters.map(&:header).join(", ")})"
  end

  def parameters_body
    parameters
      .map { |p| "#{p.name}: #{underscore(p.name)}" }
      .join(", ")
  end
end
Parameter = Struct.new(:name, :type, :optional, :experimental, :description) do
  def self.from_json(json)
    new(
      json["name"],
      json["type"] || json["$ref"],
      json["optional"],
      json["experimental"],
      json["description"]
    )
  end

  def has_description?
    !description.nil?
  end

  def header
    [
      "#{underscore(name)}:",
      optional ? " nil" : nil
    ].compact.join
  end

  def yard_doc
    "@param #{underscore(name)} [#{type.capitalize}] #{description.strip.gsub(/\s+/, ' ')}"
  end
end

def underscore(word)
  word
    .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
    .gsub(/([a-z\d])([A-Z])/,'\1_\2')
    .tr("-", "_")
    .downcase
end

path = "lib/chromiebara/protocol/"
FileUtils.mkdir_p path
protocol = Protocol.from_json(JSON.parse(File.read("./protocol.json")))

File.open("lib/chromiebara/protocol.rb", "w") do |protocol_file|
  protocol_file.write ERB.new(protocol_template).result(binding)
end

protocol.domains.each do |domain|
  File.open("#{path}#{underscore(domain.name)}.rb", "w") do |domain_file|
    domain_file.write ERB.new(template).result(binding)
  end
end