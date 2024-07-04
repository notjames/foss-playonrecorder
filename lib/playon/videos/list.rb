# frozen_string_literal: true

require 'terminal-table'
require 'csv'
require 'yaml'

# http --follow api.playonrecorder.com/v3/library/all x-mmt-app:web "Authorization: Bearer "$(jq -Mr '.data.token' <<< "$por_json")""
module Library
  class Videos
    def list(args, pre_action = false)
      @actionable = pre_action
      @options    = args.values.first

      get_all

      # this will be the data structure containing sorted and desired videos
      @v_out        = @videos
      @desired_rows = [:ProviderID, :Name, :Season, :Episode, :ContentRating, :ReleaseYear, :HumanSize, :Expires]
      @head_map     = { ProviderID:    'Provider',
                        Name:          'Name',
                        Season:        'Season',
                        Episode:       'Episode',
                        ContentRating: 'Rating',
                        ReleaseYear:   'Year',
                        HumanSize:     'Size',
                        Expires:       'Expires',}

      show_final
    end

    private

    def show_final
      @options[:all] = false if @options[:'by-series'] || @options[:'by-season'] || @options[:title]
      collate unless @options[:all] == true
      do_sort

      if @v_out.empty?
        warn 'Nothing to show for the given criteria. Exiting.'
        return []
      end

      return @v_out if @actionable

      case @options[:'show-as']
      when 'table'
        show_table
      when 'json'
        show_json
      when 'yaml'
        show_yaml
      when 'csv'
        show_csv
      end
    end

    def show_table
      rows = []

      # TODO optimize rows with @desired_rows
      @v_out.each do |v|
        rows << [v[:ProviderID], v[:Name], v[:Season], v[:Episode], v[:ContentRating], v[:ReleaseYear], v[:HumanSize], v[:Expires]]
      end

      puts Terminal::Table.new headings: @head_map.values, rows: rows
    end

    def show_json
      puts JSON.pretty_generate(@v_out)
    end

    def show_yaml
      puts @v_out.to_yaml
    end

    def show_csv
     cs = CSV.generate do |csv|
        csv << @desired_rows
        @v_out.each do |video|
          csv << @desired_rows.map{|k| video[k]}.flatten
        end
      end
     puts cs
    end

    #{
    #:success => true,
    #   :data => {
    #    :total_entries => 13,
    #          :entries => [
    #        [ 0] {
    #                           :ID => 15786522,
    #                    :AccountID => 1961118,
    #                         :Rank => 1668,
    #                         :Name => "The Call of the Wild",
    #                     :Duration => 5986000,
    #            :EstimatedDuration => 5974000,
    #                   :BrowsePath => "Vudu | My Movies | C",
    #                   :ProviderID => "vudu",
    #                       :Series => nil,
    #                       :Season => nil,
    #                      :Episode => nil,
    #                  :ReleaseYear => "2020",
    #                      :AirDate => "2020-02-21 00:00:00",
    #                :ContentRating => "PG",
    #                  :Description => "..."
    #                 :ThumbnailUrl => "https://thumbs.playonrecorder.com/15786522/wgKhaQO2Zp/",
    #                       :Status => 2,
    #                       :Result => 0,
    #                   :RetryCount => 0,
    #                     :Credited => 0,
    #                      :Quality => 2,
    #                      :Created => "2024-06-25 02:21:35",
    #                      :Updated => "2024-06-25 02:21:35",
    #                 :CreditSource => 3,
    #                         :Size => 2063358322,
    #                      :Expires => "2024-07-02 02:21:35",
    #                    :HumanSize => "1.92 GB"
    #        },
    def get_all
      uri      = '/v3/library/all'
      response = @client.get(uri)
      resp_body = JSON.parse(response.body, symbolize_names: true)

      begin
        raise RuntimeError, format('Error getting all videos: %s', resp_body[:error_message]) \
          if resp_body[:success] == false
      rescue RuntimeError => e
        if e.message =~ /expired token/i
          if auth
            # settle
            sleep 0.65

            warn '...renewed token'
            read_config(@cfgpath)
            get_all
          end
        end
        warn e.message
        exit!
      end

      # TODO mem management and pages of data
      @videos = resp_body[:data][:entries]
    end

    # provides taking videos by-series and by-season
    def collate
      unless @options[:'by-series'].empty?
        @v_out = @v_out.select { |v| @options[:'by-series'].map(&:downcase).include?(v[:Name].downcase) }
      end

      unless @options[:'by-season'].empty?
        @v_out = @v_out.select { |v| @options[:'by-season'].include?(v[:Season]) }
      end

      unless @options[:title].empty?
        @v_out = @v_out.select { |v| @options[:title].map(&:downcase).include?(v[:Name].downcase) }
      end
    end

    def do_sort
      if @options[:reverse]
        @v_out = @v_out.sort_by { |v| v[:Name]    }.reverse     if @options[:'sort-by'] == 'title'
        @v_out = @v_out.sort_by { |v| v[:Size]    }.reverse     if @options[:'sort-by'] == 'size'
        @v_out = @v_out.sort_by { |v| v[:Episode] }.reverse     if @options[:'sort-by'] == 'episode'
        @v_out = @v_out.sort_by { |v| v[:Expires] }.reverse     if @options[:'sort-by'] == 'expires'
        @v_out = @v_out.sort_by { |v| v[:ReleaseYear] }.reverse if @options[:'sort-by'] == 'year'
        return
      end

      @v_out = @v_out.sort_by { |v| v[:Name]    }     if @options[:'sort-by'] == 'title'
      @v_out = @v_out.sort_by { |v| v[:Size]    }     if @options[:'sort-by'] == 'size'
      @v_out = @v_out.sort_by { |v| v[:Episode] }     if @options[:'sort-by'] == 'episode'
      @v_out = @v_out.sort_by { |v| v[:Expires] }     if @options[:'sort-by'] == 'expires'
      @v_out = @v_out.sort_by { |v| v[:ReleaseYear] } if @options[:'sort-by'] == 'year'
    end

    def get_by_title(title)
    end
  end
end

