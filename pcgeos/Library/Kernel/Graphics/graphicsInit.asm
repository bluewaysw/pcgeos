COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Graphics
FILE:		grInit.asm (graphics initialization)

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
   EXT	GrInitSys	Initialize the graphics subsystem
   INT	LoadSysCharSet	Load the system font
   INT  GrInitFonts	Initializes the font manager.
   EXT	GrInitFontDriver Initializes a font driver.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/88		Initial version

DESCRIPTION:
	This module initializes the graphics system.  See manager.asm for
	documentation.

	$Id: graphicsInit.asm,v 1.1 97/04/05 01:13:24 newdeal Exp $

------------------------------------------------------------------------------@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrInitSys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the graphics system.

CALLED BY:	EXTERNAL
		InitGeos

PASS:		ds - kernel variable segment

RETURN:		ds, pointing to kernel variable segment

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrInitSys	proc	near
	uses	es
	.enter

	push	ds
	segmov	ds, cs
	mov	si, offset grLogString
	call	LogWriteInitEntry
	pop	ds

	mov	ax,ds:[defaultFontID]
	mov	ds:[defaultState.GS_fontAttr.FCA_fontID],ax
	mov	ax,ds:[defaultFontSize]
	mov	ds:defaultState.GS_fontAttr.FCA_pointsize.WBF_int,ax
	mov	ds:defaultState.GS_fontAttr.FCA_pointsize.WBF_frac,0

	mov	ds:[defaultState.GS_header.LMBH_offset], ROUNDED_GSTATE_SIZE
	mov	ds:[defaultState.GS_header.LMBH_flags],0
	mov	ds:[defaultState.GS_header.LMBH_lmemType], LMEM_TYPE_GSTATE
	;
	; Set block size to be the size of the gstate, plus some space for
	; the one empty handle that we will use for the application clip
	; region.
	;
	mov	ds:[defaultState.GS_header.LMBH_blockSize], DEF_GSTATE_SIZE
	mov	ds:[defaultState.GS_header.LMBH_nHandles],2
	mov	ds:[defaultState.GS_header.LMBH_freeList], \
						ROUNDED_GSTATE_SIZE + 6
	mov	ds:[defaultState.GS_header.LMBH_totalFree], \
					DEF_GSTATE_SIZE-ROUNDED_GSTATE_SIZE-4
	mov	ax,ds:[defaultFontHandle]
	mov	bx, ax				;bx <- default font handle
	mov	ds:[defaultState.GS_fontHandle],ax
	;
	; Initialize the font optimizations in the GState
	;
	call	InitDefFontOpts

	.leave
	ret
GrInitSys	endp

grLogString	char	"Graphics Module", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitDefFontOpts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize font optimizations for the default GState
CALLED BY:	GrInitSys()

PASS:		bx - handle of default font
		ds - seg addr of idata
RETURN:		none
DESTROYED:	ax, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitDefFontOpts	proc	near

	call	MemLock				;lock the default font
	mov	es, ax				;es <- seg addr of font

	mov	ax, es:FB_pixHeight		;ax <- pixel height
	mov	ds:defaultState.GS_pixelHeightM1, ax
DBCS <	mov	ds:defaultState.GS_fontAttr.FCA_charSet, FCS_ASCII	>
SBCS <	mov	ax, {word}es:FB_firstChar	;al,ah <- first, last char >
SBCS <	mov	{word}ds:defaultState.GS_fontFirstChar, ax		>
	;
	; set opcode if a complex transform is in use...
	;
	mov	al, GO_SPECIAL_CASE		;al <- complex transform
	test	es:FB_flags, mask FBF_IS_COMPLEX
	jnz	isComplex			;branch if complex xform
	mov	al, GO_FALL_THRU		;al <- simple transform
isComplex:
	mov	ds:defaultState.GS_complexOpcode, al
	;
	; stuff minimum left side bearing for clipping checks...
	;
	mov	ax, es:FB_minLSB		;ax <- min LSB
	mov	ds:defaultState.GS_minLSB, ax
	mov	ax, es:FB_minTSB		;ax <- min TSB
	mov	ds:defaultState.GS_minTSB, ax
	;
	; set bits if track kerning or pairwise kerning
	;
	andnf	ds:defaultState.GS_textMode, not TM_KERNING
	mov	al, GO_FALL_THRU		;al <- opcode for no JMP
	tst	es:FB_kernCount			;see if any pair kerning info
	jz	noKernInfo			;branch if no info
	ornf	ds:defaultState.GS_textMode, mask TM_PAIR_KERN
	mov	al, GO_SPECIAL_CASE		;al <- opcode for JMP
noKernInfo:
	mov	ds:defaultState.GS_kernOp, al
	;
	; Copy the FontBufFlags, and indicat the font is
	; the default font.
	;
	mov	al, es:FB_flags
	ornf	al, mask FBF_DEFAULT_FONT	;mark as default font
	mov	ds:defaultState.GS_fontFlags, al

	call	MemUnlock			;unlock the default font

	ret
InitDefFontOpts	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrInitFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the font manager.   Finds all of the font files
		in the current font directory, loads in their headers.

CALLED BY:	INTERNAL

PASS:		ds - seg addr of idata

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
       		change to current font directory
		allocate a block for the font names, of some size
		read in all of the .geo files in the directory
		create a fontsAvail chunk that's 4 * number of files
		for each file
			open the file as read-only
			read in the font file info for the file
			compare signature to BSWF
			if we have a match:
				lookup number of bytes in font info
				create a chunk of that size
				save file handle in first byte of chunk
				read in the header
				save font id and chunk handle in fontsAvail
			else
				close the file
		resize fontsAvail to correct size
		unlock font block

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/22/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


if	TEST_FONT_CACHE_ENUM_SPEED
include timedate.def
idata	segment
fontCacheTime	sword	0
idata	ends
endif


