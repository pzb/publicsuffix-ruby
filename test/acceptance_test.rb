require 'test_helper'

class AcceptanceTest < Minitest::Unit::TestCase

  ValidCases = [
      ["example.com",             "example.com",        [nil, "example", "com"]],
      ["foo.example.com",         "example.com",        ["foo", "example", "com"]],

      ["verybritish.co.uk",       "verybritish.co.uk",  [nil, "verybritish", "co.uk"]],
      ["foo.verybritish.co.uk",   "verybritish.co.uk",  ["foo", "verybritish", "co.uk"]],

      ["parliament.uk",           "parliament.uk",      [nil, "parliament", "uk"]],
      ["foo.parliament.uk",       "parliament.uk",      ["foo", "parliament", "uk"]],
  ]

  def test_valid
    ValidCases.each do |input, domain, results|
      parsed = PublicSuffix.parse(input)
      trd, sld, tld = results
      assert_equal tld, parsed.tld, "Invalid tld for `#{name}`"
      assert_equal sld, parsed.sld, "Invalid sld for `#{name}`"
      assert_equal trd, parsed.trd, "Invalid trd for `#{name}`"

      assert_equal domain, PublicSuffix.domain(input)
      assert PublicSuffix.valid?(input)
    end
  end


  InvalidCases = [
      ["nic.ke",                  PublicSuffix::DomainNotAllowed],
      [nil,                       PublicSuffix::DomainInvalid],
      ["",                        PublicSuffix::DomainInvalid],
      ["  ",                      PublicSuffix::DomainInvalid],
  ]

  def test_invalid
    InvalidCases.each do |(name, error)|
      assert_raises(error) { PublicSuffix.parse(name) }
      assert !PublicSuffix.valid?(name)
    end
  end


  RejectedCases = [
      ["www. .com",           true],
      ["foo.co..uk",          true],
      ["goo,gle.com",         true],
      ["-google.com",         true],
      ["google-.com",         true],

      # This case was covered in GH-15.
      # I decided to cover this case because it's not easily reproducible with URI.parse
      # and can lead to several false positives.
      ["http://google.com",   false],
  ]

  def test_rejected
    RejectedCases.each do |name, expected|
      assert_equal expected, PublicSuffix.valid?(name), "Expected %s to be %s" % [name.inspect, expected.inspect]
      assert !valid_domain?(name), "#{name} expected to be invalid"
    end
  end


  CaseCases = [
      ["Www.google.com", %w( www google com )],
      ["www.Google.com", %w( www google com )],
      ["www.google.Com", %w( www google com )],
  ]

  def test_ignore_case
    CaseCases.each do |name, results|
      domain = PublicSuffix.parse(name)
      trd, sld, tld = results
      assert_equal tld, domain.tld, "Invalid tld for `#{name}'"
      assert_equal sld, domain.sld, "Invalid sld for `#{name}'"
      assert_equal trd, domain.trd, "Invalid trd for `#{name}'"
      assert PublicSuffix.valid?(name)
    end
  end


  IncludePrivateCases = [
      ["blogspot.com", true, "blogspot.com"],
      ["blogspot.com", false,  nil],
      ["subdomain.blogspot.com", true, "blogspot.com"],
      ["subdomain.blogspot.com", false,  "subdomain.blogspot.com"],
  ]

  def test_ignore_private
    # test domain and parse
    IncludePrivateCases.each do |given, ignore_private, expected|
      assert_equal expected, PublicSuffix.domain(given, ignore_private: ignore_private)
    end
    # test valid?
    IncludePrivateCases.each do |given, ignore_private, expected|
      assert_equal !expected.nil?, PublicSuffix.valid?(given, ignore_private: ignore_private)
    end
  end


  def valid_uri?(name)
    uri = URI.parse(name)
    !uri.host.nil?
  rescue
    false
  end

  def valid_domain?(name)
    uri = URI.parse(name)
    !uri.host.nil? && uri.scheme.nil?
  rescue
    false
  end

end