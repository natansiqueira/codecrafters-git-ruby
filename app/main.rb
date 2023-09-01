# frozen_string_literal: true

require 'zlib'

command = ARGV[0]

case command
when 'init'
  Dir.mkdir('.git')
  Dir.mkdir('.git/objects')
  Dir.mkdir('.git/refs')
  File.write('.git/HEAD', "ref: refs/heads/master\n")
  puts 'Initialized git directory'
when 'cat-file'
  option = ARGV[1]
  hash = ARGV[2]
  raise 'You must provide an option. Valid option is -p' if option.nil?
  raise "Unkown option #{option}" unless option == '-p'
  raise 'You must provide a hash' if hash.nil?

  blob_dir = hash[0..1]
  blob_sha = hash[2..]
  object_path = File.join('.git', 'objects', blob_dir, blob_sha)
  raise "Not a valid object name #{hash}" unless File.exist? object_path

  compressed = File.read(object_path)
  uncompressed = Zlib::Inflate.inflate(compressed)
  puts uncompressed

else
  raise "Unknown command #{command}"
end
