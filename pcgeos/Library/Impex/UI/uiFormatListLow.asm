COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/UI
FILE:		uiFormatListLow.asm

ROUTINES:
	Name			Description
	----			-----------
	FormatEnum		Find all formats that we could translate
	LocateLibraries		Locate translation libraries with given token
	ImpexCheckLibraryType	Called during FileEnum, checks type of xlat lib
	ProcessLibrary		Finds all formats from a single library
	AlphaSort		Callback for ChunkArraySort
	OpenLibrary		Opens a translation library as a file
	LoadExtendedInfo	Finds the format/info resource in the library

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/91		initial version
	don	11/91		Added comments, cleaned up code, etc.
	don	 5/92		Removed LocateResource, cleaned up code, changed
				name of file.

DESCRIPTION:
	$Id: uiFormatListLow.asm,v 1.1 97/04/04 23:09:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatListCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Locate all extended libraries with a given token and return
                a block of format and library descriptors giving all formats
                supported by the libraries.

CALLED BY:	FormatListSpecBuild

Pass:		ds	= if called internally from within Impex library,
			  the segment of the block containing FormatList
			  object, so it can report errors that way.  When
			  calling this routine from outside the Impex lib,
			  pass NULL_SEGMENT in ds.

		dx	= mask IFA_IMPORT_CAPABLE
				 - or -
			= mask IFA_EXPORT_CAPABLE
		bx	= ImpexDataClasses

Return:		bx	= FormatInfo block handle
		cx	= # of formats available
		carry	= clear
			 - or -
		cx	= ImpexError
		carry	= Set		

DESTROYED:	AX, DX, DI, BP

PSEUDO CODE/STRATEGY:
		Find all translation libraries in the impex directory

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		* We're going to ignore all memory errors

	The check for errors processing libs NEEDS more work since it turns
	out that if there is more than one error, only the first error
	dialog box will be put up and rest will be thrown out.

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy   3/91        	Initial version
	jenny	12/91		Cleaned up, added check for errors

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatEnum	proc	far
	uses	si, es
	.enter

	; Allocate and initialize a block to hold all the info.
	;
	push	ds			; save FormatList segment - needs to
					;   be on stack so the error reporting
					;   function will work properly
	mov	bp, bx			; bp <- data classes
	mov     ax, LMEM_TYPE_GENERAL
	mov	cx, size FormatInfo
	call	MemAllocLMem		; FormatInfo block => BX
	call	MemLock			; lock the sucker down
	mov	ds, ax			; FormatInfo => DS

	; Allocate and store the array for format descriptors
	;
	mov     bx, size lptr
	clr	cx, si
	call    ChunkArrayCreate
	mov     ds:[FI_formats], si

	; Allocate and store the array for library descriptors
	;
	mov	si, cx
	call    ChunkArrayCreate
	mov     ds:[FI_libraries], si
	mov	si, bp			; si <- data classes app. supports

	; Now locate all the libraries with the right token
	;
	call	ImpexChangeToImpexDir
	call    LocateLibraries		; bx <- buffer holding library names
	jcxz	done			; if none found, we're done

	; Now process each of the libraries found
	;
	call	MemLock
	mov	es, ax
	mov	si, dx			; si <- ImpexFormatInfo
	clr     dx			; es:dx <- start of libraries
processLoop:
	call    ProcessLibrary
	jc	libraryError
continue:
	add	dx, IMPEX_NAME_SIZE
	loop    processLoop
	call	MemFree			; free names block

	; Sort the array of formats alphabetically
	;
	mov     cx, SEGMENT_CS
	mov     dx, offset AlphaSort
	mov     si, ds:[FI_formats]
	call    ChunkArraySort

	; Figure the number of formats actually found.
	;
	mov     si, ds:[FI_formats]
	call    ChunkArrayGetCount	; cx <- number of formats

        ; Unlock the data block and return it.
done:
	mov     bx, ds:[LMBH_handle]
	call    MemUnlock
	call    FilePopDir
	pop	ds			; restore FormatList segment

	.leave
	ret

	; We encountered an error with a library, so notify the user
	; Pass:
	;	AX	= ImpexError
	;	DS	=  FormatInfo block
	;	top of stack = segment passed in to this routine
	; Destroy:
	;	AX, BP only!
