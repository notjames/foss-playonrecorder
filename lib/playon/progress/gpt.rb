require 'curses'
require 'colorize'

##
# Class for managing progress bars in the terminal
class TerminalProgress
  attr_accessor :row

  # Initialize a TermProg instance with a maximum value and a row number.
  #
  # @param max [Integer] The maximum value of the progress bar.
  # @param row [Integer] The row number to display the progress bar.
  def initialize(max, row)
    @max = max
    @current = 0
    @row = row
    @cycle = '⣷⣯⣟⡿⢿⣻⣽⣾'.chars.cycle
    @stop = '⣾'
    @message = nil
    @loop = loop_thread

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
    @current = current
    @message = msg
    print_progress
  end

  ##
  # Increment the progress bar and print a message if present.
  #
  # @param message [String, nil] Optional message to display above the progress bar.
  def print_progress
    Curses.setpos(@row * 2, 0)
    Curses.clrtoeol # Clear the current line
    Curses.addstr(@message) unless @message.nil?
    Curses.setpos(@row * 2 + 1, 0)
    Curses.clrtoeol # Clear the current line
    print_line
  end

  ##
  # Print a single line of the progress bar.
  def print_line
    Curses.attron(Curses.color_pair(1) | Curses::A_BOLD) do
      Curses.addstr(prefix)
      Curses.addstr('='.light_cyan * width)
      Curses.attroff(Curses.color_pair(1) | Curses::A_BOLD)
      Curses.addstr(' ' * blank + suffix)
      Curses.refresh
    end
  end

  ##
  # This is the last call to terminate the progress loop and finish rendering the bar.
  def print_complete
    kill
    Curses.setpos(@row * 2, 0)
    Curses.clrtoeol # Clear the current line
    Curses.setpos(@row * 2 + 1, 0)
    Curses.clrtoeol # Clear the current line
    Curses.attron(Curses.color_pair(2) | Curses::A_BOLD) do
      Curses.addstr("    #{@max}/#{@max}: [#{'='.light_yellow * max_width}]")
      Curses.refresh
    end
  end

  # Terminate the progress loop.
  def kill
    Thread.kill @loop
    Curses.close_screen
  end

  private

  # Generate the prefix of the progress bar.
  def prefix
    "  #{@stop} #{@current.to_s.rjust(@max.to_s.length)}/#{@max}: ["
  end

  # Calculate the maximum width for the progress bar.
  def max_width
    Curses.cols - prefix.length - suffix.length
  end

  # Calculate the current width of the progress bar.
  def width
    ((@current / @max.to_f) * max_width).to_i
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
