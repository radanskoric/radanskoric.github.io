require "application_system_test_case"

class TicketsTest < ApplicationSystemTestCase
  test "target_top approach with message" do
    visit "/form_in_frame"
    within "#target_top" do
      fill_in "Message", with: "target_top"
      click_on "The frame targets the top!"
    end

    assert_text "target_top"
  end

  test "refresh_action approach with message" do
    visit "/form_in_frame"
    within "#refresh_action" do
      fill_in "Message", with: "refresh_action"
      click_on "Use refresh action!"
    end

    assert_text "refresh_action"
  end

  test "refresh_action approach with no message entered" do
    visit "/form_in_frame"
    within "#refresh_action" do
      click_on "Use refresh action!"
      assert_text "An error has occurred: the message can't be empty"
    end
  end

  test "visit_control approach with message" do
    visit "/form_in_frame"
    within "#visit_control" do
      fill_in "Message", with: "visit_control"
      click_on "Make redirect target have turbo-visit-control meta tag!"
    end

    assert_text "visit_control"
  end

  test "visit_control approach with no message entered" do
    visit "/form_in_frame"
    within "#visit_control" do
      click_on "Make redirect target have turbo-visit-control meta tag!"
      assert_text "An error has occurred: the message can't be empty"
    end
  end

  test "custom_action approach with message" do
    visit "/form_in_frame"
    within "#custom_action" do
      fill_in "Message", with: "custom_action"
      click_on "Make redirect target have turbo-visit-control meta tag!"
    end

    assert_text "custom_action"
  end

  test "custom_action approach with no message entered" do
    visit "/form_in_frame"
    within "#custom_action" do
      click_on "Make redirect target have turbo-visit-control meta tag!"
      assert_text "An error has occurred: the message can't be empty"
    end
  end
end
