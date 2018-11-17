COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Startup app
FILE:		rstartupUtils.asm

AUTHOR:		Jason Ho, Aug 28, 1995

ROUTINES:
	Name				Description
	----				-----------
INT	DerefDgroupES			Return es = dgroup
INT	CallProcess			Call the message to process.
INT	RecursiveDeleteNear		rm -rf *
INT	RecursiveDeleteHandleDirectory	rm *, and call recursive for subdir.
INT	RStartupDisplayWithHighPriority	display a dialog with high
					priority
	
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		8/28/95   	Initial revision


DESCRIPTION:
	Utils for startup app.
		

	$Id: rstartupUtils.asm,v 1.1 97/04/04 16:52:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefDgroupES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets our dgroup into es.

CALLED BY:	INT
PASS:		nothing
RETURN:		es	= dgroup
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	reza	2/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
DerefDgroupES	-- not used -- proc	near
		uses	ax, bx
		.enter
		
		mov	bx, handle dgroup
		call	MemDerefES
EC <		mov	ax, es						>
EC <		call	ECCheckSegment					>

		.leave
		ret
DerefDgroupES	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallProcess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call process the message.

CALLED BY:	INTERNAL
PASS:		ax 	= Method to send to process
		cx, dx, bp = data to send on to process
RETURN:		carry	= whatever routine is.
DESTROYED:	whatever the message destroys
		ds  is NOT fixed. Do not depend on ds.
	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallProcess	proc	near
		uses	bx, si, di
		.enter
		call	GeodeGetProcessHandle
		clr	si
		mov	di, mask MF_CALL
		call	ObjMessage
		.leave
		ret
CallProcess	endp



if RSTARTUP_DO_LANGUAGE		;++++++++++++++++++++++++++++++++++++++++++

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecursiveDeleteNear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recursively delete all files starting from current directory

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	4/27/93    	Initial version
				in Library/Iclas/Init/initMain.asm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecursiveDeleteNear proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
		sub	sp, size FileEnumParams
		mov	bp, sp
		mov	ss:[bp].FEP_searchFlags, FILE_ENUM_ALL_FILE_TYPES \
			 or mask FESF_DIRS or mask FESF_REAL_SKIP
		movdw	ss:[bp].FEP_returnAttrs, FESRT_DOS_INFO
		mov	ss:[bp].FEP_returnSize, size FEDosInfo
		mov	ss:[bp].FEP_matchAttrs.segment, 0
		mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
		mov	ss:[bp].FEP_skipCount, 0
		call	FileEnum
		jc	done

		tst	bx				; any files in buffer
		jz	done
	
		call	RecursiveDeleteHandleDirectory
done:
		.leave
		ret
RecursiveDeleteNear endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecursiveDeleteHandleDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete files in current directory.
		Call RecursiveDeleteNear for any subdirectories.

CALLED BY:	RecursiveDeleteNear
PASS:		bx	= handle of buffer returned by FileEnum
		cx	= number of files returned in buffer
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di,bp,ds
SIDE EFFECTS:	Memory block is freed.

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	4/30/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecursiveDeleteHandleDirectory	proc	near
		call	MemLock
		push	bx
		mov	ds, ax
		clr	si

fileLoop:
	;
	; Do not delete non-local files
	;
		test	ds:[si].FEDI_pathInfo, mask DPI_EXISTS_LOCALLY
		jz	afterDelete

		test	ds:[si].FEDI_attributes, mask FA_VOLUME or \
			 mask FA_SYSTEM or  mask FA_RDONLY
		jnz	afterDelete

		lea	dx, ds:[si].FEDI_name		; ds:dx = filename

		test	ds:[si].FEDI_attributes, mask FA_SUBDIR
		jz	deleteFile

		test	ds:[si].FEDI_attributes, mask FA_LINK
		jnz	deleteFile
	;
	; Delete files in sub-directory
	;
		push	ds, dx, cx, si 
		call	FilePushDir
		clr	bx
		call	FileSetCurrentPath
		call	RecursiveDeleteNear
		call	FilePopDir
		pop	ds, dx, cx, si
	;
	; Delete directory
	;
		call	FileDeleteDir
		jmp	afterDelete

deleteFile:
		call	FileDelete

afterDelete:
		add	si, size FEDosInfo
		loop	fileLoop

		pop	bx
		call	MemFree
		ret
RecursiveDeleteHandleDirectory	endp

endif				; ++++++++++++ RSTARTUP_DO_LANGUAGE ++++++++


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupDisplayWithHighPriority
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just like FoamDisplayCommon that the priority
		is set differently (so that they will appear above
		startup's dialogs -- which have unusually high priority.)

CALLED BY:	INTERNAL
PASS:		^lcx:dx - optr of text to display.
		ax	- FoamCustomDialogBoxFlags
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	10/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RStartupDisplayWithHighPriority	proc	near
		uses	bp
		.enter
EC <		Assert_optr	cxdx					>
EC <		Assert	record, ax, FoamCustomDialogBoxFlags		>

		sub	sp, size FoamStandardDialogOptrParams
		mov	bp, sp
		mov	ss:[bp].FSDOP_customFlags, ax
		movdw	ss:[bp].FSDOP_bodyText, cxdx
		clr	ax			;none of these are passed
		mov	ss:[bp].FSDOP_titleText.handle, ax
		mov	ss:[bp].FSDOP_titleIconBitmap.handle, ax
		mov	ss:[bp].FSDOP_triggerTopText.handle, ax
		mov	ss:[bp].FSDOP_stringArg1.segment, ax
		mov	ss:[bp].FSDOP_stringArg2.segment, ax
		mov	ss:[bp].FSDOP_helpContext.segment, ax
		mov	ss:[bp].FSDOP_layerPriority, \
					RSTARTUP_POPUP_LAYER_PRIORITY
		call    FoamStandardDialogOptr  	;pass params on stack
		
		.leave
		ret
RStartupDisplayWithHighPriority	endp

CommonCode	ends
