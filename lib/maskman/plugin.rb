require 'maskman'

module Maskman
  class PluginBase
    def mask(text)
      raise "Must be implemented in subclass"
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

    def targets(val)
      @on_matched_ ||= {}
      [val].flatten.each{|target|
        @on_matched_[target.to_s] = ->(m){
          @to
        }
      }
    end

    def method_missing(name, *blk)
      @on_matched_ ||= {}
      if name =~ %r"on_matched_(.+)"
        target = $1
        @on_matched_[target] = blk.first
      end
    end
    
    def on_matched(val)
      @on_matched = val
    end

    def mask(text)
      @on_matched_ ||= {}
      @patterns.each{|pattern|
        option = @ignore_case ? Regexp::IGNORECASE : nil
        pattern = pattern.gsub(" ", '\s+') if @space_has_any_length
        text = text.gsub(Regexp.new(pattern, option)){|_|
          m = Regexp.last_match
          substring = m[0]
          mm = Regexp.new(pattern).match(substring)
          if @on_matched
            substring = @on_matched.call(mm)
          end

          unless @on_matched_ == {}
            mm.names.reverse.each{|target|
              if @on_matched_.key?(target)
                replaced = @on_matched_[target].call(mm)
                substring = TextReplacer.replace(substring, mm, target, replaced)
              end
            }
          end

          if @on_matched.nil? and @on_matched_ == {}
            m = Regexp.new(pattern, option).match(substring)
            bind = binding
            m.names.each{|name|
              bind.local_variable_set(name.to_sym, m[name])
            }
            substring = bind.eval('"' + @to + '"')
          end
          substring
        }
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

  class Ipv4AddressPlugin < RegexpPlugin
    def initialize(**kwargs)
      super(**kwargs)
      @patterns = [
        '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'
      ]
      @on_matched = ->(m){
        substring = m[0]
        if Resolv::IPv4::Regex =~ substring
          return @to
        else
          return substring
        end
      }
    end
  end

  class Ipv4AddressWithMaskLengthPlugin < RegexpPlugin
    def initialize(**kwargs)
      super(**kwargs)
      @patterns = [
        '\b(?<ipaddr>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(?<masklen>\d{1,2})\b'
      ]
      @on_matched = ->(m){
        ipaddr = m[:ipaddr]
        masklen = m[:masklen].to_i
        if Resolv::IPv4::Regex =~ ipaddr && (0 <= masklen && masklen <= 32)
          return @to
        else
          return substring
        end
      }
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
      text[b...e] = replacer
      text
    end
  end

end

