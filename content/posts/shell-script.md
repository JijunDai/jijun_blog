---
title: "Shell script collection"
author: "Jijun Dai"
date: 2022-12-10T20:12:56-05:00
draft: true
tags:
- development
- script
- shell
---

## awk examples

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

---

## Linux Web服务器网站故障分析常用的命令

### 1.查看TCP连接状态

```shell
netstat -nat |awk ‘{print $6}’|sort|uniq -c|sort -rn

netstat -n | awk ‘/^tcp/ {++S[$NF]};END {for(a in S) print a, S[a]}’ 或
netstat -n | awk ‘/^tcp/ {++state[$NF]}; END {for(key in state) print key,"\t",state[key]}’
netstat -n | awk ‘/^tcp/ {++arr[$NF]};END {for(k in arr) print k,"t",arr[k]}’

netstat -n |awk ‘/^tcp/ {print $NF}’|sort|uniq -c|sort -rn

netstat -ant | awk ‘{print $NF}’ | grep -v ‘[a-z]‘ | sort | uniq -c
```

### 2.查找请求数请20个IP（常用于查找攻来源）

```shell
netstat -anlp|grep 80|grep tcp|awk ‘{print $5}’|awk -F: ‘{print $1}’|sort|uniq -c|sort -nr|head -n20

netstat -ant |awk ‘/:80/{split($5,ip,":");++A[ip[1]]}END{for(i in A) print A[i],i}’ |sort -rn|head -n20
```

### 3.用tcpdump嗅探80端口的访问看看谁最高

`tcpdump -i eth0 -tnn dst port 80 -c 1000 | awk -F"." ‘{print $1"."$2"."$3"."$4}’ | sort | uniq -c | sort -nr |head -20`

### 4.查找较多time_wait连接

`netstat -n|grep TIME_WAIT|awk ‘{print $5}’|sort|uniq -c|sort -rn|head -n20`

### 5.找查较多的SYN连接

`netstat -an | grep SYN | awk ‘{print $5}’ | awk -F: ‘{print $1}’ | sort | uniq -c | sort -nr | more`

### 6.根据端口列进程

`netstat -ntlp | grep 80 | awk ‘{print $7}’ | cut -d/ -f1`

## 网站日志分析篇1（Apache）

### 1.获得访问前10位的ip地址

```shell
cat access.log|awk ‘{print $1}’|sort|uniq -c|sort -nr|head -10
cat access.log|awk ‘{counts[$(11)]+=1}; END {for(url in counts) print counts[url], url}’
```

### 2.访问次数最多的文件或页面,取前20

`cat access.log|awk ‘{print $11}’|sort|uniq -c|sort -nr|head -20`

### 3.列出传输最大的几个exe文件（分析下载站的时候常用）

`cat access.log |awk ‘($7~/.exe/){print $10 " " $1 " " $4 " " $7}’|sort -nr|head -20`

### 4.列出输出大于200000byte(约200kb)的exe文件以及对应文件发生次数

`cat access.log |awk ‘($10 > 200000 && $7~/.exe/){print $7}’|sort -n|uniq -c|sort -nr|head -100`

### 5.如果日志最后一列记录的是页面文件传输时间，则有列出到客户端最耗时的页面

`cat access.log |awk ‘($7~/.php/){print $NF " " $1 " " $4 " " $7}’|sort -nr|head -100`

### 6.列出最最耗时的页面(超过60秒的)的以及对应页面发生次数

`cat access.log |awk ‘($NF > 60 && $7~/.php/){print $7}’|sort -n|uniq -c|sort -nr|head -100`

### 7.列出传输时间超过 30 秒的文件

`cat access.log |awk ‘($NF > 30){print $7}’|sort -n|uniq -c|sort -nr|head -20`

### 8.统计网站流量（G)

`cat access.log |awk ‘{sum+=$10} END {print sum/1024/1024/1024}’`

### 9.统计404的连接

`awk ‘($9 ~/404/)’ access.log | awk ‘{print $9,$7}’ | sort`

### 10.统计http status

`cat access.log |awk ‘{counts[$(9)]+=1}; END {for(code in counts) print code, counts[code]}'`
`cat access.log |awk '{print $9}'|sort|uniq -c|sort -rn`

