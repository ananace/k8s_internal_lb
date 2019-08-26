# frozen_string_literal: true

# This example will generate Kubernetes endpoints that map to the Ceph
# Dashboard service.
#
# Only the active manager serves the dashboard, all other nodes instead
# generate 302 redirects to the currently active node.
# This service will query all the given manager names, filter them based on
# if they respond with HTTP 2xx or not, and fill in a Kubernetes endpoint
# object like such;
#
# apiVersion: v1
# kind: Endpoints
# metadata:
#   annotations:
#     com.github.ananace.k8s-internal-lb/timestamp: 2019-08-26 10:57:47 +0000
#   name: ceph-dashboard
# subsets:
# - addresses:
#   - hostname: cephmgr2
#     ip: 10.36.252.21
#   notReadyAddresses:
#   - hostname: cephmgr1
#     ip: 10.36.252.20
#   - hostname: cephmgr3
#     ip: 10.36.252.22
#   ports:
#   - name: http
#     port: 5000
#     protocol: TCP
#
# At the moment, service objects have to be created beforehand.
#
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
