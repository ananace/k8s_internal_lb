# frozen_string_literal: true

require 'net/http'
require 'resolv'

module K8sInternalLb
  module Services
    class HTTP < Service
      attr_accessor :addresses, :timeout, :http_opts

      def initialize(addresses:, timeout: 5, http_opts: {}, **params)
        super

        @addresses = addresses
        @timeout = timeout
        @http_opts = http_opts
      end

      def update
        @endpoints = addresses.map do |addr|
          available = false

          begin
            address = Resolv.getaddress(addr.host)
            ssl = addr.scheme == 'https'

            Net::HTTP.start(addr.host, addr.port, use_ssl: ssl, read_timeout: timeout, **http_opts) do |h|
              available = h.head(addr.path).is_a? Net::HTTPSuccess
            end
          rescue StandardError
            false # Just assume failures to mean inaccessibility
          end

          Address.new ip: address,
                      hostname: addr.host.split('.').first,
                      status: available
        end

        true
      end
    end
  end
end
