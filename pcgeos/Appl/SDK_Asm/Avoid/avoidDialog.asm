COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Avoid
FILE:		avoidDialog.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/93		Initial version

DESCRIPTION:
	Demonstration program for how to deal properly with becoming
	a non-detachable application on a system working in transparent-
	launch mode (such as Zoomer)

IMPORTANT:

RCS STAMP:
	$Id: avoidDialog.asm,v 1.1 97/04/04 16:34:06 newdeal Exp $

------------------------------------------------------------------------------@

idata	segment
	AvoidFloatingDialogClass
idata	ends


FloatingDialogCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AvoidFloatingDialogStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle mouse presses to get this dialog to look & act like a
		Desk Accessory.

PASS:		*ds:si	- app object
		es	- segment of class
		ax 	- MSG_META_START_SELECT

		cx, dx	- mouse position
		bp low	- ButtonInfo
		bp high	- UIFunctionsActive

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AvoidFloatingDialogStartSelect	method	AvoidFloatingDialogClass,
						MSG_META_START_SELECT
	mov	di, offset AvoidFloatingDialogClass
	call	ObjCallSuperNoLock

	pushf				; preserve return values
	push	ax, cx, dx, bp

	mov	ax, MSG_GEN_GUP_QUERY
	mov	cx, GUQT_FIELD
	call	GenCallParent
	mov	di, bp			; Get Field window, the window that
					; we're on top of, in di
	tst	di			; if somehow NULL, just skip this
	jz	afterLayerRaise

	; Raise this dialog to the top within it's layer, give it the focus
	; within the applications
	;
	mov	ax, mask WPF_LAYER
	mov	dx, ds:[LMBH_handle]	; LayerID for custom layer windows is
					; by default the same as the handle of
					; the block the object resides in.
	call	WinChangePriority	; Bring Window Layer of dialog to top,
					; so it rise up above desk accessories.

afterLayerRaise:
	; Make this the focus & target app, but *don't* raise it to the front.
	; We want the dialog to get the focus, but appear as if it was a
	; complete desk accessory all by itself.
	;
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	UserCallApplication
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	UserCallApplication

	pop	ax, cx, dx, bp
	popf
	ret
AvoidFloatingDialogStartSelect	endm

FloatingDialogCode	ends		;end of AppCode resource
