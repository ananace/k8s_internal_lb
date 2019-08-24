# frozen_string_literal: true

require 'test_helper'

class ClientCreationTest < Test::Unit::TestCase
  def test_creation_in_cluster
    K8sInternalLb::Client.any_instance.expects(:in_cluster?).returns(true)

    File.expects(:read).with('/var/run/secrets/kubernetes.io/serviceaccount/namespace').returns('test')

    cl = K8sInternalLb::Client.new
    refute_nil cl

    assert_equal 'https://kubernetes.default.svc', cl.server
    assert_equal 'test', cl.namespace
    assert_equal '/var/run/secrets/kubernetes.io/serviceaccount/token', cl.auth_options[:bearer_token_file]
  end

  def test_creation_outside_cluster
    K8sInternalLb::Client.any_instance.expects(:in_cluster?).returns(false)

    cl = K8sInternalLb::Client.new

    assert_nil cl.server
    assert_nil cl.namespace
    assert_empty cl.auth_options
  end
end

class ClientTest < Test::Unit::TestCase
  def setup
    K8sInternalLb::Client.any_instance.expects(:in_cluster?).returns(false)

    @client = K8sInternalLb::Client.new
  end

  def test_logger_existence
    refute_nil @client.send :logger
  end

  def test_service_adding
    ep = mock
    ep.expects(:metadata).returns(nil)
    @client.expects(:get_endpoint).returns(ep)

    svc = K8sInternalLb::Services::TCP.new addresses: [], ports: [], name: 'test'

    @client.add_service svc

    assert_equal svc, @client.services['test']
  end
end