### 11.蜘蛛分析，查看是哪些蜘蛛在抓取内容

`/usr/sbin/tcpdump -i eth0 -l -s 0 -w - dst port 80 | strings | grep -i user-agent | grep -i -E 'bot|crawler|slurp|spider'`

## 网站日分析2(Squid篇）按域统计流量

`zcat squid_access.log.tar.gz| awk '{print $10,$7}' |awk 'BEGIN{FS="[ /]"}{trfc[$4]+=$1}END{for(domain in trfc){printf "%st%dn",domain,trfc[domain]}}'`

## 数据库篇

### 1.查看数据库执行的sql

`/usr/sbin/tcpdump -i eth0 -s 0 -l -w - dst port 3306 | strings | egrep -i 'SELECT|UPDATE|DELETE|INSERT|SET|COMMIT|ROLLBACK|CREATE|DROP|ALTER|CALL'`

## Shell script snippet

 记录日志的一个函数，这个很有用，朋友们可以直接用在自己的脚本中。

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

```shell
   repeat() { while :; do $@ && return; sleep 30 done }
```

Though not as readable, this is certainly faster than the first approach.

In order to list out the opened ports from the current machine, use:

```shell
 lsof -i | grep ":[0-9]\+->" -o | grep "[0-9]\+" -o  | sort | uniq
```

## Code from *bash cook*

