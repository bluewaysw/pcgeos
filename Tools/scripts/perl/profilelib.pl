##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	profiling
# MODULE:	
# FILE: 	profilelib.pl
# AUTHOR: 	Steve Kertes, 1996
#
# USED BY:      phist, pfcalls, pftimes
#
# DESCRIPTION:
#
#  Profile Library
#  --------------
#    Library routines for dealing with the 20M file of profile data and
#    the symbol file:
#
#	   * A 20M data file that contains 5242880 (5M) 32-bit integers,
#	     in Intel-byte ordering. Each integer will correspond to the
#	     number of instructions executed at that memory location. 
#
#	   * A 22000 line file in the following format:
#
#		007e3c3 geos::FarDebugProcess
#		007e3c8 geos::FarDebugMemory
#		007e3cd geos::FarDebugLoadResource
#		...
#
#		The 7-digit hex number is the address of the procedure whose
#	name is listed on the right. It lists *all* the procedures in the
#	image.
#	
# 	$Id: profilelib.pl,v 1.3 96/09/18 14:56:31 cthomas Exp $
#
#
##############################################################################


############################################
#
# openProfile, openSymbols, openExtraSyms
#	open the various files
#
sub openProfile {
	local ($filename) = @_;
	open(PROFILE, "<$filename")
		|| die "Unable to open profile in file \"$filename\".\n";
}

sub openSymbols {
	local ($filename) = @_;
	open(SYMBOLS, "<$filename")
		|| die "Unable to open symbols in file \"$filename\".\n";
}

sub openExtraSyms {
	local ($filename) = @_;
	if ($filename ne "") {
		open(EXTRAS, "<$filename")
	               || die "Unable to open extras in file \"$filename\".\n";
		&parseExtraSymbols;
	}
}

############################################
#
# readInteger
#	pulls the next 4 bytes from the PROFILE file and
#	returns them as an intel-byte-order integer
#
#	returns undef if 4 bytes could not be read
#
$profilePos = 0;
sub readInteger {
	#print "$profilePos\n" if (!($profilePos % 0x100000));
	local ($fourBytes, $answer, $len);
	if (($len = read(PROFILE, $fourBytes, 4)) != 4) {
		print "**** did not read 4 bytes ****" if $opt_d;
		$profilePos += $len;
		return undef;
	} else {
	    if (!defined($answer = unpack("V",$fourBytes))) {
			#print STDERR sprintf("ERROR: unable to convert integer %x %x %x %x\n", unpack("CCCC", $fourBytes));
			#$answer = 0;
			die sprintf("unable to convert integer 0x%02x 0x%02x 0x%02x 0x%02x at 0x%x\n", unpack("CCCC", $fourBytes), $profilePos);
		}
		#print "Returning >>>$answer<<<<\n";
		$profilePos += $len;
		$answer;
	}
}

############################################
#
# readSymbol
#	reads a line from the SYMBOLS file and parses
#	the stuff:
#
#	007e3c3 geos::FarDebugProcess
#
#	returns (offset as an integer, the symbol string) or undef if we fail
#
sub readSymbol {
	local ($aLine);

	while ($aLine = <SYMBOLS>) {
		if ($aLine =~ /^\s*([\da-fA-F]+)\s+(\S*)$/) {
			return (hex($1), $2);
		}
	}
	return undef;
}

############################################
#
# parseExtraSymbols
#	read in and parse the EXTRAS file, basicly find the ignored
#	and labled blocks.
#	
#	right now entries look like this:
#	
#	000003a 00003d				[ an ignored block ]
#	000003b 00003d Vidio			[ a labled block ]
#	
#	
sub parseExtraSymbols {
	local ($aLine);

	while ($aLine = <EXTRAS>) {
		if ($aLine =~ /([\da-fA-F]+)\s+([\da-fA-F]+)\s+(.*)/ ) {
		   if ($3 eq "") {
			print "Ignoring address range " . hex($1) . " to " .
				hex($2) . "\n" if $opt_d;
			&addToIgnoreList(hex($1), hex($2));
		   } else {
			print "Creating labled block \"$3\" from " .
				hex($1) . " to " . hex($2) . "\n" if $opt_d;
			&addToLableList(hex($1), hex($2), $3);
		   }
		}
	}
}