InitFontsParams	struct
    IFP_enumParams	FileEnumParams
    IFP_fontModData	fptr
    IFP_fontsAvailPtr	nptr
    IFP_filesLeft	word
    IFP_mismatchFlag	word
InitFontsParams	ends

GrInitFonts	proc	near
	uses	ds
	.enter

	push	ds
	segmov	ds, cs
	mov	si, offset grFontLogString
	call	LogWriteInitEntry
	pop	ds

	segmov	es, ds				;es <- seg addr of idata

	call	FilePushDir			;save kernel path

	; Look for a "fontbuf" file which should contain a font info block
	; created before -- fontbuf lives in PRIVDATA

	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath

	push	ds
	segmov	ds, cs
	mov	dx, offset fontbufName
	mov	al, FileAccessFlags <FE_EXCLUSIVE, FA_READ_WRITE>
	mov	ah, FILE_CREATE_NO_TRUNCATE or mask FCF_NATIVE
	clr	cx				;no attributes
	call	FileCreate			;create file, or open
						;and don't truncate it.
	jnc	haveFileOpen			;skip if no error...

	;The only error that we tolerate is ERROR_ACCESS_DENIED, which
	;means that the file exists, but is read-only.

	cmp	ax, ERROR_SHARING_VIOLATION
	jz	hack10
	cmp	ax, ERROR_ACCESS_DENIED
	ERROR_NE GRAPHICS_BAD_FONT_PATH		;die if other error
hack10:

	;attempt to re-open the file, read-only this time

	mov	bx, 50				;retry count
tryOpenReadOnly:
	mov	al, FileAccessFlags <FE_NONE, FA_READ_ONLY>
	call	FileOpen

	; do a special check for ERROR_SHARING_VIOLATION here, since it seems
	; like we get this on overloaded networks

	jnc	haveReadOnlyFontbuf
	cmp	ax, ERROR_SHARING_VIOLATION
	ERROR_NZ	GRAPHICS_BAD_FONT_PATH
	dec	bx
	jnz	tryOpenReadOnly

	ERROR	GRAPHICS_BAD_FONT_PATH

	; yep, we got ERROR_SHARING_VIOLATION, try again

haveReadOnlyFontbuf:
	pop	ds
	;
	; The FONTBUF is read-only -- assume it is valid
	;
	mov	bx, ax				;bx <- file handle
	call	FileSize			;dx:ax <- file size
EC <	tst	dx							>
EC <	ERROR_NZ	GRAPHICS_GR_INIT_FONTS_ERROR			>
EC <	tst	ax							>
EC <	ERROR_Z		GRAPHICS_GR_INIT_FONTS_ERROR			>
	call	ReadFontCache
EC <	ERROR_C GRAPHICS_BAD_FONT_PATH		;>
	jmp	unlockAndExit

haveFileOpen:
	pop	ds
	mov	bx, ax				;bx = file handle

	mov	ax, SP_FONT
	call	FileSetStandardPath

	; if we crashed, just nuke the cache.

	test	ds:[sysConfig], mask SCF_CRASHED
	jnz	truncateExisting

	; Did we create a new file ?

	call	FileSize
EC <	tst	dx							>
EC <	ERROR_NZ	GRAPHICS_GR_INIT_FONTS_ERROR			>
	tst	ax
	jz	newFile

	call	ReadFontCache
	jc	truncateExisting		;branch if error
	call	GrVerifyFontCache
	jnc	unlockAndExit

	;note that if the FONTBUF was opened read-only, and the verify
	;fails, then we will die below with GRAPHICS_GR_INIT_FONTS_ERROR.

truncateExisting:
	clr	cx
	clr	dx
	call	FileTruncate
EC <	ERROR_C	GRAPHICS_GR_INIT_FONTS_ERROR				>

newFile:
	segmov	ds, es				;ds = idata

	call	GrCreateFontBlock

	; write out a cache file for next time

	clr	dx
	mov	cx, ds:[LMBH_blockSize]
	clr	ax
	call	FileWriteFar
EC <	ERROR_C	GRAPHICS_GR_INIT_FONTS_ERROR				>

unlockAndExit:
	clr	ax
	call	FileCloseFar
EC <	ERROR_C	GRAPHICS_GR_INIT_FONTS_ERROR				>

	;
	; Reallocate the font file cache big enough to hold as many fonts
	; as we expect.  This allows us to not have to resize the block
	; later, which would cause many a headache if it caused the block
	; to move...
	;
	push	ds
	mov	dx, offset maxFontFilesString
	call	GetSystemInteger
	jnc	foundMaxFontFiles		;branch if found
	mov	ax, FID_DEFAULT_FILE_HANDLES	;ax <- default # file handles
foundMaxFontFiles:
	cmp	ax, FID_MIN_FILE_HANDLES
	jae	minFilesOK
	mov	ax, FID_MIN_FILE_HANDLES
minFilesOK:
	cmp	ax, FID_MAX_FILE_HANDLES
	jbe	maxFilesOK
	mov	ax, FID_MAX_FILE_HANDLES
maxFilesOK:
	pop	ds
	shl	ax, 1				;2 bytes per handle
	mov	cx, ax				;cx <- # of bytes
	mov	ax, FONT_FILE_CACHE_HANDLE
	call	LMemReAlloc
	mov	di, [FONT_FILE_CACHE_HANDLE]
	segmov	es, ds
	clr	ax				;ax <- word to store
	shr	cx, 1				;cx <- # of words
	rep	stosw				;zero me jesus

	mov	bx, ds:[LMBH_handle]		;unlock font info block
	call	MemUnlock

	call	FilePopDir			; restore kernel path
EC <	mov	ax, NULL_SEGMENT					>
EC <	mov	es, ax							>

	.leave
	ret

GrInitFonts	endp

