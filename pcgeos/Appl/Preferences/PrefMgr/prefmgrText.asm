COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Preferences
FILE:		prefmgrText.asm

AUTHOR:		Chris, 12/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial revision

DESCRIPTION:
		
	$Id: prefmgrText.asm,v 1.1 97/04/04 16:27:32 newdeal Exp $

------------------------------------------------------------------------------@


COMMENT @----------------------------------------------------------------------

METHOD:		PrefMgrTextApply -- 
		MSG_TEXT_APPLY for PrefMgrClass

DESCRIPTION:	Handles apply for sound dialog box.

PASS:		es - dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/12/90	Initial version

------------------------------------------------------------------------------@

PrefMgrTextApply	method dynamic PrefMgrClass, MSG_TEXT_APPLY

;	IF THE DICTIONARY CHANGED, CONFIRM AND THEN SHUTDOWN

	mov	ax, es:[newDictionaryInfo]
	cmp	ax, es:[oldDictionaryInfo]
	jnz	checkReboot

	;
	; Reboot not needed, just save settings and scram.
	;

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_APPLY
	mov	bx,  handle TextDialog
	mov	si,  offset TextDialog
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_INTERACTION_COMPLETE
	clr	di
	GOTO	ObjMessage		; <-- EXIT 

		
checkReboot:		

	mov	bx, handle parameterChangeConfirmation
	mov	si, offset parameterChangeConfirmation
	mov	cx, handle dictionaryChangeString
	mov	dx, offset dictionaryChangeString
	call	ConfirmDialog
	jc	exit			;Exit if user cancels

;	WRITE THE DATA OUT TO THE INI FILE

	mov	bx, es:[dictionaryData]
	mov	cx, es:[newDictionaryInfo];CX <- dictionary # the user selected
	call	MemLock
	mov	es, ax
	mov	ax, size DictionaryInfoStruct
	mul	cx
	mov_tr	di, ax			;ES:DI <- ptr to DictionaryInfoStruct

;	WRITE OUT THE LANGUAGE VALUE

	mov	cx, cs
	mov	ds, cx
	mov	al, es:[di].DIS_language
	clr	ah
	xchg	bp, ax			;BP <- language value to write out
	mov	dx, offset LanguageKey
	mov	si, offset TextCategory
	call	InitFileWriteInteger

;	WRITE OUT THE DIALECT VALUE

	mov	bp, es:[di].DIS_dialect
	mov	dx, offset DialectKey
	call	InitFileWriteInteger


;	WRITE OUT THE LANGUAGE NAME

	mov	bp, di
	add	di, offset DIS_languageName
	mov	dx, offset LanguageNameKey	;ES:DI <- language name
	call	InitFileWriteString

	lea	di, es:[bp].DIS_dictName	;ES:DI <- dict name
	mov	dx, offset DictionaryNameKey
	call	InitFileWriteString

	call	MemUnlock

	;
	; Also, be sure to save other options, if changed
	;

	mov	bx, handle TextDialog
	mov	si, offset TextDialog
	mov	ax, MSG_META_SAVE_OPTIONS
	clr	di
	call	ObjMessage 
		
	call	InitFileCommit

	mov	ax, MSG_PREF_DIALOG_REBOOT
	clr	di
	GOTO	ObjMessage			; EXIT HERE ALSO

exit:
	ret
		
PrefMgrTextApply	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLanguageName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the current (or default) language name into the passed
		buffer.

CALLED BY:	VisOpenText

PASS:		DX:BP <- buffer to copy data into

RETURN:		nothing 

DESTROYED:	ax, bx, cx, di, si, ds, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLanguageName	proc	far

	uses	dx, bp

	.enter
		
	mov	es, dx
	mov	di, bp
	mov	cx, cs
	mov	ds, cx
	mov	si, offset TextCategory
	mov	dx, offset LanguageNameKey
	mov	bp, INITFILE_INTACT_CHARS or MAX_LANGUAGE_NAME_LENGTH+1
	call	InitFileReadString
	jnc	found

	mov	bx, handle PrefMgrStrings
	call	MemLock
	mov	ds, ax

	assume ds:PrefMgrStrings
	mov	si, ds:[DefaultDictionaryName]
	ChunkSizePtr	ds, si, cx
	shr	cx, 1

	jnc	10$
	movsb
