require 'digest/md5'
require 'erb'
require 'json' unless defined? JSON
require 'rest_client'

module MiniFB

    # Global constants
    FB_URL = "http://api.facebook.com/restserver.php"
    FB_API_VERSION = "1.0"

    @@logging = false

    def self.enable_logging
        @@logging = true
    end

    def self.disable_logging
        @@logging = false
    end

    class FaceBookError < StandardError
        attr_accessor :code
        # Error that happens during a facebook call.
        def initialize( error_code, error_msg )
            @code = error_code
            super("Facebook error #{error_code}: #{error_msg}" )
        end
    end

    class Session
        attr_accessor :api_key, :secret_key, :session_key, :uid

        def initialize(api_key, secret_key, session_key, uid)
            @api_key = api_key
            @secret_key = FaceBookSecret.new secret_key
            @session_key = session_key
            @uid = uid
        end

        # returns current user
        def user
            return @user unless @user.nil?
            @user = User.new(MiniFB.call(@api_key, @secret_key, "Users.getInfo", "session_key"=>@session_key, "uids"=>@uid, "fields"=>User.all_fields)[0], self)
            @user
        end

        def photos
            Photos.new(self)
        end

        def call(method, params={})
            return MiniFB.call(api_key, secret_key, method, params.update("session_key"=>session_key))
        end
    end

    class User
        FIELDS = [:uid, :status, :political, :pic_small, :name, :quotes, :is_app_user, :tv, :profile_update_time, :meeting_sex, :hs_info, :timezone, :relationship_status, :hometown_location, :about_me, :wall_count, :significant_other_id, :pic_big, :music, :work_history, :sex, :religion, :notes_count, :activities, :pic_square, :movies, :has_added_app, :education_history, :birthday, :birthday_date, :first_name, :meeting_for, :last_name, :interests, :current_location, :pic, :books, :affiliations, :locale, :profile_url, :proxied_email, :email, :email_hashes, :allowed_restrictions, :pic_with_logo, :pic_big_with_logo, :pic_small_with_logo, :pic_square_with_logo]
        STANDARD_FIELDS = [:uid, :first_name, :last_name, :name, :timezone, :birthday, :sex, :affiliations, :locale, :profile_url, :proxied_email, :email]

        def self.all_fields
            FIELDS.join(",")
        end

        def self.standard_fields
            STANDARD_FIELDS.join(",")
        end

        def initialize(fb_hash, session)
            @fb_hash = fb_hash
            @session = session
        end

        def [](key)
            @fb_hash[key]
        end

        def uid
            return self["uid"]
        end

        def profile_photos
            @session.photos.get("uid"=>uid, "aid"=>profile_pic_album_id)
        end

        def profile_pic_album_id
            merge_aid(-3, uid)
        end

        def merge_aid(aid, uid)
            uid = uid.to_i
            ret = (uid << 32) + (aid & 0xFFFFFFFF)
