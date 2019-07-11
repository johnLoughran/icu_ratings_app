module ICU
  class Export
    def self.ratings
      @start = Time.now

      # Run the command that creates both export zip files. Perl is used because
      # it isn't so easy to create DBF files (for SwissPerfect) using Ruby.
      # The two file previously produced are swiss_perfect_pub.dbf and
      # e.g. swiss_manager_pub.Jun19.txt suitable for previous versions of swiss_manager
      # JL added another file swiss_manager_unicode_pub.MMMYY.xls suitable for swiss_manager from 2019 on
      # All bundled in a file called pub_ratings.zip (see line 31 below) 
      # available from https://ratings.icu.ie/downloads currently(2019) as admin
      # This page has one live_ratings.zip and lots of pub_ratings.zip s
      cmd = "bin/export.pl -e #{Rails.env} 2>&1"
      out = `#{cmd}`.strip
      # .strip removes only leading and trailing whitespace

      # Initialise a report and a Boolean success for the Event we'll create later.
      report = []
      report.push cmd
      report.push "---"
      report.push out
      report.push "---"
      success = true
      # report should be [export from perl, ---, export from perl(stripped), ---, updated/created, published, 

      # Update (or create) a Download object for each export file.
      begin
        %w(published live).each do |type|
          # ternary operator. If Condition is true ? Then value X : Otherwise value Y
          short = type == "published" ? "pub" : "live"
          file  = "tmp/#{short}.zip"   # e.g. tmp/pub_ratings.zip
          match = "wrote #{file}"
          # if the index of "wrote tmp/pub_ratings.zip" returns true i.e. if the element "wrote tmp/pub_ratings.zip"
          # is in the stripped output from perl
          if out.index(match)
            comment      = "Latest #{type} ratings"
            file_name    = "#{short}_ratings.zip"
            content_type = "application/zip"
            if type == "published"
              rating_list = RatingList.first
            else
              rating_list = nil
            end
            data         = File.open(file, "r", encoding: "ASCII-8BIT") { |f| f.read }
            # creates a Download object with attributes as shown
            download = Download.where(comment: comment, file_name: file_name, content_type: content_type, rating_list: rating_list).first
            if download
              action = "updated"
              download.data = data
              download.save!
            else
              action = "created"
              download = Download.create!(comment: comment, file_name: file_name, content_type: content_type, rating_list: rating_list, data: data)
            end
            report.push "#{action} #{type} ratings download"
          else
            report.push "output doesn't match '#{match}'"
            success = false
          end
        end
      rescue => e
        report.push "EXCEPTION: #{e.message}"
        report += e.backtrace[0..10]
        success = false
      end

      # Create an Event to summarize what happened.
      Event.create(name: "Ratings Export", report: report.join("\n"), time: Time.now - @start, success: success)
    end
  end
end
