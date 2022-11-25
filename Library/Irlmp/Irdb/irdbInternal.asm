COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved
	Geoworks Confidential

PROJECT:	GEOS
MODULE:		Irlmp
FILE:		irdbInternal.asm

AUTHOR:		Andy Chiu, Jan 11, 1996

ROUTINES:
	Name			Description
	----			-----------
	IIInitializeDatabaseFile
	IIGetObjArrayFileBlockAndChunkHandles
	IIAddAttributeToAttributeArray
	IIAddAttributeName
	IIAddStringOrSequenceData
	IICreateVMChunkArray
	IIReadIniFile
	IIReadIniObject
	IIReadAttribute
	IIReadAttributeData
	IIGetNewObjectID
	IIIrdbFileSetExtAttrs
	IIOpenDatabaseFile
	IICheckDatabaseFileProtocol
	IIDeleteDatabaseFile


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/11/96   	Initial revision


DESCRIPTION:
	Work to handle the calls to the object database

	$Id: irdbInternal.asm,v 1.1 97/04/05 01:08:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrdbCode	segment

;
; These need to be single byte strings in both dbcs and sbcs
;
irdbIniCategory		char	"IRDB", 0 
irdbIniObjectKey	char	"Objects", 0 
irdbIniClassNameKey	char	"ClassName", 0 
irdbIniAttributesKey	char	"Attributes",0 
irdbIniPermanentKey	char	"Permanent",0 
irdbIniAttrTypeSuffix	char	"_type",0 
irdbIniAttrDataSuffix	char	"_data",0 
if DBCS_PCGEOS
;
; The name was too long for DBCS.
;
LocalDefNLString	irdbDatabaseFileName	<"IR Object Db",C_NULL>
else
LocalDefNLString	irdbDatabaseFileName	<"IR Object Database",C_NULL>
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIInitializeDatabaseFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the database file.

CALLED BY:	(INTERNAL) IRDBOPENDATABASE
PASS:		bx	= file handle of database
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIInitializeDatabaseFile	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter

		Assert	vmFileHandle	bx
	;
	; Initialize the file.  Set the extended attributes.
	;
		call	IIIrdbFileSetExtAttrs
	;
	; Create the map block. 
	;
		clr	ax			; no user id
		mov	cx, size IrdbFileMapBlock
		call	VMAlloc			; ax <- map block
		mov	di, ax			; di <- map block handle

	;
	; Create the chunk array to live inside this file.
	;
		clr	dx			; var size elements
		call	IICreateVMChunkArray	; *ds:si <- chunk array
						; ax <- VMBlock Handle
						; bp <- mem handle
	;
	; We don't need the block anymore so unlock it.
	; If we couldn't create the chunk array, then destory this
	; map block.
	;
		jc	destroyMapBlock
		call	IUUnlockBlockAndUpdateFile
	;
	;  Save the chunk array in the map block
	;
		mov_tr	dx, ax			; dx <- chunk array vm
						;        block handle

		mov	ax, di			; Map block handle
		call	VMLock			; ax <- segment
						; bp <- mem handle

		mov_tr	ds, ax
		mov	ds:[IFMB_objArrayVMBlockHandle], dx
		mov	ds:[IFMB_objArrayChunkHandle], si
	;
	; Set the map block to the file
	;
		mov_tr	ax, di			; ax <- map block
		call	VMSetMapBlock

	;
	; Dirty and unlock the block
	;
		call	IUUnlockBlockAndUpdateFile
	;
	; Read the default values from the ini file.
	;
		call	IIReadIniFile
		
		clc
exit:
		.leave
		ret
	;
	; Error creating chunk array so destroy the map block
	;
destroyMapBlock:
		mov_tr	ax, di			; ax <- VMBlock
		call	VMFree
		stc
		jmp	exit

IIInitializeDatabaseFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIGetObjArrayFileBlockAndChunkHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the object array block and chunk handle.

CALLED BY:	(INTERNAL) IrdbAddAttributeLow, IrdbCreateEntryLow,
		IrdbDeleteEntry
