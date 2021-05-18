# frozen_string_literal: true

require_relative "maskman/version"
require 'thor'

module Maskman
  class Error < StandardError; end

  class CLI < Thor
    desc "unko", "unko"
    def mask
      Maskman.new.start("text")
    end
  end
end


module Maskman
  class Simple
  end
  
  class Maskman
    def initialize
      @rules = []
    end

    def add_rule(**kwargs)
      @rules << kwargs
    end

    # @param ptext [String]
    def start(ptext)
      text = ptext.dup
      pp text
      @rules.each{|rule|
        pp rule
        regexp = rule[:regexp]
        if rule[:space_has_any_length]
          regexp = regexp.gsub(" ", '\s*')
        end
        text.gsub!(Regexp.new(regexp), rule[:to])
      }
      pp text

      return text
    end
  end
end
