# frozen_string_literal: true
require 'maskman'

RSpec.describe Maskman do
  before(:all) do
    Maskman.clear_mask_types
  end

  it "mask" do
    text = <<~EOS
    address 192.168.0.1 is ok
    EOS
    expect = <<~EOS
    address XXX.XXX.XXX.XXX is ok
    EOS

    Maskman.add_type :common do
      add :Regexp do
        pattern '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
        to 'XXX.XXX.XXX.XXX'
        ignore_case false
      end
    end

    maskman = Maskman::Maskman.new
    actual = maskman.mask(text, type: :common)
    expect(actual).to eq expect
  end

  fit "mask" do
    text = <<~EOS
    address 192.168.0.1 is ok
    192.168.1.1 is ng
    EOS
    expect = <<~EOS
    address XXX.XXX.XXX.XXX is ok
    192.168.1.1 is ng
    EOS

    Maskman.add_type :common do
      add :Regexp2 do
        pattern '(?<pre>address )(?<ipaddr>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(?<post> is ok)'
        ignore_case false
        on_matched ->(substring, m){
            "#{m[:pre]}XXX.XXX.XXX.XXX#{m[:post]}"
        }
      end
      # add :Regexp3 do
      #   pattern 'address (?<ipaddr>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) is ok'
      #   target :ipaddr
      #   to 'XXX.XXX.XXX.XXX'
      #   ignore_case false
      # end
    end

    maskman = Maskman::Maskman.new
    actual = maskman.mask(text, type: :common)
    expect(actual).to eq expect
  end

  it "mask" do
    text = <<~EOS
    address 192.168.0.1 is ok
    EOS
    expect = <<~EOS
    this address is 192.168.0.1 desu.
    EOS
    
    Maskman.add_type :common do
      add :Regexp do
        pattern 'address (?<ipaddr>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) is ok'
        to 'this address is \k<ipaddr> desu.'
        ignore_case false
      end
    end

    maskman = Maskman::Maskman.new
    actual = maskman.mask(text, type: :common)
    expect(actual).to eq expect
  end

  it "mask" do
    text = <<~EOS
    ipaddr:       192.168.0.1
    netmask:      255.255.255.0
    EOS
    expect = <<~EOS
    ipaddr: XXX.XXX.XXX.XXX
    netmask: XXX.XXX.XXX.XXX
    EOS

    Maskman.add_type :common do
      add :Regexp do
        pattern 'ipaddr: \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
        to 'ipaddr: XXX.XXX.XXX.XXX'
        space_has_any_length true
        ignore_case false
      end
      add :Regexp do
        pattern 'netmask: \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
        to 'netmask: XXX.XXX.XXX.XXX'
        space_has_any_length true
        ignore_case false
      end
    end

    maskman = Maskman::Maskman.new
    actual = maskman.mask(text, type: :common)
    expect(actual).to eq expect
  end

  it "mask" do
    text = <<~EOS
    ProjectName: ProjectX
    Director: John Smith
    Actor: Jane Smith
    Designer: John Doe
    EOS
    expect = <<~EOS
    ProjectName: XXXXXXXX
    Director: XXXXXXXX
    Actor: YYYYYYY
    Designer: John Doe
    EOS

    Maskman.add_type :common do
      add :Regexp do
        patterns ["ProjectX", "John Smith"]
        to "XXXXXXXX"
        ignore_case true
      end
      add :Regexp do
        patterns ["Jane Smith"]
        to "YYYYYYY"
        ignore_case true
      end
      add :Regexp do
        patterns ["john doe"]
        to "ZZZZ"
        ignore_case false
      end
    end

    maskman = Maskman::Maskman.new
    actual = maskman.mask(text, type: :common)
    expect(actual).to eq expect
  end
  
  it "mask" do
    text = <<~EOS
    filter MyFilter {
      term MyTerm {
        src 192.168.0.1
      }
    }
    EOS
    expect = <<~EOS
    filter FILTERNAME {
      term TERMNAME {
        src 192.168.0.1
      }
    }
    EOS

    Maskman.add_type :common do
      add :Regexp do
        pattern 'filter .+ {'
        to 'filter FILTERNAME {'
        ignore_case false
      end
      add :Regexp do
        pattern 'term .+ {'
        to 'term TERMNAME {'
        ignore_case false
      end
    end

    maskman = Maskman::Maskman.new
    actual = maskman.mask(text, type: :common)
    expect(actual).to eq expect
  end

  it "mask" do
    text = <<~EOS
    filter MyFilter {
    filter YourFilter {
    filter OurFilter {
    use MyFilter
    EOS
    expect = <<~EOS
    filter FILTERNAME1 {
    filter FILTERNAME2 {
    filter FILTERNAME3 {
    use FILTERNAME1
    EOS
    
    Maskman.add_type :common do
      add :RegexpIncremental do
        patterns [
          '(?<pre>filter )(?<filtername>\w+)(?<post>.*)',
          '(?<pre>use )(?<filtername>\w+)(?<post>.*)'
        ]
        ignore_case false
        incremental_suffix_target 'filtername'
        on_matched ->(m, inc){
          "#{m[:pre]}FILTERNAME#{inc}#{m[:post]}"
        }
      end
    end

    maskman = Maskman::Maskman.new
    actual = maskman.mask(text, type: :common)
    expect(actual).to eq expect
  end
end
