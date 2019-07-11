# frozen_string_literal: true

require 'k8s_internal_lb/version'

autoload :Logging, 'logging'

module K8sInternalLb
  autoload :Address, 'k8s_internal_lb/address'
  autoload :Client, 'k8s_internal_lb/client'
  autoload :Port, 'k8s_internal_lb/port'
  autoload :Service, 'k8s_internal_lb/service'

  module Services
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
