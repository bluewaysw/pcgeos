@rem = '-*- Perl -*-';
@rem = '
@echo off
perl -S %0.cmd %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
';

# BEGIN PERL SCRIPT
#
# Ugly thing.  This will update all .rev files according to the arguments
# passed.  In order to do this, it must find all .rev files, create a
# perforce changelist, do a perforce edit, run grev on all of them, and
# then leaves all changes for user to commit.  Sound like fun?
#

# Need a temporary directory to put some crapola.
# MAY NOT NEED THIS!
#
$tmpdir = $ENV{"TEMP"};
if ( ! $tmpdir )
{
    $tmpdir = $ENV{"TMP"};
    if ( ! $tmpdir )
    {
	die "Need to set TEMP or TMP variable to temporary directory.\n";
    }
}

# Parse arguments.. be user friendly and all that rot.
#
if ( @ARGV == 0 )
{
    usage();
}

$nextarg = 1;
$comment = $newrev = "";

if ( $ARGV[0] eq "newrev" )
{
    $newrev = $ARGV[$nextarg];
    if ( $newrev !~ /^\d+\.\d+\.\d+$/ )
    {
	print "bad revision number '$newrev' given as arg to newrev command\n";
	usage();
    }

    ++$nextarg;
}

elsif ( $ARGV[0] ne "newprotomajor" && $ARGV[0] ne "NPM" &&
       $ARGV[0] ne "newprotominor" && $ARGV[0] ne "npm" &&
       $ARGV[0] ne "newchange" )
{
    print "Unknown command: $ARGV[0]\n";
    usage();
}

@targv = @ARGV;
while ( $nextarg-- )
{
    shift @targv;
}

$grabarg = "";
$grabarg_switch = "";

foreach $arg (@targv)
{
    if ( $grabarg )
    {
	$$grabarg = $arg;
	$grabarg = "";
    }

    elsif ( $arg =~ /^-/ )
    {
	if ( $arg eq "-C" )
	{
	    $grabarg = "comment";
	    $grabarg_switch = $arg;
	}

	else
	{
	    die "unknown switch '$arg'\n";
	}
    }

    else
    {
	if ( ! -d $arg )
	{
	    die "$arg is not a directory\n";
	}

	push @dirlist, $arg;
    }
}

if ( $grabarg )
{
    die "argument not given for '$grabarg_switch' switch.\n";
}

if ( @dirlist == 0 )
{
    die "no directories given.\n";
}

# Whew! Now build up a list of all .rev files.
#
print "Seaching for .rev files.";
$_dcnt = 0;
foreach $dir (@dirlist)
{
    # Ugly, but findRev builds up global revFiles.
    findRev( $dir );
}

$n = @revFiles;
print "Done\n$n .rev files found\n";

if ( $n > 0 )
{
    print "\nDo you wish to proceed creating a perforce changelist, checking out\n";
    print "all rev files and running grev on each of them (y/n) <n>? ";
    checkContinue();

    $grev_cmd = "grev $ARGV[0] %s -s";

    if ( $newrev )
    {
	$grev_cmd .= " $newrev";
    }

    if ( $comment )
    {
	$grev_cmd .= " \"$comment\"";
    }

    $chfile = $tmpdir."/rgcf.tmp";
    open CHFILE, "> $chfile" or die "Couldn't open $chfile for write\n";

    print CHFILE "Change: new\n";
    print CHFILE "\nDescription:\n";
    print CHFILE "\tRev file updated with recgrev script with command:\n";
    print CHFILE "\t    ";
    printf CHFILE $grev_cmd, "<fname>";
    print CHFILE "\n\nFiles:\n";
    close CHFILE;

    open( P4CHANGE, "p4 change -i < $chfile |" ) or
	die "Couldn't run 'p4 change' command\n";
    $p4changeResp = <P4CHANGE>;
    close( P4CHANGE );

    unlink( $chfile );

    if ( $p4changeResp !~ /change\s+(\d+)\s+created/i )
    {
	die "'p4 change' gave unexpected response:\n$p4changeResp\n";
    }

    $changeNum = $1;
    print "Change list $changeNum created.\n";

    print "Running 'p4 edit' on all rev files.\n";

    @tlist = ();

    # We can't call p4 edit with all files on the command line.  The
    # NT command shell will barf if we do that.
    foreach $file (@revFiles)
    {
	push @tlist, $file;
	if ( @tlist > 9 )
	{
	    callP4EDIT( @tlist );
	    @tlist = ();
	}
    }

    if ( @tlist > 0 )
    {
	callP4EDIT( @tlist );
    }

    print "Executing grev on all rev files:\n";
    foreach $file (@revFiles)
    {
	$tfile = $file;
	$tfile =~ s/\//\\/g;
	$tfile =~ s/^\.\\//;
	$cmd = sprintf $grev_cmd, "$tfile";
	print "+ $cmd\n";
	system( "$cmd" );
    }

    print "\nrecgrev complete\n";
    print "Please remember to review changelist $changeNum and then submit it.\n";
}
else
{
    print "Nothing to do.. thanks for using recgrev! :-)\n";
}

