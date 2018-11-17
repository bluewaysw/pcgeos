#############################################################################
#
# 	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	objcount.tcl
# AUTHOR: 	Brian Chin, Jan 30, 1991
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	objcount	    	Walk the heap, counting up objects
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	brianc	1/30/91		Initial Revision
#	brianc	1/13/92		update for 2.0, new UI stuff
#
# DESCRIPTION:
#
#	$Id: objcount.tcl,v 1.11.11.1 97/03/29 11:26:20 canavese Exp $
#
###############################################################################

require	vardaddr pvardata.tcl

#
# return size of instance data defined explicitly for this class (excludes
# size of inherited instance data)
#
[defsubr instance-size {class}
{
    #
    # return (our instance size - superclass instance size)
    #
    var ourSize [value fetch [sym fullname $class].Class_instanceSize]
    var super [index [sym get $class] 4]
    var superFlags [index [sym get $class] 3]
    #
    # in case no superclass
    #
    if {[null $super]
		|| ![string compare $superFlags master]
		|| ![string compare $superFlags variant]} {
        var superSize 0
    } else {
        var superSize [value fetch [sym fullname $super].Class_instanceSize]
    }
    return [expr ($ourSize-$superSize)]
}]

#
# global counter array
#
defvar _ca {}
defvar _ocIndent 0

#
# update extra info
#
# pass:
#    class - class of object
#    obj - object
#    info - current extra info (a list)
#		(=nil if no extra info yet)
# return:
#    new extra info (a list)
#
# if MetaClass (all objects), extra info = {vardata-count vardata-size}
#
# if GenClass, extra info = {moniker-count moniker-size
#				moniker-list-count moniker-list-size
#				moniker-item-count moniker-item-size
#				vardata-count vardata-size}
# if VisTextClass, extra info = {text-count text-size}
#
# add other classes with extra info here
#
[defsubr update-extra {obj class info}
{
    var className [sym name $class]
    var objAddr [addr-parse $obj]
    var objSeg [handle segment [index $objAddr 0]]
    var objOff [index $objAddr 1]
    #
    # MetaClass - var data
    #
    if {![string compare $className MetaClass]} {
	if {[null $info]} {
	    var vardataCount 0
	    var vardataSize 0
	} else {
	    var vardataCount [index $info 0]
	    var vardataSize [index $info 1]
	}
	var thisVarDataSize [vardsize $objSeg:$objOff]
	if {$thisVarDataSize != 0} {
	    var vardataCount [expr $vardataCount+1]
	    var vardataSize [expr $vardataSize+$thisVarDataSize]
	}
        var newInfo [list $vardataCount $vardataSize]
    }
    #
    # GenClass - monikers
    #
    if {![string compare $className GenClass]} {
        var monikerChunk [value fetch (($obj)+[value fetch ($obj).ui::Gen_offset]).ui::GI_visMoniker word]
	if {[null $info]} {
	    var monikerCount 0
	    var monikerSize 0
	    var monikerListCount 0
	    var monikerListSize 0
	    var monikerItemCount 0
	    var monikerItemSize 0
	    var vardataCount 0
	    var vardataSize 0
	} else {
	    var monikerCount [index $info 0]
	    var monikerSize [index $info 1]
	    var monikerListCount [index $info 2]
	    var monikerListSize [index $info 3]
	    var monikerItemCount [index $info 4]
	    var monikerItemSize [index $info 5]
	    var vardataCount [index $info 6]
	    var vardataSize [index $info 7]
	}
	# get offset of end of object
	var vardataEnd [expr [chunk-size $objSeg $objOff]-2]
	var vardataEnd [expr $vardataEnd+$objOff]
	# size of any vardata = end of object chunk - start of vardata
	var vardataStart [vardaddr $obj]
    	if {$varDataStart == -1} {
	    var vardataCount 0
	    var vardataSize 0
    	} elif {[expr $vardataEnd-$vardataStart] != 0} {
	    var vardataCount [expr $vardataCount+1]
	    var vardataSize [expr $vardataSize+[expr $vardataEnd-$vardataStart]]
	}

	if {$monikerChunk != 0} {
	    var monikerAddr [value fetch $objSeg:$monikerChunk word]
	    var monikerType [value fetch $objSeg:$monikerAddr.ui::VM_type ui::VisMonikerType]
	    if {[field $monikerType VMT_MONIKER_LIST] == 1} {
		#
		# deal with moniker list
		#
		var monikerListCount [expr $monikerListCount+1]
		var sz [chunk-size $objSeg $monikerAddr]
		var monikerListSize [expr $monikerListSize+$sz]
		var off $monikerAddr
		var listEntrySize [type size
				    [symbol find type ui::VisMonikerListEntry]]
		#
		# loop through monikers in moniker list and add the size
		# of each one that is in-memory to $monikerSize
		#
		for {var sz [value fetch $objSeg:$off-2 word]} {$sz != 2} {var sz [expr $sz-$listEntrySize]} {
		    var monItemHandle [value fetch $objSeg:$off.ui::VMLE_moniker.handle]
		    var monItemBlockInfo [value fetch kdata:$monItemHandle HandleMem]
		    var monItemSeg [field $monItemBlockInfo HM_addr]
		    var monItemChunk [value fetch $objSeg:$off.ui::VMLE_moniker.chunk]
		    if {$monItemSeg != 0} {
			var monikerItemCount [expr $monikerItemCount+1]
			var monItemAddr [value fetch $monItemSeg:$monItemChunk word]
			var monikerItemSize [expr $monikerItemSize+[chunk-size $monItemSeg $monItemAddr]]
		    }
		    var off [expr $off+$listEntrySize]
		#
		# for {var sz [value fetch $objSeg:$off-2 word]}
		}
	    } else {
		#
		# deal with simple moniker
		#
		var monikerCount [expr $monikerCount+1]
		var monikerSize [expr $monikerSize+[chunk-size $objSeg $monikerAddr]]
	    }
	}
	var newInfo [list $monikerCount $monikerSize
				$monikerListCount $monikerListSize
				$monikerItemCount $monikerItemSize
				$vardataCount $vardataSize]
    }
    #
    # VisTextClass - text
    #
    if {![string compare $className VisTextClass]} {
        var textChunk [value fetch (($obj)+[value fetch ($obj).ui::Vis_offset]).text::VTI_text word]
	if {[null $info]} {
	    var textCount 0
	    var textSize 0
	} else {
	    var textCount [index $info 0]
	    var textSize [index $info 1]
	}
	if {$textChunk != 0} {
	    var textCount [expr $textCount+1]
	    var textAddr [value fetch $objSeg:$textChunk word]
	    var textSize [expr $textSize+[chunk-size $objSeg $textAddr]]
	}
        var newInfo [list $textCount $textSize]
    }
    #add other classes' extra info here
    return $newInfo
}]

