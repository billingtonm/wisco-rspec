# frozen_string_literal: true

require 'wisco'
require 'tempfile'

module SchemaHelpers
  def schema_field_paths(schema, prefix = '')
    schema.flat_map do |field|
      path = [prefix, field['name']].reject(&:empty?).join('.')
      children = field['properties'] ? schema_field_paths(field['properties'], path) : []
      [path] + children
    end
  end
end

# Shared example that verifies every field present in the actual output is declared
# in the output_fields schema.
#
# Parameters:
#   output_fields_file - path to the output_fields.json schema definition
#
# The caller must provide `actual_output` as a let — the Ruby object returned by
# the action execution (e.g. let(:actual_output) { expected_output }).
RSpec.shared_examples 'output schema matches actual output' do |output_fields_file|
  include SchemaHelpers

  let(:wisco_config) do
    config_path = Wisco.config_path(Dir.pwd)
    config = Wisco::Config.load_config(config_path)
    Wisco::Config.ensure_api_config(config, config_path)
  end

  let(:defined_paths) do
    schema = JSON.parse(File.read(output_fields_file))
    schema_field_paths(schema)
  end

  let(:generated_schema) do
    hostname  = wisco_config.dig('workato_developer_api', 'hostname')
    api_token = wisco_config.dig('workato_developer_api', 'api_token')
    Tempfile.create(['actual_output', '.json']) do |f|
      f.write(JSON.generate(actual_output))
      f.flush
      Wisco::Commands::Schema.fetch_schema(f.path, hostname, api_token, col_sep: 'comma', debug: false)
    end
  end

  it 'all fields in actual output are declared in output_fields' do
    missing = schema_field_paths(generated_schema) - defined_paths
    expect(missing).to be_empty,
      "Fields present in actual output but missing from output_fields.json:\n" +
      missing.map { |f| "  - #{f}" }.join("\n")
  end
end
