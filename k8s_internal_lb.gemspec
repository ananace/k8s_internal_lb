# frozen_string_literal: true

require File.join File.expand_path('lib', __dir__), 'k8s_internal_lb/version'

Gem::Specification.new do |spec|
  spec.name          = 'k8s_internal_lb'
  spec.version       = K8sInternalLb::VERSION
  spec.authors       = ['Alexander Olofsson']
  spec.email         = ['alexander.olofsson@liu.se']

  spec.summary       = 'A ruby application for setting up your k8s cluster as a load balancer.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/ananace/k8s_internal_lb'
  spec.license       = 'MIT'

  spec.extra_rdoc_files = %w[CHANGELOG.md LICENSE.md README.md]
  spec.files            = Dir['{bin,lib}/**/*'] + spec.extra_rdoc_files
  spec.executables      = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'test-unit'

  spec.add_dependency 'kubeclient'
  spec.add_dependency 'logging', '~> 2'
  spec.add_dependency 'thor'
end
