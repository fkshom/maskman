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

Maskman.add_type :simple do
  add :Dummy
end

Maskman.add_type :common do
  include_type :ipaddress
  include_type :plain
end