PASS:		nothing
RETURN:		bx	= File handle
		ax	= VMBlock handle of object array
		si	= Chunk array handle of object array
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIGetObjArrayFileBlockAndChunkHandles	proc	near
		uses	dx,bp,ds,es
		.enter

	;
	; Get the map block from the file.
	;
		call	UtilsLoadDGroupES
		mov	bx, es:[irdbFileHandle]
		call	VMGetMapBlock		; ax <- map block handle
	;
	; Lock the map block down and get the chunk array.
	;
		call	VMLock			; ax <- segment
						; bp <- mem handle
		mov_tr	ds, ax
		mov	si, ds:[IFMB_objArrayChunkHandle] 
		mov	ax, ds:[IFMB_objArrayVMBlockHandle]
	;
	; Unlock the map block and get the chunk array.
	;
		call	VMUnlock

		.leave
		ret
IIGetObjArrayFileBlockAndChunkHandles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIAddAttributeToAttributeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an element to the attribute array

CALLED BY:	(INTERNAL) IrdbAddAttributeLow
PASS:		ds:di	= Element in the object array (IrdbObjArrayEntry)

		on stack in pascal convention.  These are the paramters
		passed to IrdbAddAttribute

		ds:si	= attributeName
		cxdxax	= data passed to IrdbAddAttribute
		di	= IrlmpIasValueType

RETURN:		carry set if error
		cx	= attribute count
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIAddAttributeToAttributeArray	proc	near	attributeType:word,
						attributeDataAX:word,
						attributeDataDX:word,
						attributeDataCX:word,
						attributeLength:word,
						attributeName:fptr

		uses	ax,bx,dx,si,di,bp,ds,es
		.enter

		ForceRef	attributeName
		ForceRef	attributeLength
		
		Assert	fptr		dsdi
	;
	; Get the attribute array. Create one if necessary.
	;
		push	bp				; save for locals
		segmov	es, ds				; es:di <- object info
		call	IUGetAttributeArray
			; ax = vm block handle
			; si = chunk handle
			; *ds:si = Attribute array
			; bp = mem handle for locked VMBlock
	;
	; Add the attribute name to the attribute block
	;
		pop	bp			; restore for locals
		call	IIAddAttributeName	; ax <- lptr to the name
						; cx <- name size
		mov	dx, ax			; dx <- lptr to attr name
		mov	bx, cx
		jc	error
	;
	; If the info is a user string or an octet sequence, allocate
	; a chunk and write the data in there.  The routine will
	; do nothing if the attribute data is IIVT_MISSING or IIVT_INTEGER
	;
		mov	cx, ss:[attributeType]
		cmp	cl, IIVT_MISSING
		jz	writeData
		cmp	cl, IIVT_INTEGER
		jz	writeData

		call	IIAddStringOrSequenceData ; ax <- lptr to attribute
						  ; cx <- size of data copied
		jc	errorDestroyAttrName
	;
	; Now write the information into the attribute chunk array
	; When we get here, we assume:
	; dx <- lptr to attribute name
	; bx <- size of attribute name
	; ax <- lptr to user string or octect sequence
	; cx <- size of data copied
	;
writeData:
		call	ChunkArrayAppend	; ds:di <- new element
		jc	error

		mov	ds:[di].IAAE_attrNameSize, bl
		mov	ds:[di].IAAE_attrName, dx
		mov	bx, ss:attributeType
		mov	ds:[di].IAAE_attrType, bl

		shl	bx, 1				; attribute enum
		call	cs:writeAttributeTable[bx]	; dx <- trashed
	;
	; Unlock the block with the attributes.
	;
		push	bp			; save for locals
		mov	bp, ds:[LMBH_handle]	; bp <- mem handle
		call	IUUnlockBlockAndUpdateFile
		pop	bp			; bp <- local vars
		
		clc
done:
		.leave
		ret

	;
	; Error appending an element to the attribute array.
	; First destory the attribute name that we previously wrote.
	;
errorDestroyAttrName:
		mov_tr	ax, cx			; ax <- lptr to attr name
		call	LMemFree
	;
	; Unable to write data.  Unlock the block and be done with it.
	;
error:
		call	VMUnlock
		mov	bp, dx			; bp <- local vars
		stc
		jmp	done


	;---------------------------------------------------
	; Write the data into the attribute array
	; Assumes ds:di <- new element in object array.
	; Assumes ax <- vm chunk of data if octet seq or user string
	;---------------------------------------------------

	;
	; Write the integer data.  We are going to store it in
	; network order so it's easier to write out later.
	;
