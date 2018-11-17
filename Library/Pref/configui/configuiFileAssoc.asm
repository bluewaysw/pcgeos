COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Designs in Light 2002 -- All Rights Reserved

FILE:		configuiProgList.asm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include fileEnum.def

ProgListCode	segment	resource


;--------------

FileAssocEntry	struct
    FAE_ext	DosDotFileName		;e.g., *.FNT
    FAE_icon	GeodeToken		;e.g., font,0
    FAE_app	GeodeToken		;e.g., FVWR,0
    FAE_appName	FileLongName		;e.g., Font Viewer
FileAssocEntry	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAssocListBuildArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the list array

CALLED BY:	PrefMgr

PASS:		*ds:si - FileAssocListClass object
		ds:di - FileAssocListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

fileMgrCat char "fileManager",0
filenameTokensKey char "filenameTokens",0

FileAssocListBuildArray	method	dynamic	FileAssocListClass,
					MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
		.enter

		push	ds:OLMBH_header.LMBH_handle
		push	si
	;
	; Create an lmem block for our array
	;
		mov	ax, LMEM_TYPE_GENERAL		;ax <- LMemType
		clr	cx				;cx <- default header
		call	MemAllocLMem
		call	MemLock
		mov	ds, ax				;ds <- seg addr
		push	bx				;save array block
	;
	; Create a chunk array
	;
		mov	bx, (size FileAssocEntry)	;bx <- extra data
		clr	cx				;cx <- default header
		clr	si				;si <- alloc block
		call	ChunkArrayCreate
		mov	bx, si				;*ds:bx <- chunkarray
		push	si				;save array chunk
	;
	; Enumerate the filenameTokens section
	;
		segmov	es, ds				;es <- obj block
		segmov	ds, cs, cx
		mov	si, offset fileMgrCat		;ds:si <- category
		mov	dx, offset filenameTokensKey	;cx:dx <- key
		mov	di, cs
		mov	ax, offset FileAssocListBuildCallback
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 0, 0>
		call	InitFileEnumStringSection
	;
	; Save the array optr for later
	;
		pop	ax				;ax <- array chunk
		pop	bx				;bx <- array block
		mov	dx, bx
		call	MemUnlock
		pop	si
		pop	bx				;^lbx:si <- object
		call	MemDerefDS
		mov	di, ds:[si]
		add	di, ds:[di].ConfigUIList_offset
		movdw	ds:[di].CUILI_array, dxax
	;
	; get the program names
	;
		mov	ax, MSG_FAL_GET_PROGRAM_NAMES
		call	ObjCallInstanceNoLock
	;
	; Sort the list
	;
		mov	ax, MSG_FAL_SORT
		call	ObjCallInstanceNoLock
	;
	; Initialize the list and mark not dirty
	;
		mov	ax, MSG_CUIL_INIT_UI
		call	ObjCallInstanceNoLock
		mov	ax, MSG_CUIL_MARK_NOT_DIRTY
		call	ObjCallInstanceNoLock

		.leave
		ret
FileAssocListBuildArray	endm

;
; Pass:
;	ds:si - string section
;	dx - section #
;	cx - length of section
;	*es:bx - chunkarray

; Return:
;	carry - set to stop enum
;	es - fixed up
;
FileAssocListBuildCallback	proc	far
		uses	bx, di
fae		local	FileAssocEntry
		.enter

		clr	ax
		mov	{word}ss:fae.FAE_app[0], ax
		mov	{word}ss:fae.FAE_app[2], ax
		mov	{word}ss:fae.FAE_app[4], ax
		mov	{byte}ss:fae.FAE_ext[0], al
		mov	{byte}ss:fae.FAE_appName[0], al
	CheckHack <(size GeodeToken eq 6)>

	;
	; parse something of the form:
	;    *.ZIP         = "dZIP",0,"ZipM",16480
	; or:
	;    *.ZIP         = "dZIP",0
	;

	;
	; skip leading white space
	;
		call	SkipSpaces
	;
	; get the extension, e.g., *.ZIP
	;
		mov	di, si				;ds:di <- extension
extLoop:
		mov	al, ds:[si]			;al <- char
		tst	al
		jz	done				;stop if NULL
		cmp	al, '='
		je	afterExt			;done if =
SBCS <		clr	ah				;>
		call	LocalIsSpace
		jnz	afterExt			;done if space
		inc	si
		jmp	extLoop
afterExt:
		mov	cx, si
		sub	cx, di				;cx <- # bytes in name
	;
	; skip =
	;
		call	SkipSpaces
		lodsb					;al <- char
		cmp	al, '='
		jne	done
	;
	; get the icon if any
	;
