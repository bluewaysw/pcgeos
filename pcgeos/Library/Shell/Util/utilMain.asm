COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Shell -- Util
FILE:		utilMain.asm

AUTHOR:		Martin Turon, October 30, 1992

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/30/92        Initial version

DESCRIPTION:
	Externally callable routines for this module.
	No routines outside this file should be called from outside this
	module.

	$Id: utilMain.asm,v 1.1 97/04/07 10:45:42 newdeal Exp $

=============================================================================@



COMMENT @-------------------------------------------------------------------
			ShellBuildFullFilename
----------------------------------------------------------------------------

DESCRIPTION:	Builds the full path and filename of the given file
		based on the current directory.

CALLED BY:	GLOBAL

PASS:		ds:dx	= filename
		bx	= handle of LMemBlock to add chunk to
			  (if 0, LMemBlock will be allocated)

RETURN:		carry set on error:
			- path too long to fit in buffer
			- invalid drive name given
		carry clear if OK:
			*es:di	= PathName
			bx	= disk handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/30/92	Initial version

---------------------------------------------------------------------------@
ShellBuildFullFilename	proc	far
		.enter

if ERROR_CHECK
	;
	; Validate that the filename is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif
		tst	bx
		jnz	haveMemBlock

		mov	ax, LMEM_TYPE_GENERAL
		clr	cx			; use default header
		call	MemAllocLMem

haveMemBlock:
		call	MemLock
		mov	es, ax

		push	ds
		mov	ds, ax
		clr	ax			; no ObjChunkFlags
		mov	cx, size PathName
		call	LMemAlloc
		pop	ds

		push	si
		mov_tr	di, ax
		mov	di, es:[di]
		mov	si, dx
		clr	bx, dx
		call	FileConstructFullPath
		pop	di
		.leave
		ret
ShellBuildFullFilename	endp



COMMENT @-------------------------------------------------------------------
			ShellCombineFileAndPath
----------------------------------------------------------------------------

DESCRIPTION:	Appends the given filename to the given path.

CALLED BY:	GLOBAL

PASS:		ds:dx	= FileLongName	(null terminated)
		es:di	= PathName 	(null terminated)

RETURN:		es:di	= PathName with FileLongName appended

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	PATH		FILENAME		RESULT

	""		"FOO"			"FOO"
	"FOO"		"BAR"			"FOO\BAR"
	"\"		"FOO"			"\FOO"
	"FOO\"		"BAR"			"FOO\BAR"

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/30/92	Initial version

---------------------------------------------------------------------------@
ShellCombineFileAndPath	proc	far
		uses	ax, bx, cx, di, si
		.enter

if ERROR_CHECK
	;
	; Validate that the filename is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif
		mov	bx, di		; start of path		
	;
	; Point es:di to the end of the path
	;

		clr	al
		mov	cx, size PathName
		repne	scasb
		dec	di

	;
	; If the path is null, then just tack on the filename, with no
	; leading slash
	;
		cmp	di, bx
		je	append

	;
	; If the character before the NULL is a backslash, then don't
	; add another one.
	;

		mov	al, C_BACKSLASH
		cmp	es:[di]-1, al			; have slash?
		je	append				; yes
		stosb					; else, store it
append:

	;
	; append away!
	;
		mov	si, dx
		LocalCopyString

		.leave
		ret
ShellCombineFileAndPath	endp



COMMENT @-------------------------------------------------------------------
		FileComparePathsEvalLinks
----------------------------------------------------------------------------

DESCRIPTION:	Takes two paths that may contain links and evaluates both
		before calling FileComparePaths on them.

CALLED BY:	GLOBAL


PASS:		cx - disk handle of path 1
		ds:si - pathname #1

		dx - disk handle of path #2
		es:di - pathname #2

RETURN:		carry:
			- set on error,
			  ax = FileError or PCT_ERROR
					(if failed in FileComparePaths)

			- clear if completed,
			  al - PathCompareType

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/1/92		Initial version

---------------------------------------------------------------------------@
FileComparePathsEvalLinks	proc	far
	uses	si, di, ds, es

path2	local	fptr	push	es, di
diskHandle2	local	word	push	dx
diskHandle1	local	word

	.enter

if ERROR_CHECK
	;
	; Validate that path 1 is not in a movable code segment
	;
FXIP<	push	bx, si						>
FXIP<	mov	bx, ds						>
FXIP<	call	ECAssertValidFarPointerXIP			>
	;
	; Validate that path 2 is not in a movable code segment
	;
FXIP<	mov	bx, es						>
FXIP<	mov	si, di						>
FXIP<	call	ECAssertValidFarPointerXIP			>
FXIP<	pop	bx, si						>
endif

	call	ShellAlloc2PathBuffers
	mov	di, offset PB2_path1

	clr	dx				; no <drivename:> neccessary
	mov	bx, cx				; bx, ds:si is path to evaluate
	mov	cx, size PathName
	call	FileConstructActualPath
	jc	done

	mov	ss:[diskHandle1], bx

	mov	bx, ss:[diskHandle2]
	lds	si, ss:[path2]
	mov	di, offset PB2_path2
	push	di
	call	FileConstructActualPath
	pop	di
	jc	done

	mov	dx, bx				; dx, es:di is path 2

	mov	cx, ss:[diskHandle1]
	segmov	ds, es
	mov	si, offset PB2_path1
	call	FileComparePaths
	clc

done:
	call	ShellFreePathBuffer
	.leave
	ret
FileComparePathsEvalLinks	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellFreePathBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a path buffer allocated by either
		ShellAllocPathBuffer or ShellAlloc2PathBuffers

CALLED BY:	GLOBAL

PASS:		es - segment of path buffer

RETURN:		nothing 

DESTROYED:	nothing, flags preserved 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShellFreePathBuffer	proc far
	uses	bx
	.enter
	pushf
	mov	bx, es:[PB_handle]
	call	MemFree
	popf

	.leave
	ret
ShellFreePathBuffer	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellAllocPathBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a path buffer on the heap, to avoid using up
		gobs of stack space

CALLED BY:	GLOBAL

PASS:		nothing 

RETURN:		es:di - path buffer
		es:0 - PathBuffer structure (es:0 is the handle of the
		block that should be freed by the caller)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShellAllocPathBuffer	proc far
	uses	ax
	.enter
	mov	ax, size PathBuffer
	call	AllocCommon
	mov	di, offset PB_path
	.leave
	ret
ShellAllocPathBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellAlloc2PathBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a buffer for 2 paths on the heap

CALLED BY:	GLOBAL

PASS:		nothing 

RETURN:		es:0 - PathBuffer2 structure (es:0 is the handle)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShellAlloc2PathBuffers	proc far
	uses	ax
	.enter
	mov	ax, size PathBuffer2
	call	AllocCommon
	.leave
	ret
ShellAlloc2PathBuffers	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to allocate the desired buffer

CALLED BY:	ShellAllocPathBuffer, ShellAlloc2PathBuffers

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocCommon	proc near
	uses	bx, cx	
	.enter

	mov	cx, (mask HAF_ZERO_INIT shl 8) or ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	es, ax
	mov	es:[PB_handle], bx
	.leave
	ret
AllocCommon	endp


