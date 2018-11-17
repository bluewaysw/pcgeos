#!/usr/local/bin/perl5
##############################################################################
#
# FILE: 	whosin.pl
# AUTHOR: 	jon, 11 nov 96
#		matta, 12 nov 96	(works with nested lists)
#		jon, 12 nov 96 		(added list negation)
#               matta, 14 nov 96	(3x fast, use ypmatch, thanks rlocke!)
#               matta, 14 nov 96	(handle cc:mail crap sortof nicely)
#               matta, 16 nov 96	(special case the "seattle" list)
#               matta, 20 nov 96        (better cc:mail handling)
#               reza, 18 feb 97         (cleanup Seattle matching)
#		matta, 24 apr 97	(Matt_Armstrong -> matta and
#					strip @geoworks.com)
#		matta, 14 may 97	(don't print @.*geoworks.(co.uk|com)$)
#
# DESCRIPTION:
#
#	This script returns the group of people that're in *all*
#	of the passed newsgroups, and not in any of the newsgroups
#       that're prefixed with a '-'. For example:
#
#       whosin.pl bicycles softball snoboarding -coffee
#
#       ... will give you all the de-caffeinated tri-athletes in the company.
#
#       whosin.pl linstalls -company
#
#       ... will give you all "outsiders" that get Liberty installs mail
#
#       $Id: whosin.pl,v 1.15 97/09/16 17:47:49 matta Exp $
#
###############################################################################

use strict;
$ENV{'PATH'} = "/usr/ucb:/bin:/usr/bin";

# Hash of known lists.  Key is the list name.  Hash element is another hash
# of list members.
my %lists;

# Hash of known terminals.  A terminal is either a non-alias or an
# alias that just does a mapping to a particular site (matta ->
# matta@quark.geoworks.com).
my %terminals;

# Hash of known cc-mail aliases.  If we find "tony ->
# Tony_Requist_at_ALAMEDA@smtpgwy.geoworks.com" this hash will have a
# key of Tony_Requist and a value of tony.
my %cc_mail;

# Hash of long e-mail addresses as keys (like Matt_Armstrong) to short
# login names (like matta).
my %verbose2login;

# Pass these lists to ypmatch
my %resolve_these;

my $debug = 0;

##############################################################################
#	InitVerbose2LoginHash
##############################################################################
#
# SYNOPSIS:	Initialize the passwd database conversion hash 
#		(%verbose2login).
# PASS:		nothing
# CALLED BY:	main
# RETURN:	nothing
# SIDE EFFECTS:	Fills in %verbose2login
#
# STRATEGY:	Call "ypcat passwd" and parse the output.
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       matta   	4/24/97		Initial Revision
#	
##############################################################################
sub InitPasswdConversionHash {
    open(WHOSIN, "ypcat passwd |") || die "Can't spawn";

    while (<WHOSIN>) {
	my @F = split(':');
	my ($login, $long) = ($F[0], $F[4]); # field 0 and 4 in passwd entry

	# Ignore the ex accounts (XDOUG, etc.)
	if ($login =~ /^X[A-Z]+$/) {
	    next;
	}

	$long =~ s/,.*$//;	# get rid of ",Ext #XXXX"
	$long =~ tr/ /_/;	# spaces to _
	print("Convert $long -> $login\n") if $debug;
	$verbose2login{$long} = $login;

	# We can put the long name form in as a terminal now (maybe
	# saving some calls to ResolveNonTerminals().  Can't do this
	# with the login because there are Eden people with Geoworks
	# logins but have membership in lists with thier @eden.co.uk
	# address.
	print "TERMINAL $long (long to short)\n" if $debug;
	$terminals{$long} = 1;
    }

    close(WHOSIN);
}
# End of InitPasswdConversionHash


##############################################################################
#	InitWhosinTree
##############################################################################
#
# SYNOPSIS:	Initialize the whosin tree with the first pass
# PASS:		List of sendmail aliases
# CALLED BY:	main
# RETURN:	nothing
# SIDE EFFECTS:	Fills in %lists
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       matta 	11/13/96  	Initial Revision
#
##############################################################################
sub InitWhosinTree {
    my (@array) = @_;		# copy args 'cause we modify them

    # Create a bogus "meta list" that has all our target lists in it.
    foreach (@array) {
	 s/^-//;			# strip any leading negation
	$lists{"\@whosin\@"}{$_} = 1;
    }
}
# End of InitWhosinTree

