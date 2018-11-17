COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefTocList.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/92   	Initial version.

DESCRIPTION:
	

	$Id: prefTocList.asm,v 1.2 98/04/05 12:58:52 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListBuildArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Build the array of files for this TOC list

PASS:		*ds:si	= PrefTocListClass object
		ds:di	= PrefTocListClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTocListBuildArray	method	dynamic	PrefTocListClass, 
		MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
		
		uses	cx, dx, bp
		
		.enter
		
		mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
		call	GenCallApplication
		
		call	FilePushDir
		
	;
	; Set our current path.  If we're unable to set it, then just
	; read from the toc file without updating.
	;
		
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathSetCurrentPathFromObjectPath
		
		pushf
		DerefPref	ds, si, bx
		popf
		
	;
	; Fetch the flags to pass to TocUpdateCategory.  If the carry
	; is set, then we were unable to CD to the directory
	; containing the files, so pass that information to
	; TocUpdateCategory.
	;
		
		mov	ax, ds:[bx].PTLI_flags
		jnc	gotFlags
		ornf	ax, mask TUCF_DIRECTORY_NOT_FOUND
gotFlags:
		sub	sp, size TocUpdateCategoryParams
		mov	bp, sp
		mov	ss:[bp].TUCP_flags, ax
		movtok	ss:[bp].TUCP_tokenChars, 	\
			ds:[bx].PTLI_tocInfo.TCS_tokenChars, ax
		
		lea	di, ds:[bx].PTLI_tocInfo
		segmov	es, ds
		
		call	TocUpdateCategory
		
		add	sp, size TocUpdateCategoryParams
		
	;
	; Find the category, and cache the array pointers in our
	; instance data. 
	;
		
		call	TocFindCategory
EC <		ERROR_C CATEGORY_NOT_FOUND			>
	;
	; Fetch the count from the item array
	;
		
		call	PrefTocListGetItemArray	; di - VM handle of array
		call	TocGetFileHandle	; bx- VM file handle
		call	HugeArrayGetCount	; ax - count
		
	;
	; Add the number of extra entries.
	;
		
		call	PrefTocListGetNumExtraEntries
		add	cx, ax
		
	;
	; Save the selection, for those cases where there's a default
	; value specified in the .ui file (usually 0 or 1, 
	; corresponding to an "extra entry")
	;
		
		push	cx
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		pop	cx
		
		pushf			; carry set if none selected
		push	ax		; ax - selection
		
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjCallInstanceNoLock
		
		pop	cx
		popf
		jc	afterSet
		
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx
		call	ObjCallInstanceNoLock
		
afterSet:
		
		call	FilePopDir
		
		mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
		call	GenCallApplication
		
		.leave
		ret
PrefTocListBuildArray	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PrefTocListQueryItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the moniker for an entry in the dynamic list

CALLED BY:	MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER

PASS:		*ds:si	= PrefDeviceList object
		ds:di	= PrefDeviceListInstance
		bp	= entry number whose moniker is requested.

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb  5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTocListQueryItemMoniker method dynamic PrefTocListClass,
		MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
		
SBCS <locals	local	NAME_ARRAY_MAX_NAME_SIZE dup (char)		>
DBCS <locals	local	NAME_ARRAY_MAX_NAME_SIZE dup (wchar)		>
		
		mov	ax, bp			; element #
		
		.enter
		
		push	bp
		
		mov	cx, ss
		lea	dx, locals
		mov	bp, NAME_ARRAY_MAX_NAME_SIZE
		call	PrefTocListGetItemName
		
		mov	bp, ax
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	ObjCallInstanceNoLock
		
		pop	bp
		
		.leave
		ret
PrefTocListQueryItemMoniker		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListGetItemPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get ds:di pointing to the specified element data.
		Caller MUST call HugeArrayUnlock when done

CALLED BY:	PrefTocListGetItemName

PASS:		ax - device #
		*ds:si - PrefTocList

RETURN:		IF FOUND:
			carry clear
			ds:di - TocDeviceStruct
			cx - size of data (ie, stringLength (in bytes) + size
			TocDeviceStruct (in bytes))
			caller MUST call HugeArrayUnlock when done
		ELSE:
			carry set
			di - destroyed
			nothing to unlock

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Caller must unlock the HugeArray element, but only if it was
	locked (carry clear)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTocListGetItemPtr	proc near
		uses	ax,bx,dx,si
		
EC <		call	ECCheckPrefTocListDSSI	>
		
		.enter
		call	PrefTocListGetItemArray	; di - SortedNameArray
		call	TocGetFileHandle
		clr	dx
		call	HugeArrayLock
		
		tst	ax
		jz	notFound
		
		mov	di, si
		mov	cx, dx
done:
		.leave
		ret

notFound:
		stc
		jmp	done
		
		
PrefTocListGetItemPtr	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PrefTocListGetItemArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the SortedNameArray handle for this list.

CALLED BY:	PrefTocListGetItemPtr

PASS:		*ds:si - PrefTocList

RETURN:		di - VM handle of SortedNameArray

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTocListGetItemArray	proc near
		class	PrefTocListClass
		
		uses	bx
		
		.enter
		
EC <		call	ECCheckPrefTocListDSSI	>
		
		DerefPref	ds, si, di
		lea	bx, ds:[di].PTLI_tocInfo.TCS_files
		test	ds:[di].PTLI_flags, mask TUCF_EXTENDED_DEVICE_DRIVERS
		jz	gotPtr
		lea	bx, ds:[di].PTLI_tocInfo.TCS_devices
