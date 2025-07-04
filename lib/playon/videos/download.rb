# frozen_string_literal: true

require_relative '../progress/manager'
require_relative '../progress/bar'

MAX_DOWNLOADS = 6

module Library
  class Videos
    include Helpers

    def download(global, args, videos)
      @options = args.values.first.merge(global)
      @videos  = videos

      download_all
    end

    private

    def touch(file_path)
      File.open(file_path, 'w').close
    end

    def already_exists?(file_path)
      return false if @options[:force]
      
      seek_file  = File.basename(file_path)
      seek_dir   = @config.base_storage_path if @config.to_h.key?(:base_storage_path)
      seek_dir ||= File.dirname(file_path) # Default to directory of file_path if base_file_path not provided
      
      Dir.glob(seek_dir) do |paths| 
        # Use Find.find to recursively search within seek_dir
        Find.find(paths) do |path_file|
          next if File.directory?(path_file)
          
          iter_file = File.basename(path_file)
          
          if iter_file == seek_file
            warn format('Video: %-45s already exists in: %20s. Skipping. Use --force to override.',
                        seek_file, @options[:'dl-path'])
            return true
          end
        end
      end
      
      false # Return false if file was not found
    rescue Errno::ENOENT; end

    def get_resp(video)
      resp_body = get_download_link(video[:ID], video[:Name])
      video_ext = resp_body[:data][:url].split('.').last
      title     = video[:Name].gsub(/[^ -~]+\'|\s*\(\d+\-?\)|\s+$/, '')
      file_path = format('%s/%s.%s', @options[:'dl-path'], title, video_ext)

      video[:resp]      = resp_body
      video[:file_path] = file_path

      video
    end

    def download_all
      threads = []
      manager = Playon::ProgressManager.new if @options[:progress]

      if @options[:force] == false
        warn 'Checking for video existence...'

        @videos.select! do |video|
          get_resp(video)

          next if already_exists?(video[:file_path])

          puts format('Will download: %s (%s)', video[:Name], video[:HumanSize])
          video
        end 

        puts format('Will download %d videos...', @videos.size)
      end

      if @options[:progress]
        progress_thread = Thread.new do
          loop do
            manager.draw
            sleep 0.1
          end
        end
        threads << progress_thread
      end

      @videos.each_slice(MAX_DOWNLOADS) do |slice|
        slice.each do |video|
          video = get_resp(video) unless video.key?(:resp)
          resp = video[:resp]
          cf_link = build_cf_link(resp[:data])
          video_ext = resp[:data][:url].split('.').last
          title = video[:Name].gsub(/[^ -~]+\'|\s*\(\d+\-?\)|\s+$/, '')
          file_path = video[:file_path]
          dl_tpath = format('%s/%s.%s%s', @options[:'dl-path'], title, video_ext, TMP_EXT)
          fin_size = video[:Size]

          if @options[:force]
            File.unlink(file_path) rescue Errno::ENOENT
            touch(dl_tpath)
          end

          if @options[:progress]
            bar = Playon::ProgressBar.new(title, fin_size)
            manager.add_bar(bar)
          end

          download_thread = Thread.new do
            @dl_client.do_download(cf_link, @options, title, file_path, dl_tpath) do |progress|
              bar.update(progress) if @options[:progress]
            end
            if @options[:progress]
              bar.complete
              manager.remove_bar(bar)
            end
          end
          threads << download_thread
        end
        threads.each(&:join)
        threads.clear
      end
    ensure
      manager.close if @options[:progress]
    end

    def get_download_link(video_id, title)
      uri       = format('/v3/library/%s/download', video_id)
      response  = @client.get(uri)
      resp_body = JSON.parse(response.body, symbolize_names: true)

      raise format('Download request failed: %s',
                    resp_body[:error_message]) unless resp_body[:success]
      resp_body
    end
  end
end
