COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996.  All rights reserved.
			GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		ms7Utils.asm

AUTHOR:		Jim Wood, Dec 17, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	12/17/96   	Initial revision


DESCRIPTION:
		
	
	$Id: ms7Utils.asm,v 1.1 97/04/10 11:55:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PathOps 	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7MapComponent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the first file in the CWD that matches the passed name
		by :
			1) passedName*		(Geos longname)
				or
			2) ??????passedName*	(embedded short name)

CALLED BY:	utility

PASS:		ds:dx	= name of file to find
		cx	= non-zero if component should be a directory.
		CWD lock grabbed and DOS CWD set to the one that should
			contain the component.


RETURN:		dos7FindData.W32FD_fileName filled with the 256 character
			true longname of the file matching.
		the short name is found embedded in the long name...

		carry set if failure

DESTROYED:	nothing


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	12/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7MapComponentFar	proc far
		call	DOS7MapComponent
		ret
DOS7MapComponentFar	endp
		
DOS7MapComponent	proc	near
compType 	local	word	push	cx
badChars	local	word
searchType	local	MSDOS7SearchType
passedName	local	MSDOS7LongNameType 
		uses	bx,dx,si,di,bp, ds, es
		.enter

	;
	; Assum no error.
	;
		push	ax
	;
	; Record the start & length of the final path component mapped, for use
	; by others who might be interested.
	;
		segmov	es, ds
		mov	di, dx
		LocalStrLength
		segmov	es, dgroup, ax
		mov	es:[dosFinalComponent].segment, ds
		mov	es:[dosFinalComponent].offset, dx
		mov	es:[dosFinalComponentLength], cx
	;
	; Set up some local vars.
	;
		mov	ss:[searchType], MSD7ST_long	; long search first
		mov	ss:[badChars], FALSE		; no bad chars yet
	;
	; Copy the name before we change it.  cx is the length.
	;
		push    cx, es			; str length
		mov	si, dx			; ds:si <- passed name
		segmov	es, ss
		lea	di, ss:[passedName]
		rep	movsb
		pop     cx, es
	;	
	; Prepend the * and copy the file name, then append a *.
	; cx is the string length.
		mov	di, offset dos7LongName.MSD7GN_longName
		LocalLoadChar	ax, '*'
		LocalPutChar esdi, ax
		mov	si, dx			; ds:si <- source
		LocalCopyNString
		
	; Append the '*', add a null.
		LocalLoadChar	ax, '*'
		LocalPutChar esdi, ax
		LocalClrChar es:[di]
		segmov	ds, es			; ds, es <- dgroup
		mov	dx, offset dos7LongName.MSD7GN_longName
						; ds:dx <- "*passedName*"
	;
	; Fix up the string.
	;
		clr	cx			; null teminated string
		mov	di, dx		
		call	DOS7BadCharReplace
		jnz	startFind

		mov	ss:[badChars], TRUE
startFind:
		inc	dx			; ds:dx <- "passedName*"
	;
	; Set up for the first find; there may be more.
	;
		clr	bx			; no search handle yet
		mov	ax, MSDOS7F_FIND_FIRST
findLongName:
	;
	; Make the call. ds:dx is the file name. 
	;
		mov	es:[dos7FindData].W32FD_fileName.MSD7GN_shortName[0], 0
		mov	di, offset dos7FindData		; es:di <- find data
		mov	cx, MSDOS7_FIND_FIRST_ATTRS	; 6!
		mov	si, DOS7_DATE_TIME_MS_DOS_FORMAT
		call	DOSUtilInt21
		jc	findLongCleanUp
	;
	; Need to check the found name against the passed name to make sure
	; we have an exact match.  We'll have ds:si <- name we're looking for
	; es:di <- name we found.  Save search handle first.
	;
		tst	bx				; search handle?
		jnz	cmpLongName

		mov	bx, ax				; bx <- search handle
cmpLongName:
	;
	; If there were illegal characters in the name, we have to look
	; inside the header.
	;
		cmp	ss:[badChars], TRUE
		LONG	je	dealWithIllegalChars
	;
	; Must get string length of the found name.  
	;
		mov	di, offset dos7FindData.W32FD_fileName.MSD7GN_longName 
		tst	es:[dos7FindData].W32FD_fileName.MSD7GN_shortName[0]
		jz	getLongLength

		clr	ax			; signal NON DESTRUCTIVE
		call	DOS7UnPadLongName	; ax <- length
		mov	cx, ax
	;
	; Now compare that many characters.
	;
doLongCmp:
		mov	si, dx			; ds:si <- name
		call	LocalCmpStringsNoCase
		LONG	jz	success

		mov	ax, MSDOS7F_FIND_NEXT
		jmp	findLongName

getLongLength:
		push	di
		LocalStrLength
		pop	di
		jmp	doLongCmp
findLongCleanUp:
	;
	; Clean up from last find first, if needed.  (bx would have search han)
	;
		tst	bx
		jz	prepareShortName
		
		mov	ax, MSDOS7F_FIND_CLOSE
		call	DOSUtilInt21
		WARNING_C	MSDOS7_FIND_CLOSE_FAILED
		clr	bx