```shell
#!/usr/bin/env bash

# Use a : NOOP and here document to embed documentation,
: <<'END_OF_DOCS'
# replace the semi with a blank
NEWPATH=${PATH/;/ }
#
# switch the text on either side of a semi
sed -e 's/^\(.*\);\(.*\)$/\2;\1/' < $FILE

    Embedded documentation here
    [...]
    $* ${@} $#
    ${#} with ${#VAR} or even ${VAR#alt}
    FILEDIR=${1:-"/tmp"}
    ${VAR:=value} and ${VAR:-value} and ${HOME=/tmp}
    More Than Just a Constant String for Default: ${BASE:="$(pwd)"}
    Command substitution: $( cmds )
    Arithmeticexpansion: $((...))   ex: echo ${BASE:=/home/uid$((ID+1))}

    # cookbook filename: check_unset_parms
    #
    USAGE="usage: myscript scratchdir sourcefile conversion"
    FILEDIR=${1:?"Error. You must supply a scratch directory."}
    FILESRC=${2:?"Error. You must supply a source file."}
    CVTTYPE=${3:?"Error. ${USAGE}. $(rm $SCRATCHFILE)"}

    inside ${ ... }             Action taken

    name:number:number          Substring starting character, length
    #name                       Return the length of the string
    name#pattern                Remove (shortest) front-anchored pattern
    name##pattern               Remove (longest) front-anchored pattern
    name%pattern                Remove (shortest) rear-anchored pattern
    name%%pattern               Remove (longest) rear-anchored pattern
    name/pattern/string         Replace first occurrence
    name//pattern/string        Replace all occurrences

    Try them all. They are very handy.

    #array of variables
    MYRA=(first second third home)
    ${MYRA[0]} and ${MYRA[2]}

    # some examples
    if [ $# -lt 3 ]  vs  if (( $# < 3 ))
    if [ -r "$FN" -a \( -f "$FN" -o  -p "$FN" \) ]
    if [ -z "$V1" -o -z "${V2:=YIKES}" ]
    Use the -eq operator for numeric comparisons and the equality primary = (or ==) for string comparisons.

    Use the double-bracket compound statement in an if statement to enable shell-style pattern matches 
    on the righthand side of the equals operator:
     if [[ "${MYFILENAME}" == *.jpg ]]

    shopt -s extglob
     if [[ "$FN" == *.@(jpg|jpeg) ]]
     then
    # and so on
    Grouping symbols for extended pattern-matching
    @( ... )           Only one occurrence
    *( ... )           Zero or more occurrences   
    +( ... )           One or more occurrences
    ?( ... )           Zero or one occurrences
    !( ... )           Not these occurrences, but anything else

Sometimes even the extended pattern matching of the extglob option isn’t enough.
What you really need are regular expressions.
# bash version >= 3.0
     for CDTRACK in *
     do
         if [[ "$CDTRACK" =~ "([[:alpha:][:blank:]]*)- ([[:digit:]]*) - (.*)$" ]]
         then
             echo Track ${BASH_REMATCH[2]} is ${BASH_REMATCH[3]}
             mv "$CDTRACK" "Track${BASH_REMATCH[2]}"
         fi
     done
The subexpressions, each enclosed in parentheses, are used to populate the bash built-in array
variable $BASH_REMATCH. The zeroth element ($BASH_REMATCH[0]) is the entire string matched by
the regular expression. Any subexpressions are available as $BASH_REMATCH[1], $BASH_REMATCH[2], and so on.

while (( 1 ))
{
...
}

                while read lineoftext
                do
                  process that line
                done < file.input
# or --------------------------------------
                cat file.input | \
                while read lineoftext
                do
                  process that line
                done

# Like C Language, but with double parentheses:
$ for (( i=0 ; i < 10 ; i++ )) ; do echo $i ; done
# Looping with Floating-Point Values
for fp in $(seq 1.0 .01 1.1) ; do ...; done

$ grep 'Dec [0-9 ][0-9]' logfile
It’s good to get into the habit of
using single quotes around anything that might possibly be confusing to the shell.
Another mechanism we want to introduce is a repetition mechanism written as \{n,m\}
where n is the minimum number of repetitions and m is the maximum.
If it is written as \{n\} it means “exactly n times,” and when written as “\{n,\}” then “at least n times.”

$ find . -name '*.mp3' -print0 | xargs -i -0 mv '{}' ~/songs
$ find some_directory -type f -print0 | xargs -0 chmod 0644
$ find . -follow -name '*.mp3' -print0 | xargs -i -0 mv '{}' ~/songs
$ find . -mtime +7 -a -mtime -14 -print
$ find . -mtime +14 -name '*.text' -o \( -mtime -14 -name '*.txt' \) -print

for path in ${PATH//:/ } /opt/foo/bin /opt/bar/bin; do
[ -x "$path/ls" ] && $path/ls
done

nohup mydaemonscript  0<&-  1>/dev/null  2>&1  &
##or:
nohup mydaemonscript  >>/var/log/myadmin.log  2>&1  <&-  &

## Parsing Output into an Array
LSL=$(ls -ld $1)
declare -a MYRA
MYRA=($LSL)
echo the file $1 is ${MYRA[4]} bytes.

for ((i=0; i < ${#ALINE}; i++))
do
ACHAR=${ALINE:i:1}
# do something here, e.g. echo $ACHAR
done

svn status src | grep '^\?' | cut -c8- | \
while read fn; do echo "$fn"; rm -rf "$fn"; done

END_OF_DOCS

: <<'SEEING_ALL_VARIABLE_VALUES'
Use the set command to see the value of all variables and function definitions in the current shell.
Use the env (or export -p) command to see only those variables that have been exported
and would be available to a subshell.
SEEING_ALL_VARIABLE_VALUES

###Trapping Interrupts
function trapped {
if [ "$1" = "USR1" ]; then
echo "Got me with a $1 trap!"
exit else
echo "Received $1 trap--neener, neener"
fi
}
trap "trapped ABRT" ABRT
trap "trapped EXIT" EXIT
trap "trapped HUP"  HUP
trap "trapped INT"  INT
trap "trapped KILL" KILL
trap "trapped QUIT" QUIT
trap "trapped TERM" TERM
trap "trapped USR1" USR1
# This won't actually work
# This one is special
    # Just hang out and do nothing, without introducing "third-party"
    # trap behavior, such as if we used 'sleep'
while (( 1 )); do
:   # : is a NOOP
done
```

---

## Case 1: initial linux system

