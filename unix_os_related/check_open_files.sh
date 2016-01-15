#!/bin/bash
#set -xv
# Nagios Plugin to check openfiles by a program and it's child processes
# nasim.ansari  at gmail dit com: 30 Sep 2011
#
#  requirement :  /usr/sbin/lsof should be allowed in /etc/sudoers for nrpe user
#
# Valid Options:
# -p ProgramName        : program name or string listed in ps -ef
# -W ProgramWarlevel    : Number of FD for Program Warning Level
# -C ProgramCriticlevel : Number of FD for Program Critical level
# -w ProgramWarlevel    : Number of FD for Program Warning Level
# -c ProgramCriticlevel : Number of FD for Program Critical level
#
#
# Exit Status
okExit=0
warningExit=1
criticalExit=2
unknownExit=3

MESSAGE=""

# Command Variable
AWK=/bin/awk
LSOF=/usr/sbin/lsof
SUDO=/usr/bin/sudo


# Syntax for this script
function printhelp {
echo
echo 'This script is to check open file by a program and its Child process.'
echo "Usages: $0 -p ProgramName -W ProgramWarningLevel -C ProgramCriticalLevel -w ChildProgramWarningLevel -c ChildProgramCriticalLevel"
echo 'Where:
        -p ProgramName                  : Program Name for which check need to be performed. Mandatory. ALL for each running process
        -W ProgramWarningLevel          : Programs Warning Level (def : 400)
        -C ProgramCriticalLevel         : Programs Critical Level (def : 512)
        -w ChildProgramWarningLevel     : Warning Level for any child of program (def : 400)
        -c ChildProgramCriticalLevel    : Critical Level for any child of program (def : 512)
Examples:
/opt/nrpe/plugins/check_open_files.sh -p ALL -W 170 -C 200
/opt/nrpe/plugins/check_open_files.sh -p java -W 820 -C 920 -w 820 -c 920
/opt/nrpe/plugins/check_open_files.sh -p httpd -W 150 -C 171 -w 150 -c 171
'
exit $unknownExit
}

# Let's validate command line parameters

while getopts "hp:W:C:w:c:" optionName; do
   case "$optionName" in
        p) ProgName="$OPTARG";;
        W) ProgWlevel="$OPTARG";;
        C) ProgClevel="$OPTARG";;
        w) SubProgWlevel="$OPTARG";;
        c) SubProgClevel="$OPTARG";;
        *) printhelp;;
   esac
done

# Programe name is mandatory option
[ -z "$ProgName" ] && printhelp

# Set default values
[ -z "$ProgWlevel" ] && ProgWlevel=400
[ -z "$ProgClevel" ] && ProgClevel=512
[ -z "$SubProgWlevel" ] && SubProgWlevel=400
[ -z "$SubProgClevel" ] && SubProgClevel=512

# Enable this if you are debugging
#echo -n "Running ...: "
#echo $0 -p $ProgName -W $ProgWlevel -C $ProgClevel -w $SubProgWlevel -c $SubProgClevel


# Get the PID of program(s)
if [ $ProgName = ALL ];then
PidOfProg="`ps -ef|grep -Ewv "grep|$0"|awk '{print $2}'|/usr/bin/tr '\n' ' '`"
else
PidOfProg="`ps -ef|grep $ProgName|grep -Ewv "grep|$0"|awk '{print $2}'|/usr/bin/tr '\n' ' '`"
fi
[ -z "$PidOfProg" ] && echo "CRITICAL: Not able to determine PID of $ProgName" && exit $criticalExit

# Collect lsof output in /var/tmp
lsoffile=/var/tmp/lsoffile.$$
$SUDO $LSOF >$lsoffile

[ ! -s $lsoffile ] && echo 'CRITICAL : /usr/sbin/lsof should be allowed in /etc/sudoers for nrpe user.' && exit $criticalExit

# Let's check how many files are opened by ParentsPid
MESSAGE=""
for ParentPid in $PidOfProg ; do
   [ $ProgName = ALL ] || ChildProcPIDs="`ps -ef| awk -v pid=$ParentPid '$3 == pid {print $2}'`"
   NoOfOpenFiles="`awk -v pid=$ParentPid '$2 == pid ' $lsoffile|wc -l`"
       if [ $NoOfOpenFiles -ge $ProgClevel ] ;then
          MESSAGE="$MESSAGE PID $ParentPid has $NoOfOpenFiles open files."
          CRITICAL=yes
       elif [ $NoOfOpenFiles -ge $ProgWlevel ] ;then
          MESSAGE="$MESSAGE PID $ParentPid has $NoOfOpenFiles open files."
          [ x$CRITICAL != xyes ] && WARNING=yes
       else
          [ x$CRITICAL != xyes ] && [ x$WARNING != xyes ] && OK=yes
       fi
done
if [ $ProgName != ALL ];then
# Let's check for Child processes
 if [ ! -z "$ChildProcPIDs" ];then
    for ChildPid in $ChildProcPIDs ; do
     NoOfOpenFiles="`awk -v pid=$ChildPid '$2 == pid ' $lsoffile|wc -l`"
       if [ $NoOfOpenFiles -ge $SubProgClevel ] ;then
          MESSAGE="$MESSAGE ChildPid $ChildPid : $NoOfOpenFiles "
          CRITICAL=yes
       elif [ $NoOfOpenFiles -ge $SubProgWlevel ] ;then
          MESSAGE="$MESSAGE ChildPid $ChildPid : $NoOfOpenFiles "
          [ x$CRITICAL != xyes ] && WARNING=yes
       fi
   done
 fi
fi

# Remove lsof on each run
[ -f $lsoffile ] && rm -f $lsoffile

# Display Message and exit with correct exit status
[ "$CRITICAL" = yes ] && echo "CRITICAL: $MESSAGE"  && exit $criticalExit
[ "$WARNING" = yes  ] && echo "WARNING: $MESSAGE"  && exit $warningExit
[ "$OK" = yes  ] && echo "OK: Number of open file of $ProgName process are within limits."  && exit $okExit
# End of script
