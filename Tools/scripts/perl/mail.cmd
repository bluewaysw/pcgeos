@rem = '-*- Perl -*-';
@rem = '
@echo off
perl -S %0.cmd %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
';#!/usr/public/perl5
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1998.  All rights reserved.
#       GEOWORKS CONFIDENTIAL
#
# FILE: 	mail.pl
# AUTHOR: 	Simon Auyeung, Jan 14, 1998
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#	simon   	1/14/98   	Initial Revision
#
# DESCRIPTION:
#
#       Usage: mail [-s <subject string>] [-c <contents string>] <recipient>+
#
#	$Id: mail.cmd,v 1.3 98/05/28 20:04:23 simon Exp $
#
###############################################################################

$SIG{INT} = sub {
    print "\n[User Interrupted]\n";
    exit( 1 );
};

require "newgetopt.pl";
NGetOpt("help", "c=s", "s=s");

#
# Make sure there is at least an argument
#
if ($#ARGV < 0 || $opt_help) {
    Usage();
    exit(1);
}

#
# Global variables
#
$Contents = "";
$User = $ENV{'USERNAME'} || die "Error: %USERNAME% variable is not set for mail.\n";
$Recipients = join(' ', @ARGV);
$MailHost = $ENV{'SAMBA_HOST'} || "tungsten";
$TempMailFile = ".perlmail.$$." . time(); # Process ID + current time

#
# If there is a mail subject on command line, use it. Otherwise,
# prompt it from the user.
#
if ($opt_s) {
    $Subject = $opt_s;
} else {
    print "Subject: ";                        # subject line of mail
    chop($Subject = <STDIN>);
}

#
# Read in mail contents from command line option or wait for users'
# input. 
#
if ($opt_c) {
    $Contents = $opt_c;
} else {
    while (<STDIN>) {
	chop($input = $_);
	if ( $input eq "." ) {
	    last;
	} else {
	    $Contents .= $_;
	}
    }
}

print "------------------\n";
print "Sending mail...\n";

# Write mail contents into the temp file
open(MAIL_TEMP_FILE, "> h:/$TempMailFile") || 
    die "Error: Cannot write to temp file: h:\$TempMailFile\n";
print MAIL_TEMP_FILE $Contents;
close(MAIL_TEMP_FILE);

#
# Call mail host in UNIX to deliver mail
#
# We need to escape Subject string and re-direction of temp file. Otherwise, 
# rsh will treat it as arguments.
#
#print "rsh $MailHost mail -s \\\"$Subject\\\" $Recipients ^< /staff/$User/$TempMailFile; rm /staff/$User/$TempMailFile";
$result = system("rsh $MailHost mail -s \\\"$Subject\\\" $Recipients ^< /staff/$User/$TempMailFile; rm /staff/$User/$TempMailFile");

if ( $result ) {
    print "Error sending mail.\n";
} else {
    print "Mail sent.";
}


sub Usage {
    local($now) = time();

    print <<EOM;
NAME
    mail - send mail messages

SYNOPSIS
    mail [-s <mail subject string>] [-c <mail contents string>] <recipient>+

DESCRIPTION
    This is an NT Perl mail interface program. It packs the input data
    from user and sends it to Samba host for actual mail delivery.

USAGE
    User can interactively type in the subject and/or the
    contents to send the mail. Alternatively, users can them as
    options to the program.

    * In the interactive mode, the end of mail is denoted by '.' as
      the only character on a new line. 

OPTIONS
    -s <subject string>		Mail subject

    -c <contents string>	Mail contents

REQUIREMENT
    * %SAMBA_HOST% is set to Samba mail host like "tungsten" or "fusion".
    * H: drive is connected to your Samba host home directory like 
      \\\\tungsten\\homes or \\\\fusion\\homes.
    * UNIX mail is accessible and functional from your UNIX account.
    * Your NT login username %USERNAME% is the same as your Samba host
      UNIX username. 
    * Your H:\\ directory is writable from NT.

NOTES
    * Ctrl-D is NOT a valid keystroke to send mail. A single dot
      on the newline is.
    * Neither Cc: nor Bcc: is implemented yet.
    * Mail recipients must be separated by spaces. Commas do not
      separate recipients.
    * It does not support piped input as mail contents.

FILES
    * H:\\.perlmail.$$.$now      
                                 Temporary file containing the mail
                                 contents. It should be cleaned up
                                 after the mail is sent.
EOM
}
__END__
:endofperl
