winrm_opts = {
  endpoint: 'http://localhost:5985/wsman',
  transport: :plaintext,
  basic_auth_only: true,
  user: 'Administrator',
  password: 'Password'
}

require 'winrm'
require 'stringio'

# require 'hexdump'
# def dump(prefix, data)
#   return if data == nil
#   s = StringIO.new
#   Hexdump.dump(data, output: s)
#   puts s.string.gsub(/^/, "#{prefix}: ")
# end

class LineBuffer
  def initialize
    @buffer = StringIO.new
  end

  def lines(data, &block)
    if data == nil
      return
    end
    remaining_buffer = StringIO.new
    @buffer << data
    @buffer.string.each_line do |line|
      if line.end_with? "\n"
        block.call(line.rstrip)
      else
        remaining_buffer << line
        break
      end
    end
    @buffer = remaining_buffer
  end

  def remaining(&block)
    if @buffer.length > 0
      block.call(@buffer.string.rstrip)
      @buffer = StringIO.new
    end
  end
end

def line_buffered_shell_run(shell, command, &block)
  out = LineBuffer.new
  err = LineBuffer.new

  # execute the command and emit its output as complete lines.
  output = shell.run(command) do |stdout, stderr|
    out.lines stdout do |line|
      block.call(line, nil)
    end
    err.lines stderr do |line|
      block.call(nil, line)
    end
  end

  # emit the remaining as incomplete/partial lines.
  out.remaining do |line|
    block.call(line, nil)
  end
  err.remaining do |line|
    block.call(nil, line)
  end

  return output
end

def original_shell_run(shell, command, &block)
  return shell.run(command) do |stdout, stderr|
    block.call(stdout, stderr)
  end
end

def shell_run(conn, shell_type, shell_run_method)
  conn.shell(shell_type) do |shell|
    out = StringIO.new
    err = StringIO.new
    command = 'C:/Python36/python.exe c:/emit-partial-output.py --lines 3 --length 120 --flush'
    command = "#{command} --no-stderr" if shell_type == :powershell
    output = shell_run_method.call(shell, command) do |stdout, stderr|
      out << "stdout: #{stdout}\n" if stdout
      err << "stderr: #{stderr}\n" if stderr
    end
    return output.exitcode, out.string, err.string
  end
end

def shell_run_and_dump(conn, shell_type, shell_run_method_symbol)
  puts '='*128
  puts "#{shell_type} #{shell_run_method_symbol}"
  exitcode, stdout, stderr = shell_run(conn, shell_type, method(shell_run_method_symbol))
  puts "exitcode: #{exitcode}"
  if stdout != ''
    puts '-'*128
    puts stdout
  end
  if stderr != ''
    puts '-'*128
    puts stderr
  end
end

puts "ruby/#{RUBY_VERSION} winrm/#{WinRM::VERSION}"
conn = WinRM::Connection.new(winrm_opts)
# conn.logger.level = :debug
[:cmd, :powershell].each do |shell_type|
  shell_run_and_dump(conn, shell_type, :original_shell_run)
  shell_run_and_dump(conn, shell_type, :line_buffered_shell_run)
end
