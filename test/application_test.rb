require 'minitest/autorun'

require 'application'


class TestApplication < Minitest::Test
  def test_finding_templates
    app = Application.new('test')

    assert_equal 1, app.templates.count
    assert app.templates.has_key?('layouts/application')
  end

  def test_graph
    app = Application.new('test')
    app.to_graph.output png: 'test/graph_output.png'

    assert File.exist?('test/graph_output.png')
  end
end
