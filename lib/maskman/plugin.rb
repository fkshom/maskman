require 'maskman'

module Maskman
  class PluginBase
    def mask(text)
      raise "Must be implemented in subclass"
    end
  end

  class DummyPlugin < PluginBase
    def mask(text)
      test
    end
  end

  class PlainTextPlugin < PluginBase
    def initialize(**kwargs)
      @patterns = []
      @to = ""
      
      kwargs.each{|k, v|
        self.send(k, v)
      }
    end

    def pattern(val)
      case val
      when Array
        @patterns += val
      when String, Regexp, Integer
        @patterns << val
      else
        raise "pattern class #{val.class} is not supported"
      end
      self
    end

    alias :patterns :pattern

    def to(val)
      @to = val
    end

    def mask(text)
      @patterns.each{|pattern|
        text = text.gsub(pattern, @to)
      }
      text
    end
  end
  
  class RegexpPlugin < PlainTextPlugin
    def ignore_case(val)
      @ignore_case = val
    end

    def space_has_any_length(val)
      @space_has_any_length = val
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

  class RegexpIncrementalPlugin < RegexpPlugin
    def initialize(**kwargs)
      super(**kwargs)
      @target_texts = []
    end

    def incremental_suffix_target(val)
      @incremental_suffix_target = val.to_sym
    end

    def on_matched(proc)
      @on_matched = proc
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

  
  class Regexp2Plugin < RegexpPlugin
    def ignore_case(val)
      @ignore_case = val
    end

    def space_has_any_length(val)
      @space_has_any_length = val
    end
    
    def on_matched(proc)
      @on_matched = proc
    end

    def mask(text)
      @patterns.each{|pattern|
        regexpopt = @ignore_case ? Regexp::IGNORECASE : nil
        text = text.gsub(Regexp.new(pattern, regexpopt)){|_|
          m = Regexp.last_match
          substring = m[0]
          mm = Regexp.new(pattern).match(substring)
          replace = @on_matched.call(substring, mm)
          replace
        }
      }
      text
    end
  end

  
  class Regexp3Plugin < RegexpPlugin
    def targets(val)
      @targets ||= []
      case val
      when Array
        @targets += val
      when String, Regexp, Integer
        @targets << val
      else
        raise "target class #{val.class} is not supported"
      end
      self
    end

    def mask(text)
      @patterns.each{|pattern|
        text = text.gsub(Regexp.new(pattern)){|_|
          m = Regexp.last_match
          substring = m[0]
          mm = Regexp.new(pattern).match(substring)
          @targets.each{|target|
            if mm.names.include?(target.to_s)
              substring = TextReplacer.replace(substring, mm, target, @to)
            end
          }
          substring
        }
      }
      text
    end
  end

  class Regexp4Plugin < RegexpPlugin
    def targets(val)
      @targets ||= []
      case val
      when Array
        @targets += val
      when String, Regexp, Integer
        @targets << val
      else
        raise "target class #{val.class} is not supported"
      end
      self
    end

    def on_matched(val)
      @on_matched = val
    end

    def mask(text)
      @patterns.each{|pattern|
        text = text.gsub(Regexp.new(pattern)){|_|
          m = Regexp.last_match
          @on_matched.call(m)
        }
      }
      text
    end
  end

  class TextReplacer2
    def initialize
      @m = m
      @substring = m[0]
    end
    def replace(n_or_key, replacer)
      b = @m.begin(n_or_key)
      e = @m.end(n_or_key)
      text[b..e] = replacer
      text
    end
    def text
      @substring
    end
  end
  
  module TextReplacer
    def self.replace(text, m, n_or_key, replacer)
      b = m.begin(n_or_key)
      e = m.end(n_or_key)
      text[b..e] = replacer
      text
    end
  end

end