libraryError:
	pop	bp
	push	bp
	cmp	bp, NULL_SEGMENT	; if not called by Impex library,
	je	continue		;   then don't display the error

	mov	bp, ax			; ImpexError => BP
	mov	ax, ds			; save current ds
	pop	ds			; ds <- FormatList segment
	push	ds
	push	cx
	mov	cx, es			; library name => CX:DX
	call	FormatListShowError	; display error to user
	pop	cx
	mov	ds, ax			; restore ds
	jmp	continue
FormatEnum  endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                LocateLibraries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Locate up to IMPEX_LIBRARIES_PER_ENUM libraries with the
                given token.

CALLED BY:      FormatEnum

PASS:		SI	= ImpexDataClasses

RETURN:		BX	= Buffer holding library names (= 0 if none found)
		CX	= Number of libraries found

DESTROYED:	AX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy   3/91	        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

impexCBAttrs	FileExtAttrDesc \
		<FEA_TOKEN>,
		<FEA_END_OF_LIST>

LocateLibraries proc  near
	uses	dx
	.enter  
if FULL_EXECUTE_IN_PLACE
	push	ds
	xchg	si, di				;di = ImpexDataClasses
	segmov	ds, cs, cx
	mov	si, offset impexCBAttrs
	mov	cx, (length impexCBAttrs) * (size FileExtAttrDesc)
	call	SysCopyToStackDSSI		;dssi = impexCBAttrs on stack
	xchg	si, di				;dsdi = impexCBAttrs on stack
						;si = ImpexDataClasses
endif

	mov_tr	ax, bp				; save bp in ax
	sub     sp, size FileEnumParams
	mov     bp, sp

	; Search for GEOS executables only.
	; Search by token, ignoring the manufacturer's ID.
	;
	mov	ss:[bp].FEP_searchFlags, mask FESF_GEOS_EXECS or \
					 mask FESF_CALLBACK

	; All matching will be done by the callback.
	;
	clr	ax
	mov	ss:[bp].FEP_matchAttrs.segment, ax

        ; Let the callback match only the characters from the passed token.
        ;
	mov	ss:[bp].FEP_cbData1.low, si	; data classes app supports
	mov	cx, SEGMENT_CS
	mov	ss:[bp].FEP_callback.high, cx
	mov	ss:[bp].FEP_callback.low, offset ImpexCheckLibraryType
if FULL_EXECUTE_IN_PLACE
	mov	ss:[bp].FEP_callbackAttrs.segment, ds
	mov	ss:[bp].FEP_callbackAttrs.offset, di
else
	mov	ss:[bp].FEP_callbackAttrs.segment, cs
	mov	ss:[bp].FEP_callbackAttrs.offset, offset impexCBAttrs
endif
	clr	ss:[bp].FEP_skipCount

	; Return only the file names.
	;
	mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
	mov	ss:[bp].FEP_returnSize, size ImpexFileName
	mov	ss:[bp].FEP_returnAttrs.segment, ax
	mov	ss:[bp].FEP_returnAttrs.offset, FESRT_NAME

        ; Seek and maybe ye shall find.
        ;
	mov_tr	bp, ax			; restore bp for callback routine ;)
	call    FileEnum		; bx <- handle of buffer

if FULL_EXECUTE_IN_PLACE
	pop	ds
	call	SysRemoveFromStack
endif
	.leave
	ret
LocateLibraries endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexCheckLibraryType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks at the token for each file, and sees if it matches
		the type of translation library we are searching for

CALLED BY:	LocateLibraries (via FileEnum)

PASS:		DS	= Segment of FileEnumCallbackData
                          
RETURN: 	Carry	= Clear - accept the file
			= Set   - reject the file

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
	jimmy	3/91		Initial version
	don	11/91		Re-written to save space/time

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

tokenTable	TokenTableStruct \
		< \
			mask IDC_TEXT, \
			XLAT_TOKEN_TEXT_12, \
			XLAT_TOKEN_TEXT_34>, \
		< \
			mask IDC_GRAPHICS, \
			XLAT_TOKEN_GRAPHICS_12, \
			XLAT_TOKEN_GRAPHICS_34>, \
		< \
			mask IDC_SPREADSHEET, \
			XLAT_TOKEN_SPREADSHEET_12, \
			XLAT_TOKEN_SPREADSHEET_34>, \
		< \
			mask IDC_FONT, \
			XLAT_TOKEN_FONT_12, \
			XLAT_TOKEN_FONT_34> \

