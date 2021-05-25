# frozen_string_literal: true
require 'maskman'

RSpec.describe Maskman do
  describe Maskman::PlainTextPlugin do
    fit "mask" do
      text = <<~EOS
      p@ssw0rd
      s3cr3t
      __p@ssw0rd__
      secret
      p@ssw0rd s3cr3t
      EOS
      expect = <<~EOS
      XXXX
      XXXX
      __XXXX__
      secret
      XXXX XXXX
      EOS
      
      inst = Maskman::PlainTextPlugin.new
      inst.instance_eval do
        patterns ['p@ssw0rd', 's3cr3t']
        to 'XXXX'
      end
      actual = inst.mask text
      expect(actual).to eq expect
    end
  end

  describe Maskman::RegexpPlugin do
    it "mask" do
      text = <<~EOS
      hostname retail
      EOS
      expect = <<~EOS
      hostname XXXXXX
      EOS
      
      inst = Maskman::RegexpPlugin.new
      inst.instance_eval do
        pattern "hostname .+"
        to 'hostname XXXXXX'
      end
      actual = inst.mask text
      expect(actual).to eq expect
    end

    fit "mask4" do
      text = <<~EOS
      hostname retail
      EOS
      expect = <<~EOS
      hostname rXXXXX
      EOS
      
      inst = Maskman::Regexp4Plugin.new
      inst.instance_eval do
        pattern "hostname (?<hostname>.+)"
        on_matched ->(m){
          cap = m[:hostname][0]
          past = "X" * (m[:hostname].length - 1)
          "hostname #{cap}#{past}"
        }
      end
      actual = inst.mask text
      expect(actual).to eq expect
    end

    it "mask" do
      text = <<~EOS
      enable password cisco123
      !
      username jsomeone password 0 cg6#107X
      !
      interface FastEthernet1
        description To Server001
        ip address 192.168.12.1 255.255.255.0
      !
      interface FastEthernet2
        description To Server002
        ip address 192.168.12.2 255.255.255.0
      EOS
      expect = <<~EOS
      enable password XXXXXX
      !
      username jsomeone password 0 XXXXXX
      !
      interface FastEthernet1
        description XXXXXX
        ip address 192.168.12.1 255.255.255.0
      !
      interface FastEthernet2
        description XXXXXX
        ip address 192.168.12.2 255.255.255.0
      EOS
      inst = Maskman::Regexp3Plugin.new
      inst.instance_eval do
        patterns [
          '^enable password (?<pass>.+)',
          '^username [^ ]+ password \d (?<pass>.+)',
          '^\s+description (?<desc>.+)',
          '^s+ip (?<ip>[^ ]+) .+', # nop
        ]
        targets [:pass, 'desc']
        to 'XXXXXX'
      end
      actual = inst.mask text
      expect(actual).to eq expect
    end
  end


end

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

  it "mask" do
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

  it "mask" do
    text = <<~EOS
    Router# show running-config
    Building configuration...
    Current configuration : 3781 bytes
    !
    version 12.3
    no service pad
    service timestamps debug datetime msec
    service timestamps log datetime msec
    no service password-encryption
    !
    hostname retail
    !
    enable password cisco123
    !
    username jsomeone password 0 cg6#107X
    aaa new-model
    !
    interface FastEthernet1
      description To Server001
      ip address 192.168.12.1 255.255.255.0
    !
    interface FastEthernet2
      description To Server002
      ip address 192.168.12.2 255.255.255.0
    !
    user jsomeone nthash 7 0529575803696F2C492143375828267C7A760E1113734624452725707C010B065B
    user AMER\jsomeone nthash 7 0224550C29232E041C6A5D3C5633305D5D560C09027966167137233026580E0B0D
    !
    radius-server host 10.0.1.1 auth-port 1812 acct-port 1813 key cisco123
    EOS
    expect = <<~EOS
    Router# show running-config
    Building configuration...
    Current configuration : 3781 bytes
    !
    version 12.3
    no service pad
    service timestamps debug datetime msec
    service timestamps log datetime msec
    no service password-encryption
    !
    hostname HOSTNAME
    !
    enable password XXXXXX
    !
    username jsomeone password 0 XXXXXX
    aaa new-model
    !
    interface FastEthernet1
      description YYYYYY
      ip address 192.168.12.1 255.255.255.0
    !
    interface FastEthernet2
      description YYYYYY
      ip address 192.168.12.2 255.255.255.0
    !
    user USER nthash 7 ABCDABCD
    user USER nthash 7 ABCDABCD
    !
    radius-server host 10.0.1.1 auth-port 1812 acct-port 1813 key KEY
    EOS
  end
end
