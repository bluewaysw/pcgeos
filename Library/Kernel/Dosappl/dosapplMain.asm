COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Dosappl
FILE:		dosapplMain.asm

AUTHOR:		Adam de Boor, Jul 13, 1990

ROUTINES:
	Name			Description
	----			-----------
	DosExec			Function to perform setup

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	7/13/90		Initial revision


DESCRIPTION:
	Setup functions for running a DOS program.
		

	$Id: dosapplMain.asm,v 1.1 97/04/05 01:11:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DosapplCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosExec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin execution of a DOS application.

CALLED BY:	GLOBAL
PASS:		bx	= optional disk handle for disk on which the DOS
			  program sits
		ds:si	= pathname of DOS program to run. If this is the empty
			  string (just a null-terminator), the system's
			  command interpreter will be run with the given
			  arguments.
		es:di	= if DEF_MEM_REQ is passed
				DosExecArgAndMemReqsStruct containing memory
				requirements of the program plus the argument
				string
			  else
				arguments for the program.
		ax	= optional disk handle for disk that contains path of
			  directory in which program should be executed
		dx:bp	- path of directory in which program should be executed
			  If both AX and DX are 0, the program will be started
			  within the directory from which PC/GEOS was started.
		cx - DosExecFlags

		Disk handle support:
		--------------------
		If a disk handle is passed, the program path may be:
		    1) full with drive specification, drive will be ignored
		    2) full without drive specification
		
		If a disk handle is not passed (bx=0), the path may be:
		    1) full path with drive specification
		    2) relative path without drive or leading components. In
		       this case, the DOS PATH environment variable will be
		       searched.

RETURN: 	Returns carry set if couldn't run DOS program:
			AX=ERROR_FILE_NOT_FOUND (only if program must be
			   searched for on the search path)
				-or-
			AX=ERROR_DOS_EXEC_IN_PROGRESS
				-or-
			AX=ERROR_INSUFFICIENT_MEMORY	
				-or-
			AX=ERROR_ARGS_TOO_LONG

		Else, carry clear, ax=0		

DESTROYED:	ax,bx,cx,dx,di,si,bp,ds,es

PSEUDO CODE/STRATEGY:
	construct the full path for the working directory.
	
	locate the program itself:
		if disk handle given, program path must be absolute
		else, search along $PATH. if still not found, try what will
		be its working directory, as a last resort. if that fails,
		return an error.
	
	resolve standard paths in both cases.
	
	if the program ends in .BAT:
		locate command.com:
			- see if path specified by COMSPEC envariable
			  is legal.
			- look for COMMAND.COM along $path
			- look for COMMAND.COM in the root of all fixed
			  disks.
			- if all those failed, then error
		copy /c into the command tail
		copy in the name of the batch file, minus any leading
		    components that are common between the batch file and
		    the working directory
		set command.com to be the program to run
	
	copy 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosExec		proc	far
if not ALLOW_DOS_EXEC
		mov	ax, ERROR_UNSUPPORTED_FUNCTION
		stc
		ret
else
.warn -unref_local
cwdOffset	local	word		push bp
cwdSegment	local	sptr		push dx
cwdDisk		local	word		push ax
progDisk	local	word		push bx
progPath	local	fptr		push ds, si
args		local	fptr		push es, di
flags		local	word		push cx
pathBuf		local	PathName	; general-purpose buffer for building
					;  paths
if DBCS_PCGEOS
driveNameBuf	local	VolumeName
endif
.warn @unref_local
		.enter

		mov	ax, idata
		mov	ds, ax
		mov	es, ax
		tst	ds:[taskDriverStrategy].segment
		LONG jz	noDriverLoaded

		mov	ax, size DosExecArgs
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
		mov	bx, handle 0
		call	MemAllocSetOwnerFar
		jnc	haveDEF
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	done

haveDEF:
		mov	ds, ax
		mov	ds:[DEA_handle], bx
		mov	al, ss:[flags].low
		mov	ds:[DEA_flags], al
		mov	ax, es:[loaderVars].KLV_pspSegment
		mov	ds:[DEA_psp], ax

AXIP<		mov	ax, es:[loaderVars].KLV_heapStart		>
AXIP<		mov	ds:[DEA_heapStart], ax				>

NOAXIP<		mov	ds:[DEA_heapStart], es	; kdata is always the   >
NOAXIP<						;  start of the heap...	>

		call	DEConstructWorkingDir
		jc	error

		call	DEConstructProgramPath
		jc	error

		call	DECopyAndMapArgs
		jc	error

		call	DEHandleBatchFile
		jc	error

		test	ss:flags.low, mask DEF_MEM_REQ
		jz	noMemReqsStruct

		; copy DosExecMemReqsStruct into DosExecArgs
		segmov	es, ds			; es:0 = DosExecArgs
		mov	di, offset DEA_memReq	; es:di = DEA_memReq
		lds	si, ss:args		; ds:si = passed
						;   DosExecArgAndMemReqsStruct
		add	si, offset DEAAMRS_memReq ; ds:si = DosExecMemReqsStruct
EC <		add	si, size DosExecMemReqsStruct - 1		>
EC <		call	ECCheckBounds					>
EC <		sub	si, size DosExecMemReqsStruct - 1		>
		mov	cx, size DEA_memReq / 2
		rep	movsw
if size DEA_memReq and 1
		movsb
endif
		segmov	ds, es			; ds:0 = DosExecArgs

noMemReqsStruct:
		mov	di, DR_TASK_START
		mov	cx, idata
		mov	es, cx
		mov	dx, offset loaderVars.KLV_bootupPath
		call	es:[taskDriverStrategy]
done:
		.leave
		ret
error:
		mov	bx, ds:[DEA_handle]
		call	MemFree
		stc
		jmp	done
noDriverLoaded:
		mov	ax, ERROR_NO_TASK_DRIVER_LOADED
		stc
		jmp	done
endif
DosExec		endp

if ALLOW_DOS_EXEC


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DEConstructPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Construct a DOS representation of a path.

CALLED BY:	DEConstructWorkingDir, DEConstructProgramPath
PASS:		bx	= disk handle on which path resides
		ds:dx	= path itself
		es:di	= DEDiskAndPath in which to store the results
		al	= mask FA_SUBDIR if path must be a directory
			= 0 if path must be a file
		ss:bp	= inherited stack frame

RETURN:		carry set if couldn't construct the desired path.

