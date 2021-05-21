require 'maskman'

module Maskman
  class PlainPlugin
    def initialize(**kwargs)
      @patterns = []
      @to = ""
      
      kwargs.each{|k, v|
        self.send(k, v)
      }
    end

    def patterns(val)
      pattern(val)
    end

    def pattern(val)
      case val
      when Array
        @patterns += val
      when String
        @patterns << val
      when Regexp
        @pattern << val
      else
        raise "pattern claaa #{val.class} is not supported"
      end
      self
    end

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
  
  class RegexpPlugin
    def initialize(**kwargs)
      @patterns = []
      @to = ""
      
      kwargs.each{|k, v|
        self.send(k, v)
      }
    end
    
    def ignore_case(val)
      @ignore_case = val
    end

    def space_has_any_length(val)
      @space_has_any_length = val
    end

    def patterns(val)
      pattern(val)
    end

    def pattern(val)
      case val
      when Array
        @patterns += val
      when String
        @patterns << val
      when Regexp
        @pattern << val
      else
        raise "pattern claaa #{val.class} is not supported"
      end
      self
    end

    def to(val)
      @to = val
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
