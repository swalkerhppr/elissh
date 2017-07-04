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

Use `eli -h` for more options

Building
========

Install elixir and clone this repository. Cd to the repo and run `mix get.deps` then `mix escript.build`. This should create the `eli` executable in the same directory.

