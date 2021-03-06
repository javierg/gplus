require 'oauth2'

# gplus: A complete implementation of the Google+ API for Ruby
# @see https://developers.google.com/+/api/ The official Google+ API documentation
module Gplus
  autoload :Version, 'gplus/version'
  autoload :Client, 'gplus/client'
  autoload :Activity, 'gplus/activity'
  autoload :Comment, 'gplus/comment'
  autoload :Person, 'gplus/person'
end
