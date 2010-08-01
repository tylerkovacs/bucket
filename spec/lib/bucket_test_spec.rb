require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'tempfile'

describe Bucket::Test do
  before(:each) do
    Bucket.clear!

    @definition =<<-EOF
      create_bucket_test :test_name do
        values [1, 2, 3]
      end
    EOF
    @test = Bucket::Test.from_dsl(@definition)
  end

  describe 'get' do
    it 'should return a test with a matching name' do
      test = Bucket::Test.get_test(:test_name)
      test.name.should == :test_name
      test.values.should == [1, 2, 3]
    end

    it 'should return nil if no match' do
      Bucket::Test.get_test('no such test').should be_nil
    end
  end

  describe 'save' do
    it 'should allow tests changes to written to store' do
      test = Bucket::Test.get_test(:test_name)
      test.values [1,2]
      test.save

      Bucket::Test.get_test(:test_name).values.should == [1,2]
    end
  end

  describe 'attributes' do
    context 'name' do
      it 'should accept a symbol for the name attribute' do
        @test.name :new_test_name
        @test.name.should == :new_test_name
      end

      it 'should return an cookie name of 20 characters' do
        @test.cookie_name.should == "bucket_test_4fce0bb2"
        @test.cookie_name.length.should == 20
      end

      it 'should return a cookie name of 8 characters' do
        @test.encoded_name.should == "4fce0bb2"
        @test.encoded_name.length.should == 8
      end

      it 'should not allow multiple tests with the same name' do
        lambda {
          @test2 = Bucket::Test.from_dsl <<-EOF
            create_bucket_test :test_name do
              values [1, 2, 3]
            end
          EOF
        }.should raise_error(Bucket::Test::DuplicateTestNameException)
      end

      it 'should allow the name to be specified within the block' do
        new_test = Bucket::Test.from_dsl <<-EOF
          create_bucket_test :new_test do
            name :new_test
            values [1, 2, 3]
          end
        EOF

        new_test.name.should == :new_test
      end

      it 'should allow the name to be passed in as the first argument' do
        new_test = Bucket::Test.from_dsl <<-EOF
          create_bucket_test :new_test do
            values [1, 2, 3]
          end
        EOF

        new_test.name.should == :new_test
        new_test.values.should == [1, 2, 3]
      end
    end

    context 'values' do
      it 'should accept an array for the values attribute' do
        @test.values [1, 2, 3, 4]
        @test.values.should == [1, 2, 3, 4]
      end

      it 'should accept nil as a value value' do
        lambda {
          @test.values [1, nil]
        }.should_not raise_error
      end

      it 'should accept false as a value value' do
        lambda {
          @test.values [1, false]
        }.should_not raise_error
      end

      it 'should accept an array of hashes for the values attribute' do
        @test.values [
          {:value => 1},
          {:value => 2}
        ]
        @test.values.should == [1, 2]
      end

      it 'should support a mix of hash and non-hash values' do
        @test.values [
          {:value => 1},
          2
        ]
        @test.values.should == [1, 2]
      end

      it 'should error if a hash value is missing a :value' do
        lambda {
          @test.values [
            {}
          ]
        }.should raise_error(Bucket::Test::InvalidTestConfigurationException)
      end

      it 'should not allow missing values' do
        lambda {
          test = Bucket::Test.from_dsl <<-EOF
            create_bucket_test :bad do
            end
          EOF
        }.should raise_error(Bucket::Test::InvalidTestConfigurationException)
      end

      it 'should not allow non-Array values' do
        lambda {
          test = Bucket::Test.from_dsl <<-EOF
            create_bucket_test :bad do
              values({1 => 20})
            end
          EOF
        }.should raise_error(Bucket::Test::InvalidTestConfigurationException)
      end

      it 'should not allow empty values' do
        lambda {
          test = Bucket::Test.from_dsl <<-EOF
            create_bucket_test :bad do
              values []
            end
          EOF
        }.should raise_error(Bucket::Test::InvalidTestConfigurationException)
      end

      it 'should allow weights to be participated to values' do
        @test.values [
          {:value => 1, :weight => 2},
          {:value => 2}
        ]
        @test.instance_eval("@weights[0]").should == 2.0
      end
    end
  end

  describe 'from_dsl' do
    it 'should set supported attribute' do
      @test.name.should == :test_name
      @test.values.should == [1, 2, 3]
    end

    it 'should register the new test' do
      Bucket::Test.number_of_tests.should == 1
    end
  end

  describe 'participate' do
    context 'active' do
      it 'should pick a value at random' do
        value = @test.participate
        value.should_not be_nil
        @test.values.should include(value)
      end

      it 'should record in new_participations by default' do
        Bucket.new_participations[@test.name].should be_nil
        value = @test.participate
        Bucket.new_participations[@test.name].should == value
      end

      it 'should not record in new_participations with previously_participated argument' do
        Bucket.new_participations[@test.name].should be_nil
        value = @test.participate(1, {:previously_participated => true})
        Bucket.new_participations[@test.name].should be_nil
      end

      it 'should pick a value using an even distribution by default' do
        frequencies = Hash.new(0)
        1000.times { frequencies[@test.participate_uncached] += 1}
        frequencies.values.each do |val|
          val.should be_close(333, 150) 
        end
      end

      it 'should pick a value using a weighted distribution if configured' do
        @test.values [
          {:value => 1, :weight => 2},
          {:value => 2}
        ]
        frequencies = Hash.new(0)
        1000.times { frequencies[@test.participate_uncached] += 1}
        frequencies[1].should be_close(666, 150)
        frequencies[2].should be_close(333, 150)
      end

      it 'should support weighted distribution with any number of values' do
        @test.values [
          {:value => 1, :weight => 0.5},
          {:value => 2},
          {:value => 3, :weight => 3.5}
        ]
        frequencies = Hash.new(0)
        1000.times { frequencies[@test.participate_uncached] += 1}
        frequencies[1].should be_close(100, 150)
        frequencies[2].should be_close(200, 150)
        frequencies[3].should be_close(700, 150)
      end

      it 'should accept a value when passed in' do
        value = @test.participate(2)
        value.should == 2
      end

      it 'should not override a value if already set by default' do
        value = @test.participate(2)
        value.should == 2
        value = @test.participate(3)
        value.should == 2
      end

      it 'should override a value if already set by default using force' do
        value = @test.participate(2)
        value.should == 2
        value = @test.force_participate(3)
        value.should == 3
      end

      it 'should accept a value when passed in as a string' do
        value = @test.participate('2')
        value.should == 2
      end

      it 'should not accept a value if not a valid value' do
        value = @test.participate(-1)
        value.should_not == -1
        @test.values.should include(value)
      end
    end

    context 'inactive' do
      before(:each) do
        @test.pause
        @test.active?.should be_false
      end

      it 'should return the default value if the test is not active' do
        @test.participate.should == @test.default_value
      end

      it 'should not participate a persistent value if test is not active' do
        Bucket.participations[@test.name].should be_nil
        Bucket.new_participations[@test.name].should be_nil
      end

      it 'should not allow a manual participation by default' do
        @test.participate(2).should == 1
      end

      it 'should allow a manual participation when force option used' do
        @test.participate(2, {:force => true}).should == 2
      end
    end
  end

  describe 'values_include' do
    it 'should return value if value is included' do
      @test.values_include?(2).should == 2
    end

    it 'should return value if value as string is included' do
      @test.values_include?('2').should == 2
    end

    it 'should return a value if value as symbol is included' do
      @test.values ['one']
      @test.values_include?(:one).should == 'one'
    end

    it 'should return nil if value is not included' do
      @test.values_include?(7).should be_nil
    end
  end

  describe 'participated values' do
    it 'should return the selected value' do
      value = @test.participate
      value.should_not be_nil
      @test.values.should include(value)
    end

    it 'should not change between calls' do
      value = @test.value
      10.times { @test.value.should == value }
    end
  end

  describe 'create_bucket_test' do
    it 'should not select a value' do
      test = Bucket::Test.create_bucket_test :new_test_name do
        values [1, 2, 3, 4]
      end
      test.value.should be_nil
    end
  end

  describe 'bucket_test' do
    it 'should return the test with the matched name' do
      test = Bucket::Test.bucket_test :test_name
      test.name.should == :test_name
      test.values.should == [1, 2, 3]
      test.default.should be_nil
      test.start_at.should be_nil
      test.end_at.should be_nil
    end

    it 'should create and return a new test if no match' do
      Bucket::Test.number_of_tests.should == 1
      Bucket::Test.bucket_test :new_test_name do
        values [1, 2, 3, 4]
      end
      Bucket::Test.number_of_tests.should == 2
      test = Bucket::Test.get_test(:new_test_name)
      test.values.should == [1, 2, 3, 4]
    end

    it 'should raise an exception if no match and no block' do
      lambda {
        test = Bucket::Test.bucket_test :non_existent
      }.should raise_error(Bucket::Test::UnknownTestException)
    end

    it 'should select a value' do
      test = Bucket::Test.bucket_test :test_name
      test.value.should_not be_nil
      test.values.should include(test.value)
    end
  end

  describe 'default value' do
    it 'should participate a default value' do
      @test.default 2
      @test.default_value.should == 2
    end

    it 'should default to the first value' do
      @test.default_value.should == 1
    end

    it 'should not participate a default value if default is invalid' do
      @test.default 4
      @test.default_value.should == 1
    end
  end

  describe 'start and end times' do
    it 'should allow you to participate a start_at that gets converted to a Time' do
      ts = '2010/07/20 03:00'
      @test.start_at ts
      @test.start_at.should == Time.parse(ts)
    end

    it 'should accept Time objects for start_at' do
      ts = Time.now
      @test.start_at ts
      @test.start_at.should == ts
    end

    it 'should allow you to participate an end_at that gets converted to a Time' do
      ts = '2010/07/20 05:00'
      @test.end_at ts
      @test.end_at.should == Time.parse(ts)
    end

    it 'should accept Time objects for end_at' do
      ts = Time.now
      @test.end_at ts
      @test.end_at.should == ts
    end

    it 'should not accept non-string values for start_at' do
      lambda {
        @test.start_at 1
      }.should raise_error(Bucket::Test::InvalidTestConfigurationException)
    end

    it 'should not accept non-string values for end_at' do
      lambda {
        @test.end_at 1
      }.should raise_error(Bucket::Test::InvalidTestConfigurationException)
    end
  end

  describe 'within_range' do
    it 'should return true if start_at blank and end_at blank' do
      @test.within_time_range?.should be_true
    end

    it 'should return true if start_at in past and end_at blank' do
      @test.start_at Time.now - 86400
      @test.within_time_range?.should be_true
    end

    it 'should return false if start_at in future and end_at blank' do
      @test.start_at Time.now + 86400
      @test.within_time_range?.should be_false
    end

    it 'should return false if end_at in past and start_at blank' do
      @test.end_at Time.now - 86400
      @test.within_time_range?.should be_false
    end

    it 'should return true if end_at in future and start_at blank' do
      @test.end_at Time.now + 86400
      @test.within_time_range?.should be_true
    end

    it 'should return true if start_at and end_at set and within boundaries' do
      @test.start_at Time.now - 86400
      @test.end_at Time.now + 86400
      @test.within_time_range?.should be_true
    end

    it 'should return false if start_at and end_at set but outside boundaries' do
      @test.start_at Time.now + 86000
      @test.end_at Time.now + 86400
      @test.within_time_range?.should be_false

      @test.start_at Time.now - 86400
      @test.end_at Time.now - 86000
      @test.within_time_range?.should be_false
    end

    it 'should take a time as an argument' do
      @test.start_at Time.now + 86000
      @test.end_at Time.now + 86400
      @test.within_time_range?.should be_false
      @test.within_time_range?(Time.now + 86200).should be_true
    end
  end

  describe 'active' do
    it 'should return true for normal test' do
      @test.active?.should be_true
    end

    it 'should return false if not within time range' do
      @test.stub!(:within_time_range?).and_return(false)
      @test.active?.should be_false
    end

    it 'should return false if paused' do
      @test.stub!(:paused?).and_return(true)
      @test.active?.should be_false
    end
  end

  describe 'paused' do
    it 'should return false for normal test' do
      @test.paused?.should be_false
    end

    it 'should return true if paused' do
      @test.pause
      @test.paused?.should be_true
      @test.resume
      @test.paused?.should be_false
    end
  end
end
