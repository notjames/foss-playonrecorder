# frozen_string_literal: true

require 'curses'
require 'thread'

module Playon
  class ProgressManager
    def initialize
      @bars = []
      @mutex = Mutex.new
      Curses.init_screen
      Curses.start_color
      Curses.init_pair(1, Curses::COLOR_CYAN, Curses::COLOR_BLACK)
      Curses.init_pair(2, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
      Curses.curs_set(0) # Invisible cursor
    end

    def add_bar(bar)
      @mutex.synchronize do
        @bars << bar
      end
    end

    def remove_bar(bar)
      @mutex.synchronize do
        @bars.delete(bar)
      end
    end

    def draw
      @mutex.synchronize do
        Curses.clear
        @bars.each_with_index do |bar, i|
          bar.draw(i)
        end
        Curses.refresh
      end
    end

    def close
      Curses.close_screen
    end
  end
end
