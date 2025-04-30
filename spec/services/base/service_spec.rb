require 'rails_helper'

RSpec.describe Base::Service do
  # Create a test service class that inherits from Base::Service
  class TestService < Base::Service
    def initialize(value)
      @value = value
    end

    def call
      if @value.positive?
        success(result: @value)
      else
        failure("Value must be positive")
      end
    end
  end

  describe '.call' do
    it 'creates an instance and calls the service' do
      result = TestService.call(5)
      expect(result[:success?]).to be true
      expect(result[:result]).to eq(5)
    end
  end

  describe '#success' do
    it 'returns a hash with success? true and the payload' do
      result = TestService.new(5).call
      expect(result[:success?]).to be true
      expect(result[:error]).to be_nil
      expect(result[:result]).to eq(5)
    end
  end

  describe '#failure' do
    it 'returns a hash with success? false and the error message' do
      result = TestService.new(-1).call
      expect(result[:success?]).to be false
      expect(result[:error]).to eq("Value must be positive")
    end
  end
end
