COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosVirtual.asm

AUTHOR:		Adam de Boor, Feb 11, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/11/92		Initial revision


DESCRIPTION:
	The functions in this file implement the virtual <-> native
	name mapping for DOS-based filesystems.
		

	$Id: dos7Virtual.asm,v 1.1 97/04/10 11:55:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtMapToDOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A function provided for secondary drivers to map a name
		in the PC/GEOS character set in standard 8.3 format to
		an 11-character array, with both the root and the extension
		space-padded and nary a decimal point in sight.

CALLED BY:	DR_DPFS_MAP_TO_DOS
PASS:		ds:dx	= file name to map
		cx	= # chars to map
		es:si	= place to store the result
RETURN:		carry set if name not a valid DOS name
DESTROYED:	bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		MUST BE IN FIXED CODE AS GFS DRIVERS CALL IT WITH THE 
		FILESYSTEM LOCKED.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtMapToDOS	proc	far
SBCS <		uses	ax, si, cx, dx					>
DBCS <		uses	ax, bx, si, cx, dx				>
		.enter
	;
	; Map the root, up to null or '.', space padding as required to get out
	; to the full 8 characters.
	; 
		mov	di, si		; es:di <- dest for mapping
		mov	si, dx
		add	dx, cx
		mov	cx, DOS_FILE_NAME_CORE_LENGTH

DBCS <		call	DCSFindCurCodePage				>
mapRootLoop:
		cmp	si, dx		; hit the end of the name?
		je	padRoot		; yes -- pad the rest of the way

DBCS <		mov	ax, ds:[si]					>
SBCS <		lodsb							>
		LocalCmpChar ax, '.'	; end of root?
		jne	mapRootChar	; no
SBCS <		dec	si		; back up so we keep coming here for >
SBCS <					;  the remainder of the root name. >
padRoot:
		mov	al, ' '		; store a space instead
DBCS <		stosb							>
		jmp	storeRootChar

mapRootChar:
SBCS <		call	DOSVirtCheckLegalDosFileChar			>
SBCS <		jnc	fail		; => not legal in a name	>
SBCS <		call	DOSUtilGeosToDosChar				>
DBCS <		call	DCSGeosToDosCharFileString			>
		jc	fail		; => not mappable to DOS set
storeRootChar:
SBCS <		stosb							>
		loop	mapRootLoop
	;
	; Done with all 8 chars. What did we end on?
	; 
		cmp	si, dx		; at end of name?
		je	startExtLoop	; yes -- don't check final char, just
					;  space-fill the extension

		LocalGetChar ax, dssi, NO_ADVANCE
		LocalCmpChar ax, '.'
		jne	fail		; => too many chars before ., so not
					;  DOS
		LocalNextChar dssi	; point to first extension char.
startExtLoop:
	;
	; Map the extension, up to null, space padding what's not there.
	; 
		mov	cx, DOS_FILE_NAME_EXT_LENGTH
mapExtLoop:
		cmp	si, dx		; hit the end of the name?
		jne	fetchExtChar	; no -- get the next char

		mov	al, ' '
DBCS <		stosb							>	
		jmp	storeExtChar

fetchExtChar:
SBCS <		lodsb							>
SBCS <		call	DOSVirtCheckLegalDosFileChar			>
SBCS <		jnc	fail		; => not legal in a name	>
SBCS <		call	DOSUtilGeosToDosChar				>
DBCS <		call	DCSGeosToDosCharFileString			>
		jc	fail		; => not mappable to DOS set
storeExtChar:
SBCS <		stosb							>

		loop	mapExtLoop

		cmp	si, dx
		jne	fail		; => name too long
done:
		.leave
		ret
fail:
		stc
		jmp	done
DOSVirtMapToDOS	endp

if _MS7
; ms7 allows a few extra characters.
LocalDefNLString badDosFilenameChars <'"*./:<>?\\\\|'>
else
LocalDefNLString badDosFilenameChars <'"*+,./:;<=>?[\\\\]|'>
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtCheckLegalDosFileChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed character is legal in a DOS filename and
		map it to an underscore if it's not.

CALLED BY:	INTERNAL
PASS:		ax	= char to check
RETURN:		carry clear if illegal:
			ax	= _
		carry set if legal
			ax	= untouched
DESTROYED:	

PSEUDO CODE/STRATEGY:
		MUST BE IN FIXED CODE AS GFS DRIVERS CALL IT WITH THE 
		FILESYSTEM LOCKED.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtCheckLegalDosFileChar proc	far
		uses	es, di, cx
		.enter
if not _MS7
		LocalCmpChar	ax, ' '	; space or ctrl code?
		jbe	fail
endif
		
	; DOS2.X: high-ascii chars not allowed either, mappable or not.
		segmov	es, cs
		mov	di, offset badDosFilenameChars
		mov	cx, length badDosFilenameChars
DBCS <		repne	scasw						>
SBCS <		repne	scasb						>
		stc
		jne	done
if not _MS7
fail:
endif
		LocalLoadChar	ax, '_'
		clc

done:
		.leave
		ret
DOSVirtCheckLegalDosFileChar		endp

Resident	ends

PathOps		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtCheckNumericExtension
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the filename extension at es:di is all numeric.

CALLED BY:	
PASS:		es:di	= start of extension to check
RETURN:		carry set if extension is all numeric
		ax	= first 2 chars of extension
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtCheckNumericExtension proc	far
		.enter
		mov	ax, es:[di]
		cmp	ax, '0' or ('0' shl 8)
		jb	notNumeric
		cmp	al, '9'
		ja	notNumeric
		cmp	ah, '9'
		ja	notNumeric
		cmp	{word}es:[di][2], '0' or (0 shl 8)
		jb	notNumeric
		cmp	{word}es:[di][2], '9' or (0 shl 8)
		ja	notNumeric
		stc
done:
		.leave
		ret
notNumeric:
		clc
		jmp	done
DOSVirtCheckNumericExtension endp
if not _MS7



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtCheckPossibleGeosFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the file in the passed FileFindDTA might be a
		geos file, with all that implies.

CALLED BY:	DOSVirtOpenGeosFileForHeader
PASS:		ds:dx	= FileFindDTA
RETURN:		carry set if a possible geos file
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
			.GEO
			.VM
			.DB
			.STA
			.BIT
			.[0-9][0-9][0-9]
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtCheckPossibleGeosFile proc	near
		uses	es, di, cx, ax
		.enter
		segmov	es, ds
		mov	di, dx
	;
	; Because of the way we create directories (if their virtual name
	; is a valid DOS name, we create the directory with the virtual name
	; as its DOS name, so the user doesn't get thoroughly confused
	; when s/he goes to DOS), we must assume that any directory is a
	; possible GEOS file, regardless of its name -- ardeb 4/2/92
	; 
		test	es:[di].FFD_attributes, mask FA_SUBDIR
		jnz	success

		add	di, offset FFD_name
		mov	cx, size FFD_name
		mov	al, '.'
		repne	scasb
		jne	fail
	;
	; Deal with numeric suffix first, as they're the most common in
	; our world.
	; 
		call	DOSVirtCheckNumericExtension
		jc	success
	;
	; Next check .geo
	; 
		cmp	ax, 'G' or ('E' shl 8)
		jne	checkVM
		cmp	{word}es:[di][2], 'O' or (0 shl 8)
		jne	fail
success:
		stc	; signal the truth of the assertion
done:
		.leave
		ret
checkVM:
	;
	; Look for .vm
	; 
		cmp	ax, 'V' or ('M' shl 8)
		jne	checkDB
checkFinalNull:
	;
	; Common code to ensure extension is just 2 chars.
	; 
		cmp	{char}es:[di][2], 0
		je	success
fail:
	;
	; Common code to signal failure.
	; 
		clc	; signal the falsehood of the assertion
		jmp	done
checkDB:
	;
	; Look for .db
	; 
		cmp	ax, 'D' or ('B' shl 8)
		je	checkFinalNull
	;
	; Look for .sta
	; 
		cmp	ax, 'S' or ('T' shl 8)
		jne	checkBit
		cmp	{word}es:[di][2], 'A' or (0 shl 8)
		je	success
		jmp	fail

checkBit:
	;
	; Look for .bit (background bitmaps)
	; 
		cmp	ax, 'B' or ('I' shl 8)
		jne	checkSym
		cmp	{word}es:[di][2], 'T' or (0 shl 8)
		jne	fail
		jmp	success

checkSym:
	;
	; Look for .sym (linker symbol file)
	;
		cmp	ax, 'S' or ('Y' shl 8)
		jne	checkObj
		cmp	{word}es:[di][2], 'M' or (0 shl 8)
		jne	fail
		jmp	success

checkObj:
	;
	; Look for .obj (assembler object file)
	;
		cmp	ax, 'O' or ('B' shl 8)
		jne	checkLdf
objPart2:
		cmp	{word}es:[di][2], 'J' or (0 shl 8)
		jne	fail
		jmp	success

checkLdf:
	;
	; Look for .ldf (library definition file)
	;
		cmp	ax, 'L' or ('D' shl 8)
		jne	checkEbj
		cmp	{word}es:[di][2], 'F' or (0 shl 8)
		jne	fail
		jmp	success
    
checkEbj:
	;
	; Look for .ebj (error-checking assembler object file)
	;
		cmp	ax, 'E' or ('B' shl 8)
		je	objPart2
		jmp	fail
DOSVirtCheckPossibleGeosFile endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtOpenSpecialDirectoryFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a FileFindDTA for a directory, try and open the
		special file we create to hold the directory's extended
		attributes.

CALLED BY:	DOSVirtOpenGeosFileForHeader, DOSVirtMapCheckGeosName
PASS:		ds:dx	= FileFindDTA
		al	= FileAccess type
		JFT slot allocated already
		CWD lock grabbed and directory set to the one that contains
			the passed directory.


		MS7:

		ds:dx	= Win32FindData

RETURN:		carry set if couldn't open the file
		carry clear if could:
			ax	= file handle
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIR_NAME_PATH_SIZE	equ (size FFD_name + 1) * 2
DOSVirtOpenSpecialDirectoryFile proc far
if _MS7
fileName	local	MSDOS7_MAX_PATH_SIZE dup(char)
else
fileName	local	DIR_NAME_PATH_SIZE dup(char)
endif
		uses	es, di, ds, si
		.enter
	;
	; Copy the subdirectory's name into the buffer.
	; 
		push	ax
		lea	di, ss:[fileName]
		segmov	es, ss
		mov	si, dx
if _MS7
		add	si, offset W32FD_fileName.MSD7GN_longName
else
		add	si, offset FFD_name
endif
		call	copyName
	;
	; Stick in the appropriate separator...
	; 
		mov	al, '\\'
		stosb
	;
	; Now copy in the well-defined name for our extended directory
	; attributes...
	; 
		segmov	ds, dgroup, si
		mov	si, offset dirNameFile
		call	copyName
	;
	; Try and open that file.
	; 
		segmov	ds, ss
		lea	dx, ss:[fileName]
		pop	ax
		call	DOSUtilOpenFar
	;
	; Return whatever.
	; 
		.leave
		ret

	;
	; Internal routine to copy a null-terminated string from ds:si to
	; es:di, leaving es:di pointing to the null...
	; 
copyName:
		lodsb
		stosb
		tst	al
		jne	copyName
		dec	di
		retn
DOSVirtOpenSpecialDirectoryFile endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtReadFileHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Actually read the file header from the passed file and
		make sure it's valid.

CALLED BY:	DOSVirtOpenGeosFileForHeader, DOSVirtGetExtAttrsReadHeader
PASS:		bx	= DOS handle
		es:si	= buffer into which to read the thing
		cx	= # bytes to read
RETURN:		carry set if file not a GEOS file
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtReadFileHeader proc	far
		uses	ds, dx, cx
		.enter
	;
	; Make sure the thing isn't a device. This should be quick...
	; 
		mov	ax, MSDOS_IOCTL_GET_DEV_INFO
		call	DOSUtilInt21
		jc	done
		test	dx, mask DOS_IOCTL_IS_CHAR_DEVICE
		stc
		jnz	done
	;
	; Have the file open, so read in the header to the passed buffer.
	; es:si = buffer
	; cx = # bytes to read
	; 
		mov	dx, si
		segmov	ds, es		; ds:dx <- buffer

		mov	ah, MSDOS_READ_FILE
		call	DOSUtilInt21
		jc	done
	    ;
	    ; Check the amount read, special casing the hack in
	    ; DOSGetExtAttrsLow that goes 2 bytes beyond the header to obtain
	    ; possible GeodeAttrs. For a non-executable, non-vm, or directory
	    ; file, however, there could well be just a header, and we'd hate
	    ; to penalize such files because of a hack in DOSFileEnum...
	    ; 
		push	cx
		cmp	cx, size GeosFileHeader
		jbe	checkReadSize
		mov	cx, size GeosFileHeader
checkReadSize:
		cmp	ax, cx			; enough bytes read?
		pop	cx
		jb	shortRead
	;
	; Verify the signature means it's a file with a header.
	;
		cmp	{word}ds:[si].GFH_signature[0], GFH_SIG_1_2
		jne	fail
		cmp	{word}ds:[si].GFH_signature[2], GFH_SIG_3_4
		je	checkGeodeAttrs
if DBCS_PCGEOS
	;
	; There was no DBCS version in 1.X.
	;
else
	;
	; See if it's an old-style VM file.
	;
		cmp	{word}ds:[si].GFH_signature[2], GFHO_SIG_3_4
		je	oldStyleVM
endif
fail:
		mov	ax, ERROR_ATTR_NOT_FOUND
		stc
done:
		.leave
		ret

	;--------------------
shortRead:
if DBCS_PCGEOS
	; there was no DBCS version in 1.X
else
	;
	; Because the 1.X file header is shorter than the 2.X by 50-odd bytes,
	; the file could well be an empty 1.X file without enough data to
	; fill up a 2.0 header. If we read enough to tell from the signature
	; whether the thing's a 1.X file, check it and act accordingly.
	; 
		CheckHack <offset GFHO_signature eq 0>
		cmp	ax, size GFHO_signature
		jb	reallyShortRead		; => not enough to tell

		cmp	{word}ds:[si].GFHO_signature[0], GFHO_SIG_1_2
		jne	reallyShortRead
		cmp	{word}ds:[si].GFHO_signature[2], GFHO_SIG_3_4
		je	oldStyleVM
reallyShortRead:
endif
		mov	ax, ERROR_ATTR_NOT_FOUND; signal why...
		stc				;  and error
		jmp	done

	;--------------------
checkGeodeAttrs:
if DBCS_PCGEOS
	;
	; DBCS_PCGEOS can only open DBCS files.  Can only check if read
	; enough bytes.
	;
		cmp	cx, offset GFH_flags + size GFH_flags
		jb	doneOK
		.assert (offset GFH_flags + size GFH_flags) lt \
						(size GeosFileHeader)
		test	ds:[si].GFH_flags, mask GFHF_DBCS
		jz	fail			; not DBCS file
endif
	;
	; Hack to deal with getting extended attributes. If caller asked for
	; more than a header, we assume the word following the header is
	; a GeodeAttrs record, which should be set to 0 unless the file is
	; a PC/GEOS executable.
	; 
		cmp	cx, size GeosFileHeader
		jbe	doneOK
	;
	; If the file isn't executable, set the geode attributes to 0
	;
		cmp	ds:[si].GFH_type, GFT_EXECUTABLE
		je	done		; (carry cleared by == comparison)
		mov	{GeodeAttrs}ds:[si+size GeosFileHeader], 0
doneOK:
		clc
		jmp	done

if DBCS_PCGEOS
	; there was no DBCS version in 1.X
else
	;--------------------
oldStyleVM:
	;
	; Confirm the thing's a 1.X *VM* file -- anything else we treat as
	; a DOS file. Note that this code assumes we never are asked for
	; just GFH_signature, but always get GFH_longName as well. This
	; overlaps with GFHO_type, so we can always check that field.
	; 
	CheckHack <offset GFHO_type ge offset GFH_longName and \
		   offset GFHO_type + size GFHO_type lt \
		   offset GFH_longName + size GFH_longName>
EC <		cmp	cx, offset GFHO_type + size GFHO_type		>
EC <		ERROR_B	GASP_CHOKE_WHEEZE				>

		cmp	ds:[si].GFHO_type, GFTO_VM
		jne	fail
	;
	; Change the signature to the 2.0 format, just in case, then fetch
	; the longname into the proper part of the header. If we read enough
	; to actually have the longname in the buffer (albeit in the wrong
	; part of it), just copy it down. Else we'll have to read it in.
	;
	; es = ds
	; ds:si = buffer
	; cx = bytes of header asked for
	; 
		mov	{word}ds:[si].GFH_signature[2], GFH_SIG_3_4
		cmp 	cx, offset GFH_longName + size GFH_longName
		jb	doneOK
		
		push	di		; always need to biff this, so...

		cmp	cx, offset GFHO_longName + size GFHO_longName
		jb	readOldLongName
		
	    ;
	    ; Actually read the longname while we weren't looking. Copy it
	    ; from the old header location to the new.
	    ; 
		CheckHack <size GFH_longName eq size GFHO_longName>
		push	si, cx
		lea	di, ds:[si].GFH_longName
		add	si, offset GFHO_longName
		mov	cx, size GFHO_longName
		rep	movsb
		pop	si, cx

zeroRestOfHeader:
	;
	; Zero whatever else was read (set GFH_type in a moment)
	; cx = number of bytes of header actually read
	;
		push	cx
		lea	di, ds:[si].GFH_longName+size GFH_longName
		sub	cx, offset GFH_longName + size GFH_longName
		clr	al
		rep	stosb
		pop	cx
	;
	; Now set GFH_type to GFT_OLD_VM, if it was part of what was to be
	; returned.
	; 
		pop	di

		cmp	cx, offset GFH_type + size GFH_type
		jb	doneOK
		mov	ds:[si].GFH_type, GFT_OLD_VM
		jmp	doneOK

