COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Loader
FILE:		path.asm

ROUTINES:
	Name			Description
	----			-----------
   	GetPaths		Parse all paths set for GEOS directories

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

DESCRIPTION:

	$Id: path.asm,v 1.2 98/05/01 17:31:56 martin Exp $

------------------------------------------------------------------------------@

stdPathKeys	nptr	\
	topKey, worldKey, documentKey, systemKey, privdataKey, stateKey,
	fontKey, spoolKey, sysapplKey, userdataKey, mouseKey, printerKey,
	fsKey, videoKey, swapKey, kbdKey, fontDrKey, impexKey,
	taskKey, helpKey, templateKey, powerKey, dosroomKey, hwrKey, wasteKey,
	backupKey, pagerKey

topKey		char	"top", 0
worldKey	char	"world", 0
documentKey	char	"document", 0
systemKey	char	"system", 0
privdataKey	char	"privdata", 0
stateKey	char	"state", 0
fontKey		char	"userdatafont", 0
spoolKey	char	"privdataspool", 0
sysapplKey	char	"systemsysappl", 0
userdataKey	char	"userdata", 0
mouseKey	char	"systemmouse", 0
printerKey	char	"systemprinter", 0
fsKey		char	"systemfs", 0
videoKey	char	"systemvideo", 0
swapKey		char	"systemswap", 0
kbdKey		char	"systemkbd", 0
fontDrKey	char	"systemfont", 0
impexKey	char	"systemimpex", 0
taskKey		char	"systemtask", 0
helpKey		char	"userdatahelp", 0
templateKey	char	"userdatatemplate", 0
powerKey	char	"systempower", 0
dosroomKey	char	"dosroom", 0
hwrKey		char	"systemhwr", 0
wasteKey	char	"privdatawaste", 0
backupKey	char	"privdatabackup", 0
pagerKey	char	"systempager", 0
compKey		char	"systemcomp", 0


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetPaths

DESCRIPTION:	Parse all paths set for GEOS directories

CALLED BY:	LoadGeos

PASS:
	ds, es - loader segment