maxFontFilesString	char	"maxfontfiles", 0

grFontLogString	char	"Fonts", 0

LocalDefNLString fontbufName <"fontbuf", 0>

LocalDefNLString fntFileSpec <"*.fnt",0>

initFontsCallbackAttrs	FileExtAttrDesc \
	<FEA_NAME, 0, size FileLongName>,
	<FEA_MODIFICATION, 0, size FileDateAndTime>,
	<FEA_SIZE, 0, size dword>,
	<FEA_END_OF_LIST>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFontsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for GrInitFonts checking to make sure that
		the directory does not have to be rescanned.

CALLED BY:	GrInitFonts (via FileEnum)

PASS: 		ds	= segment of FileEnumCallbackData
RETURN:		carry - set to reject file
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	10/8/90		Initial version
	ardeb	10/14/91	Adapted to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitFontsCallback	proc	far	params:InitFontsParams
				uses	ax, cx, si, di, ds, es
	.enter inherit far

	; if mismatch already found then ignore

	tst	ss:[params].IFP_mismatchFlag
	jnz	done

	; if not a font file, as determined by name, do nothing
	call	FileEnumWildcard
	jc	exit

	dec	ss:[params].IFP_filesLeft
	js	different

	mov	ax, FEA_NAME
	call	IFCBLocateAttr
	
	push	es, di

	mov	ax, FEA_SIZE
	call	IFCBLocateAttr

	push	es, di

	; compare date and time

	mov	ax, FEA_MODIFICATION
	call	IFCBLocateAttr

	lds	si, ss:[params].IFP_fontModData
		CheckHack <(size FileDateAndTime eq 4) and \
			   (offset FMI_modified eq 0)>

	;
	; ignore time and date mismatches.
	; 

	cmpsw
	; jne	popSizeAndNameDifferent
	cmpsw
	; jne	popSizeAndNameDifferent

	pop	es, di		; es:di <- &file size
		CheckHack <offset FMI_fileSize eq size FMI_modified>
	cmpsw
	jne	popNameDifferent
	cmpsw
	jne	popNameDifferent
	
	pop	es, di

	; compare filenames up to and including the final null

	mov	si, ss:[params].IFP_fontsAvailPtr
	mov	cx, FONT_FILE_LENGTH
nameCompareLoop:
	lodsb
	scasb
	jne	different
	tst	al
	loopne	nameCompareLoop

done:
	add	ss:[params].IFP_fontsAvailPtr, size FontsAvailEntry
	add	ss:[params].IFP_fontModData.offset, size FontModificationInfo
	stc					;always reject

exit:
	.leave
	ret

popNameDifferent:
	add	sp, 4
different:
	inc	ss:[params].IFP_mismatchFlag
	jmp	done
InitFontsCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFCBLocateAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subroutine to locate an extended attribute in a
		FileEnumCallbackData segment, which attribute *must*
		be present.

CALLED BY:	InitFontsCallback
PASS:		ax	= FileExtendedAttribute for which to search
		ds	= segment of FileEnumCallbackData
RETURN:		es:di	= address of file's extended attribute
DESTROYED:	ax, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFCBLocateAttr	proc near
	clr	si
		CheckHack <FECD_attrs eq 0>
	call	FileEnumLocateAttr
EC <	ERROR_C	GRAPHICS_FILE_ATTR_NOT_RETURNED_FOR_FONT_FILE		>
EC <	tst	es:[di].FEAD_value.segment				>
EC <	ERROR_Z	GRAPHICS_FILE_ATTR_NOT_RETURNED_FOR_FONT_FILE		>
	les	di, es:[di].FEAD_value
   	ret
IFCBLocateAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadFontCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the FONTBUF font cache from disk

CALLED BY:	GrInitFonts()
PASS:		ax - file size
		bx - file handle
		ds, es - dgroup
RETURN:		carry - set if error
		ds - seg addr of locked FontInfoBlock
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 1/93		broke out from GrVerifyFontCache()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadFontCache		proc	near
	uses	ax, bx, cx, si, di
	.enter

	push	ax				;save file size
	push	bx
	mov	cx, FID_BLK_ALLOC_FLAGS
	call	MemAllocFar			; bx <- handle, ax <- segment
	mov	ds:fontBlkHandle, bx	 	;save the block handle
	mov	si, bx				;si = block handle
	mov	ds, ax			 	;font info segment in ds

	; read in font info block

	pop	bx				;recover file handle
	pop	cx				;cx = # bytes
	clr	dx				;read into ds:0
	clr	ax
	call	FileReadFar
EC <	ERROR_C	GRAPHICS_GR_INIT_FONTS_ERROR				>
NEC <	LONG jc	freeCacheBlock						>

	; set handle properly for this session.

	mov	ds:[LMBH_handle], si

	; EC: initialize free-space in block in case it was created with a
	; non-ec kernel

EC <	push	ax, dx							>
EC <	mov	ax, si							>
EC <	mov	dx, ds							>
EC <	call	ECLMemInitHeap						>
EC <	pop	ax, dx							>
	;
	; mark the block as an lmem block
	;
	ornf	es:[si].HM_flags, mask HF_LMEM
	;
	; zero out the file handles for all font entries, as none is open.
	;
	clr	ax
	mov	si, ds:[FONTS_AVAIL_HANDLE]	;point at the thing
	ChunkSizePtr	ds, si, cx		;cx = size
zeroLoop:
	mov	di, ds:[si].FAE_infoHandle
	mov	di, ds:[di]
	mov	ds:[di].FI_fileHandle, ax
	add	si, (size FontsAvailEntry)
	sub	cx, (size FontsAvailEntry)
	jnz	zeroLoop

NEC <done:					;>
	.leave
	ret

ife ERROR_CHECK
freeCacheBlock:
	;
	; error -- return with carry set to signal cache invalid.
	;
	clr	bx
	xchg	bx, es:fontBlkHandle		;bx <- font info block
	call	MemFree
	stc
	jmp	done
