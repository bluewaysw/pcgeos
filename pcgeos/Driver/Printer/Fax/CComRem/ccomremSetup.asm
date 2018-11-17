COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer/Fax/CCom
FILE:		ccomSetup.asm

AUTHOR:		Don Reeves, May 2, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/02/91		Initial revision

DESCRIPTION:
	Miscellaneous routines that are called to initialize and clean up
	after print jobd

	$Id: ccomremSetup.asm,v 1.1 97/04/18 11:52:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do pre-job initialization

CALLED BY:	GLOBAL

PASS:		BP	= segment of locked PState
		
RETURN:		carry	= set if some communication problem

DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/90		Initial version
	Don	04/91		Incorporated CCom calls

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintStartJob	proc	far
		mov	bx, bp				; PState => BX
		uses	ax, bx, cx, dx, si, di, es, ds
		.enter
	;
	; initialize some info in the PState
	;
		ForceRef cff
		mov	ds, bx				; PState => DS:0
		clr	ax
		mov	ds:[PS_asciiSpacing], 12	; set to 1/6th inch
		mov	ds:[PS_asciiStyle], ax		; set to plain text
		mov	ds:[PS_cursorPos].P_x, ax	; set to 0,0 text
		mov	ds:[PS_cursorPos].P_y, ax

	;
	; Set the paper input/output params from the device info
	;
		
		mov	bx, ds:[PS_deviceInfo]
		call	MemLock
		mov	es, ax

		CheckHack <offset PI_paperOutput eq offset PI_paperInput+1>

		mov	ax, {word} es:[PI_paperInput]
		call	MemUnlock

		push	bp
		mov	bp, ds
		call	PrintSetPaperPath
		pop	bp
		
	;
	; Store the JobParameters in the status file.
	; 
		call	OpenStatusFile	; returns with exclusive access
		jc	done
		call	StoreJobParams	; ax <- VM block handle
	;
	; Copy the spool file (yurg).
	; 
		call	CopySpool
		call	FilePopDir
		jc	done
	;
	; Put the thing in the queue.
	; 
		call	AddToQueue
	;
	; Let the remote spooler do its thing.
	; 
		call	VMReleaseExclusive
		clr	al
		call	VMClose
done:
		.leave
		ret
PrintStartJob	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenStatusFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the Queue Status file in the remote spool directory and
		return it for exclusive access.

CALLED BY:	(INTERNAL) PrintStartJob
PASS:		ds	= PState
RETURN:		carry set on error
			ax	= FileError/VMStatus
		carry clear if ok
			bx	= handle of VM file
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
serverDirKeyString	char	'serverDir', 0
statusFileName		char	'Queue Status', 0
OpenStatusFile 	proc	near
remDir		local	PathName
category	local	MAX_INITFILE_CATEGORY_LENGTH dup(char)
		uses	cx, dx, si, di, es, ds
		.enter
	;
	; Determine the category that holds the server directory.
	; 
		mov	al, ({JobParamData}ds:PS_jobParams.JP_printerData).JPD_server
		clr	ah
		segmov	ds, cs, cx
			.assert	@CurSeg eq segment printerCatString
		mov	si, offset printerCatString
		mov	dx, offset faxServerKeyString
		segmov	es, ss
		lea	di, ss:[category]
		push	bp
		mov	bp, (IFCC_INTACT shl offset IFRF_CHAR_CONVERT) or \
				(size category shl offset IFRF_SIZE)
		call	InitFileReadStringSection
		pop	bp
	;
	; Fetch the server directory.
	; 
		segmov	ds, ss
		mov	si, di
		mov	cx, cs
		mov	dx, offset serverDirKeyString
		lea	di, ss:[remDir]
		push	bp
		mov	bp, (IFCC_INTACT shl offset IFRF_CHAR_CONVERT) or \
				(size remDir shl offset IFRF_SIZE)
		call	InitFileReadString
		pop	bp
		jc	done
	;
	; Push to the server directory.
	; 
		segmov	ds, es
		mov	dx, di
		call	FilePushDir
		clr	bx
		call	FileSetCurrentPath
		jc	popDirDone
	;
	; Open the queue file, creating it if necessary.
	; 
		segmov	ds, cs
		mov	dx, offset statusFileName
		mov	ax, (VMO_CREATE	shl 8) or \
				mask VMAF_FORCE_READ_WRITE or \
				mask VMAF_FORCE_SHARED_MULTIPLE
		clr	cx
		call	VMOpen
		jc	popDirDone
	;
	; Gain exclusive access to the queue file.
	; 
		mov	ax, VMO_WRITE
		clr	cx
		call	VMGrabExclusive