DESTROYED:	ax, bx, cx, ds, dx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DEConstructPath	proc	near
		uses	es
		.enter	inherit DosExec

	;
	; Make sure we have an actual path -- no links or Standard
	; Path nonsense.
	; 
		push	es, di, ax, si, dx
		mov	si, dx
		segmov	es, ss
		lea	di, ss:[pathBuf]	; es:di <- dest buffer
		mov	cx, size pathBuf	; cx <- size of same
		clr	dx			; nothing special...
		call	FileConstructActualPath	; al - FileAttrs
		pop	es, di, cx, si, dx	; cl - passed FileAttrs
		jc	done

	;
	; Store the actual disk handle away.
	; 

		mov	es:[di].DEDAP_disk, bx
	;
	; Make sure the type of thing found (file or dir) is what was wanted
	; 

		xornf	al, cl
		test	al, mask FA_SUBDIR
		jnz	badAttrs

	;
	; Prepend the drive specifier to the result.
	; 
		call	DiskGetDrive		; al <- drive #
if DBCS_PCGEOS
		push	bx
		push	es, di
		segmov	es, ss
		lea	di, ss:[driveNameBuf]
		mov	cx, size driveNameBuf
		call	DriveGetName
		segmov	ds, es
		lea	si, ss:[driveNameBuf]
		pop	es, di
		add	di, offset DEDAP_path	; es:di - buffer
		mov	cx, 0			; null-terminated
		mov	bx, cx			; current code page
		mov	dx, cx			; use primary FSD
		call	LocalGeosToDos
		mov	ax, ERROR_PATH_NOT_FOUND	; assume error
		pop	bx
		jc	done
		add	di, cx			; point past name
		dec	di			; back to null
else
		add	di, offset DEDAP_path	; es:di <- buffer
		mov	cx, size DEDAP_path
		call	DriveGetName
endif
		mov	al, ':'
		stosb
	;
	; Now map the found path into the native namespace.
	; 
		mov	si, bx
		mov	bx, es
		mov	cx, di			; bx:cx <- dest buffer
		call	FileLockInfoSharedToES	; es:si <- DiskDesc

		segmov	ds, ss
		lea	dx, ss:[pathBuf]	; ds:dx <- path to map 
						;  (absolute, w/o drive)
		push	bp			; biffed by DiskLockCallFSD...
		mov	di, DR_FS_PATH_OP
		mov	ax, FSPOF_MAP_VIRTUAL_NAME shl 8 ; al <- 0, to allow
							 ;  abort of disk
							 ;  lock
		call	DiskLockCallFSD
		pop	bp
		call	FSDUnlockInfoShared
done:
		.leave
		ret

badAttrs:
	;
	; The type of thing found wasn't what was expected, so return carry set
	; and ax set to the appropriate error code.
	; 
		mov	ax, ERROR_PATH_NOT_FOUND
		test	cl, mask FA_SUBDIR
		stc
		jnz	done
		mov	ax, ERROR_FILE_NOT_FOUND
		jmp	done
DEConstructPath endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DEConstructWorkingDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build up the full path of the working directory for the 
		beast, given what the caller told us.

CALLED BY:	DosExec
PASS:		ds	= DosExecArgs
		ss:bp	= inherited stack frame
RETURN:		carry set if couldn't find the directory.
DESTROYED:	ax, bx, cx, dx, si, di, es


PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DEConstructWorkingDir proc	near
		uses	ds
		.enter	inherit DosExec
		mov	bx, ss:[cwdDisk]
		segmov	es, ds
		mov	di, offset DEA_cwd
		mov	al, mask FA_SUBDIR
		tst	bx
		jz	checkNullCWD
loadCWDAddr:
		mov	dx, ss:[cwdOffset]
		mov	ds, ss:[cwdSegment]
constructIt:
		call	DEConstructPath
		.leave
		ret
checkNullCWD:
	;
	; If both disk handle and cwd segment are zero, it means to use the
	; directory from which PC/GEOS was started up, i.e.
	; loaderVars.KLV_bootupPath. That's got a drive spec on it, so we
	; can leave the disk handle 0.
	; 
		tst	ss:[cwdSegment]
		jnz	loadCWDAddr

		LoadVarSeg	ds, dx
		mov	dx, offset loaderVars.KLV_bootupPath
		jmp	constructIt
DEConstructWorkingDir endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DEConstructProgramPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build up the full path of the working directory for the 
		beast, given what the caller told us.

CALLED BY:	DosExec
PASS:		ds	= DosExecArgs
		ss:bp	= inherited stack frame
RETURN:		carry set if couldn't find the directory.
DESTROYED:	ax, bx, cx, dx, si, di, es


PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DEConstructProgramPath proc	near
		uses	ds
		.enter	inherit DosExec
	;
	; For now we cheat and just do as we did for the working directory.
	; This is what we'd need to do first anyway...
	; 
		mov	bx, ss:[progDisk]
		segmov	es, ds
		mov	di, offset DEA_prog
		clr	al		; must be a file
		lds	dx, ss:[progPath]
		mov	si, dx
SBCS <		tst	{char}ds:[si]					>
DBCS <		tst	{wchar}ds:[si]					>
		jz	wantsPlainShell
		tst	bx
		jz	locateOnPath
		call	DEConstructPath
done:
		.leave
		ret
locateOnPath:
		mov	di, offset DEA_prog.DEDAP_path
		call	SysLocateFileInDosPath
		jc	tryCWD
if DBCS_PCGEOS
	;
	; map to DOS character set
	;	es:di = path to map
	;	cx = length
	;
		push	bx
		segmov	ds, es			; ds:si = in place conversion
		mov	si, di
		clr	bx, dx			; default code page, IFS
		mov	ax, '_'			; default character
		call	LocalGeosToDos		; convert to DOS char set
		pop	bx			; bx = disk handle
endif
		mov	es:[DEA_prog].DEDAP_disk, bx
		jmp	done

wantsPlainShell:
	;
	; If empty string passed as the program to invoke, it means the caller
	; wants the command interpreter, so just set DEA_prog.DEDAP_path[0]
	; to 0 (al is already 0 to signal requirement for file).
	; DEHandleBatchFile will catch this.
	; 
		mov	es:[di].DEDAP_path[0], al
		clc
		jmp	done

tryCWD:
	;
	; See if the program lies within its working directory.
	; 
		call	FilePushDir
		mov	bx, ss:[cwdDisk]	; push to the program's working
		mov	ds, ss:[cwdSegment]	;  dir.
		mov	dx, ss:[cwdOffset]
		call	FileSetCurrentPath
		jc	fail			; XXX
		
		clr	bx			; indicate relativity
		lds	dx, ss:[progPath]
		mov	di, offset DEA_prog
		clr	al		; must be file
		call	DEConstructPath
