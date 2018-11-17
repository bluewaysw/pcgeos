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

	$Id: ccomSetup.asm,v 1.1 97/04/18 11:52:34 newdeal Exp $

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
cff		local	CFFrame
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
	; Allocate a block for a CFFrame.
	;
		mov	ax, size CFFrame
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		mov	ds:[PS_expansionInfo], bx	; store CFFrame handle
		mov	es, ax				; es = CFFrame segment
	;
	; Write info (coverSheet status and phone #) from JobParameters
	; to CFFrame.  ds:si points to 30 bytes (15 words) and we luck out
	; because the CFF_coverSheet and CFF_phoneNum fields are adjacent
	; so we can just write it all out at once.
	;
		lea	si, ds:[PS_jobParams].JP_printerData
		mov	di, offset CFF_coverSheet
		mov	cx, (size CFF_coverSheet + size CFF_phoneNum) / 2
		ECRepMovsw
		call	MemUnlock		; we're done transfering info
	;
	; Put address of JobParameters into es:si to make the following calls
	; happy.
	;
		segmov	es, ds
		lea	si, es:[PS_jobParams]
		call	ConvertCFFrameToStack		; move frame onto stack
		call	InitializeCFFrame		; initialize the frame
		jc	done				; if errror, abort
	;
	; Initialize specific CCom things
	;
		call	ConvertStartJob			; preserves BP
		call	ConvertStackToCFFrame		; write back to block
done:
		.leave
		ret
PrintStartJob	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeCFFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the CFFrame for this print job

CALLED BY:	PrintStartJob
	
PASS:		SS:BP	= Local variables
		ES:SI	= JobParameters

RETURN:		Carry	= Set if error
			= Clear if OK

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeCFFrame	proc	near
cff		local	CFFrame
		uses	cx, di, si, ds, es
		.enter	inherit
	;
	; Copy the initial frame into our stack frame
	;
		push	es, si
		segmov	ds, dgroup, cx
		mov	si, offset faxFileHeader
		segmov	es, ss
		lea	di, ss:[cff.CFF_faxFileHeader]
		mov	cx, faxFrameSize
		ECRepMovsb
	;
	; Allocate a a conversion buffer
	;
		mov	ax, CONVERT_BUFFER_SIZE
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		mov	ss:[cff.CFF_outBufHan], bx
		mov	ss:[cff.CFF_outBufSeg], ax
		pop	es, si
		jc	exit			; fail if allocation fails
	;
	; Now copy values we need from JobParameters to our stack frame
	;
		cmp	es:[si].JP_printMode, PM_GRAPHICS_HI_RES
		jne	getPages		; not "fine", so use standard
		mov	ss:[cff.CFF_faxFileHeader.FFH_resolution], 2
getPages:
		mov	ax, es:[si].JP_numPages
		cmp	ss:[cff.CFF_coverSheet], TRUE
		jne	storePages
		inc	ax
storePages:
		mov	ss:[cff.CFF_numPages], ax
		mov	es:[si].JP_numPages, ax
		clc
exit:
		.leave
		ret
InitializeCFFrame	endp


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
		mov	bx, bp
cff		local	CFFrame
		uses	ax, ds
		.enter
	;
	; Initialize specific CCom things
	;
		ForceRef cff
		mov	ds, bx
		call	ConvertCFFrameToStack
		call	ConvertEndJob
		call	CComEndJob
	;
	; Free CFFrame block
	;
		mov	bx, ds:[PS_expansionInfo]
		call	MemFree

		.leave
		ret
PrintEndJob	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CComEndJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after the print job

CALLED BY:	GLOBAL
	
PASS:		SS:BP	= Local variables

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CComEndJob	proc	near
cff		local	CFFrame
		uses	bx
		.enter	inherit

		mov	bx, ss:[cff.CFF_outBufHan]
		call	MemFree

		.leave
		ret
CComEndJob	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertCFFrameToStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the variable record CFFrame contained in a memory
		block pointed to by the PState to local variables on stack

CALLED BY:	INNTERNAL
	
PASS:		DS	= PState
		SS:BP	= Local variables

RETURN:		Nothing

DESTROYED:	Nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertCFFrameToStack	proc	near
cff		local	CFFrame
		uses	ax, bx, cx, di, si, ds, es
		.enter	inherit
	;
	; Just copy information onto the stack
	;
		pushf
		mov	bx, ds:[PS_expansionInfo]
		call	MemLock
		mov	ds, ax
		clr	si
		segmov	es, ss
		lea	di, cff
		mov	cx, size CFFrame
		ECRepMovsb
		call	MemUnlock
		popf
			
		.leave
		ret
ConvertCFFrameToStack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertStackToCFFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the variable record CFFrame from the stack back into
		the memory block pointer to by the PState

CALLED BY:	INTERNAL
	
PASS:		DS	= PState
		SS:BP	= Local variables

RETURN:		Nothing

DESTROYED:	Nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertStackToCFFrame	proc	near
cff		local	CFFrame
		uses	ax, bx, cx, di, si, ds, es
		.enter	inherit
	;
	; Just copy information from stack back to CFFrame struct
	;
		pushf
		mov	bx, ds:[PS_expansionInfo]
		call	MemLock
		mov	es, ax
		clr	di
		segmov	ds, ss
		lea	si, cff
		mov	cx, size CFFrame
		ECRepMovsb
		call	MemUnlock
		popf
			
		.leave
		ret
ConvertStackToCFFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertStartJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the process of converting the print job to a fax

CALLED BY:	PrintStartJob

PASS:		SS:BP	= Local variables

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/91		Initial version
	don	5/02/91		Made into printer dirver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
faxDirBufferSize	= (size FRA_faxDir + 1)

ConvertStartJob	proc	near
cff		local	CFFrame
		uses	ax, bx, cx, dx, di, si, ds, es
		.enter	inherit | ForceRef cff

	;
	; Set our current directory to the fax directory.
	;
		segmov	ds, dgroup, ax
		mov	ds, ds:[faxDataArea]
		mov	si, offset FRA_faxDir
		lodsw
		sub	al, 'A'

	;
	; Preserve DS, so that segment error-checking doesn't mistreat
	; this segment.
	;
		
EC <		push	ds			>
		call	DiskRegisterDisk	; need a disk handle for it
EC <		pop	ds			>
		
		
		; Sigh. CCom stores the path with a trailing \ to make
		; appending files to it easier. Sadly, changing to
		; \CC\ doesn't work, so we must copy the path onto the
		; stack and abuse the thing to trim any trailing \
		; from it.

		mov	cx, faxDirBufferSize
		sub	sp, cx
		segmov	es, ss
		mov	di, sp
pathCopyLoop:
		lodsb
		ECStosb
		tst	al
		loopne	pathCopyLoop
		cmp	{char}es:[di-2], '\\'
		jne	changeDir
		mov	{char}es:[di-2], al
changeDir:
		mov	dx, sp
		segmov	ds, ss			; ds:dx <- path w/o
						; drive letter
		call	FilePushDir		; popped in EndJob...
		call	FileSetCurrentPath
		add	sp, faxDirBufferSize
	;
	; Create the administrative files required by the background fax
	; spooler.
	;
		call	ConvertCreateAdmin

		.leave
		ret
ConvertStartJob	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertEndJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End the process of converting a print job to a fax

CALLED BY:	PrintEndJob
	
PASS:		SS:BP	= Local variables

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/02/91		Initial version
	Don	5/02/91		Made into a printer driver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertEndJob	proc	near
cff		local	CFFrame
		uses	ax, bx, cx, dx, di, si, bp, ds, es
		.enter	inherit

	;
	; Finally, tell the background spooler to ship the beast. It will
	; clean up the stuff needed to send the fax from its perspective.
	;
		call	ConvertShipIt
		jnc	done
	;
	; If unsuccessful, delete all the pages we just created
	;
		segmov	ds, ss
		lea	dx, ss:[cff.CFF_convertFileEntry].CFE_fileName
delPageLoop:
		call	FileDelete
	;
	; Reduce the three-digit suffix by one and loop.
	;
		mov	si, 11
decLoop:
		mov	al, ss:[cff.CFF_convertFileEntry].CFE_fileName[si]
		dec	al
		mov	ss:[cff.CFF_convertFileEntry].CFE_fileName[si], al
		cmp	al, '0'-1		; did we wrap?
		jne	delPageLoop		; no -- try this one.

		mov	al, '9'			; wrap correctly
		mov	ss:[cff.CFF_convertFileEntry].CFE_fileName[si], al
		dec	si			; borrow from next higher digit
		cmp	si, 8			; back to 999?
		jne	decLoop			; nope -- keep going
	;
	; Delete the administrative files for the fax spooler.
	;
		call	ConvertDeleteAdmin
done:
		call	FilePopDir
		.leave
		ret
ConvertEndJob	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertCreateAdmin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open and initialize the administrative files for this
		job.

CALLED BY:	ConvertStartJob

PASS:		frame inherited from ConvertStartJob
		es - stack segment, apparently...

RETURN:		CFF_adminFileName holds name of S#~ file used.
		cfe.CFE_fileName holds filename for first converted page

DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
seqFile		char	'OUT#FAX.CFX', 0	; file holding next sequence
						;  number for faxes

ConvertCreateAdmin proc	near
cff		local	CFFrame
		uses	ds, es
		.enter	inherit

		clr	bx
		mov	ss:[cff.CFF_sequenceNum].low, bx ; assume no seqFile
		mov	ss:[cff.CFF_sequenceNum].high, bx

		segmov	ds, cs
		mov	dx, offset seqFile
		mov	ax, (FILE_CREATE_NO_TRUNCATE or \
				mask FCF_NATIVE) shl 8 or \
				FileAccessFlags <FE_EXCLUSIVE, FA_READ_WRITE>
		mov	cx, FILE_ATTR_NORMAL
		call	FileCreate
LONG		jc 	done

		xchg	bx, ax		; bx <- file handle
		segmov	ds, ss
		lea	dx, ss:[cff.CFF_sequenceNum]
		mov	cx, size CFF_sequenceNum
		clr	al
		call	FileRead

	;
	; Create initial file name template using the sequence number
	; we just got.
	;
		mov	{word}ss:[cff.CFF_adminFileName], 'S' or ('#' shl 8)
		mov	{char}ss:[cff.CFF_adminFileName][2], '~'
		mov	{word}ss:[cff.CFF_adminFileName][8], '.' or ('C' shl 8)
		mov	{word}ss:[cff.CFF_adminFileName][10], 'F' or ('X' shl 8)
		mov	{char}ss:[cff.CFF_adminFileName][12], 0

		mov	ax, ss:[cff.CFF_sequenceNum].low
		mov	ss:[cff.CFF_sequenceStart], ax
tryNumber:
	;
	; This is brain-dead coding, here. We need a five-digit ascii
	; representation of the current sequence number with leading zeroes.
	; Rather than do the rippling addition of ascii numbers, I'm just
	; going to reconvert the number each time. It's a hack, but it'll
	; work.
	;
		cwd
		mov	cx, 10000
		div	cx
		add	al, '0'		; ten-thousand's digit...
		mov	ss:[cff.CFF_adminFileName][3], al
		xchg	ax, dx

		cwd
		mov	cx, 1000
		div	cx
		add	al, '0'		; thousand's digit...
		mov	ss:[cff.CFF_adminFileName][4], al
		xchg	ax, dx

		cwd
		mov	cx, 100
		div	cx
		add	al, '0'		; hundred's digit...
		mov	ss:[cff.CFF_adminFileName][5], al
		xchg	ax, dx

		cwd
		mov	cx, 10
		div	cx
		add	al, '0'		; ten's digit...
		mov	ss:[cff.CFF_adminFileName][6], al
		xchg	ax, dx
		
		add	al, '0'		; one's digit...
		mov	ss:[cff.CFF_adminFileName][7], al

	;
	; Now try and create the initial administrative file.
	;
		lea	dx, ss:[cff.CFF_adminFileName]
		mov	ax, ((FILE_CREATE_ONLY or mask FCF_NATIVE) shl 8) or \
				FileAccessFlags <FE_EXCLUSIVE, FA_WRITE_ONLY>
		mov	cx, FILE_ATTR_NORMAL
		call	FileCreate
		jnc	haveFile
	;
	; Oops. Try the next sequence number...it must wrap at 32768...
	; XXX: look for out-of-disk-space error.
	;
		mov	ax, ss:[cff.CFF_sequenceNum].low
		inc	ax
		jns	checkWrap
		clr	ax
checkWrap:
		mov	ss:[cff.CFF_sequenceNum].low, ax
		cmp	ax, ss:[cff.CFF_sequenceStart]
		jne	tryNumber

		call	writeNewSequence
		stc
		jmp	done

haveFile:
	;
	; Now write the next available sequence number to the sequence file.
	;
		inc	ss:[cff.CFF_sequenceNum].low
		jns	18$
		mov	ss:[cff.CFF_sequenceNum].low, 0
18$:
		push	ax
		call	writeNewSequence
		pop	ss:[cff.CFF_sendFileHan]

	;
	; Open the C#~ file and save its handle away.
	;
		mov	ss:[cff.CFF_adminFileName], 'C'
		lea	dx, ss:[cff.CFF_adminFileName]
		mov	ax, (FILE_CREATE_TRUNCATE or mask FCF_NATIVE) shl 8 \
			    or FileAccessFlags <FE_EXCLUSIVE, FA_WRITE_ONLY>
		mov	cx, FILE_ATTR_NORMAL
		call	FileCreate
		LONG	jc	nukeSFile
		mov	ss:[cff.CFF_convFileHan], ax
	;
	; Now, create the recipient list file.
	;
		sub	sp, (size PhoneList + size word + 1)
		mov	di, sp
		mov	ax, 1	; 1 record in the file
		stosw
		; zero the whole thing out
		mov	bx, di	; save base
		dec	ax
		mov	cx, size PhoneList/2 + 1
		rep	stosw

		; fill unused fields with null-terminated strings of blanks
		;
		lea	di, ss:[bx].PL_name
		mov	cx, size PL_name - 1
		mov	al, ' '
		ECRepStosb
		lea	di, ss:[bx].PL_voiceNum
		mov	cx, size PL_voiceNum-1
		ECRepStosb
		lea	di, ss:[bx].PL_password
		mov	cx, size PL_password-1
		ECRepStosb
		lea	di, ss:[bx].PL_faxNum
		mov	cx, size PL_faxNum-1
		ECRepStosb

		mov	ds:[bx].PL_poll, 'N'
;		mov	ds:[bx].PL_status, 3
;		mov	ds:[bx].PL_tries, 0
		
		; now copy in the phone number
		;
		lea	di, ss:[bx].PL_faxNum-1		; buffer => ES:DI
		lea	si, ss:[cff.CFF_phoneNum]	; phone number => DS:SI
		mov	cx, size PL_faxNum
		clr	al
phoneCopyLoop:
		ECStosb
		lodsb
		tst	al
		loopne	phoneCopyLoop
;		clr	al
;		stosb					; just in case...
		
		mov	ss:[cff.CFF_adminFileName], 'R'
		lea	dx, ss:[cff.CFF_adminFileName]
		mov	ax, (FILE_CREATE_TRUNCATE or mask FCF_NATIVE) shl 8 \
			    or FileAccessFlags <FE_EXCLUSIVE, FA_WRITE_ONLY>
		mov	cx, FILE_ATTR_NORMAL
		call	FileCreate
LONG		jc	nukeCAndSFile

		xchg	bx, ax		; bx <- file handle
		mov	dx, sp
		mov	cx, (size PhoneList + size word)
		clr	al
		call	FileWrite
EC <		WARNING_C ERROR_WRITING_TO_RECIPIENT_FILE	>
		pushf
		clr	al
		call	FileClose
		popf
		lahf
		add	sp, (size PhoneList + size word + 1)
		sahf
		jc	nukeRAndCAndSFile

	;
	; Set up the converted-file-list file now. Converted fax pages go in
	; files named XAF?????.??? where the first five ?'s are the same number
	; used for the administrative files, and the last three are the page
	; number.
	;
EC <		segcmp	es, ss		>
EC <		ERROR_NE -1		>
		
		lea	si, ss:[cff.CFF_adminFileName]
		lea	di, ss:[cff.CFF_convertFileEntry]
		mov	cx, length CFF_adminFileName
		ECRepMovsb
		segmov	ds, ss
		mov	{word} ss:[cff.CFF_convertFileEntry].CFE_fileName,
			'X' or ('A' shl 8)
		mov	ss:[cff.CFF_convertFileEntry].CFE_fileName[2], 'F'
	;
	; Copy the first data file name into the SFE as well...
	;
		lea	si, ss:[cff.CFF_convertFileEntry].CFE_fileName
		lea	di, ss:[cff.CFF_sendFileEntry].SFE_origFile
		mov	cx, size SFE_origFile
			CheckHack <size SFE_origFile lt size CFE_fileName>
		ECRepMovsb
		mov	ss:[cff.CFF_sendFileEntry].SFE_origFile[8], 0
		lea	dx, ss:[cff.CFF_sendFileEntry]
		mov	cx, size SendFileElement
		mov	bx, ss:[cff.CFF_sendFileHan]
		clr	al
		call	FileWrite
EC <		WARNING_C ERROR_WRITING_TO_SEND_FILE	>
		jc	nukeRAndCAndSFile
	;
	; Delete all data files of the same base name. While we're at it,
	; determine the extension for the first data file.
	;
		call	RemoveOldDataFiles
		jc	nukeRAndCAndSFile
done:
		.leave
		ret

nukeRAndCAndSFile:
		segmov	ds, ss
		lea	dx, ss:[cff.CFF_adminFileName]
		call	FileDelete
nukeCAndSFile:
		clr	bx
		xchg	bx, ss:[cff.CFF_convFileHan]
		clr	al
		call	FileClose
		segmov	ds, ss
		mov	ss:[cff.CFF_adminFileName], 'C'
		lea	dx, ss:[cff.CFF_adminFileName]
		call	FileDelete
nukeSFile:
		clr	bx
		mov	bx, ss:[cff.CFF_sendFileHan]
		clr	al
		call	FileClose
		segmov	ds, ss
		mov	ss:[cff.CFF_adminFileName], 'S'
		lea	dx, ss:[cff.CFF_adminFileName]
		call	FileDelete
		stc
		jmp	done

	;
	; Subroutine to write the next available sequence number back to the
	; sequence file.
	;
	; Pass:		bx = file handle
	;		ss:[cff.CFF_sequenceNum].low set to next number
	; Return:	nothing
	; Destroyed:	ax, cx, dx
	;
writeNewSequence:
		clr	dx
		mov	cx, dx
		mov	al, FILE_POS_START
		call	FilePos

		lea	dx, ss:[cff.CFF_sequenceNum]
		mov	cx, size CFF_sequenceNum
		clr	al
		call	FileWrite
EC <		WARNING_C ERROR_WRITING_TO_SEQUENCE_FILE	>
		clr	al
		call	FileClose
		retn
ConvertCreateAdmin endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveOldDataFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumarate and destroy all files with the same base number

CALLED BY:	ConvertCreateAdmin
	
PASS:		SS:BP	= Local variables

RETURN:		Carry	= Clear (if success)
			= Set (if failure)

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveOldDataFiles	proc	near
cff		local	CFFrame
		.enter	inherit

		mov	{word}ss:[cff.CFF_convertFileEntry].CFE_fileName[8],
			'.' or ('*' shl 8)
		mov	{char}ss:[cff.CFF_convertFileEntry].CFE_fileName[10], 0
		lea	ax, ss:[cff.CFF_convertFileEntry.CFE_fileName]
		push	bp
		sub	sp, size FileEnumParams
		mov	bp, sp
		clr	bx
		mov	ss:[bp].FEP_searchFlags, mask FESF_CALLBACK or \
						 mask FESF_NON_GEOS
		mov	ss:[bp].FEP_returnAttrs.segment, bx
		mov	ss:[bp].FEP_returnAttrs.offset, FESRT_NAME
		mov	ss:[bp].FEP_returnSize, size FileLongName
		mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
		mov	ss:[bp].FEP_skipCount, bx
		mov	ss:[bp].FEP_matchAttrs.segment, bx
		mov	ss:[bp].FEP_callback.segment, bx
		mov	ss:[bp].FEP_callback.offset, FESC_WILDCARD
		mov	ss:[bp].FEP_cbData1.offset, ax
		mov	ss:[bp].FEP_cbData1.segment, ss
		mov	ss:[bp].FEP_cbData2.low, TRUE
		call	FileEnum
EC <		ERROR_C	FILE_ENUM_ERROR >

	; Test to see if any files matched.
	;
		tst	bx
		jz	noFilesMatched

		push	ds
		call	MemLock
		mov	ds, ax			;DS <- buffer w/filenames
		clr	dx			;DS:DX <- first file to delete

deleteLoop:
		call	FileDelete
		add	dx, size FileLongName	;Go to the next file
		loop	deleteLoop
		call	MemFree			;Free up the filename buffer
		pop	ds

noFilesMatched:
		pop	bp
	;
	; Now figure the extension for the first data file. It's 000 if
	; the first page is the coversheet, and 001 if not.
	;
		mov	{word}ss:[cff.CFF_convertFileEntry].CFE_fileName[8],
			 '.' or ('0' shl 8)
		mov	ss:[cff.CFF_curPage], 0	; assume has cover sheet
		mov	ax, '00'
		cmp	ss:[cff.CFF_coverSheet], TRUE
		je	storeFirstDataExtension
		mov	ah, '1'			; nope start w/page 1
		mov	ss:[cff.CFF_curPage], 1
storeFirstDataExtension:
		mov	{word}ss:[cff.CFF_convertFileEntry].CFE_fileName[10], ax
		lea	dx, ss:[cff.CFF_convertFileEntry]
		mov	cx, size ConvertFileElement
		mov	bx, ss:[cff.CFF_convFileHan]
		clr	al
		call	FileWrite
EC <		WARNING_C ERROR_WRITING_TO_CONVERT_FILE		>

		.leave
		ret
RemoveOldDataFiles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertDeleteAdmin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the administrative files created for the fax spooler's
		benefit, as something's gone wrong.

CALLED BY:	ConvertStartJob

PASS:		inherited frame

RETURN:		nothing

DESTROYED:	ax, dx, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertDeleteAdmin proc	near
cff		local	CFFrame
		.enter	inherit far

		mov	bx, ss:[cff.CFF_sendFileHan]
		tst	bx
		jz	closeConvertFile
		clr	al
		call	FileClose
closeConvertFile:
		mov	bx, ss:[cff.CFF_convFileHan]
		tst	bx
		jz	nukeFiles
		clr	al
		call	FileClose
nukeFiles:
		segmov	ds, ss
		mov	ss:[cff.CFF_adminFileName], 'R'
		lea	dx, ss:[cff.CFF_adminFileName]
		call	FileDelete
		mov	ss:[cff.CFF_adminFileName], 'C'
		call	FileDelete
		mov	ss:[cff.CFF_adminFileName], 'S'
		call	FileDelete
		.leave
		ret
ConvertDeleteAdmin endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertShipIt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the CCom software about the fax so it can send it
		for us.

CALLED BY:	ConvertEndJob

PASS:		SS:BP	= Local variables

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
queueFile	char	'WAITQUE.CFX', 0

ConvertShipIt	proc	near
		uses	es
		
cff		local	CFFrame

		.enter	inherit
	;
	; Close the S#~ and C#~ files for the job first.
	;
		clr	bx
		xchg	ss:[cff.CFF_convFileHan], bx
		clr	al
		call	FileClose
		jc	shortDone

		clr	bx
		xchg	ss:[cff.CFF_sendFileHan], bx
		clr	al
		call	FileClose
		jnc	createWaitQueue
shortDone:
		jmp	done
	;
	; Now make up the entry for the wait queue.
	;
createWaitQueue:
		segmov	es, ss
		mov	ax, ss:[cff.CFF_numPages]
		mov	ss:[cff.CFF_waitQueueEntry].WQ_numPages, ax
		mov	ss:[cff.CFF_adminFileName], 'S'
		lea	si, ss:[cff.CFF_adminFileName]
		segmov	ds, ss
		lea	di, ss:[cff.CFF_waitQueueEntry].WQ_fileList
		mov	cx, size WQ_fileList
		ECRepMovsb
		
		mov	ss:[cff.CFF_adminFileName], 'R'
		lea	si, ss:[cff.CFF_adminFileName]
		mov	cx, size WQ_recipList
		ECRepMovsb

		call	TimerGetDateAndTime
		mov	ss:[cff.CFF_waitQueueEntry].WQ_day, bh
		mov	ss:[cff.CFF_waitQueueEntry].WQ_mon, bl
		mov	ss:[cff.CFF_waitQueueEntry].WQ_year, ax
		mov	ss:[cff.CFF_waitQueueEntry].WQ_minute, dl
		mov	ss:[cff.CFF_waitQueueEntry].WQ_hour, ch
		segmov	es, dgroup, ax
		mov	es, es:[faxDataArea]
lockLoop:
		mov	al, 1
		lock xchg es:[FRA_waitQueBusy], al
		tst	al		; was it locked before?
		jz	itsMine		; no -- go team.

	;
	; Preserve ES in case segment error-checking biffs it.
	;
		
EC <		push	es				>
EC <		mov	ax, NULL_SEGMENT		>
EC <		mov	es, ax				>
		
		mov	ax, 60
		call	TimerSleep	; Wait a second...
EC <		pop	es				>
		jmp	lockLoop

itsMine:
		push	ds
		segmov	ds, cs

	;
	; (EC-only) Remove the horrible faxDataArea from ES, so CheckDS_ES
	; doesn't barf.
	;
		
EC <		mov	ax, NULL_SEGMENT		>
EC <		mov	es, ax				>
		
		mov	dx, offset queueFile
		
		mov	ax, (FILE_CREATE_NO_TRUNCATE or \
				mask FCF_NATIVE) shl 8 or \
				FileAccessFlags <FE_EXCLUSIVE, FA_WRITE_ONLY>
		mov	cx, FILE_ATTR_NORMAL
		call	FileCreate
		pop	ds
		jc	queueError
		xchg	bx, ax
		
		clr	cx
		mov	dx, cx
		mov	al, FILE_POS_END
		call	FilePos
		
		lea	dx, ss:[cff.CFF_waitQueueEntry]
		mov	cx, size WaitQueue
		clr	al
		call	FileWrite
EC <		WARNING_C ERROR_WRITING_TO_CONVERT_FILE		>
		
		pushf
		clr	al
		call	FileClose
		popf
		jc	queueError

	;
	; Force the transmit scheduler to re-read.
	;

EC <		segmov	es, dgroup, ax			>
EC <		mov	es, es:[faxDataArea]		>
		mov	es:[FRA_nextSend], 1	; 1st entry in file
		mov	es:[FRA_sendYear], 0	; re-read
	;
	; Release the file.
	;
queueError:
EC <		segmov	es, dgroup, ax			>
EC <		mov	es, es:[faxDataArea]		>
		mov	es:[FRA_waitQueBusy], 0
done:
		.leave
		ret
ConvertShipIt	endp
