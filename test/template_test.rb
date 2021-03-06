require 'minitest/autorun'

require 'template'

class TestTemplate < Minitest::Test
  LayoutFile = 'test/app/views/layouts/application.html.haml'

  def test_filename_handling
    template = Template.from_file(LayoutFile, basename: 'test/app/views')
    assert_equal 'layouts/application', template.name
  end

  def test_boring_template
    template = Template.new(".foo hi!\n", name: 'boring.haml')

    assert template.dependencies.empty?
  end

  def test_simple_render
    template = Template.new("= render 'foo/bar'\n", name: 'simple_render.haml')
    dependencies = template.dependencies

    assert_equal 1, dependencies.count
    assert_equal 'foo/bar', dependencies.first
  end

  def test_simple_yield
    template = Template.new("= yield\n", name: 'simple_yield.haml')
    contents = template.contents

    assert_equal 1, contents.count
    assert_equal 'YIELD', contents.first
  end

  def test_haml_block
    template = Template.new("= form_for my_model do\n  %p hi\n", name: 'haml_block.haml')

    assert_equal Set.new(%w{my_model}), template.references
  end

  def test_fixture_template
    template = Template.from_file(LayoutFile, basename: 'test')

    assert_equal Set.new(["layouts/head", "layouts/google_tag_manager", "notices/upgrade_browser", "app/views/layouts/precompiled_asset_warning", "layouts/header", "layouts/feedback", "layouts/footer", "layouts/footer_scripts"]), template.dependencies
    assert_equal Set.new(%w{header content YIELD footer}), template.contents
    assert_equal Set.new(%w{onboarding_modal}), template.references
  end
end
