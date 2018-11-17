COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Config
FILE:		prefIniDynamicList.asm

AUTHOR:		Paul Canavese, Oct  5, 1994

ROUTINES:
	Name			Description
	----			-----------
	PIDLPrefDynamicListBuildArray	Create an array of list
				entries from the ini file
	BuildArrayCallback	Callback routine to insert passed
				string into a chunk array.
	PIDLItemGroupGetItemMoniker	Get the moniker of one item.
	PIDLGenSaveOptions	Save the selected entry to the .ini
				file.
	PIDLPrefDynamicListFindItem	Find an entry with a given
				moniker.
	PIDLPrefDynamicListMatchCallback	Check if passed entry
				of the chunk array matches the entry
				currently selected in the .ini file.
	PIDLGenApply		Save the options and reboot.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	10/ 5/94   	Initial revision


DESCRIPTION:
	An interface for when the Preferences module wants to allow a
	user to choose between entries of a list contained in the .ini
	file.  Originally created for preflang.

	$Id: prefIniDynamicList.asm,v 1.1 97/04/04 17:50:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include initfile.def


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIDLPrefDynamicListBuildArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the array of list entries from the .ini file.

CALLED BY:	MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
PASS:		*ds:si	= PrefIniDynamicListClass object
		ds:di	= PrefIniDynamicListClass instance data
		ds:bx	= PrefIniDynamicListClass object (same as *ds:si)
		es 	= segment of PrefIniDynamicListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	10/ 6/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIDLPrefDynamicListBuildArray	method dynamic PrefIniDynamicListClass, 
					MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
		.enter

	; Build an array to put the elements in.

		push	si			; Save list offset.
		mov	bp, si
		clr	ax, bx, cx, si
		call	NameArrayCreate

	; Save handle to chunk array.

		mov	di, ds:[bp]
		add	di, ds:[di].PrefIniDynamicList_offset
		mov	ds:[di].PIDLI_array, si

	; Save handle to chunk array.

		segmov	es, ds, ax		; Chunk array segment.
		mov	ax, si
		pop	si			; List offset.
		push	si, ax

	; Get the entries and place them into the array.

		mov	ax, ATTR_PREF_INI_INIT_FILE_LIST_KEY
		call	ObjVarFindData		; ds:bx	= key string.
		mov	cx, ds			; Key string segment.
		mov	dx, bx			; Key string offset.
		jnc	notFound

		mov	ax, ATTR_PREF_INI_INIT_FILE_LIST_CATEGORY
		call	ObjVarFindData		; ds:bx	= category string. 
		mov	si, bx
		jnc	notFound

		pop	bx			; chunk array -> *ds:bx
		mov	di, cs
		mov	ax, offset BuildArrayCallBack
		mov	bp, InitFileReadFlags< IFCC_INTACT, 0,1,0>
		call	InitFileEnumStringSection

		segmov	ds, es, ax
		mov	si, bx			; *ds:si = chunk array

	; Get the count of items in the array.

		call	ChunkArrayGetCount	; cx = entries in array

	; Initialize the list.

		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		pop	si			; List offset.
		call	ObjCallInstanceNoLock
notFound:
		.leave
		Destroy	ax, cx, dx, bp
		ret
PIDLPrefDynamicListBuildArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildArrayCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to insert passed string into a chunk array.

CALLED BY:	PrefPagGetItems via InitFileEnumStringSection

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
	Don	12/29/00		Store NULL-terminate strings in
					  the array, as that is more useful

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildArrayCallBack	proc	far
		uses	ax,cx,dx,ds	
		.enter

	; Append the string to the chunk array.

		mov	dx, ds
		segmov	ds, es, ax
		mov	es, dx
		mov	di, si			; *es:di = string to add.
		mov	si, bx			; *ds:si = name array.
		clr	bx
		inc	cx			; include NULL in the length
		call	NameArrayAdd

	; Return the chunk array.

		segmov	es, ds, ax
		mov	bx, si			; *es:bx = chunk array again

		clc
		.leave
		ret
BuildArrayCallBack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIDLItemGroupGetItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the moniker of one item.

CALLED BY:	MSG_ITEM_GROUP_GET_ITEM_MONIKER
PASS:		*ds:si	= PrefIniDynamicListClass object
		ds:di	= PrefIniDynamicListClass instance data
		ds:bx	= PrefIniDynamicListClass object (same as *ds:si)
		es 	= segment of PrefIniDynamicListClass
		ax	= message #
		ss:bp	= GetItemMonikerParams
RETURN:		bp	= number of characters returned
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	10/ 7/94   	Initial version
	Don	12/29/00	Since array now holds NULL-terminated strings,
				  don't copy an extra NULL into the buffer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIDLItemGroupGetItemMoniker	method dynamic PrefIniDynamicListClass, 
					MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
		uses	ax, cx, dx
		.enter

	; Get the length and position of the moniker from the chunk array.

		mov	si, ds:[di].PIDLI_array
		mov	ax, ss:[bp].GIMP_identifier
		call	ChunkArrayElementToPtr
		add	di, offset NAE_data
		sub	cx, offset NAE_data
			; ds:di = moniker
			; cx = length

	; Check if moniker will fit in buffer.

		cmp	cx, ss:[bp].GIMP_bufferSize
		ja	notEnoughSpace

	; Copy the moniker into the buffer.

		mov	si, di			; Moniker string offset.
		les	di, ss:[bp].GIMP_buffer
		rep	movsb