fail:
		call	FilePopDir
		jmp	done
DEConstructProgramPath endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DECopyAndMapArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the argument string into the DosExecArgs and map
		it to the DOS character set.

CALLED BY:	DosExec
PASS:		ds	= DosExecArgs
		ss:bp	= inherited stack frame
RETURN:		carry set on error:
			ax	= error code
		carry clear if happy
DESTROYED:	ax, bx, cx, dx, si, di, es


PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DECopyAndMapArgs proc	near
		uses	ds
		.enter	inherit DosExec
	;
	; First copy the null-terminated argument string into the frame,
	; being careful not to overflow the thing...
	; 
		segmov	es, ds
		lds	si, ss:[args]
		test	ss:[flags].low, mask DEF_MEM_REQ
		jz	notMemReqsStruct
		lds	si, ds:[si].DEAAMRS_arguments
notMemReqsStruct:
		mov	di, offset DEA_args
		mov	cx, size DEA_args
	;
	; lead off with a space, always...command.com gets confused, otherwise
	;
		mov	al, ' '
		stosb
if DBCS_PCGEOS
		clr	cx			; null-terminated
		mov	bx, cx			; current code page
		mov	dx, bx			; use primary FSD
		call	LocalGeosToDos
PrintMessage <DosExec: trashes stuff if args-too-long>
		jc	argsInvalid
		add	di, cx			; advance dest ptr
else
		dec	cx
copyLoop:
		lodsb
		stosb
		tst	al
		loopne	copyLoop
		jne	argsTooLong	; => didn't hit null before hitting the
					;  end
endif

	;
	; Store a carriage return over the null character, with a null following
	; that, since this is what DOS likes...though I don't know why...
	; 
if DBCS_PCGEOS
;DOS V doesn't like this
if not PZ_PCGEOS
		cmp	di, (offset DEA_args + size DEA_args)
		je	figureArgLength
		ja	argsTooLong
		mov	{word}es:[di-1], '\r' or (0 shl 8)
		inc	di
figureArgLength:
endif
		sub	di, offset DEA_args
		mov	cx, di
		mov	es:[DEA_argLen], cl
		clc
		jmp	short done
else
		jcxz	figureArgLength
		mov	{word}es:[di-1], '\r' or (0 shl 8)
figureArgLength:
		sub	cx, size DEA_args
		not	cx		; don't include the null...
		mov	es:[DEA_argLen], cl
	;
	; Now convert the whole string to the DOS character set. If any char
	; can't be converted, it's an error...
	; 
		segmov	ds, es
		mov	si, offset DEA_args
		mov	ax, '_'
		call	LocalGeosToDos
		jnc	done
endif
DBCS <argsInvalid:							>
		mov	ax, ERROR_ARGS_INVALID
done:
		.leave
		ret
if not PZ_PCGEOS
argsTooLong:
		mov	ax, ERROR_ARGS_TOO_LONG
		stc
		jmp	done
endif
DECopyAndMapArgs endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DECheckExtensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the program name matches one of the batch-file
		extensions given in the passed list.

CALLED BY:	DEHandleBatchFile
PASS:		es	= DosExecArgs block
		bx	= handle of block containing space-separated 
			  list of possible extensions, upcased. 0 if should
			  use default list.
		ds	= cs
RETURN:		handle of extension list freed
		carry set if extension on the program matches one in the list
			dx	= length of program name, including null byte
		carry clear if no match:
			dx	= preserved
DESTROYED:	ax, bx, bp, ds, si, di, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
defaultExtensions char	"BAT BTM", 0	; default extensions that indicate
					;  a batch file.

DECheckExtensions proc	near
		.enter
	;
	; Get to the end of the program name
	;
		mov	di, offset DEA_prog.DEDAP_path
		clr	al
		mov	cx, -1
		repne	scasb
		not	cx			; cx <- bytes in name (including
						;  null)
		mov	dx, cx
		dec	di			; point to null
	;
	; Find the number of chars in the final component of the path, so we
	; don't find an ersatz suffix in a directory name.
	;
		std
		push	di, cx
		mov	al, '\\'
		repne	scasb			; cx -= # chars
		mov_tr	ax, cx
		pop	di, cx			; di <- null terminator
		sub	cx, ax			; cx <- # bytes in final
						;  component
	;
	; Now see if there's a . in that final component. If not, there's no
	; extension.
	; 
		mov	al, '.'
		repne	scasb
		cld
		clc
		jne	done
	;
	; Found the extension. Now see if it matches anything.
	; 
		inc	di
		inc	di		; es:di <- first char of extension

		mov	si, offset defaultExtensions	; ds:si <- default ext
		tst	bx
		jz	extensionLoop
	;
	; Lock down the block from the ini file and point ds:si to its start
	; 
		call	MemLock
		mov	ds, ax
		clr	si
extensionLoop:
		push	di
compareLoop:
		lodsb			; al <- next ext list char
		tst	al
		jz	checkEndOfPath	; => see if at end of prog path
		cmp	al, ' '
		je	checkEndOfPath
		cmp	al, '\t'
		je	checkEndOfPath
		mov	cl, es:[di]	; cl <- next component char
		inc	di
		clr	ah, ch		; zero-extend both chars

		call	LocalCmpCharsNoCase
		je	compareLoop	; loop while still matches

	;
	; Mismatch. Skip to the next extension.
	; 
		pop	di		; es:di <- start of path extension
skipToEndOfThisExtension:		; loop until hit end or w.s.
		lodsb
		tst	al
		jz	done
		cmp	al, ' '
		je	skipToStartOfNextExtension
		cmp	al, '\t'
		jne	skipToEndOfThisExtension

skipToStartOfNextExtension:		; loop while w.s.
		lodsb
		cmp	al, ' '
		je	skipToStartOfNextExtension
		cmp	al, '\t'
		je	skipToStartOfNextExtension

		tst	al
		jz	done
		dec	si		; return to non-w.s. char
		jmp	extensionLoop	; and loop

checkEndOfPath:
	;
	; Current character (0, space or tab) is allowed to match the null byte
	; at the end of the program path. See if that's what we're looking at.
	; 
		cmp	{char}es:[di], 0
		pop	di
		je	isBatchFile

		tst	al		; end of the line?
		jnz	skipToStartOfNextExtension	; no -- skip to next
							;  extension
