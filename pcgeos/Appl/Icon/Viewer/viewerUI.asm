COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1994.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Icon editor
MODULE:		Viewer
FILE:		viewerUI.asm

AUTHOR:		Steve Yegge, Jun 17, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT EnableGroup1		Sets-enabled RenameIconDialog.

    INT EnableGroup2		Sets-enabled Delete and Copy.

    INT DisableGroup1		Sets-not-enabled the RenameIconDialog.

    INT DisableGroup2		Disables ui, for no selections.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/17/94		Initial revision

DESCRIPTION:

	Routines for interfacing with the UI.

	$Id: viewerUI.asm,v 1.1 97/04/04 16:07:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ViewerCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerShowSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scrolls the view to show the first selection.

CALLED BY:	MSG_DB_VIEWER_SHOW_SELECTION

PASS:		*ds:si = DBViewer object
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get the bounds of the selected icon
	- record a classed event of MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	- send that baby to the view

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/28/92		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerShowSelection	proc	far
		class	DBViewerClass
		uses	ax, cx, dx, bp
		.enter
	;
	;  Get the OD of the first selected child.
	;
		mov	ax, MSG_DB_VIEWER_GET_FIRST_SELECTION
		call	ObjCallInstanceNoLock		; cx = selection
		LONG	jc	done			; no selection
		
		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		call	ObjCallInstanceNoLock		; ^lcx:dx = child
		jc	done				; something barfed
	;
	;  Get the bounds of the selected child.
	;
		push	si				; save viewer
		
		movdw	bxsi, cxdx
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_GET_BOUNDS		; (ax,bp) to (cx,dx)
		call	ObjMessage
		mov	bx, bp
		
		pop	si				; restore viewer
	;
	;  Set up the stack frame to pass to the view.
	;
		push	ds:[LMBH_handle], si			; save us!
		
		sub	sp, size MakeRectVisibleParams
		mov	bp, sp
		
		clr	ss:[bp].MRVP_bounds.RD_left.high
		mov	ss:[bp].MRVP_bounds.RD_left.low, ax
		clr	ss:[bp].MRVP_bounds.RD_top.high
		mov	ss:[bp].MRVP_bounds.RD_top.low, bx
		clr	ss:[bp].MRVP_bounds.RD_right.high
		mov	ss:[bp].MRVP_bounds.RD_right.low, cx
		clr	ss:[bp].MRVP_bounds.RD_bottom.high
		mov	ss:[bp].MRVP_bounds.RD_bottom.low, dx
		mov	ss:[bp].MRVP_xMargin, MRVM_0_PERCENT
		mov	ss:[bp].MRVP_yMargin, MRVM_0_PERCENT
		clr	ss:[bp].MRVP_xFlags
		clr	ss:[bp].MRVP_yFlags
	;
	;  Record a classed event to send to the view.
	;
		mov	bx, segment GenViewClass
		mov	si, offset  GenViewClass
		mov	di, mask MF_RECORD or mask MF_STACK
		mov	dx, size MakeRectVisibleParams
		mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
		call	ObjMessage
		
		add	sp, size MakeRectVisibleParams
	;
	;  Send the classed event along to the view.
	;
		pop	bx, si
		call	MemDerefDS			; *ds:si = viewer
		mov	cx, di				; ^hcx = classed even
		mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
DBViewerShowSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerEnableUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables or disables the triggers based on the number of
		selections.

