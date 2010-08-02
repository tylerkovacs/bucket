require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'tempfile'

describe Bucket::Test do
  before(:each) do
    Bucket.clear!

    @test = Bucket::Test.from_dsl <<-EOF
      create_bucket_test :test_name do
        values [1, 'string', :red]
        default :red
        start_at '2010/07/20 03:00:00'
        end_at '2010/07/20 05:00:00'
      end
    EOF
  end

  context 'dsl' do
    it 'should return a dsl for the test' do
      t = @test.to_dsl
      t.is_a?(String).should be_true
      t.should include("define_test :#{@test.name} do")
    end

    it 'should be able to restore test from dsl' do
      test = Bucket::Test.from_dsl(@test.to_dsl)
      test.name.should == :test_name
      test.values.should == [1, 'string', :red]
      test.default.should == :red
      test.start_at.should == Time.parse('2010/07/20 03:00:00')
      test.end_at.should == Time.parse('2010/07/20 05:00:00')
    end
  end

  context 'yaml' do
    it 'should return a yaml string for the test' do
      t = @test.to_yaml
      t.is_a?(String).should be_true
      t.should include("Bucket::Test")
    end

    it 'should be able to restore test from yaml' do
      test = Bucket::Test.from_yaml(@test.to_yaml)
      test.name.should == :test_name
      test.values.should == [1, 'string', :red]
      test.default.should == :red
      test.start_at.should == Time.parse('2010/07/20 03:00:00')
      test.end_at.should == Time.parse('2010/07/20 05:00:00')
    end
  end

  context 'marshal' do
    it 'should marshal object to a string' do
      t = @test.marshal
      t.is_a?(String).should be_true
      t.should include("Bucket::Test")
    end

    it 'should be able to restore test from marshal' do
      test = Bucket::Test.from_marshal(@test.marshal)
      test.name.should == :test_name
      test.values.should == [1, 'string', :red]
      test.default.should == :red
      test.start_at.should == Time.parse('2010/07/20 03:00:00')
      test.end_at.should == Time.parse('2010/07/20 05:00:00')
    end
  end

  context 'hash' do
    it 'should convert object to a hash' do
      t = @test.to_hash
      t.is_a?(Hash).should be_true
      t[:name].should == :test_name
    end

    it 'should be able to restore test from hash' do
      test = Bucket::Test.from_hash(@test.to_hash)
      test.name.should == :test_name
      test.values.should == [1, 'string', :red]
      test.default.should == :red
      test.start_at.should == Time.parse('2010/07/20 03:00:00')
      test.end_at.should == Time.parse('2010/07/20 05:00:00')
    end
  end
end
