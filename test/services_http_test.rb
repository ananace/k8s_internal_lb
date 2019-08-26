# frozen_string_literal: true

require 'test_helper'

class ServicsHTTPTest < Test::Unit::TestCase
  def test_creation
    refute_nil K8sInternalLb::Services::HTTP.new name: 'test', addresses: ['http://example.com']
    refute_nil K8sInternalLb::Services::HTTP.new name: 'test', addresses: ['http://example.com'], timeout: 2
    refute_nil K8sInternalLb::Services::HTTP.new name: 'test', addresses: ['http://example.com'], method: :get, timeout: 2
    refute_nil K8sInternalLb::Services::HTTP.new name: 'test', addresses: ['http://example.com'], method: :get, expects: 302, timeout: 2
  end

  def test_ports
    svc = K8sInternalLb::Services::HTTP.new name: 'test', addresses: ['http://example.com']

    assert_equal 80, svc.ports.first.port
    assert_nil svc.ports.first.name

    svc = K8sInternalLb::Services::HTTP.new name: 'test', addresses: ['http://example.com'], ports: [K8sInternalLb::Port.new(name: 'HTTP', port: 80)]

    assert_equal 80, svc.ports.first.port
    assert_equal 'HTTP', svc.ports.first.name

    svc = K8sInternalLb::Services::HTTP.new name: 'test', addresses: ['http://example.com:5000'], ports: [K8sInternalLb::Port.new(name: 'HTTP', port: 5000)]

    assert_equal 5000, svc.ports.first.port
    assert_equal 'HTTP', svc.ports.first.name
  end
end
