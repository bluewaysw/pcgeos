##############################################################################
#
# 	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	ramdisk.tcl
# AUTHOR: 	Adam de Boor, Apr 30, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/30/93		Initial Revision
#
# DESCRIPTION:
#	functions for messing with the RAM disk or DOS on the Zoomer
#
#	$Id: ramdisk.tcl,v 1.4 95/03/15 14:53:10 tony Exp $
#
 ##############################################################################

defvar rambase 655360
# drive B:
defvar base_driveb 65536
# drive C: for sram card
defvar base_sram 0x4000000
# drive C: for dual-drive sram card
defvar base_dd_sram_c 0x4000200
# drive D: for dual-drive sram card
defvar base_dd_sram_d 0x4020200

##############################################################################
#				mapram
##############################################################################
#
# SYNOPSIS:	Map a particular byte offset of the RAM disk to the 16K bank
#		at d400h.
# PASS:		val 	= byte offset from start of RAM disk
#   	    	offVar	= name of variable to receive the offset from d400h
#			  at which the byte requested is located.
# CALLED BY:	INTERNAL
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/30/93		Initial Revision
#
##############################################################################
[defsubr mapram {val offVar}
{
    var a [expr [uplevel 0 var rambase]+($val)]
    uplevel 1 var off [expr $a%16384]
    var b [expr $a/16384]
    var cur [index [io w aah] 0]
    if {$cur != $b} {
    	# flush the data cache
    	dcache bsize [index [dcache params] 0]
    }
    io w aah $b
}]

##############################################################################
#				mapprotect
##############################################################################
#
# SYNOPSIS:	Execute a Tcl command while ensuring that the mapping of
#		the d400h bank gets restored no matter what happens.
# PASS:		command	= command string to execute
# CALLED BY:	INTERNAL
# RETURN:	what the command returns
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/30/93		Initial Revision
#
##############################################################################

[defsubr mapprotect {command}
{
    var mapReg [index [io w aah] 0]
    protect {
    	var retval [uplevel 1 eval $command]
    } {
    	if {![null $mapReg]} {
	    io w aah $mapReg
    	}
    }
    return $retval
}]
	
##############################################################################
#				brs
##############################################################################
#
# SYNOPSIS:	Print the bytes that make up a RAM disk sector
# PASS:		snum	= sector number
#   	    	[count]	= number of bytes to print, or, if type is given
#			  number of them to print
#   	    	[type]	= data type found at the start of the sector
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/30/93		Initial Revision
#
##############################################################################

[defsubr brs {snum {count {}} {type {}}}
{
    ramdisk-get-geometry
    mapprotect {
    	mapram $snum*$secsize off
	
	if {[null $type]} {
	    if {[null $count]} {
	    	bytes d400h:$off $secsize
    	    } else {
    	    	bytes d400h:$off [getvalue $count]
    	    }
    	} elif {[null $count]} {
    	    print $type d400h:$off
    	} else {
    	    print $type d400h:$off#$count
    	}
    }
}]
    
##############################################################################
#				brs
##############################################################################
#
# SYNOPSIS:	Print the bytes that make up a RAM disk cluster (has 1 sector
#		per cluster)
# PASS:		clust	= cluster number
#   	    	[count]	= number of bytes to print, or, if type is given
#			  number of them to print
#   	    	[type]	= data type found at the start of the cluster
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/30/93		Initial Revision
#
##############################################################################
[defsubr brc {clust {count {}} {type {}}}
{
    ramdisk-get-geometry
    mapprotect {
    	mapram (($clust-2+$startfiles)*$secsize) off
	if {[null $type]} {
	    if {[null $count]} {
	    	bytes d400h:$off $secsize
    	    } else {
    	    	bytes d400h:$off [getvalue $count]
    	    }
    	} elif {[null $count]} {
    	    print $type d400h:$off
    	} else {
    	    print $type d400h:$off#$count
    	}
    }
}]