prepareShortName:
	;
	; If the name is longer than a DOS name, then there's no reason
	; to look for this as a short name.  This also sets up cx as the
	; number of chars to be space padded if it is short enough.
	;
		mov	ax, es:[dosFinalComponentLength]
		mov	cx, size MSD7GN_shortName
		sub	cx, ax			; carry set if name too long
		jc	finish
	;
	; Pad the passed name with blanks because that's how it appears in
	; the long name.
	;
		mov	dx, offset dos7LongName.MSD7GN_longName
		inc	dx		; es(ds):dx <- passedname *
		mov	di, dx		; es:di <- passedName *
		add	di, ax		; es:di <- *
		LocalLoadChar	ax, ' '
SBCS <		rep	stosb						>
DBCS <		rep	stosw						>
		LocalLoadChar 	ax, '*'
		LocalPutChar	esdi, ax
		LocalClrChar es:[di]
	;
	; Make the FindFirst call. 
	;
		dec	dx			; ds:dx <- *passed name    *
		mov	di, offset dos7FindData	; es:di <- find data
		mov	ax, MSDOS7F_FIND_FIRST
		clr	bx				; no search handle yet
		mov	ss:[searchType], MSD7ST_short
findShortName:
		mov	si, DOS7_DATE_TIME_MS_DOS_FORMAT
		mov	cx, MSDOS7_FIND_FIRST_ATTRS
		call	DOSUtilInt21
		jc	finish

	; Keep track of the search handle.
		tst	bx
		jnz	cmpShortName
		mov	bx, ax
cmpShortName:
	;
 	; We're only looking for this name as the short component, so...
	;
		clr	ax			; don't actually null	
		mov	di, offset dos7FindData.W32FD_fileName.MSD7GN_shortName
		call	DOS7UnPadShortName	; ax <- length
		mov	cx, ax			; cx <- max chars to check
		mov	si, dx			; ds:si <- *passed name
		inc	si			; ds:si <- passed name
		call	LocalCmpStringsNoCase
		jz	success
	;
	; Look for the next one,
	;
		mov	ax, MSDOS7F_FIND_NEXT
		jmp	findShortName
success:		
	;
	; If this is a directory, then we need to CD to it.
	;
		cmp	ss:[compType], DVCT_INTERNAL_DIR
		je	tryDirChange
	;
	; Set the geos file flag if appropriate.   Subdirs are geos.
	;
		segmov	ds, es
		mov	di, offset dos7FindData
		test	es:[di].W32FD_fileAttrs.low.low, mask FA_SUBDIR
		jnz	setFlag
	;
	; Native are not.
	;
		push	di
		add	di, offset W32FD_fileName.MSD7GN_signature 
		mov	si, offset nativeSignature
		mov	cx, size nativeSignature
		repe	cmpsb
		pop	di
		jz	afterFlag
setFlag:
		ornf	es:[di].W32FD_fileAttrs.low.low, FA_GEOS_FILE
afterFlag:
	;
	; We want to set up the the dosNativeFFD.FFD_name to be the dos
	; version of the file.  This means either the long name or the
	; short name, depending on which open succeeded.
	;
		mov	si, offset dos7FindData
		mov	di, offset dosNativeFFD
		call	DOS7SetupDTAHack
		clc					; signal peace on earth
finish:
		pop	ax
	; FindClose if needed.

		pushf
		tst	bx
		jz	done

		push	ax
		mov	ax, MSDOS7F_FIND_CLOSE
		call	DOSUtilInt21
		WARNING_C	MSDOS7_FIND_CLOSE_FAILED
		pop	ax
done:
		popf
		jnc	exit
		
		mov	cx, ss:[compType]
		mov	ax, ERROR_FILE_NOT_FOUND	; assume s/b file
		jcxz	exit
		mov	ax, ERROR_PATH_NOT_FOUND	; s/b dir, so return 
exit:
		.leave
		ret

tryDirChange:
	;
	; Change to the directory.
	;
		mov	dx, offset dos7FindData.W32FD_fileName.MSD7GN_longName
		call	DOSInternalSetDir
		ERROR_C	MSDOS7_CANT_CHANGE_DIR_WHILE_MAPPING
		jmp	finish

dealWithIllegalChars:
	;
	; Read the name from the header. 
	;
		push	dx, ds
		segmov	ds, es
		mov	dx, di				; ds:dx <- fd
		mov	cx, size GFH_signature+ size GFH_longName
							; copy amount
		mov	si, offset dos7MPHeaderScratch		; es:si <-dst 
		call	DOSVirtOpenGeosFileForHeader
	;
	; Compare the two names.
	;
		add	si, size GFH_signature		; point to name
		mov	di, si
		mov	cx, es:[dosFinalComponentLength]; number to compare
		segmov	ds, ss
		lea	si, ss:[passedName]		; es:di <- passed str
		call	LocalCmpStringsNoCase
		pop	dx, ds
		LONG	jz	success
		
		mov	ax, MSDOS7F_FIND_NEXT
		LONG	jmp	findLongName

	
DOS7MapComponent	endp


; Bad characters are :
;	" ' / : < > ? |     
; These are replaced with ^
;
LocalDefNLString charTable <'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ !^#$%&^()*+,-.^0123456789^;^=^^@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\\\]^_`abcdefghijklmnopqrstuvwxyz{^}~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7BadCharReplace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take the string in es:di and replace any illegal DOS
		chars with carrots, returning the z flag to indicate
		whether or not there were any.

		looks at up to (size GeosLongName + size shortName) chars,
		stopping as soon as it sees a null.