gotPtr:
		mov	di, ds:[bx]
		
		.leave
		ret
PrefTocListGetItemArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PrefTocListGetDriverArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the array of drivers

CALLED BY:	PrefTocListGetSelectedDriverName

PASS:		*ds:si - PrefTocList

RETURN:		ax:di - dbptr to NameArray of TocFileStruct
		structures. 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTocListGetDriverArray	proc near
		class	PrefTocListClass
		.enter
		
EC <		call	ECCheckPrefTocListDSSI	>
		
		DerefPref	ds, si, di
		
		movdw	axdi, ds:[di].PTLI_tocInfo.TCS_files
		
		.leave
		ret
PrefTocListGetDriverArray	endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PrefTocListSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	If this is an extended device driver, then save the
		"driver = " key

PASS:		*ds:si	= PrefTocListClass object
		ds:di	= PrefTocListClass instance data
		es	= Segment of PrefTocListClass.

		ss:bp 	= GenOptionsParams

RETURN:		nothing 	

DESTROYED:	cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTocListSaveOptions	method	dynamic	PrefTocListClass, 
		MSG_GEN_SAVE_OPTIONS
		uses	ax
passedBP	local	word	push	bp
spuiDOSName	local	DosDotFileName
tocBuffer	local	TOC_ELEMENT_BUFFER_SIZE dup (TCHAR)
		.enter

	;
	; use DOS name?
	;
		mov	ax, ATTR_PREF_TOC_LIST_STORE_DOS_NAME
		call	ObjVarFindData
		LONG jc	storeDOSName
	;
	; If this object is not a device list, then no need to do
	; anything special.
	;
		mov	di, ds:[si]
		add	di, ds:[di].PrefTocList_offset
		test	ds:[di].PTLI_flags, mask TUCF_EXTENDED_DEVICE_DRIVERS
		jz	done
		
	;
	; Write info word, if specified
	;
		mov	ax, ATTR_PREF_TOC_LIST_INFO_KEY
		call	ObjVarFindData
		jnc	afterInfo
		
		mov	ax, MSG_PREF_TOC_LIST_GET_SELECTED_ITEM_INFO
		call	ObjCallInstanceNoLock
		jc	afterInfo		
		
	;
	; Now, deref the vardata again in case it moved and write out
	; the info.
	;
		push	ax
		mov	ax, ATTR_PREF_TOC_LIST_INFO_KEY
		call	ObjVarFindData
		pop	ax
		push	bp
		mov	dx, bx
		mov	cx, ds				;cx:dx <- key
		push	ds, si	
		segmov	ds, ss
		mov	bp, ss:passedBP
		lea	si, ss:[bp].GOP_category	;ds:si <- category
		push	bp
		mov_tr	bp, ax
		call	InitFileWriteInteger
		pop	bp
		pop	ds, si
		pop	bp
		
afterInfo:
	;
	; Get the name of the selected driver. If bp=0, then no driver
	; is selected.
	;
		push	bp
		mov	cx, ss
		lea	dx, ss:tocBuffer	;cx:dx <- buffer
		mov	bp, TOC_ELEMENT_BUFFER_SIZE
		mov	ax, MSG_PREF_TOC_LIST_GET_SELECTED_DRIVER_NAME
		call	ObjCallInstanceNoLock
		tst	bp			;any name returned?
		pop	bp
		jz	afterWrite		;branch if not
		
		push	ds, es, si
		segmov	ds, ss
		mov	bx, ss:passedBP
		lea	si, ss:[bx].GOP_category
		
		mov	es, cx
		mov	di, dx			; string to write
		mov	cx, cs
		mov	dx, offset driverKey
		CheckHack <segment driverKey eq @CurSeg>
		call	InitFileWriteString
		pop	ds, es, si
		
afterWrite:
		
done:
		.leave
		mov	di, offset PrefTocListClass
		GOTO	ObjCallSuperNoLock

	;
	; store the DOS name instead
	;
storeDOSName:
	;
	; get the DOS name
	;
		mov	cx, ss
		lea	dx, ss:spuiDOSName
		mov	ax, MSG_PREF_TOC_LIST_GET_DOS_NAME
		call	ObjCallInstanceNoLock
	;
	; write it out to the .INI file
	;
		push	bp, es, ds
		segmov	es, ss
		lea	di, ss:spuiDOSName		;es:di <- string
		mov	bp, ss:passedBP			;ss:bp <- params
		segmov	ds, ss, cx
		lea	si, ss:[bp].GOP_category	;ds:si <- category
		lea	dx, ss:[bp].GOP_key		;cx:dx <- key
		call	InitFileWriteString
		pop	bp, es, ds

		.leave
		ret
PrefTocListSaveOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PrefTocListLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Load the DOS name if this has ATTR_PREF_TOC_LIST_STORE_DOS_NAME

PASS:		*ds:si	= PrefTocListClass object
		ds:di	= PrefTocListClass instance data
		es	= Segment of PrefTocListClass.

		ss:bp 	= GenOptionsParams

RETURN:		nothing 	

DESTROYED:	cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/29/00   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTocListLoadOptions	method	dynamic	PrefTocListClass, 
		MSG_GEN_LOAD_OPTIONS
