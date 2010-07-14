require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')
require File.join(File.dirname(__FILE__), 'rails_spec_helper')
require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'bucket', 'frameworks', 'rails', 'filters')

describe Bucket::Frameworks::Rails::Filters do
  include Bucket::Frameworks::Rails::Filters

  before(:each) do
    Bucket.clear!
    cookies.clear

    @test1 = Bucket::Test.from_string <<-EOF
      bucket_test :test_1 do
        variations [1, 2, 3]
      end
    EOF
    @test2 = Bucket::Test.from_string <<-EOF
      bucket_test :test_2 do
        variations [4, 5, 6]
      end
    EOF
  end

  describe 'bucket_participant' do
    it 'should assign new bucket_participant if none exists' do 
      Bucket.participant.should be_nil
      bucket_participant
      Bucket.participant.should == 'mkkV9YNS70946Q=='
    end

    it 'should keep the same bucket_participant if one exists' do
      Bucket.participant = 'test value'
      bucket_participant
      Bucket.participant.should == 'mkkV9YNS70946Q=='
    end
  end

  describe 'persist_bucket_state' do
    it 'should write the participant to a cookie' do
      cookies['bucket_participant'].should be_nil
      Bucket.participant = 1
      persist_bucket_state
      cookies['bucket_participant'][:value].should == 1
    end

    it 'should write assignments to a cookie' do
      @test1.assign_variation
      @test2.assign_variation

      persist_bucket_state

      cookie1 = cookies[Bucket::Test.cookie_name(@test1.name)]
      @test1.variations.should include(cookie1[:value])

      cookie2 = cookies[Bucket::Test.cookie_name(@test2.name)]
      @test2.variations.should include(cookie2[:value])
    end
  end

  describe 'restore_bucket_state' do
    it 'should restore assignments' do
      variation1 = @test1.assign_variation
      variation2 = @test2.assign_variation

      persist_bucket_state
      Bucket.clear_all_but_tests!
      restore_bucket_state

      Bucket::Test.get(@test1.name).assigned_variation.should == variation1 
      Bucket::Test.get(@test2.name).assigned_variation.should == variation2 
    end
  end
end