done:
		.leave
		ret

popDirDone:
		call	FilePopDir
		jmp	done
OpenStatusFile endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreJobParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the JobParameters into a block attached to the VM file

CALLED BY:	(INTERNAL) PrintStartJob
PASS:		ds	= PState
		bx	= VM handle
RETURN:		ax	= VM block handle of parameters
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreJobParams	proc	near
		uses	cx, dx, ds, si, di, es, bp
		.enter
	;
	; Allocate a block to hold the JobParameters
	; 
		mov	cx, ds:[PS_jobParams].JP_size
		clr	ax		; uid == 0 => no next
		call	VMAlloc
		push	ax
	;
	; Copy the existing ones into the block
	; 
		call	VMLock
		mov	es, ax
		clr	di
		mov	si, offset PS_jobParams
		mov	cx, ds:[PS_jobParams].JP_size
		rep	movsb
		
		; sign-extend coverSheet into server so params all ready for
		; ccom
		mov	al, ({JobParamData}es:[JP_printerData]).JPD_coverSheet
		mov	({JobParamData}es:[JP_printerData]).JPD_server, al
	;
	; Change the JP_fname to the one we're going to use (formed from the
	; VM block handle)
	; 
		mov	di, offset JP_fname
		clr	dx
		pop	ax		; ax <- block handle
		push	ax
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii
	;
	; Dirty the block, unlock it, and we're done.
	; 
		call	VMDirty
		call	VMUnlock
		
		pop	ax
		
		.leave
		ret
StoreJobParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopySpool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the spool file to the remote directory.

CALLED BY:	(INTERNAL) PrintStartJob
PASS:		ds	= PState
		bx	= VM file handle
		ax	= VM block handle of params
		current dir set to remote spool directory
RETURN:		carry set if couldn't copy
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopySpool	proc	near
		uses	ax, cx, dx, si, di, es, bp
		.enter
		
		mov	si, offset PS_jobParams.JP_fname
		mov	cx, SP_SPOOL
		push	ax
		call	VMLock
		mov	es, ax
		mov	di, offset JP_fname
		clr	dx
		call	FileCopy
		call	VMUnlock
		pop	ax
		jc	nogood
done:
		.leave
		ret
nogood:
		call	VMFree
		call	VMReleaseExclusive
		clr	ax
		call	VMClose
		stc
		jmp	done
CopySpool	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddToQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the allocated JobParameters block to the end of the
		current queue within the Queue Status file for the server.

CALLED BY:	(INTERNAL) PrintStartJob
PASS:		bx	= VM file
		ax	= VM block handle
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	map block for file may change

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddToQueue	proc	near
		uses	es, bp, cx, di
		.enter
		push	ax
		call	VMGetMapBlock
		tst	ax
		jnz	addToEnd
	;
	; No map block => no queue, so make this the head of the queue.
	; 
		pop	ax
		call	VMSetMapBlock
done:
		.leave
		ret
addToEnd:
	;
	; Locate the last block in the queue.
	; 
		push	ax
		call	VMInfo
		pop	ax
		tst	di
		jz	hitEnd
		mov_tr	ax, di
		jmp	addToEnd
hitEnd:
	;
	; Set our block as the next block following the last block.
	; 
		pop	cx		; cx <- new uid
		call	VMModifyUserID
		jmp	done
		
AddToQueue	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do post-job cleanup

CALLED BY:	GLOBAL

PASS:		BP	- segment of locked PState
		
RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintEndJob	proc	far
		.enter
		clc
		.leave
		ret
PrintEndJob	endp



