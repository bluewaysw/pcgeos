COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ResEdit
FILE:		documentImpExp.asm

AUTHOR:		Jonathan Magasin, Feb  8, 1995

ROUTINES:
	Name			Description
	----			-----------
	REDExport		Checks if chunk is: a text chunk an object 
				chunk an exportable chunk 
	DIEClearUnmappedChars	Clears out the UnmappedChars text object. 
	DIEGetImpExpFileNameAndPath	Gets the path and filename of the new 
				ascii translation file. 
	DIECreateExportFile	Creates a new DOS file, our export file. Also 
				sets the threads path. 
	DIECheckExportFileExists	Warns user if export file already 
				exists so that user can decide whether to 
				overwrite it. 
	DIEExportHeader		Exports header information to the ASCII 
				translation file. 
	DIEExportVersionData	Exports protocol number. 
	DIEExportBody		Exports the resources and chunks of the current 
				translation file. The resources and chunks make 
				up the body, while the header contains other 
				data, such as version info. 
	DIEExportChunkCallback	Callback routine for exporting a chunk to an 
				ASCII translation file. 
	DIECheckIfChangedChunk	If only modified chunks are supposed to be 
				exported, this routine will check if the passed 
				ResourceArrayElement is associated with a 
				modified chunk. 
	DIECheckMnemonicOrShortcutChanged	Checks if the mnemonic or 
				shortcut of the passed chunk (array element) 
				has been edited. 
	DIEExportShortcut	Exports the shortcut for the chunk (if any) to 
				the ASCII translation file. 
	DIEExportMnemonic	Export the mnemonic char (or keyword "esc" or 
				"nil"). 
	DIEExportLocalizeHints	Exports localization instructions, max, min and 
				type to ASCII translation file. 
	DIEExportChunkType	Writes the chunk type to the ASCII export file. 
	DIEFileWriteNumber	Converts the passed double word into an ASCII 
				string and writes it to the export file. 
	DIEExportResourceBegin	If appropriate, print the resource keyword and 
				name to the ASCII translation file. 
	DIEExportResourceName	Writes the resource's name to the ASCII 
				translation file. 
	DIEExportResourceEnd	If appropriate, exports the [endresrc] keyword 
				and resource name to the ASCII translation 
				file. 
	DIEExportKeyword	Exports a keyword to the passed file. 
	DIEExportChunkName	Copies the chunk name in the passed 
				ResourceArrayElement to the export file. 
	DIEExportText		Exports the original or translated text to the 
				ASCII translation file. Also exports 
				instruction text. 
	DIERecordUnmappedText	Writes text that could not be properly exported 
				or imported (due to unmappable Geos chars). 
	DIECallUnmappedChars	Call the UnmappedChars text object. 
	DIENotifyUserUnmappedChars	Notify the user if there were any 
				exported strings that had characters that could 
				not be mapped. 
	DIEGetStringLength	Calculates length of actual text portion of 
				chunk. 
	DIELocalStringSize	Returns string size of null-terminated string 
				at ds:si. 
	DIEEnumAllChunks	For each resource, enumerate all its chunks. 
	DIEEnumAllChunksCallback	Enumerate the chunks this 
				ResourceArray, calling passed callback for each 
				on. 
	DIEFileWrite		Writes the passed string to the export file. 
	DIEFileWriteChar	 
	DIEExportCRLF		Write a carriage return to the export file. 
	DIENotifyError		Tell the user that an error occurred. 
	REGDocumentControlImport	Initiate ASCII import. 
	REGDocumentControlOAIS	Analogous to handler for 
				MSG_GEN_DOCUMENT_CONTROL_ OPEN_IMPORT_SELECTED, 
				but we're not using the Impex library. Create a 
				new document, which will later be sent 
				MSG_RESEDIT_DOCUMENT_ASCII_IMPORT. 
	REGDocumentControlDisplayDialog	Causes document control to display the 
				new/open dialog. Delays delivery of 
				MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG a bit 
				to make sure it actually comes up. See Tony's 
				comments in cmainUIDocOperations.asm. 
	REDImport		Imports an ASCII translation file. 
	DIENotifyUserItemsMissing	If necessary, tell user about ATF 
				entries that the user wanted to import, but for 
				which there were no corresponding DB items. 
	DIEInitLocals		Initializes ImportBufferStruct local variable. 
	REFSNotifyText		Make either text1 or text2 be the selected file 
				name and toggle the state field. 
	DIEGetTextSize		Gets the number of characters in the ATF or loc 
				text object. 
	REITSetModifiedState	If passed cx says "you're modified," the text 
				then gets AsciiImportFileSelector's path, and 
				tells the other* text that it* is not modified. 
				*Other: If text is atf, then tell the loc. If 
				text is loc, then tell the atf. 
	DIEGetImportFileName	Gets the name of the localization file 
				associated with the ascii file being imported. 
	DIECheckIfImporting	Sets carry flag if the user is importing an 
				ASCII translation file. 
	DIEDoneImporting	We're done importing, so have the doc control 
				clear its flag. 
	REGDControlGetImportFlag	Returns import flag, which indicates 
				whether user is importing an ASCII translation 
				file right now. 
	REGDControlClrImportFlag	Clears the doc control's import flag. 
	DIEDisplayDialogAfterErrorIfNecessary	An error occured in 
				InitializeDocumentFile, so we might want to 
				display the new/open/import dialog. We will 
				want to if we were trying to import. 
	DIEOpenImportFile	Opens the ATF, our import file. Also sets the 
				threads path. 
	DIECheckImportHeader	Checks the header of the ATF for version 
				mismatch between ATF and localiztion file. 
	DIEApplyATF		Make the DB file agree with the ATF. Enumerate 
				the ATF, applying resource/chunk changes to the 
				DB of the passed document. 
	DIEGetNextResource	Gets the next resource in the ATF. 
	DIEApplyATFToChunks	Apply ATF to all chunks in the current 
				resource. 
	DIEGetNextChunk		Gets the next chunk in the ATF. 
	DIEApplyATFToTrans	Gets the translated text from the import buffer 
				and makes it the translated text for chunk 
				we're currently modifying with ATF changes 
				(this modified chunk exists in the DB file). 
	DIEApplyATFToMnemonic	Gets the mnemonic from the ATF and applies it 
				to its chunk. 
	DIEMakeMnemonicOffset	Figures out the mnemonic's offset. 
	DIEApplyATFToShortcut	Gets the shortcut from the ATF and applies it 
				to its chunk. 
	DIESaveNewShortcut	Saves the passed shortcut as the shortcut for 
				the passed ResourceArrayElement. 
	DIEGetShortcut		Gets the shortcut from the import buffer. 
	DIENullTermBuffer	Null terminates the passed buffer (NOT imp 
				buffer), and updates the position of that 
				buffer. 
	DIECopyTillChar		Reads everything from the current position 
				until the specified char (not including) into 
				the passed buffer. Source buffer is impBuffer, 
				and passed buffer is unfBuffer, resource or 
				chunk. 
	DIECopyTillCharLow	Copy characters from IBS_importBuffer to 
				specified destination buffer. 
	DIECopyCharToBuffer	If the char in ds:di is not the same as the 
				char passed in al (the stop char), then copy it 
				to the buffer. (Unless copying to unformatted 
				buffer, in which case we undouble doubled 
				braces -- there is no stop char in al.) 
	DIECheckOKForUnformatCopy	Determines whether the character in 
				ds:di can be copied to the unformatted buffer. 
	DIEGetPosAddr		Points bx to the correct position field in an 
				ImportBufferStruct for the passed BufferType. 
	DIEFindNextKeyword	Advances the buffer position to the character 
				immediately following the next instance of the 
				specified keyword. Make *sure* that you set the 
				IBS_buffStatus flags the way you want them 
				before calling this routine. Every call will 
				want at least IBF_NOT_IN_TEXT. DON'T use this 
				for the keywords "null" and "esc" because they 
				don't have leading ['s. 
	DIECheckIfKeywordSearchFailed	A left bracket '[' was found. If we've 
				been scanning for left brackets with 
				IBF_NOT_IN_TEXT (as we should), then we must be 
				at a keyword. Check if we've violated any 
				passed IBS_buffStatus flags. 
	DIECheckIfStillInResource	Sees if we have hit the [endresrc] 
				keyword. Useful for DIEFindNextKeyword if we 
				want to look ahead for a keyword, but don't 
				want to look outside of this resource. 
	DIECompareStrings	Compare the string of length cx in ds:dx with 
				the string in the buffer at position 
				IBS_impPos. 
	DIEScanForChar		Scans the ImportBuffer looking for the passed 
				character. Reloads the chunk with bytes from 
				the ATF if the char is not found in the chunk. 
				Eventually, either the end of the ATF is 
				reached or the char is found. 
	DIECheckIsChar		Sees if the character at the current position 
				in the buffer is the passed character. 
	DIEAdvanceOneByte	Advance position in buffer by one byte. 
	DIECheckFoundMatchingChar	Check if passed char is the one we're 
				looking for, *but* need to be careful if we 
				care about whether the character occurs inside 
				of a text ({.....}) region. This type of 
				comparison will prevent us from identifying 
				[chunk ] as a keyword if it just happens to be 
				some text in an original or translated chunk. 
	DIELockBuffer		Locks the impBuffer or unfBuffer chunk, 
				allocating space if necessary. 
	DIEFillBufferIfNecessaryFixupDS	Fills the buffer if almost all of its 
				bytes have been seen. 
	DIELockKeyword		Locks ResEditKeywordResource and returns a 
				pointer to the desired keyword. 
	DIEFileRead		Reads some bytes from the ATF into import 
				buffer. Then applies LocalDosToGeos to the 
				buffer. 
	DIELocalDosToGeos	Convert from GeosToDos or DosToGeos. 
	DIELocalGeosToDos	Convert from GeosToDos or DosToGeos. 
	DIERememberUnmappable	We just read a bunch of bytes from the ATF, 
				some of which were unmappable under 
				LocalDosToGeos. We now need to reread these 
				bytes, LocalDosToGeosChar'ing them one at a 
				time, remembering unmappables so that we can 
				warn the user. 
	DIESetFilePosRelative	Adjusts file position by dx bytes. 
	DIEFileReadLow		Reads bytes from the ATF, plus some error 
				checking. 
	DIEEnlargeBufferIfNeeded	Writes the name of the chunk being 
				parsed to the UnmappedChars text object because 
				some chars were found that could not be mapped 
				to GEOS chars at the time this chunk was being 
				parsed. 
	DIEClearBuffer		Clears the buffer. (This will make debugging 
				much easier, but should not be functionally 
				necessary.) 
	DIEDeallocBuffers	At the conclusion of importing, we need to get 
				rid of the buffers we created. 
	DIESkipWhiteSpace	Skips ahead until reaches a non-whitespace 
				character in the impBuffer (not for unfBuffer). 
	DIELocalIsNotWhiteSpace	Clears zf if passed character is *not* a ws. 
				Otherwise sets zf. 
	DIEReadProtocolNumber	Makes a hex number from the run of digits 
				starting with the digit at the current buffer 
				position. Advances buffer position to character 
				following the run of digits. 
	DIEScanAheadCommon	Common code for scanning ahead until some type 
				of character is encountered. The passed 
				comparsion routine should *clear* the zero flag 
				when its condition is satisfied. 
	DIESaveNewTransText	Save the text from the unformat buffer to a DB 
				Item. 
	DIESaveMnemonic		Saves ATF's mnemonic to the db file. 
	DIECopyVisMoniker	Need to save the VisMoniker structure from the 
				source item before it is possibly resized, so 
				that it can be copied to the destination item 
				correctly. 
	DIESaveNewMnemonic	The mnemonic has been changed. Save the new 
				mnemonic to the translation item. 
	DIESaveNewText		Saves the trans text into DB. 
	DIESaveTextNotMoniker	Save any changes to text object to database 
				item. 
	DIEAllocNewTransItem	Allocates a new trans item, and fixes up *ds:dx 
				and ds:si to point to the resource array and 
				the passed element, respectively. 
	DIERecordMissingItem	Saves the name of the missing item to the 
				MissingItems text. 
	DIECallMissingItemsText	Call the MissingItems text. 
	DIEInitiateInteractionCommon	Initiates the passed interaction (which 
				is in FileMenuUI). 
	DIEWarnUser		Useful routine for warning user if he's about 
				to export to an already existing file, or 
				importing an ATF that is older than the geode. 
	DIEEvalKeywordFailure	Called if DIEFindNextKeyword returned carry 
				set. 
	DIEWarnUserWithName	Warns user of some error, with the passed 
				string used as the single string argument 
				substituted into the warning message. 
	DIEHitEOF		Warns user if the EOF was hit unexpectedly. 
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/ 8/95   	Initial revision


DESCRIPTION:
	Import/Export routines for ResEditDocumentClass.  SBCS only.
		

	$Id: documentImpExp.asm,v 1.1 97/04/04 17:14:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	system.def		; Need just for UtilHex32ToAscii
include	library.def		; Need for GeodeUse/FreeLibrary


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECheckIfTextChunk,
		DIECheckIfObjectChunk,
		DIECheckIfExportableChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if chunk is:
			a text chunk
			an object chunk
			an exportable chunk

CALLED BY:	DIEExportChunkCallback
PASS:		ds:di	- ResourceArrayElement
RETURN:		zero 	- set if is *not* a text/obj/exportable
			- clear if *is* a text/obj/exportable
DESTROYED:	nothing
SIDE EFFECTS:	
	Cassie said she'd seen cases where there was no chunk type
	information.  If the type info is missing (so that RAD_
	chunkType is incorrectly set, most likely to 0), then
	a legitimate chunk might be overlooked.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECheckIfTextChunk	macro
	test	ds:[di].RAE_data.RAD_chunkType, mask CT_TEXT
endm

DIECheckIfObjectChunk	macro
	test	ds:[di].RAE_data.RAD_chunkType, mask CT_OBJECT
endm

DIECheckIfExportableChunk	macro
	test	ds:[di].RAE_data.RAD_chunkType, mask CT_TEXT or \
						mask CT_OBJECT
endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		stz, clz
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the zf, clears the zf.

CALLED BY:	
PASS:		nothing
RETURN:		zf = 1 for stz
		zf = 0 for clz
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
stz	macro	trashReg
	mov_tr	trashReg, ah
	lahf
	or	ah, mask CPU_ZERO
	sahf
	mov_tr	ah, trashReg
endm

clz	macro	trashReg
	mov_tr	trashReg, ah
	lahf
	and	ah, not mask CPU_ZERO
	sahf
	mov_tr	ah, trashReg
endm




DocumentExport		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received when user wants an ASCII translation file
		output.  

CALLED BY:	MSG_RESEDIT_DOCUMENT_ASCII_EXPORT
PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDExport	method dynamic ResEditDocumentClass, 
					MSG_RESEDIT_DOCUMENT_ASCII_EXPORT
	uses	ax, cx, dx, bp
FILE_AND_PATH_LOCALS
	.enter
	call	MarkBusyAndHoldUpInput
	call	FilePushDir
	;
	; Clear out the UnmappedChars text object.
	;
	call	DIEClearUnmappedChars
	;
	; Get name and path of ASCII (DOS) file.
	;
	mov	cx, offset ExportAsciiFileSelector
	mov	dx, offset ExportAsciiFileText
	call	DIEGetImpExpFileNameAndPath	;cx=0 or disk handle
	jc	done
	jcxz	done				;No string.
	;
	; Create and open DOS file.
	;
	call	DIECreateExportFile		;cx=export file handle
	jc	done
	;
	; Write header to DOS file.
	;
	call	DIEExportHeader
	jc	fileDelete
	;
	; Enumerate all resources and their chunks, writing them
	; to the DOS file.
	;
	call	DIEExportBody
	jc	fileDelete
	call	DIENotifyUserUnmappedChars
	;
	; Close DOS file.
	;
	mov_tr	bx, cx				;bx=file handle
	clr	al
	call	FileClose			;ax=error code
	mov	cx, EV_COULD_NOT_CLOSE_FILE
	jc	error

done:
	call	FilePopDir
	call	MarkNotBusyAndResumeInput
	.leave
	ret
error:
	call	DIENotifyError
	jmp	done
fileDelete:
	segmov	ds, ss, ax
	lea	dx, ss:fileName
	call	FileDelete
	mov	cx, EV_ERROR_DELETING_FILE
	jc	error
	jmp	done
REDExport	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEClearUnmappedChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears out the UnmappedChars text object.

CALLED BY:	REDExport,REDImport
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	fixes up ds

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEClearUnmappedChars	proc	far
	uses	ax,bx,bp,cx,dx
	.enter

	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	push	ds:[LMBH_handle]
	call	DIECallUnmappedChars
	pop	bx
	call	MemDerefDS

	.leave
	ret
DIEClearUnmappedChars	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEGetImpExpFileNameAndPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the path and filename of the new ascii
		translation file.

CALLED BY:	REDExport,REDImport
PASS:		ss:bp	- inherited locals
		cx	- offset to file selector (or text obj, later***)
		dx	- offset to text object
RETURN:		cx	- success: disk handle, and
			  fileName has file name
			  pathName has path name
			- 0 if bad path or no file specified
		carry	- set on error
			  cx = ErrorValue
DESTROYED:	nothing
SIDE EFFECTS:	
	CAUTION:  The locals from REDImport and REDExport must *both*
		  have locals for the file name and path name.  This
		  routine inherits from REDImport because it has more
		  locals.  If we inherited from REDExport, we'd mangle
		  the locals belonging to REDImport.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEGetImpExpFileNameAndPath	proc	far
	uses	ax,bx,dx,si,di,bp
	.enter inherit REDImport
	;
	; Get disk handle and relative path.
	;
	push	bp,dx
	GetResourceHandleNS	FileMenuUI, bx
	mov	si, cx				;bxsi=file slctr or text
	mov	ax, MSG_GEN_PATH_GET
	mov	dx, ss
	lea	bp, ss:pathName
	mov	cx, size PathName
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;cx=disk handle
	jc	error
	pop	bp,si				;bxsi=text
	jcxz	done
	push	cx				;Save disk handle.
	;
	; Get file name from GenText.
	;
	mov	dx, ss
	lea	bp, ss:fileName			;dx:bp = dest buffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;dx:bp has name, cx=count
	pop	ax				;Retrieve disk handle.
	jcxz	done				;No file specified in GenText.
	mov_tr	cx, ax
	clc					;No error
done:
	.leave
	ret
error:
	mov	cx, EV_COULD_NOT_SET_PATH
	call	DIENotifyError
	stc
	jmp	done
DIEGetImpExpFileNameAndPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECreateExportFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new DOS file, our export file.
		Also sets the threads path.

CALLED BY:	REDExport
PASS:		cx	- disk handle
		ss:bp	- inherited locals
RETURN:		cx	- file handle
		if carry, cx = ErrorValue
DESTROYED:	nothing
SIDE EFFECTS:	
	May fixup ds (which happens to hold segment
	of ResEditDocumentObject).

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECreateExportFile	proc	near
	uses	ax,bx,dx,ds
	.enter inherit REDExport
	push	ds:[LMBH_handle]
	;
	; Set up path.
	;
	mov_tr	bx, cx
	segmov	ds, ss, cx
	lea	dx, ss:pathName
	call	FileSetCurrentPath
	mov	cx, EV_PATH_NOT_FOUND
	jc	error
	;
	; Warn user if file already exists.
	;
	call	DIECheckExportFileExists
	mov	cx, EV_COULD_NOT_CREATE_FILE
	jc	done
	;
	; Create the new export file.
	;
	mov	ah, FILE_CREATE_TRUNCATE shl offset FCF_MODE or \
		    mask FCF_NATIVE
	mov	al, FE_DENY_WRITE shl offset FAF_EXCLUDE or \
		    FA_WRITE_ONLY shl offset FAF_MODE
	clr	cx				;No special FileAttrs
	lea	dx, ss:fileName
	call	FileCreate			;ax=file handle or
						;error code
	mov	cx, EV_COULD_NOT_CREATE_FILE
	jc	error
	mov_tr	cx, ax
	clc					;no error
done:
	pop	bx
	call	MemDerefDS
	.leave
	ret
error:
	stc
	call	DIENotifyError
	jmp	done
DIECreateExportFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECheckExportFileExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Warns user if export file already exists so that user
		can decide whether to overwrite it.

CALLED BY:	DIECreateExportFile
PASS:		ss:bp	- inherited locals
RETURN:		carry	- set if user elected *not* to overwrite
			  an already existing export file
			- clear if user elected to overwrite, or
			  if file does not exist
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECheckExportFileExists	proc	near
	uses	dx,cx,ax
	.enter inherit DIECreateExportFile
	;
	; See if file exists.
	;
	lea	dx, ss:fileName
	call	FileGetAttributes
	jnc	warnUser
	clc					;File doesn't exist.
done:
	.leave
	ret
warnUser:
	push	si,bx
	lea	cx, ss:pathName
	mov	si, offset WarningFileExists
	mov	bl, GIT_AFFIRMATION
	call	DIEWarnUser
	pop	si,bx
	jmp	done
DIECheckExportFileExists	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exports header information to the ASCII translation
		file.

CALLED BY:	REDExport
PASS:		*ds:si	- instance data (document)
		cx	- export file handle
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	May fixup ds.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportHeader	proc	near
	uses	dx,cx,bx,di,ax,bp
	.enter
	push	ds:[LMBH_handle],si

	; Header keyword.
	mov	bp, cx
	mov_tr	dx, cx				; save export handle
	mov	cl, REKT_HEADER
	mov	ch, 1
	call	DIEExportKeyword
	jc	error
	mov	cl, 2
	call	DIEExportCRLF
	jc	error
	;
	; Get the TransMapHeader.
	;
	call	GetFileHandle			; bx = DB file handle
	call	DBLockMap_DS			; *ds:si <- ResourceMap
	mov	di, ds:[si]			; ds:di = ResourceMap
	clr	al
	mov	ah, mask REESF_NEWLINE
	mov_tr	bx, dx				; export file handle
	
	; Source geode file name (Geos name).
	mov	cl, REKT_SOURCE
	call	DIEExportKeyword
	jc	error
	lea	si, ds:[di].TMH_sourceName	; ds:si=source name
	call	DIELocalStringSize		; cx = size w/o null
	mov_tr	dx, si				; ds:dx = source buff
	call	DIEFileWrite
	jc	error

	; Relative path of source geode.
	mov	cl, REKT_PATH
	mov	ch, 1
	call	DIEExportKeyword
	jc	error
	lea	si, ds:[di].TMH_relativePath
	call	DIELocalStringSize
	mov_tr	dx, si
	call	DIEFileWrite
	jc	error

	; Protocol data (version data).
	call	DIEExportVersionData
	jc	error

	; Dos name of source geode.
	mov	cl, REKT_DOS_NAME
	mov	ch, 1
	call	DIEExportKeyword
	jc	error
	lea	si, ds:[di].TMH_dosName
	call	DIELocalStringSize
	mov_tr	dx, si
	call	DIEFileWrite
	jc	error

	mov	ch, 1
	mov	cl, 2
	call	DIEExportCRLF

	; Was an error iff jumped here.  Else everything's fine.