readOldLongName:
	;
	; Didn't read far enough to get the old longname, so we have to
	; seek there and read it ourselves. We quite purposely use a relative
	; seek here, not an absolute one, in case something relies on being
	; able to read a header from any point in a file (I don't remember
	; if you need this or not, Chris, but figured I'd be careful -- ardeb)
	; 
		push	cx
		mov	ax, offset GFHO_longName
		sub	ax, cx
		cwd			; sign-extend as necessary
		xchg	ax, dx		; dx <- low word, ax <- high word
		mov_tr	cx, ax		; cx <- high word
		mov	ax, MSDOS_POS_FILE shl 8 or FILE_POS_RELATIVE
		call	DOSUtilInt21

		lea	dx, ds:[si].GFH_longName
		mov	cx, size GFH_longName
		mov	ah, MSDOS_READ_FILE
		call	DOSUtilInt21
		pop	cx
		jmp	zeroRestOfHeader
endif
DOSVirtReadFileHeader endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtOpenGeosFileForHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the file or directory in the passed DTA and read
		all or part of its header in.

CALLED BY:	DOSEnumReadHeader, DOSVirtMapCheckGeosName
PASS:		ds:dx	= FileFindDTA
		es:si	= place to which to read the header
		cx	= # bytes of header to read
RETURN:		carry set if could not open file or if file not a
			a geos file.
			ax	= ERROR_ATTR_NOT_PRESENT (if not geos file)
				= error code (if couldn't be opened)
		carry clear if file open & valid:
			header read to ds:si
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtOpenGeosFileForHeader proc	far
		uses	bx, ds
		.enter
EC <		cmp	cx, offset GFH_signature + size GFH_signature	>
EC <		ERROR_B	MUST_READ_AT_LEAST_FILE_SIGNATURE_IN		>
if not _MS7
	;
	; If not named like a geos file, then we assume it ain't one.
	; 
		call	DOSVirtCheckPossibleGeosFile
		cmc
		mov	ax, ERROR_ATTR_NOT_FOUND
		jc	done
endif
	;
	; Allocate a JFT slot since we need to open it.
	; 
		mov	bx, NIL
		call	DOSAllocDosHandleFar
		mov	bx, dx
	;
	; If it's a directory, see if it's got a special file that would give
	; us extended attributes for the beast.
	; 
		mov	al, FA_READ_ONLY
if _MS7
		test	ds:[bx].W32FD_fileAttrs.low.low, mask FA_SUBDIR
else
		test	ds:[bx].FFD_attributes, mask FA_SUBDIR
endif
		jz	regularFile
		
		call	DOSVirtOpenSpecialDirectoryFile
		jmp	checkFileOpen
regularFile:

	;
	; Try and open the beast. 
	;
if _MS7
		lea	dx, ds:[bx].W32FD_fileName.MSD7GN_longName
else
		lea	dx, ds:[bx].FFD_name
endif
		call	DOSUtilOpenFar
checkFileOpen:
		jc	failFreeJFTSlot

MS7<		WARNING  MSDOS7_OPENING_FILE_FOR_HEADER>
		mov_tr	bx, ax
		call	DOSVirtReadFileHeader
		jc	closeFail
	;
	; Close the file again and signal our happiness.
	; 
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
		clc
freeJFTSlot:
	;
	; Release the JFT slot we allocated above.
	; 
		mov	bx, NIL
		call	DOSFreeDosHandleFar
if not _MS7
done:
endif
		.leave
		ret
closeFail:
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
		mov	ax, ERROR_ATTR_NOT_FOUND
failFreeJFTSlot:
		stc
		jmp	freeJFTSlot
DOSVirtOpenGeosFileForHeader endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtConvertGeosToDos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a geos name to a DOS name.

CALLED BY:	DOSVirtMapCheckGeosName, DOSVirtGenerateDosName
PASS:		ds:dx	= name to map
		cx	= # chars in name to map
		es:di	= place to store the result
RETURN:		es:di	= after last char in name (at most 8 chars away from
			  passed
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		Use the first eight characters of the geos name as the
		8 characters of the DOS name, mapping any character that's
		not legal in a DOS filename to be an underscore.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtConvertGeosToDos proc near
DBCS <		uses	si, bx, dx, bp					>
SBCS <		uses	si, bx, dx					>
		.enter
if DBCS_PCGEOS
	;
	; For DBCS, we know how many characters the name has in
	; Unicode, and how many bytes maximum (8) it can be in DOS,
	; but not how many it *will* be until we map the name.
	;
	; So we track both, and quit when we run out of characters
	; or bytes.
	;
		mov	si, dx				;ds:si <- name to map
		mov	dx, cx				;dx <- # of chars
		shl	cx, 1				;cx <- max # of bytes
endif
	;
	; Use as many bytes in the name as possible, but no more than
	; DOS_FILE_NAME_CORE_LENGTH, of course.
	; 
		cmp	cx, DOS_FILE_NAME_CORE_LENGTH
		jbe	startMap
		mov	cx, DOS_FILE_NAME_CORE_LENGTH
startMap:
if DBCS_PCGEOS
;--------------------
		call	DCSFindCurCodePage
mapLoop:
		call	DCSGeosToDosCharFileString
		dec	dx				;maximum # of chars?
		jz	doneMap				;branch if so
		loop	mapLoop
doneMap:
else
;--------------------
		mov	si, dx
		clr	dx
mapLoop:
		lodsb			; al <- next char
		call	DOSVirtCheckLegalDosFileChar	; al <- _ if illegal
		lahf
		and	dh, ah
		sahf
		jnc	storeChar
		call	DOSUtilGeosToDosChar
storeChar:
		stosb
		loop	mapLoop
		mov_tr	ax, dx
		sahf
;--------------------
endif
		.leave
		ret
DOSVirtConvertGeosToDos endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGenerateDosName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an unique name for the geos name pointed to by
		dosFinalComponent

CALLED BY:	DOSAllocOpCreate, DOSPathOpMakeDir
PASS:		dosFinalComponent pointing to the geos name
		dosFinalComponentLength holding # chars in final component,
			excluding the null
		CWD lock grabbed & DOS working dir set to place to create
			the file/dir
RETURN:		carry set if all extensions used or name is invalid
			ax	= ERROR_CANNOT_MAP_NAME
				= ERROR_INVALID_NAME
		carry clear if generation successful:
			dosNativeFFD.FFD_name contains name to use
			ds:dx	= dosNativeFFD.FFD_name

		MS7 - dos7LongName.MSD7GN_shortName filled in
		      with the new unique short name
		      ds:dx 	= dos7LongName

DESTROYED:	ax (if successful)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		It might be faster to do a find_first/find_next loop to
		find the highest-numbered extension and just add 1 to that.
		Rather than having to search the directory over and over
		again to find that a file with that extension already
		exists, then finally searching all the way through to find
		it doesn't, this would require but a single pass through the
		whole directory...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGenerateDosName proc	far
MS7<		findData	local	hptr	>

		uses	es, di, si, bx, cx
		.enter
		call	PathOps_LoadVarSegDS
		segmov	es, ds
if _MS7
		mov	di, offset dos7LongName.MSD7GN_shortName
		clr	ss:[findData]
else
		mov	di, offset dosNativeFFD.FFD_name
endif
		mov	cx, ds:[dosFinalComponentLength]
	;
	; Make sure the name is not too long
	;
		cmp	cx, FILE_LONGNAME_LENGTH
		LONG 	ja	invalidNoPop
		lds	dx, ds:[dosFinalComponent]
	;
	; Make sure the name is a valid long name. Longnames are allowed
	; to contain any character other than:
	; 	backslash
	; 	asterisk
	; 	question mark
	; 	colon
	; 
		push	cx
		mov	si, dx
validateLoop:
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, '\\'
		je	invalid
		LocalCmpChar	ax, ':'
		je	invalid
		LocalCmpChar	ax, '*'
		je	invalid
		LocalCmpChar	ax, '?'
		je	invalid
		loop	validateLoop
		pop	cx
	;
	; Convert the first 8 chars to DOS appropriately.
	; 
		call	DOSVirtConvertGeosToDos
	;
	; Record the start of the extension so we can easily go to the next
	; one.
	; 
	; NOTE: at this point the string we are working with is in the DOS
	; character set, and hence the single-byte character references
	; below are OK.
	;
		lea	si, [di+1]
	;
	; Initialize the extension to .000
	; 
		mov	ax, '.' or ('0' shl 8)
		stosw
		mov	al, '0'
		stosw
		clr	al
		stosb
		segmov	ds, es
if _MS7
		mov	di, offset dos7FindData			;es:di <-findD
		mov	dx, offset dos7LongName			
		mov	cx, MSDOS7_FIND_FIRST_ATTRS
		mov	si, DOS7_DATE_TIME_MS_DOS_FORMAT
		mov	ax, MSDOS7F_FIND_FIRST
		call	DOSUtilInt21
		jc	done

PrintMessage<Should do strcmp on results here?>
		
		mov	ss:[findData], ax
		jmp	tryAgain

else
		mov	dx, offset dosNativeFFD.FFD_name
endif		
nameLoop:
		mov	ax, MSDOS_GET_SET_ATTRIBUTES shl 8 or 0	; get attrs
		call	DOSUtilInt21
		jc	done
MS7<tryAgain:							>
		mov	bx, ds:[si]
		mov	al, ds:[si][2]
		inc	al
		cmp	al, '9'
		jbe	storeNew
		mov	al, '0'
		inc	bh
		cmp	bh, '9'
		jbe	storeNew
		mov	bh, '0'
		inc	bl
		cmp	bl, '9'
		jbe	storeNew
		mov	ax, ERROR_CANNOT_MAP_NAME
		jmp	done
storeNew:
		mov	ds:[si], bx
		mov	ds:[si][2], al
		jmp	nameLoop
done:
	;
	; Carry is set if found a name (the get attrs call failed) or clear
	; if didn't (the most-significant digit is above '9' => carry clear),
	; but we need it the other way 'round.
	; 
		cmc		
		.leave
		ret
invalid:
		pop	cx
invalidNoPop:
		mov	ax, ERROR_INVALID_NAME
		jmp	done		; (carry cleared by == comparison,
					;  above, so cmc will set carry)

DOSVirtGenerateDosName endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtMapCheckComponentIsValidDosName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the given component is a valid DOS name, mapping it
		to the DOS character set, upcasing it, and copying it to
		the passed buffer.

CALLED BY:	DOSVirtMapCheckDosName, DOSVirtMapPathWithDosAFAP
PASS:		ds:si	= start of component (GEOS)
		ds:dx	= first char after component (GEOS)
		es:di	= place to which to copy the mapped path (DOS)
RETURN:		carry set if not valid DOS name:
			es:di	= same as passed in, but {char}es:[di] set
				  to 0
		carry clear if valid DOS name:
			es:di	= after last char stored
DESTROYED:	cx, ax, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtMapCheckComponentIsValidDosName proc	near
startAddr	local	word	push di
dotFlag		local	byte

SBCS <		uses	si						>
DBCS <		uses	si, bx						>
		.enter
		mov	ss:[dotFlag], -1; dot not seen yet

if _MS7
	;
	; We can do 32 character DOS names in ms7.
	; 
		mov	cx, FILE_LONGNAME_LENGTH
else
		mov	cx, DOS_FILE_NAME_CORE_LENGTH
endif
	
DBCS <		push	bp						>
DBCS <		call	DCSFindCurCodePage				>
DBCS <		mov	bx, bp						>
DBCS <		pop	bp						>
	;
	; If component is empty, assume we were given something ending with
	; a backslash (or just the root...) and pretend the thing is actually
	; "."
	; 
		LocalCmpChar ds:[si], C_NULL
		jne	notNull
		mov	al, '.'
		jmp	seenDot
notNull:

	;
	; If the component is the ".." directory, then copy it
	;
if DBCS_PCGEOS
		mov	ax, '.'
		cmp	ds:[si], ax
		jne	copyLoop
		cmp	ds:[si][2], ax
		jne	copyLoop
		stosb
		stosb
		add	si, 2*(size wchar)
else
		mov	ax, '..'
		cmp	ds:[si], ax
		jne	copyLoop
		stosw
		add	si, 2
endif
		cmp	si, dx
		je	done

copyLoop:

DBCS <		mov	ax, ds:[si]	; ax <- next component char	>
SBCS <		lodsb			; al <- next component char	>
SBCS <		cmp	al, DOS_UMDOS_LEAD_CHAR		; special funkiness? >
SBCS <		je	mapUnmappable					>
	;
	; Period is special-cased and only accepted if not seen before. It
	; also changes the number of chars left in the loop...
	;
		LocalCmpChar ax, '.'
		je	seenDot
	;
	; See if the thing is allowed to appear in a DOS filename. If not, this
	; can't be a DOS name mapped to GEOS.
	; 
SBCS <		call	DOSVirtCheckLegalDosFileChar			>
SBCS <		jnc	notDosName	; => not legal in DOS filename, so...>
	;
	; Else, convert the thing from GEOS to DOS. If it's not mappable, that
	; also indicates the name can't have been mapped from DOS.
	;
DBCS <		call	DCSGeosToDosCharFileStringCurBX			>
SBCS <		call	DOSUtilGeosToDosChar				>
		jc	notDosName	; if default char needed, then couldn't
					;  have come from DOS
storeDosChar:
	;
	; Store the mapped character into the buffer we're building. Stop
	; if we've reached the end of the component or the end of the buffer.
	; 
SBCS <		stosb							>
		cmp	si, dx
		loopne	copyLoop
		jne	checkExtension
		; (carry cleared by == comparison)
done:
		.leave
		ret

SBCS <popNotDosName:							>
SBCS <		pop	ax		; discard return address from	>
					;  convertHexDigit
notDosName:
		mov	di, ss:[startAddr]
		mov	{char}es:[di], 0	; flag not DOS
						;  for callers of our
						;  caller
		stc			; flag not DOS
		jmp	done		; and boogie

seenDot:
		inc	ss:[dotFlag]
		jnz	notDosName	; => more than one dot, so not DOS name
		mov	cx, DOS_FILE_NAME_EXT_LENGTH+1	; 1 extra for the dot
							;  itself...
DBCS <		inc	si						>
DBCS <		inc	si						>
DBCS <		stosb				;store the dot		>
		jmp	storeDosChar

if DBCS_PCGEOS
	; DOS_UMDOS_LEAD_CHAR not needed in DBCS
else
mapUnmappable:
		cmp	si, dx
		je	notDosName	; => improper format, so bad

		lodsb			; al <- 16s digit
		call	convertHexDigit
		cmp	si, dx
		je	notDosName	; => improper format, so bad

		mov	ah, al
		lodsb			; al <- 1s digit
		call	convertHexDigit
		shl	ah
		shl	ah
		shl	ah
		shl	ah
		or	al, ah
		jmp	storeDosChar
endif

checkExtension:
		LocalCmpChar ds:[si], '.'	; at dot separating core from
						;  extension?
		jne	notDosName		; no => name too long to be
						;  DOS name
		tst	ss:[dotFlag]		; dot seen yet?
		jns	notDosName		; yes => name not DOS as can't
						;  have more than one
		jmp	copyLoop		; no => go fetch the dot and
						;  process it; seenDot will
						;  set cx properly so we pick
						;  up the rest of the chars.

if DBCS_PCGEOS
	; DOS_UMDOS_LEAD_CHAR not needed in DBCS
else
	;--------------------
	; internal routine to convert an ascii hex digit to a number, dealing
	; with the digit being invalid by doing a "longjmp" to notDosName
	; al = ascii digit
convertHexDigit:
		cmp	al, '9'
		jbe	asciiToBin
		sub	al, 'A'-('0'+10)
asciiToBin:
		sub	al, '0'
		cmp	al, 16		; out of bounds?
		jae	popNotDosName	; yes => improper format, so bad
		retn
endif
DOSVirtMapCheckComponentIsValidDosName endp



if not _MS7

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtMapCheckDosName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed component might be a mapped DOS name in
		the geos character set.

CALLED BY:	DOSVirtMapComponent
PASS:		ds:dx	= start of component to check
		si	= end of component + 2
		cx	= DOSVirtComponentType
RETURN:		carry clear if file/dir of given name found:
			dosNativeFFD.FFD_name set to DOS version of the name
			if cx == DVCT_INTERNAL_DIR, current dir is the one
			    that was found
		carry set if file/dir of given name not found:
			dosNativeFFD.FFD_name[0] set to 0 if component not a
			    legal
			    DOS filename.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtMapCheckDosName proc	near
compType	local	DOSVirtComponentType push cx
		uses	ds, si, cx, dx, bx, di, es, ax
		.enter
		assume	ds:nothing
	;
	; Copy characters into dosNativeFFD.FFD_name, on the assumption that it
	; is a DOS name mapped into the pc/geos character set. We must
	; deal, of course, with the amusing mapping of non-pcgeos characters
	; that was performed in DOSEnum, where such things get converted to
	; a question mark (an illegal DOS and GEOS filename character) followed
	; by two hex digits.
	;
		xchg	si, dx		; ds:si <- compoment
		LocalPrevChar dsdx	; dx <- end of component (null or b/s)

		segmov	es, <segment dosNativeFFD>, di
		mov	di, offset dosNativeFFD.FFD_name
		assume	es:dgroup
			.assert segment dosNativeFFD eq udata

		call	DOSVirtMapCheckComponentIsValidDosName
		jc	done
		
		segmov	ds, es
		assume	ds:dgroup
	;
	; Null-terminate the buffer.
	; 
		clr	al
		stosb

	;
	; If the name is ".", then assume it exists
	;

		cmp	{word} ds:[dosNativeFFD.FFD_name], '.'
		je	done

		cmp	ss:[compType], DVCT_INTERNAL_DIR
		je	tryChangeDir

	;
	; Special case: Also check for ".." as a final compoment,
	; since NetWare won't find this using FIND_FIRST, and it won't
	; return its attributes using MSDOS_GET_ATTRIBUTES
	;
		call	DOSVirtCheckParentDir
		jne	notParent

		call	DOSGetTimeStamp
		mov	ds:[dosNativeFFD].FFD_modTime, cx
		mov	ds:[dosNativeFFD].FFD_modDate, dx
		mov	ds:[dosNativeFFD].FFD_attributes, mask FA_SUBDIR
		clc
		jmp	done

notParent:

	;
	; dosNativeFFD.FFD_name now contains the potential DOS name.
	; The file might either be a FILE or a DEVICE.  
	;
	; See if it's a file by doing a FIND_FIRST with the name as a
	; pattern, allowing us to have a full report on the file when
	; getting extended attributes for a path.
	;

		call	SysLockBIOS
		lea	dx, ds:[mapDTA]
		mov	ah, MSDOS_SET_DTA
		call	DOSUtilInt21

		mov	dx, offset dosNativeFFD.FFD_name
		mov	cx, mask FA_SUBDIR or mask FA_HIDDEN or mask FA_SYSTEM
		mov	ah, MSDOS_FIND_FIRST
		call	DOSUtilInt21
		call	SysUnlockBIOS
		jnc	foundIt

	;
	; It's not a file -- see if it's a device (if cx = DVCT_FILE_OR_DIR)
	;
		cmp	ss:[compType], DVCT_FILE_OR_DIR
		stc
		jne	done
		call	DOSVirtMapCheckDevice
		jc	done

foundIt:
	;
	; Found it, so copy the DTA into dosNativeFFD.
	; 
		lea	si, ds:[mapDTA]
		mov	di, offset dosNativeFFD
		mov	cx, size dosNativeFFD
		rep	movsb
	;
	; 9/11/92: cope with Novell sometimes returning high bit of attributes
	; (aka FA_GEOS_FILE) set for some files (something to do with file
	; being sharable or somesuch nonsense) -- ardeb
	;
		andnf	ds:[dosNativeFFD].FFD_attributes, not FA_GEOS_FILE
		mov	ds:[dosFileType], GFT_NOT_GEOS_FILE
	;
	; XXX: might want to confirm that the proper type of file was found
	; here, except one assumes that our caller will find out soon enough
	; whether it's the right type of file when it goes to actually access
	; it in the appropriate manner (e.g. DOSVirtMapComponent will attempt
	; to cd into it if it's not the last component, and will get and return
	; the appropriate error if the thing found is actually a file.)
	; 
done:
		.leave
		ret
tryChangeDir:
	;
	; Since the component we're mapping is an internal directory, we should
	; be able to just try and change to the thing, which is what our caller
	; needs us to do anyway. Regardless of whether the change succeeds or
	; fails, we can just jump up to done w/o copying anything into
	; dosNativeFFD since no one will use it...
	; 
		mov	dx, offset dosNativeFFD.FFD_name
		call	DOSInternalSetDir
		jmp	done
DOSVirtMapCheckDosName endp
endif		




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtCheckParentDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if dosNativeFFD.FFD_name is the name of the parent
		directory (..)

CALLED BY:	DOSVirtMapCheckDosName, DOSPathOp

PASS:		es - dgroup

RETURN:		Z flag set if this is the parent dir

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtCheckParentDir	proc near
		.enter
if _MS7
		cmp	{word} es:[dos7FindData].W32FD_fileName.\
				MSD7GN_longName, '..'
else
		cmp	{word} es:[dosNativeFFD].FFD_name, '..'
endif
		jne	done
if _MS7
		cmp	{word} es:[dos7FindData].W32FD_fileName.\
					MSD7GN_longName, 0
else
		cmp	es:[dosNativeFFD].FFD_name[2], 0
endif
done:
		.leave
		ret
DOSVirtCheckParentDir	endp




if not _MS7

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtMapCheckDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed thing is a device

CALLED BY:	DOSVirtMapCheckDosName

PASS:		ds:dx - filename (DOS)
		(ds - dgroup)

RETURN:		If found:
			carry clear
			mapDTA setup
		Else:
			carry set
			ax = ERROR_FILE_NOT_FOUND

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtMapCheckDevice	proc near
		uses	es, bx, di, si, cx

		.enter
	;
	; Save DS in a place we can get to it should the device be found.
	; 
		push	ds
	;
	; Space-pad the filename.  We should be able to reject the
	; file in most cases here... (XXX: Assume that device names
	; can't contain a period)
	;
		mov	cx, DEVICE_NAME_SIZE
		sub	sp, cx
		mov	di, sp		; es:di - buffer
		segmov	es, ss

		mov	si, dx		; ds:si - passed filename

startLoop:
		lodsb
		tst	al
		jz	spacePad
		cmp	al, '.'
		je	notFound
		stosb
		loop	startLoop
		
	;
	; We've copied 8 characters and still not come to the end.
	; Make sure the next character is NULL, otherwise bail.
	;
		tst	<{byte} ds:[si]>
		jnz	notFound
		jmp	getNullDevice
spacePad:
		mov	al, ' '
		rep	stosb

	;
	; Load the pointer to the NULL device header
	;
getNullDevice:

		call	PathOps_LoadVarSegDS
		les	di, ds:[dosNullDevice]
		segmov	ds, ss

checkDeviceLoop:
	;
	; Check for a null pointer (both 0000:0000 and xxxx:FFFF)
	;
		mov	ax, es

		or	ax, di
		jz	notFound	; => both 0
		cmp	di, 0xFFFF
		je	notFound
		add	di, offset DH_name

		mov	si, sp		; ds:si <- space-padded form
		mov	cx, DEVICE_NAME_SIZE/2
		push	di
		repe	cmpsw
		pop	di
		je	found

	;
	; DI is pointing at the name, and we want to 
	; access the next pointer, so:
	;
		les	di, es:[di][offset DH_next - offset DH_name]
		jmp	checkDeviceLoop
notFound:
		stc
done:
		mov	di, sp
		lea	sp, ss:[di+DEVICE_NAME_SIZE]
		pop	ds
		.leave
		ret

found:				; MUCH less common case.
	;
	; Initialize mapDTA with standard it-exists-trust-us info
	; 
		call	PathOps_LoadVarSegDS
		clr	ax
		mov	ds:[mapDTA].FFD_attributes, al
		mov	ds:[mapDTA].FFD_dirLBN, ax
		mov	ds:[mapDTA].FFD_modTime, ax
		mov	ds:[mapDTA].FFD_modDate, ax
		mov	ds:[mapDTA].FFD_fileSize.low, ax
		mov	ds:[mapDTA].FFD_fileSize.high, ax
		dec	ax
		mov	ds:[mapDTA].FFD_dirIndex, ax
	;
	; Copy the device name into mapDTA, without the space-padding.
	; 
		segmov	es, ds
		mov	si, sp
		mov	ds, ss:[si+DEVICE_NAME_SIZE]
		mov	si, dx
		mov	di, offset mapDTA.FFD_name
copyDevNameLoop:
		lodsb
		stosb
		tst_clc	al
		jnz	copyDevNameLoop
		jmp	done
DOSVirtMapCheckDevice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtMapCheckGeosName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to map a pc/geos "longname" to its DOS counterpart.
		If successful, the result is left in dosNativeFFD.FFD_name.

CALLED BY:	DOSVirtMapComponent
PASS:		ds:dx	= start of component to map
		ds:si	= 2 past end of component (start of next)
		cx	= DOSVirtComponentType
RETURN:		carry set if component not found, or if link
			ax - error code
			if ax = ERROR_LINK_ENCOUNTERED, 
				bx = handle of link data

		carry clear if component found
			dosNativeFFD.FFD_name	= file name
			(DOS character set, of course)
DESTROYED:	

PSEUDO CODE/STRATEGY:

	To find a GEOS file, we go in three passes:

	1) Enumerate through all files in the directory, and open
	   likely candidates.  A file is considered likely if it ends in
	   any of these suffixes:
			.GEO
			.VM
			.DB
			.STA
			.BIT
			.[0-9][0-9][0-9]
	   An additional constraint is placed on opening files with an
	   all-numeric extension: they must match the "shouldMatch"
	   string during the first pass.

	2) Open the DIRNAME.000 file and see if there's a link
	   that matches the passed filename.

	3) Enumerate again over the files, this time opening EVERY
	   file that has a numeric extension to find the given long name.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DOSVirtMapCheckGeosName		proc near
SBCS <componentStart	local	fptr.char	push ds, dx		>
DBCS <componentStart	local	fptr.wchar	push ds, dx		>
componentType	local	DOSVirtComponentType push cx
nextComponent	local	nptr	push	si
passedBX	local	word	push	bx
componentLength	local	word
	ForceRef	nextComponent	; used in DOSLinkCheckLink

		uses	cx, es, di, ds, si, dx
		.enter
EC <		call	ECCheckStack					>

		sub	si, dx		; si <- length w/terminator
DBCS <		shr	si, 1		; si <- length w/terminator	>
		dec	si		;  except we don't want it :)
		mov	ss:[componentLength], si
		tst	si
EC <		ERROR_Z	CANNOT_MAP_ZERO_LENGTH_GEOS_NAME		>
NEC <		jnz	createShouldMatch				>
NEC <		mov	ax, ERROR_INVALID_NAME				>
NEC <		stc							>
NEC <		jmp	done						>
NEC <createShouldMatch:							>

	;
	; Convert the component to a DOS name with which we can compare the
	; files we find via find_first/find_next
	; 
		mov	cx, si
		segmov	es, dgroup, di
		assume	es:dgroup
		mov	di, offset mapShouldMatch
		call	DOSVirtConvertGeosToDos
		segmov	ds, es
		clr	al		; null-terminate
		stosb
startPass:
		mov	ah, MSDOS_FIND_FIRST
		jmp	doFind
searchLoop:
		mov	ah, MSDOS_FIND_NEXT
doFind:
		assume	ds:dgroup
	;
	; Snag BIOS lock so we can set the DTA w/o worry, then do that.
	; 
		call	SysLockBIOS
		push	ax			; save DOS call to use
		lea	dx, ds:[mapDTA]
		mov	ah, MSDOS_SET_DTA
		call	DOSUtilInt21
		pop	ax
	;
	; Enumerate *all* files, including hidden and system ones; who knows
	; what the caller might be trying to access...
	; 
		lea	dx, ds:[mapSearchPattern]
		mov	cx, mask FA_HIDDEN or mask FA_SYSTEM or mask FA_SUBDIR
		call	DOSUtilInt21
		call	SysUnlockBIOS
		jc	passComplete
	;
	; If entry is bogus (q.v. DOSEnum) or '.' or '..', then skip it as
	; it can't possibly be what we're interested in.
	; 
		mov	al, ds:[mapDTA].FFD_name[0]
		cmp	al, '.'
		je	searchLoop
		tst	al
		jz	searchLoop
	;
	; See if the file ends in a numeric extension. If it does, and we're
	; on the first pass, we want to make sure its core part matches
	; shouldMatch. If it doesn't and we're on the second pass, we can
	; skip this file, as we checked it during the first pass.
	; 
		lea	di, ds:[mapDTA].FFD_name
		mov	cx, size FFD_name
		mov	al, '.'
		repne	scasb
		mov	al, 0
		jne	checkPass
		call	DOSVirtCheckNumericExtension
		mov	al, 0 			; must be pass 2 to skip
						;  this file if non-numeric
						;  extension (as file was
						;  checked on 1st pass), so
						;  set al to 0
		jnc	checkPass

		lea	si, ds:[mapDTA].FFD_name
		sbb	di, si			; carry already set, so this
						;  subtracts an extra 1 so we
						;  don't compare the dot
		mov	cx, di			; cx <- # chars to compare
		lea	di, es:[mapShouldMatch]
		repe	cmpsb
		jne	numericNoMatch		; => mismatch or 2d pass
		scasb				; match all the way to the
						;  end of shouldMatch (al still
						;  0 from right after
						;  DOSVirtCheckNumericExtension)?
		jne	searchLoop		; no => must be 1st pass (as
						;  no geos filename will have
						;  null characters in
						;  its core), so don't bother
		jmp	checkHeader


numericNoMatch:
		cmp	ds:[mapShouldMatch][0], al; first char 0? (i.e. 2d pass?)
		jne	searchLoopJMP		; no => ignore it
	;
	; Don't bother to open the thing if it's our special directory file.
	; 
		cmp	ds:[mapDTA].FFD_name[0], '@'
		jne	checkHeader
		
		lea	si, ds:[mapDTA].FFD_name
		mov	di, offset dirNameFile
		mov	cx, size dirNameFile
		repe	cmpsb
		jne	checkHeader
searchLoopJMP:
		jmp	searchLoop

passComplete:
	;
	; Made it through all the files in the directory, possibly for a second
	; time. Set first byte of shouldMatch to 0 if it wasn't zero
	; before.  Before going on to the slow 3rd pass, in which
	; we check every file with a non-numeric extension, see if the
	; file might be a link.
	; 
		clr	al
		xchg	ds:[mapShouldMatch][0], al
		tst	al
		stc
		jnz	checkLink
toDone:
		jmp	done

checkLink::

		call	DOSLinkCheckLink

if _REDMS4
	;
	; We won't do the full exhaustive third pass in Redwood -- it's too
	; slow.  5/ 6/94 cbh
	;
		jc	toDone			;link found, done
		clr	ax			;else return no error
		stc				;but also path not found.
		jmp	short toDone
else
		jc	toDone
		jmp	startPass
endif

	;--------------------
checkPass:
		cmp	ds:[mapShouldMatch][0], al
		je	searchLoopJMP		; => we checked on previous pass

checkHeader:
	;
	; So far so good. Read in the header of the file in the DTA.
	; 
		lea	dx, ds:[mapDTA]		; ds:dx <- DTA
		lea	si, es:[mapHeaderBuf]	; es:si <- header buffer
		mov	cx, size mapHeaderBuf
		call	DOSVirtOpenGeosFileForHeader
		jc	searchLoopJMP		; => not a geos file or
						;  couldn't open it. Either
						;  way, we're hosed.
	;
	; See if the longnames match.
	; 
		lea	di, es:[mapHeaderBuf].DVMCGNH_partial.GPH_longName
		lds	si, ss:[componentStart]
		assume	ds:nothing
		mov	cx, ss:[componentLength]
SBCS <		repe	cmpsb						>
DBCS <		repe	cmpsw						>
		segmov	ds, es
		assume	ds:dgroup
		jne	searchLoopJMP
	;
	; Names match, but make sure we're at the end of the file's longname
	; before we declare success.
	; 
SBCS <		cmp	{char}ds:[di], 0				>
DBCS <		cmp	{wchar}ds:[di], 0				>
		jne	searchLoopJMP

	;
	; Screen out the special @DIRNAME.000 file: the file may not be of
	; type GFT_DIRECTORY unless FA_SUBDIR is set for the thing in the
	; DTA (i.e. if we opened @DIRNAME.000 any way other than by
	; recognizing the current file is a directory, we ignore it).
	; 
		test	ds:[mapDTA].FFD_attributes, mask FA_SUBDIR
		jnz	success		; => no need to check type, as
					;  GFT_DIRECTORY is allowed
		cmp	ds:[mapHeaderBuf].DVMCGNH_type, GFT_DIRECTORY
		je	searchLoopJMP
	;
	; Success! Copy the DTA into dosNativeFFD after setting FA_GEOS_FILE,
	; should anyone care.
	; 
success::
		ornf	ds:[mapDTA].FFD_attributes, FA_GEOS_FILE
		cmp	ss:[componentType], DVCT_INTERNAL_DIR
		je	changeToFoundDir

		mov	di, offset dosNativeFFD
		mov	cx, size dosNativeFFD
		lea	si, ds:[mapDTA]	; ds:si <- source
		rep	movsb

		mov	ax, ds:[mapHeaderBuf].DVMCGNH_type
		mov	ds:[dosFileType], ax
		clc

done:

	;
	; Either restore the passed BX, or return the handle of the
	; link data, if any.
	;

		mov	bx, ss:[passedBX]
		.leave
		ret

changeToFoundDir:
	;
	; Change to the directory we assume we found, since we're mapping
	; an internal component of the path and that's what we'd otherwise
	; do...
	; 
		lea	dx, ss:[mapDTA].FFD_name
		call	DOSInternalSetDir
		jmp	done
DOSVirtMapCheckGeosName endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtMapComponent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a single component from its virtual name to its DOS
		equivalent.

CALLED BY:	DOSVirtMapPath
PASS:		ds:dx	= start of component to map
		ds:si	= 1 past terminator of component to map (i.e.
			  2 past the end of the component)
		cx	= non-zero if component should be a directory.
		CWD lock grabbed and DOS CWD set to the one that should
			contain the component.
RETURN:		carry set on error:
			ax	= error code
		carry clear if mapped:
			dosNativeFFD.FFD_name set
			ax	= preserved
		MS7 :
			dos7FindData.W32FD_fileName  set to the whole 256
			char kabob

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		There are a number of things to consider here:
			- the component may be a 32-character name taken
			  straight from the header of a file/directory
			- the component may be an 8.3 DOS name that had
			  some characters changed to _ because they couldn't
			  be mapped to the geos character set
			- the component may be an honest-to-god 8.3 name
		We need to generate a pattern we can use in a find_first/
		    find_next loop to locate the file as quickly as
		    possible.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtMapComponent	proc	near
		uses	es
		.enter
		push	ax			; assume there will be no error
						;  and that we'll have
						;  to return this...
		segmov	es, dgroup, ax
	;
	; Record the start & length of the final path component mapped, for use
	; by others who might be interested.
	; 
		mov	es:[dosFinalComponent].segment, ds
		mov	es:[dosFinalComponent].offset, dx
SBCS <		lea	ax, ds:[si-1]					>
DBCS <		lea	ax, ds:[si-2]					>
		sub	ax, dx
DBCS <		shr	ax, 1			; ax <- length		>
		mov	es:[dosFinalComponentLength], ax

if _MS7	
		call	DOS7MapComponent
else
	;
	; First try the thing as a DOS name, taking care of the funky
	; mapping between the DOS character set and the GEOS character set.
	; 
		call	DOSVirtMapCheckDosName
		jnc	done

	;
	; 9/29/92 - Removed optimization based on the assumption that
	; if the thing had a valid DOS name, and it was an internal
	; directory, that we didn't have to check the GEOS namespace
	; Links can have valid DOS names, but still must
	; be searched for specially. -chrisb
	;


	;
	; Not a DOS name, so go whole hog and enum things to locate the file
	; with the right header.
	; 
		call	DOSVirtMapCheckGeosName
		jnc	done
		cmp	ax, ERROR_LINK_ENCOUNTERED
		je	linkEncountered
done:
		pop	ax			; assume no error, so must
						;  return the passed AX
endif
		jnc	exit
	;
	; Return the proper error code, based on the passed value of CX.
	; 
		mov	ax, ERROR_FILE_NOT_FOUND	; assume s/b file
		jcxz	exit
		mov	ax, ERROR_PATH_NOT_FOUND	; s/b dir, so return
exit:
		.leave
		ret
if not _MS7
linkEncountered:
		add	sp, 2
		stc
		jmp	exit
endif
DOSVirtMapComponent	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtMapPathWithDosAFAP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map the leading components of the path with DOS As Far As
		Possible so we can use just one DOSInternalSetDir for
		as much of the thing as is legal, avoiding the overhead of
		the component-by-component approach.

CALLED BY:	DOSVirtMapPath
PASS:		ds:dx	= path to map
		cx	= DOSVirtComponentType (DVCT_FILE_OR_DIR or
			  DVCT_DIR)

RETURN:		carry set on error (leading components were valid DOS but
		    didn't exist)
			ax	= FileErrors

		carry clear if ok:
			ds:si	= remaining things to map the hard way

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		look down the string while the components
		are valid DOS names until we find one that isn't or
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtMapPathWithDosAFAP proc	near
		uses	cx, bx, es, di, dx
		.enter
		segmov	es, dgroup, di
		mov	di, offset dosPathBuffer
		mov	si, dx
		mov	bx, si			; bx <- start of whole thing
		LocalCmpChar ds:[si], '\\'	; absolute?
		je	storeComponentEnd
componentLoop:
		LocalGetChar	ax, dssi
		LocalIsNull	ax
		jz	hitEndOfTheRoad
		LocalCmpChar	ax, '\\'
		jne	componentLoop
	;
	; Hit the end of the component. Call common code to see if the thing's
	; a valid DOS name.
	; 
		LocalPrevChar	dssi	; back up to the backslash itself
		cmp	dx, si
		je	invalidName	; empty component is error, else we
					;  mess up Novell when we give it this
					;  bogus path -- ardeb 4/19/93

	;
	; See if we have enough room in the buffer to add this
	; component and a NULL
	;
SBCS <		mov	ax, si		; ax - end of component		>
SBCS <		sub	ax, dx		; ax - # bytes in component	>

	;
	; DBCS -- since GEOS-to-DOS mapping produces an unpredictable
	; number of characters, just assume the worst case.
	;

DBCS <		mov	ax, DOS_DOT_FILE_NAME_LENGTH			>

		add	ax, di		; ax - buffer pointer after copy
		cmp	ax, offset dosPathBuffer + size dosPathBuffer -1
 
		jae	checkLeadingComponents
		
		xchg	dx, si		; ds:si <- start, ds:dx <- end
if _MS7
		push	es, di, cx
		mov	cx, dx
		sub	cx, si
		segmov	es, ds
		mov	di, si
		call	DOS7BadCharReplace
		pop	es, di, cx
endif
		call	DOSVirtMapCheckComponentIsValidDosName
		jc	notDOS		; not DOS, so work with what
					;  we've got in dosPathBuffer
		mov	si, dx		; ds:si <- end of valid component
storeComponentEnd:
		mov	al, '\\'
		stosb
		LocalNextChar	dssi	; skip over backslash
		mov	dx, si		; ds:dx <- start of next component
		jmp	componentLoop
		
notDOS:
		mov	dx, si		; ds:dx <- start of first non-mapped
					;  component
		jmp	checkLeadingComponents

invalidName:
		mov	ax, ERROR_PATH_NOT_FOUND
		stc
		jmp	done

hitEndOfTheRoad:
	;
	; Deal specially with getting just the root path or an empty path.
	; 
DBCS <		cmp	di, offset dosPathBuffer+2			>
SBCS <		cmp	di, offset dosPathBuffer+1			>
		ja	checkLeadingComponents	; more than 1 char => can't be
						;  root or null.
	;
	; 10/7/93: this used to compare si-1 against dx and think it was the
	; root if they were equal. However, that meant that \foo\ would be
	; taken to be the root, rather than the error it likely is, so we
	; now compare si-2 against the start of the whole thing (bx) as that
	; also allows us to detect a null path and do as we would do for the
	; root, namely manufacture a fake thing for '.' -- ardeb
	;
		LocalPrevChar dssi
		LocalPrevChar dssi
		cmp	si, bx
		ja	checkLeadingComponents	; => something after the b.s.,
						;  so not just root
	;
	; If path is just root, we must handle it specially, as stupid MS DOS
	; says "." doesn't exist when you search for it in the root.
	; 
		call	DOSVirtMapRootName

checkLeadingComponents:
	;
	; Hit the end of the string, so dx contains the start of the last
	; component that our caller will have to map.
	; 
		mov	si, dx
		cmp	di, offset dosPathBuffer
		je	done		; => no leading components to change
					;  into, so it's ok

		push	ds
		segmov	ds, es
DBCS <		cmp	di, offset dosPathBuffer+2	; root?		>
SBCS <		cmp	di, offset dosPathBuffer+1	; root?		>
		je	setCWD
		dec	di			; back up so we overwrite final
						;  backslash
setCWD:
		mov	{char}ds:[di], 0	; null-terminate the leading
						;  components
		mov	dx, offset dosPathBuffer
		call	DOSInternalSetDir	; carry set if components
						;  bad.
		pop	ds
done:
		.leave
		ret
DOSVirtMapPathWithDosAFAP endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtMapPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a pathname to its native name, leaving the DOS
		current directory set to the directory containing the name,
		or the name itself, if it's a directory.

CALLED BY:	INTERNAL
PASS:		ds:dx	= path to map
		cx	= non-zero if path is expected to be a directory
			= zero if path is expected to be a file
		CWD lock held and thread's current directory set in DOS
RETURN:		carry set if error:
			ax	= ERROR_PATH_NOT_FOUND, if internal component
				  not found or final component not found and
				  cx passed non-zero
				= ERROR_FILE_NOT_FOUND if final component 
				  not found
				= ERROR_LINK_ENCOUNTERED if there's a
				  link somewhere along the path

		carry clear if successful:
			ax	= preserved
			dosNativeFFD.FFD_name contains final component in the
			    native namespace
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		for each component of the path:
		    DOSVirtMapComponent(component, final ? cx : TRUE);
		    if map not successful:
		    	return (CF=1,AX=ERROR_PATH_NOT_FOUND)
		    else if (!final):
			cd dosNativeFFD.FFD_name
		    else:
			return carry clear

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtMapPath	proc	near
		uses	si, dx
		.enter
		push	ax		; save passed ax

	;
	; Added back in 10/17/92 by EDS so that PC/GEOS will run
	; from a directory on a drive where the user does not have
	; scan permission at the top level of that drive.
	; (Such as F:\LOGIN\GEOWORKS on a Novell server.)
	;
		call	DOSVirtMapPathWithDosAFAP	; ds:si <- stuff left
							;	to map
		jc	mapFullPathByComponent		; skip if error...

almostMapped::
	;
	; No error was returned. If we've mapped all the way through the
	; path, then we're done. Otherwise, fall through to map
	; remaining component one at a time.
	; ds:si = remaining component, or null at end of path.
	;
	; (DO NOT use "tst", because we are not guaranteed that it sets cy=0.)

SBCS <		cmp	{char}ds:[si], 0		; mapped all the way >
DBCS <		cmp	{wchar}ds:[si], 0		; mapped all the way >
							;  through?
		jz	doneFileDirFlagPopped		; yes => done (cy=0)

		jmp	gotStart			; skip to finish...

mapFullPathByComponent:
	;
	; Some internal component was missing, so let's start over,
	; and do it the hard way.
	;

		mov	si, dx

	;
	; If we have an absolute path, begin by changing to the root
	; directory. 
	;

		LocalCmpChar ds:[si], '\\'
		jne	gotStart

		push	ds, dx
		segmov	ds, cs, dx
			CheckHack <segment pathOpsRootPath eq @CurSeg>
		mov	dx, offset pathOpsRootPath
FXIP<		push	cx						>
FXIP<		clr	cx						>
FXIP<		call	SysCopyToStackDSDX				>
FXIP<		pop	cx						>
		call	DOSInternalSetDir
FXIP<		call	SysRemoveFromStack				>
		pop	ds, dx

		LocalNextChar dssi

gotStart:
	;
	; If we were passed the root directory, then deal with it specially
	;
SBCS <		tst	{char}ds:[si]					>
DBCS <		tst	{wchar}ds:[si]					>
		jz	mapRoot

	;
	; Begin the mapping of the path to the native namespace. First we need
	; to save the flag that says if the whole path is a file or a
	; directory as we'll need it when mapping the final component.
	; 

		push	cx		; save file/dir flag

nextComponent:
	;
	; The main mapping loop starts here. ds:si points to the start of the
	; component to map next. We loop, looking for a backslash, which ends
	; just the component, or a null byte, which ends the path as a whole.
	;
	; At the end, ds:dx is the start of the component, ds:si is the start
	; of the next one, al is 0 if the component is the final one.
	; 
		mov	dx, si		; record component start
findComponentEndLoop:
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, '\\'
		je	foundEnd
		LocalIsNull	ax
		jnz	findComponentEndLoop

foundEnd:
		LocalCmpChar	ax, '\\'
		jne	notNull

	;
	; See if this is a null component -- if it is, just skip it.
	;
		mov	cx, dx
		LocalNextChar	dscx
		cmp	cx, si
		jne	notNull
		mov	dx, cx
		jmp	nextComponent

notNull:

	;
	; Set up CX to pass to DOSVirtMapComponent, based on whether this is an
	; internal component (CX=non-zero => directory), or not (CX=whatever
	; we were passed)
	; 
		mov	cx, DVCT_INTERNAL_DIR 	; assume not final => must be
						;  directory.
		LocalIsNull	ax
		jnz	mapComponent
		pop	cx		; recover file/dir flag
		push	cx		; ...and put it back, so handling a
					;  mapping error is easier...
mapComponent:
	;
	; Attempt to map the single component at ds:dx
	; 
if _MS7
		call	DOS7MapComponent
else
		call	DOSVirtMapComponent
endif
		jc	mapError
		LocalIsNull	ax	; final component?
		jnz	nextComponent	; no -- go map the next one
mapError:
		pop	cx		; recover passed flag. CF and AX
					;  are already set appropriately.
doneFileDirFlagPopped:
		pop	si		; recover passed ax
		jc	exit
		mov_tr	ax, si		; return passed ax when successful
exit:
		.leave
		ret

mapRoot:
		call	DOSVirtMapRootName
		jmp	doneFileDirFlagPopped

DOSVirtMapPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtMapFilePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a virtual name to its native equivalent, assuming the
		final component is a file *or* a directory

CALLED BY:	INTERNAL
PASS:		ds:dx	= path to map
RETURN:		carry set if couldn't map:
			ax	= ERROR_FILE_NOT_FOUND
		carry clear if map successful:
			dosNativeFFD.FFD_name contains native name of final component.
			DOS CWD set to directory containing it.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtMapFilePath	proc	far
		uses	cx
		.enter
			CheckHack <DVCT_FILE_OR_DIR eq 0>
		clr	cx		; dir or file
		call	DOSVirtMapPath
		.leave
		ret
DOSVirtMapFilePath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtMapDirPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a virtual path to something we know is a directory

CALLED BY:	INTERNAL
PASS:		ds:dx	= path to map
RETURN:		carry set if couldn't map it:
			ax - FileError
			if AX = ERROR_LINK_ENCOUNTERED
				bx = handle of link data

		carry clear if map successful:
			dosNativeFFD.FFD_name filled with native
			version  of final component
			DOS CWD set to directory holding dosNativeFFD.FFD_name
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtMapDirPath	proc	far
		uses	cx
		.enter
		mov	cx, DVCT_DIR		; flag last component is dir
		call	DOSVirtMapPath
		.leave
		ret
DOSVirtMapDirPath	endp


PathOps		ends

;---

PathOpsRare segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtMapRootName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up dosNativeFFD to deal with being told to map the
		root directory.

CALLED BY:	DOSVirtMapPath
PASS:		nothing
RETURN:		carry clear
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtMapRootName proc	far
		uses	ds
		.enter
		call	PathOpsRare_LoadVarSegDS
if _MS7
		mov	{word}ds:[dos7FindData].W32FD_fileName.MSD7GN_longName, '.' or (0 shl 8)
		mov	ds:[dos7FindData].W32FD_fileAttrs.low.low, mask FA_SUBDIR
endif
		mov	{word}ds:[dosNativeFFD].FFD_name, '.' or (0 shl 8)
		mov	ds:[dosNativeFFD].FFD_attributes, mask FA_SUBDIR
		clr	ax
		mov	ds:[dosNativeFFD].FFD_dirIndex, -1
		mov	ds:[dosNativeFFD].FFD_dirLBN, ax
		mov	ds:[dosNativeFFD].FFD_modTime, ax
		mov	ds:[dosNativeFFD].FFD_modDate, ax
		mov	ds:[dosNativeFFD].FFD_fileSize.low, ax
		mov	ds:[dosNativeFFD].FFD_fileSize.high, ax
		.leave
		ret
DOSVirtMapRootName endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtCreateDirectoryFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the special directory file so that we can store
		extended attributes in it.

CALLED BY:	DOSVirtWriteChangedExtAttrs, DOSPathRenameGeosFile

PASS:		si - disk handle
		ds - dgroup
		JFT slot allocated

RETURN:		IF ERROR:
			carry set
			ax - FileError
		ELSE:
			ax - DOS handle

		JFT slot will remain allocated in either case

DESTROYED:	bx,cx,dx,si,di,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This procedure changes the DOS CWD.  Currently no code relies
	on it being left the same, so we should be OK


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtCreateDirectoryFile	proc far

	;
	; First, we want to CD into the directory where the file will
	; be created.
	;
if _MS7
		mov	dx, offset dos7FindData.W32FD_fileName.MSD7GN_longName
else
		mov	dx, offset dosNativeFFD.FFD_name
endif
		call	DOSInternalSetDir
		jc	done
	
	;
	; Call the common routine to create the directory file
	; To create it, we have to pass the DiskDesc in es:si, since
	; DOSCreateNativeFile uses it (DOSCheckDiskIsOurs).
	;
		call	FSDDerefInfo
		mov	es, ax
		call	DOSLinkCreateDirectoryFile
		jc	done

	;
	; Position the file at the start, which is something our
	; called routine didn't do for us:
	;

		clr	cx, dx
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21

	;
	; DOSCreateNativeFile allocated another JFT slot if it was
	; successful.  Therefore, we should free a JFT slot if the
	; file was successfully created, so that we maintain the same
	; number of JFT grabs.
	;

		mov_tr	ax, bx			; DOS handle
		mov	bx, NIL
		call	DOSFreeDosHandleFar
done:
		ret
DOSVirtCreateDirectoryFile	endp

PathOpsRare ends

;---

ExtAttrs	segment	resource

if _MS7
;
; Offsets of virtual extended attributes in the longname.
; 
eaDOS7VirtAttrOffsetTable word \
	0,					; FEA_MODIFICATION (not used)
	0,					; FEA_FILE_ATTR (n.u.)
	0,					; FEA_SIZE (n.u.)
	MSD7GN_type,				; FEA_FILE_TYPE
	MSD7GN_flags,				; FEA_FLAGS
	MSD7GN_release,				; FEA_RELEASE
	MSD7GN_protocol,			; FEA_PROTOCOL
	MSD7GN_token,				; FEA_TOKEN
	MSD7GN_creator,				; FEA_CREATOR
	0,					; FEA_USER_NOTES
	0,					; FEA_NOTICE
	0,					; FEA_CREATION
	0,					; FEA_PASSWORD
	0,					; FEA_CUSTOM (n.u.)
	MSD7GN_longName,			; FEA_NAME (n.u.)
	MSD7GN_geodeAttrs,			; FEA_GEODE_ATTR
	0,					; FEA_PATH_INFO (n.u.)
	0,					; FEA_FILE_ID (n.u.)
	0,					; FEA_DESKTOP_INFO
	0,					; FEA_DRIVE_STATUS (n.u.)
	0,					; FEA_DISK (n.u.)
	0,					; FEA_DOS_NAME (n.u.)
	0,					; FEA_OWNER (n.u.)
	0,					; FEA_RIGHTS (n.u.)
	0					; FEA_TARGET_FILE_ID (n.u.)
CheckHack <length eaDOS7VirtAttrOffsetTable eq FEA_LAST_VALID+1>

endif
		
;
; Offsets of virtual extended attributes within the file header.
; 
eaVirtAttrOffsetTable word \
	0,					; FEA_MODIFICATION (not used)
	0,					; FEA_FILE_ATTR (n.u.)
	0,					; FEA_SIZE (n.u.)
	GFH_type,				; FEA_FILE_TYPE
	GFH_flags,				; FEA_FLAGS
	GFH_release,				; FEA_RELEASE
	GFH_protocol,				; FEA_PROTOCOL
	GFH_token,				; FEA_TOKEN
	GFH_creator,				; FEA_CREATOR
	GFH_userNotes,				; FEA_USER_NOTES
	GFH_notice,				; FEA_NOTICE
	GFH_created,				; FEA_CREATION
	GFH_password,				; FEA_PASSWORD
	0,					; FEA_CUSTOM (n.u.)
	GFH_longName,				; FEA_NAME (n.u.)
	FGEAD_geodeAttr-FGEAD_header,		; FEA_GEODE_ATTR
	0,					; FEA_PATH_INFO (n.u.)
	0,					; FEA_FILE_ID (n.u.)
	GFH_desktop,				; FEA_DESKTOP_INFO
	0,					; FEA_DRIVE_STATUS (n.u.)
	0,					; FEA_DISK (n.u.)
	0,					; FEA_DOS_NAME (n.u.)
	0,					; FEA_OWNER (n.u.)
	0,					; FEA_RIGHTS (n.u.)
	0					; FEA_TARGET_FILE_ID (n.u.)
CheckHack <length eaVirtAttrOffsetTable eq FEA_LAST_VALID+1>


		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the indicated extended attribute(s) from the
		passed open file.

CALLED BY:	DOSHandleOp, DOSPathOp
PASS:		bx	= DOS handle if dx is nonzero
		ax	= FileExtendedAttribute
		es:di	= buffer in which to place results, or array of
			  FileExtAttrDesc structures, if ax is FEA_MULTIPLE
		cx	= size of said buffer, or # of entries in buffer if
			  ax is FEA_MULTIPLE
		dx	= DOSFileEntry offset if file already open
			= 0 if given a path, not an open file (=>
			  dosNativeFFD and dosFinalComponent contain
			  information suitable for return as FEA_DOS_NAME
			  and FEA_NAME values).
		si	= disk on which file/name is located

RETURN:		carry set on error:
			ax	= error code
		carry clear on success
			ax	= destroyed
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetExtAttrs	proc	far
singleAttr	local	FileExtAttrDesc
		uses	es, di, ds, bx, cx
		.enter


		
		cmp	ax, FEA_MULTIPLE
		je	haveAttrArray
	;
	; It's easiest to work with an array of descriptors always, so if
	; a single attribute is being asked for, stuff it into our local frame
	; and point ds:si at that one attribute...
	; 
EC <		cmp	ax, FEA_CUSTOM					>
EC <		ERROR_E	CUSTOM_ATTRIBUTES_MUST_BE_PASSED_AS_FEA_MULTIPLE>
		mov	ss:[singleAttr].FEAD_attr, ax
		mov	ss:[singleAttr].FEAD_value.segment, es
		mov	ss:[singleAttr].FEAD_value.offset, di
		mov	ss:[singleAttr].FEAD_size, cx
		segmov	es, ss
		lea	di, ss:[singleAttr]
		mov	cx, 1
haveAttrArray:
	;
	; Allocate the necessary workspace. We allocate it fixed as we'd
	; otherwise keep it locked for its entire lifetime, so why bother
	; with that?
	; 
		call	DOSAllocFileGetExtAttrData
		LONG	jc	exit
	;
	; Initialize the various pieces that always get the same things,
	; regardless of who called us.
	; 
		mov	ds:[FGEAD_disk], si
		mov	ds:[FGEAD_numAttrs], cx
		mov	ds:[FGEAD_fileHandle], bx

		mov	ds:[FGEAD_attrs].offset, di
		mov	ds:[FGEAD_attrs].segment, es
if not _MS7
	    ;
	    ; Always set the fptr to the DTA, even if have a handle (why not?)
	    ; 
		mov	ds:[FGEAD_dta].segment, dgroup
		mov	ds:[FGEAD_dta].offset, offset dosNativeFFD
else
	;
	; We want a pointer to the whole FindData because TIME comes from
	; there.  This is also a good time to check the signature in the
	; complex long name to see if this is a geos or native file.
	;
		push	ds, es, di, si
		call	ExtAttrs_LoadVarSegDS
		mov	si, offset dos7FindData
		test	ds:[si].W32FD_fileAttrs.low.low, mask FA_SUBDIR
		jnz	popRegs
		add	si, offset W32FD_fileName.MSD7GN_signature
		segmov	es, ds
		mov	di, offset nativeSignature
		mov	cx, size nativeSignature
		repe	cmpsb
popRegs:
		pop	ds, es, di, si
		jnz	geosFile

		or	ds:[FGEAD_flags], mask FGEAF_NOT_GEOS
geosFile:
		mov	ds:[FGEAD_fd].segment, dgroup
		mov	ds:[FGEAD_fd].offset, offset dos7FindData
endif
	;
	; Set FGEAD_flags. Assume file not open (as there's nothing else to
	; set up...)
	;
		mov	ax, mask FGEAF_HAVE_VIRTUAL or \
					 mask FGEAF_HAVE_LONG_NAME_ATTRS
		tst	dx
		jz	setFlags
	;
	; Wrong. FHGEAD_fileHandle already set up, but need to set up
	; FHGEAD_privData too, then set FGEAF_HAVE_HANDLE, not
	; FGEAF_HAVE_VIRTUAL.
	; 
		mov	ds:[FGEAD_spec].FGEASD_handle.FHGEAD_privData.offset,
				dx
		mov	ax, dgroup
		mov	ds:[FGEAD_spec].FGEASD_handle.FHGEAD_privData.segment,
				ax

	    ;
	    ; DirPathInfo unknown.
	    ; 
		mov	ds:[FGEAD_pathInfo], 0
	    ;
	    ; If private data for handle indicates file isn't geos, then set
	    ; FGEAF_NOT_GEOS, to avoid wasting time.
	    ;
		push	ds
		mov	ds, ax
		mov	bx, dx
		mov	ax, mask FGEAF_HAVE_HANDLE
		test	ds:[bx].DFE_flags, mask DFF_GEOS or mask DFF_OLD_GEOS
		pop	ds
		jnz	setFlags
		ornf	ax, mask FGEAF_NOT_GEOS
setFlags:
		mov	ds:[FGEAD_flags], ax

	;
	; Call common routine to do the real work.
	; 
		call	DOSVirtGetExtAttrsLow
	;
	; Free the workspace without biffing the carry.
	; 
		pushf
		mov	bx, ds:[FGEAD_block]
		call	MemFree
		popf
exit:
		.leave
		ret
DOSVirtGetExtAttrs endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtCallSecondary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the secondary IFS driver to have it perform some
		function for us.

CALLED BY:	DOSVirtGetExtAttrsLow, DOSVirtSetExtAttr
PASS:		bx	= disk handle via which we get to the secondary
		di	= DOSSecondaryFSFunction to call
RETURN:		carry set on error:
			ax	= ERROR_ATTR_NOT_SUPPORTED, if disk is actually
				  run by us.
				= whatever secondary returned otherwise
		carry clear if ok
DESTROYED:	es, bp nuked before call is made, but returned to caller intact

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtCallSecondary proc near
		uses	bp, es
		.enter
	;
	; See if the disk is actually ours...
	; 
		push	ax
		call	FSDLockInfoShared
		mov	es, ax
		pop	ax
		xchg	bx, di
		call	DOSCheckDiskIsOurs
		xchg	bx, di
		jc	unsupported		; => disk is ours, so fail

	;
	; Find the secondary's FSDriverInfoStruct.
	; 
		mov	bp, es:[bx].DD_drive
		mov	bp, es:[bp].DSE_fsd

		push	ds, si, bx
		mov	bx, es:[bp].FSD_handle
		call	GeodeInfoDriver
		segmov	es, ds
		mov	bp, si		; es:bp <- FSDIS
		pop	ds, si, bx
	;
	; Make sure the secondary's protocol number isn't out of line.
	; 
		cmp	es:[bp].FSDIS_altProto.PN_major,
			DOS_SECONDARY_FS_PROTO_MAJOR
		jne	unsupported
		cmp	es:[bp].FSDIS_altProto.PN_minor,
			DOS_SECONDARY_FS_PROTO_MINOR
		jb	unsupported
	;
	; All systems are go -- call the secondary.
	; 
		call	es:[bp].FSDIS_altStrat
done:
		call	FSDUnlockInfoShared
		.leave
		ret

unsupported:
	;
	; Can't call the secondary, either because *we* are the secondary
	; or because it might not support the call, so return that the
	; attribute isn't supported.
	; 
		mov	ax, ERROR_ATTR_NOT_SUPPORTED
		stc
		jmp	done
DOSVirtCallSecondary endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetExtAttrsEnsureHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make certain we've got the header for the file or we know
		it ain't there.

CALLED BY:	DOSVirtGetExtAttrsLow, DOSFileEnum
PASS:		ds	= FileGetExtAttrData
RETURN:		carry set if file not a geos file.
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_MOVABLE_READ_HEADER	equ (not FULL_EXECUTE_IN_PLACE) and \
				(segment DOSVirtReadFileHeader ne @CurSeg)
DOSVirtGetExtAttrsEnsureHeader proc	near
if _MOVABLE_READ_HEADER
readHeaderProc	local	fptr.far
endif
		uses	es, si, cx
		.enter
		
		mov	ax, ds:[FGEAD_flags]
		test	ax, mask FGEAF_NOT_GEOS
		stc				; assume not geos...
		LONG 	jnz	error

		test	ax, mask FGEAF_HAVE_HEADER
		LONG 	jnz	done

		test	ax, mask FGEAF_HAVE_HANDLE
		jnz	useHandle
		
	;
	; Call common routine to open the file and read in the entire header,
	; plus the geode attributes, which just happen to come after the header
	; It's not too big, so there's no gain, really, in not reading the
	; whole thing in (as opposed to reading in the signature and making
	; sure it's something we like, then reading in the rest). Since the
	; attributes for a geode, if that's what this is, follow directly after
	; the GeosFileHeader, as (surprisingly) does our storage spot for them,
	; we actually read the word following the header, on the assumption that
	; the file we've got is actually a geode.
	; 
	CheckHack <FGEAD_geodeAttr eq FGEAD_header+size FGEAD_header>
	CheckHack <GFH_execHeader.EFH_attributes eq 0>

		push	ds
		segmov	es, ds
		mov	si, offset FGEAD_header	; es:si <- buffer for read
if _MS7
		lds	dx, ds:[FGEAD_fd]
else
		lds	dx, ds:[FGEAD_dta]	; ds:dx <- dta
endif
		mov	cx, size FGEAD_header + size FGEAD_geodeAttr
		call	DOSVirtOpenGeosFileForHeader
		pop	ds
		jmp	processReadResult

useHandle:
	;
	; More fun when all we've got is a handle:
	; 1) save current file position
	; 2) seek back to 0
	; 3) read the header in
	; 4) seek back to previous position
	; 5) see if header is for geos file.
	; 
		push	bx
