@rem = '-*- Perl -*-';
@rem = '
@echo off
perl fnid2.cmd %1 
goto endofperl
';

#
# find not in depot
# fnid <path>
# This perl program finds any files under the optionally passed path that 
# are not in the depot.  
#
open FILES, "fnid1 $ARGV[0] 2>&1 |", 
	or die "can't fork $!";

while ($line = <FILES>) {
	if ($line =~ m/.*(no such file)+.*/) {
		$line =~ s/(.*)(- no such file)+.*/$1/;
		print $line;
	}
}

__END__
:endofperl
