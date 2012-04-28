require 'spec_helper'

describe "Error" do

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
  end
  
  context "when a new error is created" do
    it "should contain an array of errors" do
      @error.errors.size.should == 1
    end

    it "should have an error code" do
      @error.code.should == 400
    end

    it "should have an error message" do
      @error.message.should == "Invalid value '-1' for max-results. Value must be within the range: [1, 1000]"
    end
  end

  context "a bad request" do
    it "should return an error object" do
      conn   = Ariadna::Analytics.new("token")
      Ariadna.connexion.stub(:get_url).with("error").and_return(["bad request", @error])
      error  = Ariadna.connexion.get_url("error")
      
      error[1].class.should == Ariadna::Error
    end
  end
end