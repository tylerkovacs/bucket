require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')
require File.join(File.dirname(__FILE__), 'rails_spec_helper')
require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'bucket', 'frameworks', 'rails', 'helpers')

describe Bucket::Frameworks::Rails::Helpers do
  include Bucket::Frameworks::Rails::Helpers

  before(:each) do
    Bucket.clear!
    @test = Bucket::Test.from_dsl <<-EOF
      create_bucket_test :test_name do
        values [:red, :green, :blue]
      end
    EOF
  end

  describe 'bucket_test' do
    it 'should return the test with the matched name' do
      test = bucket_test :test_name
      test.name.should == :test_name
      test.values.should == [:red, :green, :blue]
      test.default.should be_nil
      test.start_at.should be_nil
      test.end_at.should be_nil
    end

    it 'should create and return a new test if no match' do
      Bucket::Test.number_of_tests.should == 1
      bucket_test :new_test_name do
        values [:red, :green, :blue, :cyan]
      end
      Bucket::Test.number_of_tests.should == 2
      test = Bucket::Test.get_test(:new_test_name)
      test.values.should == [:red, :green, :blue, :cyan]
    end

    it 'should raise an exception if no match and no block' do
      lambda {
        test = bucket_test :non_existent
      }.should raise_error(Bucket::Test::UnknownTestException)
    end

    it 'should select a value' do
      test = bucket_test :test_name
      test.value.should_not be_nil
      test.values.should include(test.value)
    end

    it 'should record as being assigned in this request' do
      Bucket.new_assignments[@test.name].should be_nil
      test = bucket_test :test_name
      Bucket.new_assignments[@test.name].should_not be_nil
    end
  end
end
