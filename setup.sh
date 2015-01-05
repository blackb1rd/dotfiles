use strict;
use warnings;

if (`tput colors` != 256) {
    system('apt-get install ncurses-term');
    open  FILE ,">>~/.bashrc";
    print FILE "\nexport TERM=xterm-256color";
    close FILE;
    system('source ~/.bashrc');
}
print "check 256 color mode completed\n";
