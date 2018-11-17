COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoDex/DB		
FILE:		dbInk.asm

AUTHOR:		Ted H. Kim, March 3, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial revision


DESCRIPTION:

	$Id: dbInk.asm,v 1.1 97/04/04 15:49:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexInkClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the current ink from the screen.

CALLED BY:	GLOBAL (MSG_DP_CLEAN_INK)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance

RETURN:		Nothing

DESTROYED:	AX, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RolodexInkClear	proc	near
	uses	cx, dx, bp
	.enter

;	Clear out the ink data, and mark the object as clean.

	GetResourceHandleNS	InkResource, bx
	mov	si, offset InkResource:InkObject

	sub	sp, size InkDBFrame
	mov	bp, sp
	clr	ss:[bp].IDBF_VMFile
	clrdw	ss:[bp].IDBF_DBGroupAndItem
	clr	ss:[bp].IDBF_bounds.R_left
	clr	ss:[bp].IDBF_bounds.R_top
	mov	ax, MSG_INK_LOAD_FROM_DB_ITEM
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size InkDBFrame

	.leave
	ret
RolodexInkClear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexInkDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load data into the ink object

CALLED BY:	GLOBAL (MSG_DP_LOAD_INK)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance
		SS:BP	= EventTableEntry

RETURN:		CX	= Offset to insertion point (bougs)

DESTROYED:	AX, BX, DI, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RolodexInkDisplay	proc	near
	uses	ax, bx, cx, dx, si, di, bp
	.enter

	; We have the correct day. Load the ink
		
	mov	dx, size InkDBFrame
	sub	sp, dx
	mov	bp, sp			; InkDBFrame => SS:BP
	call	VMGetThreadVMFile
	mov	ss:[bp].IDBF_VMFile, bx
	call	DBGetThreadDBGroup
	mov	ss:[bp].IDBF_DBGroupAndItem.DBGI_group, ax
	mov	ss:[bp].IDBF_DBGroupAndItem.DBGI_item, di
	mov	ss:[bp].IDBF_DBExtra, 0
	clr	ss:[bp].IDBF_bounds.R_left
	clr	ss:[bp].IDBF_bounds.R_top


	; Now send messages to the ink object

	GetResourceHandleNS	InkResource, bx
	mov	si, offset InkResource:InkObject
	mov	ax, MSG_INK_LOAD_FROM_DB_ITEM
	mov     di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size InkDBFrame

	.leave
	ret
RolodexInkDisplay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexInkSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the ink away into a DB item

CALLED BY:	GLOBAL (MSG_DP_STORE_INK)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RolodexInkSave	proc	near
	uses	ax, bx, cx, dx
	.enter

	; If we need to save anything away, do it

	test	ds:[ink], mask IF_INK_DIRTY
	jz	done			; if not dirty, do nothing

	and	ds:[ink], not mask IF_INK_DIRTY
	mov	dx, size InkDBFrame
	sub	sp, dx
	mov	bp, sp			; InkDBFrame => SS:BP
	call	VMGetThreadVMFile
	mov	ss:[bp].IDBF_VMFile, bx
	call	DBGetThreadDBGroup
	mov	ss:[bp].IDBF_DBGroupAndItem.DBGI_group, ax
	mov	ss:[bp].IDBF_DBGroupAndItem.DBGI_item, 0
	mov	ss:[bp].IDBF_DBExtra, 0
	clr	ss:[bp].IDBF_bounds.R_left
	clr	ss:[bp].IDBF_bounds.R_top
	mov	ss:[bp].IDBF_bounds.R_right, 0xffff
	mov	ss:[bp].IDBF_bounds.R_bottom, 0xffff

	; Now send messages to the ink object

	GetResourceHandleNS	InkResource, bx
	mov	si, offset InkResource:InkObject
	mov	ax, MSG_INK_SAVE_TO_DB_ITEM
	mov     di, mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, size InkDBFrame
done:
	.leave
	ret
RolodexInkSave	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexInkDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that the ink has become dirty

CALLED BY:	GLOBAL (MSG_DP_INK_DIRTY)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RolodexInkDirty		proc	far

	class	RolodexClass

	.enter

	; Set the dirty flag

	or	ds:[ink], mask IF_INK_DIRTY

	mov	cx, ds:[fileHandle]
	jcxz	exit
	call	RolodexVMFileDirty
exit:
	.leave
	ret
RolodexInkDirty	endm

CheckInkOn	proc	far	 uses	ax, bx, cx, dx, si, di
	.enter

	test	ds:[ink], mask IF_INK_ON	; is the check box on?

	.leave
	ret
CheckInkOn	endp

RolodexSetInkUsable	proc	far

	class	RolodexClass

	call	ClearNoteField

	mov	si, offset NoteText	
	GetResourceHandleNS	NoteText, bx 
	mov	ax, MSG_GEN_SET_NOT_USABLE  ; ax - method number
	mov	di, mask MF_FIXUP_DS	  ; di - set flags 
	mov	dl, VUM_NOW		; do it right now
	call	ObjMessage		; make the window usable

	mov	si, offset InkView	
	GetResourceHandleNS	InkView, bx 
	mov	ax, MSG_GEN_SET_USABLE	  ; ax - method number
	mov	di, mask MF_FIXUP_DS		  ; di - set flags 
	mov	dl, VUM_NOW		; do it right now
	call	ObjMessage		; make the window usable
	or	ds:[ink], mask IF_INK_ON  
	ret
RolodexSetInkUsable	endp
	
RolodexSetInkNotUsable	proc	far

	class	RolodexClass

	call	RolodexInkClear

	mov	si, offset InkView	
	GetResourceHandleNS	InkView, bx 
	mov	ax, MSG_GEN_SET_NOT_USABLE	  ; ax - method number
	mov	di, mask MF_FIXUP_DS    ; di - set flags 
	mov	dl, VUM_NOW		; do it right now
	call	ObjMessage		; make the window usable

	mov	si, offset NoteText	
	GetResourceHandleNS	NoteText, bx 
	mov	ax, MSG_GEN_SET_USABLE  ; ax - method number
	mov	di, mask MF_FIXUP_DS    ; di - set flags 
	mov	dl, VUM_NOW		; do it right now
	call	ObjMessage		; make the window usable
	andnf	ds:[ink], not mask IF_INK_ON  
	ret
RolodexSetInkNotUsable	endp

CommonCode	ends