10$:
	rep	movsw

	assume ds:dgroup
	call	MemUnlock

found:	
	.leave
	ret
GetLanguageName	endp


COMMENT @----------------------------------------------------------------------

METHOD:		PrefMgrTextReset -- 
		MSG_TEXT_RESET for PrefMgrClass

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_TEXT_RESET

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/12/90	Initial version

------------------------------------------------------------------------------@

PrefMgrTextReset	method dynamic PrefMgrClass, MSG_TEXT_RESET

	mov	bx, handle TextDialog
	mov	si, offset TextDialog
	mov	ax, MSG_GEN_RESET
	clr	di
	call	ObjMessage

	FALL_THRU	VisOpenText
PrefMgrTextReset	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisOpenText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	VisOpen handler for the text dialog

CALLED BY:	PrefMgrTextReset, text dialog

PASS:		es - dgroup

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/30/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisOpenText	proc	far

	sub	sp, MAX_LANGUAGE_NAME_LENGTH+2
	mov	bp, sp
	mov	dx, ss		;DX:BP <- dest for language name

	call	GetLanguageName
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle TextCurrentDictionary
	mov	si, offset TextCurrentDictionary
	mov	di, mask MF_CALL 
	call	ObjMessage

	add	sp, MAX_LANGUAGE_NAME_LENGTH+2


	;
	; Read the dictionary directory.  Do this NOW, so that we set
	; the "oldDictionaryInfo" value when the dialog first comes
	; up.  The ChooseDictionaryList will always be set to
	; the "newDictionaryInfo" value when it comes up.
	;

		
	call	TextCloseEditBox		; free old data
		
	clr	es:[numDictionaries]

;	GO TO THE DICTIONARY DIRECTORY

	call	FilePushDir
	mov	bx, SP_PUBLIC_DATA
	segmov	ds, cs
	mov	dx, offset dictionaryDir
	call	FileSetCurrentPath
	LONG jc	noItems

;	READ IN DATA FROM THE VARIOUS GEOS DICTIONARY INFO (GDI) FILES

	sub	sp, size FileEnumParams
	mov	bp, sp
	mov	ss:[bp].FEP_searchFlags, mask FESF_NON_GEOS or \
					mask FESF_CALLBACK
	clr	ss:[bp].FEP_returnAttrs.segment
	mov	ss:[bp].FEP_returnAttrs.offset, FESRT_NAME
	mov	ss:[bp].FEP_returnSize, size FileLongName
	clr	ss:[bp].FEP_skipCount
	clr	ss:[bp].FEP_matchAttrs.segment
	mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
	clr	ss:[bp].FEP_callback.segment
	mov	ss:[bp].FEP_callback.offset, FESC_WILDCARD
	mov	ss:[bp].FEP_cbData1.segment, cs
	mov	ss:[bp].FEP_cbData1.offset, offset dictionaryInfoName
	mov	ss:[bp].FEP_cbData2.low, TRUE	;Be case insensitive
	call	FileEnum
	jc	noItems
					;BX = handle of buffer returned by
					; FileEnum
					;CX = # items returned by FileEnum
	jcxz	noItems

	call	MemLock			;Lock down list of filenames
	mov	ds, ax

	push	bx			;Save handle of list of filenames

	mov	ax, size DictionaryInfoStruct
	push	cx
;
;	Lock the block here - the handle is dereferenced in
;	ReadDictionaryInfoFile().
;
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	es:[dictionaryData], bx	;
	pop	cx			;Restore # files
	clr	di			;ES:DI <- ptr to next place to save
					; dictionary info
	clr	dx			;DS:DX <- ptr to next file to read