if _MOVABLE_READ_HEADER
		; cannot read this thing in while we have the bios lock, so
		; be sure it's resident before we grab the bios lock
		mov	bx, vseg DOSVirtReadFileHeader
		call	MemLockFixedOrMovable
		mov	ss:[readHeaderProc].segment, ax
		mov	ss:[readHeaderProc].offset, offset DOSVirtReadFileHeader
endif
		call	SysLockBIOS	; make this stuff atomic so we don't
					;  mess up some other thread reading
					;  from the same file.
		
	    	mov	bx, ds:[FGEAD_fileHandle]

		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_RELATIVE
		clr	cx		; seek 0 bytes from current
		mov	dx, cx
		call	DOSUtilInt21	; dx:ax <- cur position
		push	ax, dx
		
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		clr	cx		; seek to position 0
		mov	dx, cx
		call	DOSUtilInt21
		
		segmov	es, ds
	CheckHack <FGEAD_geodeAttr eq FGEAD_header+size FGEAD_header>
	CheckHack <GFH_execHeader.EFH_attributes eq 0>
		mov	si, offset FGEAD_header
		mov	cx, size FGEAD_header+size FGEAD_geodeAttr
if _MOVABLE_READ_HEADER
   		call	ss:[readHeaderProc]
else
		call	DOSVirtReadFileHeader
