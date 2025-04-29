module Base
  class Result
    attr_reader :success, :error, :data

    def initialize(success: true, error: nil, **data)
      @success = success
      @error = error
      @data = data
    end

    def success?
      @success
    end

    def method_missing(name, *args)
      return data[name] if data.key?(name)
      super
    end

    def respond_to_missing?(name, include_private = false)
      data.key?(name) || super
    end
  end
end