10$:
	call	ReadDictionaryInfoFile
	add	es:[numDictionaries], ax
	add	dx,size FileLongName	;Keep looping until all files
	loop	10$			; are read

;	Set the number of dictionaries to display

	call	LoadDictionaryListSetting
	call	MemUnlock		;Unlock dictionary info
	pop	bx			;Restore handle of list of DOS files

	call	MemFree
exit:
	call	FilePopDir
	.leave
	ret

noItems:
	; There are no dictionaries.  Disable spell-checking options
	LoadBXSI	TextSpellGroup
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage 
	jmp	exit


VisOpenText	endp

MAX_DICTIONARIES 	equ	20
SBCS <dictionaryInfoName	char	"*.GDI",0			>
DBCS <dictionaryInfoName	wchar	"*.GDI",0			>
SBCS <dictionaryDir		char	"DICTS",0			>
DBCS <dictionaryDir		wchar	"DICTS",0			>
TextCategory		char	"text",0
LanguageNameKey		char	"languageName",0
LanguageKey		char	"language",0
DialectKey		char	"dialect",0
DictionaryNameKey	char	"dictionary",0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetChooseDictionaryList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the ChooseDictionaryList's setting to the default
		setting. 

CALLED BY:	LoadDictionaryListSetting

PASS:		es - dgroup
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetChooseDictionaryList	proc	near
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, es:[newDictionaryInfo]
	cmp	cx, GIGS_NONE
	jne	10$
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
10$:
	mov	bx, handle ChooseDictionaryList
	mov	si, offset ChooseDictionaryList

	clr	dx	;Do not set indeterminate
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	clr	di
	call	ObjMessage
	.leave
	ret
SetChooseDictionaryList	endp

;
;
;	CODE FOR SELECTING NEW MAIN DICTIONARIES
;
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyCRTerminatedString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies a CR terminated string from the input ptr to the
		output ptr.

CALLED BY:	GLOBAL
PASS:		CX <- max # chars to read in (not counting null)
		DS:SI <- ptr to string (SBCS)
		ES:DX <- ptr to store string (after mapping from DOS char set)
				(DBCS)
RETURN:		SI <- ptr passed CR terminated string
		carry set if null encountered
DESTROYED:	ax, cx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyCRTerminatedString	proc	near
SBCS <	uses	di, bx							>
DBCS <	uses	di, bx, dx						>
	.enter
	call	LocalGetCodePage	; bx <- original code page
	push	bx			; save original code page
	mov	ax, CODE_PAGE_LATIN_1
	call	LocalSetCodePage	; set code page to multilingual

	mov	di, dx
	clr	ah
SBCS <	clr	bx		;bx = default char to use		>
SBCS <				; (Don't use LocalClrChar here, because	>
SBCS <				; we need to clear the whole word even	>
SBCS <				; in SBCS.)				>
DBCS <	mov	bx, CODE_PAGE_LATIN_1	;GDI file is in code page latin 1	>
DBCS <	clr	dx			;disk handle=0, use primary FSD	>

10$:
	lodsb
	cmp	al, C_CR		;If we hit a carriage return, exit
	je	endOfString
	cmp	al, C_LF		;If we hit a line feed, ignore it
	je	10$
	tst	al
	jz	endOfFileReached

	call	LocalDosToGeosChar
	LocalPutChar	esdi, ax
	loop	10$

;	Scan until we hit a CR

scanForCR:
	lodsb
	tst	al
	jz	endOfFileReached
	cmp	al, C_CR
	jne	scanForCR

endOfString:
SBCS <	clr	al							>
SBCS <	stosb								>
DBCS <	clr	ax							>
DBCS <	LocalPutChar	esdi, ax					>
	clc
exit:
	pop	ax			; ax <- original code page
	call	LocalSetCodePage
	.leave
	ret
endOfFileReached:
	dec	si			;DS:SI <- ptr to null
	stc
	jmp	exit
CopyCRTerminatedString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadCRTerminatedDigit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads in a CR/null terminated value

