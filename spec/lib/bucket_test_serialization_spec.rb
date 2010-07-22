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
    describe 'to_dsl' do
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

      it 'should be able to restore from dsl' do
        dsl = @test.to_dsl
      end
    end
  end

  context 'yaml' do
    describe 'to_yaml' do
      it 'should a yaml string for the test' do
        @test.to_yaml.should == "--- !ruby/object:Bucket::Test \nattributes: \n  name: :test_name\n  end_at: 2010-07-20 05:00:00 -07:00\n  default: :red\n  start_at: 2010-07-20 03:00:00 -07:00\n  values: \n  - 1\n  - string\n  - :red\nweights: {}\n\n"
      end
    end
  end

  context 'marshal' do
    describe 'marshal' do
      it 'should marshal object to a string' do
        t = @test.marshal
        t.is_a?(String).should be_true
        t.should include("Bucket::Test")
      end
    end
  end
end