##############################################################################
#	ExpandLists
##############################################################################
#
# SYNOPSIS:	Go through %lists and expand known lists to their members
# PASS:		nothing
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       matta 	11/13/96  	Initial Revision
#
##############################################################################
sub ExpandLists {
    my ($dirty, $list, $member, $tempMember);
    $dirty = 1;

    if ($debug) {
	print("\n\n");
	PrintHash("terminals", \%terminals);
	PrintHash("lists", \%lists);
	print("\n\n");
    }

    while ($dirty) {
	$dirty = 0;
	foreach $list (keys %lists) {
	    print("Expanding list $list\n") if $debug;
	    foreach $member (keys %{$lists{$list}}) {
		unless (defined $terminals{$member}) {
		    $dirty = 1;
		    delete $lists{$list}{$member};
		    print("...remove list member $member from $list\n") 
			if $debug;
		    foreach $tempMember (keys %{$lists{$member}}) {
			$lists{$list}{$tempMember} = 1;
			print("Add $tempMember to $list\n") if $debug;
		    }
		} else {
		    print("...$member is a terminal.\n") if $debug;

		    if ($member =~ /(.*)@(ccmail|smtpgwy).geoworks.com/) {  
			# Got a cc-mail address, try to convert to
			# its alias.
			my $cc_mail_address = NormalizeCCMailAddress("$1");
			my $normalized = ($cc_mail_address .
					  "\@ccmail.geoworks.com");
			$tempMember = $cc_mail{$cc_mail_address};
			if (defined $tempMember) {
			    delete $lists{$list}{$member};
			    $lists{$list}{$tempMember} = 1;
			    print("change $list:$member to $tempMember ($cc_mail_address)\n")
				if $debug;
			} elsif ($normalized ne $member) {
			    # If we don\'t know the short unix name,
			    # convert it to a normalized cc:mail address
			    delete $lists{$list}{$member};
			    $lists{$list}{$normalized} = 1;
			    $terminals{$normalized} = 1;
			    print("change $list:$member to $normalized\n")
				if $debug;
			}
		    } elsif (defined $verbose2login{$member}) {
			
			# Delete the long (full name) version and add
			# the short (unix login) version.
			delete $lists{$list}{$member};
			$lists{$list}{$verbose2login{$member}} = 1;
			print("change $list:$member to $verbose2login{$member} (verbose2login)\n")
			  if $debug;
		    }
		}
	    }
	}
    }
}
# End of ExpandLists

##############################################################################
#	FindNonTerminals
##############################################################################
#
# SYNOPSIS:	Iterate members in %lists and put non terminals in 
#               %resolve_these
# PASS:		nothing
# CALLED BY:	
# RETURN:	1 when non terminals found, undef otherwise
# SIDE EFFECTS:	erases and fills the %resolve_these variables
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       matta 	11/13/96  	Initial Revision
#
##############################################################################
sub FindNonTerminals {
    %resolve_these = {};	# initialize to nothing
    my ($list, $member, $retval);
    foreach $list (keys %lists) {
	foreach $member (keys %{$lists{$list}}) {
	    unless (defined $terminals{$member} ||
		    defined $lists{$member}) {
		$retval = 1;
		$resolve_these{$member} = 1;
		print("Resolve $list member $member\n") if $debug;
	    }
	}
    }
    return $retval;
}
# End of FindNonTerminals


##############################################################################
#	NormalizeCCMailAddress
##############################################################################
#
# SYNOPSIS:	Takes a CC mail address and normalizes it to a standard
#               format.
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:     Strip off _at_ALAMEDA and change _ to .
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       matta 	11/20/96  	Initial Revision
#
##############################################################################
sub NormalizeCCMailAddress {
    my($address) = @_;
    $address =~ s/_at_ALAMEDA//; # strip _at_ALAMEDA
    $address =~ tr [_] [.];	# _ to .
    $address =~ s/(\w+)/\u\L$1/g; # capitalize
    return $address;
}
# End of NormalizeCCMailAddress


##############################################################################
#	ProcessYPMatchLine
##############################################################################
#
# SYNOPSIS:	Take a line of output from a "ypmatch -k" and process it
# PASS:		The line
# CALLED BY:	ResolveSeattle(), ResolveNonTerminals()
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       matta 	11/13/96  	Initial Revision
#
##############################################################################
sub ProcessYPMatchLine {
    my ($line) = @_;
    my ($alias, $rest) = split(/:\s+/, $line);
	    
    # Split the output into a members list
    my @members = split(/,/, $rest);

    # If it is a single member list, we might want to treat it
    # as a terminal or it might be a cc-mail alias.
    if (@members == 1) {
	# Match terminals
	if ($members[0] =~ m,log/logger, |
	    $members[0] =~ m,mail2news,) {
	    # A grok logger or a mail2news gateway
	    delete $resolve_these{$alias};
	    $terminals{$alias} = 1;
	    print "TERMINAL $alias (/staff/pcgeos)\n" if $debug;
	    next;
	}
	# Get cc-mail aliases
	if ($members[0] =~ /(.*)@(smtpgwy|ccmail).geoworks.com/) {
	    my $cc_mail_address = NormalizeCCMailAddress("$1");
	    delete $resolve_these{$alias};
	    $cc_mail{$cc_mail_address} = $alias;
	    $terminals{$alias} = 1;
	    print "TERMINAL $alias (cc-mail)\n" if $debug;
	    print "CC-MAIL $alias -> $cc_mail_address\n" if $debug;
	    next;
	}
    }
    
    # Otherwise we treat them as new lists with a set of
    # members
    my $member;
    foreach $member (@members) {
	
	# For some reason, lots of "@geoworks.com." addresses are in
	# the alias database (note trailing dot, weird).  Get rid of
	# that here.
	$member =~ s/\@geoworks\.com\.?//;

	print "LIST $alias has member $member\n" if $debug;
	delete $resolve_these{$alias};
	$lists{$alias}{$member} = 1;
    }
}
# End of ProcessYPMatchLine


