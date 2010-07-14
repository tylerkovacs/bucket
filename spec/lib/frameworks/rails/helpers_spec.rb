require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')
require File.join(File.dirname(__FILE__), 'rails_spec_helper')
require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'bucket', 'frameworks', 'rails', 'helpers')

describe Bucket::Frameworks::Rails::Helpers do
  include Bucket::Frameworks::Rails::Helpers

  before(:each) do
    Bucket.clear!
    @test = Bucket::Test.from_string <<-EOF
      bucket_test :test_name do
        variations [1, 2, 3]
      end
    EOF
  end

  describe 'bucket_test' do
    it 'should return the test with the matched name' do
      test = bucket_test :test_name
      test.should == @test
    end

    it 'should create and return a new test if no match' do
      Bucket::Test.number_of_tests.should == 1
      bucket_test :new_test_name do
        variations [1, 2, 3, 4]
      end
      Bucket::Test.number_of_tests.should == 2
      test = Bucket::Test.get(:new_test_name)
      test.variations.should == [1, 2, 3, 4]
    end

    it 'should raise an exception if no match and no block' do
      lambda {
        test = bucket_test :non_existent
      }.should raise_error(Bucket::Test::UnknownTestException)
    end

    it 'should select a variation' do
      test = bucket_test :test_name
      test.assigned_variation.should_not be_nil
      test.variations.should include(test.assigned_variation)
    end
  end
end
