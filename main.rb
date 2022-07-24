require "rubygems"
require "benchmark"
require "bundler"

Bundler.require(:default)

# Connections
connections = {
  redis: Redis.new(host: "127.0.0.1", port: 6379),
  dragonfly: Redis.new(host: "127.0.0.1", port: 6380),
}

# Benchmark properties
trials = 3
kv_size = 10000

# Benchmark results
results = connections.map { |k, _|
  [k, { set: [], get: [], del: [] }]
}.to_h

# Benchmark
trials.times do
  # Key Values
  kvs = Array.new(kv_size, &:itself).shuffle.map { |idx| ["Key #{idx}", "Val #{idx}"] }.to_h

  # Set
  connections.each do |server, connection|
    results[server][:set] << Benchmark.realtime do
      kvs.each do |key, value|
        connection.set(key, value)
      end
    end
  end

  # Get
  connections.each do |server, connection|
    results[server][:get] << Benchmark.realtime do
      kvs.each do |key, _|
        connection.get(key)
      end
    end
  end

  # Del
  connections.each do |server, connection|
    results[server][:del] << Benchmark.realtime do
      kvs.each do |key, _|
        connection.del(key)
      end
    end
  end
end

# Output
results.each do |server, result|
  puts "#{server} #{'-' * 80}"[0..80]

  result.each do |op, reals|
    puts(format("%s: AVG = %.6f, All = [#{reals.map { |_| "%.6f" }.join(", ")}]", op, reals.sum / reals.size, *reals))
  end
end
