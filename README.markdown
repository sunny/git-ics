Git-ICS
=======

Makes an ical of commits out of git repositories.

- Author: [Sunny Ripert](http://sunfox.org/)
- Licence: [WTFPL](http://sam.zoy.org/wtfpl/)
- Requires gems `icalendar`, `grit`, `mime-types`:

        $ sudo gem install icalendar grit mime-types

- Usage:

        $ ruby git-ics.rb [--github-user=username|repository-path|repository-uri] ...
        
- Example:

        $ ruby git-ics.rb ~/code/*/.git --github-user=sunny > my-code-calendar.ics

