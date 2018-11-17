COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992, 1991, 1990 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		SubUI
FILE:		subui.asm

AUTHOR:		Eric E. Del Sesto, June 10, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EDS	6/10/91		Initial revision.
	mav	1/14/92		ported to V2.0

DESCRIPTION:
	This application demonstrates how to subclass a Generic User Interface
	class, in order to change its behavior slightly.

	This file contains source code for the SubUI application. This code
	will be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: subui.asm,v 1.1 97/04/04 16:32:51 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------
;some of the include files contain conditional assembly, to (for example)
;prevent application code from calling certain system routines.

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def

include object.def
include graphics.def
include Objects/winC.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------
UseLib	ui.def


;------------------------------------------------------------------------------
;			SubUIGenProcessClass Definitions
;------------------------------------------------------------------------------
;Here we define "SubUIGenProcessClass" as a subclass of the system provided
;"GenProcessClass". As this application is launched, an instance of this class
;will be created, and will handle all application-related events (messages).
;The application thread will be responsible for running this object,
;meaning that whenever this object handles a method, we will be executing
;in the application thread.

SubUIGenProcessClass	class	GenProcessClass

;define messages for this class here.

SubUIGenProcessClass	endc	;end of class definition

;This class definition must be stored in memory at runtime, so that
;the PC/GEOS messaging system can examine it. We will place it in this
;application's idata (initialized data) area, which is part of
;the "DGroup" resource.


;------------------------------------------------------------------------------
;			MyTriggerClass Definitions
;------------------------------------------------------------------------------

;Here we define MyTriggerClass, for the sake of the ESP assembler.
;This is necessary so that ESP can create a class definition structure for
;this class in our "idata" segment (see below). This will also define
;"MT_altMoniker" as a field within the structure that is the instance
;data for MyTriggerClass objects. When you go to access the instance data
;for one of these objects (which sits inside a chunk inside an ObjectBlock),
;you will need the offset of this field to change its value.
;
;NOTE: in cases where you specify a class definition in both ESP and UIC,
;be sure that the definitions match, or your pre-instantiated objects
;that you list in your .ui file will not be built correctly.
;
;You will also probably note that we defined the single instance data field
;as "altMoniker" for UIC, but we define it as "MT_altMoniker"
;for ESP. This is just a naming convention that we use. For V2.0, UIC and
;ESP will be merged, and you will only have one definition of the class anyway.

MyTriggerClass	class	GenTriggerClass

;messages defined for this class

    MSG_MY_TRIGGER_ACTIVATE			message

    ;This message is sent by this object to itself, when the user clicks
    ;on this trigger on the screen. Remember, MyTriggerClass inherits all
    ;of the behavior of GenTriggerClass, including the code which sends out
    ;a message when the user clicks on the trigger. In our .ui file,
    ;we have defined that for each instance of MyTriggerClass, the message
    ;to send is MSG_MY_TRIGGER_ACTIVATE, and the destination is that
    ;same object.

;instance data for this class

    MT_altMoniker	lptr	;an "lptr" is basically a word value which
				;contains a chunk handle. Defining the instance
				;data in this manner allows swat to print the
				;object instance data out right.


MyTriggerClass	endc


;------------------------------------------------------------------------------
;			DGroup: idata and udata definitions
;------------------------------------------------------------------------------

;Now we place all of our initialized variables in the DGroup resource.
;The first data that we place into the idata section are the actual
;class definition structures that we defined above.

idata	segment

	SubUIGenProcessClass	mask CLASSF_NEVER_SAVED
				;this flag necessary because ProcessClass
				;objects are hybrid objects, which are
				;not part of the UI, and never saved
				;to the state file.

	MyTriggerClass

;Note that we are not listing any method tables here. We are using the
;shorthand method, where you actually make the association between a message
;and the routine which handles it at the definition of the routine itself.

idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
;The "subui.ui" file, which contains user-interface descriptions for this
;application, is written in a language called Espire. That file gets compiled
;by UIC, and the resulting assembly statements are written into the
;subui.rdef file. We include that file here, so that these descriptions
;can be assembled into our application.
;
;Precisely, we are assembling .byte and .word statements which comprise the
;exact instance data for each generic object in the .ui file. When this
;application is launched, these resources (such as MenuResource) will be loaded
;into the Global Heap. The objects in the resource can very quickly become
;usable, as they are pre-instantiated.

include		subui.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for SubUIGenProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource	;start of code resource

;we don't have any code (methods) for SubUIGenProcessClass.

