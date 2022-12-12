---
title: "Some tips about shell script"
author: "Jijun Dai"
date: 2022-12-10T20:12:56-05:00
draft: true
tags:
- development
- script
---

```bash
awk -F: '{$3>1000?usertype="Not system user":usertype="systemID";printf "%-15s:%s\n",$1,usertype}' /etc/passwd

awk -F: '$3>1000{print $1,$3}' /etc/passwd

awk -F: '$NF=="/bin/bash"{print $1,$NF}' /etc/passwd

awk -F: '$NF~/bash$/{print $1,$NF}' /etc/passwd

awk -F: '/^nobody/,/^root/{print $1}' /etc/passwd

awk -F: '{if($NF~/bash$/) print $1,$3}' /etc/passwd
awk -F: '{if($NF~/bash$/) {print $1,$3} else {print $NF}}' /etc/passwd

awk '/^[[:space:]]*linux16/{i=1;while(i<NF) {print $i,length($i); i++}}' /etc/grub2.cfg
awk '/^[[:space:]]*linux16/{i=1;while(i<NF) {if(length($i)>7 {print $i,length($i)}; i++}}' /etc/grub2.cfg
awk '/^[[:space:]]*linux16/{for(i=1;i<=NF;i++) {if(length($i)>7 {print $i,length($i)}}}' /etc/grub2.cfg

awk -F: '{if($3%2 != 0 ) next;print $1,$3}' /etc/passwd
#array
netstat -tnA|awk '{state[$NF]++}END{for(i in state) {print i,state[i]}}'
awk '{ip[$1]++}END{for(i in ip) print i, ip[i]}' /var/log/httpd/access_log
```

---------------

