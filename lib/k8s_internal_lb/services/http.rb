# frozen_string_literal: true

require 'net/http'
require 'resolv'

module K8sInternalLb
  module Services
    class HTTP < Service
      attr_accessor :addresses, :timeout, :http_opts
      attr_reader :method, :expects

      def initialize(addresses:, method: :head, expects: :success, timeout: 5, http_opts: {}, **params)
        super

        self.method = method
        self.expects = expects

        addresses = addresses.map { |addr| URI(addr) }

        @addresses = addresses
        @timeout = timeout
        @http_opts = http_opts
      end

      def method=(method)
        raise ArgumentError, 'Invalid HTTP request method' unless %i[get head options post put].include? method

        @method = method
      end

      def expects=(expects)
        raise ArgumentError, 'Invalid expects type' unless expects == :success || [Numeric, Proc].include?(expects.class)

        @expects = expects
      end

      def update
        @endpoints = addresses.map do |addr|
          available = false

          begin
            address = Resolv.getaddress(addr.host)
            ssl = addr.scheme == 'https'

            Net::HTTP.start(addr.host, addr.port, use_ssl: ssl, read_timeout: timeout, **http_opts) do |h|
              resp = h.send(@method, addr.path)

              available = if @expects == :success
                            resp.is_a? Net::HTTPSuccess
                          elsif @expects.is_a? Numeric
                            resp.code == @expects
                          elsif @expects.is_a? Proc
                            @expects.call(resp)
                          end
            end
          rescue StandardError => e
            logger.warn "Failed to determine availability for #{addr} - #{e.class}: #{e.message}\n#{e.backtrace}"
            available = false # Assume failures to mean inaccessibility
          end

          e_addr = Address.new ip: address,
                               hostname: addr.host.split('.').first,
                               status: available

          Endpoint.new address: e_addr, port: port, status: available
        end

        true
      end
    end
  end
end
