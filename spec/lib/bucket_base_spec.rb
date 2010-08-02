require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'tempfile'

describe Bucket::Base do
  describe 'cookie_names' do
    it 'should return the name of a cookie if exists' do
      Bucket.cookie_name(:participant).should == 'bucket_participant'
    end

    it 'should return nil if not exists' do
      Bucket.cookie_name(:none).should be_nil
    end
  end

  describe 'escape_javascript' do
    it 'should return valid escaped javascript' do
      js =<<-EOF
var x = 'test1';
var y = "test2";
      EOF
      Bucket.escape_javascript(js).should == "var x = \\'test1\\';\\nvar y = \\\"test2\\\";\\n"
    end
  end
end
