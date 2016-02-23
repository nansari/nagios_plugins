#!/bin/bash
# nasim.ansari (at) gmail.com - 06-Mar-2014
# nagios plugin to monitor veritas componentsi by looking output of below command
# - cluster status
# - vxprint output
# - hastatus -sum output

PATH=$PATH:/sbin:/usr/bin:/bin:/opt/VRTSvcs/bin

# Nagios Exit Status
okExit=0
criticalExit=2
#warningExit=1
#unknownExit=3

MSG=""
STATUS=0


# check all required binaries are present

if [ ! -f /opt/VRTSvcs/bin/haclus ]; then
       STATUS=$criticalExit
       MSG="$MSG /opt/VRTSvcs/bin/haclus"
fi

if [ ! -f /sbin/lltstat ]; then
       STATUS=$criticalExit
       MSG="$MSG /sbin/lltstat"
fi

if [ ! -f /sbin/vxprint ]; then
       STATUS=$criticalExit
       MSG="$MSG /sbin/vxprint"
fi

if [ ! -f /opt/VRTSvcs/bin/hastatus ]; then
       STATUS=$criticalExit
       MSG="$MSG /opt/VRTSvcs/bin/hastatus"
fi


# If any executables are not present the check cannot continue
if [ "$STATUS" != "$okExit"  -o  "$MSG" != "" ]; then
       echo "VCS P1 CRITICAL: Missing command(s):$MSG"
       exit $STATUS
fi


# check llt status - if there is any line not containing OPEN State - it is problem

if [ $(/sbin/lltstat -nv configured|grep [0-9]|grep -vc OPEN) -eq 0 ];then
       MSG="$MSG lltstat -nv is OK."
else
       STATUS=$(($criticalExit + $STATUS))
       MSG=" Problem with lltstat -nv output.$MSG"
fi


# Check local and remote cluster status
# if there is any uncommented line without word RUNNING - it is problem

if [ $(/opt/VRTSvcs/bin/haclus -state |grep -Evc "RUNNING|^#") -eq 0 ];then
       MSG="$MSG haclus -state is OK."
else
       STATUS=$criticalExit
       MSG=" Problem with haclus -state output.$MSG"
fi

# Check vxprint output - if anything disabled failed detached etc. - it is problem

if [ $(/sbin/vxprint -h|grep -cE "DISABLED|DETACHED|IOFAIL|LFAILED") -eq 0 ]; then
       MSG="$MSG vxprint output is OK."
else
       STATUS=$criticalExit
       MSG=" Check for DISABLED DETACHED IOFAIL LFAILED in vxprint -h output.$MSG"
fi



# check for hastatus -sum output - if anything partial of faulted - it is problem

if [ $(/opt/VRTSvcs/bin/hastatus -sum |grep -Ec "FAULTED|PARTIAL|EXITED|UNKNOWN") -eq 0 ];then
       MSG="$MSG hastatus -sum output is OK."
else
       STATUS=$criticalExit
       MSG=" Check for FAULTED PARTIAL EXITED UNKNOWN in hastatus -sum output.$MSG"
fi


# Print final message and final exit status
[ $STATUS -eq 0 ] && MSG="VCS OK:$MSG" || MSG="VCS P1 CRITICAL:$MSG"
echo $MSG
exit $STATUS

