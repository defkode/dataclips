require "test_helper"

class Dataclips::InsightTest < ActiveSupport::TestCase
  class DefaultParams < ActiveSupport::TestCase
    teardown do
      # Make sure we work with pristine config each time
      Dataclips::Insight.remove_instance_variable(:@config)
    end

    test "configuring via configuration block" do
      Dataclips::Insight.configure do |config|
        config.default_params = {test: "test"}
      end

      expected_params = {test: "test"}
      assert_equal expected_params, Dataclips::Insight.config.default_params
    end

    test "assigning empty hash to default params by default" do
      assert_equal Hash.new, Dataclips::Insight.config.default_params
      insight = Dataclips::Insight.get!("dummy")
      assert_equal Hash.new, insight.params
    end

    test "merging default params with those provided by the user" do
      Dataclips::Insight.config.default_params = { test: "test" }
      symbol_insight = Dataclips::Insight.get!("dummy", id: 1)
      string_insight = Dataclips::Insight.get!("dummy", "id" => 1)
      expected_params = { "test" => "test", "id" => 1}
      assert_equal expected_params, symbol_insight.params
      assert_equal expected_params, string_insight.params
    end

    test "overriding default params" do
      Dataclips::Insight.config.default_params = { test: "test" }
      symbol_insight = Dataclips::Insight.get!("dummy", test: 1)
      string_insight = Dataclips::Insight.get!("dummy", "test" => 1)
      expected_params = { "test" => 1 }
      assert_equal expected_params, symbol_insight.params
      assert_equal expected_params, string_insight.params
    end

    test "setting dynamic default params values" do
      Dataclips::Insight.config.default_params = {
        test: -> { Thread.current[:test_value] },
      }

      Thread.current[:test_value] = "test"
      insight = Dataclips::Insight.get!("dummy")
      expected_params = { "test" => "test" }
      assert_equal expected_params, insight.params

      Thread.new do
        Thread.current[:test_value] = "other value"
        insight = Dataclips::Insight.get!("dummy")
        expected_params = { "test" => "other value" }
        assert_equal expected_params, insight.params
      end
    end
  end
end