CALLED BY:	utility

PASS:		es:di	= string to check
RETURN:		z flags set if string contained illegal characters.
			clear if legal string (unchanged)
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	2/20/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7BadCharReplace	proc	far

	;
	; Set up ds:si = es:di for string instructions.  If cx is zero then
	; we'll look at up to longname+shortname # characters, or until we
	; find a null.
	;
		push	bx, cx, ds, si, di
		segmov	ds, es
		mov	si, di		
		push	di			; save start for later
		mov	bx, offset charTable
		tst	cx
		jnz	charLoop
		
		mov	cx, size MSDOS7LongNameType + size MSDOS7ShortNameType
charLoop:
		lodsb				; al <- next char from ds:si
		tst	al			; end o' string?
		jz	done
		
		cs:xlatb			; al <- new char
		stosb				
		loop	charLoop
done:
	;
	; Now see if we replaced any characters.
	;
		mov	cx, di			; cx <- end
		pop	di			; di <- start
		sub	cx, di			; cx <- length
		mov	al, '^'			
		repne	scasb
		pop	bx, cx, ds, si, di
		ret
DOS7BadCharReplace endp



		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7RenameFileFromGeosHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Construct a newfile name based on the changed attribute flags.
		Rename the file once the name is constructed.  This does
		the copying from the GeosFileHeader to the long name.  Like
		dosEnum shme, it only copies the things that have changed.

CALLED BY:	DOSVirtWriteChangedExtAttrs

PASS:		es:di	= GeosFileHeader to rename from
		ds:dx	= existing  long name
		si	= disk handle
		ax	= EAMasks to tell us which ones we need to
			  copy.
RETURN:		ds:dx	= new long name
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	12/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7RenameFileFromGeosHeader	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds

		.enter
if ERROR_CHECK
NOFXIP <	Assert	fptr dsdx					>
NOFXIP <	Assert	fptr esdi					>
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		mov	bx, es						>
FXIP<		mov	si, di						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif
		
	;
	; First copy the whole existing long name to dos7LongName, which
	; is the buffer we user for building the new name.
	;
		push	ds, dx			; save source file long name
		push	es, di			; save GeosFileHeader
		mov	cx, ds			; save source name seg
		call	PathOps_LoadVarSegDS
		segmov	es, ds
		mov	ds, cx				
		mov	si, dx			; ds:si <- existing name
		mov	di, offset dos7LongName	; es:di <- build buffer
		mov	cx, size MSDOS7GeosName
		rep	movsb
	;
	; Set up for the header -> name map/copy.
	;
		mov	di, offset dos7LongName	; es:di <- dest name
		pop	ds, si			; ds:si <- GeosFileHeader
	;
	; Look through the passed EAMasks to see what to change.
	; We have :
	;		ax <- EAMasks telling us what to copy
	;		bx <- index for tables based on current attr
	;		cx <- size of attr to copy
	;		ds:si <- start of header
	;		es:di <- start of long file name
		
		clr	bx
attrLoop:
		shr	ax			; carry gets attr bit
		jc	copyAttr		;
	
		tst	ax			; finished?
		jz	rename

		inc	bx			
		inc	bx			; next table offset
		jmp	attrLoop
		
copyAttr:
		mov	cx, cs:[attrSizeTable][bx]	; cx <- source size
	; Zero size means we don't store this attr in the long name.
		jcxz	attrLoop

	; Set up and call the attrs copy routine.
		push	di, si				; save offsets
		add	si, cs:[headerOffsetTable][bx]	; si, header offset
		add	di, cs:[longnameOffsetTable][bx] ; long name offset
		call	cs:[attrRoutineTable][bx]
		pop	di, si
		inc	bx
		inc	bx
		jmp	attrLoop
rename:
	;
	; Rename the bloody thing.  es:di is the rename name.
	;
	; I don't think we need to do the notify shme here...
	;
		
		pop	ds, dx			; source name
		mov	ax, MSDOS7F_RENAME_FILE
		call	DOSUtilInt21
EC <		WARNING_C MSDOS7_RENAME_FROM_HEADER_FAILED		>
	;
	; Copy the new name to the location of the old one.
	;
		segxchg	ds, es
		mov	si, di
		mov	di, dx
		mov	cx, size MSDOS7GeosName
		rep	movsb
		jmp	done

stringCopy:
	; Just copy cx characters as they are, then space pad the rest.
	; This assumes cx is the size in bytes not characters.
		push	ax
		push	cx		; source size
		mov	dx, di		; save current dest offset
charLoop:
		lodsb
		tst	al
		jz	spacePad
		stosb
		loop	charLoop
spacePad:
		sub	di, dx
		pop	cx
		sub	cx, di
		jcxz	return

		LocalLoadChar ax, ' '
SBCS <		rep	stosb						>
DBCS <		rep	stosw						>
		pop	ax
return:
		retn
mapCopy:
	; Convert to ascii and copy.
		call 	DOS7MapBytesToAscii
		retn
doNothing:
		retn							
done:
		.leave
		ret