CommonCode	ends			;end of code resource

;------------------------------------------------------------------------------
;		Code for MyTriggerClass
;------------------------------------------------------------------------------

UICommonCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	MSG_MY_TRIGGER_ACTIVATE handler.

DESCRIPTION:	This method is sent from this object to itself when the
		user presses it with the mouse. If we did not intercept
		it here, the generic and specific UI (which are the
		superclasses of this class) would send out the
		Action Descriptor for this GenTrigger.

PASS:		*ds:si	= instance data for a MyTriggerClass object,
			  which is stored in the chunk inside
			  an "ObjectBlock" -- basically a local memory
			  heap which contains objects. DS is the segment
			  value for the block on the global heap,
			  which has been temporarily locked by the kernel,
			  before this routine is run. SI is the local memory
			  handle for the chunk which contains the instance
			  data for the object which received the
			  MSG_MY_TRIGGER_ACTIVATE message.

		es	= segment of this application's DGroup. This is passed
			  so that we can refer to this object's class
			  definition, which lies in the "idata" portion
			  of DGroup.

		cx, dx, bp = data passed with this message (if any)

RETURN:		*ds:si	= same
		es	= same

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
	call superclass for default behavior
	swap moniker pointers
	mark the ObjectBlock containing this object as "dirty" so that
		it will be saved to a state file if we shutdown.
	force this object to redraw

KNOWN BUGS:
	If the second moniker is a longer string than the first, the text
	will draw outside of the button. This is because the specific UI
	most likely determines the width of the button based on the width
	of the first moniker. We could intercept some of the geometry
	determination messages at this class level, and return the width
	of the longest moniker, but that might conflict with the
	requirements of the specific UI.

	In general, MyTriggerClass is a stupid example, because it
	violates some basic stylistic principles in specific UIs like Motif.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/91		initial version
------------------------------------------------------------------------------@


MyTriggerActivate	method	MyTriggerClass, MSG_MY_TRIGGER_ACTIVATE
					;this is shorthand for defining
					;a procedure, AND specifying that
					;it should be listed in the method
					;table as a handler
					;for MSG_MY_TRIGGER_ACTIVATE.

	;Very often, we need to pass this message up the class hierarchy,
	;in case any of our superclasses have handlers for this message.
	;
	;(In this particular case, we have defined this message at this
	;class level, so no superclass could possibly care about it.)

	mov	di, offset MyTriggerClass
					;set es:di = class definition, so that
					;ObjCallSuperNoLock can determine the
					;superclass of this class.

	call	ObjCallSuperNoLock	;pass the message onto the kernel's
					;messaging system, so that it can
					;be forwarded up the class hierarchy.
					;The "NoLock" suffix means we are
					;taking advantage of the fact that
					;we know this ObjectBlock is already
					;locked.

	;Note that we don't care what was passed in the CX, DX, or BP registers
	;to this method. We also don't care what the superclass handler
	;returned in these registers. If we did, we would push/pop the
	;registers.


	;now perform our special functionality: switch the moniker pointers,
	;and force this trigger to redraw itself.
	;regs:	*ds:si = instance data chunk for this object

	mov	di, ds:[si]		;set ds:di = object instance data chunk
					;(Note that the chunk contains both
					;"Vis" data and "Generic" data.)

	add	di, ds:[di].Gen_offset	;set ds:di = "Generic" portion of
					;that instance data, which is where
					;our extra instance data has been
					;appended.

	mov	ax, ds:[di].MT_altMoniker
					;set *ax = alternate moniker chunk
					;(see the top of this file for the
					;definition of this field in
					;MyTriggerClass.)

	mov	bx, ds:[di].GI_visMoniker
					;set *bx = alternate moniker chunk
					;(see ui.def for the definition of
					;this field in GenClass).

	mov	ds:[di].GI_visMoniker, ax
	mov	ds:[di].MT_altMoniker, bx
					;swap the values in these two fields.

	;mark the ObjectBlock containing this object as "dirty" so that
	;it will be saved to a state file if we shutdown.
	;regs:	*ds:si = instance data chunk for this object

	call	ObjMarkDirty

	;now force this object to redraw.
	;regs:	*ds:si = instance data chunk for this object
	;	es     = segment of DGroup

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock	;send this message to this object,
					;taking advantage of the fact that
					;this ObjectBlock is already locked,
					;and bypassing the UI queue,
					;so that this message is delivered
					;and handled synchronously.
	ret
MyTriggerActivate	endp

UICommonCode	ends			;end of code resource
