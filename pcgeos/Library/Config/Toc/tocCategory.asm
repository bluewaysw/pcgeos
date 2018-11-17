COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tocCategory.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	TocLockCategoryArray	Return the category array.
	TocFindCategory		Find a category in the TOC file,
				loading the TocCategoryStructure if
				found.
	TocFindCategoryCB	Callback routine to find the category
				in the category array.
	TocUpdateCategory	Create the category if it doesn't
				exist, and update the file lists by
				scanning the current directory for
				files.
	TocCreateCategory	Create a new TOC category.
	TocUpdateFiles		Update the file list for a category.
	TocUpdateDeviceDrivers	Preform the file update for device
				drivers.
	TocUpdateNormalFiles	Update the non-device drivers list.
	TocHugeArrayUnlock	Unlock the current array element.
	StoreTocFileStructInfo	Copy the pertinent data into a
				TocFileStruct.
	CheckReleaseNumber	Check the release number of the file
				in the array and see if it matches
				that of the one on disk.  If not,
				delete it from the array.
	TocHugeArrayLock	Lock the TOC huge array element.
	TocAddFileCB		Standard routine to add a file to the
				SortedNameArray of files.
	TocHugeArrayEnum	Enumerate the huge array.
	TocRemoveExtraFilesCB	Callback routine to nuke a file from
				the TOC array if it's not in the
				current directory.
	TocDeleteFileFromArray	Delete this file from the array, and
				delete all devices that correspond to
				this file, if necessary.
	TocHugeArrayDelete	Delete this element from the array.
	GetFileSourceDisk	Return the SOURCE DISK number of the
				current element in the files array.
	GetFileName		Return the filename from the array
				element.
	TocLocateFiles		Locate the drivers with the given
				token.
	TocProcessDriver	Go through the device list for this
				driver, adding each name to the
				devices array.
	TocLoadExtendedInfo	Load the DriverExtendedInfoTable block
				for the driver, if it exists.
	TocMapPrinterInfo	Map the word of info stored in the
				printer driver's table into something
				we can use -- the PrinterConnections
				record for the device.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.
	pjc	1/26/95		Made multi-language compatible.

DESCRIPTION:
	

	$Id: tocCategory.asm,v 1.1 97/04/04 17:50:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocLockCategoryArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the category array.

CALLED BY:	(internal) TocFindCategory, TocUpdateCategory

PASS:		nothing 

RETURN:		*ds:si - Chunk array of TocCategoryStruct structures

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocLockCategoryArray	proc near
		uses	ax, di
		.enter

	; Lock the map block and fetch the category array.
		
		call	TocDBLockMap
		mov	si, ds:[si]
		movdw	axdi, ds:[si].TM_categories
		call	TocDBUnlock
		
	; Lock the category array.
		
		call	TocDBLock
		
		.leave
		ret
TocLockCategoryArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOCFINDCATEGORY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a category in the Toc file

CALLED BY:	GLOBAL
PARAMETERS:	Boolean (TocCategoryStruct *cat)
RETURN:		TRUE if category found
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGeosConvention
TOCFINDCATEGORY	proc	far	cat:fptr.TocCategoryStruct
		uses	es, di
		.enter
		les	di, ss:[cat]
		call	TocFindCategory
		.leave
		ret
TOCFINDCATEGORY	endp
SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocFindCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a category in the TOC file, loading the
		TocCategoryStructure if found.

CALLED BY:	GLOBAL: TocUpdateCategory

PASS:		es:di - TocCategoryStruct buffer
			(TCS_tokenChars MUST already be filled in --
			the other fields will be filled in by this routine)

RETURN:		carry SET if not found, carry clear otherwise

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocFindCategory	proc far
		
		uses	ax, bx, cx, dx, es, di, ds, si
		.enter
		
	; Lock down the category array.

		call	TocLockCategoryArray		; *ds:si - categories
		
	; Check if our category is in the array.

		mov	cx, {word} es:[di].TCS_tokenChars
		mov	dx, {word} es:[di].TCS_tokenChars+2
		
		push	es, di
		mov	bx, cs
		mov	di, offset TocFindCategoryCB
		clr	ax
		call	ChunkArrayEnum
		pop	es, dx
		
		cmc
		jc	done			; Our category was not found.
		
	; Our category was found: copy the TocCategoryStruct into the
	; return buffer.
		
		push	si
		call	ChunkArrayElementToPtr
		mov	si, di
		
		mov	di, dx
		mov	cx, size TocCategoryStruct
		rep	movsb
		pop	si
		clc
		
done:
	; Unlock the category array.

		call	TocDBUnlock
		
		.leave
		ret
		
TocFindCategory	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocFindCategoryCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to find the category in the category
		array.

CALLED BY:	TocFindCategory

PASS:		cx:dx - TokenChars to find
		ax - current element number
		ds:di - current TocCategoryStruct

RETURN:		if found:
			carry set
		else
			carry clear
			ax - next element number

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocFindCategoryCB	proc far
		.enter
		cmp	{word} ds:[di].TCS_tokenChars, cx
		jne	notFound
		cmp	{word} ds:[di].TCS_tokenChars+2, dx
		stc
		je	done