#            puts 'merge_aid=' + ret.inspect
            return ret
        end
    end

    class Photos

        def initialize(session)
            @session = session
        end

        def get(params)
            pids = params["pids"]
            if !pids.nil? && pids.is_a?(Array)
                pids = pids.join(",")
                params["pids"] = pids
            end
            @session.call("photos.get", params)
        end
    end

    BAD_JSON_METHODS = ["users.getloggedinuser", "auth.promotesession", "users.hasapppermission",
                        "Auth.revokeExtendedPermission", "pages.isAdmin", "pages.isFan"].collect { |x| x.downcase }

    # Call facebook server with a method request. Most keyword arguments
    # are passed directly to the server with a few exceptions.
    # The 'sig' value will always be computed automatically.
    # The 'v' version will be supplied automatically if needed.

    # If an error occurs, a FacebookError exception will be raised
    # with the proper code and message.

    # The secret argument must be an instance of FacebookSecret
    # to hide value from simple introspection.
    def MiniFB.call( api_key, secret, method, kwargs={} )
      raise ArgumentError, "secret must be a FaceBookSecret" unless secret.kind_of?(FaceBookSecret)
      
      default_keyword_args = { 'format' => 'JSON', 'v' => FB_API_VERSION, 'api_key' => api_key, 'method' => method, 'call_id' => Time.now.tv_sec.to_s }
      keyword_args = default_keyword_args.merge(kwargs)
      
      filename = keyword_args.delete("filename") # Remove filename before signature is generated
      
      keyword_args['sig'] = MiniFB.generate_sig(keyword_args, secret)
    
      if keyword_args["method"].downcase=="photos.upload" && filename
        response = RestClient.post FB_URL, keyword_args.merge("file" => File.new(filename))
      else
        response = RestClient.post FB_URL, keyword_args
      end
      
      data = JSON.parse(response.body)
      raise FaceBookError.new( data["error_code"] || 1, data["error_msg"] ) if data.include?( "error_msg" )
      data
    end

    # Returns true is signature is valid, false otherwise.
    def MiniFB.verify_signature( secret, arguments )
        signature = arguments.delete( "fb_sig" )
        return false if signature.nil?

        unsigned = Hash.new
        signed = Hash.new

        arguments.each do |k, v|
            if k =~ /^fb_sig_(.*)/ then
                signed[$1] = v
            else
                unsigned[k] = v
            end
        end

        arg_string = String.new
        signed.sort.each { |kv| arg_string << kv[0] << "=" << kv[1] }
        if Digest::MD5.hexdigest( arg_string + secret ) == signature
            return true
        end
        return false
    end
    
    # Validates that the cookies sent by the user are those that were set by facebook. Since your
    # secret is only known by you and facebook it is used to sign all of the cookies set.
    #
    # options:
    # * api_key - the connect applications facebook API key
    # * secret - the connect application secret
    # * cookies - the cookies given by facebook - it is ok to just pass all of the cookies, the method will do the filtering for you.
    def MiniFB.verify_connect_signature(api_key, secret, cookies)
      signature = cookies[api_key]
      return false if signature.nil?

      unsigned = Hash.new
      signed = Hash.new

      cookies.each do |k, v|
        if k =~ /^#{api_key}_(.*)/ then
          signed[$1] = v
        else
          unsigned[k] = v
        end
      end

      arg_string = String.new
      signed.sort.each {|kv| arg_string << kv[0] << "=" << kv[1] }
      if Digest::MD5.hexdigest(arg_string + secret) == signature
        return true
      end
      return false
    end

    # Returns the login/add app url for your application.
    #
    # options:
    #    - :next => a relative next page to go to. relative to your facebook connect url or if :canvas is true, then relative to facebook app url
    #    - :canvas => true/false - to say whether this is a canvas app or not
    def self.login_url(api_key, options={})
        login_url = "http://api.facebook.com/login.php?api_key=#{api_key}"
        login_url << "&next=#{options[:next]}" if options[:next]
        login_url << "&canvas" if options[:canvas]
        login_url
    end

    # This function expects arguments as a hash, so
    # it is agnostic to different POST handling variants in ruby.
    #
    # Validate the arguments received from facebook. This is usually
    # sent for the iframe in Facebook's canvas. It is not necessary
    # to use this on the auth_token and uid passed to callbacks like
    # post-add and post-remove.
#
    # The arguments must be a mapping of to string keys and values
    # or a string of http request data.
#
    # If the data is invalid or not signed properly, an empty
    # dictionary is returned.
#
    # The secret argument should be an instance of FacebookSecret
    # to hide value from simple introspection.
#
    # DEPRECATED, use verify_signature instead
    def MiniFB.validate( secret, arguments )

        signature = arguments.delete( "fb_sig" )
        return arguments if signature.nil?

        unsigned = Hash.new
        signed = Hash.new

        arguments.each do |k, v|
            if k =~ /^fb_sig_(.*)/ then
                signed[$1] = v
            else
                unsigned[k] = v
            end
        end

        arg_string = String.new
        signed.sort.each { |kv| arg_string << kv[0] << "=" << kv[1] }
        if Digest::MD5.hexdigest( arg_string + secret ) != signature
            unsigned # Hash is incorrect, return only unsigned fields.
        else
            unsigned.merge signed
        end
    end

    class FaceBookSecret
        # Simple container that stores a secret value.
        # Proc cannot be dumped or introspected by normal tools.
        attr_reader :value

        def initialize( value )
            @value = Proc.new { value }
        end
    end
    
    def self.generate_sig(keyword_args_hash, secret)
      arg_string = String.new
      # todo: convert symbols to strings, symbols break the next line
      keyword_args_hash.sort.each { |kv| arg_string << kv[0].to_s << "=" << kv[1].to_s }
      Digest::MD5.hexdigest( arg_string + secret.value.call )
    end

end