endif

ReadFontCache		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrVerifyFontCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the font cache file we just opened is still
		valid.

CALLED BY:	GrInitFonts
PASS:		bx	= handle of file holding cache data
		dx:ax	= size of cache file (dx 0)
		ds	= segment of locked FontInfoBlock
		es	= dgroup
RETURN:		carry set if cache is invalid
		carry clear if cache is valid:
DESTROYED:	ax, cx, dx, si, di, ds, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/14/91	Initial version (broke out of GrInitFonts)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrVerifyFontCache proc	near
	uses	bx
	.enter

	; now go through the fonts using FileEnum to ensure that nothing
	; has changed

if	TEST_FONT_CACHE_ENUM_SPEED
	call	TimerGetCount
	mov	es:[fontCacheTime], ax
endif

	; figure the number of fonts that were available by seeing how many
	; FontModificationInfo structures fit in the appropriate chunk of the
	; cached block.
	mov	si, ds:[FONT_MOD_DATA_HANDLE]
	ChunkSizePtr	ds, si, ax
	mov	cx, size FontModificationInfo
	div	cx				;ax = # fonts

	; set up our part of the parameter block we pass to FileEnum

	sub	sp, size InitFontsParams
	mov	bp, sp
	mov	ss:[bp].IFP_fontModData.segment, ds
	mov	ss:[bp].IFP_fontModData.offset, si
	mov	si, ds:[FONTS_AVAIL_HANDLE]
	add	si, offset FAE_fileName
	mov	ss:[bp].IFP_fontsAvailPtr, si
	mov	ss:[bp].IFP_filesLeft, ax
	mov	ss:[bp].IFP_mismatchFlag, 0

	; set up the rest of the paramters that FileEnum itself uses. We're
	; interested only in non-geos files and have our own special
	; callback to check for validity of each file.

	mov	ss:[bp].FEP_searchFlags, mask FESF_NON_GEOS or mask FESF_CALLBACK
	clr	ax
	mov	ss:[bp].FEP_returnSize, ax		; nothing for FileEnum
	mov	ss:[bp].FEP_returnAttrs.segment, ax	;  to return
	mov	ss:[bp].FEP_returnAttrs.offset, FESRT_COUNT_ONLY

	mov	ss:[bp].FEP_matchAttrs.segment, ax	; no attributes for it
							;  to match (our call-
							;  back handles all)
	mov	ss:[bp].FEP_bufSize, ax
	mov	ss:[bp].FEP_skipCount, ax		; nothing to skip
	mov	ss:[bp].FEP_callback.segment, SEGMENT_CS
	mov	ss:[bp].FEP_callback.offset, offset InitFontsCallback
	;
	; Set up callback data fields as if FESC_WILDCARD were passed,
	; since we'll be calling FileEnumWildcard ourselves.
	;
if	FULL_EXECUTE_IN_PLACE

;	On XIP systems, all these pointers into our code segment are bad, so
;	copy them onto the stack

	push	ds, si
	segmov	ds, cs
	mov	si, offset fntFileSpec
	mov	cx, size fntFileSpec + size initFontsCallbackAttrs
.assert (offset initFontsCallbackAttrs - offset fntFileSpec) eq (size fntFileSpec)
	call	SysCopyToStackDSSIFar
	
	mov	ss:[bp].FEP_cbData1.offset, si
	mov	ss:[bp].FEP_cbData1.segment, ds
	mov	ss:[bp].FEP_cbData2.low, TRUE	; case-insensitive matching
	;
	; Set up callback attributes so we get what we need.
	; 
	mov	ss:[bp].FEP_callbackAttrs.segment, ds
	add	si, size fntFileSpec
	mov	ss:[bp].FEP_callbackAttrs.offset, si
	pop	ds, si
else
	mov	ss:[bp].FEP_cbData1.offset, offset fntFileSpec
	mov	ss:[bp].FEP_cbData1.segment, cs
	mov	ss:[bp].FEP_cbData2.low, TRUE	; case-insensitive matching
	;
	; Set up callback attributes so we get what we need.
	; 
	mov	ss:[bp].FEP_callbackAttrs.segment, cs
	mov	ss:[bp].FEP_callbackAttrs.offset, offset initFontsCallbackAttrs
endif
;done loading params, call FileEnum
	call	FileEnum
EC <	ERROR_C	GRAPHICS_GR_INIT_FONTS_ERROR				>
FXIP <	call	SysRemoveFromStackFar					>

if	TEST_FONT_CACHE_ENUM_SPEED
	call	TimerGetCount
	sub	ax, es:[fontCacheTime]
	mov	es:[fontCacheTime], ax
endif

	; if either a mismatch was flagged, or there were still some
	; modification data entries left, the cache is invalid.

	mov	ax, ss:[bp].IFP_mismatchFlag
	ornf	ax, ss:[bp].IFP_filesLeft

	; clear our own data off the stack (FileEnum already cleared
	; the FileEnumParams portion of it off...)
	add	sp, (size InitFontsParams) - (size FileEnumParams)

	tst	ax
	jnz	freeCacheBlock

	clc
done:
	.leave
	ret

freeCacheBlock:

	; mismatch somewhere above, so nuke the info block we got from the
	; cache and return with carry set to signal cache invalid.

	mov	bx, ds:[LMBH_handle]
	call	MemFree
	stc
	jmp	done
GrVerifyFontCache endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCreateFontBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate all fonts in the current directory and build a
		font info block for them all.