CALLED BY:	MSG_DB_VIEWER_ENABLE_UI

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance
		cx	= number of selections

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- if none are selected, disable all triggers
	- if one is selected, enable all triggers
	- if 2 or more are selected, disable edit & rename, and
		enable delete & copy

	- to be really studly and speed things up, we keep a
	  flag for each trigger group.  Rename and Edit are
	  always turned on & off together, and the same is true
	  of Delete & Copy.  Sort of.  We only enable Copy if
	  there are 2 databases open (for now), so we have to
	  pass along *another* flag for that one.  Ugh.

	  If the group isn't changing state we skip sending the 
	  messages.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerEnableUI	proc	far
		class	DBViewerClass
		uses	ax, cx, dx, bp
		.enter
	;
	;  Notify the clipboard.
	;
		mov	ax, MSG_DB_VIEWER_NOTIFY_CLIPBOARD
		call	ObjCallInstanceNoLock
	;
	;  Update the rest of the UI.
	;
		mov	bl, ds:[di].DBVI_triggersEnabled
		push	ds:[LMBH_handle], si			; save OD info
		
		tst	cx
		jz	noneSelected
		
		cmp	cx, 1
		je	oneSelected
	;
	;  More than one was selected.  If necessary, disable first
	;  group and enable the second.
	;
		test	bl, mask TBT_GROUP1
		jz	enGroup2a
		
		call	DisableGroup1
		andnf	bl, not mask TBT_GROUP1			; clear the bit
enGroup2a:
		test	bl, mask TBT_GROUP2
		jnz	done
		
		call	EnableGroup2
		ornf	bl, mask TBT_GROUP2
		
		jmp	short	done
oneSelected:
		test	bl, mask TBT_GROUP1
		jnz	enGroup2b
		
		call	EnableGroup1
		ornf	bl, mask TBT_GROUP1
enGroup2b:
		test	bl, mask TBT_GROUP2
		jnz	done
		
		call	EnableGroup2
		ornf	bl, mask TBT_GROUP2
		
		jmp	short	done
noneSelected:
		test	bl, mask TBT_GROUP1
		jz	disGroup2
		
		call	DisableGroup1
		andnf	bl, not mask TBT_GROUP1
disGroup2:
		test	bl, mask TBT_GROUP2
		jz	done
		
		call	DisableGroup2
		andnf	bl, not mask TBT_GROUP2
done:
		mov	cl, bl					; flags
		pop	bx, si
		call	MemDerefDS
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].DBVI_triggersEnabled, cl
		
		.leave
		ret
DBViewerEnableUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableGroup1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets-enabled RenameIconDialog.

CALLED BY:	DBViewerEnableUI

PASS:		*ds:si	= DBViewer object

RETURN:		nothing

DESTROYED:	everything except bx and si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableGroup1	proc	near
		class	DBViewerClass
		uses	bx, si
		.enter
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	;
	;  enable the Rename Icon Dialog
	;
		mov	bx, ds:[di].GDI_display
		mov	si, offset RenameIconDialog
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  enable the Edit Icon Trigger
	;
		mov	si, offset EditIconTrigger
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage

		.leave
		ret
EnableGroup1	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableGroup2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets-enabled Delete and Copy.

CALLED BY:	DBViewerEnableUI

PASS:		*ds:si = ViewerTitleBar object

RETURN:		nothing

DESTROYED:	everything except bx and si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableGroup2	proc	near
		class	DBViewerClass
		uses	bx, si
		.enter
		
		.leave
		ret
EnableGroup2	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableGroup1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets-not-enabled the RenameIconDialog.

CALLED BY:	DBViewerEnableUI

PASS:		*ds:si	 = DBViewer object

RETURN:		nothing

DESTROYED:	everything except bx and si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableGroup1	proc	near
		class	DBViewerClass
		uses	bx, si
		.enter
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	;
	;  disable the Rename Icon Dialog
	;
		mov	bx, ds:[di].GDI_display
		mov	si, offset RenameIconDialog
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  disable the Edit Icon Trigger
	;
		mov	si, offset EditIconTrigger
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
		
		.leave
		ret
DisableGroup1	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableGroup2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables ui, for no selections.

CALLED BY:	DBViewerEnableUI

PASS:		*ds:si	= DBViewer object

RETURN:		nothing

DESTROYED:	everything except bx and si

PSEUDO CODE/STRATEGY:

	Right now, there's nothing to disable, but I'm
	keeping the routine around in case something needs to be.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableGroup2	proc	near
		class	DBViewerClass
		uses	bx, si
		.enter
		
		
		.leave
		ret
DisableGroup2	endp

ViewerCode	ends
