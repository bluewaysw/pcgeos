COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosInitExit.asm

AUTHOR:		Adam de Boor, Mar 10, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/10/92		Initial revision


DESCRIPTION:
	Common initialization/exit code for DOS-based IFS drivers
		

	$Id: dosInitExit.asm,v 1.1 97/04/10 11:55:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;==============================================================================
;
;		       SECTOR BUFFER ALLOCATION
;
;==============================================================================

Init		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSAllocateSectorBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a fixed-memory sector buffer to hold a boot sector,
		making sure it doesn't cross a (linear) 64K boundary, as
		DMA cannot handle that...(the DMA page register can only
		address 64K at a time)

CALLED BY:	DRIInit
PASS:		ax	= size of buffer to allocate
RETURN:		ax	= segment of properly-aligned block
		bx	= handle of same
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSAllocateSectorBuffer	proc	far
		.enter
	;
	; Make initial attempt. If buffer crosseth not a 64K boundary,
	; we're happy.
	;
		call	MemGrabHeap	; snag in case called by format/copy
					;  code
		push	ax
		mov	cx, mask HF_FIXED or mask HF_SHARABLE
		mov	bx, handle 0
		call	MemAllocSetOwner
	;
	; See if starting segment and ending segment differ in the 12th
	; bit, as that's the one that indicates the 64K "page". If the thing
	; crosses a boundary, the test will be non-zero
	;
		pop	cx
		push	cx
		add	cx, 15		; convert to paragraphs, rounded up
		shr	cx
		shr	cx
		shr	cx
		shr	cx

		add	cx, ax		; cx <- ending segment
		xornf	cx, ax
		test	cx, 1 shl 12
		jz	done
	;
	; Sigh. Free the thing and allocate enough to get to the 64K boundary
	;
		neg	ax
		andnf	ax, 0xfff
		mov	cl, 4
		shl	ax, cl
		call	MemFree
		mov	cx, mask HF_FIXED
		mov	bx, handle 0
		call	MemAllocSetOwner
		pop	ax
		push	bx
	;
	; Now allocate the sector buffer itself.
	;
		mov	cx, mask HF_FIXED
		mov	bx, handle 0
		call	MemAllocSetOwner
	;
	; And free the aligning block.
	;
		pop	cx
		xchg	bx, cx
		call	MemFree
		mov	bx, cx
		jmp	exit
done:
		inc	sp	; discard buffer size
		inc	sp
exit:
		call	MemReleaseHeap
		.leave
		ret
DOSAllocateSectorBuffer	endp

;==============================================================================
;
;		CREATE HANDLES FOR ALREADY-OPEN FILES
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSInitOpenFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate all files in the open-file list that are on drives
		we manage and alter their private data and SFN to our
		liking.

CALLED BY:	DRIInit
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSInitOpenFiles proc	near
		.enter
		clr	bx			; process entire list
		mov	dx, ds:[fsdOffset]	; pass the offset of our
						;  FSDriver record
		mov	di, SEGMENT_CS
		mov	si, offset DIOF_callback
		call	FileForEach
		.leave
		ret
DOSInitOpenFiles endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIOF_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to initialize file handles that were
		opened with the skeleton FSD.

CALLED BY:	DOSInitOpenFiles via FileForEach
PASS:		ds:bx	= HandleFile
		dx	= offset of our FSDriver record
RETURN:		carry set to end processing
DESTROYED:	ax, cx, bp, di, si, es may all be nuked

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIOF_callback	proc	far
		.enter
	;
	; See if the file handle is on one of our drives by checking if the
	; DSE_fsd field of the drive of the disk the file is on matches our
	; own.
	; 
		call	FSDLockInfoShared
		mov	es, ax
		mov	si, ds:[bx].HF_disk
		tst	si		; device?
		jz	ours		; yes => our responsibility
		mov	si, es:[si].DD_drive
		cmp	es:[si].DSE_fsd, dx
ours:
		call	FSDUnlockInfoShared
		jne	done
		call	DOSInitTakeOverFile
		ornf	es:[si].DFE_flags, mask DFF_OURS
done:
		clc		; continue processing
		.leave
		ret
DIOF_callback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSInitTakeOverFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take over control of a file, either for ourselves or one
		of our seconds.

