# frozen_string_literal: true

require 'test_helper'

class AddressTest < Test::Unit::TestCase
  def test_creation
    refute_nil K8sInternalLb::Address.new ip: '1.2.3.4'
    refute_nil K8sInternalLb::Address.new ip: '1.2.3.4', hostname: 'host'

    assert_raises(ArgumentError) { K8sInternalLb::Address.new hostname: 'test' }
    assert_raises(ArgumentError) { K8sInternalLb::Address.new ip: '1.2.3.4', hostname: 'host.example.com' }
    assert_raises(IPAddr::InvalidAddressError) { K8sInternalLb::Address.new ip: 'not an IP' }
  end

  def test_equality
    addr_a = K8sInternalLb::Address.new ip: '1.2.3.4', hostname: 'host'
    addr_b = K8sInternalLb::Address.new ip: '1.2.3.4', hostname: 'host'
    addr_c = K8sInternalLb::Address.new ip: '1.2.3.4', hostname: 'other-host'
    addr_d = K8sInternalLb::Address.new ip: '1.2.3.5', hostname: 'other-host'

    assert addr_a == addr_b
    assert addr_b == addr_a
    refute addr_b == addr_c
    refute addr_c == addr_a
    refute addr_c == addr_d
  end

  def test_assignment
    addr = K8sInternalLb::Address.new ip: '1.2.3.4'

    addr.hostname = 'host'
    assert_equal 'host', addr.hostname

    addr.hostname = ''
    assert_nil addr.hostname

    addr.hostname = 'other-host'
    refute_nil addr.hostname

    addr.hostname = nil
    assert_nil addr.hostname

    assert_raises(ArgumentError) { addr.hostname = 'host.example.com' }
  end

  def test_json
    addr = K8sInternalLb::Address.new ip: '1.2.3.4', hostname: 'host'

    assert_equal '{"hostname":"host","ip":"1.2.3.4"}', addr.to_json
  end
end
