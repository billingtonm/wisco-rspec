# frozen_string_literal: true

# This file defines shared examples for testing Workato connector actions. 
# It includes a shared example for verifying that the output of an action matches expected output, 
# and a shared example for testing the standard behavior of an action (execute, input_fields, output_fields) 
# using fixtures.


# The standard tests compare actual output to exepcted output stored in a fixture files. 
# Testing expected output against a fixture. The procedure is:
# 1. Define an input fixture, call it: execute_test.json. ** This will be the test case input **
#    - Suggestions for this:
#      - Take an existing execute_input.json fixture and copy/rename it to execute_test.json
#  2. If an output fixture doesn't already exist, create one:
#    - Suggestion:
#      - Use `wisco exec <item_type>.<item> --input=execute_test.json` to generate the output
#      - Rename the output fixture to expected_execute_test.json
# Then the shared example will use the input file to run the action and compare the output to the expected output fixture.

require_relative 'this_connector'
require_relative 'schema_helpers'

# -----------------------------------------------------------------------------
def read_fixture(path)
  File.read(path)
rescue Errno::ENOENT
  filename = File.basename(path)
  dir      = File.dirname(path)
  message  = case filename
             when 'execute_test.json'
               <<~MSG
                 Missing fixture: #{path}

                 To create it:
                   1. Copy an existing execute_input.json from #{dir}/ and rename it to execute_test.json
                      e.g.  cp #{dir}/execute_input.json #{dir}/execute_test.json
                   2. Then generate the expected output:
                      wisco exec <item_type>.<item_name> --input=#{dir}/execute_test.json
                   3. Rename the generated output file to expected_execute_test.json in #{dir}/
               MSG
             when 'expected_execute_test.json'
               <<~MSG
                 Missing fixture: #{path}

                 To create it:
                   Run:  wisco exec <item_type>.<item_name> --input=#{dir}/execute_test.json
                   Then rename the generated output file to expected_execute_test.json in #{dir}/
               MSG
             else
               "Missing fixture: #{path}\n\nCreate the file at #{path} before running this spec."
             end
  raise message
end

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
  let(:config_fields) { File.exist?("#{fixture_path}/config_fields.json") ? JSON.parse(File.read("#{fixture_path}/config_fields.json")) : {} }
  let(:action) { connector.actions.public_send(action_name) }

  describe 'execute' do
    let(:expected_output) { JSON.parse(read_fixture("#{fixture_path}/expected_execute_test.json")) }
    subject { action.execute(settings, JSON.parse(read_fixture("#{fixture_path}/execute_test.json"))) }

    it_behaves_like 'returns expected output'
    it('output is a hash') { expect(subject).to be_a(Hash) }

    describe 'output schema consistency', :vcr do
      it_behaves_like 'output schema matches actual output',
        "fixtures/actions/#{action_name}/output_fields.json" do
        let(:actual_output) { subject }
      end
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

RSpec.shared_examples 'a standard method' do |method_name|
  include_context 'connector'
  let(:fixture_path) { "fixtures/methods/#{method_name}" }

  describe 'execute' do
    subject do
      args = JSON.parse(read_fixture("#{fixture_path}/execute_test.json"))
      connector.methods.public_send(method_name, *args)
    end
    it_behaves_like 'returns expected output' do
      let(:expected_output) { JSON.parse(read_fixture("#{fixture_path}/expected_execute_test.json")) }
    end
  end
end