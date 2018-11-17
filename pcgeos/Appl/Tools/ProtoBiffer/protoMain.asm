COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Appl/Tools/ProtoBiffer
FILE:		protoMain.asm

AUTHOR:		Don Reeves: July 29, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/29/91		Initial revision


DESCRIPTION:
	Main routines for the protocol biffer application

	$Id: protoMain.asm,v 1.1 97/04/04 17:15:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	ProtoClass	mask CLASSF_NEVER_SAVED

	protocolBuffer	ProtocolNumber	<1, 0>
idata	ends

udata	segment
	geodesCheckedCount	word
	geodesTweakedCount	word
	geodesFailureCount	word
udata	ends


Utils	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProtoBegin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the process of going through the GEOS tree and
		modifying UI protocols

CALLED BY:	GLOBAL (METHOD_PROTO_BEGIN)

PASS:		DS, ES	= Dgroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProtoBegin	method dynamic ProtoClass, METHOD_PROTO_BEGIN
	.enter

	; First verify that we have selected a GEOS tree
	;
	clr	ds:[geodesCheckedCount]
	clr	ds:[geodesTweakedCount]
	clr	ds:[geodesFailureCount]
	call	FilePushDir
	call	VerifyGeosTree
	jc	done

	; If everything is OK, display the action status box
	;
	call	OpenActionStatusBox

	; And begin the file enumerations
	;
	call	EnumerateTree

	; Close the action status box
	;
	call	CloseActionStatusBox

	; Display the results
	;
	call	DisplayResultsBox

done:
	call	FilePopDir
	
	.leave
	ret
ProtoBegin	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyGeosTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the top-level directory that user has selected, and
		verify that it is a GEOS tree.

CALLED BY:	ProtoBegin

PASS:		DS, ES	= DGroup

RETURN:		Carry	= Clear if a GEOS tree
			= Set otherwise

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Sets current path to top of GEOS tree

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kernelName	byte	'GEOS.GEO', 0
kernelPath	byte	'SYSTEM', 0

VerifyGeosTree	proc	near
sourcePath	local	PATH_BUFFER_SIZE dup (char)
	uses	ds
	.enter
	
	; Get the Path selected by the user
	;
	push	bp				; save local variables frame
	GetResourceHandleNS	SourceSelector, bx
	mov	si, offset SourceSelector
	mov	ax, MSG_GEN_PATH_GET
	mov	cx, size sourcePath
	mov	dx, ss
	lea	bp, ss:[sourcePath]		; buffer => DX:BP
	mov	di, mask MF_CALL
	call	ObjMessage			; fill buffer, handle => CX
	pop	bp				; restore local variables

	; Go to this directory, and then go to the SYSTEM subdirectory
	;
	mov	bx, cx				; disk handle => BX
	lea	dx, ss:[sourcePath]		; path => DS:DX
	call	FileSetCurrentPath
	jc	error
	call	FilePushDir
	clr	bx
	segmov	ds, cs
	mov	dx, offset kernelPath
	call	FileSetCurrentPath
	jc	errorKernelDir

	; Now check for the Kernel (non-EC)
	;
	segmov	ds, cs
	mov	dx, offset kernelName		; file name => DS:DX
	mov	al, FullFileAccessFlags<1, FE_EXCLUSIVE, 0, 0, FA_READ_WRITE>
	call	FileOpen
	jnc	closeFile			; if no carry, success
	cmp	ax, ERROR_FILE_NOT_FOUND	; if not ERROR_FILE_NOT_FOUND
	jne	success				; then we have a GEOS directory

	; Else we have an error. Display something to user
error:
	mov	cx, ss
	lea	dx, sourcePath			; CX:DX = path selected
	mov	ax, offset notGeosTreeText	; error to display => AX
	call	DisplayError			; show an error
	stc
	jmp	done
success:
	call	FilePopDir			; current path is now system top
	clc					; success (once inverted)
done:
	.leave
	ret

	; Close the file we opened above
	;
closeFile:
	mov	bx, ax				; file handle => BX 
	clr	al				; ignore errors
	call	FileClose			; close the file
	jmp	success

	; Pop the saved directory and be done
	;
errorKernelDir:
	call	FilePopDir
	jmp	error
VerifyGeosTree	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumerateTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go through the entire GEOS tree, finding all geodes. The
		callback routine does the actual work of determining what to
		do with the protocol, etc.

CALLED BY:	ProtoBegin, self

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:
		Start with current path, assumed set earlier.
		Find all files in current directory
			For each geode (*.GEO), call callback
			Recurse on all directories in current directory

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		No assumptions are made as to where geodes can be found, so
		this is slower than it could be.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FILES_AT_ONE_TIME 	= 20		; files to enumerate in one pass