endif

		pop	dx, cx		; cx:dx <- old position that we must
					;  restore before dealing with the error
		pushf
		push	ax
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21

		call	SysUnlockBIOS
if _MOVABLE_READ_HEADER
		mov	bx, vseg DOSVirtReadFileHeader
		call	MemUnlockFixedOrMovable
endif

		pop	ax
		popf

		pop	bx

processReadResult:
		mov	dx, mask FGEAF_HAVE_HEADER
		jnc	setFlags
error:
		mov	ax, ERROR_ATTR_NOT_FOUND
		mov	dx, mask FGEAF_NOT_GEOS
setFlags:
		pushf
		or	ds:[FGEAD_flags], dx
		popf
done:
		.leave
		ret
DOSVirtGetExtAttrsEnsureHeader	endp


;-----------------------------------------------------------------------------
;	Attribute tables for normal files (not links)
;-----------------------------------------------------------------------------

; If the size is zero, then any size is OK

getAttrSizeTable byte	size FileDateAndTime,	; FEA_MODIFIED
			size FileAttrs,		; FEA_FILE_ATTR
			size dword,		; FEA_SIZE
			size GeosFileType,	; FEA_FILE_TYPE
			size GeosFileHeaderFlags,; FEA_FLAGS
			size ReleaseNumber,	; FEA_RELEASE
			size ProtocolNumber,	; FEA_PROTOCOL
			size GeodeToken,	; FEA_TOKEN
			size GeodeToken,	; FEA_CREATOR
			0,			; FEA_USER_NOTES
			0,			; FEA_NOTICE
			size FileDateAndTime,	; FEA_CREATED
			0,			; FEA_PASSWORD
			0,			; FEA_CUSTOM
			0,			; FEA_NAME
			size GeodeAttrs,	; FEA_GEODE_ATTR
			size DirPathInfo,	; FEA_PATH_INFO
			size FileID,		; FEA_FILE_ID
			0,			; FEA_DESKTOP_INFO
			size DriveExtendedStatus,; FEA_DRIVE_STATUS
			size word,		; FEA_DISK
			0,			; FEA_DOS_NAME
			0,			; FEA_OWNER
			0,			; FEA_RIGHTS
			size FileID		; FEA_TARGET_FILE_ID

