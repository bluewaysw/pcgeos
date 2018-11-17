COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GenDList (Sample PC GEOS application)
FILE:		gendlist.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/90		Initial version
	Eric	 3/91		Simplified by removing text color changes.

DESCRIPTION:
	This file source code for the GenDList application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT:
	This example is written for the PC/GEOS V1.0 API. For the V2.0 API,
	we have new ObjectAssembly and Object-C versions.

RCS STAMP:
	$Id: gendlist.asm,v 1.1 97/04/04 16:34:22 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

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

UseLib ui.def

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;Here we define "GenDListProcessClass" as a subclass of the system provided
;"GenProcessClass". As this application is launched, an instance of this class
;will be created, and will handle all application-related events (messages).
;The application thread will be responsible for running this object,
;meaning that whenever this object handles a method, we will be executing
;in the application thread.

GenDListProcessClass	class	GenProcessClass

MSG_OPTR_LIST_MONIKER_QUERY		message
;
; Queries destination for the moniker for the given item.
;
; Pass:		^lcx:dx -- list
;		bp -- item
; Return:	nothing
;

MSG_OPTR_LIST_APPLY			message
;
; Sent to the destination when a user change is applied to the list.
;
; Pass:		cx -- selection
;		bp -- num selections
;		dl -- GenItemGroupState
;

GenDListProcessClass	endc	;end of class definition

;This class definition must be stored in memory at runtime, so that
;the PC/GEOS messaging system can examine it. We will place it in this
;application's idata (initialized data) area, which is part of
;the "DGroup" resource.

idata	segment
	GenDListProcessClass	mask CLASSF_NEVER_SAVED
				;this flag necessary because ProcessClass
				;objects are hybrid objects.
idata	ends


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
;The "gendlist.ui" file, which contains user-interface descriptions for this
;application, is written in a language called Espire. That file gets compiled
;by UIC, and the resulting assembly statements are written into the
;gendlist.rdef file. We include that file here, so that these descriptions
;can be assembled into our application.
;
;Precisely, we are assembling .byte and .word statements which comprise the
;exact instance data for each generic object in the .ui file. When this
;application is launched, these resources (such as MenuResource) will be loaded
;into the Global Heap. The objects in the resource can very quickly become
;usable, as they are pre-instantiated.

include		gendlist.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for GenDListProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	MSG_META_EXPOSED handler.

DESCRIPTION:	This method is sent by the Windowing System when we must
		redraw a portion of the document in the View area.

PASS:		ds	= dgroup
		cx	= handle of window which we must draw to.

RETURN:		ds	= same

CAN DESTROY:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/90		initial version

------------------------------------------------------------------------------@

GenDListExposed	method	GenDListProcessClass, MSG_META_EXPOSED

	mov	di, cx			;set ^hdi = window handle
	call	GrCreateState		;Get a default graphics state that we
					;can use while drawing.

	;first, start a window update. This tells the windowing system that
	;we are in the process of drawing to this window.

	call	GrBeginUpdate

	;now free the GState, and indicate that we are done drawing to the
	;window.

	call	GrEndUpdate
	call	GrDestroyState

	ret

GenDListExposed	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenDListProcessMonikerQuery -- 
		MSG_OPTR_LIST_MONIKER_QUERY for GenDListProcessClass

DESCRIPTION:	Returns moniker for the optr list.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OPTR_LIST_MONIKER_QUERY

		^lcx:dx - list
		bp	- item

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/17/92		Initial Version

------------------------------------------------------------------------------@

GenDListProcessMonikerQuery	method dynamic	GenDListProcessClass, \
				MSG_OPTR_LIST_MONIKER_QUERY

        GetResourceHandleNS	BlackText, bx	
	call	MemLock
	push	bx				;save text block

	movdw	bxsi, cxdx			;^lbx:si <- list

	pop	cx				;get ^lcx:dx -- item moniker
	push	cx				;
	mov	dx, bp				;item offset in dx
	shl	dx, 1				;double item for chunk offset
	add	dx, offset BlackText		;add to black text offset
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR
	call	ObjMessageCall
	pop	bx				;restore text block handle
	call	MemUnlock
	ret
GenDListProcessMonikerQuery	endm

ObjMessageCall	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
ObjMessageCall	endp




COMMENT @----------------------------------------------------------------------

METHOD:		GenDListProcessApply -- 
		MSG_OPTR_LIST_APPLY for GenDListClass

DESCRIPTION:	Handles an apply from the optr dynamic list.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OPTR_LIST_APPLY
		cx	- new color

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/17/92		Initial Version

------------------------------------------------------------------------------@

GenDListProcessApply method dynamic GenDListProcessClass, MSG_OPTR_LIST_APPLY
	clr	dx		;no GB values
        GetResourceHandleNS	GenDListView, bx	
	mov	si, offset GenDListView
	mov	ax, MSG_GEN_VIEW_SET_COLOR
	call	ObjMessageCall
	ret
GenDListProcessApply	endm

CommonCode	ends		;end of CommonCode resource