EnumerateTree	proc	near
	uses	bp
	.enter
	
	; Some set-up work
	;
	call	DisplayCurrentDirectory	; tell user where we are
	clr	bx			; start with an empty buffer handle
	clr	di			; skip no files initially

	; Now grab FILES_AT_ONE_TIME files, until we have all of them
	;
enumerate:
	push	bx			; save the previous file buffer
	sub	sp, size FileEnumParams
	mov	bp, sp				; FileEnumParams => SS:BP
	mov	ss:[bp].FEP_searchFlags, mask FESF_REAL_SKIP or \
					 mask FESF_DIRS or \
					 mask FESF_GEOS_EXECS
	clr	ss:[bp].FEP_matchAttrs.segment
	clr	ss:[bp].FEP_returnAttrs.segment
	mov	ss:[bp].FEP_returnAttrs.offset, FESRT_NAME_AND_ATTR
	mov	ss:[bp].FEP_returnSize, (size FENameAndAttr)
	mov	ss:[bp].FEP_bufSize, FILES_AT_ONE_TIME
	mov	ss:[bp].FEP_skipCount, di
	call	FileEnum		; load those files (cleans up stack)
	jc	done			; if error, stop file enumeration
	tst	dx			; any files left ??
	jnz	enumerate

	; Now we have all of the files in one or more buffers
	; Go through each buffer, and perform the appropriate action
	; on each element found (of type FENameAndAttr)
	;
	jcxz	doneFiles		; no files - we're done
bufferLoop:
	clr	si			; start at beginning of buffer
	call	MemLock
	mov	ds, ax
innerLoop:
	test	ds:[si].FENAA_attr, mask FA_SUBDIR
	jnz	handleRecursion
	add	si, offset FENAA_name
	call	MangleProtocol		; do the real work
nextFile:
	add	si, (size FENameAndAttr) - (offset FENAA_name)
	loop	innerLoop
	call	MemFree			; we're done - free the file buffer
doneFiles:
	pop	bx			; get the next buffer
	mov	cx, FILES_AT_ONE_TIME	; # of files in buffer => CX
	tst	bx			; any more buffers ?
	jnz	bufferLoop
	push	bx			; push a zero word on the stack

	; We're done. Clean up. Dgroup is in ES. Pop stack until we get zero.
	;
done:
	pop	bx			; clean up the stack
	tst	bx			; is the word zero ??
	jz	exit
	call	MemFree			; else free the memory handle
	jmp	done
exit:
	segmov	ds, es			; DGroup => DS

	.leave
	ret

	; Handle recursion on directories
	;
handleRecursion:
	call	FilePushDir		; save the current directory
	add	si, offset FENAA_name	
	push	bx, cx, ds, si		; save some registers
	mov	dx, si			; directory name => DS:DX
	clr	bx			; user current disk handle
	call	FileSetCurrentPath
	call	EnumerateTree		; do this directory
	pop	bx, cx, ds, si		; restore registers
	call	FilePopDir		; restore old directory
	call	DisplayCurrentDirectory	; tell user where we are
	jmp	nextFile
EnumerateTree	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MangleProtocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks at the geode and determines what to do with it.

CALLED BY:	GLOBAL

PASS:		DS:SI	= Geode longname
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

uiName	byte	'Generic User Interface'

MangleProtocol	proc	near
	uses	ax, bx, cx, dx, di, si, bp
	.enter
	
	; Tell user what file we're working with
	;
	inc	es:[geodesCheckedCount]
	xchg	ax, si				; filename => DS:AX
	mov	si, offset ActionStatusText	; GenTextObject => SI
	call	StuffTextObject			; stuff the text	
	
	; Open the file, and determine what to do
	;
	xchg	dx, ax				; filename => DS:DX
	mov	al, FullFileAccessFlags<1, FE_EXCLUSIVE, 0, 0, FA_READ_WRITE>
	call	FileOpen			; file handle => AX
	jc	errorOpen

	; Do we have the UI, or some other geode ??
	;
	xchg	bx, ax				; file handle => BX
	mov	cx, (size uiName)		; bytes to check => CX
	push	es				; save DGroup
	segmov	es, cs
	mov	di, offset uiName		; UI name => ES:DI
	mov	si, dx				; file name => DS:SI
	repe	cmpsb				; check first CX bytes
	pop	es				; restore DGroup
	jnz	doGeode

	call	MangleUI
	jc	errorWrite			; if error, tell user
doGeode:
	call	MangleGeode
	jc	errorWrite			; if error, tell user