isBatchFile:
		stc			; flag batchitude.
done:
		lahf			; preserve carry
		tst	bx
		jz	exit
		call	MemFree
exit:
		sahf
		.leave
		ret
DECheckExtensions endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DELCICheckComspec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look at the COMSPEC envariable and see if it refers to an
		existing file. Returning it as the command interpreter if so.

CALLED BY:	DELocateCommandInterpreter
PASS:		ds	= DosExecArgs
		ss:bp	= inherited frame (from DosExec)
RETURN:		carry set if not found:
			ax	= ERROR_CANNOT_FIND_COMMAND_INTERPRETER
		carry clear if found:
			ds:DEA_prog set
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DELCICheckComspec proc	near
		uses	ds
		.enter	inherit DosExec
	;
	; Fetch the environment variable into DEA_prog. If it's what we need,
	; that's where we'll need it anyway.
	; 
		segmov	es, ds		; es <- DEA
		segmov	ds, cs
		mov	si, offset comspecName
		mov	di, offset DEA_prog.DEDAP_path
		mov	cx, size DEA_prog.DEDAP_path
		call	SysGetDosEnvironment
		mov	ax, ERROR_CANNOT_FIND_COMMAND_INTERPRETER
		jc	done
	;
	; Got it. We now need to map the name to its virtual form so we
	; can ask the IFS driver whether the file exists. Note that since
	; DOS drive letters are always in the low-ascii set, we can just
	; call FileGetDestinationDisk on the thing even though it's in the
	; DOS character set.
	; 
		segmov	ds, es		; ds <- DEA
		mov	dx, offset DEA_prog.DEDAP_path
		mov	bx, TRUE	; avoid std path check
		call	FileGetDestinationDisk
		jc	error
		
		mov	ds:[DEA_prog].DEDAP_disk, bx

		mov	si, dx
		cmp	{char}ds:[si], '\\'
		jne	isHackedNovellCrap

		call	FileLockInfoSharedToES
		mov	si, bx		; es:si <- DiskDesc
		mov	ah, FSPOF_MAP_NATIVE_NAME
		mov	bx, ss
		lea	cx, ss:[pathBuf]
		mov	di, DR_FS_PATH_OP
		push	bp
		call	DiskLockCallFSD	
		pop	bp
	;
	; Now see if the thing's a file. If it is, we've got the path
	; and disk in DEA_prog already, so we need do nothing else.
	; 
		segmov	ds, ss
		lea	dx, ss:[pathBuf]
		mov	ah, FSPOF_GET_ATTRIBUTES
		mov	di, DR_FS_PATH_OP
		push	bp
		call	DiskLockCallFSD
		pop	bp
		call	FSDUnlockInfoShared	; preserves flags
		jc	error
		test	cl, mask FA_SUBDIR
		jz	done
error:
		mov	ax, ERROR_CANNOT_FIND_COMMAND_INTERPRETER
		stc
done:
		.leave
		ret

isHackedNovellCrap:
	;
	; Novell likes to set the COMSPEC to a relative path and then not
	; root-map the search drive on which the thing sits. If we do the above
	; stuff, we will change the working directory of the drive, which will
	; louse things up. I downright refuse to pollute the filesystem by
	; making it assume a relative path passed in this way means to use the
	; working directory for that drive, since we don't maintain such
	; information.
	;
	; To make things work, I am polluting this little part here by
	; assuming the interpreter exists if faced with such silliness. If
	; it doesn't, the final exec in the task-switch driver will find out
	; the thing is awol, but we won't have hosed anything here. -- ardeb
	; 
		clc
		jmp	done
DELCICheckComspec endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DELCICheckOnPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	look for command.com in the directories listed in the
		PATH envariable.

CALLED BY:	DELocateCommandInterpreter
PASS:		ds	= DosExecArgs
		ss:bp	= inherited stack frame (DosExec)
RETURN:		carry clear if found:
			ds:DEA_prog	filled in
		carry set if not found:
			ax	= ERROR_CANNOT_FIND_COMMAND_INTERPRETER
DESTROYED:	ax, bx, cx, dx, si, di,es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
commandName	char	'COMMAND.COM', 0

DELCICheckOnPath proc	near
		.enter	inherit DosExec
		segmov	es, ds
		segmov	ds, cs
		mov	si, offset commandName
		mov	di, offset DEA_prog.DEDAP_path
		call	SysLocateFileInDosPath
		mov	ax, ERROR_CANNOT_FIND_COMMAND_INTERPRETER
		jc	done
		mov	es:[DEA_prog].DEDAP_disk, bx
done:
		segmov	ds, es			; ds <- DosExecArgs again
		.leave
		ret
DELCICheckOnPath endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DELCICheckHardDisks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	look for command.com in the root of all non-removable disks

CALLED BY:	DELocateCommandInterpreter
PASS:		ds	= DosExecArgs
		ss:bp	= inherited stack frame (DosExec)
RETURN:		carry clear if found:
			ds:DEA_prog	filled in
		carry set if not found:
			ax	= ERROR_CANNOT_FIND_COMMAND_INTERPRETER
DESTROYED:	ax, bx, cx, dx, si, di,es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DELCICheckHardDisks proc	near
		.enter	inherit DosExec
		mov	ax, ERROR_CANNOT_FIND_COMMAND_INTERPRETER
		stc
		.leave
		ret
DELCICheckHardDisks endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DELocateCommandInterpreter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Seek after the command interpreter we should run.

CALLED BY:	DEHandleBatchFile
PASS:		ds	= DosExecArgs
RETURN:		carry clear if interpreter found:
			ds:[DEA_prog] filled in with its location
		carry set if couldn't find it:
			ax	= ERROR_CANNOT_FIND_COMMAND_INTERPRETER
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
		- see if path specified by COMSPEC envariable
		  is legal.
		- look for COMMAND.COM along $path
		- look for COMMAND.COM in the root of all fixed
		  disks.
		- if all those failed, then error
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
comspecName	char	'COMSPEC', 0

DELocateCommandInterpreter proc	near
		.enter	inherit DosExec
		call	DELCICheckComspec
		jnc	done
		
		call	DELCICheckOnPath
		jnc	done
		
		call	DELCICheckHardDisks
done:
		.leave
		ret
DELocateCommandInterpreter endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DEHandleBatchFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the program being invoked is considered a batch file
		and react accordingly.

