#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) GlobalPC 1999.  All rights reserved.
#       GLOBALPC CONFIDENTIAL
#
# PROJECT:	
# MODULE:	
# FILE: 	buildupd.pl
# AUTHOR: 	, Aug 19, 1999
#
# REVISION HISTORY:
#	Name	        Date		Description
#	----	        ----		-----------
#	porteous	8/19/99   	Initial Revision
#
# DESCRIPTION:
#	
#       create a .list file for use with pack.pl as a system update by 
#       comparing the two directories passed as arguments.  Should be run 
#       from the directory containing the two system subdirectories.
#       The output file will be new.list.
#
#       buildupd.pl newdirectory olddirectory
#
#	$Id$
#
###############################################################################

use File::Find;
use Cwd;

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

&Include("Tools/scripts/perl/diffgeo.pl");

#directory 1 is the new tree, directory 2 is the old tree
$dir1 = shift @ARGV;
$dir2 = shift @ARGV;


find(\&getthemall1, $dir1);
find(\&getthemall2, $dir2);

$dir = cwd();

foreach (@files1) {
	print $_."\n";
}
#print "$dir\n";

open(LIST, ">new.list");

print LIST "Name = geos2001\n";
print LIST "Version = 1.0\n";
print LIST "author = Don Reeves\n";
print LIST "system = 3.0\n";
print LIST "type = system\n";
print LIST "readme = \n";
print LIST "note = system update\n";
print LIST "rootdir = $dir\\$dir1\n";
print LIST "#add files here\n";

while ($file1 = pop @files1) {
    $file2 = lookupFile($file1);
    if ($file2 eq "") {
	$file1 =~ s/$dir1\///;
	print "$file1 does not exist in the old tree\n";
	print LIST "$file1\n";
    } else {
	if ($file1 =~ m/.*geo$/i) {
	print "Doing compare of $file1\n";
	    $_ = compare($file1,$file2);
	} else {
	print "Doing bindiff of $file1\n";
	    $_ = bindiff($file1,$file2);
	}
	if ($_ eq false) {
	    print STDOUT "$file1 matches $file2\n";
	} else {
	    print STDOUT "$file1 does not match $file2\n";
	    $file1 =~ s/$dir1\///;
	    print LIST "$file1\n";
	}
    }
}

sub getgeodes1 {
    if ((m/.*geo$/) || (m/.*GEO$/)) {
	$_ = $File::Find::name;
	$file1 = $_;
	push @files1, $file1;
    }
}

sub getgeodes2 {
    if ((m/.*geo$/) || (m/.*GEO$/)) {
	$_ = $File::Find::name;
	$file2 = $_;
	push @files2, $file2;
    }
}

sub getthemall1 {
    push @files1, $File::Find::name if -f and !(m/\@dirname\.000/i);
}

sub getthemall2 {
    push @files2, $File::Find::name if -f and !(m/\@dirname\.000/i);
}

sub lookupFile {
    my ($file) = @_;
    $file  =~ s/$dir1//;
    foreach $f (@files2) {
	$f1 = $f;
	$f1 =~ s/$dir2//;
	if (uc($f1) eq uc($file)) {
	    return $f;
	}
    }
    return "";
}

sub bindiff {
    my ($file1, $file2) = @_;
    my ($done) = 0;
    my ($i, $j);
    my $buflen = 512;

    open(A, $file1) or return true;
    open(B, $file2) or return true; 
    binmode A;
    binmode B;

    while (!(eof A) and !(eof B) and !$done) {
	$i = (read A, $charA, $buflen);
	$j = (read B, $charB, $buflen);
	@listA = unpack "c$i", $charA;
	@listB = unpack "c$j", $charB;
	$done = ($i != $j);
	if (!$done) {
	    for ($i = 0; $i < scalar @listA; $i++) {
		$done = 1 if (@listA[$i] != @listB[$i]);
	    }
	}
    }
    $done = $done or !((eof A) and (eof B));
    close A;
    close B;
    return $done ? true : false;
}




