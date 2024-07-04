# frozen_string_literal: true
# from original source:
# https://github.com/Okomikeruko/terminal-progress/tree/master
#
# altered by @jimconner
# This was necessary because two things:
# 1. The original code didn't seem to be able to work properly
#    with input status values meaning it didn't measure anything
# 2. I needed the output to remain in a specified location on the screen

require 'curses'

##
# Class for managing progress bars in the terminal
class TerminalProgress
  attr_accessor :row

  # Initialize a TermProg instance with a maximum value and a row number.
  #
  # @param row [Integer] The row number to display the progress bar.
  # @param max [Integer] The maximum value of the progress bar.
  def initialize(row, max_width = nil, threaded = false, max)
    @current   = 0
    @total     = 0
    @row       = row
    @max       = max
    @max_width = max_width
    @cycle     = '⣷⣯⣟⡿⢿⣻⣽⣾'.chars.cycle
    @stop      = '⣾'
    @message   = nil
    @mutex     = Mutex.new
    @threaded  = threaded
    @loop      = loop_thread unless threaded == false

    Curses.init_screen
    Curses.start_color
    Curses.init_pair(1, Curses::COLOR_CYAN, Curses::COLOR_BLACK)
    Curses.init_pair(2, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
    Curses.curs_set(0) # Invisible cursor
  end

  def loop_thread
    Thread.new do
      loop do
        instance_variable_set(:@stop, @cycle.next)
        print_line
        sleep 0.0625
      end
    end
  end

  def update_progress(current, msg = nil)
    @total  += current
    @current = current
    @message = msg
    print_progress
  end

  ##
  # Increment the progress bar and print a message if present.
  #
  # @param message [String, nil] Optional message to display above the progress bar.
  def print_progress
    @mutex.synchronize do
      Curses.setpos(@row, 0)
      Curses.clrtoeol # Clear the current line
      Curses.addstr(@message) unless @message.nil?
      Curses.setpos(@row + 1, 0)
      Curses.clrtoeol # Clear the current line

      instance_variable_set(:@stop, @cycle.next) if @threaded == false

      print_line
    end
  end

  ##
  # Increment the progress bar and print a message if present.
  #
  # @param message [String, nil] Optional message to display above the progress bar.
  def print_error(error)
    @mutex.synchronize do
      Curses.setpos(@row, 0)
      Curses.clrtoeol # Clear the current line
      Curses.addstr(error) unless error.nil?
      Curses.setpos(@row + 1, 0)
      Curses.clrtoeol # Clear the current line

      instance_variable_set(:@stop, @cycle.next) if @threaded == false

      print_line
    end
  end

  ##
  # Print a single line of the progress bar.
  def print_line
    Curses.attron(Curses.color_pair(1) | Curses::A_BOLD) do
      Curses.addstr(prefix)
      Curses.addstr('=' * width)
      Curses.addstr('>')
      Curses.addstr(' ' * blank + suffix)
      Curses.attroff(Curses.color_pair(1) | Curses::A_BOLD)
      Curses.refresh
    end
  end

  ##
  # This is the last call to terminate the progress loop and finish rendering the bar.
  def print_complete(*error)
    error = error.first unless error.empty?
    kill
    Curses.setpos(@row, 0)
    Curses.clrtoeol # Clear the current line
    Curses.setpos(@row + 1, 0)
    Curses.clrtoeol # Clear the current line
    Curses.attron(Curses.color_pair(2) | Curses::A_BOLD) do
      if error
        Curses.addstr(format("    %s/%s: [error: %s", error))
      else
        Curses.addstr(format("    %s/%s: [%s!]", @max, @max, '=' * @max_width))
      end
      Curses.refresh
    end
  end

  # Terminate the progress loop.
  def kill
    Thread.kill @loop unless @threaded == false
    Curses.close_screen
  end

  private

  # Generate the prefix of the progress bar.
  def prefix
    "  #{@stop} #{@total.to_s.rjust(@max.to_s.length)}/#{@max}: [>"
  end

  # Calculate the maximum width for the progress bar.
  def max_width
    @max_width || Curses.cols - prefix.length - suffix.length
  end

  # Calculate the current width of the progress bar.
  def width
    ratio  = (@total / @max.to_f)
    ratio /= @max_width.to_f * 100 if ratio > @max_width

    (ratio * max_width).to_i
  end

  # Calculate the number of blank spaces in the progress bar.
  def blank
    max_width - width
  end

  # Define the suffix of the progress bar.
  def suffix
    ']'
  end
end