attrRoutineTable		nptr	mapCopy,		; sig
					stringCopy,		; longname
					mapCopy,		; type
					mapCopy,		; flags
					mapCopy,		; release
					mapCopy,		; protocol
					mapCopy,		; token
					mapCopy,		; creator
					doNothing,		; user notes
					doNothing,		; copyright
					doNothing,		; no time/date
					doNothing,		; password
					doNothing,		; desktop
					doNothing,		;
					doNothing		;
			
		
headerOffsetTable	word	offset  GFH_signature,
				offset	GFH_longName,
				offset	GFH_type,
				offset  GFH_flags,
				offset	GFH_release,
				offset	GFH_protocol,
				offset	GFH_token,
				offset	GFH_creator,
				0,
				0,
				0,
				0,
				0,
				0,
				0
								
		
longnameOffsetTable	word	offset  MSD7GN_signature,
				offset  MSD7GN_longName,
				offset	MSD7GN_type,
				offset	MSD7GN_flags,
				offset	MSD7GN_release,
				offset	MSD7GN_protocol,
				offset	MSD7GN_token,
				offset	MSD7GN_creator,
				0,
				0,
				0,
				0,
				0,
				0,
				0
		
attrSizeTable 		word 	size GFH_signature,
				size GFH_longName,
				size GFH_type,
				size GFH_flags,
				size GFH_release,
				size GFH_protocol,
				size GFH_token,
				size GFH_creator,
				0,
				0,	
				0,
				0,
				0,
				0,
				0
		
CheckHack <length attrRoutineTable  eq length headerOffsetTable >
CheckHack<length headerOffsetTable eq length longnameOffsetTable>
CheckHack<length longnameOffsetTable eq length attrSizeTable>
		
DOS7RenameFileFromGeosHeader	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7MapAsciiToBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map cx*2 ascii bytes to the passed buffer.  Each ascii
		byte becomes a hex nybble.

CALLED BY:	utility

PASS:		ds:si 	= source of ascii bytes
		es:di	= place to build result
		cx	= number of bytes to _produce_
RETURN:		XXXX
DESTROYED:	XXXX

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/10/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7MapAsciiToBytes	proc	far
		uses	ax, bx
		
		.enter
EC <		jcxz	error						>
NEC <		jcxz	done						>

		shl	cx			; takes 2 bytes to make one
byteLoop:
	;
	; Load al with the next character and map it to hex.
	;
		mov	ah, al
		lodsb
EC <		Assert	ge al, '0'					>
EC <		Assert	le al, 'F'					>

		cmp	al, 'A'		; A-F?
		jb	subZero

		sub	al, 7
subZero:
		sub	al, '0'
		dec	cx			; ready to write a bytes?
		test 	cx, 1
		jnz	byteLoop

		shl	ah
		shl	ah
		shl	ah
		shl	ah
		or	al, ah
		stosb
		jcxz	done
		jmp	byteLoop

done:
		.leave
		
		ret
error:

EC <		ERROR MSDOS7_CANT_MAP_ZERO_BYTES			>
		
		.unreached

DOS7MapAsciiToBytes	endp
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7MapBytesToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map cx bytes from ds:si to ascii double-bytes and
		copy them to es:di.

CALLED BY:	Utility

PASS:		ds:si 	= source bytes
		es:di	= destination for mapped bytes
		cx	= number of bytes to map from the source
			  (cx*2 needed for the destination).
RETURN:		si, di moved past last copied byte
DESTROYED:	cx, dx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/ 8/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7MapBytesToAscii	proc	near
		uses	ax, bx
		.enter

DBCS <		CheckHack 1 eq 2					>
EC <		jcxz	error						>
NEC <		jcxz	done						>
		
byteLoop:
		lodsb
		call	DOS7MapByteToAscii
		loop	byteLoop

NEC < done:								>
		.leave
		ret
error:
EC <		ERROR MSDOS7_CANT_MAP_ZERO_BYTES			>
		.unreached
DOS7MapBytesToAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7MapByteToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maps ONE hex byte to two ascii chars, putting them in
		es:di.

CALLED BY:	utility

PASS:		al	= byte to map
		es:di	= result buffer
RETURN:		es:di 	= points after result
DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/16/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7MapByteToAscii	proc	near

	;
	; Isolate the nybbles.
	;
		mov	ah, al		; al = ah = byte	
		and	al, 0xf0	; al <- low nybble
		shr	al
		shr	al
		shr	al
		shr	al
		and	ah, 0x0f	; ah <- high nybble shifted up 

	;
	; Map the first one.
	;
		add	al, '0'		; assume < 10 (ah)
		cmp	al, '9'	; is it a-f?
		jbe	writeByte1

		add	al, 0x7		; bump up to a-f
writeByte1:
	;
	; Write the result, then setup and map the second one.
	;
		stosb
		mov	al, ah

		add	al, '0'		; assume < 10 (ah)
		cmp	al, '9'	; is it a-f?
		jbe	writeByte2

		add	al, 0x7		; bump up to a-f
writeByte2:
		stosb

		ret
DOS7MapByteToAscii	endp



