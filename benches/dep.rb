# frozen_string_literal: true

require "benchmark/ips"

require_relative "../lib/pkgcraft"

Benchmark.ips do |benchmark|
  benchmark.config(time: 5, warmup: 2)

  benchmark.report("dep-static") do |times|
    (0..times).each do
      Pkgcraft::Dep::Dep.new("=cat/pkg-1-r2:3/4=[a,b,c]")
    end
  end

  benchmark.report("dep-sorting-worse-case") do |times|
    deps = (1..100).each { |v| Pkgcraft::Dep::Dep.new("=cat/pkg-#{v}-r2:3/4=[a,b,c]") }.compact
    deps = deps.reverse
    (0..times).each do
      deps.sort
    end
  end

  benchmark.report("dep-sorting-best-case") do |times|
    deps = (1..100).each { |v| Pkgcraft::Dep::Dep.new("=cat/pkg-#{v}-r2:3/4=[a,b,c]") }.compact
    (0..times).each do
      deps.sort
    end
  end
end
