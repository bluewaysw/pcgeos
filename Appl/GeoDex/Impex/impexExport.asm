COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Impex		
FILE:		impexExport.asm

AUTHOR:		Ted H. Kim, March 4, 1992

ROUTINES:
	Name			Description
	----			-----------
	RolodexExportTransferItem	Create the export file
	FileExport		Create the export file in meta file format
	ExportRecord		Create a record entry in meta file format
	ReplaceCarriageReturn	Replace CR's with space characters
	WriteEmptyField		Create a blank element and add it to huge array
	WriteTextField		Create a text element and add it to huge array

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial revision

DESCRIPTION:
	This file contains all routines that deal with exporting a GeoDex file. 

	$Id: impexExport.asm,v 1.1 97/04/04 15:50:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Impex	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexExportToClipboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a transfer item on clipboard file.

CALLED BY:	(GLOBAL) MSG_ROLODEX_EXPORT_TO_CLIPBOARD

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di, es

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexExportToClipboard	proc	far
	RETC_SSMeta	local	SSMetaStruc
	.enter

	class	GeoDexClass

	push	bp
	call	SaveCurRecord
	pop	bp

	; is the database file empty?

	tst	ds:[gmb.GMB_numMainTab]
	je	exit				; if empty, just exit

	push	dx, bp	
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	UserCallApplication
	pop	dx, bp

	push	bp
	call	SaveCurRecord			; update if modified
	pop	bp

	; initialize the stack frame for copying a transfer item

	clr	ax
	mov	cx, ax				; ax:cx - source ID
	mov	bx, ax				; bx - TransferItemFlags
	push	bp
	mov	dx, ss				; dx:bp - SSMetaStruc
	lea	bp, RETC_SSMeta
	call	SSMetaInitForCutCopy

	; set the scrap size

	mov	ax, ds:[gmb.GMB_numMainTab]		; ax - number of rows
	mov	cx, GEODEX_NUM_FIELDS+NUM_PHONE_TYPE_FIELDS
	; cx - number of columns
	call	SSMetaSetScrapSize		; update the header block
	pop	bp

	mov	ds:[exportFlag], IE_CLIPBOARD	; a clipboard item
	call	FileExport			; export the current file

	push    bp
	mov     dx, ss                          ; SSMetaStruc => dx:bp
	lea     bp, RETC_SSMeta
	call    SSMetaDoneWithCutCopy           ; we are done
	pop     bp

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	UserCallApplication

exit:
	.leave
	ret
RolodexExportToClipboard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexExportTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a transfer item to be exported.

CALLED BY:	UI (=MSG_ROLODEX_CREATE_EXPORT_TRANSFER_ITEM)

PASS:		ss:bp - ptr to ImpexTranslationParams

RETURN:		TransferItem VMChain updated in ImpexTranslationParams

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexExportTransferItem	proc	far
	RETI_SSMeta	local	SSMetaStruc
	mov	bx, bp
	.enter
	
	class	RolodexClass

	push	bx, bp
	call	SaveCurRecord			; update if modified
	pop	bx, bp

	; initialize the stack frame for exporting

	push	bx
	mov	bx, ss:[bx].ITP_transferVMFile	; bx - VM file handle
	mov	ds:[xferFileHandle], bx		; save it
	push	bp
	mov	dx, ss				; dx:bp - SSMetaStruc
	lea	bp, RETI_SSMeta
	clr	cx
	clr	ax				; ax:cx - source ID
	call	SSMetaInitForStorage	

	; set the scrap size

	mov	ax, ds:[gmb.GMB_numMainTab]		; ax - number of rows
	mov	cx, GEODEX_NUM_FIELDS+NUM_PHONE_TYPE_FIELDS ; cx - number of columns
	call	SSMetaSetScrapSize		; update the header block
	pop	bp

	; is the database file empty?

	tst	ds:[gmb.GMB_numMainTab]
	je	empty				; if empty, skip

	mov	ds:[exportFlag], IE_FILE	; not a clipboard item
	call	FileExport			; export the current file

	; return TransferItem VMChain 
