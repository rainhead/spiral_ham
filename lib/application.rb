require 'graphviz'

require 'template'

class Application
  attr_reader :templates

  def initialize(root)
    @root = root

    view_root = File.join(@root, 'app/views')
    all_views = all_views_in(view_root)
    templates = all_views.map do |filename|
      Template.from_file(filename, basename: view_root)
    end.compact

    @templates = templates.inject({}) do |hash, template|
      hash[template.name] = template
      hash
    end
  end

  def to_graph
    GraphViz::new(:G, type: :digraph) do |graph|
      @templates.each_key do |name|
        graph.add_nodes name
      end

      @templates.each do |template_name, template|
        template.dependencies.each do |dependency|
          graph.add_edges template_name, dependency
        end
      end
    end
  end

  private

  def all_views_in(dir)
    Dir.glob(File.join(dir, '**/*.haml'))
  end
end
