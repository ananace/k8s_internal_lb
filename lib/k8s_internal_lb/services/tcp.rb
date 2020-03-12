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
          ports.select(&:tcp?).map do |port|
            available = \
              begin
                Timeout.timeout(timeout) do
                  begin
                    TCPSocket.new(addr.ip.to_s, port.port).close
                    true
                  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
                    false
                  end
                end
              rescue Timeout::Error
                false
              end

            Endpoint.new address: addr, port: port, status: available
          end
        end.flatten

        true
      end
    end
  end
end