getIcon::
		push	di
		lea	di, ss:fae.FAE_icon
		call	GetToken
		pop	di
		jc	done				;branch if error
	;
	; skip the comma if any
	;
		call	SkipSpaces
		lodsb					;al <- char
		tst	al
		jz	noApp				;branch if no comma
		cmp	al, ','
		jne	done				;stop if not comma
	;
	; get the app if any
	;
getApp::
		push	di
		lea	di, ss:fae.FAE_app
		call	GetToken
		pop	di
		jc	done				;branch if error
noApp:
	;
	; copy the extension
	;
		push	es
		mov	si, di				;ds:si <- extension
		segmov	es, ss
		lea	di, ss:fae.FAE_ext		;es:di <- dest
		rep	movsb				;copy extension
		clr	al
		stosb					;NULL-terminate
		pop	ds
	;
	; add an element
	;
		mov	si, bx				;*ds:si <- chunkarray
		clr	ax
		call	ChunkArrayAppend
		segxchg	ds, es				;es:di <- element
		lea	si, ss:fae			;ds:si <- fae on stack
		mov	cx, (size FileAssocEntry)	;cx <- # of bytes
		rep	movsb				;copy entry
	;
	; keep processing 
	;
done:
		clc					;carry <- keep going

		.leave
		ret
FileAssocListBuildCallback	endp

SkipSpaces	proc	near
charLoop:
		lodsb					;al <- char
		tst	al
		jz	done				;branch if end
SBCS <		clr	ah				;>
		call	LocalIsSpace			;whitespace?
		jnz	charLoop			;branch if so
done:
		dec	si				;back up to non-WS
		ret
SkipSpaces	endp

SkipSpacesAndComma	proc	near
		call	SkipSpaces
		lodsb					;al <- char
		cmp	al, ','
		jne	doneError
		call	SkipSpaces
		clc
done:
		ret
doneError:
		stc
		jmp	done
SkipSpacesAndComma	endp

GetToken	proc	near
		uses	es, cx, ax, cx
		.enter

		segmov	es, ss				;es:di <- GeodeToken

	;
	; skip spaces and lead "
	;
		call	SkipSpaces
		lodsb					;al <- char
		cmp	al, '"'
		jne	doneError			;branch if not "
	;
	; copy TokenChars
	;
		mov	cx, (size TokenChars)
charLoop:
		lodsb
		tst	al
		jz	doneError
		stosb
		loop	charLoop
	;
	; skip trailing "
	;
		lodsb					;al <- char
		cmp	al, '"'
		jne	doneError			;branch if not "
	;
	; get the manufacturer ID
	;
		call	SkipSpacesAndComma
		jc	doneError
		call	GetManufID
	CheckHack <offset GT_manufID eq offset GT_chars+(size TokenChars)>
		stosw
		clc
		jmp	done

doneError:
		stc
done::
		.leave
		ret
GetToken	endp

GetManufID	proc	near
		uses	bx
		.enter

		clr	dx
numLoop:
		lodsb					;al <- char
		sub	al, '0'
		jc	done
		cmp	al, 9
		ja	done
		clr	ah
		shl	dx, 1				;dx <- value * 2
		mov	cx, dx				;cx <- value * 2
		shl	dx, 1
		shl	dx, 1				;dx <- value * 8
		add	dx, cx				;dx <- value * 10
		add	dx, ax				;dx <- + digit
		jmp	numLoop
done:
		dec	si
		mov_tr	ax, dx				;ax <- manufID

		.leave
		ret
GetManufID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAssocListGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a particular file association

CALLED BY:	MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER

PASS:		*ds:si - FileAssocListClass object
		ds:di - FileAssocListClass object
		ss:bp - GetItemMonikerParams
RETURN:		bp - # of chars returned
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

FileAssocListGetMoniker	method	dynamic	FileAssocListClass,
					MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
		.enter

	;
	; Get the specified element
	;
		call	LockArrayForList
		mov	ax, ss:[bp].GIMP_identifier
		call	ChunkArrayElementToPtr
		jc	noItem				;branch if not found
	;
	; Copy it into the buffer
	;
		lea	si, ds:[di].FAE_ext		;ds:si <- extension
		segmov	es, ds
		mov	di, si
		call	LocalStringLength
		les	di, ss:[bp].GIMP_buffer		;es:di <- dest
		mov	bp, cx				;bp <- # chars
		rep	movsb				;copy me
		LocalClrChar ax
		LocalPutChar esdi, ax			;NULL terminate
	;
	; Unlock the array
	;
		call	MemUnlock
