require 'test_helper'
require 'action_controller/parameters'


class StrongArrayTest < ActiveSupport::TestCase

  def setup
    @params = ActionController::StrongArray.new([
      ActionController::Parameters.new({
        :name => "William Shakespeare",
        :born => "1564-04-26"
      }), 
      ActionController::Parameters.new({
        :name => "Christopher Marlowe"
      })
    ])
  end

  test 'permit' do
    permitted = @params.strengthen(:name => :permit, :born => :permit)
    assert_not_equal [], permitted
    permitted.each_with_index do |item, index|
      assert_equal(item.keys, @params[index].keys)
      assert_equal(item.values, @params[index].values)
    end
  end

  test 'require' do
    permitted = @params.strengthen(:name => :require, :born => :permit)
    assert_not_equal [], permitted
    permitted.each_with_index do |item, index|
      assert_equal(item.keys, @params[index].keys)
      assert_equal(item.values, @params[index].values)
    end  
  end

  test 'require with parameter missing' do
    assert_raise(ActionController::ParameterMissing) do
      @params.strengthen(:name => :require, :born => :require)
    end
  end

  test 'permit with parameter missing' do
    assert_equal(
      [{'name' => "William Shakespeare"}, {'name' => "Christopher Marlowe"}],
      @params.strengthen(:name => :permit)
    )
  end
end
