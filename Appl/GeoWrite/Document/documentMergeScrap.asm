COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		documentMergeScrap.asm

AUTHOR:		John Wedgwood, Nov  2, 1992

ROUTINES:
	Name				Description
	----				-----------
	MergeScrapInit			Set up for merging
	MergeScrapFinish		Finish after merging
	
	MergeScrapGetNumberOfEntries	Get the number of entries
	MergeScrapResetForData		Set up for reading data values

	MergeScrapLockFieldEntry	Lock the current field entry
	MergeScrapUnlockFieldEntry	Unlock the current field entry

	MergeScrapLockDataEntry		Lock the current data entry
	MergeScrapUnlockDataEntry	Unlock the current data entry

	MergeScrapNextField		Advance to the next data field
	MergeScrapNextRecord		Advance to the next data record
	
	MergeDieDieDie			Need I say more?
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/ 2/92	Initial revision

DESCRIPTION:
	Scrap related code.

	$Id: documentMergeScrap.asm,v 1.2 98/03/24 21:41:50 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocMerge	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeScrapLoadLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the ssmeta library

CALLED BY:	SetupForMerge
PASS:		ss:bp	= Inheritable stack frame
RETURN:		carry set on error
		carry clear otherwise
			scrapLibraryHandle set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeScrapLoadLibrary	proc	near
	uses	ax, bx, dx, si, ds
	.enter	inherit	WriteDocumentContinuePrinting

	segmov	ds, cs
	mov	bx, SSMETA_LIB_DISK_HANDLE	; Set path to library
	mov	dx, offset ssmetaLibDir
	call	FileSetCurrentPath
	jc	quit				; Branch on error

	mov	si, offset ssmetaLibPath	; ds:si <- ptr to library
	mov	ax, SSMETA_PROTO_MAJOR		; ax.bx <- protocol
	mov	bx, SSMETA_PROTO_MINOR
	call	GeodeUseLibrary			; bx <- library handle
	jc	quit

	mov	scrapLibraryHandle, bx
quit:
	.leave
	ret

if DBCS_PCGEOS
ssmetaLibDir	wchar	SSMETA_LIB_DIR
ssmetaLibPath	wchar	SSMETA_LIB_PATH
else
ssmetaLibDir	char	SSMETA_LIB_DIR
ssmetaLibPath	char	SSMETA_LIB_PATH
endif

MergeScrapLoadLibrary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeScrapUnloadLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the library

CALLED BY:	CleanupAfterMerge
PASS:		ss:bp	= Inheritable stack frame
				scrapLibraryHandle set
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeScrapUnloadLibrary	proc	near
	uses	bx
	.enter	inherit	WriteDocumentContinuePrinting

	mov	bx, scrapLibraryHandle
	call	GeodeFreeLibrary

	.leave
	ret
MergeScrapUnloadLibrary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeScrapInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the scrap data-structures before merging.

CALLED BY:	Utility
PASS:		*ds:si	= WriteDocument instance
		es	= dgroup
		ss:bp	= Inheritable stack frame
RETURN:		carry set on error (ie: there is no scrap)
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeScrapInit	proc	near
	.enter	inherit	WriteDocumentContinuePrinting
	clr	ssmetaData.SSMDAS_row		; Start at the start...
	clr	ssmetaData.SSMDAS_col

	call	CallSSMetaInitForPaste		; Call the routine
	jc	quit				; Branch if no scrap

	;
	; We can handle this data. Reset the pointer so we can start reading.
	;
	call	CallSSMetaDataArrayResetEntryPointer
	
	clc					; Signal: has a scrap
quit:
	.leave
	ret
MergeScrapInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeScrapFinish
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish up with a scrap

CALLED BY:	Utility
PASS:		*ds:si	= WriteDocument instance
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeScrapFinish	proc	near
	uses	ax, bx, dx, bp
	.enter
	mov	ax, enum SSMetaDoneWithPaste	; ax <- routine
	call	CallSSMetaRoutine
	.leave
	ret
MergeScrapFinish	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeScrapGetNumberOfEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of records in a merge scrap