done:
		.leave
		ret

noItem:
		clr	bp				;bp <- item ignored
		jmp	done
FileAssocListGetMoniker	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FALFileAssocSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A file extension has been selected

CALLED BY:	MSG_FAL_FILE_ASSOC_SELECTED

PASS:		*ds:si - FileAssocListClass object
		ds:di - FileAssocListClass object
		cx - item #
		bp - # of selections
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

FALFileAssocSelected	method	dynamic	FileAssocListClass,
					MSG_FAL_FILE_ASSOC_SELECTED
numSel		local	word	push	bp
fae		local	FileAssocEntry

		.enter

	;
	; in case of no selection, init FileAssocEntry to reasonable values
	;
		clr	ax
		mov	{byte}ss:fae.FAE_ext, al
		mov	{byte}ss:fae.FAE_icon, al
		mov	{byte}ss:fae.FAE_app, al
		mov	{byte}ss:fae.FAE_appName, al
	;
	; enable or disable "Remove"
	;
		push	cx, bp, si
		mov	ax, MSG_GEN_SET_ENABLED
		tst	ss:numSel
		jnz	gotMsg
		mov	ax, MSG_GEN_SET_NOT_ENABLED
gotMsg:
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		push	ax
		mov	si, offset RemoveFileTypeTrigger
		call	ObjCallInstanceNoLock
		pop	ax
		mov	si, offset FileAssocRight
		call	ObjCallInstanceNoLock
		pop	cx, bp, si
		tst	ss:numSel
		LONG jz	noIcon			;branch if no selection
	;
	; copy the element to a local var for ease of use
	;
		push	ds, si, cx
		call	LockArrayForList
		mov	ax, cx				;ax <- item #
		call	ChunkArrayElementToPtr
		mov	si, di				;ds:si <- element
		segmov	es, ss
		lea	di, ss:fae			;es:di <- local
		mov	cx, (size FileAssocEntry)
		rep	movsb
		call	MemUnlock
		pop	ds, si, cx
	;
	; get the moniker for the token
	;
		call	UserGetDisplayType
		mov	dh, ah				;dh <- DisplayType
		mov	ax, {word}ss:fae.FAE_icon.GT_chars[0]
		mov	bx, {word}ss:fae.FAE_icon.GT_chars[2]
		mov	si, ss:fae.FAE_icon.GT_manufID
		mov	cx, ds:LMBH_handle		;cx <- block for alloc
		push	cx
		mov	di, mask VMSF_GSTRING or \
					(VMS_ICON shl offset VMSF_STYLE)
		push	di				;VisMonikerSearchFlags
		push	di				;size (not used)
		clr	di				;di (not used)
		call	TokenLoadMoniker
		pop	bx
		call	MemDerefDS			;preserves flags
		pop	si				;*ds:si <- list object
		jc	iconNotFound			;branch if not found
	;
	; update the moniker of the glyph
	;
		mov	dx, di
		mov	cx, bx				;^lcx:dx <- moniker
		call	setMoniker
	;
	; free the token as the moniker copied it
	;
		mov_tr	ax, dx				;ax <- chunk
		call	LMemFree
	;
	; update the app to launch, if any
	;
afterIcon:
		lea	di, ss:fae.FAE_appName
		segmov	es, ss
		call	LocalStringLength		;cx <- string length
		tst	cx
		jnz	gotApp				;branch if app name
		tst	{byte}ss:fae.FAE_app[0]
		jz	noApp				;branch if no chars
		lea	di, ss:fae.FAE_app
		mov	cx, TOKEN_CHARS_LENGTH		;cx <- string length
gotApp:
		push	bp
		mov	dx, ss
		mov	bp, di				;dx:bp <- ptr to text
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	si, offset FileAssocProgEntry
		call	ObjCallInstanceNoLock
		pop	bp
done:

		.leave
		ret

	;
	; icon not found, use token chars
	;
iconNotFound:
		tst	{byte}ss:fae.FAE_icon[0]
		jz	noIcon
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		mov	cx, ss
		lea	dx, ss:fae.FAE_icon
		call	setMoniker2
		jmp	afterIcon
noIcon:
		mov	cx, ds:LMBH_handle
		mov	dx, offset noneStr
		call	setMoniker
		jmp	afterIcon

	;
	; no app, clear the app name field
	;
noApp:
		push	bp
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		mov	si, offset FileAssocProgEntry
		call	ObjCallInstanceNoLock
		pop	bp
		jmp	done


