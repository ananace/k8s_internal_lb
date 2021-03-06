# frozen_string_literal: true

require 'net/http'

module K8sInternalLb
  module Services
    class HTTP < Service
      attr_accessor :timeout, :http_opts
      attr_reader :addresses, :method, :expects

      def initialize(addresses:, method: :head, expects: :success, timeout: 5, http_opts: {}, **params)
        params[:ports] ||= []
        super

        self.method = method
        self.expects = expects
        self.addresses = addresses

        @timeout = timeout
        @http_opts = http_opts

        @address_hash = nil
        @port_hash = nil
      end

      def ports
        # Ensure data is recalculated if addresses or ports change
        address_hash = @addresses.hash
        port_hash = super.hash
        @http_ports = nil if @address_hash != address_hash
        @http_ports = nil if @port_hash != port_hash
        @address_hash = address_hash
        @port_hash = port_hash

        @http_ports ||= begin
          http_ports = @addresses.map { |addr| Port.new(port: addr.port) }.uniq
        
          # Copy port names over where appropriate
          super.each do |port|
            http_port = http_ports.find { |hp| hp.port == port.port }
            next unless http_port

            http_port.name = port.name
          end

          http_ports
        end
      end

      def addresses=(addresses)
        addresses = addresses.map do |addr|
          addr = URI(addr)

          addr.path = '/' if addr.path.empty?

          addr
        end

        @addresses = addresses
      end

      def method=(method)
        raise ArgumentError, 'Invalid HTTP request method' unless %i[get get2 head head2 options post put].include? method

        @method = method
      end

      def expects=(expects)
        raise ArgumentError, 'Invalid expects type' unless expects == :success || [Integer, Proc].include?(expects.class)

        @expects = expects
      end

      def update
        @endpoints = addresses.map do |addr|
          available = false

          begin
            ssl = addr.scheme == 'https'

            Net::HTTP.start(addr.host, addr.port, use_ssl: ssl, read_timeout: timeout, **http_opts) do |h|
              resp = h.send(@method, addr.path)
              logger.debug "#{addr} - #{resp.inspect}"

              available = if @expects == :success
                            resp.is_a? Net::HTTPSuccess
                          elsif @expects.is_a? Numeric
                            resp.code == @expects
                          elsif @expects.is_a? Proc
                            @expects.call(resp)
                          end
            end
          rescue StandardError => e
            logger.debug "#{addr} - #{e.class}: #{e.message}\n#{e.backtrace[0, 20].join("\n")}"
            available = false # Assume failures to mean inaccessibility
          end

          e_addr = Address.new fqdn: addr.host
          Endpoint.new address: e_addr, port: ports.find { |p| p.port == addr.port }, status: available
        end

        true
      end
    end
  end
end
