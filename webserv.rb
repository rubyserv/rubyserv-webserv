# Plugin: WebServ
# Author: James Newton <hello@jamesnewton.com>
#
# Description: Provides a JSON web API to the data stored in Channel, Client,
#              Server, and User.
#
# Configuration:
#   webserv:
#     key: some_key
#
#   "key" is the key you will use in the request to "authenticate". Example:
#
#   http://domain.tld/api/users?key=some_key
#
# Gems: json

require 'json'
require 'sinatra/json'

module WebServ
  include RubyServ::Plugin

  configure do |config|
    config.nickname = 'WebServ'
    config.realname = 'WebServ'
    config.username = 'WebServ'
  end

  [:user, :channel, :server, :client].each do |type|
    class_eval <<-RUBY
      web :get, '/api/#{type}s' do |m|
        halt 403 if unauthorized?(params)

        hash = { #{type}s: build_#{type}s_array }

        json hash
      end

      web :get, '/api/#{type}/:name' do |m, name|
        halt 403 if unauthorized?(params)

        hash = { #{type}: build_#{type}(name) }

        json hash
      end
    RUBY
  end

  def unauthorized?(params)
    params['key'] != RubyServ.config.webserv.key.to_s
  end

  # hash generating methods

  def build_user(user)
    user = RubyServ::IRC::User.find_by_nickname(user) unless user.respond_to?(:nickname)

    {
      nickname: user.nickname,
      hostname: user.hostname,
      username: user.username,
      realname: user.realname,
      realhost: user.realhost,
      login:    user.login,
      modes:    user.modes,
      away:     user.away,
      uid:      user.uid,
      sid:      user.sid,
      ts:       user.ts
    }
  end

  def build_users_array(users = nil)
    if users
      users.map { |user| build_user(user) }
    else
      RubyServ::IRC::User.all.map { |user| build_user(user) }
    end
  end

  def build_channel(channel)
    channel = RubyServ::IRC::Channel.find(channel) unless channel.respond_to?(:name)

    {
      modes: channel.modes,
      users: build_users_array(channel.users),
      name:  channel.name,
      sid:   channel.sid,
      ts:    channel.ts
    }
  end

  def build_channels_array
    RubyServ::IRC::Channel.all.map { |channel| build_channel(channel) }
  end

  def build_server(server)
    server = RubyServ::IRC::Server.find_by_name(server) unless server.respond_to?(:name)

    {
      description: server.description,
      name:        server.name,
      sid:         server.sid
    }
  end

  def build_servers_array
    RubyServ::IRC::Server.all.map { |server| build_server(server) }
  end

  def build_client(client)
    client = RubyServ::IRC::Client.find_by_nickname(client) unless client.respond_to?(:nickname)

    {
      nickname: client.nickname,
      hostname: client.hostname,
      username: client.username,
      realname: client.realname,
      modes:    client.modes,
      uid:      client.uid
    }
  end

  def build_clients_array
    RubyServ::IRC::Client.all.map { |client| build_client(client) }
  end
end
