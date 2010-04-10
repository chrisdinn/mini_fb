require 'test_helper'

class SessionTests < Test::Unit::TestCase
  
  def setup
    @secret = mock('secret_key')
    MiniFB::FaceBookSecret.stubs(:new).returns(@secret)
    @session = MiniFB::Session.new('api_key', 'secret_key', 'session_key', 'uid')
  end
  
  def test_call
    MiniFB.expects(:call).with('api_key', @secret, "method", :session_key => 'session_key', :test_custom_param => "test").returns("ok") 
    assert_equal "ok", @session.call('method', :test_custom_param => "test")
  end
  
  def test_photos
    assert @session.photos.kind_of?(MiniFB::Photos)
  end
  
  def test_user    
    user = mock('user')
    MiniFB.expects(:call).with('api_key', @secret, "Users.getInfo", :session_key => 'session_key', :uids => 'uid', :fields => MiniFB::User.all_fields).returns("called")
    MiniFB::User.expects(:new).returns(user)
    
    assert_equal user, @session.user
  end
  
end