##############################################################################
#				clist
##############################################################################
#
# SYNOPSIS:	Return the list of clusters that make up a file, given
#		the starting cluster.
# PASS:		start	= starting cluster
#   	    	verbose	= non-zero if should print out each cluster as it
#			  is found, so you can tell if the FAT is trashed
# CALLED BY:	INTERNAL/USER
# RETURN:	list of clusters that make up the file
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/30/93		Initial Revision
#
##############################################################################

[defsubr clist {start {verbose 0}}
{
    ramdisk-get-geometry

    var list $start clust $start
    [for {} {1} {}
    {
	if {$verbose} {
	    echo -n $clust...
	    flush-output
	}
    	var bnum [expr $clust*3/2]
	var s [expr 1+($bnum/$secsize)]
	var o [expr $bnum%$secsize]
	mapprotect {
	    mapram ($s*$secsize) off
	    var b1 [value fetch d400h:$off+$o byte]
	    if {$off == 16383} {
	    	mapram ($s+1)*$secsize off
		var b2 [value fetch d400h:$off byte]
    	    } else {
	    	var b2 [value fetch d400h:($off+$o+1) byte]
    	    }
    	}
    	if {$clust & 1} {
	    var clust [expr ((($b2<<8)|$b1)>>4)&0xfff]
    	} else {
	    var clust [expr (($b2<<8)|$b1)&0xfff]
    	}
    	if {$clust != 0xfff} {
	    var list [concat $list [list $clust]]
    	} else {
    	    break
    	}
    }]
    
    return $list
}]

##############################################################################
#				rls
##############################################################################
#
# SYNOPSIS:	List the contents of a directory on the RAM disk, given its
#		starting cluster.
# PASS:		start	= starting cluster
# CALLED BY:	USER
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/30/93		Initial Revision
#
##############################################################################
[defsubr rls {{start 0}}
{
    ramdisk-get-geometry

    var det [symbol find type geos::RootDirEntry]
    var t [type make array [expr $secsize/[type size $det]] $det]

    if {$start == 0} {
    	var sects {}
	for {var s $rootdir} {$s < $rootdir+$rootsize} {var s [expr $s+1]} {
	    var sects [concat $sects $s]
    	}
    } else {
    	var sects [clist-to-slist [clist $start]]
    }
    foreach s $sects {
    	mapprotect {
	    mapram ($s*$secsize) off
	    var ents [value fetch d400h:$off $t]
    	}
	foreach e $ents {
	    if {[string c [index [field $e RDE_filename] 0] {\000}]} {
		echo [format {"%s.%s" at %4d, %5d bytes}
			[mapconcat c [field $e RDE_filename] {var c}]
			[mapconcat c [field $e RDE_extension] {var c}]
			[field $e RDE_startCluster]
			[field $e RDE_fileSize]]
    	    }
    	}
    }
}]

##############################################################################
#				clist-to-slist
##############################################################################
#
# SYNOPSIS:	Convert a list of clusters to a list of sectors
# PASS:		clist	= list of clusters
#   	    	ramdisk-get-geometry called by caller
# CALLED BY:	INTERNAL
# RETURN:	list of sectors that correspond to the clusters
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/10/93		Initial Revision
#
##############################################################################
[defsubr clist-to-slist {clist}
{
    var clustsize [uplevel 1 var clustsize]

    return [eval [concat concat [map c $clist {
    	var slist {}
    	[for {var s [expr $c-2+[uplevel 1 var startfiles]] i $clustsize}
	     {$i > 0}
	     {var s [expr $s+1] i [expr $i-1]}
    	{
	    var slist [concat $slist $s]
    	}]
	var slist
    }]]]
}]
	     
