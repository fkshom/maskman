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
    maskman.add_plugin Maskman::RegexpPlugin.new(
      pattern: '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',
      to: "XXX.XXX.XXX.XXX",
      ignore_case: false,
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
    maskman.add_plugin Maskman::RegexpPlugin.new(
      pattern: 'address (?<ipaddr>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) is ok',
      to: 'this address is \k<ipaddr> desu.',
      ignore_case: false,
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
    maskman.add_plugin Maskman::RegexpPlugin.new(
      pattern: 'ipaddr: \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',
      to: 'ipaddr: XXX.XXX.XXX.XXX',
      space_has_any_length: true,
      ignore_case: false,
    )
    maskman.add_plugin Maskman::RegexpPlugin.new(
      pattern: 'netmask: \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',
      to: 'netmask: XXX.XXX.XXX.XXX',
      space_has_any_length: true,
      ignore_case: false,
    )
    actual = maskman.start(text)
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
    maskman = Maskman::Maskman.new
    maskman.add_plugin Maskman::RegexpPlugin.new(
      patterns: ["ProjectX", "John Smith"],
      to: "XXXXXXXX",
      ignore_case: true,
    )
    maskman.add_plugin Maskman::RegexpPlugin.new(
      patterns: ["Jane Smith"],
      to: "YYYYYYY",
      ignore_case: true,
    )
    maskman.add_plugin Maskman::RegexpPlugin.new(
      patterns: ["john doe"],
      to: "ZZZZ",
      ignore_case: false,
    )
    actual = maskman.start(text)
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
    maskman = Maskman::Maskman.new
    maskman.add_plugin Maskman::RegexpPlugin.new(
      pattern: 'filter .+ {',
      to: 'filter FILTERNAME {',
      ignore_case: false,
    )
    maskman.add_plugin Maskman::RegexpPlugin.new(
      pattern: 'term .+ {',
      to: 'term TERMNAME {',
      ignore_case: false,
    )
    actual = maskman.start(text)
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
    maskman = Maskman::Maskman.new
    regexpincrementalplugin = Maskman::RegexpIncrementalPlugin.new(
      patterns: ['(?<pre>filter )(?<filtername>\w+)(?<post>.*)', '(?<pre>use )(?<filtername>\w+)(?<post>.*)'],
      ignore_case: false,
      incremental_suffix_target: :filtername,
    )
    regexpincrementalplugin.on_matched = ->(m, inc){
      "#{m[:pre]}FILTERNAME#{inc}#{m[:post]}"
    }
    maskman.add_plugin regexpincrementalplugin
    actual = maskman.start(text)
    expect(actual).to eq expect
  end
end
