require 'test_helper'

class SessionTests < Test::Unit::TestCase
  
  def setup
    @session = MiniFB::Session.new('api_key', 'secret_key', 'session_key', 'uid')
  end
  
  def test_call
    MiniFB.expects(:call).returns("ok") 
    assert_equal "ok", @session.call('method')
  end
  
  def test_photos
    assert @session.photos.kind_of?(MiniFB::Photos)
  end
  
  def test_user    
    user = mock('user')
    MiniFB.stubs(:call).returns("called")
    MiniFB::User.expects(:new).returns(user)
    
    assert_equal user, @session.user
  end
  
end