# encoding: UTF-8
require 'spec_helper'

describe Mysql2::Client do
  before(:each) do
    @client = Mysql2::Client.new
  end

  it "should respond to #query" do
    @client.should respond_to(:query)
  end

  context "#pseudo_bind" do
    it "should return query just same as argument, if without any placeholders" do
      @client.__send__(:pseudo_bind, "SELECT x,y,z FROM x WHERE x='1'", []).should eql("SELECT x,y,z FROM x WHERE x='1'")
    end

    it "should return replaced query if with placeholders" do
      @client.__send__(:pseudo_bind, "SELECT x,y,z FROM x WHERE x=?", [1]).should eql("SELECT x,y,z FROM x WHERE x='1'")
      @client.__send__(:pseudo_bind, "SELECT x,y,z FROM x WHERE x=? AND y=?", [1, 'X']).should eql("SELECT x,y,z FROM x WHERE x='1' AND y='X'")
    end
      
    it "should raise ArgumentError if mismatch exists between placeholders and arguments" do
      expect {
        @client.__send__(:pseudo_bind, "SELECT x,y,z FROM x", [1])
      }.should raise_exception(ArgumentError)
      expect {
        @client.__send__(:pseudo_bind, "SELECT x,y,z FROM x WHERE x=?", [1,2])
      }.should raise_exception(ArgumentError)
      expect {
        @client.__send__(:pseudo_bind, "SELECT x,y,z FROM x WHERE x=? AND y=?", [1])
      }.should raise_exception(ArgumentError)
      expect {
        @client.__send__(:pseudo_bind, "SELECT x,y,z FROM x WHERE x=?", [])
      }.should raise_exception(ArgumentError)
    end

    it "should replace placeholder with NULL about nil" do
      @client.__send__(:pseudo_bind, "UPDATE x SET y=? WHERE x=?", [nil,1]).should eql("UPDATE x SET y=NULL WHERE x='1'")
    end

    it "should replace placeholder with formatted timestamp string about Time object" do
      require 'time'
      t = Time.strptime('2012/04/20 16:50:45', '%Y/%m/%d %H:%M:%S')
      @client.__send__(:pseudo_bind, "UPDATE x SET y=? WHERE x=?", [t,1]).should eql("UPDATE x SET y='2012-04-20 16:50:45' WHERE x='1'")
    end
  end

  context "#xquery" do
    it "should let you query again if iterating is finished when streaming" do
      @client.xquery("SELECT 1 UNION SELECT ?", 2, :stream => true, :cache_rows => false).each {}

      expect {
        @client.xquery("SELECT 1 UNION SELECT ?", 2, :stream => true, :cache_rows => false)
      }.to_not raise_exception(Mysql2::Error)
    end

    it "should accept an options hash that inherits from Mysql2::Client.default_query_options" do
      @client.xquery "SELECT ?", 1, :something => :else
      @client.query_options.should eql(@client.query_options.merge(:something => :else))
    end

    it "should return results as a hash by default" do
      @client.xquery("SELECT ?", 1).first.class.should eql(Hash)
    end

    it "should be able to return results as an array" do
      @client.xquery("SELECT ?", 1, :as => :array).first.class.should eql(Array)
      @client.xquery("SELECT ?", 1).each(:as => :array)
      @client.query("SELECT 1").first.should eql([1])
      @client.query("SELECT '1'").first.should eql(['1'])
      @client.xquery("SELECT 1", :as => :array).first.should eql([1])
      @client.xquery("SELECT ?", 1).first.should eql(['1'])
      @client.xquery("SELECT ?+1", 1).first.should eql([2.0])
    end

    it "should be able to return results with symbolized keys" do
      @client.xquery("SELECT 1", :symbolize_keys => true).first.keys[0].class.should eql(Symbol)
    end

    it "should require an open connection" do
      @client.close
      lambda {
        @client.xquery "SELECT ?", 1
      }.should raise_error(Mysql2::Error)
    end
  end

  it "should respond to escape" do
    Mysql2::Client.should respond_to(:escape)
  end

  if RUBY_VERSION =~ /1.9/
    it "should respond to #encoding" do
      @client.should respond_to(:encoding)
    end
  end
end