notFound:
		clc
		inc	ax
done:
		.leave
		ret
TocFindCategoryCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOCUPDATECATEGORY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the category if it doesn't exist, and update the file
		lists by scanning the current directory for files.

CALLED BY:	GLOBAL
PARAMETERS:	void (TocUpdateCategoryParams *)
RETURN:		nothing
SIDE EFFECTS:	The category is created or overwritten with new data.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGeosConvention
TOCUPDATECATEGORY proc	far	passedParams:fptr.TocUpdateCategoryParams

passedDS	local	sptr	push ds
params		local	TocUpdateCategoryParams
ForceRef	passedDS ; used in callback

		uses	ds, si
		.enter
		lds	si, ss:[passedParams]
		CheckHack <TUCP_flags eq 0>
		lodsw
		mov	ss:[params].TUCP_flags, ax
		CheckHack <TUCP_tokenChars eq 2>
		lodsw
		mov	{word}ss:[params].TUCP_tokenChars[0], ax
		lodsw
		mov	{word}ss:[params].TUCP_tokenChars[2], ax
		CheckHack <TUCP_fileArrayElementSize eq 6>
		lodsb
		mov	ss:[params].TUCP_fileArrayElementSize, al
		mov	ss:[params].TUCP_addCallback.offset, 
		offset __TOCUPDATECATEGORY_callback
		mov	ss:[params].TUCP_addCallback.segment, cs
		push	bp
		add	bp, offset params
		call	TocUpdateCategory
		pop	bp
		.leave
		ret
TOCUPDATECATEGORY endp
SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		__TOCUPDATECATEGORY_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to call the real callback function

CALLED BY:	TOCUPDATECATEGORY via TocUpdateCategory
PASS:		es:di	= filename to add
		*ds:si	= array to which to add it
RETURN:		carry clear if new element added
			ds:di	= pointer to new element
		carry set if add aborted
DESTROYED:	ax, bx, cx, dx, bp, es allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
__TOCUPDATECATEGORY_callback proc	far
		uses	es
		.enter	inherit TOCUPDATECATEGORY
	;
	; Re-establish TOCUPDATECATEGORY's frame pointer so we can get to
	; things.
	; 
		push	bp
		mov	bp, ss:[bp]		; bp <- bp we passed into 
						;  TocUpdateCategory
		sub	bp, offset params	; bp <- frame pointer for
						;  TOCUPDATECATEGORY
	;
	; Save the handle for DS away so we can dereference it after the
	; callback is done.
	; 
		mov	bx, ds:[LMBH_handle]
		push	bx
	;
	; Call the callback.
	; 
		push	es, di, bx, si		; Pass filename & optr of array.
		mov	ds, ss:[passedDS]	; Reload DS it's expecting
		les	di, ss:[passedParams]
		movdw	bxax, es:[di].TUCP_addCallback
		call	ProcCallFixedOrMovable
	;
	; Restore DS
	; 
		pop	bx
		call	MemDerefDS
		
		mov_tr	di, ax			; ds:di <- new element
		tst_clc	di
		jnz	done			; => add successful
		stc				; signal add aborted
done:
		pop	bp
		.leave
		ret
__TOCUPDATECATEGORY_callback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocUpdateCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the category if it doesn't exist, and update
		the file lists by scanning the current directory for
		files. 

CALLED BY:	GLOBAL

PASS:		ss:bp - TocUpdateCategoryParams
		CWD set to the directory where the files should be

RETURN:		nothing

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TocUpdateCategory	proc far
		uses	ax,bx,cx,dx,di,si,ds,es

params		local	nptr.TocUpdateCategoryParams	push	bp
flags		local	TocUpdateCategoryFlags
categoryBuf	local	TocCategoryStruct
fileBuf		local	TocFileStruct
deviceBuf	local	TocDeviceStruct
lastPInfo	local	word
lastPConn	local	PrinterConnections
fileHandle	local	hptr
driverType	local	word
printerInfo	local	word
printerConn	local	PrinterConnections
fileEnumBuffer	local	hptr
fileEnumCount	local	word
curElement	local	word
array		local	lptr
enumPtr		local	nptr
		
		.enter

ForceRef	fileBuf
ForceRef	deviceBuf
ForceRef	lastPInfo
ForceRef	lastPConn
ForceRef	fileHandle
ForceRef	driverType
ForceRef	printerInfo
ForceRef	printerConn
ForceRef	fileEnumBuffer
ForceRef	fileEnumCount
ForceRef	curElement
ForceRef	array
ForceRef	enumPtr


	; Gain exclusive access to the TOC file, just to be safe

		call	LoadDSDGroup
		PSem	ds, tocFileSem, TRASH_AX_BX
		
	; Move the (passed) BP into our PARAMS structure
		
		mov	bx, ss:[params]
		
	; Copy the flags to local variable (we use them often).
		
		mov	ax, ss:[bx].TUCP_flags
		ECCheckFlags	ax, TocUpdateCategoryFlags
		mov	ss:[flags], ax
		
	; See if the caller has a custom callback routine to add file
	; array elements, or if we should just use the default one
		
		test	ax, mask TUCF_ADD_CALLBACK
		jnz	gotCallback
		
		mov	ss:[bx].TUCP_addCallback.segment, cs
		mov	ss:[bx].TUCP_addCallback.offset, offset TocAddFileCB
		