empty:
	pop	bx
	mov	ax, RETI_SSMeta.SSMDAS_hdrBlkVMHan	
	mov	ss:[bx].ITP_transferVMChain.high, ax
	tst	ds:[gmb.GMB_numMainTab]
	jne	skip				; if file empty, skip
	mov	ss:[bx].ITP_transferVMChain.high, 0
skip:
	mov	ss:[bx].ITP_transferVMChain.low, 0

	mov	ss:[bx].ITP_clipboardFormat, CIF_SPREADSHEET
	mov	ss:[bx].ITP_manufacturerID, MANUFACTURER_ID_GEOWORKS

	; Send notification back to ImportControl that we're done

	push	bp
	mov	bp, bx
	call	ImpexImportExportCompleted
	pop	bp

	.leave
	mov	bp, bx
	ret
RolodexExportTransferItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Export current file into meta file format.

CALLED BY:	(INTERNAL) RolodexExportTransferItem

PASS:		ds - segment address of dgroup

RETURN:		nothing

DESTROYED:	ax, cx, dx, si, di, es	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileExport	proc	far	uses	bp, bx
	FE_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	push	ds:[curRecord]		; save current record handle
	call	InitFieldSize		; initialize 'fieldSize' variable
	clr	cx			; initialize the record counter
	clr	dx			; offset into main handle table
mainLoop:
	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table
	call	DBLockNO
	mov	di, es:[di]		; lock this block
	add	di, dx
	mov	di, es:[di].TE_item	; di - handle of record entry 
	mov	ds:[curRecord], di	; save the record handle
	call	DBUnlock		; unlock main table
	call	ExportRecord		; export this record entry
	jc	error			; exit if errror
	add	dx, size TableEntry	; next entry
	inc	cx
	cmp	cx, ds:[gmb.GMB_numMainTab]	; continue if not done
	jne	mainLoop

	call	ExportFieldName		; export field names 
	jmp	quit
error:
	call	MemAllocErrBox		; put up an error message
quit:
	pop	ds:[curRecord]		; restore current record handle

	.leave
	ret
FileExport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFieldSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize 'fieldSize' variable.

CALLED BY:	(GLOBAL) FileExport

PASS:		ds - dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	11/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFieldSize	proc	far		uses	ax, cx, di, es
	.enter

	segmov	es, ds
	mov	di, offset fieldSize	; es:di - fieldSize
	clr	ax
	mov	cx, GEODEX_NUM_FIELDS+NUM_PHONE_TYPE_FIELDS	

	; cx - number of words to copy
next:
	stosw				; clear the variable
	loop	next
	.leave
	ret
InitFieldSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportFieldName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a field info block that contains field name and data
		types, etc and write this block out to ssmeta file.

CALLED BY:	(GLOBAL)

PASS:		nothing

RETURN:

DESTROYED:

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	11/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportFieldName		proc	far	uses	bp, ds
	EFN_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	; allocate a data block to store field info

	mov	ax, size FieldInfoBlock		; ax - # of bytes to allocate
	mov	cx, ALLOC_DYNAMIC_NO_ERR or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc			; allocate a block

	clr	dx				; dx - field number
	push	bx				; save the handle
	call	MemLock
	mov	es, ax
	mov	es:[FIB_fieldType], FDT_GENERAL_TEXT	; text field
mainLoop:
	; lock the field info block

	push	ds				; ds - dgroup
	shl	dx, 1
	mov	di, dx
	mov	cx, ds:fieldSize[di]
	mov	es:[FIB_fieldSize], cx		; cx - field data size

	; locate field name string

	GetResourceHandleNS	TextResource, bx	
	call	MemLock				; lock the strings block
	mov	ds, ax
	mov	si, offset DexListArray		; *ds:si - DexListArray
	mov	si, ds:[si]			; dereference it
	add	si, dx				; ds:si - ptr to offset list
	mov	si, ds:[si]			
	mov	si, ds:[si]			; ds:si - ptr to string

	ChunkSizePtr	ds, si, ax		; ax - size of lmem chunk
	LocalPrevChar	dsax
	mov	cx, ax				; cx - number of bytes to copy

	; check to see if the field name is too long

SBCS<	cmp	cx, MAX_FIELD_NAME_LENGTH				>
DBCS<	cmp	cx, MAX_FIELD_NAME_LENGTH*(size wchar)			>
	jle	skip	