CALLED BY:	DIOF_callback, DR_DPFS_INIT_HANDLE
PASS:		ds:bx	= handle of file to take over
RETURN:		es:si	= private data for the file
DESTROYED:	ax, si, di, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSInitTakeOverFile proc far
		uses	dx
		.enter
	;
	; The skeleton driver always sets HF_private to be either 0 or -1, and
	; we never set it to either of those values, and no one but us or the
	; skeleton driver should ever have control of a file being taken over
	; this way, so we can just check for 0/-1 in HF_private to decide
	; whether we actually have to do anything.
	; 
		mov	ax, ds:[bx].HF_private
		inc	ax
		jz	fullTakeOver
		dec	ax
		jz	fullTakeOver
	;
	; We already took it over, so all data are properly established, both
	; in our own table and in the handle itself, with the exception of
	; the DFF_OURS flag, which we assume should be clear since we assume
	; we had control of the file first and are now giving it to some
	; other driver.
	; 
		mov_tr	si, ax
		segmov	es, dgroup, ax
		andnf	es:[si].DFE_flags, not mask DFF_OURS
		jmp	done
fullTakeOver:
		mov	al, ds:[bx].HF_sfn
		clr	ah
	;
	; Translate its SFN, which is just the DOS handle, to its real SFN,
	; freeing up that slot in the JFT.
	; 
		xchg	bx, ax
		call	DOSFreeDosHandleFar
		xchg	ax, bx
	;
	; XXX: what about networks that don't fill in SFT entries? SFN is
	; bullshit.
	; 
		mov	ds:[bx].HF_sfn, al
	;
	; Fill in our file-table entry. HF_private is non-zero if the
	; thing is a geos file.
	; 
		segmov	es, dgroup, si		; es <- dgroup
		clr	ah
if SEND_DOCUMENT_FCN_ONLY
			CheckHack <type dosFileTable eq 11>
		mov	si, ax
		shl	ax
		add	si, ax
		shl	ax, 2
		add	si, ax
else	; not SEND_DOCUMENT_FCN_ONLY
			CheckHack <type dosFileTable eq 10>
		shl	ax
		mov	si, ax
		shl	ax
		shl	ax
		add	si, ax
endif	; SEND_DOCUMENT_FCN_ONLY
		add	si, offset dosFileTable

		mov	es:[si].DFE_index, -1	; index
								;  not fetched
								;  yet
		mov	es:[si].DFE_attrs, 0
if SEND_DOCUMENT_FCN_ONLY
ifdef	GPC
	;
	; In Enhanced Mode, any file can be considered a document.  In that
	; case we set DFF_LIKELY_DOC even for files opened by skeleton driver.
	;
		mov	ax, mask DFF_LIKELY_DOC
			CheckHack <offset DFF_LIKELY_DOC ge 8>
		andnf	ah, es:[enhancedMode]	; bit set if Enhanced Mode
else	; not GPC
	;
	; Since the file was opened by the skeleton driver, it is probably
	; not a document.  So there's no need to set DFF_LIKELY_DOC.
	;
		clr	ax
endif	; GPC
		tst	ds:[bx].HF_private
		jz	setEntryFlags
		ornf	ax, mask DFF_GEOS
setEntryFlags:
		mov	es:[si].DFE_flags, ax

else	; not SEND_DOCUMENT_FCN_ONLY
		clr	al
		tst	ds:[bx].HF_private
		jz	setEntryFlags
		ornf	al, mask DFF_GEOS
setEntryFlags:
		mov	es:[si].DFE_flags, al
endif	; SEND_DOCUMENT_FCN_ONLY
		mov	ax, ds:[bx].HF_disk
		mov	es:[si].DFE_disk, ax
		mov	ds:[bx].HF_private, si

done:
		.leave
		ret
DOSInitTakeOverFile endp

;==============================================================================
;
;		       CODE PAGE INITIALIZATION
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSInitUseCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare a code page from the kernel for our own use.

CALLED BY:	EXTERNAL
PASS:		ax	= DOSCodePage to use
		ds 	= dgroup
RETURN:		nothing
DESTROYED:	bx, ax, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSInitUseCodePage proc	near
SBCS <		uses	ds, si, es, di					>
DBCS <		uses	di, es
		.enter

if DBCS_PCGEOS
	;
	; Get the code page to use
	;
		call	GetCodePage
		jnc	gotCodePage		;branch if supported
		mov	ax, CODE_PAGE_US	;ax <- default code page
