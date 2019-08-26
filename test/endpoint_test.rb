# frozen_string_literal: true

require 'test_helper'

class EndpointTest < Test::Unit::TestCase
  def setup
    @address = mock
    @address.stubs(:is_a?).with(K8sInternalLb::Address).returns(true)
    @port = mock
    @port.stubs(:is_a?).with(K8sInternalLb::Port).returns(true)
  end

  def test_creation
    refute_nil K8sInternalLb::Endpoint.new address: @address, port: @port, status: true
    refute_nil K8sInternalLb::Endpoint.new address: @address, port: @port, status: false
    refute_nil K8sInternalLb::Endpoint.new address: @address, port: @port, status: :ready
    refute_nil K8sInternalLb::Endpoint.new address: @address, port: @port, status: :not_ready

    assert_raises(ArgumentError) { K8sInternalLb::Endpoint.new address: Object.new, port: @port, status: :not_ready }
    assert_raises(ArgumentError) { K8sInternalLb::Endpoint.new address: @address, port: Object.new, status: :not_ready }
    assert_raises(ArgumentError) { K8sInternalLb::Endpoint.new address: @address, port: @port, status: 'Something else' }
  end

  def test_status
    ep = K8sInternalLb::Endpoint.new address: @address, port: @port, status: true

    assert ep.ready?
    refute ep.not_ready?

    ep.status = false

    refute ep.ready?
    assert ep.not_ready?
  end
end
