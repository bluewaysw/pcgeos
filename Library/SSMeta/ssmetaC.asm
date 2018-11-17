
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 8/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial revision

DESCRIPTION:
		
	$Id: ssmetaC.asm,v 1.1 97/04/07 10:44:11 newdeal Exp $

-------------------------------------------------------------------------------@
	
	SetGeosConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETAINITFORSTORAGE

C DECLARATION:	extern void SSMetaInitForStorage(SSMetaStruc *ssmStruc,
			VMFileHandle vmFileHan,
			optr sourceID);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETAINITFORSTORAGE	proc	far	ssmetaStruc:fptr,
					vmFileHan:word,
					sourceID:optr
	.enter

	mov	bx, vmFileHan
	mov	ax, sourceID.high
	mov	cx, sourceID.low
	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaInitForStorage

	.leave
	ret
SSMETAINITFORSTORAGE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETAINITFORRETRIEVAL

C DECLARATION:	extern void SSMetaInitForRetrieval(SSMetaStruc *ssmStruc,
			VMFileHandle vmFileHan,
			word ssmHdr);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETAINITFORRETRIEVAL	proc	far	ssmetaStruc:fptr,
					vmFileHan:word,
					ssmHdr:word
	.enter

	mov	bx, vmFileHan
	mov	ax, ssmHdr
	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaInitForRetrieval

	.leave
	ret
SSMETAINITFORRETRIEVAL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETAINITFORCUTCOPY

C DECLARATION:	extern void SSMetaInitForCutCopy(SSMetaStruc *ssmStruc,
			ClipboardItemFlags flags,
			optr sourceID);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETAINITFORCUTCOPY	proc	far	ssmetaStruc:fptr,
					flags:ClipboardItemFlags,
					sourceID:optr
	.enter

	mov	bx, flags
	mov	ax, sourceID.high
	mov	cx, sourceID.low
	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaInitForCutCopy

	.leave
	ret
SSMETAINITFORCUTCOPY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADONEWITHCUTCOPY

C DECLARATION:	extern void SSMetaDoneWithCutCopy(SSMetaStruc *ssmStruc);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADONEWITHCUTCOPY	proc	far	ssmetaStruc:fptr
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaDoneWithCutCopy

	.leave
	ret
SSMETADONEWITHCUTCOPY	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADONEWITHCUTCOPYNOREGISTER

C DECLARATION:	extern void SSMetaDoneWithCutCopyNoRegister
							(SSMetaStruc *ssmStruc);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADONEWITHCUTCOPYNOREGISTER	proc	far	ssmetaStruc:fptr
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaDoneWithCutCopyNoRegister

	.leave
	ret
SSMETADONEWITHCUTCOPYNOREGISTER	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETAINITFORPASTE

C DECLARATION:	extern boolean
			SSMetaInitForPaste(SSMetaStruc *ssmStruc,
			ClipboardItemFlags flags);

Returns TRUE is spreadsheet clipboard item present.

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETAINITFORPASTE	proc	far	ssmetaStruc:fptr,
					flags:ClipboardItemFlags
	.enter

	mov	bx, flags
	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaInitForPaste
	mov	ax, 0			; set boolean return value
	jc	done			; carry => no item present
	dec	ax
done:
	.leave
	ret
SSMETAINITFORPASTE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADONEWITHPASTE

C DECLARATION:	extern void SSMetaInitForCutCopy(SSMetaStruc *ssmStruc);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADONEWITHPASTE	proc	far	ssmetaStruc:fptr
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaInitForCutCopy

	.leave
	ret
SSMETADONEWITHPASTE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETASETSCRAPSIZE

C DECLARATION:	extern void SSMetaSetScrapSize(SSMetaStruc *ssmStruc,
			word numCols,
			word numRows);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETASETSCRAPSIZE	proc	far	ssmetaStruc:fptr,
					numRows:word,
					numCols:word
	.enter

	mov	ax, numRows
	mov	cx, numCols
	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaSetScrapSize
	.leave
	ret
SSMETASETSCRAPSIZE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADATAARRAYLOCATEORADDENTRY

C DECLARATION:	extern boolean
			SSMetaDataArrayLocateOrAddEntry(SSMetaStruc *ssmStruc,
			word token,
			word entryDataSize,
			byte *entryData);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADATAARRAYLOCATEORADDENTRY	proc	far	ssmetaStruc:fptr,
						token:word,
						entryDataSize:word,
						entryData:fptr
	uses	ds,si
	.enter

	mov	ax, token
	mov	cx, entryDataSize
	lds	si, entryData
	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaDataArrayLocateOrAddEntry

	mov	ax, 0
	jc	done			; carry => entry added
	dec	ax			; else entry was located
done:
	.leave
	ret
SSMETADATAARRAYLOCATEORADDENTRY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADATAARRAYADDENTRY

C DECLARATION:	extern void
			SSMetaDataArrayAddEntry(SSMetaStruc *ssmStruc,
			word token,
			word entryDataSize,
			byte *entryData);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADATAARRAYADDENTRY	proc	far	ssmetaStruc:fptr,
					token:word,
					entryDataSize:word,
					entryData:fptr
	uses	ds,si
	.enter

	mov	ax, token
	mov	cx, entryDataSize
	lds	si, entryData
	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaDataArrayAddEntry
	.leave
	ret
SSMETADATAARRAYADDENTRY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETASEEIFSCRAPPRESENT

C DECLARATION:	extern boolean
			SSMetaSeeIfScrapPresent(ClipboardItemFlags flags);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETASEEIFSCRAPPRESENT	proc	far	flags:ClipboardItemFlags
	.enter

	mov	ax, ss:flags
	call	SSMetaSeeIfScrapPresent
	mov	ax, 1
	jc	done
	clr	ax
done:
	.leave
	ret
SSMETASEEIFSCRAPPRESENT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETAGETSCRAPSIZE

C DECLARATION:	extern void
			SSMetaGetScrapSize(SSMetaStruc *ssmStruc);

Return values differ from asm version. ASM version returns scrap size but these
can be gotten from the SSMetaStruc.

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETAGETSCRAPSIZE	proc	far	ssmetaStruc:fptr
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaGetScrapSize
	.leave
	ret
SSMETAGETSCRAPSIZE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADATAARRAYGETNUMENTRIES

C DECLARATION:	extern word
			SSMetaDataArrayGetNumEntries(SSMetaStruc *ssmStruc);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADATAARRAYGETNUMENTRIES	proc	far	ssmetaStruc:fptr
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaDataArrayGetNumEntries
	.leave
	ret
SSMETADATAARRAYGETNUMENTRIES	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADATAARRAYRESETENTRYPOINTER

C DECLARATION:	extern void
			SSMetaDataArrayResetEntryPointer(SSMetaStruc *ssmStruc);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADATAARRAYRESETENTRYPOINTER	proc	far	ssmetaStruc:fptr
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaDataArrayResetEntryPointer
	.leave
	ret
SSMETADATAARRAYRESETENTRYPOINTER	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADATAARRAYGETFIRSTENTRY

C DECLARATION:	extern *SSMetaDataEntry
			SSMetaDataArrayGetFirstEntry(SSMetaStruc *ssmStruc);

Return values differ from asm version. ASM version returns size as well but
the size can be gotten from SSMetaStruc. Also, return value can be NULL to
indicate no first entry. (ASM version uses the carry flag).

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADATAARRAYGETFIRSTENTRY	proc	far	ssmetaStruc:fptr
	uses	ds,si
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaDataArrayGetFirstEntry
	mov	dx, ds
	mov	ax, si
	jnc	done
	clr	ax,dx
done:
	.leave
	ret
SSMETADATAARRAYGETFIRSTENTRY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADATAARRAYGETNEXTENTRY

C DECLARATION:	extern *SSMetaDataEntry
			SSMetaDataArrayGetNextEntry(SSMetaStruc *ssmStruc);

Return values differ from asm version. ASM version returns size as well but
the size can be gotten from SSMetaStruc. Also, return value can be NULL
to indicate no next entry. (ASM version uses the carry flag).

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADATAARRAYGETNEXTENTRY	proc	far	ssmetaStruc:fptr
	uses	ds,si
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaDataArrayGetNextEntry

	mov	dx, ds
	mov	ax, si
	jnc	done
	clr	ax,dx
done:
	.leave
	ret
SSMETADATAARRAYGETNEXTENTRY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADATAARRAYGETENTRYBYTOKEN

C DECLARATION:	extern *SSMetaDataEntry
			SSMetaDataArrayGetEntryByToken(SSMetaStruc *ssmStruc,
			word token);

Return values differ from asm version. ASM version returns size as well but
the size can be gotten from SSMetaStruc. Also, return value can be NULL
to indicate no entry. (ASM version uses the carry flag).

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADATAARRAYGETENTRYBYTOKEN	proc	far	ssmetaStruc:fptr,
						token:word
	uses	ds,si
	.enter

	mov	ax, token
	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaDataArrayGetEntryByToken

	mov	dx, ds
	mov	ax, si
	jnc	done
	clr	ax,dx
done:
	.leave
	ret
SSMETADATAARRAYGETENTRYBYTOKEN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADATAARRAYGETENTRYBYCOORD

C DECLARATION:	extern *SSMetaDataEntry
			SSMetaDataArrayGetEntryByCoord(SSMetaStruc *ssmStruc);

Return values differ from asm version. ASM version returns size as well but
the size can be gotten from SSMetaStruc. Also, return value can be NULL
to indicate no entry. (ASM version uses the carry flag).

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADATAARRAYGETENTRYBYCOORD	proc	far	ssmetaStruc:fptr
	uses	ds, si
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaDataArrayGetEntryByCoord

	mov	dx, ds
	mov	ax, si
	jnc	done
	clr	ax,dx
done:
	.leave
	ret
SSMETADATAARRAYGETENTRYBYCOORD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADATAARRAYGETNTHENTRY

C DECLARATION:	extern void SSMetaDataArrayGetNthEntry(SSMetaStruc *ssmStruc,
			word N);

Return values differ from asm version. ASM version returns size as well but
the size can be gotten from SSMetaStruc. Also, return value can be NULL
to indicate no entry. (ASM version uses the carry flag).

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADATAARRAYGETNTHENTRY	proc	far	ssmetaStruc:fptr
	uses	ds,si
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaDataArrayGetNthEntry

	mov	dx, ds
	mov	ax, si
	jnc	done
	clr	ax,dx
done:
	.leave
	ret
SSMETADATAARRAYGETNTHENTRY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADATAARRAYUNLOCK

C DECLARATION:	extern void SSMetaDataArrayUnlock(SSMetaStruc *ssmStruc);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADATAARRAYUNLOCK	proc	far	ssmetaStruc:fptr
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaDataArrayUnlock

	.leave
	ret
SSMETADATAARRAYUNLOCK	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETAGETNUMBEROFDATARECORDS

C DECLARATION:	extern word 
		       SSMetaGetNumberOfDataRecords(SSMetaStruc *ssmStruc);
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETAGETNUMBEROFDATARECORDS	proc	far	ssmetaStruc:fptr
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaGetNumberOfDataRecords

	.leave
	ret
SSMETAGETNUMBEROFDATARECORDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETARESETFORDATARECORDS

C DECLARATION:	extern void SSMetaResetForDataRecords(SSMetaStruc *ssmStruc);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETARESETFORDATARECORDS	proc	far	ssmetaStruc:fptr
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaResetForDataRecords

	.leave
	ret
SSMETARESETFORDATARECORDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETAFIELDNAMELOCK

C DECLARATION:	extern *char
		SSMetaFieldNameLock(SSMetaStruc *ssmStruc, 
				    word *mHandle, 
				    word *dataLength);
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETAFIELDNAMELOCK	proc	far	ssmetaStruc:fptr,
					mHandle:fptr,
					dataLength:fptr
	uses ds, es, si, di
	.enter

	push	bp
	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaFieldNameLock
	pop	bp
	jc	noField

	les	di, dataLength
	stosw	
	les	di, mHandle
	mov_tr  ax, bx
	stosw
	mov	dx, ds
	mov	ax, si
	jnc	done
noField:
	clr	ax,dx
done:
	.leave
	ret
SSMETAFIELDNAMELOCK	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADATARECORDFIELDLOCK

C DECLARATION:	extern *char
		SSMetaDataRecordFieldLock(SSMetaStruc *ssmStruc, 
				    word *mHandle, 
				    word *dataLength);
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADATARECORDFIELDLOCK	proc	far	ssmetaStruc:fptr,
						mHandle:fptr,
						dataLength:fptr
	uses ds, es, si, di
	.enter

	push	bp
	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	call	SSMetaDataRecordFieldLock
	pop	bp
	jc	noField

	les	di, dataLength
	stosw	
	les	di, mHandle
	mov_tr  ax, bx
	stosw
	mov	dx, ds
	mov	ax, si
	jnc	done
noField:
	clr	ax,dx
done:
	.leave
	ret
SSMETADATARECORDFIELDLOCK	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETAFIELDNAMEUNLOCK

C DECLARATION:	extern void SSMetaFieldNameUnlock(SSMetaStruc *ssmStruc,
						  word mHandle);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETAFIELDNAMEUNLOCK	proc	far	ssmetaStruc:fptr,
					mHandle:word
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	mov	bx, mHandle
	call	SSMetaFieldNameUnlock

	.leave
	ret
SSMETAFIELDNAMEUNLOCK	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETADATARECORDFIELDUNLOCK

C DECLARATION:	extern void SSMetaDataRecordFieldUnlock(SSMetaStruc *ssmStruc,
						  	word mHandle);
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETADATARECORDFIELDUNLOCK	proc	far	ssmetaStruc:fptr,
						mHandle:word
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	mov	bx, mHandle
	call	SSMetaDataArrayUnlock

	.leave
	ret
SSMETADATARECORDFIELDUNLOCK	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
C FUNCTION:	SSMETAFORMATCELLTEXT

C DECLARATION:	extern *char
		SSMetaFormatCellText(SSMetaStruc *ssmStruc, 
					 word *mHandle,
				    word *dataLength);
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	2/1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMETAFORMATCELLTEXT	proc	far	ssmetaStruc:fptr,
					mHandle:word,
					dataLength:fptr
	.enter

	mov	dx, ssmetaStruc.high
	mov	bp, ssmetaStruc.low
	mov	bx, mHandle
	call	SSMetaFormatCellText
	jc	noField

	les	di, dataLength
	stosw	
	les	di, mHandle
	mov_tr  ax, bx
	stosw
	mov	dx, ds
	mov	ax, si
	jnc	done
noField:
	clr	ax,dx
done:
	.leave
	ret
SSMETAFORMATCELLTEXT	endp

	SetDefaultConvention
