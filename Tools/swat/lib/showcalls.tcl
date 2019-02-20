##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library
# FILE: 	showcalls.tcl
# AUTHOR: 	Adam de Boor, Dec 27, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	showcalls   	    	Turn on/off various monitors
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
#	$Id: showcalls.tcl,v 3.14 90/09/28 15:56:46 tony Exp $
#
###############################################################################
[defcommand showcalls {{flags {}} {args {}}} profile
{showcalls displays calls to various parts of PC GEOS.  The flags to showcalls
determine the types of calls displayed.  Invoking showcalls with no arguments
causes all call monitors to be disabled.  Flags must be all given in the first
argument such as "showcalls -vl"
    -p : Modify all other flags to work for the current patient only

    -b : Monitors vis builds
    -s : Monitors shutdown: METHOD_DETACH, DETACH_COMPLETE, ACK, DETACH_ABORT
    -d : Show dispatching of threads
    -e : Show FOCUS, TARGET, MODAL, DEFAULT, etc. exclusive grabs and releases
    -f : Show flow object calls for mouse, kbd & window grabs & releases
    -g : Show geometry manager resizing things (all sizes in hex)
    -i : Show software interrupt calls
    -l : Show local memory create, destroy, rellocate
    -m : Show global memory alloc, free, realloc
    -n : Show grab/exclude/include calls to window system
    -o : Show ObjMessage and ObjCallXXX
    -r : Show calls to a given resource
    -t : Show calls to transfer routines
    -v : Show calls to the video driver
    -w : Show WinOpen, WinClose, WinMoveResize, WinChangePriority

    -G : Show GrCreateState and GrDestroyState
    -N : Show navigation calls (between fields, and between windows)
}
{
	global	sc_vid sc_lmem sc_mem sc_obj sc_win sc_dispatch sc_geo
	global	sc_build sc_flowgrab sc_exclgrab sc_gstate sc_int sc_nav
	global	sc_transfer sc_resource sc_shutdown
	global	gsCount gsLevel
	global  getsizeDepth navIndent exclIndent

    var getsizeDepth 0
    var gsCount 0
    var gsLevel 0
    var navIndent 0
    var exclIndent 0
    remove-brk sc_video
    remove-brk sc_lmem
    remove-brk sc_mem
    remove-brk sc_obj
    remove-brk sc_shutdown
    remove-brk sc_win
    remove-brk sc_dispatch
    remove-brk sc_geo
    remove-brk sc_build
    remove-brk sc_flowgrab
    remove-brk sc_exclgrab
    remove-brk sc_gstate
    remove-brk sc_winnote
    remove-brk sc_int
    remove-brk sc_nav
    remove-brk sc_transfer
    remove-brk sc_resource
    var ps {aset}
    if {![null $flags]} {
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
				      [brk $ps LMemCompactHeap print-lch]]
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
		    var ma [index [symbol get [symbol find any METHOD_ACK]] 0]
#		    var md [index [symbol get [symbol find any METHOD_DETACH]] 0]
		    var aa [brk $ps ObjMessage print-detach-info]
		    var bb [brk $ps ObjDetachCompleted::sendmethod print-obj-ack-info]
		    var cc [brk $ps ThreadExit::swatlab print-thread-ack-info]
		    var dd [brk $ps ObjCallInstanceNoLockES
					print-shutdown-info-ds:si]
		    var ee [brk $ps ObjCallInstanceNoLock
					print-shutdown-info-ds:si]
		#HACK - only break on detach methods -- assumes METHOD_DETACH
		# is the first one and METHOD_ACK is the last
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
	     	w {
		    var sc_win [list [brk $ps WinOpen print-wo]
				     [brk $ps WinClose print-wc]
				     [brk $ps WinMoveResize print-wmr]
				     [brk $ps WinChangePriority print-wcp]]
		}
	     	d {
		    var sc_dispatch [list [brk $ps DispatchSI print-disp]]
		}
		g {
		    var sc_geo [list
		       [brk $ps ui::StartGeometry start-geometry]
		       [brk $ps ui::EndGeometry end-geometry]
		       [brk $ps ui::StartCalcNewSize start-calc-new-size]
		       [brk $ps ui::EndCalcNewSize end-calc-new-size]
		       [brk $ps ui::EndSpacing end-spacing]
		       [brk $ps ui::EndMinSize end-min-size]
		       [brk $ps ui::EndCenter end-center]]
		}
		b { 
		   var sc_build [list
		       [brk $ps ui::GenGenSetNotUsable print-build]
		       [brk $ps ui::GenGenSetUsable print-build]
		       [brk $ps ui::VisUpdateVisBuild print-build]
		       [brk $ps ui::VisVisBuild print-build]
		       [brk $ps ui::GenAddGenChild print-add]
		       [brk $ps ui::GenRemoveGenChild print-add]
		       [brk $ps ui::GenMoveGenChild print-add]
		       [brk $ps ui::VisCompAddVisChild print-add]
		       [brk $ps ui::VisCompRemoveVisChild print-add]
		       [brk $ps ui::VisCompMoveVisChild print-add]]
		}
		f {
		   var sc_flowgrab [list
		       [brk $ps ui::FlowGrabMouse print-fgm]
		       [brk $ps ui::FlowForceGrabMouse print-ffgm]
		       [brk $ps ui::FlowReleaseMouse print-frm]
		       [brk $ps ui::FlowGrabKbd print-fgk]
		       [brk $ps ui::FlowForceGrabKbd print-ffgk]
		       [brk $ps ui::FlowReleaseKbd print-frk]
		       [brk $ps ui::FlowAddButtonPrePassive print-abpp]
		       [brk $ps ui::FlowRemoveButtonPrePassive print-rbpp]
		       [brk $ps ui::FlowAddButtonPostPassive print-abop]
		       [brk $ps ui::FlowRemoveButtonPostPassive print-rbop]
		       [brk $ps ui::FlowAddKbdPrePassive print-akpp]
		       [brk $ps ui::FlowRemoveKbdPrePassive print-rkpp]
		       [brk $ps ui::FlowAddKbdPostPassive print-akop]
		       [brk $ps ui::FlowRemoveKbdPostPassive print-rkop]]
		}
		e {
		   var sc_exclgrab [list
		       [brk $ps ui::FlowForceGrab print-forcegrab]
		       [brk $ps ui::FlowForceGrab::done end-flowexcl]
		       [brk $ps ui::FlowReleaseGrab print-releasegrab]
		       [brk $ps ui::FlowReleaseGrab::done end-flowexcl]
		       [brk $ps ui::FlowRequestGrab print-requestgrab]
		       [brk $ps ui::FlowRequestGrab::done end-flowexcl]
		       [brk $ps ui::FlowGainedExcl print-gainedexcl]
		       [brk $ps ui::FlowGainedExcl::done end-flowexcl]
		       [brk $ps ui::FlowLostExcl print-lostexcl]
		       [brk $ps ui::FlowLostExcl::done end-flowexcl]
		       [brk $ps ui::FlowGrabWithinLevel print-grabwithinlevel]
		       [brk $ps ui::FlowGrabWithinLevel::done end-flowexcl]
		       [brk $ps ui::FlowReleaseWithinLevel print-releasewithinlevel]
		       [brk $ps ui::FlowReleaseWithinLevel::done end-flowexcl]
		       [brk $ps ui::FlowSendMethodIfMismatch::send print-fsm]]
		}
		n {
		   var sc_winnote [list
		       [brk $ps WinStartGrab print-wsg]
		       [brk $ps WinEndGrab print-weg]
		       [brk $ps WinMouseGrab print-wmg]
		       [brk $ps WinMouseRelease print-wmr]
		       [brk $ps WinBranchExclude print-wbe]
		       [brk $ps WinBranchInclude print-wbi]]
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
		       [brk $ps ui::VisNavigateCommon::completedCircuit print-navcompleted]
		       [brk $ps ui::VisNavigateCommon::isParentNode print-navfirstchild]
		       [brk $ps ui::VisNavigateCommon::reachedRoot print-navreachedroot]
		       [brk $ps ui::VisNavigateCommon::reachedPrevious print-navprevious]
		       [brk $ps ui::VisNavigateCommon::returnODCXDX print-navreturnOD]
		       [brk $ps ui::VisNavigateCommon::done print-navleave]
		       [brk $ps ui::VisNavSendToNextNode::sendViaHint print-navhint]
		       [brk $ps ui::VisNavSendToNextNode::sendToSibling print-navsibling]
		       [brk $ps ui::VisNavSendToNextNode::sendToParent print-navparent]]
		}
		t {
		   var sc_transfer [list
		       [brk $ps ui::UserRegisterTransfer print-transfer-register]
		       [brk $ps ui::UserUnregisterTransfer print-transfer-unregister]
		       [brk $ps ui::UserQueryTransfer print-transfer-query]
		       [brk $ps ui::UserRequestTransfer print-transfer-request]
		       [brk $ps ui::UserDoneWithTransfer print-transfer-done]
		       [brk $ps ui::UserAddTransferNotify print-transfer-addn]
		       [brk $ps ui::UserRemoveTransferNotify print-transfer-remn]
		       [brk $ps ui::FreeTransfer print-transfer-free]
		       [brk $ps ui::StoreInFreeList print-transfer-save]
		       [brk $ps ui::SendToNotificationList print-transfer-sendn]
		       [brk $ps ui::SendToNotificationList::sendIt print-transfer-sendnlow]]
		}
		r {
		   var aa [brk ResourceLibraryCallCommon print-rlcc]
		   brk cond $aa bx=$args
		   var bb [brk ProcCallModuleRoutine print-pcmr]
		   brk cond $bb bx=$args
		   var sc_resource [list $aa $bb]
		}
		default {
		    error [list Unrecognized flag $i]
		}]
	}
    }
}]