setMoniker:
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
setMoniker2:
		push	dx, bp
		mov	si, offset TokenGlyph
		mov	bp, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock
		pop	dx, bp
		retn
FALFileAssocSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FALDeleteAssociation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the currently selected association

CALLED BY:	MSG_FAL_DELETE_ASSOCIATION

PASS:		*ds:si - FileAssocListClass object
		ds:di - FileAssocListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

FALDeleteAssociation	method	dynamic	FileAssocListClass,
					MSG_FAL_DELETE_ASSOCIATION
	;
	; get the current selection
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		jc	done			;branch if no selections
	;
	; delete it from the list
	;
		mov_tr	cx, ax			;cx <- selection #
		push	ds, si
		call	LockArrayForList
		mov_tr	ax, cx			;ax <- delete item
		mov	cx, 1			;cx <- # to delete
		call	ChunkArrayDeleteRange	;deletes range [ax,cx]
		call	MemUnlock
		pop	ds, si
	;
	; update the list UI
	;
		mov	ax, MSG_CUIL_INIT_UI
		call	ObjCallInstanceNoLock
		mov	ax, MSG_CUIL_MARK_DIRTY
		call	ObjCallInstanceNoLock
done:
		ret
FALDeleteAssociation	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FALSort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sort the file associations

CALLED BY:	MSG_FAL_SORT

PASS:		*ds:si - FileAssocListClass object
		ds:di - FileAssocListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

NOTE:
	Sort alphabetically, but also put more specific extensions
	before more general ones, e.g., *.FNT before *

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

FALSort			method	dynamic	FileAssocListClass,
					MSG_FAL_SORT
		call	LockArrayForList

		push	bx
		mov	cx, cs
		mov	dx, offset FALSortCB	;cx:dx <- compare routine
		call	ChunkArraySort
		pop	bx

		call	MemUnlock
		ret
FALSort			endm

FileExtensionType	etype byte
FET_FILE	enum FileExtensionType	;e.g., COMMAND.COM
FET_EXT		enum FileExtensionType	;e.g., *.FNT
FET_STAR_STAR	enum FileExtensionType	;i.e., *.*
FET_STAR	enum FileExtensionType	;i.e., *

FALSortCB	proc	far
	CheckHack <offset FAE_ext eq 0>
	;
	; if different types, just compare those
	;
		mov	bx, si
		call	GetExtType
		mov	ah, al			;ah <- ex
		mov	bx, di
		call	GetExtType
		cmp	ah, al			;different types?
		jne	done			;branch if different types
	;
	; same type, need to compare strings
	;
		clr	cx
		call	LocalCmpStringsNoCase
done:
		ret
FALSortCB	endp

GetExtType	proc	near
	;
	; (1) not *something?  -> must be file, e.g., COMMAND.COM
	;
		mov	al, FET_FILE
		cmp	{byte}ds:[bx], '*'
		jne	done
	;
	; (2) is *?
	;
		mov	al, FET_STAR
		tst	{byte}ds:[bx][1]
		jz	done
	;
	; (3) is *.*?
	;
EC <		cmp	{byte}ds:[bx][1], '.'		;>
EC <		ERROR_NE	-1			;>
		mov	al, FET_STAR_STAR
		cmp	{byte}ds:[bx][2], '*'
		je	done
	;
	; (4) must be *.something, e.g., *.FNT
	;
		mov	al, FET_EXT
done:
		ret
GetExtType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FALAddAssociation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Addd a new association

CALLED BY:	MSG_FAL_ADD_ASSOCIATION

PASS:		*ds:si - FileAssocListClass object
		ds:di - FileAssocListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

FALAddAssociation	method	dynamic	FileAssocListClass,
					MSG_FAL_ADD_ASSOCIATION
extBuf		local	DosDotFileName

		.enter

	;
	; get the new extension
	;
		push	bp, si
		mov	si, offset AddFileTypeEntry
		mov	dx, ss
		lea	bp, ss:extBuf			;dx:bp <- buffer
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock
		pop	bp, si
		jcxz	closeDialog
	;
	; see if it's already there
	;
		push	ds, si
		call	LockArrayForList
		push	bx
		mov	bx, cs
		mov	di, offset CheckForExtCB	;bx:di <- callback
		lea	dx, ss:extBuf			;ss:dx <- extension
		call	ChunkArrayEnum
		pop	bx
		call	MemUnlock
		pop	ds, si
		jc	nameExistsError			;branch if exists
	;
	; add the extension to the array
	;
		push	ds, si
		call	LockArrayForList
		call	ChunkArrayAppend		;ds:di <- element
		lea	si, ss:extBuf
		segmov	es, ds				;es:di <- element
	CheckHack <offset FAE_ext eq 0>
		segmov	ds, ss				;ds:si <- extension
		LocalCopyString
		call	MemUnlock
		pop	ds, si
	;
	; close the dialog
	;
