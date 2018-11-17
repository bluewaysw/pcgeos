#!/usr/public/perl5
# -*- perl -*-
###############################################################################
#
#   Copyright (c) GlobalPC 1998 -- All Rights Reserved
#   GLOBALPC CONFIDENTIAL
#
# PROJECT:  GlobalPC
# MODULE:   Make tools
# FILE:     nightmake.pl
# AUTHOR:   Tim Bradley, Nov 17, 1998
#
# REVISION HISTORY:
#   Name    Date        Description
#   ----    ----        -----------
#   timb    11/17/98    Initial Revision
#
# DESCRIPTION:
#    Invokes a pmake -k and redirects output to nightmake.out.  This is meant
#    to be called from nightmake.bat, which should run as a nightly at command.
#
#   $Id:$
#
###############################################################################
$email = "";

$ROOT_DIR = $ENV{'ROOT_DIR'};
chdir("$ROOT_DIR\\Installed");

$outFileName = "$ROOT_DIR\\Installed\\nightmake.out";

unlink($outFileName);
open(OUT, ">$outFileName");
$| = 1;

open(OUT, ">$outFileName");
$| = 1;

# do a p4 sync first
open (IN, "p4 sync //depot/pcgeos/... 2>&1 |") ||
    print OUT "couldn't spawn p4 sync.\n";
while (<IN>) {
    print OUT;
}
close IN;

# next resolve all files that can be done automatically
open (IN, "p4 resolve -am //depot/pcgeos/... 2>&1 |") ||
    print OUT "couldn't spawn p4 resolve.\n";
while (<IN>) {
    print OUT;
}
close IN;

# finally, spawn the make.
open (IN, "pmake -k 2>&1 |") || print OUT "couldn't spawn pmake\n";
while (<IN>) {
    print OUT;
}
close(IN);

close(OUT);
close(ERROR);
