#!/usr/public/perl
# $Id: xipoffset.pl,v 1.1 96/09/11 14:54:24 andrew Exp $
###
# This is the inner loop of xipoffset. It traverses a file that contains a
# list of all the procedures within a resource and the offsets within the
# resource. It adds the offsets within the resource to the offset of the
# resource in the XIP image, and also prepends a geodename to the start of
# the procedure names.
#
# The pass parameters are:
#
# $ARGV[0] = geode name
# $ARGV[1] = resource offset (in HEX)
# $ARGV[2] = extra offset (in HEX)
# $ARGV[3] = file name
#
# We read in the file, which consists of:
# <routine name> <hex value>
#
# We produce output like so:
#
# <hex value + $ARGV[1] + $ARGV[2]> <$ARGV[0]::routine name>
#
open (INPUT, $ARGV[3]) || die "can't open $ARGV[3]";

while (<INPUT>) {
    ($routname, $offset) = /([^\s]+)\s+([0-9a-fA-F]+)/;
    $offset = hex($offset)+hex($ARGV[1])+hex($ARGV[2]);
    printf ("%07x $ARGV[0]::%s\n",$offset, $routname);
}
    