closeDialog:
		push	bp, si
		mov	si, offset AddFileTypeDialog
		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		call	ObjCallInstanceNoLock
		pop	bp, si
	;
	; resort the array and refresh the list
	;
		mov	ax, MSG_FAL_SORT
		call	ObjCallInstanceNoLock
		mov	ax, MSG_CUIL_INIT_UI
		call	ObjCallInstanceNoLock
		mov	ax, MSG_CUIL_MARK_DIRTY
		call	ObjCallInstanceNoLock

done:
		.leave
		ret

nameExistsError:
		clr	ax
		pushdw	axax			;SDP_helpContext
		pushdw	axax			;SDP_customTriggers
		pushdw	axax			;SDP_stringArg2
		lea	ax, ss:extBuf
		pushdw	ssax			;SDP_stringArg1
		mov	si, offset ExtExistsError
		mov	si, ds:[si]
		pushdw	dssi			;SDP_customString
		mov	ax, CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION, 0>
		push	ax
		call	UserStandardDialog
		jmp	done
FALAddAssociation	endm

CheckForExtCB	proc	far
		push	ds
	CheckHack <offset FAE_ext eq 0>
		mov	si, di				;ds:si <- element
		segmov	es, ss
		mov	di, dx				;es:di <- extension
		clr	cx
		call	LocalCmpStringsNoCase
		pop	ds
		clc					;carry <- OK
		jne	nameOK
		stc					;carry <- name in use
nameOK:
		ret
CheckForExtCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FALChangeIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to the selected icon

CALLED BY:	MSG_FAL_CHANGE_ICON

PASS:		*ds:si - FileAssocListClass object
		ds:di - FileAssocListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

FALChangeIcon	method	dynamic	FileAssocListClass,
					MSG_FAL_CHANGE_ICON
	;
	; get the token
	;
		push	si
		mov	si, offset ChangeTokenList
		mov	ax, MSG_ITL_GET_SELECTED_TOKEN
		call	ObjCallInstanceNoLock
		pop	si
	;
	; store in our array, checking to see if we actually changed
	;
		push	ax, cx, dx
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		pop	bp, cx, dx
		jc	done				;branch if no selection
		push	ds, si
		call	LockArrayForList
		call	ChunkArrayElementToPtr
		lea	di, ds:[di].FAE_icon
		call	CheckStoreToken
		call	MemUnlock
		pop	ds, si
	;
	; mark dirty if necessary, and update the UI
	;
		jnc	noDirty
		mov	ax, MSG_CUIL_MARK_DIRTY
		call	ObjCallInstanceNoLock
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		call	ObjCallInstanceNoLock
noDirty:
	;
	; close the dialog
	;
done:
		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		mov	si, offset ChangeTokenDB
		call	ObjCallInstanceNoLock
		ret
FALChangeIcon	endm

CheckStoreToken	proc	near
		cmp	{word}ds:[di].GT_chars[0], bp
		jne	isChanged
		cmp	{word}ds:[di].GT_chars[2], cx
		jne	isChanged
		cmp	ds:[di].GT_manufID, dx
		jne	isChanged
		clc					;carry <- no change
		ret

isChanged:
		stc					;carry <- change
		mov	al, TRUE
		mov	{word}ds:[di].GT_chars[0], bp
		mov	{word}ds:[di].GT_chars[2], cx
		mov	ds:[di].GT_manufID, dx
		ret
CheckStoreToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FALChangeProgram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to the selected program

CALLED BY:	MSG_FAL_CHANGE_PROGRAM

PASS:		*ds:si - FileAssocListClass object
		ds:di - FileAssocListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

FALChangeProgram	method	dynamic	FileAssocListClass,
					MSG_FAL_CHANGE_PROGRAM