DOS7GetGeosDOSName	proc far
	;
	; Pass ds:si pointing to an MSDOS7GeosName.  ds:si will be
	; returned pointing to the short DOS name which can be one of
	; two places, depending on what type of file this is.
	;
		tst	ds:[si].MSD7GN_shortName
		CheckHack <offset MSD7GN_longName eq 0>
		jz	done
		add	si, offset MSD7GN_shortName
done:
		ret
DOS7GetGeosDOSName endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7SetupDTAHack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hack to maintain the DTA that the rest of the file system
		currently depends on.  In the final deal, there will be no
		DTA;  a W32FindEData instead.

CALLED BY:	

PASS:		ds:si	= W32FindData
		es:di	= FileFindDTA
RETURN:		XXXX
DESTROYED:	XXXX

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/ 9/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7SetupDTAHack	proc	far
		uses	ax,bx,cx,dx,si,di,bp
	.enter

if 0
		push	ds
		call	SysLockBIOS
		segmov	ds, es
		mov	dx, di
		mov	ah, MSDOS_SET_DTA
		call	DOSUtilInt21
		
		pop	ds
		mov	ah, MSDOS_FIND_FIRST
		mov	dx, offset dos7FindData.W32FD_alternateFileName
		mov	cx, mask FA_HIDDEN or mask FA_SYSTEM or mask FA_SUBDIR
		call	DOSUtilInt21
		call	SysUnlockBIOS

endif
	; just do attrs, mod time, file size, and name.  Hope those
	; undocumented fields aren't used...

	;name
		push	si, di
		add	si, offset W32FD_fileName 
		call	DOS7GetGeosDOSName
		add	di, FFD_name
		mov	cx, size FFD_name-1
		LocalCopyNString
		mov	al, 0
		stosb
		pop	si, di
		
	;attrs
		mov	al, ds:[si].W32FD_fileAttrs.low.low
		mov	es:[di].FFD_attributes, al
	;mod time
		mov	ax, ds:[si].W32FD_accessed.MSD7DT_time
		mov	bx, ds:[si].W32FD_accessed.MSD7DT_date
		mov	es:[di].FFD_modTime, ax
		mov	es:[di].FFD_modDate, bx
	; size
		movdw	axbx, ds:[si].W32FD_fileSizeLow
		movdw	es:[di].FFD_fileSize, axbx
		
		.leave
		ret
DOS7SetupDTAHack	endp

		
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7GenerateGeosLongName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a complex long name, consisting of the long name
		in dos7LongName, the short name we generate here,
		the passed file type, the known signature, and
		the known GeodeAttrs (0) for data, which we assume.

CALLED BY:	utility

PASS:		ds:dx	= geos long name
 		es	= dgroup
		ax	= GeosFileType
		ch	= FileCreateFlags
RETURN:		dos7LongName filled with the created long name.
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	12/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
geosSignature	char		MSDOS7_GEOS_SIGNATURE_ASCII
DOS7GenerateGeosLongName	proc	near

		.enter
	;
	; Copy the long name and space pad the rest.
	;
		push	ax				; save file type
		call	DOS7GenerateLongNameCommon
	;
	; See if we have some mutant native file with ext attrs to deal with.
	;
		test	ch, mask FCF_NATIVE_WITH_EXT_ATTRS
		LONG	jnz	handleNativeWithExtAttrs
	;
	; Generate the virtual native name.  Space pad it.
	; 
		segxchg	es, ds				; ds <- dgroup
		mov	di, dx				; es:di <- long name
		LocalStrLength				; cx <- length

		mov	ds:[dosFinalComponent].high, es
		mov	ds:[dosFinalComponent].low, dx
		mov	ds:[dosFinalComponentLength], cx
		call	DOSVirtGenerateDosName		; ds:dx <- dos7LongName
		
		segmov	es, ds
		mov	di, dx				; es:di <- long name
		add	di, offset MSD7GN_shortName
common:
		LocalStrLength				; cx <-length
		
		dec	di				; point to null
		mov	ax, cx
		mov	cx, size MSD7GN_shortName
EC <		Assert	ae cx, ax					>
		sub	cx, ax
DBCS <		shr	cx						>
		LocalLoadChar	ax, ' '
SBCS <		rep	stosb						>
DBCS <		rep	stosw						>
	;
	; Convert the file type to ascii and store it at the proper offset.
	;
		pop	ax			; ax <- file type
		mov	ch, ah
		mov	di, offset dos7LongName.MSD7GN_type
		call	DOS7MapByteToAscii
		mov	al, ch
		call	DOS7MapByteToAscii
	;
	; Copy the signature in there, too.  Since we're creating the
	; file, we use the defined ascii rep of the signature.
	;
		segmov	ds, cs
		mov	si, offset geosSignature
		mov	cx, size geosSignature
		mov	di, offset dos7LongName.MSD7GN_signature
		rep	movsb
	;
	; Set the GeodeAttrs to be 0, which means '0000' in ascii land.
	;
		mov	di, offset dos7LongName.MSD7GN_geodeAttrs
		mov	ax, '00'
		stosw
		stosw
		segmov	ds, es
	;
	; Set the Token and Creator fields to be 0/geoworks.
	;
		mov	di, offset dos7LongName.MSD7GN_token
		mov	ax, '00'
		mov	cx, 4
		rep	stosw

		mov	di, offset dos7LongName.MSD7GN_creator
		mov	cx, 4
		rep	stosw
	;
	; Is that it?
	;
	; 	...
		
		.leave
		ret
