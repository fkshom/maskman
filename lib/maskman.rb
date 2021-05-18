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
  class Plugin
  end
  
  class Maskman
    def initialize
      @rules = []
      @plugins = []
    end

    def add_plugin(instance)
      @plugins << instance
    end

    def add_rule(**kwargs)
      @rules << kwargs
    end

    # @param ptext [String]
    def start(ptext)
      text = ptext.dup
      @plugins.each{|plugin|
        text = plugin.mask(text)
      }
      text
    end
  end
end
module Maskman
  class RegexpPlugin
    def initialize(**kwargs)
      @patterns = []
      @patterns += kwargs[:patterns] if kwargs.has_key?(:patterns)
      @patterns << kwargs[:pattern] if kwargs.has_key?(:pattern)
      @to = kwargs[:to]
      @ignore_case = kwargs[:ignore_case]
      @space_has_any_length = kwargs[:space_has_any_length]
    end

    def mask(text)
      @patterns.each{|pattern|
        ignore_case = @ignore_case ? Regexp::IGNORECASE : nil
        if @space_has_any_length
          pattern = pattern.gsub(" ", '\s+')
        end
        text = text.gsub(Regexp.new(pattern, ignore_case), @to)
      }
      text
    end
  end

  class RegexpIncrementalPlugin
    attr_accessor :on_matched
    def initialize(**kwargs)
      @patterns = []
      @patterns += kwargs[:patterns] if kwargs.has_key?(:patterns)
      @patterns << kwargs[:pattern] if kwargs.has_key?(:pattern)
      @to = kwargs[:to]
      @ignore_case = kwargs[:ignore_case]
      @space_has_any_length = kwargs[:space_has_any_length]
      @incremental_suffix_target = kwargs[:incremental_suffix_target]
      @target_texts = []
      @on_matched = nil
    end

    def get_id(text)
      unless @target_texts.include?(text)
        @target_texts << text
      end
      @target_texts.find_index(text) + 1
    end

    def mask(text)
      @patterns.each{|pattern|
        ignore_case = @ignore_case ? Regexp::IGNORECASE : nil
        if @space_has_any_length
          pattern = pattern.gsub(" ", '\s+')
        end
        text = text.gsub(Regexp.new(pattern, ignore_case)){|_|
          m = Regexp.last_match
          target_text = m[ @incremental_suffix_target ]
          @on_matched.call(m, get_id(target_text))
        }
      }
      text
    end
  end
end

module Maskman
  class IpAddressPlugin
    def mask(text)
      text.gsub(%r'(?<b>[^d])\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?<a>[^\d])', '\k<b>XXX.XXX.XXX.XXX\k<a>')
    end
  end
end

# mask --type juniper from to