done:
	clr	al				; ignore (but deal with) errors
	call	FileClose			; close file handle in BX
exit:
	.leave
	ret

	; We've encountered an error opening the file. Let the user know.
	;
errorOpen:
	inc	es:[geodesFailureCount]
	mov	ax, offset cantOpenFileText
	mov	cx, ds
	call	DisplayError
	jmp	exit

	; We've encountered an error writing to the file. Let the user know.
	;
errorWrite:
	inc	es:[geodesFailureCount]
	mov	ax, offset fileWriteErrText
	mov	cx, ds
	call	DisplayError
	jmp	done
MangleProtocol	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MangleUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the UI's protocol to be something earlier than it
		is currently, to prevent people from using a standard UI
		geode.

CALLED BY:	MangleProtocol

PASS:		BX	= File handle

RETURN:		Carry	= Set if error
			= Clean if success

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MangleUI	proc	near
	uses	ax, cx, dx, ds
	.enter
	
	; Move to the GeosFileHeaderCore
	;
	mov	al, FILE_POS_START
	clr	cx
	mov	dx, offset GFH_protocol		; seek position => CX:DX
	call	FilePos				; perform the seek

	; Write a new protocol there
	;
	segmov	ds, es
	mov	dx, offset protocolBuffer	; buffer => DS:DX
	mov	cx, size protocolBuffer		; # of bytes to write
	clr	al				; return errors
	call	FileWrite			; do the dirty deed
	jc	done

	; Now move to the GeodeHEader
	;
	mov	al, FILE_POS_START
	clr	cx
	mov	dx, size GeosFileHeader + \
		    size ExecutableFileHeader + \
		    offset GH_geodeProtocol
	call	FilePos

	; Again write the new protocol
	;
	mov	dx, offset protocolBuffer	; buffer => DS:DX
	mov	cx, size protocolBuffer		; # of bytes to write
	clr	al				; return errors
	call	FileWrite			; do the dirty deed
done:
	.leave
	ret
MangleUI	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MangleGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search a geode for use of the UI library. If such use is
		found, change the protocol accordingly.

CALLED BY:	GLOBAL

PASS:		BX	= File handle

RETURN:		Carry	= Set if error
			= Clear if success

DESTROYED:	DI, SI, BP

PSEUDO CODE/STRATEGY:
		Access the library entry points for this geode
		Loop through the table of ImportedLibraryEntry's,
			looknig for the UI. If found, change protocol

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		A lot of code is stolen from ProcessLibraryTable

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MangleGeode	proc	near
	uses	ax, cx, dx, ds
	.enter
	
	; Calculate offset for library table
	;
	call	FindImportLibraryTable		; file offset => AX
	jc	exit				; if error, we're done
	jcxz	exit				; if no libraries, we're done

	; Allocate stack space for library names
	;
	xchg	bp, ax				; offset => BP
	mov	si, cx				; count (for later) => SI
	mov	ax, size ImportedLibraryEntry	; compute table size
	mul	cx
	mov	cx, ax				; table size => CX
	mov	dx, sp				; SP to recover => DX
	sub	sp, cx
	mov	di, sp
	push	dx				; save original stack pointer

	; Read in library name table
	;
	push	cx				; save table size
	mov	al, FILE_POS_START
	clr	cx
	mov	dx, bp				; file offset => CX:DX
	call	FilePos				; seek to start of table
	pop	cx				; table size => CX
	segmov	ds, ss
	mov	dx, di				; buffer => DS:DX
	clr	al
	call	FileRead
	jc	done

	; Look for the UI library
	;
	mov	cx, si				; count => CX
libraryLoop:
	call	LookForUI			; look for the UI
	cmc					; invert the carry
	jnc	done
	add	bp, size ImportedLibraryEntry
	add	di, size ImportedLibraryEntry
	loop	libraryLoop
done:
	pop	dx
	mov	sp, dx				; clean up the stack		
exit:
	.leave
	ret
MangleGeode	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindImportLibraryTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the ImportedLibraryTable, given a geode file handle

CALLED BY:	GLOBAL

PASS:		BX	= File handle

RETURN:		Carry	= Clear (success)
		AX	= Offset to start of ImportedLibraryTable
		CX	= Number of imported libraries
			- or -
		Carry	= Set (failure)
		
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ((size GeosFileHeader) ge (size ExecutableFileHeader))
	TEMP_BUFFER_SIZE = size GeosFileHeader
else
	TEMP_BUFFER_SIZE = size ExecutableFileHeader
endif

GEODE_FILE_TABLE_SIZE	equ GH_geoHandle


