COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Start up app
FILE:		rstartupLangList.asm

AUTHOR:		Jason Ho, Apr 20, 1995

METHODS:
	Name				Description
	----				-----------
	RSLDLRslangDynamicListBuildArray
					Create the array of list
					entries from the .ini file.
	RSLDLRslangListQueryItemMoniker	To query for moniker of an item.  
	RSLDLRslangAddItemMoniker	Get the moniker of one item,
					and put it into the dynamic
					list.
	RSLDLRslangGetLanguageName	Get the name of the language.
	RSLDLGenSaveOptions		Save the selected language
					entry to the .ini file.

ROUTINES:
	Name				Description
	----				-----------
INT	BuildArrayCallBack		Callback routine to insert
					passed string into a chunk array. 
INT	StartupLangGetString		Get the (ax)th element of the
					instance data nameArray, and
					copy it to buffer
	
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		4/20/95   	Initial revision


DESCRIPTION:
	Code for RStartupLangDynmaicListClass
		

	$Id: rstartupLangList.asm,v 1.1 97/04/04 16:52:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RSTARTUP_DO_LANGUAGE		;++++++++++++++++++++++++++++++++++++++++++

RStartupClassStructures	segment resource
	RStartupLangDynamicListClass
RStartupClassStructures	ends

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSLDLRslangDynamicListBuildArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the array of list entries from the .ini file.

CALLED BY:	MSG_RSLANG_DYNAMIC_LIST_BUILD_ARRAY
PASS:		*ds:si	= RStartupLangDynamicListClass object
		ds:di	= RStartupLangDynamicListClass instance data
		es 	= segment of RStartupLangDynamicListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Build an array to put the strings in an instance data
		of the dynamic list.
		The strings are in "ATTR_LANG_INIT_FILE_LIST_KEY" of
		ini file (category: ATTR_LANG_INIT_FILE_LIST_CATEGORY).
		Descriptions are in ATTR_LANG_INIT_FILE_DESCRIPTION_KEY.
		Then initialize the dynamic list.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/20/95   	Initial version (modified from
				Library/Config/Pref/prefIniDynamicList.asm) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSLDLRslangDynamicListBuildArray method dynamic RStartupLangDynamicListClass, 
					MSG_RSLANG_DYNAMIC_LIST_BUILD_ARRAY
		.enter
	;
	; Build an array to put the language name in.
	;
		push	si			; Save list offset.
		mov	bp, si
		clr	ax
		czr	ax, bx, cx, si
		call	NameArrayCreate		; *ds:si - array,
						; carry set if error
						; Block might move

	;
	; Save handle to chunk array.
	;
		mov	di, ds:[bp]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].RSLDLI_nameArray, si

		segmov	es, ds, ax		; Chunk array segment.
		mov	ax, si			; ax <- Chunk array offset
		pop	si			; List offset.

		push	si			; List offset
		push	si			; List offset
		push	ax			; Chunk array offset
	;
	; Get the entries and place them into the array.
	;
		mov	ax, ATTR_LANG_INIT_FILE_LIST_KEY
		call	ObjVarFindData		; ds:bx	= key string.
		mov	cx, ds			; Key string segment.
		mov	dx, bx			; Key string offset.
		jnc	notFound

		mov	ax, ATTR_LANG_INIT_FILE_LIST_CATEGORY
		call	ObjVarFindData		; ds:bx	= category string. 
		mov	si, bx			; Category string offset.
		jnc	notFound

		mov	bp, InitFileReadFlags<IFCC_INTACT,1,0,0>
						; second field: IFRF_READ_ALL
		mov	di, cs
		mov	ax, offset BuildArrayCallBack
		pop	bx			; Chunk array offset.
	;
	; InitFileEnumStringSection needs the following passed:
	;	ds:si	= Category ASCIIZ string
	;	cx:dx	= Key ASCIIZ string
	;	bp	= InitFileReadFlags (IFRF_SIZE is of no importance)
	;	di:ax	= Callback routine (fptr)
	;	
	; and for the call back function:
	;	*es:bx	= chunk array
	;
		call	InitFileEnumStringSection
	;
	; Now deal with language name list
	;
		pop	dx			; List offset
		push	ds, si, ax, bx
		mov	ax, ATTR_LANG_INIT_FILE_DESCRIPTION_KEY
		mov_tr	si, dx
		call	ObjVarFindData		; ds:bx	= key string.
		mov	cx, ds			; Key string segment.
		mov	dx, bx			; Key string offset.
		pop	ds, si, ax, bx
		jnc	notFound
		call	InitFileEnumStringSection

		segmov	ds, es, ax
		mov	si, bx			; *ds:si = chunk array
	;
	; Get the count of items in the array.
	;
		call	ChunkArrayGetCount	; cx = entries in array
	;
	; If cx == 0, ie. no language exists, fatal error
	;
