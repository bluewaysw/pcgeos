
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ssmetaUtils.asm

AUTHOR:		Cheng, 8/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial revision

DESCRIPTION:

FATAL ERRORS:
	SSMETA_INVALID_RESULT

	$Id: ssmetaUtils.asm,v 1.1 97/04/07 10:44:04 newdeal Exp $

-------------------------------------------------------------------------------@

SSMetaCode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetDataArrayRecord

DESCRIPTION:	Utility routine. Returns pointer to a SSMetaDataArrayRecord.

CALLED BY:	INTERNAL
		    (InitSSMetaDataArrayRecord,
		    SSMetaDataArrayAddEntry,
		    SSMetaDataArrayGetNumEntries,
		    SSMetaDataArrayGetFirstEntry,
		    SSMetaDataArrayGetNthEntry)

PASS:		es:bp - SSMetaStruc with these fields initialized:
		    SSMDAS_vmFileHan *
		    SSMDAS_hdrBlkVMHan *
		    SSMDAS_dataArraySpecifier **
		    * = initilization done by SSMetaGetClipboardTransferItem
		    ** = caller initializes this

RETURN:		ds:si - SSMetaDataArrayRecord
		bx - mem handle of locked header block

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

GetDataArrayRecord	proc	near	uses	ax,di
	.enter
EC<	call	ECCheckSSMetaStruc >

	call	MapSpecifierToHeaderOffset	; si <- offset
	call	LockHeaderBlk			; ds:si <- SSMetaDataArrayRecord
						; bx <- mem handle

	mov	es:[bp].SSMDAS_dataArrayRecordPtr.segment, ds
	mov	es:[bp].SSMDAS_dataArrayRecordPtr.offset, si

	;
	; retrieve huge array handle for data array
	;
	mov	di, ds:[si].SSMDAR_dataArrayLinkOffset	; di <- offset
	mov	di, ds:[di].high		; deref to get blk han

	mov	es:[bp].SSMDAS_dataArrayBlkHan, di ; used by LockDataArrayEntry
	mov	es:[bp].SSMDAS_hdrBlkMemHan, bx

	.leave
	ret
GetDataArrayRecord	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MapSpecifierToHeaderOffset

DESCRIPTION:	Maps a DataArraySpecifier into an offset to the corresponding
		SSMetaDataArrayRecord.

CALLED BY:	INTERNAL ()

PASS:		es:bp - SSMetaStruc

RETURN:		si - offset into header to the SSMetaDataArrayRecord

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

MapSpecifierToHeaderOffset	proc	near	uses	ax,dx
	.enter
EC<	call	ECCheckSSMetaStruc >

	clr	ah
	mov	al, es:[bp].SSMDAS_dataArraySpecifier
	mov	dx, size SSMetaDataArrayRecord
	mul	dx				; dx:ax <- ax * record size
EC<	tst	dx >
EC<	ERROR_NE SSMETA_INVALID_RESULT >
	add	ax, offset SSMHB_startArrayRecords
	mov	si, ax

	.leave
	ret
MapSpecifierToHeaderOffset	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LockDataArrayEntry

DESCRIPTION:	Lock the entry in the current data array.

CALLED BY:	INTERNAL (SSMetaDataArrayGetFirstEntry,
		    SSMetaDataArrayGetNthEntry)

PASS:		dx:ax - element number in huge array
		es:bp - SSMetaStruc with these fields initialized:
		    SSMDAS_vmFileHan
		    SSMDAR_dataArrayListOffset

RETURN:		carry clear if entry present
		    ds:si - pointer to requested entry
		    cx - size of entry
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

LockDataArrayEntry	proc	near	uses	ax,bx,dx,di
	.enter
EC<	call	ECCheckSSMetaStruc >

	mov	bx, es:[bp].SSMDAS_vmFileHan
	mov	di, es:[bp].SSMDAS_dataArrayBlkHan
	call	HugeArrayLock			; ds:si <- entry
						; dx <- entry size
						; ax - 0 if ds:si invalid
						; cx - ignore
	mov	cx, dx				; cx <- size
	tst	ax				; valid ptr?
	clc					; assume so
	jne	done				; done if assumption correct
	stc					; else flag invalid
done:
	.leave
	ret
LockDataArrayEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LockHeaderBlk

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		es:bp - SSMetaStruc

RETURN:		bx - mem handle of locked VM block
		ds - seg addr of locked block

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

LockHeaderBlk	proc	near	uses	ax
	.enter
EC<	call	ECCheckSSMetaStruc >

	mov	bx, es:[bp].SSMDAS_vmFileHan
	mov	ax, es:[bp].SSMDAS_hdrBlkVMHan
	call	SSMetaVMLock			; bx <- mem han, ax <- seg
	mov	ds, ax

	.leave
	ret
LockHeaderBlk	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaVMLock

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		bx - VM file handle
		ax - VM block handle

RETURN:		ax - segment of locked VM block
		bx - handle of locked VM block

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaVMLock	proc	near	uses	bp
	.enter
	call	VMLock		; ax <- segment, bp <- mem han
	mov	bx, bp
	.leave
	ret
SSMetaVMLock	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaVMUnlock

DESCRIPTION:	Unlocks the VM block corresponding to the passed mem handle.

CALLED BY:	INTERNAL ()

PASS:		bx - mem handle of locked VM block

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaVMUnlock	proc	near	uses	bp
	.enter
	mov	bp, bx
	call	VMUnlock
	.leave
	ret
SSMetaVMUnlock	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaVMDirty

DESCRIPTION:	Dirties the VM block corresponding to the passed mem handle.

CALLED BY:	INTERNAL ()

PASS:		bx - mem handle of locked VM block

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/93		Initial version

-------------------------------------------------------------------------------@

SSMetaVMDirty	proc	near	uses	bp
	.enter
	mov	bp, bx
	call	VMDirty
	.leave
	ret
SSMetaVMDirty	endp

SSMetaCode	ends
