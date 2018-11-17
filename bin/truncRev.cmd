@rem = '-*- Perl -*-';
@rem = '
@echo off
perl -S %0.cmd %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
';

# BEGIN PERL SCRIPT
#

# Need a temporary directory to put some crapola.
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

foreach $arg (@ARGV)
{
    if ( $arg =~ /^-/ )
    {
	die "unknown switch '$arg'\n";
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

### TEST!
open( TST, ">d:/tmp/tst") or die "argh";
foreach $f (@revFiles)
{
    print TST "$f\n";
}
close TST;
### TEST!

if ( $n > 0 )
{
    print "\nDo you wish to proceed creating a perforce changelist, checking out\n";
    print "all rev files and truncating them appropriately (y/n) <n>? ";
    checkContinue("");

    $chfile = $tmpdir."/tcrf.tmp";
    open CHFILE, "> $chfile" or die "Couldn't open $chfile for write\n";

    print CHFILE "Change: new\n";
    print CHFILE "\nDescription:\n";
    print CHFILE "\tRev file truncated by truncRev script.\n";
    print CHFILE "\nFiles:\n";
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

    print "Truncating all rev files.";

    $curfile = 0;
    $curpct = -100;

    foreach $file (@revFiles)
    {
	# Print busy output.  Shows percent complete every appx 10%.
	if ( (( $curfile * 100 / $n ) - $curpct) >= 10 )
	{
	    $curpct = int( (($curfile * 100 / $n) + 0.5) / 10) * 10;
	    printf "%d%%", $curpct;
	}
	
	else
	{
	    print ".";
	}
	$curfile++;

	if ( ! -w "$file" )
	{
	    print "\n$file is READ-ONLY.  Did the p4 edit fail?\n";
	    checkContinue(1);
	    next;
	}

	$ofile = $file.".tmp";
	if ( ! open( OUTFILE, ">$ofile" ) )
	{
	    print "\nCOULD NOT OPEN $ofile for write.\n";
	    checkContinue(1);		# May exit script.
	    next;
	}

	if ( ! open( INFILE, "$file" ) )
	{
	    print "\nCOULD NOT OPEN $file for read.\n";
	    checkContinue(1);		# May exit script.
	    next;
	}

	%haveseen = ();
	@order = ();

	while ( <INFILE> )
	{
	    chop( $_ );
	    $_ =~ s/^\s+//;
	    @spl = split( /\s+/, $_ );
	    if ( $spl[0] =~ /^[PR]/ && ! $haveseen{$spl[0]} )
	    {
		$haveseen{$spl[0]} = 1;
		push @order, $_;
	    }
	}

	close( INFILE );

	foreach $line (@order)
	{
	    print OUTFILE "$line\n";
	}

	close( OUTFILE );

	unlink( $file );
	rename( $ofile, $file );
    }

    print ".Done\n";
    print "\ntruncRec complete\n";
    print "Please remember to review changelist $changeNum and then submit it.\n";
}
else
{
    print "Nothing to do.. thanks for using truncRec! :-)\n";
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
    print "usage: truncRev <dir>+\n";
    print "    Recursively truncate all rev files found in and below all given\n";
    print "    given <dir> directories.  Leaves only top-most release and protocol\n";
    print "    numbers for each branch.  Creates a perforce changelist,\n";
    print "    \"edits\" all .rev files and leaves the changelist\n";
    print "    for you to commit afterward.\n";
    print "    USE WITH CARE!\n\n";

    exit 1;
}

# Will return if user responds with a y/Y.. otherwise will exit.
sub checkContinue
{
    my ($pmsg) = @_;

    if ( $pmsg )
    {
	print "Do you want to continue [if you abort now, changelist $changeNum\n";
	print "must be cleaned up manually] (y/n) <n>? ";
    }

    while ( 1 )
    {
	$_resp = <STDIN>;
	if ( $_resp =~ /^y/i )
	{
	    last;
	}

	else
	{
	    die "truncRec aborted.\n";
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
	    checkContinue(1);
	}
    }

    close( P4EDIT );
}


# END PERL SCRIPT
__END__
:endofperl
