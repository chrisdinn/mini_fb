require 'test_helper'

class PhotosTests < Test::Unit::TestCase
  
  def test_get_photos
    session = mock('session')
    photos = MiniFB::Photos.new(session)
    
    session.expects(:call).with("photos.get", {"uid" => "3", "pids" => "1,2,3"})
    photos.get({"uid" => "3", "pids" => ["1", "2", "3"]})
  end
  
end