CALLED BY:	GrInitFonts
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/14/91	Initial version (Broke out from GrInitFonts
				and upgraded to 2.0 FileEnum)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrCreateFontBlock proc	near
	uses	bx, es
	.enter
	;
	; Create a font block, with a local heap to keep a list of available
	; font ID's, a list of font ID and sizes that currently are assigned
	; handles, a temporary list of names that match *.fnt in the font
	; directory, and a chunk for the info header for each font.
	;
   	mov	ax, INIT_FONT_BLK_SIZE	 	;initial size of font block
	mov	cx, FID_BLK_ALLOC_FLAGS 	;lock block, make space for it
	call	MemAllocFar		 	;allocate space for it
	mov	ds:fontBlkHandle, bx	 	;save the block handle
	mov	ds, ax			 	;font info segment in ds
	mov	dx, size LMemBlockHeader	;offset to start of heap
	mov	ax, LMEM_TYPE_FONT_BLK		;heap type is general
	mov	cx, STD_INIT_HANDLES
	mov	si, STD_INIT_HEAP
	clr	di
	call	LMemInitHeap		 	;initialize a local heap

	; MUST allocate chunks in the correct order

	clr	cx
	call	LMemAlloc		 	;empty chunk for fontsAvail
	call	LMemAlloc		 	;empty chunk for fontsInUse
	call	LMemAlloc			;empty chunk for driversAvail
	call	LMemAlloc			;empty chunk for mod info

	sub	sp, size FileEnumParams
	mov	bp, sp
	mov	ss:[bp].FEP_searchFlags, mask FESF_NON_GEOS or \
					 mask FESF_CALLBACK
	mov	ss:[bp].FEP_returnAttrs.segment, cx
	mov	ss:[bp].FEP_returnAttrs.offset, FESRT_DOS_INFO
	mov	ss:[bp].FEP_returnSize, size FEDosInfo
	mov	ss:[bp].FEP_matchAttrs.segment, cx
	mov	ss:[bp].FEP_bufSize, MAX_FONTS
	mov	ss:[bp].FEP_skipCount, cx
if	FULL_EXECUTE_IN_PLACE

;	Can't pass pointers into our code segment, so copy data to the stack
;	first

	push	ds, si
	segmov	ds, cs
	mov	si, offset fntFileSpec
	call	SysCopyToStackDSSIFar
	movdw	ss:[bp].FEP_cbData1, dssi
	pop	ds, si
else
	mov	ss:[bp].FEP_cbData1.segment, cs
	mov	ss:[bp].FEP_cbData1.offset, offset fntFileSpec
endif
	mov	ss:[bp].FEP_cbData2.low, TRUE
	mov	ss:[bp].FEP_callback.segment, cx
	mov	ss:[bp].FEP_callback.offset, FESC_WILDCARD
	call	FileEnum
FXIP <	call	SysRemoveFromStackFar					>

	ERROR_C	GRAPHICS_NO_FONT_FILES
	tst	cx
	ERROR_Z	GRAPHICS_NO_FONT_FILES

	call	MemLock
	mov	es, ax
	push	bx		; save handle of return data block for
				;  later free

	; di = current FEDosInfo structure in ES
	; cx = # files left to process

	clr	di				;point at first structure
fontLoop:
	call	GrProcessFont
	add	di, size FEDosInfo	;move to next file
	loop	fontLoop

	; free the block holding the available files.

	pop	bx
	call	MemFree

	; compact the heap so that we don't write out unneeded stuff

	mov	bx, ds:[LMBH_handle]
	call	LMemContractBlock

	.leave
	ret
GrCreateFontBlock endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrProcessFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a single font file, adding appropriate entries to
		appropriate chunks in the passed font info block.

CALLED BY:	GrCreateFontBlock
PASS:		ds	= segment of locked font info block
		es:di	= FEDosInfo record for file to process
RETURN:		nothing
DESTROYED:	ax, dx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrProcessFont	proc	near
fontInfo	local	FontFileInfo
	uses	cx
	.enter

	;
	; First open the file using the name in the current FEDosInfo entry.
	; 
	push	ds
	segmov	ds, es
	lea	dx, ds:[di].FEDI_name
	mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
       	call	FileOpen			;open the file
EC <	ERROR_C	GRAPHICS_BAD_FONT_FILE					>
NEC <	LONG jc	openError						>

	;
	; Read the signature and version # from the start of the file.
	; 
	mov_trash	bx, ax			;put file handle in bx
	mov	cx, size fontInfo		;read in first few bytes

	lea	dx, ss:[fontInfo]
	segmov	ds, ss				;ds:dx <- buffer to which to
						; read
	clr	al				;return errors, please
	call	FileReadFar			;read in the bytes
	pop	ds

	push	di			; save FEDI offset for later now DS
					;  is back off the stack

EC <	jnc	noReadError			>;no problems, branch
EC <	cmp	ax, ERROR_SHORT_READ_WRITE	>;see if small file
EC < 	ERROR_NE GRAPHICS_BAD_FONT_FILE					>
EC <noReadError:							>
	LONG jc	closeFont


	;
	; Make sure the file's actually a font file that we can handle.
	; 
	cmp	ss:[fontInfo].FFI_signature, FID_SIG_LO
	LONG jne closeFont				;nope, branch
	cmp	ss:[fontInfo].FFI_signature[2], FID_SIG_HI
	LONG jne closeFont				;nope, branch
	cmp	ss:[fontInfo].FFI_majorVer, MAX_MAJOR_VER;can we deal with it?
	ja	closeFont				;nope, branch

	;
	; At this point, the file is a font file.  We will read the file into
	; a new chunk and save the font ID and chunk handle in the
	; fontsAvail list.
	;
	; We zero the file handle since it will be closed when we're done
	;
	mov	cx, ss:[fontInfo].FFI_headerSize;make a chunk for the rest

	add	cx, FI_RESIDENT			;add room to store file handle
	call	LMemAlloc			;handle in ax

	mov	di, ax				;put handle in di
	mov	di, ds:[di]			;point to the buffer
	push	ax				;save chunk handle

	lea	dx, ds:[di].FI_fontID		;read in bytes here
	sub	cx, FI_RESIDENT			;not reading file handle
	clr	al
	call	FileReadFar
