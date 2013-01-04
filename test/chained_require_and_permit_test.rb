require 'test_helper'
require 'action_controller/parameters'

class ChainedRequireAndPermitTest < ActiveSupport::TestCase
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
  
  test "required with one present and one missing" do   
    assert_raises(ActionController::ParameterMissing) do
      @params.strengthen(:foo => :require).strengthen(:something_else => :require)
    end
  end
  
  test "required is present" do
    assert_equal(
      @params,
      @params.strengthen(:foo => :require).strengthen(:things => [:one => :require, :two => :require])
    )
  end
  
  test "part of param not within permitted" do
    assert_equal(
      {'foo' => :bar},
      @params.permit(:foo).permit(:something_else)
    )
  end
  
  test 'when everything present is permitted' do   
    assert_equal(
      @params,
      @params.permit(:foo).permit(:things => [:one, :two])
    )
  end
  
  test 'everything present is within permitted' do
    assert_equal(
      @params,
        @params.permit(:foo).permit(:things => [:one, :two]).permit(:something_else)
      )
  end
  
  test "everything present is permitted or required" do
    assert_equal(
      @params,
      @params.strengthen(:foo => :require).permit(:things => [:one, :two])
    )
  end
  
  test 'everything present is within permitted or is required' do
    assert_equal(
      @params,
      @params.strengthen(:foo => :require).permit(:things => [:one, :two]).permit(:something_else)
    )
  end
    
  test 'everything present is within permitted or is required, but something else is required' do
    assert_raises(ActionController::ParameterMissing) do
      !@params.strengthen(:foo => :require).permit(:things => [:one, :two]).strengthen(:something_else => :require)
    end
  end
  
  test 'require followed by permit on same object' do
    assert_equal(
      {'things' => @params['things']},
      @params.strengthen(:things => :require).permit(:things => [:one, :two])
    )
  end
  
  test 'working with child parameter'  do
    assert_equal(
      @params['things'],
      @params['things'].permit(:one, :two)
    )
  end
end
