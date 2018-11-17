COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GenItemGroup (Sample PC GEOS application)
FILE:		genitemgroup.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/90		Initial version
	Eric	 3/91		Simplified by removing text color changes.

DESCRIPTION:
	This file source code for the GenItemGroup application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT:
	This example is written for the PC/GEOS V1.0 API. For the V2.0 API,
	we have new ObjectAssembly and Object-C versions.

RCS STAMP:
	$Id: genitemgroup.asm,v 1.1 97/04/04 16:34:23 newdeal Exp $

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

;Here we define "GenItemGroupProcessClass" as a subclass of the system provided
;"GenProcessClass". As this application is launched, an instance of this class
;will be created, and will handle all application-related events (messages).
;The application thread will be responsible for running this object,
;meaning that whenever this object handles a method, we will be executing
;in the application thread.

GenItemGroupProcessClass	class	GenProcessClass


MSG_SELECTION_STATUS		message
; Handles any change to the selection object.  The selection object basically
; is a poor man's way of selecting the sample text.  We'll use the status
; message to notify us of any user change to the selection group.  Any time
; we receive the message, we'll recalculate the correct attributes to set
; for the selection.
; 
; Pass:		cx -- selected item (if there is one selection)
;		bp -- num selections
; Return:	nothing
;		ax, cx, dx, bp -- destroyed

MSG_COLOR_APPLY			message
;
; Handles an apply of the color group, to set a new color for the current
; selection.
;
; Pass:		cx -- selection
; Return:	nothing
;		ax, cx, dx, bp -- destroyed
;

MSG_COLOR_STATUS		message
; 
; Sent on any user change to the color group.  Used to adjust the RGB group
; to match the color group.
;
; Pass:		cx -- selection
; Return:	nothing
;		ax, cx, dx, bp -- destroyed 
;

MSG_RGB_APPLY			message
;
; Handles an apply of the RGB group.  We'll make changes to the selection
; for those RGB elements that are marked as modified.
;
; Pass:		cx -- selected booleans
;		bp -- modified booleans
; Return:	nothing
;		ax, cx, dx, bp -- destroyed
;

MSG_RGB_STATUS			message
; 
; Sent on any user change to the RGB group.  Used to adjust the color group
; to match the RGB group.  
;
; Pass:		cx -- selected booleans
;		bp -- changed booleans
; Return:	nothing
;		ax, cx, dx, bp -- destroyed 
;

MAX_SELECTIONS	equ	4   	;Number of selections in our sample text
NUM_COLOR_BITS	equ	3	;RGB bits

SelectionItem	etype	byte
	SELECTION_THIS	enum SelectionItem
	SELECTION_IS	enum SelectionItem
	SELECTION_A	enum SelectionItem
	SELECTION_TEST	enum SelectionItem

GenItemGroupProcessClass	endc	;end of class definition

;This class definition must be stored in memory at runtime, so that
;the PC/GEOS messaging system can examine it. We will place it in this
;application's idata (initialized data) area, which is part of
;the "DGroup" resource.

idata	segment
	GenItemGroupProcessClass	mask CLASSF_NEVER_SAVED
				;this flag necessary because ProcessClass
				;objects are hybrid objects.

textColor		word	MAX_SELECTIONS dup (C_VIOLET)
	;The current colors for each possible selection in the text.

curTextSelections	word	MAX_SELECTIONS dup (0)
	;Parts of text that are selected

numTextSelections	word
	;The number of parts that are selected.

idata	ends


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
;The "genitemgroup.ui" file, which contains user-interface descriptions for this
;application, is written in a language called Espire. That file gets compiled
;by UIC, and the resulting assembly statements are written into the
;genitemgroup.rdef file. We include that file here, so that these descriptions
;can be assembled into our application.
;
;Precisely, we are assembling .byte and .word statements which comprise the
;exact instance data for each generic object in the .ui file. When this
;application is launched, these resources (such as MenuResource) will be loaded
;into the Global Heap. The objects in the resource can very quickly become
;usable, as they are pre-instantiated.

include		genitemgroup.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for GenItemGroupProcessClass
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

