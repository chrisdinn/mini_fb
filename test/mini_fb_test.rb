require 'test_helper'

class MiniFBTests < Test::Unit::TestCase

    def setup
       @current_time = Time.now
       Time.stubs(:now).returns(@current_time)
       RestClient.stubs(:post).returns("stubbed_post_form")
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

    def test_call_to_facebook_restful_api
      expected_keyword_args = { 
        'format' => 'JSON' , 
        'v' => MiniFB::FB_API_VERSION, 
        'api_key' => 'test_api_key', 
        'method' => 'method',
        'call_id' => @current_time.tv_sec.to_s
      }
      expected_keyword_args['sig'] = MiniFB.generate_sig(expected_keyword_args, @secret)
      
      stubbed_json_api_response = '{ "firstName": "John", "lastName": "Smith", "male": true, "phoneNumbers": ["212-555-1234","646-555-4567"]}'
      response = RestClient::Response.new(stubbed_json_api_response, nil, nil)
      RestClient.expects(:post).with(MiniFB::FB_URL, expected_keyword_args).returns(response)
      
      assert_equal JSON.parse(response.body), MiniFB.call('test_api_key', @secret, 'method', {})
    end
    
    def test_facebook_api_photo_upload
      expected_keyword_args = { 
        'format' => 'JSON' , 
        'v' => MiniFB::FB_API_VERSION, 
        'api_key' => 'test_api_key', 
        'method' => 'photos.upload',
        'call_id' => @current_time.tv_sec.to_s,
      }
      expected_keyword_args['sig'] = MiniFB.generate_sig(expected_keyword_args, @secret)
      expected_keyword_args["file"] = "file_object"
      
      File.stubs(:new).returns("file_object")    
      stubbed_json_api_response = '{"pid": "940915697041656", "aid": "940915667462717", "owner": "219074", "src": "http://ip002.facebook.com/v67/161/72/219074/s219074_31637752_5455.jpg"}'
      response = RestClient::Response.new(stubbed_json_api_response, nil, nil)
      RestClient.expects(:post).with(MiniFB::FB_URL, expected_keyword_args).returns(response)
      
      assert_equal JSON.parse(response.body), MiniFB.call('test_api_key', @secret, 'photos.upload', {'filename' => "some_file.jpg"})
    end
        
    def test_bad_api_request_raises_facebook_error
      mock_request = stub(:body => 'request_body')
      RestClient.expects(:post).returns(mock_request)
      JSON.expects(:parse).with('request_body').returns({"error_msg"=>"Permissions error", "error_code"=>200})
      
      assert_raise MiniFB::FaceBookError do
        MiniFB.call('test_api_key', @secret, 'method', {})
      end
    end
    
    def test_api_call_requires_facebook_secret
      stubbed_json_api_response = '{ "firstName": "John", "lastName": "Smith", "male": true, "phoneNumbers": ["212-555-1234","646-555-4567"]}'
      response = RestClient::Response.new(stubbed_json_api_response, nil, nil)
      RestClient.expects(:post).returns(response)
      
      assert_raise ArgumentError do
        MiniFB.call('apikey', 'secret', 'method', {})
      end
      assert_nothing_raised do
        MiniFB.call('apikey', MiniFB::FaceBookSecret.new('secret'), 'method', {})
      end
    end

    # Facebook signature verification tests
    
    def test_verify_facebook_connect_signature
      test_fb_creds = { 'user' => "1234", 'session_key' => "session_key" }
      test_cookies = {'MINIFBTEST' => MiniFB.generate_sig(test_fb_creds, @secret), 'disctraction_cookie' => "gotcha?", 'MINIFBTEST_user' => "1234", 'MINIFBTEST_session_key' => "session_key"}
      
      assert MiniFB.verify_connect_signature('MINIFBTEST', @secret.value.call, test_cookies)
      assert ! MiniFB.verify_connect_signature('MINIFBTEST', "fake-secret", test_cookies)
      assert ! MiniFB.verify_connect_signature('BADAPIKEY', "fake-secret", test_cookies)
    end
end