buf		local	PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE dup (TCHAR)
filename	local	FileLongName
token		local	GeodeToken

		.enter

	;
	; get the selected file, and make sure it is a file
	;
		push	bp, si
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
		mov	si, offset FileAssocProgSelector
		mov	cx, ss
		lea	dx, ss:buf			;cx:dx <- buffer
		call	ObjCallInstanceNoLock
		andnf	bp, mask GFSEF_TYPE
		cmp	bp, GFSET_FILE shl offset GFSEF_TYPE
		pop	bp, si
		LONG jne	done
		push	ax, bp, si
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
		mov	si, offset FileAssocProgSelector
		mov	cx, ss
		lea	dx, ss:filename			;cx:dx <- buffer
		call	ObjCallInstanceNoLock
		pop	ax, bp, si
	;
	; go to the parent dir
	;
		call	FileSetStandardPath
	;
	; get the token for the file
	;
		push	ds
		segmov	ds, ss, dx
		mov	es, dx
		lea	dx, ss:buf			;ds:dx <- file
		lea	di, ss:token			;es:di <- dest
		mov	ax, FEA_TOKEN
		mov	cx, (size GeodeToken)
		call	FileGetPathExtAttributes
		pop	ds
	;
	; get the selected file association entry
	;
		push	bp
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		pop	bp
		jc	done				;branch if no selection
		push	ds, si
		call	LockArrayForList
		call	ChunkArrayElementToPtr
		push	di, bp
		lea	di, ds:[di].FAE_app
		mov	dx, ss:token.GT_manufID
		mov	cx, {word}ss:token.GT_chars[2]
		mov	bp, {word}ss:token.GT_chars[0]
		call	CheckStoreToken
		pop	di, bp
		pushf
		segmov	es, ds
		lea	di, ds:[di].FAE_appName		;es:di <- dest
		segmov	ds, ss
		lea	si, ss:filename			;ds:si <- src
		LocalCopyString
		call	MemUnlock
		popf
		pop	ds, si
	;
	; update and dirty the list if needed
	;
		jnc	noDirty
		push	bp
		mov	ax, MSG_CUIL_MARK_DIRTY
		call	ObjCallInstanceNoLock
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		call	ObjCallInstanceNoLock
		pop	bp
noDirty:
	;
	; close the dialog
	;
		push	bp
		mov	si, offset FileAssocProgChange
		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		call	ObjCallInstanceNoLock
		pop	bp
done:
		.leave
		ret
FALChangeProgram	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FALGetProgramNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the program names for our tokens

CALLED BY:	MSG_FAL_GET_PROGRAM_NAMES

PASS:		*ds:si - FileAssocListClass object
		ds:di - FileAssocListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

TokenAndName	struct
   TAN_attrs	FileAttrs
   TAN_token	GeodeToken
   TAN_name	FileLongName
TokenAndName	ends

findAttrs FileExtAttrDesc \
	<FEA_FILE_ATTR, offset TAN_attrs, (size FileAttrs), 0>,
	<FEA_TOKEN, offset TAN_token,(size GeodeToken), 0>,
	<FEA_NAME, offset TAN_name, (size FileLongName), 0>,
	<FEA_END_OF_LIST, 0, 0, 0>

FALGetProgramNames	method	dynamic	FileAssocListClass,
					MSG_FAL_GET_PROGRAM_NAMES
		mov	ax, SP_APPLICATION
		call	FileSetStandardPath

		mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
		call	GenCallApplication

		call	LockArrayForList
		clr	dx				;dx <- depth
		call	FindGEOSNames
		call	MemUnlock

		mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
		call	GenCallApplication
		ret
FALGetProgramNames	endm

FindGEOSNames	proc	near
		uses	bx, cx, dx, es, di
		.enter

	;
	; don't recurse too deeply
	;
		inc	dx
		cmp	dx, 3
		ja	done
	;
	; find the programs and sub-directories
	;
		clr	ax
		sub	sp, (size FileEnumParams)
		mov	bp, sp
		mov	ss:[bp].FEP_searchFlags, mask FESF_DIRS or \
						mask FESF_GEOS_EXECS
		mov	ss:[bp].FEP_returnAttrs.segment, cs
		mov	ss:[bp].FEP_returnAttrs.offset, offset findAttrs
		mov	ss:[bp].FEP_returnSize, (size TokenAndName)
		movdw	ss:[bp].FEP_matchAttrs, axax
		mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED;
		mov	ss:[bp].FEP_skipCount, ax
		movdw	ss:[bp].FEP_callback, axax
		movdw	ss:[bp].FEP_callbackAttrs, axax
		call	FileEnum
		jc	done				;branch if error
		jcxz	done				;branch if no files
	;
	; go through the files and dirs
	;
		push	bx
		call	MemLock
		mov	es, ax
		clr	di				;es:di <- TokenAndName
fileLoop:
		test	es:[di].TAN_attrs, mask FA_SUBDIR
		jnz	handleDir
	;
	; for files, see if this is a program we're interested in
	;
		push	cx, dx, di
		mov	dx, di				;es:dx <- TokenAndName
		mov	di, offset CheckGEOSNameCB
		mov	bx, cs
		call	ChunkArrayEnum
		pop	cx, dx, di
