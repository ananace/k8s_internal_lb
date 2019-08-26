# frozen_string_literal: true

require 'test_helper'

class PortTest < Test::Unit::TestCase
  def test_creation
    refute_nil K8sInternalLb::Port.new port: 1234
    refute_nil K8sInternalLb::Port.new name: 'API', port: 1234
    refute_nil K8sInternalLb::Port.new name: 'API', port: 1234, protocol: :TCP
    refute_nil K8sInternalLb::Port.new name: 'API', port: 1234, protocol: :UDP
    refute_nil K8sInternalLb::Port.new name: 'API', port: 1234, protocol: :SCTP

    assert_raises(ArgumentError) { K8sInternalLb::Port.new }
    assert_raises(ArgumentError) { K8sInternalLb::Port.new port: 0 }
    assert_raises(ArgumentError) { K8sInternalLb::Port.new port: 99_999 }
    assert_raises(ArgumentError) { K8sInternalLb::Port.new port: 1234, protocol: :IPX }
  end

  def test_protocols
    port = K8sInternalLb::Port.new port: 1234

    assert port.tcp?
    refute port.udp?
    refute port.sctp?

    port.protocol = 'tcp'

    assert port.tcp?
    refute port.udp?
    refute port.sctp?

    port.protocol = :udp

    refute port.tcp?
    assert port.udp?
    refute port.sctp?

    port.protocol = :SCTP

    refute port.tcp?
    refute port.udp?
    assert port.sctp?
  end

  def test_json
    port = K8sInternalLb::Port.new port: 443, name: 'HTTPS'

    assert_equal '{"name":"HTTPS","port":443,"protocol":"TCP"}', port.to_json
  end
end
