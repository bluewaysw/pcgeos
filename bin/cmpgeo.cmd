@rem = '-*- Perl -*-';
@rem = '
@echo off

perl -S cmpgeo.cmd %1 %2 %3 %4 %5 %6 %7 %8 %9

goto endofperl
';

#
# Include files.  Perl will first look for the files in the local GEOS
# tree, if it is run from one.
#
if ( $ENV{"OS"} eq "Windows_NT" ) { # NT version
    require Win32;
    require Win32::Process;
    require "$ENV{ROOT_DIR}/Tools/scripts/perl/lib/include.pl";
} else {			# Unix version
    require "/staff/pcgeos/Tools/scripts/perl/lib/include.pl";
}

&Include("Tools/scripts/perl/diffgeo.pl");

-e $ARGV[0] or die "Unable to open $ARGV[0]!\n";
-e $ARGV[1] or die "Unable to open $ARGV[1]!\n";
if (compare($ARGV[0], $ARGV[1]) eq true) {
    print "\nFiles are different!\n";
} else {
    print "\nFiles are identical\n";
}

__END__
:endofperl



