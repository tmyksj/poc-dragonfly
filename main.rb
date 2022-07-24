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
kv_size = {
  s: 10000,
  m: 10000,
}

# Benchmark results
results = connections.map { |k, _|
  [k, { set: [], get: [], del: [], mset: [], mget: [], mdel: [] }]
}.to_h

# Benchmark (Single Ops)
trials.times do |trial|
  # Key Values
  kvs = Array.new(kv_size[:s], &:itself).shuffle.map { |idx| ["Key #{idx}", "Val #{idx}"] }.to_h

  connections.each do |server, connection|
    # Set
    $stderr.puts(format("[INFO] %d / %d: %9s Set", trial + 1, trials, server))
    results[server][:set] << Benchmark.realtime do
      kvs.each do |key, value|
        connection.set(key, value)
      end
    end

    # Get
    $stderr.puts(format("[INFO] %d / %d: %9s Get", trial + 1, trials, server))
    results[server][:get] << Benchmark.realtime do
      kvs.each do |key, _|
        connection.get(key)
      end
    end

    # Del
    $stderr.puts(format("[INFO] %d / %d: %9s Del", trial + 1, trials, server))
    results[server][:del] << Benchmark.realtime do
      kvs.each do |key, _|
        connection.del(key)
      end
    end
  rescue => e
    $stderr.puts(format("[ERRO] %d / %d: %9s %s", trial + 1, trials, server, e))
  end
end

# Benchmark (Multi Ops)
trials.times do |trial|
  # Key Values
  kvs = Array.new(kv_size[:m], &:itself).shuffle.map { |idx| ["Key #{idx}", "Val #{idx}"] }.to_h

  connections.each do |server, connection|
    # Multi Set
    $stderr.puts(format("[INFO] %d / %d: %9s Multi Set", trial + 1, trials, server))
    results[server][:mset] << Benchmark.realtime do
      connection.mset(*kvs.to_a.flatten)
    end

    # Multi Get
    $stderr.puts(format("[INFO] %d / %d: %9s Multi Get", trial + 1, trials, server))
    results[server][:mget] << Benchmark.realtime do
      connection.mget(*kvs.keys)
    end

    # Multi Del
    $stderr.puts(format("[INFO] %d / %d: %9s Multi Del", trial + 1, trials, server))
    results[server][:mdel] << Benchmark.realtime do
      connection.del(*kvs.keys)
    end
  rescue => e
    $stderr.puts(format("[ERRO] %d / %d: %9s %s", trial + 1, trials, server, e))
  end
end

# Output
results.each do |server, result|
  puts("#{server} #{'-' * 80}"[0..80])

  result.each do |op, reals|
    if reals.empty?
      puts(format("%4s: AVG = , All = []", op))
    else
      puts(format("%4s: AVG = %.6f, All = [#{reals.map { |_| "%.6f" }.join(", ")}]", op, reals.sum / reals.size, *reals))
    end
  end
end
