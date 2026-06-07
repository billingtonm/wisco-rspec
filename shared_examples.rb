# frozen_string_literal: true

# This file defines shared examples for testing Workato connector actions. 
# It includes a shared example for verifying that the output of an action matches expected output, 
# and a shared example for testing the standard behavior of an action (execute, input_fields, output_fields) 
# using fixtures.

require_relative 'this_connector'

# -----------------------------------------------------------------------------
RSpec.shared_examples 'returns expected output' do
  it { expect(JSON.parse(subject.to_json)).to eq(expected_output) }
end

# -----------------------------------------------------------------------------
# 'a standard action' shared example tests the execute, input_fields, and output_fields 
# methods of a Workato connector action
RSpec.shared_examples 'a standard action' do |action_name|
  include_context 'connector'
  let(:fixture_path) { "fixtures/actions/#{action_name}" }
  let(:config_fields) { JSON.parse(File.read("#{fixture_path}/config_fields.json")) }
  let(:action) { connector.actions.public_send(action_name) }

  describe 'execute' do
    subject { action.execute(settings, JSON.parse(File.read("#{fixture_path}/execute_input.json"))) }
    it_behaves_like 'returns expected output' do
      let(:expected_output) { JSON.parse(File.read("#{fixture_path}/expected_execute_input.json")) }
    end
  end

  describe 'input_fields' do
    subject { action.input_fields(settings, config_fields) }
    it_behaves_like 'returns expected output' do
      let(:expected_output) { JSON.parse(File.read("#{fixture_path}/input_fields.json")) }
    end
  end

  describe 'output_fields' do
    subject { action.output_fields(settings, config_fields) }
    it_behaves_like 'returns expected output' do
      let(:expected_output) { JSON.parse(File.read("#{fixture_path}/output_fields.json")) }
    end
  end
end
