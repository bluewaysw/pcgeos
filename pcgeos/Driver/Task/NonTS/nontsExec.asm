COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nontsExec.asm

AUTHOR:		Adam de Boor, May  9, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 9/92		Initial revision


DESCRIPTION:
	Code that performs the actual exec.
		

	$Id: nontsExec.asm,v 1.1 97/04/18 11:58:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NTSExecCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSExecRunIt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run the program we were told to run.

CALLED BY:	NTSShutdownComplete
PASS:		ntsExecFrame 	= filled in
		ss 	= cs
		sp	= ntsExecFrame.NTSEF_stack
RETURN:		nope
DESTROYED:	

PSEUDO CODE/STRATEGY:
		When this function is jumped to, the whole block has been
		copied to the proper place and the PC/GEOS memory block
		shrunk down appropriately, and we're in the proper working
		directory, so all we have to do is perform the exec and recover
		from it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTSExecRunIt	proc	far
		assume	ds:NTSExecCode, es:NTSExecCode, ss:NTSExecCode
	;
	; Just do the exec, babe.
	; 
		segmov	ds, cs, ax
		mov	es, ax
		mov	dx, offset ntsExecFrame.NTSEF_args.DEA_prog.DEDAP_path
		mov	bx, offset ntsExecFrame.NTSEF_execBlock
		mov	ax, MSDOS_EXEC shl 8 or MSESF_EXECUTE
		int	21h
	;
	; Restore ds and ss:sp to their former pre-eminence.
	; 
		segmov	ds, cs, ax
		mov	ss, ax
		mov	sp, offset ntsExecFrame.NTSEF_stack+size NTSEF_stack
		jnc	backToTheBatCaveRobin
	;
	; Exec failed, so give error and force prompt before re-entry.
	; 
		mov	dx, ds:[ntsExecFrame].NTSEF_execError
		mov	ah, MSDOS_DISPLAY_STRING
		int	21h
		ornf	ds:[ntsExecFrame].NTSEF_args.DEA_flags, mask DEF_PROMPT
backToTheBatCaveRobin:
	;
	; Switch back to the boot path, since we've got the absolute path
	; of the loader.
	; 
		mov	dl, ds:[ntsExecFrame].NTSEF_bootPath[0]
		sub	dl, 'A'		; dl <- drive number
		mov	ah, MSDOS_SET_DEFAULT_DRIVE
		int	21h
		lea	dx, ds:[ntsExecFrame].NTSEF_bootPath[2]
		mov	ah, MSDOS_SET_CURRENT_DIR
		int	21h
	;
	; If DEF_PROMPT set, prompt user and wait for keystroke.
	; 
		test	ds:[ntsExecFrame].NTSEF_args.DEA_flags, mask DEF_PROMPT
		jz	getMemoryForReload
		
		mov	dx, ds:[ntsExecFrame].NTSEF_prompt
		mov	ah, MSDOS_DISPLAY_STRING
		int	21h
		mov	ax, MSDOS_FLUSH_AND_DO_CONSOLE shl 8 or \
				MSDOS_CONSOLE_INPUT
		int	21h		; al <- keyboard char
	    ;
	    ; If received char is escape, user wants to bail.
	    ; 
		cmp	al, C_ESCAPE
		jne	getMemoryForReload
		mov	ax, MSDOS_QUIT_APPL shl 8
		int	21h
		.unreached
getMemoryForReload:
	;
	; Now gain back all the memory we can for our beloved system.
	; 
		mov	es, ds:[ntsExecFrame].NTSEF_args.DEA_psp
		mov	bx, 0xffff		; find out how much the
						;  system has to give first
resizePSP:
		mov	ah, MSDOS_RESIZE_MEM_BLK
		int	21h
		jnc	resizeOK
		
		cmp	ax, ERROR_INSUFFICIENT_MEMORY
		jne	memError
	;
	; Couldn't get that much. See if what the system can give us will get
	; us back to where we were before. It won't be able to if we just ran
	; a TSR...
	; 
		mov	ax, es
		add	ax, bx
		cmp	ax, es:[PSP_endAllocBlk]
		jae	resizePSP		; if it gets us back where
						;  we were, accept it
	;
	; We just ran a TSR, so our only option is to allocate a new block
	; of memory and load the system there.
	; 
		mov	bx, 0xffff
allocNewBlock:
		mov	ah, MSDOS_ALLOC_MEM_BLK
		int	21h
		jnc	haveNewBlock
	;
	; Couldn't allocate that much. If the size available is less than
	; 256K we refuse to reload the system, else we accept our lot in life.
	; 
		cmp	ax, ERROR_INSUFFICIENT_MEMORY
		jne	memError
		
		cmp	bx, (256 * 1024) shr 4
		jae	allocNewBlock
memError:
	;
	; COULDN'T ALLOCATE ENOUGH MEMORY TO RELOAD
	; 
		mov	dx, ds:[ntsExecFrame].NTSEF_noMemory
		jmp	cantReloadHaveMsg
	;--------------------
