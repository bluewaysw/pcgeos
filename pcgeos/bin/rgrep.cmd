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
# FILE: 	rgrep.cmd
# AUTHOR: 	Tim Bradley
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tbradley 10/25/96   	Initial Revision
#
# DESCRIPTION:
#	
#	NT replacement for sh script rgrep
#
#	$Id: rgrep.cmd,v 1.6 97/11/13 08:53:14 cthomas Exp $
#
###############################################################################

###################################
# handle the command line arguments
###################################

$arg1 = shift @ARGV;

# didn't pass the -i flag as arg 1?
if ($arg1 ne '-i') {
    $pat = $arg1;
}

# did pass the -i flag as arg 1
else {
    $pat        = shift @ARGV;
    $ignorecase = 'TRUE';
}

# no pattern defined? die with usage
&usage() if ($pat eq "");

# grab the directory from the command line
$dir = shift @ARGV;

# if directory not passed in then define it as '.'
$dir = '.' if ($dir eq "");

# turn off output buffering so we can see progress
$| = 1;

####################################
# set the file extensions to search
# and actually do the searching
####################################

# if the path is legal
if (-e $dir) {
    if (-f $dir) {
        &grep($dir);
    } else {
        $extns  = '\.bas|\.c|\.cc|\.cpp|\.[hH]|\.ih|\.hi|\.uih|\.asm|\.def|\.ui|\.gp|\.pl|\.filetree|\.build|\.goc|\.goh|\.txt|\.mk|\.el|\.tcl|\.java';
	$excl = '_e\.c|_g\.c';

	# Assume helper script is in the same path. 
	# Get the path of this script.
	$helperPath = $0;
	$helperPath =~ s/(.*)[\\|\/](.*)/$1/;
	$helperPath =~ s/\\/\//;        # Convert backslash into forward slash

	if ($ignorecase) {
	    open(GREP, "|perl $helperPath/rgrep-helper.pl $pat -i");
	} else {
	    open(GREP, "|perl $helperPath/rgrep-helper.pl $pat");
	}

        &find($dir, "\\./.+($extns)\$", "\\./.+($excl)\$");
	close(GREP);
    }
}

#otherwise die with usage
else {
    print STDERR "\nfile or directory \"$dir\" not found.\n";
    &usage();
}

############
# END
############


#########################################################################
# sub grep ($file)
#
# search $file for global $pat and return lines containing $pat
#
# prints a string containing the lines which matched $pat
#
#########################################################################
sub grep
{
    my    $file = shift @_;
    local *FILE;        # localize filehandle FILE and $line
    my    $line;

    open(FILE, $file);
    $line = 1;

    #
    # move this check outside of the loops to improve performance
    #
    if ($ignorecase) {
	while(<FILE>) {
	    print "$file: $line: $_" if (m/$pat/oi);
	    $line++;
	}
    } else {
	while(<FILE>) {
	    print "$file: $line: $_" if (m/$pat/o);
	    $line++;
	}
    }
}



#########################################################################
# sub usage
#
# die with usage statement
#
#########################################################################
sub usage
{
    die "Usage: rgrep [-i] pattern [search_path]\n";
}


#########################################################################
# sub find ($path, $pattern)
#
# recursively searches the path stored in its first argument to see which
# files (not directories) match the pattern stored in the second argument
#
# calls grep on all files that matched
#
#########################################################################
sub find
{
    my ($path, $pattern, $exclude)  = @_;
    my $file = "";
    local *PATH; # localize the filehandle.

    # if $path is a directory do a possibly recursive search of each of
    # it's entries

    if (-d $path) {
	opendir(PATH, $path);
	
	while($file = readdir(PATH)) {
	    # ignore the pointer to this directory and the pointer to
	    # the parent
	    if ( ($file ne '.') && ($file ne '..') ) {
		&find("$path/$file", $pattern, $exclude);
	    }
	}

	closedir(PATH);
    }

    # if $path is a file, see if it matches the $pattern
    else { #if (-f $path)
	if ($path =~ m/$pattern/oi &&
	    $path !~ m/$exclude/oi) {
	    # now run grep on the file
	    print GREP $path, "\n";
	}
    }
}
__END__
:endofperl