CALLED BY:	DosExec
PASS:		ds	= DosExecArgs
RETURN:		carry set on error:
			ax	= FileErrors
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
		Eventually, this should look up a list of suffixes to check
		in the .ini file, and see if the program has any of them.
		
		if so, it needs to:
			- insert /c <program> at the front of the argument
			  list, returning ERROR_ARGS_TOO_LONG if they are.
			  to give this a better chance of succeeding, remove
			  any components that are common between the working
			  directory and the program.
			- locate command.com:
			    - see if path specified by COMSPEC envariable
			      is legal.
			    - look for COMMAND.COM along $path
			    - look for COMMAND.COM in the root of all fixed
			      disks.
			    - if all those failed, then error
			- set the program to be run to be the found interpreter.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
systemCatStr	char	"system", 0
batExtStr	char	"batch ext", 0


DEHandleBatchFile proc	near
		uses	ds
		.enter	inherit DosExec
	;
	; If program name is empty, pretend it's a batch file so we find the
	; command interpreter.
	; 
		tst	ds:[DEA_prog].DEDAP_path[0]
		jz	argsMunged
	;
	; See if the ini file holds a list of batch-file extensions
	; 
		segmov	es, ds
		segmov	ds, cs, cx	; ds, cx <- cs
		mov	si, offset systemCatStr	; ds:si <- category
		mov	dx, offset batExtStr	; cx:dx <- key
		push	bp
		mov	bp, InitFileReadFlags <IFCC_UPCASE,,,0>	; alloc buffer
								;  and upcase
DBCS <PrintMessage <fix DECheckExtensions for DBCS>>
		call	InitFileReadString
		pop	bp
		jnc	checkExtensions
		clr	bx			; flag no handle/use default
checkExtensions:
		call	DECheckExtensions
		jc	isBatchFile
done:
		.leave
		ret

isBatchFile:
	;
	; It's a batch file, so for now just copy the program into the
	; argument string, with a leading /c.
	; 
		segmov	ds, es
		mov	al, ds:[DEA_argLen]
			CheckHack <DOS_EXEC_MAX_ARG_LENGTH lt 128>
		cbw			; zero-extend
		add	dx, 2+1		; add room for /c<space>
		add	ax, dx		; add room for filename, replacing
					;  null with space
		cmp	ax, DOS_EXEC_MAX_ARG_LENGTH
		jbe	insertProgName
		mov	ax, ERROR_ARGS_TOO_LONG
		stc
		jmp	done

insertProgName:
	;
	; There's enough room in the argument string to store the program and
	; its leading /c<space>, so shift the rest of the argument string
	; up to make room for them.
	; 
		mov	cx, ax
		xchg	cl, ds:[DEA_argLen]	; store new arg len and fetch
						;  old for copying up

		add	ax, offset DEA_args
		inc	ax		; copy the \r at the end, too
		inc	cx		; copy the \r at the end, too

		mov	di, ax		; es:di <- dest
		mov_tr	si, ax
		sub	si, dx		; ds:si <- src
		std
		rep	movsb
		cld
	;
	; Now store the /c<space> first, after the leading space.
	; 
		mov	di, offset DEA_args+1
		mov	ax, '/' or ('c' shl 8)
		stosw
		mov	al, ' '
		stosb
	;
	; Copy up all of the path but the null byte.
	; 
		mov	si, offset DEA_prog.DEDAP_path
		mov	cx, dx
		sub	cx, 2+1+1	; copy 
		rep	movsb
	;
	; Store a space where the null byte would have gone.
	; 
		stosb
argsMunged:
	;
	; Argument string is now as it should be. Now we must quest for
	; command.com
	; 
		call	DELocateCommandInterpreter
		jmp	done
DEHandleBatchFile endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosExecLocateLoader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the full path of the loader, along with its initial
		CS:IP and SS:SP.

CALLED BY:	GLOBAL
PASS:		es:di	= address of DosExecLoaderInfo
RETURN:		carry set if loader couldn't be found
		carry clear if loader info returned.
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
EC <loaderName	wchar	"LOADEREC.EXE", 0				>
NEC <loaderName	wchar	"LOADER.EXE", 0					>
else
EC <loaderName	char	"LOADEREC.EXE", 0				>
NEC <loaderName	char	"LOADER.EXE", 0					>
endif
DosExecLocateLoader proc far
header		local	ExeHeader
loaderDisk	local	word
loaderFullPath	local	PathName
DBCS <dbcsDELIPath	local	3+DOS_STD_PATH_LENGTH+1 dup (wchar)	>
		uses	ds, dx, cx, bx, di, si, es
		.enter

	;
	;  Clear loaderDisk to indicate that we haven't searched the
	;  environment block yet.
	;
		clr	ss:[loaderDisk]

	;
	; Push to SP_TOP, as that's where we expect the loader to be.
	; XXX: what if someone has GEOSDIR set and puts loader.exe in some
	; common executable directory? We should search the path then...
	; 
		call	FilePushDir
		mov	ax, SP_TOP
		call	FileSetStandardPath
	;
	; Now get the absolute path of the thing, without regard for standard
	; path nonsense.
	; 
		segmov	ds, cs
		mov	dx, offset loaderName

resolvePath:
		mov	cx, length DELI_path
		mov	ax, mask FRSPF_ADD_DRIVE_NAME
			CheckHack <offset DELI_path eq 0>
if DBCS_PCGEOS
		push	es, di			; save DELI_path
		segmov	es, ss			; our DBCS DELI_path
		lea	di, dbcsDELIPath
		call	FileResolveStandardPath
		pop	es, di
		LONG jc	checkEnvironment
		push	ds, si, di, es, bx, dx
		segmov	ds, ss
		mov	ax, dbcsDELIPath[0]	; drive letter
EC <		tst	ah						>
EC <		ERROR_NZ	ERROR_PATH_NOT_FOUND			>
		stosb
		mov	ax, dbcsDELIPath[2]	; colon
EC <		cmp	ax, ':'						>
EC <		ERROR_NE	ERROR_PATH_NOT_FOUND			>
		stosb
		lea	dx, dbcsDELIPath[4]	; ds:dx <- path to map
						;	(skip drive reference)
		mov	si, bx			; si = disk returned from
						;	FileResolveStandardPath
		mov	bx, es
		mov	cx, di			; bx:cx <- dest buffer
						;	(after drive reference)
		call	callMapVirtual
		pop	ds, si, di, es, bx, dx
else
		push	di
		call	FileResolveStandardPath
		pop	di
		jc	checkEnvironment
