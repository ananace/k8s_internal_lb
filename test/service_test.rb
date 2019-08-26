# frozen_string_literal: true

require 'test_helper'

class ServiceTest < Test::Unit::TestCase
  def test_creation
    refute_nil K8sInternalLb::Service.new name: 'test', ports: []
    refute_nil K8sInternalLb::Service.new name: 'test', ports: [], interval: 4
    refute_nil K8sInternalLb::Service.new name: 'test', namespace: 'default', ports: [], interval: 4
    refute_nil K8sInternalLb::Service.new name: 'test', namespace: 'default', ports: [], interval: 4, garbage: nil

    assert_equal K8sInternalLb::Services::HTTP, K8sInternalLb::Service.create(type: :HTTP, name: 'test', addresses: []).class
    assert_equal K8sInternalLb::Services::TCP, K8sInternalLb::Service.create(type: :TCP, name: 'test', addresses: [], ports: []).class
  end

  def test_subsets
    svc = K8sInternalLb::Service.new name: 'test', ports: []

    addr1 = K8sInternalLb::Address.new(ip: '1.2.3.4')
    addr2 = K8sInternalLb::Address.new(ip: '2.3.4.5')
    port1 = K8sInternalLb::Port.new(port: 1234)
    port2 = K8sInternalLb::Port.new(port: 2345)

    ep1 = mock
    ep1.stubs(:ready?).returns(true)
    ep1.stubs(:not_ready?).returns(false)
    ep1.stubs(:address).returns(addr1)
    ep1.stubs(:port).returns(port1)

    ep2 = mock
    ep2.stubs(:ready?).returns(true)
    ep2.stubs(:not_ready?).returns(false)
    ep2.stubs(:address).returns(addr2)
    ep2.stubs(:port).returns(port1)

    ep3 = mock
    ep3.stubs(:ready?).returns(false)
    ep3.stubs(:not_ready?).returns(true)
    ep3.stubs(:address).returns(addr2)
    ep3.stubs(:port).returns(port2)

    svc.expects(:endpoints).returns([ep1, ep2, ep3])

    assert_equal [
      { addresses: [addr1, addr2], ports: [port1], notReadyAddresses: [] },
      { addresses: [], ports: [port2], notReadyAddresses: [addr2] }
    ], svc.to_subsets
  end
end