handleNativeWithExtAttrs:
		push	ds
		segmov	ds, es
		mov	si, offset dos7LongName
		mov	di, offset dos7LongName.MSD7GN_shortName
		mov	cx, size MSD7GN_shortName
		rep	movsb
		mov     {byte}	es:[di], 0
		pop	ds
		mov	di, offset  dos7LongName.MSD7GN_shortName
		jmp	common
DOS7GenerateGeosLongName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7GenerateNativeLongName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a long name suitable for native naming.

CALLED BY:	
PASS:		ds:dx	= long name
		es	= dgroup
RETURN:		XXXX
DESTROYED:	XXXX

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/15/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7GenerateNativeLongName	proc	near
		.enter
		push	es					
		segmov	es, ds						
		mov	di, dx						
		LocalStrLength						
EC <		Assert	le, cx, DOS_DOT_FILE_NAME_LENGTH		>
		pop	es					
	;
	; Copy the long name, space pad, and nullify.
	;
		call	DOS7GenerateLongNameCommon
	;
	; Copy the passed name to the short name too.
	;
		mov	si, dx			; ds:si <- source
		mov	di, offset dos7LongName.MSD7GN_shortName
		rep	movsb
	;
	; And put the ol' native signature in there.
	;
		push	ds
		segmov	ds, es
		mov	si, offset nativeSignature
		mov	di, offset dos7LongName.MSD7GN_signature
		mov	cx, size nativeSignature
		rep	movsb
		mov	al, 0			; null term after signature.
		stosb
		pop	ds
		
		.leave
		ret
DOS7GenerateNativeLongName endp

		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7GenerateLongNameCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the part of the complex long name that is
		common to geos and native files, that is :

			- space pad the whole thing
			- copy the passed geos long name
			- put the null in the right place.

		Create the thing in dos7LongName in dgroup
		
CALLED BY:	utility

PASS:		ds:dx	= geos long name
		es	= dgroup
RETURN:		es:di	= dos7LongName
DESTROYED:	ax, di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/15/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7GenerateLongNameCommon	proc	near

		uses	cx, dx
		.enter
	;
	; Space pad the short name.  Then write '0's into the rest.
	; (DOS7CopyLongName will space pad the geos longname) Nullit.
	;
		mov	di, offset dos7LongName.MSD7GN_shortName
							; es:di <- dest 
		mov	al, ' '
		mov	cx, size MSD7GN_shortName
		rep	stosb
		mov	al, '0'
		mov	cx, (offset MSD7GN_null) - (offset MSD7GN_signature)
		rep	stosb						
		mov	es:[dos7LongName].MSD7GN_null, 0
	;
	; Copy the long name. 
	;
		mov	di, offset dos7LongName.MSD7GN_longName
							; es:di <- dest
		mov	si, dx				; ds:si <- source
		mov	cx, -1				; signal space pad
		call	DOS7CopyLongName	; destroys ax
		call	DOS7BadCharReplace
		
		.leave
		ret	
DOS7GenerateLongNameCommon	endp



		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7RenameGeosFileHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the long name stored inside the geos file header.
		This does NOT update other attributes stored in the header,
		assuming these are current.

CALLED BY:	Utility

PASS:		es	= dgroup
		ds:si	= pointing to the file to rename.  No need to do a
		find first, as the long name is in complete form.

		Since the geos long name may have illegal charcters in it,
		we copy the name from dosFinalComponent to the GeosFileHeader.

		(si = disk handle?  for directories??????)
RETURN:		carry set if failure
		clear for succes
DESTROYED:	the file name is hosed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/ 3/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7RenameGeosFileHeader	proc	far

		uses	ax,bx,cx,dx,si,di,bp, es
		.enter
	;
	; Allocate a slot in the JFT for us to use.
	; 
		mov	bx, NIL
		call	DOSAllocDosHandleFar
	;
	; DEAL WITH SUBDIR HERE????
	;

	;
	; Open the file.
	;
		mov	bx, FA_WRITE_ONLY	; bl <- access flags
		clr	cx			; attributes
		clr	di			; no alias hint
		mov	dx, MSDOS7COOA_OPEN	; there's gotta be a better...
		mov	ax, MSDOS7F_CREATE_OR_OPEN
		call	DOSUtilInt21			; ax <- handle
		jc	errorOpen
	;
	; Position the file pointer.
	;
		mov_tr	bx, ax			; bx <- file handle
		mov	dx, offset GFH_longName
		clr	cx
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21
	;
	; Write out the whole long name.
	;
		les	di, es:[dosFinalComponent]
						; ds:di <- source string
		push	di
		LocalStrLength	ax		; cx <- length w/o null
		pop	dx
		segmov	ds, es
DBCS <		shl	cx, 1			; cx <- # of bytes	>
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21
	;
	; Close the file again, being careful to save any error flag & code
	; from the write.
	; 
		pushf
		push	ax
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
		pop	ax
		popf
		
errorOpen:
		mov	bx, NIL		; release the JFT slot (already nilled
					;  out by DOS itself during the close)
		call	DOSFreeDosHandleFar	
		.leave
		ret
DOS7RenameGeosFileHeader	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7CopyLongName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the long name in ds:si to ed:di, space padding as
		desired.

