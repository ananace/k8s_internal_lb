# frozen_string_literal: true

require 'socket'
require 'timeout'

module K8sInternalLb
  module Services
    class TCP < Service
      attr_accessor :addresses, :timeout

      def initialize(addresses:, timeout: 1, **params)
        super

        @addresses = addresses
        @timeout = timeout
      end

      def update
        raise 'No TCP ports provided' if ports.select(&:tcp?).empty?

        @endpoints = addresses.map do |addr|
          available = \
            begin
              Timeout.timeout(timeout) do
                begin
                  ports.select(&:tcp?).each do |p|
                    TCPSocket.new(addr, p.port).close
                    true
                  end
                rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
                  false
                end
              end
            rescue Timeout::Error
              false
            end

          Address.new ip: addr, status: available
        end

        true
      end
    end
  end
end

