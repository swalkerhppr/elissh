Elissh
=========
A command line utility configured with yaml written in elixir to run commands on many seperate hosts

Config File
==========
The default file is ./hosts.yml, but it may be passed in using the -c argument. It is a list of groups and hosts under the groups. You can send a command to all hosts in a group or all hosts with a certain name.

For example:
```
---
  lab:
    myserver: "192.168.100.2"
    web:      "192.168.100.3"
  prod:
    myserver: "192.168.100.4"
    web:      "192.168.100.5"
    dns:      "192.168.100.6"
    db:       "192.168.100.7"
```

Of course in reality group and hosts names will be more descriptive and the ip addresses will all be different (though they can be the same).

Usage
=========

To run a command on all hosts defined in the `lab` group run:

```
  eli -m 'mkdir adir' -a lab 
```

To run a command on one host defined in the `lab` group run:

```
  eli -m 'mkdir adir' lab 
```

Or just the first instance of host named `myserver`:

```
  eli -m 'mkdir adir' myserver
```

Or all instances of hosts named `myserver`:

```
  eli -m 'mkdir adir' -a myserver
```

You may also supply a username and password to connect (must be the same for all hosts)

```
  eli -m 'mkdir adir' -u auser -p mypass lab

```

If you don't supply a username with the -u flag, it assumes the user that you are running as.
If you don't supply a password with the -p flag, it asssumes that you are using ssh keys.

You may also access the name and address that you set on the particular host by using the #{name} and #{address} replacement variables:

```
  eli -m 'mkdir #{name} && touch #{name}/#{address}' -a lab
```
This would create  the  myserver/192.168.100.2 on myserver and web/192.168.100.3 on web. (see example config above)

Use `eli -h` for more options

Interactive Console
===================

To enter an interactive console run `eli -i`. The console allows you to form sets of hosts to run multiple commands on.

In the interactive console you must set the configuration using commands preceeded by '!'. The available commands are:
```
    !run_on <host|group> - add a host or group to the hosts to run on
    !reset               - reset run on hosts
    !user <username>     - set the remote username
    !password <pass>     - set the password for the remote user
    !connect             - connect to hosts to run on
    !send                - run commands on hosts
    !help                - show help
    !info                - display the map of set configurations
```

Any command that is not preceded by '!' is assumed to be a command to send to hosts.

You must run !connect before !send.

An example interactive session would be like so:
```
eli>echo A user was here! >> trace
eli>echo And here >> trace
eli>!run_on lab
eli>!run_on dns
eli>!user auser
eli>!password mypassword
eli>!connect
eli>!send
```

You may automate the running of interactive mode by running `eli -is myscript.elic`.
Each line is parsed as a line in interactive mode.
The following would produce the same results as the interactive session above:
```
echo A user was here! >> trace
echo And here >> trace
!run_on lab
!run_on dns
!user auser
!password mypassword
!connect
!send
```

Facts
==========

== Static facts

Facts can be defined in a yaml file and the file can be specified with -f flag.
The default facts file is `./facts.yml`
The format for the fact file is specified by hostname.
If a host had the same name, then it will pull from the same fact map.
An example facts.yml file:
```
---
  global_facts:
    os: "ubuntu"
  myserver: 
    default_dir:  "/tmp/data"
  web:
    default_dir:  "/home/web"
  dns:
    default_dir:  "/home/dns"
  db:
    default_dir:  "/etc/db"
```

These facts can be used in commands by using #{fact_name} in the command.
Note that if you are running a command with a fact, each host record needs to have a value for that fact or the fact should be located under the `global_facts` portion of the yaml.
Global facts will override any other facts.
An example of using facts in a command:
```
  # default_dir would evaluate to the fact that is set for each of the hosts that it is running on
  eli -m "cd #{default_dir} && echo #{os} > os_info" -a lab
```

== Dynamic facts

You may capture the output of a command and turn it into a fact by using #{>regex}.
This uses elixir regex functions to match the output of a command and extract the value that you want.
You will need to use a 'named capture' to specify the name of the fact that you want.
For example running the command `echo my name is steve #{>my name is (?<my_name>\w+)}` would set the my_name fact to steve.
In subsequent commands in the same interactive session you could run `echo "Hello, #{my_name}!" > a_file` to output Hello, steve! to a_file.  
A couple notes:

  - Only one output capture is allowed per command

  - The fact is computed AFTER the operation has finished (you can't capture and use in the same line)

  - Everything between the ${> and } are considered to be a regex.

  - Dynamic facts are not saved between sessions. Their use should be limited to interactive mode and interactive scripts.

  - Dynamic facts are computed per host. If the output is different on different hosts, the fact will reflect the difference.

For example:
```
  eli -i
  eli>!user auser
  eli>!run_on lab
  eli>!connect
  eli>cat /proc/meminfo #{>MemTotal:\s+(?<memory>.*)}
  eli>echo #{memory} > my_mem
  eli>!send 
```
would retrieve the MemTotal from /proc/meminfo and put the value in a file named my_mem on each of the lab hosts

== name and address

The name and address values hold the information stored in the hosts.yml file. They can be retrieved like static facts:
```
  eli -m "echo my name is #{name} and my address is #{address}" dns
```

Take care not to override these values because any value that is set with the same name will overwrite them.

Building
========

Install elixir and clone this repository. Cd to the repo and run `mix get.deps` then `mix escript.build`. This should create the `eli` executable in the same directory.