##############################################################################
#				ramdisk-get-geometry
##############################################################################
#
# SYNOPSIS:	Fetch the boot sector of the disk and define variables in
#		our caller that reflect the geometry of the disk in question
# PASS:		nothing
# CALLED BY:	INTERNAL
# RETURN:	the following variables set:
#   	    	    secsize 	= size of a sector
#   	    	    rootdir 	= starting sector of root directory
#   	    	    rootsize	= number of sectors in the root directory
#   	    	    startfiles	= starting sector of files area (cluster 2)
#   	    	    clustsize	= sectors per cluster
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/10/93		Initial Revision
#
##############################################################################
[defsubr ramdisk-get-geometry {}
{
    mapprotect {
    	mapram 0 off
	var secsize [value fetch d400h:$off.BS_bpbSectorSize]
	var clustsize [value fetch d400h:$off.BS_bpbClusterSize]
	var rootdir [expr [value fetch d400h:$off.BS_bpbNumReserved]+[value fetch d400h:$off.BS_bpbNumFATs]*[value fetch d400h:$off.BS_bpbFATSize]]
	var rootsize [expr [value fetch d400h:$off.BS_bpbNumRootDirs]*[type size [symbol find type geos::RootDirEntry]]/$secsize]
	var startfiles [expr $rootdir+$rootsize]
    }
    [uplevel 1 var secsize $secsize clustsize $clustsize rootdir $rootdir
		   rootsize $rootsize startfiles $startfiles]
}]

##############################################################################
#				rfile
##############################################################################
#
# SYNOPSIS:	Print out the contents of a file, given its starting cluster
#   	    	number.
# PASS:		start	= starting cluster
#   	    	[size]	= size of the file, if known (won't print the 
#			  uninvolved parts of the final cluster, if given)
# CALLED BY:	USER
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/30/93		Initial Revision
#
##############################################################################
[defsubr rfile {start {size 0}}
{
    ramdisk-get-geometry
    var o 0
    foreach c [clist $start] {
	if {$size == 0} {
	    var n $secsize
	} else {
	    var n [expr $size-$o]
	    if {$n > $secsize} {
		var n $secsize
	    }
	}
    	var t [type make array $n [type byte]]
	mapprotect {
	    mapram ($c-2+$startfiles)*$secsize off
	    var bytes [value fetch d400h:$off $t]
	}
	type delete $t
	fmt-bytes $bytes 0 $n 0
	var o [expr $o+$n]
    }
}]

