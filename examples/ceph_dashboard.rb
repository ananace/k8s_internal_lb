# frozen_string_literal: true

require 'k8s_internal_lb'
require 'net/http'
require 'resolv'

class CephDashboard < K8sInternalLb::Services::HTTP
  attr_reader :mgrs

  def initialize(mgrs:, **params)
    super name: 'ceph-dashboard',
          ports: [Port.new(name: 'http', port: 5000, protocol: :TCP)],
          addresses: mgrs.map { |mgr| URI("http://#{mgr}.ctrl-c.liu.se:5000/") },
          **params

    @mgrs = mgrs
  end
end

K8sInternalLb.configure! do |client|
  client.add_service(CephDashboard.new(mgrs: ['jill-flitter', 'leroy-acevedo', 'nancy-daleske']))
end
