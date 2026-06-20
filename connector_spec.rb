# frozen_string_literal: true

require_relative 'this_connector'

RSpec.describe 'connector', :vcr do
  include_context 'connector'

  it { expect(connector).to be_present }

  describe 'test' do
    subject(:output) { connector.test(settings) }

    it 'establishes valid connection', :no_vcr do
      expect(output).to be_truthy
    end
  end
end