[defsubr remove-brk {bname} {
	global	$bname

    if {![null $[var $bname]]} {
	foreach i [var $bname] {
	    catch {brk clear $i}
	}
	var $bname {}
    }
}]

#
#	-v : VIDEO
# Prints the name (and parameters of) a call to a video driver.
#

[defsubr print-video {} {
    var code [type emap [read-reg di] [sym find type VidFunctions]]
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
      echo -n [format {%*s%s(*%04x:%04x[?],%04x,%04x)} [expr $getsizeDepth*3] {}
	    	 CALC_NEW_SIZE [read-reg ds] [read-reg si] [read-reg cx]
		 [read-reg dx]]
    } else {
      echo -n [format {%*s%s(*%04x:%04x) (%04x,%04x)} [expr $getsizeDepth*3] {}
	    	 [symbol name $csym] [read-reg ds] [read-reg si] 
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

    echo -n [format {(%04x,%04x)} [read-reg cx]
		[read-reg dx]]

    echo
    return 0
}]



[defsubr    	end-spacing {} {
    global getsizeDepth breakpoint
    
    var csym [symbol faddr var *(*ds:si).MB_class]
    if {[null $csym]} {var cname ?} {var cname [symbol name $csym]}
        
     echo [format {%*sMargins (%x,%x,%x,%x) Spacing (%x,%x)} 
 	    [expr $getsizeDepth*3] {}
     	    [read-reg cl] [read-reg dl] [read-reg ch] [read-reg dh]
 	    [read-reg al] [read-reg ah]]

    return 0
}]

[defsubr    	end-min-size {} {
    global getsizeDepth breakpoint
    
    var csym [symbol faddr var *(*ds:si).MB_class]
    if {[null $csym]} {var cname ?} {var cname [symbol name $csym]}
        
     echo [format {%*sMinimum length %x, width %x} 
 	    [expr $getsizeDepth*3] {}
     	    [read-reg cx] [read-reg dx]]

    return 0
}]
    
[defsubr    	end-center {} {
    global getsizeDepth breakpoint
    
    var csym [symbol faddr var *(*ds:si).MB_class]
    if {[null $csym]} {var cname ?} {var cname [symbol name $csym]}
        
    echo [format {%*sObject's center in X: (%x,%x) in Y: (%x,%x)}
 	    [expr $getsizeDepth*3] {}
     	    [read-reg cx] [read-reg dx] [read-reg ax] [read-reg bp]]
    return 0
}]
    
    
#
#	-l : LMEM
#

[defsubr	print-la {} {
    echo [format {LMemAlloc, size = %d, heap = %04x (at %04x)}
		[read-reg cx] [value fetch ds:LMBH_handle] [read-reg ds]]
    return 0
}]

[defsubr	print-lf {} {
    echo [format {LMemFree, chunk = %04x, heap = %04x (at %04x)}
		[read-reg ax] [value fetch ds:LMBH_handle] [read-reg ds]]
    return 0
}]

[defsubr	print-lr {} {
    echo -n [format {LMemReAlloc, chunk = %04x, old size = %d, new size = %d,}
		[read-reg ax] [expr [value fetch (*ds:ax)-2 [type word]]-2]
		[read-reg cx]]
    echo [format {heap = %04x (at %04x)}
		[value fetch ds:LMBH_handle] [read-reg ds]]
    return 0
}]

[defsubr	print-lch {} {
    echo [format {LMemCompactHeap, heap = %04x (at %04x)}
		[value fetch ds:LMBH_handle] [read-reg ds]]
    return 0
}]
#
#	-m : MEM
#
[defsubr	print-ma {} {
    echo [format {MemAlloc, size = %d, flags = %d}
		[read-reg ax] [read-reg cx]]
    return 0
}]

[defsubr	print-mf {} {
    echo [format {MemFree, handle = %04x} [read-reg bx]]
    return 0
}]

[defsubr	print-mr {} {
    echo [format {DoReAlloc, handle = %04x, old = %04x, new = %04x}
		[read-reg bx] [value fetch kdata:bx.HM_size]
		[read-reg ax]]
    return 0
}]

[defsubr	name-root {name} {
    var lo [expr [string last :: $name]+2]
    if {$lo == 1} {
	return $name
    } else {
        return [range $name $lo end chars]
    }
}]

#
#	-o : OBJECT
#
[defsubr	print-om {} {
    echo -n {Message, }
    if {[fieldmask MF_CALL] & [read-reg di]} {
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
    [print-obj-and-method [read-reg bx] [read-reg si] [read-reg ax] [read-reg cx]
    	    	    	  [read-reg dx] [read-reg bp]]
    return 0
}]

[defsubr print-call-ds:si {func class}
{
    var h [handle find ds:si]

    if {[null $class]} {
    	var name {class unknown} fn {}
    } else {
    	var name [symbol name $class] fn [symbol fullname $class]
    }
    
    if {[handle state $h] & 0x800} {
    	# ds:si lies in an lmem block, so we assume it's an object
    	var en [map-method [read-reg ax] $fn *ds:si]
	echo -n [format {%s, %s, *%04xh:%04xh, %s} $func
			 $en [read-reg ds] [read-reg si] $name]
    } else {
    	var en [map-method [read-reg ax] $fn]
	echo -n [format {%s, %s, ds=%04xh, si=%04xh, %s} $func $en
	    	    [read-reg ds] [read-reg si] $name]
    }
    echo [format {, data = %04xh, %04xh, %04xh} [read-reg cx]
    	    	[read-reg dx] [read-reg bp]]
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
    echo [format {WinClose, handle = %04x} [read-reg di]]
    return 0
}]

[defsubr	print-wmr {} {
    echo -n [format {WinMoveResize, handle = %04x, move = (%d, %d)}
			[read-reg di] [read-reg ax] [read-reg bx]]
    if {[read-reg si] & 0x0200} {
	echo [format {, resize to (%d, %d)} [read-reg cx] [read-reg dx]]
    } else {
	echo
    }
    return 0
}]

[defsubr	print-wcp {} {
    echo [format {WinChangePriority, handle = %04x, flags = %04x}
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
	        	var thread [value fetch ^h[handle id $h].PH_firstThread]
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
   	echo [format {%s at ^l%04xh:%04xh sending METHOD_ACK to %s at ^l%04xh:%04xh}
			$src [read-reg dx] [read-reg bp] $name
			[read-reg bx] [read-reg si]]
	return 0
}]
[defsubr print-thread-ack-info {}
{
	var name [get-class-name [read-reg bx] [read-reg si]]
   	echo [format {Exiting thread sending METHOD_ACK to %s at ^l%04xh:%04xh}
			$name [read-reg bx] [read-reg si]]
	return 0
}]
[defsubr print-detach-info {}
{
    var method [map-method [read-reg ax] MetaClass]
    [case $method in
    	METHOD_DETACH*|METHOD_ACK {
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
    	METHOD_DETACH*|METHOD_ACK {
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
    echo [format {Dispatching thread %d of process %s}
		[thread number [handle other $han]]
		[patient name [handle patient $han]]]
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
    echo [format {%s (%s, *%04x:%04x)}
			[func] $sname [read-reg ds] [read-reg si]]
    return 0
}]

[defsubr	print-add {} {
    var addr [addr-parse *(^lcx:dx).MB_class]
    # Find the symbol token for that class and get its name
    var tok [symbol faddr var [handle segment [index $addr 0]]:[index $addr 1]]
    var sname [symbol name $tok]
    echo [format {%s (%s, ^l%04x:%04x)}
			 [func] $sname [read-reg cx] [read-reg dx]]
	
    var addr [addr-parse *(*ds:si).MB_class]
    # Find the symbol token for that class and get its name
    var tok [symbol faddr var [handle segment [index $addr 0]]:[index $addr 1]]
    var sname [symbol name $tok]
    echo -n [format {    to (%s, *%04x:%04x), }
			$sname [read-reg ds] [read-reg si]]
    echo [format {%s, ref #%s}
			[type emap [expr {[read-reg bp] & 0xff}] [sym find type CompChildOptions]] [expr {[read-reg bp] >> 8}]]

    return 0
}]

#
#	-f : FLOW GRABS
#

[defsubr	print-fgm {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowGrabMouse, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-ffgm {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowForceGrabMouse, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-frm {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowReleaseMouse, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-fgk {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowGrabKbd, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-ffgk {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowForceGrabKbd, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-frk {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowReleaseKbd, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-abpp {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowAddButtonPrePassive, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-rbpp {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowRemoveButtonPrePassive, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-abop {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowAddButtonPostPassive, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-rbop {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowRemoveButtonPostPassive, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-akpp {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowAddKbdPrePassive, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-rkpp {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowRemoveKbdPrePassive, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]

[defsubr	print-akop {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowAddKbdPostPassive, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 
}]

[defsubr	print-rkop {} {
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {FlowRemoveKbdPostPassive, ^l%04x:%04x, %s}
			[read-reg cx] [read-reg dx] [name-root $sn]]
    return 0
}]



[defsubr	print-gw {} {
    echo [format {FlowGrabWindow, ^h%04x} [read-reg di]]
    return 0
}]

[defsubr	print-rw {} {
    echo [format {FlowReleaseWindow, ^h%04x} [read-reg di]]
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
    echo [format {WinMouseGrab, ^h%04x} [read-reg di]]
    return 0
}]

[defsubr	print-wmr {} {
    echo [format {WinMouseRelease, ^h%04x} [read-reg di]]
    return 0
}]

[defsubr	print-wbe {} {
    echo [format {WinBranchExclude, ^h%04x} [read-reg di]]
    return 0
}]

[defsubr	print-wbi {} {
    echo [format {WinBranchInclude, ^h%04x} [read-reg di]]
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
    echo -n [format {%*sVisNavigateCommon, ^l%04x:%04x, %s, }
		[expr $navIndent*2] {} [value fetch ds:LMBH_handle]
		[read-reg si] [name-root $sn]]
    pvm *ds:si 1
    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {%*s  originator = ^l%04x:%04x, %s}
		[expr $navIndent*2] {} [read-reg cx] [read-reg dx] [name-root $sn]]

    echo -n [format {%*s  NavigateFlags =}
		[expr $navIndent*2] {}]
    precord NavigateFlags bp 1

    echo -n [format {%*s  NavigateCommonFlags =}
		[expr $navIndent*2] {}]
    precord NavigateCommonFlags bl 1
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

    echo [format {%*s  REACHED PREVIOUS FOCUSABLE NODE. Returning...}
		[expr $navIndent*2] {}]
    return 0
}]

[defsubr	print-navreturnOD {} {
    global navIndent

    var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
    echo [format {%*s  RETURNING OD = ^l%04x:%04x, %s}
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
    [flow-print-obj-and-requestor {FlowForceGrab} {requested by}]
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

[defsubr	print-releasegrab {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj-and-requestor {FlowReleaseGrab} {requested by}]
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

[defsubr	print-requestgrab {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj-and-requestor {FlowRequestGrab} {requested by}]
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

# INFO for SendMethodIfMisMatch utility routine.

[defsubr	print-fsm {} {
    global exclIndent

    if {[read-reg bx]} {
	var sn [sym fullname [sym faddr var *(^lbx:si).MB_class]]
	var en [map-method [read-reg ax] $sn ^lbx:si]
	echo [format {%*ssending: %s to: ^l%04x:%04x, %s}
		[expr $exclIndent*4-2] {} $en [read-reg bx] [read-reg si]
		[name-root $sn]]
    }
    return 0
}]

# GAINED and LOST utility routines

[defsubr	print-gainedexcl {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj {FlowGainedExcl}]
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

[defsubr	print-lostexcl {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj {FlowLostExcl}]
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
    echo [format {%*s%s: using %s, at: ^l%04x:%04x, %s}
		[expr $exclIndent*4] {} $text $name
		[value fetch ds:LMBH_handle] [read-reg si] [name-root $sn]]
    return 0
}]

# GRAB/RELEASE WITHIN LEVEL utility routines

[defsubr	print-grabwithinlevel {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj-and-requestor {FlowGrabWithinLevel} {FAKING a request by}]
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

[defsubr	print-releasewithinlevel {} {
    global exclIndent
    [begin-excl-draw-line]
    [flow-print-obj-and-requestor {FlowReleaseWithinLevel} {FAKING a request by}]
    var exclIndent [expr {$exclIndent + 1}]
    return 0
}]

# SUB-PROCEDURES USED ABOVE:

[defsubr	begin-excl-draw-line {} {
    global exclIndent
    if {$exclIndent==0} {
    	echo {Beginning call to exclusive grab utility----------------------------}
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
    	echo {Ending call to exclusive grab utility-------------------------------}
	echo
    } else {
	echo [format {%*s%.*s} [expr $exclIndent*4] {} [expr 68-($exclIndent*4)]
	{--------------------------------------------------------------------}]
    }
    return 0
}]

# subroutine used above

[defsubr	flow-print-obj-and-requestor {text requesttext} {
    global exclIndent
    # use *ds:si, bx, and di to get the name of the field,
    # "OLFI_applExcl" for example.

    var sn [sym fullname [sym faddr var *(*ds:si).MB_class]]
    var name [get-instance-field-name *ds:si]
    echo [format {%*s%s:} [expr $exclIndent*4] {} $text]
    echo [format {%*s  using %s structure in: ^l%04x:%04x, %s}
		[expr $exclIndent*4] {} $name
		[value fetch ds:LMBH_handle] [read-reg si] [name-root $sn]]

    var offset [value fetch ds:si [type word]]
    var part [value fetch ds:($offset+bx) [type word]]
    var data [value fetch ds:($offset+$part+di) [type word]]

    echo [format {%*s  HG_data = %04x, bp = %04x} [expr $exclIndent*4] {}
		$data [read-reg bp]]

#    echo -n [format {%*s  HG_flags = } [expr $exclIndent*2] {}]
#    precord HierarchicalGrabFlags $data 1
#    echo -n [format {%*s  bp = } [expr $exclIndent*2] {}]
#    precord HierarchicalGrabFlags bp 1

    if {[read-reg cx]} {
	var sn [sym fullname [sym faddr var *(^lcx:dx).MB_class]]
	echo [format {%*s  %s: ^l%04x:%04x, %s, bp=%04x}
		[expr $exclIndent*4] {} $requesttext
		[read-reg cx] [read-reg dx] [name-root $sn] [read-reg bp]]
    } else {
	echo [format {%*s  RESETTING exclusive grab to nil.}
		[expr $exclIndent*4] {}]
    }
}]

# subroutine used by GAINED and LOST functions

[defsubr	flow-print-obj {text} {
    global exclIndent
    # use *ds:si, bx, and di to get the name of the field,
    # "OLFI_applExcl" for example.
    var sn [sym fullname [sym faddr var *(*ds:si).MB_class]]
    var name [get-instance-field-name *ds:si]
    echo [format {%*s%s: using %s, at: ^l%04x:%04x, %s}
		[expr $exclIndent*4] {} $text $name
		[value fetch ds:LMBH_handle] [read-reg si] [name-root $sn]]
    return 0
}]

#
#	-t : transfer routines
#

[defsubr	print-transfer-register {} {
    if {[read-reg bp]} {
	echo [format {Registering QUICK transfer item at %04x:%04x}
		[read-reg bx] [read-reg ax]]
    } else {
	echo [format {Registering NORMAL transfer item at %04x:%04x}
		[read-reg bx] [read-reg ax]]
    }
    return 0
}]

[defsubr	print-transfer-unregister {} {
    echo [format {Unregistering item owned by ^l%04x:%04x}
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
    echo [format {	...returning %x items owned by ^l%04x:%04x in header at %04x:%04x}
	    [read-reg bp]
	    [read-reg cx] [read-reg dx]
	    [read-reg bx] [read-reg ax]]
    return 0
}]

[defsubr	print-transfer-request {} {
    echo [format {Requesting %s format from header at %04x:%04x}
	    [prenum ui::TransferItemFormats [read-reg cx]]
	    [read-reg bx] [read-reg ax]]
    finishframe [frame top]
    echo [format {	...returning transfer item at at %04x:%04x}
	    [read-reg bx] [read-reg ax]]
    return 0
}]

[defsubr	print-transfer-done {} {
    if {[read-reg cx]} {
	echo [format {Done with QUICK transfer item at %04x:%04x}
		[read-reg bx] [read-reg ax]]
    } else {
	echo [format {Done with NORMAL transfer header at %04x:%04x}
		[read-reg bx] [read-reg ax]]
    }
    return 0
}]

[defsubr	print-transfer-addn {} {
    echo [format {Adding ^l%04x:%04x to transfer notification list}
		[read-reg cx] [read-reg dx]]
    return 0
}]

[defsubr	print-transfer-remn {} {
    echo [format {Removing ^l%04x:%04x from transfer notification list}
		[read-reg cx] [read-reg dx]]
    return 0
}]

[defsubr	print-transfer-free {} {
    echo [format {Freeing transfer item at %04x:%04x}
		[read-reg bx] [read-reg ax]]
    return 0
}]

[defsubr	print-transfer-save {} {
    echo [format {Saving transfer item at %04x:%04x in free list}
		[read-reg bx] [read-reg ax]]
    return 0
}]

[defsubr	print-transfer-sendn {} {
    echo Sending notification to...
    return 0
}]

[defsubr	print-transfer-sendnlow {} {
    echo [format {	...%04x:%04x}
		[read-reg bx] [read-reg si]]
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
	echo [format {Module call to %s} [sym fullname $s]]
    }
    return 0
}]

[defsubr	print-rlcc {} {
    var s [sym faddr proc ^hbx:[value fetch ss:TPD_callVector [type word]]]
    if {[null $s]} {
	echo [format {Int call to ^h%04xh:%04xh} [read-reg bx]
				[value fetch ss:TPD_callVector [type word]]]
    } else {
	echo [format {Int call to %s} [sym fullname $s]]
    }
    return 0
}]
