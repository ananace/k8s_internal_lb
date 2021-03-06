# frozen_string_literal: true

require 'k8s_internal_lb/version'
require 'kubeclient'

autoload :Logging, 'logging'

module K8sInternalLb
  autoload :Address, 'k8s_internal_lb/address'
  autoload :Client, 'k8s_internal_lb/client'
  autoload :Endpoint, 'k8s_internal_lb/endpoint'
  autoload :Port, 'k8s_internal_lb/port'
  autoload :Service, 'k8s_internal_lb/service'

  module Services
    autoload :HTTP, 'k8s_internal_lb/services/http'
    autoload :TCP, 'k8s_internal_lb/services/tcp'
  end

  class Error < StandardError; end

  def self.configure!(&block)
    block.call Client.instance
  end

  def self.debug!
    logger.level = :debug
  end

  def self.logger
    @logger ||= ::Logging.logger[self].tap do |logger|
      logger.add_appenders ::Logging.appenders.stdout
      logger.level = :info
    end
  end
end

K8sInternalLb.logger # Set up logger
