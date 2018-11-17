##############################################################################
#
# 	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:      PC GEOS	
# MODULE:	Swat
# FILE: 	verbkeys.tcl
# AUTHOR: 	Paul Canavese, May 12, 1995
#
# VARIABLES:
# 	Name			Description
#	----			-----------
#       verboseKeys             All verbose keys and their report points.
#       geosReportPoints        Report points for geos.
#       reseditReportPoints     Report points for resedit.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	pjc	5/12/95   	Initial Revision
#
# DESCRIPTION:
#	Definitions of keys and report points for "verbose".
#       
#       It's so easy to add to this file that even you can do it.  Right now.
#
#	$Id: verbkeys.tcl,v 1.3.6.1 97/03/29 11:27:37 canavese Exp $
#
###############################################################################


####################################################################################
# verboseKeys
#
# {className
#    {keyName
#       {Description}
#       {
#           {patient reportPointName}
#           {patient reportPointName}
#           ...
#       }
#    }
#    ...
# }
# ...
#
# The report point names are defined below...

[var verboseKeys {

    {faxrec
	{state
	    {Current fax state.}
	    {
		{faxrec class-1-receive-handle-data-notification}
		{faxrec fax-call-parser}
		{faxrec fax-move-to-state}
		{faxrec non-blocking-write-es}
	    }
	}
    }

    {kernel-geode

	{load-geode
	    {Geode loading calls.}
	    {
		{geos load-geode-after-start}
		{geos load-geode-after-done}
		{geos load-geode-low-done}
		{geos load-geode-low-error}
		{geos load-geode-low-start}
		{geos try-open-common-open-file}
		{geos use-library-low-done}
		{geos use-library-low-proto-error}
		{geos use-library-low-start}
	    }
	}
    }

    {kernel-heap

	{alloc-free
	    {Memory allocation and freeing routines.}
	    {
		{geos mem-alloc}
		{geos mem-free}
	    }
	}

    }

    {kernel-local

	{strcmp
	    {String comparison code.}
	    {
		{geos local-cmp-strings-real}
		{geos local-cmp-strings-no-case-real}
		{geos local-cmp-strings-no-space-real}
		{geos local-cmp-strings-no-space-case-real}
		{geos local-cmp-strings-dos-to-geos-real}
	    }
	}

	{strcmp-dbls
	    {Correct double-s sorting for string compares.}
	    {
		{geos translate-special-characters-done}
	    }
	}
    }

    {patch 

	{high
	    {System resource patching (high-level).}
	    {
		{geos patch-file-found}
		{geos patch-file-not-found}
		{geos patch-resource}
	    }
	}

	{load-resource
	    {Report whenever a resource is loaded.}
	    {
		{geos patch-do-load-resource}
	    }
	}
    }

    {patch-create

	{compare-bytes
	    {Byte-comparison algorithm to compare resources.}
	    {
		{resedit patch-compare-bytes}
	    }
	}

	{generate-high
	    {Patch file generation (high-level).}
	    {
		{resedit patch-create-resource-entry}
		{resedit patch-create-element}
		{resedit patch-start-relocation-table}
	    }
	}

	{generate-low
	    {Patch file generation (low-level).}
	    {
		{resedit patch-find-largest-match}
		{resedit patch-find-largest-match-result}
	    }
	}

	{write
	    {Writing out the new patch file.}
	    {
		{resedit patch-write-element}
		{resedit patch-write-resource-elements}
		{resedit patch-write-relocation-elements}
		{resedit patch-write-resource-list}
		{resedit patch-write-file-header}
	    }
	}
    }

    {resedit

	{main
	    {Normal debugging.}
	    {
		{resedit change-resource}
		{resedit create-executable}
		{resedit update-translation}
		{resedit update-translation-exit}
		{resedit process-batch-file}
		{resedit process-batch-file-open}
		{resedit process-batch-file-save}
		{resedit process-batch-file-done}
	    }
	}

	{read-vm
	    {Read in the localization information from the .vm file.}
	    {
		{resedit copy-loc-to-trans-callback-got-name}
		{resedit copy-loc-element-find-chunk}
		{resedit copy-loc-element-localizable}
		{resedit copy-loc-element-not-localizable}
		{resedit init-resource-arrays-callback}
		{resedit add-chunk-items-chunk-added}
	    }
	}

	{null-geode
	    {Create a geode without textual monikers.}
	    {
		{resedit null-strings-in-chunk-null-string}
	    }
	}

	{translate
	    {Translating resources/chunks.}
	    {
		{resedit update-resource}
		{resedit verify-chunk-equality-done}
	    }
	}

	{update
	    {Updating translation file.}
	    {
		{resedit update-translation}
		{resedit update-translation-exit}
	    }
	}

    }

    {ui

	{geometry
	    {Show geometry manager resizing things.}
	    {
		{ui start-geometry}
		{ui end-geometry}
		{ui start-recalc-size}
		{ui end-recalc-size}
		{ui end-spacing}
		{ui end-min-size}
		{ui end-center}
		{ui end-margins}
	    }
	}

	{invalidation
	    {Shows invalidation mechanism.}
	    {
		{ui vis-invalidate}
		{ui inval-old-bounds}
		{ui vis-spec-set-not-usable}
		{ui invalidate-area}
		{ui add-to-inval-region}
		{ui inval-update-region}
		{ui inval-done}
	    }
	}
    }


}]