GenItemGroupExposed	method	GenItemGroupProcessClass, MSG_META_EXPOSED

	mov	di, cx			;set ^hdi = window handle
	call	GrCreateState		;Get a default graphics state that we
					;can use while drawing.

	;first, start a window update. This tells the windowing system that
	;we are in the process of drawing to this window.

	call	GrBeginUpdate

	;if we had background graphics to draw, we would call the
	;apropriate graphics routines now.

	;draw the text into the window (pass ^hdi = GState)

	mov	cx, FID_DTC_URW_ROMAN		;font (URW Roman)
	mov	dx, 48				;point size (integer)
	clr	ah				;point size (fraction) = 0
	call	GrSetFont

	mov	ax, ds:textColor
	call	GrSetTextColor

	mov	ax, 30				;position
	mov	bx, 100
	clr	cx				;null termed
	push	ds
	segmov	ds, cs				;ds:si <- text
	mov	si, offset thisText
	call	GrDrawText
	pop	ds

	mov	ax, ds:textColor[1*(size word)]
	call	GrSetTextColor

	clr	cx				;null termed
	push	ds
	segmov	ds, cs				;ds:si <- text
	mov	si, offset isText
	call	GrDrawTextAtCP
	pop	ds

	mov	ax, ds:textColor[2*(size word)]
	call	GrSetTextColor

	clr	cx				;null termed
	push	ds
	segmov	ds, cs				;ds:si <- text
	mov	si, offset aText
	call	GrDrawTextAtCP
	pop	ds

	mov	ax, ds:textColor[3*(size word)]
	call	GrSetTextColor

	clr	cx				;null termed
	push	ds
	segmov	ds, cs				;ds:si <- text
	mov	si, offset testText
	call	GrDrawTextAtCP
	pop	ds

	;now free the GState, and indicate that we are done drawing to the
	;window.

	call	GrEndUpdate
	call	GrDestroyState
	ret

GenItemGroupExposed	endm

thisText	byte	"This ",0
isText		byte	"is ",0
aText		byte	"a ",0
testText	byte	"test ",0





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupProcessSelectionStatus -- 
		MSG_SELECTION_STATUS for GenItemGroupProcessClass

DESCRIPTION:	Handles a user change of the selection object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SELECTION_STATUS
		cx	- selection
		bp	- numSelections
		dl	- GenItemGroupStateFlags	

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

GenItemGroupProcessSelectionStatus method dynamic GenItemGroupProcessClass, \
				MSG_SELECTION_STATUS

	;
	; Get the current selections.  (If there are multiple selections, we
	; have to get them by passing a pointer to a buffer.)
	;
	mov	ds:numTextSelections, bp
	mov	ds:curTextSelections[0], cx	;assume one selection

	cmp	bp, 1				;only one selection?
	jbe	gotSelections

	push	bp
	mov	cx, ds
	mov	dx, offset curTextSelections
	mov	bp, MAX_SELECTIONS
	mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
        GetResourceHandleNS	SelectionGroup, bx	
	mov	si, offset SelectionGroup
	call	ObjMessageCall
	pop	bp

gotSelections:
	mov	ax, MSG_GEN_SET_ENABLED		;assume enabling gadgets
	tst	bp				;selections?
	jnz	enableGadgets			;yes, branch
	mov	ax, MSG_GEN_SET_NOT_ENABLED	;else we'll disable them
enableGadgets:

	;
	; Disable various UI gadgets that pertain to a selection.
	;
	push	bp
	mov	dl, VUM_NOW
        GetResourceHandleNS	ColorsGroup, bx	
	mov	si, offset ColorsGroup
	push	ax, dx
	call	ObjMessageCall
	pop	ax, dx
	
	mov	si, offset RGBGroup
	call	ObjMessageCall
	pop	bp

	tst	bp				;any selections?
	jz	exit				;no, exit

	;
        ; Set the proper state for the various UI gadgets.  We'll get the color
        ; of the first selection, and keep track of which color bits are 
        ; indeterminate, by comparing them to the first selection's state. (The 
        ; individual bits' indeterminate states are needed for the RGB group.)
	;
	clr	dx				;assume no indeterminates
	mov	di, ds:curTextSelections[0]	;get first text selection
	shl	di, 1				;double for word offset
	mov	cx, ds:textColor[di]		;get color of first selection
	mov	bx, 1				;start at second text selection

calcIndeterminate:
	cmp	bx, ds:numTextSelections	;see if done
	jae	indeterminateCalced		;yes, exit
	
	push	bx
	shl	bx, 1				;double for word offset
	mov	di, ds:curTextSelections[bx]	;get the selection
	shl	di, 1				;double for word offset
	mov	ax, ds:textColor[di]		;get the color of the selection
	xor	ax, cx				;find diffs with first selection
	or	dx, ax				;or them into indeterminate
	pop	bx
	inc	bx
	jmp	short calcIndeterminate

indeterminateCalced:
	;
	; We have our initial and indeterminate state.  Conveniently, we can
	; pass the same values to both our boolean RGB gadget and our exclusive
	; color gadget.
	;	cx -- first selection color
	;	dx -- indeterminate color bits
	;
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
        GetResourceHandleNS	ColorsGroup, bx	
	mov	si, offset ColorsGroup
	push	cx, dx
	call	ObjMessageCall
	pop	cx, dx

	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	si, offset RGBGroup
	call	ObjMessageCall
exit:
	ret
GenItemGroupProcessSelectionStatus	endm

ObjMessageCall	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
ObjMessageCall	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	RedrawViewArea

SYNOPSIS:	Redraws view.

CALLED BY:	GenItemGroupProcessColorApply,
		GenItemGroupProcessRGBApply

PASS:		ds -- dgroup