EC <	ERROR_C	GRAPHICS_BAD_FONT_FILE					>

	mov	ds:[di].FI_fileHandle, 0	;clear file handle
	;
	; allocate chunks for all ODE_extraData
	;
DBCS <	pop	di				;di = FontInfo chunk	>
DBCS <	push	di							>
DBCS <	call	AllocateExtraData					>
DBCS <	mov	di, ds:[di]			;ds:di = FontInfo	>
	;
	; Adjust any V1.X font weights
	;
SBCS <	call	AdjustFontWeight					>
	mov	di, ds:[di].FI_fontID		;get the font ID
	;
	; Make entry in fontsAvail for the font just read in
	;
	mov	ax, FONTS_AVAIL_HANDLE
	mov	dx, size FontsAvailEntry
	call	GPFEnlargeChunk

	mov	ds:[si].FAE_fontID, di		;save font ID
	pop	ds:[si].FAE_infoHandle		;save chunk handle of info

	; copy file name into fonts avail structure

	lea	di, ds:[si].FAE_fileName	;di <- place to save name

	pop	si
	push	si

	add	si, offset FEDI_name
	segxchg	es, ds				;copy in file name
	mov	cx, FONT_FILE_LENGTH
DBCS <	rep	movsw							>
SBCS <	rep	movsb							>
	segxchg	es, ds

	; save font file modification info for validating the cache next time

	mov	ax, FONT_MOD_DATA_HANDLE
	mov	dx, size FontModificationInfo
	call	GPFEnlargeChunk			; ds:si <- new last entry

	pop	di
	push	di

	mov	ax, es:[di].FEDI_modified.FDAT_date
	mov	ds:[si].FMI_modified.FDAT_date, ax
	mov	ax, es:[di].FEDI_modified.FDAT_time
	mov	ds:[si].FMI_modified.FDAT_time, ax
	mov	ax, es:[di].FEDI_fileSize.low
	mov	ds:[si].FMI_fileSize.low, ax
	mov	ax, es:[di].FEDI_fileSize.high
	mov	ds:[si].FMI_fileSize.high, ax

closeFont:
	pop	di
	clr	al
	call	FileCloseFar			;close the file
done::
	.leave
	ret

NEC <openError:								>
NEC <	pop	ds							>
NEC <	jmp	done							>

GrProcessFont	endp

if not DBCS_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustFontWeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust any V1.X font weights

CALLED BY:	GrProcessFont()
PASS:		ds:di - ptr to FontInfo
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustFontWeight		proc	near
	uses	si, di, bx
	.enter
	mov	si, ds:[di].FI_outlineTab	;si <- offset of outlines
	add	si, di				;si <- ptr to start
	add	di, ds:[di].FI_outlineEnd	;di <- ptr to end
outlineLoop:
	cmp	si, di				;end of outlines?
	jae	endLoop				;branch if end of list
	mov	bl, ds:[si].ODE_weight		;bl <- FontWeight
	cmp	bl, FWE_BLACK			;old weight?
	ja	weightOK			;branch if old weight
	clr	bh
	mov	bl, cs:weightAdjustTable[bx]	;bl <- new weight
	mov	ds:[si].ODE_weight, bl
weightOK:
	add	si, (size OutlineDataEntry)	;ds:si <- next entry
	jmp	outlineLoop

endLoop:
	.leave
	ret

weightAdjustTable	byte \
	80,		;FWE_ULTRA_LIGHT
	85,		;FWE_EXTRA_LIGHT
	90,		;FWE_LIGHT
	95,		;FWE_BOOK
	100,		;FWE_NORMAL
	105,		;FWE_DEMI
	110,		;FWE_BOLD
	115,		;FWE_EXTRA_BOLD
	120,		;FWE_ULTRA_BOLD
	125		;FWE_BLACK

AdjustFontWeight		endp

endif

if DBCS_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateExtraData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate chunks for all ODE_extraData

CALLED BY:	GrProcessFont()
PASS:		*ds:di - FontInfo
		bx - font file handle
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/ 4/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocateExtraData		proc	near
	uses	si, di, ax, bx, cx, dx, bp
	.enter
	mov	bp, bx				;bp = file handle
	mov	si, ds:[di]			;ds:si = FontInfo
	mov	bx, ds:[si].FI_outlineTab	;bx <- offset of outlines
outlineLoop:
	cmp	bx, ds:[si].FI_outlineEnd	;end of outlines?
	jae	endLoop				;branch if end of list
	mov	cx, ds:[si][bx].ODE_extraData	;cx = size of extra data
	call	LMemAlloc			;*ds:ax = extra data chunk
	mov	si, ds:[di]			;deref after alloc
	mov	ds:[si][bx].ODE_extraData, ax
	push	si
	mov	si, ax				;*ds:si = extra data chunk
	mov	dx, ds:[si]			;ds:dx = extra data chunk
	pop	si
	clr	al
	xchg	bx, bp				;bx = file handle, bp = offset
	call	FileReadFar			;read extra data into chunk
	xchg	bx, bp				;bx = offset, bp = file handle
EC <	ERROR_C	GRAPHICS_BAD_FONT_FILE					>
	add	bx, (size OutlineDataEntry)	;ds:[si][bx] <- next entry
	jmp	outlineLoop

endLoop:
	.leave
	ret
AllocateExtraData		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPFEnlargeChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for GrProcessFont to enlarge a chunk containing
		an array of elements by one element and return the last entry
		in that chunk.

CALLED BY:	GrProcessFont
PASS:		*ds:ax	= chunk to enlarge
		dx	= # bytes by which to enlarge it