CALLED BY:	GLOBAL
PASS:		DS:SI <- ptr to string (SBCS)
RETURN:		cl <- value 
		carry set if non-digit encountered, or if null encountered
			before any digits
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadCRTerminatedDigit	proc	near
	clr	ah
	clr	cl
10$:
	lodsb
	cmp	al, C_LF		;Ignore linefeeds
	je	10$	
	cmp	al, C_CR		;If we hit the end of the string,
	je	endString		; branch
	tst	al
	jz	endOfFileReached
	call	LocalIsNumChar
       	jz	10$			;If not number character, branch
	sub	al, '0'
	shl	cl, 1
	mov	ch, cl
	shl	cl, 1
	shl	cl, 1
	add	cl, ch			;CL <- CL * 10
	add	cl, al			;Add next numeric value to counter
	jmp	10$
endString:
	cmp	{char} ds:[si], C_LF	;Skip linefeed if one exists
	jne	exit
	inc	si
	clc
exit:
	ret
endOfFileReached:
	dec	si			;DS:SI <- ptr to null
	stc
	jmp	exit
ReadCRTerminatedDigit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadDictionaryInfoFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in information from the passed filename.
		Format of data in block is (repeated arbitrarily many times):

	CR-terminated dictionary filename
	CR-terminated language name (<= 64 bytes)
	CR-terminated language description (<= 256 bytes)
	CR-terminated language value 
	CR-terminated dialect value (128,64,32,16)

CALLED BY:	VisOpenText

PASS:		BX <- handle to store next DictionaryInfoStruct
		DI <- size of block in BX
		DS:DX <- file to read from
		ES - dgroup
RETURN:		DI <- new size of block
		AX <- # DictionaryInfoStructs read in 
DESTROYED:	si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadDictionaryInfoFile	proc	near	uses	es, bx, cx, dx, ds
	fileHandle	local	hptr
	memHandle	local	hptr
	destHandle	local	hptr
	numStructsRead	local	word
	.enter

;	GET SIZE OF FILE

	mov	destHandle, bx
	clr	bx
	mov	fileHandle, bx
	mov	memHandle, bx
	mov	numStructsRead, bx
	mov	ax, FILE_ACCESS_R or FILE_DENY_NONE
	call	FileOpen		;If couldn't open info file, branch
	LONG jc	exit			;
	mov	fileHandle, ax
	xchg	ax, bx			;BX <- handle of file	
	call	FileSize		;DX:AX <- size of file
	tst	dx			;If > 64K, exit
	LONG jnz	exit
	cmp	ax, 8000		;If file > 8K, don't read it in.
	LONG ja	exit
	mov	dx, ax

;	ALLOCATE BUFFER TO HOLD FILE DATA

	inc	ax			;Increment file size (we will null
					; terminate the file)
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc		;If couldn't alloc memory to read it
	jc	exit			; in, branch to exit
	mov	memHandle, bx

;	READ FILE INTO MEMORY

	mov	cx, dx			;CX <- file size
	clr	dx
	mov	ds, ax			;DS:DX <- buffer to read file into
	clr	al
	mov	bx, fileHandle
	call	FileRead		;If error reading file, exit	
	jc	exit
	mov	si, dx
	add	si, ax			;DS:SI <- ptr to the end of the buffer
	mov	{byte} ds:[si], 0	;Null terminate the buffer
	clr	si
	mov	bx, destHandle