resizeOK:
	;
	; Put resized segment into ax for calculating block-end
	; 
		mov	ax, es
haveNewBlock:
	;
	; Figure the end of stuff the loader will be able to play with and
	; store that in the PSP, whose segment remains steadfastly in ES.
	; 
		add	bx, ax
		mov	es:[PSP_endAllocBlk], bx
	;
	; If we actually were able to enlarge the block holding the PSP enough,
	; we don't want to load the thing *at* AX, but rather 256 bytes beyond
	; it, so we don't overwrite the PSP itself.
	; 
		cmp	ax, ds:[ntsExecFrame].NTSEF_args.DEA_psp
		jne	loadAtAX
		add	ax, size ProgramSegmentPrefix shr 4
loadAtAX:
	;
	; ax = segment at which to load the loader. Now must copy the
	; loading code up into high memory (bx = end of the block), jump
	; there, and perform the load.
	; 
		sub	bx, (size NTSReloadFrame + \
				(reloadFrame-NTSExecRunIt) + \
				15) shr 4
		mov	cx, es			; preserve PSP segment
	;
	; Set ES to where we'll be copying things, and switch to that stack.
	; 
		mov	es, bx
		mov	ss, bx
		mov	sp, offset reloadFrame.NTSRF_stack + size NTSRF_stack
	;
	; Store the segment at which we'll be reloading the loader into the
	; parameter block for MSESF_LOAD_OVERLAY that's now in high memory.
	; 
		mov	es:[reloadFrame].NTSRF_execBlock.DLOA_base, ax
		mov	es:[reloadFrame].NTSRF_execBlock.DLOA_reloc, ax
	;
	; Relocate the initial cs:ip and ss:sp for the loader by that base
	; segment, too.
	; 
		add	ds:[ntsExecFrame].NTSEF_loader.DELI_sssp.segment, ax
		add	ds:[ntsExecFrame].NTSEF_loader.DELI_csip.segment, ax
	;
	; Pass the segment of the PSP to the reload code.
	; 
		mov	es:[reloadFrame].NTSRF_psp, cx
	;
	; Set the segment of the far call we're about to make to the reload
	; code.
	; 
		mov	cs:[reloadCodeSegment], bx	
	;
	; Shift the reload code up into high memory.
	; 
		mov	si, offset doReload
		mov	di, offset doReload
		mov	cx, offset reloadFrame-offset doReload
		rep	movsb
	;
	; Shift the info about the loader up into high memory.
	; 
		mov	si, offset ntsExecFrame.NTSEF_loader
		mov	di, offset reloadFrame.NTSRF_loaderInfo
		mov	cx, size NTSRF_loaderInfo
		rep	movsb
	;
	; This is a decomposed far call, as Esp will always optimize a call to
	; a far label in the same segment into a push cs/call near ptr, which
	; we don't want...If the call returns, it means the reload failed and
	; we should give an appropriate message.
	; 
		.inst	byte	9ah		; far call
		.inst	word	offset doReload
reloadCodeSegment	label	sptr
		.inst	sptr	0

		segmov	ds, cs		; reload failed; ds:dx <- message
		mov	dx, ds:[ntsExecFrame].NTSEF_failedReload
cantReloadHaveMsg:
	;
	; Couldn't reload for some reason; tell the user this and exit. We
	; long since returned to the directory from which we came.
	; 
		mov	ah, MSDOS_DISPLAY_STRING
		int	21h
		
		mov	ax, MSDOS_QUIT_APPL shl 8
		int	21h
		.unreached
doReload:
	;------------------------------------------------------------
	; RELOAD THE LOADER USING THE STUFF THE LOW-MEM CODE COPIED UP
	; HERE.
	; es = cs already
	; 
		segmov	ds, cs			; ds:dx <- file to load
		mov	dx, offset reloadFrame.NTSRF_loaderInfo
		mov	bx, offset reloadFrame.NTSRF_execBlock
		mov	ax, MSDOS_EXEC shl 8 or MSESF_LOAD_OVERLAY
		int	21h
		jnc	jumpToLoader
		retf			; return to put up the error
jumpToLoader:
	;
	; Set up for the loader:
	; 	ss:sp	<- initial ss:sp for the thing
	; 	ds 	<- PSP
	; 	es	<- PSP
	; 
		mov	ss, cs:[reloadFrame].NTSRF_loaderInfo.DELI_sssp.segment
		mov	sp, cs:[reloadFrame].NTSRF_loaderInfo.DELI_sssp.offset
		mov	ax, cs:[reloadFrame].NTSRF_psp
		mov	ds, ax
		mov	es, ax
	;
	; Jump to its entry point.
	; 
		jmp	cs:[reloadFrame].NTSRF_loaderInfo.DELI_csip

		assume	ds:nothing, es:nothing, ss:nothing

reloadFrame	label	NTSReloadFrame
NTSExecRunIt	endp

ntsExecFrame	NTSExecFrame	<>

ntsEnvKindaStart label	char		; place at which to store the
					;  environment, after aligning to
					;  a paragraph boundary

NTSExecCode	ends

