TR_OPTS="-n transmission:transmission"

tsm-daemon-start()  { sudo service transmission-daemon start;}
tsm-daemon-stop()   { sudo service transmission-daemon stop;}
tsm-daemon-reload() { sudo service transmission-daemon reload;}
tsm-start()         { transmission-remote ${TR_OPTS} -t "$1" -s;}
tsm-stop()          { transmission-remote ${TR_OPTS} -t "$1" -s;}
tsm-add()           { transmission-remote ${TR_OPTS} -a "$1";}
tsm-remove()        { transmission-remote ${TR_OPTS} -t "$1" -r;}
tsm-list()          { transmission-remote ${TR_OPTS} -l;}
tsm-info()          { transmission-remote ${TR_OPTS} -t "$1" -i;}
tsm-basicstats()    { transmission-remote ${TR_OPTS} -st;}
tsm-fullstats()     { transmission-remote ${TR_OPTS} -si;}