RETURN:
	KLV_stdDirPaths - set to segment of path block (or 0 if no paths set)

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	foundAPath = false;
	for (each .ini file) {
	    if (FindCategory("paths")) {
		foreach key
	    }
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

GetPaths	proc	near

	call	StoreParamsForPaths		; store stuff for .ini routines

	mov	bx, offset loaderVars.KLV_initFileBufHan
iniFileLoop:
	mov	ax, ds:[bx]			; ax = segment
	mov	ds:[initFileBufPos].segment, ax
	mov	ds:[initFileBufPos].offset, 0
	call	FindCategory
	jc	categoryNotFound

	; found a "paths" category in this .ini file...

	mov	di, 0				;di = index of std path
stdPathLoop:
	push	ds:[initFileBufPos].offset

	; finish up StoreParams stuff

	push	di, es
	mov	ax, ds:[stdPathKeys][di]
	mov	ds:[keyStrAddr].offset, ax
	les	di, ds:[keyStrAddr]
	call	GetStringLength
	pop	di, es
	mov	ds:[keyStrLen], cx

	; try to find it

	call	FindKey
	jc	keyNotFound

	; found key, add path to data structure

	call	AddPathToDataStructure

keyNotFound:
	pop	ds:[initFileBufPos].offset
	add	di, 2
	cmp	di, StandardPath-1
	jnz	stdPathLoop

categoryNotFound:
	add	bx, size word
	cmp	bx, (offset loaderVars.KLV_initFileBufHan)+ \
						((size word)*MAX_INI_FILES)
	jz	done
	cmp	{word} ds:[bx], 0
	jnz	iniFileLoop
done:
	ret

GetPaths	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	StoreParamsForPaths

DESCRIPTION:	Store the parameters in local variables.

CALLED BY:	INTERNAL (LibInitFileWriteData, LibInitFileWriteString)

PASS:		ds:si	- category ASCIIZ string
		cx:dx	- key ASCIIZ string

RETURN:		all parameters stored away in variables

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

StoreParamsForPaths	proc	near
	push	ds
	LoaderDS

	mov	ds:[catStrAddr].offset, offset pathsCategoryString
	mov	ds:[catStrAddr].segment, ds
	mov	ds:[keyStrAddr].segment, ds

	mov	ds:[catStrLen], size pathsCategoryString

	pop	ds
	ret

StoreParamsForPaths	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddPathToDataStructure

DESCRIPTION:	Add a path to the std path data structure

CALLED BY:	GetPaths

PASS:
	ds, es - loader
	di - StandardPath enum - 1
	KLV_stdDirPaths - set to segment of path block (or 0 if no paths yet)
	initFileBufPos - offset to start of data

RETURN:
	KLV_stdDirPaths - updated

DESTROYED:
	ax, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

AddPathToDataStructure	proc	near	uses bx, di, bp, es
	.enter

	mov	bp, di			;bp = StandardPath enum

	; create path block if it does not already exist and create entry

	call	CreatePathBlockAndEntry

	; create buffer of stack with data to copy into path block

	sub	sp, INI_PATH_BUFFER_SIZE
	mov	di, sp
	segmov	es, ss
	mov	cx, INI_PATH_BUFFER_SIZE
	call	ReconstructString		;es:di = string

DBCS <	call	ConvertLoaderStringInPlace				>

	call	NullTerminatePathElements	;cx = path size

	; add this path to the appropriate std path entry

	call	AddStdPathEntry

	add	sp, INI_PATH_BUFFER_SIZE

	.leave
	ret

AddPathToDataStructure	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertLoaderStringInPlace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a SBCS string to DBCS using the same buffer

CALLED BY:	(INTERNAL) AddPathToDataStructure
PASS:		es:di	= null-terminated string in KernelLoaderVars to convert
RETURN:		es:di	= null-terminated converted string in same buffer
DESTROYED:	ax, cx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	allen	9/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	DBCS_PCGEOS

ConvertLoaderStringInPlace	proc	near
	uses	di, ds
	.enter

	segmov	ds, es

	;
	; Find the ends of the source string (SBCS) and dest string (DBCS).
	;
	clr	ax
	mov	cx, -1
	repne	scasb
	dec	di
	mov	si, di			; ds:si = null char in src

	not	cx			; cx = length w/ null

	add	di, cx
	dec	di			; es:di = last wchar (dest)

	std

charLoop:
	lodsb
EC <	cmp	al, 0x80						>
EC <	ERROR_AE LS_MALFORMED_PATH_SPEC					>
	stosw
	loop	charLoop

	cld

	.leave
	ret
ConvertLoaderStringInPlace	endp

endif	; DBCS_PCGEOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateAndInitPathBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the path block and initialize it properly, setting
		the path for SP_TOP to be the top-level path we found
		and have in KLV_topLevelPath

CALLED BY:	CreatePathBlockAndEntry
PASS:		ds = es = loader segment
RETURN:		ax	= path block segment
		KLV_stdDirPaths set to same
DESTROYED:	di, cx, bx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateAndInitPathBlock proc near
	uses	bp
	.enter
	; alloc the block to the max size we allow

	mov	ax, MAX_PATH_BLOCK_SIZE
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE
	mov	bx, offset loaderVars.KLV_stdDirPaths
	call	LoaderSimpleAlloc		;ax = segment

	; initialize block by storing (size StdDirPaths) in SDP_blockSize
	; as well as in all of the SDP_pathOffsets array.

	push	es
	mov	es, ax
	clr	di
	mov	ax, size StdDirPaths
	mov	cx, (StandardPath / 2) + 1
	rep	stosw
	mov	ax, es
	pop	es

	.leave
	ret
CreateAndInitPathBlock	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CreatePathBlockAndEntry

DESCRIPTION:	Create path block if it does not already exist

CALLED BY:	AddPathToDataStructure

PASS:
	bp - std path entry to create - 1 (to index SDP_pathOffsets)
	ds, es - loader segment
	KLV_stdDirPaths - set to segment of path block (or 0 if no paths set)

RETURN:
	KLV_stdDirPaths - set

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

CreatePathBlockAndEntry	proc	near	uses di, ds
	.enter

	; if block does not exist then create it

	mov	ax, ds:[loaderVars].KLV_stdDirPaths
	tst	ax
	jnz	haveBlock

	call	CreateAndInitPathBlock

haveBlock:
	mov	ds, ax

	; if no entry exists for the path, create an empty one (just a null
	; terminator)

	mov	si, ds:[SDP_pathOffsets][bp]
	cmp	si, ds:[SDP_pathOffsets][bp][2]
	jnz	entryExists

	; no entry exists -- insert a char here

	mov	ax, size TCHAR
	call	InsertBytesInPathBlock
	LocalClrChar	ds:[si]

entryExists:

	.leave
	ret

CreatePathBlockAndEntry	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	InsertBytesInPathBlock

DESCRIPTION:	Insert bytes in a path block

CALLED BY:	CreatePathBlockAndEntry

PASS:
	ds - path block
	bp - StandardPath - 1
	ax - number of bytes to insert
	si - offset to insert at

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

InsertBytesInPathBlock	proc	near	uses	cx, si, di, ds, es
	.enter

	; insert the bytes

	mov	cx, ds:[SDP_blockSize]
	sub	cx, si			;cx = count
	inc	cx

	mov	si, ds:[SDP_blockSize]	;ds:si = source (end of block)
	dec	si
	segmov	es, ds			;es = path block
	mov	di, si
	add	di, ax			;es:di = dest
	std
	rep	movsb
	cld

	; fix up pointers (including SDP_blockSize)

	mov	si, bp
fixLoop:
	add	si, 2
	add	ds:[si], ax
	cmp	si, offset SDP_blockSize
	jnz	fixLoop

	.leave
	ret

InsertBytesInPathBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddStdPathEntry

DESCRIPTION:	Create path block if it does not already exist

CALLED BY:	AddPathToDataStructure

PASS:
	bp - std path entry to create - 1
	ds, es - loader segment
	KLV_stdDirPaths - set to segment of path block
	es:di - string to add (at end of existing path)
	cx - size of string to add (including null)

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

AddStdPathEntry	proc	near	uses	di, ds, es
	.enter

	; add at end of path

	mov	ds, ds:[loaderVars].KLV_stdDirPaths
	mov	si, ds:[SDP_pathOffsets][bp][2]
	LocalPrevChar	dssi			;si points at null

	mov	ax, cx
	call	InsertBytesInPathBlock

	; ds:si - point to insert at
	; es:di - bytes to insert

	segxchg	ds, es
	xchg	si, di

	; ds:si - bytes to insert
	; es:di - point to insert at

	rep	movsb

	.leave
	ret

AddStdPathEntry	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NullTerminatePathElements

DESCRIPTION:	Null terminate elements in path found in .ini file

CALLED BY:	AddPathToDataStructure

PASS:
	es:di - string from .ini file

RETURN:
	cx - size of fixed up string

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

NullTerminatePathElements	proc	near	uses	di, ds
	.enter

	segmov	ds, es
	mov	dx, di			;dx = string start
	mov	si, di			;si = source, di = dest

	; loop #1: skip over whitespace chars that separate elements. done
	; first to deal with things like:
	; 	systemfs = {
	; 		g:\foo\fs
	; 	}

	clr	bx		; set bx to 0 so we bitch if the string
				; is devoid of all meaning.

skipSeparator:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	done
	LocalCmpChar	ax, C_SPACE
	je	skipSeparator
	LocalCmpChar	ax, C_TAB
	je	skipSeparator
	LocalCmpChar	ax, C_CR
	je	skipSeparator
	LocalCmpChar	ax, C_LF
	jz	skipSeparator
	LocalPrevChar	dssi		; point back to non-space

	; loop #2: skip over chars until we find a separator or the end of
	; the string.

	mov	bx, 1		; haven't seen colon yet

endOfElementLoop:
	LocalGetChar	ax, dssi
	LocalPutChar	esdi, ax
	LocalIsNull	ax
	jz	done
	LocalCmpChar	ax, C_COLON
	je	seenColon
	LocalCmpChar	ax, C_BACKSLASH
	je	seenBackslash
	tst	bx		; expecting backslash (right after colon)?
	jz	malformed	; yes -- didn't get it, so bad path

	LocalCmpChar	ax, C_SPACE	; was this a separator?
	je	nullIt		; ja
	LocalCmpChar	ax, C_TAB
	je	nullIt		; ja
	LocalCmpChar	ax, C_CR
	je	nullIt		; ja
	LocalCmpChar	ax, C_LF
	jne	endOfElementLoop; nein

nullIt:
	; found space (separator) -- null terminate component and look for
	; next component

	mov	{TCHAR} ds:[di]-size TCHAR, 0
	jmp	skipSeparator

done:
	tst	bx
	jns	malformed	; => neither colon nor backslash, or only
				;  a colon, so bitch

	mov	cx, di
	sub	cx, dx

	.leave
	ret

malformed:
	ERROR	LS_MALFORMED_PATH_SPEC

seenColon:
	dec	bx		; should reduce this to 0. If not (more than
				;  one colon in the path), path is
	jnz	malformed	;  malformed
	jmp	endOfElementLoop

seenBackslash:
	dec	bx		; should reduce this below 0, or keep it below
				;  0 (if initial path already seen). If not
				;  (backslash comes before colon), path is
				;  malformed
	js	endOfElementLoop
	LocalCmpChar	ds:[si], C_BACKSLASH	; network path (double-backslash)?
	je	endOfElementLoop	; yes -- it's ok (XXX: check if \\ at
					;  start of string...)
	jmp	malformed