ImpexCheckLibraryType	proc	far params:FileEnumParams
	uses	ax, bx, cx, di
	.enter  inherit far
	
	; Enter into a loop, comparing tokens
	;
	mov	ax, FEA_TOKEN
	call	FileEnumLocateAttr		; es:di <- attrs for token
	jc	done				; if error, reject file
	les	di, es:[di].FEAD_value		; es:di <- &token 
	clr	bx
	mov	cx, NUMBER_IMPEX_DATA_CLASSES
	mov	dx, ss:[params].FEP_cbData1.low
tokenLoop:
	test	dx, cs:[tokenTable][bx].TTS_type
	jz	next
	mov	ax, {word} es:[di].GT_chars+0
	cmp	ax, cs:[tokenTable][bx].TTS_tokenWord1
	jne	next
	mov	ax, {word} es:[di].GT_chars+2
	cmp	ax, cs:[tokenTable][bx].TTS_tokenWord2
	je	done				; we're done (carry clear)
next:
	add	bx, size TokenTableStruct
	loop	tokenLoop			; try next token type
	stc					; set carry (we fail)
done:
	.leave
	ret
ImpexCheckLibraryType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                ProcessLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Process a single extended library, locating all formats it
                supports, etc.

CALLED BY:      FormatEnum

PASS:		ES:DX	= Translation Library file name
		DS	= FormatInfo segment
		SI	= mask IFA_IMPORT_CAPABLE
				- or -
			= mask IFA_EXPORT_CAPABLE

RETURN:		DS	= FormatInfo segment (may have moved)
		Carry	= Clear
			- or -
		AX	= ImpexError
		Carry	= Set

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		get data from library about what formats is supports
		and put data into chunk array for later use

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy	3/91	       	Initial version
	jenny	12/91		Handle error msgs from LoadExtendedInfo

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProcessLibrary	proc  near
formatInfo	local	ImpexFormatInfo \
		push	si
dataSegment	local   sptr.FormatInfo
libraryChunk    local   word            ; chunk handle of new library descriptor
libraryClass	local	ImpexDataClasses
	uses	bx, cx, dx, di, si, es
	.enter

	; Try to open the library, and obtain the format information
	;
	call    OpenLibrary
	jc      done
	push	bx			; save the file handle
	mov     ss:[libraryChunk], ax
	mov     ss:[dataSegment], ds    ; record possibly-moved data block seg
	call    LoadExtendedInfo	; data => BX, CX, DX, DS, ES
	jc 	closeFile
	mov	ss:[libraryClass], dx

	; Set up to loop through formats listed by this library
	;
	mov	ax, ss:[formatInfo]	; Import/Export flag => AX
	mov	si, offset TLMBH_stringHandleTable
	clr	dx			; dx = enumerated type value
formatLoop:
	test	ds:[si].IFGI_formatInfo, ax
	jz	skipFormat		; if not capable, don't add format
	call	AllocFormatDescriptor	; allocate & initialize descriptor
	inc	dx			; go to next enumeration
skipFormat:
	add	si, size ImpexFormatGeodeInfo
	loop	formatLoop		; loop until done
        call    MemFree			; free the format strings block
	clc

	; Close the translation library, preserving AX & carry state
closeFile:
	pop	bx			; bx <- file handle
	push	ax			; save error message
	pushf				; preserve carry flag
	clr     al			; pretend we'll handle any errors
	call    FileClose		; close the library (ignore errors)
	popf				; restore carry flag
	pop	ax			; restore error message
	mov	ds, ss:[dataSegment]
done:
	.leave
	ret
ProcessLibrary endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocFormatDescriptor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate & initialize an ImpexFormatDescriptor

CALLED BY:	ProcessLibrary

PASS:		DS:SI	= ImpexFormatGeodeInfo
		ES:SI	= ImpexFormatGeodeInfo
		DX	= Format #

RETURN:		Nothing

