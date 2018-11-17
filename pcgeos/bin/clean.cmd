@rem = '-*- Perl -*-';
@rem = '
@echo off
attrib +R %ROOT_DIR%\Installed\Library\BorlandRTL\BORLAND.OBJ
attrib +R %ROOT_DIR%\Installed\Include\rgb2cmyk.ldf
attrib +R %ROOT_DIR%\Installed\Include\serial.ldf
attrib +R %ROOT_DIR%\Installed\Library\RGB2CMYK/*.*
attrib +R %ROOT_DIR%\Installed\Library\RGB2CMYK/666/*.*

perl -S %0.cmd %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
';
#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996.  All rights reserved.
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	GEOS
# MODULE:	NT Tools
# FILE: 	clean.cmd
# AUTHOR: 	Chris Thomas
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tbradley 10/25/96   	Initial Revision (rgrep.cmd)
#	cthomas	11/20/96	Stole for clean.cmd
#
# DESCRIPTION:
#	
#	NT replacement for sh script clean
#
# USAGE:
#
#    clean [no] [path]
#
#	Use 'no' to print only, not clean.
#	if path not specified, uses cwd
#
#	$Id: clean.cmd,v 1.2 97/10/03 17:21:21 allen Exp $
#
###############################################################################

###################################
# handle the command line arguments
###################################

$arg1 = shift @ARGV;

$removeIt = 1;

# pass the 'no' keyword?
if ($arg1 eq 'no')
{
    $removeIt = 0;
    $arg1 = shift @ARGV;
}


# grab the directory from the command line
$dir = $arg1;

;# if directory not passed in then define it as '.'
$dir = '.' if ($dir eq "");

####################################
# set the file extensions to search
# and actually do the searching
####################################

# if the path is legal
if (-e $dir)
{
    $extns = '\.lst|\.out|\.obj|\.eobj|\.gobj|\.exe|\.ldf|\.rdef|' .
	     '\.grdef|\.geo|\.ec|\.nc|\.egc|\.map|\.mod|\.o|\.a|' .
             '\.sym|~|\.rsc|\.vm|\.backup|#.*#|LOCK\.make|\.i|' .
	     '\.pdb|\.lib|\.err|\.\$\$\$';

    $grepargs = &find($dir,".*($extns)\$");

    # print $grepargs, "\n";

    foreach $f (split(/\s+/, $grepargs)) {
	print "$f\n";
	$f =~ s/\//\\/g;
	system "del $f" if ($removeIt);
    }
}

#otherwise die with usage
else
{
    print STDERR "\nfile or directory \"$dir\" not found.\n";
    &usage();
}

############
# END
############

#########################################################################
# sub usage
#
# die with usage statement
#
#########################################################################
sub usage
{
    die "Usage: clean [no] [path]\n";
}



#########################################################################
# sub find ($path, $pattern)
#
# recursively searches the path stored in its first argument to see which
# files (not directories) match the pattern stored in the second argument
#
# returns a string containing all files that matched
#
#########################################################################
sub find
{
    local($path, $pattern)  = @_;
    local($filelist, $file) = ("","");
    local(*PATH); # localize the filehandle. (Not quite.  See 
                 ;# _Programming_Perl_ pg 255)

   ;# if $path is a directory do a possibly recursive search of each of
    # it's entries

    if (-d $path)
    {
	# print "current directory = $path\n";

	opendir(PATH, $path);
	
	while($file = readdir(PATH))
	{
	    # ignore the pointer to this directory and the pointer to
	    # the parent

	    if ( ($file ne '.') && ($file ne '..') )
	    {
		$filelist .= &find("$path/$file", $pattern);
	    }
	}

	closedir(PATH);
    }

    # if $path is a file, see if it matches the $pattern
    elsif (-f $path)
    {
	# print "current file = $path\n";
	if ($path =~ m/$pattern/i)
	{
	    $filelist .= " $path";
	    # print "current file matched\n";
	}
    }

    # RETURN
    $filelist;
}
__END__
:endofperl
