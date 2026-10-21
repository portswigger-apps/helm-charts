#!/usr/bin/env ruby
# Requires Helm 3, Ruby's standard YAML library, and chart dependencies.
require 'open3'
require 'yaml'

Dir.chdir(File.expand_path('../../..', __dir__))

def render(release, *options)
  output, error, status = Open3.capture3('helm', 'template', release, 'charts/app', *options)
  raise error unless status.success?

  YAML.load_stream(output).compact
end

def matches?(selector, labels)
  selector.all? { |key, value| labels[key] == value }
end

options = ['--set', 'infra.postgres.enabled=true', '--set', 'postgresExtensionSetup.enabled=true',
           '--set', 'postgresExtensionSetup.extensions[0].name=vector',
           '--set-string', 'postgresExtensionSetup.extensions[0].version=0.8.1',
           '--set', 'preDeployCommand[0]=migrate', '--set', 'preRollbackCommand[0]=rollback']
releases = ['isolation', 'a' * 53, 'a' * 47 + 'bbbbbb', 'isolation-extension-hooks']
hook_policy_names = []
releases.each do |release|
  documents = render(release, *options)
  service = documents.find { |doc| doc['kind'] == 'Service' }
  workload = documents.find { |doc| doc['kind'] == 'Deployment' }
  jobs = documents.select { |doc| doc['kind'] == 'Job' }
  policies = documents.select { |doc| doc['kind'] == 'CiliumNetworkPolicy' }
  application_policy = policies.find { |doc| doc['metadata']['name'] == release }
  hook_policy = policies.find { |doc| doc['metadata']['annotations'] }
  raise 'expected both hook jobs' unless jobs.length == 2
  selector = service.fetch('spec').fetch('selector')
  raise 'Service excludes application' unless matches?(selector, workload['spec']['template']['metadata']['labels'])
  jobs.each do |job|
    raise 'Service includes hook' if matches?(selector, job['spec']['template']['metadata']['labels'])
  end
  raise 'expected application and hook policies' unless policies.length == 2
  policy_name = hook_policy['metadata']['name']
  raise 'hook policy name can collide with application policy name' unless policy_name.length > 53 && policy_name.length <= 63
  hook_policy_names << policy_name
  hook_policy['spec']['endpointSelector']['matchLabels'].each_value do |value|
    raise 'invalid hook label' unless value.length <= 63 && value.match?(/\A[a-z0-9]([-a-z0-9]*[a-z0-9])?\z/)
  end
  raise 'hook policy includes application' if matches?(hook_policy['spec']['endpointSelector']['matchLabels'], workload['spec']['template']['metadata']['labels'])
  jobs.each do |job|
    pod = job.fetch('spec').fetch('template')
    labels = pod.fetch('metadata').fetch('labels')
    raise 'application policy includes hook' if matches?(application_policy['spec']['endpointSelector']['matchLabels'], labels)
    raise 'hook policy excludes hook' unless matches?(hook_policy['spec']['endpointSelector']['matchLabels'], labels)
    pod['spec']['topologySpreadConstraints'].each do |constraint|
      raise 'spread selector differs from hook policy' unless constraint['labelSelector']['matchLabels'] == hook_policy['spec']['endpointSelector']['matchLabels']
    end
  end
  raise 'hook egress differs from application' unless hook_policy['spec']['egress'] == application_policy['spec']['egress']
  raise 'hook policy grants ingress' if hook_policy['spec'].key?('ingress')
  without_setup = render(release, *options, '--set', 'postgresExtensionSetup.enabled=false')
  original_policy = without_setup.find { |doc| doc['kind'] == 'CiliumNetworkPolicy' }
  raise 'application policy changed' unless application_policy == original_policy
end
raise 'hook policy names collide across releases' unless hook_policy_names.uniq.length == releases.length
raise 'hook policy name collides with an application release' unless (hook_policy_names & releases).empty?
puts 'PASS: Service/workload/hook/policy selector relationships and application policy parity (4 release names, including shared-prefix names)'
