require 'spec_helper'

describe "Analytics" do
  before :each do
    @conn = Ariadna::Analytics.new("token")
  end

  it "creates a new connexion" do
    Ariadna.connexion.class.should == Ariadna::FakeConnector
  end

  context :accounts do
    before :each do
      @accounts = @conn.accounts.all
    end

    it "gets a list of accounts" do
      @accounts.size.should == 2
    end

    it "returns a list of Account objects" do
      @accounts.first.class == Ariadna::Account
    end
  end
end