#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FindBin;

# Run with: perl Tools/build/product/bbxensem/Tests/version.pl
my $root = abs_path("$FindBin::Bin/../../../../..");
my $tmp = tempdir(CLEANUP => 1);
local $ENV{ROOT_DIR} = $root;
local $ENV{versionTag} = 'BLD1614';
local $ENV{layoutInstallRoot} = 'ENSEMBLE/FREEGEOS/BLD1614/SETUP/INSTALL';

for my $target ('fg', 'ntbbx') {
    for my $ec ('false', 'true') {
        my $dest = "$tmp/$target-$ec";
        open my $pipe, '-|', $^X, "$root/Tools/build/build/build.pl",
            "$root/Tools/build/product/bbxensem/$target.build",
            'shipfiles=true', 'sendTemplateOnly=true', 'makeImages=false',
            "sourceDirs=$root", 'language=english', "desttree=$dest",
            "ec=$ec" or die "Cannot start template build: $!\n";
        my $log = do { local $/; <$pipe> };
        close $pipe or die $log;
        $log =~ /No errors\./ or die $log;

        my $path = "$dest/localpc/ENSEMBLE";
        $path .= '/FREEGEOS/BLD1614/SETUP/ACTIVATE' if $target eq 'fg';
        open my $file, '<:raw', "$path/VERSION.TXT" or die "$path: $!\n";
        my $version = do { local $/; <$file> };
        close $file;
        $version =~ /\r\nPC\/GEOS Build 1614\r\n\z/
            or die "Wrong version text: $version\n";
        $version !~ /(?:VAR\(|ENVAR\(|Build:|Basebox|Version BLD)/
            or die "Unexpected version metadata: $version\n";
        !-e "$dest/gfs/FG/VERSION.TXT"
            or die "FreeGEOS version file is still in the GFS tree\n";
        print "PASS: $target EC=$ec version payload\n";
    }
}
