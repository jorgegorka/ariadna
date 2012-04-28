module Ariadna
  class Error < StandardError
    attr_reader :errors, :code, :message
  
    def initialize(error_codes)
      @errors  = ErrorCode.get_errors(error_codes["error"]["errors"])
      @code    = error_codes["error"]["code"]
      @message = error_codes["error"]["message"]
    end
  end
end