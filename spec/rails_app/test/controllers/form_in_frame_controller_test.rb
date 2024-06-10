require "test_helper"

class FormInFrameControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get form_in_frame_index_url
    assert_response :success
  end
end