DESTROYED:	DI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocFormatDescriptor	proc	near
	uses	ax, cx, si, es
	.enter	inherit	ProcessLibrary
	
	; Find length of the format string
	;
	push	dx			; save the format #
	mov	di, ds:[si].IFGI_headerString
	mov	di, ds:[di]		; dereference the chunk handle
	push	si	
	push    di			; save start of format string
	ChunkSizePtr	ds,di,cx	; figure length of format string
	push    cx			; save length of format string for copy

        ; Allocate a format descriptor and tack it onto the end of
        ; the formats array.
        ;
	mov     ds, ss:[dataSegment]
	add     cx, size ImpexFormatDescriptor
	call    LMemAlloc
	mov     si, ds:[FI_formats]
	call    ChunkArrayAppend	; ds:di <- new element of array
	mov     ds:[di], ax

        ; Initialize the format descriptor.
        ;
	xchg    di, ax
	mov     di, ds:[di]     	; ds:di <- format descriptor
	mov     ax, ss:[libraryChunk]
	mov     ds:[di].IFD_library, ax
	mov	ax, ss:[libraryClass]
	mov	ds:[di].IFD_dataClass, ax
	pop     cx			; cx <- format name length (with null)
DBCS <	shr	cx, 1			; cx <- format name length w/NULL >
	pop     si			; si <- start of format name
	mov	ds:[di].IFD_formatNameLen, cx

        ; Copy the format name into the descriptor.
        ;
	push	di
	mov     ss:[dataSegment], ds
	segxchg	es, ds		    ; ds <- info block, es <- data block
	add     di, offset IFD_formatName
	LocalCopyNString		; rep movsb/movsw
	pop	di

	; Now store the default file specification
	;
	pop	si			; si <- string table pointer
	push	di
	push	si
	mov	si, ds:[si].IFGI_fileSpecString
	mov	si, ds:[si]		; dereference the string chunk
	add	di, offset IFD_defaultFileMask
	mov	cx, IMPEX_FILE_MASK_STRING_LENGTH
	LocalCopyNString		; rep movsb/movsw
	pop	si		

	; Now we get the handles (not really handles until after relocation)
	; and stuff them away for safe-keeping. They are actually only used
	; as binary values, as the relocated values are fetched from
	; memory directly later.
	;
	pop	di
	mov	ax, ds:[si].IFGI_importUI.handle
	mov	es:[di].IFD_importUIFlag, ax
	mov	ax, ds:[si].IFGI_exportUI.handle
	mov	es:[di].IFD_exportUIFlag, ax
	pop	dx
	mov	es:[di].IFD_formatNumber, dx

	.leave
	ret
AllocFormatDescriptor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                OpenLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Open the library and add it to the array of known
                translation libraries.

CALLED BY:      ProcessLibrary

PASS:		ES:DX	= Translation library filename
		DS	= FormatInfo block

RETURN:		DS	= FormatInfo block (may have moved)
		BX	= Translation library *file* handle
		AX	= Chunk handle of ImpexLibraryDescriptor
		Carry	= Clear
			- or -
		AX	= ImpexError
		Carry	= Set

DESTROYED:      cx, dx, es, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/91		Initial version
	don	11/91		Cleaned up code, commenting

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OpenLibrary	proc    near
	uses	si
	.enter

	; First try and open the sucker.
	;
	push    ds			; save FormatInfo block
	segmov  ds, es			; ds:dx <- filename
	mov     al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
	call    FileOpen
	pop     ds			; ds <- FormatInfo block
	mov_tr  bx, ax			; bx <- file handle
	mov	ax, IE_COULD_NOT_OPEN_XLIB
	jc      done

	; Have it open, so create a ImpexLibraryDescriptor for it.
	;
	mov     cx, size ImpexLibraryDescriptor
	call    LMemAlloc		; ax <- chunk handle of descriptor
	mov	di, ax			; di <- ditto
	segxchg	es, ds
	mov	si, dx			; ds:si <- filename of library
	mov     di, es:[di]
		CheckHack <(offset ILD_fileName) eq 0>
	mov	cx, IMPEX_NAME_SIZE
	rep     movsb

	; Add it to the libraries array....
	;
	segmov	ds, es
	mov     si, ds:[FI_libraries]
	call    ChunkArrayAppend	; ds:di <- new element
	mov	ds:[di],ax	
	clc				; return success
