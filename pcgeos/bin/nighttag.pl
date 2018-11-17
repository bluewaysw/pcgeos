use FileHandle;
use IPC::Open2;

unlink("tagList");

$excludeDirs = join('|^', @ARGV);

$excludeDirs = '^' . $excludeDirs;

print "excludeDirs = $excludeDirs\n";

@tagList;

&RunInSubdirs(".", "dirtags");

$tagList = join("\n", @tagList);

open  TOTAGS, ">tagargs" || die "failed to open tagargs for writing.\n";
print TOTAGS  $tagList;
close TOTAGS;

print "mergetags -stdin < tagargs > nightlytags\n";
open(FROMTAGS, "mergetags -stdin < tagargs |") ||
    die "failed to spawn mergetags.\n";

open OUT, ">nightlytags" || die "failed to open nightlytags for writing.\n";

while (<FROMTAGS>) {
    s|\./|/staff/pcgeos/|;
    print OUT;
}
close OUT;
close FROMTAGS;

unlink "tagargs";

#########################################################################
# sub:    RunInSubdirs
# args:   directory to start in, command to run
# return: nothing
#########################################################################
sub RunInSubdirs
{
    my   ($path, $cmd)  = @_;
    my    $file = "";
    my    $line;
    local *PATH, *DIRTAG; # localize the filehandle.

    # if $path is a directory do a possibly recursive search of each of
    # it's entries

    print "Tagging directory $path\n";

    open DIRTAG, "$cmd $path |";
    $line = <DIRTAG>;
    if ($line !~ /dirtags: No taggable files found/) {
	push @tagList, "$path/tags";
    }
    close DIRTAG;

    opendir(PATH, $path);
    while($file = readdir(PATH)) {
        #
        # ignore the pointer to this directory, the pointer to
        # the parent and any non-directory files
        #
        if (($file ne '.') && ($file ne '..') && (-d "$path/$file") && !&Excluded("$path/$file")) {
            &RunInSubdirs("$path/$file", $cmd);
        }
    }

    closedir(PATH);
}

sub Excluded
{
    my $file = $_[0];
    $file =~ s/^\.\///;

    if ((@ARGV > 0) && ($file =~ m/($excludeDirs)/i)) {
        print "$file is excluded\n";
        return 1;
    }

    return 0;
} 
