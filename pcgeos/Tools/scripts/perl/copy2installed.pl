##############################################################################
#
#       Copyright (C) Global PC 1998, All Rights Reserved
#
# PROJECT:	Global PC's Initial Product
# FILE:         copy2installed.pl
# AUTHOR:       Ian Porteous
#
# REVISION HISTORY:
#       Name      Date            Description
#       ----      ----            -----------
#       ian     9/23/98         Initial Revision
#
# DESCRIPTION:
#       script to create the installed directory tree and copy necessary
# files, Makefile, from the source tree to the installed tree.  
#
# The script assumes the source tree is ROOT_DIR and that the destination 
# tree is ROOT_DIR/Installed.  It looks for files named Makefile
# under library, appl, loader, driver.
#
# To test the script in your environment pass an argument.
#
###############################################################################


use File::CheckTree;
use File::Copy;
use File::Find;
use File::Path;
use File::Basename;

if ($ARGV[0]) {
    $test = 1;
    print "Testing \n";
}

$appl = $ENV{ROOT_DIR}."\\Appl";
$lib = $ENV{ROOT_DIR}."\\Library";
$driver = $ENV{ROOT_DIR}."\\Driver";
$loader = $ENV{ROOT_DIR}."\\Loader";

find(\&wanted,$appl,$lib,$driver,$loader);
sub wanted{
    if ($_ eq 'Makefile') {

	# get rid of the back slashes since the seem to cause problems 
	# with the reg expression matching.
	$path = $File::Find::dir;
	$path =~ s/\\/\//g;

	# construct Installed/...
	$suffix = $path;
	$root = $ENV{ROOT_DIR};
	$root =~ s/\\/\//g;
	$suffix =~ s/$root//;
	$ipath = $root . "/Installed" . $suffix;

	
	# verify that the directory exists in the installed tree.  
	# create the directory if it does not alread exist.
	$q = $ipath . "  -e || warn";
	if ( validate ( $q   ) ) {
	    if (!$test) {
		mkpath($ipath,1);
	    }
	}
	print "copy :", $File::Find::name, "\n" , "to   :", $ipath . '/' . $_ , "\n";
	if (!$test) {
	    copy($File::Find::name, $ipath . '/' . $_);
	}
    }
}


