require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'tempfile'
require 'fileutils'

describe Bucket::Store::Directory do
  before(:all) do
    @original_store = Bucket.store

    Bucket.store = Bucket::Store::Memory.new

    @test = Bucket::Test.new
    @test.name :store_test
    @test.values [:red, :green, :blue]
    @test.save
  end

  after(:all) do
    Bucket.store = @original_store
  end

  describe 'number_of_tests' do
    it 'should default to zero tests when directory is empty' do
      Bucket.store.number_of_tests.should == 1
    end
  end

  describe 'get_test' do
    it 'should return tests matching name' do
      test = Bucket.store.get_test(@test.name)
      test.name.should == @test.name
      test.values.should == @test.values
    end

    it 'should return nil if no matching name' do
      Bucket.store.get_test(:no_match).should be_nil
    end
  end

  describe 'has_test?' do
    it 'should return true on matching name' do
      Bucket.store.has_test?(@test.name).should be_true
    end

    it 'should return false on no matching name' do
      Bucket.store.has_test?(:no_match).should be_false
    end
  end

  describe 'put_test' do
    it 'should save a test to the store' do
      @test2 = Bucket::Test.new
      @test2.name :new_store_test
      Bucket.store.put_test(@test2)
      Bucket.store.has_test?(@test2.name).should be_true
    end
  end

  describe 'all_tests' do
    it 'should return a hash of all tests' do
      hash = Bucket.store.all_tests
      hash.length.should == 1
      hash.keys.should == [@test.name]
      test = hash.values.first
      test.name.should == @test.name
    end
  end

  describe 'clear!' do
    it 'should remove all tests from the store' do
      Bucket.store.number_of_tests.should == 1
      Bucket.store.clear!
      Bucket.store.number_of_tests.should == 0
    end
  end
end