```shell
Linux Web服务器网站故障分析常用的命令

系统连接状态篇：
1.查看TCP连接状态
netstat -nat |awk ‘{print $6}’|sort|uniq -c|sort -rn

netstat -n | awk ‘/^tcp/ {++S[$NF]};END {for(a in S) print a, S[a]}’ 或
netstat -n | awk ‘/^tcp/ {++state[$NF]}; END {for(key in state) print key,"\t",state[key]}’
netstat -n | awk ‘/^tcp/ {++arr[$NF]};END {for(k in arr) print k,"t",arr[k]}’

netstat -n |awk ‘/^tcp/ {print $NF}’|sort|uniq -c|sort -rn

netstat -ant | awk ‘{print $NF}’ | grep -v ‘[a-z]‘ | sort | uniq -c



2.查找请求数请20个IP（常用于查找攻来源）：

netstat -anlp|grep 80|grep tcp|awk ‘{print $5}’|awk -F: ‘{print $1}’|sort|uniq -c|sort -nr|head -n20

netstat -ant |awk ‘/:80/{split($5,ip,":");++A[ip[1]]}END{for(i in A) print A[i],i}’ |sort -rn|head -n20

3.用tcpdump嗅探80端口的访问看看谁最高

tcpdump -i eth0 -tnn dst port 80 -c 1000 | awk -F"." ‘{print $1"."$2"."$3"."$4}’ | sort | uniq -c | sort -nr |head -20

4.查找较多time_wait连接

netstat -n|grep TIME_WAIT|awk ‘{print $5}’|sort|uniq -c|sort -rn|head -n20

5.找查较多的SYN连接

netstat -an | grep SYN | awk ‘{print $5}’ | awk -F: ‘{print $1}’ | sort | uniq -c | sort -nr | more

6.根据端口列进程

netstat -ntlp | grep 80 | awk ‘{print $7}’ | cut -d/ -f1



网站日志分析篇1（Apache）：

1.获得访问前10位的ip地址

cat access.log|awk ‘{print $1}’|sort|uniq -c|sort -nr|head -10
cat access.log|awk ‘{counts[$(11)]+=1}; END {for(url in counts) print counts[url], url}’

2.访问次数最多的文件或页面,取前20

cat access.log|awk ‘{print $11}’|sort|uniq -c|sort -nr|head -20

3.列出传输最大的几个exe文件（分析下载站的时候常用）

cat access.log |awk ‘($7~/.exe/){print $10 " " $1 " " $4 " " $7}’|sort -nr|head -20

4.列出输出大于200000byte(约200kb)的exe文件以及对应文件发生次数

cat access.log |awk ‘($10 > 200000 && $7~/.exe/){print $7}’|sort -n|uniq -c|sort -nr|head -100

5.如果日志最后一列记录的是页面文件传输时间，则有列出到客户端最耗时的页面

cat access.log |awk ‘($7~/.php/){print $NF " " $1 " " $4 " " $7}’|sort -nr|head -100

6.列出最最耗时的页面(超过60秒的)的以及对应页面发生次数

cat access.log |awk ‘($NF > 60 && $7~/.php/){print $7}’|sort -n|uniq -c|sort -nr|head -100

7.列出传输时间超过 30 秒的文件

cat access.log |awk ‘($NF > 30){print $7}’|sort -n|uniq -c|sort -nr|head -20

8.统计网站流量（G)

cat access.log |awk ‘{sum+=$10} END {print sum/1024/1024/1024}’

9.统计404的连接

awk ‘($9 ~/404/)’ access.log | awk ‘{print $9,$7}’ | sort

10. 统计http status

cat access.log |awk ‘{counts[$(9)]+=1}; END {for(code in counts) print code, counts[code]}'
cat access.log |awk '{print $9}'|sort|uniq -c|sort -rn

10.蜘蛛分析，查看是哪些蜘蛛在抓取内容。

/usr/sbin/tcpdump -i eth0 -l -s 0 -w - dst port 80 | strings | grep -i user-agent | grep -i -E 'bot|crawler|slurp|spider'

网站日分析2(Squid篇）按域统计流量

zcat squid_access.log.tar.gz| awk '{print $10,$7}' |awk 'BEGIN{FS="[ /]"}{trfc[$4]+=$1}END{for(domain in trfc){printf "%st%dn",domain,trfc[domain]}}'

数据库篇
1.查看数据库执行的sql

/usr/sbin/tcpdump -i eth0 -s 0 -l -w - dst port 3306 | strings | egrep -i 'SELECT|UPDATE|DELETE|INSERT|SET|COMMIT|ROLLBACK|CREATE|DROP|ALTER|CALL'

系统Debug分析篇
1.调试命令
strace -p pid
2.跟踪指定进程的PID
gdb -p pid
```

--------------------

# Safer bash scripts with 'set -euxo pipefail'

Mar 16, 2015

Often times developers go about writing bash scripts the same as writing code in a higher-level language. This is a big mistake as higher-level languages offer safeguards that are not present in bash scripts by default. For example, a Ruby script will throw an error when trying to read from an uninitialized variable, whereas a bash script won’t. In this article, we’ll look at how we can improve on this.

The bash shell comes with several builtin commands for modifying the behavior of the shell itself. We are particularly interested in the [set builtin](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html), as this command has several options that will help us write safer scripts. I hope to convince you that it’s a really good idea to add `set -euxo pipefail` to the beginning of all your future bash scripts.

### set -e

The `-e` option will cause a bash script to exit immediately when a command fails. This is generally a vast improvement upon the default behavior where the script just ignores the failing command and continues with the next line. This option is also smart enough to not react on failing commands that are part of conditional statements. Moreover, you can append a command with `|| true` for those rare cases where you don’t want a failing command to trigger an immediate exit.

#### Before

```bash
#!/bin/bash

# 'foo' is a non-existing command
foo
echo "bar"

# output
# ------
# line 4: foo: command not found
# bar
#
# Note how the script didn't exit when the foo command could not be found.
# Instead it continued on and echoed 'bar'.
```

#### After

```bash
#!/bin/bash
set -e

# 'foo' is a non-existing command
foo
echo "bar"

# output
# ------
# line 5: foo: command not found
#
# This time around the script exited immediately when the foo command wasn't found.
# Such behavior is much more in line with that of higher-level languages.
```