passedBP	local	word
spuiName	local	FileLongName
spuiDOSName	local	FileLongName	;just in case

	;
	; check for normal case
	;
		push	ax
		mov	ax, ATTR_PREF_TOC_LIST_STORE_DOS_NAME
		call	ObjVarFindData
		pop	ax
		jnc	callSuper

		mov_tr	ax, bp
		.enter
		mov	ss:passedBP, ax
	;
	; read the DOS name from the INI file
	;
		push	ds, si, bp
		segmov	es, ss
		lea	di, ss:spuiDOSName
		mov	bp, ss:passedBP
		segmov	ds, ss, cx
		lea	si, ss:[bp].GOP_category	;ds:si <- category
		lea	dx, ss:[bp].GOP_key		;cx:dx <- key
		mov	bp, InitFileReadFlags <0, 0, 0, (size FileLongName)>
		call	InitFileReadString
		pop	ds, si, bp
		jc	afterSetSelection		;branch if none
	;
	; go to the correct directory
	;
		call	FilePushDir
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathSetCurrentPathFromObjectPath
	;
	; get its longname
	;
		push	ds
		segmov	ds, ss
		lea	dx, ss:spuiDOSName
		mov	ax, FEA_NAME
		mov	cx, (size FileLongName)
		lea	di, ss:spuiName
		call	FileGetPathExtAttributes
		pop	ds

		call	FilePopDir
	;
	; set the list selection
	;
		push	bp
		mov	cx, ss
		lea	dx, ss:spuiName
		clr	bp				;bp <- exact match
		mov	ax, MSG_PREF_DYNAMIC_LIST_FIND_ITEM
		call	ObjCallInstanceNoLock		;ax <- item #
		pop	bp
		jc	afterSetSelection

		mov_tr	cx, ax				;cx <- item #
		mov	ax, MSG_PREF_ITEM_GROUP_SET_ORIGINAL_SELECTION
		call	ObjCallInstanceNoLock
afterSetSelection:

		.leave
		ret

callSuper:
		mov	di, offset PrefTocListClass
		GOTO	ObjCallSuperNoLock
PrefTocListLoadOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListGetSelectedItemInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the info field of the selected device

PASS:		*ds:si	= PrefTocListClass object
		ds:di	= PrefTocListClass instance data
		es	= Segment of PrefTocListClass.

RETURN:		if found:
			carry clear
			ax - device info
		else
			carry set

DESTROYED:	nothing  

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTocListGetSelectedItemInfo	method	dynamic	PrefTocListClass, 
			MSG_PREF_TOC_LIST_GET_SELECTED_ITEM_INFO
		
		uses	cx,dx,bp
		.enter
		
		
		call	GetSelection
		cmp	ax, GIGS_NONE
		stc
		je	done
		
		call	PrefTocListCheckExtraEntry
		jc	extraEntry		; ax <- extra entry info, or
						; item #
		
		call	PrefTocListGetItemPtr
		mov	ax, 0			; don't trash carry
		jc	done
		
		mov	ax, ds:[di].TDS_info
		call	HugeArrayUnlock	
done:
		.leave
		ret
		
extraEntry:
		mov	ax, ds:[di].PTEE_info
		clc
		jmp	done
		
		
PrefTocListGetSelectedItemInfo	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection without trashing the #!%$#&*
		registers. 

CALLED BY:	PrefTocListGetSelectedDeviceInfo, 
		PrefTocListGetSelectedDriverName

PASS:		*ds:si - PrefTocList

RETURN:		ax - selection

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelection	proc near
		uses	cx,dx,bp
		.enter
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		.leave
		ret
GetSelection	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListGetSelectedDriverName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Fill in the buffer with the name of the driver of the
		selected device.	

