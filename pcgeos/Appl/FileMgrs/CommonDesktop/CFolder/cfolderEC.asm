COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cfolderEC.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/10/92   	Initial version.

DESCRIPTION:
	

	$Id: cfolderEC.asm,v 1.2 98/06/03 13:32:55 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderUtilCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckFolderRecordESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that es:di points to a valid FolderRecord

CALLED BY:

PASS:		es:di - FolderRecord

RETURN:		nothing 

DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/10/92   	Initial version.
	martin	11/14/92	Added some checks.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckFolderRecordESDI	proc far

		uses	ax, cx

		.enter
		pushf

		call	ECCheckBoundsESDI
	;
	; Check that FileLongName is null-terminated
	;
		push	di
		lea	di, es:[di].FR_name
		mov	cx, size FR_name
		clr	ax
		repne	scasb
		ERROR_NE ILLEGAL_FOLDER_RECORD
		pop	di
	;
	; Error-check the bounds
	;
		mov	ax, es:[di].FR_boundBox.R_right
		sub	ax, es:[di].FR_boundBox.R_left
		ERROR_L	ILLEGAL_FOLDER_RECORD
		cmp	ax, MAX_FOLDER_RECORD_WIDTH
		ERROR_G	ILLEGAL_FOLDER_RECORD

		mov	ax, es:[di].FR_boundBox.R_bottom
		sub	ax, es:[di].FR_boundBox.R_top
		ERROR_L	ILLEGAL_FOLDER_RECORD
		cmp	ax, MAX_FOLDER_RECORD_HEIGHT
		ERROR_G	ILLEGAL_FOLDER_RECORD	

		popf
		.leave
		ret
ECCheckFolderRecordESDI	endp

ForceRef ECCheckFolderRecordESDI
; In case it's used only by NewDesk



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ECCheckFolderRecordDSDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that ds:di points to valid FolderRecord
		"instance data"

PASS:		ds:di - FolderRecord

RETURN:		nothing 

DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckFolderRecordDSDI	proc	far
	uses	es, di
	.enter
	segmov	es, ds
	call	ECCheckFolderRecordESDI
	.leave
	ret
ECCheckFolderRecordDSDI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ECCheckFolderBufferHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Verifies that the FolderBufferHeader for the given
		folder buffer is correct.

PASS:		*ds:si - FolderClass object 
		es:0	= FolderBufferHeader

RETURN:		nothing 

DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckFolderBufferHeader	proc	far
		uses	ax, bx
		.enter
		pushf

		movdw	axbx, es:[FBH_folder]

		cmp	ax, ds:[LMBH_handle]
		ERROR_NE	CORRUPT_FOLDER_BUFFER_HEADER	

		cmp	bx, si
		ERROR_NE	CORRUPT_FOLDER_BUFFER_HEADER	

		popf
		.leave
		ret
ECCheckFolderBufferHeader	endp



ECCheckBoundsESDI	proc	far
	uses	ds, si
	.enter
	segmov	ds, es, si
	mov	si, di
	call	ECCheckBounds
	.leave
	ret
ECCheckBoundsESDI	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckFolderObjectDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that *ds:si is a folder object

CALLED BY:

PASS:		*ds:si - folder object (perhaps)

RETURN:		nothing 

DESTROYED:	nothing (flags preserved) 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/17/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckFolderObjectDSSI	proc far
		uses	es, di
		.enter
		pushf	
		segmov	es, <segment FolderClass>, di
		mov	di, offset FolderClass		
		call	ObjIsObjectInClass		
		ERROR_NC DS_SI_NOT_FOLDER_OBJECT
		popf
		.leave
		ret
ECCheckFolderObjectDSSI	endp




FolderUtilCode	ends