CALLED BY:	Utility
PASS:		ss:bp	= Inheritable stack frame
RETURN:		ax	= Number of mergable entries
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeScrapGetNumberOfEntries	proc	near
	uses	bx, dx, bp
	.enter
	mov	ax, enum SSMetaGetNumberOfDataRecords
	call	CallSSMetaRoutine
	.leave
	ret
MergeScrapGetNumberOfEntries	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeScrapResetForData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset data pointers to get data for a given scrap.

CALLED BY:	Utility
PASS:		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeScrapResetForData	proc	near
	uses	ax, bx, dx, bp
	.enter
	mov	ax, enum SSMetaResetForDataRecords
	call	CallSSMetaRoutine
	.leave
	ret
MergeScrapResetForData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeScrapLockFieldEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a field defined by SSMDAS_col

CALLED BY:	Utility
PASS:		ss:bp	= Inheritable stack frame
RETURN:		carry set if there is no such entry
		carry clear otherwise
		    es:bx	= Pointer
		    ax		= Size of the data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeScrapLockFieldEntry	proc	near
	uses	dx, si, ds
	.enter	inherit	WriteDocumentContinuePrinting
	
	call	CallSSMetaFieldNameLock	; carry set if it exists
					; ds:si <- ptr to name
					; ax <- size of name
					; bx <- data block
	jc	quit			; Branch if no field name

	;
	; There is data.
	;
	mov	dataBlock, bx		; Save data-block
	segmov	es, ds, bx		; es:bx <- ptr to data
	mov	bx, si
					; ax already has the size

	clc				; Signal: has data
quit:
	.leave
	ret
MergeScrapLockFieldEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeScrapUnlockFieldEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the locked field.

CALLED BY:	Utility
PASS:		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeScrapUnlockFieldEntry	proc	near
	.enter	inherit	WriteDocumentContinuePrinting
	
	call	CallSSMetaFieldNameUnlock ; Release the field
	.leave
	ret
MergeScrapUnlockFieldEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeScrapLockDataEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the data entry defined by SSMDAS_row/col

CALLED BY:	Utility
PASS:		ss:bp	= Inheritable stack frame
RETURN:		carry set if there is no such entry
		carry clear otherwise
		    es:bx	= Pointer
		    ax		= Size of the data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeScrapLockDataEntry	proc	near
	uses	dx, si, ds
	.enter	inherit	WriteDocumentContinuePrinting
	
	call	CallSSMetaDataRecordFieldLock ; carry set if it exists
					; ds:si <- ptr to name
					; ax <- size of name
					; bx <- data block
	jc	quit			; Branch if no field name

	;
	; There is data.
	;
	mov	dataBlock, bx		; Save data-block
	segmov	es, ds, bx		; es:bx <- ptr to data
	mov	bx, si
					; ax already has the size

	clc				; Signal: has data
quit:
	.leave
	ret
MergeScrapLockDataEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeScrapUnlockDataEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the entry which was last locked

CALLED BY:	Utility
PASS:		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeScrapUnlockDataEntry	proc	near
	.enter	inherit	WriteDocumentContinuePrinting
	
	call	CallSSMetaDataRecordFieldUnlock ; Release the data
	.leave
	ret
MergeScrapUnlockDataEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeScrapNextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance to the next field in a record.

CALLED BY:	Utility
PASS:		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeScrapNextField	proc	near
	.enter	inherit	WriteDocumentContinuePrinting

	inc	ssmetaData.SSMDAS_col		; Next column

	.leave
	ret
MergeScrapNextField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeScrapNextRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance to the next record.

CALLED BY:	Utility
PASS:		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeScrapNextRecord	proc	near
	.enter	inherit	WriteDocumentContinuePrinting

	clr	ssmetaData.SSMDAS_col		; First column of...
	inc	ssmetaData.SSMDAS_row		;    next row

	.leave
	ret