PASS:		*ds:si	= PrefTocListClass object
		ds:di	= PrefTocListClass instance data
		es	= Segment of PrefTocListClass.
		cx:dx	= buffer to fill in
		bp 	= length of buffer (# chars)

RETURN:		bp = length of string copied (0 if none) (# chars)

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTocListGetSelectedDriverName	method	dynamic	PrefTocListClass, 
		MSG_PREF_TOC_LIST_GET_SELECTED_DRIVER_NAME
		uses	ax,cx,dx
		.enter
		
if ERROR_CHECK
		test	ds:[di].PTLI_flags, mask TUCF_EXTENDED_DEVICE_DRIVERS
		ERROR_Z NOT_A_DEVICE_LIST
endif
		
		
		call	GetSelection		; ax <- selection
		cmp	ax, GIGS_NONE
		je	notFound
		
		mov	es, cx			; buffer segment
		
		call	PrefTocListCheckExtraEntry
		jc	extraEntry
		
		push	ds, si				; *ds:si - PrefTocList
		call	PrefTocListGetItemPtr
		jc	notFoundAndPop

		mov	bx, ds:[di].TDS_driver
		call	HugeArrayUnlock			; unlock it
		pop	ds, si
		
		call	PrefTocListGetDriverArray	; ax:di - driver array
		call	TocDBLock
		mov_tr	ax, bx
		call	ChunkArrayElementToPtr		; ds:di - ptr, cx-size
EC <		ERROR_C ELEMENT_NUMBER_OUT_OF_BOUNDS 	>
		
		add	di, offset NAE_data + offset TFS_name
		sub	cx, offset NAE_data + offset TFS_name
		call	CopyStringDSDIToESDX
		call	TocDBUnlock
		
done:
		.leave
		ret

notFoundAndPop:
		pop	ds, si		
notFound:
		clr	bp
		jmp	done

		
extraEntry:
		mov	di, ds:[di].PTEE_driver
		mov	di, ds:[di]
		ChunkSizePtr	ds, di, cx
		call	CopyStringDSDIToESDX
		jmp	done	

PrefTocListGetSelectedDriverName	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyStringDSDIToESDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the string at DS:DI to CX:DX

CALLED BY:	PrefTocListGetItemName, 
			PrefTocListGetSelectedDriverName

PASS:		ds:di - source
		es:dx - dest
		cx - size of source (# bytes)
		bp - length of dest (# chars)

RETURN:		bp - # chars copied.  0 if source bigger than dest

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyStringDSDIToESDX	proc near
		uses	ax,ds,es,si,di,cx
		.enter
		
		mov	si, di
		
DBCS <		shl	bp, 1			; # chars -> # bytes	>

if ERROR_CHECK
	; Copious error-checking
		push	ds, si
		call	ECCheckBounds
		segmov	ds, es
		mov	si, dx
		call	ECCheckBounds
		lea	si, ds:[si][bp][-1]
		call	ECCheckBounds
		pop	ds, si
endif
		
		mov	di, dx	
		
		cmp	cx, bp
		jg	tooBig	
		mov	bp, cx			; string length
		shr	cx
		rep	movsw
		jnc	afterByte
		movsb
afterByte:
SBCS <		mov	{byte} es:[di], 0		; null terminate>
DBCS <		mov	{word} es:[di], 0		; null terminate>
		
done:
		.leave
		ret
tooBig:
		clr	bp
		jmp	done
CopyStringDSDIToESDX	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListGetItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefTocListClass object
		ds:di	= PrefTocListClass instance data
		es	= dgroup
		ss:bp	= GetItemMonikerParams

RETURN:		buffer filled in
		bp - length of string (zero if buffer too short) (# chars)

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTocListGetItemMoniker	method	dynamic	PrefTocListClass, 
		MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
		uses	cx,dx
		.enter
		movdw	cxdx, ss:[bp].GIMP_buffer
		mov	ax, ss:[bp].GIMP_identifier
		mov	bp, ss:[bp].GIMP_bufferSize
		call	PrefTocListGetItemName
		
		.leave
		ret
PrefTocListGetItemMoniker	endm

	



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListGetItemName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the name of an item

CALLED BY:	PrefTocListGetItemMoniker

PASS:		cx:dx - buffer to fill in
		bp - length of buffer (# chars)
		ax - device number
		*ds:si - PrefTocList

RETURN:		bp 	- length of item name (w/o NULL) (# chars)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTocListGetItemName	proc near
		class	PrefTocListClass
		
		uses	ax,bx,cx,ds,di,ds,si,es
		
		.enter
		
EC <		call	ECCheckPrefTocListDSSI	>
		
		mov	es, cx			; es:dx - dest
		
		call	PrefTocListCheckExtraEntry
		jc	extraEntry
		
	;
	; Get a pointer into the TOC file.  We'll either be pointing
	; to a TocFileStruct or a TocDeviceStruct, and we need to know
	; which, so that we can point to the string portion.
	;
		
		DerefPref	ds, si, bx
		mov	bx, ds:[bx].PTLI_flags
		
		call	PrefTocListGetItemPtr		; cx - size of info
		jc	notFound
		
		test	bx, mask TUCF_EXTENDED_DEVICE_DRIVERS 
		jnz	device
		
		add	di, offset TFS_name
		sub	cx, offset TFS_name
		jmp	copyString
		
device:
		add	di, offset TDS_name
		sub	cx, offset TDS_name
copyString:
		call	CopyStringDSDIToESDX	; characters copied =>
						; BP (w/o NULL)
		
		call	HugeArrayUnlock
		
done:
		.leave
		ret
		
extraEntry:
		mov	di, ds:[di].PTEE_item
		mov	di, ds:[di]
		ChunkSizePtr	ds, di, cx
		call	CopyStringDSDIToESDX
		jmp	done

	;
	; The item isn't in the array for some reason.  Just return a
	; null string.
	;
notFound:

		mov	di, dx
DBCS <		mov	{byte} es:[di], 0				>
SBCS <		mov	{word} es:[di], 0				>
		clr	bp
		jmp	done
		
		
PrefTocListGetItemName	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListFindItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the element # of the passed item

PASS:		*ds:si	= PrefTocListClass object
		ds:di	= PrefTocListClass instance data
		es	= dgroup
		cx:dx	- string to find
		bp	- nonzero to ignore case		

RETURN:		carry clear if found:
			ax - item number
		carry set if not found:
			ax - item number after where device would be

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/18/92   	Initial version.
	gene	3/26/98		Changed to use ObjVarScanData()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScanExtraEntries	proc	near
		segmov	es, cs, ax
		mov	ax, length tocListExtraFindHandlers
		call	ObjVarScanData
		ret
ScanExtraEntries	endp

CheckHack <segment tocListExtraFindHandlers eq segment tocListExtraCheckHandlers>
CheckHack <segment tocListExtraFindHandlers eq segment tocListExtraCountHandlers>
CheckHack <length tocListExtraFindHandlers eq length tocListExtraCheckHandlers>
CheckHack <length tocListExtraFindHandlers eq length tocListExtraCountHandlers>

tocListExtraFindHandlers VarDataHandler \
	<ATTR_PREF_TOC_LIST_EXTRA_ENTRY_1, offset ListExtraFindHandler>,
	<ATTR_PREF_TOC_LIST_EXTRA_ENTRY_2, offset ListExtraFindHandler>

ListExtraFindHandler	proc	far
		uses	es
		.enter
	;
	; See if we've already found the string (there's no way
	; to abort the ObjVarScanData() call early)
	;
		tst	bp				;found string?
		jz	done				;branch if so
	;
	; See if the passed string matches the extra entry
	;
		mov	es, bp				;es:dx <- string
		call	CompareStringESDXWithExtraEntry
		je	foundString
		inc	cx				;cx <- adjust count
done:
		.leave
		ret

foundString:
		clr	bp				;bp <- indicate found
		jmp	done
ListExtraFindHandler	endp

PrefTocListFindItem	method	dynamic	PrefTocListClass,
		MSG_PREF_DYNAMIC_LIST_FIND_ITEM
		uses	dx,bp
		.enter
		
	;
	; 3/26/98: changed to use ObjVarScanData() so that more than
	; two EXTRA_ENTRY devices can be specified.
	;
		push	cx				;save string segment
		push	bp
		mov	bp, cx
		clr	cx		; item number (start by assuming zero)

		mov	di, offset tocListExtraFindHandlers
		call	ScanExtraEntries
	;
	; See if we found the string in vardata
	;
		tst	bp				;found string?
		pop	bp
		pop	es				;es <- string segment
		jz	done				;branch if so
	;
	; String not found in vardata
	;
		push	cx			; number of extra entries
		call	PrefTocListGetItemArray	; di - array
		mov	si, dx
		segmov	ds, es
		clr	bx, cx		; assume no flags -- don't copy name
		tst	bp
		jz	gotFlags
		mov	bl, mask SNAFF_IGNORE_CASE
gotFlags:
		call	TocSortedNameArrayFind		; bx - element in array
		pop	cx
		add	cx, ax
		
done:
		mov_tr	ax, cx			; ax <- item number
		.leave
		ret
PrefTocListFindItem	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareStringESDXWithExtraEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the string at es:dx with the item in the extra
		entry at ds:bx.  Sets the Z flag if equal

CALLED BY:	PrefTocListFindItem

PASS:		es:dx - string
		ds:bx - PrefTocExtraEntry to compare against

RETURN:		nothing 

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareStringESDXWithExtraEntry	proc near
		uses	si,cx,di
		.enter
		
		mov	si, ds:[bx].PTEE_item
		
		mov	si, ds:[si]		; ds:si - extra entry string
EC <		call	ECCheckLMemChunk			>
		
		mov	di, dx			; es:di - one string
		clr	cx
		call	LocalCmpStrings
		
		.leave
		ret
CompareStringESDXWithExtraEntry	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListCheckExtraEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed item # requires that we use the
		extra entry fields 

CALLED BY:	PrefTocListGetSelectedDriverName,
		PrefTocListGetSelectedDeviceInfo,
		PrefTocListGetItemName

PASS:		*ds:si - PrefDeviceList
		ax - item #

RETURN:		If Extra Entry:
			ax - entry number
			ds:di - points to extra entry name
			carry set
		Else
			ax - subtracted by # of extra entries
			carry clear
			di - unchanged

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/ 1/92   	Initial version.
	gene	3/26/98		Changed to use ObjVarScanData()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
tocListExtraCheckHandlers VarDataHandler \
	<ATTR_PREF_TOC_LIST_EXTRA_ENTRY_1, offset ListExtraCheckHandler>,
	<ATTR_PREF_TOC_LIST_EXTRA_ENTRY_2, offset ListExtraCheckHandler>

ListExtraCheckHandler	proc	far
		jcxz	foundEntry			;branch if at entry
afterEntry:
		dec	cx				;cx <- adjust count
		ret

foundEntry:
		mov	dx, bx				;ds:dx <- ptr to data
		jmp	afterEntry
ListExtraCheckHandler	endp

PrefTocListCheckExtraEntry	proc near
		uses	bx
		
		class	PrefTocListClass
		
		.enter
		
EC <		call	ECCheckPrefTocListDSSI	>
		
		cmp	ax, GIGS_NONE
		je	done
		
		call	PrefTocListGetNumExtraEntries
		cmp	ax, cx
		jl	useExtraEntry
		sub	ax, cx		; clears carry
done:
		.leave
		ret

useExtraEntry:
		push	es, ax, dx
		mov	cx, ax				;cx <- item #

		mov	di, offset tocListExtraCheckHandlers
		call	ScanExtraEntries

		mov	di, dx		; ds:di - pointer to PrefTocExtraEntry
		pop	es, ax, dx
		stc
		jmp	done
		
PrefTocListCheckExtraEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListGetNumExtraEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the number of extras from the instance data

CALLED BY:	PrefTocListBuildArray, PrefTocListCheckExtraEntry

PASS:		*ds:si - sorted list

RETURN:		cx - # extra entries

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This is a potentially slow operation -- we could instead cache
	this value if we wanted...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/ 1/92   	Initial version.
	gene	3/26/98		Changed to use ObjVarScanData()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
tocListExtraCountHandlers VarDataHandler \
	<ATTR_PREF_TOC_LIST_EXTRA_ENTRY_1, offset ListExtraCountHandler>,
	<ATTR_PREF_TOC_LIST_EXTRA_ENTRY_2, offset ListExtraCountHandler>

ListExtraCountHandler	proc	far
		inc	cx				;cx <- adjust count
		ret
ListExtraCountHandler	endp

PrefTocListGetNumExtraEntries	proc near
		uses	ax,di,bx,es
		
		class	PrefTocListClass
		
		.enter
		
EC <		call	ECCheckPrefTocListDSSI	>
		
		clr	cx		; item number (start by assuming zero)

		mov	di, offset tocListExtraCountHandlers
		call	ScanExtraEntries

		.leave
		ret
PrefTocListGetNumExtraEntries	endp




if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckPrefTocListDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ensure *ds:si - is a pref device list

CALLED BY:	PrefTocListClass procedures

PASS:		*ds:si - pref device list

RETURN:		nothing 

DESTROYED:	nothing - flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckPrefTocListDSSI	proc near
		uses	es, di
		.enter
		
		pushf
		segmov	es, <segment PrefTocListClass>, di
		mov	di, offset PrefTocListClass
		call	ObjIsObjectInClass
		ERROR_NC DS_SI_WRONG_CLASS
		popf
		
		.leave
		ret
ECCheckPrefTocListDSSI	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListSendStatusMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cope with any associated container object when something new
		gets selected

CALLED BY:	MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
PASS:		*ds:si	= PrefTocList object
		cx	= non-zero if GIGSF_MODIFIED bit should be set in
			  status message
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 7/92 	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTocListSendStatusMessage method dynamic PrefTocListClass, 
		MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		uses	cx, ax
		.enter
		mov	ax, ATTR_PREF_TOC_LIST_CONTAINER
		call	ObjVarFindData
		jnc	done
		movdw	cxdx, ({optr}ds:[bx])
		call	PrefTocListSendSelectionToContainer
done:
		.leave
		mov	di, offset PrefTocListClass
		GOTO	ObjCallSuperNoLock
PrefTocListSendStatusMessage endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListSendSelectionToContainer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the name of the vm file/library associated with the
		current selection to the passed container object. If there
		is no associated vm file/library, the container is set 
		not-usable

CALLED BY:	(INTERNAL) PrefTocListSendSelectionToContainer
PASS:		*ds:si	= PrefTocList object
		^lcx:dx	= PrefContainer object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTocListSendSelectionToContainer proc near
		class	PrefTocListClass
container	local	optr		push cx, dx
driverName	local	FileLongName
matchAttrs	local	2 dup (FileExtAttrDesc)

		uses	es, si
		.enter

		mov	di, ds:[si]
		add	di, ds:[di].PrefTocList_offset
	;
	; Fetch the name of the selected file, based on what type of data
	; we're displaying (for a non-driver list, we can just use the item's
	; moniker, as that's the file name, while a driver list displays the
	; device name, so we need to ask for the driver name instead)
	; 
		mov	cx, ss
		lea	dx, ss:[driverName]		; cx:dx <- buffer
		push	bp
		mov	bp, length driverName		; bp <- buffer size
		mov	ax, MSG_PREF_TOC_LIST_GET_SELECTED_DRIVER_NAME
		test	ds:[di].PTLI_flags, mask TUCF_EXTENDED_DEVICE_DRIVERS
		jnz	haveMessage
		mov	ax, MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
haveMessage:
		call	ObjCallInstanceNoLock
		tst	bp				; buffer big enough?
		pop	bp
		LONG jz	noSpecialPrefs			; nope
		
	;
	; Strip off any leading "EC " from the driverName, as prefs
	; are the same for either one.
	; 
SBCS <		cmp	{word}ss:[driverName], 'E' or ('C' shl 8)	>
DBCS <		cmp	{word}ss:[driverName], 'E'			>
DBCS <		jne	findFile					>
DBCS <		cmp	{word}ss:[driverName][2], 'C'			>
		jne	findFile
SBCS <		cmp	ss:[driverName][2], ' '				>
DBCS <		cmp	{word}ss:[driverName][4], ' '			>
		jne	findFile
		
	;
	; Shuffle the name down over top of the "EC "
	; 
		push	ds, si
SBCS <		lea	si, ss:[driverName][3]				>
DBCS <		lea	si, ss:[driverName][6]				>
		segmov	ds, ss, cx
		mov	es, cx
		lea	di, ss:[driverName]
		mov	cx, length driverName - 3
		LocalCopyNString
		pop	ds, si
		
findFile:
if DBCS_PCGEOS
	;
	; for DBCS, convert to SBCS as FEA_NOTICE is SBCS
	; (in-place DBCS-to-SBCS works)
	;
		push	ds, si
		segmov	ds, ss, cx
		mov	es, cx
		lea	si, ss:[driverName]
		lea	di, ss:[driverName]
		mov	ax, '.'			; default char
		mov	bx, CODE_PAGE_US	; should give SBCS
		clr	cx, dx			; null-term, default FS driver
		call	LocalGeosToDos
		pop	ds, si
		LONG jc	noSpecialPrefs		; couldn't convert
endif
	;
	; Look for a file whose FEA_NOTICE attribute matches the
	; longname of the selected driver.
	; 
		call	FilePushDir
		
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathSetCurrentPathFromObjectPath
		
		mov	ss:[matchAttrs][0*FileExtAttrDesc].FEAD_attr, FEA_NOTICE	
		mov	ss:[matchAttrs][0*FileExtAttrDesc].FEAD_value.segment, ss
		lea	ax, ss:[driverName]
		mov	ss:[matchAttrs][0*FileExtAttrDesc].FEAD_value.offset, ax
		mov	ss:[matchAttrs][0*FileExtAttrDesc].FEAD_size, size driverName
		
		mov	ss:[matchAttrs][1*FileExtAttrDesc].FEAD_attr, FEA_END_OF_LIST
		
		push	bp
		lea	ax, ss:[matchAttrs]
		sub	sp, size FileEnumParams
		mov	bp, sp
		mov	ss:[bp].FEP_searchFlags, mask FESF_GEOS_NON_EXECS or \
							mask FESF_GEOS_EXECS
		mov	ss:[bp].FEP_returnAttrs.segment, 0
		mov	ss:[bp].FEP_returnAttrs.offset, FESRT_NAME
		mov	ss:[bp].FEP_returnSize, size FileLongName
		movdw	ss:[bp].FEP_matchAttrs, ssax
		mov	ss:[bp].FEP_bufSize, 1
		mov	ss:[bp].FEP_skipCount, 0
		
		call	FileEnum
		pop	bp
		
		call	FilePopDir
		
		jc	noSpecialPrefs
		jcxz	noSpecialPrefs
		
	;
	; Build the full path of the file in question.
	; 
		push	bp
		pushdw	ss:[container]
		call	PrefTocListBuildPath
		popdw	axsi
	;
	; Tell the container about it.
	; 
		push	bx
		mov_tr	bx, ax
		mov	ax, MSG_GEN_PATH_SET
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		jc	freeFullPath
		
	;
	; Since that was successful, set the container usable.
	; 
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		clc
		
freeFullPath:
	;
	; Free the full-path block.
	; 
		lahf
		pop	bx
		call	MemFree
		sahf
		pop	bp
		jc	noSpecialPrefs	; => path set was bad, so make
					; sure  container isn't usable.
		
done:
		.leave
		ret
		
		
noSpecialPrefs:
		movdw	bxsi, ss:[container]
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		push	bp
		call	ObjMessage
		pop	bp
		jmp	done
PrefTocListSendSelectionToContainer endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListBuildPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the full path of the found file to give to the
		container

CALLED BY:	(INTERNAL) PrefTocListSendSelectionToContainer
PASS:		*ds:si	= PrefTocList
		^hbx	= FileLongName of found file
RETURN:		cx:dx	= full path
		bx	= handle of same
		bp	= disk handle
DESTROYED:	ax, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTocListBuildPath proc	near
		class	PrefTocListClass
		.enter
	;
	; Get the list's current path into a block o' memory.
	; 
		push	bx			; save block holding filename
		clr	di
		mov	es, di			; es <- 0 => allocate block, please
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathGetObjectPath
		push	cx			; save disk handle
		
	;
	; Enlarge returned block to hold the filename, plus a path separator.
	; 
		mov_tr	bx, ax
		mov	ax, MGIT_SIZE
		call	MemGetInfo		; ax <- # bytes
SBCS <		add	ax, size FileLongName + 1			>
DBCS <		add	ax, size FileLongName + 2			>
		mov	ch, mask HAF_LOCK
		call	MemReAlloc
	;
	; Find the end of the path.
	; 
		mov	es, ax
		clr	ax, di
		mov	cx, -1
		LocalFindChar
		LocalPrevChar	esdi		; point to the char before
		LocalPrevChar	esdi		;  the null term
		LocalLoadChar	ax, '\\'
SBCS <		scasb				; is it a backslash?	>
DBCS <		scasw				; is it a backslash?	>
		je	copyName		; yes -- no need of another
		LocalPutChar	esdi, ax	; no -- replace the null byte
copyName:
	;
	; Copy the filename onto the end.
	; 
		pop	bp			; bp <- disk handle
		mov_tr	ax, bx			; preserve full path handle
		pop	bx			; bx <- filename
		push	ds, si, ax
		call	MemLock
		mov	ds, ax
		clr	si
		mov	cx, length FileLongName
		LocalCopyNString
	;
	; Free that block.
	; 
		call	MemFree
	;
	; Set up for return.
	; 
		pop	ds, si, bx		; bx <- path handle
		
		mov	cx, es			; cx:dx <- path
		clr	dx
		.leave
		ret
PrefTocListBuildPath endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListGetSelectedItemPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the full path of the selected item.

CALLED BY:	MSG_PREF_TOC_LIST_GET_SELECTED_ITEM_PATH
PASS:		*ds:si	= PrefTocList object
		ds:di	= PrefTocListInstance
RETURN:		cx:dx	= full path
		ax	= locked handle of same
		bp	= disk handle
DESTROYED:	bx, si, di
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTocListGetSelectedItemPath method dynamic PrefTocListClass, 
		MSG_PREF_TOC_LIST_GET_SELECTED_ITEM_PATH
		.enter
	;
	; Get the current selection into a block on the heap for use by
	; PrefTocListBuildPath
	; 
		mov	ax, size FileLongName
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		mov	cx, ax
		clr	dx
		mov	bp, length FileLongName
		mov	ax, MSG_PREF_TOC_LIST_GET_SELECTED_DRIVER_NAME
		test	ds:[di].PTLI_flags, mask TUCF_EXTENDED_DEVICE_DRIVERS
		jnz	haveMessage
		mov	ax, MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
haveMessage:
		call	ObjCallInstanceNoLock
		call	MemUnlock
	;
	; Now use common routine to create our return value.
	; 
		call	PrefTocListBuildPath
		mov_tr	ax, bx		; return handle in ax
		
		.leave
		ret
PrefTocListGetSelectedItemPath	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListCheckDeviceAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the driver for the selected device and see if it thinks
		the selected device is present.

CALLED BY:	MSG_PREF_TOC_LIST_CHECK_DEVICE_AVAILABLE
PASS:		*ds:si	= PrefTocList object
RETURN:		carry set if device available:
			if driver is video driver, ax = DisplayType
		carry clear if device not available
			ax	= 0 if device not present
				= GeodeLoadError + 1 if couldn't load driver
DESTROYED:	cx, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTocListCheckDeviceAvailable method dynamic PrefTocListClass, 
		MSG_PREF_TOC_LIST_CHECK_DEVICE_AVAILABLE
DBCS <deviceName	local	NAME_ARRAY_MAX_NAME_SIZE	dup (wchar)>
SBCS <deviceName	local	NAME_ARRAY_MAX_NAME_SIZE	dup (char)>
DBCS <driverName	local	NAME_ARRAY_MAX_NAME_SIZE	dup (wchar)>
SBCS <driverName	local	NAME_ARRAY_MAX_NAME_SIZE	dup (char)>
		
		.enter
		
		
	;
	; Call ourselves to fetch the device and driver names.
	; 
		push	bp
		mov	cx, ss
		lea	dx, deviceName
		mov	bp, length deviceName
		mov	ax, MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
		call	ObjCallInstanceNoLock
		pop	bp
		
		push	bp
		mov	cx, ss
		lea	dx, driverName
		mov	bp, length driverName
		mov	ax, MSG_PREF_TOC_LIST_GET_SELECTED_DRIVER_NAME
		call	ObjCallInstanceNoLock		; will upchuck
							; if list not
							;  for devices
		pop	bp
		
	;
	; Push to the directory that contains our drivers.
	; 
		call	FilePushDir
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathSetCurrentPathFromObjectPath
		
	;
	; Attempt to load the device driver.
	; 
		segmov	ds, ss
		lea	si, ss:[driverName]
		clr	ax, bx			; XXX: no protocol numbers
		call	GeodeUseDriver
		call	FilePopDir
		jc	cantLoad
		
	;
	; Driver loaded ok, so now call its DRE_TEST_DEVICE vector to see
	; if the desired device is actually present.
	; 
		push	bx			; driver handle
		call	GeodeInfoDriver		; ds:si <- DriverInfoStruct
	;
	; if video driver, return the display type...
	;
		
		clr	cx
		cmp	ds:[si].DIS_driverType, DRIVER_TYPE_VIDEO
		jne	testDevice
		mov	cl, ds:[si].VDI_displayType
testDevice:
		mov	bx, si			; ds:bx <- DriverInfoStruct
		mov	dx, ss
		lea	si, deviceName		; dx:si <- device name
		mov	di, DRE_TEST_DEVICE
		
callIt::
		call	ds:[bx].DIS_strategy

	;
	; Free up the driver now its dread work is accomplished.
	;
		pop	bx			; driver handle
		mov	ds, dx
		push	ax
		call	GeodeFreeDriver
		pop	ax
		
	;
	; See if the device is actually there.
	;
		xchg	ax, cx			; ax <- DisplayType, cx <- res.
		cmp	cx, DP_PRESENT
		je	ok
		cmp	cx, DP_CANT_TELL
		je	ok		
		
	;
	; Signal device's absence, returning carry clear (eventually).
	; 
		clr	ax
error:
		stc
ok:
		cmc		; want carry set if ok and clear if not...
		.leave
		ret
		
cantLoad:
	;
	; Couldn't load the video driver. If it's not because the thing's
	; already resident (error code is something other than
	; GLE_NOT_MULTI_LAUNCHABLE), return immediately.
	;
		inc	ax		; so it's non-zero
		jmp	error
PrefTocListCheckDeviceAvailable endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListSetTokenChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the token chars for this TOC list.

PASS:		*ds:si	- PrefTocListClass object
		ds:di	- PrefTocListClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/26/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTocListSetTokenChars	method	dynamic	PrefTocListClass, 
		MSG_PREF_TOC_LIST_SET_TOKEN_CHARS
		
		
	;
	; Store the token chars
	;
		push	ds, si, di
		lea	di, ds:[di].PTLI_tocInfo.TCS_tokenChars
		segmov	es, ds
		segmov	ds, ss
		mov	si, bp
		mov	cx, size TokenChars/2
		rep	movsw
		pop	ds, si, di
		
	;
	; Mark the object dirty (necessary?)
	;
		call	ObjMarkDirty
		
	;
	; Rescan stuff
	;
		
		mov	ax, MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
		GOTO	ObjCallInstanceNoLock
PrefTocListSetTokenChars	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTocListGetDosName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the DOS name for the selected driver

PASS:		*ds:si	- PrefTocListClass object
		ds:di	- PrefTocListClass instance data
		es	- dgroup

		cx:dx - buffer (at least DosDotFileName in size)

RETURN:		cx:dx - filled in (NULL for no selection)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        gene	2/29/00   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTocListGetDosName	method	dynamic PrefTocListClass,
					MSG_PREF_TOC_LIST_GET_DOS_NAME
		uses	ax, cx, dx, es
bufPtr		local	fptr.TCHAR push cx, dx
longName	local	FileLongName

		.enter
	;
	; go to the correct directory
	;
		call	FilePushDir
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathSetCurrentPathFromObjectPath
	;
	; get the longname from the list
	;
		push	bp
		mov	cx, ss
		lea	dx, ss:longName
		mov	bp, FILE_LONGNAME_LENGTH
		mov	ax, MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
		call	ObjCallInstanceNoLock
		pop	bp
	;
	; get the DOS name from the longname
	;
		segmov	ds, ss, cx
		lea	dx, ss:longName			;ds:dx <- filename
		les	di, ss:bufPtr			;es:di <- buffer
		mov	cx, (size DosDotFileName)	;cx <- buffer size
		mov	ax, FEA_DOS_NAME
		call	FileGetPathExtAttributes
		jnc	done				;branch if no error
		mov	{TCHAR}es:[di], 0		;store NULL if error
done:
	;
	; return to the old directory
	;
		call	FilePopDir

		.leave
		ret
PrefTocListGetDosName	endm