writeInteger:
		mov	dx, ss:attributeDataDX
		xchg	dl, dh
		mov	ax, ss:attributeDataAX
		xchg	al, ah
		movdw	ds:[di].IAAE_attrData.AD_integer, axdx
		ret
	;
	; Write the octet sequence
	;
writeOctSeq:
		mov	ds:[di].IAAE_attrData.AD_octetSequence.OSD_data, ax
		mov	ds:[di].IAAE_attrData.AD_octetSequence.OSD_size, cx
		ret
	;
	; Write the user string.  We need to remember the char set so
	; we get that from attributeDataCX.  But since the size
	; passed may have been 0, we use cl which is the size of
	; data copied
	;
writeUsrStr:
		mov	ds:[di].IAAE_attrData.AD_userString.USD_data, ax
		mov	ax, ss:attributeDataCX
		mov	ds:[di].IAAE_attrData.AD_userString.USD_charSet, ah
		mov	ds:[di].IAAE_attrData.AD_userString.USD_size, cl
	;
	; Write nothing for missing
	;
writeMissing:
		ret
		
		
writeAttributeTable	nptr	\
	writeMissing,
	writeInteger,
	writeOctSeq,
	writeUsrStr

IIAddAttributeToAttributeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIAddAttributeName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the name into the attribute VM Block

CALLED BY:	(INTERNAL) IIAddAttributeToAttributeArray
PASS:		ds	= segment of attribute data block
		inherit IrdbAddAttribute local variables
RETURN:		carry set if error
		ax	= lptr to attribute name
		cx	= size of attribute name (without null)
