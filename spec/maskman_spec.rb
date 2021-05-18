# frozen_string_literal: true

RSpec.describe Maskman do
  it "mask" do
    text = <<~EOS
    address 192.168.0.1 is ok
    EOS
    expect = <<~EOS
    address XXX.XXX.XXX.XXX is ok
    EOS
    maskman = Maskman::Maskman.new
    maskman.add_rule(
      regexp: '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',
      to: "XXX.XXX.XXX.XXX"
    )
    actual = maskman.start(text)
    expect(actual).to eq expect
  end

  it "mask" do
    text = <<~EOS
    address 192.168.0.1 is ok
    EOS
    expect = <<~EOS
    this address is 192.168.0.1 desu.
    EOS
    maskman = Maskman::Maskman.new
    maskman.add_rule(
      regexp: 'address (?<ipaddr>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) is ok',
      to: 'this address is \k<ipaddr> desu.'
    )
    actual = maskman.start(text)
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
    maskman = Maskman::Maskman.new
    maskman.add_rule(
      regexp: 'ipaddr: \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',
      to: 'ipaddr: XXX.XXX.XXX.XXX',
      space_has_any_length: true,
    )
    maskman.add_rule(
      regexp: 'netmask: \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',
      to: 'netmask: XXX.XXX.XXX.XXX',
      space_has_any_length: true,
    )
    actual = maskman.start(text)
    expect(actual).to eq expect
  end

end
