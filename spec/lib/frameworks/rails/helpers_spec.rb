require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')
require File.join(File.dirname(__FILE__), 'rails_spec_helper')
require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'bucket', 'frameworks', 'rails', 'helpers')

def escape_javascript(value)
  value
end

def javascript_tag(value)
  return <<-EOF
<script type="text/javascript">
  //<![CDATA[
    #{value}
  //]]>
</script>
  EOF
end

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

  describe 'bucket_include_javascript' do
    it 'should call javascript_include_tag' do
      self.should_receive(:javascript_include_tag).with(:bucket).and_return(nil)
      bucket_include_javascript
    end
  end

  describe 'bucket_initialize_inner' do
    it 'should initialize the recorder with the supplied key' do
      bucket_initialize_inner('abcdef').should == "Bucket.recorder.initialize({\n  key: 'abcdef'\n});"
    end

    it 'should include supplied options in the initialization object' do
      bucket_initialize_inner('abcdef', 
        {'foo' => 'bar'}
      ).should == "Bucket.recorder.initialize({\n  foo: 'bar'\n  key: 'abcdef'\n});"
    end
  end

  describe 'bucket_initialize_javascript' do
    it 'should initialize recorder with supplied key within javascript tag' do
      bucket_initialize_javascript('abcdef').should == "<script type=\"text/javascript\">\n  //<![CDATA[\n    Bucket.recorder.initialize({\n  key: 'abcdef'\n});\n  //]]>\n</script>\n"
    end

    it 'should initialize recorder with supplied key and options within javascript tag' do
      bucket_initialize_javascript('abcdef', {'foo' => 'bar'}).should == "<script type=\"text/javascript\">\n  //<![CDATA[\n    Bucket.recorder.initialize({\n  foo: 'bar'\n  key: 'abcdef'\n});\n  //]]>\n</script>\n"
    end
  end
end
