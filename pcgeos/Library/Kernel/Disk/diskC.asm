COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Disk
FILE:		diskC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the geode routines

	$Id: diskC.asm,v 1.1 97/04/05 01:11:03 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_File	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskGetVolumeInfo

C DECLARATION:	extern word
		    DiskGetVolumeInfo(DiskHandle diskHan,
					DiskInfoStruct *info);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DISKGETVOLUMEINFO	proc	far
	C_GetThreeWordArgs	bx, cx, dx, ax	; cx <- seg, dx <- off, bx <- dh

	push	es, di
	mov	di, dx
	mov	es, cx
	call	DiskGetVolumeInfo
	pop	es, di

	GOTO_ECN	CStoreError

DISKGETVOLUMEINFO	endp


if FULL_EXECUTE_IN_PLACE
C_File	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskSetVolumeName

C DECLARATION:	extern word
			 DiskSetVolumeName(DiskHandle dh,
							const char *name);
			Note: "name" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DISKSETVOLUMENAME	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = dhan, ax = seg, cx = off

	push	si, ds
	mov	ds, ax
	mov	si, cx
	call	DiskSetVolumeName
	pop	si, ds

NOFXIP<	GOTO_ECN	CStoreError					>
FXIP<	call	CStoreError						>
FXIP<	ret								>
DISKSETVOLUMENAME	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_File	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskGetVolumeFreeSpace

C DECLARATION:	extern dword
			 DiskGetVolumeFreeSpace(DiskHandle dh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DISKGETVOLUMEFREESPACE	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	call	DiskGetVolumeFreeSpace
	mov	ss:[TPD_error], 0	; assume no error
	jnc	done
	mov	ss:[TPD_error], ax	; store error in TPD_error, too
done:
	ret

DISKGETVOLUMEFREESPACE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskCopy

C DECLARATION:	extern DiskCopyError
		    DiskCopy(word source, word dest,
				Boolean (*callback)(
						DiskCopyCallback code,
						DiskHandle disk,
						word param));
			Note: callback *must* be vfptr for XIP.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DISKCOPY	proc	far	source:word, dest:word, callback:fptr.far
realDS		local	sptr	\
		push	ds
	ForceRef	callback
	ForceRef	realDS	; used by callback
	.enter

if      FULL_EXECUTE_IN_PLACE
        ;
        ; Make sure the fptr passed in is valid
        ;
EC <    pushdw  bxsi                                            >
EC <    movdw   bxsi, callback                                  >
EC <    call    ECAssertValidFarPointerXIP                      >
EC <    popdw   bxsi                                            >
endif

	; TPD_error holds the offset of the address of the callback routine

	mov	ss:[TPD_error], bp

	mov	dh, source.low
	mov	dl, dest.low

	mov	cx, SEGMENT_CS
	mov	bp, offset _DISKCOPY_callback

	call	DiskCopy

	mov	ss:[TPD_error], ax

	.leave
	ret

DISKCOPY	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	_DISKCOPY_callback

DESCRIPTION:	Callback routine for DISKCOPY.  Call the real callback after
		pushing args on the stack

CALLED BY:	DiskCopy

PASS:
	ax - callbcak code
	bx - disk handle (sometimes)
	dl - drive number
	ss:[TPD_error] - inherited variables
	Note: callback which passes through stack *must* be vfptr for XIP.
RETURN:
	ax = 0 to continue, non-0 to abort

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
				Boolean (*callback)(
						DiskCopyCallback code,
						DiskHandle disk,
						word param));

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

_DISKCOPY_callback	proc	far	source:word, dest:word,
					callback:fptr.far
				uses bx, cx, dx, bp, ds
	ForceRef	source
	ForceRef	dest
realDS		local	sptr
	.enter inherit far

	push	bp
	mov	bp, ss:[TPD_error]

	push	ax			;push code
	push	bx			;push disk handle
	clr	dh
	push	dx			;push drive number

	mov	ax, callback.offset
	mov	bx, callback.segment
	mov	ds, realDS
	call	ProcCallFixedOrMovable

	pop	bp

	.leave
	ret

_DISKCOPY_callback	endp

if FULL_EXECUTE_IN_PLACE
C_File	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskFormat

C DECLARATION:	extern FormatError
		    DiskFormat(word driveNumber, MediaType media,
				word flags, dword *goodClusters,
				dword *badClusters, DiskHandle diskHandle,
				char *volumeName,
				Boolean (*callback)(word percentDone));
			NOTE: callback *must* be vfptr for XIP.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DISKFORMAT	proc	far	driveNumber:word, media:word,
				flags:word, goodClusters:fptr.dword,
				badClusters:fptr.dword, disk:word,
				volumeName:fptr.char, callback:fptr.far
						uses si, di, ds
	ForceRef	callback
