# frozen_string_literal: true

require 'thread'
require 'thwait'
require 'find'

require_relative '../progress/bar'

MAX_DOWNLOADS = 6

# http --follow api.playonrecorder.com/v3/library/<video ID IE: 15786531>/download x-mmt-app:web "Authorization: Bearer "$(jq -Mr '.data.token' <<< "$por_json")""
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
      threads   = []
      progress  = {}
      errors    = {}
      file_path = nil

      warn 'Checking for video existence...' unless @options[:force]

      unless @options[:force]
        @videos.select! do |video|
          next if already_exists?(file_path)
          resp_body         = get_resp(video)[:resp]

          video[:resp]      = resp_body
          video[:file_path] = file_path
          video
        end 

        puts format('Will download %d videos...', @videos.size)
      end

      # download MAX_DOWNLOADS videos at a time
      @videos.each_slice(MAX_DOWNLOADS).with_index do |slice, index|
        slice.each_with_index do |video, idx|
          video     = get_resp(video) unless video.has_key?(:resp)
          resp      = video[:resp]
          cf_link   = build_cf_link(resp[:data])
          video_ext = resp[:data][:url].split('.').last
          title     = video[:Name].gsub(/[^ -~]+\'|\s*\(\d+\-?\)|\s+$/, '')
          file_path = video[:file_path]
          dl_tpath  = format('%s/%s.%s%s', @options[:'dl-path'], title, video_ext, TMP_EXT)
          tui_row   = index + idx
          tui_row  *= 3 if idx > 0
          fin_size  = video[:Size]
          last_size = 0

          if @options[:force]
            File.unlink(file_path) rescue Errno::ENOENT
            touch(dl_tpath)
          end

          progress[title] = TerminalProgress.new(tui_row, 80, false, fin_size) \
            if @options[:progress]

          download_thread = Thread.new do
            @dl_client.do_download(cf_link, @options, title, file_path, dl_tpath)
          end

          # location of this thread is important
          # it must be after the download_thread is created
          threads << { thread: download_thread,
                       filepath: file_path,
                       dl_tpath: dl_tpath,
                       title: title,
                       type: 'download' }

          if @options[:progress]
            progress_thread = Thread.new do
              loop do
                begin
                  now_size   = File.size(dl_tpath)
                  delta_size = now_size - last_size

                  progress[title].update_progress(delta_size,
                                                  format('Downloading:: %87s (%s)',
                                                          title, video[:HumanSize]))

                  last_size  = File.size(dl_tpath)

                  break if now_size >= fin_size
                  sleep 0.1
                rescue Errno::ENOENT
                  break
                end
              end
              progress[title].print_complete
            end

            # location of this thread is important
            threads << { thread: progress_thread,
                         filepath: file_path,
                         dl_tpath: dl_tpath,
                         title: title,
                         type: 'progress' }
          else
            puts format("Downloading: %s (%s)", title, video[:HumanSize])
          end
        end

        ThreadsWait.all_waits(*threads.map { |t| t[:thread] }) do |t|
          done_thread = threads.select { |th| th[:thread] == t }.first
          if done_thread[:type] == 'download' && t == done_thread[:thread]
            begin
              File.rename(done_thread[:dl_tpath], done_thread[:filepath])
            rescue Errno::ENOENT => e
              title   = done_thread[:title]
              unless @options[:progress]
                warn format('Error renaming file: %s (so moving on)', e.message)
                next
              end

              progress_thread = threads.select do |th|
                                  th[:title] == title && th[:type] == 'progress'
                                end.first

              progress[title].print_complete(errors[title]) 
              progress_thread[:thread].kill
            end
          end
        end
      ensure
        Curses.close_screen
      end
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
