require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'tempfile'

describe Bucket::Test do
  before(:each) do
    Bucket.clear!

    @definition =<<-EOF
      bucket_test :test_name do
        variations [1, 2, 3]
      end
    EOF
    @test = Bucket::Test.from_string(@definition)
  end

  describe 'get' do
    it 'should return a test with a matching name' do
      Bucket::Test.get(:test_name).should == @test
    end

    it 'should return nil if no match' do
      Bucket::Test.get('no such test').should be_nil
    end
  end

  describe 'attributes' do
    it 'should accept a string for the name attribute' do
      @test.name :new_test_name
      @test.name.should == :new_test_name
    end

    it 'should accept an array for the variations attribute' do
      @test.variations [1, 2, 3, 4]
      @test.variations.should == [1, 2, 3, 4]
    end

    it 'should allow the name to be specified within the block' do
      new_test = Bucket::Test.from_string <<-EOF
        bucket_test :new_test do
          name :new_test
          variations [1, 2, 3]
        end
      EOF

      new_test.name.should == :new_test
    end

    it 'should allow the name to be passed in as the first argument' do
      new_test = Bucket::Test.from_string <<-EOF
        bucket_test :new_test do
          variations [1, 2, 3]
        end
      EOF

      new_test.name.should == :new_test
      new_test.variations.should == [1, 2, 3]
    end
  end

  describe 'from_string' do
    it 'should set supported attribute' do
      @test.name.should == :test_name
      @test.variations.should == [1, 2, 3]
    end

    it 'should register the new test' do
      Bucket::Test.number_of_tests.should == 1
    end
  end

  describe 'from_file' do
    it 'should read the test definition from a file' do
      Bucket.clear_tests!
      Bucket::Test.number_of_tests.should == 0

      Tempfile.open('from_file') do |file|
        file.write @definition
        file.fsync

        new_test = Bucket::Test.from_file(file.path)
        new_test.name.should == :test_name
        new_test.variations.should == [1, 2, 3]
      end

      Bucket::Test.number_of_tests.should == 1
    end
  end

  describe 'clear!' do
    it 'should remove all registered tests' do
      Bucket::Test.number_of_tests.should == 1
      Bucket::Test.clear!
      Bucket::Test.number_of_tests.should == 0
    end
  end

  describe 'assign_variation' do
    it 'should pick an variation at random' do
      variation = @test.assign_variation
      variation.should_not be_nil
      @test.variations.should include(variation)
    end

    it 'should pick an variation using an even distribution' do
      frequencies = Hash.new(0)
      1000.times { frequencies[@test.assign_variation_uncached] += 1}

      frequencies.values.each do |val|
        val.should be_close(333, 150) 
      end
    end

    it 'should accept a value when passed in' do
      variation = @test.assign_variation(2)
      variation.should == 2
    end

    it 'should not accept a value if not a valid variation' do
      variation = @test.assign_variation(-1)
      variation.should_not == -1
      @test.variations.should include(variation)
    end
  end

  describe 'variation' do
    it 'should return the selected variation' do
      variation = @test.assign_variation
      variation.should_not be_nil
      @test.variations.should include(variation)
    end

    it 'should not change between calls' do
      variation = @test.assigned_variation
      10.times { @test.assigned_variation.should == variation }
    end
  end
end