#
# routine to check if object is in given class
#
[defsubr checkclass-callback {class obj checkClass}
{
    if {![string compare [sym name $class] $checkClass]} {
	#
	# match, return non-null to stop
	#
	return 1
    } else {
	#
	# no match, return nil to continue up class tree
	#
	return {}
    }
}]

#
# update count-array (_ca) entry or add new count-array (_ca) entry
# for this class
#
# array item format:
#   {class direct-reference-counter indirect-reference-counter extra-info}
#
# pass:
#   class - class in array to update
#   obj - object
#   topClass - top-level class of object (used to determine whether to update
#		direct-reference-counter or indirect-reference-counter
#   verboseFlags - 000 for no verbose info (status output only)
#		   001 for no verbose info (no status output)
#		   01x for verbose info on search
#		   10x for general verbosity
#		   11x for both general and search verbose info
# return:
#   updated array
#
[defsubr objcount-callback {class obj topClass verboseFlags}
{
    global _ca
    global _ocIndent
    var nca nil
    var found 0
    var verboseSearch [index $verboseFlags 1 char]
    var quiet [index $verboseFlags 2 char]

    if {$verboseFlags == 000} {
	if {![string compare $class $topClass]} {
	    echo -n {,}
	} else {
	    echo -n {;}
	}
	flush-output
    }

    if {[index $verboseFlags 0 char]} {
	echo [format {%*scurrent class is %s} [expr $_ocIndent+8] {}
						[sym name $class]]
    }
    var _ocIndent [expr $_ocIndent+2]

    if {$verboseSearch} {
	echo -n {        searching for }
	echo -n $class
	echo { in:}
	echo -n {        }
	echo $_ca
    }

    #
    # search current count-array entries
    #
    foreach i $_ca {

	if {$verboseSearch} {
	    echo -n {            checking: }
	    echo $i
	}

	if {![string compare [index $i 0] $class]} {

	    if {$verboseSearch} {
		echo {            updating item...}
	    }

	    if {![null $nca]} {
		#
		# update array items 2-n
		#
		if {![string compare $class $topClass]} {
		    #
		    # update direct-count
		    #
		    var nca [concat $nca [list [list $class
						[expr [index $i 1]+1]
						[index $i 2]
						[update-extra $obj $class
							    [index $i 3]] ]]]
		} else {
		    #
		    # update indirect-count
		    #
		    var nca [concat $nca [list [list $class
						[index $i 1]
						[expr [index $i 2]+1]
						[update-extra $obj $class
							    [index $i 3]] ]]]
		}
	    } else {
		#
		# update first item in array
		#
		if {![string compare $class $topClass]} {
		    #
		    # update direct-count
		    #
		    var nca [list [list $class
					[expr [index $i 1]+1]
					[index $i 2]
					[update-extra $obj $class
							[index $i 3]] ]]
		} else {
		    #
		    # update indirect count
		    #
		    var nca [list [list $class
					[index $i 1]
					[expr [index $i 2]+1]
					[update-extra $obj $class
							[index $i 3]] ]]
		}
	    }
	    var found 1
	} else {

	    if {$verboseSearch} {
		echo {            copying item...}
	    }

	    if {![null $nca]} {
		#
		# copy array items 2-n
		#
	        var nca [concat $nca [list $i]]
	    } else {
		#
		# copy first item in array
		#
		var nca [list $i]
	    }
	}

	if {$verboseSearch} {
	    echo -n {                }
	    echo $nca
	}

    }

    #
    # if not found, add new count-array entry
    #
    if {!($found)} {

        if {$verboseSearch} {
	    echo {            adding item...}
	}

	if {![null $nca]} {
	    #
	    # add array item 2-n
	    #
	    if {![string compare $class $topClass]} {
		#
		# adding item for direct count
		#
	        var nca [concat $nca
				[list [list $class 1 0
					[update-extra $obj $class nil]]]]
	    } else {
		#
		# adding item for indirect count
		#
	        var nca [concat $nca
				[list [list $class 0 1
					[update-extra $obj $class nil]]]]
	    }
	} else {
	    #
	    # add first item in array
	    #
	    if {![string compare $class $topClass]} {
		#
		# adding item for direct count
		#
	        var nca [list [list $class 1 0 [update-extra $obj $class nil]]]
	    } else {
		#
		# adding item for indirect count
		#
	        var nca [list [list $class 0 1 [update-extra $obj $class nil]]]
	    }
	}

	if {$verboseSearch} {
	    echo -n {                }
	    echo $nca
	}

    }
    #
    # update global count array
    #
    var _ca $nca
}]

