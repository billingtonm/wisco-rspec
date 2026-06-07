# frozen_string_literal: true

require 'json'

# This file defines a shared context for testing Workato connectors.
# The connector file name is resolved from .wisco/config.json so this file
# can be reused across projects without modification.

CONNECTOR_FILE = JSON.parse(File.read(File.join(__dir__, '..', '..', '.wisco', 'config.json')))
                     .dig('connector', 'file')

RSpec.shared_context 'connector' do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file(CONNECTOR_FILE, settings) }
  let(:settings) { Workato::Connector::Sdk::Settings.from_default_file }
end