.assert (length getAttrSizeTable) eq (FEA_LAST_VALID+1)

getAttrRoutTable	nptr	DOSVirtGetAttrModified,; FEA_MODIFICATION
			DOSVirtGetAttrFileAttr,	; FEA_FILE_ATTR
			DOSVirtGetAttrSize,		; FEA_SIZE
			DOSVirtGetAttrVirtual,		; FEA_FILE_TYPE
			DOSVirtGetAttrVirtual,		; FEA_FLAGS
			DOSVirtGetAttrVirtual,		; FEA_RELEASE
			DOSVirtGetAttrVirtual,		; FEA_PROTOCOL
			DOSVirtGetAttrVirtual,		; FEA_TOKEN
			DOSVirtGetAttrVirtual,		; FEA_CREATOR
			DOSVirtGetAttrVirtual,		; FEA_USER_NOTES
			DOSVirtGetAttrVirtual,		; FEA_NOTICE
if _MS7
			DOS7GetCreationDateAndTime,	
else
			DOSVirtGetAttrVirtual,		; FEA_CREATION
endif
			DOSVirtGetAttrVirtual,		; FEA_PASSWORD
			DOSVirtGetAttrUnsupported,	; FEA_CUSTOM
			DOSVirtGetAttrName,		; FEA_NAME
			DOSVirtGetAttrVirtual,		; FEA_GEODE_ATTR
			DOSVirtGetAttrPathInfo,		; FEA_PATH_INFO
			DOSVirtGetAttrFileID,		; FEA_FILE_ID
			DOSVirtGetAttrVirtual,		; FEA_DESKTOP_INFO
			DOSVirtGetAttrDriveStatus,	; FEA_DRIVE_STATUS
			DOSVirtGetAttrDisk,		; FEA_DISK
			DOSVirtGetAttrDosName,		; FEA_DOS_NAME
			DOSVirtGetAttrUnsupported,	; FEA_OWNER
			DOSVirtGetAttrUnsupported,	; FEA_RIGHTS
			DOSVirtGetAttrUnsupported	; FEA_TARGET_FILE_ID
CheckHack <length getAttrRoutTable eq FEA_LAST_VALID+1>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetExtAttrsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the indicated extended attributes for the given file.

CALLED BY:	DOSVirtGetExtAttrs, DOSEnum
PASS:		ds	= segment of FileGetExtAttrData block with
			  appropriate fields filled in appropriately.
RETURN:		carry set if error:
			ax	= error code
		carry clear if ok:
			ax	= destroyed
DESTROYED:	es, cx, di, bx, si, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetExtAttrsLow proc	near

	;
	; See if the disk is ours and, if not, whether we can still use
	; the SFT entry for our fun.
	; 
		call	FSDLockInfoShared
		mov	es, ax
		mov	di, ds:[FGEAD_disk]
		call	DOSCheckDiskIsOurs
		jc	releaseFSIR
		ornf	ds:[FGEAD_flags], mask FGEAF_DISK_NOT_OURS
	;
	; Disk isn't ours, but the SFT may still be ok. Check the private
	; data to see.
	; 
		les	di, ds:[FGEAD_spec].FGEASD_handle.FHGEAD_privData
		test	es:[di].DFE_flags, mask DFF_SFT_VALID
		jz	releaseFSIR
		ornf	ds:[FGEAD_flags], mask FGEAF_SFT_VALID
releaseFSIR:
		call	FSDUnlockInfoShared
	;
	; Set up for the attribute loop.
	; 
		mov	cx, ds:[FGEAD_numAttrs]
		les	si, ds:[FGEAD_attrs]

		mov	ds:[FGEAD_sizeTable], offset getAttrSizeTable
		CheckHack <segment getAttrSizeTable eq @CurSeg>
		mov	ds:[FGEAD_routTable], offset getAttrRoutTable
		CheckHack <segment getAttrRoutTable eq @CurSeg>

		FALL_THRU	DOSVirtGetExtAttrsProcessLoop
DOSVirtGetExtAttrsLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetExtAttrsProcessLoop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the attributes for the file, based on the
		passed attribute array and tables
		

CALLED BY:	DOSVirtGetExtAttrsLow, DOSLinkGetLinkAttrs

PASS:		ds - segment of FileGetExtAttrData

		ds:FGEAD_sizeTable -- pointer to table of sizes of
			each attribute
		ds:FGEAD_routTable -- pointer to table of attribute-
			fetching routines

		es:si - FileExtAttrDesc array
		cx    - number of elements in array

RETURN:		if attrs were fetched OK:
			carry clear
		else
			carry set

DESTROYED:	ax,cx,di,si,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	Broken out from DOSVirtGetExtAttrsLow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetExtAttrsProcessLoop	proc near

		uses	bx, bp

		.enter
	;
	; If pathInfo given and indicates the thing is local, set the
	; DPI_EXISTS_LOCALLY bit to make life in the app world a bit easier.
	; 
		mov	ax, ds:[FGEAD_pathInfo]
		tst	ax
		jz	processAttrs	; => not known
		test	ax, mask DPI_ENTRY_NUMBER_IN_PATH
		jnz	processAttrs	; => not local
		ornf	ds:[FGEAD_pathInfo], mask DPI_EXISTS_LOCALLY
processAttrs:


		mov	ds:[FGEAD_error], 0	; no error, yet

attrLoop:
	;
	; Fetch the next attribute desired from the array and make sure the
	; destination buffer is big enough to hold the value.
	; 
		push	cx
		mov	bx, es:[si].FEAD_attr
EC <		cmp	bx, FEA_LAST_VALID				>
EC <		ERROR_A	ILLEGAL_EXTENDED_ATTRIBUTE			>
		mov	cx, es:[si].FEAD_size
		tst	ch
		jnz	sizeOK
		mov	di, ds:[FGEAD_sizeTable]
		cmp	cl, cs:[di][bx]
		jae	sizeOK
		jmp	sizeError
sizeOK:
	;
	; Load the rest of the attribute descriptor into appropriate
	; registers and call the handler for it.
	; 
		shl	bx
		push	es
		les	di, es:[si].FEAD_value
		;
		; pass:
		; 	es:di	= FEAD_value
		;	si   	= offset of FileExtAttrDesc
		; 	cx	= FEAD_size
		; 	bx	= FEAD_attr * 2
		; 	al	= FileGetExtAttrFlags
		; return:
		; 	nothing
		;
		; destroy:
		; 	es, di, cx, bx, ax, dx
		;
		mov	ax, ds:[FGEAD_flags]
		mov	bp, ds:[FGEAD_routTable]
		add	bp, bx
		call	cs:[bp]
		pop	es
nextAttr:
	;
	; Advance to the next descriptor in the array.
	; 
		pop	cx
		add	si, size FileExtAttrDesc
		loop	attrLoop
	;
	; Fetch any error we're to return, and set carry if there is one...
	; 
		mov	ax, ds:[FGEAD_error]
		tst	ax
		jz	done
		stc
done:					
		.leave
		ret

sizeError:
		mov	ds:[FGEAD_error], ERROR_ATTR_SIZE_MISMATCH
		jmp	nextAttr


DOSVirtGetExtAttrsProcessLoop	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAttrModified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the "modified" extended attribute

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:		es:di = place to store result
		cx	= size of dest
		bx	= attr * 2
		ax	= FileGetExtAttrFlags

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetAttrModified	proc near
		.enter
	;
	; Consult DOS to get this if this is a call for a handle, else use
	; the dosNativeFFD, since we may not have opened the file yet...
	; 
		test	ax, mask FGEAF_HAVE_HANDLE
		jnz	eaMUseHandle
		push	es
if _MS7
		les	bx, ds:[FGEAD_fd]
		mov	dx, es:[bx].W32FD_modified.MSD7DT_date
		mov	cx, es:[bx].W32FD_modified.MSD7DT_time
else
		les	bx, ds:[FGEAD_dta]
		mov	dx, es:[bx].FFD_modDate
		mov	cx, es:[bx].FFD_modTime
endif
		pop	es
		jmp	eaMHaveDateTime
eaMUseHandle:
		mov	bx, ds:[FGEAD_fileHandle]
		mov	ax, (MSDOS_GET_SET_DATE shl 8) or 0	; get...
		call	DOSUtilInt21
eaMHaveDateTime:
		mov	es:[di].FDAT_date, dx
		mov	es:[di].FDAT_time, cx

		.leave
		ret
DOSVirtGetAttrModified	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAttrFileAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch FileAttr record

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:		es:di = place to store result
		cx	= size of dest
	 	bx	= attr * 2
	 	ax	= FileGetExtAttrFlags
	

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetAttrFileAttr	proc near

		.enter

	; 
	; If we've got names, then dosNativeFFD contains these. Else we must
	; consult our own table for the info, based on the file's SFN.
	; 
		push	es
if _MS7
		les	bx, ds:[FGEAD_fd]
		test	ax, mask FGEAF_HAVE_HANDLE
		mov	al, es:[bx].W32FD_fileAttrs.low.low
		jz	eaFAHaveAttrs
else
		les	bx, ds:[FGEAD_dta]
		test	ax, mask FGEAF_HAVE_HANDLE
		mov	al, es:[bx].FFD_attributes
		jz	eaFAHaveAttrs
endif
		les	bx, ds:[FGEAD_spec].FGEASD_handle.FHGEAD_privData
		mov	al, es:[bx].DFE_attrs
eaFAHaveAttrs:
		andnf	al, not FA_GEOS_FILE	; let's not screw ourselves,
						;  shall we?
		pop	es
		stosb

		.leave
		ret
DOSVirtGetAttrFileAttr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAttrSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine file size

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:		es:di = place to store result
		ds:si = FileExtAttrDesc
		bx	= attr * 2
		ax	= FileGetExtAttrFlags


RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetAttrSize	proc 	near
		.enter
	;
	; Similar to FEA_MODIFICATION, if called for a handle, use DOS's
	; internal tables to get the current size, else dosNativeFFD is
	; sufficient.
	; 
		push	es, di
		test	ax, mask FGEAF_HAVE_HANDLE
		jnz	useHandle
if _MS7
		les	di, ds:[FGEAD_fd]
EC <		movdw	cxdx, es:[di].W32FD_fileSizeHigh		>
EC <		Assert	e cx, 0						>
EC <		Assert	e dx, 0						>
		movdw	cxdx, es:[di].W32FD_fileSizeLow

		test	es:[di].W32FD_fileAttrs.low.low, mask FA_SUBDIR