gotCodePage:
		mov	ds:currentCodePage, ax
else
	;
	; Copy the code page into our own buffer.
	; 
		segmov	es, ds
		call	MemLock
		mov	ds, ax
		clr	si
		mov	di, offset dosCodePage
		mov	cx, size dosCodePage
		rep	movsb
		call	MemUnlock
		segmov	ds, es
	;
	; Now upcase everything in the LCP_to array.
	; 
		mov	bx, offset dosCodePage
			CheckHack <LCP_to eq 0x80>
		mov	di, offset LCP_to
		mov	cx, length LCP_to
upcaseLoop:
		mov	ax, di			; ax <- geos char
		call	LocalUpcaseChar		; al <- upcase version
		xlatb				; al <- DOS equivalent (maps
						;  upcase geos to upcase DOS
						;  through LCP_to, since
						;  LCP_to starts at 0x80)
		mov	({byte}ds:[dosCodePage])[di], al
						; store uppercase DOS equivalent
		inc	di
		loop	upcaseLoop
endif
		.leave
		ret
DOSInitUseCodePage endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSInitNullDevicePointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the pointer to the NULL device

CALLED BY:	MSInit, DRIInit, OS2Init

PASS:		ds - dgroup

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nullDeviceName	char	"NUL     "

DOSInitNullDevicePointer	proc near

		.enter

	;
	; Get the list of lists, and make sure the NUL device header
	; is where we think it is.
	;

		mov	ah, MSDOS_GET_DOS_TABLES
		call	DOSUtilInt21
		lea	di, es:[bx][DLOL_null]
if _MS3
	;
	; The List Of Lists for MSDOS 3.0 is slightly different.  Add
	; the difference between the 2 data structures
	;
		cmp	ds:[dosVersionMinor], 0
		jne	gotNullDevice
		add	di, offset (D3LOL_null - DLOL_null)
gotNullDevice:
endif

	;
	; Make sure that we actually have the NUL device, and we're
	; not just pointing off into space somewhere.  If this test
	; fails, then we leave the dosNullDevice pointer uninitialized
	; (ie, zero).
	;

		push	ds, di
		add	di, offset DH_name
		segmov	ds, cs, si
		mov	si, offset nullDeviceName
		mov	cx, DEVICE_NAME_SIZE/2
		repe	cmpsw
		pop	ds, di
		jne	done

		mov	ds:[dosNullDevice].segment, es
		mov	ds:[dosNullDevice].offset, di
done:
EC <		segmov	es, ds		; avoid ec +segment death	>
		.leave
		ret
DOSInitNullDevicePointer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSInitRecordDocPaths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the DOS paths which are used later to decide if file
		change notifications should be send for operations in a
		particular directory because the directory is likely to
		contain documents.

CALLED BY:	MSInit, OS2Init
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	2/11/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if SEND_DOCUMENT_FCN_ONLY

desktopDir	TCHAR	"DESKTOP"
nullDir		TCHAR	C_NULL
.assert	desktopDir + size desktopDir eq nullDir

DOSInitRecordDocPaths	proc	near
DBCS <	pathBuf	local	PathName					>
	uses	ds, es
	.enter
	pusha

ifdef	GPC
	;
	; If we're running in Enhanced Mode, we're not going to check paths
	; later, so there's no need to init document paths here.
	;
	tst	ds:[enhancedMode]
	jnz	done			; => Enhanced Mode
endif	; GPC

	;
	; First get SP_DOCUMENT.
	;
	clr	dx			; no drive name
	mov	bx, SP_DOCUMENT
if DBCS_PCGEOS
	segmov	es, ss
	lea	di, ss:[pathBuf]	; es:di = pathBuf
	mov	cx, size pathBuf
else
	segmov	es, ds			; es = dgroup
	mov	di, offset docPath	; es:di = docPath
	mov	cx, size docPath
endif	; DBCS_PCGEOS
	segmov	ds, cs
	mov	si, offset nullDir	; ds:si = nullDir
	call	FileConstructFullPath
if DBCS_PCGEOS
	mov	di, offset docPath
	call	copyDBCSToSBCS		; es:di = NULL
