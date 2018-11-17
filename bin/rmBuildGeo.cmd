@rem = '-*- Perl -*-';
@rem = '
@echo off
perl -S %0.cmd %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
';

# BEGIN PERL SCRIPT
#

if ( @ARGV == 0 )
{
    print "Usage: rmBuildGeo <filetree file>\n";
    print "    Will grossly parse the filetree to find all of the geode\n";
    print "    files used in the build and then removes all of those geodes\n";
    print "    from the Installed directory.  This is used to force the relinking\n";
    print "    of all used geodes.  Specifically, this is useful to run after changing\n";
    print "    all of the .rev files.\n\n";
    print "    Should be run from /perforce/pcgeos or /perforce/pcgeos/Installed or\n";
    print "    you should have ROOT_DIR set appropriately.\n\n";
    print "    example invocation:\n";
    print "\trmBuildGeo Tools\\build\\product\\Ark\\ark.filetree\n";
    exit( 0 );
}

$topdir = ".";

if ( $ENV{"ROOT_DIR"} )
{
    $topdir = $ENV{"ROOT_DIR"};
}

while ( 1 )
{
    if ( -d "$topdir/Installed" )
    {
	$topdir = "$topdir/Installed";
    }

    if ( ! -d "$topdir/Appl" || ! -d "$topdir/Library" ||
	 ! -d "$topdir/Driver" )
    {
	# If ROOT_DIR is set wrong and we can't find an installed tree,
	# then try again with current dir as topdir.
	if ( $topdir !~ /^\./ )
	{
	    $topdir = ".";
	    next;
	}
	die "Can't find Installed directory.\n";
    }

    else
    {
	last;
    }
}

$topdir .= "/";

open( FILETREE, "$ARGV[0]" ) or die "could not open $ARGV[0]\n";

$count = 0;

while ( <FILETREE> )
{
    chop( $_ );

    if ( $_ =~ /^\s*([a-zA-Z\d.{}_]+\/[a-zA-Z\d\/{}._]+)/ )
    {
	$whole = $1;
	if ( $whole =~ /^\s*([a-zA-Z\d\/{}._]+)\/([a-zA-Z\d{}._]+)/ )
	{
	    $path = $1;
	    $tail = $2;

	    if ( $tail =~ /\.geo$/i )
	    {
		# Only allow paths that start like this:
		if ( $path !~ /^Appl\// &&
		     $path !~ /^Library\// &&
		     $path !~ /^Loader\// &&
		     $path !~ /^Driver\// )
		{
		    next;
		}

		if ( $pathlist{$path} )
		{
		    if ( $pathlist{$path} != $tail )
		    {
			die "Different geodes for $path:\n  prev: $pathlist{$path}\n  new: $tail";
		    }
		}

		else
		{
		    $pathlist{$path} = $tail;
		    ++$count;
		}
	    }
	}
    }
}

close FILETREE;

$td = $topdir;
$td =~ s/\//\\/g;
print "Installed directory: $td\n";
print "$count distinct geode directories read from build script\n";
checkContinue();

$readonly = $removed = 0;
foreach $path (keys %pathlist)
{
    $tail = $pathlist{$path};
    $path = $topdir . $path;

    if ( ! -d $path )
    {
	print "****** WARNING: $path does not exist\n";
    }

    else
    {
	@fn = ();

	if ( $tail =~ /{ec}/i )
	{
	    $t = $t2 = $tail;
	    $t =~ s/{ec}//i;
	    $t2 =~ s/{(ec)}/$1/i;
	    push @fn, $t;
	    push @fn, uc($t);
	    push @fn, $t2;
	    push @fn, uc($t2);
	}

	else
	{
	    push @fn, $tail;
	    push @fn, uc($tail);
	}

	foreach $file (@fn)
	{
	    $backslashes = "$path/$file";
	    $backslashes =~ s/\//\\/g;

	    if ( -f "$backslashes" )
	    {
		if ( ! -w "$backslashes" )
		{
		    $readonly++;
		    print "READ-ONLY FILE NOT REMOVED: $backslashes\n";
		}

		else
		{
		    print "removing $backslashes\n";
		    unlink( "$backslashes" );
		    $removed++;
		}
	    }
	}
    }
}

print "\n$removed geodes were removed from installed tree\n";

if ( $readonly > 0 )
{
    print "$readonly files were encountered that were not removed\n";
}

# Will return if user responds with a y/Y.. otherwise will exit.
sub checkContinue
{
    print "Do you want to continue (y/n) <n>? ";

    while ( 1 )
    {
	$_resp = <STDIN>;
	if ( $_resp =~ /^y/i )
	{
	    last;
	}

	else
	{
	    die "rmBuildGeo aborted.\n";
	    exit 0;
	}
    }
}

# END PERL SCRIPT
__END__
:endofperl
