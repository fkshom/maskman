require 'maskman'

Maskman.add_type :ipaddress do
  add :Regexp do
    patterns [
      '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d\d(?=[^\d])',
      '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d(?=[^d])',
    ]
    to 'XXX.XXX.XXX.XXX/XX'
  end
  
  add :Regexp do
    pattern '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
    to 'XXX.XXX.XXX.XXX'
  end
end

Maskman.add_type :plain do
  add :PlainText do
    patterns ['p@ssw0rd', 's3cr3t']
    to 'YYYY'
  end
end

require 'resolv'
Maskman.add_type :exactipaddress do
  add :Regexp do
    pattern "\b#{Resolv::IPv4::Regex}\b"
    to 'XXX.XXX.XXX.XXX'
  end
  add :Regexp do
    pattern "\b#{Resolv::IPv4::Regex}/#{Resolv::IPv4::Regex}\b"
    to 'XXX.XXX.XXX.XXX/XXXX.XXXX.XXXX.XXXX'
  end
  add :Regexp do
    pattern "\b#{Resolv::IPv4::Regex}/\d{1,2}\b"
    to 'XXX.XXX.XXX.XXX/XX'
  end
  add :Regexp do
    pattern "\b#{Resolv::IPv6::Regex}\b"
    to 'xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx'
  end
end

Maskman.add_type :common do
  include_type :ipaddress
  include_type :plain
end