SBCS<	mov	cx, MAX_FIELD_NAME_LENGTH	; if too long, truncate it >
DBCS<	mov	cx, MAX_FIELD_NAME_LENGTH*(size wchar)			>
skip:
	mov	di, offset FIB_fieldName	; es:di - destination
	rep	movsb				; copy the string
	LocalClrChar	ax
	LocalPutChar	esdi, ax		; null terminate the string

	call	MemUnlock			; unlock TextResource block

	; initialize ssmeta stack frame

	shr	dx, 1				
	mov	EFN_SSMeta.SSMDAS_dataArraySpecifier, DAS_FIELD
	mov	EFN_SSMeta.SSMDAS_row, 0
	mov	EFN_SSMeta.SSMDAS_col, dx	; dx - column number

	; add this entry to DAS_FIELD data array

	push	bp, dx
	mov	cx, size FieldInfoBlock		; cx - # of bytes in the entry
	segmov	ds, es				; ds:si - string to copy
	clr	si				
	mov	al, SSMETA_ADD_TO_END		; al - SSMetaAddEntryFlags
	mov	dx, ss				; dx:bp - SSMetaStruc
	lea	bp, EFN_SSMeta 
	call	SSMetaDataArrayAddEntry		; add the new element
	pop	bp, dx
	pop	ds				; ds - dgroup
	inc	dx
	cmp	dx, GEODEX_NUM_FIELDS+NUM_PHONE_TYPE_FIELDS	; are we done?
	jne	mainLoop			; if not, continue

	pop	bx
	call	MemFree				; free the block

	.leave
	ret
ExportFieldName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a record entry in database meta file format.

CALLED BY:	FileExport

PASS:		ds - segment address of dgroup
		exportFlag - flag indicating whether or not
			this is a clipboard item
		cx - current record number

RETURN:		carry set if there was an error

DESTROYED:	ax, si, di 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version
	owa	7/93		added phonetic/zip field

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportRecord	proc	far	uses	bx, cx, dx, bp
	ER_SSMeta	local	SSMetaStruc
	.enter	inherit	far

	clr	dx				; field number counter
mainLoop:
	mov	di, ds:[curRecord]		; di - handle of current record
	call	DBLockNO
	mov	si, es:[di]			; lock this block
	push	cx, dx				; save the counter
	cmp	dx, TEFI_LASTNAME		; last name field?
	je	doName				; if so, skip to handle it

	cmp	dx, TEFI_ADDRESS		; address field?
	je	doAddr				; if so, skip to handle it

PZ <	cmp	dx, TEFI_PHONETIC		; phonetic field?       >
PZ <	je	doPhonetic			; if so, skip to handle it>

PZ <	cmp	dx, TEFI_ZIP			; zip field?    >
PZ <	je	doZip				; if so, skip to handle it>

	cmp	dx, TEFI_NOTES			; notes field?
	je	doNote				; if so, skip to handle it

	cmp	dx, TEFI_PHONE_NAME1		; phone field? 
	jb	doPhone				; if so, skip to handle it
	jmp	doPhoneTypes			; if not, must be phone type

doName:
	mov	cx, es:[si].DBR_indexSize	; cx - # of bytes to copy
	add	si, size DB_Record		; es:si - ptr to string to copy
	jmp	writeField
doAddr:
	mov	cx, es:[si].DBR_addrSize	; cx - # of bytes to copy
	add	si, es:[si].DBR_toAddr		; es:si - ptr to string to copy
	jmp	writeField			; skip to write this field out
if PZ_PCGEOS
doPhonetic:
	mov	cx, es:[si].DBR_phoneticSize	; cx - # of bytes to copy
	add	si, es:[si].DBR_toPhonetic	; es:si - ptr to string to copy
	jmp	writeField
doZip:
	mov	cx, es:[si].DBR_zipSize		; cx - # of bytes to copy
	add	si, es:[si].DBR_toZip		; es:si - ptr to string to copy
	jmp	writeField
endif

