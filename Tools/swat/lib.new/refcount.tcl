##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	refcount.tcl
# AUTHOR: 	Eric Weber, Feb  4, 1996
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	EW	2/ 4/96   	Initial Revision
#
# DESCRIPTION:
#
#	Observe reference count changes in a single patient, and who
#       is making them.
#
#	$Id: refcount.tcl,v 1.1.6.1 97/03/29 11:27:32 canavese Exp $
#
###############################################################################

#
# WISH LIST:
#    * ability to monitor multiple patients
#    * ability to dynamicly set and remove the breakpoints
#

defvar refcount-patient foo
defvar frame-ignore-list {geos ui}

[defsubr is-frame-interesting {f}
 {
     global frame-ignore-list

     [case [patient name [frame patient $f]] in
      ${frame-ignore-list} {return 0}
      default {return 1}
     ]
 }
]

[defsubr show-interesting-frame {}
 {
     # find the first nonignored frame
     [for {var f [frame top]} 
      {!([null $f] || [is-frame-interesting $f])}
      {var f [frame next $f]}
      {}
     ]
 
     # if one exists, display info about it, in backtrace format
     if {![null $f]} {
	 #if know source info for frame, use that, else use cs:ip
	 if {([catch {src line [frame register pc $f]} fileLine] == 0) 
	     && ![null $fileLine]} {
		 var fileline [src line [frame register pc $f]]
		 echo [format {called from %s, %s:%d}
		       [frame function $f]
		       [file tail [index $fileLine 0]]
		       [index $fileLine 1]]
	     } else {
		 echo [format {called from %s, %s}
		       [frame function $f]
		       [frame register pc $f]]
	     }
     }
 }
]	 

#
# display current refcount, where it is being changed, and the most 
# recent interesting routine on the stack
#
[defsubr show-refcount {verb rname}
 {
     global {refcount-patient}

     var core_owner [patient name 
		     [handle patient [handle lookup [frame reg $rname]]]]

     if {$core_owner == ${refcount-patient}} {
	 echo [format {%s in %s:%d %s from %d}
	       [frame function]
	       [patient name]
	       [index [patient data] 2]
	       [var verb]
	       [value fetch ^h${rname}:GH_geodeRefCount]
	      ]
	 show-interesting-frame
     }
     return 0
 }
]

alias set-refcount-brk {
    brk UseLibraryLow::inMemory {show-refcount increments bx}
    brk CreateThreadCommon::createSem {show-refcount increments bp}
    brk GeodeAddReference {show-refcount increments bx}
    brk FreeGeodeLow {show-refcount decrements bx}
}