############################################
#	
# addToIgnoreList
#	insert a new ignore block into @ignoreList.  entries
#	have two elements (start, end).  blocks are sorted
#	by start address, blocks that have the same start address
#	are combined.  overlapping blocks are ok.
#	
sub addToIgnoreList {
    local ($startIgnore, $endIgnore) = @_;
    #
    # we expect that the list is sorted, so add new items
    # to the end with insertion sort
    #
    if ($#ignoreList < 0) {
	@ignoreList = ($startIgnore, $endIgnore);
	return;
    }

    #print ("\tstart: $startIgnore  end: $endIgnore\n");
    for ($a = $#ignoreList-1 ; $a >= 0 ; $a-=2) {
	#print ("\ta: $a  $ignoreList[$a]  $ignoreList[$a+1]\n");
	if ($startIgnore > $ignoreList[$a]) {
	    # insert the new ignore after this element
	    splice (@ignoreList, $a+2, 0, ($startIgnore, $endIgnore));
            return;
	} elsif ($startIgnore == $ignoreList[$a]) {
	    # in this case keep the one with the larger $endIgnore
	    if ($ignoreList[$a+1] < $endIgnore) {
		$ignoreList[$a+1] = $endIgnore;
	    }
	    return
	}
    }
    # darn, it belongs at the front of the array
    unshift (@ignoreList, ($startIgnore, $endIgnore));
}

############################################
#
# addToLableList
#	insert a new labled block entry to the @lableList
#	entries are sorted by the start address of the block
#	each entry has 4 elements, (start, end, name, count)
#
sub addToLableList {
    local ($startLable, $endLable, $lable) = @_;
    #
    # we expect that the list is sorted, so add new items
    # to the end with insertion sort
    #

    #print ("\tstart: $startLable  end: $endLable  name: $lable\n");
    if ($#lableList < 0) {
	@lableList = ($startLable, $endLable, $lable, 0);
	return;
    }

    for ($a = $#lableList-3 ; $a >= 0 ; $a-=4) {
	#print ("\ta: $a $lableList[$a] $lableList[$a+1] $lableList[$a+2]\n");
	if ($startLable > $lableList[$a]) {
	    # insert the new lable after this element
	    splice (@lableList, $a+4, 0, ($startLable, $endLable, $lable, 0));
            return;
	}
    }
    # darn, it belongs at the front of the array
    unshift (@lableList, ($startLable, $endLable, $lable, 0));
}

############################################
#
# isThisAddressIgnored
#	return true if passed address is inside an ignore block.
#	also removes any ignore blocks whose end-address is less
#	than the passed address, so at some point the @ignoreList
#	will probably be empty.
#	
sub isThisAddressIgnored {
	local ($thisAddress) = @_;
	local ($a);
	#
	#  if there is no ignoreList then this is real simple
	# 
	return 0 if $#ignoreList < 0;

	#
	# the list is sorted, so we only have to check to see if we
	# are above the value at the front of the ignoreList and less
	# than the second value in the array
	#
	if ($thisAddress >= $ignoreList[0]) {
	    if ($thisAddress > $ignoreList[1]) {
		# we are out of the current ignore block, so get rid of it
		print ("out of ignore block\n") if $opt_d;
		shift @ignoreList; shift @ignoreList;

		# we might be in the next ignore block...
		return &isThisAddressIgnored($thisAddress);
	    }

	    print "*** Ignoring address $thisAddress\n" if $opt_d;
	    return 1;
	}

	# not in ignored range, so return false
	return 0;
}

############################################
#
# checkForLabledBlock
#	searches all the labled blocks to see if the passed
#	address is contained in them, if they are then the
#	count is added to that blocks count
#
#	NOTE:
#	right now every entry in the array is checked for a match until
#	thisAddress is below the start value of a block. blocks whose
#	end values are below thisAddress do not need to be checked ever
#	again, but they are.  this might be worth fixing some day...
#
sub checkForLabledBlock {
	local ($newCount, $thisAddress) = @_;
	local ($a);
	#
	# blocks can overlap, so check until we get one that
	# does not work at all
	# 
	for ($a = 0 ; $a < $#lableList ; $a += 4) {
	    #print "$thisAddress checking $lableList[$a] $lableList[$a+1] " .
		#"$lableList[$a+2] $lableList[$a]\n";

	    last if $lableList[$a] > $thisAddress;

	    # we know we are above the start of this block, check the end
	    if ($lableList[$a+1] >= $thisAddress) {
		$lableList[$a+3] += $newCount;
	    }
	}

}

############################################
#
# printIgnoredAndLabledLists
#	what more can I say?
#	
sub printIgnoredAndLabledLists {
    local ($oldSeperator);
    $oldSeperator = $,;
    $, = " ";
    print @ignoreList;
    print "\n";
    print @lableList;
    print "\n";
    $, = $oldSeperator;
}

# everything is fine, so return non-zero
1;
