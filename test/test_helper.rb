require 'test/unit'
require "rubygems"
require "bundler"

Bundler.setup(:default, :test)
Bundler.require(:default, :test)

require 'mini_fb'

class ExpectationNotMetError < StandardError; end