gotCallback:
		
	; Copy the token chars to local variable.
		
		mov	cx, {word} ss:[bx].TUCP_tokenChars
		mov	{word} ss:[categoryBuf].TCS_tokenChars, cx
		mov	dx, {word} ss:[bx].TUCP_tokenChars+2
		mov	{word} ss:[categoryBuf].TCS_tokenChars+2, dx

	; Check if the category exists in the TOC file.  If so, fill
	; in the TocCategoryStruct.
		
		segmov	es, ss
		lea	di, ss:[categoryBuf]
		call	TocFindCategory
		jnc	gotCategory
		
	; Category does not exist.  Create it.

		call	TocCreateCategory
		
gotCategory:
		
	; If the TUCF_DIRECTORY_NOT_FOUND flag is set, then skip the
	; file update.
		
		test	ss:[flags], mask TUCF_DIRECTORY_NOT_FOUND
		jnz	done
		
		call	TocUpdateFiles	; update the files for this
					; category
done:

	; Flush any changes that may have been made, and then release
	; the semaphore

		call	LoadDSDGroup
		mov	bx, ds:[tocFileHandle]
		call	VMUpdate

		
		VSem	ds, tocFileSem, TRASH_AX_BX
		
		.leave
		ret
TocUpdateCategory	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocCreateCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new TOC category

CALLED BY:	(internal) TocUpdateCategory

PASS:		ss:bp - inherited local vars

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp,ds,es

PSEUDO CODE/STRATEGY:	
	Update the TocCategoryStruct on the stack

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocCreateCategory	proc near
		
		.enter	inherit	TocUpdateCategory
		
	; See if we're dealing with device drivers or just plain old
	; files. 

		test	ss:[flags],
				mask TUCF_EXTENDED_DEVICE_DRIVERS
		jnz	deviceDrivers
		
	; Not device drivers, so allocate a sorted name array as the
	; "files" array.  If the custom size flag is set, then use
	; that size
		
		test	ss:[flags], mask TUCF_CUSTOM_FILES
		mov	bx, size TocFileStruct
		jz	gotSize
		mov	bx, ss:[params]
		mov	bl, ss:[bx].TUCP_fileArrayElementSize
		clr	bh
		
gotSize:

	; Create a sorted name array in the TOC file for driver filenames.

		call	TocAllocSortedNameArray		; ax:di - files array
		jmp	addIt
		
deviceDrivers:
		
	; Create a sorted name array in the TOC file for devices.

		mov	bx, size TocDeviceStruct ; elements for device name
						; array. 
		call	TocAllocSortedNameArray
		movdw	ss:[categoryBuf].TCS_devices, axdi
		
	; Create a name array in the TOC file for the driver filenames.

		mov	bx, size TocFileStruct
		call	TocAllocNameArray
		
addIt:
	; ax:di - dbptr to files array

		movdw	ss:[categoryBuf].TCS_files, axdi
		
	; Add a new category to the array.
		
		call	TocLockCategoryArray	; *ds:si - categories array
		
		call	ChunkArrayAppend	; ds:di - new
						; TocCategoryStruct 
		
	; Copy the category data off the stack
		
		segmov	es, ds
		segmov	ds, ss
		lea	si, ss:[categoryBuf]
		mov	cx, size TocCategoryStruct
		rep	movsb
		
	; Unlock (using DBUnlock) since ES is the segment
		
		call	DBDirty
		call	DBUnlock
		
		.leave
		ret
TocCreateCategory	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocUpdateFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the file list for a category

CALLED BY:	TocUpdateCategory

PASS:		ss:bp (local frame) TocUpdateVars

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,es,ds 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TocUpdateFiles	proc near
		
		.enter	inherit	TocUpdateCategory
		
	; Search for the files, & store the enum buffer in our local
	; variable frame.  

	; Find all files that match our token characters.
		
		lea	bx, ss:[categoryBuf].TCS_tokenChars
		call	TocLocateFiles
		
	; Remember the returned file information.

		mov	ss:[fileEnumCount], cx
		mov	ss:[fileEnumBuffer], bx

	; Do we have extended device drivers?

		test	ss:[flags],
				mask TUCF_EXTENDED_DEVICE_DRIVERS
		jz	notDeviceDrivers

	; Update device drivers.

		call	TocUpdateDeviceDrivers
		jmp	freeBuffer

notDeviceDrivers:
		call	TocUpdateNormalFiles

freeBuffer:

	; Free the file information.

		mov	bx, ss:[fileEnumBuffer]
		tst	bx
		jz	done
		
		call	MemFree	
done:
		.leave
		ret
TocUpdateFiles	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocUpdateDeviceDrivers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the file update for device drivers

CALLED BY:	TocUpdateFiles

