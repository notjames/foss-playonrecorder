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

      Find.find(file_path) do |file|
        if file == file_path
          basename = File.basename(file)
          warn format('Video: %-45s already exists in: %20s. Skipping. Use --force to override.',
                      basename, @options[:'dl-path'])
          return true
        end
      end rescue Errno::ENOENT

      false
    end

    def download_all
      threads   = []
      progress  = {}
      errors    = {}
      filepath  = nil

      warn 'Checking for video existence...' unless @options[:force]

      # download MAX_DOWNLOADS videos at a time
      @videos.each_slice(MAX_DOWNLOADS).with_index do |slice, index|
        slice.each_with_index do |video, idx|
          resp_body = get_download_link(video[:ID], video[:Name])
          cf_link   = build_cf_link(resp_body[:data])
          video_ext = resp_body[:data][:url].split('.').last
          title     = video[:Name].gsub(/[^ -~]+\'|\s*\(\d+\-?\)|\s+$/, '')
          filepath  = format('%s/%s.%s', @options[:'dl-path'], title, video_ext)
          dl_tpath  = format('%s/%s.%s%s', @options[:'dl-path'], title, video_ext, TMP_EXT)
          tui_row   = index + idx
          tui_row  *= 3 if idx > 0
          fin_size  = video[:Size]
          last_size = 0

          next if already_exists?(filepath)

          File.unlink(filepath) rescue Errno::ENOENT if @options[:force]

          touch(dl_tpath)

          progress[title] = TerminalProgress.new(tui_row, 80, false, fin_size) \
            if @options[:progress]

          download_thread = Thread.new do
            @dl_client.do_download(cf_link, @options, title, filepath, dl_tpath)
          end

          # location of this thread is important
          # it must be after the download_thread is created
          threads << { thread: download_thread,
                       filepath: filepath,
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
                         filepath: filepath,
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
      end
    ensure
      Curses.close_screen
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
