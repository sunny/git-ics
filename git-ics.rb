#!/usr/bin/env ruby
# Makes an ical of commits out of a git repository.
# Author:   Sunny Ripert http://sunfox.org
# Licence:  WTFPl http://sam.zoy.org/wtfpl/
# Requires: $ sudo gem install icalendar grit mime-types
# Usage:    $ ruby git-ics.rb git-directory-or-uri > calendar.ics
#           $ ruby git-ics.rb --github-user=sunny > my-github-calendar.ics

require 'rubygems'
require 'icalendar'
require 'grit'
require 'yaml'
require 'open-uri'

class GitIcs
  def initialize(paths)
    @paths = paths
  end

  def commits
    commits = []
    @paths.map do |path|
      is_uri = path =~ /\:\/\//

      begin
        path = self.class.clone_from_uri(path) if is_uri
        repo_name = File.basename(File.expand_path(path).gsub(/\/?\.git$/, ''))
        grit_commits = Grit::Repo.new(path).commits
        commits += grit_commits.map { |commit| [repo_name, commit] }
      rescue Grit::NoSuchPathError => e
        $stderr.puts "#{$0}: No such path #{e.message}"
      rescue Grit::InvalidGitRepositoryError => e
        $stderr.puts "#{$0}: #{e.message} is not a git repository"
      ensure
        %x(rm -rf #{path}) if is_uri
      end
    end
    commits.sort_by { |ary| ary[1].committed_date }
  end

  def to_ical
    cal = Icalendar::Calendar.new
    self.commits.each do |repo_name, commit|
      datetime = DateTime.parse(commit.committed_date.to_s)
      cal.event do
        dtstamp     datetime
        dtstart     datetime
        dtend       datetime
        summary     "#{repo_name}: commit by #{commit.author}"
        description commit.message
        uid         commit.id
        klass       "PUBLIC"
      end
    end
    cal.to_ical
  end

  def self.clone_from_uri(uri)
    dirname = uri.gsub(/^.*:\/\/|\/?\.git\/?$/, '').gsub(/\//, '-')
    path = "/tmp/git-ics/#{dirname}.git"
    %x(git clone --bare #{uri} #{path})
    path
  end

  def self.github_uris_for_user(username)
    yaml = YAML.load(open("http://github.com/api/v1/yaml/#{username}"))
    yaml["user"]["repositories"].map { |rep|
      "git://github.com/#{rep[:owner]}/#{rep[:name]}.git"
    }
  end
end

if __FILE__ == $0

  def usage
    "Usage: #{$0} path [path...]\n" + \
    "       #{$0} uri [uri...]\n" + \
    "       #{$0} --github-user=username"
  end

  abort usage if ARGV.empty?

  paths = ARGV
  if ARGV.first =~ /--github-user=(.*)/
    paths = GitIcs.github_uris_for_user($1)
  end

  puts GitIcs.new(paths).to_ical
end

