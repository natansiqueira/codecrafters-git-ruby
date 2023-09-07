# frozen_string_literal: true

require 'zlib'
require 'digest/sha1'
require 'fileutils'

def hash_object(file_path)
  file_content = File.open(file_path).read

  object = "blob #{file_content.size}\0#{file_content}"
  object_hash = Digest::SHA1.hexdigest object

  object_dir = object_hash[0..1]
  object_sha = object_hash[2..]

  object_content = Zlib::Deflate.deflate object
  object_path = File.join('.git', 'objects', object_dir, object_sha)
  FileUtils.mkdir_p(File.dirname(object_path))
  File.open(object_path, 'w') { |f| f.write(object_content) }
  object_hash
end

def write_tree(path)
  files = Dir.children(path)
             .reject { |file| file.start_with?('.') }

  tree_content = ''

  files.each_with_object(tree_content) do |file|
    object_hash = File.directory? file ? 'dir' : hash_object(file) 
    file_mode = format('%o', File.stat(file).mode)
    tree_content = tree_content + "#{file_mode} #{file}\0 #{object_hash}"
  end

  object = "tree #{tree_content.length}\0#{tree_content}"
  puts tree_content
  puts 'length', tree_content.length
  object_hash = Digest::SHA1.hexdigest object
  object_dir = object_hash[0..1]
  object_sha = object_hash[2..]

  object_content = Zlib::Deflate.deflate object
  object_path = File.join('.git', 'objects', object_dir, object_sha)
  FileUtils.mkdir_p(File.dirname(object_path))
  File.open(object_path, 'w') { |f| f.write(object_content) }
  object_hash
end

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
  object_hash = ARGV[2]

  raise 'You must provide an option. Valid option is -p' if option.nil?
  raise "Unkown option #{option}" unless option == '-p'
  raise 'You must provide a hash' if object_hash.nil?

  object_dir = object_hash[0..1]
  object_sha = object_hash[2..]
  object_path = File.join('.git', 'objects', object_dir, object_sha)

  raise "Not a valid object hash #{hash}" unless File.exist? object_path

  compressed = File.read(object_path)
  uncompressed = Zlib::Inflate.inflate(compressed)
  _, content = uncompressed.split("\0")
  print content
when 'hash-object'
  option = ARGV[1]
  file_path = ARGV[2]

  raise 'You must provide an option. Valid option is -w' if option.nil?
  raise "Unkown option #{option}" unless option == '-w'
  raise 'You must provide a file name' if file_path.nil?

  object_hash = hash_object(file_path)
  puts object_hash
when 'ls-tree'
  option = ARGV[1]
  tree_hash = ARGV[2]

  raise 'You must provide an option. Valid option is --name-only' if option.nil?
  raise "Unkown option #{option}" unless option == '--name-only'
  raise 'You must provide a hash' if tree_hash.nil?

  tree_dir = tree_hash[0..1]
  tree_hash = tree_hash[2..]
  tree_path = File.join('.git', 'objects', tree_dir, tree_hash)

  raise "Not a valid object hash #{tree_hash}" unless File.exist? tree_path

  compressed = File.read(tree_path)
  uncompressed = Zlib::Inflate.inflate(compressed)
  tree_object = uncompressed.split("\0")
  tree_object.each do |tree_child|
    file = tree_child.scan(/[a-zA-Z]{2,}$/)
    puts file
  end
when 'write-tree'
  object_hash = write_tree '.'
  puts object_hash
else
  raise "Unknown command #{command}"
end