FindImportLibraryTable	proc	near
	uses	bx, dx, di, si, bp, ds, es
	.enter
	
	; Position the file to its start
	;
	mov	al, FILE_POS_START
	clr	cx
	clr	dx				; go to start of file
	call	FilePos

	; Read the GeosFileHeader
	;
	segmov	ds, ss				; use stack space
	mov	bp, sp
	sub	sp, TEMP_BUFFER_SIZE		; allocate buffer large enough
	mov	dx, sp				; buffer => DS:DX
	push	bp				; save original stack
	mov	bp, dx
	clr	al
	mov	cx, size GeosFileHeader		; bytes to read => CX
	call	FileRead
	jc	error				; if error, abort

	; Check the file signature
	;
	cmp	{word} ss:[bp].GFH_signature, GFH_SIG_1_2
	jnz	error
	cmp	{word} ss:[bp].GFH_signature+2,GFH_SIG_3_4
	jnz	error
	cmp	ss:[bp].GFH_type, GFT_EXECUTABLE
	jnz	error

	; See if we have a specific UI. If so, change its protocol
	; This is no longer required for 2.0. Yeah!  -Don 8/4/00
	;
;;;	cmp	{word} ss:[bp].GFH_token.GT_chars+0, 'SP'
;;;	jne	continue
;;;	cmp	{word} ss:[bp].GFH_token.GT_chars+2, 'UI'
;;;	jne	continue
;;;	call	MangleUI			; else muck with the UI file
;;;	jc	error
		
	; Read in the executable file header
continue::
	mov	al, FILE_POS_START		; position correctly
	clr	cx
	mov	dx, size GeosFileHeader		; right after the header core
	call	FilePos
	mov	dx, bp				; buffer => DS:DX
	clr	al
	mov	cx, size ExecutableFileHeader	; bytes to read => CX
	call	FileRead
	jc	error

	; Now determine where the f*** the library table begins
	;
	mov	cx, ss:[bp].EFH_importLibraryCount
	mov	ax, size GeosFileHeader + \
		    size ExecutableFileHeader + \
		    GEODE_FILE_TABLE_SIZE
	clc
	jmp	done
error:
	stc
done:
	pop	bp
	mov	sp, bp				; restore the stack

	.leave
	ret
FindImportLibraryTable	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LookForUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for a ImportedLibraryEntry using the UI library

CALLED BY:	MangleGeode

PASS:		ES	= DGroup
		SS:DI	= ImportedLibraryEntry
		BX	= File handle
		BP	= Offset from start of file to ImportedLibraryEntry

RETURN:		Carry	= Set if found
			= Clear if not

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

uiLibName	char	'ui      '		; UI followed by six spaces

LookForUI	proc	near
	uses	ax, cx, dx, di, si, ds
	.enter
	
	; Look for the UI name
	;
	push	es
	segmov	es, ss				; string => ES:DI
	segmov	ds, cs
	mov	si, offset uiLibName		; UI name => DS:SI
	mov	cx, GEODE_NAME_SIZE
	repe	cmpsb				; check first CX bytes
	pop	es
	clc					; assume not found
	jnz	done

	; Seek to the correct location in the file
	;
	mov	ax, FILE_POS_START
	clr	cx
	mov	dx, bp
	add	dx, offset ILE_protocol		; file offset => CX:DX
	call	FilePos				; seek to correct location
	
	; Now write the new protocol into the file
	; 	
	segmov	ds, es
	mov	dx, offset protocolBuffer	; buffer => DS:DX
	mov	cx, size protocolBuffer		; # of bytes to write
	clr	al				; return errors
	call	FileWrite			; do the dirty deed
	inc	es:[geodesTweakedCount]
	stc
done:
	.leave
	ret
LookForUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Status Display Procedures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenActionStatusBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the Action Status dialog box

CALLED BY:	INTERNAL
	
PASS:		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

blankText	byte 0

OpenActionStatusBox	proc	near
	uses	ds
	.enter

	; Set the current directory being displayed.
	;
	call	DisplayCurrentDirectory

	; Clear out the current text displays
	;
	segmov	ds, cs
	mov	ax, offset blankText
	mov	si, offset ActionStatusText	; GenTextObject => SI
	call	StuffTextObject			; stuff the text	

	; Actually bring up the dialog box
	;
	GetResourceHandleNS	ActionStatusBox, bx
	mov	si, offset ActionStatusBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
OpenActionStatusBox	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayCurrentDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the current directory in the status box.

CALLED BY:	OpenActionStatusBox

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

dirText	byte	'<Scanning Directory>', 0

