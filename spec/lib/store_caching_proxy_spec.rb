require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'tempfile'
require 'fileutils'

describe Bucket::Store::Directory do
  before(:all) do
    @original_store = Bucket.store

    Bucket.store = Bucket::Store::Memory.new
    Bucket.store_proxy_cache = Bucket::Store::CachingProxy.new(60)

    @test = Bucket::Test.new
    @test.name :store_test
    @test.values [:red, :green, :blue]
    @test.save

    Bucket.store_proxy_cache.refresh_from_store
  end

  after(:all) do
    Bucket.store = @original_store
  end

  context 'warm cache' do
    before(:each) do
      Bucket.store_proxy_cache.stale?.should be_false
    end

    describe 'number_of_tests' do
      it 'should default to zero tests when directory is empty' do
        Bucket.store.should_not_receive(:number_of_tests)
        Bucket.store_proxy_cache.number_of_tests.should == 1
      end
    end

    describe 'get_test' do
      it 'should return tests matching name' do
        Bucket.store.should_not_receive(:get_test)
        test = Bucket.store_proxy_cache.get_test(@test.name)
        test.name.should == @test.name
        test.values.should == @test.values
      end

      it 'should return nil if no matching name' do
        Bucket.store.should_not_receive(:get_test)
        Bucket.store_proxy_cache.get_test(:no_match).should be_nil
      end
    end

    describe 'has_test?' do
      it 'should return true on matching name' do
        Bucket.store.should_not_receive(:has_test?)
        Bucket.store_proxy_cache.has_test?(@test.name).should be_true
      end

      it 'should return false on no matching name' do
        Bucket.store.should_not_receive(:has_test?)
        Bucket.store_proxy_cache.has_test?(:no_match).should be_false
      end
    end

    describe 'put_test' do
      it 'should save a test to the store' do
        Bucket.store.should_receive(:put_test)
        @test2 = Bucket::Test.new
        @test2.name :new_store_test
        Bucket.store_proxy_cache.put_test(@test2)
        Bucket.store_proxy_cache.has_test?(@test2.name).should be_true
      end
    end

    describe 'all_tests' do
      it 'should return a hash of all tests' do
        Bucket.store.should_not_receive(:all_tests)
        hash = Bucket.store_proxy_cache.all_tests
        hash.length.should == 1
        hash.keys.should == [@test.name]
        test = hash.values.first
        test.name.should == @test.name
      end
    end

    describe 'clear!' do
      it 'should remove all tests from the store' do
        Bucket.store.should_not_receive(:all_tests)
        Bucket.store.should_receive(:clear!)
        Bucket.store_proxy_cache.number_of_tests.should == 1
        Bucket.store_proxy_cache.clear!
        Bucket.store_proxy_cache.number_of_tests.should == 0
      end
    end
  end

  context 'cold cache' do
    before(:each) do
      Bucket.store_proxy_cache.stub!(:stale?).and_return(true)
    end

    describe 'number_of_tests' do
      it 'should default to zero tests when directory is empty' do
        Bucket.store.should_receive(:all_tests).and_return(Bucket.store.instance_eval("@hash"))
        Bucket.store_proxy_cache.number_of_tests.should == 1
      end
    end

    describe 'get_test' do
      it 'should return tests matching name' do
        Bucket.store.should_receive(:all_tests).and_return(Bucket.store.instance_eval("@hash"))
        test = Bucket.store_proxy_cache.get_test(@test.name)
        test.name.should == @test.name
        test.values.should == @test.values
      end

      it 'should return nil if no matching name' do
        Bucket.store.should_receive(:all_tests).and_return(Bucket.store.instance_eval("@hash"))
        Bucket.store_proxy_cache.get_test(:no_match).should be_nil
      end
    end

    describe 'has_test?' do
      it 'should return true on matching name' do
        Bucket.store.should_receive(:all_tests).and_return(Bucket.store.instance_eval("@hash"))
        Bucket.store_proxy_cache.has_test?(@test.name).should be_true
      end

      it 'should return false on no matching name' do
        Bucket.store.should_not_receive(:has_test?)
        Bucket.store_proxy_cache.has_test?(:no_match).should be_false
      end
    end

    describe 'put_test' do
      it 'should save a test to the store' do
        Bucket.store.should_receive(:put_test)
        @test2 = Bucket::Test.new
        @test2.name :new_store_test
        Bucket.store.should_receive(:all_tests).and_return({
          @test.name => @test,
          @test2.name => @test2
        })
        Bucket.store_proxy_cache.put_test(@test2)
        Bucket.store_proxy_cache.has_test?(@test2.name).should be_true
      end
    end

    describe 'all_tests' do
      it 'should return a hash of all tests' do
        Bucket.store.should_receive(:all_tests).and_return(Bucket.store.instance_eval("@hash"))
        hash = Bucket.store_proxy_cache.all_tests
        hash.length.should == 1
        hash.keys.should == [@test.name]
        test = hash.values.first
        test.name.should == @test.name
      end
    end

    describe 'clear!' do
      it 'should remove all tests from the store' do
        Bucket.store.should_receive(:all_tests).at_least(:once).and_return(Bucket.store.instance_eval("@hash"))
        Bucket.store.should_receive(:clear!)
        Bucket.store_proxy_cache.number_of_tests.should == 1
        Bucket.store_proxy_cache.clear!
        Bucket.store_proxy_cache.number_of_tests.should == 0
      end
    end
  end
end
