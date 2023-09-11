# frozen_string_literal: true

require 'zlib'
require 'digest/sha1'
require 'fileutils'
require 'time'

def hash_object(content, type)
  object = "#{type} #{content.length}\0#{content}"
  object_hash = Digest::SHA1.hexdigest object

  object_dir = object_hash[0..1]
  object_sha = object_hash[2..]

  object_content = Zlib::Deflate.deflate object
  object_path = File.join('.git', 'objects', object_dir, object_sha)
  FileUtils.mkdir_p(File.dirname(object_path))
  File.write(object_path, object_content)
  object_hash
end

def write_tree(path)
  tree_objects = []
  children = Dir.children(path).sort

  children.each do |child|
    next if child == '.git'
    hash = ''
    mode = 0
    if File.directory? child
      hash = [write_tree(File.join(path, child))].pack('H*')
      mode = 40000
    else
      content = File.open(File.join(path, child)).read
      hash = [hash_object(content, 'blob')].pack('H*')
      mode = 100644
    end
    tree_objects << "#{mode} #{child}\0#{hash}"
  end
  hash_object(tree_objects.join, 'tree')
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
  path = ARGV[2]

  raise 'You must provide an option. Valid option is -w' if option.nil?
  raise "Unkown option #{option}" unless option == '-w'
  raise 'You must provide a file name' if path.nil?

  content = File.read(path)
  hash = hash_object(content, 'blob')
  puts hash
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
    puts tree_child.scan(/\d+ ([a-zA-Z.]+)$/)
  end
when 'write-tree'
  puts write_tree('.')
when 'commit-tree'
  tree_hash = ARGV[1]
  commit_hash = ARGV[3]
  message = ARGV[5]

  content = <<~COMMIT.strip
    tree #{tree_hash}
    parent #{commit_hash}
    author Natan Siqueira<natanounatan@gmail.com> #{Time.now}
    commiter Natan Siqueira<natanounatan@gmail.com> #{Time.now}

    #{message}
  COMMIT

  hash_object(content, 'commit')
else
  raise "Unknown command #{command}"
end
