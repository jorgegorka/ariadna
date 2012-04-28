require 'spec_helper'

describe "ErrorCode" do
  context "A new error code" do
    before :each do
      new_error = {
        "error" => {
          "errors" => [
           {
            "domain"       => "global",
            "reason"       => "invalidParameter",
            "message"      => "Invalid value '-1' for max-results. Value must be within the range: [1, 1000]",
            "locationType" => "parameter",
            "location"     => "max-results"
           }
          ],
          "code"           => 400,
          "message"        => "Invalid value '-1' for max-results. Value must be within the range: [1, 1000]"
         }
      }

      @error = Ariadna::Error.new(new_error)
      @error_code = @error.errors.first
    end

    it "should have all information mapped as attributes" do
      @error_code.domain.should  == "global"
      @error_code.reason.should  == "invalidParameter"
      @error_code.message.should == "Invalid value '-1' for max-results. Value must be within the range: [1, 1000]"
    end
  end
end