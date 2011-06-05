require 'test/unit'
require 'date'
require './TMY3.rb'
class Some_tests < Test::Unit::TestCase
  def test_method_invalid?
    assert_equal true, invalid?("GU", 96)
    assert_equal true, invalid?("HI", 960)
    assert_equal true, invalid?("VI", 490)
    assert_equal true, invalid?("PR", 139)
    assert_equal true, invalid?("AK", 1094)
    assert_equal false, invalid?("CA", 83)
    assert_equal true, invalid?("CA", 1049)
  end

  def test_method_days_in_month
    assert_equal days_in_month(2), 28 #no leap years in TMY3 
    assert_equal days_in_month(9), 30
  end
end