PASS:		es - segment of FileEnum buffer
		cx - number of files in array
		ss:bp - inherited local vars

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,ds

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocUpdateDeviceDrivers	proc near
		uses	bp
		.enter	inherit	TocUpdateCategory

		movdw	axdi, ss:[categoryBuf].TCS_files
		call	TocDBLock	; *ds:si - files array

	; Preserve chunk array handle for called routines

		mov	ss:[array], si

		jcxz	secondPass

		call	MemLock
		mov	es, ax
		clr	di		
		
	; Loop thru the files, adding them to our array if need be
		
startLoop:

	; The array is in *ds:si the whole time.  For each entry in
	; the FileEnum buffer, we see if that entry's in the array,
	; and if not, we add it.  If it is, then we check release
	; numbers, and if they don't match, we delete it, and re-add
	; it.  We store the release number data on the stack when
	; adding, because NameArrayAdd takes a pointer to the buffer.

		push	cx		; loop counter
		
	;		
	; es:di 	- filename
	; ss:dx 	- pointer to TocFileStruct
	; *ds:si 	- files array
	; cx 		- loop count
	;
		
	; See if the name's in the array.  Name is null-terminated,
	; and we don't want to fetch the data, so clear CX and DX
		
		clr	cx, dx
		call	NameArrayFind
		cmp	ax, CA_NULL_ELEMENT
		je	addNew
		
	; It's in the array, but it might be out of date, so...

		push	si
		push	di
		call	ChunkArrayElementToPtr
		lea	si, ds:[di].NAE_data
		pop	di

		mov_tr	dx, ax			; element #
		call	CheckReleaseNumber
		pop	si
		
		jnc	next
		
addNew:
		push	ds
		segmov	ds, ss
		lea	bx, ss:[fileBuf]
		call	StoreTocFileStructInfo
		pop	ds
		
		mov	dx, ss
		mov_tr	ax, bx			; dx:ax - TocFileStruct
		clr	bx, cx
		call	NameArrayAdd		; ax <- driver element # in
						; array 
		
	; Now, add all the devices to the device array (SortedNameArray)
		
		mov	ss:[deviceBuf].TDS_driver, ax
		call	TocProcessDriver
next:
		add	di, size TocFileReturnAttrs
		pop	cx
		loop	startLoop
		
secondPass:
	
	; Second pass -- for any files in the files array that AREN'T
	; in the current directory, and we don't have source disk
	; information for that file -- delete the element from the
	; files array.
	
		mov	bx, cs
		mov	di, offset TocRemoveExtraFilesCB
		clr	dx		; element number
		call	ChunkArrayEnum
		call	TocDBUnlock
		
		.leave
		ret
TocUpdateDeviceDrivers	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocUpdateNormalFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the non-device drivers list

CALLED BY:	TocUpdateFiles

PASS:		es:di  - first TocFileReturnAttrs struct to look at
		cx - number of files in array

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocUpdateNormalFiles	proc near
		uses	ax,bx,cx,dx,di,si
		.enter	inherit	TocUpdateCategory

		jcxz	secondPass

		call	MemLock
		mov	es, ax
		clr	ss:[enumPtr]
		
startLoop:


		push	cx		; loop counter
		
		segmov	ds, es
		mov	si, ss:[enumPtr]
		mov	di, {word} ss:[categoryBuf].TCS_files
		clr	bx, cx
		call	TocSortedNameArrayFind
		jnc	addNew

	; Check the release number of the array element with that in
	; the FileEnum buffer

		push	ax			; element #
		call	TocHugeArrayLock
		pop	dx			; element #

		mov	di, ss:[enumPtr]
		call	CheckReleaseNumber
		call	HugeArrayUnlock
		jnc	next
		
addNew:
	; Add it.  Before we call the callback, VMUpdate the thing to
	; disk, so that if GEOS crashes, the TOC file won't be corrupt.

		call	TocGetFileHandle
		call	VMUpdate
		
		mov	si, ss:[enumPtr]
		segmov	ds, es
		mov	di, {word} ss:[categoryBuf].TCS_files
		mov	bx, ss:[params]
		call	ss:[bx].TUCP_addCallback
		jc	next
		
	; ax - new element -- store release number and source disk
		
		call	TocHugeArrayLock
EC <		tst	ax					>
EC <		ERROR_Z INVALID_ELEMENT_NUMBER_RETURNED_BY_CALLBACK >
		mov	bx, si				; ds:bx - destination

		mov	di, ss:[enumPtr]
		call	StoreTocFileStructInfo

		call	TocHugeArrayUnlock
next:
		add	ss:[enumPtr], size TocFileReturnAttrs
		pop	cx
		loop	startLoop
		
secondPass:
	;
	; Second pass -- for any files in the files array that AREN'T
	; in the current directory, and we don't have source disk
	; information for that file -- delete the element from the
	; files array.
	;
		mov	di, {word} ss:[categoryBuf].TCS_files
		mov	bx, cs
		mov	ax, offset TocRemoveExtraFilesCB
		call	TocHugeArrayEnum

		.leave
		ret
TocUpdateNormalFiles	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocHugeArrayUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	unlock the current array element