RETURN:		ds:si	= last entry in the chunk
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPFEnlargeChunk	proc near
	mov	si, ax			;point at the thing
	ChunkSizeHandle	ds, si, cx		;cx = size
	xchg	dx, cx
	add	cx, dx
	call	LMemReAlloc
	add	dx, ds:[si]	;ds:dx = last entry
	mov	si, dx
	ret
GPFEnlargeChunk endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrInitDefaultFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the default font.  We will treat this font somewhat
		specially by loading it automatically on startup.  This is
		to insure that the font is on disk, and that the font is
		not made DISCARDABLE, so that all windows will have a
		font set up when they are created.

CALLED BY:	GrInitFonts

PASS: 		ds - seg addr of idata
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/22/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrInitDefaultFont	proc	near
	uses	ds
	.enter

	segmov	es, ds				;es <- seg addr of idata

	call	FarLockInfoBlock		;lock font info block

	mov	cx, es:defaultFontID		;cx <- default font ID
	mov	dl, mask FEF_BITMAPS		;dl <- flag: bitmap fonts only
	call	GrCheckFontAvail			;see if font exists
	jcxz	fontPanic			;get nervous if it doesn't
findPointsize:
	mov	dx, es:defaultFontSize		;dx <- default pointsize
	clr	ax				;al <- styles, ah <- frac size
	call	GrFindNearestPointsize		;find nearest pointsize
	jmp	fontExists

fontPanic:
	;
	; At this point, we're very worried. The specified default
	; is not available on disk (checked in GetFontId). Berkeley
	; isn't available (checked above). Call the font enum routine
	; and take the first thing we find. If that doesn't work,
	; there aren't any bitmap fonts to use. Bummer...
	;
	push	es
	sub	sp, size FontEnumStruct		;allocate a buffer
	segmov	es, ss
	mov	di, sp				;es:di <- ptr to buffer
	mov	cx, 1				;cx <- # to find
	mov	dl, mask FEF_BITMAPS		;dl <- flag: bitmap fonts only
	call	GrEnumFonts			;find ANY font
	mov	dx, es:[di].FES_ID		;dx <- ID of first font
	add	sp, size FontEnumStruct		;deallocate buffer
	pop	es
	jcxz	error				;we're doomed...
	mov	cx, dx				;cx <- ID of first font
	jmp	findPointsize			;find a pointsize to use

error:
	ERROR	DEFAULT_FONT_NOT_FOUND

fontExists:
	;
	; Hurray! The a font exists, and has at least one bitmap face.
	; Find it's font and pointsize entries, which we know exist.
	;
	mov	es:defaultFontID, cx		;just in case it changed
	mov	es:defaultFontSize, dx		;just in case it changed
	call	FarIsFontAvail			;find font
	call	EnsureFontFileOpen		;make sure file is open
	;
	; Font found!
	;	cx - FontID
	;	dx.ah - pointsize (from GrFindNearestPointsize)
	;	al - closest TextStyle (from GrFindNearestPointsize)
	;	ds:bx - ptr to FontInfo
	;
	; Find the PointsizeEntry
	;
	call	InitFindFace
	mov	dx, ax				;save pointsize, TextStyle
	;
	; Save away the information
	;
	push	ds:[di].PSE_filePosHi
	push	ds:[di].PSE_filePosLo		;save position in file
	mov	ax, ds:[di].PSE_dataSize	;ax <- size (in bytes)
	push	ax				;save size
	push	ds:[bx].FI_fileHandle		;save file handle
	;
	; Allocate a non-discardable block for the thing
	;
	mov	cx, DEF_FONT_ALLOC_FLAGS	;lock block, make discardable
	call	MemAllocFar			;allocate a block for the font
	push	ax				;save seg addr

	mov	ax, dx				;al <- TextStyle
	mov	dx, es:defaultFontSize		;dx:ah <- pointize
	mov	cx, es:defaultFontID		;cx <- font ID
	call	InitAddInUseEntry

	mov	ds:[di].FIUE_dataHandle, bx	;store font handle
	mov	es:[bx].HM_owner, FONT_MAN_ID	;set kernel to owner
	mov	es:defaultFontHandle, bx      	;save font handle

	pop	ds				;ds <- seg addr of block

	pop	ax				;restore file handle
	pop	di				;di <- data size
	pop	dx
	pop	cx				;cx:dx <- file offset of data

	push	bx				;save mem handle

	mov	bx, ax				;put file handle in bx
	mov	al, FILE_POS_START		;absolute offset
	call	FilePosFar			;position the file
	jc	error

	clr	dx				;read at start of block
	mov	cx, di				;cx <- data size
	clr	al
	call	FileReadFar			;read in the data
	jc	error

	pop	bx
	call	MemUnlock			;unlock the default font

	call	FarUnlockInfoBlock		;unlock font info block
	.leave
	ret

GrInitDefaultFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFindFace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the PointSizeEntry for the default font
CALLED BY:	GrInitDefaultFont()

PASS:		ds:bx - ptr to FontInfo
		dx.ah - pointsize (from GrFindNearestPointsize)
		al - closest TextStyle (from GrFindNearestPointsize)
RETURN:		ds:di - ptr to PointSizeEntry
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitFindFace	proc	near
	.enter

EC <	push	bx				;>
	;
	; Get pointers to the start & end of the pointsize table
	;
	mov	di, bx
EC <	add	bx, ds:[di].FI_pointSizeEnd	;bx <- ptr to end >
	add	di, ds:[di].FI_pointSizeTab	;di <- ptr to size table

IFF_loop:
EC <	cmp	di, bx				;see if at end of list >
EC <	ERROR_AE FONT_INIT_NO_POINTSIZE_FOUND 	;>
	;
	; Do the TextStyle match?
	;
	cmp	ds:[di].PSE_style, al		;see if style matches
	jne	noMatch				;branch if not
	;
	; Does the pointsize match?  If so, we're done.
	;