else
		call	DOSVirtGetExtAttrsEnsureHeader

		les	di, ds:[FGEAD_dta]
		mov	cx, es:[di].FFD_fileSize.high
		mov	dx, es:[di].FFD_fileSize.low

		test	es:[di].FFD_attributes, mask FA_SUBDIR
endif
		jnz	eaSHaveSize

		test	ds:[FGEAD_flags], mask FGEAF_NOT_GEOS
		jz	reduceByHeader
		jmp	eaSHaveSize

useHandle:
			CheckHack <(mask FGEAF_DISK_NOT_OURS eq 0x80) and \
				   (offset FGEAF_SFT_VALID lt 8)>
		test	ax, mask FGEAF_DISK_NOT_OURS or mask FGEAF_SFT_VALID
		jz	eaSGetFromSFT
		jpo	eaSUseDOS
eaSGetFromSFT:
		call	DOSVirtPointToFileDesc

DRI <		mov	cx, es:[di].FD_size.high			>
DRI <		mov	dx, es:[di].FD_size.low				>

MS <		mov	cx, es:[di].SFTE_size.high			>
MS <		mov	dx, es:[di].SFTE_size.low			>
checkHandleGeos:
   		les	bx, ds:[FGEAD_spec].FGEASD_handle.FHGEAD_privData
		test	es:[bx].DFE_flags, mask DFF_GEOS
		jz	eaSHaveSize

reduceByHeader:
		sub	dx, size GeosFileHeader
		sbb	cx, 0
eaSHaveSize:
		pop	es, di
		mov	({dword}es:[di]).high, cx
		mov	({dword}es:[di]).low, dx
		.leave
		ret

eaSUseDOS:
		push	bp
		mov	bp, ds:[FGEAD_spec].FGEASD_handle.FHGEAD_privData.offset
		mov	bx, ds:[FGEAD_fileHandle]
		call	DOSUtilFileSize
		pop	bp
		mov	cx, dx
		mov_tr	dx, ax
		jmp	checkHandleGeos

DOSVirtGetAttrSize	endp


if _MS7

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7GetCreationDateAndTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In MS7, the creation time is part of the Win32FindData
		that we have for this file.

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:		cx = FEAD_size
		es:di = place to store result
		si = FileExtAttrDesc offset
		bx 	= attr * 2
RETURN:		nothing

DESTROYED:	nothing


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	2/ 3/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7GetCreationDateAndTime	proc	near
	
		.enter
	;
	; If this is a subdirectory, then we should try whatever's in the
	; @dirname header.  If the dir doesn't have one, then we can use
	; what's here.
	;
		push	ax, ds, si
		lds	si, ds:[FGEAD_fd]
		test	ds:[si].W32FD_fileAttrs.low.low, mask FA_SUBDIR
		jz	getFromFD
	;
	; Do it virtually.
	;
		call	DOSVirtGetAttrVirtual
		jmp	done
		
getFromFD:		
		mov	ax, ds:[si].W32FD_created.MSD7DT_date
		CheckHack <size FileDateAndTime eq 4>
		stosw
		mov	ax, ds:[si].W32FD_created.MSD7DT_time
		stosw
done:
		pop	ax, ds, si

		.leave
		ret
DOS7GetCreationDateAndTime	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAttrVirtual
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch any of the virtual attributes

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:		cx = FEAD_size
		es:di = place to store result
		si = FileExtAttrDesc offset
		bx 	= attr * 2

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetAttrVirtual	proc near
if _MS7
	;
	; Do we have a long long name?
	;
		test	ds:[FGEAD_flags], mask FGEAF_HAVE_LONG_NAME_ATTRS
		jz	useHeader
	;
	; Is this one of the attrs in the long name?
	;
		cmp	bx, FEA_FILE_TYPE*2
		jb	useHeader
		
		cmp	bx, FEA_CREATOR*2
		ja	useHeader
		
		call	DOS7GetAttrFromLongName
		jnc	done
		jmp	error
useHeader:
endif
		call	DOSVirtGetExtAttrsEnsureHeader
		jc	DOSVirtGetAttrSetError
	    ;
	    ; Copy from the proper offset in the header to the destination,
	    ; however many bytes the destination will hold.
	    ; 
		push	si
		mov	si, offset FGEAD_header
		add	si, cs:[eaVirtAttrOffsetTable][bx]
		rep	movsb
		pop	si
done:
		ret
error:
		mov	ax, ERROR_ATTR_NOT_FOUND
		jmp	DOSVirtGetAttrSetError

DOSVirtGetAttrVirtual	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7GetAttrFromLongName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the requested virtual attr from the longname.

CALLED BY:	DOSVirtGetAttrVirtual. 

PASS:		ds 	= FGEAD
		es:di = place to store result
		si = FileExtAttrDesc offset
		bx 	= attr * 2
		cx	= FEAD_size
RETURN:		nothing
DESTROYED:	nothing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/10/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7GetAttrFromLongName	proc	near
		uses ds, si
		.enter
	;
	; Load the ptr to FindData into ds:si
	;
		lds	si, ds:[FGEAD_fd]
	;
	; If this is directory, the only 'extended' attribute we have is
	; the long name.
	;
		cmp	bx, FEA_NAME*2
		je	getAttr
		test	ds:[si].W32FD_fileAttrs.low.low, mask FA_SUBDIR
		stc
		jnz	done
getAttr:
	;
	; Probably need to decode an ascii encoded hex value;
	; either that or we can't do anything.
	; But then we shouldn't be here.
	;
		add	si, offset W32FD_fileName
		mov	ax, cs:[eaDOS7VirtAttrOffsetTable][bx]
		tst	ax
EC <		ERROR_Z	-1						>
NEC <		jz	fail						>
		
		add	si, ax				; ds:si <- source
	;
	; If we have a blank then there's no attr.
	;
		cmp	{byte}ds:[si], ' '
		stc	
		je	done
NEC < fail:								>
NEC <		stc							>
NEC <		jmp	done						>
	;
	; Collect the result.
	;
		call	DOS7MapAsciiToBytes
		clc
done:
		.leave
		ret
		
DOS7GetAttrFromLongName	endp


		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAttrSetError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the error condition.  JUMPED TO by various other
		"ea" routines

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:		ax - error code
		si - offset to FileExtAttrDesc

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetAttrSetError	proc near

		.enter

		mov	ds:[FGEAD_error], ax
	    ;
	    ; Zero out the return buffer. (CX must still be dest size...)
	    ; 
	    	clr	al
		rep	stosb
	;
	; If desired, zero the segment of the attribute descriptor.
	; 
		test	ds:[FGEAD_flags], mask FGEAF_CLEAR_VALUE_SEG_IF_ABSENT
		jz	eaSetErrorDone
		mov	es, ds:[FGEAD_attrs].segment
		mov	es:[si].FEAD_value.segment, 0
eaSetErrorDone:

		.leave
		ret

DOSVirtGetAttrSetError	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAttrUnsupported
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	try to call the secondary driver

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:		es:di = place to store result
		si = FileExtAttrDesc offset
		cx = dest buffer size

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetAttrUnsupported	proc near
		mov	ax, ds:[FGEAD_flags]
		test	ax, mask FGEAF_DISK_NOT_OURS
		jz	DOSVirtGetAttrReallyUnsupported
		
		mov	bx, ds:[FGEAD_disk]
		push	ds, cx, di, es
		test	ax, mask FGEAF_HAVE_HANDLE
		mov	ax, 0		; don't biff flags, please
		mov	dx, ds:[FGEAD_fileHandle]
		jnz	eaUnsupCallSecondary
if _MS7
		mov	ax, ds:[FGEAD_fd].segment
		mov	dx, ds:[FGEAD_fd].offset
		add	dx, offset W32FD_alternateFileName
else
		mov	ax, ds:[FGEAD_dta].segment
		mov	dx, ds:[FGEAD_dta].offset
		add	dx, offset FFD_name
endif
		
eaUnsupCallSecondary:
		mov	ds, ds:[FGEAD_attrs].segment
		mov	di, DR_DSFS_GET_EXT_ATTRIBUTE
		call	DOSVirtCallSecondary
		pop	ds, cx, di, es
		jc	DOSVirtGetAttrSetError

		ret

DOSVirtGetAttrReallyUnsupported label near
		mov	ax,ERROR_ATTR_NOT_SUPPORTED
		jmp	DOSVirtGetAttrSetError

DOSVirtGetAttrUnsupported	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtMapDosToGeosName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a DOS name into a virtual PC/GEOS name, dealing with
		characters that can't be mapped in our own amusing and
		inimitable fashion.

CALLED BY:	DOSVirtGetAttrName, DOSPathOp::mapNativeName
PASS:		ds:si	= DOS name to map (null-terminated, '.' between
			  name and extension)
		es:di	= place in which to store the result
		cx	= # bytes in same
RETURN:		nothing
DESTROYED:	si, di, cx, ax

PSEUDO CODE/STRATEGY:
		Because we need this mapping to be reversible, which using
		a default character like '_' manifestly is not, we do not
		use the "normal" function LocalDosToGeos. Instead, we convert
		the DOS name one character at a time. For any character
		that can't be converted, we store a question mark followed by
		the character as two hex digits. Since the question mark is
		illegal in a geos file name, the user will be unable to type
		it in a properly-set-up text object, and life should be
		golden.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DOSVirtMapDosToGeosName proc	far
SBCS <		uses	bx						>
DBCS <		uses	bx, bp						>
		.enter
		dec	cx		; leave room for null-terminator
if DBCS_PCGEOS
		call	DCSFindCurCodePage
	;
	; Get and map the character
	;
convertLoop:
		push	cx
		call	DCSDosToGeosCharString
		pop	cx
EC <		ERROR_C	DOS_CHAR_COULD_NOT_BE_MAPPED			>
		tst	ax		;reached NULL?
		jz	endString	;branch if NULL
	;
	; Loop for more characters
	;
		loop	convertLoop
	;
	; NULL terminate me
	;
endString:
		clr	ax
		stosw			; null-terminate

else
convertLoop:
		lodsb			;al <- DOS character
		tst	al		;reached NULL terminator?
		jz	done		;branch if NULL

		call	DOSUtilDosToGeosChar
		jnc	storeMappedChar
	;
	; Store question-mark first, to flag this as weird
	; 
		mov	{char}es:[di], DOS_UMDOS_LEAD_CHAR
		inc	di
		dec	cx
		jz	done
	;
	; Convert the unmappable char to hex digits, 16s digit first.
	; 
		dec	cx
		jz	done		; => byte won't fit
		call	DOSUtilByteToAscii
		jmp	endLoop
storeMappedChar:
	;
	; Store the mapped char (or the 1s digit of the unmappable one)
	; 
		stosb
endLoop:
		loop	convertLoop
done:
		clr	al
		stosb			; null-terminate
endif

		.leave
		ret
DOSVirtMapDosToGeosName endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAttrName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the filename

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:		es:di = place to store result
		si = FileExtAttrDesc offset
		bx 	= attr * 2
		cx	= size of dest buffer
		ax	= FileGetExtAttrFlags

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetAttrName	proc 	near
		.enter
if _MS7
		push	ds, si
		tst	ds:[FGEAD_fd].segment
EC <		ERROR_Z	MSDOS7_WHERE_IS_FD_FOR_FILE_ENUM_?
NEC <		jz	error						>

	;
	; Copy the long name, unpad it.  
	;
		lds	si, ds:[FGEAD_fd]
		add	si, offset W32FD_fileName.MSD7GN_longName
		push	di			; start of dest
		rep	movsb
		pop	di			; es:di <- copied string
		call	DOS7UnPadLongName	; null terminated
	;
	; Whoops.  Because we store the geos long name inside the complex
	; long name, we will have converted bad dos characters to '~' (or
	; something).  So here, we have to scan the long name to see if it
	; has any of those characters in it.  If it does, then we must resort
	; to the ol' "get it from the header" routine.  This means files that
	; were created containing the special character will have to miss out
	; on the optimization...
	;
		mov	si, di			; save start
		LocalStrLength			; cx length
		mov	dx, cx			; dx <- length too
		mov	di, si			; reset start
		mov	al, '^'
		repne	scasb
		mov	di, si			; reset start
		jnz	eaNDone

		mov	cx, dx			; length!
tryHeader::
		pop	ds, si
		test	ds:[FGEAD_flags], mask  FGEAF_HAVE_HANDLE
		jnz	DOSVirtGetAttrReallyUnsupported

endif
		push	ds, si
		call	DOSVirtGetExtAttrsEnsureHeader
		mov	si, offset FGEAD_header.GFH_longName
EC <		ERROR_C	-1						>
NEC <		jc	error						>

		push	di
		rep	movsb
		pop	di
eaNDone:
		add	di, size MSD7GN_longName	; point past end
		pop	ds, si

		.leave
		ret
if _MS7
NEC <error:
NEC <		pop	ds, si						>
NEC <		mov	ax, ERROR_ATTR_NOT_FOUND			>
NEC <		jmp	DOSVirtGetAttrSetError				>
endif
		
DOSVirtGetAttrName	endp


		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAttrDosName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	fetch the DOS name

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:		es:di = place to store result
		si = FileExtAttrDesc offset
		cx = dest buffer size
		bx 	= attr * 2
		ax	= FileGetExtAttrFlags

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetAttrDosName	proc near
		.enter
		test	ax, mask FGEAF_HAVE_HANDLE
		LONG jnz DOSVirtGetAttrReallyUnsupported  ; never supported for
						;  handle case, no matter
						;  who's running the thing.

		push	ds, si
if _MS7
	;
	; The dos name will be in the short name if we have long name attrs,
	; and in the long name if not. 
	;
		lds	si, ds:[FGEAD_fd]		; ds:si find data
		mov	bx, offset W32FD_fileName.MSD7GN_shortName
		test	ax, mask FGEAF_HAVE_LONG_NAME_ATTRS
		jnz	gotName
		
		mov	bx, offset W32FD_fileName.MSD7GN_longName
gotName:
		add	si, bx
else		
		lds	si, ds:[FGEAD_dta]
		add	si, offset FFD_name
endif
		mov	ax, di
		rep	movsb
		push	di
		mov	di, ax
		call	DOS7UnPadShortName
		pop	di
		pop	ds, si
		.leave
		ret
DOSVirtGetAttrDosName	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAttrFileID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the File ID

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:		; es:di = place to store result
		; si = FileExtAttrDesc offset
		; bx 	= attr * 2
		; ax	= FileGetExtAttrFlags


RETURN:		nothing 

DESTROYED:	cx, di, ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetAttrFileID	proc near
		.enter

		test	ax, mask FGEAF_HAVE_HANDLE
		jz	eaFIDFromDTA
		
		push	ds
		lds	bx, ds:[FGEAD_spec].FGEASD_handle.FHGEAD_privData
		movdw	cxax, ds:[bx].DFE_id
		pop	ds
eaFIDStore:
		stosw
		mov_tr	ax, cx
		stosw
		.leave
		ret

eaFIDFromDTA:
	    ;
	    ; FileID requested for path, so just figure the ID from the
	    ; DTA.
	    ; 
		push	dx, si, ds
		test	ax, mask FGEAF_HAVE_BASE_ID
		jz	getCurPathID
		
		movdw	cxdx, ds:[FGEAD_spec].FGEASD_enum.FED_baseID
addDTAID:
	;
	; Augment the ID by the string in the DTA.
	; 
	; 10/7/93: added a hack to check for . so getting the ID of a standard
	; path in GeoManager doesn't yield a bogus and totally random ID based
	; on what was in the FFD from before (well, now based on adding a . to
	; the current path ID) -- ardeb
	;
if _MS7
		lds	si, ds:[FGEAD_fd]
		call	DOS7GetIDFromFD
else
		lds	si, ds:[FGEAD_dta]
		add	si, offset FFD_name
		cmp	{word}ds:[si], '.' or (0 shl 8)
		je	haveID
		call	DOSFileChangeCalculateIDLow
haveID:
endif
		mov_tr	ax, dx
		pop	dx, si, ds
		jmp	eaFIDStore

getCurPathID:
	;
	; Get the ID for the current dir first, since caller wasn't kind
	; enough to pass it to us.
	; 
		call	DOSFileChangeGetCurPathID
		movdw	ds:[FGEAD_spec].FGEASD_enum.FED_baseID, cxdx
		ornf	ds:[FGEAD_flags], mask FGEAF_HAVE_BASE_ID
		jmp	addDTAID

DOSVirtGetAttrFileID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAttrDriveStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch drive status

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:		DS - FileGetExtAttrData segment
		es:di - buffer to store data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetAttrDriveStatus	proc near

		.enter
		mov	bx, ds:[FGEAD_disk]
		call	DiskGetDrive
		call	DriveGetExtStatus
		stosw

		.leave
		ret
DOSVirtGetAttrDriveStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAttrDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch disk status

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:		DS - FileGetExtAttrData segment
		es:di - buffer to store data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/92   	Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetAttrDisk	proc near
		.enter
		mov	ax, ds:[FGEAD_disk]
		stosw
		.leave
		ret
DOSVirtGetAttrDisk	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAttrPathInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	fetch the DirPathInfo

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:		es:di = place to store result
		ds:si = FileExtAttrDesc
		bx 	= attr * 2
		al	= FileGetExtAttrFlags

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetAttrPathInfo	proc near
		mov	ax, ds:[FGEAD_pathInfo]
		tst	ax
		jnz	eaPIStore
		mov	ax, ERROR_ATTR_NOT_FOUND
		jmp	DOSVirtGetAttrSetError
eaPIStore:
		stosw

		ret
DOSVirtGetAttrPathInfo	endp

		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtPointToFileDesc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point to the FileDesc (DRI) or SFTEntry (MS) for the
		open file handle whose attributes are being fetched.

CALLED BY:	DOSVirtGetExtAttrsProcessLoop

PASS:	 	ss:bp	= stack frame

RETURN:	 	es:di	= FileDesc

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtPointToFileDesc	proc near
		.enter

		segmov	es, dgroup, bx
	    	call	fetchSFNTimes2
DRI <		les	di, es:[handleTable]				>
DRI <		mov	di, es:[di][bx]					>
DRI <		mov	di, es:[di].FH_desc				>

MS <		xchg	ax, bx						>
MS <		shr	ax						>
MS <		call	DOSPointToSFTEntry				>
MS <		xchg	ax, bx						>

		.leave
		ret


	;--------------------
fetchSFNTimes2:
	;
	; Utility routine to fetch the SFN for the file handle and multiply
	; it by 2 for a number of nefarious purposes.
	;
	; Pass:		es		= dgroup
	; 		ds:[FGEAD_spec].FGEASD_handle.FHGEAD_fileHandle
	;				= set to DOS handle
	; Return:	bx		= file's SFN * 2
	; 
		push	es
		les	bx, es:[jftAddr]
		add	bx, ds:[FGEAD_fileHandle]
		mov	bl, es:[bx]
		clr	bh
		shl	bx
		pop	es
		retn

DOSVirtPointToFileDesc	endp




;
; Various definitions for DOSVertSetExtAttrs...
; 
EAMasks	record
    ; these are separate from the header, but must wait until the file
    ; has been opened, so...
    EAM_FILE_ATTR:1
    EAM_MODTIME:1

    EAM_DESKTOP:1
    EAM_PASSWORD:1
    EAM_CREATED:1
    EAM_NOTICE:1
    EAM_USER_NOTES:1
    EAM_CREATOR:1
    EAM_TOKEN:1
    EAM_PROTOCOL:1
    EAM_RELEASE:1
    EAM_FLAGS:1
    EAM_FILE_TYPE:1
    EAM_LONGNAME:1
    EAM_SIGNATURE:1
