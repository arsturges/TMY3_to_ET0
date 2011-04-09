require 'test/unit'
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
end
