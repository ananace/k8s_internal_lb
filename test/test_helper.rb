# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/vendor/'
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'k8s_internal_lb'

# Ensure everything is loaded
K8sInternalLb::Address.class
K8sInternalLb::Client.class
K8sInternalLb::Endpoint.class
K8sInternalLb::Port.class
K8sInternalLb::Service.class
K8sInternalLb::Services::HTTP.class
K8sInternalLb::Services::TCP.class

require 'test/unit'
require 'mocha/setup'
