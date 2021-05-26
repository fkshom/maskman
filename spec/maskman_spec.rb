# frozen_string_literal: true
require 'maskman'

RSpec.describe Maskman do
  describe Maskman::PlainTextPlugin do
    it "PlainTextの単純置換ができる" do
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
    it "マッチしたパターン全体をtoで置換できる" do
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

    it "マッチしたパターン全体を、名前付きキャプチャを利用したtoで置換できる" do
      text = <<~EOS
      address 192.168.0.1 is ok
      EOS
      expect = <<~EOS
      this address is 192.168.0.1 desu.
      EOS

      inst = Maskman::RegexpPlugin.new
      inst.instance_eval do
        pattern 'address (?<ipaddr>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) is ok'
        to 'this address is #{ipaddr} desu.'
        ignore_case false
      end
      actual = inst.mask text
      expect(actual).to eq expect
    end

    it "パターンをignore_caseすることができる" do
      text = <<~EOS
      John Doe
      EOS
      expect = <<~EOS
      ZZZZ
      EOS
      inst = Maskman::RegexpPlugin.new
      inst.instance_eval do
        patterns ["john doe"]
        to "ZZZZ"
        ignore_case true
      end
      actual = inst.mask text
      expect(actual).to eq expect
    end

    it "パターンをignore_caseしないことができる" do
      text = <<~EOS
      John Doe
      EOS
      expect = <<~EOS
      John Doe
      EOS
      inst = Maskman::RegexpPlugin.new
      inst.instance_eval do
        patterns ["john doe"]
        to "ZZZZ"
        ignore_case false
      end
      actual = inst.mask text
      expect(actual).to eq expect
    end

    it "マッチしたパターンに対してMatchDataを使った高度な置換ができる" do
      text = <<~EOS
      hostname retail
      EOS
      expect = <<~EOS
      hostname rXXXXX
      EOS
      
      inst = Maskman::RegexpPlugin.new
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

    it "マッチしたパターンの特定の名前付きキャプチャに対してon_matched_<name>で置換できる" do
      text = <<~EOS
      hostname retail
      EOS
      expect = <<~EOS
      hostname rXXXXX
      EOS
      
      inst = Maskman::RegexpPlugin.new
      inst.instance_eval do
        pattern "hostname (?<hostname>.+)"
        on_matched_hostname ->(m){
          "rXXXXX"
        }
      end
      actual = inst.mask text
      expect(actual).to eq expect
    end

    it "マッチしたパターンの特定の名前付きキャプチャ群(targets)に対してtoで単純置換できる" do
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
      inst = Maskman::RegexpPlugin.new
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

  describe Maskman::RegexpIncrementalPlugin do
    it "名前付きキャプチャをキーとしたIDを生成・利用できる" do
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
      
      inst = Maskman::RegexpIncrementalPlugin.new
      inst.instance_eval do
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
      actual = inst.mask text
      expect(actual).to eq expect
    end
  end
end

RSpec.describe Maskman do
  before(:all) do
    Maskman.clear_mask_types
  end

  it "add_typeが動く" do
    text = "address 192.168.0.1 is ok"
    expect = "address XXX.XXX.XXX.XXX is ok"

    Maskman.add_type :common do
      add :Regexp do
        pattern '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
        to 'XXX.XXX.XXX.XXX'
      end
    end

    maskman = Maskman::Maskman.new
    actual = maskman.mask(text, type: :common)
    expect(actual).to eq expect
  end

  it "addが複数可能" do
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

  it "複数のadd_typeと、type切り替え、include_typeが可能" do
    text = <<~EOS
    ProjectName: ProjectX
    ipaddr:       192.168.0.1
    EOS
    expect = <<~EOS
    ProjectName: XXXXXXXX
    ipaddr: XXX.XXX.XXX.XXX
    EOS
    Maskman.add_type :term do
      add :Regexp do
        patterns ["ProjectX"]
        to "XXXXXXXX"
        ignore_case true
      end
    end
    Maskman.add_type :ipaddress do
      add :Regexp do
        pattern 'ipaddr: \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
        to 'ipaddr: XXX.XXX.XXX.XXX'
        space_has_any_length true
        ignore_case false
      end
    end
    Maskman.add_type :common do
      include_type :term
      include_type :ipaddress
    end

    maskman = Maskman::Maskman.new
    actual = maskman.mask(text, type: :common)
    expect(actual).to eq expect
  end
  
  it "ネットワーク機器向けのサンプル1" do
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

  it "ネットワーク機器向けのサンプル2" do
    text = <<~EOS
    filter MyFilter {
      term TERM-A {
      }
    }
    filter YourFilter {
      term TERM-B {
      }
    }
    filter OurFilter {
      term TERM-C {
      }
    }
    use MyFilter
    EOS
    expect = <<~EOS
    filter FILTERNAME1 {
      term TERM-A {
      }
    }
    filter FILTERNAME2 {
      term TERM-B {
      }
    }
    filter FILTERNAME3 {
      term TERM-C {
      }
    }
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

  it "ネットワーク機器向けのサンプル3" do
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
    user jsomeone nthash 7 1234567890
    user AMER\jsomeone nthash 7 12345678901234567890
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
    username XXXXXX password 0 XXXXXX
    aaa new-model
    !
    interface FastEthernet1
      description XXXXXX
      ip address 192.168.12.1 255.255.255.0
    !
    interface FastEthernet2
      description XXXXXX
      ip address 192.168.12.2 255.255.255.0
    !
    user jXXXXXXX nthash 7 XXXXXXXXXX
    user AXXXXXXXXXXX nthash 7 XXXXXXXXXXXXXXXXXXXX
    !
    radius-server host 10.0.1.1 auth-port 1812 acct-port 1813 key XXXXXX
    EOS
    
    Maskman.add_type :common do
      add :Regexp do
        pattern 'hostname (?<MASK>.+)'
        targets [:MASK]
        to 'HOSTNAME'
      end
      add :Regexp do
        patterns [
          'user (?<USER>.+) nthash 7 (?<PASS>.+)'
        ]
        on_matched_USER ->(m){
          matched_string = m[:USER]
          first_char, past_chars = matched_string[0], matched_string[1..-1]
          first_char + 'X' * past_chars.length
        }
        on_matched_PASS ->(m){
          matched_string = m[:PASS]
          'X' * matched_string.length
        }
      end
      add :Regexp do
        patterns [
          'enable password (?<MASK>.+)',
          'username (?<MASK>.+) password \d (?<MASK1>.+)',
          '  description (?<MASK>.+)',
          'radius-server host 10.0.1.1 auth-port 1812 acct-port 1813 key (?<MASK>.+)'
        ]
        targets [:MASK, :MASK1]
        to 'XXXXXX'
      end
    end

    maskman = Maskman::Maskman.new
    actual = maskman.mask(text, type: :common)
    expect(actual).to eq expect
  end
end