endif	; DBCS_PCGEOS
	sub	di, offset docPath + size char	; don't count leading '\' or
						;  null
	mov	es:[docPathLengthNoBS], di

	;
	; Then get SP_WASTE_BASKET.
	;
	mov	bx, SP_WASTE_BASKET
if DBCS_PCGEOS
	segmov	es, ss
	lea	di, ss:[pathBuf]	; es:di = pathBuf
else
	mov	di, offset wbPath	; es:di = wbPath
		CheckHack <size wbPath eq size docPath>
endif	; DBCS_PCGEOS
	call	FileConstructFullPath
if DBCS_PCGEOS
	mov	di, offset wbPath
	call	copyDBCSToSBCS		; es:di = NULL
endif	; DBCS_PCGEOS
	sub	di, offset wbPath + size char	; don't count leading '\' or
						;  null
	mov	es:[wbPathLengthNoBS], di

	;
	; Then get SP_APPLICATION.
	;
	mov	bx, SP_APPLICATION
if DBCS_PCGEOS
	segmov	es, ss
	lea	di, ss:[pathBuf]	; es:di = pathBuf
else
	mov	di, offset appPath	; es:di = appPath
		CheckHack <size appPath eq size docPath>
endif	; DBCS_PCGEOS
	call	FileConstructFullPath
if DBCS_PCGEOS
	mov	di, offset appPath
	call	copyDBCSToSBCS		; es:di = NULL
endif	; DBCS_PCGEOS
	sub	di, offset appPath + size char	; don't count leading '\' or
						;  null
	mov	es:[appPathLengthNoBS], di

	;
	; Then get SP_TOP\DESKTOP.
	;
	mov	bx, SP_TOP
if DBCS_PCGEOS
	segmov	es, ss
	lea	di, ss:[pathBuf]	; es:di = pathBuf
else
	mov	di, offset desktopPath	; es:di = desktopPath
		CheckHack <size desktopPath eq size docPath>
endif	; DBCS_PCGEOS
	mov	si, offset desktopDir	; ds:si = desktopDir
	call	FileConstructFullPath
if DBCS_PCGEOS
	mov	di, offset desktopPath
	call	copyDBCSToSBCS		; es:di = NULL
endif	; DBCS_PCGEOS
	sub	di, offset desktopPath + size char	; don't count leading
							; '\' or null
	segmov	ds, es			; ds = dgroup
	mov	ds:[desktopPathLengthNoBS], di

	mov	ds:[sysDiskHandle], bx
	call	DiskGetDrive		; al = drive #
	mov	ds:[sysDriveNum], al

done::
	popa
	.leave
	ret

if DBCS_PCGEOS
;
; Pass:		di	= offset of SBCS buffer in dgroup to copy to
;		pathBuf	= DBCS string to copy from
; Return:	es:di	= points at NULL in SBCS buffer
; Destroyed:	ax
;
copyDBCSToSBCS	label	near
	push	ds, si

	segmov	ds, ss
	lea	si, pathBuf
	segmov	es, dgroup		; es:di = dest

copyLoop:
	lodsw				; ax = DBCS char
	stosb				; store SBCS char
	tst	ax			; reached NULL?
	jnz	copyLoop		; => no, loop until NULL
	dec	di			; es:di points at NULL

	pop	ds, si
	retn
endif	; DBCS_PCGEOS

DOSInitRecordDocPaths	endp

ifdef	GPC


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSInitEnhancedModeFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read .INI file to determine if we are in Enhanced Mode.

CALLED BY:	MSInit, OS2Init
PASS:		ds	= dgroup
RETURN:		dgroup:[enhancedMode] initialized
DESTROYED:	ax, cx, dx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	11/19/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
enhancedModeCat	char	"fileManager", 0
enhancedModeKey	char	"debug", 0

DOSInitEnhancedModeFlag	proc	near

	push	ds			; save dgroup
	mov	cx, cs
	mov	dx, offset enhancedModeKey	; cx:dx = key
	mov	ds, cx
	mov	si, offset enhancedModeCat	; ds:si = cat
	clr	al				; al = BB_FALSE (default)
	call	InitFileReadBoolean	; al = value
	pop	ds			; ds = dgroup
	mov	ds:[enhancedMode], al

	ret
DOSInitEnhancedModeFlag	endp

endif	; GPC

endif	; SEND_DOCUMENT_FCN_ONLY

Init	ends
