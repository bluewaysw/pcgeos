#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996.  All rights reserved.
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	PCGEOS
# MODULE:	Build Script
# FILE: 	miscbuild.pl
# AUTHOR: 	Paul Canavese, Oct 31, 1996
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#	canavese	10/31/96   	Initial Revision
#
# DESCRIPTION:
#
#	Miscellaneous rotines for the build tool.
#
# SUBROUTINES:
#
#	GetFromParen(<string>)
#		Extract the contents of a set of parenthesis.
#       System(<system command>)
#               Make a system call.
#       FindBuildFile(<file>)
# 	        Look in the local GEOS directory (if build tool was run from
#               one), then in the Installed directory for the build file.
#
#	$Id: miscbuild.pl,v 1.8 98/06/25 15:31:01 simon Exp $
#
###############################################################################
$timestampCounter = 0;

1;

##############################################################################
#	GetFromParen
##############################################################################
#
# SYNOPSIS:	Extract the contents of a set of parenthesis
# PASS:		String containing parentheses.
# CALLED BY:	various
# RETURN:	string inside parentheses
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/31/96   	Initial Revision
#
##############################################################################
sub GetFromParen{    
    local($passed)="@_";
    $passed =~ s/[^(]*[\s]*\(([^)]*)\)[\s]*[^)]*$/$1/; 
    return "$passed";
}


##############################################################################
#	System
##############################################################################
#
# SYNOPSIS:	Make a system call
# PASS:		<system call>
# CALLED BY:	various
# RETURN:	exit status of the system call.
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub System {
    my $result = 0;		# assume successfull system call

    if ( &Debug(syscalls) ) {
	print "SYS: @_\n\n";
    }
    if ( ! "$var{syntaxtest}" ) {
	$result = system("@_");
	if ( "$result" != 0 ) {
	    &Error("Error in system call: @_");
	}
    }

    return $result;
}



##############################################################################
#	FileBuildFile
##############################################################################
#
# SYNOPSIS:	Look in the local GEOS directory (if build tool was run from 
#               one), then in the Installed directory for the build file.	
# PASS:		<file> = name of build file to find
# CALLED BY:	top level
# RETURN:	full path to file (if exists)
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub FindBuildFile {

    local($file)=@_;
    local($fullpath)="";

    # This is to make find() work under NT.
    #
    if ( &IsWin32() ){
	$File::Find::dont_use_nlink = 1;
    }

    if ( -d "$localgeospath/Tools/build" ) {
	find(\&FindBuildFileCB, "$localgeospath/Tools/build");
    }

    if ( $fullpath ) {
	return $fullpath;
    } else {

	# Look here first as an optimization.

	if ( -d "$geosPath/Tools/build/product/Common" ) {
	    find(\&FindBuildFileCB, 
		 "$geosPath/Tools/build/product/Common");
	}

	# If we haven't found it yet, search the whole build directory.

	if ( !"$fullpath" && -d "$geosPath/Tools/build" ) {
	    find(\&FindBuildFileCB, "$geosPath/Tools/build");
	}

	return $fullpath;
    }
}

##############################################################################
#	FindBuildFileCB
##############################################################################
#
# SYNOPSIS:	Callback function used by find() inside FindBuildFileCB.
# PASS:		nothing
# CALLED BY:	find()
# RETURN:	nothing
# SIDE EFFECTS:	
#               $fullpath = full path of the found file.
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	11/21/96   	Initial Revision
#
##############################################################################
sub FindBuildFileCB {
    if (/^$file$/){
	$fullpath = $File::Find::name;
	$File::Find::prune = 1;
    }
}

