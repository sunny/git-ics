require 'rubygems'
require 'icalendar'
require 'grit'

repo = Grit::Repo.new ARGV.first

cal = Icalendar::Calendar.new

repo.commits.each do |commit|
  cal.event do
    dtstart     commit.comitted_date
    dtend       commit.comitted_date
    summary     "Commit by #{commit.author}"
    description commit.message
    klass       "PUBLIC"
  end
end

puts cal.to_ical