EC <		tst	cx						>
EC <		ERROR_Z	NO_LANGUAGE_AVAILABLE_CHECK_INI_FILE		>

		shr	cx			; we add name + description
						; in one array. So in
						; fact we have only
						; (cx/2) items in list.
	;
	; See if we have an odd number of entries in chunk array: 
	; carry flag <- right most bit of cx after SHR
	;
EC <		ERROR_C	ODD_NUMBER_OF_LANGUAGE_ITEMS_CHECK_INI		>
	;
	;
	; Initialize the list.
	;
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		pop	si			; List offset.
		call	ObjCallInstanceNoLock	; ax, cx, dx, bp gone
	;
	; Go back to top of list
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	cx, dx
		call	ObjCallInstanceNoLock
		
notFound:
		.leave
		ret
RSLDLRslangDynamicListBuildArray	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildArrayCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to insert passed string into a chunk array.

CALLED BY:	INTERNAL

PASS:		ds:si	= string section (null-terminated)
		cx	= length of section
		*es:bx	= chunk array 

RETURN:		*es:bx	= chunk array

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildArrayCallBack	proc	far
		uses	ax, cx, dx, ds
		.enter
	;
	; Append the string to the chunk array.
	;
		mov	dx, ds
		segmov	ds, es, ax
		mov	es, dx
		mov	di, si			; *es:di = string to add.
		mov	si, bx			; *ds:si = name array.
		clr	bx, cx
		call	NameArrayAdd		; carry set if added,
						; ax <- token
	;
	; Return the chunk array.
	;
		segmov	es, ds, ax
		mov	bx, si			; *es:bx = chunk array again

		clc
		.leave
		ret
BuildArrayCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSLDLRslangListQueryItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The dynamic list will send this to itself to query for
		moniker of an item. 

CALLED BY:	MSG_RSLANG_LIST_QUERY_ITEM_MONIKER
PASS:		*ds:si	= RStartupLangDynamicListClass object
		ds:di	= RStartupLangDynamicListClass instance data
		es 	= segment of RStartupLangDynamicListClass
		ax	= message #
		^lcx:dx = the dynamic list requesting the moniker
		bp	= item #

RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/20/95   	Initial version (copied from
				prefDynamicList.asm)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSLDLRslangListQueryItemMoniker	method dynamic \
					RStartupLangDynamicListClass, 
					MSG_RSLANG_LIST_QUERY_ITEM_MONIKER
		mov	ax, bp

buffer			local	MAX_STRING_SIZE	dup (TCHAR)
getMonikerParams	local	GetItemMonikerParams

		.enter

		mov	ss:[getMonikerParams].GIMP_identifier, ax
		mov	ss:[getMonikerParams].GIMP_buffer.segment, ss
		lea	ax, ss:[buffer]
		mov	ss:[getMonikerParams].GIMP_buffer.offset, ax

		mov	ax, MSG_RSLANG_ADD_ITEM_MONIKER
		push	bp
		lea	bp, ss:[getMonikerParams]
		call	ObjCallInstanceNoLock		; ax, cx, dx gone
		pop	bp

		.leave
		ret
RSLDLRslangListQueryItemMoniker	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSLDLRslangAddItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the moniker of one item, and put it into the
		dynamic list.