##############################################################################
#				objcount
##############################################################################
#
# SYNOPSIS:	Count up objects on the heap.
# PASS:		
# CALLED BY:	the user
# RETURN:	nothing
# SIDE EFFECTS:
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	brianc	1/31/91		Initial Revision
#
##############################################################################
[defcommand objcount {args} {system.heap profile}
{Usage:
    objcount [-q] [-X] [-Y] [-b #] [-o #] [-p #]

Examples:
    "objcount"				count all objects
    "objcount -p welcome"		count all objects owned by welcome
    "objcount -o *desktop::DiskDrives"	count this one object
    "objcount -b 0x3270"		count all objects in this block

Synopsis:
    Count up instances of various objects on the heap.

Notes:
    * The first argument specifies the options:
        q	quiet operation - no progress output (not applicable with X, Y)
        o #	check only object #
        b #	check ONLY block #
        p #	check only blocks for patient #
        c #	check only objects of class #
        C #	check only objects of top-level class #
        X	show general verbose info
        Y	show search verbose info

    * Output fields:
       direct - number of direct instances of this class
       indirect - number if indirect instance of this class (i.e object's
	          superclass is this class)
       size - total size of instance data for this class (excludes instance
	      data inherited from superclass)

    * Status output:
       . - processing heap block
       , - processing matching object's top-level class
       ; - processing matching object's non-top-level class

See also:
    hwalk, objwalk, lhwalk
}
{
    global _ca
    global _ocIndent
    #
    # deal with arguments
    #
    var quiet 0 verboseGen 0 verboseSearch 0
    var start [value fetch loaderVars.KLV_handleBottomBlock]
    var owner nil
    var onlyBlock nil
    var onlyObject nil
    var classToCheck nil
    var topClassToCheck nil
    if {[length $args] > 0} {
        for {} {1} {} {
	    if {[length $args] > 0 && [string match [index $args 0] -*]} {
		foreach i [explode [range [index $args 0] 1 end chars]] {
		    [case $i in
			q {var quiet 1}
			X {var verboseGen 1}
			Y {var verboseSearch 1}
			b {
			    var onlyBlock [index $args 1]
			    var start $onlyBlock
			    var args [range $args 1 end]
			}
			o {
			    var onlyObject [index $args 1]
			    var args [range $args 1 end]
			}
			c {
			    var classToCheck [index $args 1]
			    var args [range $args 1 end]
			}
			C {
			    var topClassToCheck [index $args 1]
			    var args [range $args 1 end]
			}
			p {
			    var h [handle lookup [index $args 1]]
			    if {![null $h] && $h != 0} {
				var owner [handle id $h]
			    } else {
				var owner [handle id
					[index [patient resources
						[patient find
							[index $args 1]]] 0]]
			    }
			    var args [range $args 1 end]
			}
			default {
			    error [format {Unrecognized argument %s} $i]
			}
		    ]
		}
		var args [range $args 1 end]
	    } else {
		error [format {Unrecognized argument %s} $args]
	    #
	    # if {[length $args] > 0 && [string match [index $args 0] -*]}
	    }
	    if {[null $args]} {
		break
	    }
	#
	# for {} {1} {}
        }
    #
    # if {[length $args] > 0}
    }

    #
    # initialize counter array
    #
    var _ca {}

    #
    # Set up initial conditions.
    #
    var first 1
    var nextStruct [value fetch kdata:$start HandleMem]
    var val [value fetch kdata:[field $nextStruct HM_prev] HandleMem]

    #
    # if doing only one object, go ahead and do it
    #
    if {![null $onlyObject]} {
	#
	# make sure object is in memory
	#
	if {[handle segment [index [addr-parse $onlyObject] 0]] == 0} {
	    error {Specified object not in memory}
	}
	#
	# update direct and indirect reference counters in array
	#
	var _ocIndent 0
	var topClass [obj-class $onlyObject]
	[obj-foreach-class objcount-callback
		$onlyObject
		$topClass $verboseGen$verboseSearch$quiet]
    } else {
    #
    # else, loop through all blocks on heap, looking for object blocks
    #

    for {var cur $start} {($cur != $start) || $first} {var cur $next} {
    	var val $nextStruct

	var next [field $val HM_next] prev [field $val HM_prev]

	[var nextStruct [value fetch kdata:$next HandleMem]
	    addr [field $val HM_addr]
	    oi [field $val HM_otherInfo]
	    own [field $val HM_owner]
	    flags [field $val HM_flags]
	    first 0]

	if {![null $onlyBlock] && ($addr == 0)} {
	    error {Specified block not in memory}
	}

	if {[null $owner] || $own == $owner} {

	if {$verboseGen} {
	    echo [format {checking block %04x} $cur]
	} else {
	    if {!$verboseSearch && !$quiet} {
		echo -n {.}
		flush-output
	    }
	}

        if {($own != 0) && ([field $flags HF_LMEM])} {
	    
	    #
	    # check if LMEM_TYPE_OBJ_BLOCK
	    #
	    var i [value fetch $addr:LMBH_lmemType]
	    var t [type emap $i [if {[not-1x-branch]}
				    {sym find type LMemType}
				    {sym find type LMemTypes}]]
	    if {![string compare $t LMEM_TYPE_OBJ_BLOCK]} {

	    var address [addr-parse $addr:0]
	    var seg [handle segment [index $address 0]]
	    var blockHeader [value fetch $addr:0 LMemBlockHeader]
	    var hTable [field $blockHeader LMBH_offset]
	    var nHandles [field $blockHeader LMBH_nHandles]

	    if {$verboseGen} {
		echo [format {   checking %d chunks} $nHandles]
	    }

	    var curHandle $hTable
	    var flags [value fetch $seg:$hTable word]
	    for {} {$nHandles > 0} {var nHandles [expr $nHandles-1]} {
		var chunkAddr [value fetch $seg:$curHandle word]
		#
		# check for non-zero chunks and ignore flags chunk
		#
		if {$chunkAddr != 0 &&
		      $chunkAddr != 0xffff && $curHandle != $hTable} {
		    var fl [value fetch $addr:$flags geos::ObjChunkFlags]
		    #
		    # check for object chunk
		    #
		    if {[field $fl OCF_IS_OBJECT]} {

			#
			# update direct and indirect reference counters in array
			#
			var _ocIndent 0
			var topClass [obj-class $seg:$chunkAddr]
			if {([null $topClassToCheck] && [null $classToCheck]) ||
				([null $classToCheck] && ![string c [sym name $topClass] $topClassToCheck]) ||
				(![null [obj-foreach-class checkclass-callback $seg:$chunkAddr $classToCheck]]) } {
			[obj-foreach-class objcount-callback
				$seg:$chunkAddr
				$topClass $verboseGen$verboseSearch$quiet]
			}

		    # if OCF_OBJECT
		    }
		}
		var flags [expr $flags+1]
		var curHandle [expr $curHandle+2]

	    #for chunks
	    }

	    #if OBJ_BLOCK
	    }

        #if {($own != 0) && ([field $flags HF_LMEM])}
	}

	#if {[null $owner] || $own == $owner}
	}

	#
	# if only looking at one block, break out of loop
	#
	if {![null $onlyBlock]} {
	    break
	}

    # for blocks
    }

    # if only one object or whole heap
    }

    #
    # print results
    #
    echo
    echo {Class                        direct      indirect       size}
    echo {------------------------------------------------------------}
    var totalDirect 0
    var totalIndirect 0
    var totalSize 0
    foreach i $_ca {
	var cName [sym name [index $i 0]]
	var dCount [index $i 1]
	var iCount [index $i 2]
	echo -n [format {%-30s} $cName]
	echo -n [format {%3d} $dCount]
	echo -n [format {%13d} $iCount]
	var instanceSize [instance-size [index $i 0]]
	var classSize [expr ($dCount+$iCount)*$instanceSize]
	echo [format {%13d} $classSize]
	var totalDirect [expr $totalDirect+$dCount]
	var totalIndirect [expr $totalIndirect+$iCount]
	var totalSize [expr $totalSize+$classSize]
	#
	# output MetaClass stuff
	#
	if {![string compare $cName MetaClass]} {
	    var eInfo [index $i 3]
	    echo [format {%-30s(%3d)%24d} {(vardata)}
					[index $eInfo 0]
					[index $eInfo 1]]
	    var totalSize [expr $totalSize+[index $eInfo 1]]
	}
	#
	# output GenClass stuff
	#
	if {![string compare $cName GenClass]} {
	    var eInfo [index $i 3]
	    echo [format {%-30s(%3d)%24d} {(monikers)}
					[index $eInfo 0]
					[index $eInfo 1]]
	    echo [format {%-30s(%3d)%24d} {(moniker lists)}
					[index $eInfo 2]
					[index $eInfo 3]]
	    echo [format {%-30s(%3d)%24d} {(moniker list items)}
					[index $eInfo 4]
					[index $eInfo 5]]
	    echo [format {%-30s(%3d)%24d} {(vardata)}
					[index $eInfo 6]
					[index $eInfo 7]]
	    var totalSize [expr $totalSize+[index $eInfo 1]+[index $eInfo 3]+[index $eInfo 5]+[index $eInfo 7]]
	}
	#
	# output VisTextClass stuff
	#
	if {![string compare $cName VisTextClass]} {
	    var eInfo [index $i 3]
	    echo [format {%-30s(%3d)%24d} {(text chunks)}
					[index $eInfo 0]
					[index $eInfo 1]]
	    var totalSize [expr $totalSize+[index $eInfo 1]]
	}
    }
    echo {------------------------------------------------------------}
    echo -n [format {%-30s} {Totals:}]
    echo -n [format {%3d} $totalDirect]
    echo -n [format {%13d} $totalIndirect]
    echo [format {%13d} $totalSize]
}]
