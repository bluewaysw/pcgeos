COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Spooler
FILE:		processRestart.asm

AUTHOR:		Jim DeFrisco, 26 March 1990

ROUTINES:
	Name			Description
	----			-----------
	SpoolInitiate		Setup the Spool directory
	SpoolBirth		Recover the spool state file, and clean-up
	SpoolRestartPrinting	Restart printing after shutdown
	SpoolDeleteFile		Callback routine used to delete spool files
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/26/90		Initial revision
	Don	10/25/90	Get restarting working

DESCRIPTION:
	This file contains code to restart printing after shutdown.

	$Id: processRestart.asm,v 1.1 97/04/07 11:11:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	system.def				; SysConfig definitions
include	fax.def					; fax directory definitions

SpoolInit	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolBirth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for a spool state file, and restart any printing
		that was occurring prior to the previous shutdown.

CALLED BY:	INTERAL - SpoolOpenApplication
	
PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/25/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DBCS_PCGEOS
spoolFilePattern	wchar	"spool???.dat",0
spoolPSPattern		wchar	"spool???.ps",0
else
spoolFilePattern	char	"spool???.dat",0
spoolPSPattern		char	"spool???.ps",0
endif

SpoolBirth	proc	near
		uses	ax, bx, dx, bp, ds
		.enter

		; there must be a spool dir already, so check for state file
		; check for it by trying to open it

		mov	ax, SP_SPOOL		; change to the spool directory
		call	FileSetStandardPath	; so we can access state file
		mov	al, FILE_DENY_RW or FILE_ACCESS_R
		mov	dx, offset dgroup:stateFile ; state file name
		call	FileOpen		
		jc	nukeAllSpoolFiles	; if error, nuke 'em all

		; we have a valid state file, so start things up

		mov	bx, ax			; pass file handle in bx
		call	SpoolRestartPrinting	; start from state file
		pushf				; save the carry flag
		clr	al			; we'll handle (ignore) errors
		call	FileClose		; close the file
		mov	dx, offset dgroup:stateFile
		call	FileDelete		; delete the state file
		popf				; restore the carry flag
		jnc	done			; if successful, we're done

		; no state file - we must have died going down
		; delete all the spool???.dat files
nukeAllSpoolFiles:
		mov	dx, offset spoolFilePattern
		call	SpoolNukeFiles
done:
		; nuke fax files as well
		call	SpoolNukeFaxFiles

		mov	dx, offset spoolPSPattern
		call	SpoolNukeFiles
		.leave
		ret
SpoolBirth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolNukeFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke files from the SPOOL directory

CALLED BY:	INTERNAL
		SpoolBirth
PASS:		dx	- offset to file pattern for FileEnum
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/16/93		Initial version
	sh	4/26/94		XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolNukeFiles	proc	near
if FULL_EXECUTE_IN_PLACE
		uses	bp, ax, bx, ds, dx, cx, di, es
else
		uses	bp, ax, bx, ds, dx, cx, di
endif
		.enter

if FULL_EXECUTE_IN_PLACE
	;
	; Copy the file pattern string to the stack since we can't pass a
	; fptr to the current code segment if XIP'ed
	;
		segmov	es, cs			; es:di <- file pattern str
		mov	di, dx
		clr	cx			; null-terminated
		call	SysCopyToStackESDI
endif
		sub	sp, size FileEnumParams
		mov	bp, sp			; FileEnumParams => SS:BX
		mov	ss:[bp].FEP_searchFlags, FILE_ENUM_ALL_FILE_TYPES or \
						 mask FESF_CALLBACK
		clr	ax
		mov	ss:[bp].FEP_returnAttrs.offset, FESRT_NAME
		mov	ss:[bp].FEP_returnAttrs.segment, ax
		mov	ss:[bp].FEP_returnSize, (size FileLongName)
		mov	ss:[bp].FEP_matchAttrs.segment, ax
		mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
NOFXIP<		mov	ss:[bp].FEP_cbData1.segment, cs			>
NOFXIP<		mov	ss:[bp].FEP_cbData1.offset, dx			>
FXIP<		mov	ss:[bp].FEP_cbData1.segment, es			>
FXIP<		mov	ss:[bp].FEP_cbData1.offset, di			>
		mov	ss:[bp].FEP_callback.offset, FESC_WILDCARD
		mov	ss:[bp].FEP_callback.segment, ax
		mov	ss:[bp].FEP_cbData2.low, TRUE
		mov	ss:[bp].FEP_skipCount, 0
		call	FileEnum	; bx <- filename block handle

FXIP<		call	SysRemoveFromStack				>

		;
		; now delete all the file in the returned buffer
		;
		jcxz	done
		call	MemLock			; lock filename buffer
		mov	ds, ax
		clr	dx
deleteFileLoop:
		call	FileDelete
		add	dx, (size FileLongName)	; go to the next filename
		loop	deleteFileLoop				
		call	MemFree			; free filename buffer