endif

	;
	; Try and open the beast so we can fetch its header (and thus the
	; CS:IP and SS:SP)
	; 
		mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
		call	FileOpen
		jc	done

	;
	; Read the header in.
	; 
		mov	ss:[loaderDisk], bx
		mov_tr	bx, ax
		segmov	ds, ss
		lea	dx, ss:[header]
		mov	cx, size header
		clr	al
		call	FileReadFar
		jc	closeDone
		mov	ax, ss:[header].EH_ss
		mov	es:[di].DELI_sssp.segment, ax
		mov	ax, ss:[header].EH_sp
		mov	es:[di].DELI_sssp.offset, ax
		mov	ax, ss:[header].EH_cs
		mov	es:[di].DELI_csip.segment, ax
		mov	ax, ss:[header].EH_ip
		mov	es:[di].DELI_csip.offset, ax
	;
	; Close the file again.
	; 
closeDone:
		pushf
		clr	al
		call	FileCloseFar
		popf
		jc	done
	;
	; Now map the loader path to its native form and character set.
	; 
if DBCS_PCGEOS
		segmov	ds, ss			;ds:dx <- path to map (DBCS)
		lea	dx, dbcsDELIPath[4]	;	(skip drive reference)
		mov	bx, es
		lea	cx, es:[di].DELI_path[2] ; bx:cx <- dest buffer (SBCS)
else
		segmov	ds, es, bx		; ds, bx <- es
		lea	dx, es:[di].DELI_path[2]; ds:dx <- path to map,
						;  skiping drive reference
		mov	cx, dx			; bx:cx <- dest buffer
endif
		mov	si, ss:[loaderDisk]
if DBCS_PCGEOS
		call	callMapVirtual
else
		call	FileLockInfoSharedToES	; es:si <- DiskDesc
		mov	ax, FSPOF_MAP_VIRTUAL_NAME shl 8	; al <- 0 to
								;  allow lock
								;  abort
		mov	di, DR_FS_PATH_OP
		push	bp
		call	DiskLockCallFSD		; carry set if error or lock
						;  aborted
		pop	bp
		call	FSDUnlockInfoShared
endif
done:
		call	FilePopDir
		.leave
		ret

popESDIDone:
		pop	es, di
		stc					;fail
		jmp	done

checkEnvironment:

	;
	;  We'll make one last attempt to locate the loader in the
	;  environment block
	;
		tst	ss:[loaderDisk]
		jnz	done

		mov	ss:[loaderDisk], 1

		push	es, di
		LoadVarSeg	es, ax
		mov	es, es:[loaderVars].KLV_pspSegment
		mov	es, es:[PSP_envBlk]
		clr	di

	;
	;  Search for 0x00 0x00 0x01 0x00, for some reason
	;

		mov	cx, 0xffff			;search forever
		clr	al				;find a null

keepLooking:
		repne scasb
		jnz	popESDIDone

	;
	;  we found the first 0x00, check for 0x00 0x01 0x00
	;

		cmp	es:[di], 0x0100
		jne	keepLooking

		cmp	{byte} es:[di+2], 0x00
		jnz	keepLooking

	;
	;  We've found the pattern; Now we'll copy the name into loaderFullPath
	;

		mov	si, di
		add	si, 3
		segmov	ds, es				;ds:si <- filename
		segmov	es, ss
		lea	di, ss:[loaderFullPath]		;es:di<-loaderFullPath
		mov	dx, di
		mov	cx, length PathName
if DBCS_PCGEOS
		clr	ah
convertLoop2:
		lodsb
		stosw
		loop	convertLoop2
else
		rep movsb
endif

		segmov	ds, es				;ds:dx<-loaderFullPath

		pop	es, di
		jmp	resolvePath

if DBCS_PCGEOS
callMapVirtual	label	near
		call	FileLockInfoSharedToES	; es:si <- DiskDesc
		mov	ax, FSPOF_MAP_VIRTUAL_NAME shl 8	; al <- 0 to
								;  allow lock
								;  abort
		mov	di, DR_FS_PATH_OP
		push	bp
		call	DiskLockCallFSD		; carry set if error or lock
						;  aborted
		pop	bp
		call	FSDUnlockInfoShared
		retn
endif

DosExecLocateLoader endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosExecRestartSystem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the function that is copied into a fixed block
		by DosExecPrepareForRestart, along with the DosExecLoaderInfo,
		to restart the system once it has shut down completely.
		
		As such, it is written in a position-independent manner,
		which may appear strange at times.

CALLED BY:	EndGeos
PASS:		nothing
RETURN:		never
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		The loader always gets loaded at the base of dgroup. we
		assume it's not big enough to run into our stack.

		For the bullet, the loader is loaded at the bottom of
		the heap (KLV_heapStart).  In addition, this procedure
		is moved up to the top of memory, so that it doesn't
		interfere with the loader.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosExecRestartSystem proc far

		mov	bx, dgroup		; keep dgroup around
						; in BX for a while
		mov	ds, bx

if	FULL_EXECUTE_IN_PLACE or KERNEL_EXECUTE_IN_PLACE

	;
	; Move this procedure up to the top of the heap before
	; bringing in the loader.
	;
		mov	cx, LOADER_INFO_OFFSET + RESTART_STACK_SIZE
		shr	cx
		shr	cx
		shr	cx
		shr	cx		; # paragraphs
		inc	cx
		mov	ax, ds:[loaderVars].KLV_heapEnd
		sub	ax, cx
		mov	es, ax		; destination segment address
		segmov	ds, cs, si
		mov	si, offset afterMove-DosExecRestartSystem
		clr	di
		mov	cx, LOADER_INFO_OFFSET + size dersLoaderInfo
		rep	movsb

		mov	ds, bx		; restore dgroup
		push	es		; jump to relocated code.
		clr	ax
		push	ax
		retf
		
afterMove:
endif	; AXIP
		
	;
	; Save the segment address of the PSP for passing to the loader.
	; 
		mov	cx, ds:[loaderVars].KLV_pspSegment
	;
	; Tell the stub the system's about to restart.
	; 
		mov	al, DEBUG_RESTART_SYSTEM
		call	FarDebugProcess
	;
	; Switch to our own stack so we don't load the loader in on top of
	; the int 21h's return address...
	;
