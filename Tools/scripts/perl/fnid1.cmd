@rem = '-*- Perl -*-';
@rem = '
@echo off
perl fnid1.cmd %1 
goto endofperl
';
use File::Find;

#
# Helper progoram for fnid
#
if ($#ARGV > -1) {
	find (\&wanted, $ARGV[0]);
} else  {
	find (\&wanted, '.');
}

sub wanted {
	if (-f) {
		@args = ("p4","files",$_);
		$res = system(@args);
	}

}

__END__
:endofperl
