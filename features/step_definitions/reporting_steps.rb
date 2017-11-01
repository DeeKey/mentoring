Given /^a meeting to "(.+)" and user "(.+)" at yesterday$/ do |child_name, email|
  meeting = Meeting.create! do |meeting|
    meeting.date = 1.day.since
    meeting.child_id = Child.find_by_first_name(child_name).id
    meeting.mentor_id = User.find_by_email(email).id
  end
  meeting.update(date: 1.day.before)
end

Then /^I should meeting's action "(.+)" visible only meeting at yesterday$/ do |action_name|
  page.all('table tbody tr').each do |row|
    if row.has_content?(1.day.since.to_date)
      expect(row).to have_selector(:link_or_button, action_name)
    else
      expect(row).to_not have_button(:link_or_button, action_name)
    end
  end
end

Then /^I fill in an input "(.+)" as "(.+)" in the form "(.+)"$/ do |input, value, form_id|
  within "form##{form_id}" do
    fill_in input, with: value
  end
end

Then /^a report of the meeting should be created$/ do
  expect(Report.last).to_not eq(nil)
end

Given /^meeting to "(.+)" and user "(.+)" at yesterday on state "report_sent"$/ do |child_name, email|
  meeting = Meeting.create! do |m|
    m.date = 1.day.since
    m.child_id = Child.find_by_first_name(child_name).id
    m.mentor_id = User.find_by_email(email).id
  end
  meeting.update(date: 1.day.before)

  Report.create! do |report|
    report.meeting_id = meeting.id
    report.duration = 4
    report.aim = 'something'
    report.short_description = 'something'
    report.questions = 'something'
    report.feelings = 'something'
    report.next_aim = 'something'
    report.result = 'something'
    report.other_comments = 'something'
  end
end

When /^I reject a report of meeting "(.+)" with "(.+)"$/ do |email, name|
  find('tbody tr', /#{name}(.+)#{email}/).find(:link_or_button, 'Отклонить').click
end

Then /^the report should have state "(.+)"$/ do |state|
  expect(Report.last.state).to eq(state)
end

When /^I approve a report of meeting "(.+)" with "(.+)"$/ do |email, name|
  find('tbody tr', /#{name}(.+)#{email}/).find(:link_or_button, 'Одобрить').click
end
