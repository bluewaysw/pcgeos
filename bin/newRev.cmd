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

if ( @ARGV == 0 )
{
    print "usage: newRev <list file> [-R <release no>]\n";
    print "    Run on a file that contains a list of pathnames starting from ROOT_DIR\n";
    print "    for which you'd like a new rev file created.  New rev file will have\n";
    print "    an initial protocol number of 1.0 and a release number of 0.0.0.0.\n";
    print "    Will create a perforce changelist and add these files to that changelist\n";
    print "    for you to check them in at your leisure.\n";
    print "\n    -R <release no>  Set release number to <release no> in the format\n";
    print   "                     'x.y.z'; results in a release number of x.y.z.0\n";
    exit 0;
}

$nextarg = "";
$nextargarg = "";
$listfile = "";
$releaseNo = "0.0.0";

foreach $arg (@ARGV)
{
    if ( $nextarg )
    {
	$$nextarg = $arg;
	$nextarg = "";
    }

    elsif ( $arg =~ /^-(.*)/ )
    {
	if ( $1 eq "R" )
	{
	    $nextarg = "releaseNo";
	    $nextargarg = "-R";
	}

	else
	{
	    die "Unknown flag '$arg'\n";
	}
    }

    else
    {
	if ( $listfile )
	{
	    die "Too many args\n";
	}

	else
	{
	    $listfile = $arg;
	}
    }
}

if ( $nextarg )
{
    die "Did not provide argument for '$nextargarg' flag\n";
}

if ( ! $listfile )
{
    die "Did not provide a listfile\n";
}

if ( ! -f $listfile )
{
    die "Could not find '$listfile'\n";
}

if ( $releaseNo !~ /^\d+\.\d+\.\d+$/ )
{
    die "bad release number '$releaseNo' (not x.y.z format)\n";
}

if ( $ENV{"ROOT_DIR"} )
{
    $topdir = $ENV{"ROOT_DIR"}."/";
}

else
{
    die "ROOT_DIR not set\n";
}

$chfile = $tmpdir."/nrvf.tmp";
open CHFILE, "> $chfile" or die "Couldn't open $chfile for write\n";

print CHFILE "Change: new\n";
print CHFILE "\nDescription:\n";
print CHFILE "\tNew rev files added.\n";
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


open( FILELIST, "$listfile" ) or die "could not open '$listfile';\n";

while ( <FILELIST> )
{
    chop( $_ );

    $path = "$topdir$_";
    $path =~ s/\//\\/g;
    if ( ! -d $path )
    {
	print "ERROR: Could not access directory '$path'\n";
	next;
    }

    $mf = "";
    $geode = "";
    
    if ( -f "$path/Makefile" )
    {
	$mf = "$path/Makefile";
    }
    
    elsif ( -f "$path/makefile" )
    {
	$mf = "$path/makefile";
    }
    
    if ( $mf && open( MAKEFILE, "$mf" ) )
    {
	while ( <MAKEFILE> )
	{
	    chop( $_ );
	    if ( $_ =~ /^\s*GEODE\s*=\s*([^\s]+)/ )
	    {
		$geode = $1;
		last;
	    }
	}
	close MAKEFILE;
    }

    else
    {
	print "ERROR: Could not find a Makefile in '$path'\n";
	next;
    }

    if ( ! $geode )
    {
	print "ERROR: Could not find GEODE variable in Makefile for '$path'\n";
	next;
    }

    @cmdlist = ();

    $revfile = "$path\\$geode.rev";

#    print "would do $revfile\n";
#    next;

    if ( -f $revfile )
    {
	print "ERROR: $revfile already exists\n";
	next;
    }

    push @cmdlist, "grev new $revfile";
    push @cmdlist, "grev NPM $revfile -s";

    if ( $releaseNo != "0.0.0" )
    {
	push @cmdlist, "grev newrev $revfile -s $releaseNo";
    }

    foreach $cmd (@cmdlist)
    {
	print "+ $cmd\n";
	system( "$cmd" );
    }

    print "Adding $revfile to changelist\n";
    open( P4ADD, "p4 add -c $changeNum $revfile |" ) or
	 die "Could not run p4 edit.. changelist $changeNum must be cleaned up.\n";

    while ( <P4ADD> )
    {
	chop( $_ );
	if ( $_ !~ /[^\#\s]+\#\d+[\s-]+opened for add/i )
	{
	    print "UNEXPECTED OUTPUT FROM p4:\n$_\n";
	}
    }

    close( P4ADD );
}

print "\nDone.\n";
print "\nnewRev complete\n";
print "Please remember to review changelist $changeNum and then submit it.\n";

close FILELIST;

# END PERL SCRIPT
__END__
:endofperl
