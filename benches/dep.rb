# frozen_string_literal: true

require "benchmark/ips"

require_relative "../lib/pkgcraft"

Benchmark.ips do |benchmark|
  benchmark.config(time: 5, warmup: 2)

  benchmark.report("static-dep") do |times|
    (0..times).each do
      Pkgcraft::Dep::Dep.new("=cat/pkg-1-r2:3/4=[a,b,c]")
    end
  end
end