doNote:
	mov	di, es:[si].DBR_notes		; di - handle of notes block
	call	DBUnlock			; unlock record block
	clr	cx				; assume no note field
	tst	di				; is there note field? 
	je	common				; if not, skip
	call	DBLockNO
	mov	si, es:[di]			; lock notes block

	; eliminate all carriage returns and count number of bytes

	mov	di, si				; size string from es:di
	call	LocalStringSize
	inc	cx				; add 1 for null char
DBCS <	inc	cx							>
	jmp	writeField

doPhone:
	sub	dx, TEFI_PHONE1-1
	cmp	dx, es:[si].DBR_noPhoneNo	; no more phone entry?
	jge	blankField			; if none, create empty field
	add	si, es:[si].DBR_toPhone		; es:si - source string
phoneLoop:
	tst	dx				; found the phone string
	je	phoneFound			; if so, skip 
if DBCS_PCGEOS
	mov	ax, es:[si].PE_length
	shl	ax, 1				; ax - phone string size
	add	si, ax				; advance record ptr
else
	add	si, es:[si].PE_length
endif
	add	si, size PhoneEntry		; otherwise, advance to 
	dec	dx
	jne	phoneLoop			; the next entry
phoneFound:
	mov	cx, es:[si].PE_length
DBCS<	shl	cx, 1				; cx - text size	>
	add	si, size PhoneEntry		; es:si - ptr to string to copy
	jmp	writeField
doPhoneTypes:
	sub	dx, TEFI_PHONE_NAME1-1
	cmp	dx, es:[si].DBR_noPhoneNo	; no more phone	entries?
	jge	blankField			; if none, create empty field
	add	si, es:[si].DBR_toPhone		; es:si - PhoneEntry
phoneTypeLoop:
	tst	dx				; found the string
	je	phoneTypeFound			; if so, skip
if DBCS_PCGEOS
	mov	ax, es:[si].PE_length
	shl	ax, 1				; ax - phone string size
	add	si, ax				; advance record ptr
else
	add	si, es:[si].PE_length
endif
	add	si, size PhoneEntry		; next entry
	dec	dx
	jne	phoneTypeLoop
phoneTypeFound:
	pop	ax, bx				; get count
	push	ax, bx				; save count
	call	WritePhoneName			; create text field
	jc	exit				; exit if error
	jmp	blankField
	;
	; Append the text field to huge array
	;
writeField:
	pop	ax, bx				; get col/row 
	push	ax, bx
	tst	cx				; empty field?
	jz	blankField			; if blank, don't write
	call	WriteTextField			; create a text field
	jc	exit				; exit if error
blankField:
	call	DBUnlock			; unlock DB block
common:
	pop	cx, dx				; restore the field counter
	inc	dx			

	; are we done for this record?

	cmp	dx, GEODEX_NUM_FIELDS+NUM_PHONE_TYPE_FIELDS	
	LONG	jne	mainLoop		; if not continue

	clc					; exit with no error
	jmp	quit
exit:
	call	DBUnlock
	pop	cx, dx				
quit:
	.leave
	ret
ExportRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePhoneName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the string to copy and calls WriteTextField
		to write the phone name to the huge array.

CALLED BY:	ExportRecord()

PASS:		ds    - dgroup
		es:si - Current PhoneEntry
		ax    - row number
		bx    - column number

RETURN:		nothing

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

	Get the type from the current PhoneEntry.
	if not blank
		lock the phoneTypeBlk
		use type number to index into array
		add the offset to the phone type text
		get length of text
		call WriteTextField
	else write blank field
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WritePhoneName	proc	near
	uses	cx,dx,si,di,bp,es
	.enter
	
	clr	cx
	mov	cl, es:[si].PE_type		; get the phone name type
	jcxz	blankName			; if field name empty, skip
	;
	; Lock the phoneTypeBlk and index into the type
	; of phone name text.
	;	
	mov	di, ds:[gmb.GMB_phoneTypeBlk]
	call	DBLockNO
	mov	di, es:[di]			; beginning of phone table
	mov	si, di
	shl	cx, 1				; word-size entries
	add	si, cx				; index to offset
	add	di, es:[si]			; es:di -> phone name text
	;
	; Write out the phone name to the huge array
	;
	call	LocalStringSize			; cx = bytes in string
	mov	si, di				; es:si points to string
	inc	cx				; for null char