CALLED BY:	utility

PASS:		ds:si	= source ptr
		es:di	= dest ptr
		cx	= 0 to null term, non-zero to space pad
RETURN:		ptrs unchanged

DESTROYED:	ax, cx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/ 3/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7CopyLongName	proc	near

		uses dx, di, si
		.enter
	;
	; Copy the null terminated string no matter what.
	;
		mov	dx, di			; dx <- start
		LocalCopyString
	;
	; Now space pad if desired.
	;
		jcxz	done
	;
	; Space pad
	;
		LocalPrevChar	esdi	; pre-null
		push	di		; save end ptr
		sub	di, dx		; di <- length of name copied
DBCS <		shr	di						>
		mov	cx, size MSD7GN_longName
DBCS <		shr	cx						>
		sub	cx, di		; cx <- num blanks to pad
		pop	di		; end ptr 

		LocalLoadChar	ax, ' '
SBCS <		rep	stosb						>
DBCS <		rep	stosw						>
		
done:
		.leave
		ret
DOS7CopyLongName	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7UnPadLong/ShortName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	slap a null down at the end of the geos long name
		!! destructive !!

CALLED BY:	utility

PASS:		es:di	= ptr to long name buffer to null term
		ax	= non zero to pad the thing (DESTRUCTIVE)
		ax	= 0 to just get the length, but not add the null

RETURN:		buffer nulled after long name
 		or
		ax 	= length of unpadded string
DESTROYED:	nothing
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/ 3/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7UnPadLongName	proc	far

		uses	cx, di, si
		.enter
	;
	; Get to the end of the string.
	;
		mov	si, di				; si, <- start, too
		add	di, size MSD7GN_longName	; es:di <- end
		LocalPrevChar	esdi			; point at last char

		mov	cx, size MSD7GN_longName
		call	DOS7UnPadName

		.leave
		ret
DOS7UnPadLongName	endp
			

DOS7UnPadShortName proc far

		uses	cx, di, si
		.enter
	;
	; Get to the end of the string.
	;
		mov	si, di				; si <- start
		add	di, size MSD7GN_shortName
		LocalPrevChar	esdi			; point at last char

		mov	cx, size MSD7GN_shortName
		call	DOS7UnPadName		
		.leave
		ret
		
DOS7UnPadShortName endp
		
DOS7UnPadName proc near
	;
	; Null terminates the blank-padded string which ends at es:di.
	;
	; Pass :
	;	es:di pointing to end of the string
	; 	es:si pointing to the start of the string
	;	cx    size of the string
	; Destroyed :
	;	di, si
		
	;
	; Reverse the direction and find the first non-blank.
	;
		push	ax
		INT_OFF
		std
		LocalLoadChar	ax, ' '
DBCS <		repe	scasw						>
SBCS <		repe	scasb						>
DBCS <		add 	di, 4						>
SBCS <		inc	di						>
SBCS <		inc	di						>
		sub	di, si
DBCS <		shr	di						>
	;
	; Redirect things and null terminate.
	;
		cld
		INT_ON
	;
	; Add the null.
	;
		pop	ax
		tst	ax
		jz	returnLength
		
		add	si, di
		LocalClrChar es:[si]
done:
		ret

returnLength:
		mov	ax, di
		jmp	done
		
DOS7UnPadName	endp



if _SFN_CACHE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7CachePathForSFN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cache the CWD for the passed SFN.

CALLED BY:	utility

PASS:		bx	= SFN for the file
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/21/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7CachePathForSFN	proc	far
		uses	ax,bx,cx,dx,si,di, es
		.enter
	;
	; Grab the cache block handle.
	;
		segmov	es, ds				; es <- dgroup
		mov	dx, bx				; dx <- SFN
		mov	bx, ds:[dos7PathCache]
EC <		call	ECCheckMemHandle				>
		call	MemLock
		mov	ds, ax
		mov	si, offset D7PCH_table		; es:si <- table

		shl	dx				; words
		shl	dx
		add	si, dx				; offset 
EC <		Assert	e ds:[si].OFP_pathString[0], 0			>

	;
	; Get the CWD.
	;
		clr	dl			; current drive
		mov	ax, MSDOS7F_GET_CURRENT_DIR
		mov	di, offset dosPathBuffer	; es:di <- path space
		segxchg	ds, es
		xchg	si, di
		call	DOSUtilInt21
	;
	; Get the length of the path string and allocate the chunk.
	;
		segxchg	ds, es
		xchg	si, di
		call	LocalStringSize		; cx <- size
		inc	cx			; null !		
DBCS <		inc	cx						>
		clr	al
		call	LMemAlloc
EC <		ERROR_C	MSDOS7_CANT_ALLOC_OPEN_FILE_CACHE_SPACE		>
	;
	; Store the chunk handle and copy the path string into the chunk
	;
		mov	ds:[si].OFP_pathString, ax
		mov	bx, ax			; bx <- chunk handle
		mov	si, ds:[bx]		; ds:si <- destination
		segxchg	ds, es			
		xchg	si, di			; all set up 		
		shr	cx			; copy words, please
		rep	movsw
		jnc	finish
		
		movsb
finish:
	;
	; Unlock the path cache block.
	;
		mov	bx, ds:[dos7PathCache]