afterDir:
		add	di, (size TokenAndName)
		loop	fileLoop

		pop	bx
		call	MemFree
done:
		.leave
		ret

	;
	; for directories, change to the dir and recurse
	;
handleDir:
		call	FilePushDir
		push	bx, dx, ds
		clr	bx				;bx <- no StandardPath
		segmov	ds, es
		lea	dx, es:[di].TAN_name		;ds:dx <- dir name
		call	FileSetCurrentPath
		pop	bx, dx, ds
		call	FindGEOSNames
		call	FilePopDir
		jmp	afterDir
FindGEOSNames	endp

CheckGEOSNameCB	proc	far
		uses	si, di
		.enter

	;
	; see if the token chars match
	;
		push	di
		mov	si, di				;ds:si <- element
		lea	si, ds:[si].FAE_app		;ds:si <- element token
		mov	di, dx
		lea	di, es:[di].TAN_token		;es:di <- passed token
		mov	cx, TOKEN_CHARS_LENGTH
		repe	cmpsb
		pop	di
		jne	done
	;
	; a match -- copy the name
	;
		push	ds, es
		segxchg ds, es
		mov	si, dx				;ds:si <- passed token
		lea	di, es:[di].FAE_appName		;es:di <- dest
		lea	si, ds:[si].TAN_name		;ds:si <- src
		mov	cx, (size FileLongName)/(size word)
		rep	movsw
		pop	ds, es
done:
		clc					;carry <- keep going

		.leave
		ret
CheckGEOSNameCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FALSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save our settings to the .INI file

CALLED BY:	PrefMgr

PASS:		*ds:si - StartupListClass object
		ds:di - StartupListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

FALSaveOptions	method dynamic FileAssocListClass,
					MSG_META_SAVE_OPTIONS
		uses	si
		.enter
	;
	; Is there an array?
	;
		clr	bx
		xchg	bx, ds:[di].CUILI_array.handle
		tst	bx				;any array?
		jz	done				;branch if not
		mov	si, ds:[di].CUILI_array.chunk
	;
	; Delete the existing string section
	;
		push	si
		segmov	ds, cs, cx
		mov	si, offset fileMgrCat		;ds:si <- category
		mov	dx, offset filenameTokensKey	;cx:dx <- key
		call	InitFileDeleteEntry
		pop	si
	;
	; See if there's anything to save
	;
		call	MemLock
		mov	ds, ax
		call	ChunkArrayGetCount
		jcxz	freeArray			;branch if nothing
	;
	; Loop through the strings in our array and add them
	;
		push	bx
		mov	bx, cs
		mov	di, offset SaveAssocsCallback
		call	ChunkArrayEnum
		pop	bx
	;
	; Free the array
	;
freeArray:
		call	MemFree
done:
		.leave
		ret
FALSaveOptions	endm

SaveAssocsCallback	proc	far
		uses	di, si, es, ds
strBuffer	local	PATH_BUFFER_SIZE dup (TCHAR)
		.enter
	;
	; construct the string of the form:
	;    *.ZIP = "dZIP",0,"ZipM",16480
	; or:
	;    *.ZIP = "dZIP",0
	;
		mov	si, di			;ds:si <- FileAssocEntry
		lea	di, ss:strBuffer
		segmov	es, ss			;es:di <- string
		mov	al, ' '
		stosb
		stosb
		stosb
		stosb
	;
	; copy the extension
	;
		push	si
extLoop:
		lodsb
		tst	al
		jz	afterExt
		stosb
		jmp	extLoop
afterExt:
		pop	si
	;
	; NOTE: don't include spaces, as that confuses some older apps
	;
		mov	al, '='
		stosb
	;
	; copy the icon
	;
		lea	bx, ds:[si].FAE_icon
		call	copyToken
	;
	; copy the app, if any
	;
		tst	{byte}ds:[si].FAE_app.GT_chars[0]
		jz	noApp
		mov	al, ','
		stosb
		lea	bx, ds:[si].FAE_app
		call	copyToken
noApp:
		clr	al
		stosb
	;
	; Write out the string
	;
		lea	di, ss:strBuffer
		segmov	ds, cs, cx
		mov	si, offset fileMgrCat		;ds:si <- category
		mov	dx, offset filenameTokensKey	;cx:dx <- key
		call	InitFileWriteStringSection

		clc				;carry <- keep going
		.leave
		ret

