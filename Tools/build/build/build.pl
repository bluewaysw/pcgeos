#!/usr/public/perl5
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	PCGEOS
# MODULE:	Build script
# FILE: 	build.pl
# AUTHOR: 	Paul Canavese, Mar 23, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	pjc	3/23/96   	Initial Revision
#
# DESCRIPTION:
#
#	The great big comprehensive shippin' buildin' xip-image-creatin'
#	@dirname-constructin' slicin' dicin' salad-shootin' boffo script 
#	we've all been waiting for.
#
#	$Id: build.pl,v 1.20 98/04/24 16:50:50 kliu Exp $
#
###############################################################################

#
# Include the stanard perl modules here.
#
use File::Path qw(rmtree);
use File::Find qw(find);
use File::Copy qw(copy);

#
# Include files.  Perl will first look for the files in the local GEOS
# tree, if it is run from one.
#
if ( $ENV{"OS"} eq "Windows_NT" ) { # NT version
    require Win32;
    require Win32::Process;
    require "$ENV{ROOT_DIR}/Tools/scripts/perl/lib/include.pl";
} else {			# Unix version
    require "/staff/pcgeos/Tools/scripts/perl/lib/include.pl";
}

&Include("Tools/scripts/perl/lib/osutil.pl");
&Include("Tools/scripts/perl/lib/debug.pl");
&Include("Tools/scripts/perl/lib/imageutil.pl");
&Include("Tools/scripts/perl/lib/prettyprint.pl");
&Include("Tools/build/build/debugbuild.pl");
&Include("Tools/build/build/miscbuild.pl");
&Include("Tools/build/build/var.pl");
&Include("Tools/build/build/filetree.pl");
&Include("Tools/build/build/fileutil.pl");
&Include("Tools/build/build/template.pl");


#
# Set all the variables, from the command line and build variable files. 
#
if ( ! &SetVars(@ARGV) ) {
    exit 1;			# Error occurred.
}

#
# Remove translation files directory or destination directory depending on 
# the action.
#

if (&UseResedit() && ($var{action} =~ /create_trans_files/i)) {
    #
    #  If we are just want to create some translation files, don't worry about
    #  the desttree at all.
    &DeleteTreeCommon($var{transdir}) if ($var{deletetransfiles});
} else {

    if ( "$var{deletedesttree}" && "$var{shipfiles}" && ! "$var{syntaxtest}" ) {
	&DeleteTreeCommon($var{desttree});
    }
}

#
# Read in file lists, create appropriate directories, and copy over files.
#

if ( "$var{shipfiles}" ) {
    if (&OpenAndSendFileTreeFile()) {
	exit 1;
    }
}

#
# Create images here.
#
if (! (&UseResedit() && ($var{action} =~ /create_trans_files/i))) {
    if ( "$var{makefloppyimages}" && "$var{localpc}" ) {
	&MakeFloppyImages();
    }
    if ( "$var{makeimages}" ) {
	
	# Make sure the image directory is there before making images.
	#
	&MakePath("$var{desttree}/image");
	&CreateAndMergeImages(%var);
    }
}

#
# Print out errors and warnings again
#
&PrintErrorsAndWarnings();

if (&UseResedit()) {
    &PrintReseditErrorsAndWarnings();
}









