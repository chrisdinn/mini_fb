require 'test_helper'

class MiniFBTests < Test::Unit::TestCase

    def setup
       @current_time = Time.now
       Time.stubs(:now).returns(@current_time)
       
       @mock_user_hash = stub(:body => '{"testArray":["212", "646"], "test":"JSON response"}')
       RestClient.stubs(:post).raises(ExpectationNotMetError) # Prevent actual HTTP request 
       
       @secret = MiniFB::FaceBookSecret.new("secret")     
    end

    def test_login_url
      login_url = MiniFB.login_url('api_key', :next => "relative_url_to_next_page", :canvas => true)
      assert_equal "http://api.facebook.com/login.php?api_key=api_key&next=relative_url_to_next_page&canvas", login_url
    end
    
    def test_generate_sig
      secret = MiniFB::FaceBookSecret.new("secret")
      keyword_args_hash = {'kw_arg_1' => 1, 'kw_arg_2' => 2 }
      keyword_args_string = String.new
      keyword_args_hash.sort.each { |kv| keyword_args_string << kv[0] << "=" << kv[1].to_s }
            
      expected_sig = Digest::MD5.hexdigest(keyword_args_string + secret.value.call)
      sig = MiniFB.generate_sig(keyword_args_hash, secret)
      
      assert_equal expected_sig, sig
    end
    
    # Facebook RESTful API call tests

    def test_call_to_api_with_no_keyword_arguments
      expected_default_keyword_args = { 
        'format' => 'JSON' , 
        'v' => MiniFB::FB_API_VERSION, 
        'api_key' => 'test_api_key', 
        'method' => 'method',
        'call_id' => @current_time.tv_sec.to_s
      }
      expected_default_keyword_args['sig'] = MiniFB.generate_sig(expected_default_keyword_args, @secret)
      RestClient.expects(:post).with(MiniFB::FB_URL, expected_default_keyword_args).returns(@mock_user_hash)
      assert_equal JSON.parse(@mock_user_hash.body), MiniFB.call('test_api_key', @secret, 'method')
    end
    
    def test_with_symbol_keyword_arguments
      expected_keyword_args = { 
        'format' => 'JSON' , 
        'v' => MiniFB::FB_API_VERSION, 
        'api_key' => 'test_api_key', 
        'method' => 'method',
        'call_id' => @current_time.tv_sec.to_s,
        
        'custom_keyword_1' => '123'
      }
      expected_keyword_args['sig'] = MiniFB.generate_sig(expected_keyword_args, @secret)
      RestClient.expects(:post).with(MiniFB::FB_URL, expected_keyword_args).returns(@mock_user_hash)
      assert_equal JSON.parse(@mock_user_hash.body), MiniFB.call('test_api_key', @secret, 'method', :custom_keyword_1 => '123')
    end
    
    def test_with_array_keyword_arguments
      expected_keyword_args = { 
        'format' => 'JSON' , 
        'v' => MiniFB::FB_API_VERSION, 
        'api_key' => 'test_api_key', 
        'method' => 'method',
        'call_id' => @current_time.tv_sec.to_s,
        
        'custom_keyword_array' => '[1,2,3]'
      }
      expected_keyword_args['sig'] = MiniFB.generate_sig(expected_keyword_args, @secret)
      RestClient.expects(:post).with(MiniFB::FB_URL, expected_keyword_args).returns(@mock_user_hash)
      assert_equal JSON.parse(@mock_user_hash.body), MiniFB.call('test_api_key', @secret, 'method', :custom_keyword_array => [1,2,3])
    end
    
    def test_photo_upload
      expected_keyword_args = { 
        'format' => 'JSON' , 
        'v' => MiniFB::FB_API_VERSION, 
        'api_key' => 'test_api_key', 
        'method' => 'Photos.upload',
        'call_id' => @current_time.tv_sec.to_s,
      }
      expected_keyword_args['sig'] = MiniFB.generate_sig(expected_keyword_args, @secret)
      expected_keyword_args["file"] = "file_object"
      
      File.expects(:new).with("some_file.jpg").returns("file_object")
          
      RestClient.expects(:post).with(MiniFB::FB_URL, expected_keyword_args).returns(@mock_user_hash)
      assert_equal JSON.parse(@mock_user_hash.body), MiniFB.call('test_api_key', @secret, 'Photos.upload', :file => "some_file.jpg")
    end
            
    def test_bad_api_request_raises_facebook_error
      response = stub(:body => '{"error_msg":"Permissions error", "error_code":200}')
      RestClient.expects(:post).returns(response)
      
      assert_raise MiniFB::FaceBookError do
        MiniFB.call('test_api_key', @secret, 'method', {})
      end
    end
    
    def test_api_call_accepts_secret_as_string_or_facebook_secret
      secret = "secret"
      facebook_secret = MiniFB::FaceBookSecret.new(secret)
      expected_default_keyword_args = { 
        'format' => 'JSON' , 
        'v' => MiniFB::FB_API_VERSION, 
        'api_key' => 'test_api_key', 
        'method' => 'method',
        'call_id' => @current_time.tv_sec.to_s
      }
      expected_default_keyword_args['sig'] = MiniFB.generate_sig(expected_default_keyword_args, facebook_secret)
      RestClient.expects(:post).with(MiniFB::FB_URL, expected_default_keyword_args).returns(@mock_user_hash).twice
      
      assert_equal JSON.parse(@mock_user_hash.body), MiniFB.call('test_api_key', secret, 'method')
      assert_equal JSON.parse(@mock_user_hash.body), MiniFB.call('test_api_key', facebook_secret, 'method')      
    end

    # Facebook signature verification tests
    
    def test_verify_facebook_connect_signature
      test_fb_creds = { 'user' => "1234", 'session_key' => "session_key" }
      test_cookies = {'MINIFBTEST' => MiniFB.generate_sig(test_fb_creds, @secret), 'distraction_cookie' => "gotcha?", 'MINIFBTEST_user' => "1234", 'MINIFBTEST_session_key' => "session_key"}
      
      assert MiniFB.verify_connect_signature('MINIFBTEST', @secret.value.call, test_cookies)
      assert ! MiniFB.verify_connect_signature('MINIFBTEST', "fake-secret", test_cookies)
      assert ! MiniFB.verify_connect_signature('BADAPIKEY', @secret.value.call, test_cookies)
    end

end