##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library
# FILE: 	showcall.tcl (THIS IS THE PC/GEOS V2.0 VERSION)
# AUTHOR: 	Adam de Boor, Dec 27, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	showcall   	    	Turn on/off various monitors
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/27/89	Initial Revision
#
# DESCRIPTION:
#	showcalls is a command to display the flow of control in various
#   	parts of PC GEOS.
#
#	$Id: showcall.tcl,v 1.42.4.1 97/03/29 11:27:51 canavese Exp $
#
###############################################################################

#
# We make use of stuff in the dos tcl library.
#
[require read-sft-entry dos]
[require rtcm-showcalls rtcm]

[defcmd showcalls {{flags {}} args} profile
{Usage:
    showcalls [-<flags> [<args>]]

Examples:
    "showcalls -o"  	show all calls using ObjMessage and ObjCall*
    "showcalls -ml" 	show all calls changing global and local memory
    "showcalls"	    	stop showing any calls

Synopsis:
    Display calls to various parts of PC/GEOS.

Notes:
    * The flags argument determines the types of calls displayed.
      Multiple flags must all be specified in the first argument ("showcalls
      -vl", not "showcalls -v -l"). If no flags are passed then showcalls stops
      watching whatever it was watching before.  The flags may be any of the
      following:

        p  Modify all other flags to work for the current patient only

	a  Show attach/detach/state-save/restore/lazarus, etc.
	b  Monitors vis builds
	d  Show dispatching of threads
	e  Show all exclusive grabs & releases
	f  Show certain file operations (open, read, write, and position)
	F  Show file-change notifications produced by the system.
	g  Show geometry manager resizing things (all sizes in hex)
	G  Show GrCreateState and GrDestroyState
	h  Show all hierarchical exclusive grabs & releases
        H  Show heap space allocation (using gp heapspace values, not actual
	   allocation values)
	i  Show call far calls made to movable routines.
	I  Show invalidation mechanism at work
	L  Show Library loading calls
	l  Show local memory create, destroy, rellocate
	m  Show global memory alloc, free, realloc
	N  Show navigation calls (between fields, and between windows)
	o  Show ObjMessage and ObjCallXXX
	r  Show calls between resources (args: <resource handle>)
	R  Show RTCM activity (args: <verbose>)
	s  Monitors shutdown: MSG_META_DETACH, MSG_META_DETACH_COMPLETE,
	   MSG_META_ACK, MSG_META_DETACH_ABORT
	S  Show stack borrowing activity
	t  Shows clipboard activity
	T  Show text-object related information (currently cursor changes)
	w  Show WinOpen, WinClose, WinMoveResize, WinChangePriority
	v  Show video driver calls
	V  Show loading and unloading of resources to and from state files 
		during shutdown

    * The args argument is used to pass values for some of options.

See also:
    mwatch, objwatch.
}
{
    var sc_brk_lists {
	sc_borrow sc_build sc_dispatch sc_exclgrab sc_fcn sc_file sc_flowgrab
	sc_geo sc_gload sc_gstate sc_int sc_inval sc_lmem sc_mem sc_nav sc_obj
	sc_resource sc_shutdown sc_text sc_transfer sc_vid sc_win sc_vmstate
	sc_attach sc_heapspace sc_rtcm
    }
    
    var sc_state_vars {
    	gloadIndent gsCount gsLevel getsizeDepth navIndent exclIndent
    }
    foreach v [concat $sc_brk_lists $sc_state_vars] {global $v}
    foreach v $sc_state_vars {var $v 0}
    foreach bl $sc_brk_lists {remove-brk $bl}

    var ps {aset}

    if {(![null $flags]) && ([string compare $flags off] != 0)} {
	foreach i [explode [range $flags 1 end chars]] {
    	    [case $i in
	     	p {
		    var ps {pset}
		}
	     	v {
		    var sc_vid [list [brk $ps ega::DriverStrategy print-video]]
		}
	     	l {
		    var sc_lmem [list [brk $ps LMemAlloc print-la]
				      [brk $ps LMemFree print-lf]
				      [brk $ps LMemReAlloc print-lr]
				      [brk $ps LMemCompactHeap print-lch]
				      [brk $ps GSE_LMemBlockReAlloc print-lgs]
				      [brk $ps CNN_LMemBlockContract print-lco]]
		}
	     	G {
		    var sc_gstate [list [brk $ps GrCreateState print-grcreate]
				      [brk $ps GrDestroyState print-grdestroy]]
		}
	     	m {
		    var sc_mem [list [brk $ps MemAlloc print-ma]
				     [brk $ps MemFree print-mf]
				     [brk $ps DoReAlloc print-mr]]
		}
	     	s {
		    var ma [index [symbol get [symbol find any MSG_META_ACK]] 0]
#		    var md [index [symbol get [symbol find any MSG_META_DETACH]] 0]
		    var aa [brk $ps ObjMessage print-detach-info]
		    var bb [brk $ps ODC_sendmethod print-obj-ack-info]
		    var cc [brk $ps TD_swatlab print-thread-ack-info]
		    var dd [brk $ps ObjCallInstanceNoLockES
					print-shutdown-info-ds:si]
		    var ee [brk $ps ObjCallInstanceNoLock
					print-shutdown-info-ds:si]
		#HACK - only break on detach methods -- assumes MSG_META_DETACH
		# is the first one and MSG_META_ACK is the last
		    brk cond $aa ax<$ma
		    brk cond $dd ax<=$ma 
		    brk cond $ee ax<=$ma 
		    var sc_shutdown [list $aa $bb $cc $dd $ee]
		}
	     	o {
		    var sc_obj [list [brk $ps ObjMessage print-om]
				     [brk $ps ObjCallInstanceNoLockES
								print-ocinles]
				     [brk $ps ObjCallInstanceNoLock
								print-ocinl]
				     [brk $ps ObjCallClassNoLock print-occnl]
				     [brk $ps ObjCallSuperNoLock print-ocsnl]]
		}
		I {
		    var sc_inval [list [brk $ps ui::VisInvalidate print-vi]
				       [brk $ps ui::InvalOldBounds print-bc]
				       [brk $ps ui::VisSpecSetNotUsable print-snu]
				       [brk $ps ui::InvalidateArea print-i]
				       [brk $ps ui::AddToInvalRegion print-air]
				       [brk $ps ui::InvalUpdateRegion print-iur]
				       [brk $ps ui::InvalDone print-id]]
		}
	     	w {
		    var sc_win [list [brk $ps WinOpen print-wo]
				     [brk $ps WinClose print-wc]
				     [brk $ps WinResize print-wr]
				     [brk $ps WinMove print-wm]
				     [brk $ps WinChangePriority print-wcp]]
		}
	     	d {
		    var sc_dispatch [list [brk $ps DispatchSI print-disp]]
		}
		g {
		    var sc_geo [list
		       [brk $ps ui::StartGeometry start-geometry]
		       [brk $ps ui::EndGeometry end-geometry]
		       [brk $ps ui::StartRecalcSize start-calc-new-size]
		       [brk $ps ui::EndRecalcSize end-calc-new-size]
		       [brk $ps ui::EndSpacing end-spacing]
		       [brk $ps ui::EndMinSize end-min-size]
		       [brk $ps ui::EndCenter end-center]
		       [brk $ps ui::EndMargins end-margins]]
		}
		b { 
		   var sc_build [list
		       [brk $ps ui::GenGenSetNotUsable print-build]
		       [brk $ps ui::GenGenSetUsable print-build]
		       [brk $ps ui::VisSpecBuildBranch print-build]
		       [brk $ps ui::VisSpecBuild print-build]
		       [brk $ps ui::GenAddGenChild print-add]
		       [brk $ps ui::GenRemoveGenChild print-add]
		       [brk $ps ui::GenMoveGenChild print-add]
		       [brk $ps ui::VisCompAddChild print-add]
		       [brk $ps ui::VisCompRemoveVisChild print-add]
		       [brk $ps ui::VisCompMoveVisChild print-add]]
		}
		e {
		   var sc_exclgrab [list
		       [brk $ps ui::FlowForceGrab   print-forcegrab]
		       [brk $ps ui::FFG_done 	    end-flowexcl]
		       [brk $ps ui::FlowReleaseGrab print-releasegrab]
		       [brk $ps ui::FRG_done 	    end-flowexcl]
		       [brk $ps ui::FlowRequestGrab print-requestgrab]
		       [brk $ps ui::FRqG_done end-flowexcl]
		       [brk $ps ui::FlowGainedSysExcl print-gainedsysexcl]
		       [brk $ps ui::FGSE_done end-flowexcl]
		       [brk $ps ui::FlowGainedAppExcl print-gainedappexcl]
		       [brk $ps ui::FGAE_done end-flowexcl]
		       [brk $ps ui::FlowLostSysExcl print-lostsysexcl]
		       [brk $ps ui::FLSE_done end-flowexcl]
		       [brk $ps ui::FlowLostAppExcl print-lostappexcl]
		       [brk $ps ui::FLAE_done end-flowexcl]
		       [brk $ps ui::FlowGrabWithinLevel print-grabwithinlevel]
		       [brk $ps ui::FGWL_done end-flowexcl]
		       [brk $ps ui::FlowReleaseWithinLevel print-releasewithinlevel]
		       [brk $ps ui::FRWL_done end-flowexcl]
		       [brk $ps ui::FSMTG_send print-fsm]
		       ]
		}
		h {
		   var sc_flowgrab [list
		       [brk $ps ui::FlowGainedSysExcl print-gainedsysexcl]
		       [brk $ps ui::FGSE_done end-flowexcl]
		       [brk $ps ui::FlowGainedAppExcl print-gainedappexcl]
		       [brk $ps ui::FGAE_done end-flowexcl]
		       [brk $ps ui::FlowLostSysExcl print-lostsysexcl]
		       [brk $ps ui::FLSE_done end-flowexcl]
		       [brk $ps ui::FlowLostAppExcl print-lostappexcl]
		       [brk $ps ui::FLAE_done end-flowexcl]
		       [brk $ps ui::FlowGrabWithinLevel print-grabwithinlevel]
		       [brk $ps ui::FGWL_done end-flowexcl]
		       [brk $ps ui::FlowReleaseWithinLevel print-releasewithinlevel]
		       [brk $ps ui::FRWL_done end-flowexcl]
		       [brk $ps ui::FSMTG_send print-fsm]
		       ]
		}
		i {
		   var sc_int [list
		       [brk $ps ResourceCallInt print-rci]]
		}
		N {
		   var sc_nav [list
		       [brk $ps ui::ECVisStartNavigation start-nav]
		       [brk $ps ui::ECVisEndNavigation end-nav]
		       [brk $ps ui::VisNavigateCommon print-naventer]
		       [brk $ps ui::VNC_completedCircuit print-navcompleted]
		       [brk $ps ui::VNC_sendToFirstChild print-navfirstchild]
		       [brk $ps ui::VNC_reachedRoot print-navreachedroot]
		       [brk $ps ui::VSN_reachedPrevious print-navprevious]
		       [brk $ps ui::VNC_returnODCXDX print-navreturnOD]
		       [brk $ps ui::VNC_done print-navleave]
		       [brk $ps ui::VNGNN_sendViaHint print-navhint]
		       [brk $ps ui::VNGNN_sendToSibling print-navsibling]
		       [brk $ps ui::VNGNN_sendToParent print-navparent]]
		}
		L {
		   var sc_gload [list
		       [brk $ps LoadGeodeLow loadgeodelow-start]
		       [brk $ps LGL_openError loadgeodelow-openError]
		       [brk $ps LGL_done loadgeodelow-done]
		       [brk $ps UseLibraryLow useliblow-start]
		       [brk $ps ULL_protoError useliblow-protoerror]
		       [brk $ps ULL_done useliblow-done]
		       [brk $ps LoadGeodeAfterFileOpen loadgeodeafter-start]
		       [brk $ps LGAFO_done loadgeodeafter-done]
		       [brk $ps TOC_openFile tryopencommon-openfile]]
		}
		t {
    		   global watchingTransferSend

    		   var watchingTransferSend 0
		   var sc_transfer [list
		       [brk $ps ui::ClipboardRegisterItem print-transfer-register]
		       [brk $ps ui::ClipboardUnregisterItem print-transfer-unregister]
		       [brk $ps ui::ClipboardQueryItem print-transfer-query]
		       [brk $ps ui::ClipboardRequestItemFormat print-transfer-request]
		       [brk $ps ui::ClipboardDoneWithItem print-transfer-done]
		       [brk $ps ui::ClipboardAddToNotificationList print-transfer-addn]
		       [brk $ps ui::ClipboardRemoveFromNotificationList print-transfer-remn]
		       [brk $ps ui::FreeTransfer print-transfer-free]
		       [brk $ps ui::StoreInFreeList print-transfer-save]
		       [brk $ps ui::SendToNotificationList print-transfer-sendn]
		       [brk $ps GCNLSendCallback print-transfer-sendnlow]]
	       }
		r {
#		   var aa [brk ResourceLibraryCallCommon print-rlcc]
#		   brk cond $aa bx=$args
		   var bb [brk ProcCallModuleRoutine print-pcmr]
                   if {![null $args]} {
		       brk cond $bb bx=$args
		   }
#		   var sc_resource [list $aa $bb]
		   var sc_resource [list $bb]
		}
    	    	f {
    	    	    var sc_file [list
    	    	    	[brk $ps FileOpen print-file-open]
    	    	    	[brk $ps FileRead print-file-read]
    	    	    	[brk $ps FileWrite print-file-write]
    	    	    	[brk $ps FilePos print-file-pos]
    	    	    ]
    	    	}
		T {
		    var sc_text [list
		      [brk $ps text::CursorEnable   	 print-cursor-enable]
		      [brk $ps text::CursorDisable  	 print-cursor-disable]
		      [brk $ps text::CursorToggle   	 print-cursor-toggle]
		      [brk $ps text::CursorForceOn	 print-cursor-forceon]
		      [brk $ps text::TSL_CursorDrawIfOn  print-cursor-drawifon]
		      [brk $ps text::TSL_CursorPosition  print-cursor-position]
		      [brk $ps text::TSL_CursorPositionX print-cursor-positionx]
		    ]
		}
		S {
		    var sc_text [list
		      [brk $ps geos::TBSS_borrow print-stack-borrow]
		    ]
		}
    	    	F {
		    var sc_fcn [list
		    	[brk $ps geos::FSDGenerateNotify print-fcn]
			[brk $ps geos::FSDANTB_haveOffset print-batch-fcn]
    	    	    ]
    	    	}
		V {
		    var sc_vmstate [list
			[brk $ps geos::ODVMF_lock print-loading-resource]
			[brk $ps geos::ODVMF_detach print-saving-resource]
			[brk $ps geos::DOB_finalSize print-final-size]
		    ]
		}
		a {
		    var sc_attach [list
			[brk $ps ObjAssocVMFile print-aavmfile]
			[brk $ps ObjDisassocVMFile print-advmfile]
			[brk $ps ObjSaveExtraStateBlock print-asesb]
			[brk $ps ui::UI_AttachToPassedStateFile print-ocinl]
			[brk $ps ui::UI_CreateNewStateFile print-ocinl]
			[brk $ps ui::UI_OpenApplication print-ocinl]
			[brk $ps ui::UI_RestoreFromState print-ocinl]
			[brk $ps ui::UI_OpenEngine print-ocinl]
			[brk $ps ui::UI_Detach print-ocinl]
			[brk $ps ui::UI_GetStateToSave print-ocinl]
			[brk $ps ui::UI_LazarusApplication print-ocinl]
			[brk $ps ui::UI_Ack print-ocinl]
			[brk $ps ui::UI_UIRealDetach print-ocinl]
			[brk $ps ui::UI_UIFinalDetach print-ocinl]
			[brk $ps ui::GenProcessShutdownAck print-ocinl]
			[brk $ps ui::SaveTempGenAppExtraStateBlock print-stesb]
			[brk $ps ui::RTGAESB_exit print-rtesb]
			[brk $ps ui::GenAppLazarus print-gal]
			[brk $ps ui::GenAppTransparentDetach print-ocinl]
			[brk $ps ui::GenAppAppModeComplete print-ocinl]
			[brk $ps ui::GenApplicationIACPNoMoreConnections print-ocinl]
		    ]
		}
		H {
		    var sc_heapspace [list
		        [brk $ps
			 LoadGeodeLow
			 store-heapspace-geode-name]
		        [brk $ps
			 GeodeEnsureEnoughHeapSpaceCore::GEEHSC_showHeapSpace
			 print-geehsc-heapspace]
			[brk $ps
		     GeodeEnsureEnoughHeapSpaceCore::GEEHSC_heapSpaceAcquired 
			 print-geehsc-after-detach]
			[brk $ps
			 MemAddSwapDriver::MASD_addToHeapSize
			 print-masd-add-to-heapsize]
			[brk $ps
			 MemExtendHeap::MEH_addToHeapSize
			 print-meh-add-to-heapsize]
			[brk $ps
			 InitHeapSize::IHS_initialHeapSize
			 print-ihs-initial-heapsize]
		    ]
		}
		R {
		    var sc_rtcm [rtcm-showcalls $args]
		}

		default {
		    error [list Unrecognized flag $i]
		}]
	}
    }
}]

[defsubr remove-brk {bname} {

	global	$bname
    if {![null [var $bname]]} {
	foreach i [var $bname] {
	    catch {brk clear $i}
	}
	var $bname {}
    }
}]

#
#	-I : Invalidation mechanism
# Shows invalidates.
#
[defsubr print-vi {} {
    echo -n New bounds
    echo -n [format { (*%04xh:%04xh), } [read-reg ds] [read-reg si]]
    return 0
}]
[defsubr print-bc {} {
    echo -n Old bounds
    echo -n [format { (*%04xh:%04xh), } [read-reg ds] [read-reg si]]
    return 0
}]
[defsubr print-snu {} {
    echo -n Object removed
    echo -n [format { (*%04xh:%04xh), } [read-reg ds] [read-reg si]]
    return 0
}]
[defsubr print-air {} {
    echo -n [format {Adding rect (%d, %d, %d, %d), } [read-reg ax]
			[read-reg bx] [read-reg cx] [read-reg dx]]
    return 0
}]
[defsubr print-i {} {
    echo -n [format {Invalidating (%d, %d, %d, %d), } [read-reg ax]
			[read-reg bx] [read-reg cx] [read-reg dx]]
    return 0
}]

[defsubr print-iur {} {
    echo -n Region update:
    preg bp:si
    return 0
}]

[defsubr print-id {} {
    echo Done.
    return 0
}]

#
#	-v : VIDEO
# Prints the name (and parameters of) a call to a video driver.
#

[defsubr print-video {} {
    var code [type emap [read-reg di] [sym find type VidFunction]]
    echo -n $code
    [case $code in 
	DR_VID_RECT {
		echo [format { = %d %d %d %d} [read-reg ax]
			[read-reg bx] [read-reg cx] [read-reg dx]]
	}
	DR_VID_PUTSTRING {
		echo -n [format { at %d, %d '} [read-reg ax]
			[read-reg bx]]
    	    	var seg [value fetch ss:bp.VPS_stringSeg]
		var ptr [read-reg si]
		[for {var c [value fetch $seg:$ptr byte]}
		     {$c != 0}
		     {var c [value fetch $seg:$ptr byte]}
		     {
		         echo -n [format %c $c]
			 var ptr [expr $ptr+1]
		     }
		]
		echo '
	}
	default {
		echo
	}
    ]
    return 0
}]

#
#	-g: GEOMETRY
#


[defsubr 	start-geometry {} {
    global getsizeDepth

    var getsizeDepth 0
    echo [format {%*sBegin Geometry Update: -----------------------------} 
		[expr $getsizeDepth*3] {}]

    start-calc-new-size
    return 0
}]

[defsubr 	end-geometry {} {
    global getsizeDepth

    end-calc-new-size
    echo [format {%*sEnd Geometry Update (may continue up): -------------} 
		[expr $getsizeDepth*3] {}]
    echo
    return 0
}]


[defsubr 	start-calc-new-size {} {
    global getsizeDepth

    var csym [symbol faddr var *(*ds:si).MB_class]
    if {[null $csym]} {
      echo -n [format {%*s%s(^l%04xh:%04xh[?],%04xh,%04xh)} [expr $getsizeDepth*3] {}
	    	 CALC_NEW_SIZE [value fetch ds:LMBH_handle] [read-reg si] [read-reg cx]
		 [read-reg dx]]
    } else {
      echo -n [format {%*s%s(^l%04xh:%04xh) (%04xh,%04xh)} [expr $getsizeDepth*3] {}
	    	 [symbol name $csym] [value fetch ds:LMBH_handle] [read-reg si] 
		 [read-reg cx] [read-reg dx]]
    }

     var addr [addr-parse *ds:si]
     var seg [handle segment [index $addr 0]]
     var off [index $addr 1]
     var masteroff [value fetch $seg:$off.Vis_offset]
     var master [expr $off+$masteroff]
     var comp [field [value fetch $seg:$master.VI_typeFlags]
 							VTF_IS_COMPOSITE]
     [if {$comp} {
        echo :
     }]

    var getsizeDepth [expr {$getsizeDepth + 1}]
    return 0
}]


[defsubr	end-calc-new-size {} {
    global getsizeDepth breakpoint

    var getsizeDepth [expr {$getsizeDepth - 1}]


    var addr [addr-parse *ds:si]
    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]
    var masteroff [value fetch $seg:$off.Vis_offset]
    var master [expr $off+$masteroff]
    var comp [field [value fetch $seg:$master.VI_typeFlags]
						       VTF_IS_COMPOSITE]

    [if {$comp} {
	echo -n [format {%*sReturns } [expr $getsizeDepth*3] {}]
    } else {
       echo -n [format {-> }]
    }]

    echo -n [format {(%04xh,%04xh)} [read-reg cx]
		[read-reg dx]]

    echo
    return 0
}]



[defsubr    	end-spacing {} {
    global getsizeDepth breakpoint
    
    var csym [symbol faddr var *(*ds:si).MB_class]
    if {[null $csym]} {var cname ?} {var cname [symbol name $csym]}
        
     echo [format {%*sSpacing (%xh,%xh)} 
 	    [expr $getsizeDepth*3] {}
 	    [read-reg cx] [read-reg dx]]

    return 0
}]

[defsubr    	end-margins {} {
    global getsizeDepth breakpoint
    
    var csym [symbol faddr var *(*ds:si).MB_class]
    if {[null $csym]} {var cname ?} {var cname [symbol name $csym]}
        
     echo [format {%*sMargins (%xh,%xh,%xh,%xh)} 
 	    [expr $getsizeDepth*3] {}
     	    [read-reg ax] [read-reg bp] [read-reg cx] [read-reg dx]]

    return 0
}]

[defsubr    	end-min-size {} {
    global getsizeDepth breakpoint
    
    var csym [symbol faddr var *(*ds:si).MB_class]
    if {[null $csym]} {var cname ?} {var cname [symbol name $csym]}
        
     echo [format {%*sMinimum length %xh, width %xh} 
 	    [expr $getsizeDepth*3] {}
     	    [read-reg cx] [read-reg dx]]

    return 0
}]
    
[defsubr    	end-center {} {
    global getsizeDepth breakpoint
    
    var csym [symbol faddr var *(*ds:si).MB_class]
    if {[null $csym]} {var cname ?} {var cname [symbol name $csym]}
        
    echo [format {%*sObject's center in X: (%xh,%xh) in Y: (%xh,%xh)}
 	    [expr $getsizeDepth*3] {}
     	    [read-reg cx] [read-reg dx] [read-reg ax] [read-reg bp]]
    return 0
}]
    
    
#
#	-l : LMEM
#

[defsubr	print-la {} {
    echo [format {LMemAlloc, size = %d, heap = %04xh (at %04xh)}
		[read-reg cx] [value fetch ds:LMBH_handle] [read-reg ds]]
    return 0
}]

[defsubr	print-lf {} {
    echo [format {LMemFree, chu[199znk = %04xh, heap = %04xh (at %04xh)}
		[read-reg ax] [value fetch ds:LMBH_handle] [read-reg ds]]
    return 0
}]

[defsubr	print-lr {} {
    echo -n [format {LMemReAlloc, chunk = %04xh, old size = %d, new size = %d,}
		[read-reg ax] [expr [value fetch (*ds:ax)-2 [type word]]-2]
		[read-reg cx]]
    echo [format {heap = %04xh (at %04xh)}
		[value fetch ds:LMBH_handle] [read-reg ds]]
    return 0
}]

[defsubr	print-lch {} {
    echo [format {LMemCompactHeap, heap = %04xh (at %04xh), size = %04xh, free = %04xh}
	[value fetch ds:LMBH_handle] [read-reg ds]
	[value fetch ds:LMBH_blockSize]
	[value fetch ds:LMBH_totalFree]
    ]	
    return 0
}]

[defsubr	print-lgs {} {
    echo [format {GSE_reAlloc\thandle = %04xh, old = %04xh, new = %04xh}
	[read-reg bx] [expr 16*[value fetch kdata:bx.HM_size]]
	[read-reg ax]]
    return 0
}]

[defsubr	print-lco {} {
    echo [format {CNN_contract\thandle = %04xh, old = %04xh, new = %04xh}
	[read-reg bx] [expr 16*[value fetch kdata:bx.HM_size]]
	[expr 16*[read-reg ax]]]
    return 0
}]

#
#	-m : MEM
#
[defsubr	print-ma {} {
    echo [format {MemAlloc\tsize = %d, flags = %d}
		[read-reg ax] [read-reg cx]]
    return 0
}]

[defsubr	print-mf {} {
    echo [format {MemFree\t\thandle = %04xh} [read-reg bx]]
    return 0
}]

[defsubr	print-mr {} {
    echo [format {DoReAlloc\thandle = %04xh, old = %04xh, new = %04xh}
		[read-reg bx] [value fetch kdata:bx.HM_size]
		[read-reg ax]]
    return 0
}]


#
#	-o : OBJECT
#
[defsubr	print-om {} {
    echo -n {Message, }
    if {[fieldmask MF_RECORD] & [read-reg di]} {
    	echo -n {RECORD, }
    } elif {[fieldmask MF_CALL] & [read-reg di]} {
	echo -n {CALL, }
    } else {
	echo -n {SEND, }
    }
    if {[fieldmask MF_FORCE_QUEUE] & [read-reg di]} {
	echo -n {QUEUE, }
    }
    if {[fieldmask MF_STACK] & [read-reg di]} {
	echo -n {STACK, }
    }
    if {[fieldmask MF_CHECK_DUPLICATE] & [read-reg di]} {
	echo -n {CHECK, }
    }
    [print-obj-and-method [read-reg bx] [read-reg si] -l [read-reg ax] [read-reg cx]
    	    	    	  [read-reg dx] [read-reg bp]]
    return 0
}]

[defsubr print-call-ds:si {func class}
{
    var h [handle find ds:si]

    echo -n [format {%s, } $func]
    if {[handle state $h] & 0x800} {
    
    	# ds:si lies in an lmem block, so we assume it's an object
    	[print-obj-and-method [handle id $h] [read-reg si] -l
	    [read-reg ax] [read-reg cx] [read-reg dx] [read-reg bp] $class]
    } else {
    	var class [symbol faddr var *ss:TPD_classPointer]

	[print-obj-and-method [value fetch ss:TPD_threadHandle] [read-reg si]
	    -l [read-reg ax] [read-reg cx] [read-reg dx] [read-reg bp] $class]
    }
}]

[defsubr	print-ocinles {} {
    var fn [sym faddr var *(*ds:si).MB_class]
    
    print-call-ds:si CallInstanceNoLockES $fn
    return 0
}]

[defsubr	print-ocinl {} {
    print-call-ds:si CallInstanceNoLock [sym faddr var *(*ds:si).MB_class]
    return 0
}]

[defsubr	print-occnl {} {
    print-call-ds:si CallClassNoLock [sym faddr var es:di]
    return 0
}]

[defsubr	print-ocsnl {} {
    var class [sym faddr var es:di]
    
    # get super-class
    var sn [index [symbol get $class] 4]
    
    if {[null $sn]} {
    	print-call-ds:si {CallSuperNoLock (variant/meta)} $class
    } else {
    	print-call-ds:si CallSuperNoLock $sn
    }
    return 0
}]

#
#	-w : WINDOW
#
[defsubr	print-wo {} {
    echo [format {WinOpen, bounds = (%d, %d, %d, %d)}
			[read-reg ax] [read-reg bx]
			[read-reg cx] [read-reg dx]]
    return 0
}]

[defsubr	print-wc {} {
    echo [format {WinClose, handle = %04xh} [read-reg di]]
    return 0
}]

[defsubr	print-wm {} {
    echo -n [format {WinMove, handle = %04xh, move = (%d, %d) }
			[read-reg di] [read-reg ax] [read-reg bx]]
    if {[read-reg si] & [fieldmask WPF_ABS]} {
	echo relative to parent window
    } else {
	echo relative to current position
    }
    return 0
}]

[defsubr	print-wr {} {
    echo -n [format {WinResize, handle = %04xh, resize = (%d, %d, %d, %d)}
			[read-reg di] [read-reg ax] [read-reg bx] 
			[read-reg cx] [read-reg dx]]
    if {[read-reg si] & [fieldmask WPF_ABS]} {
	echo absolute
    } else {
	echo
    }
    return 0
}]

[defsubr	print-wcp {} {
    echo [format {WinChangePriority, handle = %04xh, flags = %04xh}
			[read-reg di] [read-reg ax]]
    return 0
}]

#
#	-s : SHUTDOWN	
#
[defsubr get-class-name {bx si} {
	   var od_handle $bx
	   if {$od_handle==0} {
		var name {NULL}
	   } else {
	       	var h [handle lookup $od_handle]
		[var odown [handle owner $h]
	     	odname [index [range [patient fullname [handle patient $h]]
			     0 7 chars] 0]]
	   	if {$h == $odown} {
	        	var thread [value fetch kdata:[handle id $h].HM_otherInfo]
	       	        var h [handle lookup $thread]
		        var ss [value fetch kdata:$thread.HT_saveSS]
		        var class [sym faddr var *$ss:TPD_classPointer] obj {}
   			var name [symbol name $class]
	    	} elif {[handle isthread $h]} {
	        	var ss [value fetch kdata:[handle id $h].HT_saveSS]
	        	var class [sym faddr var *$ss:TPD_classPointer] obj {}
   			var name [symbol name $class]
	    	} elif {([handle state $h] & 0xf0000) == 0x40000} {
	        	# queue handle. See if it's got an associated thread
	        	var tid [value fetch kdata:[handle id $h].HQ_thread]
	        	if {$tid != 0} {
    	    	    	# Use the associated thread's class
    	    	    		var h [handle lookup $tid]
	    	    		var ss [value fetch kdata:$tid.HT_saveSS]
		    		var class [sym faddr var *$ss:TPD_classPointer] obj {}
	   			var name [symbol name $class]
    	        	} else {
    	    	    		var name {Queue}
		    #
		    # Disembodied event queue. Can't map the method to anything
		    # but at least print something
		    #
 	   	       }
    	    	} else {
    	        	if {[expr [handle state $h]&0x40]} {
    	            		echo DISCARDED_OBJECT
		    		return 1
    	        	} else {
		   		var class [sym faddr var *(^l$bx:$si).MB_class]
		   		if {[null $class]} {
		   			var name {UNKNOWN}
		   		} else {
		   			var name [symbol name $class]
		   		}
			}
	   	}
	   }
	return $name
}]


[defsubr print-obj-ack-info {}
{
	var name [get-class-name [read-reg bx] [read-reg si]]
	var src [get-class-name [read-reg dx] [read-reg bp]]
   	echo [format {%s (^l%04xh:%04xh) sending MSG_META_ACK to %s (^l%04xh:%04xh)}
			$src [read-reg dx] [read-reg bp] $name
			[read-reg bx] [read-reg si]]
	return 0
}]
[defsubr print-thread-ack-info {}
{
	var name [get-class-name [read-reg bx] [read-reg si]]
   	echo [format {Exiting thread sending MSG_META_ACK to %s (^l%04xh:%04xh)}
			$name [read-reg bx] [read-reg si]]
	return 0
}]
[defsubr print-detach-info {}
{
    var method [map-method [read-reg ax] MetaClass]
    [case $method in
    	{MSG_META_DETACH* MSG_META_ACK} {
	   var name [get-class-name [read-reg bx] [read-reg si]]
	   echo -n [format {Sending %s to %s at ^l%04xh:%04xh} $method $name
				[read-reg bx] [read-reg si]]
	   
	   echo [format {, data = %04xh, %04xh, %04xh} [read-reg cx]
    	   		 	[read-reg dx] [read-reg bp]]
	}
    ]
    return 0
}]

[defsubr print-shutdown-info-ds:si {}
{
    var method [map-method [read-reg ax] MetaClass]
    [case $method in
    	{MSG_META_DETACH* MSG_META_ACK} {
	   var class [sym faddr var *(*ds:si).MB_class]
	   if {[null $class]} {
	   	var name {class unknown}
	   } else {
	   	var name [symbol name $class]
	   }
	   echo -n [format {Sending %s to %s at *%04xh:%04xh} $method $name
				[read-reg ds] [read-reg si]]
	   
	   echo [format {, data = %04xh, %04xh, %04xh} [read-reg cx]
    	   		 	[read-reg dx] [read-reg bp]]
	}
    ]
    return 0
}]


#
#	-i : SOFTWARE INTERRUPT CALLS
#
[defsubr	print-rci {} {
    var seg [value fetch ss:sp+2 [type word]]
    var off [value fetch ss:sp   [type word]]
    
    var doff [value fetch $seg:$off+1 [type word]]
    var j [map i {0 1} {value fetch $seg:$off-1+$i byte}]
    var dhan [expr (([index $j 0]&0xf)<<4)+([index $j 1]<<8)]
    
    var dest [sym faddr func ^h$dhan:$doff]
    echo [format {<Interrupt> %s (called from %s)}
			[sym name $dest]
			[frame function [frame next [frame top]]]]
    return 0
}]

#
#	-d : DISPATCH
#
[defsubr	print-disp {} {
    var han [handle lookup [read-reg si]]
    echo [format {Dispatching %s:%d}
		[patient name [handle patient $han]]
		[thread number [handle other $han]] ]
    return 0
}]
#
# 	-b : BUILD
#
[defsubr	print-build {} {
    var addr [addr-parse *(*ds:si).MB_class]
    # Find the symbol token for that class and get its name
    var tok [symbol faddr var [handle segment [index $addr 0]]:[index $addr 1]]
    var sname [symbol name $tok]
    echo [format {%s (%s, *%04xh:%04xh)}
			[func] $sname [read-reg ds] [read-reg si]]
    return 0
}]

[defsubr	print-add {} {
    var addr [addr-parse *(^lcx:dx).MB_class]
    # Find the symbol token for that class and get its name
# THERE was an error on the following line once where the address looked for
# was *65a8h:0026h.  This was upon selecting the professional button and
# starting up GeoManager.  rsf 8/1/91
    var tok [symbol faddr var [handle segment [index $addr 0]]:[index $addr 1]]
    var sname [symbol name $tok]
    echo [format {%s (%s, ^l%04xh:%04xh)}
			 [func] $sname [read-reg cx] [read-reg dx]]
	
    var addr [addr-parse *(*ds:si).MB_class]
    # Find the symbol token for that class and get its name
    var tok [symbol faddr var [handle segment [index $addr 0]]:[index $addr 1]]
    var sname [symbol name $tok]
    echo -n [format {    to (%s, *%04xh:%04xh), }
			$sname [read-reg ds] [read-reg si]]
echo ERROR COVERED UP IN print-add in showcalls.tcl!
#    echo [format {%s, ref #%s}
#			[type emap [expr {[read-reg bp] & 0xff}] [sym find type CompChildFlags]] [expr {[read-reg bp] >> 8}]]

    return 0
}]

#
#	-f : FLOW GRABS
#

[defsubr	print-fgm {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowGrabMouse, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-ffgm {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowForceGrabMouse, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-frm {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowReleaseMouse, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-fgk {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowGrabKbd, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-ffgk {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowForceGrabKbd, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-frk {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowReleaseKbd, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-abpp {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowAddButtonPrePassive, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-rbpp {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowRemoveButtonPrePassive, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-abop {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowAddButtonPostPassive, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-rbop {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowRemoveButtonPostPassive, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-akpp {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowAddKbdPrePassive, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-rkpp {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowRemoveKbdPrePassive, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-akop {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowAddKbdPostPassive, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 
}]

[defsubr	print-rkop {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowRemoveKbdPostPassive, ^l%04xh:%04xh, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]



[defsubr	print-gw {} {
    echo [format {FlowGrabWindow, ^h%04xh} [read-reg di]]
    return 0
}]

[defsubr	print-rw {} {
    echo [format {FlowReleaseWindow, ^h%04xh} [read-reg di]]
    return 0
}]

#
#	-G : GrCreate and GrDestroy
#

[defsubr	print-grcreate {} {
    global gsCount gsLevel
    var gsCount [expr $gsCount+1]
    var gsLevel [expr $gsLevel+1]
    echo [format {(%d), GrCreateState #%d, from %s} $gsLevel $gsCount
		[frame function [frame next [frame top]]]]
    return 0
}]

[defsubr	print-grdestroy {} {
    global gsLevel
    echo [format {(%d), GrDestroyState, from %s} $gsLevel
		[frame function [frame next [frame top]]]]
    var gsLevel [expr $gsLevel-1]
    return 0
}]

#
#	-n : WIN NOTIFICATION
#

[defsubr	print-wsg {} {
    echo WinStartGrab
    return 0
}]

[defsubr	print-weg {} {
    echo WinEndGrab
    return 0
}]

[defsubr	print-wmg {} {
    echo [format {WinMouseGrab, ^h%04xh} [read-reg di]]
    return 0
}]

[defsubr	print-wmr {} {
    echo [format {WinMouseRelease, ^h%04xh} [read-reg di]]
    return 0
}]

[defsubr	print-wbe {} {
    echo [format {WinBranchExclude, ^h%04xh} [read-reg di]]
    return 0
}]

[defsubr	print-wbi {} {
    echo [format {WinBranchInclude, ^h%04xh} [read-reg di]]
    return 0
}]

#
#	-n : NAVIGATION
#
[defsubr 	start-nav {} {
    global navIndent

    var navIndent 0
    echo [format {%*sBeginning Navigation Query: -----------------------------} 
		[expr $navIndent*2] {}]
    return 0
}]

[defsubr 	end-nav {} {
    global navIndent

    echo [format {%*sEnding Navigation Query ---------------------------------} 
		[expr $navIndent*2] {}]
    echo
    return 0
}]

[defsubr	print-naventer {} {
    global navIndent

    var navIndent [expr {$navIndent + 1}]

    var sn [sym fullname [sym faddr var *(*ds:si).MB_class]]
    echo [format {%*s-----------------------} [expr $navIndent*2] {}]
    echo -n [format {%*sVisNavigateCommon, ^l%04xh:%04xh, %s, }
		[expr $navIndent*2] {} [value fetch ds:LMBH_handle]
		[read-reg si] [name-root $sn]]
    pobjmon *ds:si 1
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {%*s  originator = ^l%04xh:%04xh, %s}
		[expr $navIndent*2] {} [read-reg cx] [read-reg dx] [name-root $sn]]

    echo -n [format {%*s  NavigateFlags =}
		[expr $navIndent*2] {}]
    precord ui::NavigateFlags bp 1

    echo -n [format {%*s  NavigateCommonFlags =}
		[expr $navIndent*2] {}]
    precord ui::NavigateCommonFlags bl 1
    return 0
}]

[defsubr	print-navleave {} {
    global navIndent
    echo [format {%*s-----------------------} [expr $navIndent*2] {}]
    var navIndent [expr {$navIndent - 1}]
    return 0
}]

[defsubr	print-navfirstchild {} {
    global navIndent

    echo [format {%*s  SENDING TO FIRST VISIBLE CHILD...}
		[expr $navIndent*2] {}]
    return 0
}]

[defsubr	print-navreachedroot {} {
    global navIndent

    echo [format {%*s  reached root node (WIN_GROUP). Sending to first visible child...}
		[expr $navIndent*2] {}]
    return 0
}]

[defsubr	print-navcompleted {} {
    global navIndent

    echo [format {%*s  COMPLETED CIRCUIT. Returning...}
		[expr $navIndent*2] {}]
    return 0
}]

[defsubr	print-navprevious {} {
    global navIndent

    echo [format {%*s  REACHED PREVIOUS FOCUSABLE NODE.}
		[expr $navIndent*2] {}]
    echo [format {%*s  RETURNING PREVIOUS OD = ^l%04xh:%04xh, %s}
		[expr $navIndent*2] {} [read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-navreturnOD {} {
    global navIndent

    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {%*s  RETURNING OD = ^l%04xh:%04xh, %s}
		[expr $navIndent*2] {} [read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-navhint {} {
    global navIndent

    echo [format {%*s  SENDING TO NEXT NODE (using ID from hint)...}
		[expr $navIndent*2] {}]
    return 0
}]

[defsubr	print-navsibling {} {
    global navIndent

    echo [format {%*s  SENDING TO NEXT NODE (visible sibling)...}
		[expr $navIndent*2] {}]
    return 0
}]

[defsubr	print-navparent {} {
    global navIndent

    echo [format {%*s  SENDING TO VISIBLE PARENT...}
		[expr $navIndent*2] {}]
    return 0
}]

#
#	-S : Stack borrowing
#

[defsubr print-stack-borrow {} {
    if {[null [sym find var stackBorrowCount]]} {
	echo [format {Borrow for %s, limit = %d, cur = %d}
		[sym name [frame funcsym [frame next [frame top]]]]
		[expr [read-reg di]-[value fetch ss:TPD_stackBot]-100]
		[expr [read-reg sp]-[value fetch ss:TPD_stackBot]-100]]
    } else {
	echo [format {#%d, for %s, limit = %d, cur = %d}
		[expr [value fetch stackBorrowCount]+1]
		[sym name [frame funcsym [frame next [frame top]]]]
		[expr [read-reg di]-[value fetch ss:TPD_stackBot]-100]
		[expr [read-reg sp]-[value fetch ss:TPD_stackBot]-100]]
    }
    return 0
}]

###############################################################################
#	-L : Loading a Library
#
# Revisions:
#	EDS	6/14/92	Initial Version
#
###############################################################################


[defsubr 	loadgeodelow-start {} {
	require pstring pvm.tcl
    global gloadIndent

    echo -n [format {%*sLoadGeodeLow: opening file: }
		[expr $gloadIndent*2] {} ]
    pstring ds:si

    var gloadIndent [expr {$gloadIndent + 1}]
    return 0
}]

[defsubr 	loadgeodelow-openError {} {
    global gloadIndent
    echo [format {%*sERROR OPENING FILE }
		[expr $gloadIndent*2] {} ]
    return 0
}]

[defsubr 	loadgeodelow-done {} {
    global gloadIndent

#   echo [format {%*sexiting LoadGeodeLow }
#			[expr $gloadIndent*2] {}]
    var gloadIndent [expr {$gloadIndent - 1}]
    return 0
}]

#------------------------------------------------------------------------------

[defsubr 	useliblow-start {} {
    global gloadIndent

    echo -n [format {%*sLoading: } [expr $gloadIndent*2] {}]

    # deal with XIP geodes
    if {[catch {frame funcsym [frame next [frame top]]} fsym] == 0 && 
    	   ![null $fsym]} {
    	if {[string compare [sym name $fsym] UseXIPLibrary] == 0} {
    	    var pname [patient name [handle patient [handle lookup [read-reg bx]]]]
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

    var gloadIndent [expr {$gloadIndent + 1}]
    return 0
}]

[defsubr 	useliblow-protoerror {} {
    require getstring cwd
    global gloadIndent
    global dbcs

    # AX is trashed when TestProtocolNumbers returns to UseLibraryLow,
    # so grab its original value here.

    var oldax [value fetch es:di.ILE_protocol.PN_major word]
    var oldbx [value fetch es:di.ILE_protocol.PN_minor word]

    # The handle of the client Geode is on the stack. Grab it,
    # and form the name of the client.
    # (Actually, the "loader" still owns this handle, but the name of
    # the new client is in the core block.)

    var ihan [value fetch ss:sp word]

    # need to do an SBCS getstring on the permanent name
    var old_dbcs $dbcs
    var dbcs {}
    var iname [getstring ^h$ihan.GH_geodeName 8]
    var dbcs $old_dbcs

    # The handle of the imported geode is at ds:[GH_geodeHandle].
    # Grab it and form the name of the imported geode.

    var ghan [value fetch ds:GH_geodeHandle]
    var gname [patient name [handle patient [handle lookup $ghan]]]
    echo [format {%*sPROTOCOL ERROR WHILE LOADING: %s.}
			[expr $gloadIndent*2] {} $gname]

    echo [format {%*s%s expects: %d.%d}
			[expr $gloadIndent*2] {}
			$iname $oldax $oldbx]

    echo [format {%*sProtocol number for %s: %d.%d}
			[expr $gloadIndent*2] {}
			$gname [read-reg cx] [read-reg dx]]
    return 0
}]

#[defsubr 	useliblow-loadit {} {
#    global gloadIndent
#    echo [format {%*sLoading Geode... }
#		[expr $gloadIndent*2] {} ]
#    return 0
#}]

#[defsubr 	useliblow-inmemory {} {
#    global gloadIndent
#    echo [format {%*sLoading Geode... }
#		[expr $gloadIndent*2] {} ]
#    return 0
#}]

#[defsubr 	useliblow-calllibentrypoint {} {
#    global gloadIndent
#    echo [format {%*sCalling Library Entry Point... }
#		[expr $gloadIndent*2] {} ]
#    return 0
#}]

[defsubr 	useliblow-done {} {
    global gloadIndent

#   echo [format {%*sexiting UseLibraryLow }
#			[expr $gloadIndent*2] {}]

    var gloadIndent [expr {$gloadIndent - 1}]
    return 0
}]

#------------------------------------------------------------------------------
[defsubr 	loadgeodeafter-start {} {
    global gloadIndent

#   echo [format {%*sLoadGeodeAfterFileOpen}
#		[expr $gloadIndent*2] {} ]

    var gloadIndent [expr {$gloadIndent + 1}]
    return 0
}]

[defsubr 	loadgeodeafter-done {} {

    require	getcc setcc.tcl

    global gloadIndent

    var gloadIndent [expr {$gloadIndent - 1}]

    if { [getcc c] } {
	echo -n [format {%*sERROR: }
			[expr $gloadIndent*2] {}]
	echo [format {%s} [penum GeodeLoadError [read-reg ax]]]
    }

    return 0
}]

#------------------------------------------------------------------------------
[defsubr 	tryopencommon-openfile {} {
    require pstring pvm.tcl
    global gloadIndent

    var name [sym faddr var es:di]

    echo -n [format {%*sOpening: }
		[expr $gloadIndent*2] {} ]

    pstring ds:dx

    return 0
}]

###############################################################################
#------------------------------------------------------------------------------
#FUNCTION:	get-instance-field-name
#
#DESCRIPTION:	This function returns the name of the instance data field
#		which is specified by BX and DI for the current object.
#		NOTE: also removes "HG_OD", "BG_OD", and "MG_OD" from the end.
#
#PASS:		*ds:si	= instance data for object
#		bx	= offset of master class (Gen_offset, Vis_offset, etc)
#		di	= offset to instance data field in that class
#				(offset OLFI_appExcl, for example)
#
#RETURNS:	name of field "OLFI_applExcl", etc.
#
#REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	Eric	2/90		A gift from Adam.
#
#------------------------------------------------------------------------------

[defsubr	get-instance-field-name {obj} {
    # Make sure next-master is loaded

    require next-master pobject
  
    # Fetch the masterOffset for the object's class so we know how many to skip
    
    var mo [value fetch (*($obj).MB_class).Class_masterOffset]

    if {$mo==0} {
        # if no master class, grab class name and fetch type info for it.
	var sn [sym fullname [sym faddr var *($obj).MB_class]]
	var itype [sym find type [obj-name $sn Instance]]
    } else {
	# Find the lowest class and its instance structure in the proper master
	# group (cua::dgroup::OLFieldClass cua::OLFieldBase cua::OLFieldInstance
 
	var clist [next-master $obj [expr ($mo-[read-reg bx])/2]]
 
	# Use the last field (cua::OLFieldInstance) to find type info for
	# instance data. Returns: 1424796 4784 5132 (or similar).
 
	var itype [sym find type [index $clist 2]]
    } 

    # Map di to a field name in the given instance structure.
    # Returns: OLFI_applExcl.HG_OD 32 {767088 956 2015}
 
    var flist [type field $itype [read-reg di]]
 
    # Grab the full name from the list (first element)
    # sets name = OLFI_applExcl.HG_OD
 
    var name [index $flist 0]

    # And remove any suffix in the name (subfield in this field's structure
    # definition, such as "HG_OD".

    [case $name in
	*.HG_* {
	    var name [range $name 0 [expr [string first .HG_ $name]-1] c]
	}
	*.BG_* {
	    var name [range $name 0 [expr [string first .BG_ $name]-1] c]
	}
	*.MG_* {
	    var name [range $name 0 [expr [string first .MG_ $name]-1] c]
	}
	default {
	    return $name
	}
    ]
    var ld [string last . $name]
    if {$ld >= 0} {
	return [range $name [expr $ld+1] end chars]
    } else {
	return $name
    }
}]

#
#	-e : FOCUS, TARGET, MODAL, and DEFAULT exclusives.
#

# GRAB and RELEASE utility routines

[defsubr	print-forcegrab {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj {FlowForceGrab}]
    flow-print-CX-DX-BP
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

[defsubr	print-releasegrab {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj {FlowReleaseGrab}]
    flow-print-CX-DX-BP
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

[defsubr	print-requestgrab {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj {FlowRequestGrab}]
    flow-print-CX-DX-BP
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

# INFO for notifyGained/notifyLost/SendMethodIfMisMatch utility routine.

[defsubr	print-fsm {} {
    global exclIndent

    if {[read-reg bx]} {
	var sn [sym fullname [sym faddr var *(^lbx:si).MB_class]]
	var en [map-method [read-reg ax] $sn ^lbx:si]
	echo [format {%*ssending: %s to %s (^l%04xh:%04xh)}
		[expr $exclIndent*4-2] {} $en
		[name-root $sn]
		[read-reg bx] [read-reg si] ]
    }
    return 0
}]

# GAINED and LOST utility routines

[defsubr	print-gainedsysexcl {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj {FlowGainedSysExcl}]
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

[defsubr	print-gainedappexcl {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj {FlowGainedAppExcl}]
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

[defsubr	print-lostsysexcl {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj {FlowLostSysExcl}]
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

[defsubr	print-lostappexcl {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj {FlowLostAppExcl}]
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

# subroutine used by GAINED and LOST functions

[defsubr	flow-print-obj {text} {
    global exclIndent

    # use *ds:si, bx, and di to get the name of the field,
    # "OLFI_applExcl" for example.

    var name [get-instance-field-name *ds:si]

    var sn [sym fullname [sym faddr var *(*ds:si).MB_class]]
    echo [format {%*s%s: at %s (^l%04xh:%04xh) %s}
		[expr $exclIndent*4] {} $text
		[name-root $sn]
		[value fetch ds:LMBH_handle] [read-reg si]
		$name ]
    return 0
}]

# ALTER WITHIN LEVEL utility routines

[defsubr	print-grabwithinlevel {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj {FlowGrabWithinLevel}]
    flow-print-CX-DX-BP
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

[defsubr	print-releasewithinlevel {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj {FlowReleaseWithinLevel}]
    flow-print-CX-DX-BP
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

# SUB-PROCEDURES USED ABOVE:

[defsubr	begin-excl-draw-line {} {
    global exclIndent
    if {$exclIndent==0} {
    	echo {---------- Beginning call ------------------------------------------}
    } else {
	echo [format {%*s%.*s} [expr $exclIndent*4] {} [expr 68-($exclIndent*4)]
	{--------------------------------------------------------------------}]
    }
    return 0
}]

# required to un-indent as the GRAB and RELEASE utility routines return

[defsubr	end-flowexcl {} {
    global exclIndent
    var exclIndent [expr {$exclIndent - 1}]
    if {$exclIndent==0} {
    	echo {---------- Ending call ---------------------------------------------}
	echo
    } else {
	echo [format {%*s%.*s} [expr $exclIndent*4] {} [expr 68-($exclIndent*4)]
	{--------------------------------------------------------------------}]
    }
    return 0
}]


[defsubr	flow-print-HG {} {
    global exclIndent
    var offset [value fetch ds:si [type word]]
    var part 0
    if {[read-reg bx]} {var part [value fetch ds:($offset+bx) [type word]]}
    var flags [value fetch ds:($offset+$part+di+4) [type word]]
    var low [value fetch ds:($offset+$part+di+0) [type word]]
    var high [value fetch ds:($offset+$part+di+2) [type word]]
    if {$high} {
        var gsn [sym fullname [sym faddr var *(^l$high:$low).MB_class]]
        echo [format {%*s  HG:    %s (^l%04xh:%04xh), flags = %04xh}
		[expr $exclIndent*4] {}
		[name-root $gsn]
		$high $low $flags ]
    } else {
        echo [format {%*s  HG:    (^l%04xh:%04xh), flags = %04xh}
		[expr $exclIndent*4] {}
		$high $low $flags ]
    }
}]

[defsubr	flow-print-CX-DX-BP {} {
    global exclIndent
    if {[read-reg cx]} {
	var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
	echo [format {%*s  regs:  %s (^l%04xh:%04xh), flags = %04xh}
		[expr $exclIndent*4] {}
		[name-root $sn] [read-reg cx] [read-reg dx] [read-reg bp]]
    } else {
	echo [format {%*s  regs:  ^l%04xh:%04xh, flags = %04xh}
		[expr $exclIndent*4] {}
		[read-reg cx] [read-reg dx] [read-reg bp]]
    }
}]

# main object printing routine

[defsubr	flow-print-obj {text} {
    global exclIndent
    # use *ds:si, bx, and di to get the name of the field,
    # "OLFI_applExcl" for example.

    echo -n [format {%*s%s at } [expr $exclIndent*4] {} $text]

    var sn [sym fullname [sym faddr var *(*ds:si).MB_class]]
    var name [get-instance-field-name *ds:si]
    echo [format {%s (^l%04xh:%04xh) %s} [name-root $sn]
		[value fetch ds:LMBH_handle] [read-reg si] $name ]

    flow-print-HG
    return 0
}]
#
#	-t : transfer routines
#

[defsubr	print-transfer-register {} {
    if {[read-reg bp]} {
	echo [format {Registering the QUICK transfer item at %04xh:%04xh}
		[read-reg bx] [read-reg ax]]
    } else {
	echo [format {Registering the NORMAL transfer item at %04xh:%04xh}
		[read-reg bx] [read-reg ax]]
    }
    return 0
}]

[defsubr	print-transfer-unregister {} {
    echo [format {Unregistering the item owned by ^l%04xh:%04xh}
	[read-reg cx] [read-reg dx]]
    return 0
}]

[defsubr	print-transfer-query {} {
    if {[read-reg bp]} {
	echo Querying for QUICK transfer item...
    } else {
	echo Querying for NORMAL transfer item...
    }
    finishframe [frame top]
    echo [format {	...returning %xh items owned by ^l%04xh:%04xh in header at %04xh:%04xh}
	    [read-reg bp]
	    [read-reg cx] [read-reg dx]
	    [read-reg bx] [read-reg ax]]
    return 0
}]

[defsubr	print-transfer-request {} {
    echo [format {Requesting '%s:%s' format from header at %04xh:%04xh}
	    [penum ManufacturerID [read-reg cx]]
	    [penum ui::ClipboardItemFormat [read-reg dx]]
	    [read-reg bx] [read-reg ax]]
    finishframe [frame top]
    if {[read-reg bp]} {
        echo [format {	...returning the transfer item at at %04xh:(%04xh:%04xh)}
	        [read-reg bx] [read-reg ax] [read-reg bp]]
    } else {
        echo [format {	...returning the transfer item at at %04xh:%04xh}
	        [read-reg bx] [read-reg ax]]
    }
    return 0
}]

[defsubr	print-transfer-done {} {
    echo [format {Done with transfer header at %04xh:%04xh}
	    [read-reg bx] [read-reg ax]]
    return 0
}]

[defsubr	print-transfer-addn {} {
    echo [format {Adding ^l%04xh:%04xh to transfer notification list}
		[read-reg cx] [read-reg dx]]
    return 0
}]

[defsubr	print-transfer-remn {} {
    echo [format {Removing ^l%04xh:%04xh from the transfer notification list}
		[read-reg cx] [read-reg dx]]
    return 0
}]

[defsubr	print-transfer-free {} {
    echo [format {Freeing the transfer item at %04xh:%04xh}
		[read-reg bx] [read-reg ax]]
    return 0
}]

[defsubr	print-transfer-save {} {
    echo [format {Saving the transfer item at %04xh:%04xh in free list (ref=%d)}
		[read-reg bx] [read-reg ax] [read-reg cx]]
    return 0
}]

[defsubr	print-transfer-sendn {} {
    global watchingTransferSend

    var watchingTransferSend 1
    echo [format {Sending %s notification to...}
	    [map-method [read-reg ax] MetaClass]]
    finishframe [frame top]
    var watchingTransferSend 0
    return 0
}]

[defsubr	print-transfer-sendnlow {} {
    global watchingTransferSend

    if {$watchingTransferSend} {
        echo [format {	...%04xh:%04xh}
		[value fetch ds:di.GCNLE_item.handle]
		[value fetch ds:di.GCNLE_item.chunk]]
    }
    return 0
}]

#
#	-r : resource calls
#

[defsubr	print-pcmr {} {
    var s [sym faddr proc ^hbx:ax]
    if {[null $s]} {
	echo [format {Module call to ^h%04xh:%04xh} [read-reg bx] [read-reg ax]]
    } else {
	echo [format {Module call to '%s'} [sym fullname $s]]
    }
    return 0
}]

[defsubr	print-rlcc {} {
    var s [sym faddr proc ^hbx:[value fetch ss:TPD_callVector [type word]]]
    if {[null $s]} {
	echo [format {Int call to ^h%04xh:%04xh} [read-reg bx]
				[value fetch ss:TPD_callVector [type word]]]
    } else {
	echo [format {Int call to '%s'} [sym fullname $s]]
    }
    return 0
}]

#
#   	-f : file calls
#
[defsubr print-file-open {} {
    require getstring cwd
    echo [format {FileOpen: <%s>} [getstring ds:dx]]
    return 0
}]

[defsubr print-file-read {} {
    echo [format {FileRead: %s, count = %d} [get-file-from-han bx]
    	    	    	    	    	    	    [read-reg cx]]
    return 0
}]

[defsubr print-file-write {} {
    echo [format {FileWrite: %s, count = %d} [get-file-from-han bx]
    	    	    	    	    	    	    [read-reg cx]]
    return 0
}]

[defsubr print-file-pos {} {
    var sft [value fetch kdata:bx.HF_sfn]
    var oldpos [field [read-sft-entry $sft] SFTE_position]
    echo [format {FilePos: %s, pos = %d, old pos = %d} [get-file-from-han bx]
    	    	    	    	[expr ([read-reg cx]<<16)+[read-reg dx]]
    	    	    	    	$oldpos]
    return 0
}]

[defsubr get-file-from-han {file} {
    var sft [value fetch kdata:$file.HF_sfn]
    var name [field [read-sft-entry $sft] SFTE_name]
    var ret {}
    foreach i $name {
    	var ret [format {%s%s} $ret $i]
    }
    return $ret
}]


#
#	-a : Attach/detach/state calls
#

[defsubr print-aavmfile {} {
    echo ObjAssocVMFile
    return 0
}]

[defsubr print-advmfile {} {
    echo ObjDisassocVMFile
    return 0
}]

[defsubr print-asesb {} {
    echo [format {ObjSaveExtraStateBlock: ^h%04xh}
		[read-reg cx]]
    return 0
}]

[defsubr print-gal {} {
    echo GenAppLazarus
    return 0
}]

[defsubr print-stesb {} {
    echo [format {SaveTempGenAppExtraStateBlock: ^h%04xh}
		[read-reg cx]]
    return 0
}]

[defsubr print-rtesb {} {
    echo [format {RetrieveTempGenAppExtraStateBlock: ^h%04xh}
		[read-reg cx]]
    return 0
}]


##############################################################################
#				print-cursor-enable
##############################################################################
#
# SYNOPSIS:	Note that the cursor has been enabled in a text object.
# CALLED BY:	via breakpoint
# PASS:		nothing
# RETURN:	0 indicating we should keep going
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/31/92	Initial Revision
#
##############################################################################
[defsubr print-cursor-enable {}
{
    echo [format {Cursor Enabled: (^l%04xh:%04xh)}
    	    	[value fetch ds:LMBH_handle]
		[read-reg si]]
    return 0
}]

##############################################################################
#				print-cursor-disable
##############################################################################
#
# SYNOPSIS:	Note that the cursor has been disabled in a text object.
# CALLED BY:	via breakpoint
# PASS:		nothing
# RETURN:	0 indicating we should keep going
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/31/92	Initial Revision
#
##############################################################################
[defsubr print-cursor-disable {}
{
    echo [format {Cursor Disabled: (^l%04xh:%04xh)}
    	    	[value fetch ds:LMBH_handle]
		[read-reg si]]
    return 0
}]

##############################################################################
#				print-cursor-toggle
##############################################################################
#
# SYNOPSIS:	Note that the cursor has been toggled in a text object.
# CALLED BY:	via breakpoint
# PASS:		nothing
# RETURN:	0 indicating we should keep going
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/31/92	Initial Revision
#
##############################################################################
[defsubr print-cursor-toggle {}
{
    echo [format {Cursor Toggled: (^l%04xh:%04xh)}
    	    	[value fetch ds:LMBH_handle]
		[read-reg si]]
    return 0
}]

##############################################################################
#				print-cursor-forceon
##############################################################################
#
# SYNOPSIS:	Note that the cursor has been forced on in a text object.
# CALLED BY:	via breakpoint
# PASS:		nothing
# RETURN:	0 indicating we should keep going
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/31/92	Initial Revision
#
##############################################################################
[defsubr print-cursor-forceon {}
{
    echo [format {Cursor Forced On: (^l%04xh:%04xh)}
    	    	[value fetch ds:LMBH_handle]
		[read-reg si]]
    return 0
}]

##############################################################################
#				print-cursor-drawifon
##############################################################################
#
# SYNOPSIS:	Note a request to draw the cursor if it's turned on.
# CALLED BY:	via breakpoint
# PASS:		nothing
# RETURN:	0 indicating we should keep going
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/31/92	Initial Revision
#
##############################################################################
[defsubr print-cursor-drawifon {}
{
    echo [format {Cursor Draw-If-On: (^l%04xh:%04xh)}
    	    	[value fetch ds:LMBH_handle]
		[read-reg si]]
    return 0
}]

##############################################################################
#				print-cursor-position
##############################################################################
#
# SYNOPSIS:	Note that the cursor has been repositioned
# CALLED BY:	via breakpoint
# PASS:		nothing
# RETURN:	0 indicating we should keep going
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/31/92	Initial Revision
#
##############################################################################
[defsubr print-cursor-position {}
{
    echo [format {Cursor Positioned @(r%d, %d,%d): (^l%04xh:%04xh)}
		[read-reg cx]
		[read-reg ax]
		[read-reg dx]
    	    	[value fetch ds:LMBH_handle]
		[read-reg si]]
    return 0
}]

##############################################################################
#				print-cursor-positionx
##############################################################################
#
# SYNOPSIS:	Note that the cursor has been repositioned on the X axis
# CALLED BY:	via breakpoint
# PASS:		nothing
# RETURN:	0 indicating we should keep going
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/31/92	Initial Revision
#
##############################################################################
[defsubr print-cursor-positionx {}
{
    echo [format {Cursor Positioned(X) (%d): (^l%04xh:%04xh)}
		[read-reg bx]
    	    	[value fetch ds:LMBH_handle]
		[read-reg si]]
    return 0
}]

#
#   -F: File-change notification
#

[defsubr print-fcn {args}
{
    var type [penum FileChangeNotificationType [read-reg ax]]
    echo $type
    if {[string c $type FCNT_BATCH]} {
	echo [format {disk = %04xh [%s]} [read-reg si] [mapconcat c [value fetch FSInfoResource:si.DD_volumeLabel] {var c}]]
	echo [format {id = %04x%04xh} [read-reg cx] [read-reg dx]]

	# For FCNT_CREATE and FCNT_RENAME, print out the name
	if {[read-reg ax] < 2} {
	    echo -n name =
	    pstring ds:bx
	}
    } else {
    	echo [format {block = %04xh, end = %04xh} [read-reg bx]
	    	[value fetch ^hbx:FCBND_end]]
    }
    return 0
}]

[defsubr print-batch-fcn {args}
{
    echo [format {batching at ^h%04xh:%04xh} [value fetch ss:TPD_fsNotifyBatch] [read-reg bx]]
    return 0
}]

#
# State file monitoring functions
#

[defsubr print-loading-resource {} {
    	echo [format {%s: LOCKING %s %d bytes}
	      [patient name]
	      [hname bx]
	      [expr [value fetch kdata:bx.HM_size]*16]]
	return 0
}]

[defsubr print-saving-resource {} {
    	echo [format {%s: SAVING %s}
	      [patient name]
	      [hname bx]]
	return 0
}]

[defsubr print-final-size {} {
    	echo [format {Final size of %s is %d bytes}
	      [hname bx]
	      [expr [value fetch ds:bx.HM_size]*16]]
	return 0
}]

#
#	-H: Show heapspace allocation information
#
#  JimG.  3/18/95
#

# Store the geode name at GeodeLoadLow and will print it out when we reach
# GeodeEnsureEnoughHeapSpaceCore.
#
[defsubr store-heapspace-geode-name {} {
    	require getstring cwd.tcl
    global print-heapspace-geodename
    
    var print-heapspace-geodename [getstring ds:si]
    
    return 0
}]
    
[defsubr print-geehsc-heapspace {} {
    global print-heapspace-geodename
    echo -n {Loading geode: }
    if {[null ${print-heapspace-geodename}]} {
    	echo {Unknown geode name}
    } else {
    	echo ${print-heapspace-geodename}
    	var print-heapspace-geodename {}
    }
    echo [format {Heap space required by geode: %dK} [read-reg cx]]
    echo [format {Heap space available (before load): %dK out of %dK (%.2f%%)}
	  [expr {[value fetch heapSize] - [read-reg ax]}]
	  [value fetch heapSize]
	  [expr {([value fetch heapSize] - [read-reg ax])/
	      [value fetch heapSize] * 100} f]]
    return 0
}]

[defsubr print-geehsc-after-detach {} {
    echo [format {After detach and load, heap space: %dK out of %dK (%.2f%%)}
	  [expr {[value fetch heapSize] - [read-reg cx]}]
	  [value fetch heapSize]
	  [expr {([value fetch heapSize] - [read-reg cx])/
	      [value fetch heapSize] * 100} f]]
    return 0
}]
    
[defsubr print-masd-add-to-heapsize {} {
    echo [format {Swap driver adding %dK to heap size ==> %dK}
	  [read-reg ax]
	  [expr {[read-reg ax] + [value fetch heapSize]}]]
    return 0
}]

[defsubr print-meh-add-to-heapsize {} {
    echo [format {MemExtendHeap adding %dK to heap size ==> %dK}
	  [read-reg ax]
	  [expr {[read-reg ax] + [value fetch heapSize]}]]
    return 0
}]

[defsubr print-ihs-initial-heapsize {} {
    echo [format {Initial calculated heap size %dK}
	  [value fetch heapSize]]
    return 0
}]
