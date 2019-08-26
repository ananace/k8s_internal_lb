# Kubernetes Internal Load-balancer

This is a Ruby application to configure your K8s cluster to work as a load-balancer, by utilizing the ingress and service/endpoint resources.

The common flow is to set up an ingress to talk to a ClusterIP service without a selector, and letting this application populate the endpoints list.

## Installation

Install it yourself as:

    $ gem install k8s_internal_lb

## Usage

Run the application by specifying a configuration rb file, it can run in both one-shot mode as well as continuously.

    $ k8s_internal_lb

Check the provided [examples](examples/) for ideas on how to configure the system.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ananace/k8s_internal_lb

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