##############################################################################
#				bufcache
##############################################################################
#
# SYNOPSIS:	Dump DOS's buffer cache.
# PASS:		nothing
# CALLED BY:	USER
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/30/93		Initial Revision
#
##############################################################################
[defsubr bufcache {}
{
    global DOSTables

    protect {
    	#
	# Define the structure of a buffer cache element
	#
    	var bd [type make pstruct
    	    	    next [type make fptr [type void]]
		    drive [type byte]
		    flags [type make struct
    	    	    	u1 [type byte] 7 1
			dirty [type byte] 6 1
			ref [type byte] 5 1
			u2 [type byte] 4 1
			isdata [type byte] 3 1
			isdir [type byte] 2 1
			isfat [type byte] 1 1
			isboot [type byte] 0 1]
		    sector [type word]
		    numCopies [type byte]
		    sectorOff [type byte]
		    dcb [type make fptr [symbol find type DeviceControlBlock]]
		    unknown [type word]]
    	var dataOff 16
	#
	# Fetch the head of the cache
	#
    	var head [value fetch ($DOSTables).DLOL_cache]

    	echo {Addr      Drv Sect  Clust   (#/offset)  Flags}
    	echo {--------- --- ----  -----   ----------  -----}
	

	[for {var s [expr ($head>>16)&0xffff] o [expr $head&0xffff]}
	     {$o != 0xffff}
	     {var s [expr ($next>>16)&0xffff] o [expr $next&0xffff]}
	{
    	    #
	    # Figure the segment and offset and fetch the element
	    #
	    var d [value fetch $s:$o $bd]
	    var next [field $d next]
	    #
	    # Determine the drive or if the thing isn't in-use
	    #
	    if {[field $d drive] == 255} {
    	    	echo [format {%04x:%04x  %s  %4s  %6s  (%s/%2s)      %s/%s/%s}
			$s $o - - - - - - - -]
    	    } else {
	    	var drive [format %c [expr [field $d drive]+65]]
		var flags [field $d flags]

		if [field $flags isdata] {
		    #
		    # Figure the cluster number from the DCB info
		    #
		    var dcb [field $d dcb]
		    var ds [expr ($dcb>>16)&0xffff] do [expr $dcb&0xffff]
		    var cs [value fetch $ds:$do.DCB_clusterShift]
		    var fs [expr [field $d sector]-[value fetch $ds:$do.DCB_startFilesArea]]
		    var cluster [format {%4.2f} [expr $fs/[expr 1<<$cs]+2 f]]
		} else {
		    var cluster n/a
		}
		echo [format {%04x:%04x  %s  %4d  %6s  (%d/%2d)      %s/%s/%s}
			$s $o $drive
			[field $d sector]
			$cluster
			[field $d numCopies]
			[field $d sectorOff]
			[if [field $flags dirty] {format D} {format C}]
			[if [field $flags ref] {format R} {format U}]
			[if [field $flags isdata] {format data}
			    {[if [field $flags isdir] {format dir}
				{[if [field $flags isfat] {format FAT}
				    {[if [field $flags isboot] {format boot}]}]}]}]]
    	    }
    	}]
    } {
    	if {![null $bd]} {
    	    type delete $bd
    	}
    }
}]

[defsubr bufcache4 {}
{
    global DOSTables

    protect {
    	#
	# Define the structure of a buffer cache element
	#
    	var bd [type make pstruct
    	    	    next [type make nptr [type void]]
		    prev [type make nptr [type void]]
		    drive [type byte]
		    flags [type make struct
    	    	    	remote [type byte] 7 1
			dirty [type byte] 6 1
			ref [type byte] 5 1
			search [type byte] 4 1
			isdata [type byte] 3 1
			isdir [type byte] 2 1
			isfat [type byte] 1 1
			isboot [type byte] 0 1]
		    sector [type dword]
		    numCopies [type byte]
		    sectorOff [type word]
		    dcb [type make fptr [symbol find type DeviceControlBlock]]
	  	    refcount [type word]
		    unknown [type byte]]
    	var dataOff 20
	#
	# Fetch the head of the cache
	#
    	var head [value fetch ($DOSTables).DLOL_cache]
	var bufinfo [expr ($head>>16)&0xffff]:[expr $head&0xffff]
	var chainhead [value fetch $bufinfo dword]
   	var numchains [value fetch $bufinfo+4 word]

	var chainarr [expr ($chainhead>>16)&0xffff]:[expr $chainhead&0xffff]
	echo numchains = $numchains array = $chainarr

    	echo {Addr      Drv Sect  Clust   (#/offset)  Flags}
    	echo {--------- --- ----  -----   ----------  -----}
	
	while {$numchains > 0} {
	    #
	    # fetch number of buffers in this chain
	    #
	    var s [value fetch $chainhead+4 word]
	    var o [value fetch $chainhead+2 word]

	    [for {var d [value fetch $s:$o $bd]
		  var next [field $d next]}
		 {$next != 0xffff}
		 {var o $next
		  var d [value fetch $s:$o $bd]
		  var next [field $d next]}
	    {
		#
		# Determine the drive or if the thing isn't in-use
		#
		if {[field $d drive] == 255} {
		    echo [format {%04x:%04x  %s  %4s  %6s  (%s/%2s)      %s/%s/%s}
			    $s $o - - - - - - - -]
		} else {
		    var drive [format %c [expr [field $d drive]+65]]
		    var flags [field $d flags]

		    if [field $flags isdata] {
			#
			# Figure the cluster number from the DCB info
			#
			var dcb [field $d dcb]
			var ds [expr ($dcb>>16)&0xffff] do [expr $dcb&0xffff]
			var cs [value fetch $ds:$do.DCB_clusterShift]
			var fs [expr [field $d sector]-[value fetch $ds:$do.DCB_startFilesArea]]
			var cluster [format {%4.2f} [expr $fs/[expr 1<<$cs]+2 f]]
		    } else {
			var cluster n/a
		    }
		    echo [format {%04x:%04x  %s  %4d  %6s  (%d/%2d)      %s/%s/%s}
			    $s $o $drive
			    [field $d sector]
			    $cluster
			    [field $d numCopies]
			    [field $d sectorOff]
			    [if [field $flags dirty] {format D} {format C}]
			    [if [field $flags ref] {format R} {format U}]
			    [if [field $flags isdata] {format data}
				{[if [field $flags isdir] {format dir}
				    {[if [field $flags isfat] {format FAT}
					{[if [field $flags isboot] {format boot}]}]}]}]]
		}
	    }]
    	}
    } {
    	if {![null $bd]} {
    	    type delete $bd
    	}
    }
}]

[defsubr bufcache6 {}
{
    global DOSTables

    protect {
    	#
	# Define the structure of a buffer cache element
	#
    	var bd [type make pstruct
    	    	    next [type make nptr [type void]]
		    prev [type make nptr [type void]]
		    drive [type byte]
		    flags [type make struct
    	    	    	remote [type byte] 7 1
			dirty [type byte] 6 1
			ref [type byte] 5 1
			search [type byte] 4 1
			isdata [type byte] 3 1
			isdir [type byte] 2 1
			isfat [type byte] 1 1
			isboot [type byte] 0 1]
		    sector [type dword]
		    numCopies [type byte]
		    sectorOff [type word]
		    dcb [type make fptr [symbol find type DeviceControlBlock]]
	  	    refcount [type word]
		    unknown [type byte]]
    	var dataOff 20
	#
	# Fetch the head of the cache
	#
    	var head [value fetch ($DOSTables).DLOL_cache]
	var bufinfo [expr ($head>>16)&0xffff]:[expr $head&0xffff]

    	echo {Addr      Drv Sect  Clust   (#/offset)  Flags}
    	echo {--------- --- ----  -----   ----------  -----}

	#
	# fetch number of buffers in this chain
	#
	var s [value fetch $bufinfo+2 word]
	var o [value fetch $bufinfo word]
    	var first $o
        var beginning 1

	[for {var d [value fetch $s:$o $bd]
	      var next [field $d next]}
	     {($o != $first) || $beginning}
	     {var o $next
	      var d [value fetch $s:$o $bd]
	      var next [field $d next]}
	{
    	    var beginning 0
	    #
	    # Determine the drive or if the thing isn't in-use
	    #
	    if {[field $d drive] == 255} {
		echo [format {%04x:%04x  %s  %6s  %7s  (%s/%3s)      %s/%s/%s}
			$s $o - - - - - - - -]
	    } else {
		var drive [format %c [expr [field $d drive]+65]]
		var flags [field $d flags]

		if [field $flags isdata] {
		    #
		    # Figure the cluster number from the DCB info
		    #
		    var dcb [field $d dcb]
		    var ds [expr ($dcb>>16)&0xffff] do [expr $dcb&0xffff]
		    var cs [value fetch $ds:$do.DCB_clusterShift]
		    var fs [expr [field $d sector]-[value fetch $ds:$do.DCB_startFilesArea]]
		    var cluster [format {%4.2f} [expr $fs/[expr 1<<$cs]+2 f]]
		} else {
		    var cluster n/a
		}
		echo [format {%04x:%04x  %s  %6d  %7s  (%d/%3d)      %s/%s/%s}
			$s $o $drive
			[field $d sector]
			$cluster
			[field $d numCopies]
			[field $d sectorOff]
			[if [field $flags dirty] {format D} {format C}]
			[if [field $flags ref] {format R} {format U}]
			[if [field $flags isdata] {format data}
			    {[if [field $flags isdir] {format dir}
				{[if [field $flags isfat] {format FAT}
				    {[if [field $flags isboot] {format boot}]}]}]}]]
	    }
	    }]
    } {
    	if {![null $bd]} {
    	    type delete $bd
    	}
    }
}]
