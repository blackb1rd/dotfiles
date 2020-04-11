#!/bin/sh

TR_OPTS="-n transmission:transmission"

TsmDaemonStart()  { sudo service transmission-daemon start;}
TsmDaemonStop()   { sudo service transmission-daemon stop;}
TsmDaemonReload() { sudo service transmission-daemon reload;}
TsmStart()         { transmission-remote "${TR_OPTS}" -t "$1" -s;}
TsmStop()          { transmission-remote "${TR_OPTS}" -t "$1" -s;}
TsmAdd()           { transmission-remote "${TR_OPTS}" -a "$1";}
TsmRemove()        { transmission-remote "${TR_OPTS}" -t "$1" -r;}
TsmList()          { transmission-remote "${TR_OPTS}" -l;}
TsmInfo()          { transmission-remote "${TR_OPTS}" -t "$1" -i;}
TsmBasicstats()    { transmission-remote "${TR_OPTS}" -st;}
TsmFullstats()     { transmission-remote "${TR_OPTS}" -si;}
