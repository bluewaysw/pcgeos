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
    print "usage: checkRev <filetree>\n";
    print "    Checks all geodes included in <filetree>'s build to see if a rev\n";
    print "    file exists for that geode.\n";
    exit 0;
}

open( FILETREE, "$ARGV[0]" ) or die "could not open $ARGV[0]\n";

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
		$st = $tail;
		$st =~ s/{[^\}]*}//g;
	        $st =~ s/.geo$//i;
		$pathlist{$path} = $st;
	    }
	}
    }
}

close FILETREE;


foreach $path (keys %pathlist)
{
    if ( ! -d $path )
    {
	print "****** ERROR: $path does not exist\n";
    }

    else
    {
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

	if ( $geode )
	{
	    $revtail="$geode.rev";
	}

	else
	{
	    $revtail="$pathlist{$path}.rev";
	}

	$rev = "$path/$revtail";
	$REV = uc($rev);

	if ( ! -f $rev || ! -f $REV )
	{
	    opendir DIR, "$path" or die "could not open dir $path\n";
	    @files = grep !/^\.\.?$/, readdir DIR;
	    closedir DIR;

	    $gotone = "";
	    if ( @files )
	    {
		foreach $f (@files)
		{
		    if ( $f =~ /\.rev$/i )
		    {
			print "$path has rev file named $f\n  Should be $revtail\n";
			$gotone = 1;
		    }
		}
	    }

	    if ( ! $gotone )
	    {
		print "$path has no rev file\n";
	    }
	}
    }
}

# END PERL SCRIPT
__END__
:endofperl
