# frozen_string_literal: true

require 'k8s_internal_lb'
require 'net/http'
require 'resolv'

class CephDashboard < K8sInternalLb::Services::HTTP
  attr_reader :mgrs

  def initialize(mgrs:, **params)
    super name: 'ceph-dashboard',
          ports: [Port.new(name: 'http', port: 5000, protocol: :TCP)],
          addresses: mgrs.map { |mgr| URI("http://#{mgr}.example.com:5000/") },
          interval: 30,
          **params

    @mgrs = mgrs
  end
end

K8sInternalLb.configure! do |client|
  client.add_service(CephDashboard.new(mgrs: %w[cephmgr1 cephmgr2 cephmgr3]))
end
