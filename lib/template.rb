require 'haml'
require 'parser/current'

class Template
  attr_reader :name, :dependencies, :references, :contents

  def self.from_file(filename, basename: '')
    contents = File.read filename
    name = filename.sub(/\A#{basename}\/?/, '').sub(/\..*\Z/, '').gsub('/_', '/')

    new(contents, name: name)
  end

  def initialize(body, name:)
    @name = name
    @dependencies = Set.new
    @references = Set.new
    @contents = Set.new

    @root = Haml::Engine.new(body, filename: name).parser.root
    process_tree(@root)
  end

  def to_s
    @name
  end

  # The verbosity of Haml's ParseNodes make the builtin #inspect useless
  def inspect
    "#<#{self.class.name}:#{self.object_id} name:#{name}>"
  end

  private

  def dirname
    File.dirname @name
  end

  def process_tree(haml_node)
    process_haml_node(haml_node)

    haml_node.children.each { |child| process_tree(child) }
  end

  def process_haml_node(haml_node)
    case haml_node.type
    when :script then
      ruby = Parser::CurrentRuby.parse(haml_node.value[:text], file: self.name)
      process_ruby_node(ruby)
    end
  end

  def process_ruby_node(ruby_node)
    case ruby_node.type
    when :yield then process_yield(ruby_node)
    when :send then process_call(ruby_node)
    else
      if ruby_node.children
        ruby_node.children
          .compact
          .select { |child| child.respond_to? :type }
          .each { |child| process_ruby_node(child) }
      end
    end
  end

  def process_yield(ruby_node)
    if ruby_node.children.any?
      # s(:yield,
      #   s(:sym, :header))
      @contents << ruby_node.children.first.children.first.to_s
    else
      @contents << 'YIELD'
    end
  end

  def process_call(ruby_node)
    case ruby_node.children[1]
    when :render then process_render(ruby_node)
    end
  end

  def process_render(ruby_node)
    case ruby_node.children[2].type
    when :symbol, :str
      # s(:send, nil, :render,
      #   s(:str, 'template/name'))
      add_dependency ruby_node.children[2].children[0].to_s
    when :hash
      # s(:send, nil, :render,
      #   s(:hash,
      #     s(:pair,
      #       s(:sym, :partial),
      #       s(:str, "fnord"))))
      ruby_node.children[2].children.detect do |pair|
        key, value = pair
        add_dependency(value) if key.to_s == 'partial'
      end
    when :send
      # s(:send, nil, :render,
      #   s(:send, nil, :onboarding_modal))
      add_reference ruby_node.children[2].children[1].to_s
    end
  end

  def add_dependency(name)
    if name['/']
      @dependencies << name
    else
      @dependencies << File.join(dirname, name)
    end
  end

  def add_reference(name)
    @references << name
  end
end
