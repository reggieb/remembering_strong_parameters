require 'test_helper'
require 'action_controller/parameters'


class HashFromTest < ActiveSupport::TestCase
  
  def setup
    @params = ActionController::Parameters.new
    @text = 'foo'
  end
  
  test "single level array to hash" do
    array = [:a, :b, :c]
    hash = {:a => @text, :b => @text, :c => @text}
    assert_equal(hash, @params.send(:hash_from, array, @text))
  end
  
  test 'multi-level array to hash' do
    array = [:a, {:b => [:c, :d]}, :e]
    hash = {:a => @text, :b => {:c => @text, :d => @text}, :e => @text}
    assert_equal(hash, @params.send(:hash_from, array, @text))
  end
  
  
end