MergeScrapNextRecord	endp



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; Returns:
;	carry
;
CallSSMetaInitForPaste	proc	near
	uses	ax, bx, dx, bp
	.enter	inherit	WriteDocumentContinuePrinting
	mov	ax, enum SSMetaInitForPaste	; ax <- routine
	mov	bx, scrapLibraryHandle		; bx <- library handle
	call	ProcGetLibraryEntry		; bx.ax <- virtual routine

	pushdw	bxax				; Pass routine to call

	clr	bx				; No ClipboardItemFlags
	mov	dx, ss				; dx:bp <- ptr to structure
	lea	bp, ssmetaData

	call	PROCCALLFIXEDORMOVABLE_PASCAL	; Calls the routine
	.leave
	ret
CallSSMetaInitForPaste	endp



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; Returns:
;	nothing
;
CallSSMetaDataArrayResetEntryPointer	proc	near
	uses	ax, bx, dx, bp
	.enter
	mov	ax, enum SSMetaDataArrayResetEntryPointer ; ax <- routine
	call	CallSSMetaRoutine
	.leave
	ret
CallSSMetaDataArrayResetEntryPointer	endp



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; Returns:
;	carry
;	ds:si
;	ax
;	bx
;
CallSSMetaFieldNameLock	proc	near
	uses	dx, bp
	.enter
	mov	ax, enum SSMetaFieldNameLock	; ax <- routine
	call	CallSSMetaRoutine
	.leave
	ret
CallSSMetaFieldNameLock	endp




;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; Returns:
;	nothing
;
CallSSMetaFieldNameUnlock	proc	near
	uses	ax, bx, dx, bp
	.enter	inherit	WriteDocumentContinuePrinting
	mov	ax, enum SSMetaFieldNameUnlock	; ax <- routine
	mov	bx, scrapLibraryHandle		; bx <- library handle
	call	ProcGetLibraryEntry		; bx.ax <- virtual routine

	pushdw	bxax				; Pass routine to call

	mov	bx, ss:dataBlock		; bx <- block containing data
	mov	dx, ss				; dx:bp <- ptr to structure
	lea	bp, ssmetaData

	call	PROCCALLFIXEDORMOVABLE_PASCAL	; Calls the routine
	.leave
	ret
CallSSMetaFieldNameUnlock	endp



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; Returns:
;	carry
;	ds:si
;	ax
;	bx
;
CallSSMetaDataRecordFieldLock	proc	near
	uses	dx, bp
	.enter
	mov	ax, enum SSMetaDataRecordFieldLock ; ax <- routine
	call	CallSSMetaRoutine
	.leave
	ret
CallSSMetaDataRecordFieldLock	endp




;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; Returns:
;	nothing
;
CallSSMetaDataRecordFieldUnlock	proc	near
	uses	ax, bx, dx, bp
	.enter	inherit	WriteDocumentContinuePrinting
	mov	ax, enum SSMetaDataRecordFieldUnlock	; ax <- routine
	mov	bx, scrapLibraryHandle		; bx <- library handle
	call	ProcGetLibraryEntry		; bx.ax <- virtual routine

	pushdw	bxax				; Pass routine to call

	mov	bx, ss:dataBlock		; bx <- block containing data
	mov	dx, ss				; dx:bp <- ptr to structure
	lea	bp, ssmetaData

	call	PROCCALLFIXEDORMOVABLE_PASCAL	; Calls the routine
	.leave
	ret
CallSSMetaDataRecordFieldUnlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallSSMetaRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a routine in the SSMeta library

CALLED BY:	Utility
PASS:		ax	= Routine to call
		ss:bp	= Inheritable stack frame
		Arguments to routine, other than dx:bp as SSMetaStruc
RETURN:		Whatever the routine does
DESTROYED:	Whatever the routine does, ax, bx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallSSMetaRoutine	proc	near
	.enter	inherit	WriteDocumentContinuePrinting
						; ax holds the routine
	mov	bx, scrapLibraryHandle		; bx <- library handle
	call	ProcGetLibraryEntry		; bx.ax <- virtual routine

	mov	dx, ss				; dx:bp <- ptr to structure
	lea	bp, ssmetaData

	call	ProcCallFixedOrMovable		; Call the routine
	.leave
	ret
CallSSMetaRoutine	endp


DocMerge	ends