exit:
		.leave
		ret			; EXIT.

notEnoughSpace:
		clr	bp
		jmp	exit
PIDLItemGroupGetItemMoniker	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIDLGenSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the selected entry to the .ini file.

CALLED BY:	MSG_GEN_SAVE_OPTIONS
PASS:		*ds:si	= PrefIniDynamicListClass object
		ds:di	= PrefIniDynamicListClass instance data
		ds:bx	= PrefIniDynamicListClass object (same as *ds:si)
		es 	= segment of PrefIniDynamicListClass
		ax	= message #
		ss:bp	= GenOptionsParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	10/11/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIDLGenSaveOptions	method dynamic PrefIniDynamicListClass, 
					MSG_GEN_SAVE_OPTIONS
passedBP	local	word	push bp
entryBuffer	local	NAME_ARRAY_MAX_NAME_SIZE dup (char)
		.enter

	; Get the entry chunk array.

		mov	bx, ds:[di].PIDLI_array

	; Make sure there is a selection.

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		tst	ds:[di].GIGI_numSelections
		jz	exit

	; Read the entry into our buffer.

		mov	si, bx				; Entry chunk array.
		mov	ax, ds:[di].GIGI_selection
		mov	cx, ss
		lea	dx, ss:[entryBuffer] 
		call	ChunkArrayGetElement
		mov	di, dx
		add	di, ax
		segmov	es, cx
		mov	di, dx
		add	di, offset NAE_data		; *es:di = entry str

	; Record the new selection to the .ini file.

		push	bp
		mov	bp, ss:[passedBP]
		mov	cx, ss
		lea	dx, ss:[bp].GOP_key		; cx:dx = .ini key
		mov	ds, cx
		lea	si, ss:[bp].GOP_category	; ds:si = .ini category
		call	InitFileWriteString
		pop	bp
exit:
		.leave
		Destroy ax, cx, dx, bp
		ret
PIDLGenSaveOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIDLPrefDynamicListFindItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an entry with a given moniker.

CALLED BY:	MSG_PREF_DYNAMIC_LIST_FIND_ITEM

PASS:		*ds:si	= PrefIniDynamicListClass object
		ds:di	= PrefIniDynamicListClass instance data
		ds:bx	= PrefIniDynamicListClass object (same as *ds:si)
		es 	= segment of PrefIniDynamicListClass
		ax	= message #
		cx:dx	= null-terminated string
		bp	= nonzero to find best fit

RETURN:		if FOUND:
			carry clear
			ax = item #
		ELSE:
			carry set
			ax = CA_NULL_ELEMENT
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	10/ 7/94   	Initial version
	Don	12/29/00	Since array now holds NULL-terminated strings,
				  pass actual string length to NameArrayFind()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIDLPrefDynamicListFindItem	method dynamic PrefIniDynamicListClass, 
					MSG_PREF_DYNAMIC_LIST_FIND_ITEM
		uses	es
		.enter
	
	; Find matching string in dynamic list.

		mov	si, ds:[di].PIDLI_array
		mov	es, cx
		mov	di, dx		; *es:di = string to find
		clr	al
		mov	cx, -1
		repne	scasb
		neg	cx
		dec	cx		; length of string (inc. NULL) -> CX
		mov	di, dx		; *es:di = string to find
		clr	dx		; don't return a copy of the string
		call	NameArrayFind
		cmc

		.leave
		Destroy cx, dx, bp
		ret
PIDLPrefDynamicListFindItem	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIDLGenApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the options and reboot.

CALLED BY:	MSG_GEN_APPLY
PASS:		*ds:si	= PrefIniDynamicListClass object
		ds:di	= PrefIniDynamicListClass instance data
		ds:bx	= PrefIniDynamicListClass object (same as *ds:si)
		es 	= segment of PrefIniDynamicListClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	10/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIDLGenApply	method dynamic PrefIniDynamicListClass, 
					MSG_GEN_APPLY
		uses	ax, cx, dx, bp
		.enter

	; Call our superclass to do normal handling.

		push	di
		mov	di, offset PrefIniDynamicListClass
		call	ObjCallSuperNoLock
		pop	di

	; Reboot if the language was changed.

		mov	ax, MSG_PREF_GET_REBOOT_INFO
		call	ObjCallInstanceNoLock

		.leave
		ret
PIDLGenApply	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIDLMetaFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the name array.

CALLED BY:	MSG_META_OBJ_FINAL_FREE
PASS:		*ds:si	= PrefIniDynamicListClass object
		ds:di	= PrefIniDynamicListClass instance data
		ds:bx	= PrefIniDynamicListClass object (same as *ds:si)
		es 	= segment of PrefIniDynamicListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	6/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIDLMetaFinalObjFree	method dynamic PrefIniDynamicListClass, 
					MSG_META_FINAL_OBJ_FREE
		.enter

	; Free the name array.

		clr	ax
		xchg	ax, ds:[di].PIDLI_array
		call	LMemFree

	; Call the superclass.

		mov	di, offset PrefIniDynamicListClass
		call	ObjCallSuperNoLock

		.leave
		ret
PIDLMetaFinalObjFree	endm