realDS		local	sptr	\
		push	ds
	ForceRef	realDS	; used by callback
	.enter

	; TPD_error holds our frame pointer so _DISKFORMAT_callback can find
	; the callback routine.

	mov	ss:[TPD_error], bp

	mov	al, ss:[driveNumber].low
	mov	ah, ss:[media].low
	mov	bx, ss:[disk]
NOFXIP<	mov	cx, cs							>
FXIP<	mov	cx, vseg _DISKFORMAT_callback				>
	mov	dx, offset _DISKFORMAT_callback
	lds	si, ss:[volumeName]

	push	bp
	mov	bp, ss:[flags]
	call	DiskFormat
	pop	bp

	mov	ss:[TPD_error], ax

	mov	bx, si			;bx.di = good clusters
	lds	si, ss:[goodClusters]
	mov	ds:[si].high, bx
	mov	ds:[si].low, di
	lds	si, ss:[badClusters]
	mov	ds:[si].high, cx
	mov	ds:[si].low, dx

	jc	done			;if error, we're done
	CheckHack <FMT_DONE eq 0>
	clr	ax			;else return FMT_DONE
done:
	.leave
	ret

DISKFORMAT	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_File	segment	resource
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	_DISKFORMAT_callback

DESCRIPTION:	Callback routine for DISKFORMAT.  Call the real callback after
		pushing args on the stack

CALLED BY:	DiskCopy

PASS:
	ax - percentage done
	ss:[TPD_error] - inherited variables

RETURN:
	carry - set to cancel

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
				Boolean (*callback)(word percentDone));

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

_DISKFORMAT_callback	proc	far	driveNumber:word, media:word,
					callbackType:word,
					goodClusters:fptr.dword,
					badClusters:fptr.dword,
					callback:fptr.far
						uses bx, cx, dx, ds
realDS		local	sptr
	.enter inherit far

	push	bp
	mov	bp, ss:[TPD_error]

	push	ax			;push percentage done

	mov	ax, ss:[callback].offset
	mov	bx, ss:[callback].segment
	mov	ds, ss:[realDS]
	call	ProcCallFixedOrMovable

	pop	bp

	tst	ax
	jz	done
	stc				;ax = true, carry set to cancel
done:

	.leave
	ret

_DISKFORMAT_callback	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskRegisterDisk

C DECLARATION:	extern DiskHandle
			 DiskRegisterDisk(word driveNumber);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DISKREGISTERDISK	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = drive num

	call	DiskRegisterDisk
CRegisterCommon	label	far
	call	CStoreError
	mov_tr	ax, bx
	ret

DISKREGISTERDISK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskRegisterDiskSilently

C DECLARATION:	extern DiskHandle
		 DiskRegisterDiskSilently(word driveNumber);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DISKREGISTERDISKSILENTLY	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = drive num

	call	DiskRegisterDiskSilently
	jmp	CRegisterCommon

DISKREGISTERDISKSILENTLY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskGetDrive

C DECLARATION:	extern word
			 DiskGetDrive(DiskHandle disk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DISKGETDRIVE	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	call	DiskGetDrive
	clr	ah
	ret

DISKGETDRIVE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskGetVolumeName

C DECLARATION:	extern void
			 DiskGetVolumeName(DiskHandle disk,
							char *buffer);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DISKGETVOLUMENAME	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = dhan, ax = seg, cx = off

	push	di, es
	mov	es, ax
	mov	di, cx
	call	DiskGetVolumeName
	pop	di, es

	ret

DISKGETVOLUMENAME	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskFind

C DECLARATION:	extern DiskHandle
			 DiskFind(const char *fname,
				DiskFindResult *code);
			Note: "fname" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DISKFIND	proc	far	fname:fptr, dcode:fptr
				uses si, ds
	.enter

	lds	si, fname			; ds:si = filename
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
	call	DiskFind
	lds	si, dcode
	mov	ds:[si], ax

	mov_tr	ax, bx

	.leave
	ret

DISKFIND	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskCheckWritable

C DECLARATION:	extern Boolean
			 DiskCheckWritable(DiskHandle disk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DISKCHECKWRITABLE	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = disk handle

	call	DiskCheckWritableFar
	jmp	diskCBoolCommon

DISKCHECKWRITABLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskCheckInUse

C DECLARATION:	extern Boolean
			 DiskCheckInUse(DiskHandle disk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DISKCHECKINUSE	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = disk handle

	call	DiskCheckInUse
	jmp	diskCBoolCommon

DISKCHECKINUSE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskCheckUnnamed

C DECLARATION:	extern Boolean
			 DiskCheckUnnamed(DiskHandle disk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DISKCHECKUNNAMED	proc	far
		on_stack	retf
	C_GetOneWordArg	bx,   ax,cx	;bx = disk handle

	call	DiskCheckUnnamed

diskCBoolCommon	label	near
	mov	ax, 0
	jnc	done
	dec	ax
done:
	ret

DISKCHECKUNNAMED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskSave

C DECLARATION:	extern Boolean
			DiskSave(DiskHandle disk, void *buffer,
				word *bufSizePtr)
			Note : The fptrs *cannot* be pointing to the XIP 
				movable code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
DISKSAVE 	proc far disk:word, buffer:fptr, bufSizePtr:fptr.word
		uses	es, di
		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptrs passed in are valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, buffer					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, bufSizePtr				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	;
	; Load registers for call.
	; 
		mov	bx, ss:[disk]
		les	di, ss:[bufSizePtr]
		mov	cx, es:[di]
		les	di, ss:[buffer]
		call	DiskSave
	;
	; Store bytes used/bytes needed in *bufSizePtr
	; 
		les	di, ss:[bufSizePtr]
		mov	es:[di], cx
	;
	; Return FALSE if error, TRUE if ok
	; 
		mov	ax, 0
		jc	done
		dec	ax
done:
		.leave
		ret
DISKSAVE	endp
		
COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskRestore

C DECLARATION:	extern DiskHandle
			DiskRestore(void *buffer,
				DiskRestoreError
				    (*callback)(const char *driveName,
						const char *diskName
						void **bufferPtr,
						DiskRestoreError errorPtr));
			Note: The callback *must* be vfptr for XIP.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
DISKRESTORE	proc	far	buffer:fptr,
				callback:fptr.far
		uses	ds, si
		.enter
		lds	si, ss:[buffer]
		
		clr	cx			; assume no callback
		tst	ss:[callback].segment
		jz	doIt

		mov	cx, SEGMENT_CS
		mov	dx, offset _DISKRESTORE_callback
doIt:
		call	DiskRestore
		
		mov	ss:[TPD_error], 0	; assume ok
		jnc	done

		mov	ss:[TPD_error], ax	; set thread's error to the
						;  DiskRestoreError
		clr	ax			; and return a null handle
done:
		.leave
		ret
DISKRESTORE	endp
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_DISKRESTORE_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for DISKRESTORE to call the C callback
		function, if any. 

CALLED BY:	DISKRESTORE via DiskRestore
PASS:		ds:dx	= drive name (null-terminated with trailing ':')
		ds:di	= disk name (null-terminated)
		ds:si	= buffer to which the disk handle was saved with
			  DiskSave
		ax	= DiskRestoreError that would be returned if
			  callback weren't being called
		ss:bp	= frame inherited from DISKRESTORE
RETURN:		carry clear if disk should be in the drive:
			ds:si	= new position of buffer, if it moved
		carry set if user canceled the restore:
			ax	= error code to return
DESTROYED:	cx, dx, bx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_DISKRESTORE_callback proc far
		uses	es		; in case trashed by callback
		.enter	inherit	DISKRESTORE
		push	ds, dx		; drive name
		push	ds, di		; disk name
		lea	bx, ss:[buffer]
		push	ss, bx		; bufferPtr
		push	ax		; DiskRestoreError

		mov	bx, ss:[callback].segment
		mov	ax, ss:[callback].offset
		call	ProcCallFixedOrMovable

		lds	si, ss:[buffer]	; get new location of buffer

		tst	ax		; ok?
		jz	done		; yes (carry clear)
		stc			; no -- ax contains error code, but
					;  signal error
done:
		.leave
		ret
_DISKRESTORE_callback endp
		
COMMENT @----------------------------------------------------------------------

C FUNCTION:	DiskForEach

C DECLARATION:	extern DiskHandle	/*XXX*/
    			DiskForEach(Boolean (*callback) (DiskHandle disk));
			Note: callback *must* be vfptr for XIP.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
DISKFOREACH	proc	far	callback:fptr.far
		uses	di, si
		ForceRef callback
		.enter
		mov	di, SEGMENT_CS
		mov	si, offset _DISKFOREACH_callback
		call	DiskForEach
		mov_tr	ax, bx	; return final disk handle
		.leave
		ret
DISKFOREACH	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_DISKFOREACH_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the C callback for DISKFOREACH with this disk handle

CALLED BY:	DISKFOREACH via DiskForEach
PASS:		bx	= disk handle to process
		ss:bp	= frame inherited from DISKFOREACH
RETURN:		carry set to stop processing
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_DISKFOREACH_callback proc far
		uses	bx, es
		.enter	inherit DISKFOREACH
		
		push	bx
		mov	bx, ss:[callback].segment
		mov	ax, ss:[callback].offset
		call	ProcCallFixedOrMovable
		
		tst	ax
		jz	done
		stc
done:
		.leave
		ret
_DISKFOREACH_callback endp


C_File	ends

	SetDefaultConvention
