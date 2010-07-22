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
      @test.to_dsl.should ==<<-EOF
create_bucket_test :test_name do
  name :test_name
  values [1, "string", :red]
  default :red
  start_at "Tue Jul 20 03:00:00 -0700 2010"
  end_at "Tue Jul 20 05:00:00 -0700 2010"
  paused nil
end
      EOF
    end

    it 'should be able to restore test from dsl' do
      dsl = @test.to_dsl
      Bucket.store.clear!      
      dsl = test = Bucket::Test.from_dsl(@test.to_dsl)
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
end
