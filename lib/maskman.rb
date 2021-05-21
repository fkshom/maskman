# frozen_string_literal: true

require "maskman/version"
require 'maskman/plugin'
require 'thor'

module Maskman
  class Error < StandardError; end

  class CLI < Thor
    desc "mask SRC [DST]", "mask SRC [DST]"
    method_option :type, :default => "common"
    def mask(srcfilename, dstfilename=nil)
      text = File.read(srcfilename)

      result = Maskman.new.mask(text, type: options[:type].to_sym)

      if dstfilename.nil?
        dstfilename = srcfilename + ".filtered.txt"
      end
      File.write(dstfilename, result)
    end
  end
end

module Maskman
  class MaskType
    attr_reader :plugins
    def initialize
      @plugins = []
    end

    def include_type(typename)
      @plugins << typename
    end
  
    def add(pluginname, &block)
      klass = Kernel.const_get("Maskman::" + pluginname.to_s + "Plugin")
      instance = klass.new
      instance.instance_eval(&block)
      @plugins << instance
    end
  end

  def self.clear_mask_types
    @mask_types = {}
  end

  def self.mask_types
    @mask_types
  end
  @mask_types = {}
  
  def self.add_type(typename, &block)
    t = MaskType.new
    t.instance_eval(&block)
    @mask_types[typename] = t
  end
  
  class Maskman
    def initialize
    end

    def mask(text, type: :all)
      ::Maskman.mask_types[type].plugins.each{|plugin|
        if Symbol === plugin
          text = self.mask(text, type: plugin)
        else
          text = plugin.mask(text)
        end
      }
      text
    end
  end
end

Dir[File.dirname(__FILE__) + '/../rules/*.rb'].each {|file|
  pp file
  require file
}
