require 'test/unit'
require 'tmy3'
class Some_tests < Test::Unit::TestCase
  def test_method_invalid?
    @elevation = 960
    @state = "GU"
    assert_equal true, invalid?
    @state = "HI"
    assert_equal true, invalid?
    @state = "AK"
    assert_equal true, invalid?
    @state = "VI"
    assert_equal true, invalid?
    @state = "PR"
    assert_equal true, invalid?
    @state = "CA"
    assert_equal false, invalid?
    @elevation = 1069
    assert_equal true, invalid?
  end

  def test_method_days_in_month
    assert_equal days_in_month(2011,2), 28 
    assert_equal days_in_month(1996,2), 28 #leap years should still have 28 days because of tmy3 data
  end

  def test_method_last_day_of_month?
    @current_row_datetime = DateTime.new(2011,2,2)
    assert_equal last_day_of_month?, false

    @current_row_datetime = DateTime.new(1996,2,28) #leap year should still have 28 days
    assert_equal last_day_of_month?, true

    @current_row_datetime = DateTime.new(2011,6,30)
    assert_equal last_day_of_month?, true
  end

  def test_method_last_hour_of_day?
    @current_row_datetime = DateTime.new(2011,4,9,10,39,13)
    assert_equal last_hour_of_day?, false
    @current_row_datetime = DateTime.new(2011,4,9,22,39,13)
    assert_equal last_hour_of_day?, false
    @current_row_datetime = DateTime.new(2011,4,9,23,39,13)
    assert_equal last_hour_of_day?, true 
  end
end