####################################################################################
# Report points.
#
# "verbose" looks for the variable {patient}ReportPoints for that patient's report
# points.


####################################################################################

[var geosReportPoints {

    {load-geode-after-start
	LoadGeodeAfterFileOpen {
	    inc-vindent
	}
    }

    {load-geode-after-done
	LGAFO_done {
	    require	getcc setcc.tcl
	    dec-vindent
	    if { [getcc c] } {
		vindent
		error [format {%s} [penum GeodeLoadError [read-reg ax]]]
	    }
	}
    }

    {load-geode-low-done
	LGL_done	{
	    dec-vindent
	}
    }

    {load-geode-low-error
	LGL_openError {
	    vindent
	    error {Cannot open file.}
	}
    }

    {load-geode-low-start
	LoadGeodeLow {
	    require pstring pvm.tcl
	    vindent
	    echo -n LoadGeodeLow: opening file: 
	    pstring ds:si
	    inc-vindent
	}
    }

    {local-cmp-strings-dos-to-geos-real
	LocalCmpStringsDosToGeosReal {
	    if { [read-reg cx] == 0 } {
		echo [format {Comparing (DOS) "%s" and "%s".}
		      [getstring ds:si] [getstring es:di]]
	    } else {
		echo [format {Comparing (DOS) "%s" and "%s".}
		      [getstring ds:si [read-reg cx]] [getstring es:di [read-reg cx]]]
	    }
	}
    }

    {local-cmp-strings-no-case-real
	LocalCmpStringsNoCaseReal {
	    if { [read-reg cx] == 0 } {
		echo [format {Comparing (no case) "%s" and "%s".}
		      [getstring ds:si] [getstring es:di]]
	    } else {
		echo [format {Comparing (no case) "%s" and "%s".}
		      [getstring ds:si [read-reg cx]] [getstring es:di [read-reg cx]]]
	    }
	}
    }

    {local-cmp-strings-no-space-case-real
	LocalCmpStringsNoSpaceCaseReal {
	    if { [read-reg cx] == 0 } {
		echo [format {Comparing (no space, no case) "%s" and "%s".}
		      [getstring ds:si] [getstring es:di]]
	    } else {
		echo [format {Comparing (no space, no case) "%s" and "%s".}
		      [getstring ds:si [read-reg cx]] [getstring es:di [read-reg cx]]]
	    }
	}
    }

    {local-cmp-strings-no-space-real
	LocalCmpStringsNoSpaceReal {
	    if { [read-reg cx] == 0 } {
		echo [format {Comparing (no space) "%s" and "%s".}
		      [getstring ds:si] [getstring es:di]]
	    } else {
		echo [format {Comparing (no space) "%s" and "%s".}
		      [getstring ds:si [read-reg cx]] [getstring es:di [read-reg cx]]]
	    }
	}
    }

    {local-cmp-strings-real
	LocalCmpStringsReal {
	    if { [read-reg cx] == 0 } {
		echo [format {Comparing %s and %s.}
		      [getstring ds:si] [getstring es:di]]
	    } else {
		echo [format {Comparing %s and %s.}
		      [getstring ds:si [read-reg cx]] [getstring es:di [read-reg cx]]]
	    }
	}
    }

    {mem-alloc
	MemAllocLow::done {
	    echo [format {Allocing block: ^h%04xh}
		  [read-reg bx]]
	}
    }

    {mem-free
	MemFree {
	    echo [format {Freeing block: ^h%04xh}
		  [read-reg bx]]
	}
    }

    {patch-file-found
	GeodeOpenPatchFileFromList::doneNoError	{
	      var geodeCoreBlock [value fetch coreBlock]
	      echo [format {Found patch file for %s}
		    [getstring $geodeCoreBlock:GH_geodeName 8]]
	}
    }

    {patch-file-not-found
	GeodeOpenPatchFileFromList::noMatches {
	      var geodeCoreBlock [value fetch coreBlock]
	      echo [format {No patch file found for %s}
		    [getstring $geodeCoreBlock:GH_geodeName 8]]		    
	}
    }

    {patch-do-load-resource
	DoLoadResource {
	      echo [format {Loading resource %d for %s}
		    [expr [read-reg si]/2]
		    [getstring ds:GH_geodeName 8]]
	}
    }

    {patch-resource
	GeodeLoadPatchedResource {
	      echo [format {Patching resource %d for %s}
		    [expr [read-reg si]/2]
		    [getstring ds:GH_geodeName 8]]
	}
    }

    {translate-special-characters-done
	TranslateSpecialCharacters::done {
	    if { [read-reg dx] > 0 } {
		echo [format {   Actually comparing %s and %s.}
		      [getstring ds:si]
		      [getstring es:di]]
	    }
	}
    }

    {try-open-common-open-file 
	TOC_openFile {
	    require pstring pvm.tcl
	    vindent
	    echo -n {Opening: }
	    pstring ds:dx
	}
    }

    {use-library-low-done
	ULL_done {
	    dec-vindent
	}
    }


    {use-library-low-proto-error
	ULL_protoError {

	    require getstring cwd

	    # AX is trashed when TestProtocolNumbers returns to UseLibraryLow,
	    # so grab its original value here.

	    var oldax [value fetch es:di.ILE_protocol.PN_major word]
	    var oldbx [value fetch es:di.ILE_protocol.PN_minor word]

	    # The handle of the client Geode is on the stack. Grab it,
	    # and form the name of the client.
	    # (Actually, the "loader" still owns this handle, but the name of
	    # the new client is in the core block.)

	    var ihan [value fetch ss:sp word]
	    var iname [getstring ^h$ihan.GH_geodeName 8]

	    # The handle of the imported geode is at ds:[GH_geodeHandle].
	    # Grab it and form the name of the imported geode.

	    var ghan [value fetch ds:GH_geodeHandle]
	    var gname [patient name [handle patient [handle lookup $ghan]]]
	    vindent
	    echo [format {PROTOCOL ERROR WHILE LOADING: %s.} $gname]

	    echo [format {%s expects: %d.%d} $iname $oldax $oldbx]
	    echo [format {Protocol number for %s: %d.%d}
			$gname [read-reg cx] [read-reg dx]]
	}
    }

    {use-library-low-start
	UseLibraryLow {
	    vindent
	    echo -n {Loading: }

	    # deal with XIP geodes
	    if {[catch {frame funcsym [frame next [frame top]]} fsym] == 0 && 
		![null $fsym]} {
		    if {[string compare [sym name $fsym] UseXIPLibrary] == 0} {
			var pname [patient name [handle patient 
						 [handle lookup [read-reg bx]]]]
			var nlist [explode $pname]
			[for {var c [car $nlist] i 8} {![null $c]} {} {
			    echo -n $c
			    var nlist [cdr $nlist]
			    var c [car $nlist]
			    var i [expr $i-1]
			}]
			echo -n [format {%*s} $i {}]
			var	xip TRUE
		    }
		}

	    if {[null $xip]} {
		var addr es:di
		var o 0 
		[for {var c [value fetch $addr+$o byte]}
		 {$c != 0}
		 {var c [value fetch $addr+$o byte]}
		 {
		     echo -n [format %c $c]
		     var o [expr $o+1]
		 }]
	    }

	    if { [read-reg bx] != 0 } {
		if {![null $xip] || [handle isxip [handle lookup [read-reg bx]]]} {
		    echo -n (XIP)
		} else {
		    echo -n (resident)
		}
	    }

	    echo
	    inc-vindent
	}
    }

} ]