DESTROYED:	nothing (ds may have changed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIAddAttributeName	proc	near
		uses	bx,dx,si,di,bp,es
		.enter inherit IIAddAttributeToAttributeArray

	;
	; Find out how big the string is so we can write it.
	;
		mov	cx, ss:attributeLength		; cx <- string size
		tst	cx
		jnz	allocChunk
		
		les	di, ss:attributeName
		SBStringLength			; cx <- string size
	;
	; Create a chunk big enough to hold the attribute name
	;
allocChunk:
		clr	ax			; no flags
		call	LMemAlloc		; ax = handle of chunk
						; ds may of changed
		jc	done
	;
	; Get a ptr to the destination buffer and src buffer
	;
		movdw	esdi, dsax		; *es:di  <- dest
		lds	si, ss:attributeName
		mov	di, es:[di]		; es:di <- dest
	;
	; Copy the data attribute name to the chunk
	;
		push	cx
		rep	movsb			; data written
		pop	cx

		segmov	ds, es
		
		clc
done:
		.leave
		ret
IIAddAttributeName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIAddStringOrSequenceData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a string or octet sequence to the a locked vm block

CALLED BY:	(INTERNAL) IIAddAttributeToAttributeArray
PASS:		cx 	= IrdbAttributeType
		ds 	= segment of block to put data

RETURN:		ax	= VMChunk of data
		cx	= size of copied data
		(ds may have changed)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIAddStringOrSequenceData	proc	near
		uses	si,di,es
		.enter	inherit IIAddAttributeToAttributeArray

		Assert	etype	cx, IrlmpIasValueType

		cmp	cx, IIVT_USER_STRING
		jz	addUsrStr		; ax <- lptr to user string

EC <		cmp	cx, IIVT_OCTET_SEQUENCE				>
EC <		ERROR_NZ IRDB_INVALID_ATTRIBUTE_TYPE			>

	;--------------------------------------------------
	; Add a string of info into the vm block for
	; octet sequence and user string
	;--------------------------------------------------
		
	;
	; Write the octet sequence to the array
	; 
		mov	cx, ss:attributeDataCX
		jmp	short	addCopyData
	;
	; Write the user string.  If the string is null terminated,
	; then we have to figure out the size
	;
addUsrStr:
		mov	cx, ss:attributeDataCX
		clr	ch
		tst	cx
		jnz	addCopyData

		mov	es, ss:attributeDataDX
		mov	di, ss:attributeDataAX
		SBStringLength			; cx <- string size
	;
	; allocate memory for the string data and copy the data to it.
	;
addCopyData:
		call	LMemAlloc		; ax = handle of chunk
						; ds may of changed
		jc	error

	;
	; Get a ptr to the destination buffer
	;
		segmov	es, ds
		mov	di, ax
		mov	di, es:[di]		; es:di <- dest.
	;
	; Get a ptr to the src buffer
	;
		mov	ds, ss:attributeDataDX
		mov	si, ss:attributeDataAX	; ds:si <- src
	;
	; Copy the data from the src string to the destination
	;
		push	cx
		rep	movsb
		pop	cx
	;
	; Make sure ds is pointing to the right segment.
	; That is the Attribute Data block
	;
		segmov	ds, es
		
		clc
done:		
		.leave
		ret

error:
		stc
		jmp	done
IIAddStringOrSequenceData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IICreateVMChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a LMem block and chunk array inside of a VMFile

CALLED BY:	(INTERNAL) IIInitializeDatabaseFile, IUGetAttributeArray
PASS:		bx	= file handle
		dx	= size of chunk array element (0 for variable)
RETURN:		if carry clear:
			ax	= VMBlockHandle
			si	= Chunk array handle
			ds	= segment of VMBLock (locked)
			bp 	= Mem handle
		
DESTROYED:	nothing (ax, si on error)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IICreateVMChunkArray	proc	near
		uses	bx,cx,dx,di
		.enter


		Assert	vmFileHandle	bx
	;
	; Create our lmem block that will store the chunk array.
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx
		call	VMAllocLMem		; ax <- VMBlock handle
		mov	di, ax			; di <- VMBlock handle
	;
	; Lock the block and create a chunk array inside the block
	;
		call	VMLock			; ax <- segment
						; bp <- mem handle
		mov_tr	ds, ax
		clr	ax, cx, si		; no Obj flags
						; default header size
						; allocate handle
		mov_tr	bx, dx			; size of element
		

		call	ChunkArrayCreate	; *ds:si <- array
						; carry flag set if error

		mov_tr	ax, di			; ax <- VMBloch handle 
		jc	unlockBlockAndDestroy

		call	VMDirty
exit:
		.leave
		ret
	;
	; Couldn't alloc a chunk array, so destroy the block
	;
unlockBlockAndDestroy:
		call	VMUnlock
		mov	ax, di			; ax <- VMBlock handle
		call	VMFree
		call	VMUpdate
		jmp	exit

IICreateVMChunkArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIReadIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When initializing the database, we want to read
		the ini file so that we can initialize the database
		with the things that will ship with the device.

CALLED BY:	(INTERNAL) IIInitializeDatabaseFile
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Read the ini file for the list of objects.
	- For each object, read the attributes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIReadIniFile	proc	near
objectName	local		IRDB_INI_OBJECT_NAME_MAX_LENGTH	dup(TCHAR)
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter

	;
	; Loop through all the object names in the ini file.
	; AX will be the counter. 
	;
		clr	ax			; start with first string

	;
	; Read the ini file for the objects.  Puts the object name in
	; the object name local variable
	;
readObjectName:
		mov	cx, cs
		mov	dx, offset irdbIniObjectKey	; cx:dx <- key
		mov	ds, cx
		mov	si, offset irdbIniCategory	; ds:si <- category
		segmov	es, ss
		lea	di, objectName			; es:di <- buffer
		push	bp				; save for locals
		mov	bp, IRDB_INI_OBJECT_NAME_MAX_LENGTH ; buffer size
		call	InitFileReadStringSection
		pop	bp				; restore for locals
		jc	done

	;
	; Read the other info about the object in the database
	;
		call	IIReadIniObject

	;
	; Read the next object.
	;
		inc	ax
		jmp	readObjectName

		
done:
		.leave
		ret
IIReadIniFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIReadIniObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the info about an object from the ini file

CALLED BY:	(INTERNAL) IIReadIniFile
PASS:		es:di	= Object name
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Given the object name:
		- Find the class name and create an entry for that class name
		- Find out the list attributes for the name
		- Add the attributes to the database

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIReadIniObject	proc	near

objectName	local	fptr			push	es, di

	;
	; This buffer is used for two purposes.  First it'll put the
	; class name in here. Then it'll put the attribute name.
attrName	local	(IRDB_ATTRIBUTE_AND_CLASS_NAME_MAX_LENGTH + IRDB_ATTRIBUTE_INI_SUFFIX_MAX_LENGTH + 1)	dup(char)
attrNameSize	local	byte

objectID	local	word
		
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter

	;
	; Read the class name and add the entry to the database.
	;
		movdw	dssi, esdi			; ds:si <- new category
		mov	cx, cs
		mov	dx, offset irdbIniClassNameKey	; cx:dx <- key
		segmov	es, ss
		lea	di, ss:attrName			; es:di <- buffer to
							; put name
		push	bp				; #1 save for locals
		mov	bp, IRDB_ATTRIBUTE_AND_CLASS_NAME_MAX_LENGTH
		call	InitFileReadString		; cx <- number of bytes
		pop	bp				; #1 save for locals
		jc	done
	;
	; Read to see if if this is a permanent entry
	;
		mov	cx, cs
		mov	dx, offset irdbIniPermanentKey
		clr	ax			; ax <- false
		call	InitFileReadBoolean

		tst	ax
		jz	createEntry
	;
	; Write in the entry flags
	;
		mov	al, mask ICEF_PERMANENT
	;
	; Create the entry for the database.  Call IrdbCreateEntryLow
	; to bypass the library semaphore.
	;
createEntry:
		clr	cx			; null terminated
		segmov	ds, ss	
		mov	si, di			; ds:si <- classname
		clr	dx
		call	IrdbCreateEntryLow	; ax <- object id
	;
	; If there was an error trying to create the entry then
	; exit.
	;
		jc	done

		mov	ss:objectID, ax
	;
	; Now try to read all the attributes for that object.  Use the 
	; buffer that we used for class name to store the attribute name.
	;
		movdw	dssi, ss:objectName		; ds:si <- category
		mov	dx, offset irdbIniAttributesKey	
	;
	; Loop through the name of the attributes.  Use es:di as the buffer
	; to write the attribute name.  That's where we kept the classname
	; before.
	;
		
		clr	ax
attributeLoop:
		mov	cx, cs				; cx:dx <- Key
		push	bp				; #2 for locals
		Assert	fptr	esdi
		mov	bp, IRDB_ATTRIBUTE_AND_CLASS_NAME_MAX_LENGTH
		call	InitFileReadStringSection	; cx <- length
		pop	bp				; #2 for locals
		jc	done
		mov	ss:attrNameSize, cl
		inc	ax

		call	IIReadAttribute
		jnc	attributeLoop

done:
		.leave
		ret
IIReadIniObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIReadAttribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the attribute name and object name,
		read from the ini file, the data about the attribute.

CALLED BY:	IIReadIniObject
PASS:		ds:si	= object name
		es:di	= attribute name
		cx	= length of attribute name
		bp	= local stack frame of IIReadIniObject

RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	- Given the attribute name, add a new suffix of _type
	  and read it's type.
	- Add the data suffix and read the data.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIReadAttribute	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,si,es
		.enter inherit	IIReadIniObject
	;
	; Append the type suffix to the attribute name.  Append it
	;
		mov	si, offset irdbIniAttrTypeSuffix
		mov	bx, cx			; save attribute size
		call	addSuffixAndSetupIniRead; ds:si = object name
						; cx:dx  = attribute type name
	;
	; Now read in the attribute type of the object.
	;
		call	InitFileReadInteger	; ax <- value
		jc	done
		Assert	etype	ax, IrlmpIasValueType
	;
	; Append the data suffix to the type.  setup call for init file read
	;
		mov	cx, bx			; attribute size
		mov	si, offset irdbIniAttrDataSuffix
		call	addSuffixAndSetupIniRead; ds:si = object name
						; cx:dx  = attribute data name
	;
	; Depending on the type of info, we want to do a different kind
	; of read.
	;
		call	IIReadAttributeData
done:
		.leave
		ret

	;
	; Add a suffix for the attribute.   Setup the parameters for an
	; ini file read.  ds:si = object name, cx:dx = attribute info
	;
addSuffixAndSetupIniRead:
		segmov	ds, cs
		push	di
		add	di, cx			; es:di <- end of attr string
		push	ax
;
;		This needs to be the same for both sbcs and dbcs so we
;		can not use LocalCopyString
;
charLoop:
		lodsb				; 1 / 12
		stosb				; 1 / 11
		tst	al			; 2 /  3
		jnz	charLoop		; 2 / 16

		pop	ax
		pop	di			; es:di <- attr_type string

		movdw	dssi, ss:objectName
		movdw	cxdx, esdi
		ret		
		
IIReadAttribute	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIReadAttributeData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For the attribute data, we're going to have to read it
		from the ini file as data.  Then we'll interpret it as we
		see fit. 
CALLED BY:	(INTERNAL) IIReadAttribute
PASS:		ds:si	= object name
		ax	= attribute type
		bx	= object id
RETURN:		carry set if error
		Attribute added to the ini file.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	- Depending on what type of data it is we have
	  read it differently from the ini file.

	- Integers and octet sequences are read as data.

	- User strings are read as strings.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIReadAttributeData	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter inherit IIReadAttribute

		Assert	fptr	dssi
		Assert	etype	ax, IrlmpIasValueType
	;
	; Jump to the appropiate handler.  Pass cx as the number of bytes
	;
		mov_tr	di, ax
		shl	di, 1			; use for jump table
		jmp	cs:readDataTable.[di]
	;
	; The data should be only two words.  Read the first two words
	; of data and use that as the integer.  IF the size of the
	; data is not the size of a 32 bit integer, then ignore it.
	;
integer:
		push	bp		
		clr	bp
		call	InitFileReadData	; bx <- mem handle
						; cx <- number of bytes
		pop	bp
		jc	done

		call	lockBlock		; es:di <- data

		cmp	cx, size (dword)
EC <		WARNING_NZ IRDB_WARNING_INVALID_INTEGER_FROM_INI_FILE	>
		stc				; set incase it jumps
		jnz	destroyBlock

	;
	; The digits were read in network order.  Reverse them
	; so we get the value. DX will be the high word.  AX will
	; be the low word
	;
		movdw	axdx, es:[di]
		xchg	dl, dh
		xchg	al, ah
		mov	di, IIVT_INTEGER
		jmp	addAttr
	;
	; We've read in an octet sequence.  Pass the info and the size
	; into the AddAttr routine
	;
octSeq:
		push	bp
		clr	bp
		call	InitFileReadData	; bx <- mem handle
						; cx <- number of bytes
		pop	bp
		jc	done

		call	lockBlock		; es:di <- data

		movdw	dxax, esdi
		mov	di, IIVT_OCTET_SEQUENCE
		jmp	addAttr
	;
	; We've read a string of data. Pass that string as an attribute.
	;
usrString:
		push	bp
		clr	bp
		call	InitFileReadString	; bx <- mem handle
						; cx <- number of bytes
		pop	bp
		jc	done

		call	lockBlock		; es:di <- data
		movdw	dxax, esdi

	; !* Might not always be ascii.
		clr	ch			; say it's ascii for now.
		mov	di, IIVT_USER_STRING		
	;
	; If the attribute is of type IIVT_MISSING, then just write that
	; to the attribute data.
	;
missing:
addAttr:
		push	bx, bp			; save mem handle
						; save local vars

		segmov	ds, ss
		lea	si, ss:attrName
		clr	bx
		mov	bl, ss:attrNameSize
		mov	bp, ss:objectID
		xchg	bx, bp
		call	IrdbAddAttributeLow	; restore mem handle

		pop	bx, bp			; bx <- mem handle
						; bp <- local vars
	;
	;  Destory the block of data created by the ini stuff.
	;
destroyBlock:
		pushf	
		call	MemFree
		popf
done:		
		.leave
		ret
	;
	; Common code to lock the block of data and setup es:di to
	; point to the data.  Not handling error here since
	; reading from the ini file shouldn't have a data so big
	; that we don't have room for it.
	;
lockBlock:
		call	MemLock
		mov_tr	es, ax
		clr	di
		ret
		
readDataTable	nptr	\
	missing,		; IIVT_MISSING * 2
	integer,		; IIVT_INTEGER * 2
	octSeq,			; IIVT_OCTET_SEQUENCE * 2
	usrString		; IIVT__USER_STRING * 2
		
IIReadAttributeData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIGetNewObjectID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new object ID.

CALLED BY:	(INTERNAL) IrdbCreateEntryLow
PASS:		*ds:si 	= Object array
RETURN:		ax	= Object ID
DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Get the last element in the chunk array.
	- That number is guarenteed to be the biggest so we just
	  increment from that one.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIGetNewObjectID	proc	near
		uses	cx, di
		.enter

	;
	; Find out how many elements are in the object array.
	; If there are zero elements, then return 0.
	;
		call	ChunkArrayGetCount	; cx <- count
		mov	ax, cx
		jcxz	exit

	;
	; Get the last element in the chunk array and see what
	; it's object ID is.
	;
		call	ChunkArrayElementToPtr

		mov	ax, ds:[di].IOAE_objectID
	;
	; Increment that object ID and that's what we will use
	;
		inc	ax

exit:

		.leave
		ret
IIGetNewObjectID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIIrdbFileSetExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure extended attributes are set correctly
		for the ias database file

CALLED BY:	(INTERNAL) IIInitializeDatabaseFile
PASS:		bx	= file handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrdbFileExtAttrs	struc
	IFEA_fToken		GeodeToken
	IFEA_fProtocol		ProtocolNumber
	IFEA_fFlags		GeosFileHeaderFlags
IrdbFileExtAttrs	ends

irdbAttrs	IrdbFileExtAttrs <
	<<IRDB_FILE_TOKEN>, MANUFACTURER_ID_GEOWORKS >,
 	< IRDB_FILE_MAJOR_PROTOCOL, IRDB_FILE_MINOR_PROTOCOL >,
	< 0 > >

IIIrdbFileSetExtAttrs	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter

		Assert	vmFileHandle	bx
	;
	; For XIP, make copy all the stuff to the values to the
	; stack, since we'll need to pass a fptr to those variables.
	;
FXIP <		mov	si, offset irdbAttrs				>
FXIP <		mov	cx, size irdbAttrs				>
FXIP <		segmov	ds, cs						>
FXIP <		call	SysCopyToStackDSSI				>
	;
	; For non XIP we access the code segment
	;
NOFXIP <	segmov	ds, cs						>
NOFXIP <	mov	si, offset irdbAttrs				>

	;
	; Setup the parameters for the call to set the extended attributes.
	;
		sub     sp, 3 * size FileExtAttrDesc
		mov     di, sp
		segmov  es, ss

		mov     es:[di][0*FileExtAttrDesc].FEAD_attr, FEA_TOKEN
		mov     es:[di][0*FileExtAttrDesc].FEAD_value.segment, ds
		lea	bp, ds:[si].IFEA_fToken				
		mov     es:[di][0*FileExtAttrDesc].FEAD_value.offset, bp
		mov     es:[di][0*FileExtAttrDesc].FEAD_size, size GeodeToken

		mov     es:[di][1*FileExtAttrDesc].FEAD_attr, FEA_PROTOCOL
		mov     es:[di][1*FileExtAttrDesc].FEAD_value.segment, ds
		lea	bp, ds:[si].IFEA_fProtocol
		mov     es:[di][1*FileExtAttrDesc].FEAD_value.offset, bp
		mov     es:[di][1*FileExtAttrDesc].FEAD_size, \
						size ProtocolNumber

		mov     es:[di][2*FileExtAttrDesc].FEAD_attr, FEA_FLAGS
		mov     es:[di][2*FileExtAttrDesc].FEAD_value.segment, ds
		lea	bp, ds:[si].IFEA_fFlags
		mov     es:[di][2*FileExtAttrDesc].FEAD_value.offset, bp
		mov     es:[di][2*FileExtAttrDesc].FEAD_size, \
						size GeosFileHeaderFlags

		mov     ax, FEA_MULTIPLE
		mov     cx, 3			; number of entries
		call    FileSetHandleExtAttributes
		add     sp, 3 * size FileExtAttrDesc

		call	VMUpdate

FXIP <		call	SysRemoveFromStack				>

		.leave
		ret
IIIrdbFileSetExtAttrs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIOpenDatabaseFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the database file.

CALLED BY:	(INTERNAL) IRDBOPENDATABASE
PASS:		nothing
RETURN:		carry set if error
		ax 	= VMStatus
		bx 	= file handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIOpenDatabaseFile	proc	near
		uses	cx,dx,ds
		.enter

	;
	; Open the database in the SP_USER_DATA directory.
	;
		call	FilePushDir
		mov	ax, SP_USER_DATA
		call	FileSetStandardPath

	;
	; Go open the database file.
	;
		segmov	ds, cs
		mov	dx, offset irdbDatabaseFileName
		clr	cx
		mov	ax, (VMO_CREATE_TRUNCATE shl 8) or \
				mask VMAF_FORCE_SHARED_MULTIPLE or \
                         	mask VMAF_FORCE_READ_WRITE

		call	VMOpen			; ax = VMStatus
						; bx = file handle
		pushf
		call	FilePopDir
		popf
		jc	exit
	;
	; Make the library own the file.
	;
		push	ax			; VMStatus
		mov	ax, handle 0
		call	HandleModifyOwner

		pop	ax			; VMStatus

		clc
		
exit:
		.leave
		ret
IIOpenDatabaseFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IICheckDatabaseFileProtocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the protocol number of the file.

CALLED BY:	IIOpenDatabaseFile
PASS:		bx	= VMFileHandle
RETURN:		carry set if protocol unacceptable
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Get the protocol number
	- If the major is different, reject
	- If the minor is greater, reject

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IICheckDatabaseFileProtocol	proc	near
		uses	ax, cx, di, es
		.enter
	;
	; Get the extended attribute for the protocol number.
	;
		mov	cx, size ProtocolNumber
		sub	sp, cx
		mov	di, sp
		segmov	es, ss				; es:di <- buffer
		mov	ax, FEA_PROTOCOL
		call	FileGetHandleExtAttributes
		jc	exit

		cmp	es:[di].PN_major, IRDB_FILE_MAJOR_PROTOCOL
		jne	error

		cmp	es:[di].PN_minor, IRDB_FILE_MINOR_PROTOCOL
		ja	error

		clc
exit:
		lahf	
		add	sp, cx
		sahf
		.leave
		ret

error:
		stc
		jmp	exit
IICheckDatabaseFileProtocol	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIDeleteDatabaseFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the database file.

CALLED BY:	
PASS:		bx	= FileHandle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	- Close the file
	- Delete the file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIDeleteDatabaseFile	proc	near
		uses	ax,bx,dx,ds
		.enter
	;
	; Close the VMFile we have open. Don't care about errors.
	; We're killing the file anyway.
	;
		mov	al, FILE_NO_ERRORS
		call	VMClose
	;
	; Open the database in the SP_USER_DATA directory.
	;
		call	FilePushDir
		mov	ax, SP_USER_DATA
		call	FileSetStandardPath

		segmov	ds, cs
		mov	dx, offset irdbDatabaseFileName
		call	FileDelete
	;
	; Go back to the original directory
	;
		call	FilePopDir
		
		.leave
		ret
IIDeleteDatabaseFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IICleanUpDatabaseFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete any objects that aren't permanent.

CALLED BY:	(Internal) IRDBOPENDATABASE
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IICleanUpDatabaseFile	proc	near
		uses	ax,bx,cx,si,di,bp,ds
		.enter

	;
	; Get the object array.
	;
		call	IUGetObjArray	; bx <- file handle
					; ax <- VMBlock handle
					; si <- chunk handle
		call	VMLock

		mov_tr	ds, ax
	;
	; Loop through the chunk array and delete the ones that
	; are not permanent.
	;
		call	ChunkArrayGetCount	; cx <- number of elements
		jcxz	unlockBlock

		mov	ax, cx
		dec	ax			; chunk array is zero based
checkFlag:
		call	ChunkArrayElementToPtr		; ds:di <- element

		test 	ds:[di].IOAE_flags, mask ICEF_PERMANENT
		jnz	decCounter

		call	IUDeleteObjectFromObjectArray

decCounter:	dec	ax
		jns	checkFlag
	;
	; Unlock the VMBlock and make sure the new stuff gets saved.
	;
unlockBlock:
		call	IUUnlockBlockAndUpdateFile

		.leave
		ret
IICleanUpDatabaseFile	endp


IrdbCode	ends















