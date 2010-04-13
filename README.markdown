MiniFB - the simple miniature facebook library
==============================================

MiniFB is a lightweight Ruby library for interacting with the [Facebook RESTful API][].

Installation
-------------

Be sure you have rubygems.org as gem source, then: 

    gem install mini_fb


General Usage
-------------

The most general case is to use `MiniFB.call` to make a [Facebook RESTful API][] call:

    user_hash = MiniFB.call(FB_API_KEY, FB_SECRET, "Users.getInfo", :uids =>@uid, :fields => ['first_name', 'last_name'])

MiniFB.call returns a Ruby-friendly version of the API response. Most commonly, that'll be a Hash (the JSON response
from the API, parsed), but it could also be an array (e.g. an array of user info hashes), a boolean value (some methods simply return 
"true"), an integer (e.g. a user id or a 1/0 representing true/false), or a string (e.g. a new session key with extended permissions).


Some Higher Level Objects for Common Uses
----------------------

Get a MiniFB::Session:

    @fb = MiniFB::Session.new(FB_API_KEY, FB_SECRET, @fb_session, @fb_uid)

Then it makes it a bit easier to use call for a particular user/session.

    response = @fb.call("stream.get")

With the session, you can then get the user information for the session/uid.

	user_id = @fb.user_id # just returns session's user id, no API call
    user = @fb.user # Calls API for all info about this session's user and makes it available as a MiniFB::User

Then get info from the User object:

    first_name = user["first_name"]

Or profile photos:

    photos = user.profile_photos

Or if you want other photos, try:

    photos = @fb.photos("pids"=>[12343243,920382343,9208348])

Facebook Connect
----------------

This is actually very easy, first follow these instructions: http://wiki.developers.facebook.com/index.php/Connect/Setting_Up_Your_Site

Then add the following script to the page where you put the login button so it looks like this:

    <script>
        function facebook_onlogin(){
            document.location.href = "<%= url_for :action=>"fb_connect" %>";
        }
    </script>
    <fb:login-button onlogin="facebook_onlogin();"></fb:login-button>

Define an fb_connect method in your login/sessions controller like so:

     def fb_connect
        @fb_uid = cookies[FB_API_KEY + "_user"]
        @fb_session = cookies[FB_API_KEY + "_session_key"]
        puts "uid=#{@fb_uid}"
        puts "session=#{@fb_session}"
        
        if MiniFB.verify_connect_signature(FB_API_KEY, FB_SECRET, cookies)
          # And here you would create the user if it doesn't already exist, then redirect them to wherever you want.
        else
          # The cookies may have been modified as the signature does not match
        end

    end


Uploads
-------

Uploading a photo is easy:

    @fb.call("Photos.upload", :file => "<full path to file>")

Same with uploading a video:

    @fb.call("Video.upload", :file => "<full path to video>")

The `:file` parameter will be used as the file data.

Tests
-----

MiniFB has complete test coverage. To run tests, install [Bundler](http://gembundler.com/), from the project directory 
run `bundle install`, then `rake tests`


Support
--------

Join our Discussion Group at: http://groups.google.com/group/mini_fb

[Facebook RESTful API]: http://wiki.developers.facebook.com/index.php/API