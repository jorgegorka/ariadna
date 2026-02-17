require "test_helper"
require "ariadna/tools/frontmatter"

class FrontmatterTest < Minitest::Test
  def test_extract_simple
    content = "---\nphase: 1\nplan: 2\ntype: execute\n---\n\n# Body"
    fm = Ariadna::Tools::Frontmatter.extract(content)
    assert_equal "1", fm["phase"]
    assert_equal "2", fm["plan"]
    assert_equal "execute", fm["type"]
  end

  def test_extract_with_array
    content = "---\ntags:\n  - auth\n  - api\n---\n\nBody"
    fm = Ariadna::Tools::Frontmatter.extract(content)
    assert_equal %w[auth api], fm["tags"]
  end

  def test_extract_array_followed_by_key_value_does_not_crash
    content = "---\nitems:\n  - item1\n  nested: value\n---\n\nBody"
    fm = Ariadna::Tools::Frontmatter.extract(content)
    assert_equal ["item1"], fm["items"]
  end

  def test_extract_inline_array
    content = "---\ntags: [auth, api, db]\n---\n\nBody"
    fm = Ariadna::Tools::Frontmatter.extract(content)
    assert_equal %w[auth api db], fm["tags"]
  end

  def test_extract_nested
    content = "---\ndependency-graph:\n  requires: [auth]\n  provides:\n    - user-api\n---\n\nBody"
    fm = Ariadna::Tools::Frontmatter.extract(content)
    assert_equal({ "requires" => ["auth"], "provides" => ["user-api"] }, fm["dependency-graph"])
  end

  def test_extract_no_frontmatter
    content = "# Just a heading\n\nSome body text"
    fm = Ariadna::Tools::Frontmatter.extract(content)
    assert_equal({}, fm)
  end

  def test_reconstruct_simple
    obj = { "phase" => "1", "plan" => "2" }
    result = Ariadna::Tools::Frontmatter.reconstruct(obj)
    assert_includes result, "phase: 1"
    assert_includes result, "plan: 2"
  end

  def test_reconstruct_with_array
    obj = { "tags" => %w[auth api] }
    result = Ariadna::Tools::Frontmatter.reconstruct(obj)
    assert_includes result, "tags: [auth, api]"
  end

  def test_splice_replaces_frontmatter
    content = "---\nphase: 1\n---\n\n# Body"
    new_obj = { "phase" => "2", "plan" => "1" }
    result = Ariadna::Tools::Frontmatter.splice(content, new_obj)
    assert result.start_with?("---\n")
    assert_includes result, "phase: 2"
    assert_includes result, "plan: 1"
    assert_includes result, "# Body"
  end

  def test_splice_adds_frontmatter_when_missing
    content = "# Body\n\nSome text"
    new_obj = { "phase" => "1" }
    result = Ariadna::Tools::Frontmatter.splice(content, new_obj)
    assert result.start_with?("---\n")
    assert_includes result, "phase: 1"
    assert_includes result, "# Body"
  end

  def test_body_extraction
    content = "---\nphase: 1\n---\n\n# My Body"
    body = Ariadna::Tools::Frontmatter.body(content)
    assert_equal "# My Body", body
  end

  def test_body_no_frontmatter
    content = "# Just text"
    body = Ariadna::Tools::Frontmatter.body(content)
    assert_equal "# Just text", body
  end

  def test_extract_domain_fields
    content = "---\nphase: 03-features\nplan: 01\ntype: execute\ndomain: backend\ndomain_guide: backend.md\n---\n\n# Body"
    fm = Ariadna::Tools::Frontmatter.extract(content)
    assert_equal "backend", fm["domain"]
    assert_equal "backend.md", fm["domain_guide"]
  end

  def test_plan_validates_with_domain_field
    dir = Dir.mktmpdir
    plan_content = "---\nphase: 03-features\nplan: 01\ntype: execute\ndomain: backend\n---\n\n# Body"
    plan_path = File.join(dir, "test-plan.md")
    File.write(plan_path, plan_content)

    fm = Ariadna::Tools::Frontmatter.extract(plan_content)
    required = Ariadna::Tools::Frontmatter::SCHEMAS["plan"]
    missing = required.reject { |f| fm.key?(f) }
    assert_empty missing, "Plan with domain field should pass validation"
  ensure
    FileUtils.rm_rf(dir)
  end
end
