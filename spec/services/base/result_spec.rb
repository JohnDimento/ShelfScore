require 'rails_helper'

RSpec.describe Base::Result do
  describe '#initialize' do
    it 'creates a successful result by default' do
      result = described_class.new
      expect(result).to be_success
      expect(result.error).to be_nil
      expect(result.data).to eq({})
    end

    it 'creates a failed result when success is false' do
      result = described_class.new(success: false, error: 'Something went wrong')
      expect(result).not_to be_success
      expect(result.error).to eq('Something went wrong')
      expect(result.data).to eq({})
    end

    it 'stores additional data in the data hash' do
      result = described_class.new(value: 42, name: 'test')
      expect(result.data).to eq(value: 42, name: 'test')
    end
  end

  describe '#success?' do
    it 'returns true for successful results' do
      result = described_class.new
      expect(result.success?).to be true
    end

    it 'returns false for failed results' do
      result = described_class.new(success: false)
      expect(result.success?).to be false
    end
  end

  describe 'method_missing' do
    let(:result) { described_class.new(value: 42, name: 'test') }

    it 'provides access to data values through methods' do
      expect(result.value).to eq(42)
      expect(result.name).to eq('test')
    end

    it 'raises NoMethodError for undefined methods' do
      expect { result.undefined_method }.to raise_error(NoMethodError)
    end
  end

  describe 'respond_to_missing?' do
    let(:result) { described_class.new(value: 42, name: 'test') }

    it 'returns true for methods matching data keys' do
      expect(result.respond_to?(:value)).to be true
      expect(result.respond_to?(:name)).to be true
    end

    it 'returns false for undefined methods' do
      expect(result.respond_to?(:undefined_method)).to be false
    end
  end
end