done:
		.leave
		ret
SpoolNukeFiles	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolNukeFaxFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke fax files from the fax/out directory.

CALLED BY:	SpoolBirth

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	12/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalDefNLString faxFilePattern	<"fax*", 0>
LocalDefNLString faxOutDir	<FAX_OUT_DIR_STRING_NO_ESC, 0>

SpoolNukeFaxFiles	proc	near
		uses	ax, bx, cx, dx, ds 
		.enter
		call	FilePushDir
	;
	; Switch to the fax out file directory, which contains rasterized fax
	; files.  These files are temporary and huge, so clear them.
	;
		segmov	ds, cs, cx			; ds:dx <- source
		mov	dx, offset faxOutDir		
FXIP <		clr	cx				; null-terminated>
FXIP <		call	SysCopyToStackDSDX		; stackify path	>

		mov	bx, FAX_FILE_STANDARD_PATH
		call	FileSetCurrentPath		; change path

FXIP <		lahf							>
FXIP <		call	SysRemoveFromStack		; unstackify path>
FXIP <		sahf							>
		jc	done				; no faxout directory
	;
	; Nuke all fax files.
	;
		mov	dx, offset faxFilePattern
		call	SpoolNukeFiles
done:
		call	FilePopDir
		.leave
		ret
SpoolNukeFaxFiles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCheckSetupFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the continueSetup flag is set.

CALLED BY:	INTERNAL - SpoolLibraryBirth

PASS:		Nothing

RETURN:		AX	= True (0xffff)
			= Flase (0)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

systemKeyName	byte	'system', 0
setupKeyName	byte	'continueSetup', 0

SpoolCheckSetupFlag proc	near
		uses	cx, dx, si, ds
		.enter

		; Check to see if the .INI flag continueSetup is set
		;
		segmov	ds, cs, cx		; CS => CX & DS
		mov	si, offset systemKeyName
		mov	dx, offset setupKeyName
		call	InitFileReadBoolean	; set AX to value
		jnc	done			; if found, we're done
		clr	ax			; else assume flag is false
done:	
		.leave
		ret
SpoolCheckSetupFlag endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolRestartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get things going again, from a state file

CALLED BY:	INTERNAL - SpoolLibraryBirth

PASS:		BX	= Handle of open state file

RETURN:		Carry	= Set if no jobs we're restored
		Clear	= If at least one print job was restored

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		alloc a block for the PrintQueue;
		read in the Queue from the file;
		call SpoolAddJob for each job we find in the queue;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolRestartPrinting proc	near
		uses	ax, bx, cx, dx, si, ds
fileHandle	local	hptr
memHandle	local	hptr
queryUser	local	word
		.enter

		; Check to see if we can really start things at this point
		;
		mov	queryUser, TRUE		; assume we must query the user
		mov	fileHandle, bx		; save file handle
		call	SpoolCheckSetupFlag	; are we in setup ??
		mov	bx, ax			; store result in BX
		call	SysGetConfig		; get the system status
		test	al, mask SCF_CRASHED	; did we crash before ??
		jnz	fail			; if flag is true, we done
		tst	bx			; are we in setup ??
		jz	startRecovery		; no, so query the user
		mov	queryUser, FALSE	; in setup - don't query
		test	al, mask SCF_RESTARTED	; are we restarting ??
		jnz	startRecovery		; yes, so attempt to recover
fail:
		stc				; assume failure
		jmp	exit			; no, so delete all files

		; find out how big a block we need
startRecovery:
		mov	bx, fileHandle		; stateFile handle => BX
		mov	al, FILE_POS_END	; find end of file
		clr	cx			; offset 0 from end
		clr	dx
		call	FilePos			; position file

		; dx:ax has new file position (size of file). dx should
		; always be zero.

EC <		tst	dx			; check for bad file	>
EC <		ERROR_NZ SPOOL_BAD_STATE_FILE	; bail, things are bad	>
		push	ax			; save file size
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK ; lock the block
		call	MemAlloc		; alloc a file buffer
		mov	memHandle, bx		; save mem handle
		mov	ds, ax			; ds -> file buffer

		; now read in the file (reposition at beginning first, 
		; of course).  

		mov	bx, fileHandle		; restore file handle
		mov	al, FILE_POS_START	; go to start of file
		clr	cx			; offset 0 from start
		clr	dx
		call	FilePos
		mov	al, FILE_NO_ERRORS
		pop	cx			; restore file size
		clr	dx			; ds:dx -> buffer
		call	FileRead
		
		; Restore the nextJobID counter from the state file

		push	es
		segmov	es, dgroup, ax
		mov	ax, ds:[LMBH_handle]
		mov	es:[nextJobID], ax
		pop	es

		; now we have to search through the wreck for bodies.
		; For each job we find, call SpoolAddJob.

		mov	cx, ds:[PQ_numJobs]	; any jobs in queue ??
