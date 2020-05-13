#!/usr/local/bin/ruby
# frozen_string_literal: true

require "json"
require "erb"
require "fileutils"

descriptions = JSON.parse(File.read("./device_descriptors.json"))

template = <<~RUBY
  module Rammus
    DEVICE_DESCRIPTORS = {
  <% descriptions.each.with_index do |description, i| -%>
      "<%= description["name"] %>" => {
        user_agent: "<%= description["userAgent"] %>",
        viewport: {
  <% description["viewport"].each_with_index do |(key, value), i| -%>
          <%= underscore(key) %>: <%= value %><% if i < description["viewport"].size - 1 then %>,<% end %>
  <% end -%>
        }
      }<% if i < descriptions.size - 1 then %>,<% end %>
  <% end -%>
    }
    private_constant :DEVICE_DESCRIPTORS
  end
RUBY

def underscore(word)
  word
    .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
    .gsub(/([a-z\d])([A-Z])/, '\1_\2')
    .tr("-", "_")
    .downcase
end

File.open("lib/rammus/device_descriptors.rb", "w") do |descriptors_file|
  descriptors_file.write ERB.new(template, trim_mode: "-<>").result(binding)
end
