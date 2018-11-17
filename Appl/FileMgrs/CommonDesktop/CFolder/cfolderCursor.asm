COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cfolderCursor.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/13/92   	Initial version.

DESCRIPTION:
	Routines for drawing the "cursor"

	$Id: cfolderCursor.asm,v 1.3 98/06/03 13:26:44 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CURSOR_MARGIN equ 3

FolderCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the cursor

CALLED BY:

PASS:		*ds:si - FolderClass object
		es:di - FolderRecord to make cursor, or di = NIL to
			set none

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCursor	proc far
	class	FolderClass 
;
; no cursor for ZMGR - brianc 7/15/93
;
if not _ZMGR
	uses	ax,bx,cx,dx,di
	.enter

	DerefFolderObject	ds, si, bx
	cmp	di, ds:[bx].FOI_cursor
	je	done

	test	ds:[bx].FOI_folderState, mask FOS_UPDATE_PENDING
	jnz	noOld
	pushf	
	call	FolderDrawCursor		; erase the old
	popf
noOld:
	mov	ds:[bx].FOI_cursor, di
	jnz	done
	call	FolderDrawCursor		; draw the new
done:
	.leave
endif
	ret
SetCursor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderDrawCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw or erase the current cursor

CALLED BY:	UTILITY -
			FolderLockAndDrawCursor,
			SetCursor,
			FolderRepositionSingleIcon
			
PASS:		*ds:si - FolderClass object
		es - segment of FolderBuffer

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Can either "draw" or "erase" the current cursor, so be
	careful...


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderDrawCursor	proc far
	class	FolderClass
	uses	ax,bx,cx,dx,bp,di
	.enter

	DerefFolderObject	ds, si, bx

	mov	di, ds:[bx].DVI_gState
	tst	di
	jz	done

	mov	bp, ds:[bx].FOI_cursor
	cmp	bp, NIL
	je	done
	call	FolderDrawCursorLow
done:
	.leave
	ret
FolderDrawCursor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderLockAndDrawCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the FolderRecord block and draw the cursor

CALLED BY:	FolderTargetCommon

PASS:		*ds:si - FolderClass object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/17/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderLockAndDrawCursor	proc near
	uses	ax, bx, si
	class	FolderClass 
	.enter

	call	FolderLockBuffer
	jz	done
	call	FolderDrawCursor
	call	FolderUnlockBuffer
done:
	.leave
		ret
FolderLockAndDrawCursor	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderDrawCursorLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Actual routine to draw or erase the cursor

CALLED BY:	FolderLockAndDrawCursor

PASS:		*ds:si - FolderClass object
		es:bp - FolderRecord 
		di - gstate handle

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderDrawCursorLow	proc near
	class	FolderClass

EC <	xchg	di, bp	>
EC <	call	ECCheckFolderRecordESDI	>
EC <	xchg	di, bp	>

	mov	al, MM_INVERT			; set invert draw mode
	call	GrSetMixMode

	mov	al, SDM_50
	call	GrSetLineMask

	mov	bx, ds:[si]
	test	ds:[bx].FOI_displayMode, mask FIDM_LICON or mask FIDM_SICON
	jz	notIconMode
if _NEWDESK
	call	LoadNameBounds
else
	call	LoadIconBounds
endif
	sub	ax, 2
	sub	bx, 2
	inc	cx
	inc	dx
	jmp	drawCursor

notIconMode:
	call	LoadBoundBox

drawCursor:
	call	GrDrawRect
	mov	al, SDM_100
	call	GrSetLineMask
	mov	al, MM_COPY			; restore draw mode
	call	GrSetMixMode
	ret

FolderDrawCursorLow	endp

FolderCode	ends