##############################################################################
#	DeleteTreeCommon
##############################################################################
#
# SYNOPSIS:	
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:	
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	4/22/98   	Initial Revision
#	
##############################################################################
sub DeleteTreeCommon {

    
    my($treeToDelete) = @_;
    my($reply)="y";

    if ($treeToDelete eq "$var{desttree}") {
	
	if ( "$var{promptondeletedesttree}" && ! "$var{syntaxtest}" ) {
	    &printreversefullline("Are you sure you wish to delete the destination tree:");
	    &printreversefullline("   $treeToDelete    [Y]es [N]o [A]bort");
	    print "\n> ";
	    $reply=<STDIN>;
	    print "\n";
	}
    } elsif ($treeToDelete eq "$var{transdir}") {

	if ($var{promptondeletetransfiles} && ! $var{syntaxtest}) {
	    &printreversefullline("Are you sure you wish to delete the translation files:");
	    &printreversefullline("   $treeToDelete    [Y]es [N]o [A]bort");
	    print "\n> ";
	    $reply=<STDIN>;
	    print "\n";
	}
    } else {
	print "Unknown directory type passed to delete in DeleteTreeCommon, exiting..\n";
	exit;
    }

    # Delete.

    if ( $reply =~ /^[Yy]/ ) {
	&printbold("Removing $treeToDelete.\n\n");
	&RmTree($treeToDelete);
	&MkDir($treeToDelete);	# Re-create the dest. directory.
	if ( ! &IsEmptyDir($treeToDelete) ) {
	    &Error("I could not remove all files from:",
		   "   $treeToDelete",
		   "Perhaps someone is accessing the files in DOS or the UNIX",
		   "permissions do not allow me to delete them.");
	    exit(1);
	}
    } elsif ( $reply =~ /^[Nn]/ ) {
	return;
    } else {
	exit 0;
    }
}

##############################################################################
#	IsEmptyDir
##############################################################################
#
# SYNOPSIS:	Test whether the passed directory is empty or not.
# PASS:		IsEmptyDir(dirPath)
#               dirPath - path of the directory
# CALLED BY:	DeleteDestinationTree()
# RETURN:	"" - directory NOT empty
#               1 - directory empty
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	8/21/96   	Initial Revision
#
##############################################################################
sub IsEmptyDir {
    my($dirPath) = @_;		# dir path
    my @dirList;		# a list of entries in the dir

    # Get the directory info.
    #
    opendir(DIR, $dirPath);
    @dirList = readdir(DIR);
    closedir(DIR);

    # If the directory is empty, @dirList should only have "." and ".." 
    # entries. The num. of total entries won't be more than 2.
    # 
    return scalar(@dirList) <= 2;
}

##############################################################################
#	GetSiteName
##############################################################################
#
# SYNOPSIS:	Get the site name from the file.
# PASS:		nothing
# CALLED BY:	SetVars()
# RETURN:	site name on success
#               "" string on failure
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	11/21/96   	Initial Revision
#
##############################################################################
sub GetSiteName {
    my $siteName;

    # Read the 1st line of the file to get the site name.
    #
    open(SITENAME, "<$geosPath/.BUILD_SITE") || return "";
    $siteName = <SITENAME>;
    chomp($siteName);
    close(SITENAME);
    return $siteName;
}


##############################################################################
#	TimestampGeodeInOrder
##############################################################################
#
# SYNOPSIS:	"gtouch" the geode.
# PASS:		TimestampGeodeInOrder(geode)
#               geode - name of the geode.
# CALLED BY:	CopyFile
# RETURN:	1 on success
#               0 on failure
# SIDE EFFECTS:	The passed geode would be gtouch'd. If the passed file is not a
#               geode, then this routine will do nothing and return 1.
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	12/26/96   	Initial Revision
#
##############################################################################
sub TimestampGeodeInOrder {
    my $geode = $_[0];		# file name
    my $result = 1;
    my $timestampdate = "";     # Date to timestamp passed to gtouch

    # We only "gtouch" geodes, not other files.
    #
    if ( $var{"timestampgeodeinorder"} && ($geode =~ /\.geo$/) ){

	# Covert counter into HH:MM format.
	#
	my $hour = int($timestampCounter / 60);
	my $min =  $timestampCounter % 60;
	my $gtouch = "$geosPath/Tools/scripts/gtouch"; # Assume Unix system.

        # Set the date to time stamp if it is provided.
	#
	if ( $var{"timestampgeodedate"} ) {
	    $timestampdate = "-d " . $var{"timestampgeodedate"};
	} 

	if ( &IsWin32() ){
	    $gtouch =~ tr|/|\\|; # Dosify the path for NT system.
	}
	if ( &System("perl $gtouch $timestampdate -t $hour:$min $geode") ){
	    $result = 0;	# gtouch failed.
	}
	$timestampCounter++;
    }

    return $result;
}