AXIP <	mov	bx, ds:[loaderVars].KLV_heapStart			>
		
		segmov	ds, cs, ax
		mov	es, ax

		mov	ss, ax
		mov	sp, LOADER_INFO_OFFSET+RESTART_STACK_SIZE
	;
	; Relocate the cs:ip and ss:sp for the loader.  For
	; non-bullet, BX is dgroup.  For bullet, it's the heap start.
	; 

		add	ds:[LOADER_INFO_OFFSET].DELI_csip.segment, bx
		add	ds:[LOADER_INFO_OFFSET].DELI_sssp.segment, bx
	;
	; Now tell DOS to load the thing in.
	; 
		lea	dx, ds:[LOADER_INFO_OFFSET].DELI_path
						; ds:dx <- file to load
		mov	bx, LOADER_ARGS_OFFSET
						; es:bx <- parameter block
		mov	ax, MSDOS_EXEC shl 8 or MSESF_LOAD_OVERLAY
		int	21h
	; XXX: deal with error here.

		mov	ds, cx
		mov	es, cx
	;
	; Switch to the loader's stack and jump to its entry point.
	; 
		mov	ss, cs:[LOADER_INFO_OFFSET].DELI_sssp.segment
		mov	sp, cs:[LOADER_INFO_OFFSET].DELI_sssp.offset
		jmp	cs:[LOADER_INFO_OFFSET].DELI_csip
;
; the loader always gets loaded at the base of dgroup
;
dersLoadArgs	DosLoadOverlayArgs	<dgroup, dgroup>
dersLoaderInfo	label	DosExecLoaderInfo

		
NOAXIP <	LOADER_INFO_OFFSET equ dersLoaderInfo-DosExecRestartSystem >
NOAXIP <	LOADER_ARGS_OFFSET equ dersLoadArgs-DosExecRestartSystem >

AXIP <	LOADER_INFO_OFFSET equ dersLoaderInfo-afterMove 	>
AXIP <	LOADER_ARGS_OFFSET equ dersLoadArgs-afterMove 		>
		
DosExecRestartSystem endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosExecPrepareForRestart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare the system to restart itself.

CALLED BY:	SysShutdown
PASS:		ds	= dgroup
RETURN:		carry set if couldn't set up for restart
		carry clear if ok.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosExecPrepareForRestart proc	far
		uses	ax, bx, cx, ds, es, si, di
		.enter
	;
	; Allocate a fixed block large enough to hold DosExecRestartSystem and
	; the DosExecLoaderInfo
	; 
		mov	ax, (DosExecPrepareForRestart-DosExecRestartSystem) + \
				size DosExecLoaderInfo + RESTART_STACK_SIZE
		mov	cx, ALLOC_FIXED
		mov	bx, handle 0
		call	MemAllocSetOwnerFar
		jc	done
	;
	; Point the reloadSystemVector to the code
	; 
		mov	es, ax
		clr	di
		LoadVarSeg	ds, ax
		mov	ds:[reloadSystemVector].segment, es
		mov	ds:[reloadSystemVector].offset, di
	;
	; Copy the restart code into the start of the block.
	; 
		segmov	ds, cs
		mov	si, offset DosExecRestartSystem
		mov	cx, DosExecPrepareForRestart-DosExecRestartSystem
		rep	movsb


	;
	; For the bullet, rather than pointing at kdata, point the
	; load address at the start of the heap. 
	;
AXIP   <	LoadVarSeg	ds, ax					>
AXIP   <	mov	ax, ds:[loaderVars].KLV_heapStart		>
AXIP   <	assume	es:DosapplCode					>
AXIP   <	mov	es:[dersLoadArgs-DosExecRestartSystem].DLOA_base, ax >
AXIP   <	mov	es:[dersLoadArgs-DosExecRestartSystem].DLOA_reloc, ax>
AXIP   <	assume	es:dgroup					>
		

	;
	; Build the DosExecLoaderInfo in that block
	; 
		CheckHack <dersLoaderInfo-DosExecRestartSystem eq \
			   DosExecPrepareForRestart-DosExecRestartSystem>
		call	DosExecLocateLoader
		jc	errFreeBlock
	;
	; Since we're now able to restart, set the EF_RESTART flag in the
	; exitFlags.
	; 
NOAXIP <	LoadVarSeg	ds, ax					>
		ornf	ds:[exitFlags], mask EF_RESTART
	;
	; If SCF_RESTART isn't already set, prepend /r to the command tail
	; to tell ourselves we restarted when we are re-incarnated by the
	; loader.
	; 
		test	ds:[sysConfig], mask SCF_RESTARTED
		jnz	done

		mov	ax, ds:[loaderVars].KLV_pspSegment
		mov	ds, ax
		mov	es, ax
		mov	al, ds:[PSP_cmdTail][0]
		clr	ah
		mov	si, ax
		mov_tr	cx, ax
		add	si, offset PSP_cmdTail+1
		lea	di, ds:[si+2]
		std
		inc	cx
		rep	movsb
		cld
		mov	{word}ds:[PSP_cmdTail][1], '/' or ('r' shl 8)
		add	ds:[PSP_cmdTail][0], 2
done:
		.leave
		ret
errFreeBlock:		
		call	MemFree
		stc
		jmp	done
DosExecPrepareForRestart endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosExecSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put the system into stasis. The caller should have checked
		with all concerned applications, via GCNSLT_SHUTDOWN_CONTROL,
		that it's ok with them to suspend.
		
		Once this routine returns, all further file-system or
		heap activity is strictly forbidden. Any memory that must
		be accessible should be locked down before calling this
		routine.

CALLED BY:	RESTRICTED GLOBAL
PASS:		es:di	= buffer in which to place error message, if suspension
			  is denied.
RETURN:		carry set if suspension denied:
			es:di	= buffer filled with null-terminated error
				  message
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosExecSuspend	proc	far
		uses	ds, es, bp
		.enter
		LoadVarSeg	ds, ax
	;
	; First attempt to preserve all data currently swapped to volatile
	; secondary storage.
	; 
		call	MemPreserveVolatileSwapData
		jnc	grabLocks
		mov	al, KS_CANNOT_PRESERVE_VOLATILE_SWAP_DATA
		call	AddStringAtESDIFar
		stc
		jmp	done

grabLocks:
	;
	; Take hold of the various synchronization points that matter:
	; 	- geodeSem
	; 	- FSInfoResource (exclusive)
	; 	- heapSem
	; 	- biosLock
	; We do not deal with locks on individual drives on the assumption
	; that anything that has a drive locked for exclusive access ought
	; to be on the GCNSLT_SHUTDOWN_CONTROL list to make sure the user
	; doesn't dick himself/herself over by exiting during a long
	; operation. If the app isn't on the list, we assume the lock of
	; the drive isn't due to anything that would be disrupted by being
	; put into stasis.
	; 
		call	FarPGeode
		call	FSDLockInfoExcl
		call	FarPHeap
		call	SysLockBIOSFar
