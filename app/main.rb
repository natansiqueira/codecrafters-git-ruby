# frozen_string_literal: true

command = ARGV[0]

case command
when 'init'
  Dir.mkdir('.git')
  Dir.mkdir('.git/objects')
  Dir.mkdir('.git/refs')
  File.write('.git/HEAD', "ref: refs/heads/master\n")
  puts 'Initialized git directory'
else
  raise "Unknown command #{command}"
end
