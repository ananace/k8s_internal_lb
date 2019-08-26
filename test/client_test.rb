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

    @kubeclient = mock

    @client = K8sInternalLb::Client.new
    @client.stubs(:kubeclient).returns(@kubeclient)
  end

  def test_logger_existence
    refute_nil @client.send :logger
  end

  def test_service_handling
    ep = mock
    ep.expects(:metadata).returns(nil)
    @kubeclient.expects(:get_endpoint).returns(ep)

    svc = K8sInternalLb::Services::TCP.new addresses: [], ports: [], name: 'test'

    @client.add_service svc

    assert @client.services.key? 'test'
    assert_equal svc, @client.services['test']

    @client.remove_service 'test'

    refute @client.services.key? 'test'
    refute_equal svc, @client.services['test']
  end

  def test_update
    ep = mock
    ep.expects(:metadata).returns(nil)
    @kubeclient.expects(:get_endpoint).returns(ep)

    svc = K8sInternalLb::Services::TCP.new addresses: [], ports: [], name: 'test', namespace: 'testing'
    svc.expects(:update)
    svc.expects(:endpoints).times(5)
       .returns(
         [
           K8sInternalLb::Endpoint.new(address: K8sInternalLb::Address.new(ip: '1.2.3.4'), port: K8sInternalLb::Port.new(port: 1234), status: true),
           K8sInternalLb::Endpoint.new(address: K8sInternalLb::Address.new(ip: '2.3.4.5'), port: K8sInternalLb::Port.new(port: 1234), status: false)
         ]
       )

    now = Time.now
    Time.stubs(:now).returns now

    @kubeclient.expects(:patch_endpoint).with('test', { metadata: { annotations: { K8sInternalLb::Client::TIMESTAMP_ANNOTATION => now.to_s } }, subsets: svc.to_subsets }, 'testing').returns(svc)

    @client.add_service svc

    refute_equal true, @client.send(:update, svc, force: true)
  end
end
