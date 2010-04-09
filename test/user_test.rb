require 'test_helper'

class UserTests < Test::Unit::TestCase
  
  def setup
    facebook_user_info_hash = {'uid' => '333', 'fb_one' => "1", 'fb_two' => "2"}
    @user = MiniFB::User.new(facebook_user_info_hash, @session = MiniFB::Session.new('api_key', 'secret_key', 'session_key', 'uid'))
  end
  
  def test_all_fields
    assert_equal MiniFB::User.all_fields, MiniFB::User::FIELDS.join(",")
  end
  
  def test_standard_fields
    assert_equal MiniFB::User.standard_fields, MiniFB::User::STANDARD_FIELDS.join(",")
  end
  
  def test_facebook_user_info_hash
    assert_equal "1", @user['fb_one']
    assert_equal "2", @user['fb_two']
  end
  
  def test_uid
    assert_equal '333', @user.uid
  end
  
  def test_profile_photos
    photos = mock('photos')
    MiniFB::Photos.expects(:new).returns(photos)
    photos.expects(:get).with("uid"=>@user.uid, "aid"=>@user.profile_pic_album_id)
    @user.profile_photos
  end
  
  def test_profile_pic_album_id
    epected_profile_pic_album_id = (@user.uid.to_i << 32) + ((-3) & 0xFFFFFFFF)
    assert_equal epected_profile_pic_album_id, @user.profile_pic_album_id
  end
  
end