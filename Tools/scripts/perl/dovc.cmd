@rem = '-*- Perl -*-';
@rem = '
@echo off
perl -S %0.cmd %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
';
#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996.  All rights reserved.
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	Tools
# MODULE:	Scripts
# FILE: 	dovc.cmd
# AUTHOR: 	Jacob A. Gabrielson, Oct 24, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jacob	10/24/96   	Initial Revision
#
# DESCRIPTION:
#	This tool is a hacked way to run our Unix source-code control
#	utilities from NT.  
#
#	The only mapping it knows about is that S: should be
#	equivalent to the Unix directory /staff.  So it
#	substitutes /staff for S: and then rsh's over to 
#	tungsten, cd's there, and does the specified command.
#	
#	$Id: dovc.cmd,v 1.20 97/01/18 17:07:49 jacob Exp $
#
###############################################################################

##############################################################################
#	usage
##############################################################################
#
# SYNOPSIS:	Print informative help message
# PASS:		nada
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       jacob 	10/24/96   	Initial Revision
#
##############################################################################
sub usage {
    die <<EOM;
Usage: dovc <command> [<args>]

    <command> can be one of:
        gdiff
	ginstall
        gmerge
	lock
	mkmf
	pcs
	unlock
	etc...

    <args> are whatever that program expects
EOM
}

#
# If they invoke us as "dovc <command>", then we need to shift
# off the command.  Otherwise we need to set command to $0, minus
# any .cmd extension and full-path shme.
#
if ($0 =~ /dovc/) {
    &usage if !($command = shift);
} else {
    $command = $0;
    $command =~ s,.*(/|\\),,;	# foo/bar/xxx.cmd -> xxx.cmd
    #
    # The "+" in the following is to handle the case where the
    # soft-link is called, say, lock.cmd.cmd (which needs
    # to exist if someone wants to type "lock.cmd" at
    # the command-prompt).
    #
    $command =~ s/(\.cmd)+$//i;	# xxx.cmd -> xxx
}

#
# Get the Unix host to rsh to, default to tungsten.
#
$rshHost = $ENV{'SAMBA_HOST'} || "tungsten";

chop($pwd = `cd`);
$pwd =~ s,\\,/,g;
($pwd =~ s,^s:,/staff,i) || die "What does '$pwd' correspond to under Unix?\n";

#
# Put escaped quotes around every argument that has whitespace in it.
# If we didn't do this it'd get interpreted as a bunch of separate
# arguments.
#
foreach $i (0 .. $#ARGV) {
    if ($ARGV[$i] =~ m/\s/) {
	$ARGV[$i] = '\"' . $ARGV[$i] . '\"';
    }
}

%otherCase = ('a', 'A', 'b', 'B', 'c', 'C', 'd', 'D', 'e', 'E', 'f', 'F', 'g', 'G', 'h', 'H', 'i', 'I', 'j', 'J', 'k', 'K', 'l', 'L', 'm', 'M', 'n', 'N', 'o', 'O', 'p', 'P', 'q', 'Q', 'r', 'R', 's', 'S', 't', 'T', 'u', 'U', 'v', 'V', 'w', 'W', 'x', 'X', 'y', 'Y', 'z', 'Z', 'A', 'a', 'B', 'b', 'C', 'c', 'D', 'd', 'E', 'e', 'F', 'f', 'G', 'g', 'H', 'h', 'I', 'i', 'J', 'j', 'K', 'k', 'L', 'l', 'M', 'm', 'N', 'n', 'O', 'o', 'P', 'p', 'Q', 'q', 'R', 'r', 'S', 's', 'T', 't', 'U', 'u', 'V', 'v', 'W', 'w', 'X', 'x', 'Y', 'y', 'Z', 'z');

#
# NT's paths are case-insensitive, but Unix's aren't.  Replace
# every letter in the NT path with a filename glob that accepts
# both upper & lower case letters, and hope Bourne shell finds
# the right path.
#
$pwd =~ s/([a-zA-Z])/[$1$otherCase{$1}]/g;

#print("rsh $rshHost cd $pwd; $command " . join(" ", @ARGV), "\n");
system("rsh $rshHost cd $pwd; $command " . join(" ", @ARGV));

exit 0;

__END__
:endofperl

