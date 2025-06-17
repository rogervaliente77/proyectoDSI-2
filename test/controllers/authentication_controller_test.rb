require "test_helper"

class AuthenticationControllerTest < ActionDispatch::IntegrationTest
  test "should get login" do
    get authentication_login_url
    assert_response :success
  end

  test "should get signup" do
    get authentication_signup_url
    assert_response :success
  end

  test "should get validate_signup" do
    get authentication_validate_signup_url
    assert_response :success
  end
end
