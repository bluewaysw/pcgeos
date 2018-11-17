#!/usr/local/bin/perl5
##############################################################################
#
# FILE: 	aliases.pl
# AUTHOR: 	jon, 29 oct 96
#
# DESCRIPTION:
#
#	This script works just like 'aliases', but doesn't blow up
#       awk for people in a ton of groups.
#
#       Example: aliases.pl lester dloft
#
#       $Id: aliases.pl,v 1.1 96/11/12 14:50:46 jon Exp $
#
###############################################################################
use strict;

open(ALIASES, "cat /rn/fn/etc/aliases |") || die "Can't open aliases file: $!\n";

my $person;
my $group;
my @groups;

foreach $person (@ARGV) {

    while (<ALIASES>) {
	#
	# If the person's name appears in this line, grab the name of
	# the group this line represents.
	#
	if (/^([^#].*):.*\W$person\W/) {
	    $group = $1;

	    #
	    # Make sure it's not one of the "owner-foo-bugs" lines
	    #
	    if (!($group =~ /^owner/)) {
		push(@groups, $group);
	    }
	}
    }

    #
    # Print out the person's name, followed by the groups, wrapping
    # after every 75 characters.
    #
    print "$person:";
    my $sofar = length("$person:");

    foreach $group (sort @groups) {
	if ($sofar + length(" $group") >= 75) {
	    $sofar = length("$person:");
	    print "\n" . ' ' x $sofar;
	}
	print " $group";
	$sofar += length(" $group");
    }

    print "\n";
}
