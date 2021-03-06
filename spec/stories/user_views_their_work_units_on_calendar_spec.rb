require 'spec_helper'

steps "see user work units on calendar", :type => :feature do
  let :base_time do
    Time.now.beginning_of_day-1.day+12.hours
  end
  let! :user do FactoryGirl.create(:user) end
  let! :user_work_units do
    FactoryGirl.create(:work_unit_with_annotation, :user => user, :hours => 4, :description => "Number1")
  end
  let! :non_user_work_units do
    FactoryGirl.create(:work_unit_with_annotation, :hours => 7, :description => "Number2")
  end
  let! :user_work_units_in_range do
    FactoryGirl.create(:work_unit_with_annotation, :start_time => base_time-4.hours, :stop_time => base_time-3.hours, :hours => 1, :user => user, :description => "Number3")
  end
  let! :user_work_units_out_of_range do
    FactoryGirl.create(:work_unit_with_annotation, :start_time => base_time-1.week, :stop_time => base_time-1.week+2.hours, :hours =>2, :user => user, :description => "Number4")
  end

  it "log in as a regular user" do
    visit root_path
    fill_in "Login", :with => user.login
    fill_in "Password", :with => user.password
    click_button 'Login'
  end

  it "visit the 'Calendar' page" do
    click_link 'Calendar'
  end

  it "should have Full Calendar loaded" do
    page.should have_selector(".fc-view-container")
  end

  it "should have my work unit events in the calendar" do
    page.should have_content("#{user_work_units_in_range.project.name} - #{user_work_units_in_range.notes}")
    page.should_not have_content("#{user_work_units_out_of_range.project.name} - #{user_work_units_out_of_range.notes}")
  end

  it "should go to work unit show page when item is clicked" do
    click_on ("#{user_work_units_in_range.project.name} - #{user_work_units_in_range.notes}")
    page.should have_content("Editing Work Unit")
  end
end