```shell
#/bin/bash
# 设置时区并同步时间
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
if ! crontab -l |grep ntpdate &>/dev/null ; then
    (echo "* 1 * * * ntpdate time.windows.com >/dev/null 2>&1";crontab -l) |crontab 
fi

# 禁用selinux
sed -i '/SELINUX/{s/permissive/disabled/}' /etc/selinux/config

# 关闭防火墙
if egrep "7.[0-9]" /etc/redhat-release &>/dev/null; then
    systemctl stop firewalld
    systemctl disable firewalld
elif egrep "6.[0-9]" /etc/redhat-release &>/dev/null; then
    service iptables stop
    chkconfig iptables off
fi

# 历史命令显示操作时间
if ! grep HISTTIMEFORMAT /etc/bashrc; then
    echo 'export HISTTIMEFORMAT="%F %T `whoami` "' >> /etc/bashrc
fi

# SSH超时时间
if ! grep "TMOUT=600" /etc/profile &>/dev/null; then
    echo "export TMOUT=600" >> /etc/profile
fi

# 禁止root远程登录
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# 禁止定时任务向发送邮件
sed -i 's/^MAILTO=root/MAILTO=""/' /etc/crontab 

# 设置最大打开文件数
if ! grep "* soft nofile 65535" /etc/security/limits.conf &>/dev/null; then
    cat >> /etc/security/limits.conf << EOF
    * soft nofile 65535
    * hard nofile 65535
    EOF
fi

# 系统内核优化
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_tw_buckets = 20480
net.ipv4.tcp_max_syn_backlog = 20480
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_fin_timeout = 20  
EOF

# 减少SWAP使用
echo "0" > /proc/sys/vm/swappiness

# 安装系统性能分析工具及其他
yum install gcc make autoconf vim sysstat net-tools iostat iftop iotp lrzsz -y
```

## Case 2: Get system resource

```shell
#!/bin/bash
function cpu() {
    NUM=1
    while [ $NUM -le 3 ]; do
        util=`vmstat |awk '{if(NR==3)print 100-$15"%"}'`
        user=`vmstat |awk '{if(NR==3)print $13"%"}'`
        sys=`vmstat |awk '{if(NR==3)print $14"%"}'`
        iowait=`vmstat |awk '{if(NR==3)print $16"%"}'`
        echo "CPU - 使用率: $util , 等待磁盘IO响应使用率: $iowait"
        let NUM++
        sleep 1
    done
}

function memory() {
    total=`free -m |awk '{if(NR==2)printf "%.1f",$2/1024}'`
    used=`free -m |awk '{if(NR==2) printf "%.1f",($2-$NF)/1024}'`
    available=`free -m |awk '{if(NR==2) printf "%.1f",$NF/1024}'`
    echo "内存 - 总大小: ${total}G , 使用: ${used}G , 剩余: ${available}G"
}

function disk() {
    fs=$(df -h |awk '/^\/dev/{print $1}')
    for p in $fs; do
        mounted=$(df -h |awk '$1=="'$p'"{print $NF}')
        size=$(df -h |awk '$1=="'$p'"{print $2}')
        used=$(df -h |awk '$1=="'$p'"{print $3}')
        used_percent=$(df -h |awk '$1=="'$p'"{print $5}')
        echo "硬盘 - 挂载点: $mounted , 总大小: $size , 使用: $used , 使用率: $used_percent"
    done
}

function tcp_status() {
    summary=$(ss -antp |awk '{status[$1]++}END{for(i in status) printf i":"status[i]" "}')
    echo "TCP连接状态 - $summary"
}
```

## Case 3: Check servers' disk usage

```shell
#!/bin/bash
HOST_INFO=host.info
for IP in $(awk '/^[^#]/{print $1}' $HOST_INFO); do
    USER=$(awk -v ip=$IP 'ip==$1{print $2}' $HOST_INFO)
    PORT=$(awk -v ip=$IP 'ip==$1{print $3}' $HOST_INFO)
    TMP_FILE=/tmp/disk.tmp
    ssh -p $PORT $USER@$IP 'df -h' > $TMP_FILE
    USE_RATE_LIST=$(awk 'BEGIN{OFS="="}/^\/dev/{print $NF,int($5)}' $TMP_FILE)
    for USE_RATE in $USE_RATE_LIST; do
        PART_NAME=${USE_RATE%=*}
        USE_RATE=${USE_RATE#*=}
        if [ $USE_RATE -ge 80 ]; then
            echo "Warning: $PART_NAME Partition usage $USE_RATE%!"
        fi
    done
done
```
