#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996.  All rights reserved.
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	PCGEOS
# MODULE:	Build Tool
# FILE: 	builddebug.pl
# AUTHOR: 	Paul Canavese, Oct 31, 1996
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#	canavese	10/31/96   	Initial Revision
#
# DESCRIPTION:
#
#       Build tool debugging functionality.
#	
# SUBROUTINES:
#
#       Debug(<debug flag>)
#               Return true if the passed debug flag is on.
#       DebugPrint(<debug flag>, <string>)
#               If the passed debug flag is on, print the string.
#       SetDebugFlags()
#               Allow the user to interactively turn on debugging flags.
#       Assert(<boolean value>, <error string>)
#               Print the passed error message if the passed boolean is not
#               true.
#       AssertVar(<variable name>, <error string>)
#               Print the passed error message if the passed build variable
#               is not defined.
#       AssertVarTrue(<variable name>, <error string>)
#               Print the passed error message if the passed build variable
#               is not true.
#
#	$Id: debugbuild.pl,v 1.2 96/12/05 18:39:11 canavese Exp $
#
###############################################################################

1;

##############################################################################
#	Debug
##############################################################################
#
# SYNOPSIS:	Return true if the passed debug flag is on.
# PASS:		<debug flag>
# CALLED BY:	various
# RETURN:	<true/false>
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/31/96   	Initial Revision
#
##############################################################################
sub Debug {
    return grep(/\b@_\b/, "$var{debugflags} $userSelectedDebugFlags");
}


##############################################################################
#	DebugPrint
##############################################################################
#
# SYNOPSIS:	If the passed debug flag is on, print the string.
# PASS:		<debug flag>, <string>
# CALLED BY:	various
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/31/96   	Initial Revision
#
##############################################################################
sub DebugPrint {
    local($debugflag,$string) = @_;
    if ( grep(/\b$debugflag\b/, "$var{debugflags} $userSelectedDebugFlags") ) {
	print "$string\n";
    }
}


##############################################################################
#	SetDebugFlags
##############################################################################
#
# SYNOPSIS:	Allow the user to interactively turn on debugging flags.
# PASS:		nothing
# CALLED BY:	top level
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/25/96   	Initial Revision
#
##############################################################################
%debugFlags=("1","Variables",
	     "1.1:vars", "Report final settings",
	     "1.2:vardef", "Variable assignment",
	     "2", "Templates",
	     "2.1:parsetemplate","Parsing of templates",
	     "3", "Filetree files",
	     "3.1:parsefiletree","Parsing of filetree file",
	     "3.2:findinstalledfile","Locating a file in installed trees",
	     "3.3:mediaship","Media type",
	     "4", "Miscellaneous",
	     "4.1:dosify", "Dosify",
	     "4.2:syscalls", "Show all system calls",
	     "5", "Images",
	     "5.1:images", "Print out image processing arguments");

sub SetDebugFlags {

    print "\n";
    &printreversefullline("Having a bad build?  Let's debug!");
    &printreversefullline("");
    print "\n";
    $major=1;
    $minor=0;

    foreach $key (keys(%debugFlags)) {
	($number,$flag)=split(':',$key);
	if ( "$flag" ) {
	    $flags{"$number"}="$flag";
	} else {
	    $flags{"$number"}="0";
	}
    }

    while ( 1 ) {

	if ( ! $minor ) {
	    if ( !defined($flags{$major}) ) {
		last;
	    } else {
		if ( "$flags{$major}" ) {
		    $key=join(":",$major,$flags{$major});
		} else {
		    $key=$major;
		}
		print "\n$major. $debugFlags{$key}\n\n";
		$minor++;
		next;
	    }
	} else {
	    if ( !defined($flags{"$major.$minor"} ) ) {
		$major++;
		$minor=0;
		next;
	    } else {
		$flag=$flags{"$major.$minor"};
		if ( "$flag" ) {
		    $key=join(":","$major.$minor",$flag);
		} else {
		    $key="$major.$minor";
		}
		$flags=$debugFlags{"$key"};
		print "   - $major.$minor $debugFlags{$key}\n";
		$minor++;
		next;
	    }
	}
    }
    print "\nList the numbers of the debugging options you wish to use (separated\n";
    print "by spaces).\n\n> ";
    $numbers=<STDIN>;

    foreach $number (split(' ',$numbers)) {
	if ( defined($flags{$number}) ) {
	    if ( "$number" =~ /\./ ) {
		$userSelectedDebugFlags .= "$flags{$number} ";
	    } else {
		foreach $key (keys(%flags)) {
		    if ( $key =~ /^$number\./ ) {
			$userSelectedDebugFlags .= "$flags{$key} ";
		    }
		}
	    }
	} else {
	    &Error("Debugging flag $number does not exist.\n");
	}
    }
    print "\n_________________________________________________________________\n\n";
}


##############################################################################
#	Assert
##############################################################################
#
# SYNOPSIS:	Print the passed error message if the passed boolean is not 
#               true.
# PASS:		<boolean value>, <error string>
# CALLED BY:	various
# RETURN:	1 if assertion succeeded
#               0 if assertion failed
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/31/96   	Initial Revision
#
##############################################################################
sub Assert {
    local($boolean,$errormessage) = @_;
    if ( ! "$boolean" ) {
	&Error("$errormessage");
	return 0;
    }
    return 1;
}


##############################################################################
#	AssertVar
##############################################################################
#
# SYNOPSIS:	Print the passed error message if the passed build variable
#               is not defined.
# PASS:		<var name>, <error string>
# CALLED BY:	various
# RETURN:	1 if assertion succeeded
#               0 if assertion failed
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/31/96   	Initial Revision
#
##############################################################################
sub AssertVar {
    local($varname,@errormessages) = @_;
    if ( ! defined($var{"$varname"})) {
	&Error("@errormessages");
	return 0;
    }
    return 1;
}


##############################################################################
#	AssertVarTrue
##############################################################################
#
# SYNOPSIS:	Print the passed error message if the passed build variable
#               is not true
# PASS:		<var name>, <error string>
# CALLED BY:	various
# RETURN:	1 if assertion succeeded
#               0 if assertion failed
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/31/96   	Initial Revision
#
##############################################################################
sub AssertVarTrue {
    local($varname,@errormessages) = @_;
    if ( ! $var{"$varname"}) {
	&Error(@errormessages);
	return 0;
    }
    return 1;
}







