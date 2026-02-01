#!/usr/bin/env ruby
# frozen_string_literal: true

# Performance comparison between s3-rb and aws-sdk-s3
#
# Usage:
#   bundle exec ruby test/performance/benchmark.rb
#
# Environment variables:
#   S3_ACCESS_KEY_ID     - AWS access key
#   S3_SECRET_ACCESS_KEY - AWS secret key
#   S3_REGION            - AWS region (default: us-east-1)
#   S3_BUCKET            - Bucket to use for tests
#   ITERATIONS           - Number of iterations per test (default: 10)

require 'bundler/setup'
require_relative '../../lib/s3'
require 'aws-sdk-s3'
require 'securerandom'

class PerformanceBenchmark
  SMALL_SIZE = 1_024          # 1 KB
  MEDIUM_SIZE = 100_000       # 100 KB
  LARGE_SIZE = 5_000_000      # 5 MB

  def initialize
    @access_key_id = ENV.fetch( 'S3_ACCESS_KEY_ID' )
    @secret_access_key = ENV.fetch( 'S3_SECRET_ACCESS_KEY' )
    @region = ENV.fetch( 'S3_REGION', 'us-east-1' )
    @bucket = ENV.fetch( 'S3_BUCKET' )
    @iterations = ENV.fetch( 'ITERATIONS', '10' ).to_i

    setup_clients
    generate_payloads
  end

  def run
    puts "Performance Benchmark: s3-rb vs aws-sdk-s3"
    puts "=" * 60
    puts "Region: #{ @region }"
    puts "Bucket: #{ @bucket }"
    puts "Iterations: #{ @iterations }"
    puts

    results = []

    results << benchmark_write( 'Small (1 KB)', @small_payload )
    results << benchmark_write( 'Medium (100 KB)', @medium_payload )
    results << benchmark_write( 'Large (5 MB)', @large_payload )

    results << benchmark_read( 'Small (1 KB)', @small_payload )
    results << benchmark_read( 'Medium (100 KB)', @medium_payload )
    results << benchmark_read( 'Large (5 MB)', @large_payload )

    results << benchmark_mixed

    print_results( results )
    cleanup
  end

  private

  def setup_clients
    @s3rb = S3::Service.new(
      access_key_id: @access_key_id,
      secret_access_key: @secret_access_key,
      region: @region,
      connection_pool: 5
    )

    @aws = Aws::S3::Client.new(
      access_key_id: @access_key_id,
      secret_access_key: @secret_access_key,
      region: @region,
      ssl_verify_peer: false
    )
  end

  def generate_payloads
    @small_payload = SecureRandom.random_bytes( SMALL_SIZE )
    @medium_payload = SecureRandom.random_bytes( MEDIUM_SIZE )
    @large_payload = SecureRandom.random_bytes( LARGE_SIZE )
  end

  def benchmark_write( label, payload )
    key_prefix = "perf-test/#{ SecureRandom.hex( 8 ) }"
    @test_keys ||= []

    # Warmup
    warmup_key = "#{ key_prefix }/warmup"
    @s3rb.object_put( bucket: @bucket, key: warmup_key, body: payload )
    @aws.put_object( bucket: @bucket, key: warmup_key, body: payload )
    @test_keys << warmup_key

    # s3-rb benchmark
    s3rb_times = []
    @iterations.times do | i |
      key = "#{ key_prefix }/s3rb-#{ i }"
      @test_keys << key
      start = Process.clock_gettime( Process::CLOCK_MONOTONIC )
      @s3rb.object_put( bucket: @bucket, key: key, body: payload )
      s3rb_times << Process.clock_gettime( Process::CLOCK_MONOTONIC ) - start
    end

    # aws-sdk-s3 benchmark
    aws_times = []
    @iterations.times do | i |
      key = "#{ key_prefix }/aws-#{ i }"
      @test_keys << key
      start = Process.clock_gettime( Process::CLOCK_MONOTONIC )
      @aws.put_object( bucket: @bucket, key: key, body: payload )
      aws_times << Process.clock_gettime( Process::CLOCK_MONOTONIC ) - start
    end

    {
      operation: "Write #{ label }",
      s3rb_avg: average( s3rb_times ),
      s3rb_min: s3rb_times.min,
      s3rb_max: s3rb_times.max,
      aws_avg: average( aws_times ),
      aws_min: aws_times.min,
      aws_max: aws_times.max
    }
  end

  def benchmark_read( label, payload )
    key = "perf-test/#{ SecureRandom.hex( 8 ) }/read-test"
    @test_keys ||= []
    @test_keys << key

    # Upload test object
    @s3rb.object_put( bucket: @bucket, key: key, body: payload )

    # Warmup
    @s3rb.object_get( bucket: @bucket, key: key )
    @aws.get_object( bucket: @bucket, key: key ).body.read

    # s3-rb benchmark
    s3rb_times = []
    @iterations.times do
      start = Process.clock_gettime( Process::CLOCK_MONOTONIC )
      @s3rb.object_get( bucket: @bucket, key: key )
      s3rb_times << Process.clock_gettime( Process::CLOCK_MONOTONIC ) - start
    end

    # aws-sdk-s3 benchmark
    aws_times = []
    @iterations.times do
      start = Process.clock_gettime( Process::CLOCK_MONOTONIC )
      @aws.get_object( bucket: @bucket, key: key ).body.read
      aws_times << Process.clock_gettime( Process::CLOCK_MONOTONIC ) - start
    end

    {
      operation: "Read #{ label }",
      s3rb_avg: average( s3rb_times ),
      s3rb_min: s3rb_times.min,
      s3rb_max: s3rb_times.max,
      aws_avg: average( aws_times ),
      aws_min: aws_times.min,
      aws_max: aws_times.max
    }
  end

  def benchmark_mixed
    key_prefix = "perf-test/#{ SecureRandom.hex( 8 ) }/mixed"
    @test_keys ||= []
    payloads = [ @small_payload, @medium_payload, @large_payload ]

    # s3-rb benchmark
    s3rb_times = []
    @iterations.times do | i |
      payload = payloads[ i % 3 ]
      key = "#{ key_prefix }/s3rb-#{ i }"
      @test_keys << key

      start = Process.clock_gettime( Process::CLOCK_MONOTONIC )
      @s3rb.object_put( bucket: @bucket, key: key, body: payload )
      @s3rb.object_get( bucket: @bucket, key: key )
      s3rb_times << Process.clock_gettime( Process::CLOCK_MONOTONIC ) - start
    end

    # aws-sdk-s3 benchmark
    aws_times = []
    @iterations.times do | i |
      payload = payloads[ i % 3 ]
      key = "#{ key_prefix }/aws-#{ i }"
      @test_keys << key

      start = Process.clock_gettime( Process::CLOCK_MONOTONIC )
      @aws.put_object( bucket: @bucket, key: key, body: payload )
      @aws.get_object( bucket: @bucket, key: key ).body.read
      aws_times << Process.clock_gettime( Process::CLOCK_MONOTONIC ) - start
    end

    {
      operation: "Mixed (write+read)",
      s3rb_avg: average( s3rb_times ),
      s3rb_min: s3rb_times.min,
      s3rb_max: s3rb_times.max,
      aws_avg: average( aws_times ),
      aws_min: aws_times.min,
      aws_max: aws_times.max
    }
  end

  def average( times )
    times.sum / times.size.to_f
  end

  def print_results( results )
    puts
    puts "Results"
    puts "=" * 100

    # Header
    puts format(
      "%-25s %12s %12s %12s %12s %12s",
      "Operation", "s3-rb avg", "aws-sdk avg", "Difference", "s3-rb range", "aws-sdk range"
    )
    puts "-" * 100

    results.each do | r |
      diff = r[ :aws_avg ] - r[ :s3rb_avg ]
      diff_pct = ( diff / r[ :aws_avg ] * 100 ).round( 1 )
      diff_str = if diff > 0
                   "+#{ format_ms( diff ) } (#{ diff_pct }% faster)"
                 else
                   "#{ format_ms( diff ) } (#{ diff_pct.abs }% slower)"
                 end

      puts format(
        "%-25s %12s %12s %18s %12s %12s",
        r[ :operation ],
        format_ms( r[ :s3rb_avg ] ),
        format_ms( r[ :aws_avg ] ),
        diff_str,
        "#{ format_ms( r[ :s3rb_min ] ) }-#{ format_ms( r[ :s3rb_max ] ) }",
        "#{ format_ms( r[ :aws_min ] ) }-#{ format_ms( r[ :aws_max ] ) }"
      )
    end

    puts
  end

  def format_ms( seconds )
    "#{ ( seconds * 1000 ).round( 1 ) }ms"
  end

  def cleanup
    return if @test_keys.nil? || @test_keys.empty?

    puts "Cleaning up #{ @test_keys.size } test objects..."
    @test_keys.each_slice( 1000 ) do | batch |
      @s3rb.object_delete_batch( bucket: @bucket, keys: batch )
    end
    puts "Done."
  end
end

# Check required environment variables
%w[ S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_BUCKET ].each do | var |
  unless ENV[ var ]
    puts "Error: #{ var } environment variable is required"
    puts
    puts "Usage:"
    puts "  S3_ACCESS_KEY_ID=... S3_SECRET_ACCESS_KEY=... S3_BUCKET=... ruby test/performance/benchmark.rb"
    exit 1
  end
end

PerformanceBenchmark.new.run
