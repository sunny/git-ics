#!/usr/bin/env ruby

require 'icalendar'
require 'grit'
require 'yaml'
require 'open-uri'

module GitIcs
  TMP_PATH = "/tmp/git-ics"

  class Repo
    attr_reader :location

    def initialize(location)
      @location = location
    end

    def is_local?
      !(@location =~ /\:\/\//)
    end

    def path
      return @location if is_local?
      @path ||= local_clone
    end

    def name
      @name ||= @location.gsub(/^.*:\/\/|\/?\.git\/?$/, '').gsub(/\//, '-')
    end

    def grit
      @grit ||= Grit::Repo.new(path)
    end

    def commits
      grit.commits
    end

    def local_clone
      path = File.join(TMP_PATH, "#{name}.git")
      %x(git clone --bare #{@location} #{path})
      # TODO raise Grit::InvalidGitRepositoryError.new(@location)
      path
    end

  end

  class Cal
    def initialize(locations)
      @repos = locations.map { |location| Repo.new(location) }
    end

    def cleanup
      %x(rm -rf #{TMP_PATH})
    end

    def commits
      commits = []
      @repos.map do |repo|
        begin
          commits += repo.commits.map { |commit| [repo.name, commit] }
        rescue Grit::NoSuchPathError => e
          $stderr.puts "#{$0}: No such path #{e.message}"
        rescue Grit::InvalidGitRepositoryError => e
          $stderr.puts "#{$0}: #{e.message} is not a git repository"
        ensure
          cleanup
        end
      end
      cleanup
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
  end

  def self.github_uris_for_user(username)
    yaml = YAML.load(open("http://github.com/api/v1/yaml/#{username}"))
   yaml["user"]["repositories"].map { |rep|
      "git://github.com/#{rep[:owner]}/#{rep[:name]}.git"
    }
  end
end

if __FILE__ == $0

  if ARGV.empty?
    abort "Usage: #{$0} path [path...]\n" + \
          "       #{$0} uri [uri...]\n" + \
          "       #{$0} --github-user=username"
  end

  paths = ARGV.map do |arg|
    if arg =~ /--github-user=(.*)/
      GitIcs.github_uris_for_user($1)
    else
      arg
    end
  end.flatten

  puts GitIcs::Cal.new(paths).to_ical
end

