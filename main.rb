require "rubygems"
require "bundler"

Bundler.require(:default)

redis = Redis.new(host: "127.0.0.1", port: 6379)
puts(redis.set("mykey", "hello world"))
puts(redis.get("mykey"))

dragonfly = Redis.new(host: "127.0.0.1", port: 6380)
puts(dragonfly.set("mykey", "hello world"))
puts(dragonfly.get("mykey"))
