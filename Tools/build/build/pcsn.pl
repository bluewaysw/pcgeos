#!/usr/public/perl5
# -*- perl -*-
###############################################################################
#
#   Copyright (c) GlobalPC 1998 -- All Rights Reserved
#   GLOBALPC CONFIDENTIAL
#
# PROJECT:  GlobalPC
# MODULE:   Build tools
# FILE:     pcsn.pl
# AUTHOR:   Tim Bradley, Nov 16, 1998
#
# REVISION HISTORY:
#   Name    Date        Description
#   ----    ----        -----------
#   timb    11/16/98    Initial Revision
#
# DESCRIPTION:
#      Copies a geode from the Installed directory to the demo tree based
#      on mappings in ark.filetree.
#
# ARGUMENTS:
#      -n       : use the NonEC version of the geode instead of the ec version
#      filename : file to copy
#
#   $Id:$
#
###############################################################################
use File::Find qw(find);
use File::Copy qw(copy);

$ROOT_DIR = $ENV{'ROOT_DIR'};
$ROOT_DIR =~ s/\\/\//g;

#
# Include files.  Perl will first look for the files in the local GEOS
# tree, if it is run from one.
#
require "$ROOT_DIR/Tools/scripts/perl/lib/include.pl";
&Include("Tools/scripts/perl/lib/osutil.pl");
&Include("Tools/build/build/fileutil.pl");
&Include("Tools/build/build/debugbuild.pl");

$fileToSend = "";
$ec = 1;

$i = 0;
while (($arg = $ARGV[$i]) ne "") {
    if ($arg eq "-n") {
        $ec = 0;
    } else {
        $fileToSend = $arg;
    }
    $i++;
}

#
# Hardcode the filetree file location
#
$arkFileName = $ROOT_DIR . "/Tools/build/product/Ark/ark.filetree";
open(FILETREE, $arkFileName);

$LOCAL_ROOT = $ENV{'LOCAL_ROOT'};
$LOCAL_ROOT =~ s/\\/\//g;
push (@dir, $LOCAL_ROOT . "/gbuild/LOCALPC");

push (@currentCmd, "ROOT");
$line = 0;

$cwd = `cd`;
chomp $cwd;
$cwd =~ s/\\/\//g;
$cwd =~ s/^$ROOT_DIR(\/Installed)?\/?//i;

$pat = '.+\.(geo|bit|bin|fnt)';

if ($fileToSend eq "") {
    find (\&FindCallBack, ".");
}

sub FindCallBack
{
    $fileName = $File::Find::name;
    $File::Find::prune = 1;

    if ($fileName =~ m/.+$pat/oi) {
		($extension) = $fileName =~ /.+\.(.+)$/;
        $fileName =~ s/\.\///;
        $fileName =~ s/ec\.geo/\.geo/i;
        $fileToSend = $fileName;
    }
}

if ($fileToSend eq "") {
    die "pcsn: Couldn't find any send candidates in $cwd\n";
}

$fileroot = $fileToSend;
$fileToSend = $cwd . "/" . $fileToSend;

while (<FILETREE>) {
    $line++;
    
    #
    # skip lines that are comments, templates, or just complete blank
    #
    next if (m/^\s*#/);
    next if (m/^\s*TEMPLATE/);
    next if (m/^\s+$/);

    $commandParsed = 0;

    #
    # if we encounter a closing brace, remove a cmd from the stack
    #
    if (m/^\s*}/) {
        $commandParsed = 1;
        $cmd = pop(@currentCmd);
        if ($cmd eq "DIR") {
            pop @dir;
        } elsif ($cmd eq "ROOT") {
            die "pcsn: brace mismatch in $arkFileName:$line\n";
        }
    }

    #
    # if we enter a DIR command block, push it on the stack
    #
    if (m/\s*DIR\s*\(\s*([^\s][^)]*)\s*\)\s*{/) {
        $commandParsed = 1;
        push (@currentCmd, "DIR");
        $dirName = &GEOSToDOSFileName($1);
        push (@dir, $dirName);
    }

    #
    # if we encounter an IF command, push it on stack
    #
    if (m/\s*IF\s*\(\s*(.+)\s*\)\s*{/) {
        $commandParsed = 1;
        push (@currentCmd, "IF");
    }

    #
    # if we encounter an ELSE command, push it on the stack
    #
    if (m/\s*ELSE\s*{/) {
        $commandParsed = 1;
        push (@currentCmd, "ELSE");
    }

    #
    # if the line contained a control flow statement then don't look for
    # a file name
    next if ($commandParsed == 1);

    s/{ec}\./\./i;
    if (m/$fileToSend/i) {
        if ($ec == 1) {
            $fileToSend =~ s/\.geo/ec\.geo/i;
			$fileroot =~ s/\.geo/EC\.GEO/i;
        }
		print "fileroot = $fileroot\n";
        $source = "$ROOT_DIR/Installed/$fileToSend";
        $dest   = join("/", @dir) . "/" . &Dosify($fileroot);
		$source =~ s/\//\\/g;
        $dest   =~ s/\//\\/g;
        print "copy $source $dest\n";
        system ("copy $source $dest") && die "copy failed\n";

        #
        # found a match for the file so stop
        #
        last;
    }
}

die "No Match for $fileToSend in $arkFileName\n";