EAMasks	end
eaVirtAttrMaskTable EAMasks \
	0,					; FEA_MODIFICATION (not used)
	0,					; FEA_FILE_ATTR (n.u.)
	0,					; FEA_SIZE (n.u.)
	mask EAM_FILE_TYPE,			; FEA_FILE_TYPE
	mask EAM_FLAGS,				; FEA_FLAGS
	mask EAM_RELEASE,			; FEA_RELEASE
	mask EAM_PROTOCOL,			; FEA_PROTOCOL
	mask EAM_TOKEN,				; FEA_TOKEN
	mask EAM_CREATOR,			; FEA_CREATOR
	mask EAM_USER_NOTES,			; FEA_USER_NOTES
	mask EAM_NOTICE,			; FEA_NOTICE
	mask EAM_CREATED,			; FEA_CREATION
	mask EAM_PASSWORD,			; FEA_PASSWORD
	0,					; FEA_CUSTOM (n.u.)
	mask EAM_LONGNAME,			; FEA_NAME
	0,					; FEA_GEODE_ATTR (n.u.)
	0,					; FEA_PATH_INFO (n.u.)
	0,					; FEA_FILE_ID (n.u.)
	mask EAM_DESKTOP,			; FEA_DESKTOP_INFO
	0,					; FEA_DRIVE_STATUS (n.u.)
	0,					; FEA_DISK (n.u.)
	0,					; FEA_DOS_NAME (n.u.)
	0,					; FEA_OWNER (n.u.)
	0,					; FEA_RIGHTS (n.u.)
	0					; FEA_TARGET_FILE_ID (n.u)
CheckHack <length eaVirtAttrMaskTable eq FEA_LAST_VALID+1>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtSetExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the extended attributes for a file.
		Can only set FEA_FILE_ATTR if passed the NAME, not the
		HANDLE of the file

CALLED BY:	DOSPathOp, DOSHandleOp
PASS:		bx	= file handle, unless dx is zero
		ax	= FileExtendedAttribute
		es:di	= buffer in which to place results, or array of
			  FileExtAttrDesc structures, if ax is FEA_MULTIPLE
		cx	= size of said buffer, or # of entries in buffer if
			  ax is FEA_MULTIPLE
		dx	= DOSFileEntry offset if file already open.
			= 0 if given a path, not an open file (=>
			  dosNativeFFD and dosFinalComponent contain
			  suitable information)
		si	= disk on which file/name is located
RETURN:		carry set on error:
			ax	= error code
		carry clear on success
			ax	= destroyed
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DOSVirtSetExtAttrs proc	far
fileHandle	local	hptr	push bx
privData	local	word	push dx
disk		local	word	push si
newHeader	local	GeosFileHeader
newModTime	local	FileDateAndTime
newFileAttr	local	FileAttrs	; in case FA_RDONLY being set
newFieldsMask	local	EAMasks
singleAttr	local	FileExtAttrDesc
errorCode	local	FileError
if _MS7
newCreateTime	local	FileDateAndTime
endif
ForceRef	fileHandle	; DOSVirtWriteChangedExtAttrs
ForceRef	pathBuffer
ForceRef	newCreateTime
		uses	es, di, ds, si, bx, cx
		.enter

		mov	ss:[errorCode], 0	; assume all is peachy
		mov	ss:[newFieldsMask], 0	; no header fields changed yet
		mov	ss:[newFileAttr], -1	; assume file attrs not set
if _MS7
	;
	; If we're working with a handle, then we need to map the file name
	; from the geos file header, before the attrs change.  If the name
	; happens to be out of sync with the header, we'd be hosed.
	;
		tst	ss:[privData]
		jz	testMultipleAttrs

		call	DOS7MapFileNameFromHandle
		
testMultipleAttrs:
endif		
		cmp	ax, FEA_MULTIPLE
		je	haveAttrArray
	;
	; It's easiest to work with an array of descriptors always, so if
	; a single attribute is being asked for, stuff it into our local frame
	; and point ds:si at that one attribute...
	; 
EC <		cmp	ax, FEA_CUSTOM					>
EC <		ERROR_E	CUSTOM_ATTRIBUTES_MUST_BE_PASSED_AS_FEA_MULTIPLE>
		mov	ss:[singleAttr].FEAD_attr, ax
		mov	ss:[singleAttr].FEAD_value.segment, es
		mov	ss:[singleAttr].FEAD_value.offset, di
		mov	ss:[singleAttr].FEAD_size, cx
		segmov	es, ss
		lea	di, ss:[singleAttr]
		mov	cx, 1
haveAttrArray:
		push	es, di, cx
		mov	bx, es:[di].FEAD_attr
EC <		cmp	bx, FEA_LAST_VALID				>
EC <		ERROR_A	ILLEGAL_EXTENDED_ATTRIBUTE			>
		mov	cx, es:[di].FEAD_size
		tst	ch
	LONG 	jnz	sizeError
		cmp	cl, cs:[setAttrSizeTable][bx]
		LONG	ja	sizeError
sizeOK::
		shl	bx
		lds	si, es:[di].FEAD_value
		; pass:
		; 	ds:si	= FEAD_value
		; 	cx	= FEAD_size
		; 	bx	= FEAD_attr * 2
		; 	es:di	= FileExtAttrDesc
		; return:
		; 	nothing
		; nuke:
		; 	ds, si, cx, bx, ax, dx, es, di
		call	cs:[setAttrRoutTable][bx]
nextAttr:
		pop	es, di, cx
		add	di, size FileExtAttrDesc
		loop	haveAttrArray
		
	;
	; Here's where we write out portions of the header that have been
	; modified. (routine is defined below, contrary to normal coding
	; conventions I follow, to avoid problems with premature local
	; variable inheritance).
	; 
		tst	ss:[newFieldsMask]	; if anything still needs
						;  changing, do it
		jnz	changeThem
		
		; apparently nothing has changed. see if we might have
		; pre-emptively set attributes so as to clear FA_RDONLY
		
		test	ss:[newFileAttr], mask FA_RDONLY
		jnz	fetchErrorCode		; => didn't set file attrs,
						;  either, so Lord knows
						;  what we're doing here
		jmp	generateNotify		; => set file attrs already,
						;  so generate appropriate
						;  notification
changeThem:
		call	DOSVirtWriteChangedExtAttrs
		jc	fetchErrorCode
	;
	; If need to set file attrs (FA_RDONLY being set), do so now.
	; 
		call	ExtAttrs_LoadVarSegDS

		test	ss:[newFieldsMask], mask EAM_FILE_ATTR
		jz	generateNotify

if _MS7
		mov	dx, offset dos7FindData.W32FD_fileName.MSD7GN_longName
else
		mov	dx, offset dosNativeFFD.FFD_name ; ds:dx <- name
endif
		mov	cl, ss:[newFileAttr]
		clr	ch				; cx <- attrs
if _MS7
		mov	ax, MSDOS7F_GET_SET_ATTRIBUTES
		mov	bl, MSD7FAA_SET_SPECIFIED_ATTRS	
else
		mov	ax, (MSDOS_GET_SET_ATTRIBUTES shl 8) or 1
endif
		call	DOSUtilInt21
		jnc	generateNotify
		mov	ss:[errorCode], ax
generateNotify:
		mov	ax, FCNT_ATTRIBUTES
	;
	; Generate notification.
	; 
		mov	si, ss:[disk]
		mov	bx, ss:[privData]
		tst	bx
		jnz	generateNotifyForHandle
		call	DOSFileChangeGenerateNotifyForNativeFFD
		jmp	notifyDone

generateNotifyForHandle:
		movdw	cxdx, ds:[bx].DFE_id
		call	FSDGenerateNotify
notifyDone:
		clc		
fetchErrorCode:
	;
	; Fetch any error we're to return, and set carry if there is one...
	; 
		mov	ax, ss:[errorCode]
		tst	ax
		jz	done
		stc
done:
		.leave
		ret
		
sizeError:
		mov	ax, ERROR_ATTR_SIZE_MISMATCH
		cmp	cs:[setAttrSizeTable][bx], 0
		jne	setSizeError
		mov	ax, ERROR_ATTR_CANNOT_BE_SET
setSizeError:
		mov	ss:[errorCode], ax
		jmp	nextAttr

; 0 => attribute cannot be set
setAttrSizeTable byte	size FileDateAndTime,	; FEA_MODIFIED
			size FileAttrs,		; FEA_FILE_ATTR
			0,			; FEA_SIZE
			size GeosFileType,	; FEA_FILE_TYPE
			size GeosFileHeaderFlags,; FEA_FLAGS
			size ReleaseNumber,	; FEA_RELEASE
			size ProtocolNumber,	; FEA_PROTOCOL
			size GeodeToken,	; FEA_TOKEN
			size GeodeToken,	; FEA_CREATOR
			size FileUserNotes,	; FEA_USER_NOTES
			size FileCopyrightNotice,; FEA_NOTICE
			size FileDateAndTime,	; FEA_CREATED
			size FilePassword,	; FEA_PASSWORD
			0,			; FEA_CUSTOM
			size FileLongName,	; FEA_NAME
			0,			; FEA_GEODE_ATTR
			0,			; FEA_PATH_INFO
			0,			; FEA_FILE_ID
			size FileDesktopInfo,	; FEA_DESKTOP_INFO
			0,			; FEA_DRIVE_STATUS
			0,			; FEA_DISK
			0,			; FEA_DOS_NAME
			0,			; FEA_OWNER
			0,			; FEA_RIGHTS
			0			; FEA_TARGET_FILE_ID

.assert (length setAttrSizeTable) eq (FEA_LAST_VALID+1)

setAttrRoutTable	nptr	eaModified,		; FEA_MODIFICATION
			eaFileAttr,		; FEA_FILE_ATTR
			eaCannotSet,		; FEA_SIZE
			eaVirtual,		; FEA_FILE_TYPE
			eaFlags,		; FEA_FLAGS
			eaVirtual,		; FEA_RELEASE
			eaVirtual,		; FEA_PROTOCOL
			eaVirtual,		; FEA_TOKEN
			eaVirtual,		; FEA_CREATOR
			eaVirtual,		; FEA_USER_NOTES
			eaVirtual,		; FEA_NOTICE
			eaVirtual,		; FEA_CREATION
			eaVirtual,		; FEA_PASSWORD
			eaUnsupported,		; FEA_CUSTOM
			eaVirtual,		; FEA_NAME
			eaCannotSet,		; FEA_GEODE_ATTR
			eaCannotSet,		; FEA_PATH_INFO
			eaCannotSet,		; FEA_FILE_ID
			eaVirtual,		; FEA_DESKTOP_INFO
			eaCannotSet,		; FEA_DRIVE_STATUS
			eaCannotSet,		; FEA_DISK
			eaCannotSet,		; FEA_DOS_NAME
			eaUnsupported,		; FEA_OWNER
			eaUnsupported,		; FEA_RIGHTS
			eaUnsupported		; FEA_TARGET_FILE_ID
CheckHack <length setAttrRoutTable eq FEA_LAST_VALID+1>

	;--------------------
eaModified:
	;
	; Record the time & date and set EAM_MODTIME
	; 
		lodsw			; ax <- date
		mov	ss:[newModTime].FDAT_date, ax
		lodsw			; ax <- time
		mov	ss:[newModTime].FDAT_time, ax
		ornf	ss:[newFieldsMask], mask EAM_MODTIME
		retn
	;--------------------
eaFileAttr:
	;
	; Can only set if given a name, not a handle. if given a name, and
	; FA_RDONLY is clear, make the call now, as we might need the thing
	; read/write to set other attrs. If given a name and FA_RDONLY is
	; set, delay the call until after the file is closed in
	; DOSVirtWriteChangedExtAttrs, in case file is becoming read-only.
	; 
		tst	ss:[privData]
		jnz	eaCannotSet

	;
	; Clear out FA_SUBDIR and FA_LINK, as we might have gotten
	; these from copying extended attributes from a directory
	;
		lodsb			; al <- FileAttrs
		andnf	al, not (mask FA_SUBDIR or mask FA_LINK)

EC <		test	al, not (mask FA_RDONLY or mask FA_HIDDEN or \
   				mask FA_SYSTEM or mask FA_ARCHIVE)	>
EC <		ERROR_NZ	INVALID_ATTRIBUTES_FOR_FEA_FILE_ATTR	>

		mov	ss:[newFileAttr], al	; always store, so at the end,
						;  if FA_RDONLY clear here,
						;  we know we set file attrs
						;  and we generate notification

		test	al, mask FA_RDONLY
		jz	eaFASetNow
		ornf	ss:[newFieldsMask], mask EAM_FILE_ATTR
		jmp	eaFADone

eaFASetNow:
		mov	cx, ax
		clr	ch
if _MS7
		mov	ax, MSDOS7F_GET_SET_ATTRIBUTES
		mov	bl, MSD7FAA_SET_SPECIFIED_ATTRS
		mov	dx, offset dos7FindData.W32FD_fileName.MSD7GN_longName 
else		
		mov	ax, (MSDOS_GET_SET_ATTRIBUTES shl 8) or 1
		mov	dx, offset dosNativeFFD.FFD_name
endif
		call	ExtAttrs_LoadVarSegDS
		call	DOSUtilInt21
eaFADone:
		retn

	;--------------------
eaCannotSet:
		mov	ss:[errorCode], ERROR_ATTR_CANNOT_BE_SET
		retn
	;--------------------
eaUnsupported:
	; pass:
	; 	ds:si	= FEAD_value
	; 	cx	= FEAD_size
	; 	bx	= FEAD_attr * 2
	; 	es:di	= FileExtAttrDesc
	; return:
	; 	nothing
	; nuke:
	; 	ds, si, cx, bx, ax, dx, es, di
	;
		segmov	ds, es
		mov	si, di
		mov	bx, ss:[disk]

		mov	ax, dgroup	; assume have name
		mov	dx, offset dosNativeFFD.FFD_name
		tst	ss:[privData]
		jz	eaUnsupCallSecondary
		clr	ax
		mov	dx, ss:[fileHandle]
eaUnsupCallSecondary:
		mov	di, DR_DSFS_SET_EXT_ATTRIBUTE
		call	DOSVirtCallSecondary
		jnc	eaUnsupDone
		mov	ss:[errorCode], ax
eaUnsupDone:
		retn
	;--------------------
eaFlags:
if DBCS_PCGEOS
		call	eaVirtual
		or	ss:[newHeader].GFH_flags, mask GFHF_DBCS
		retn
else
		;fall thru to eaVirtual
endif
	;--------------------
eaVirtual:
		push	es, di
		segmov	es, ss
		lea	di, ss:[newHeader]
		add	di, cs:[eaVirtAttrOffsetTable][bx]
		rep	movsb
		pop	es, di
		mov	ax, cs:[eaVirtAttrMaskTable][bx]
		or	ss:[newFieldsMask], ax
		retn
		

		

DOSVirtSetExtAttrs endp


;
; Table of sizes of header fields in order from start of GeosFileHeader,
; which order is also reflected in the EAMasks record.
; 
eaHeaderSizes	word	size GFH_signature,
			size GFH_longName,
			size GFH_type,
			size GFH_flags,
			size GFH_release,
			size GFH_protocol,
			size GFH_token,
			size GFH_creator,
			size GFH_userNotes,
			size GFH_notice,
			size GFH_created,
			size GFH_password,
			size GFH_desktop

_curMask = 1

EACheckField	macro	cur, msk, prev
ifnb <prev>
.assert GFH_&cur eq GFH_&prev + size GFH_&prev
endif
.assert mask EAM_&msk eq _curMask

_curMask = _curMask shl 1
		endm

EACheckField	signature, SIGNATURE
EACheckField	longName, LONGNAME, signature
EACheckField	type, FILE_TYPE, longName
EACheckField	flags, FLAGS, type
EACheckField	release, RELEASE, flags
EACheckField	protocol, PROTOCOL, release
EACheckField	token, TOKEN, protocol
EACheckField	creator, CREATOR, token
EACheckField	userNotes, USER_NOTES, creator
EACheckField	notice, NOTICE, userNotes
EACheckField	created, CREATED, notice
EACheckField	password, PASSWORD, created
EACheckField	desktop, DESKTOP, password



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtWriteChangedExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write those extended attributes to the file that were
		actually changed, doing so as optimally as possible, of course.

CALLED BY:	DOSVirtSetExtAttrs
PASS:		ss:bp	= inherited frame
RETURN:		bx	= DOS handle of destination file
		JFT slot still allocated if file was opened here 
			(ss:[privData] is non-zero)

DESTROYED:	ax, cx, dx, ds, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%b%%%%%%%%%%%%%%%%@
DOSVirtWriteChangedExtAttrs proc near
		.enter	inherit	DOSVirtSetExtAttrs

		mov	bx, ss:[fileHandle]	; assume have file handle

		tst	ss:[privData]
		LONG jnz verifyHandleIsGeos	; assumption correct

	;--------------------
	; WRITE TO NAMED FILE
	;
	; Open the file whose name is in dosNativeFFD. We open it for both
	; reading and writing so we can make sure it actually has a header
	; before we write to it...
	; 
		mov	bx, NIL
		call	DOSAllocDosHandleFar	; allocate a JFT slot

		call	ExtAttrs_LoadVarSegDS
		mov	al, FA_READ_WRITE
if _MS7
		test	ds:[dos7FindData].W32FD_fileAttrs.low.low, \
						mask FA_SUBDIR
else
		test	ds:[dosNativeFFD].FFD_attributes, mask FA_SUBDIR
endif
		jz	openNamedFile

if _MS7
		mov	dx, offset dos7FindData
else
		mov	dx, offset dosNativeFFD
endif
		call	DOSVirtOpenSpecialDirectoryFile
		jnc	openedOK
	;
	; If the special directory file doesn't exist, then create it
	; (but only if setting the non-DOS attributes)
	;
		test	ss:[newFieldsMask], not (mask EAM_MODTIME or \
					mask EAM_FILE_ATTR)

		LONG jz	freeDOSHandle

		mov	si, ss:[disk]
		call	DOSVirtCreateDirectoryFile
		jmp	checkOpenResult
		
openNamedFile:
if _MS7
		mov	dx, offset dos7FindData.W32FD_fileName.MSD7GN_longName
else
		mov	dx, offset dosNativeFFD.FFD_name
endif
		call	DOSUtilOpenFar
checkOpenResult:
		jc	couldNotOpen

openedOK:
	;
	; Verify the thing's a geos file if any bit but EAM_MODTIME is set
	; in newFieldsMask
	; 
		mov_tr	bx, ax		; bx <- file handle
		test	ss:[newFieldsMask], not (mask EAM_MODTIME or \
						mask EAM_FILE_ATTR)
		jz	writeAttrsWithHandle
		
		mov	dx, offset dosOpenHeader
if DBCS_PCGEOS
		mov	cx, size dosOpenHeader + \
					size dosOpenType + size dosOpenFlags