CALLED BY:	TocUpdateFiles

PASS:		ds - segment of block to be unlocked

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocHugeArrayUnlock	proc near
		uses	bx
		.enter
		call	TocGetFileHandle
		call	HugeArrayUnlock
		.leave
		ret
TocHugeArrayUnlock	endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreTocFileStructInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the pertinent data into a TocFileStruct

CALLED BY:	TocUpdateFiles

PASS:		ds:bx - destination buffer
		es:di - source TocFileReturnAttrs

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreTocFileStructInfo	proc near
		uses	ax
		
		.enter
EC <		xchg	si, bx			>
EC <		call	ECCheckBounds		>
EC <		xchg	si, bx			>
ifndef	TOC_ONLY
EC <		call	ECCheckBoundsESDI	>
endif
		
		mov	ds:[bx].TFS_sourceDisk, DT_UNKNOWN
		
IRP var, <RN_major, RN_minor, RN_change>
		mov	ax, es:[di].TFRA_release.&var
		mov	ds:[bx].TFS_release.&var, ax
endm

		.leave
		ret
StoreTocFileStructInfo	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckReleaseNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the release number of the file in the array and
		see if it matches that of the one on disk.  If not,
		delete it from the array

CALLED BY:	TocUpdateFiles

PASS:		ds:si - TocFileStruct to look at
		es:di - TocFileReturnAttrs
		ss:bp - inherited local vars
		dx - element number of current element in array

RETURN:		carry SET if element deleted

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	XXX: Maybe we should only delete this element if the stored
	release number is OLDER than the file's 

	For now, is only used with device drivers, etc. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckReleaseNumber	proc near
		uses	ax,bx,cx,dx,di,si
		
		.enter	inherit	TocUpdateCategory
		
		
	;
	; Just compare the Major/Minor, and CHANGE numbers, as the
	; "Engineering" number changes too frequently.
	;
		
		lea	si, ds:[si].TFS_release
		lea	di, es:[di].TFRA_release
		mov	cx, (size RN_major + size RN_minor + size RN_change)/2
		repe	cmpsw
		je	done
		
		call	TocDeleteFileFromArray
		stc
		
done:
		.leave
		ret
CheckReleaseNumber	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocHugeArrayLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the TOC huge array element

CALLED BY:	TocUpdateFiles

PASS:		di - VM handle of array
		ax - element # to lock

RETURN:		ds:si - element 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 5/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocHugeArrayLock	proc near
		uses	bx,dx
		.enter
		call	TocGetFileHandle
		clr	dx
		call	HugeArrayLock		; ds:si - element
		.leave
		ret
TocHugeArrayLock	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocAddFileCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Standard routine to add a file to the SortedNameArray
		of files

CALLED BY:	TocUpdateFiles

PASS:		di - VM handle of SortedNameArray
		ds:si - name to add

RETURN:		ax - element number

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocAddFileCB	proc far
		
		uses	bx, cx
		
		.enter	inherit	TocUpdateCategory
		
	;
	; Add the new element, but don't store any data, as that's up
	; to the caller.
	;
		
		clr	bx, cx
		call	TocSortedNameArrayAdd
		
		clc				; signify that we added it
		.leave
		ret
TocAddFileCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocHugeArrayEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the huge array

CALLED BY:	TocUpdateFiles, TocRemoveExtraFilesCB

PASS:		di - VM handle of array
		ax - offset of callback routine in this segment

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
		Use AX as a counter to the current element

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 4/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocHugeArrayEnum	proc near
		uses	bx, di, ax, dx

		.enter
		call	TocGetFileHandle
		push	bx			; file handle
		push	di			; VM handle
		push	cs, ax			; callback

		clr	ax
		push	ax, ax			; first element
		dec	ax
		push	ax, ax			; do 'em all

		clr	dx			; element counter
		call	HugeArrayEnum

		.leave
		ret
TocHugeArrayEnum	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocRemoveExtraFilesCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to nuke a file from the TOC array if
		it's not in the current directory

CALLED BY:	TocUpdateFiles via ChunkArrayEnum (or HugeArrayEnum)

PASS:		ss:bp - inherited local vars
		ds:di - array element for current entry
		ax - size of current element

		dx - element number

		(*ds:si - chunk array, if called via ChunkArrayEnum)

RETURN:		dx - incremented

DESTROYED:	ax,bx,cx,si,di,es 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocRemoveExtraFilesCB	proc far
		
		.enter	inherit	TocUpdateCategory
		
		mov	ss:[curElement], di
	;
	; If this file is on a source disk somewhere, then scram
	;
		
		call	GetFileSourceDisk
		cmp	bx, DT_UNKNOWN
		jne	done
		
	;
	; Look for the file in the FileEnum buffer, if there is one.
	;
		
		call	GetFileName		; ds:si - current filename
						; ax - name length
		
		mov	cx, ss:[fileEnumCount]
		jcxz	notFound
		
		mov	bx, ss:[fileEnumBuffer]
		call	MemDerefES
		clr	di
		
	;
	; Go thru all the files in the FileEnum buffer until we find
	; this one. 
	;
		