loopTop:
;
;	DS:SI <- ptr to info read from dictionary file
;	DI <- current size of block with DictionaryInfoStructs
;	BX <- handle of block with DictionaryInfoStructs
;
	mov	ax, di
	add	ax, size DictionaryInfoStruct
	mov	ch, mask HAF_ZERO_INIT
	call	MemReAlloc
	jc	exit			;Branch if couldn't allocate mem
	mov	es, ax			;ES:DI <- ptr to DictionaryInfoStruct

	mov	cx, DOS_DOT_FILE_NAME_LENGTH	;# bytes in string (w/o null)
	lea	dx, es:[di].DIS_dictName	;ES:DX <- ptr to store string
	call	CopyCRTerminatedString
	jc	exit				;Branch if at end of file

	mov	cx, MAX_LANGUAGE_NAME_LENGTH	;# bytes in string (w/o null)
	lea	dx, es:[di].DIS_languageName	;ES:DX <- ptr to store string
	call	CopyCRTerminatedString
	jc	exit				;Branch if at end of file

	mov	cx, MAX_LANGUAGE_DESCRIPTION_LENGTH
	lea	dx, es:[di].DIS_description
	call	CopyCRTerminatedString
	jc	exit				;Branch if at end of file

	call	ReadCRTerminatedDigit		;
	mov	es:[di].DIS_language, cl	;
	jc	exit				;Branch if reached end of file

	call	ReadCRTerminatedDigit		;
	clr	ch
	mov	es:[di].DIS_dialect, cx		;
	inc	numStructsRead
	add	di, size DictionaryInfoStruct
	cmp	{byte} ds:[si], 0		;If not at end of file, branch
	jnz	loopTop
exit:

;	FREE UP ANY ALLOCATED MEMORY AND CLOSE FILE IF OPENED

	mov	bx, fileHandle
	tst	bx
	jz	90$
	clr	al
	call	FileClose
90$:
	mov	bx, memHandle
	tst	bx
	jz	99$
	call	MemFree
99$:
	mov	ax, numStructsRead
	.leave
	ret
ReadDictionaryInfoFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadDictionaryListSetting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the setting for the ChooseDictionaryList from the
		.INI file.  Store the value in both the
		"oldDictionaryInfo" and the "newDictionaryInfo" fields.

CALLED BY:	VisOpenText

PASS:		es - dgroup
		BX - handle of block containing DictionaryInfoStructs

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp, di, si, ds
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/31/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadDictionaryListSetting	proc	near

	uses	bx
	.enter

	push	bx

	;Load BX with the default language/ dialect values for the system

	mov	bx, mask LD_DEFAULT	or (SL_DEFAULT shl 8)

;	GET LANGUAGE OUT OF INI FILE

	mov	cx, cs
	mov	ds, cx
	mov	dx, offset LanguageKey
	mov	si, offset TextCategory
	call	InitFileReadInteger
	jc	gotLanguage

	mov	bh, al

gotLanguage:

;	GET DIALECT OUT OF INI FILE

	mov	dx, offset DialectKey
	call	InitFileReadInteger
	jc	gotDialect
	mov	bl, al

gotDialect:

	mov	dx, bx			; language / dialect
		
	pop	bx
	clr	si
	call	MemDerefDS		;DS:SI <- ptr to DictionaryInfoStructs
	mov	cx, es:[numDictionaries]
	mov	al, dh
	clr	dh

;	LOOK FOR DIALECT/LANGUAGE FROM INI FILE IN DICTIONARY STRUCTS

loopTop:
	cmp	al, ds:[si].DIS_language	;Compare language/dialect of
	jne	next				; list entry with that in the
	cmp	dx, ds:[si].DIS_dialect		; .ini file
	je	found
next:
	add	si, size DictionaryInfoStruct	;Go to next one
	loop	loopTop
	mov	dx, GIGS_NONE			;Not found. Set excl to NIL
	jmp	setExcl

found:
	mov	dx, es:[numDictionaries]
	sub	dx, cx				;DX <- item # to be exclusive

setExcl:
	mov	es:[oldDictionaryInfo], dx
	mov	es:[newDictionaryInfo], dx
		
	mov	cx, es:[numDictionaries]
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	bx, handle ChooseDictionaryList
	mov	si, offset ChooseDictionaryList
	clr	di
	call	ObjMessage

	call	SetChooseDictionaryList

	.leave
	ret