DBCS<	inc	cx				; word-size null	>

	call	WriteTextField			; create a text field
	call	DBUnlock			; unlock phone type blk
blankName:
	.leave
	ret
WritePhoneName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceCarriageReturn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace all CR's with space characters, in place.

CALLED BY:	ExportRecord

PASS:		es:si - ptr to string to scan

RETURN:		cx - number of bytes in the string

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceCarriageReturn	proc	near	uses	si, ax
	.enter
	
	clr	cx				; initialize the counter
addrLoop:
	LocalGetChar	ax, essi, noAdvance	; scan string for CR
	LocalIsNull	ax			; end of string?
	je	exit				; if so, done

	LocalCmpChar	ax, C_CR		; carriage return?
	je	replace				; if so, skip
next:
	LocalNextChar	essi			; if not, check the next char
	inc	cx				; update the counter
	jmp	addrLoop

replace:
SBCS <	mov	{char} es:[si], ' '		; replace CR with space	>
DBCS <	mov	{wchar} es:[si], ' '		; replace CR with space	>
	jmp	next				; check the next character

exit:
	inc	cx				; add one for null terminator
DBCS<	shl	cx, 1				; cx - string size	>

	.leave
	ret
ReplaceCarriageReturn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteTextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a text element and append it to the huge array.

CALLED BY:	ExportRecord

PASS:		ds - segment address of dgroup
		es:si - points to the string to copy
		cx - number of bytes to copy (string size)
		ax - row number
		bx - column number

RETURN:		carry set if there was an error

DESTROYED:	ax, bx, cx, dx, si, di, bp

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteTextField		proc	near	uses	es, ds
	WTF_SSMeta	local	SSMetaStruc
	.enter	inherit near

	mov	dl, ds:[exportFlag]

if DBCS_PCGEOS and ERROR_CHECK
	test	cx, 1
	ERROR_NZ  TEXT_STRING_ODD_STRING_SIZE
endif
	; update the size of text fields if necessary

	push	bx
	shl	bx, 1
	cmp	cx, ds:fieldSize[bx]	; is this the biggest text field?	
	jle	skip			; if not, skip
	mov	ds:fieldSize[bx], cx	; if so, update 
skip:
	pop	bx

	; initialize ssmeta stack frame

	mov	WTF_SSMeta.SSMDAS_dataArraySpecifier, DAS_CELL
	mov	WTF_SSMeta.SSMDAS_row, ax
	mov	WTF_SSMeta.SSMDAS_col, bx

	; allocate a new data block

	push	es, si				; es:si - ptr to source string
	push	cx				; cx - number of bytes to copy
	add	cx, size CellCommon		
	mov	ax, cx				; ax - # of bytes to allocate
	mov	cx, ALLOC_DYNAMIC_LOCK		; HeapAllocFlags | HeapFlags
	call	MemAlloc			; allocate a block
	pop	cx
	jc	exit				; exit if not enough memory
	mov	es, ax
	clr	di				; es:di - destination

	; copy cell data and cell type into this data block

	mov	es:[di].CC_type, CT_TEXT	; mark it as a text field
	add	di, size CellCommon		; es:di - destination
	pop	ds, si				; ds:si - source string
	push	cx
	rep	movsb				; copy the string

	; We don't want to save CRs in CSV files

	cmp	dl, IE_CLIPBOARD
	je	noReplace
	mov	si, size CellCommon		; es:si - copied string
	call	ReplaceCarriageReturn		; replace CRs with spaces
noReplace:
	pop	cx

	; add this entry to the data array

	push	bp
	add	cx, size CellCommon		; cx - # of bytes in the entry
	segmov	ds, es				; es:si - source string
	clr	si
	mov	al, SSMETA_ADD_TO_END		; al - SSMetaAddEntryFlags
	mov	dx, ss				; dx:bp - SSMetaStruc
	lea	bp, WTF_SSMeta 
	call	SSMetaDataArrayAddEntry		; add the new element
	pop	bp
	call	MemFree				; free the data block
	clc					; exit with no error
	jmp	quit
exit:
	pop	es, si
quit:
	.leave
	ret
WriteTextField		endp

Impex	ends
