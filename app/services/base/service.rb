# frozen_string_literal: true

require 'ostruct'

module Base
  class Service
    def self.call(*args, **kwargs)
      new(*args, **kwargs).call
    end

    private

    def success(**payload)
      payload.merge(success?: true, error: nil)
    end

    def failure(error)
      { success?: false, error: error }
    end
  end
end