#### Any command returning a non-zero exit code will cause an immediate exit

```bash
#!/bin/bash
set -e

# 'ls' is an existing command, but giving it a nonsensical param will cause
# it to exit with exit code 1
$(ls foobar)
echo "bar"

# output
# ------
# ls: foobar: No such file or directory
#
# I'm putting this in here to illustrate that it's not just non-existing commands
# that will cause an immediate exit.
```

#### Preventing an immediate exit

```bash
#!/bin/bash
set -e

foo || true
$(ls foobar) || true
echo "bar"

# output
# ------
# line 4: foo: command not found
# ls: foobar: No such file or directory
# bar
#
# Sometimes we want to ensure that, even when 'set -e' is used, the failure of
# a particular command does not cause an immediate exit. We can use '|| true' for this.
```

#### Failing commands in a conditional statement will not cause an immediate exit

```bash
#!/bin/bash
set -e

# we make 'ls' exit with exit code 1 by giving it a nonsensical param
if ls foobar; then
  echo "foo"
else
  echo "bar"
fi

# output
# ------
# ls: foobar: No such file or directory
# bar
#
# Note that 'ls foobar' did not cause an immediate exit despite exiting with
# exit code 1. This is because the command was evaluated as part of a
# conditional statement.
```

That’s all for `set -e`. However, `set -e` by itself is far from enough. We can further improve upon the behavior created by `set -e` by combining it with `set -o pipefail`. Let’s have a look at that next.

### set -o pipefail

The bash shell normally only looks at the exit code of the last command of a pipeline. This behavior is not ideal as it causes the `-e` option to only be able to act on the exit code of a pipeline’s last command. This is where `-o pipefail` comes in. This particular option sets the exit code of a pipeline to that of the rightmost command to exit with a non-zero status, or to zero if all commands of the pipeline exit successfully.

#### Before

```bash
#!/bin/bash
set -e

# 'foo' is a non-existing command
foo | echo "a"
echo "bar"

# output
# ------
# a
# line 5: foo: command not found
# bar
#
# Note how the non-existing foo command does not cause an immediate exit, as
# it's non-zero exit code is ignored by piping it with '| echo "a"'.
```

#### After

```bash
#!/bin/bash
set -eo pipefail

# 'foo' is a non-existing command
foo | echo "a"
echo "bar"

# output
# ------
# a
# line 5: foo: command not found
#
# This time around the non-existing foo command causes an immediate exit, as
# '-o pipefail' will prevent piping from causing non-zero exit codes to be ignored.
```

This section hopefully made it clear that `-o pipefail` provides an important improvement upon just using `-e` by itself. However, as we shall see in the next section, we can still do more to make our scripts behave like higher-level languages.

### set -u

This option causes the bash shell to treat unset variables as an error and exit immediately. Unset variables are a common cause of bugs in shell scripts, so having unset variables cause an immediate exit is often highly desirable behavior.

#### Before

```bash
#!/bin/bash
set -eo pipefail

echo $a
echo "bar"

# output
# ------
#
# bar
#
# The default behavior will not cause unset variables to trigger an immediate exit.
# In this particular example, echoing the non-existing $a variable will just cause
# an empty line to be printed.
```

#### After

```bash
#!/bin/bash
set -euo pipefail

echo "$a"
echo "bar"

# output
# ------
# line 5: a: unbound variable
#
# Notice how 'bar' no longer gets printed. We can clearly see that '-u' did indeed
# cause an immediate exit upon encountering an unset variable.
```

#### Dealing with ${a:-b} variable assignments

