require File.dirname(__FILE__) + '/../test_helper'
require 'stations_controller'

# Re-raise errors caught by the controller.
class StationsController; def rescue_action(e) raise e end; end

class StationsControllerTest < Test::Unit::TestCase
  fixtures :stations

  def setup
    @controller = StationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:stations)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_station
    old_count = Station.count
    post :create, :station => { :name => 'new', :stream_url => 'proto://some.server' }
    assert_equal old_count+1, Station.count
    
    assert_redirected_to stations_path
  end

  def test_should_show_station
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_station
    put :update, :id => 1, :station => { :name => 'updated', :stream_url => 'proto://some.server' }
    assert_redirected_to stations_path
  end
  
  def test_should_destroy_station
    old_count = Station.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Station.count
    
    assert_redirected_to stations_path
  end
end
