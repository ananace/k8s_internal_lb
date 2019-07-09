# frozen_string_literal: true

require 'k8s_internal_lb/version'

module K8sInternalLb
  class Error < StandardError; end

  autoload :Address, 'k8s_internal_lb/address'
  autoload :Client, 'k8s_internal_lb/client'
  autoload :Port, 'k8s_internal_lb/port'
  autoload :Service, 'k8s_internal_lb/service'

  module Services
    autoload :TCP, 'k8s_internal_lb/services/tcp'
  end

  def self.configure!(&block)
    block.call Client.instance
  end
end