done:
	.leave
	ret
OpenLibrary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                LoadExtendedInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Load the TranslationLibraryHeader block for the library,

CALLED BY:      ProcessLibrary

PASS: 		BX	= Translation library *file* handle

RETURN:		DS,ES	= Format strings segment
		BX	= Format strings block handle
		CX	= Number of formats
		DX	= ImpexDataClasses for library
		Carry	= Clear
			- or -
		AX	= ImpexError
		Carry	= Set

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/91		Initial version
	don	11/91		Cleaned up code, no longer closes file on error
	jenny	12/91		Check that library valid & memory allocated

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoadExtendedInfo	proc    near
libraryTab	local	fptr
libraryHeader	local	TranslationLibraryHeader
        .enter

	; Find the TranslationLibraryHeader and read in the resource ID
	; of the format strings resource table
	;
	clr     cx
	mov     dx, offset GFH_coreBlock.GH_libEntryOff
	mov     al, FILE_POS_START
	call    FilePos
	segmov  ds, ss
	lea     dx, ss:[libraryTab]
	mov     cx, size libraryTab
	clr     al
	call    FileRead
	jc	readError			; if error, abort
	mov     dx, ss:[libraryTab].offset
	mov     cx, ss:[libraryTab].segment
	call	GeodeFindResource

	; Once we get the base position of the resource
	; we must add the offset of the libraryEntryPoint
	; and then subtract the size of the Header structure
	; to get to the info we want.
	;
	add	dx, ss:[libraryTab].offset
	sub	dx, size TranslationLibraryHeader
	mov	al, FILE_POS_START
	call	FilePos
	jc	readError			; if error, abort
	lea     dx, ss:[libraryHeader]
	mov     cx, size TranslationLibraryHeader
	clr     al
	call    FileRead
readError:
	mov	ax, IE_ERROR_READING_XLIB	; error in reading the library
	jc	exit

	; Make sure this is really a TranslationLibraryHeader
	;
	mov	ax, TLH_VALID
	cmp	{word}ss:[libraryHeader].TLH_validHeaderMarker, ax
	jne	errorInvalidLibrary
	cmp	{word}ss:[libraryHeader].TLH_validHeaderMarker2, ax
	jne	errorInvalidLibrary

        ; Get the strings resource from the driver, patching it if
	; necessary.

	mov     cx, ss:[libraryHeader].TLH_stringsResource
	clr     dx
	call	GeodeSnatchResource
	jc	readError			; Error.

	; Set return data.

	mov	ds, ax			; Strings address.
	mov	es, ax			; Strings address.
	mov	cx, ss:[libraryHeader].TLH_numberOfFormats
	mov	dx, ss:[libraryHeader].TLH_dataClass
exit:
	.leave
        ret

errorInvalidLibrary:
	mov	ax, IE_ERROR_INVALID_XLIB
	stc
	jmp	exit

LoadExtendedInfo    endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                AlphaSort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Callback function for sorting the formats (case-insensitive
                alphabetic sort)

CALLED BY:      FormatEnum via ChunkArraySort

PASS:           ds:si   = element #1
                es:di   = element #2

RETURN:         flags set so jl, je, jg take as element #1 is less-than,
                equal-to or greater-than element #2

DESTROYED:      si, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy   3/91	        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlphaSort	proc    far
	uses	ax, cx, dx
	.enter

	; Some set-up work
	;
	mov     si, ds:[si]			; si <- handle of elt #1
	mov     si, ds:[si]			; si <- offset of elt #1
	mov     di, ds:[di]			; di <- handle of elt #2
	mov     di, ds:[di]			; di <- offset of elt #2
	ChunkSizePtr ds, si, cx
	ChunkSizePtr ds, di, ax
	add     si, offset IFD_formatName
	add     di, offset IFD_formatName

	; Set CX to the smaller of the two lengths so we get a reasonable
	; result.
	;
	cmp     cx, ax
	jle     doCompare
	xchg    cx, ax
doCompare:
	sub     cx, offset IFD_formatName	; subtract size of other data
DBCS <	shr	cx, 1				; cx <- length of strings >
	call    LocalCmpStringsNoCase		; compare them strings

	.leave
	ret
AlphaSort   endp

FormatListCode	ends
