# frozen_string_literal: true

# https --json delete https://api.playonrecorder.com/v3/library/15786390 Accept:application/json Content-type:application/json Authorization:'Bearer <REDACTED>'
module Library
  class Videos
    def delete(global, args, videos)
      @options = args.values.first.merge(global)
      @videos  = videos

      delete_all
    end

    private

    def delete_all
      @videos.each do |video|
        uri      = format('/v3/library/%s', video[:ID])
        response = @client.delete(uri)
        resp_body = JSON.parse(response.body, symbolize_names: true)
        warn format('Unable to delete "%s": %s', video[:Name], resp_body[:error_message]) \
          if resp_body[:success] == false
        puts format('Deleted "%s"', video[:Name]) if resp_body[:success] == true
      end
    end
  end
end

