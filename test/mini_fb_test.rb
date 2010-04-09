require 'test_helper'

class MiniFBTests < Test::Unit::TestCase

    def test_login_url
      login_url = MiniFB.login_url('api_key', :next => "relative_url_to_next_page", :canvas => true)
      assert_equal "http://api.facebook.com/login.php?api_key=api_key&next=relative_url_to_next_page&canvas", login_url
    end

end