require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')
require File.join(File.dirname(__FILE__), 'rails_spec_helper')
require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'bucket', 'frameworks', 'rails', 'filters')

describe Bucket::Frameworks::Rails::Filters do
  include Bucket::Frameworks::Rails::Filters

  before(:each) do
    Bucket.clear!
    cookies.clear
    params.clear

    @test1 = Bucket::Test.from_dsl <<-EOF
      create_bucket_test :test_1 do
        values [1, 2, 3]
      end
    EOF
    @test2 = Bucket::Test.from_dsl <<-EOF
      create_bucket_test :test_2 do
        values [4, 5, 6]
      end
    EOF
  end

  context 'before filters' do
    describe 'bucket_clear_state' do
      it 'should clear the new participation cookie' do
        cookies[Bucket.cookie_name(:participations)] = 'foo'
        bucket_before_filters
        cookies[Bucket.cookie_name(:participations)].should be_nil
      end

      it 'should clear conversion state' do
        Bucket.conversions = [1]
        bucket_before_filters
        Bucket.conversions.should == []
      end
    end

    describe 'bucket_participant' do
      it 'should participate new bucket_participant if none exists' do 
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

    describe 'bucket_restore_participations' do
      context 'active test' do
        before(:each) do
          @value1 = @test1.participate
          @value2 = @test2.participate

          bucket_after_filters
          Bucket.clear_all_but_test_definitions!
        end

        it 'should restore participations' do
          bucket_before_filters
          Bucket::Test.get_test(@test1.name).value.should == @value1
          Bucket::Test.get_test(@test2.name).value.should == @value2
        end

        it 'should not record them as being participated this request' do
          Bucket.new_participations[@test1.name].should be_nil 
          bucket_before_filters
          Bucket.new_participations[@test1.name].should be_nil 
        end
      end

      context 'inactive test' do
        before(:each) do
          @value1 = @test1.participate

          bucket_after_filters
          Bucket.clear_all_but_test_definitions!
          @test1.pause
          @test1.active?.should be_false
        end

        it 'should restore participations' do
          bucket_before_filters
          Bucket::Test.get_test(@test1.name).value.should be_nil
        end

        it 'should not record them as being participated this request' do
          Bucket.new_participations[@test1.name].should be_nil 
          bucket_before_filters
          Bucket.new_participations[@test1.name].should be_nil 
        end
      end
    end

    describe 'bucket_participation_though_url_parameters' do
      context 'active test' do
        it 'should participate value based on a url parameter' do
          Bucket.participations[@test1.name].should be_nil
          params[@test1.cookie_name] = 2
          bucket_before_filters
          Bucket.participations[@test1.name].should == 2
        end

        it 'should override a value if already set' do
          Bucket.participations[@test1.name] = 1
          params[@test1.cookie_name] = 2
          bucket_before_filters
          Bucket.participations[@test1.name].should == 2
        end

        it 'should record them as being participated this request' do
          Bucket.new_participations[@test1.name].should be_nil
          params[@test1.cookie_name] = 2
          bucket_before_filters
          Bucket.new_participations[@test1.name].should == 2
        end
      end

      context 'inactive test' do
        before(:each) do
          @test1.pause
          @test1.active?.should be_false
        end

        it 'should participate value based on a url parameter' do
          Bucket.participations[@test1.name].should be_nil
          params[@test1.cookie_name] = 2
          bucket_before_filters
          Bucket.participations[@test1.name].should == 2
        end

        it 'should override a value if already set' do
          Bucket.participations[@test1.name] = 1
          params[@test1.cookie_name] = 2
          bucket_before_filters
          Bucket.participations[@test1.name].should == 2
        end

        it 'should record them as being participated this request' do
          Bucket.new_participations[@test1.name].should be_nil
          params[@test1.cookie_name] = 2
          bucket_before_filters
          Bucket.new_participations[@test1.name].should == 2
        end
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

    describe 'bucket_persist_participations' do
      context 'active test' do
        it 'should write participations to a cookie' do
          @test1.participate
          @test2.participate
          bucket_after_filters

          cookie1 = cookies[@test1.cookie_name]
          @test1.values.should include(cookie1[:value])

          cookie2 = cookies[@test2.cookie_name]
          @test2.values.should include(cookie2[:value])
        end

        it 'should write new participations to the new participations cookie' do
          @test1.participate
          @test2.participate
          bucket_after_filters
          cookie = cookies[Bucket.cookie_name(:participations)][:value]
          expected = [@test1.cookie_name, @test2.cookie_name].sort
          cookie.split(',').sort.should == expected
        end
      end

      context 'inactive test' do
        before(:each) do
          @test1.pause
          @test1.active?.should be_false
        end

        it 'should not write participations to a cookie' do
          @test1.participate
          bucket_after_filters
          cookies[@test1.cookie_name].should be_nil
        end

        it 'should not write new participations to the new participations cookie' do
          @test1.participate
          bucket_after_filters
          cookies[Bucket.cookie_name(:participations)][:value].should be_empty
        end
      end
    end

    describe 'bucket_persist_conversions' do
      it 'should write conversions to the conversion cookie' do
        @test1.convert
        @test2.convert
        bucket_after_filters

        cookie = cookies[Bucket.cookie_name(:conversions)][:value]
        expected = [@test1.cookie_name, @test2.cookie_name].sort
        cookie.split(',').sort.should == expected
      end
    end
  end
end
