require 'test_helper'
require 'action_controller/parameters'

class StrengthenTest < ActiveSupport::TestCase
  def setup
    @params = ActionController::Parameters.new(
      {
        :things => {
          :one => 1,
          :two => 2
        }, 
          
        :foo => :bar
      }
    )
  end
  
  test "required not present" do   
    assert_raises(ActionController::ParameterMissing) do
      @params.strengthen(:something_else => :required)
    end
  end
  
  test "require not present" do   
    assert_raises(ActionController::ParameterMissing) do
      @params.strengthen(:something_else => :require)
    end
  end
    
  test "parameters persent that are not in require" do
    assert_equal(
      {'foo' => :bar},
      @params.strengthen(:foo => :require)
    )
  end
    
  test "everything required is present" do
    assert_equal(
      @params,
      @params.strengthen(
        :foo => :require, 
        :things => {:one => :require, :two => :require}
      )
    )
  end
  
  test "no permitted params present" do  
    assert_equal(
      {},
      @params.strengthen(:something_else => :permit)
    )
  end
  
  test 'only some permitted params present' do
    assert_equal(
      {'foo' => :bar},
      @params.strengthen(:foo => :permit)
    )
  end
    
  test 'everything present is permit' do
    assert_equal(
      @params,
      @params.strengthen(
        :foo => :permit, 
        :things => {:one => :permit, :two => :permit}
      )
    )
  end
  
  test 'everything present is permitted' do
    assert_equal(
      @params,
      @params.strengthen(
        :foo => :permitted, 
        :things => {:one => :permitted, :two => :permitted}
      )
    )
  end
  
  test 'everything present is within permitted' do
    assert_equal(
      @params,
      @params.strengthen(
        :foo => :permit, 
        :things => {:one => :permit, :two => :permit},
        :something_else => :permit
      )
    )
  end
  
  test "everything present is permitted or required" do
    assert_equal(
      @params,
      @params.strengthen(
        :foo => :require, 
        :things => {:one => :permit, :two => :permit}
      )
    )
  end
  
  test "everything present is within permitted or is required" do 
    assert_equal(
      @params,
      @params.strengthen(
        :foo => :require, 
        :things => {:one => :permit, :two => :permit},
        :something_else => :permit
      )
    )   
  end
  
  test "something required is missing in mixed require and permit" do   
    assert_raises(ActionController::ParameterMissing) do
      @params.strengthen(
        :foo => :require, 
        :things => {:one => :permit, :two => :permit},
        :something_else => :require
      )
    end
  end
  
  test "child has missing required parameter" do 
    assert_raises(ActionController::ParameterMissing) do
      @params.strengthen(
        :foo => :require, 
        :things => {:one => :permit, :two => :permit, :three => :require},
        :something_else => :permit
      )
   end   
  end

  test "strengthened?" do
    assert !@params.strengthened?, "should not be true as strengthen not called"
    @params.strengthen(:foo => :permit)
    assert @params.strengthened?, "should be true as strengthen has been called"
  end 
  
  test 'original' do
    original_params = @params.clone
    @params.strengthen(:foo => :permit)
    assert_equal(
      original_params,
      @params.original
    )
  end
end
