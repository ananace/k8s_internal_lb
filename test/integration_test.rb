# frozen_string_literal: true

require 'test_helper'

class IntegrationTest < Test::Unit::TestCase
  def setup
    @address1 = K8sInternalLb::Address.new ip: '1.2.3.4'
    @address2 = K8sInternalLb::Address.new ip: '2.3.4.5'
    @port1 = K8sInternalLb::Port.new name: 'http', port: 80
    @port2 = K8sInternalLb::Port.new name: 'http', port: 443

    @endpoint1 = K8sInternalLb::Endpoint.new address: @address1, port: @port1, status: :ready
    @endpoint2 = K8sInternalLb::Endpoint.new address: @address1, port: @port2, status: :ready
    @endpoint3 = K8sInternalLb::Endpoint.new address: @address2, port: @port1, status: :not_ready
    @endpoint4 = K8sInternalLb::Endpoint.new address: @address2, port: @port2, status: :ready

    @service = K8sInternalLb::Service.new name: 'testservice', addresses: [@address1, @address2], ports: [@port1, @port2], interval: 2
    @service.stubs(:update).returns(true)

    @kubeclient = mock

    @client = K8sInternalLb::Client.instance
    @client.instance_variable_set :@kubeclient, @kubeclient

    endpoint = mock
    endpoint.stubs(:metadata).returns(nil)

    @kubeclient.stubs(:get_endpoint).returns(endpoint)
    @client.add_service @service
  end

  def test_mainloop
    state = states('state').starts_as('A')

    @service.expects(:endpoints).when(state.is('A')).times(4)
            .returns([])
            .then.returns([@endpoint1, @endpoint2, @endpoint3, @endpoint4])
    @service.expects(:endpoints).when(state.is('B')).times(4)
            .returns([])
            .then.returns([@endpoint3, @endpoint4])

    K8sInternalLb.debug!

    # To avoid time differences causing issues
    now = Time.now
    later = now + 3600
    Time.stubs(:now).when(state.is('A')).returns(now)
    Time.stubs(:now).when(state.is('B')).returns(later)

    @kubeclient.expects(:patch_endpoint)
               .when(state.is('A')).with(
                 @service.name,
                 {
                   metadata: {
                     annotations: {
                       K8sInternalLb::Client::TIMESTAMP_ANNOTATION => now.to_s
                     }
                   },
                   subsets: [
                     { addresses: [@address1], notReadyAddresses: [@address2], ports: [@port1] },
                     { addresses: [@address1, @address2], notReadyAddresses: [], ports: [@port2] }
                   ]
                 },
                 @service.namespace
               ).then(state.is('B'))
    @kubeclient.expects(:patch_endpoint)
               .when(state.is('B')).with(
                 @service.name,
                 {
                   metadata: {
                     annotations: {
                       K8sInternalLb::Client::TIMESTAMP_ANNOTATION => later.to_s
                     }
                   },
                   subsets: [
                     { addresses: [], notReadyAddresses: [@address2], ports: [@port1] },
                     { addresses: [@address2], notReadyAddresses: [], ports: [@port2] }
                   ]
                 },
                 @service.namespace
               )

    @client.sleep_duration = 0.5
    Timeout.timeout(1) do
      @client.run
    end
  rescue Timeout::Error
    true
  end
end