RETURN:		nothing

DESTROYED:	anything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/17/92		Initial version

------------------------------------------------------------------------------@

RedrawViewArea	proc	near
	;
	; Get the window to draw to.
	;
        GetResourceHandleNS	GenItemGroupView, bx	
	mov	si, offset GenItemGroupView
	mov	ax, MSG_GEN_VIEW_GET_WINDOW
	call	ObjMessageCall			;cx <- view window
	
	mov	di, cx
	call	GrCreateState			;di <- gstate

	clr	ax
	mov	bx, ax
	mov	cx, 1000
	mov	dx, cx
	call	GrInvalRect			;invalidate some large area

	call	GrDestroyState
	ret
RedrawViewArea	endp





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupProcessColorApply -- 
		MSG_COLOR_APPLY for GenItemGroupProcessClass

DESCRIPTION:	Handles an apply of the color group object.

PASS:		ds 	- dgroup
		ax 	- MSG_COLOR_APPLY

		cx 	- selection
		bp 	- numSelections	

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

GenItemGroupProcessColorApply	method dynamic	GenItemGroupProcessClass, \
				MSG_COLOR_APPLY

	mov	dx, cx				;put color in dx
	mov	cx, ds:numTextSelections	;do all text selections

setColors:
	;
	; For each text selection, set a new color.
	;	cx -- the text selection to change, plus one
	;	dx -- the color to use
	;
	mov	di, cx
	dec	di
	shl	di, 1
	mov	di, ds:curTextSelections[di]	;get text selections
	shl	di, 1
	mov	ds:textColor[di], dx		;stuff a new text color
	loop	setColors			;loop to do more

	call	RedrawViewArea			;redraw everything
	ret
GenItemGroupProcessColorApply	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupProcessColorStatus -- 
		MSG_COLOR_STATUS for GenItemGroupProcessClass

DESCRIPTION:	Handles any user change of the color group object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_COLOR_STATUS

		cx	- selection
		bp 	- num selections
		dl	- GenItemStateFlags

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

GenItemGroupProcessColorStatus	method dynamic	GenItemGroupProcessClass, \
				MSG_COLOR_STATUS
	;
    	; We'll set the RGB Group to match the Color group, taking advantage of
     	; the fact that the data of each is identical.  Also, since the user has
     	; set a new color for the *entire* selection, there is no longer any
     	; indeterminate state.  We will not mark the RGB group modified, as
     	; we only really need to send an apply message from the ColorGroup if
     	; this turns out to be the only user action.
	;
	clr	dx				;no indeterminate booleans
	mov	si, offset RGBGroup
        GetResourceHandleNS	RGBGroup, bx	
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	ObjMessageCall
	ret
GenItemGroupProcessColorStatus	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupProcessRGBApply -- 
		MSG_RGB_APPLY for GenItemGroupProcessClass

DESCRIPTION:	Handles an apply for the RGB thing.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_RGB_APPLY
	
		cx	- selected booleans
		dx	- indeterminate booleans
		bp 	- modified booleans

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

GenItemGroupProcessRGBApply	method dynamic	GenItemGroupProcessClass, \
				MSG_RGB_APPLY

	mov	dx, cx				;put colors in dx
	and	dx, bp				;only care about modified bits
	not	bp				;invert
	mov	cx, ds:numTextSelections	;do all text selections

setColors:
	;
	; For each text selection, we will change the bits that have been
	; modified by the user.
	;	cx -- the text selection to change, plus one
	;	bp -- the color bits to change, inverted
	;	dx -- the color bits that should be set
	;
	mov	di, cx
	dec	di
	shl	di, 1
	mov	di, ds:curTextSelections[di]	;get text selections
	shl	di, 1
	and	ds:textColor[di], bp		;clear bits being changed
	or	ds:textColor[di], dx		;or in bits to set
	loop	setColors			;loop to do more

	call	RedrawViewArea			;redraw everything
	ret
GenItemGroupProcessRGBApply	endm






COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupProcessRGBStatus -- 
		MSG_RGB_STATUS for GenItemGroupProcessClass

DESCRIPTION:	Handles any user change of the color group object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_RGB_STATUS

		cx	- selected booleans
		bp 	- changed booleans

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

GenItemGroupProcessRGBStatus	method dynamic	GenItemGroupProcessClass, \
				MSG_RGB_STATUS
    	; We'll go set the ColorsGroup to match the RGBGroup, taking advantage
     	; of the fact that the data is identical for both, and that if anything
	; is still indeterminate for the RGB Group, the Color group must stay 
     	; indeterminate.  We will not set the ColorGroup modified, as only one
     	; of the two groups really need send an apply message for this action.
     	;
	mov	si, offset ColorsGroup
        GetResourceHandleNS	ColorsGroup, bx	
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjMessageCall
	ret
GenItemGroupProcessRGBStatus	endm



CommonCode	ends		;end of CommonCode resource


