@rem = '-*- Perl -*-';
@rem = '
@echo off
@echo replace color8 with color4
perl color8.cmd %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
';

use File::Copy;
use File::Find;

find (\&goh, '.');

sub goh {
    if (/.*\.goh/) {
	@files = ($_,@files);
    }
    ($File::Find::prune=1 );

}

foreach $file (@files) {

    copy ($file, $file.".old");
    open (OLDGPFILE,$file.".old");
    open (NEWGPFILE,">".$file);

    while (<OLDGPFILE>) {
	s/(.*)(color8)(.*)/$1color4$3/;
	print NEWGPFILE $_;
    }

    close (OLDGPFILE);
    $_ = $file.".old";
    unlink;
}

__END__
:endofperl