####################################################################################

[var reseditReportPoints {

    {add-chunk-items-chunk-added
	AddChunkItems::chunkAdded
	{
	    echo -n [format {%s, }
		     [getstring ss:chunkName]]
	}
    }

    {create-executable
	REDCreateExecutable
	{
	    echo [format {Creating executable (%s, %s, %s, %s)}
		  [penum CreateExecutableTypeEnum [read-reg cl]]
		  [penum CreateExecutableUpdateEnum [read-reg ch]]
		  [penum CreateExecutableNameEnum [read-reg dl]]
		  [penum CreateExecutableDestinationEnum [read-reg dh]]]
	}
    }

    {change-resource
	DocumentChangeResource
	{
	    echo [format {UI is changing to resource %d.}
		  [read-reg cx]]
	}
    }

    {copy-loc-element-find-chunk
	CopyLocElement::findChunk
	{
	    echo -n [format { Chunk %d}
		  [read-reg ax]]
	}
    }

    {copy-loc-element-localizable
	CopyLocElement::localizable
	{
	    echo [format { %s: localizable}
		  [getstring es:bx.LAE_data.LAD_name [size LocArrayElement]]]
	}
    }

    {copy-loc-element-not-localizable
	CopyLocElement::notLocalizable
	{
	    echo [format { %s: not localizable}
		  [getstring es:bx.LAE_data.LAD_name] [size LocArrayElement]]
	}
    }

    {copy-loc-to-trans-callback-got-name
	CopyLocToTransCallback::gotName
	{
	    echo [format {Creating resource array for %s.}
		  [getstring es:di]]
	}
    }

    {init-resource-arrays-callback
	InitResArraysCallback
	{
	    echo -n [format {\n* Initializing %s:}
		  [getstring ds:di.RME_data.RMD_name]]
	}
    }


    {null-strings-in-chunk-null-string
	NullStringsInChunk::nullString
	{
	    echo [format {Nulling string: "%s".}
		  [getstring ds:[value fetch ds:ax [type word]]]]
	}
    }

    {patch-compare-bytes
	CompareBytes
	{
	      echo [format {CompareBytes: (Old range= %d-%d) (New range= %d-%d).}
		    [read-reg ax] [read-reg bx] [read-reg cx] [read-reg dx]]
	}
    }

    {patch-create-resource-entry
	CreatePatchedResourceEntry 
	{
	    echo [format {\nResource %d:  (old size: %04xh, new size: %04xh).}
		  [read-reg cx]
		  [value fetch oldResourceSize]
		  [value fetch newResourceSize]]
	}
    }

    {patch-create-element
	CreatePatchElement::done
	{
	    [var patchtype 
	     [expr ([value fetch ^hbx:PCE_entry.PE_flags word]&(3<<14))>>14]]
	    if {[null $patchtype]} {
		var patchtype 0
	    }
	    echo [format {Patch at position %04xh, type %9s, size %04xh}
		  [value fetch ^hbx:PCE_entry.PE_pos]
		  [penum PatchType $patchtype]
		  [value fetch ^hbx:PCE_entry.PE_flags.PF_SIZE]]
	}
    }

    {patch-find-largest-match
	FindLargestMatchSimple
	{
	      echo [format { FindLargestMatch: (Old range= %d-%d) (New range= %d-%d).}
		    [read-reg ax] [read-reg bx] [read-reg cx] [read-reg dx]]
	}
    }

    {patch-find-largest-match-result
	FindLargestMatchSimple:exit
	{
	      if {[getcc carry]} {
		  echo [format { ...returning: CARRY SET (large enough match not found)}]
	      } else {
		  echo [format { ...returning:  %d matching bytes.  Oldpos: %d.  Newpos: %d.}
			[value fetch mostMatchingBytes] [read-reg si] [read-reg di]]
	      }
	}
    }

    {patch-start-relocation-table
	PatchCompareResources::patchRelocationTable
	{
	    echo Relocation table.
	}
    }

    {patch-write-element
	WritePatchElement::writeElement 
	{
	      [var patchtype 
	       [expr ([value fetch ds:PCE_entry.PE_flags word]&(3<<14))>>14]]
	      if {[null $patchtype]} {
		  var patchtype 0
	      }
	      echo [format { Writing PatchElement: position %02xh, size %02xh, type: %s}
		    [value fetch ds:PCE_entry.PE_pos]
		    [value fetch ds:PCE_entry.PE_flags.PF_SIZE]   
		    [penum PatchType $patchtype]]
	}
    }

    {patch-write-file-header
	GeneratePatchFile::writePatchFileHeader
	{
	      echo ========== WRITING PATCH DATA ==============
	      echo [format {Patch file header: (%04xh bytes)}
		    [size PatchFileHeader]]
	}
    }

    {patch-write-resource-elements
	WritePatchLists::writePatchResourceElements
	{
	      echo [format {Resource %d Entries}
		    [value fetch ds:PRE_id]]
	}
    }

    {patch-write-relocation-elements
	WritePatchLists::writePatchRelocationElements
	{
	      echo Relocation table.
	}
    }

    {patch-write-resource-list
	WritePatchResourceList::writePatchedResourceEntry
	{
	      echo [format { Resource %d.  Size: %04xh.  Position:%04xh.  (%d bytes)}
		    [value fetch ds:PRE_id]
		    [value fetch ds:PRE_size]
		    [value fetch ds:PRE_pos]
		    [size PatchedResourceEntry]]
	}
    }

    {process-batch-file
	REAProcessBatchFile
	{
	    var segment [value fetch cx:BPS_nextFileName.segment]
	    var offset [value fetch cx:BPS_nextFileName.offset]
	    echo [format {Processing translation file: %s}
		  [getstring $segment:$offset]
		 ]
	}
    }

    {process-batch-file-done
	REAProcessBatchFile::done
	{
	    echo Done processing batch file.
	}
    }

    {process-batch-file-open
	REAProcessBatchFile::documentOpen
	{
	    echo Translation file opened.
	}
    }

    {process-batch-file-save
	REAProcessBatchFile::saveDocument
	{
	    echo Saving translation file.
	}
    }

    {update-resource
	UpdateResource
	{
	    echo [format {Updating resource %d.}
		  [value fetch ss:bp.CEF_resNumber]]
	}
    }

    {update-translation
	DocumentUpdateTranslation
	{
	    echo Translation file being updated....
	}
    }

    {update-translation-exit
	DocumentUpdateTranslation::exit
	{
	    echo -n Translation file update completed...
	    report-carry-error
	}
    }

    {verify-chunk-equality-done
	VerifyChunkEquality::done
	{
	      if {[getcc carry]} {
		  echo [format {Chunks match.}]
	      } else {
		  echo [format {Chunks don't match.}]
	      }
	}
    }

}]


####################################################################################

[var uiReportPoints {

    {add-to-inval-region
	AddToInvalRegion
	{
	    echo -n [format {Adding rect (%d, %d, %d, %d), } [read-reg ax]
			[read-reg bx] [read-reg cx] [read-reg dx]]
	}
    }

    {end-center
	EndCenter
	{
	    vindent
	    echo [format {Object's center in X: (%xh,%xh) in Y: (%xh,%xh)}
		  [read-reg cx] [read-reg dx] [read-reg ax] [read-reg bp]]	
	}
    }

    {end-geometry
	EndGeometry
	{
	    verbose-report ui end-recalc-size
	    vindent
	    echo End Geometry Update (may continue up): -------------
	    echo
	}
    }

    {end-margins
	EndMargins
	{
	    vindent
	    echo [format {Margins (%xh,%xh,%xh,%xh)} 
		  [read-reg ax] [read-reg bp] [read-reg cx] [read-reg dx]]
	}
    }

    {end-min-size
	EndMinSize
	{
	    vindent
	    echo [format {Minimum length %xh, width %xh} 
		  [read-reg cx] [read-reg dx]]
	}
    }

    {end-recalc-size
	EndRecalcSize
	{
	    dec-vindent

	    var addr [addr-parse *ds:si]
	    var seg [handle segment [index $addr 0]]
	    var off [index $addr 1]
	    var masteroff [value fetch $seg:$off.Vis_offset]
	    var master [expr $off+$masteroff]
	    var comp [field [value fetch $seg:$master.VI_typeFlags]
		      VTF_IS_COMPOSITE]

	    [if {$comp} {
		vindent
		echo -n [format {Returns }]
	    } else {
		echo -n [format {-> }]
	    }]
	    echo [format {(%04xh,%04xh)} [read-reg cx] [read-reg dx]]
	}
    }

    {end-spacing
	EndSpacing
	{
	    vindent
	    echo [format {Spacing (%xh,%xh)} [read-reg cx] [read-reg dx]]
	}
    }

    {invalidate-area
	InvalidateArea
	{
	    echo -n [format {Invalidating (%d, %d, %d, %d), } [read-reg ax]
			[read-reg bx] [read-reg cx] [read-reg dx]]
	}
    }

    {inval-done
	InvalDone
	{
	    echo Invalidation done.
	}
    }

    {inval-old-bounds
	InvalOldBounds
	{
	    echo -n [format {Old bounds (*%04xh:%04xh), } [read-reg ds] [read-reg si]]
	}
    }

    {inval-update-region
	InvalUpdateRegion
	{
	    echo -n Region update:
	    preg bp:si
	}
    }

    {start-geometry
	StartGeometry
	{
	    echo Begin Geometry Update: -----------------------------
	    verbose-report ui start-recalc-size
	}
    }

    {start-recalc-size
	StartRecalcSize
	{
	    var csym [symbol faddr var *(*ds:si).MB_class]
	    vindent
	    if {[null $csym]} {
		echo -n [format {%s(^l%04xh:%04xh[?],%04xh,%04xh)} 
			 CALC_NEW_SIZE [value fetch ds:LMBH_handle] [read-reg si] 
			 [read-reg cx] [read-reg dx]]
	    } else {
		echo -n [format {%s(^l%04xh:%04xh) (%04xh,%04xh)} 
			 [symbol name $csym] [value fetch ds:LMBH_handle] [read-reg si] 
			 [read-reg cx] [read-reg dx]]
	    }

	    var addr [addr-parse *ds:si]
	    var seg [handle segment [index $addr 0]]
	    var off [index $addr 1]
	    var masteroff [value fetch $seg:$off.Vis_offset]
	    var master [expr $off+$masteroff]
	    var comp [field [value fetch $seg:$master.VI_typeFlags] VTF_IS_COMPOSITE]
	    [if {$comp} {
		echo :
	    }]
	    inc-vindent
	}
    }

    {vis-invalidate
	VisInvalidate
	{
	    echo -n [format {New bounds (*%04xh:%04xh), } [read-reg ds] [read-reg si]]
	}
    }

    {vis-spec-set-not-usable
	VisSpecSetNotUsable
	{
	    echo -n [format {Object removed (*%04xh:%04xh), } [read-reg ds] [read-reg si]]
	}
    }

} ]



####################################################################################

[var faxrecReportPoints {

    {class-1-receive-handle-data-notification
	Class1ReceiveHandleDataNotification
	{
	    echo We got data.
	}
    }

    {fax-call-parser
	FaxCallParser
	{
	    echo Reading:
	    bytes ds:cx [expr [read-reg di]-[read-reg cx]]
	}
    }

    {fax-move-to-state
	FaxMoveToState
	{
	    echo [format {%s->%s} 
		  [penum FaxReceiveState class1in::dgroup::currentState]
		  [penum FaxReceiveState [read-reg si]]]
	}
    }

    {non-blocking-write-es
	NonBlockingWriteES
	{
	    echo Writing:
	    bytes es:si [read-reg cx]
	}
    }

} ]


####################################################################################
# Not yet implemented.

[var verboseLevels { 

    {patch-create 1

	{
	    {patch-create generate-high}
	}

	{
	    {patch-create generate-high}
	    {patch-create write}
	}

    }
} ]