##############################################################################
#	ResolveNonTerminals
##############################################################################
#
# SYNOPSIS:	Run ypmatch and decide if the things in %resolve_these
#               are lists or terminals
# PASS:		nothing
# CALLED BY:	ExpandLists()
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       matta 	11/13/96  	Initial Revision
#
##############################################################################
sub ResolveNonTerminals {
    my (@args, $lists, $line, $alias);
    
    # For each item to resolve, check if it is a "long" e-mail name.
    foreach (keys %resolve_these) {

	if (defined $verbose2login{$_}) {
	    # Found a terminal, delete it from %resolve_these add it
	    # to %terminals.  It will be converted to its short
	    # equivalent in the ExpandLists() step.
	    delete $resolve_these{$_};
	    $terminals{$_} = 1;
	    print "TERMINAL (via %verbose2login) $_\n" if $debug;
	}
    }

    # Get what remains into an array
    foreach (keys %resolve_these) {
	@args[$#args + 1] = $_;
    }

    if ($#args >= 0) {
	$lists = join(" ", @args);

	print "DO: ypmatch $lists aliases\n" if $debug;

	# Save stderr and redirect it to /dev/null
	open(SAVE_STDERR, ">&STDERR") || die $!;
	open(STDERR, ">/dev/null") || die $!;

	open(WHOSIN, "ypmatch -k $lists aliases |") || die "Can't spawn";
	my @input = <WHOSIN>;

	# Restore stderr
	open(STDERR, ">&SAVE_STDERR") || die $!;

	# Process each line of output
	print @input if $debug;
	chop @input;
	foreach $line (@input) {
	    ProcessYPMatchLine($line);
	}

	# Convert keys not matched by ypmatch into terminals
	foreach $alias (keys %resolve_these) {

	    $terminals{$alias} = 1;
	    delete $resolve_these{$alias};
	    print "TERMINAL $alias (no ypmatch alias)\n" if $debug;
	}
    }
}
# End of ResolveNonTerminals

##############################################################################
#	ResolveAndExpand
##############################################################################
#
# SYNOPSIS:	Expand all lists to have only terminals in them
# PASS:		nothing
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       matta 	11/13/96  	Initial Revision
#
##############################################################################
sub ResolveAndExpand {
    while (FindNonTerminals()) {
	print("Found non terminals, resolving...\n") if $debug;
	ResolveNonTerminals();
    }
    print("Didn't find non terminals, expanding lists...\n") if $debug;
    ExpandLists();
}
# End of ResolveAndExpand


MAIN:

InitWhosinTree(@ARGV);
InitPasswdConversionHash();
ResolveAndExpand();

my $list;
my %people;
my $inc;
my $ngroups;
foreach $list (@ARGV) {
    PrintHash("$list", $lists{"$list"}) if $debug;
    if ($list =~ /^-(.*)/) {
	$inc = -1;
	$list = $1;
    } else {
	$inc = 1;
	$ngroups++;
    }
    unless (defined $lists{$list}) {
	print STDERR "bogus list $list, aborting\n";
	exit(0); 
    }
    foreach (keys %{$lists{$list}}) {
	$people{$_} += $inc;
	print("$_ $people{$_}\n") if $debug;
    }
}

my $person;
my @intersection;
foreach $person (sort(keys %people)) {
    if ($people{$person} == $ngroups) {
	
	# Strip off geoworks specifiers
	$person =~ s,\@.*geoworks\.(co\.uk|com)$,,;

	# Save it and print it later
	push(@intersection, $person);
    }
}

print join(',', @intersection) . "\n";

sub PrintHash {
    my ($prefix, $hash) = @_;
    print "$prefix <- ", join(" ", keys(%$hash), "\n");
}


