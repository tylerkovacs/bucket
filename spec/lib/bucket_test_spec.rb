require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'tempfile'

describe Bucket::Test do
  before(:each) do
    Bucket.clear!

    @definition =<<-EOF
      create_bucket_test :test_name do
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
    context 'name' do
      it 'should accept a symbol for the name attribute' do
        @test.name :new_test_name
        @test.name.should == :new_test_name
      end

      it 'should not allow multiple tests with the same name' do
        lambda {
          @test2 = Bucket::Test.from_string <<-EOF
            create_bucket_test :test_name do
              variations [1, 2, 3]
            end
          EOF
        }.should raise_error(Bucket::Test::DuplicateTestNameException)
      end

      it 'should allow the name to be specified within the block' do
        new_test = Bucket::Test.from_string <<-EOF
          create_bucket_test :new_test do
            name :new_test
            variations [1, 2, 3]
          end
        EOF

        new_test.name.should == :new_test
      end

      it 'should allow the name to be passed in as the first argument' do
        new_test = Bucket::Test.from_string <<-EOF
          create_bucket_test :new_test do
            variations [1, 2, 3]
          end
        EOF

        new_test.name.should == :new_test
        new_test.variations.should == [1, 2, 3]
      end
    end

    context 'variations' do
      it 'should accept an array for the variations attribute' do
        @test.variations [1, 2, 3, 4]
        @test.variations.should == [1, 2, 3, 4]
      end

      it 'should accept nil as a variation value' do
        lambda {
          @test.variations [1, nil]
        }.should_not raise_error
      end

      it 'should accept false as a variation value' do
        lambda {
          @test.variations [1, false]
        }.should_not raise_error
      end

      it 'should accept an array of hashes for the variations attribute' do
        @test.variations [
          {:value => 1},
          {:value => 2}
        ]
        @test.variations.should == [1, 2]
      end

      it 'should support a mix of hash and non-hash variations' do
        @test.variations [
          {:value => 1},
          2
        ]
        @test.variations.should == [1, 2]
      end

      it 'should error if a hash variation is missing a :value' do
        lambda {
          @test.variations [
            {}
          ]
        }.should raise_error(Bucket::Test::InvalidTestConfigurationException)
      end

      it 'should not allow missing variations' do
        lambda {
          test = Bucket::Test.from_string <<-EOF
            create_bucket_test :bad do
            end
          EOF
        }.should raise_error(Bucket::Test::InvalidTestConfigurationException)
      end

      it 'should not allow non-Array variations' do
        lambda {
          test = Bucket::Test.from_string <<-EOF
            create_bucket_test :bad do
              variations({1 => 20})
            end
          EOF
        }.should raise_error(Bucket::Test::InvalidTestConfigurationException)
      end

      it 'should not allow empty variations' do
        lambda {
          test = Bucket::Test.from_string <<-EOF
            create_bucket_test :bad do
              variations []
            end
          EOF
        }.should raise_error(Bucket::Test::InvalidTestConfigurationException)
      end

      it 'should allow weights to be assigned to variations' do
        @test.variations [
          {:value => 1, :weight => 2},
          {:value => 2}
        ]
        @test.instance_eval("@weights[0]").should == 2.0
      end
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
    it 'should pick a variation at random' do
      variation = @test.assign_variation
      variation.should_not be_nil
      @test.variations.should include(variation)
    end

    it 'should pick a variation using an even distribution by default' do
      frequencies = Hash.new(0)
      1000.times { frequencies[@test.assign_variation_uncached] += 1}
      frequencies.values.each do |val|
        val.should be_close(333, 150) 
      end
    end

    it 'should pick a variation using a weighted distribution if configured' do
      @test.variations [
        {:value => 1, :weight => 2},
        {:value => 2}
      ]
      frequencies = Hash.new(0)
      1000.times { frequencies[@test.assign_variation_uncached] += 1}
      frequencies[1].should be_close(666, 150)
      frequencies[2].should be_close(333, 150)
    end

    it 'should support weighted distribution with any number of values' do
      @test.variations [
        {:value => 1, :weight => 0.5},
        {:value => 2},
        {:value => 3, :weight => 3.5}
      ]
      frequencies = Hash.new(0)
      1000.times { frequencies[@test.assign_variation_uncached] += 1}
      frequencies[1].should be_close(100, 150)
      frequencies[2].should be_close(200, 150)
      frequencies[3].should be_close(700, 150)
    end

    it 'should accept a value when passed in' do
      variation = @test.assign_variation(2)
      variation.should == 2
    end

    it 'should accept a value when passed in as a string' do
      variation = @test.assign_variation('2')
      variation.should == 2
    end

    it 'should not accept a value if not a valid variation' do
      variation = @test.assign_variation(-1)
      variation.should_not == -1
      @test.variations.should include(variation)
    end
  end

  describe 'variations_include' do
    it 'should return value if value is included' do
      @test.variations_include?(2).should == 2
    end

    it 'should return value if value as string is included' do
      @test.variations_include?('2').should == 2
    end

    it 'should return a value if value as symbol is included' do
      @test.variations ['one']
      @test.variations_include?(:one).should == 'one'
    end

    it 'should return nil if value is not included' do
      @test.variations_include?(7).should be_nil
    end
  end

  describe 'assigned variations' do
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

  describe 'create_bucket_test' do
    it 'shouldnot select a variation' do
      test = Bucket::Test.create_bucket_test :new_test_name do
        variations [1, 2, 3, 4]
      end
      test.assigned_variation.should be_nil
    end
  end

  describe 'bucket_test' do
    it 'should return the test with the matched name' do
      test = Bucket::Test.bucket_test :test_name
      test.should == @test
    end

    it 'should create and return a new test if no match' do
      Bucket::Test.number_of_tests.should == 1
      Bucket::Test.bucket_test :new_test_name do
        variations [1, 2, 3, 4]
      end
      Bucket::Test.number_of_tests.should == 2
      test = Bucket::Test.get(:new_test_name)
      test.variations.should == [1, 2, 3, 4]
    end

    it 'should raise an exception if no match and no block' do
      lambda {
        test = Bucket::Test.bucket_test :non_existent
      }.should raise_error(Bucket::Test::UnknownTestException)
    end

    it 'should select a variation' do
      test = Bucket::Test.bucket_test :test_name
      test.assigned_variation.should_not be_nil
      test.variations.should include(test.assigned_variation)
    end
  end
end