NullTerminatePathElements	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ParseCmdLineStdPaths

DESCRIPTION:	Scan for each "/sp<std path name>:<path>" that is on the
		command line, and insert the <path> string into the Standard
		Paths list for <std path name>. Note: if a path is specified
		for SP_TOP, it will be placed at the head of the path list
		for SP_TOP, but it will still follow the primary SP_TOP path
		which is defined by loaderVars.topLevelPath.

CALLED BY:	LoadGeos

PASS:		ds, es	= loader segment

RETURN:		ds, es	= same
		KLV_stdDirPaths = updated

DESTROYED:	ax, bx, cx, dx, bp, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EDS	4/25/93		Initial version

------------------------------------------------------------------------------@

ifidn	HARDWARE_TYPE, <PC>

ParseCmdLineStdPaths	proc	near
	uses	ds, es
	.enter

	; Search throught the command tail

	mov	es, ds:[loaderVars].KLV_pspSegment

	mov	di, offset PSP_cmdTail
	mov	dl, es:[di]			;dl = number of chars on line
	clr	dh				;dx = number of chars on line
	inc	di				;point past count

	segmov	ds, cs, ax			;ds = kdata and this code res.

scanForArg:
	;Begin to scan the line for "/sp_" args

	mov	cx, dx				;cx = number of remaining chars
	tst	cx				;must also check for negative
	jz	jzToDone			;abort if done...
	js	jsToDone			;abort if done...

	mov	al, '/'				; al = 1st char of argument

