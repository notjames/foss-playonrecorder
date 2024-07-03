# frozen_string_literal: true

# {
#   "data": {
#       "data": {
#           "CloudFront-Expires": 1719337059,
#           "CloudFront-Key-Pair-Id": "APKAI47TL42WETPLCGAQ",
#           "CloudFront-Signature": "<REDACTED>"
#       },
#       "thumbnail_url": "https://thumbs.playonrecorder.com/15786531/DKzgeOFLfy/",
#       "url": "https://downloads.playonrecorder.com/us-east-1/1961118/15786531_0_Chicken%20Run.mp4"
#   },
#   "success": true
# }
# data.url/Expires=data.data.CloudFront-Expires&Signature=data.data.CloudFront-Signature&Key-Pair-Id=data.data.CloudFront-Key-Pair-Id
module Helpers
  def build_cf_link(data)
    format('%s?Expires=%s&Signature=%s&Key-Pair-Id=%s', data[:url],
                                                        data[:data][:'CloudFront-Expires'],
                                                        data[:data][:'CloudFront-Signature'],
                                                        data[:data][:'CloudFront-Key-Pair-Id'])
  end

  def read_config(config_file)
    config = ConfigFile.new(config_file)
    RecursiveOpenStruct.new(config.load)
  end

  def save_config(config_file, contents)
    config = ConfigFile.new(config_file)
    config.save(contents)
  end
end