startLoop:
	;
	; ds:si - name of array element
	; ax 	- string length
	; es:di - name of file on disk
	; cx 	- number of remaining files to look at
	;
		mov	bx, di
SBCS <		tst	<{char} es:[di]>				>
DBCS <		tst	<{wchar} es:[di]>				>
		jz	next
		
	;
	; To compare this filename, we compare (ax) bytes.  If they're
	; equal, then we make sure the next byte at es:di is null.
	;
		push	cx, si
		mov	cx, ax
SBCS <		repe	cmpsb						>
DBCS <		repe	cmpsw						>
		pop	cx, si
		
		jne	next
SBCS <		tst	<{char} es:[di]>				>
DBCS <		tst	<{wchar} es:[di]>				>
		jnz	next
		
	;
	; They're equal.  We'll never have to look at this file again,
	; so nuke its first byte.
	;
SBCS <		mov	{char} es:[bx], 0				>
DBCS <		mov	{wchar} es:[bx], 0				>
		jmp	done
next:
		mov	di, bx
		add	di, size TocFileReturnAttrs
		loop	startLoop
		
notFound:
		
	;
	; This file is no longer on the disk, so delete it from the
	; files array and the devices array
	;
		
		mov	di, ss:[curElement]
		call	TocDeleteFileFromArray

	;
	; If the thing being deleted is a device driver, then we DO
	; want to increment DX in all cases, because the array is an
	; element array, and elements don't actually get deleted, they
	; just get freed.  If the thing is NOT a device driver, then
	; we don't want to increment the element number, since the
	; element will actually have gotten deleted.
	;
		
		
		test	ss:[flags], mask TUCF_EXTENDED_DEVICE_DRIVERS
		jnz	done


	;
	; Decrement DX so that it continues to point to this element number
	;
		
		dec	dx
		
done:
		inc	dx		; element number
		clc
		.leave
		ret
TocRemoveExtraFilesCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocDeleteFileFromArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete this file from the array, and delete all
		devices that correspond to this file, if necessary

CALLED BY:	TocRemoveExtraFilesCB, CheckReleaseNumber

PASS:		dx - element number in array
		ds - segment of array, if ChunkArray

RETURN:		nothing 

DESTROYED:	ax,bx,cx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocDeleteFileFromArray	proc near

		uses	dx, si, ds
		
		.enter	inherit	TocUpdateCategory

		mov_tr	ax, dx		; current element #

		
		test	ss:[flags], mask TUCF_EXTENDED_DEVICE_DRIVERS
		jnz	deviceDrivers

		mov	di, {word} ss:[categoryBuf].TCS_files
		call	TocHugeArrayDelete
		jmp	done
		
	;
	; The device drivers case is more complicated, since we need
	; to remove the file, AND all devices that reference this file.
	;
		
deviceDrivers:
		mov	si, ss:[array]		
		call	ElementArrayDelete
		call	TocDBDirty
		
		mov_tr	cx, ax				; driver #
		
		mov	di, {word} ss:[categoryBuf].TCS_devices
		
	;
	; Remove all devices that point to this file.  We can't use
	; HugeArrayEnum, because it doesn't support deleting array
	; elements, so just enumerate the thing by hand.  This is
	; probably way slow, but what can I do?
	;
		
		clr	ax, dx			; element number
		call	TocGetFileHandle	; bx - file handle
deviceLoop:

		push	ax, cx, dx	; element #, driver #
		call	HugeArrayLock	; ds:si - next element
		tst	ax
		pop	ax, cx, dx	; element #, driver #
		
		jz	done
		

		cmp	ds:[si].TDS_driver, cx
		call	HugeArrayUnlock
		jne	next

		push	cx
		mov	cx, 1
		call	HugeArrayDelete
		pop	cx
		
		jmp	deviceLoop
next:
		inc	ax
		jmp	deviceLoop
		
done:
		.leave
		ret
TocDeleteFileFromArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocHugeArrayDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete this element from the array

CALLED BY:	TocDeleteFileFromArray

PASS:		di - VM handle of huge array
		ax - element number

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 4/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocHugeArrayDelete	proc near
		uses	bx, cx, dx
		.enter
		mov	cx, 1
		call	TocGetFileHandle
		clr	dx
		call	HugeArrayDelete

		.leave
		ret
TocHugeArrayDelete	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileSourceDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the SOURCE DISK number of the current element
		in the files array

CALLED BY:	TocRemoveExtraFilesCB

PASS:		ds:di - current element
		ss:bp - inherited local vars

RETURN:		bx - disk #

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	if TUCF_EXTENDED_DEVICE_DRIVERS is set, then we assume the
	array is a NAME ARRAY, and add the NAE_data offset.  
	OTHERWISE, we don't add this offset

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 7/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileSourceDisk	proc near
		uses	di
		.enter	inherit	TocUpdateCategory
		
		test	ss:[flags], mask TUCF_EXTENDED_DEVICE_DRIVERS
		jz	gotOffset
		add	di, offset NAE_data
		
gotOffset:
		mov	bx, ds:[di].TFS_sourceDisk
		.leave
		ret
