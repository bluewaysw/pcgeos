#!/usr/public/perl

# This script makes the .plt file for the DOS SDK.
# Run this script from the Installed directory of whatever branch
# you're building the SDK from.

# Be sure to weed out the "I have no idea"'s this script, usually 
# caused by missing .geo files. 
 
open(FIND, "find Library -name \*.ldf -print |") || die "Couldn't run find: $!\n";
 
while (<FIND>) {
        s/\.ldf/\.geo/g;
        $geofile = $_;
 
        if (!open (DUMPGEO, "dumpgeo $geofile |")) {
                print "Can't dumpgeo $geofile!\n";
        } else {
                $geofile =~ /.*\/([^\/]+).geo$/;
                $georoot = $1;
                        if (length ($georoot) > 7) {
                        print "$georoot\t";
                } else {
                        print "$georoot\t\t";
                }
                $proto = "I have no idea.";
                while (<DUMPGEO>) {
                        if (/Protocol: (\d+)\.(\d+)/) {
                                $proto = "$1\t$2"
                        }
                }
                print "$proto\n";
        }
}