copyToken:
	;
	; copy the token chars "AAAA",
	;
		mov	al, '"'
		stosb
		push	si
		mov	cx, TOKEN_CHARS_LENGTH
		lea	si, ds:[bx].GT_chars	;ds:si <- token chars
		rep	movsb
		pop	si
		mov	al, '"'
		stosb
		mov	al, ','
		stosb
	;
	; write the number #####
	;
		clr	cx, dx			;cx <- UtilHexToAsciiFlags
		mov	ax, ds:[bx].GT_manufID	;dx:ax <- manufID
		call	UtilHex32ToAscii
		add	di, cx

		retn
SaveAssocsCallback	endp

;----


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ITLInitList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the list of tokens

CALLED BY:	MSG_ITL_INIT_LIST
PASS:		*ds:si	- IconTokenListClass object
		ds:di	- IconTokenListClass instance
		es	- dgroup
RETURN:		
DESTROYED:	ax, bx, cx, dx, si, di, ds, es

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ITLInitList		method	dynamic IconTokenListClass,
						MSG_ITL_INIT_LIST
	;
	; get the list of tokens
	;
		clr	ax, bx				;ax <- TokenRangeFlags
							;bx <- no extra header
		call	TokenListTokens
		mov	ds:[di].ITL_tokenList, bx	;save it for later
	;
	; set our number of items accordingly
	;
		mov_tr	cx, ax				;cx <- # of items
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		GOTO	ObjCallInstanceNoLock
ITLInitList		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ITLGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a moniker for our list of tokens

CALLED BY:	MSG_ITL_GET_MONIKER
PASS:		*ds:si	- IconTokenListClass object
		ds:di	- IconTokenListClass instance
		es	- dgroup
		bp - item #
RETURN:		
DESTROYED:	ax, bx, cx, dx, si, di, ds, es

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ITLGetMoniker		method	dynamic IconTokenListClass,
						MSG_ITL_GET_MONIKER
		mov	cx, ds:[LMBH_handle]		;cx <- our block
		push	cx, si				;save for later
	;
	; get the offset of the item
	;
		mov	ax, (size GeodeToken)
		mul	bp
		mov	si, ax				;si <- index
	;
	; lock the list of tokens
	;
		mov	bx, ds:[di].ITL_tokenList
		push	bx
		call	MemLock
		mov	ds, ax
	;
	; get our token
	;
		mov	ax, (VMS_ICON shl offset VMSF_STYLE) \
				or mask VMSF_GSTRING
		push	ax				;VisMonikerSearchFlags
		clr	ax
		push	ax				;buffer size
		call	UserGetDisplayType
		mov	dh, ah				;dh <- DisplayType
		mov	ax, {word}ds:[si].GT_chars[0]
		mov	bx, {word}ds:[si].GT_chars[2]
		mov	si, ds:[si].GT_manufID
		clr	di				;di <- alloc new chunk
		call	TokenLoadMoniker
	;
	; unlock the token list
	;
		pop	bx				;bx <- token list block
		call	MemUnlock
	;
	; set the moniker
	;
		pop	bx, si
		call	MemDerefDS

		mov	cx, bx
		mov	dx, di				;^lcx:dx <- moniker
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR
		call	ObjCallInstanceNoLock
	;
	; clean up
	;
		mov	ax, di				;ax <- chunk handle
		call	LMemFree
		ret
ITLGetMoniker		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ITLGetSelectedToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the token of the selected icon

CALLED BY:	MSG_ITL_GET_SELECTED_TOKEN
PASS:		*ds:si	- IconTokenListClass object
		ds:di	- IconTokenListClass instance
		es	- dgroup
RETURN:		ax:cx:dx - GeodeToken of selection
		carry - set if none selected
DESTROYED:	bx, si, ds

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ITLGetSelectedToken		method	dynamic IconTokenListClass,
						MSG_ITL_GET_SELECTED_TOKEN
		uses	bp
		.enter
	;
	; get the selection, if any
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		jc	done				;branch if no selection
	;
	; get the corresponding token
	;
		push	ax
		mov	bx, ds:[di].ITL_tokenList
		call	MemLock
		mov	ds, ax
		pop	ax
		mov	dx, (size GeodeToken)
		mul	dx
		mov	si, ax				;ds:si <- GeodeToken
		mov	ax, {word}ds:[si].GT_chars[0]
		mov	cx, {word}ds:[si].GT_chars[2]
		mov	dx, ds:[si].GT_manufID
		call	MemUnlock

		clc					;carry <- selection
done:
		.leave
		ret
ITLGetSelectedToken		endm

ProgListCode	ends
