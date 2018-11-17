@rem = '
@echo off
perl -S %0.cmd %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
';
$extns = '\.asm|\.ui|\.def|\.goc|\.c|\.h|\.uih|\.goh|\.el';
$pat   = ".+($extns)\$";
$excl  = ".+_e($extns)\$";

$path = shift @ARGV;

if ($path eq "") {
    $path = ".";
}

opendir CWD, $path;

while ($file = readdir(CWD)) {
    if ((-f "$path/$file") && ($file =~ m/$pat/oi) && ($file !~ m/$excl/i)) {
        push @files, "$path/$file";
    }
}

if (@files < 1) {
    print "dirtags: No taggable files found.\n";
    exit(1);
}

if (-e "$path/tags") {
    $tagTime = &GetDate("$path/tags");
}

$remakeTags = 0;

foreach $file (@files) {
    $fileTime = &GetDate($file);
    if ($fileTime > $tagTime) {
        $remakeTags = 1;
        last;
    }
}

if (!$remakeTags) {
    exit(0);
}

$fileList = join(" ", @files);

if (system("pctags -f $path/tags $fileList") != 0) {
    print STDERR "dirtags: failed to run pctags\n";
    exit(1);
}

sub GetDate
{
    my($filename) = $_[0];
    my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
       $atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);

    return $mtime;
}
__END__
:endofperl