EC <		call	ECCheckMemHandle				>
		call	MemUnlock
		
		.leave
		ret
DOS7CachePathForSFN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7ClearCacheForSFN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the cached path info for the passed SFN

CALLED BY:	Utility

PASS:		bx	= SFN for the file
		ds	= dgroup
RETURN:		XXXX
DESTROYED:	XXXX

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/21/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7ClearCacheForSFN	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Lock the cache block.
	;
		push	ds				; save dgroup
		mov	dx, bx				; dx <-SFN
		mov	bx, ds:[dos7PathCache]
EC <		call	ECCheckMemHandle				>
		call	MemLock
	;
	; Point to the proper table entry.
	;
		mov	ds, ax
		mov	si, offset D7PCH_table
		shl	dx
		shl	dx
		add	si, dx				; ds:si <- entry
	;
	; Free the chunk
	;
		clr	ax
		xchg	ax, ds:[si].OFP_pathString
		tst	ax
		jz	done
		call	LMemFree
	;
	; Unlock the path cache.
	;
done:
		pop	ds
		mov	bx, ds:[dos7PathCache]
		call	MemUnlock
		
		.leave
		ret
DOS7ClearCacheForSFN	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7GetPathForSFN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the path associated with the passed SFN, checking to
		see if the cached path is the same as DOS's current path.

CALLED BY:	utility

PASS:		bx	= SFN
		ds	= dgroup
		es:di	= place to copy the path if different
 				better be MSDOS7_MAX_PATH_SIZE large
RETURN:		es:di	= filled 

DESTROYED:	?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/22/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7GetPathForSFN	proc	far

		uses	bx,cx,si,di
		.enter
	;
	; Point to the proper entry.
	;
		push	ds				; save dgroup
		mov	dx, bx				; dx <- SFN
		mov	bx, ds:[dos7PathCache]
EC <		call	ECCheckMemHandle 				>
		call	MemLock
		mov	ds,ax		
		mov	si, offset D7PCH_table		; ds:si <- table
	;
	; Access the correct entry.
	;
		shl	dx
		shl	dx				; 4 words per entry
		add	si, dx				; ds:si <- entry
		mov	bx, ds:[si].OFP_pathString	; bx <- chunk handle
EC <		tst	bx						>
EC <		ERROR_Z	MSDOS7_MISSING_PATH_CACHE_CHUNK_HANDLE		>
	;
	; Copy the string to the buffer
	;
		mov	si, ds:[bx]			; ds:si <- path string
		LocalCopyString
	;
	; Clean and go.
	;
		pop	ds			; dgroup
		mov	bx, ds:[dos7PathCache]	; bx <- path cach handle
EC <		call	ECCheckMemHandle				>
		call	MemUnlock
		
		.leave
		ret	
DOS7GetPathForSFN	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7GetIDFromFD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the 32 bit id associated with the file found in the
		passed Win32FindData structure.  The id is based on the
		current path and the embedded dos name (shortName) for the
		file.

CALLED BY:	Utility

PASS:		ds:si	= Win32FindData structure
		dx	= 0 if want to use CWD
			else
		cxdx	= base ID from which to work from
RETURN:		cxdx	= 32 bit Id
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	2/ 3/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7GetIDFromFD	proc	far
scratch			local	(FILE_LONGNAME_LENGTH+2) dup(char)
scratchLength		local	word

		uses	ax, ds, es, si, di
		.enter
	;
	; Copy the short name locally, so we can null terminate it, unless
	; it's a directory, in which case we use the geos long name.
	; Assume we'll use the short name (ie, it's a file, not a dir)
	;
		push	cx, dx
		mov	cx, DOS_DOT_FILE_NAME_LENGTH
		mov	di, offset W32FD_fileName.MSD7GN_shortName
		test	ds:[si].W32FD_fileAttrs.low.low, mask FA_SUBDIR
		jz	copyName

	; Wrong.  Set up for short name. (file)
		mov	cx, FILE_LONGNAME_LENGTH
		mov	di, offset W32FD_fileName.MSD7GN_longName
copyName:
		mov	ss:[scratchLength], cx
		add	si, di			; ds:si <- pts to name to use
		segmov	es, ss
		lea	di, ss:[scratch]	; es:di <- dest buff
	;
	; Space pad whole the scratch space, and copy.
	;
		push	di
		mov	al, ' '
		rep	stosb
		pop	di
		mov	cx, ss:[scratchLength]
		mov	ax, di
		rep	movsb
	;
	; We have es:di pointing to the end of the short name area, and
	; es:si pointing to the start.  Need cx size of field, and we're ready.
	;
		mov	di, ax
		add	di, ss:[scratchLength]
		dec	di
		mov	si, ax
		mov	cx, ss:[scratchLength]
		call	DOS7UnPadName
	;
	; Get the ID for the current path.
	;
		pop	cx, dx
		tst	dx
		jnz	calcID
		call	DOSFileChangeGetCurPathID	; cxdx <- path ID
	;
	; Use that for the base for generating the file's ID.
	;
calcID:
		segmov	ds, ss
		lea	si, ss:[scratch]
		call	DOSFileChangeCalculateIDLow	
		.leave
		
		ret
		
DOS7GetIDFromFD	endp

endif


		
		
PathOps	ends


