# frozen_string_literal: true

require 'curses'

module Playon
  class ProgressBar
    attr_reader :title, :total, :max, :error

    def initialize(title, max)
      @title = title
      @max = max
      @total = 0
      @error = nil
      @cycle = '⣷⣯⣟⡿⢿⣻⣽⣾'.chars.cycle
    end

    def update(total)
      @total = total
    end

    def complete(error = nil)
      @error = error
      @total = @max
    end

    def draw(row)
      Curses.setpos(row * 2, 0)
      Curses.clrtoeol
      Curses.addstr(@title)
      Curses.setpos(row * 2 + 1, 0)
      Curses.clrtoeol

      if @error
        Curses.attron(Curses.color_pair(2) | Curses::A_BOLD) do
          Curses.addstr("  Error: #{@error}")
        end
      elsif @total == @max
        Curses.attron(Curses.color_pair(2) | Curses::A_BOLD) do
          Curses.addstr("  Done!")
        end
      else
        Curses.attron(Curses.color_pair(1) | Curses::A_BOLD) do
          Curses.addstr("  #{@cycle.next} [#{"=" * (width)}>] #{(@total / @max.to_f * 100).to_i}%")
        end
      end
    end

    private

    def width
      (total / max.to_f * (Curses.cols - 10)).to_i
    end
  end
end