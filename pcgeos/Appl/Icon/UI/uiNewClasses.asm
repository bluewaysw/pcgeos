COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Icon	
MODULE:		UI
FILE:		uiNewClasses.asm

AUTHOR:		Steve Yegge, Sep  1, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/ 1/92		Initial revision


DESCRIPTION:
	
	This file contains handlers and helper routines for any and
	all classes subclassed off generic classes to make the 
	program run smoothly.  As of now this includes:

		AddIconInteractionClass -- sets glyphs in the add dialog
		SmartTextClass -- enables & disables 'apply' trigger		

	These classes are both part of the Add-Icon dialog.

	$Id: uiNewClasses.asm,v 1.1 97/04/04 16:06:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddDialogResource	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmartTextEmptyStatusChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	enables or disables the "OK" trigger

CALLED BY:	MSG_META_TEXT_EMPTY_STATUS_CHANGED

PASS:		cx:dx = object
		*ds:si = instance data
		ds:di = instance data
		bp = zero if text is becoming empty, nonzero otherwise

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- enable the ok trigger, or disable it.	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmartTextEmptyStatusChanged	method dynamic SmartTextClass, 
					MSG_META_TEXT_EMPTY_STATUS_CHANGED
		uses	ax, cx, dx, bp
		.enter
	;
	;  call the superclass
	;
		push	bp
		mov	di, offset SmartTextClass
		call	ObjCallSuperNoLock
		pop	bp
	;
	;  Let the database viewer know the text has been modified.
	;
		push	si
		mov	bx, segment	GenDocumentClass
		mov	si, offset	GenDocumentClass
		mov	di, mask MF_RECORD
		mov	ax, MSG_DB_VIEWER_ADD_DIALOG_TEXT_MODIFIED
		call	ObjMessage
		pop	si
		
		mov	cx, di
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		mov	dx, TO_APP_MODEL
		call	ObjCallInstanceNoLock
		
		.leave
		ret
SmartTextEmptyStatusChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatViewInteractionPopOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	allows format view to get big, when popped out.

CALLED BY:	MSG_GEN_INTERACTION_POP_OUT

PASS:		*ds:si	= FormatViewInteractionClass object
		ds:di	= FormatViewInteractionClass instance data
		ds:bx	= FormatViewInteractionClass object (same as *ds:si)
		es	= segment of FormatViewInteractionClass

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- get the view to resize correctly
	- add expand-to-fit-parent to self
	- update the options menu to reflect the state of the popout

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatViewInteractionPopOut	method dynamic FormatViewInteractionClass, 
				MSG_GEN_INTERACTION_POP_OUT
	;
	;  Call the superclass
	;
		mov	di, offset	FormatViewInteractionClass
		call	ObjCallSuperNoLock
	;
	;  Nuke the no-taller & no-wider hints
	;
		mov	ax, MSG_GEN_REMOVE_GEOMETRY_HINT
		mov	cx, HINT_NO_TALLER_THAN_CHILDREN_REQUIRE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		
		mov	ax, MSG_GEN_REMOVE_GEOMETRY_HINT
		mov	cx, HINT_NO_WIDER_THAN_CHILDREN_REQUIRE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
	;
	;  Tell ourselves to expand-to-fit-parent
	;
		mov	ax, MSG_GEN_ADD_GEOMETRY_HINT
		mov	cx, HINT_EXPAND_WIDTH_TO_FIT_PARENT
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		
		mov	ax, MSG_GEN_ADD_GEOMETRY_HINT
		mov	cx, HINT_EXPAND_HEIGHT_TO_FIT_PARENT
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
	;
	;  Tell the view to reset to its initial size
	;
		mov	si, offset FormatViewGroup	
		mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
	;
	;  Make sure that the change is reflected on the Format menu.
	;
		mov	si, offset FormatBooleanGroup
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
		mov	cx, mask FO_FLOATING_FORMATS
		mov	dx, 1					; TRUE
		call	ObjCallInstanceNoLock
		
		ret
FormatViewInteractionPopOut	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatViewInteractionPopIn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets a fixed-size on the format view, etc etc

CALLED BY:	MSG_GEN_INTERACTION_POP_IN

PASS:		*ds:si	= FormatViewInteractionClass object
		ds:di	= FormatViewInteractionClass instance data
		es 	= segment of FormatViewInteractionClass

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- call the superclass
	- get rid of our expand-height-to-fit hint (keep the width one)
	- give the view a fixed-size hint for the height
	- notify the options menu of the change

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatViewInteractionPopIn	method dynamic FormatViewInteractionClass, 
					MSG_GEN_INTERACTION_POP_IN
		.enter
	;
	;  call the superclass
	;
		mov	di, offset FormatViewInteractionClass
		call	ObjCallSuperNoLock
	;
	;  Remove the expand-height geometry hint from the 
	;
		mov	ax, MSG_GEN_REMOVE_GEOMETRY_HINT
		mov	cx, HINT_EXPAND_HEIGHT_TO_FIT_PARENT
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
	;
	;  Tell the format view to reset to initial size.
	;
		mov	si, offset FormatView
		mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
	;
	;  Make sure the change is reflected in the Format menu.
	;
		mov	si, offset FormatBooleanGroup
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
		mov	cx, mask FO_FLOATING_FORMATS
		clr	dx				; FALSE
		call	ObjCallInstanceNoLock

		.leave
		ret
FormatViewInteractionPopIn	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopImportTriggerSendAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the continueImporting global variable to false

CALLED BY:	MSG_GEN_TRIGGER_SEND_ACTION

PASS:		es = dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp (by superclass)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopImportTriggerSendAction	method dynamic StopImportTriggerClass, 
					MSG_GEN_TRIGGER_SEND_ACTION
		.enter
	;
	;  Call the superclass
	;
		mov	di, offset	StopImportTriggerClass
		call	ObjCallSuperNoLock
	;
	;  Set the variable
	;
		clr	es:[continueImporting]

		.leave
		ret
StopImportTriggerSendAction	endm


AddDialogResource	ends