error:	
	call	DBUnlock_DS

	pop	bx,si
	call	MemDerefDS
	.leave
	ret
DIEExportHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportVersionData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exports protocol number.

CALLED BY:	DIEExportHeader only
PASS:		ds:di	- ResourceMap
		bp	- export file handle
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportVersionData	proc	near
	uses	cx, ax, dx
	.enter

	mov	cl, REKT_VERSION
	mov	ch, 1
	call	DIEExportKeyword
	jc	done

	mov	cl, C_COMMA
	clr	dx
	mov	ax, ds:[di].TMH_version.PN_major
	call	DIEFileWriteNumber
	jc	done
	call	DIEFileWriteChar
	jc	done

	mov	ax, ds:[di].TMH_version.PN_minor
	call	DIEFileWriteNumber
	jc	done

	clr	cl
	call	DIEExportCRLF

done:
	.leave
	ret
DIEExportVersionData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exports the resources and chunks of the current
		translation file.  The resources and chunks make up
		the body, while the header contains other data, such
		as version info.

CALLED BY:	REDExport
PASS:		*ds:si	- instance data (document)
		cx	- export file handle
RETURN:		carry	- set if error occurred
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	For each resource in the translation file {
	    export [resource] <resource name>
	    For each chunk within the resource {
	        export [chunk    ] <chunk name>
		export [original ] {<original text>}
		export [localize ] {<instructions>} max,min,type
	        export [translate] {<translated text>}
	        export [mnemonic ] <mnemonic> [shortcut] <shortcut>
	    }
	    export [endresrc] <resource name>
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportBody	proc	near
	uses	bx,di,bp,ax
	.enter

	push	cx,dx,si
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset ExportBooleanList
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	cl, offset EF_CHANGED_ONLY
	shl	ax, cl				; make into ExportFlags
	pop	cx,dx,si

EC <	call	AssertIsResEditDocument					>
	sub	sp, (size ExportChunkStruct)
	mov	bp, sp

	mov	ss:[bp].ECS_EACS.EACS_size, (size ExportChunkStruct)
	mov	ss:[bp].ECS_EACS.EACS_callback.segment,cs
	mov	ss:[bp].ECS_EACS.EACS_callback.offset,
			offset DIEExportChunkCallback
	mov	ss:[bp].ECS_exportFile, cx
	mov	{word}ss:[bp].ECS_flags, ax
	call	GetFileHandle			; bx <- DB xlatn file
	push	cx
	mov	cl, REKT_BODY
	clr	ch
	call	DIEExportKeyword
	jc	afterCRLF
	mov	cl, 2
	call	DIEExportCRLF
afterCRLF:
	pop	cx
	jc	afterEnum
	mov	ss:[bp].ECS_transFile, bx
	call	DIEEnumAllChunks
afterEnum:
	pushf
	pop	bx
	add	sp, (size ExportChunkStruct)
	push	bx
	popf

	.leave
	ret
DIEExportBody	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportChunkCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for exporting a chunk to an ASCII
		translation file.

CALLED BY:	DIEExportBody (via DIEEnumAllChunks)
PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		ss:bp	- ExportChunkStruct
		dx	- file handle of DB translation file
			  (from GetFileHandle in DIEEnumAllChunks)
		cx	- resource group
		ax	- size of this element **
		es	- number of the resource owning this chunk
RETURN:		carry set if an error occurred during export
DESTROYED:	nothing
SIDE EFFECTS:	
NOTES:
		Just be careful about ax,cx,dx,bp,es.  ChunkArrayEnum,
		which DIEEnumAllChunksCallback calls, allows these regs
		to be changed by the callback (DIEExportChunkCallback
		in this case).  But DIEEnumAllChunksCallback needs dx
		left alone.

	     **	Although DIEEnumAllChunksCallback doesn't *say* it's
		passing the size of the element to its callback,
		EACC does call ChunkArrayEnum, which *does* pass
		the element size to the callback.


PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportChunkCallback	proc	far
	uses	bx,cx
	.enter

	DIECheckIfExportableChunk		;no bitmaps,grafx,etc
	jz	done
	call	DIECheckIfChangedChunk
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR	>
	jz	done

	mov_tr	bx, cx
	clr	ch				;(for ExportText)
	mov	cl, REKT_CHUNK			;[chunk] keyword
	call	DIEExportKeyword
	jc	done
	call	DIEExportChunkName
	jc	done

	mov	cl, REKT_ORIG_TEXT
	call	DIEExportKeyword
	jc	done
	clr	cl
	call	DIEExportText
	jc	done
	call	DIEExportCRLF
	jc	done

	call	DIEExportLocalizeHints
	jc	done

	mov	cl,  REKT_TRANS_TEXT
	call	DIEExportKeyword
	jc	done
	mov	cl, 1				; for xlated text
	call	DIEExportText
	jc	done
	clr	cl
	call	DIEExportCRLF
	jc	done

	mov	cl, REKT_MNEMONIC
	call	DIEExportKeyword
	jc	done
	call	DIEExportMnemonic
	jc	done
	mov	cl, C_TAB
	call	DIEFileWriteChar
	jc	done

	mov	cl, REKT_SHORTCUT
	call	DIEExportKeyword
	jc	done
	call	DIEExportShortcut
	jc	done

	mov	cl, 2
	call	DIEExportCRLF

done:
	.leave
	ret
DIEExportChunkCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECheckIfChangedChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If only modified chunks are supposed to be exported,
		this routine will check if the passed
		ResourceArrayElement is associated with a modified 
		chunk.

CALLED BY:	DIEExportChunkCallback
PASS:		ds:di	- ResourceArrayElement
		cx	- resource group
		ss:bp	- ExportChunkStruct
RETURN:		zf	- set if should *not* export this chunk
			- clr if should export this chunk
		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	
	May fixup ds.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECheckIfChangedChunk	proc	near
	uses	ax,bx,cx,dx,si,di,es

	test	ss:[bp].ECS_flags, mask EF_CHANGED_ONLY
	jnz	start
	push	ax
	or	al, 1				   ; Clear zf.
	pop	ax
	clc					   ; no error
	ret
start:
	.enter

	push	ds:[LMBH_handle]
EC <	DIECheckIfExportableChunk			>
EC <	ERROR_Z	RESEDIT_INTERNAL_ERROR			>
	;
	; Did the mnemonic or shortcut change?
	;
	call	DIECheckMnemonicOrShortcutChanged
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR			>
	jc	error
	jnz	doneAndPop			   ; *do* export
	;
	; Get the original chunk (which must be a string).
	;
	mov	dx, di				   ; Save element.
	mov	di, ds:[di].RAE_data.RAD_origItem
	cmp	di, 0
	je	error
	mov_tr	ax, cx				   ; group
	mov	bx, ss:[bp].ECS_transFile	   ; trans file (DB file)
	call	DBLock_DS
	mov	si, ds:[si]			   ; ds:si = origString
	;
	; Get the translated chunk (also a string).
	;
	mov	di, dx				   ; element offset
	mov_tr	cx, bx				   ; save file handle
	pop	bx				   ; Get LMBH_handle
	call	MemDerefES
	push	bx
	mov_tr	bx, cx				   ; Restore file
						   ; handle
	mov	di, es:[di].RAE_data.RAD_transItem ;ax:di = DB grp:item
	cmp	di, 0
	jz	doneAndUnlock			   ; no trans item
	call	DBLock
	mov	di, es:[di]			   ; es:di = transString
	;
	; Compare the two strings.
	;
	mov	cx, ds				   ; Save segment
	pop	bx
	call	MemDerefDS
	push	bx
	xchg	dx, di				   ; ds:di=element
	mov	al, ds:[di].RAE_data.RAD_chunkType
	mov	ah, ds:[di].RAE_data.RAD_mnemonicType
	mov	ds, cx				   ; Restore segment
	xchg	dx, di
	push	dx
	mov_tr	dx, ax
	call	DIEGetStringLength_DS		  ; cx = orig length
	mov_tr	ax, cx
	call	DIEGetStringLength		  ; cx = trans length
	pop	dx
	cmp	ax, cx
	jnz	doneAndUnlockBoth			  ; diff lengths
	repe cmpsb

doneAndUnlockBoth:
	call	DBUnlock
doneAndUnlock:
	call	DBUnlock_DS
doneAndPop:
	pop	bx
	call	MemDerefDS
	clc					  ; no error
done:
	.leave
	ret
error:
	mov	cx, EV_COULD_NOT_FIND_A_CHUNK
	call	DIENotifyError
	pop	bx
	call	MemDerefDS
	stc
	jmp	done
DIECheckIfChangedChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECheckMnemonicOrShortcutChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the mnemonic or shortcut of the passed
		chunk (array element) has been edited.

CALLED BY:	DIECheckIfChangedChunk only
PASS:		ds:di	- ResourceArrayElement
		cx	- resource group
		ss:bp	- ExportChunkStruct
RETURN:		zf	- set if there is *no* change in mnem/short
			- clr if there is a change
		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	See DocumentRevertToOriginalItem in documentMisc.asm.
	Most of this code is taken from that routine, except
	here we compare the mnemonic (for a text thing) or
	shortcut (for an object) in the array elt to the
	original item.

	TResEd.txt indicates that an object can have a mnemonic
	("In some cases, an object will have a keyboard shortcut 
	in addition to a moniker mnemonic") so for objects we
	check for changes in both mnemonic and shortcut.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECheckMnemonicOrShortcutChanged	proc	near
	uses	ax,bx,cx,dx,si,di
	.enter
	push	ds:[LMBH_handle]
	mov_tr	ax, cx				   ; group
	;
	; Rem current mnemonic and shortcut.
	;
	mov	cl, ds:[di].RAE_data.RAD_chunkType
	mov	ss:[bp].ECS_extra, cl
	mov	ch, ds:[di].RAE_data.RAD_mnemonicType
DBCS <	PrintMessage <Problems occur here if DBCS.>		>
	mov	cl, ds:[di].RAE_data.RAD_mnemonicChar 
	mov	dx, ds:[di].RAE_data.RAD_kbdShortcut
	;
	; Lock original item.
	;
	mov	di, ds:[di].RAE_data.RAD_origItem
	cmp	di, 0
	LONG	je	error
	mov	bx, ss:[bp].ECS_transFile	   ; trans file (DB file)
	call	DBLock_DS
	mov	si, ds:[si]			   ; ds:si = origString
	;
	; Get original mnemonic and compare
	;
	cmp	ss:[bp].ECS_extra, mask CT_TEXT or mask CT_MONIKER
	je	mightHaveMnemonic
	cmp	ss:[bp].ECS_extra, mask CT_TEXT or mask CT_MONIKER \
				   or mask CT_OBJECT
	jne	checkShortcut				;no mnemonic
mightHaveMnemonic:
	mov	ah, ds:[si].VM_data.VMT_mnemonicOffset	
	push	dx					;save shortcut
	mov_tr	dl, cl					;mnem char
	;
	; Now assume that the mnemonic is in the moniker text and add
	; the size of the moniker structure to get the offset to the
	; char within the moniker.
	; DBCS: use cx to hold the mnemonic
	;
	mov	bl, ah					;bl <- mnemonic offset
	clr	bh					;bx <- offset in text
DBCS <	shl	bx, 1					;bx <- offset in text>
	add	bx, MONIKER_TEXT_OFFSET			;bx <-offset in moniker
SBCS <	clr	al					;no char initially>
DBCS <	clr	cx					;no char initially>

	cmp	ah, VMO_CANCEL				; is mnemonic CANCEL?
	je	noMnemonic				;   yes, so no char
	cmp	ah, VMO_NO_MNEMONIC			; is there no mnemonic?
	je	noMnemonic				;   yes, no char
	cmp	ah, VMO_MNEMONIC_NOT_IN_MKR_TEXT	; is it after text?
	jne	inText					;   no, it's in text
	ChunkSizePtr	ds, si, bx			; get size of chunk
	dec	bx					; bx <- offset of last
							;   byte in the chunk
DBCS <	dec	bx					; bx <- of last word>
inText:
	push	si					;need for shortcut
	add	si, bx					; si <- mnemonic offset
SBCS <	mov	al, {char}ds:[si]			; al <- mnemonic char>
DBCS <	mov	cx, {wchar}ds:[si]			; cx <- mnemonic char>
	pop	si

	; SBCS note: assume cx destroyed from this point on
	;
noMnemonic:
SBCS <	cmp	dl, al					>
DBCS <	clr	dh					;JM: check w/ Cassie>
DBCS <	cmp	dx, cx					>
	pop	dx					;retrive shortcut
	jnz	unlock					;*Is* a change.
	;
	; Get original kbd shortcut and compare, if necessary.
	;
checkShortcut:
	cmp	ss:[bp].ECS_extra, mask CT_OBJECT
	jne	noChange			   ;no obj -> no short
	ChunkSizePtr	ds, si, bx		   ; bx<-chunk size
	sub	bx, 2				   ; ds:bx+si<-shortcut
	add	bx, si
	mov	ax, ds:[bx]			   ; orig shortcut
	cmp	ax, dx				   ; orig vs. current

unlock:
	clc
	call	DBUnlock_DS
exit:
	pop	bx
	call	MemDerefDS
	.leave
	ret
error:
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR			>
	stc
	jmp	exit
noChange:
	xor	al, al				  ; set zf
	jmp	unlock
DIECheckMnemonicOrShortcutChanged	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exports the shortcut for the chunk (if any) to the 
		ASCII translation file.

CALLED BY:	DIEExportChunkCallback
PASS:		ds:di	- ResourceArrayElement
		ss:bp	- ExportChunkStruct
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportShortcut	proc	near
	uses	ax,cx
	.enter

	clr	ch				;FileWriteChar flag
	mov	ax, ds:[di].RAE_data.RAD_kbdShortcut
	cmp	ax, 0
	je	afterModifiers

	test	ax, mask KS_PHYSICAL
	jz	checkAlt
	mov	cl, C_CAP_P
	call	DIEFileWriteChar
	jc	done
checkAlt:
	test	ax, mask KS_ALT
	jz	checkCtrl
	mov	cl, C_CAP_A
	call	DIEFileWriteChar
	jc	done
checkCtrl:
	test	ax, mask KS_CTRL
	jz	checkShift
	mov	cl, C_CAP_C
	call	DIEFileWriteChar
	jc	done
checkShift:
	test	ax, mask KS_SHIFT
	jz	afterModifiers
	mov	cl, C_CAP_S
	call	DIEFileWriteChar
	jc	done

afterModifiers:
	mov	cl, C_COMMA
	call	DIEFileWriteChar
	jc	done
	and	ax, mask KS_CHAR shr offset KS_CHAR	;al=char
	jz	done
	mov_tr	cl, al
	call	DIEFileWriteChar

done:
	.leave
	ret
DIEExportShortcut	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Export the mnemonic char (or keyword "esc" or "nil").

CALLED BY:	DIEexportChunkCallback
PASS:		ds:di	- ResourceArrayElement
		ss:bp	- ExportChunkStruct
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportMnemonic	proc	near
	push	cx

	clr	ch
DBCS<	PrintMessage <Problems occur here if DBCS.>		>
	mov	cl, ds:[di].RAE_data.RAD_mnemonicChar 
	cmp	cl, C_NULL
	jne	checkESC
	mov	cl, REKT_NULL_MNEMONIC
	jmp	specialMnemonic

checkESC:
	cmp	cl, C_ESC
	jne	regularMnemonic
	mov	cl, REKT_ESC_MNEMONIC

specialMnemonic:
	call	DIEExportKeyword
	pop	cx
	ret

regularMnemonic:
	call	DIEFileWriteChar
	pop	cx
	ret
DIEExportMnemonic	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportLocalizeHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exports localization instructions, max, min and type
		to ASCII translation file.

CALLED BY:	
PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		ss:bp	- ExportChunkStruct
		dx	- file handle of DB translation file
			  (from GetFileHandle in DIEEnumAllChunks)
		bx	- resource group
		ax	- size of this element **
		es	- number of the resource owning this chunk
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportLocalizeHints	proc	near
	uses	cx,dx,ax
	.enter

	; Keyword and instructions.
	mov	cl, REKT_LOCALIZE
	clr	ch
	call	DIEExportKeyword
	jc	done	
	mov	cl, 3				; cx <>0 nor 1
	call	DIEExportText
	jc	done
	mov	cl, C_SPACE
	call	DIEFileWriteChar
	jc	done

	; Min, max, and type.
	clr	dx
	mov	ax, ds:[di].RAE_data.RAD_maxSize
	call	DIEFileWriteNumber		; max
	jc	done
	mov	cl, C_COMMA
	call	DIEFileWriteChar		; ,
	jc	done
	mov	ax, ds:[di].RAE_data.RAD_minSize
	call	DIEFileWriteNumber		; min
	jc	done
	call	DIEFileWriteChar		; ,
	jc	done
	call	DIEExportChunkType
	jc	done

	clr	cl
	call	DIEExportCRLF

done:	
	.leave
	ret
DIEExportLocalizeHints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportChunkType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the chunk type to the ASCII export file.

CALLED BY:	DIEExportLocalizeHints
PASS:		ss:bp	- ExportChunkStruct
		ds:di	- ResourceArrayElement
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	
	May fixup ds.		

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportChunkType	proc	near
	uses	ax,bx,cx,dx,si
	.enter
	push	ds:[LMBH_handle]

EC <	DIECheckIfExportableChunk				>
EC <	ERROR_Z	RESEDIT_INTERNAL_ERROR				>
	mov	dl, ds:[di].RAE_data.RAD_chunkType

	mov	si, offset TypeObject
	test	dl, mask CT_OBJECT
	jnz	getString			; It's an obj.
	mov	si, offset TypeText
	test	dl, mask CT_MONIKER		; Text moniker?
	jz	getString			; Nope.  Just text.
	mov	si, offset TypeTextMoniker

getString:
	GetResourceHandleNS	StringsUI, bx
	push	bx
	call	MemLock
	jc	error
	mov	ds, ax				; ^lds:si = string
	mov	dx, ds:[si]			; ds:dx = string
	ChunkSizeHandle	ds,si,cx
	dec	cx				; size w/o null

	clr	ax				; no flags
	mov	bx, ss:[bp].ECS_exportFile	; file handle
	call	DIEFileWrite
	pop	bx
	call	MemUnlock
	clc					; no errors

done:
	pop	bx
	call	MemDerefDS

	.leave
	ret
error:
	pop	bx
	mov	cx, EV_BLOCK_DISCARDED
	call	DIENotifyError
	stc
	jmp	done
DIEExportChunkType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEFileWriteNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the passed double word into an ASCII string
		and writes it to the export file.

CALLED BY:	
PASS:		dx:ax	- dword
		ch	- 0 if ss:bp = ExportChunkStruct
			- nonzero if bp = export file handle
		ss:bp	- ExportChunkStruct
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEFileWriteNumber	proc	near
	uses	es,bx,di,cx,ax,ds,dx
	.enter

CheckHack < (UHTA_NO_NULL_TERM_BUFFER_SIZE/2)*2 eq UHTA_NO_NULL_TERM_BUFFER_SIZE >
	sub	sp, UHTA_NO_NULL_TERM_BUFFER_SIZE
	segmov	es, ss, bx
	mov	di, sp				; es:di = buffer
	mov_tr	bh, ch				; Save ch flag
	clr	cx				; no flags
	call	UtilHex32ToAscii		; cx = num bytes

	mov_tr	ah, bh				; ah <- ch flag
	segmov	ds, es, bx
	mov_tr	dx, di				; ds:dx = string
	mov	bx, bp				; assume ch was <> 0
	cmp	ah, 0
	jne	writeIt
	mov	bx, ss:[bp].ECS_exportFile	;ch was 0
writeIt:
	clr	ax				; no flags
	call	DIEFileWrite
	pushf
	pop	ax
	add	sp, UHTA_NO_NULL_TERM_BUFFER_SIZE
	push	ax
	popf

	.leave
	ret
DIEFileWriteNumber	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportResourceBegin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If appropriate, print the resource keyword and
		name to the ASCII translation file.

CALLED BY:	DIEExportChunkCallback
PASS:		ss:bp	- ExportChunkStruct
		dx	- file handle of DB translation file
		ds:di	- ResourceMapElement
		cx	- size of element
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportResourceBegin	proc	near
	uses	cx
	.enter

	push	cx
	mov	cl, REKT_RSRC_BEGIN
	clr	ch
	call	DIEExportKeyword
	pop	cx
	jc	done
	call	DIEExportResourceName
	jc	done
	clr	cl
	call	DIEExportCRLF
done:
	.leave
	ret
DIEExportResourceBegin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportResourceName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the resource's name to the ASCII translation
		file.

CALLED BY:	DIEExportResourceBegin, DIEExportResourceEnd
PASS:		ss:bp	- ExportChunkStruct
		dx	- file handle of DB translation file
		ds:di	- ResourceMapElement
		cx	- size of ResourceMapElement
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	
	Resource names had better be null-terminated.
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportResourceName	proc	near
	uses	bx,ax,cx,dx
	.enter
	;
	; Write the resource name to the ASCII file.
	;
	lea	dx, ds:[di].RME_data.RMD_name	;ds:dx = source name
	sub	cx, size ResourceMapElement	; cx=string size
	clr	al
	mov	ah, mask REESF_NEWLINE
	mov	bx, ss:[bp].ECS_exportFile	;file handle
	call	DIEFileWrite

	.leave
	ret
DIEExportResourceName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportResourceEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If appropriate, exports the [endresrc] keyword and
		resource name to the ASCII translation file.

CALLED BY:	DIEExportChunkCallback
PASS:		ss:bp	- ExportChunkStruct
		dx	- file handle of DB translation file
		ds:di	- ResourceMapElement
		cx	- size of the ResourceMapElement
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportResourceEnd	proc	near
	uses	cx
	.enter

	push	cx
	mov	cl, REKT_RSRC_END
	clr	ch
	call	DIEExportKeyword
	pop	cx
	jc	done
	call	DIEExportResourceName
	jc	done
	mov	cl, 2
	call	DIEExportCRLF
done:
	.leave
	ret
DIEExportResourceEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportKeyword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exports a keyword to the passed file.

CALLED BY:	DIEExportChunkCallback
PASS:		cl	- ResEditKeywordType
		ch	- 0 if ss:bp is ExportChunkStruct
			- nonzero if bp is export file handle
		ss:bp	- ExportChunkStruct
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	
	May fixup ds.		

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportKeyword	proc	near
	uses	bx,ax,cx,dx
	.enter

	push	ds:[LMBH_handle]
	;
	; Fetch the element from our table.
	;
	mov_tr	ah, ch				;save passed flag
	call	DIELockKeyword			;ds:dx=keyword,
						;cx=length
	jc	done
	;
	; Export the string to the ASCII file.
	;
	mov	bx, bp
	tst	ah			; can't assume with read/write checking
	jnz	writeIt
	mov	bx, ss:[bp].ECS_exportFile	;Assume *are* using
						; ExportChunkStruct.
;	cmp	ah, 0
;	je	writeIt				;Assumed correctly.
;	mov	bx, bp				;Assumed incorrectly.

writeIt:
	clr	ax				;no flags
	call	DIEFileWrite
	GetResourceHandleNS	ResEditKeywordResource, bx
	call	MemUnlock
	clc					; no error

done:
	pop	bx
	call	MemDerefDS

	.leave
	ret
DIEExportKeyword	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportChunkName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the chunk name in the passed
		ResourceArrayElement to the export file.

CALLED BY:	DIEExportChunkCallback
PASS:		ds:di	- ResourceArrayElement
		ax	- size of passed element
		ss:bp	- ExportChunkStruct
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	
	May fixup ds.		

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportChunkName	proc	near
	uses	ax,bx,cx,dx
	.enter
	push	ds:[LMBH_handle]

	sub	ax, size ResourceArrayElement	; ax = length of name
	lea	dx, ds:[di].RAE_data.RAD_name	;ds:dx <- source name

	; Write the buffer to the export file.  I'm assuming the file
	; routines or DOS will use the right code pages.
	mov_tr	cx, ax				;num bytes
	clr	al
	mov	ah, mask REESF_NEWLINE
	mov	bx, ss:[bp].ECS_exportFile	;file handle
	call	DIEFileWrite

	pop	bx
	call	MemDerefDS
	.leave
	ret
DIEExportChunkName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exports the original or translated text to the ASCII 
		translation file.  Also exports instruction text.

CALLED BY:	DIEExportChunkCallback
PASS:		ss:bp	- ExportChunkStruct
		ds:di	- ResourceArrayElement
		bx	- resource group
		cx	- 0 for original
			- 1 for translated
			- neither for instructions
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	
	May fixup ds.		

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportText		proc	near
	uses	ax,bx,di,cx,dx,si
	.enter

	push	ds:[LMBH_handle]

	mov	dl, ds:[di].RAE_data.RAD_chunkType ; (for string copy)
	mov	dh, ds:[di].RAE_data.RAD_mnemonicType
	mov	ax, ds:[di].RAE_data.RAD_origItem
	jcxz	knowItem
	mov	ax, ds:[di].RAE_data.RAD_transItem
	dec	cx
	jcxz	forceXlatString
	mov	ax, ds:[di].RAE_data.RAD_instItem
	;
	; Find the string in its group:item.
	;
knowItem:
	cmp	ax, 0				   ; no item (e.g. instr)
	je	done
	mov_tr	di, ax				   ; item
	mov_tr	ax, bx				   ; group
	mov	bx, ss:[bp].ECS_transFile	   ; trans file (DB file)
	call	DBLock_DS
	mov	si, ds:[si]			   ; ds:si = string
	;
	; Copy string to export file.
	;
	test	dl, mask CT_OBJECT
	jnz	findShortcutLength
	call	DIEGetStringLength_DS		   ; cx = size
gotLength:
	mov	dx, si				   ; ds:dx = string
	clr	al				   ; No flags.
	mov	ah, mask REESF_FORMAT 
	mov	bx, ss:[bp].ECS_exportFile	   ; File handle.
	call	DIEFileWrite
	jz	remExportedStringWithUnmappables
afterWrite:
	call	DBUnlock_DS

done:
	pop	bx
	call	MemDerefDS

	.leave
	ret
	;
	; Must have some translation text for import.
forceXlatString:
	tst	ax
	jnz	knowItem
	mov	ax, ds:[di].RAE_data.RAD_origItem
	jmp	knowItem
	;
	; This string has chars not in the DOS code page.
remExportedStringWithUnmappables:
	call	DIERecordUnmappedText
	jmp	afterWrite
	;
	; DIEGetStringLength_DS doesn't properly size the original
	; shortcut text.  It's 2 too big (chunk is 2 bytes bigger for
	; some reason).  So just find string length the normal way.
findShortcutLength:
	push	es,di
	segmov	es,ds,cx
	mov	di, si
	call	LocalStringLength
	pop	es,di
EC <	cmp	cx, 30			>
EC <	ERROR_AE RESEDIT_INTERNAL_ERROR	>
	jmp	gotLength
DIEExportText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIERecordUnmappedText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes text that could not be properly exported or
		imported (due to unmappable Geos chars).

CALLED BY:	DIEExportText, DIERecordChunkWithUnmappableChars,
		DIERememberUnmappable
PASS:		ds:si	- text
		cx	- length of text
RETURN:		nothing
DESTROYED:	si,di,cx
SIDE EFFECTS:	fixes up ds (to be safe)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIERecordUnmappedText	proc	far
	uses	es,dx,ax,bp
	.enter
	jcxz	done
	;
	; Let's not let the text object get *too* big.
	;
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	call	DIECallUnmappedChars
	cmpdw	dxax, MAX_UNMAPPED_CHARS_TEXT_SIZE
	jge	done
	;
	; Scan for null, so text lib doesn't complain.
	;
EC <	cmp	cx, 0				>
EC <	ERROR_L RESEDIT_INTERNAL_ERROR		>
EC <	cmp	cx, 200				>
EC <	ERROR_G	RESEDIT_INTERNAL_ERROR		>
	mov	dx, cx
	segmov	es, ds, ax
	mov	di, si				; es:di=text
	clr	al
	repne	scasb
	jne	afterAdjust
	inc	cx
	sub	dx, cx				; (cx not 0)
afterAdjust:
	xchg	cx, dx				; cx=count
	jcxz	done
	;
	; Prepare buffer.
	;
EC <	cmp	cx, 0				>
EC <	ERROR_LE RESEDIT_INTERNAL_ERROR		>
	mov	dx, cx
	inc	dx				; for CR
	inc	dx				; (for swat)
	and	dx, 0xfffe			; (word align for swat)
	sub	sp, dx				; name length
	segmov	es, ss, ax
	mov	di, sp				;es:di = dest
	;
	; Copy name, with a CR.
	;
	mov	ax, cx
	rep	movsb
	mov	{byte}es:[di], C_CR		;tack on a CR
	mov_tr	cx, ax
	inc	cx
	;
	; Write to text object.
	;
	mov	di, dx
	mov	bp, sp
	mov	dx, ss				;dx:bp=buffer
	mov	ax, MSG_VIS_TEXT_APPEND
	call	DIECallUnmappedChars
	mov	dx, di
	;
	; Remove buffer.
	;
	add	sp, dx
done:
EC <	call	ECCheckStack		>
	.leave
	ret
DIERecordUnmappedText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECallUnmappedChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the UnmappedChars text object.

CALLED BY:	DIERecordUnmappedText,
		DIENotifyUserUnmappedChars
PASS:		ax	- message
		cx,dx,bp - arguments to message
RETURN:		ax,cx,dx,bp
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECallUnmappedChars	proc	near
	uses	si,di,bx
	.enter

	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset UnmappedChars
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
DIECallUnmappedChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIENotifyUserUnmappedChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the user if there were any exported strings
		that had characters that could not be mapped.

CALLED BY:	REDExport,REDImport only
PASS:		*ds:si	- ResEditDocument (just happens to be,
			  but we don't really care, except for
			  fixup ds)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	fixes up ds (although don't expect any change
		from GET_SIZE)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIENotifyUserUnmappedChars	proc	far
	uses	ax,dx,bx,cx,bp
	.enter inherit REDImport
	;
	; See if we hit any unmapped chars.
	;
	push	ds:[LMBH_handle]
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	call	DIECallUnmappedChars			;dxax<-length
EC <	tst	dx			>
EC <	ERROR_NZ RESEDIT_INTERNAL_ERROR	>
	cmp	ax, 0
	jz	done
	;
	; If importing and hit a lot of unmapped chars, 
	; tell user to double-check the atf.
	;
	cmp	ax, MAX_UNMAPPED_CHARS_TEXT_SIZE
	jl	displayUnmappables
	test	ss:[buffer].IBS_parseStatus, mask IPF_importing
	jz	displayUnmappables
	mov_tr	ax, si
	mov	si, offset WarningManyUnmappables
	mov	cx, sp					;(to be safe)
	mov	dx, sp
	mov	bl, GIT_NOTIFICATION
	call	DIEWarnUser
	;
	; Display the unmappable characters.
	;
displayUnmappables:
	mov	si, offset ExportAsciiFileUnmappedChars
	call	DIEInitiateInteractionCommon
	mov_tr	si, ax

done:
	pop	bx
	call	MemDerefDS
	.leave
	ret
DIENotifyUserUnmappedChars	endp


COMMENT @ JM: Remember to see if it's better to make the code in
	      documentCount "far" @




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStringLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates length of actual text portion of chunk.

CALLED BY:	CreateWordTreeCallback
PASS:		es:di	- text
		dl	- ChunkType
		dh	- mnemonic type
RETURN:		cx	- string length
		es:di	- points to string
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEGetStringLength		proc	near

	ChunkSizePtr	es, di, cx
EC <	cmp	cx, 0						>
EC <	ERROR_LE RESEDIT_INTERNAL_ERROR				>
	
	test	dl, mask CT_MONIKER
	jz	notMoniker
	add	di, MONIKER_TEXT_OFFSET
	sub	cx, MONIKER_TEXT_OFFSET

	cmp	dh, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	notMoniker
	dec	cx				

notMoniker:
	dec	cx				; don't count the NULL
EC <	cmp	cx, 500						>
EC <	ERROR_G RESEDIT_INTERNAL_ERROR		; Be suspicious.>
	;
	; Let's set a floor of 0 on the string's length.
	;
	cmp	cx, 0
EC <	WARNING_L RESEDIT_INTERNAL_ERROR			>
	jl	setFloor
	ret
setFloor:
	clr	cx				; set floor of 0
	ret
DIEGetStringLength		endp

DIEGetStringLength_DS	proc	near
ForceRef DIEGetStringLength_DS
	push	di, es
	segmov	es, ds, cx
	mov	di, si
	call	DIEGetStringLength
	mov	si, di				; JM added.  Bug fix???
	pop	di, es
	ret
DIEGetStringLength_DS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIELocalStringSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns string size of null-terminated string
		at ds:si.

CALLED BY:	
PASS:		ds:si	- string
RETURN:		cx	- num bytes w/o null
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIELocalStringSize	proc	near
	uses	es
	.enter

	segmov	es, ds
	xchg	di, si
	call	LocalStringSize
	xchg	di, si

	.leave
	ret
DIELocalStringSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEEnumAllChunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For each resource, enumerate all its chunks.

CALLED BY:	EXTERNAL - utility

PASS:		*ds:si	- document
		ss:bp	- EnumAllChunksStruct

			passed to EACS_callback:
				*ds:si - ResourceArray
				 ds:di - ResourceArrayElement
				 ss:bp - EnumAllChunksStruct
				 dx - file handle
				 cx - resource group

RETURN:		carry set if enumeration was aborted
		
DESTROYED:	bx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	May fixup ds.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/23/95		Initial 
				(just like Cassie's EnumAllChunks)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEEnumAllChunks		proc	near
	uses	dx,si,bp
	.enter 

	push	ds:[LMBH_handle]

	call	GetFileHandle
	mov	dx, bx
	call	DBLockMap_DS			; *ds:si <- ResourceMap
	mov	bx, cs
	mov	di, offset DIEEnumAllChunksCallback
	call	ChunkArrayEnum	
	call	DBUnlock_DS

	pop	bx
	call	MemDerefDS

	.leave
	ret
DIEEnumAllChunks		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEEnumAllChunksCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the chunks this ResourceArray, calling
		passed callback for each on.

CALLED BY:	DIEEnumAllChunks
PASS:		*ds:si	- ResourceMap
		ds:di	- ResourceMapElement
		dx	- file handle
		ss:bp	- EnumAllChunksStruct
		ax	- size of this element

RETURN:		carry set to abort
			ax - ErrorValue
DESTROYED:	

PSEUDO CODE/STRATEGY:
	This callback is very similar to Cassie's
	except that 
	1.  I need to export resource keywords and names.
	2.  es is set to the resource number.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	May fixup ds.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/23/95		Initial
				(almost ident to Cassie's
				 EnumAllChunksCallback)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEEnumAllChunksCallback	proc	far
	uses	cx, bp, es
	.enter 

	push	ds:[LMBH_handle],di

	mov_tr	cx, ax
	push	cx				;save elt size
	call	DIEExportResourceBegin
	jc	afterEnum
	mov	bx, dx
	mov	ax, ds:[di].RME_data.RMD_group
	mov	di, ds:[di].RME_data.RMD_item
	mov	es, ds:[di].RME_data.RMD_number
	call	DBLock_DS			; *ds:si <- ResourceArray

	movdw	bxdi, ss:[bp].EACS_callback
	mov	cx, ax				; cx <- group
	call	ChunkArrayEnum
	call	DBUnlock_DS
afterEnum:
	pop	cx
	pop	bx,di
	call	MemDerefDS
	jc	done				; error occurred
	call	DIEExportResourceEnd
done:
	.leave
	ret
DIEEnumAllChunksCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEFileWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the passed string to the export file.

CALLED BY:	
PASS:		al - flags for FileWrite (most likely 0)
		ah - ResEditExportStringFlags
		bx - file handle
		cx - number of bytes to write
		ds:dx - buffer from which to write

RETURN:		carry	- set if error
		zf	- set if some Geos chars couldn't be mapped
			  to DOS chars (unless cf is set, in which 
			  case zf is meaningless)
DESTROYED:	nothing
SIDE EFFECTS:	
	*** Written for SBCS. ***

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEFileWrite	proc	near
	uses	dx,si,di,bp,es,ds,ax,cx
	.enter
EC <	cmp	cx, 500			; Looks suspicious.	>
EC <	ERROR_G RESEDIT_INTERNAL_ERROR 				>
EC <	cmp	cx, 0						>
EC <	ERROR_L RESEDIT_INTERNAL_ERROR 				>
	;
	; Make a buffer for string to export.  It will be at most
	; twice as long as the passed string, plus the {,} and
	; CR/LF (and align evenly, hence add 5).  ax = buffer size
	;
	mov_tr	bp, ax				; Save flags.
	mov	ax, cx
	shl	ax,1	
	add	ax, 5
	andnf	ax, 0xfffe
	sub	sp, ax	
	segmov	es, ss				; es:di = ss:sp
	mov	di, sp				; 	= buffer 
	push	ax				; Save buffer size.
						; (ss:sp <> buffer now)
	mov	si, dx				; ds:si = source
EC <	call	ECCheckStack		>
	;
	; If formatting specified, surround text by {} and 
	; double the instances of { or } appearing in the string.
	;
	mov	dx, bp
	test	dh, mask REESF_FORMAT
	jnz	copyWithFormat
	mov	dx, cx
	rep	movsb				; Regular copy.
	dec	di
	mov_tr	cx, dx
	pop	ax				; ax=buffer size
	jmp	tackOnNewline

	; Copy to buffer.  dx = running total length of formatted
	; string.
copyWithFormat:
	mov	{byte}es:[di], C_LEFT_BRACE	; Opening {
	mov	dx, 1				; One char so far.
	inc	di
	jcxz	afterLoop
nextChar:
	lodsb	
	stosb					; Copy the char.
	inc	dx
	cmp	al, C_LEFT_BRACE
	jne	checkRightBrace
	mov	{byte}es:[di], al
	inc	di
	inc	dx
checkRightBrace:
	cmp	al, C_RIGHT_BRACE
	jne	doneWithChar
	mov	{byte}es:[di], al
	inc	di
	inc	dx
doneWithChar:
	loop	nextChar
afterLoop:
	mov	{byte}es:[di], C_RIGHT_BRACE	; Closing }
	inc	dx

	pop	ax				; Restore buffer size.
						; (ss:sp = buffer again)
	mov_tr	cx, dx				; cx = string length
	;
	; Write a newline, if necessary.
	;
tackOnNewline:
	mov	dx, bp
	test	dh, mask REESF_NEWLINE
	jz	writeBufferToFile
	inc	di
	mov	{byte}es:[di], C_CR
	inc	di
	mov	{byte}es:[di], C_LF
	inc	cx
	inc	cx				; inc string length

writeBufferToFile:
	segmov	ds, ss
	mov	dx, sp				; ds:dx = string
	xchg	ax, bp				; ax<-flags; bp<-buf
						; size
EC <	call	ECCheckFileHandle					>

	mov	si, dx				; ds:si = string
	call	DIELocalGeosToDos
EC <	WARNING_C RESEDIT_LOCALGEOSTODOS_WARNING	>
	jc	remUnmappedChars

	call	FileWrite
	jc	error

done:
	lahf					;save cf and zf
	add	sp, bp
	sahf

	.leave
	ret
error:
	mov	cx, EV_ERROR_WRITING_TO_FILE
	call	DIENotifyError
	jmp	done
remUnmappedChars:
	call	FileWrite
	jc	error
	stz	al				; set zf to rem unmapped
	jmp	done
DIEFileWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OjoLocalGeosToDos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		cx	- # bytes
		ax	- the default (ah=0 b/c SBCS)
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
OjoLocalGeosToDos	proc	near
	uses	ax,bx,cx,dx,si,di
	.enter

	jcxz	done

	push	ax
	mov_tr	dh, ch				; save flag
	call	LocalGetCodePage		; bx=navitve code page
	mov_tr	dx, bx
	pop	bx				;bx=default
	
copyOne:
	xchg	cx, dx				;cx=codepage,dx=count
	clr	ah
	mov	al, {byte}ds:[si]		;ax=char to map
	mov	di, ax				;a copy
	call	LocalGeosToDosChar		;ax=mapped char
	jc	gotcha
after:
EC <	tst	ah	>
EC <	ERROR_NZ RESEDIT_INTERNAL_ERROR	>
	mov	{byte}ds:[si], al
	inc	si

	xchg	cx, dx
	loop	copyOne

done:
	clc
	.leave
	ret
gotcha:
	jmp	after
OjoLocalGeosToDos	endp
%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEFileWriteChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a carriage return to the export file.

CALLED BY:	DIEExportChunkCallback
PASS:		cl	- char to write to export file
		ch	- 0 if ss:bp is ExportChunkStruct
			- nonzero if bp is export file handle
			  SBCS
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEFileWriteChar	proc	near
	uses	ax,bx,cx,dx,ds
	.enter

	mov_tr	dh, ch				; save flag
	mov_tr	al, cl
	clr	ah
	call	LocalGetCodePage		; bx=navitve code page
	mov_tr	cx, bx
	clr	bh				; Unmatched characters
	mov	bl, C_UNDERSCORE		; will be underscores.
	call	LocalGeosToDosChar		; ax=mapped char
EC <	WARNING_C RESEDIT_LOCALGEOSTODOS_WARNING	>

	push	ax
	mov	bx, bp				; Assume bp=file handle
	cmp	dh, 0
	jne	writeIt
	mov	bx, ss:[bp].ECS_exportFile	; File handle.
writeIt:
	segmov	ds, ss, ax
	mov	dx, sp				; ds:dx = the char
	mov	cx, 1
	clr	al				; No flags.
EC <	call	ECCheckFileHandle					>
	call	FileWrite
	jc	error
	clc					; no errors
done:
	pop	ax				; Kill the 1 byte
						; buffer.

	.leave
	ret
error:
	mov	cx, EV_ERROR_WRITING_TO_FILE
	call	DIENotifyError
	stc
	jmp	done	
DIEFileWriteChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEExportCRLF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a carriage return to the export file.

CALLED BY:	DIEExportChunkCallback
PASS:		cl	- 0 if want just one crlf
			- nonzero if want 2 crlf's
		ch	- 0 if ss:bp = ExportChunkStruct
			- nonzero if bp = export file handle 
		ss:bp	- ExportChunkStruct

RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	
		This is a SBCS routine.
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEExportCRLF	proc	near
	uses	ax,bx,cx,dx,ds,si,di
	.enter

	mov	dh, cl				; save CR/LF flag
	clr	di				; di=file handle flag
	cmp	ch, 0
	je	donePreservingFlags
	inc	di				; means bp=file handle

donePreservingFlags:
	mov	al, C_LF
	clr	ah
	call	LocalGetCodePage		; bx=native code page
	mov_tr	cx, bx
	clr	bh				; Unmatched characters
	mov	bl, C_UNDERSCORE		; will be spaces.
	call	LocalGeosToDosChar		; ax=mapped char
EC <	WARNING_C RESEDIT_LOCALGEOSTODOS_WARNING	>
	mov_tr	dl, al
	clr	ah
	mov	al, C_CR
	call	LocalGeosToDosChar
EC <	WARNING_C RESEDIT_LOCALGEOSTODOS_WARNING	>
	mov_tr	ah, dl				; al=cr,ah=lf

	mov	cx, 2				; assume 1 CR/LF
	push	ax
	mov	si, 0				; flag: 1 CR/LF
	cmp	dh, 0
	je	bufferReady
	inc	si				; flag: 2 CR/LF
	inc	cx
	inc	cx
	push	ax				; 2 x CR/LF
bufferReady:
	segmov	ds, ss, ax
	mov	dx, sp				; ds:dx = the char
	clr	al				; No flags.
;
; This is not the best way to do it, but in order to get this working with
;  read/write checking we can't blindly move stuff. awu - 6/27/96
;
	cmp	di, 0
	jne	writeIt
	mov	bx, ss:[bp].ECS_exportFile	; File handle.
	jmp	writeIt2
writeIt:
	mov	bx, bp
writeIt2:
EC <	call	ECCheckFileHandle					>
	call	FileWrite
	jc	error
	clc					; no errors
killBuffer:
	pop	ax				; Kill the 2 byte
						; buffer.
	cmp	si, 0
	je	done
	pop	ax
done:
	.leave
	ret
error:
	mov	cx, EV_ERROR_WRITING_TO_FILE
	call	DIENotifyError
	stc
	jmp	killBuffer			; si was 0 or 1, so
						; don't need worry about
						; cmp si,0 changing cf
DIEExportCRLF	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIENotifyError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the user that an error occurred.

CALLED BY:	
PASS:		cx	- error value
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIENotifyError	proc	far
	uses	ax,bx,cx,dx,di,si,bp,es
	.enter
	pushf

	mov	ax, MSG_RESEDIT_DOCUMENT_DISPLAY_MESSAGE
	GetResourceSegmentNS	ResEditDocumentClass, es
	mov	bx, es
	mov	si, offset ResEditDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; ^hdi = event

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	clr	bx
	call	GeodeGetAppObject		; ^lbx:si
	mov	dx, TO_MODEL
	mov_tr	cx, di
	mov	di, mask MF_CALL
	call	ObjMessage

	popf
	.leave
	ret
DIENotifyError	endp

DocumentExport	ends




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Code below this comment deals with import.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentImport		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDGenDocumentImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate ASCII import.

CALLED BY:	MSG_GEN_DOCUMENT_CONTROL_INITIATE_IMPORT_DOC
PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
RETURN:
		nothing
DESTROYED:
		nothing
SIDE EFFECTS:	
	Note that we don't call superclass because that handler
	works with the Impex library, which we're not using.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REGDocumentControlImport	method dynamic ResEditGenDocumentControlClass, 
				MSG_GEN_DOCUMENT_CONTROL_INITIATE_IMPORT_DOC
	.enter

	mov	si, offset ResEditImportInteraction
	call	DIEInitiateInteractionCommon

	.leave
	ret
REGDocumentControlImport	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REGDocumentControlOAIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Analogous to handler for MSG_GEN_DOCUMENT_CONTROL_
		OPEN_IMPORT_SELECTED, but we're not using the Impex
		library.  Create a new document, which will later
		be sent MSG_RESEDIT_DOCUMENT_ASCII_IMPORT.

CALLED BY:	MSG_RESEDIT_GEN_DOCUMENT_CONTROL_OPEN_ASCII_IMPORT_SELECTED
PASS:		*ds:si	= ResEditGenDocumentControlClass object
		ds:di	= ResEditGenDocumentControlClass instance data
		ds:bx	= ResEditGenDocumentControlClass object (same as *ds:si)
		es 	= segment of ResEditGenDocumentControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Create a new document with MSG_GEN_DOCUMENT_GROUP_NEW_DOC.
	This will cause ResEdit's usual translation file creation
	mechanism to kick in.  A new translation file will be
	created from the localization file chosen by the user
	in the create file dialog.
	We then send a message to the new document so that it
	gets all the changes specified in the Ascii translation
	file the user specified in ImportAsciiFileSelector.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REGDocumentControlOAIS	method dynamic ResEditGenDocumentControlClass, 
					MSG_RESEDIT_GEN_DOCUMENT_CONTROL_OPEN_ASCII_IMPORT_SELECTED
	.enter
	;
	; Make sure we've been given two file names.
	;
	push	si
	mov	si, offset ImportAsciiFileATFText
	call	DIEGetTextSize
	jcxz	warnUser
	mov	si, offset ImportAsciiFileLocText
	call	DIEGetTextSize
	jcxz	warnUser
	pop	si
	;
	; Remember that we're doing an import.
	;
	mov	{byte}ds:[di].REGDCI_import, 1
	;
	; Create new document.
	;
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	bx, ds:[si].GDCI_documentGroup.handle
	mov	si, ds:[si].GDCI_documentGroup.chunk
	mov	dx, size DocumentCommonParams
	inc	dx
	and	dx, 0xfffe			; for swat
	sub	sp, dx
	mov	bp, sp
	push	dx
	clr	ax
	mov	ss:[bp].DCP_flags, mask DOF_FORCE_REAL_EMPTY_DOCUMENT
	mov	ss:[bp].DCP_diskHandle, ax
	mov	ss:[bp].DCP_connection, ax
	mov	ss:[bp].DCP_docAttrs, mask GDA_UNTITLED
	mov	ax, MSG_GEN_DOCUMENT_GROUP_NEW_DOC
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	pop	dx
	add	sp, dx
exit:
	.leave
	ret
warnUser:
	mov	si, offset WarningNeedTwoFiles	;has not string args
	mov	bl, GIT_NOTIFICATION
	call	DIEWarnUser
	pop	si				;*ds:si=controller
	mov	ax, MSG_RESEDIT_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
	call	ObjCallInstanceNoLock
	jmp	exit
REGDocumentControlOAIS	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REGDocumentControlDisplayDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Causes document control to display the new/open
		dialog.

		Delays delivery of
		MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG a bit to
		make sure it actually comes up.  See Tony's comments
		in cmainUIDocOperations.asm.

CALLED BY:	MSG_RESEDIT_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
PASS:		*ds:si	= ResEditGenDocumentControlClass object
		ds:di	= ResEditGenDocumentControlClass instance data
		ds:bx	= ResEditGenDocumentControlClass object (same as *ds:si)
		es 	= segment of ResEditGenDocumentControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REGDocumentControlDisplayDialog	method dynamic ResEditGenDocumentControlClass, 
					MSG_RESEDIT_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
	.enter

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_IMPORT_CANCELLED
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret
REGDocumentControlDisplayDialog	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Imports an ASCII translation file.

CALLED BY:	MSG_RESEDIT_DOCUMENT_ASCII_IMPORT, which is called
		by InitializeDocumentFile
PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Get name of ASCII translation file (ATF) user selected.
	Warn user if the localization file is newer than the ATF,
	  indicating that the geode has been updated since the
	  ATF was first exported.
	If the user wishes to proceed
	    For each resource in the ATF 
	        For each chunk in the current ATF resource
	            Replace translation text, mnemonic, and shortcut
	              of DB file with that specified in the ATF, 
	              placing deleted chunks in Deleted Chunks resource.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDImport	method dynamic ResEditDocumentClass, 
					MSG_RESEDIT_DOCUMENT_ASCII_IMPORT
	uses	ax, cx, dx, bp
FILE_AND_PATH_LOCALS
.warn -unref_local
buffer		local	ImportBufferStruct
.warn @unref_local
	.enter
	call	MarkBusyAndHoldUpInput
	call	FilePushDir
	;
	; Get name and path of ASCII (DOS) file (the ATF).
	;
	mov	cx, offset ImportAsciiFileATFText
	mov	dx, cx
	call	DIEGetImpExpFileNameAndPath	;cx=0 or disk handle
	jc	doneAfterDealloc
	jcxz	doneAfterDealloc		;No string.
	;
	; Clear out the UnmappedChars text object.
	;
	call	DIEClearUnmappedChars
	;
	; Open ATF file, initialize locals and check header.
	;
	call	DIEOpenImportFile		;cx=import file handle
	jc	doneAfterDealloc
	call	GetFileHandle
	call	DIEInitLocals
	call	DIECheckImportHeader
	jc	close
	jz	close
	;
	; Enumerate the ATF, applying changes to DB file.
	;
	call	DIEApplyATF
	call	DIENotifyUserUnmappedChars
	call	DIENotifyUserItemsMissing
	;
	; Close DOS file.
	;
close:
	mov_tr	bx, cx				;bx=file handle
	clr	al
	call	FileClose			;ax=error code
	jc	errorClosing

done:
	call	DIEDeallocBuffers
doneAfterDealloc:
	call	FilePopDir
	call	MarkNotBusyAndResumeInput
	.leave
	ret
errorClosing:
	mov	cx, EV_COULD_NOT_CLOSE_FILE
	call	DIENotifyError
	jmp	done
REDImport	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIENotifyUserItemsMissing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If necessary, tell user about ATF entries that the
		user wanted to import, but for which there were no
		corresponding DB items.
		
CALLED BY:	REDImport only
PASS:		ss:bp	- inherited locals
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIENotifyUserItemsMissing	proc	near
	.enter inherit REDImport

	test	ss:[buffer].IBS_parseStatus, 
		mask IPF_itemsMissing
	jz	done
	push	si
	mov	si, offset ImportAsciiFileItemsMissing
	call	DIEInitiateInteractionCommon
	pop	si

done:
	.leave
	ret
DIENotifyUserItemsMissing	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEInitLocals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes ImportBufferStruct local variable.

CALLED BY:	REDImport only
PASS:		ss:bp	- inherited ImportBufferStruct
		bx	- db file
		cx	- ATF file
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEInitLocals	proc	near
	.enter inherit REDImport

	clr	ss:[buffer].IBS_buffStatus
	mov	ss:[buffer].IBS_parseStatus, mask IPF_importing
	mov	ss:[buffer].IBS_keyword, -1
	mov	ss:[buffer].IBS_dbFile, bx
	mov	ss:[buffer].IBS_atfFile, cx
	clr	ss:[buffer].IBS_bytesUnchkd
	clr	ss:[buffer].IBS_impPos
	clr	ss:[buffer].IBS_impBuffer
	clr	ss:[buffer].IBS_unfPos
	clr	ss:[buffer].IBS_unfBuffer
	clr	ss:[buffer].IBS_resource
	clr	ss:[buffer].IBS_resourcePos
	clr	ss:[buffer].IBS_chunk
	clr	ss:[buffer].IBS_chunkPos
	mov	ss:[buffer].IBS_rscGroup, -1
	mov	ss:[buffer].IBS_rscItem, -1
	mov	ss:[buffer].IBS_mnemonicType, -1
	mov	ss:[buffer].IBS_mnemonicChar, -1

	.leave
	ret
DIEInitLocals	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REFSNotifyText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make either text1 or text2 be the selected file name
		and toggle the state field.

CALLED BY:	MSG_RESEDIT_FILE_SELECTOR_NOTIFY_TEXT
PASS:		*ds:si	= ResEditFileSelectorClass object
		ds:di	= ResEditFileSelectorClass instance data
		ds:bx	= ResEditFileSelectorClass object (same as *ds:si)
		es 	= segment of ResEditFileSelectorClass
		ax	= message #
		cx 	= entry # of selection made
		bp	= GenFileSelectorEntryFlags

RETURN:		nothing
DESTROYED:	ax,cx,dx,bp (bx,si,di, es but this is a message)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If user double-clicked a file
		If (ATF text is blank) {
		   set ATF text to name of file double-clicked
		   set ATF text state to modified
		}
		Else if (loc text is blank) {
		   set loc text to name of file double-clicked
		   set loc text state to modified
		}
		Else if (ATF text state != modified) {
		   set ATF text to name of file double-clicked
		   set ATF text state to modified
		}
		else { /* loc text state must be !=modified */
		   set loc text to name of file double-clicked
		   set loc text state to modified
		}
	}
	/* else do nothing (user d-clicked a directory, probably) */

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REFSNotifyText	method dynamic ResEditFileSelectorClass, 
					MSG_RESEDIT_FILE_SELECTOR_NOTIFY_TEXT
	.enter
	;
	; Is user opening a file?
	;
	test	bp, mask GFSEF_OPEN
	LONG	jz	exit
	mov	ax, bp
	and	ax, mask GFSEF_TYPE 
	cmp	ax, GFSET_FILE shl offset GFSEF_TYPE
	LONG	jnz	exit
EC <	test	bp, mask GFSEF_ERROR				>
EC <	ERROR_NZ RESEDIT_INTERNAL_ERROR				>
EC <	test	bp, mask GFSEF_SHARED_SINGLE or \
		    mask GFSEF_SHARED_MULTIPLE			>
EC <	ERROR_NZ RESEDIT_INTERNAL_ERROR				>
	;
	; Get name of file selected.
	;
CheckHack < (FILE_LONGNAME_BUFFER_SIZE/2)*2 eq FILE_LONGNAME_BUFFER_SIZE >
	sub	sp, FILE_LONGNAME_BUFFER_SIZE
	mov	cx, ss
	mov	dx, sp					;cx:dx=buffer
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	call	ObjCallInstanceNoLock
	;
	; Which text, if any, is blank?
	;
	push	bp					;rem local var
	push	cx,dx
	mov	si, offset ImportAsciiFileATFText
	call	DIEGetTextSize				;cx<-size
	jcxz	modifyText
	mov	si, offset ImportAsciiFileLocText
	call	DIEGetTextSize				;cx<-size
	jcxz	modifyText
	;
	; Get modified states of texts.
	;
	mov	si, offset ImportAsciiFileATFText
	mov	ax, MSG_GEN_TEXT_IS_MODIFIED
	call	ObjCallInstanceNoLock
	jnc	modifyText
	mov	si, offset ImportAsciiFileLocText
	;
	; Set text's name to be the file name, and set text modified.
	;
modifyText:
	pop	cx,dx
	push	cx,dx
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	ObjCallInstanceNoLock
	pop	dx,bp					;dx:bp=buffer
	clr	cx					;null term.	
	mov	ax, MSG_VIS_TEXT_REPLACE_SELECTION_PTR
	call	ObjCallInstanceNoLock

	or	cx, 1					;non-zero
	mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
	call	ObjCallInstanceNoLock
	pop	bp					;rstr local

	add	sp, FILE_LONGNAME_BUFFER_SIZE

exit:
	.leave
	ret
REFSNotifyText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEGetTextSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the number of characters in the ATF or loc text
		object.

CALLED BY:	REGDocumentControlOAIS,
PASS:		*ds:si	- text object
RETURN:		cx	- size
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEGetTextSize	proc	near
	uses	ax,dx
	.enter

	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	call	ObjCallInstanceNoLock
EC <	tst	dx						>
EC <	ERROR_NZ RESEDIT_INTERNAL_ERROR		;filename!?!	>
	mov_tr	cx, ax

	.leave
	ret
DIEGetTextSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REITSetModifiedState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If passed cx says "you're modified," the text then 
		gets AsciiImportFileSelector's path, and tells the
		other* text that it* is not modified.

		*Other:  If text is atf, then tell the loc.
			 If text is loc, then tell the atf.

CALLED BY:	MSG_GEN_TEXT_SET_MODIFIED_STATE
PASS:		*ds:si	= ResEditImpTextClass object
		ds:di	= ResEditImpTextClass instance data
		ds:bx	= ResEditImpTextClass object (same as *ds:si)
		es 	= segment of ResEditImpTextClass
		ax	= message #
		cx	- non-zero to mark modified, 
			  zero to mark unmodified
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp (and the rest -- msg handler)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REITSetModifiedState	method dynamic ResEditImpTextClass, 
					MSG_GEN_TEXT_SET_MODIFIED_STATE
pathName	local	PathName
	.enter

	mov	di, si
	mov	si, ds:[si]
	add	si, ds:[si].GenText_offset
	and	ds:[si].GTXI_stateFlags, not mask GTSF_MODIFIED
	jcxz	exit
	or	ds:[si].GTXI_stateFlags, mask GTSF_MODIFIED
	;
	; We're modified.  First get file selector's path.
	;
	push	bp				     ;stack integrity
	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset ImportAsciiFileSelector   ;bxsi=file slctr
	mov	ax, MSG_GEN_PATH_GET
	mov	cx, size PathName
	mov	dx, ss
	lea	bp, ss:pathName
	call	ObjCallInstanceNoLock		     ;cx=disk handle
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR		>
	mov_tr	si, di				     ;*ds:si=textobj
	;
	; Set our own path.
	;
	mov	ax, MSG_GEN_PATH_SET
	mov_tr	dx, bp
	mov_tr	bp, cx				    ;bp=disk handle
	mov	cx, ss				    ;cx:dx=pathName
	call	ObjCallInstanceNoLock
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR		>
	;
	; Set other text not modified.
	;
	mov	di, offset ImportAsciiFileLocText
	cmp	si, offset ImportAsciiFileATFText
	je	gotOther
	mov	di, offset ImportAsciiFileATFText
EC <	cmp	si, offset ImportAsciiFileLocText	>
EC <	ERROR_NE RESEDIT_INTERNAL_ERROR			>
gotOther:
	mov_tr	si, di
	mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
	clr	cx				    ;not modified
	call	ObjCallInstanceNoLock
	pop	bp				    ;restore stack
exit:
	.leave
	ret
REITSetModifiedState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEGetImportFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the name of the localization file associated 
		with the ascii file being imported.

CALLED BY:	InitializeDocumentFile
PASS:		es:di	- map block
		ax	- offset of text object
RETURN:		Carry set did not get the file name
		ax - ErrorValue
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEGetImportFileName	proc	far
	uses	cx,dx,si,di,bx
passedAX	local	word	push ax
	.enter

	push	ds:[LMBH_handle]

	GetResourceHandleNS	FileMenuUI, bx
	mov	si, ax
	call	ConstructRelativePath
	jc	error

	; get the file name from the text object
	;
	GetResourceHandleNS	FileMenuUI, bx
	mov	si, ss:[passedAX]			;^lbx:si=text
	push	bp
	lea	dx, es:[di].TMH_sourceName
	mov_tr	bp, dx
	mov	dx, es					;dx:bp=buffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL 
	call	ObjMessage
	pop	bp
	clc
error:
	pop	bx
	call	MemDerefDS

	.leave
	ret
DIEGetImportFileName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECheckIfImporting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets carry flag if the user is importing an ASCII
		translation file.

CALLED BY:	InitializeDocumentFile,
		DIEDisplayDialogAfterErrorIfNecessary
PASS:		nothing
RETURN:		carry	- set if we are importing an ATF
			- clear if not importing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECheckIfImporting	proc	far
	uses	ax,bx,si,di,cx
	.enter

	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset ResEditDocumentControl
	mov	ax, MSG_RESEDIT_GEN_DOCUMENT_CONTROL_GET_IMPORT_FLAG
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;cl = flag
EC <	cmp	di, MESSAGE_NO_ERROR	>
EC <	ERROR_NE RESEDIT_INTERNAL_ERROR	>
	clr	ch
	clc
	jcxz	done
	stc
done:
	.leave
	ret
DIECheckIfImporting	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEDoneImporting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We're done importing, so have the doc control
		clear its flag.

CALLED BY:	InitializeDocumentFile
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEDoneImporting	proc	far
	uses	ax,bx,si,di
	.enter

	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset ResEditDocumentControl
	mov	ax, MSG_RESEDIT_GEN_DOCUMENT_CONTROL_CLR_IMPORT_FLAG
	clr	di
	call	ObjMessage
EC <	cmp	di, MESSAGE_NO_ERROR	>
EC <	ERROR_NE RESEDIT_INTERNAL_ERROR	>

	.leave
	ret
DIEDoneImporting	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REGDControlGetImportFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns import flag, which indicates whether user is
		importing an ASCII translation file right now.

CALLED BY:	MSG_RESEDIT_GEN_DOCUMENT_CONTROL_GET_IMPORT_FLAG
PASS:		*ds:si	= ResEditGenDocumentControlClass object
		ds:di	= ResEditGenDocumentControlClass instance data
		ds:bx	= ResEditGenDocumentControlClass object (same as *ds:si)
		es 	= segment of ResEditGenDocumentControlClass
		ax	= message #
RETURN:		cl	= flag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REGDControlGetImportFlag	method dynamic ResEditGenDocumentControlClass, 
					MSG_RESEDIT_GEN_DOCUMENT_CONTROL_GET_IMPORT_FLAG
	.enter

	mov	cl, {byte}ds:[di].REGDCI_import

	.leave
	ret
REGDControlGetImportFlag	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REGDControlClrImportFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the doc control's import flag.

CALLED BY:	MSG_RESEDIT_GEN_DOCUMENT_CONTROL_CLR_IMPORT_FLAG
PASS:		*ds:si	= ResEditGenDocumentControlClass object
		ds:di	= ResEditGenDocumentControlClass instance data
		ds:bx	= ResEditGenDocumentControlClass object (same as *ds:si)
		es 	= segment of ResEditGenDocumentControlClass
		ax	= message #
RETURN:		cl	= flag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REGDControlClrImportFlag	method dynamic ResEditGenDocumentControlClass, 
					MSG_RESEDIT_GEN_DOCUMENT_CONTROL_CLR_IMPORT_FLAG
	.enter

	clr	{byte}ds:[di].REGDCI_import

	.leave
	ret
REGDControlClrImportFlag	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEDisplayDialogAfterErrorIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An error occured in InitializeDocumentFile, so we 
		might want to display the new/open/import dialog.
		We will want to if we were trying to import.

CALLED BY:	InitializeDocumentFile only
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEDisplayDialogAfterErrorIfNecessary	proc	far
	uses	ax,bx,di,si

	call	DIECheckIfImporting
	jnc	done

	.enter

	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset ResEditDocumentControl
	mov	ax, MSG_RESEDIT_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
EC <	cmp	di, MESSAGE_NO_ERROR	>
EC <	ERROR_NE RESEDIT_INTERNAL_ERROR	>

	.leave

done:
	ret
DIEDisplayDialogAfterErrorIfNecessary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEOpenImportFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens the ATF, our import file.
		Also sets the threads path.

CALLED BY:	REDImport
PASS:		cx	- disk handle
		ss:bp	- inherited locals
RETURN:		cx	- file handle
		if carry, cx = ErrorValue
DESTROYED:	nothing
SIDE EFFECTS:	
	May fixup ds (which happens to hold segment
	of ResEditDocumentObject).

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEOpenImportFile	proc	near
	uses	ax,bx,dx,ds
	.enter inherit REDImport
	push	ds:[LMBH_handle]
	;
	; Set up path.
	;
	mov_tr	bx, cx
	segmov	ds, ss, cx
	lea	dx, ss:pathName
	call	FileSetCurrentPath
	mov	cx, EV_PATH_NOT_FOUND
	jc	error
	;
	; Open the new import file.
	;
	mov	al, FE_DENY_WRITE shl offset FAF_EXCLUDE or \
		    FA_READ_ONLY  shl offset FAF_MODE
	clr	cx				;No special FileAttrs
	lea	dx, ss:fileName
	call	FileOpen			;ax=file handle or
						;error code
	mov	cx, EV_ERROR_OPENING_FILE
	jc	error
	mov_tr	cx, ax
	clc					;no error
done:
	pop	bx
	call	MemDerefDS
	.leave
	ret
error:
	stc
	call	DIENotifyError
	jmp	done
DIEOpenImportFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECheckImportHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the header of the ATF for version mismatch
		between ATF and localiztion file.

CALLED BY:	REDImport
PASS:		*ds:si	- ResEditDocument
		ss:bp	- inherited locals, ImportBufferStruct
RETURN:		carry	- set if error
		zf	- clear if should proceed with import
			- set if import should be aborted
DESTROYED:	nothing
SIDE EFFECTS:	
	ds gets fixed if necessary
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECheckImportHeader	proc	near
	uses	cx,dx,ax,bx,si
	.enter inherit REDImport
	or	ss:[buffer].IBS_parseStatus, 
		mask IPF_checkingHeader
	;
	; First get protocol major and minor numbers.
	;
	mov	cl, REKT_VERSION
	mov	ss:[buffer].IBS_buffStatus, mask IBF_NOT_IN_TEXT
	call	DIEFindNextKeyword	
	jc	error
	call	DIESkipWhiteSpace
	jc	error
	call	DIEReadProtocolNumber	
	jc	error
	mov_tr	dx, ax				;dx = major
	call	DIESkipWhiteSpace
	jc	error
	mov	al, C_COMMA
	call	DIECheckIsChar
	jc 	error
	jnz	error				;no match
	call	DIEAdvanceOneByte
	jc	error
	call	DIEReadProtocolNumber		;ax = minor
	jc	error
	;
	; Now compare those to protocol from localization file.
	;
	push	ds:[LMBH_handle]
	call	GetFileHandle			; bx = handle
	call	DBLockMap_DS			; *ds:si <- ResourceMap
	mov	si, ds:[si]
	mov	bx, ds:[si].TMH_version.PN_major
	cmp	bx, dx
	jg	geodeIsNewer
	mov	bx, ds:[si].TMH_version.PN_minor
	cmp	bx, ax
	jg	geodeIsNewer
	call	DBUnlock_DS
	pop	bx
	call	MemDerefDS
	clc
	clz	cl
done:
	mov	ss:[buffer].IBS_parseStatus, 
		mask IPF_importing	       ;(don't worry about
					       ;other flags right now)
	.leave
	ret

error:
	mov	cx, EV_ERROR_PARSING_HEADER
	call	DIENotifyError
	jmp	done

geodeIsNewer:
	mov	si, offset WarningGeodeNewer	; has not string args
	mov	bl, GIT_AFFIRMATION
	call	DIEWarnUser
	stz	bl				; set zf
	jc	gotit
	clz	bl				; clr zf
gotit:
	call	DBUnlock_DS
	pop	bx
	call	MemDerefDS
	clc
	jmp	done
DIECheckImportHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEApplyATF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the DB file agree with the ATF.
		Enumerate the ATF, applying resource/chunk changes
		to the DB of the passed document.

CALLED BY:	REDImport
PASS:		*ds:si	- ResEditDocument
		ss:bp	- inherited locals, ImportBufferStruct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Fixes up ds.
PSEUDO CODE/STRATEGY:
		For all resources
			While haven't encountered end of resource
				Scan to [chunk] keyword;
				Find chunk of that name in DB;
				If don't find, apply the following
				 steps to a chunk in Deleted Chunks rsc.
				Scan to [translated] keyword;
				Load trans text into unfBuffer;
				Replace DB text w/ unfBuffer text;
				Scan to [mnemonic] keyword;
				Replace DB mnemonic w/ ATF mnemonic;
				Scan to [shortcut] keyword;
				Replace DB shortcut w/ ATF shortcut;



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEApplyATF	proc	near
	uses	bx,cx
	.enter inherit REDImport
	push	ds:[LMBH_handle],si
	call	GetFileHandle			; bx = handle
	;
	; Clear out the deleted items text object.
	;
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	DIECallMissingItemsText
	;
	; Lock the resource array.
	;
	call	DBLockMap_DS			; *ds:si <- ResourceMap
	push	ds:[LMBH_handle]

resourceScan:
	call	DIEGetNextResource
	jc	unlock				;err or no more rsc`s
	jz	resourceScan			;rsc not found
	
	call	DIEApplyATFToChunks
	jc	evalCarry			;err, or all done
	
	jmp	resourceScan

unlock:
	pop	bx
	call	MemDerefDS
	call	DBUnlock_DS

	pop	bx,si
	call	MemDerefDS			; restore document
	.leave
	ret
	;
	; Error or all done with this resource.
evalCarry:
	tst	cl
	stc
	jz	unlock				;error occurred
	clc
	jmp	resourceScan			;goto next resource
DIEApplyATF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEGetNextResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the next resource in the ATF.

CALLED BY:	DIEApplyATF
PASS:		ss:bp	- inherited locals
		*ds:si	- ResourceMap (already locked)
RETURN:		carry	- set if done (Was no next resource,
			  or an error occurred.  Either way,
			  we're done.)
		zf	- set if should skip to next resource
			  b/c this one wasn't in the loc file
			  (meaningless if carry set)
DESTROYED:	nothing
SIDE EFFECTS:	
	Fixes up ds.
PSEUDO CODE/STRATEGY:
	Scan ahead until find beginning of a resource.
	Copy resource name to IBS_resource.
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEGetNextResource	proc	near
	uses	cx,ax,bx,si,es,di,dx
	.enter inherit REDImport
	push	ds:[LMBH_handle],si
	;
	; Skip to just after [resource] keyword.
	;
	mov	cl, REKT_RSRC_BEGIN
	mov	ss:[buffer].IBS_buffStatus, mask IBF_NOT_IN_TEXT
	call	DIEFindNextKeyword
	jc	done
	;
	; Copy keyword (on export, we ended it with a CRLF).
	;
	clr	ss:[buffer].IBS_resourcePos	;Overwrite prev name
	mov	ah, BT_RESOURCE
	mov	al, C_CR
	call	DIECopyTillChar			;save name
	jc	done				;some err
	stc
	jz	done				;hit eof
	;
	; Find the resource in the DB.
	;
	mov	si, BT_RESOURCE
	call	DIELockBuffer
	segmov	es, ds, bx
	mov_tr	di, si				;es:di=rsc name
	mov	cx, ss:[buffer].IBS_resourcePos	;(CopyTillChar changed pos)
	popdw	bxsi
	pushdw	bxsi
	call	MemDerefDS			;*ds:si = ResourceMap
	clr	dx				;Don't copy data
	call	NameArrayFind			;ax = token
	jnc	rscNotFound
	call	ChunkArrayElementToPtr		;ds:di=elt, cx=size
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR		>
	mov	bx, ds:[di].RME_data.RMD_group
	mov	ss:[buffer].IBS_rscGroup, bx
	mov	bx, ds:[di].RME_data.RMD_item
	mov	ss:[buffer].IBS_rscItem, bx

	clr	bl
	inc	bl				;clr zf 
	clc					;no errors
unlock:
	mov	bx, es:[LMBH_handle]
	call	MemUnlock

done:
	pop	bx,si
	call	MemDerefDS
	.leave
	ret
rscNotFound:
	mov	ss:[buffer].IBS_parseStatus,
		mask IPF_itemsMissing or mask IPF_importing
						;(Don't care about
						;other IP flags.)
	mov	al, REKT_RSRC_BEGIN
	call	DIERecordMissingItem
	xor	bl, bl				;set zf (and clr cf)
	jmp	unlock
DIEGetNextResource	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEApplyATFToChunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply ATF to all chunks in the current resource.

CALLED BY:	DIEApplyATF
PASS:		ss:bp	- inherited locals
		*ds:si	- ResourceMap (already locked)
RETURN:		carry	- set if error occurred or done w/
			  chunks for this resource
		   cl	- used if carry set
			  0 if error occurred
			  nonzero if done w/ chunks for this rsc
DESTROYED:	ch
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEApplyATFToChunks	proc	near
	uses	ax,di,bx
	.enter inherit REDImport
	push	ds:[LMBH_handle],si
	;
	; Get the resource's name array.
	;
	mov	ax, ss:[buffer].IBS_rscGroup
	mov	di, ss:[buffer].IBS_rscItem
	call	DBLock_DS			;*ds:si = chunk name array
	;
	; For each ATF chunk in this resource, find it and apply it to DB.
	;
chunkScan:
	call	DIEGetNextChunk			;ds:di = chunk in array
	jc	evalCarry			;err or no more chunks
	jz	chunkScan			;chunk not found

EC <	DIECheckIfExportableChunk		>
EC <	ERROR_Z RESEDIT_INTERNAL_ERROR		>
	clr	cl				;Prepare for errors.
	clr	{byte}ss:[buffer].IBS_mnemonicType
	clr	{byte}ss:[buffer].IBS_mnemonicChar

	call	DIEApplyATFToTrans
	jc	doneScan

	call	DIEApplyATFToMnemonic
	jc	doneScan

	call	DIEApplyATFToShortcut
	jc	doneScan

	call	DIESaveNewTransText
EC <	call	ECCheckChunkArray		>

	jmp	chunkScan

doneScan:
	call	DBUnlock_DS
	pop	bx,si
	call	MemDerefDS
	.leave
	ret
	;
	; Error occurred, or there are no more chunks in this rsc.
evalCarry:
	tst	cl
	stc
	jz	doneScan			;error occurred
	clc
	jmp	doneScan			;done w/ this rsc
DIEApplyATFToChunks	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEGetNextChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the next chunk in the ATF.

CALLED BY:	DIEApplyATFToChunks
PASS:		ss:bp	- inherited locals
		*ds:si	- chunk name array (already locked)
RETURN:		ds:di	- points to name array elt for the next chunk
		carry	- set if done (was no next chunk, or
			  error occurred)
		   cl	- used only if carry is set
			  0 if error occurred
			  nonzero if done w/ chunks in this rsc
		zf	- set if chunk not found in loc file
			  (meaningless if carry set)

DESTROYED:	ch
SIDE EFFECTS:	
	Fixes up ds.
PSEUDO CODE/STRATEGY:
	Scan ahead until find a chunk.
	Copy resource name to IBS_chunk.
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEGetNextChunk	proc	near
	uses	ax,bx,si,es,dx
	.enter inherit REDImport
	push	ds:[LMBH_handle],si
	;
	; Skip to just after [chunk] keyword.
	;
	mov	cl, REKT_CHUNK
	mov	ss:[buffer].IBS_buffStatus, mask IBF_NOT_IN_TEXT or \
					mask IBF_CHECK_IN_RSC
	call	DIEFindNextKeyword
	jc	evalNoFind
	clr	cl				;Prepare for errors.
	;
	; Copy keyword (on export, we ended it with a CRLF).
	;
	clr	ss:[buffer].IBS_chunkPos	;Overwrite prev name
	mov	ah, BT_CHUNK
	mov	al, C_CR
	call	DIECopyTillChar			;save name
	jc	done
	stc
	jz	done
	;
	; Find the resource in the DB.
	;
	mov	si, BT_CHUNK
	call	DIELockBuffer
	segmov	es, ds, bx
	mov_tr	di, si				;es:di=chunk name
	mov	cx, ss:[buffer].IBS_chunkPos	;(CopyTillChar changed pos)
	popdw	bxsi
	pushdw	bxsi
	call	MemDerefDS			;*ds:si = chunkarray
	clr	dx				;Don't copy data
	call	NameArrayFind			;ax = token
	jnc	chunkNotFound
	call	ChunkArrayElementToPtr		;ds:di=elt, cx=size
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR		>
	clr	bl
	inc	bl				;clr zf
	clc					;no errors
unlock:
	mov	bx, es:[LMBH_handle]
	call	MemUnlock

done:
	pop	bx,si
	call	MemDerefDS
	.leave
	ret
	;
	; Didn't find chunk in db.
chunkNotFound:
	mov	ss:[buffer].IBS_parseStatus, 
		mask IPF_itemsMissing or mask IPF_importing
						;(Don't care about
						;other flags.)
	mov	al, REKT_CHUNK
	call	DIERecordMissingItem
	xor	bl, bl				;set zf, clr cf
	jmp	unlock
	;
	; Didn't find chunk keyword in ATF.
evalNoFind:
	tst	cl
	stc
	jz	done				;EOF or err occurred
EC <	test	cl, mask IBF_CHECK_IN_RSC	>
EC <	ERROR_Z	RESEDIT_INTERNAL_ERROR		>
	stc
	jmp	done				;done w/ this rsc
DIEGetNextChunk	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEApplyATFToTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the translated text from the import buffer and
		makes it the translated text for chunk we're currently
		modifying with ATF changes (this modified chunk exists
		in the DB file).

CALLED BY:	DIEApplyATFToChunks
PASS:		ss:bp	- inherited locals
		*ds:si	- chunk name array (already locked)
		ds:di	- chunk name array element of the chunk
			  for which we want to set its translation
			  text
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEApplyATFToTrans	proc	near
	uses	cx,ax,es,bx,dx
	.enter inherit REDImport
EC <	call	ECCheckChunkArray		>
	;
	; Skip to beginning of translation text.
	;
	mov	cl, REKT_TRANS_TEXT
	mov	ss:[buffer].IBS_buffStatus, mask IBF_NOT_IN_TEXT or \
					mask IBF_CHECK_IN_RSC
	call	DIEFindNextKeyword
	jc	done
	clr	ss:[buffer].IBS_buffStatus	;NO FLAGS! esp
						;"NO_TEXT" (see
						;CheckFoundMatchingChar)
	mov	al, C_LEFT_BRACE
	call	DIEScanForChar
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR		>
	jc	done
	stc
	jz	done				;hit the eof
	;
	; Copy translated text to unfBuffer, unformatting it.
	;
	clr	ss:[buffer].IBS_unfPos		;Overwrite prev text
	mov	ah, BT_UNFORMAT
	call	DIECopyTillChar
	jc	done
	stc
	jz	done
	call	DIENullTermBuffer		;(cf may be set)

done:
	.leave
	ret
DIEApplyATFToTrans	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEApplyATFToMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the mnemonic from the ATF and applies it to its
		chunk.

CALLED BY:	DIEApplyATFToChunks
PASS:		ss:bp	- inherited locals
		*ds:si	- chunk name array (already locked)
		ds:di	- chunk name array element of the chunk
			  for which we want to set the mnemonic
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Scan ahead for [mnemonic], but stay within this resource
	and fail if another keyword is encountered before [mnemonic].
	Check if null or esc is the mnemonic.  Otherwise it's just
	the char *immediately* after [mnemonic].  (Recall that the
	last char of the mnemonic keyword is a char; that is, the
	keyword is "[mnemonic  ] ".
	Save mnemonic to the passed chunk.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEApplyATFToMnemonic	proc	near
	uses	dx,cx,ax,es,di,bx,si
	.enter inherit REDImport
EC <	call	ECCheckChunkArray		>
	push	ds:[LMBH_handle]
	;
	; Skip ahead to mnemonic char or null/esc keyword.
	;
	mov	cl, REKT_MNEMONIC
	mov	ss:[buffer].IBS_buffStatus, mask IBF_NOT_IN_TEXT or \
					mask IBF_CHECK_IN_RSC or \
					mask IBF_NO_INTERMEDIATES
	call	DIEFindNextKeyword
	jc	done

	call	DIEFillBufferIfNecessaryFixupDS
	jc	done				; some error
	stc
	jz	done				; hit eof
	;
	; Whatever we are (obj or text), we might have a mnemonic,
	; so get it.
	;
EC <	DIECheckIfExportableChunk		>
EC <	ERROR_Z RESEDIT_INTERNAL_ERROR		>
	;
	; Check if null or esc is the mnemonic.
	;
	mov	cl, REKT_NULL_MNEMONIC
	call	DIELockKeyword			;ds:dx=kywd,cx=lngth
	call	DIECompareStrings
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	mov	al, C_NULL
	jc	gotChar

	mov	cl, REKT_ESC_MNEMONIC
	call	DIELockKeyword			;ds:dx=kywd,cx=lngth
	call	DIECompareStrings
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	mov	al, C_ESC
	jc	gotChar
	;
	; Not a keyword, so must be the char at our position.
	;
	mov	si, BT_IMPORT
	call	DIELockBuffer
	add	si, {word}ss:[buffer].IBS_impPos
	mov	al, {byte}ds:[si]		;al<- mnemonic char
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	;
	; Save mnemonic info.
gotChar:
	mov	{byte}ss:[buffer].IBS_mnemonicChar, al
	call	DIEMakeMnemonicOffset		;ah<-mnemonic offset
	mov	{byte}ss:[buffer].IBS_mnemonicType, ah
	clc

done:
	pop	bx
	call	MemDerefDS
	.leave
	ret
DIEApplyATFToMnemonic	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEMakeMnemonicOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figures out the mnemonic's offset.

CALLED BY:	DIEApplyATFToMnemonic
PASS:		al	- mnemonic char
		ss:bp	- inherited locals
RETURN:		ah	- mnemonic offset
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If mnemonic=null
	   type<-VMO_NO_MNEMONIC
	Else if mnemonic=esc
	   type<-VMO_CANCEL
	Else {
	   scan for mnemonic in chunk
	   If not found
	      type<-VMO_MNEMONIC_NOT_IN_MKR_TEXT
	   Else
	      type<-position of match (0 indexed)
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEMakeMnemonicOffset	proc	near
	uses	bx,cx,dx,si,di,es
	.enter inherit REDImport

	mov	ah, VMO_NO_MNEMONIC
	cmp	al, C_NULL
	je	exit
	mov	ah, VMO_CANCEL
	cmp	al, C_ESC
	je	exit

	mov	si, BT_UNFORMAT
	call	DIELockBuffer				;ds:si=trans txt
	segmov	es, ds, cx
	mov_tr	di, si
	mov	dx, {word}ss:[buffer].IBS_unfPos	;txt length
	mov	cx, dx
	mov	ah, VMO_MNEMONIC_NOT_IN_MKR_TEXT	;assume won't find
	repne	scasb
	jnz	unlock					;didn't find
	sub	dx, cx
	dec	dx
EC <	tst	dh					>
EC <	ERROR_NZ RESEDIT_INTERNAL_ERROR	;looong moniker!>
	mov	ah, dl

unlock:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
exit:
	.leave
	ret
DIEMakeMnemonicOffset	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEApplyATFToShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the shortcut from the ATF and applies it to its
		chunk.

CALLED BY:	DIEApplyATFToChunks
PASS:		ss:bp	- inherited locals
		*ds:si	- chunk name array (already locked)
		ds:di	- chunk name array element of the chunk
			  for which we want to set the shortcut
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Scan ahead for [shortcut], but stay within this resource
	and fail if another keyword is encountered before [shortcut].
	Check for letters A (for alt), S (shift), C (ctrl) and P 
	(physical) preceeding a comma.
	The char*immediately* after the comma is the shortcut char (so
	it could be a space).
	Save shortcut to the passed chunk.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEApplyATFToShortcut	proc	near
	uses	cx,dx,bx
	.enter inherit REDImport
EC <	call	ECCheckChunkArray		>
	push	ds:[LMBH_handle]
	;
	; Skip ahead to shortcut keyword.
	;
	mov	cl, REKT_SHORTCUT
	mov	ss:[buffer].IBS_buffStatus, mask IBF_NOT_IN_TEXT or \
					mask IBF_CHECK_IN_RSC or \
					mask IBF_NO_INTERMEDIATES
	call	DIEFindNextKeyword
	jc	done
	;
	; If we're not an object type, ignore shortcut info.
	; (We check now b/c we wanted to scan ahead regardless of type.)
	;
EC <	DIECheckIfExportableChunk		>
EC <	ERROR_Z RESEDIT_INTERNAL_ERROR		>
	DIECheckIfObjectChunk
	clc
	jz	done
	;
	; Get the shortcut and save it.
	;
	call	DIEGetShortcut			;dx<-shortcut
	jc	done

	pop	bx
	push	bx
	call	MemDerefDS			;ds:di = array elt

	call	DIESaveNewShortcut
	clc

done:
	pop	bx
	call	MemDerefDS
	.leave
	ret
DIEApplyATFToShortcut	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIESaveNewShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the passed shortcut as the shortcut for the
		passed ResourceArrayElement.

CALLED BY:	
PASS:		dx	- shortcut
		ds:di	- ResourceArrayElement
		*ds:si	- array of chunks for current resource
		ss:bp	- inherited locals
RETURN:		ds:di	- ResourceArrayElement (corrected)
		*ds:si	- array of chunks (corrected)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIESaveNewShortcut	proc	near
	uses	ax,bx,cx,dx,es
	.enter inherit REDImport
	;
	; Save shortcut into resource array element.
	;
	mov	ds:[di].RAE_data.RAD_kbdShortcut, dx
	mov_tr	ax, dx				; ax<-shortcut
	mov_tr	bx, di				; bx<-elt offset
	;
	; Transform shortcut into text string.  
	;
CheckHack < (SHORTCUT_BUFFER_SIZE/2)*2 eq SHORTCUT_BUFFER_SIZE >
	sub	sp, SHORTCUT_BUFFER_SIZE
	mov	di, sp
	segmov	es, ss, dx			;es:di = buffer

	call	ShortcutToAscii			; cx <- string length w/NULL
	;
	; Allocate or reallocate a trans item for it.
	;
	push	cx,di				;save shortcut lngth,offset
DBCS <	shl	cx, 1				;cx <- string size w/NULL>

	mov_tr	dx, si				;*ds:dx=array of chunks
	mov_tr	si, bx				;ds:si=ResourceArrayElement
	call	DIEAllocNewTransItem		;cx <- new item
	mov_tr	dx, bx				;*ds:dx=array
						;ds:si=array elt.

	mov_tr	di, cx				; di <- transItem
	pop	cx,ax				; restore buffer length,offset
	xchg	si, ax				; restore offset
	;
	; copy the shortcut text to the item
	;
	push	ds:[LMBH_handle],ax,dx		;save block, elt, array
	mov	bx, ss:[buffer].IBS_dbFile
	mov	ax, ss:[buffer].IBS_rscGroup
	call	DBLock
	mov	di, es:[di]			;es:di <- destination
	segmov	ds, ss, ax			;ds:si <- source buffer
	LocalCopyNString
	call	DBDirty
	call	DBUnlock
	pop	bx,di,si
	call	MemDerefDS

	add	sp, SHORTCUT_BUFFER_SIZE	;free the buffer

	.leave
	ret
DIESaveNewShortcut	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEGetShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the shortcut from the import buffer.

CALLED BY:	DIEApplyATFToShortcut only
PASS:		ss:bp	- inherited locals
RETURN:		dx	- KeyboardShortcut
		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEGetShortcut	proc	near
	uses	ax,bx,cx,si
	.enter inherit REDImport

	call	DIESkipWhiteSpace		;(also fills buffer)
	jc	exit2				;error occurred
	jz	exit				;hit eof
	mov	si, BT_IMPORT
	call	DIELockBuffer			;ds:si=buffer
	add	si, {word}ss:[buffer].IBS_impPos
	mov	cx, 4				;max # modifiers
	clr	bx				;no modifiers yet
scan:
	lodsb					;al<-char
	cmp	al, C_COMMA
	je	afterModifiers
	mov	dx, mask KS_ALT
	cmp	al, C_CAP_A
	je	gotModifier
	mov	dx, mask KS_SHIFT
	cmp	al, C_CAP_S
	je	gotModifier
	mov	dx, mask KS_CTRL
	cmp	al, C_CAP_C
	je	gotModifier
	mov	dx, mask KS_PHYSICAL
	cmp	al, C_CAP_P
	je	gotModifier
	jmp	illegalShortcut
gotModifier:
	or	bx, dx				;update modifiers tally
	loop	scan
	inc	si
afterModifiers:
	dec	si				;back up to comma
	lodsb
	cmp	al, C_COMMA
	jne	illegalShortcut
	clr	ah
	lodsb					;al <- shortcut char?
	cmp	{byte}ds:[si], C_LF		;No. Just CR of CRLF
	je	noShort				;from export.

	mov	cl, offset KS_CHAR
	shl	ax, cl
	or	ax, bx				;ax = KeyboardShortcut
	mov_tr	dx, ax

unlock:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
exit:
	clc
exit2:
	.leave
	ret
illegalShortcut:
	push	ds
	mov	ax, offset ErrorIllegalShortcut
	mov	cx, ss:[buffer].IBS_chunkPos	;chunk name length
	mov	si, BT_CHUNK
	call	DIELockBuffer			;ds:si=name
	call	DIEWarnUserWithName
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	pop	ds
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	jmp	exit2
noShort:
	clr	dx
	jmp	unlock
DIEGetShortcut	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIENullTermBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Null terminates the passed buffer (NOT imp buffer),
		and updates the position of that buffer.

CALLED BY:	DIEApplyATFToTrans
PASS:		ss:bp	- inherited locals
		ah	- BufferType
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	
	Fixes up ds.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIENullTermBuffer	proc	near
	uses	bx,si,cx
	.enter inherit REDImport
EC <	cmp	ah, BT_IMPORT		>
EC <	ERROR_E	RESEDIT_INTERNAL_ERROR	>
	push	ds:[LMBH_handle]
	;
	; Lock target buffer.
	;
	mov	bl, ah
	clr	bh
	mov	si, bx
	call	DIELockBuffer			;ds:si=buffer
	;
	; Do we need to make this buffer bigger?
	;
	call	DIEGetPosAddr			;ss:[bx]=pos
	mov	ax, ss:[bx]
	ChunkSizePtr	ds,si,cx		;cx = chunk size
EC <	cmp	cx, 0			>
EC <	ERROR_LE RESEDIT_INTERNAL_ERROR	>
	cmp	ax, cx
	jge	enlargeBuffer
	;
	; Copy null char, advance buffer position, and unlock buffer.
	;
bufferBigEnough:
	add	si, ax				;ds:si=dest byte
	mov	{byte}ds:[si], C_NULL
	inc	ax
	mov	ss:[bx], ax			;advance pos
	clc					;no error
unlock:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	pop	bx
	call	MemDerefDS
	.leave
	ret

enlargeBuffer:
	add	cx, BUFFER_INCR
	call	DIEEnlargeBufferIfNeeded
	jc	unlock
	jmp	bufferBigEnough
DIENullTermBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECopyTillChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads everything from the current position until the
		specified char (not including) into the passed buffer.
		Source buffer is impBuffer, and passed buffer is
		unfBuffer, resource or chunk.

CALLED BY:	DIEGetNextResource
PASS:		ss:bp	- inherited locals
		ah	- BufferType -- dest. buffer 
		al	- character to look for (SBCS)
			  (unless ah=BT_UNFORMAT)
RETURN:		carry	- set if error
		zf	 - set if hit EOF looking for char in al
DESTROYED:	nothing
SIDE EFFECTS:	
	Fixes up ds.
PSEUDO CODE/STRATEGY:
	We know that ScanAheadCommon locks IBS_importBuffer.
	Let's take advantage of this and just pass the offset
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECopyTillChar	proc	near
	uses	si,bx
	.enter inherit REDImport
	push	ds:[LMBH_handle]
	;
	; First make sure dest has some space.
	;
	mov	bl, ah
	clr	bh
	mov	si, bx
	call	DIELockBuffer			;ds:si=buffer
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	;
	; Do the copy.
	;
	call	DIECopyTillCharLow
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR		;some err >
;EC <	ERROR_Z RESEDIT_ATF_ERROR		;hit eof  >

	pop	bx
	call	MemDerefDS
	.leave
	ret
DIECopyTillChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECopyTillCharLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy characters from IBS_importBuffer to specified
		destination buffer.

CALLED BY:	CopyTillChar, via ScanAheadCommon
PASS:		al	- char we're going to stop at 
			  (unless ah=BT_UNFORMAT)
		ah	- BufferType
		ss:bp	- inherited locals, ImportBufferStruct
			- *set up status before calling this!*
RETURN:		zf	- set if EOF reached before finding al
			- clr if copied successfully until al
		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		IBS_importBuffer, passed in ds:di, is already
		locked, and so is our destination buffer since
		it's in the same resource.

		We must already have storage set aside for the
		destination buffer (see CopyTillChar above).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECopyTillCharLow	proc	near
	uses	bx,ds,si,di,cx
	.enter inherit REDImport

EC <	cmp	ah, BT_IMPORT			>
EC < 	ERROR_E	RESEDIT_INTERNAL_ERROR		>
	mov	si, BT_IMPORT
	call	DIELockBuffer
	mov_tr	di, si			;ds:di = source buffer
	clr	dh
	mov	dl, ah
	mov	si, dx
	mov	dx, di			;ds:dx = source buffer
	call	DIELockBuffer		;ds:si = dest buffer
	call	DIEGetPosAddr		;ss:bx = IBS_???Pos
	;
	; Outer scan used to refill buffer with bytes from ATF.  Inner
	; scan (scanBuffer) just scans the filled bufer.
	;
scan:
	mov	di, dx
	call	DIEFillBufferIfNecessaryFixupDS
	jc	exit
	jz	done				;hit the EOF
	add	di, ss:[buffer].IBS_impPos	;ds:di=where left off
	mov	cx, ss:[buffer].IBS_bytesUnchkd
EC <	cmp	cx,0					>
EC <	ERROR_Z	RESEDIT_INTERNAL_ERROR			>
scanBuffer:
	call	DIECopyCharToBuffer
	jc	exit				;error occurred
	jnz	done
	inc	ss:[buffer].IBS_impPos		;Nope.  Try next char.
	dec	ss:[buffer].IBS_bytesUnchkd
	inc	di
	loop	scanBuffer
	jmp	scan				;Reload buffer & try
						;again
done:
	clc
exit:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock			;for both
	call	MemUnlock			;dest & source

	.leave
	ret
DIECopyTillCharLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECopyCharToBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the char in ds:di is not the same as the char
		passed in al (the stop char), then copy it to the
		buffer.  (Unless copying to unformatted buffer, in
		which case we undouble doubled braces -- there is
		no stop char in al.)

CALLED BY:	DIECopyTillCharLow only
PASS:		ss:bx	- position of first unused byte in the
			  destination buffer (an index, not the 
			  actual byte)
		ds:di	- source char
		ds:si	- destination buffer
		ah	- BufferType: if BT_UNFORMAT, then copy all
			  but the delimiter {,} and undouble any
			  internal {{,}}.  Ignore al.
		al	- character to stop at (unless BT_UNFORMAT)
RETURN:		zf	- clear if al is the stop character
		carry	- set if error occurred
DESTROYED:	nothing
SIDE EFFECTS:	
	If we're copying to the unformat buffer, then the position
	in the import buffer will be updated to be the character after
	the terminal right brace (}).

PSEUDO CODE/STRATEGY:
		Note that unlike impBuffer, the other buffers
		grow in size to accomodate long resource names,
		chunk names or translation text.  Although 
		chunks should not get as large as 65536 bytes!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECopyCharToBuffer	proc	near
	uses	bx,cx,ax
	.enter

	cmp	ah, BT_UNFORMAT
	jne	checkChar
	call	DIECheckOKForUnformatCopy
	jnz	done			;found terminal RB (zf clr)
	jnc	done			;skip this char (a brace)
	jmp	copy			;copy this char

checkChar:
	cmp	al, {byte}ds:[di]
	je	stopChar

copy:
	mov	ax, ss:[bx]		;ax = position
	ChunkSizePtr	ds,si,cx	;cx = chunk size
EC <	cmp	cx, 0			>
EC <	ERROR_LE RESEDIT_INTERNAL_ERROR	>
	cmp	ax, cx
	jge	enlargeBuffer

bufferBigEnough:
	mov	cl, {byte}ds:[di]
	add	ax, si			; ds:[ax]=dest byte
	xchg	ax, si
	mov	{byte}ds:[si], cl	; Store it.
	xchg	ax, si
	inc	{word}ss:[bx]		; Next pos is new pos.
	stz	cl

done:
	clc
exit:
	.leave
	ret
stopChar:
	clz	cl
	jmp	done
enlargeBuffer:
	add	cx, BUFFER_INCR
	call	DIEEnlargeBufferIfNeeded
	jc	exit
	jmp	bufferBigEnough
DIECopyCharToBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECheckOKForUnformatCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines whether the character in ds:di can be
		copied to the unformatted buffer.

CALLED BY:	DIECopyCharToBuffer only, when BufferType is
		BT_UNFORMAT
PASS:		ss:bp	- inherited locals
RETURN:		carry	- set if should copy this char
			- clr if should not copy this char
		zero	- set if should examine other chars
			- clr if found the terminal right brace
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	When this routine is *first* called by CopyCharToBuffer, ds:di
	must point to the leading { of a text region, and IBS_buffStatus
	must be clear.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECheckOKForUnformatCopy	proc	near
	uses	ax
	.enter inherit REDImport

	lahf
	and	ah, not (mask CPU_ZERO or mask CPU_CARRY)	
						;assume won't copy and
						;will stop
	mov	al, {byte}ss:[buffer].IBS_buffStatus

	cmp	{byte}ds:[di], C_LEFT_BRACE
	je	leftBrace
	and	al, not mask IBF_LB_RUN_PARITY

	cmp	{byte}ds:[di], C_RIGHT_BRACE
	je	rightBrace
	;
	; If RB parity is odd and encountered a nonRB, we're done.
	;
	test	al, mask IBF_RB_RUN_PARITY
	jnz	done
	or	ah, mask CPU_ZERO or mask CPU_CARRY

done:
	mov	ss:[buffer].IBS_buffStatus, al
	sahf

	.leave
	ret

leftBrace:
	test	al, mask IBF_LB_RUN_PARITY
	jz	toggleLB
	or	ah, mask CPU_CARRY	;(means do copy)
toggleLB:
	xor	al, mask IBF_LB_RUN_PARITY
	or	ah, mask CPU_ZERO
	jmp	done

rightBrace:
	test	al, mask IBF_RB_RUN_PARITY
	jz	toggleRB
	or	ah, mask CPU_CARRY	;(means do copy)
toggleRB:
	xor	al, mask IBF_RB_RUN_PARITY
	or	ah, mask CPU_ZERO
	jmp	done
DIECheckOKForUnformatCopy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEGetPosAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Points bx to the correct position field in an
		ImportBufferStruct for the passed BufferType.

CALLED BY:	
PASS:		ah	- BufferType
		ss:bp	- inherited locals
RETURN:		ss:bx	- points to position field
		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEGetPosAddr	proc	near
	.enter inherit REDImport

	lea	bx, ss:[buffer].IBS_chunkPos
	cmp	ah, BT_CHUNK
	je	done
	lea	bx, ss:[buffer].IBS_unfPos
	cmp	ah, BT_UNFORMAT
	je	done
	lea	bx, ss:[buffer].IBS_resourcePos
	cmp	ah, BT_RESOURCE
	je	done
	lea	bx, ss:[buffer].IBS_impPos
EC <	cmp	ah, BT_IMPORT			>
EC <	ERROR_NZ RESEDIT_INTERNAL_ERROR		>
done:
	.leave
	ret
DIEGetPosAddr	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEFindNextKeyword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advances the buffer position to the character
		immediately following the next instance of the 
		specified keyword.

		Make *sure* that you set the IBS_buffStatus flags the
		way you want them before calling this routine.  Every
		call will want at least IBF_NOT_IN_TEXT.

		DON'T use this for the keywords "null" and "esc"
		because they don't have leading ['s.

CALLED BY:	
PASS:		ss:bp	- inherited locals, ImportBufferStruct
			  Note:  Make sure you set IBS_buffStatus
		cl	- ResEditKeywordType
RETURN:		carry	- set if couldn't find keyword
			cl  - ImportBufferFlags that could not
			      be satisfied (NO_INTERMEDIATES or
			      CHECK_IN_RESOURCE), or 0 if hit EOF
			      or some other error occurred
DESTROYED:	nothing
SIDE EFFECTS:	
	Fixes up ds
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEFindNextKeyword	proc	near
	uses	dx,ax,bx
	.enter inherit REDImport
EC <	test	ss:[buffer].IBS_buffStatus, mask IBF_NOT_IN_TEXT 	>
EC <	ERROR_Z	RESEDIT_INTERNAL_ERROR				>
	push	ds:[LMBH_handle]
	mov	bx, cx
	;
	; Remember our keyword, in case hit EOF
	mov	{byte}ss:[buffer].IBS_keyword, cl
	;
	; Get the keyword we're looking for.
	clr	ah				; return flags
	call	DIELockKeyword			;ds:dx=kw,cx=lngth
	push	ds:[LMBH_handle]
	;
	; Find [ of keyword in atf, in accordance w/ passed IBS_buffStatus.
	mov	al, C_LEFT_BRACKET
scan:
	call	DIEScanForChar
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR				>
	jc	done
	jz	failed					; [ not found
	call	DIECompareStrings
	jc	foundKeyword
	call	DIECheckIfKeywordSearchFailed		; ah<-flags
	jc	failed
	;
	; Found [, but wrong keyword, so advance position.
	add	ss:[buffer].IBS_impPos, KEYWORD_INCR         ;
	sub	ss:[buffer].IBS_bytesUnchkd, KEYWORD_INCR
	jmp	scan

failed:
	cmp	bl, REKT_CHUNK
	je	afterMsg
	cmp	bl, REKT_RSRC_BEGIN
	je	afterMsg
	call	DIEEvalKeywordFailure
afterMsg:
	stc

done:
	mov_tr	ch, bh					;restore ch
	pop	bx
	call	MemUnlock
	mov_tr	cl, ah					;return flags,
							;if error
	pop	bx
	call	MemDerefDS
	mov	ss:[buffer].IBS_keyword, -1
	.leave
	ret
	;
	; Although pos and bytesUnchkd are updated by ScanForChar,
	; *here* we adjust our pos/unchkd for the successful string
	; comparsion (which did nothing to these indices).
foundKeyword:
	add	ss:[buffer].IBS_impPos, cx		; char after keyword
	sub	ss:[buffer].IBS_bytesUnchkd, cx
	clc
	jmp	done
DIEFindNextKeyword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECheckIfKeywordSearchFailed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A left bracket '[' was found.  If we've been scanning 
		for left brackets with IBF_NOT_IN_TEXT (as we should),
		then we must be at a keyword.  Check if we've violated
		any passed IBS_buffStatus flags.

CALLED BY:	DIEFindNextKeyword only
PASS:		ss:bp	- inherited locals
		ah	- 0
RETURN:		ah	- ImportBufferFlags that weren't met,
			  w/ RSC taking priority over INTERMEDIATES
		carry	- set if search failed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECheckIfKeywordSearchFailed	proc	near
	.enter inherit REDImport
EC <	test	ss:[buffer].IBS_buffStatus, mask IBF_NOT_IN_TEXT 	>
EC <	ERROR_Z	RESEDIT_INTERNAL_ERROR				>
EC <	tst	ah						>
EC <	ERROR_NZ	RESEDIT_INTERNAL_ERROR			>
	;
	; Found some other keyword.
	; If important, check if hit end this resource.
	;
	test	ss:[buffer].IBS_buffStatus, mask IBF_CHECK_IN_RSC
	jz	afterRscCheck
	call	DIECheckIfStillInResource
EC <	ERROR_C RESEDIT_INTERNAL_ERROR		>
	jz	noFindOutsideResource
	;
	; Shall we keep looking?  Or *must* we have found the
	; specified keyword before encountering some other keyword?
	;
afterRscCheck:
	test	ss:[buffer].IBS_buffStatus, mask IBF_NO_INTERMEDIATES
	jnz	noFindIntermediates

	clc
	.leave
	ret

noFindIntermediates:
	mov	ah, mask IBF_NO_INTERMEDIATES
	stc
	.leave
	ret
noFindOutsideResource:
	mov	ah, mask IBF_CHECK_IN_RSC
	stc
	.leave
	ret
DIECheckIfKeywordSearchFailed	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECheckIfStillInResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sees if we have hit the [endresrc] keyword.
		Useful for DIEFindNextKeyword if we want to
		look ahead for a keyword, but don't want to look
		outside of this resource.

CALLED BY:	DIEFindNextKeyword
PASS:		ss:bp	- inherited locals
RETURN:		carry	- set if error
		zf	- set if is [endresrc]
DESTROYED:	nothing
SIDE EFFECTS:	
	Fixes up ds.  (Although nothing really happens
	since the keyword resource is already locked when
	this is called.)
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECheckIfStillInResource	proc	near
	uses	cx,bx,dx
	.enter inherit REDImport
	push	ds:[LMBH_handle]

	mov	cl, REKT_RSRC_END
	call	DIELockKeyword			;ds:dx=keyword,
						;cx=lngth
	call	DIECompareStrings
	stz	cl				;assume same
	jc	unlock
	clz	cl
unlock:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	clc

	pop	bx
	call	MemDerefDS
	.leave
	ret
DIECheckIfStillInResource	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECompareStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the string of length cx in ds:dx with
		the string in the buffer at position IBS_impPos.

CALLED BY:	DIEFindNextKeyword
PASS:		ss:bp	- inherited locals, ImportBufferStruct
		ds:dx	- a string
		cx	- length of string in ds:dx
RETURN:		carry	- set if strings are same
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECompareStrings	proc	near
	uses	bx,di,si,es,ds
	.enter inherit REDImport

	segmov	es, ds, bx
	mov	di, dx				;es:di=string
	mov	si, BT_IMPORT
	call	DIELockBuffer		;ds:si=buffer
	add	si, ss:[buffer].IBS_impPos		;ds:si=string start
	call	LocalCmpStrings
	stc					;assume match
	jz	match
	clc
match:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	.leave
	ret
DIECompareStrings	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEScanForChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scans the ImportBuffer looking for the passed
		character.  Reloads the chunk with bytes from
		the ATF if the char is not found in the chunk.
		Eventually, either the end of the ATF is reached or
		the char is found.

CALLED BY:	
PASS:		ss:bp	- inherited locals.  ImportBufferStruct
		al	- character we're looking for
RETURN:		carry	- set if error
		zf	- set if reached end of file w/o finding char
			- clear if found the character
		ss:bp	- IBS_impPos points to the character found,
			  unless carry set
	
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	(see the note in DIEFileRead)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEScanForChar	proc	near
	uses	cx, dx
	.enter	inherit REDImport
	
	mov	cx, cs
	mov	dx, offset DIECheckFoundMatchingChar
	call	DIEScanAheadCommon

	.leave
	ret
DIEScanForChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECheckIsChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sees if the character at the current position in
		the buffer is the passed character.

CALLED BY:	
PASS:		ss:bp	- inherited locals, ImportBufferStruct
		al	- character (SBCS)
RETURN:		zf	- set if match, clr if not a match
		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	
	The buffer must already have characters in it!
	Fixes up ds.
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECheckIsChar	proc	near
	uses	bx,ds,si
	.enter inherit REDImport
	push	ds:[LMBH_handle]

	mov	si, BT_IMPORT
	call	DIELockBuffer		;ds:si = buffer
	add	si, ss:[buffer].IBS_impPos
	cmp	{byte}ds:[si], al
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	pop	bx
	call	MemDerefDS
	.leave
	ret
DIECheckIsChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEAdvanceOneByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance position in buffer by one byte.

CALLED BY:	DIECheckImportHeader only
PASS:		ss:bp	- inherited locals, ImportBufferStruct
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	
	Fixes up ds.
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEAdvanceOneByte	proc	near
	.enter inherit REDImport

	call	DIEFillBufferIfNecessaryFixupDS
	jc	done
	inc	ss:[buffer].IBS_impPos
	dec	ss:[buffer].IBS_bytesUnchkd
done:
	.leave
	ret
DIEAdvanceOneByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECheckFoundMatchingChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if passed char is the one we're looking for,
		*but* need to be careful if we care about whether the
		character occurs inside of a text ({.....}) region.
		This type of comparison will prevent us from
		identifying [chunk     ] as a keyword if it just 
		happens to be some text in an original or translated 
		chunk.

CALLED BY:	
PASS:		al	- char we're looking for
		ds:di	- char to check
		ss:bp	- inherited locals, ImportBufferStruct
			- *set up status before calling this!*
RETURN:		zf	- clear if we got a match
DESTROYED:	nothing
SIDE EFFECTS:	
	IMPORTANT:  If the target character (in dl) *is* a curly
	brace, then we'd better not care about whether we find
	the brace in a text region ({....}).  If we *do* care,
	the following code probably won't work.  But for our
	parsing purposes, we won't care about curly braces in
	text regions.  Again, the IBF_NOT_IN_TEXT flag is
	just so we won't find keywords inside of text regions.

PSEUDO CODE/STRATEGY:
	Need to see if we've got an *odd* run of adjacent right
	braces because even runs can only be created by the
	formatting applied during export.  For example, if
	we've already encountered a { (? is some char other than }),

		??????????}}}}? means we're still in a text region
		??????????}}}?  means we found the terminal }

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECheckFoundMatchingChar	proc	far
	.enter inherit REDImport

	push	dx,cx
	mov	dl, ss:[buffer].IBS_buffStatus
	mov	dh, {byte}ds:[di]
	cmp	dh, C_LEFT_BRACE
	je	leftBrace
	cmp	dh, C_RIGHT_BRACE
	je	rightBrace
	jmp	checkEndedOddRBRun
charCheck:
	cmp	{byte}ds:[di], al		;Found a match?
	je	matched
	stz	cl				;Whoops.  No match.
done:
	
	mov	{byte}ss:[buffer].IBS_buffStatus, dl
	pop	dx,cx
	.leave
	ret

matched:
	clz	cl
	jmp	done
leftBrace:
	test	dl, mask IBF_NOT_IN_TEXT	;Do we care about {,}?
	je	charCheck
	or	dl, mask IBF_SEEN_LEFT_BRACE	;Remember the first {
						;(or a repeat -- no
						;matter).
	and	dl, not mask IBF_RB_RUN_PARITY	;Start with even
						;parity for }.
	stz	cl				;Reject, as we've
						;entered a {} region.
	jmp	done				
	;
	; Record the parity (odd/even) of right braces.
rightBrace:
	test	dl, mask IBF_NOT_IN_TEXT	;Do we care about {,}?
	je	charCheck
	test	dl, mask IBF_SEEN_LEFT_BRACE
	je	charCheck			;no { yet.
	xor	dl, mask IBF_RB_RUN_PARITY
	stz	cl				;Reject.
	jmp	done
	;
	; A run of } ended (might have seen 0 }).  Check parity.
checkEndedOddRBRun:
	test	dl, mask IBF_NOT_IN_TEXT	;Do we care?
	je	charCheck
	test	dl, mask IBF_SEEN_LEFT_BRACE
	je	charCheck			;Not in text region.
	test	dl, mask IBF_RB_RUN_PARITY
	jne	charCheck			;Odd run, so it's ok
						;to check this char.
	stz	cl				;Did not have an odd
						;run, so reject this
						;char.
	jmp	done
DIECheckFoundMatchingChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIELockBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks the impBuffer or unfBuffer chunk, allocating
		space if necessary.

CALLED BY:	
PASS:		si	- BufferType
RETURN:		ds:si	- the buffer (not a pointer, the 1st byte)
		carry	- set if error (in which case ds:si=garbage)
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIELockBuffer	proc	near
	uses	ax,bx,cx,di
	.enter inherit REDImport

	GetResourceHandleNS	ImportResource, bx
	call	MemLock
	mov	cx, EV_BLOCK_DISCARDED
	jc	error
	mov	ds, ax
	mov_tr	bx, si

	mov	cx, BUFFER_SIZE_SMALL
	lea	di, ss:[buffer].IBS_chunk
	cmp	bl, BT_CHUNK
	je	knowWhichBuffer
	lea	di, ss:[buffer].IBS_resource
	cmp	bl, BT_RESOURCE
	je	knowWhichBuffer

	mov	cx, BUFFER_SIZE_LARGE
	lea	di, ss:[buffer].IBS_impBuffer
	cmp	bl, BT_IMPORT
	je	knowWhichBuffer
	lea	di, ss:[buffer].IBS_unfBuffer
EC <	cmp	bl, BT_UNFORMAT		>
EC <	ERROR_NE RESEDIT_INTERNAL_ERROR >

knowWhichBuffer:
	tst	{word}ss:[di]
	jz	createChunk

gotChunkPtr:
	mov	si, ss:[di]			;si<-chunk handle
	mov	si, ds:[si]			;ds:si=chunk
exit:
	.leave
	ret

createChunk:
	clr	al
	call	LMemAlloc			;ax=chunk handle
	mov	cx, EV_ERROR_ALLOCATING_MEMORY
	jc	error
	mov_tr	ss:[di], ax			;save handle
	lahf					;save cf
	mov	ah, bl
	call	DIEGetPosAddr			;ss:bx = pos
	clr	{word}ss:[bx]
	sahf					;restore cf
	jmp	gotChunkPtr

error:
	call	DIENotifyError
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR		>
	jmp	exit
DIELockBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEFillBufferIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fills the buffer if almost all of its bytes have been
		seen.

CALLED BY:	DIEScanForChar
PASS:		ss:bp	- inherited locals
RETURN:		carry	- set if error
		zero	- set if was necessary to read new bytes,
			  but EOF was reached (that is, we wanted
			  to read more, but hit the EOF)
		ss:bp	- bytesUnchkd gets updated
			- size gets updated
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEFillBufferIfNecessaryFixupDS	proc	near
	uses	bx
	.enter inherit REDImport
	push	ds:[LMBH_handle]
	call	DIEFillBufferIfNecessary
	pop	bx
	call	MemDerefDS
	.leave
	ret
DIEFillBufferIfNecessaryFixupDS	endp

DIEFillBufferIfNecessary	proc	near
	uses	dx,cx
	.enter inherit REDImport

	clr	dx
	mov	cx, ss:[buffer].IBS_bytesUnchkd
	cmp	cx, IMPORT_BUFFER_MIN_LEFT
	jg	readNone
	sub	dx, cx				;Make 1st unchkd byte
						;the first byte in
						;reloaded buffer.
	call	DIEFileRead
	jc	done
	tst	ss:[buffer].IBS_bytesUnchkd
	jz	hitEOF

readNone:
	clr	dl
	inc	dl				;clr zf
	clc
done:
	.leave
	ret
hitEOF:
	call	DIEHitEOF
	xor	dl,dl				;set zf (assume EOF)
	clc
	jmp	done
DIEFillBufferIfNecessary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIELockKeyword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks ResEditKeywordResource and returns a pointer
		to the desired keyword.

CALLED BY:	
PASS:		cl	- ResEditKeywordType
RETURN:		ds:dx	- keyword
		cx	- keyword length
		carry	- set if error occurred (other returned regs
			  invalid if carry set)
DESTROYED:	nothing
SIDE EFFECTS:	
	Don't forget to call MemUnlock if you use this, unless
	an error occured (in the MemLock).

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIELockKeyword	proc	far
	uses	ax,bx,si
	.enter
	;
	; Fetch the element from our table.
	;
	GetResourceHandleNS	ResEditKeywordResource, bx
	call	MemLock
	jc	error
	mov	ds, ax
	mov	si, offset ResEditKeywordResource:ResEditKeywordArray
	mov	si, ds:[si]		;ds:si <- the array
	mov	al, (size  ResEditKeywordArrayStruct)
	mul	cl			;ax = array entry offset
	add	si, ax			;ds:si points to array entry
	;
	; Get length and the actual string.
	;
	clr	ch
	mov	cl, ds:[si].REKAS_length	;cx = keyword length
	mov	si, ds:[si].REKAS_keyword	;si = keyword chunk
	mov	dx, ds:[si]			;dsdx = keyword
	clc
done:
	.leave
	ret

error:
	mov	cx, EV_BLOCK_DISCARDED
	call	DIENotifyError
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR	>
	jmp	done
DIELockKeyword	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEFileRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads some bytes from the ATF into import buffer.
		Then applies LocalDosToGeos to the buffer.

CALLED BY:	
PASS:		ss:bp	- ImportBufferStruct, an  inherited local
		dx	- start reading at dx from current position
RETURN:		ss:bp	- buffer position set to 0
			  buffer bytesUnchkd set to # bytes read
		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The higher routines that scan the buffer will not need to
	worry that the buffer is just a portion of the ATF.  In
	particular, they will not have to worry about keywords
	or text of which only part is in the buffer.  Lower level
	routines, such as DIEScanForChar, will give the higher
	routines the illusion that the buffer contains the whole
	file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEFileRead	proc	near
	uses	ax,bx,cx,dx,si
	.enter inherit REDImport
	;
	; Update file position.
	;
	mov	bx, ss:[buffer].IBS_atfFile
	call	DIESetFilePosRelative
	;
	; Get bytes from ATF.
	;
	mov	si, BT_IMPORT
	call	DIELockBuffer		;ds:si = the chunk
	mov	cx, BUFFER_SIZE_LARGE	;cx = # bytes to read
	call	DIEEnlargeBufferIfNeeded
	jc	exit
	call	DIEClearBuffer
	mov	dx, si				;ds:dx=chunk
	clr	al
EC <	mov	ss:[buffer].IBS_bytesUnchkd, -1	>
	call	DIEFileReadLow			;cx<-# bytes read
	jc	exit
	;
	; Convert buffer.
	;
	mov	ss:[buffer].IBS_bytesUnchkd, cx
	clr	ss:[buffer].IBS_impPos		;Pos at start of chunk.
	mov	ax, C_UNDERSCORE		;Unmatched chars are
	call	DIELocalDosToGeos		; treated as underscore.
EC <	WARNING_C RESEDIT_LOCALDOSTOGEOS_WARNING	>
;j;	jc	handleUnmappables
	clc					; Force cf=0 since 
						; we took out
						; ReadAgainCarefully
exit:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	.leave
	ret

;j;handleUnmappables:
;j;	call	DIEReadAgainCarefully		;carry may be set
;j;	jmp	exit
DIEFileRead	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIELocalDosToGeos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert from GeosToDos or DosToGeos.

CALLED BY:	DIEFileRead
PASS:		ds:si	- buffer
		cx	- number of chars to convert
RETURN:		carry	- set if there were some
			  unmappable chars
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This routine also records any unmappables so that we don't
	have to reread from the file with DIEReadAgainCarefully.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIELocalDosToGeos	proc	near
	uses	dx,bx,cx,ax,si,di
	clc
	jcxz	exit2

	.enter
	mov	di, 2				;(means *no* unmapped chars)
	;
	; Copy one-by-one.
	;
	call	LocalGetCodePage		; bx=navitve code page
	mov_tr	dx, bx				; dx <- code page
	mov	bx, C_UNDERSCORE		; bx <- default char
	
copyOne:
	xchg	cx, dx				;cx=codepage,dx=count
	clr	ah
	mov	al, {byte}ds:[si]		;ax=char to map
	call	LocalDosToGeosChar
	jc	remNoMapper
afterLDTGC:
EC <	tst	ah	>
EC <	ERROR_NZ RESEDIT_INTERNAL_ERROR	>
	mov	{byte}ds:[si], al
	inc	si

	xchg	cx, dx
	loop	copyOne

	sub	di, 1				;if was 0, then cf<-1
	.leave
exit2:
	ret
remNoMapper:
	clr	di				;rem unmapped
	xchg	cx, dx
	call	DIERememberUnmappable
	xchg	cx, dx
	jmp	afterLDTGC
DIELocalDosToGeos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIELocalGeosToDos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert from GeosToDos or DosToGeos.

CALLED BY:	DIEFileWrite
PASS:		ds:si	- buffer
		cx	- number of chars to convert
RETURN:		carry	- set if there were some
			  unmappable chars
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIELocalGeosToDos	proc	far
	uses	dx,bx,cx,ax,si,di
	clc
	jcxz	exit2
	.enter
	mov	di, 2			;(means *no* unmapped chars)
	;
	; Copy one-by-one.
	;
	call	LocalGetCodePage		; bx=navitve code page
	mov_tr	dx, bx				; dx <- code page
	mov	bx, C_UNDERSCORE		; bx <- default char
	
copyOne:
	xchg	cx, dx				;cx=codepage,dx=count
	clr	ah
	mov	al, {byte}ds:[si]		;ax=char to map
	call	LocalGeosToDosChar
	jc	remNoMapper
afterLGTDC:
EC <	tst	ah	>
EC <	ERROR_NZ RESEDIT_INTERNAL_ERROR	>
	mov	{byte}ds:[si], al
	inc	si

	xchg	cx, dx
	loop	copyOne

	sub	di, 1			;if was 0, then cf<-1
	.leave
exit2:
	ret
remNoMapper:
	clr	di			;rem unmapped
	jmp	afterLGTDC
DIELocalGeosToDos	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEReadAgainCarefully
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We just read a bunch of bytes from the ATF, some of
		which were unmappable under LocalDosToGeos.  We now
		need to reread these bytes, LocalDosToGeosChar'ing
		them one at a time, remembering unmappables so that
		we can warn the user.

CALLED BY:	DIEFileRead only
PASS:		ds:si	- buffer to reread into
		cx	- number of bytes to reread
		bx	- file handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DIEReadAgainCarefully	proc	near
	uses	dx,bx,ax,cx,si
	.enter 
EC <	cmp	cx, 0			>
EC <	ERROR_L	RESEDIT_INTERNAL_ERROR	>
	jcxz	doneOK
	;
	; Reposition our file position and reread (undoing the
	; LocalDosToGeos from before).
	;
	clr	dx
	sub	dx, cx				; back up cx bytes
	call	DIESetFilePosRelative
	mov	dx, si				; ds:dx = buffer
	clr	al				; no flags
	push	cx				; save count
	call	DIEFileReadLow
	pop	ax
	jc	exit
	cmp	cx, ax
	stc
EC <	ERROR_NE RESEDIT_INTERNAL_ERROR	;could read once, but not twice?!>
	jne	exit
	;
	; Copy one-by-one.
	;
	call	LocalGetCodePage		; bx=navitve code page
	mov_tr	dx, bx				; dx <- code page
	mov	bx, C_UNDERSCORE		; bx <- default char
	
copyOne:
	xchg	cx, dx				;cx=codepage,dx=count
	clr	ah
	mov	al, {byte}ds:[si]		;ax=char to map
	call	LocalDosToGeosChar		;ax=mapped char
	jc	gotcha
after:
EC <	tst	ah	>
EC <	ERROR_NZ RESEDIT_INTERNAL_ERROR	>
	mov	{byte}ds:[si], al
	inc	si

	xchg	cx, dx
	loop	copyOne

doneOK:
	clc
exit:
	.leave
	ret
gotcha:
	call	DIERememberUnmappable
	jmp	after
DIEReadAgainCarefully	endp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIERememberUnmappable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remember an unmappable character encountered while
		importing.

CALLED BY:	DIEReadAgainCarefully only
PASS:		ds:si	- unmappable character
		cx	- # chars in buffer
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIERememberUnmappable	proc	near
	uses	ax,cx
	.enter 

EC <	cmp	cx, 0			>
EC <	ERROR_L RESEDIT_INTERNAL_ERROR	>
	mov	ax, 8			; print at most 8 chars
	cmp	cx, ax
	jge	warnUser
	mov_tr	ax, cx
	
warnUser:
	mov_tr	cx, ax
	push	si,di
	call	DIERecordUnmappedText
	pop	si,di

	.leave
	ret
DIERememberUnmappable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIESetFilePosRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjusts file position by dx bytes.

CALLED BY:	DIEReadFile, DIEReadAgainCarefully only
PASS:		dx	- distance to move relative to cur pos
		bx	- file handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIESetFilePosRelative	proc	near
	uses	ax,cx,dx
	.enter 

	mov_tr	ax, dx
	cwd					;dx:ax=offset
	mov_tr	cx, dx
	mov_tr	dx, ax
	mov	al, FILE_POS_RELATIVE
	call	FilePos				;dx:ax = new file pos

	.leave
	ret
DIESetFilePosRelative	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEFileReadLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads bytes from the ATF, plus some error 
		checking.

CALLED BY:	DIEFileRead only
PASS:		bx	- FileHandle
		cx	- number of bytes to read
		ds:dx	- buffer into which to read
RETURN:		carry	- set if error
		cx	- number of bytes read (unless error)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEFileReadLow	proc	near
	uses	ax
	.enter

	clr	al			; no flags
	call	FileRead
	jnc	done

	cmp	ax, ERROR_SHORT_READ_WRITE
	clc
	je	done
	mov	cx, EV_ERROR_READING_FILE
	call	DIENotifyError
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR	>
	stc

done:
	.leave
	ret
DIEFileReadLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIERecordChunkWithUnmappableChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the name of the chunk being parsed to the 
		UnmappedChars text object because some chars were
		found that could not be mapped to GEOS chars at
		the time this chunk was being parsed.

CALLED BY:	DIEFileRead only
PASS:		ss:bp	- inherited locals
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	If an unmappable char was found somewhere below
	DIEGetNextChunk, then this will write the chunk name of
	the previous chunk.
	If an unmappable char was found before any chunks had been
	seen, this will write nothing to the text object.
	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DIERecordChunkWithUnmappableChars	proc	near
	uses	cx
	.enter inherit REDImport

	mov	cx, ss:[buffer].IBS_chunkPos
	jcxz	done

	push	si,di,bx
	mov	si, BT_CHUNK
	call	DIELockBuffer
	call	DIERecordUnmappedText
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	pop	si,di,bx

done:
	.leave
	ret
DIERecordChunkWithUnmappableChars	endp
%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEEnlargeBufferIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enlarges the chunk so that it is as big as cx 
		specifies.  (If already that large or larger, does
		nothing).

CALLED BY:	
PASS:		ds:si	- the chunk
		cx	- chunk must be at least this size
RETURN:		carry	- set if error occurred
DESTROYED:	nothing
SIDE EFFECTS:	
	Fixes up ds.  May cause lmem block to be resized, invalidating
	pointers.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEEnlargeBufferIfNeeded	proc	near
	uses	bx
	.enter inherit REDImport

	ChunkSizePtr	ds, si, bx
	cmp	bx, cx			;bx = insertion offset (@ end)
	jge	done

	push	cx,ax
	sub	cx, bx			;cx = # bytes needed
	mov	ax, si
	call	LMemInsertAt
	jc	error
	pop	cx,ax

done:
	.leave
	ret
error:
	mov	cx, EV_ERROR_ALLOCATING_MEMORY
	call	DIENotifyError
	pop	cx,ax
	jmp	done
DIEEnlargeBufferIfNeeded	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEClearBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the buffer.  (This will make debugging much
		easier, but should not be functionally necessary.)

CALLED BY:	DIEFileRead only
PASS:		ds:si	- chunk (buffer) to clear
			  must be a BUFFER_SIZE_LARGE buffer
		ss:bp	- inherited locals
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEClearBuffer	proc	near
	uses	cx,si
	.enter inherit REDImport

	mov	cx, BUFFER_SIZE_LARGE
	jcxz	done
beginLoop:
	clr	{byte}ds:[si]
	inc	si
	loop beginLoop

done:
	.leave
	ret
DIEClearBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEDeallocBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	At the conclusion of importing, we need to get rid of
		the buffers we created.

CALLED BY:	REDImport
PASS:		ss:bp	- inherited locals, ImportBufferStruct
RETURN:		carry	- set if error
DESTROYED:	ds,bx,ax,cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEDeallocBuffers	proc	near
	.enter inherit REDImport

	GetResourceHandleNS	ImportResource, bx
	call	MemLock
	jc	error
	mov	ds, ax
	mov	ax, ss:[buffer].IBS_impBuffer
	tst	ax
	jz	checkUnfBuff
	call	LMemFree

checkUnfBuff:
	mov	ax, ss:[buffer].IBS_unfBuffer
	tst	ax
	jz	checkChunk
	call	LMemFree

checkChunk:
	mov	ax, ss:[buffer].IBS_chunk
	tst	ax
	jz	checkResource
	call	LMemFree

checkResource:
	mov	ax, ss:[buffer].IBS_resource
	tst	ax
	jz	done
	call	LMemFree

done:
	call	MemUnlock
	clc
exit:
	.leave
	ret

error:
	mov	cx, EV_BLOCK_DISCARDED
	call	DIENotifyError
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR	>
	jmp	exit
DIEDeallocBuffers	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIESkipWhiteSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skips ahead until reaches a non-whitespace character
		in the impBuffer (not for unfBuffer).

CALLED BY:	
PASS:		ss:bp	- inherited locals, ImportBufferStruct
RETURN:		carry	- set if error occurred
		zf	- set if EOF reached
DESTROYED:	nothing
SIDE EFFECTS:	
	Fixes up ds.
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIESkipWhiteSpace	proc	far
	uses	cx,dx
	.enter inherit REDImport
	push	ds:[LMBH_handle]

	mov	cx, cs
	mov	dx, offset DIELocalIsNotWhiteSpace
	call	DIEScanAheadCommon

	pop	bx
	call	MemDerefDS
	.leave
	ret
DIESkipWhiteSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIELocalIsNotWhiteSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears zf if passed character is *not* a ws.
		Otherwise sets zf.

CALLED BY:	DIEScanAheadCommon only
PASS:		ds:di	- char to check
RETURN:		zf	- clr (nz) if the character *is* a whitespace
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIELocalIsNotWhiteSpace	proc	far
	uses	ax
	.enter

	clr	ah
	mov	al, {byte}ds:[di]
	call	LocalIsSpace
	lahf
	xor	ah, mask CPU_ZERO	; want opposite of IsSpace
	sahf

	.leave
	ret
DIELocalIsNotWhiteSpace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEReadProtocolNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes a hex number from the run of digits starting
		with the digit at the current buffer position.
		Advances buffer position to character following
		the run of digits.

CALLED BY:	
PASS:		ss:bp	- inherited locals, ImportBufferStruct
RETURN:		carry	- set if error occurred
		ax	- hex number (if cf is clr)
DESTROYED:	nothing
SIDE EFFECTS:	
	Since we're expecting a protocol number, we know the
	run of digits must be expressible in just a word, so
	its ascii string must be no more than 5 digits, for
	"65535".

	Fixes up ds.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEReadProtocolNumber	proc	near
	uses	cx,dx,bx,si,ds
	.enter inherit REDImport
	push	ds:[LMBH_handle]

	call	DIEFillBufferIfNecessary
	jc	exit
	mov	si, BT_IMPORT
	call	DIELockBuffer		;ds:si=buffer
	add	si, ss:[buffer].IBS_impPos
	;
	; 5 bytes for digits, and 1 for null.  Also, we only
	; need to FillBuffer once, as we won't read more than
	; IMPORT_BUFFER_MIN_LEFT.
	mov	cx, 6				; See ProtocolNumber
	sub	sp, cx
	mov	bx, sp
	clr	ah
loadBuff:
	mov	al, {byte}ds:[si]
	call	LocalIsDigit
	jz	gotNum
	mov	{byte}ss:[bx], al
	inc	si
	inc	ss:[buffer].IBS_impPos
	dec	ss:[buffer].IBS_bytesUnchkd
	inc	bx
	loop	loadBuff
	cmp	cx, 0				; Read 6 digits!
	je	error
gotNum:
	cmp	cx, 6
	je	error				; No digit at start.
	mov	{byte}ss:[bx], C_NULL
	;
	; Make a string from a run of digits.
	mov_tr	bx, ds
	mov	si, sp
	segmov	ds, ss, ax
	call	UtilAsciiToHex32		;dx:ax = number (dx=0)
	jc	error
EC <	tst	dx					>
EC <	ERROR_NZ RESEDIT_INTERNAL_ERROR			>
	clc
	mov_tr	ds, bx

done:
	mov_tr	bx, ax
	lahf
	add	sp, 6				;Restore stack
	sahf
	mov_tr	ax, bx
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
exit:
	pop	bx
	call	MemDerefDS
	.leave
	ret
error:
	mov	cx, EV_ERROR_READING_VERSION
	call	DIENotifyError
	stc
	jmp	done
DIEReadProtocolNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEScanAheadCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for scanning ahead until some type of
		character is encountered.  The passed comparsion
		routine should *clear* the zero flag when its condition
		is satisfied.

CALLED BY:	
PASS:		ss:bp	- inherited locals, ImportBufferStruct
		cx:dx	- comparison routine
		ax	- optional argument (see
			  CheckFoundMatchingChar)
RETURN:		carry	- set if error occurred
		zf	- set if EOF reached
			- clr if the condition was satisfied
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEScanAheadCommon	proc	near
	uses	bx,ds,si,di,cx,ax
	.enter inherit REDImport

	mov	si, BT_IMPORT
	call	DIELockBuffer		;ds:si = buffer
	;
	; Remember our comparison routine. 
	;
	CheckHack	< ((size fptr)/2)*2 eq (size fptr) >
	sub	sp, size fptr
	mov	bx, sp
	movdw	ss:[bx], cxdx
	;
	; Outer scan used to refill buffer with bytes from ATF.  Inner
	; scan (scanBuffer) just scans the filled bufer.
	;
scan:
	mov	di, si
	call	DIEFillBufferIfNecessaryFixupDS
	jc	exit
	jz	done				;hit the EOF
	add	di, ss:[buffer].IBS_impPos	;ds:di=where left off
	mov	cx, ss:[buffer].IBS_bytesUnchkd
EC <	cmp	cx,0					>
EC <	ERROR_Z	RESEDIT_INTERNAL_ERROR			>
scanBuffer:
	call	{dword} ss:[bx]
	jnz	done
	inc	ss:[buffer].IBS_impPos		;Nope.  Try next char.
	dec	ss:[buffer].IBS_bytesUnchkd
	inc	di
	loop	scanBuffer
	jmp	scan				;Reload buffer & try
						;again
done:
	clc
exit:
	mov_tr	bl, ah
	lahf
	add	sp, size fptr
	sahf
	mov_tr	ah, bl
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	.leave
	ret
DIEScanAheadCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIESaveNewTransText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the text from the unformat buffer to a DB Item.

CALLED BY:	DIEApplyATFToTrans
PASS:		*ds:si	- locked resource array
		ds:di	- locked ResourceArrayElement
		ss:bp	- inherited locals

RETURN:		*ds:si	- resource array (fixed)
		ds:di	- ResourceArrayElement (fixed)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
    cassie's:
	Allocate or resize the dbitem, by calling AllocNewTransItem,
	passing the new size.  This size must include room for the
	text, VisMoniker structure if necessary, and an extra byte
	for a mnemonic not in the moniker text, if there is one.

	The database item needs to be updated if either the text
	object has been user modified, or the mnemonic has been
	modified.

    JM's:
	On export we stripped the moniker/mnemonic stuff off the
	item, exporting just the text.  Now we must reconstruct the
	VisMoniker (unless the chunk type is just text).

	Because DB allocation may take place in the same item as
	our resource array, the passed pointer -- even the chunk --
	may become invalidated (see Concepts 20.3.4).  So we fix
	them up.

KNOWN BUGS/SIDE EFFECTS/IDEAS:  ds fixed up (see call to AllocNewTransItem)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/20/92		Initial version
	JM	3/24/95			Similiar to Cassie's code, but
					modified for ascii import.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIESaveNewTransText	proc	near
	uses	ax,cx,dx,bx,es
	;
	; Forget whole thing if it's an object.
	;
	DIECheckIfObjectChunk
	jz	start
	ret
start:
	.enter inherit REDImport
	;
	; Can only handle chunks of type we exported.
	;
EC <	DIECheckIfExportableChunk		>
EC <	ERROR_Z RESEDIT_INTERNAL_ERROR		>
	mov_tr	dx, si				;dx saves array
	mov	si, di				;ds:si=array elt

	test	ds:[si].RAE_data.RAD_chunkType, mask CT_MONIKER
	LONG	jz	notMoniker

	; make room for VisMoniker buffer first
	;
	sub	sp, (MONIKER_TEXT_OFFSET+1 and 0xfffe)
	mov	di, sp				;es:di <- buffer

	; cx will hold num bytes
	; add room for the VisMoniker structures
	;
	mov	cx, ss:[buffer].IBS_unfPos	;cx=#chars in text (w/ null)
	add	cx, (MONIKER_TEXT_OFFSET)

	; add the room for mnemonic char if it comes after text
	;
	cmp	ss:[buffer].IBS_mnemonicType, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	noExtra
	inc	cx				;add room for extra byte
noExtra:
	;
	; copy the item's VisMoniker structures into buffer
	;
	segmov	es, ss				;es:di <- buffer
	call	DIECopyVisMoniker
	;
	; Alloc trans item.
	;
	push	di					;save buffer
	call	DIEAllocNewTransItem			;*ds:bx=array
							;ds:si=elt
							;cx=trans item
	pop	di					;restore buffer
	;
	; Save the new text and mnemonic.
	;
	call	DIESaveNewText
	call	DIESaveMnemonic

	mov_tr	di, si					;ds:di=elt
	mov_tr	si, bx					;*ds:si=array
	add	sp, (MONIKER_TEXT_OFFSET+1 and 0xfffe)

done:
	.leave
	ret

notMoniker:
	call	DIESaveTextNotMoniker
	jmp	done
DIESaveNewTransText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIESaveMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves ATF's mnemonic to the db file.

CALLED BY:	DIESaveNewTransText only
PASS:		ss:bp	- inherited locals
		ds:si	- ResourceArrayElement
		cx	- db item to save to
RETURN:		nothing
DESTROYED:	es,ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIESaveMnemonic		proc	near
	.enter inherit REDImport

	mov	ah, ss:[buffer].IBS_mnemonicType
	mov	al, ss:[buffer].IBS_mnemonicChar
	mov	{byte}ds:[si].RAE_data.RAD_mnemonicType, ah
	mov	{byte}ds:[si].RAE_data.RAD_mnemonicChar, al
	call	DIESaveNewMnemonic

	.leave
	ret
DIESaveMnemonic		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECopyVisMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Need to save the VisMoniker structure from the source
		item before it is possibly resized, so that it can be
		copied to the destination item correctly.

CALLED BY:	DIESaveNewTransText
PASS:		es:di 	- buffer
		ds:si	- ResourceArrayElement
		ss:bp	- inherited locals

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/10/93		Initial version
	JM	3/24/95			Similiar to Cassie's code, but
					modified for ascii import.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECopyVisMoniker		proc	near
	uses	ax,bx,cx,si,di,ds
	.enter inherit REDImport

	push	di
	mov	di, ds:[si].RAE_data.RAD_transItem
	mov	ax, ss:[buffer].IBS_rscGroup
	mov	bx, ss:[buffer].IBS_dbFile
	tst	di
	jnz	haveItem
	mov	di, ds:[si].RAE_data.RAD_origItem
haveItem:
	call	DBLock_DS
	mov	si, ds:[si]				;ds:si <- source
	pop	di					;es:di <- destination

	mov	cx, MONIKER_TEXT_OFFSET
	rep	movsb

	call	DBUnlock_DS
	.leave
	ret
DIECopyVisMoniker		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIESaveNewMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The mnemonic has been changed.  
		Save the new mnemonic to the translation item.

CALLED BY:	DIESaveNewTransText

PASS:		ss:bp	- inherited locals
		cx	- translation item to save text into
		ah	- offset of mnemonic, or
				  VMO_CANCEL, or
				  VMO_NO_MNEMONIC, or
				  VMO_MNEMONIC_NOT_IN_MKR_TEXT
		al = mnemonic char

RETURN:		nothing

DESTROYED:	es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/10/93		Initial version
	JM	3/24/95			Similiar to Cassie's code, but
					modified for ascii import.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIESaveNewMnemonic		proc	near
	uses	si,di,bx
	.enter inherit REDImport

	push	ax		
	mov	di, cx
	mov	ax, ss:[buffer].IBS_rscGroup
	mov	bx, ss:[buffer].IBS_dbFile
	call	DBLock
	call	DBDirty
	mov	di, es:[di]
	mov	si, di
	ChunkSizePtr	es, di, bx
	pop	ax

	; save the new mnemonicOffset
	;
	add	di, offset VM_data + offset VMT_mnemonicOffset
	mov	{byte}es:[di], ah

	; if mnemonic comes after text, save that byte, too
	;
	cmp	ah, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	done
	add	si, bx				
	dec	si				;es:di <- last byte of moniker
	mov	{byte}es:[si], al

done:
	call	DBUnlock

	.leave
	ret
DIESaveNewMnemonic		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIESaveNewText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the trans text into DB.

CALLED BY:	DIESaveNewTransText

PASS:		es:di	- buffer holding VisMoniker structures
		cx	- translation item to save text into
		ss:bp	- inherited locals
		ds:si	- ResourceArrayElement

RETURN:		nothing

DESTROYED:	es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/10/93		Initial version
	JM	3/24/95			Similiar to Cassie's code, but
					modified for ascii import.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIESaveNewText		proc	near
	uses	ax,cx,si,ds,di,bx
	.enter inherit REDImport

EC <	push	ds,si				>
	clr	bh
	mov	bl, {byte}ds:[si].RAE_data.RAD_chunkType
EC <	test	bl, mask CT_TEXT		>
EC <	ERROR_Z	RESEDIT_INTERNAL_ERROR		>
	push	bx					;save for later
	segmov	ds, es
	mov	si, di					;ds:si <- VisMoniker

	; lock the item into which text will be saved
	;
	mov	di, cx
	mov	ax, ss:[buffer].IBS_rscGroup
	mov	bx, ss:[buffer].IBS_dbFile
	call	DBLock
	call	DBDirty
	mov	di, es:[di]

EC <	ChunkSizePtr	es, di, bx		>

	pop	cx					;cl = chunk type
	test	cl, mask CT_MONIKER
	jz	notMoniker

	; copy the moniker stuff now
	;
	mov	cx, MONIKER_TEXT_OFFSET			
EC <	sub	bx, cx				>	
	rep	movsb

notMoniker:
	;
	; read the trans text from unfBuffer into the item
	;
	mov	si, BT_UNFORMAT
	call	DIELockBuffer				;ds:si=buffer
	mov	cx, ss:[buffer].IBS_unfPos
EC <	push	cx,bx				>
	rep	movsb
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
EC <	pop	cx,bx				>

;
; does the allocated chunk size (bx) gibe with the string length?
;
EC <	pop	ds,si				>
EC <	cmp	ss:[buffer].IBS_mnemonicType, \
		VMO_MNEMONIC_NOT_IN_MKR_TEXT 	>
EC <	je	noCheck				>	;too complicated
EC <	cmp	bx, cx				>	
EC <	ERROR_NE TEXT_SIZE_DOES_NOT_MATCH_CHUNK_SIZE	>
EC < noCheck:					>

	call	DBUnlock

	.leave
	ret
DIESaveNewText		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIESaveTextNotMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save any changes to text object to database item.

CALLED BY:	DIESaveNewTransText
PASS:		ds:si	- ResourceArrayElement
		ss:bp	- inherited locals
		*ds:dx	- resource array
RETURN:		ds:di	- ResourceArrayElement
		*ds:si	- resource array
		cx	- new translation item
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 8/93		Initial version
	JM	3/24/95			Similiar to Cassie's code, but
					modified for ascii import.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIESaveTextNotMoniker		proc	near
	uses	bx,di
	.enter inherit REDImport

	mov	cx, ss:[buffer].IBS_unfPos	;size of the text
	call	DIEAllocNewTransItem
	call	DIESaveNewText
	mov_tr	di, si			;ds:di=array elt
	mov_tr	si, bx			;*ds:si=array

	.leave
	ret
DIESaveTextNotMoniker		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEAllocNewTransItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates a new trans item, and fixes up
		*ds:dx and ds:si to point to the resource
		array and the passed element, respectively.

CALLED BY:	DIESaveNewTransText, DIESaveTextNotMoniker
PASS:		ss:bp	- inherited locals
		ds:si	- array element
		*ds:dx	- resource array
		cx	- desired size of new item

RETURN:		ds:si	- ResourceArrayElement
		*ds:bx	- resource array
		cx	- translation item to save text into

DESTROYED:	ax,dx,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEAllocNewTransItem	proc	near
	.enter inherit REDImport
	;
	; AllocNewTransItem returns cx = 0 if the new transItem is
	; the same size as the old.
	; Need to unlock our chunk name array for safe DBAllocation
	; b/c chunk of the current element might have changed.
	mov_tr	di, si					;ds:di=elt
	mov_tr	si, dx					;*ds:si=array
	call	ChunkArrayPtrToElement			;ax<-elt #
	push	ax
	mov	bx, ss:[buffer].IBS_dbFile
	mov	ax, ss:[buffer].IBS_rscGroup
	mov	dx, ds:[di].RAE_data.RAD_origItem
	mov	di, ds:[di].RAE_data.RAD_transItem
	call	DBUnlock_DS
	call	AllocNewTransItem			;cx<-new DB item
	mov	di, ss:[buffer].IBS_rscItem		;array's item #
	call	DBLock_DS				;*ds:si<-array
	call	DBDirty_DS
	pop	ax					;ax = elt #
	mov_tr	dx, cx					;save item #
	call	ChunkArrayElementToPtr			;ds:di=array elt
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR	>
	mov_tr	cx, dx
	mov	ds:[di].RAE_data.RAD_transItem, cx	;save new DB item
	mov_tr	bx, si					;*ds:bx=array
	mov_tr	si, di					;ds:si=array elt

	.leave
	ret
DIEAllocNewTransItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIERecordMissingItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the name of the missing item to the
		MissingItems text.

CALLED BY:	DIEGetNextResource, DIEGetNextChunk
PASS:		es:di	- name of missing chunk or resource
		cx	- num bytes in name (there is no null)
		al	- ResEditKeywordType (REKT_RSRC_BEGIN
			  or REKT_CHUNK)
		ss:bp	- inherited locals
RETURN:		nothing
DESTROYED:	nothing (but fixes up ds)
SIDE EFFECTS:	
	Fixes up ds
PSEUDO CODE/STRATEGY:
		bx holds size of stack buffer
		cx holds length of string to print to buffer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIERecordMissingItem	proc	near
	uses	ax,bx,si,dx,di,cx,es
	.enter inherit REDImport
EC <	cmp	al, REKT_RSRC_BEGIN		>
EC <	je	legalKeyword			>
EC <	cmp	al, REKT_CHUNK			>
EC <	je	legalKeyword			>
EC <	ERROR	RESEDIT_INTERNAL_ERROR		>
EC <legalKeyword:				>
	;
	; Prepare buffer.
	;
	push	ds:[LMBH_handle]
	mov	bx, KEYWORD_INCR+2		;kywd lngth+CR+null
	add	bx, cx				;+lngth of name
	cmp	al, REKT_CHUNK
	jne	madeBuffer
	add	bx, ss:[buffer].IBS_resourcePos	;rsc name length
	add	bx, 4				;" in " length
madeBuffer:
	inc	bx
	and	bx, 0xfffe			;(for swat)
	sub	sp, bx
	mov	dx, sp				;ss:dx=buffer
	push	es,di				;save name
	mov	di, dx
	segmov	es, ss				;es:di=buffer
	;
	; Put type of missing item into buffer.
	;
	push	cx,dx				;save name lngth
	mov	cl, al
	call	DIELockKeyword			;ds:dx=keywd,cx=lngth
EC <	cmp	cx, KEYWORD_INCR		>
EC <	ERROR_A RESEDIT_INTERNAL_ERROR		>
	mov_tr	si, dx				;ds:si=keywd
	rep	movsb
	mov_tr	dx, bx				;save buffer size
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	mov_tr	bx, dx
	pop	cx,dx				;retrieve lngth
	;
	; Put name of missing item into buffer.
	;
	pop	ds,si				;retrieve name
	push	cx
	rep	movsb
	pop	cx
	;
	; If printing a chunk, print its resource too.
	;
	cmp	al, REKT_CHUNK
	jne	addCRandNull
	mov	{byte}es:[di], C_SPACE
	inc	di
	mov	{byte}es:[di], C_SMALL_I
	inc	di
	mov	{byte}es:[di], C_SMALL_N
	inc	di
	mov	{byte}es:[di], C_SPACE
	inc	di	
	mov	si, BT_RESOURCE
	call	DIELockBuffer			;ds:si=rsc name
	push	bx
	mov	cx, ss:[buffer].IBS_resourcePos	;rsrc name length
	rep	movsb
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	pop	bx

addCRandNull:
	mov	{byte}es:[di], C_CR		;tack on a CR
	inc	di
	mov	{byte}es:[di], C_NULL		;and null
	;
	; Write to text object.
	;
	clr	cx				;null term buffer
	push	bp
	mov_tr	bp, dx
	mov	dx, ss				;dx:bp=buffer
	mov	ax, MSG_VIS_TEXT_APPEND
	call	DIECallMissingItemsText
	pop	bp
	;
	; Remove buffer.
	;
	add	sp, bx
	pop	bx
	call	MemDerefDS

	.leave
	ret
DIERecordMissingItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIECallMissingItemsText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the MissingItems text.

CALLED BY:	DIERecordMissingItem
PASS:		ax		- msg
		cx,dx,bp	- parameters
RETURN:		nothing
DESTROYED:	ax, and possibly ds (does not fixup)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIECallMissingItemsText	proc	near
	uses	si,di,bx,ax,cx,dx,bp
	.enter 

	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset MissingItems
	mov	di, mask MF_CALL
	call	ObjMessage
EC <	cmp	di, MESSAGE_NO_ERROR	>
EC <	ERROR_NE RESEDIT_INTERNAL_ERROR	>

	.leave
	ret
DIECallMissingItemsText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEInitiateInteractionCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiates the passed interaction (which is in 
		FileMenuUI).

CALLED BY:	REGDocumentControlImport, DIENotifyUserUnmappedChars
PASS:		si	- offset of interaction in FileMenuUI
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEInitiateInteractionCommon	proc	far
	uses	ax,bx,di
	.enter

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	GetResourceHandleNS	FileMenuUI, bx
	clr	di
	call	ObjMessage
EC <	cmp	di, MESSAGE_NO_ERROR	>
EC <	ERROR_NE RESEDIT_INTERNAL_ERROR	>

	.leave
	ret
DIEInitiateInteractionCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEWarnUser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Useful routine for warning user if he's about to export
		to an already existing file, or importing an ATF that
		is older than the geode.

CALLED BY:	DIECheckExportFileExists,DIECheckImportHeader
PASS:		ss:cx	- string arg 1
		ss:dx	- string arg 2
		si	- offset to message in ErrorStrings
			  resource
		bl	- GenInteractionType
RETURN:		carry	- set if user elected *not* to 
			  continue with operation (export or
			  import)
			- clear if user elected to continue
			  with operation
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEWarnUser	proc	far
	uses	ax,ds,bx,si,dx,cx
	.enter

	segmov	ds, ss, ax

	clr	ax
	pushdw	axax				;SDP_helpContext
	pushdw	axax				;SDP_customTriggers
	pushdw	dsdx				;SDP_stringArg2
	pushdw	dscx				;SDP_stringArg1

	mov_tr	dl, bl				;save GenInteractionType
	mov	bx, handle ErrorStrings
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]
	pushdw	dssi				;SDP_customString

	mov	ax, CustomDialogBoxFlags <1, CDT_WARNING,0, 0>
	clr	dh
	mov	cl, offset CDBF_INTERACTION_TYPE
	shl	dx, cl
	or	ax, dx				;plug in GIType
	
	push	ax				;SDP_customFlags
	call	UserStandardDialog
	call	MemUnlock

	cmp	ax, IC_NO
	stc
	je	done				;*NOT* jumping based
						;on cf.  Based on zf.
	clc

done:
	.leave
	ret
DIEWarnUser	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEEvalKeywordFailure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called if DIEFindNextKeyword returned carry set.

CALLED BY:	DIEFindNextKeyword
PASS:		ah	- ImportBufferFlags
		ss:bp	- inherited locals
		carry	- set
RETURN:		carry	- set
DESTROYED:	nothing
SIDE EFFECTS:	
	Strings used in this routine must not take more than
	one string arg, b/c ss:dx will point to garbage when
	DIEWarnUser is called.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEEvalKeywordFailure	proc	near
	uses	ax,bx,cx,dx,si,ds
	.enter inherit REDImport

	cmp	ss:[buffer].IBS_keyword, REKT_VERSION
	je	noVersion
	mov	cl, ah
	cmp	cl, 0
	je	done

	mov	ax, offset ErrorExpectedKeywordInChunk
	mov	si, BT_CHUNK
	mov	dx, ss:[buffer].IBS_chunkPos
	test	cl, mask IBF_NO_INTERMEDIATES
	jnz	knowWhy

	mov	ax, offset ErrorExpectedKeywordInRsc
	mov	si, BT_RESOURCE
	mov	dx, ss:[buffer].IBS_resourcePos
EC <	test	cl, mask IBF_CHECK_IN_RSC	>
EC <	ERROR_Z RESEDIT_INTERNAL_ERROR		; what else could it be!>
	;
	; Put name of chunk in stack buffer, and warn user.
	;
knowWhy:
EC <	cmp	dx, 0				>
EC <	ERROR_LE RESEDIT_INTERNAL_ERROR		>
	mov	cx, dx
	call	DIELockBuffer			;ds:si=name
	call	DIEWarnUserWithName
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

done:
	stc
	.leave
	ret
noVersion:
	mov	dx, sp
	mov	cx, sp
	mov	si, offset ErrorNoVersion	;(has no string args)
	mov	bl, GIT_NOTIFICATION
	call	DIEWarnUser
	jmp	done
DIEEvalKeywordFailure	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEWarnUserWithName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Warns user of some error, with the passed string
		used as the single string argument substituted into
		the warning message.

CALLED BY:	DIEEvalKeywordFailure
PASS:		ds:si	- string
		ax	- offset to error msg in ErrorStrings
		cx	- length of string
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEWarnUserWithName	proc	near
	uses	dx,cx,es,bx,di,si,ax
	.enter
EC <	cmp	cx, 0							>
EC <	ERROR_L RESEDIT_INTERNAL_ERROR					>
EC <	cmp	cx, 100							>
EC <	ERROR_G	RESEDIT_INTERNAL_ERROR		; Hmm.  Be suspicious.	>

	mov	dx, cx
	inc	dx				;for null
	inc	dx				;for swat
	and	dx, 0xfffe			;for swat
	sub	sp, dx

	segmov	es, ss, bx
	mov	di, sp				;es:di=buffer
	rep	movsb				;copy
	mov	{byte}es:[di], C_NULL		;null term
	mov_tr	si, ax				;si<-offset
	mov_tr	ax, dx	
	mov	cx, sp
	mov	dx, sp				;(to be safe)
	mov	bl, GIT_NOTIFICATION
	call	DIEWarnUser

	add	sp, ax
	stc

	.leave
	ret
DIEWarnUserWithName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIEHitEOF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Warns user if the EOF was hit unexpectedly.

CALLED BY:	DIEFillBufferIfNecessary
PASS:		ss:bp	- inherited locals
RETURN:		nothing
DESTROYED:	nothing (but flags are destroyed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIEHitEOF	proc	near
	uses	ax,cx,si,bx,ds
	.enter inherit REDImport
	;
	; Just return if we were looking for a resource,
	; so that we don't complain when *do* hit eof
	; looking for a resource after the last.
	;
	mov	cl, ss:[buffer].IBS_keyword
	cmp	cl, REKT_RSRC_BEGIN
	je	done
	;
	; See if hit eof looking for [version   ].
	;
	cmp	cl, REKT_VERSION
	je	done
	;
	; Tell user about hitting eof.
	;
	mov	ax, offset ErrorHitEOF
	mov	cx, ss:[buffer].IBS_chunkPos	;chunk name length
	jcxz	useResourceName
	mov	si, BT_CHUNK
gotName:
	call	DIELockBuffer			;ds:si=name
	call	DIEWarnUserWithName
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

done:
	.leave
	ret
useResourceName:
	mov	cx, ss:[buffer].IBS_resourcePos
EC <	cmp	cx, 0			>
EC <	ERROR_Z	RESEDIT_INTERNAL_ERROR	>
	mov	si, BT_RESOURCE
	jmp	gotName
DIEHitEOF	endp


DocumentImport		ends
