@rem = '-*- Perl -*-';
@rem = '
@echo off
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
# PROJECT:	Tim Bradley
# MODULE:	NT Tools
# FILE: 	fui.cmd
# AUTHOR: 	Tim Bradley
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tbradley 10/25/96   	Initial Revision
#       gene    8/18/98         Wrote fui based on rgrep
#
# DESCRIPTION:
#	
#	NT replacement for sh script fui
#
#	$Id$
#
###############################################################################

###################################
# handle the command line arguments
###################################

$nrdOnly = '';
$dir = '.';

# check for writable flag
$nrdOnly = shift @ARGV;

if ($nrdOnly ne "-w") {
    $dir = $nrdOnly;
    $nrdOnly = "";
} else {
    # grab the directory from the command line
    $dir = shift @ARGV;
}

;# if directory not passed in then define it as '.'
$dir = '.' if ($dir eq "");

####################################
# set the file extensions to search
# and actually do the searching
####################################

# if the path is legal
if (-e $dir)
{
    if (-f $dir) {
        &eui($dir);
    } else {
        $extns  = '\.bas|\.c|\.cc|\.cpp|\.[hH]|\.ih|\.hi|\.uih|\.asm|\.def|\.ui|\.gp';
        $extns .= '|\.pl|\.filetree|\.build|\.goc|\.goh|\.txt|\.mk|\.el|\.tcl';
        $extns .= '|\.java';

        $grepargs = &find($dir,".*($extns)\$");

        #print $grepargs, "\n";

        &eui($grepargs);
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
    die "Usage: fui [-w] [path]\n";
}


#########################################################################
# sub grep ($pattern, $files)
#
# search each of $files for $pattern and return lines containing $pattern
#
# returns a string containing the lines which matched $pattern
#
#########################################################################
sub eui
{
    # make an array of the string
    # containing the filenames to store
    local(@files) = (split(/\s+/, $_[0]) );

    foreach $file (@files) {
	if ($nrdOnly eq "-w") {
	    if (-w $file) {
		print "$file\n";
	    }
	} else {
	    print "$file\n";
	}
    }
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
    local($except) = ("_g.c");
    local($except2) = ("_e.c");

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
	if (!($path =~ m/$except/i) && !($path =~ m/$except2/i)) {
	    if ($path =~ m/$pattern/i) {
		$filelist .= " $path";
		# print "current file matched\n";
	    }
	}
    }

    # RETURN
    $filelist;
}
__END__
:endofperl
