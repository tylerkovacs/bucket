require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')
require File.join(File.dirname(__FILE__), 'rails_spec_helper')
require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'bucket', 'frameworks', 'rails', 'filters')

describe Bucket::Frameworks::Rails::Filters do
  include Bucket::Frameworks::Rails::Filters

  before(:each) do
    Bucket.clear!
    cookies.clear
    params.clear

    @test1 = Bucket::Test.from_string <<-EOF
      create_bucket_test :test_1 do
        variations [1, 2, 3]
      end
    EOF
    @test2 = Bucket::Test.from_string <<-EOF
      create_bucket_test :test_2 do
        variations [4, 5, 6]
      end
    EOF
  end

  context 'before filters' do
    describe 'bucket_clear_state' do
      it 'should clear the new assignment cookie' do
        cookies[Bucket.new_assignments_cookie_name] = 'foo'
        bucket_before_filters
        cookies[Bucket.new_assignments_cookie_name].should be_nil
      end
    end

    describe 'bucket_participant' do
      it 'should assign new bucket_participant if none exists' do 
        Bucket.participant.should be_nil
        bucket_before_filters
        Bucket.participant.should == 'mkkV9YNS70946Q=='
      end

      it 'should keep the same bucket_participant if one exists' do
        Bucket.participant = 'test value'
        bucket_before_filters
        Bucket.participant.should == 'mkkV9YNS70946Q=='
      end
    end

    describe 'bucket_restore_assignments' do
      before(:each) do
        @variation1 = @test1.assign_variation
        @variation2 = @test2.assign_variation

        bucket_after_filters
        Bucket.clear_all_but_tests!
      end

      it 'should restore assignments' do
        bucket_before_filters
        Bucket::Test.get(@test1.name).assigned_variation.should == @variation1 
        Bucket::Test.get(@test2.name).assigned_variation.should == @variation2 
      end

      it 'should not record them as being assigned this request' do
        Bucket.new_assignments[@test1.name].should be_nil 
        bucket_before_filters
        Bucket.new_assignments[@test1.name].should be_nil 
      end
    end

    describe 'bucket_assignment_though_url_parameters' do
      it 'should assign variation based on a url parameter' do
        Bucket.assignments[@test1.name].should be_nil
        params[@test1.cookie_name] = 2
        bucket_before_filters
        Bucket.assignments[@test1.name].should == 2
      end

      it 'should override a value if already set' do
        Bucket.assignments[@test1.name] = 1
        params[@test1.cookie_name] = 2
        bucket_before_filters
        Bucket.assignments[@test1.name].should == 2
      end

      it 'should record them as being assigned this request' do
        Bucket.new_assignments[@test1.name].should be_nil
        params[@test1.cookie_name] = 2
        bucket_before_filters
        Bucket.new_assignments[@test1.name].should == 2
      end
    end
  end

  context 'after filters' do
    describe 'bucket_persist_participant' do
      it 'should write the participant to a cookie' do
        cookies['bucket_participant'].should be_nil
        Bucket.participant = 1
        bucket_after_filters
        cookies['bucket_participant'][:value].should == 1
      end
    end

    describe 'bucket_persist_assignments' do
      it 'should write assignments to a cookie' do
        @test1.assign_variation
        @test2.assign_variation
        bucket_after_filters

        cookie1 = cookies[@test1.cookie_name]
        @test1.variations.should include(cookie1[:value])

        cookie2 = cookies[@test2.cookie_name]
        @test2.variations.should include(cookie2[:value])
      end

      it 'should write new assignments to the new assignments cookie' do
        @test1.assign_variation
        @test2.assign_variation
        bucket_after_filters
        cookie = cookies[Bucket.new_assignments_cookie_name]
        expected = [@test1.cookie_name, @test2.cookie_name].sort
        cookie.split(',').sort.should == expected
      end
    end
  end
end
