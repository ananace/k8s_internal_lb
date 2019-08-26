# frozen_string_literal: true

# This example will generate Kubernetes endpoints that map to SMTP servers.
#
# It will check the existence/status of the SMTP servers by opening a TCP
# socket to each of the specified ports, allowing 1 second for each attempt.
#
# The resulting endpoint object could look something like;
#
# apiVersion: v1
# kind: Endpoints
# metadata:
#   name: smtp
# subsets:
# - addresses:
#   - ip: 1.2.3.4
#   notReadyAddresses:
#   - ip: 2.3.4.5
#   ports:
#   - name: submission
#     port: 587
#     protocol: TCP
# - addresses:
#   - ip: 2.3.4.5
#   notReadyAddresses:
#   - ip: 1.2.3.4
#   ports:
#   - name: smtp
#     port: 25
#     protocol: TCP
#   - name: smtps
#     port: 465
#     protocol: TCP
#
# At the moment, service objects have to be created beforehand, and port names
# have to map correctly.
#

K8sInternalLb.configure! do |client|
  client.add_service(K8sInternalLb::Service.create(
    name: 'smtp',
    type: :TCP,
    ports: [
      K8sInternalLb::Port.new(port: 25, name: 'smtp'),
      K8sInternalLb::Port.new(port: 465, name: 'smtps'),
      K8sInternalLb::Port.new(port: 587, name: 'submission')
    ],
    addresses: [
      K8sInternalLb::Address.new(ip: '1.2.3.4'),
      K8sInternalLb::Address.new(ip: '2.3.4.5')
    ])
  )
end