exit 0;

sub findRev
{
    # Provide user something to look at.
    if ( $dc++ % 10 == 0 )
    {
	print ".";
    }

    my($curdir) = @_;

    opendir DIR, "$curdir" or die "Cannot open directory: $curdir\n";

    # find all the files matched (without "." and "..")
    my(@files) = grep !/^\.\.?$/, readdir DIR;
    closedir DIR;

    if ( @files )
    {
	my($f);
	foreach $f ( @files )
	{
	    if ( -d "$curdir/$f" )
	    {
		# subdirectory.. Recurse recurse recurse
		#
		findRev( "$curdir/$f" );
	    }

	    elsif ( $f =~ /\.rev$/i )
	    {
		push @revFiles, "$curdir/$f";
	    }
	}
    }
}

sub usage
{
    print "usage: recgrev <command> [-C <comment>] <dir>+\n";
    print "    Recursively applies grev command to all rev files found in\n";
    print "    and below all given <dir> directories.  Creates a perforce\n";
    print "    changelist, \"edits\" all .rev files and leaves the changelist\n";
    print "    for you to commit afterward.\n";
    print "    USE WITH CARE!\n\n";
    print "    grev commands that can be used:\n";
    print "\n    recgrev newprotomajor [-C <comment>] <dir>+\n";
    print "\tIncrements protocol major number.\n";
    print "\n    recgrev newprotominor [-C <comment>] <dir>+\n";
    print "\tIncrements protocol minor number.\n";
    print "\n    recgrev newchange [-C <comment>] <dir>+\n";
    print "\tIncrements revision change number (eg. X in 3.4.X.1).\n";
    print "\n    recgrev newrev <rev> [-C <comment>] <dir>+\n";
    print "\tSets release number to <rev>.0 where <rev> is like '1.2.3'.\n";

    exit 1;
}

# Will return if user responds with a y/Y.. otherwise will exit.
sub checkContinue
{
    while ( 1 )
    {
	$_resp = <STDIN>;
	if ( $_resp =~ /^y/i )
	{
	    last;
	}

	else
	{
	    die "recgrev aborted.\n";
	    exit 0;
	}
    }
}

sub callP4EDIT
{
    my (@filelist) = @_;

    open( P4EDIT, "p4 edit -c $changeNum @filelist |" ) or 
	die "Could not run p4 edit.. changelist $changeNum must be cleaned up.\n";

    while ( <P4EDIT> )
    {
	chop( $_ );
	if ( $_ !~ /[^\#\s]+\#\d+[\s-]+opened for edit/i )
	{
	    print "UNEXPECTED OUTPUT FROM p4:\n$_\n";
	    print "Do you want to continue [if you abort now, changelist $changeNum\n";
	    print "must be cleaned up manually] (y/n) <n>? ";
	    checkContinue();
	}
    }

    close( P4EDIT );
}

# END PERL SCRIPT
__END__
:endofperl
