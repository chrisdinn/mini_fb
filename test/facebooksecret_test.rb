require 'test_helper'

class FacebookSecretTests < Test::Unit::TestCase
  
  def test_value
    secret = MiniFB::FaceBookSecret.new("3")
    assert_equal "3", secret.value.call
  end
  
end