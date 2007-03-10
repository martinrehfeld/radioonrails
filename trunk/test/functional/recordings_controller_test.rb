require File.dirname(__FILE__) + '/../test_helper'
require 'recordings_controller'

# Re-raise errors caught by the controller.
class RecordingsController; def rescue_action(e) raise e end; end

class RecordingsControllerTest < Test::Unit::TestCase
  fixtures :stations, :recordings

  def setup
    @controller = RecordingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:recordings)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_recording
    old_count = Recording.count
    post :create, :recording => { :title => 'test_new', :duration => 99, :station => stations(:one) }
    assert_equal old_count+1, Recording.count

    assert_response :success
  end

  def test_should_show_recording
    get :show, :id => 1
    assert_response :success
  end

  def test_should_update_recording
    put :update, :id => 1, :recording => { :title => 'test_update' }
    assert_response :success
  end
  
  def test_should_destroy_recording
    old_count = Recording.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Recording.count
    
    assert_response :success
  end
end