Sometimes you’ll want to use a [${a:-b} variable assignment](https://unix.stackexchange.com/questions/122845/using-a-b-for-variable-assignment-in-scripts/122878) to ensure a variable is assigned a default value of `b` when `a` is either empty or undefined. The `-u` option is smart enough to not cause an immediate exit in such a scenario.

```bash
#!/bin/bash
set -euo pipefail

DEFAULT=5
RESULT=${VAR:-$DEFAULT}
echo "$RESULT"

# output
# ------
# 5
#
# Even though VAR was not defined, the '-u' option realizes there's no need to cause
# an immediate exit in this scenario as a default value has been provided.
```

#### Using conditional statements that check if variables are set

Sometimes you want your script to not immediately exit when an unset variable is encountered. A common example is checking for a variable’s existence inside an `if` statement.

```bash
#!/bin/bash
set -euo pipefail

if [ -z "${MY_VAR:-}" ]; then
  echo "MY_VAR was not set"
fi

# output
# ------
# MY_VAR was not set
#
# In this scenario we don't want our program to exit when the unset MY_VAR variable
# is evaluated. We can prevent such an exit by using the same syntax as we did in the
# previous example, but this time around we specify no default value.
```

This section has brought us a lot closer to making our bash shell behave like higher-level languages. While `-euo pipefail` is great for the early detection of all kinds of problems, sometimes it won’t be enough. This is why in the next section we’ll look at an option that will help us figure out those really tricky bugs that you encounter every once in a while.

### set -x

The `-x` option causes bash to print each command before executing it. This can be a great help when trying to debug a bash script failure. Note that arguments get expanded before a command gets printed, which will cause our logs to contain the actual argument values that were present at the time of execution!

```bash
#!/bin/bash
set -euxo pipefail

a=5
echo $a
echo "bar"

# output
# ------
# + a=5
# + echo 5
# 5
# + echo bar
# bar
```

That’s it for the `-x` option. It’s pretty straightforward, but can be a great help for debugging. Next up, we’ll look at an option I had never heard of before that was suggested by a reader of this blog.

### Reader suggestion: set -E

[Traps](http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html) are pieces of code that fire when a bash script catches certain signals. Aside from the usual signals (e.g. `SIGINT`, `SIGTERM`, …), traps can also be used to catch special bash signals like `EXIT`, `DEBUG`, `RETURN`, and `ERR`. However, reader Kevin Gibbs pointed out that using `-e` without `-E` will cause an `ERR` trap to not fire in certain scenarios.

#### Before

```bash
#!/bin/bash
set -euo pipefail

trap "echo ERR trap fired!" ERR

myfunc()
{
  # 'foo' is a non-existing command
  foo
}

myfunc
echo "bar"

# output
# ------
# line 9: foo: command not found
#
# Notice that while '-e' did indeed cause an immediate exit upon trying to execute
# the non-existing foo command, it did not case the ERR trap to be fired.
```

#### After

```bash
#!/bin/bash
set -Eeuo pipefail

trap "echo ERR trap fired!" ERR

myfunc()
{
  # 'foo' is a non-existing command
  foo
}

myfunc
echo "bar"

# output
# ------
# line 9: foo: command not found
# ERR trap fired!
#
# Not only do we still have an immediate exit, we can also clearly see that the
# ERR trap was actually fired now.
```

The documentation states that `-E` needs to be set if we want the `ERR` trap to be inherited by shell functions, command substitutions, and commands that are executed in a subshell environment. The `ERR` trap is normally not inherited in such cases.

### Conclusion

I hope this post showed you why using `set -euxo pipefail` (or `set -Eeuxo pipefail`) is such a good idea. If you have any other options you want to suggest, then please let me know and I’ll be happy to add them to this list.

> https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/

### Shell script snippet

 #记录日志的一个函数，这个很有用，朋友们可以直接用在自己的脚本中。

```shell
debug(){ 

    echo `date "+%F %X"`" >> $1" >> /tmp/run.log

}
```

```shell
#!/bin/bash
       #Filename: time_take.sh
       start=$(date +%s)
       commands;
       statements;
       end=$(date +%s)
       difference=$(( end - start))
       echo Time taken to execute commands is $difference seconds.
```

```shell
repeat() { while true; do $@ && return; done }
```

A faster approach

On most modern systems, true is implemented as a binary in /bin. This means that each time the aforementioned while loop runs, the shell has to spawn a process. To avoid this, we can use the : shell built-in, which always returns an exit code 0:

```
   repeat() { while :; do $@ && return; sleep 30 done }
```

Though not as readable, this is certainly faster than the first approach.

In order to list out the opened ports from the current machine, use:

```shell
$ lsof -i | grep ":[0-9]\+->" -o | grep "[0-9]\+" -o  | sort | uniq
```

#### Version control-based backup with Git

Let's see how to use git to version control data, in this case backups:

1. In the directory which is to be backed up use:
   
   ```
          $ cd /home/data/source
   ```
   
   Let it be the directory source to be tracked.

2. Set up and initiate the remote backup directory. In the remote machine, create the backup destination directory:
   
   ```
          $ mkdir -p /home/backups/backup.git
          $ cd /home/backups/backup.git
          $ git init --bare
   ```

The following steps are to be performed in the source host machine:

1. Add user details to Git in the source host machine:
   
   ```
          $ git config --global user.name  "Sarath Lakshman"
   ```
   
   ```
          $ git config --global user.email slynux@slynux.com
   ```

2. Initiate the source directory to backup from the host machine. In the source directory in the host machine whose files are to be backed up, execute the following commands:
   
   ```
          $ git init
          Initialized empty Git repository in /home/backups/backup.git/
   ```
   
   ```
          $ git commit --allow-empty -am "Init"
          [master (root-commit) b595488] Init
   ```

3. In the source directory, execute the following command to add the remote git directory and synchronize backup:
   
   ```
      $ git remote add origin user@remotehost:/home/backups/backup.git
   ```
   
   ```
      $ git push origin master
      Counting objects: 2, done.
      Writing objects: 100% (2/2), 153 bytes, done.
      Total 2 (delta 0), reused 0 (delta 0)
      To user@remotehost:/home/backups/backup.git
   ```
   
   ```
       * [new branch]      master -> master
   ```

4. Add or remove files for Git tracking.
   
   ```
      The following command adds all files and folders in the current
      directory to the backup list:
   ```
   
   **$ git add \***
   
   We can conditionally add certain files only to the backup list as follows:
   
   ```
      $ git add *.txt
      $ git add *.py
   ```
   
   We can remove the files and folders not required to be tracked by using:
   
   **$ git rm file**
   
   It can be a folder or even a wildcard as follows:
   
   **$ git rm \*.txt**

5. Check-pointing or marking backup points.
    We can mark checkpoints for the backup with a message using the following command: **$ git commit -m "Commit Message"**
   
   We need to update the backup at the remote location at regular intervals. Hence, set up a cron job (for example, backing up every five hours):
   
   Create a file crontab entry with lines:    

```
0 */5 * * *  /home/data/backup.sh
```

​    Create a script /home/data/backup.sh as follows:

```
#!/bin/ bash
cd /home/data/source
git add .
git commit -am "Backup taken at @ $(date)"
git push
```

Now we have set up the backup system.

1. To view all backup versions:
   
   **$ git log**

2. To revert back to any previous state or version, look into the commit ID, which is a 32-character hex string. Use the commit ID with git checkout.
   
   For commit ID 3131f9661ec1739f72c213ec5769bc0abefa85a9 it will be:
   
   ```
          $ git checkout 3131f9661ec1739f72c213ec5769bc0abefa85a9
   ```
   
   To make this revert permanent:
   
   ```
          $ git commit -am "Restore @ $(date) commit ID:
          3131f9661ec1739f72c213ec5769bc0abefa85a9"
   ```
   
   In order to view the details about versions again, use:
   
   **$ git log**

3. If the working directory is broken due to some issues, we need to fix the directory with the backup at the remote location. We can recreate the contents from the backup at the remote location as follows:
   
   ```
          $ git clone user@remotehost:/home/backups/backup.git
   ```

It will create a directory backup with all contents.
