# About

This example shows how the [WinRM gem](https://github.com/WinRb/WinRM) behaves while capturing an application output.

This was used to troubleshoot [vagrant#11047](https://github.com/hashicorp/vagrant/issues/11047).

The example [emit-partial-output.py](emit-partial-output.py) application is executed by [main.rb](main.rb) and its output is displayed.

The example application will write a single byte at a time to stdout/stderr to test how the WinRM gem handles partial output.

The example application is executed as:

```ruby
# shell_type will be :cmd or :powershell
conn.shell(shell_type) do |shell|
  output = shell.run command do |stdout, stderr|
    puts "stdout: #{stdout}" if stdout
    puts "stderr: #{stderr}" if stderr
  end
end
```

We can see unexpected differences in how the gem reports the output data.

When using the `cmd` shell we can see partial lines being reported. Compare the actual output:

```plain
================================================================================================================================
cmd original_shell_run
exitcode: 0
--------------------------------------------------------------------------------------------------------------------------------
stdout: #
stdout:  line 0001 ###################################################
stdout: #########################################################
# line 0002 ############################################################################################################
# line 0003 ############################################################################################################

--------------------------------------------------------------------------------------------------------------------------------
stderr: #
stderr:  line 
stderr: 0001 ############################################################################################################
# line 0002 ############################################################################################################
# line 0003 ############################################################################################################

================================================================================================================================
```

With the expected result:

```plain
cmd line_buffered_shell_run
exitcode: 0
--------------------------------------------------------------------------------------------------------------------------------
stdout: # line 0001 ############################################################################################################
stdout: # line 0002 ############################################################################################################
stdout: # line 0003 ############################################################################################################
--------------------------------------------------------------------------------------------------------------------------------
stderr: # line 0001 ############################################################################################################
stderr: # line 0002 ############################################################################################################
stderr: # line 0003 ############################################################################################################
================================================================================================================================
```

While using the `powershell` shell, we can see extra new lines being reported. Compare the actual output:

```plain
powershell original_shell_run
exitcode: 0
--------------------------------------------------------------------------------------------------------------------------------
stdout: # line 0001 ############################################################################################################

stdout: # line 0002 ############################################################################################################

stdout: # line 0003 ############################################################################################################

================================================================================================================================
```

With the expected result:

```plain
powershell line_buffered_shell_run
exitcode: 0
--------------------------------------------------------------------------------------------------------------------------------
stdout: # line 0001 ############################################################################################################
stdout: # line 0002 ############################################################################################################
stdout: # line 0003 ############################################################################################################
```

The expected results we normalized by `line_buffered_shell_run` function, which implements my expected results.

That function essentially buffers the command output and only emit complete lines to its caller.

To execute the whole example:

1. In the target machine:
    1. Install Python 3.6 at `C:\Python36`.
    1. Copy the `emit-partial-output.py` file to the target machine `C:\` directory.
2. In the client machine:
    1. Install Ruby 2.7.0 and the WinRM gem 2.3.6.
    1. Set the target machine credentials in `main.rb`.
    1. Execute `main.rb`.

Please note that you might need to fiddle with the `main.rb` to make it misbehave in your machine. This is the line you want to modify:

```ruby
command = 'C:/Python36/python.exe c:/emit-partial-output.py --lines 3 --length 120 --flush'
```