abortRestart:
		stc				; assume no jobs
		jcxz	done			; if no jobs, we're done now

		call	StripCanceledJobs
		jc	done

		; See if the user wants to restart these print jobs
		;
		cmp	queryUser, FALSE	; query user about restart
		je	doRestart		; no - just do it!
		mov	cx, SERROR_PRINT_ON_STARTUP
		clr	dx			; no print queue
		call	SpoolErrorBox		; query the user
		clr	cx			; assume failure
		TestUserStandardDialogResponses	SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_YES, IC_NO, IC_DISMISS
		cmp	ax, IC_YES		; does the user want to print ?
		jne	abortRestart		; no, so exit
doRestart:
		mov	ax, ds:[PQ_numQueues]	; number of queues to search
		mov	bx, ds:[PQ_firstQueue]	; first queue to search
		mov	cx, ds:[PQ_numJobs]	; number of print jobs

		; loop through each queue looking for jobs
qLoop:
		mov	bx, ds:[bx]		; get pointer to queue
		mov	si, ds:[bx].QI_curJob	; get handle of first job

		; loop through all the jobs in this queue
jLoop:
		mov	si, ds:[si]		; ds:si -> next job
		push	cx			; save the count
		mov	cx, ds:[si].JIS_jobID	; cx <- former job ID
		add	si, JIS_info		; get pointer to info
		mov	dx, ds			; DX:SI => JobParameters
		call	SpoolAddJobInternal	; add next job in
		pop	cx			; restore the count
		dec	cx			; one less job to do
		jz	done			;  if all done, leave
		sub	si, JIS_info		; back to beginning of info
		mov	si, ds:[si].JIS_next	; get handle of next job in q
		tst	si			; if zero, at end of line
		jnz	jLoop

		; done with this queue.  check for more queues

		dec	ax			; one less queue to do
		jz	done			;  all done
		mov	bx, ds:[bx].QI_next	; get handle of next queue
		tst	bx			; check for end of line
		jnz	qLoop			;  no, keep going (carry clear)

		; all done, cleanup and exit
done:
		pushf				; save the carry flag
		mov	bx, memHandle		; release the file buffer
		call	MemFree			;  all done w/it
		popf				; restore the carry flag
exit:
		.leave
		ret
SpoolRestartPrinting endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StripCanceledJobs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlink any jobs marked SSJA_CANCEL_JOB in their 
		SO_SHUTDOWN_ACTION field

CALLED BY:	(INTERNAL) SpoolRestartPrinting
PASS:		ds	= saved PrintQueue block
RETURN:		carry set if no jobs left
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 9/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StripCanceledJobs proc	near
		uses	bx, si, ax, di
		.enter
	;
	; Loop through all the queues.
	; ds:bx	= previous queue, so we can unlink the current one if it
	;	  becomes empty.
	; ds:si	= current queue
	;
		mov	si, offset PQ_firstQueue - offset QI_next
queueLoop:
		mov	bx, si
queueLoopNoAdvance:
		mov	si, ds:[bx].QI_next
		tst	si
		jz	checkAnythingLeft
		
		mov	si, ds:[si]
		push	bx			; save prev queue while we
						;  abuse bx during job loop
	;
	; Loop through the jobs for this queue, unlinking any that were
	; canceled during the shutdown (cancelation happens after state file
	; is written)
	; ds:di = previous job
	; ds:bx = current job
	; 
		lea	bx, ds:[si].QI_curJob - offset JIS_next
jobLoop:
		mov	di, bx
jobLoopNoAdvance:
		mov	bx, ds:[di].JIS_next
		tst	bx			; end of job list?
		jz	jobDone			; yes

		mov	bx, ds:[bx]
		test	ds:[bx].JIS_info.JP_spoolOpts, mask SO_SHUTDOWN_ACTION
		jz	jobLoop			; => still here, so advance to
						;  next job
	    ;
	    ; Job was canceled -- unlink it from the chain.
	    ;
		dec	ds:[PQ_numJobs]
		mov	ax, ds:[bx].JIS_next
		mov	ds:[di].JIS_next, ax
		jmp	jobLoopNoAdvance	; go examine new next job for
						;  current previous, if you
						;  see what I mean

jobDone:
	;
	; All jobs processed. Now see if there are any jobs left for this queue.
	;
		pop	bx			; ds:bx <- prev queue
		tst	ds:[si].QI_curJob
		jnz	queueLoop
	;
	; No more jobs for the queue, so unlink it from the list.
	; 
		dec	ds:[PQ_numQueues]
		mov	ax, ds:[si].QI_next
		mov	ds:[bx].QI_next, ax
		jmp	queueLoopNoAdvance

checkAnythingLeft:
	;
	; Done processing all the jobs on all the queues. See if there are
	; any queues remaining.
	;
		tst_clc	ds:[PQ_firstQueue]
		jnz	done
		stc				; not => do nothing on return
done:
		.leave
		ret
StripCanceledJobs endp

SpoolInit	ends
