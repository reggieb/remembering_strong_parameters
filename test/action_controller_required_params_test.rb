require 'test_helper'

class BooksController < ActionController::Base
  def create
    params.require(:book).require(:name)
    head :ok
  end
  
  def create_with_chained_require
    params.strengthen(:hat => :require).strengthen(:book => {:name => :require})
    head :ok
  end
end

class ActionControllerRequiredParamsTest < ActionController::TestCase
  tests BooksController

  test "missing required parameters will raise exception" do
    post :create, { :magazine => { :name => "Mjallo!" } }
    assert_response :bad_request
  end
  
  test "missing second lavel required parameters will raise exception" do
    post :create, { :book => { :title => "Mjallo!" } }
    assert_response :bad_request
  end
  
  test "missing required parameters will raise exception when require chained" do
    post :create_with_chained_require, { :magazine => { :name => "Mjallo!" }, :hat => 'bowler' }
    assert_response :bad_request

    post :create_with_chained_require, { :book => { :title => "Mjallo!" }, :hat => 'bowler' }
    assert_response :bad_request
    
    post :create_with_chained_require, { :book => { :name => "Mjallo!" } }
    assert_response :bad_request
  end

  test "required parameters that are present will not raise" do
    post :create, { :book => { :name => "Mjallo!" } }
    assert_response :ok
    
    post :create_with_chained_require, { :book => { :name => "Mjallo!" }, :hat => 'bowler' }
    assert_response :ok
  end

  test "missing parameters will be mentioned in the return" do
    post :create, { :magazine => { :name => "Mjallo!" } }
    assert_match "Required parameter missing: 'book'", response.body
  end
  
end