DisplayCurrentDirectory	proc	near
curdir		local	PATH_BUFFER_SIZE + VOLUME_BUFFER_SIZE + 4 dup(char)
		uses	bx, cx, dx, si, ds, es
		.enter
	;
	; Find the disk handle of the current directory.
	;
		clr	cx
		call	FileGetCurrentPath
	;
	; Point es:di to our buffer and store the initial [ there.
	;
		segmov	es, ss
		lea	di, ss:[curdir]
		mov	al, '['
		stosb
	;
	; Fetch the volume name from the disk handle.
	;
		call	DiskGetVolumeName
	;
	; Find the null-terminator.
	;
		clr	al
		mov	cx, size curdir - 1
		repne	scasb
	;
	; Store '] ' over the null terminator and the following byte
	;
		dec	di
		mov	ax, ']' or (' ' shl 8)
		stosw
		dec	cx
	;
	; Fetch the directory, now.
	;
		segmov	ds, es
		mov	si, di
		call	FileGetCurrentPath
	;
	; Set the result as the text for the DirectoryText object.
	;
		mov	ax, bp
		add	ax, offset curdir	; text => DS:AX
		mov	si, offset DirectoryText
		call	StuffTextObject
	;
	; Stuff in something to the file name text object
	;
		segmov	ds, cs
		mov	ax, offset dirText	; text => DS:AX (unlocalizable)
		mov	si, offset ActionStatusText
		call	StuffTextObject

		.leave
		ret
DisplayCurrentDirectory	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuffs the source name text into the passed GenText object

CALLED BY:	INTERNAL
	
PASS:		DS:AX	= Text
		SI	= Handle of GenText object in Interface resource

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StuffTextObject	proc	near
	uses	ax, bx, cx, dx, bp, di
	.enter

	clr	cx				; text is NULL terminated
	mov	dx, ds
	xchg	bp, ax				; text => DX:BP
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	GetResourceHandleNS	Interface, bx
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
StuffTextObject	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseActionStatusBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring down the action status dialog box

CALLED BY:	INTERNAL
	
PASS:		Nothing

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CloseActionStatusBox	proc	near
	.enter

	; Bring down the dialog box
	;
	GetResourceHandleNS	ActionStatusBox, bx
	mov	si, offset ActionStatusBox
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_CALL
	call	ObjMessage

	; Make a "done" noise
	;
	mov	ax, SST_NOTIFY
	call	UserStandardSound

	.leave
	ret
CloseActionStatusBox	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayResultsBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the Action Status dialog box

CALLED BY:	INTERNAL
	
PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/6/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DisplayResultsBox	proc	near
	.enter

	; Set the counts
	;
	GetResourceHandleNS	Interface, bx
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	mov	cx, ds:[geodesCheckedCount]
	clr	bp				; determinate
	mov	si, offset Interface:ResultsCheckedValue
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	mov	cx, ds:[geodesTweakedCount]
	clr	bp				; determinate
	mov	si, offset Interface:ResultsTweakedValue
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	mov	cx, ds:[geodesFailureCount]
	clr	bp				; determinate
	mov	si, offset Interface:ResultsFailureValue
	clr	di
	call	ObjMessage

	; Finally, display the dialog box
	;
	mov	si, offset Interface:ResultsBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
DisplayResultsBox	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Other Utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display an error to the user

CALLED BY:	GLOBAL

PASS:		AX	= Error string chunk handle
		CX:DX	= 1st string parameter
		BX:SI	= 2nd string parameter

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PROTO_ERROR_FLAGS equ CustomDialogBoxFlags<,CDT_WARNING, GIT_NOTIFICATION, >

DisplayError	proc	near
	uses	ax, bx, cx, dx, di, si, bp, ds
	.enter
	
	; Put up the error box (always an error for now)
	;
	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customFlags, PROTO_ERROR_FLAGS
	mov	ss:[bp].SDP_stringArg1.segment, cx
	mov	ss:[bp].SDP_stringArg1.offset, dx
	mov	ss:[bp].SDP_stringArg2.segment, bx
	mov	ss:[bp].SDP_stringArg2.offset, si
	mov_tr	si, ax				; ProtoBifferError => SI
	mov	bx, handle Strings
	call	MemLock				; lock the block
	mov	ds, ax				; set up the segment
	mov	si, ds:[si]			; dereference the handle
	mov	ss:[bp].SDP_customString.segment, ax
	mov	ss:[bp].SDP_customString.offset, si
	clr	ss:[bp].SDP_helpContext.segment
	call	UserStandardDialog		; put up the dialog box

	; Clean up
	;
	mov	bx, handle Strings		; block handle to BX
	call	MemUnlock			; unlock the block

	.leave
	ret
DisplayError	endp

Utils	ends
