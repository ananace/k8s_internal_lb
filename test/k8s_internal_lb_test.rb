# frozen_string_literal: true

require 'test_helper'

class K8sInternalLbTest < Test::Unit::TestCase
  def test_that_it_has_a_version_number
    refute_nil ::K8sInternalLb::VERSION
  end

  def test_logger
    refute_nil ::K8sInternalLb.logger
  end
end
