#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 10 sep 2014 - nasim.ansari (at) gmail.com
# usages:
# ./check_file_age.py -d /dest/dir/name/ -c 300 -w 180
# - nagios plugin to aler if age of oldest file in directory is more than given time
# - time arguments to 1w and -c is in seconds
# - it takes 6 arguments
# - argument orders should be same a per above example
# - if no file in destination directory, it will return OK


import os
import time
import sys

# there should be six argument to script
if not len(sys.argv) == 7:
  print "CRITICAL: script needs exactly six arguments"
  print "Example: " + os.sys.argv[0] + " -d /dest/dir/name/ -c 300 -w 180"
  os.sys.exit(2)

# check if directory has been provided : -d </dest/dir/name/>
if os.sys.argv[1] == "-d" and os.path.isdir(os.sys.argv[2])  :
#    try :
        destdir = os.sys.argv[2]
        # create list of all file names in given directory
        files = [ f for f in os.listdir(destdir) if os.path.isfile(os.path.join(destdir,f)) ]
        # check if there is a file in directory
        if not files:
          print "OK: no file in " + os.sys.argv[2] + " to check file age"
          os.sys.exit(0)
#    except:
#        print "UNKNOWN: Could not open any files."
#        os.sys.exit(3)
else :
    print "CRITICAL: Could you please provide a valid directory?"
    os.sys.exit(2)

# Check if time in seocnds has been provioded : -c 300 -w 180
if os.sys.argv[3] == "-c" and isinstance( int(os.sys.argv[4]) , int )  :
  critical_time = int(os.sys.argv[4])
else:
  print "CRITICAL: argument for -c should be integer to denote critical time in seconds"
  os.sys.exit(2)

if os.sys.argv[5] == "-w" and isinstance(int(os.sys.argv[6]) , int )  :
  warning_time = int(os.sys.argv[6])
else:
  print "CRITICAL: argument for -w should be integer to denote warning time in seconds"
  os.sys.exit(2)

# warning_time should be less than critical time
if warning_time > critical_time :
  print "CRITICAL: Script configuration is wrong. warning time should not be grater that critical time"
  os.sys.exit(2)

# check each file creation time against time provided -w and -c time
#print files
for f in files :
    f = os.sys.argv[2] + f
    # print f
    if os.stat(f)[-1] < ( time.time() - critical_time ) :
        print "CRITICAL: File is older then " + str(critical_time) + " seconds"
        os.sys.exit(2)
    elif os.stat(f)[-1] < ( time.time() - warning_time ) :
        print "WARNING: File is older then " + str(warning_time) + " seconds"
        os.sys.exit(1)
    else :
        print "OK: No file older than " + str(warning_time) + " seconds"
        os.sys.exit(0)
