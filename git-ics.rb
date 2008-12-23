#!/usr/bin/env ruby
# Makes an ical of commits out of a git repository.
# Author:   Sunny Ripert http://sunfox.org
# Licence:  WTFPl http://sam.zoy.org/wtfpl/
# Requires: $ sudo gem install icalendar grit mime-types
# Usage:    $ ruby git-ics.rb git-directory > calendar.ics

require 'rubygems'
require 'icalendar'
require 'grit'

class GitIcs
  def initialize(dir)
    @dir = dir
  end

  def name
    File.basename(File.expand_path(@dir).gsub(/\/?\.git$/, ''))
  end

  def commits
    Grit::Repo.new(@dir).commits
  end

  def to_ical
    cal = Icalendar::Calendar.new
    name = self.name
    self.commits.each do |commit|
      datetime = DateTime.parse(commit.committed_date.to_s)
      cal.event do
        dtstamp     datetime
        dtstart     datetime
        dtend       datetime
        summary     "#{name}: commit by #{commit.author}"
        description commit.message
        uid         commit.id
        klass       "PUBLIC"
      end
    end
    cal.to_ical
  end
end

if __FILE__ == $0
  dir = ARGV.first || ""
  begin
    puts GitIcs.new(dir).to_ical
  rescue Grit::NoSuchPathError
    abort "#{$0}: No such path #{File.expand_path(dir)}"
  rescue Grit::InvalidGitRepositoryError
    abort "#{$0}: #{File.expand_path(dir)} is not a git repository"
  end
end