next:
	repne	scasb				; scan for delimiter
	jne	jneToDone			; if none, found, we're done

	cmp	{byte} es:[di]+0, 's'
	je	foundS

	cmp	{byte} es:[di]+0, 'S'
	jne	next

foundS:
	cmp	{byte} es:[di]+1, 'p'
	je	foundP

	cmp	{byte} es:[di]+1, 'P'
	jne	next

foundP:
	cmp	{byte} es:[di]+2, '_'
	jne	next

foundArgument::
	add	di, 3
	sub	cx, 3				;cx = number of chars remaining
jsToDone:
	js	done				;skip if we were fooled...
jzToDone:
	jz	done				;skip if null arg...

	mov	dx, cx

	;We found the path argument. Find the end of the std path name
	;	es:di = std path name, followed by ":" and path.
	;	cx = number of remaining chars in command line
	;	dx = number of remaining chars in command line

	push	di
	mov	al, ':'
	repne	scasb				;look for ":" char or end of
						;string, whichever comes first
	mov	bx, di				;es:bx = location of ":"+1
	pop	di				;es:di = std path name
jneToDone:
	jne	done				;if none at all, then abort...

	dec	bx				;es:bx = location of ":"

	mov	cx, bx
	sub	cx, di				;cx = length of std path name

	;see if this is a standard path name

	mov	bp, StandardPath-1

nextStdPath:
	sub	bp, 2
	js	scanForArg			;could not find match for this
						;std path name. Loop for next
						;arg on the line...

	mov	si, ds:[stdPathKeys][bp]	;ds:si = one string
	push	cx, di
	repe	cmpsb				;
	pop	cx, di
	jne	nextStdPath			;skip if do not match

	cmp	byte ptr ds:[si], 0		;make sure we have reached end
						;of string from table
	jne	nextStdPath			;loop if not...

foundStdPath::
	;we've found a std. path spec on the command line.
	;	bp = StandardPath enum

	mov	di, bx				;es:di = location of ":"
	inc	di				;es:di = start of path string
	dec	dx

	sub	dx, cx				;dx = # chars remaining on line
	jle	done				;abort if reached end...

	;find the end of this path string

	mov	cx, dx				;cx = number of chars left
	push	di
	mov	al, ' '				;search for space or EOL
	repne	scasb				;whichever comes first

	; Added 12/94 - if space found, then DI is AFTER space, so
	; back up.

	jne	atEnd
	dec	di
atEnd:
		mov	cx, di				;cx = char after end

	mov	bl, es:[di]			;remember that char
	mov	byte ptr es:[di], 0		;stuff a temporary 0 in

	pop	di

	sub	cx, di				;cx = length of path

	;Create path block if it does not already exist, and create
	;null entry for SP_TOP.
	;
	;	bp = StandardPath enum
	;	es:di = path string
	;	cx = length of string
	;
	;	dx = number of chars remaining on line

	push	bx, cx, dx
	call	CreatePathBlockAndEntry
	pop	bx, cx, dx

	;Add this path to the appropriate std path entry

	push	dx, cx, bx
	inc	cx				;account for null term at end
	call	AddStdPathEntry
	pop	dx, cx, bx

	add	di, cx				;di = first char after path
	mov	es:[di], bl			;repair it
	sub	dx, cx				;adjust count to end of line

	;loop to scan for next argument (es:di = this path, but it will
	;be skipped as we scan for the next arg)

	jmp	scanForArg

done:
	.leave
	ret
ParseCmdLineStdPaths	endp

endif