SBCS <	cmpwbf	ds:[di].PSE_pointSize, dxah				>
DBCS <	cmp	ds:[di].PSE_pointSize, dl				>
	je	match
noMatch:
	add	di, size PointSizeEntry		;else move to next entry
	jmp	IFF_loop			;and loop

match:
EC <	pop	bx				;>

	.leave
	ret
InitFindFace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitAddInUseEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a FontsInUseEntry for the default font
CALLED BY:	GrInitDefaultFont()

PASS:		cx - FontID for default font
		dx.ah - pointsize for default font
		al - TextStyle for default font
		ds - seg addr of font info block
		es - seg addr of kdata
RETURN:		ds:di - ptr to FontsInUseEntry
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitAddInUseEntry	proc	near
	.enter

	;
	; The chunk should be empty at this point...
	;
EC <	push	cx, si				;>
EC <	mov	si, FONTS_IN_USE_HANDLE		;si <- chunk handle>
EC <	ChunkSizeHandle	ds, si, cx		;>
EC <	tst	cx				;zero sized?>
EC <	ERROR_NZ FONT_INIT_IN_USE_CHUNK_NOT_EMPTY >
EC <	pop	cx, si				;>

	push	ax, cx				;save TextStyle, FontID
	;
	; Resize the block to have one entry.
	;
	mov	ax, FONTS_IN_USE_HANDLE 	;ax <- lmem handle of FIU
	mov	cx, size FontsInUseEntry	;cx <- size for one entry
	call	LMemReAlloc			;resize the thing
	mov	di, ds:[FONTS_IN_USE_HANDLE]	;di <- ptr to chunk
	;
	; Stuff the values we have
	;
DBCS <	mov	al, es:defaultState.GS_fontAttr.FCA_charSet		>
DBCS <	mov	ds:[di].FIUE_attrs.FCA_charSet, al			>
	pop	ds:[di].FIUE_attrs.FCA_fontID
	pop	ax
	mov	ds:[di].FIUE_attrs.FCA_textStyle, al
	movwbf	ds:[di].FIUE_attrs.FCA_pointsize, dxah
	;
	; Set other values that are constants
	;
	mov	ds:[di].FIUE_refCount, 1	;set to one reference
	mov	ds:[di].FIUE_flags, 0		;no transform
	;
	; Since the font is a bitmap-only font, we can
	; assume the following attributes are normal:
	;
	mov	ds:[di].FIUE_attrs.FCA_weight, FW_NORMAL
	mov	ds:[di].FIUE_attrs.FCA_width, FWI_MEDIUM
	mov	ds:[di].FIUE_attrs.FCA_superPos, SPP_DEFAULT
	mov	ds:[di].FIUE_attrs.FCA_superSize, SPS_DEFAULT
	mov	ds:[di].FIUE_attrs.FCA_subPos, SBP_DEFAULT
	mov	ds:[di].FIUE_attrs.FCA_subSize, SBS_DEFAULT
	;
	; Make the FontMatrix look nice.  We only do this in the EC
	; version, as it doesn't actually get used unless the transformation
	; is complex.
	;
EC <	push	ax, cx, di, es			;>
EC <	clr	ax				;store 0's>
EC <	mov	cx, (size FontMatrix)/2		;cx <- # of words
EC <	add	di, offset FIUE_matrix		;>
EC <	segmov	es, ds				;es:di <- ptr to FontMatrix >
EC <	rep	stosw				;>
EC <	pop	ax, cx, di, es			;>
EC <	mov	ds:[di].FIUE_matrix.FM_11.WWF_int, 1 >
EC <	mov	ds:[di].FIUE_matrix.FM_22.WWF_int, 1 >

	.leave
	ret
InitAddInUseEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrInitFontDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a font driver and add a DriversAvailEntry for it

CALLED BY:	LoadFontDriver

PASS:		bx - GEODE handle
		ds - seg addr of idata

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, ds

PSEUDO CODE/STRATEGY:
	add a drivers available entry
	call GeodeInfoDriver to initialize it

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrInitFontDriver	proc	near
	uses	di
	.enter

	push	bx				;save GEODE handle

	call	FarLockInfoBlock		;ds <- segment of info block

	mov	si, FONT_DRIVERS_HANDLE 	;point to drivers handle
	ChunkSizeHandle ds, si, cx		;cx <- chunk size
	push	cx				;save old size
	add	cx, size DriversAvailEntry	;make room for another entry
	mov	ax, FONT_DRIVERS_HANDLE		;ax <- handle of drivers avail
	call	LMemReAlloc			;resize the thing
	mov	di, ds:[FONT_DRIVERS_HANDLE]	;di <- ptr to chunk
	pop	cx				;recover old size
	add	di, cx				;di <- ptr to end of old chunk
	pop	bx				;bx <- geode handle
  	mov	ds:[di][DAE_driverHandle], bx	;store the geode handle

	push	ds
	call	GeodeInfoDriver			;get structure w/valuable info
	mov	ax,word ptr ds:[si][DIS_strategy]   ; get strategy rout vector
	mov	bx,word ptr ds:[si][DIS_strategy+2]
	mov	cx,word ptr ds:[si][DIS_driverType]+2	;cx <- font maker
	pop	ds
	mov	word ptr ds:[di][DAE_strategy],ax
	mov	word ptr ds:[di][DAE_strategy+2],bx	;store strategy routine
	mov	word ptr ds:[di][DAE_makerID],cx	;store font maker

	mov	si, di				;ds:si <- DriversAvailEntry
	mov	di, DR_FONT_INIT_FONTS		;di <- allow driver to add fonts
	call	ds:[si].DAE_strategy		;call the driver strategy

	call	FarUnlockInfoBlock		;unlock font info block

	.leave
	ret
GrInitFontDriver	endp