CALLED BY:	MSG_RSLANG_ADD_ITEM_MONIKER
PASS:		*ds:si	= RStartupLangDynamicListClass object
		ds:di	= RStartupLangDynamicListClass instance data
		ds:bx	= RStartupLangDynamicListClass object (as *ds:si)
		es 	= segment of RStartupLangDynamicListClass
		ax	= message #
		ss:bp	= GetItemMonikerParams
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		All the strings (language / description) are in the
		chunk array instance data. Example of the array:
			English
			Deutsch
			Francais
			Language selection:
			Sprachanswahl:
			Choix langue:
			(note that language name comes first)

		To get the moniker of one item (Language selection:
		English) we have to access the chunk array twice. And
		we need the number of items in chunk array. (e.g. to
		get the moniker of second item, we append (2 + 6/2)th
		string and (2) nd string.

		We need to make the language part BOLD (using
		CreateVisMonikerLine).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSLDLRslangAddItemMoniker	method dynamic RStartupLangDynamicListClass, 
					MSG_RSLANG_ADD_ITEM_MONIKER
		mov	bx, bp
;
; forgive the unmeaningful name: moniker field text
;
mft		local	2 dup(VisMonikerColumn)
itemNum		local	word
languageName	local	MAX_STRING_SIZE dup (TCHAR)

		.enter
		push	si
		push	ds:[LMBH_handle]
		push	ds:[di].RSLDLI_nameArray
	;
	; Get the length from ss:bx struct, and position of the
	; moniker of description in the chunk array.
	;
		mov	ax, ss:[bx].GIMP_identifier
		mov	ss:[itemNum], ax		; save the num
							; to local var
		segmov	es, ss
		lea	di, ss:[languageName]		; es:di - string
		mov	dx, MAX_STRING_SIZE		; size of buffer
		call	RStartupLangGetString		; string filled
							; cx, di destroyed
	;
	; Now get the language description from chunk array. It is the
	; (itemNum + (#item in chunk array)/2) th item.
	;
		pop	si
		call	ChunkArrayGetCount		; cx <- #of items
		mov_tr	ax, cx
		shr	ax
		add	ax, ss:[itemNum]
		call	ChunkArrayElementToPtr		; ds:di <- element
							; cx <- element size
		add	di, offset NAE_data
		sub	cx, offset NAE_data		; ds:di = moniker
							; cx = length
	;
	; Add a null to string
	;
		mov	si, di
		add	si, cx
		mov	{TCHAR}ds:[si], 0
	;
	; If moniker is too long, it will be truncated in CreateVisMonikerLine
	; No need to check for moniker too long
	;
	; Format the moniker
	;
		mov	ss:[mft][0*VisMonikerColumn].VMC_just, J_LEFT
		mov	ss:[mft][0*VisMonikerColumn].VMC_width, \
				LANGUAGE_COLUMN_WIDTH
		clr	ss:[mft][0*VisMonikerColumn].VMC_style
		clr	ss:[mft][0*VisMonikerColumn].VMC_border
		mov	ss:[mft][0*VisMonikerColumn].VMC_ptr.segment, ds
		mov	ss:[mft][0*VisMonikerColumn].VMC_ptr.offset, di

		mov	ss:[mft][1*VisMonikerColumn].VMC_just, J_LEFT
		mov	ss:[mft][1*VisMonikerColumn].VMC_width, \
				LANGUAGE_COLUMN_WIDTH
		mov	ss:[mft][1*VisMonikerColumn].VMC_style, \
				mask TS_BOLD
		mov	ss:[mft][1*VisMonikerColumn].VMC_ptr.segment, ss
		lea	ax, ss:[languageName]
		mov	ss:[mft][1*VisMonikerColumn].VMC_ptr.offset, ax
		clr	ss:[mft][1*VisMonikerColumn].VMC_border		

		call	GrGetDefFontID			; cx <- FontID
							; dx.ah <- pointsize
							; bx <- font handle
		mov_tr	bx, dx
		mov	dx, 2				; two columns
		segmov	ds, ss
		lea	si, ss:[mft]
		clr	di
		call	CreateVisMonikerLine		; ^lcx:dx <- visMoniker
	;
	; Get back ds:si. On the stack we have the handle and segment.
	;
		pop	bx
		call	MemDerefDS			; ds <- segment
		pop	si
	;
	; Put the text on dynamic list
	;
		push	cx				; handle of visMoniker
		push	bp
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR
		mov	bp, ss:[itemNum]
		call	ObjCallInstanceNoLock		; ax, cx, dx, bp gone
		pop	bp
		pop	bx				; bx <- visMon handle
		call	MemFree	

		.leave
		ret

RSLDLRslangAddItemMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupLangGetString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the (ax)th element of the instance data nameArray,
		and copy it to buffer.

CALLED BY:	INTERNAL
PASS:		*ds:si	= RStartupLangDynamicListClass object
		ax	= item num
		es:di	= buffer
		dx	= buffer size (limit)
RETURN:		nothing.
		buffer is filled.
		in EC, Fatal error if string is larger than buffer (because
		the string will be used in dialog).

DESTROYED:	cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RStartupLangGetString	proc	near
		class	RStartupLangDynamicListClass
		uses	si
		.enter
		
EC <		Assert	objectPtr, dssi, RStartupLangDynamicListClass	>
	;
	; Redereference
	;
		push	di
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	;
	; Get (ax)th element in RSLDLI_nameArray
	;
		mov	si, ds:[di].RSLDLI_nameArray
		call	ChunkArrayElementToPtr		; ds:di <- element
							; cx <- element size
		add	di, offset NAE_data
		sub	cx, offset NAE_data		; ds:di = moniker
							; cx = length
	;
	; Get ready to copy string to es:di
	;
		mov_tr	si, di
		pop	di
	;
	; Check if moniker will fit in buffer. If not, fatal error.
	;
EC <		cmp	cx, dx						>
EC <		ERROR_A	LANGUAGE_NAME_TOO_LONG_CHECK_INI_FILE		>
		
SBCS <		rep	movsb						>
DBCS <		rep	movsw						>
		mov	{TCHAR} es:[di], 0

		.leave
		ret
RStartupLangGetString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSLDLRslangGetLanguageName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name of the language.

CALLED BY:	MSG_RSLANG_GET_LANGUAGE_NAME
PASS:		*ds:si	= RStartupLangDynamicListClass object
		ds:di	= RStartupLangDynamicListClass instance data
		es 	= segment of RStartupLangDynamicListClass
		ax	= message #
		bp	= item number
		cx:dx	= string buffer
RETURN:		nothing
DESTROYED:	ax, cx, di
SIDE EFFECTS:	
		All the strings (language / description) are in the
		chunk array instance data. Example of the array:
			English
			Deutsch
			Francais
			Language selection:
			Sprachanswahl:
			Choix langue:
			(note that language name comes first)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSLDLRslangGetLanguageName	method dynamic RStartupLangDynamicListClass, 
					MSG_RSLANG_GET_LANGUAGE_NAME
		mov_tr	ax, bp
		mov_tr	es, cx				; es:di - string
		mov_tr	di, dx
		mov	dx, MAX_STRING_SIZE
		call	RStartupLangGetString		; cx, di destroyed
		ret
RSLDLRslangGetLanguageName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSLDLGenSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the selected entry to the .ini file.

CALLED BY:	MSG_GEN_SAVE_OPTIONS
PASS:		*ds:si	= RStartupLangDynamicListClass object
		ds:di	= RStartupLangDynamicListClass instance data
		es 	= segment of RStartupLangDynamicListClass
		ax	= message #
		ss:bp	= GenOptionsParams
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We need to save options, mainly to write
		[system]systemLanguage to a language name.

		All the language names are stored in a name array,
		RSLDLI_nameArray.

		This message is sent by MSG_META_SAVE_OPTIONS. The
		ss:bp GenOptionsParams is set up by system. The
		category and key are of course in *.ui file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/ 4/95   	Initial version (mostly copied from
				Library/Config/Pref/prefInitDynamicList.asm) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSLDLGenSaveOptions	method dynamic RStartupLangDynamicListClass, 
					MSG_GEN_SAVE_OPTIONS
passedBP	local	word	push bp
entryBuffer	local	MAX_STRING_SIZE dup (TCHAR)
		.enter
	;
	; Get the entry chunk array.
	;
		mov	bx, ds:[di].RSLDLI_nameArray
	;
	; Make sure there is a selection.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		tst	ds:[di].GIGI_numSelections
		jz	exit
	;
	; Read the entry into our buffer.
	;
		mov	si, bx				; Entry chunk array.
		mov	ax, ds:[di].GIGI_selection
		mov	cx, ss
		lea	dx, ss:[entryBuffer] 
		call	ChunkArrayGetElement
		mov	di, dx
		add	di, ax
		segmov	es, cx
		mov	{TCHAR} es:[di], 0		; Null-terminate.
		mov	di, dx
		add	di, offset NAE_data		; *es:di = entry string
	;
	; Record the new selection to the .ini file.
	;
		push	bp
		mov	bp, ss:[passedBP]
		mov	cx, ss
		lea	dx, ss:[bp].GOP_key		; cx:dx = .ini key
		mov	ds, cx
		lea	si, ss:[bp].GOP_category	; ds:si = .ini category
		call	InitFileWriteString
		pop	bp

		call	InitFileCommit
exit:
		.leave
		ret
RSLDLGenSaveOptions	endm

CommonCode	ends

endif				; ++++++++++++ RSTARTUP_DO_LANGUAGE ++++++++

