# nagios_plugins

DETAILS of nagios_plugins

>>> unix_os_related/check_open_files.sh
Nagios Plugin to check openfiles by a program and it's child processes
  requirement :  /usr/sbin/lsof should be allowed in /etc/sudoers for nrpe user

 Valid Options:
 -p ProgramName        : program name or string listed in ps -ef
 -W ProgramWarlevel    : Number of FD for Program Warning Level
 -C ProgramCriticlevel : Number of FD for Program Critical level
 -w ProgramWarlevel    : Number of FD for Program Warning Level
 -c ProgramCriticlevel : Number of FD for Program Critical level


>>> veritas_monitoring/check_veritas_health.sh

 nagios plugin to monitor veritas componentsi by looking output of below command
 - cluster status
 - vxprint output
 - hastatus -sum output