GetFileSourceDisk	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the filename from the array element

CALLED BY:	TocRemoveExtraFilesCB

PASS:		ds:di - array element
		ax - size of array element
		ss:bp - inherited local vars

RETURN:		ds:si - filename
		ax- length of filename

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 7/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileName	proc near
		uses	cx, bx
		.enter	inherit	TocUpdateCategory

		test	ss:[flags], mask TUCF_EXTENDED_DEVICE_DRIVERS
		jz	notDrivers

	;
	; For device drivers, the array is a NameArray, so fetch the
	; data size, and add the NameArrayElement offset
	;
		
		mov	si, ds:[si]
		mov	cx, ds:[si].NAH_dataSize
		add	cx, offset NAE_data
		jmp	gotSize
notDrivers:
		push	di
		mov	di, {word} ss:[categoryBuf].TCS_files
		call	TocSortedNameArrayGetDataSize
		pop	di
gotSize:
		
		mov	si, di
		add	si, cx
		sub	ax, cx
DBCS <		shr	ax, 1		; # bytes -> # chars		>
DBCS <		ERROR_C	DBCS_ERROR					>
		
		.leave
		ret
GetFileName	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TocLocateFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the drivers with the given token.

CALLED BY:	TocUpdateFiles

PASS:		ss:bx - pointer to token chars
		if BX = 0, then don't use token chars

RETURN:		bx 	= handle of buffer created by FileEnum -- MUST
		BE FREED by caller.

		cx	= number of matches found
	
DESTROYED:	ax,dx,si,di

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 2/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocFileReturnAttrs	struct
	TFRA_name	FileLongName
	TFRA_release	ReleaseNumber
TocFileReturnAttrs	ends

returnAttrs	FileExtAttrDesc	\
	<FEA_NAME, offset TFRA_name, size TFRA_name>,
	<FEA_RELEASE, offset TFRA_release, size TFRA_release>,
	<FEA_END_OF_LIST>

TocLocateFiles proc	near
		
		
	; DON'T add a USES directive to this procedure, and don't
	; rearrange the order of the local variables.  
		
lastAttr	local	FileExtAttrDesc
tokenAttr	local	FileExtAttrDesc
enumParams	local	FileEnumParams
		
		.enter
		
		tst	bx
		jz	dontUseTokenChars
		
	; Initialize the attribute description
		
		mov	tokenAttr.FEAD_attr, FEA_TOKEN
		mov	tokenAttr.FEAD_value.segment, ss
		mov	tokenAttr.FEAD_value.offset, bx
		
	; Only compare TOKEN_CHARS_LENGTH chars
		
		mov	tokenAttr.FEAD_size, TOKEN_CHARS_LENGTH
		
	; Set last attribute
		
		mov	lastAttr.FEAD_attr, FEA_END_OF_LIST
		
	; Search for GEOS files that have the specified token
		
		mov	enumParams.FEP_matchAttrs.segment, ss
		lea	ax, tokenAttr
		mov	enumParams.FEP_matchAttrs.offset, ax
		jmp	afterToken
		
		
dontUseTokenChars:
		clrdw	ss:[enumParams].FEP_matchAttrs
		
afterToken:
		
		mov	enumParams.FEP_searchFlags, mask FESF_GEOS_EXECS or \
			mask FESF_GEOS_NON_EXECS

if	_FXIP

;	Copy returnAttrs to the stack, so they don't get mapped out when
;	calling FileEnum on an XIP system

		push	ds, si, cx
		segmov	ds, cs
		mov	si, offset returnAttrs
		mov	cx, size returnAttrs
		call	SysCopyToStackDSSI
		movdw	enumParams.FEP_returnAttrs, dssi
		pop	ds, si, cx
else
		mov	enumParams.FEP_returnAttrs.segment, cs
		mov	enumParams.FEP_returnAttrs.offset, offset returnAttrs
endif
		mov	enumParams.FEP_returnSize, size TocFileReturnAttrs
		mov	enumParams.FEP_bufSize, FE_BUFSIZE_UNLIMITED
		mov	enumParams.FEP_skipCount, 0
		
	; Seek and maybe ye shall find.
		
		call	FileEnum
if	_FXIP
		call	SysRemoveFromStack
endif
		
		.leave
		ret
TocLocateFiles endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TocProcessDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go through the device list for this driver, adding
		each name to the devices array.

CALLED BY:	TocLocateFiles

PASS:		es:di - filename
		ss:bp - (local) TocUpdateVars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	add all the devices for this driver to the device array.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 7/92   	copied from PrefProcessDriver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocProcessDriver	proc near
		uses ax,bx,cx,dx,si,di,es,ds
		
		.enter	inherit TocUpdateCategory
		
	; Nuke cached data (if dealing with printers)
		
		mov	ss:[printerInfo], -1
		
		segmov	ds, es
		mov	dx, di
		mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
		call	FileOpen
		jc	done
		
		mov	ss:[fileHandle], ax
		
		call	TocLoadExtendedInfo
		jc	done
		push	bx
		
		mov	ss:[driverType], ax
		
	; bx - handle of extended info segment
		