else
		mov	cx, size dosOpenHeader
endif
		mov	ah, MSDOS_READ_FILE
		call	DOSUtilInt21
		cmp	ax, cx
		je	checkSignature
notGeosFile:
		mov	ss:[errorCode], ERROR_ATTR_NOT_FOUND
		andnf	ss:[newFieldsMask], mask EAM_MODTIME or \
					    mask EAM_FILE_ATTR
		jmp	writeAttrsWithHandle
checkSignature:
		cmp	{word}ds:[dosOpenHeader].GPH_signature[0],
			GFH_SIG_1_2
		jne	notGeosFile
		cmp	{word}ds:[dosOpenHeader].GPH_signature[2],
			GFH_SIG_3_4
		jne	notGeosFile
if DBCS_PCGEOS
		test	ds:[dosOpenFlags], mask GFHF_DBCS
		jz	notGeosFile
endif
		jmp	writeAttrsWithHandle

	;--------------------
couldNotWrite:
	;
	; File was opened, but we had trouble writing to it, so close the
	; file, if doing stuff to a path, then store and return the error code.
	; 
		tst	ss:[privData]
		jnz	storeErrorCode		; => nothing to close, no JFT
						;  slot to free
		
		push	ax			; save error code
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
		pop	ax

couldNotOpen:
		push	ax			; save error code
		mov	bx, NIL
		call	DOSFreeDosHandleFar
		pop	ax

storeErrorCode:
		mov	ss:[errorCode], ax
		stc
		jmp	done

	;-----------------------
	; WRITE TO PASSED HANDLE
verifyHandleIsGeos:
	;
	; If setting any geos-specific attributes, make sure the file handle
	; is a geos file.
	; 
		test	ss:[newFieldsMask], not (mask EAM_MODTIME or \
						 mask EAM_FILE_ATTR)
		jz	writeAttrsWithHandle	; => doesn't matter

		call	ExtAttrs_LoadVarSegDS
		mov	di, ss:[privData]
		test	ds:[di].DFE_flags, mask DFF_GEOS
		jz	notGeosFile

	;--------------------
	; COMMON CODE
writeAttrsWithHandle:
	;
	; Preserve current file position (for handle case).
	; 
		clrdw	cxdx
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_RELATIVE
		call	DOSUtilInt21
		push	dx, ax
	;
	; For this loop, we've got a number of things in the air:
	; 	dx	= absolute offset in the file for the start of the
	;		  next range to write. This is also the offset
	;		  into newHeader from which to write.
	;	cx	= the number of bytes to write in the next range.
	;		  this is 0 if we've not found a field we need to
	;		  write yet and increased with each field that's
	;		  been modified.
	;	di	= mask of fields left to write.
	;	ax	= size of the current field
	;	cs:si	= pointer into eaHeaderSizes array for current
	;		  field.
	;
	; The strategy is simple:
	; 	- advance the start position by the size of each unchanged
	;	  field until we find a changed field.
	;	- when we find a changed field, we add its size into cx
	;	  and keep doing so for each successive field until we find
	;	  one that hasn't changed.
	;	- when we find a field that hasn't changed, if cx is non-zero
	;	  then position the file and write cx bytes from offset
	;	  dx in the header to the file, advancing dx by cx bytes when
	;	  the write completes.
	;	- only when we find a field hasn't changed do we need to
	;	  check to see if we've written everything.
	;
		clr	cx		; flag no bytes to write yet
		mov	dx, cx
		mov	di, ss:[newFieldsMask]
		andnf	di, not (mask EAM_MODTIME or mask EAM_FILE_ATTR)
		mov	si, offset eaHeaderSizes
		segmov	ds, ss
figureWriteLoop:
		lodsw	cs:		; ax <- size of this field
		shr	di		; shift changed flag into CF
		jnc	noChange

		add	cx, ax		; field changed, so add size to
					;  # bytes to write next time
		jmp	figureWriteLoop
noChange:
		jcxz	adjustStart	; => no bytes need writing, so just
					;  adjust dx

		push	ax, dx, cx

positionFile::
	    ;
	    ; Position the file at the start of the range we're going to write.
	    ; 
		clr	cx
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21
	    ;
	    ; Point ds:dx to the proper location in the header and write CX
	    ; bytes to the file.
	    ; 
		lea	ax, ss:[newHeader]
		pop	dx, cx		; dx <- offset into header
					; cx <- # bytes to write
		push	dx		; save offset again
		add	dx, ax		; ds:dx <- buffer
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21
		LONG	jc	writeError
		cmp	ax, cx
		LONG	jne	shortWrite
	    ;
	    ; Adjust the starting position by the amount just written.
	    ;
		pop	ax, dx		; ax <- field size, dx <- header offset
		add	dx, cx
		clr	cx		; => no bytes accumulated
adjustStart:
	    ;
	    ; Adjust the starting position by the size of the unchanged field
	    ; and loop if there are more fields to write.
	    ; 
		add	dx, ax
		tst	di
		jnz	figureWriteLoop
	;
	; Deal with the modification time last, if such there be, now we've
	; done the writing we're going to do.
	;
		test	ss:[newFieldsMask], mask EAM_MODTIME
if _MS7
		jz	tryCreateTime
else
		jz	rePos
endif
		mov	ax, (MSDOS_GET_SET_DATE shl 8) or 1
		mov	cx, ss:[newModTime].FDAT_time
		mov	dx, ss:[newModTime].FDAT_date
		call	DOSUtilInt21
		LONG	jc	setDateError
if _MS7
tryCreateTime:
				
		test	ss:[newFieldsMask], mask EAM_CREATED
		jz	rePos

		mov	ax, MSDOS7F_SET_CREATION_DATE_AND_TIME
		lea	si, ss:[newHeader]
		add	si, offset GFH_created
		mov	cx, ss:[si].FDAT_time
		mov	dx, ss:[si].FDAT_date
		clr	si
		call	DOSUtilInt21
		LONG	jc	setDateError
endif		
rePos:
	;
	; Reposition the file to its previous read/write position.
	;
		pop	cx, dx
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21
	;
	; All changes now written. Commit or close the file, as appropriate.
	; 
		mov	ah, MSDOS_CLOSE_FILE
		tst	ss:[privData]
		jz	commitChanges
		mov	ah, MSDOS_COMMIT
commitChanges:
		call	DOSUtilInt21

if _MS7
	;
	; TEMPORARY : we can't yet rename files while they
	; are still open.  Must close before rename.
	;
		push	ax			; might need to reopen
		cmp	ah, MSDOS_COMMIT
		call	ExtAttrs_LoadVarSegDS		
		jne	reName
	;
	; Some DOSs can rename while the file is open and some can't.
	; Consult the dgroup flags to see which one we're using.  This
	; flag was set during MSInit based on an ini setting.
	;
		cmp	ds:[dos7RenameWhileOpen], TRUE
		je	reName

		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
		mov	bx, -1
		call	DOSFreeDosHandleFar
reName:
	;
	; Rename the file.  Returns ds:dx <- new name.  Don't rename
	; directories.
	;
		mov	dx, offset dos7FindData.W32FD_fileName
		test	ds:[dos7FindData].W32FD_fileAttrs.low.low, \
							mask FA_SUBDIR
		jnz	afterRename
		segmov	es, ss
		lea	di, ss:[newHeader]		; es:di <- geos header
		mov	ax, ss:[newFieldsMask]		; ax <- change mask
		call	DOS7RenameFileFromGeosHeader
afterRename:
	;
	; If we were working with a path, or if the DOS we're working with
	; can rename while open, then we don't need to reopen now.
	;
		pop	ax
		cmp	ah, MSDOS_COMMIT
		jne	afterReOpen

		cmp	ds:[dos7RenameWhileOpen], TRUE
		je	afterReOpen
	;
	; Re open the file.  ds:dx is the complete new long name.
	; bx is a dos handle for the file if we renamed while open.
	; 
		mov	si, dx		; ds:si <- complex long name
		mov	ax, MSDOS7F_CREATE_OR_OPEN
		mov	bx, FILE_ACCESS_RW
		mov	dx, MSDOS7COOA_OPEN
		clr	cx, di
		mov	ax, MSDOS7F_CREATE_OR_OPEN
		call	DOSUtilInt21

EC <		ERROR_C	MSDOS7_CANNOT_REOPEN_FILE_AFTER_ATTR_RENAME	>
		
EC <		cmp	ax, ss:[fileHandle]
EC <		WARNING_NE MSDOS7_DOS_HANDLES_DONT_MATCH		>

		mov	ss:[fileHandle], ax
		mov	bx, ax
		
afterReOpen:
endif	
	;
	; Free the JFT slot, if we allocated one.
	; 
		tst	ss:[privData]
		jnz	done			; (carry clear)

freeDOSHandle:		
		mov	bx, NIL
		call	DOSFreeDosHandleFar
	;
	; All done.
	; 
done:
		.leave
		ret


shortWrite:
		mov	ax, ERROR_SHORT_READ_WRITE
writeError:
		pop	dx
		inc	sp
		inc	sp
setDateError:
	;
	; Restore read/write position for the file.
	; 
		pop	cx, dx
		push	ax
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21
		pop	ax
	;
	; Return the appropriate error code.
	; 
		jmp	couldNotWrite

DOSVirtWriteChangedExtAttrs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7MapFileNameFromHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up dos7FindData to hold the complete filename
		of the passed DOS handle.  That is, read the long name
		from the header and map it.

CALLED BY:	DOSVirtSetExtAttrs

PASS:		bp	= stack frame from DOSVirtSetExtAttrs
RETURN:		dos7FindData filled in or
		carry set if failure

DESTROYED:	ds

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/22/97    	Initial versin

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7MapFileNameFromHandle	proc	far
		uses	ax, cx, dx, es, di
		.enter inherit DOSVirtSetExtAttrs
	;		
	;	1)	Get the SFN for the JFT in bx
	;	2) 	Get the path for the SFN
	;	3) 	Set the CWD to be that path
	;	4) 	Map the long name from the GeosFileHeader in 
	; 		the file, which results in dos7FindData filled
	;	5) 	Rename the pup (close/rename/open for now)
	; 	6) 	fix up jft references
	;
	; Get the SFN for this file.
	;
		call	ExtAttrs_LoadVarSegDS		; ds<- dgroup
		mov	bx, ss:[fileHandle]
		call	DOSFreeDosHandleFar		; bl <- sfn
		clr	bh				; bx <- sfn
	;	
	; Get the path associated with this file; es:di will be
	; the path string.  We set up with C:\ to start with
	;
		mov	ah, MSDOS_GET_DEFAULT_DRIVE
		call	DOSUtilInt21
EC <		cmp	al, 2						>
EC <		WARNING_NE MSDOS7_DEFAULT_DRIVE_NOT_C			>
EC <		mov	ax, 2						>
		add	al, 'A'
		clr	ah
		segmov	es, ds
		mov	di, offset dosPathBuffer	; es:di <- path buffer
		stosb
		mov	al, ':'
		stosb
		mov	al, '\\'
		stosb				
		call	DOS7GetPathForSFN
		dec	di
		dec	di
		dec	di			; es:di <- C:\yada yada
	;
	; Set DOS's CWD.  ds = es = dgroup
	;
		mov	dx, di				; ds:dx <- path
		mov	ax, MSDOS7F_SET_CURRENT_DIR
		call	DOSUtilInt21
EC <		ERROR_C	MSDOS7_CANT_CHANGE_DIR_FOR_RENAME		>
	;
	; Map the long name from the geos file header.
	;
		call	DOSAllocDosHandleFar	; bl <- dos handle (JFT)
EC <		clr	bh						>
EC <		cmp	bx, ss:[fileHandle]				>
EC <		WARNING_NE MSDOS7_DOS_HANDLES_DONT_MATCH		>
	;		
	; Point to the long name in the file.
	;
		clr	cx
		mov	dx, size GFH_signature
		mov	ax,(MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21
	;
	; Read in the long name.		ds= es = dgroup.
	;
		mov	cx, size FileLongName		
		mov	dx, offset  dosPathBuffer
		mov	ah, MSDOS_READ_FILE
		call	DOSUtilInt21
EC <		ERROR_C	MSDOS7_CANT_READ_GEOS_FILE_HEADER	>
NEC <		jc	done
	;
	; Map the name.	
	;
		mov	di, offset dosPathBuffer
		call	DOS7UnPadLongName
		clr	cx
		call	DOS7MapComponentFar
EC <		ERROR_C MSDOS7_CANT_MAP_COMPONENT_FROM_FILE_HEADER	>
NEC < done:								>

		segmov	ds, es				; ds <- dgroup
		
		.leave
		ret
DOS7MapFileNameFromHandle	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAllExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load all the attributes that we know about into a buffer

CALLED BY:	DOSHandleOp
PASS:		bx	= DOS handle
		bp	= DOSFileEntry for the file

RETURN:		carry set if error:
			ax	= error code
		carry clear if ok
			ax	= handle of locked block holding array
				  of FileExtAttrDesc structures at its
				  beginning
			cx	= number entries in the array
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dosvceaAllAttrs	FileExtAttrDesc \
    <FEA_MODIFICATION,	DOSAA_modified,			size DOSAA_modified>,
    <FEA_FILE_ATTR, 	DOSAA_fileAttr,			size DOSAA_fileAttr>,
    <FEA_FILE_TYPE,	DOSAA_header.GFH_type,		size GFH_type>,
    <FEA_FLAGS,		DOSAA_header.GFH_flags,		size GFH_flags>,
    <FEA_RELEASE,	DOSAA_header.GFH_release,	size GFH_release>,
    <FEA_PROTOCOL,	DOSAA_header.GFH_protocol,	size GFH_protocol>,
    <FEA_TOKEN,		DOSAA_header.GFH_token,		size GFH_token>,
    <FEA_CREATOR,	DOSAA_header.GFH_creator,	size GFH_creator>,
    <FEA_USER_NOTES,	DOSAA_header.GFH_userNotes,	size GFH_userNotes>,
    <FEA_NOTICE,	DOSAA_header.GFH_notice,	size GFH_notice>,
    <FEA_CREATION,	DOSAA_header.GFH_created,	size GFH_created>,
    <FEA_PASSWORD,	DOSAA_header.GFH_password,	size GFH_password>,
    <FEA_DESKTOP_INFO,	DOSAA_header.GFH_desktop,	size GFH_desktop>

DOS_NUM_ATTRS	equ	length dosvceaAllAttrs
DOS_NUM_NON_GEOS_ATTRS equ 2		; FEA_MODIFICATION and FEA_FILE_ATTR
					;  only... (first two in above
					;  array, of course)

DOSAllAttrs	struct
    DOSAA_attrs		FileExtAttrDesc	DOS_NUM_ATTRS dup(<>)
    DOSAA_header	GeosFileHeader
    DOSAA_modified	FileDateAndTime
    DOSAA_fileAttr	FileAttrs
DOSAllAttrs	ends

DOSVirtGetAllExtAttrs proc far
		uses	bx, dx, es, di, ds
		.enter

		push	bx		; DOS handle

		call	DOSVirtBuildBufferForAllAttrs

		jc	restoreBXexit			; mem full

	;
	; Call the common routine to fetch all the attributes at once.
	; 
		pop	ax
		push	bx			; save block handle
		mov_tr	bx, ax			; bx <- file handle
		mov	dx, bp			; dx <- private data for the
						;  file
		call	ExtAttrs_LoadVarSegDS
		mov	si, ds:[bp].DFE_disk	; si <- disk on which the file
						;  is located

		mov	ax, FEA_MULTIPLE
		call	DOSVirtGetExtAttrs
		pop	bx			; bx <- block handle

		call	DOSVirtGetAllAttrsCommon
exit:
		.leave
		ret
restoreBXexit:
		pop	bx
		jmp	exit

DOSVirtGetAllExtAttrs endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtGetAllAttrsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to handle error cases from in
		get-all-attributes routines

CALLED BY:	DOSVirtGetAllExtAttrs, DOSPathGetAllExtAttrs

PASS:		bx - mem handle of attribute buffer
		ax - return code from DOSVirtGetExtAttrs
		carry flag - returned from DOSVirtGetExtAttrs

RETURN:		if error:
			carry set
			ax = FileError
		else
			carry clear
			ax	= handle of locked block holding array
				  of FileExtAttrDesc structures at its
				  beginning
			cx	= number entries in the array

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtGetAllAttrsCommon	proc near

		mov	cx, length DOSAA_attrs	; assume all attributes there
		jnc	checkOldVM

		cmp	ax, ERROR_ATTR_NOT_FOUND; this is the only error we
						;  let go through, as it means
						;  the file ain't geos, and
						;  that's...ok.
		jne	error
	;
	; Not a geos file, so set only the non-geos attributes...
	; 
dosAttrsOnly:
		mov	cx, DOS_NUM_NON_GEOS_ATTRS
done:
	;
	; Leave the buffer locked so the FEAD_value segments remain valid
	; and return its handle and the number of attributes
	; 
		mov_tr	ax, bx
		clc				; signal success.
exit:
		ret

checkOldVM:
	;
	; Deal with old VM files, which appear to have all the attributes,
	; but don't actually.
	; 
		cmp	es:[DOSAA_header].GFH_type, GFT_OLD_VM
		jne	done
		jmp	dosAttrsOnly

error:
		call	MemFree
		stc
		jmp	exit

DOSVirtGetAllAttrsCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSVirtBuildBufferForAllAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and initialize a buffer big enough to hold all
		the attributes of a file

CALLED BY:	DOSVirtGetAllExtAttrs, DOSPathOpGetAllExtAttrs

PASS:		nothing 

RETURN:		If buffer successfully allocated:
			carry clear
			bx = handle
			es:di - fptr to array of FileExtAttrDesc structures
			cx = # of attributes in array
		else
			carry set
			ax = ERROR_INSUFFICIENT_MEMORY

DESTROYED:	dx,di,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSVirtBuildBufferForAllAttrs	proc near

		uses	ds, si

		.enter
	;
	; Allocate a buffer to hold all the attributes.
	; 
		mov	ax, size DOSAllAttrs
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jnc	haveBuffer
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	exit

haveBuffer:
	;
	; Copy in the array of attributes to get and set. Since we need the
	; array for setting things anyway, it's easiest just to set it up
	; and use our internal routine to fetch all the attributes, rather
	; than reading the header etc. ourselves.
	; 
		mov	es, ax
		mov	di, offset DOSAA_attrs
		segmov	ds, cs
		mov	si, offset dosvceaAllAttrs
		mov	cx, (size dosvceaAllAttrs)/2
			CheckHack <(size dosvceaAllAttrs and 1) eq 0>
		rep	movsw

	;
	; Now point all the FEAD_value.segments to the block (the .offsets
	; are set properly in the dosvceaAllAttrs array)
	; 
		mov	di, offset DOSAA_attrs
		mov	cx, length DOSAA_attrs
setSegmentLoop:
		mov	es:[di].FEAD_value.segment, es
		add	di, size FileExtAttrDesc
		loop	setSegmentLoop

		mov	di, offset DOSAA_attrs	; es:di <- list of attrs
		mov	cx, length DOSAA_attrs	; cx <- # of attrs to get
exit:
		.leave
		ret
DOSVirtBuildBufferForAllAttrs	endp


ExtAttrs	ends

