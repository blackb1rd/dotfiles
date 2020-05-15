#!/bin/sh

TR_OPTS="-n transmission:transmission"

tsmdaemonstart()  { sudo service transmission-daemon start;}
tsmdaemonstop()   { sudo service transmission-daemon stop;}
tsmdaemonreload() { sudo service transmission-daemon reload;}
tsmstart()         { transmission-remote "${TR_OPTS}" -t "$1" -s;}
tsmstop()          { transmission-remote "${TR_OPTS}" -t "$1" -s;}
tsmadd()           { transmission-remote "${TR_OPTS}" -a "$1";}
tsmremove()        { transmission-remote "${TR_OPTS}" -t "$1" -r;}
tsmlist()          { transmission-remote "${TR_OPTS}" -l;}
tsminfo()          { transmission-remote "${TR_OPTS}" -t "$1" -i;}
tsmbasicstats()    { transmission-remote "${TR_OPTS}" -st;}
tsmfullstats()     { transmission-remote "${TR_OPTS}" -si;}