LoadDictionaryListSetting	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisOpenChooseDictionary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the ChooseDictionaryList to the current value held
		by the parent dialog, so that if the sub-dialog is
		closed and reopend, it will have the same state as the 
		parent. 

CALLED BY:	VisOpen handler for ChooseDictionarySummons

PASS:		ds, es - dgroup

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,bp,es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisOpenChooseDictionary	proc	far

	call	SetChooseDictionaryList
	ret

VisOpenChooseDictionary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTextObjectToFieldInDIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the passed text object to a field in the 
		passed DictionaryInfoStruct

CALLED BY:	TextUpdateDictionaryDescription, TextSetDictionary

PASS:		es - dgroup
		cx - zero-based array index of DictionaryInfoStruct
		^lbx:si - text object
		bp - offset into DictionaryInfoStruct 

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTextObjectToFieldInDIS	proc	near

	uses	bx, si
	.enter

	tst	es:[dictionaryData]
	jz	done

	push	bx
	mov	bx, es:[dictionaryData]
	call	MemLock
	mov	bx, ax		;BX <- segment of block w/data
	mov	ax, size DictionaryInfoStruct
	mul	cx		;AX <- offset to DictionaryInfoStruct
	mov	dx, bx		;DX:BP <- ptr to description
	add	bp, ax
	pop	bx

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx		;Null-terminated string
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	bx, es:[dictionaryData]
	call	MemUnlock
done:
	.leave
	ret
SetTextObjectToFieldInDIS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextUpdateDictionaryDescription
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If just a user change, changes the dictionary description text.
		Else, says that the dictionary changed and says what it changed
		to.

CALLED BY:	ChoseDictionaryList status message

PASS:		ds, es - dgroup

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <nullStr	char	0						>
DBCS <nullStr	wchar	0						>

TextUpdateDictionaryDescription	method	dynamic PrefMgrClass, 
				MSG_TEXT_UPDATE_DICTIONARY_DESCRIPTION
	.enter

;	FIND OUT WHICH ELEMENT IS SELECTED

	cmp	cx, GIGS_NONE
	je	setNullString
	cmp	cx, es:[numDictionaries]
	jae	setNullString

	mov	bp, offset DIS_description
	mov	bx, handle ChooseDictionaryDescription
	mov	si, offset ChooseDictionaryDescription
	call	SetTextObjectToFieldInDIS

exit:
	.leave
	ret

setNullString:
	mov	dx, cs			
	mov	bp, offset nullStr
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle ChooseDictionaryDescription
	mov	si, offset ChooseDictionaryDescription
	mov	di, mask MF_CALL
	call	ObjMessage
	jmp	exit
TextUpdateDictionaryDescription	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextSetDictionary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a new dictionary.

CALLED BY:	APPLY trigger for ChooseDictionarySummons

PASS:		cx - item selected

RETURN:		nada

DESTROYED:	ax,cx,dx,bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextSetDictionary	method	dynamic PrefMgrClass, MSG_TEXT_SET_DICTIONARY
	.enter

	cmp	cx, GIGS_NONE
	je	exit
	
	mov	es:[newDictionaryInfo], cx

	mov	bp, offset DIS_languageName
	mov	bx, handle TextCurrentDictionary
	mov	si, offset TextCurrentDictionary
	call	SetTextObjectToFieldInDIS

;	Make some random object in the dialog applyable so the OK/RESET
;	triggers will get enabled.

	mov	ax, MSG_GEN_MAKE_APPLYABLE
	clr	di
	call	ObjMessage
exit:
	.leave
	ret
TextSetDictionary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCloseEditBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the dictionary data.

CALLED BY:	VisOpen & VisClose handler for TextDialog (called by
		VisOpen handler in the event of a RESET -- we free the
		old block and create a new one).

PASS:		es - dgroup

RETURN:		nothing 

DESTROYED:	bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextCloseEditBox	proc	far

	clr	bx
	xchg	bx, es:[dictionaryData]
	tst	bx
	jz	exit
	call	MemFree
exit:
	ret
TextCloseEditBox	endp
