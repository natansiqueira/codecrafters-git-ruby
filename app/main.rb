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

  object_dir = hash[0..1]
  object_sha = hash[2..]
  object_path = File.join('.git', 'objects', object_dir, object_sha)
  raise "Not a valid object name #{hash}" unless File.exist? object_path

  compressed = File.read(object_path)
  uncompressed = Zlib::Inflate.inflate(compressed)
  _, content = uncompressed.split("\0")
  print content
when 'hash-object'
  option = ARGV[1]
  filepath = ARGV[2]
  raise 'You must provide an option. Valid option is -w' if option.nil?
  raise "Unkown option #{option}" unless option == '-w'
  raise 'You must provide a file name' if filepath.nil?

  content = File.open(filepath).read
  object = "blob #{content.size}\0#{content}"
  puts object
else
  raise "Unknown command #{command}"
end
