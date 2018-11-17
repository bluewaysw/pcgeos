@rem = '-*- Perl -*-';
@rem = '
@echo off

perl -S cpi.cmd %1 %2 %3 %4 %5 %6 %7 %8 %9

goto endofperl
';

#
# Perl script to copy one file from the source tree to the installed tree or
# the other way around. 
#

use Cwd;
use File::Copy;

if ($#ARGV == 0) {

    $_ = uc(getcwd());
    
    $root = uc( $ENV{ROOT_DIR} );
    $root =~ s/\\/\\\\/g;
    
    if (/.*INSTALLED+.*/) {
	s/^($root+)(\\INSTALLED)(.*)/$1$3/;
    } else {
	s/^($root+)(.*)/$1\\INSTALLED$2/;
    }
    $_ .= "\\" . $ARGV[0];

    copy($ARGV[0],$_) or die "copy failed";

} else {

    print "usage: cpi [filename]\n";

}

__END__
:endofperl