locateDrivers::
	;
	; Now get the strategy routine for all the drivers, pushing each
	; onto the stack in turn so we can call them in reverse order. This
	; is important as some drivers depend on other drivers...
	; 
		mov	bx, ds:[geodeListPtr]
		mov	bp, sp		; save current stack for after
					;  everything's suspended.
geodeLoop:
		call	MemLock
		mov	ds, ax
		mov	cx, ds:[GH_nextGeode]
		test	ds:[GH_geodeAttr], mask GA_DRIVER
		jz	nextGeode
		lds	si, {fptr}ds:[GH_driverTabOff]
		pushdw	ds:[si].DIS_strategy
nextGeode:
		call	MemUnlock
		mov	bx, cx		; bx <- next geode in the list
		tst	bx
		jnz	geodeLoop
	;
	; All strategy routines are now on the stack. joy. Call each in turn.
	; 
		mov	si, sp
		mov	cx, es
		mov	dx, di
callDriverLoop:
		cmp	si, bp		; reached the old stack point?
		je	resetTimer	; yes -- reset the timer chip

		mov	di, DR_SUSPEND
		call	{fptr.far}ss:[si]; call the next driver
		jc	driverError

		add	si, size fptr	; driver's happy, so advance to next
		jmp	callDriverLoop	;  and loop


driverError:
	;
	; One of the drivers returned an error. Call back the drivers we've
	; already called to tell them to unsuspend. Note we do this in the
	; "forward" order.
	; 
		sub	si, size fptr
		cmp	si, sp
		jb	releaseLocks
		mov	di, DR_UNSUSPEND
		call	{fptr.far}ss:[si]
		jmp	driverError

releaseLocks:
		call	SysUnlockBIOSFar
		call	FarVHeap
		call	FSDUnlockInfoExcl
		call	FarVGeode

		LoadVarSeg	ds, ax
		call	MemVolatileSwapNowSafeAndSound
		stc
clearStack:
		mov	sp, bp		; Clear the strategy routines off the
					;  stack
done:
		.leave
		ret

resetTimer:
	;
	; Reset the timer to its usual 18.2 ticks/second keel. We don't
	; reset the DOS date & time as we assume it's been keeping up with us.
	; 
	; Can't use WriteTimer here as that
	; always programs to mode 2, not the mode 3 that the rest of the world
	; uses.
		LoadVarSeg	ds, ax
		call	TimerSuspend
	;
	; Un-intercept all hardware interrupts so TaskMax doesn't screw up when
	; we're using Novell. The fail case is on my system (of course) where
	; PC/GEOS intercepts vector 72h (for IRQ 10) that my 3Com 3C507 board
	; uses, and the system freezes.
	; 
		call	SysSwapIntercepts
	;
	; uninstall int 21, too
	;
		call	FSDSuspend

		clc
		jmp	clearStack
DosExecSuspend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosExecUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the system out of suspended animation.

CALLED BY:	RESTRICTED GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If there is a possibility the the ResourceCallInt vectors have been
	destroyed, this routine must be called using ProcCallFixedOrMovable (see
	code in Driver/Task/Common/taskSwitch.asm)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosExecUnsuspend proc	far
		uses	ds, es, bp
		.enter
		LoadVarSeg	ds, ax
	;
	; Re-establish whatever hardware intercepts are necessary to preserve
	; the system's sanity.
	; 
		call	SysSwapIntercepts
		call	FSDUnsuspend
	;
	; Restart our timebase.
	; 
		call	TimerUnsuspend
	;
	; Call all the drivers back in forward order. Note that we assume no
	; core block could have gotten swapped out after all the drivers were
	; called before, as no further heap or filesystem activity is
	; allowed once DosExecSuspend returns.
	; 
		mov	bx, ds:[geodeListPtr]
driverLoop:
		call	MemLock
		mov	es, ax
		mov	cx, es:[GH_nextGeode]	; get next ptr while we've got
						;  the core block in ES
		test	es:[GH_geodeAttr], mask GA_DRIVER
		jz	nextGeode
		les	si, {fptr}es:[GH_driverTabOff]
		mov	di, DR_UNSUSPEND
		push	bx, cx
		call	es:[si].DIS_strategy
		pop	bx, cx
nextGeode:
		call	MemUnlock
		mov	bx, cx		; bx <- next geode
		tst	bx
		jnz	driverLoop
	;
	; Now release all the locks.
	; 
		LoadVarSeg	ds, bx

		call	SysUnlockBIOSFar
		call	FarVHeap
		call	FSDUnlockInfoExcl
		call	FarVGeode
	;
	; And tell the heap that all volatile swap devices are now safe.
	; 
		call	MemVolatileSwapNowSafeAndSound
	;
	; Now tell the world we've changed the date and/or time.
	; 
		mov	ax, MSG_NOTIFY_DATE_TIME_CHANGE
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	si, GCNSLT_DATE_TIME
		clr	di
		call	GCNListRecordAndSend
		.leave
		ret
DosExecUnsuspend endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosExecRestoreMovableVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the software interrupt vectors to their state before
		DosExecInsertMovableVector was called.

CALLED BY:	RESTRICTED GLOBAL (Task Drivers)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	2/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosExecRestoreMovableVector		proc	far
		uses	ax, bx, cx, dx, ds
		.enter

		LoadVarSeg	ds, ax

		call	RestoreMovableInt

		.leave
		ret
DosExecRestoreMovableVector		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosExecInsertMovableVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert our own software interrupt vectors to handle calls to
		movable routines.

CALLED BY:	RESTRICTED GLOBAL (Task Drivers)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/IDEAS:
	If this code remains in DosapplCode, the caller MUST use
	ProcCallFixedOrMovable to call it, since (as the existence of this
	routine implies), the ResourceCallInt vectors are suspect.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	2/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosExecInsertMovableVector		proc	far
		uses	ax, bx, cx, dx, si, di, ds
		.enter

		LoadVarSeg	ds, ax
	;
	; We've got to use ProcCallModuleRoutine, since the RCI vectors may be
	; mush....
	;
		mov	ax, offset ReplaceMovableVector
		mov	bx, handle ReplaceMovableVector
		call	ProcCallModuleRoutine

		.leave
		ret
DosExecInsertMovableVector		endp

DosapplCode	ends