deviceLoop:
	;
	; ds:si - name table
	; ds:dx - info table
		
		lodsw			; *ds:ax - device string
		mov_tr	di, ax		;*ds:di <- device string
		xchg	si, dx		;si <- infoTable, dx <- nameTable
		lodsw			; ax - info word
		push	si, cx, dx	; info table, loop count, name table
		mov	si, ds:[di]	;ds:si <- device string
		
	; Initialize the TocDeviceStruct
		
		cmp	ss:[driverType], DRIVER_TYPE_PRINTER
		jne	storeInfo
		push	bx
		mov	bx, ss:[fileHandle]
		call	TocMapPrinterInfo
		pop	bx
		
storeInfo:
	
	; Add this device to the array.  If it's already there, then
	; set the data, as it may have changed (?)
		
		mov	ss:[deviceBuf].TDS_info, ax
		mov	di, {word} ss:[categoryBuf].TCS_devices
		mov	cx, ss
		lea	dx, ss:[deviceBuf]
		mov	bx, mask NAAF_SET_DATA_ON_REPLACE
		call	TocSortedNameArrayAdd
		
		pop	si, cx, dx	; info table, loop count, name table
		xchg	si, dx		; si <- nameTable, dx <- infoTable
		loop	deviceLoop
		
	; All devices entered. Free the info block.
		
		pop	bx
		call	MemFree
		
		mov	bx, ss:[fileHandle]
		clr	al		; pretend we'll handle any errors
		call	FileClose
done:
		
		.leave
		ret
TocProcessDriver	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TocLoadExtendedInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the DriverExtendedInfoTable block for the driver,
		if it exists.

CALLED BY:	TocProcessDriver

PASS:		ax	= file handle of the driver

RETURN:		carry set if driver doesn't contain valid extended-driver
		info

		carry clear if driver is ok:
		ds	= segment of locked DriverExtendedInfoTable
		ax	= DriverType for the driver
		bx	= handle of locked DriverExtendedInfoTable
		cx	= number of devices
		dx	= offset of info table in ds
		si	= offset of name table in ds

DESTROYED:	es 

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocLoadExtendedInfo	proc	near
		
driverTab	local	fptr
driverInfo	local	DriverExtendedInfoStruct
		
		.enter
		
		mov	bx, ax
	
	; Find the DriverExtendedInfoStruct and read in the resource ID
	; of the extended info table
	
		clr	cx
		mov	dx, offset GFH_coreBlock.GH_driverTabOff
		mov	al, FILE_POS_START
		call	FilePos
		push	ds
		segmov	ds, ss
		lea	dx, ss:[driverTab]
		mov	cx, size driverTab
		clr	al
		call	FileRead
		jc	popDSErrorCloseFile
		
		mov	dx, ss:[driverTab].offset
		mov	cx, ss:[driverTab].segment
		call	GeodeFindResource
		jc	popDSErrorCloseFile
		
		lea	dx, ss:[driverInfo]
		mov	cx, size driverInfo
		clr	al
		call	FileRead
popDSErrorCloseFile:
		pop	ds
		jc 	errorCloseFile
		test	ss:[driverInfo].DEIS_common.DIS_driverAttributes,
		mask DA_HAS_EXTENDED_INFO
		jz	errorCloseFile
	
	; Locate the extended resource in the file, then allocate a block
	; big enough to hold the whole thing.
	
		mov	cx, ss:[driverInfo].DEIS_resource
		clr	dx

		call	GeodeSnatchResource
		mov	ds, ax

	; Load device descriptor info for caller.
		
		mov	cx, ds:[DEIT_numDevices]
		mov	si, ds:[DEIT_nameTable]
		mov	dx, ds:[DEIT_infoTable]

exit:
		mov	ax, ss:[driverInfo].DEIS_common.DIS_driverType
		.leave
		ret

errorCloseFile:
		clr	al
		call	FileClose
		stc
		jmp	exit
TocLoadExtendedInfo	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TocMapPrinterInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map the word of info stored in the printer driver's table
		into something we can use -- the PrinterConnections record
		for the device.

CALLED BY:	TocProcessDriver

PASS:
		ax	= resource # of info from the printer driver's table
   		bx	= file handle of driver

RETURN:		ax	= PrinterConnections word

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocMapPrinterInfo proc	near	uses dx, cx, ds
		.enter	inherit	TocUpdateCategory
		
	;
	; See if the last info resource loaded was the same as this one.
	; If so, we can just use the cached value
	;
		
		cmp	ss:[printerInfo], ax
		je	loadFromCache
		mov	ss:[printerInfo], ax
		
	;
	; Seek to PI_connect field of PrinterInfo for the device
	;
		
		mov_tr	cx, ax			
		mov	dx, offset PI_connect
		call	GeodeFindResource
		
		segmov	ds, ss
		lea	dx, ss:[printerConn]	; buffer => DS:DX
		mov	cx, size printerConn
		clr	al
		call	FileRead
		
loadFromCache:
		mov	al, ss:[printerConn]
		clr	ah
		
		.leave
		ret
TocMapPrinterInfo endp



