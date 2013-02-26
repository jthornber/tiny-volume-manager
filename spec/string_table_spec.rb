require 'spec_helper'
require 'string/string-table'
require 'set'

#----------------------------------------------------------------

describe StringUtils::StringTable do
  it 'should raise an exception if string not in table' do
    t = StringUtils::StringTable.new
    expect {t['foo']}.to raise_error(RuntimeError, /foo/)
    expect {t['bar']}.to raise_error(RuntimeError, /bar/)
    expect {t['hux']}.to raise_error(RuntimeError, /hux/)
  end

  it 'should not allow empty strings to be added' do
    t = StringUtils::StringTable.new
    expect {t.add('')}.to raise_error(RuntimeError, /invalid string/)
  end

  it 'should not allow empty strings to be looked up' do
    t = StringUtils::StringTable.new
    expect {t['']}.to raise_error(RuntimeError, /invalid string/)
  end

  it 'should allow lookup of an added string' do
    t = StringUtils::StringTable.new
    t.add('one')
    t['one']
  end

  it 'should give unique short values' do
    h = Hash.new

    t = StringUtils::StringTable.new
    1.upto(1000) do |n|
      str = n.to_s
      h[str] = t.add(str)
    end

    1.upto(1000) do |n|
      str = n.to_s
      t[str].should == h[str]
    end

    s = h.values.to_set
    s.size.should == 1000
  end

  it 'should support each which iterates in key order' do
    words = %w(fish apple goat ball cat jumper hedge)

    t = StringUtils::StringTable.new
    words.each {|w| t.add(w)}

    a = Array.new
    t.each {|k, v| a << k}

    a.should == words.sort
  end
end
