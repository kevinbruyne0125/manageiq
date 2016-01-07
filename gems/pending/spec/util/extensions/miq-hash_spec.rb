require "spec_helper"
require 'util/extensions/miq-hash'

# Subclass of String to test []= substring complex key patch
class SubString < String
  attr_accessor :sub_str
end

describe Hash do
  it '#[]= with a substring key' do
    s = SubString.new("string")
    s.sub_str = "substring"

    h = {}
    h[s] = "test"
    s2 = h.keys.first

    expect(s2).to eq(s)
    expect(s2.sub_str).to eq(s.sub_str)
  end

  it "#sort!" do
    h = {:x => 1, :b => 2, :y => 3, :a => 4}
    h_id = h.object_id

    h.sort!

    expect(h.keys).to eq([:a, :b, :x, :y])
    expect(h.object_id).to eq(h_id)
  end

  it "#sort_by!" do
    h = {:x => 1, :b => 2, :y => 3, :a => 4}
    h_id = h.object_id

    h.sort_by! { |k, _v| k }

    expect(h.keys).to eq([:a, :b, :x, :y])
    expect(h.object_id).to eq(h_id)
  end
end
