COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc		
FILE:		miscPrint.asm

AUTHOR:		Ted H. Kim, 2/12/90

ROUTINES:
	Name			Description
	----			-----------
	RolodexPrint		method handler for print menu
	RolodexPrintOption	status message from print option list
	PrintAllOrPhones	prints everything
	PrintCurRecord		prints current record
	GetAnAddress		gets text string for PrintAll option
	GetAString		replace CR's with ", "
	GetPhoneEntry		copies a single phone entry to text object 
	PrintAnAdress		prints text string in PrintAll format
	GetPhoneNumbers		copies all of phone entries to text object
	PrintPhoneNumbers	prints text strings in PrintPhones format
	PageBreak		does a form feed
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	2/12/90		Initial revision

DESCRIPTION:

	$Id: miscPrint.asm,v 1.2 98/02/15 19:07:05 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Print	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexPrint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method handler for print menu.

CALLED BY:	UI (= MSG_ROLODEX_PRINT)

PASS:		cx:dx - OD of DocumentControlObject
		bp - graphics state handle

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	5/2/90		Initial version
	Ted	8/6/91		Uses text object to print

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexPrint	proc	far
	RP_PrintInfo	local	PageSizeReport
	mov	bx, bp			; bx - gState handle

	.enter

	class	RolodexClass

	push	bx, cx, dx, bp
	call	SaveCurRecord		; update if modified
	pop	bx, cx, dx, bp

	mov	ds:[printGState], bx	; save gstate handle
	clr	ds:[pageCount]		; initialize page count
	clr	ds:[printFlag]		; initialize print flags

	; Get margins & document size 

	push	bp
	mov	dx, ss			; dx:bp - PageSizeReport
	lea	bp, RP_PrintInfo
	mov	ax, MSG_PRINT_CONTROL_CALC_DOC_DIMENSIONS
	call	CallSpoolPrintControlMF_CALL	
	pop	bp
	
	; update document size info

	movdw	dxax, RP_PrintInfo.PSR_width	
	mov	ds:[printWidth], ax
	movdw	dxax, RP_PrintInfo.PSR_height	
	mov	ds:[printHeight], ax

	; update margin info

	mov	ax, RP_PrintInfo.PSR_margins.PCMP_left
	mov	ds:[leftMargin], ax	
	mov	ax, RP_PrintInfo.PSR_margins.PCMP_top
	mov	ds:[topMargin], ax	
	mov	ds:[curYPos], ax	

	; get the printer mode and set the font
	
	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_PRINT_MODE
	call	CallSpoolPrintControlMF_CALL	; PrinterMode => CL

	;	Pizza --  Uses Kanji Square Gothic always
	;	DBCS  --  Uses 
	;	SBCS  --  Either URW Roman or URW Mono

if DBCS_PCGEOS
	mov	ax, FID_PIZZA_KANJI		; assume text mode printing
	cmp	cl, PM_FIRST_TEXT_MODE		; bitmap font
	jae	gotPrintMode			; yes, text mode.
PZ  <	mov	ax, FID_BITSTREAM_KANJI_SQUARE_GOTHIC	; always for Pizza>
NPZ <	mov	ax, FID_DTC_URW_MONO		; generic for DBCS	>
else
	mov	ax, FID_DTC_URW_MONO		; assume text mode printing
	cmp	cl, PM_FIRST_TEXT_MODE
	jae	gotPrintMode
	mov	ax, FID_DTC_URW_ROMAN		; graphics mode printing
endif
gotPrintMode:
	mov	dx, size VisTextSetFontIDParams	; dx - size of VTSFIDP
	sub	sp, size VisTextSetFontIDParams
	mov	bp, sp				; ss:bp - ptr to VTSFIDP
	mov	ss:[bp].VTSFIDP_range.VTR_start.low, 0	
	mov	ss:[bp].VTSFIDP_range.VTR_start.high, 0	
	mov	ss:[bp].VTSFIDP_range.VTR_end.low, TEXT_ADDRESS_PAST_END_LOW 
	mov	ss:[bp].VTSFIDP_range.VTR_end.high, TEXT_ADDRESS_PAST_END_HIGH 
	mov	ss:[bp].VTSFIDP_fontID, ax	; ax - font ID 
	mov	ax, MSG_VIS_TEXT_SET_FONT_ID
	call	CallPrintTextObjectMF_STACK	; set the font
	add	sp, size VisTextSetFontIDParams	; restore sp

	; set the point size for this font

	mov	cx, 12					; cx - point size
	mov	dx, size VisTextSetPointSizeParams	; dx - size of VTSPSP
	sub	sp, size VisTextSetPointSizeParams
	mov	bp, sp					; ss:bp - ptr to VTSPSP
	mov	ss:[bp].VTSPSP_range.VTR_start.low, 0	
	mov	ss:[bp].VTSPSP_range.VTR_start.high, 0	
	mov	ss:[bp].VTSPSP_range.VTR_end.low, TEXT_ADDRESS_PAST_END_LOW 
	mov	ss:[bp].VTSPSP_range.VTR_end.high, TEXT_ADDRESS_PAST_END_HIGH 
	mov	ss:[bp].VTSPSP_pointSize.WWF_int, cx
	clr	ss:[bp].VTSPSP_pointSize.WWF_frac
	mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
	call	CallPrintTextObjectMF_STACK		; set the point size
	add	sp, size VisTextSetPointSizeParams	; restore sp

	; check to see if "Print Notes" option is set 

	andnf	ds:[printFlag], not mask PF_NOTES	
	mov	si, offset PrintNotes		; bx:si - OD of list entry
	GetResourceHandleNS	PrintNotes, bx 
	mov	cx, 1				; cx - identifier
	MOV	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	
	call	ObjMessage			; get the state of check box 
	jnc	noNotes				; if off, skip
	ornf	ds:[printFlag], mask PF_NOTES	

noNotes:
if	FAX_SUPPORT
	; consult the PrintControl to see which MailboxObjectType the user
	; wants us to send.

	mov	ax, MSG_PRINT_GET_MAILBOX_OBJECT_TYPE
	call	CallSpoolPrintControlMF_CALL
	jc	getOptionSel			; => SendControl doesn't enter
						;  into it

	sub	ax, MOT_CURRENT_CARD		; (compare & set ax to 0 if it's
						;  the current card)
	je	haveSelection

	; if not MOT_CURRENT_CARD, ask PrintOptionList for its opinion

getOptionSel:
endif	; FAX_SUPPORT

	; figure out which print format has been selected

	mov	si, offset PrintOptionList	
	GetResourceHandleNS	PrintOptionList, bx
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 
	call	ObjMessage		; get the entry number selected 

if 	FAX_SUPPORT

haveSelection:

endif	; FAX_SUPPORT
	tst	ax			; is print cur record option selected?
	jne	checkCurAddress		; if not, skip 

	ornf	ds:[printFlag], mask PF_CUR_REC 
	call	PrintCurRecord		; print current record
	jmp	common
checkCurAddress:
	cmp	ax, PFF_CUR_REC_ADDR	; is print cur address selected?
	jne	printAll
	ornf	ds:[printFlag], mask PF_CUR_ADDRESS
	andnf	ds:[printFlag], not mask PF_NOTES
	call	PrintCurRecord		; print current record (addr only)
	jmp	common
printAll:
	cmp	ax, PFF_ALL		; print phone numbers only option?
	jne	printAddresses
	ornf	ds:[printFlag], mask PF_ALL	; if not, then print all
	jmp	startPrint
printAddresses:
	cmp	ax, PFF_ALL_ADDR		; print addresses only option?
	jne	printPhones
	ornf	ds:[printFlag], mask PF_ADDRESSES
	andnf	ds:[printFlag], not mask PF_NOTES
	jmp	startPrint
printPhones:
	ornf	ds:[printFlag], mask PF_PHONES	; if so, print phone numbers 
startPrint:
	call	PrintAllOrPhones	; print it!
common:
	; Set the total number of pages to be printed

	mov	cx, 1			; cx - first possible page
	mov	dx, ds:[pageCount]	; dx - last possible page
	inc	dx			; compensate for being set 0 initially
	mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
	call	CallSpoolPrintControl	; set the total page

	; Tell the PrintControl object that we're done
	
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
	call	CallSpoolPrintControl
	pop	bp

	.leave
	ret
RolodexPrint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexPrintOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable or enable "Print Notes" checkbox depending on
		the print option selected.

CALLED BY:	(GLOBAL) MSG_ROLODEX_PRINT_OPTION

PASS:		cx - identifier of the item selected

RETURN:		nothing

DESTROYED:	ax, bx, dx, si, di

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	11/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexPrintOption	proc	far
	class	GeoDexClass

	mov     ax, MSG_GEN_SET_ENABLED         ; enable GenBoolean
	cmp	cx, PFF_CUR_REC			; full current record?
	je	enable				; if not, enable GenBoolean 
	cmp	cx, PFF_ALL			; full all records?
	je	enable
	mov     ax, MSG_GEN_SET_NOT_ENABLED     ; disable GenBoolean 
enable:
	mov	si, offset PrintNotes  		; bx:si - OD of GenBoolean
	GetResourceHandleNS	PrintNotes, bx 
	mov	di, mask MF_FIXUP_DS
	mov	dl, VUM_NOW			; do it now
	call	ObjMessage			; en/disable the checkbox
	ret
RolodexPrintOption	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintAllOrPhones
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles PrintAll or PrintPhones options.

CALLED BY:	(INTERNAL) RolodexPrint

PASS:		printGState - gState handle

RETURN:		nothing

DESTROYED:	everything 

PSEUDO CODE/STRATEGY:
	For each record in database
		If PrintAll option
			get an address
			print an address
		Else 
			get phone entries
			print phone entries
	Next record

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	5/2/90		Initial version
	Ted	8/6/91		Uses text object to print

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintAllOrPhones	proc	near
	call	ClearAllTabs			; clear all previously set tabs
	clr	ds:[columnNo]			; column indicator
	clr	ds:[firstPage]			; clear for first page
	clr	dx				; dx - offset into main table
mainLoop:
	push	dx
	mov	di, ds:[gmb.GMB_mainTable]		; di - handle of main table
	call	DBLockNO				
	mov	di, es:[di]			; open it up
	TableEntryIndexToOffset  dx		; dx - offset to current record
	add	di, dx				; di - ptr to current record
	mov	di, es:[di].TE_item		; di - handle of current record
	call	DBUnlock			; unlock main table
	test	ds:[printFlag], mask PF_PHONES	; print phones options?
	jne	phones				; if so, skip

	call	GetAnAddress			; get a record
	call	PrintAnAddress			; print a record
	jmp	common
phones:
	call	GetPhoneNumbers			; get phone entries
	call	PrintPhoneNumbers		; print phone entries 

common:
	call	GetPageType
	cmp	ax, PT_PAPER			; printing on regular paper?
	je	noPageBreak			; jump if so
	call	PageBreak			; for each new label / envelope
noPageBreak:
	pop	dx				; dx - offset to main table
	inc	dx
	mov	ds:[firstPage], 1		; no longer first page
	cmp	dx, ds:[gmb.GMB_numMainTab]		; are we done yet?
	jne	mainLoop			; if not, continue
	ret
PrintAllOrPhones	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintCurRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the current record only.

CALLED BY:	(INTERNAL) RolodexPrint

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, si, es

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	3/16/93		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintCurRecord	proc	near
	call	ClearAllTabs
	clr	ds:[firstPage]
	mov	di, ds:[curRecord]
	tst	di
	je	exit
	call	GetAnAddress
	call	PrintAnAddress
	call	PageBreak
exit:
	ret
PrintCurRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the CR string to the text object

CALLED BY:	GetAnAddress
PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	ax, cx, cx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCR	proc	near
	.enter
	;
	; Append the Carriage Return
	;
	mov	bp, offset CRString	; dx:bp - pointer to string to print
	mov	dx, ds
	clr	cx			; null terminated string
	mov	ax, MSG_VIS_TEXT_APPEND
	call	CallPrintTextObjectMF_CALL	; add a carriage return

	.leave
	ret
GetCR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTAB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends the Tab string to the text object

CALLED BY:	GetAnAddress
PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTAB	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; Append the Tab 
	;
	mov	bp, offset TABString	; dx:bp - pointer to string to print
	mov	dx, ds
	clr	cx			; null terminated string
	mov	ax, MSG_VIS_TEXT_APPEND
	call	CallPrintTextObjectMF_CALL	; add a tab character

	.leave
	ret
GetTAB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAnAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the text string to text object in PrintAll format.

CALLED BY:	(INTERNAL) PrintAllOrPhones, PrintCurRecord

PASS:		di - handle of DB block to print

RETURN:		Text object contains the text string to print

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

PSEUDO CODE/STRATEGY:
   if not PZ_PCGEOS
	Copy the index field to text object
   else
	Copy the phonetic field if exist, otherwise copy the index field.
   endif
	If the index field is too wide
		Add a carriage return
	Add a tab
	Add the address field while replacing a CR w/ comma and space
	Add all the phone entries w/ phone numbers

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	8/6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

nullString char 0

GetAnAddress	proc	near

	; Open up the record and copy the index field to text object

	call	DBLockNO				
	mov	di, es:[di]		; open up current record

	test	ds:[printFlag], mask PF_ADDRESSES or mask PF_CUR_ADDRESS
	je	doIndex
	;
	; Since we'll be appending strings with calls to GetAString,
	; we better clear the text now
	;
	mov	dx, cs
	mov	bp, offset nullString
	clr	cx			; cx - null terminated string
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	CallPrintTextObjectMF_CALL
	jmp	noIndex

doIndex:
	push	es, di
	clr	cx			; cx - null terminated string
if PZ_PCGEOS
	; At first check wheter phonetic field exist
	tst	es:[di].DBR_phoneticSize ; is phonetic field empty?
	jz	useIndex		; if so, use index field.
	add	di, es:[di].DBR_toPhonetic ; else, use phonetic field.
	jmp	common
useIndex:
endif
	add	di, size DB_Record	
PZ < common:							>
	mov	bp, di
	mov	dx, es			; dx:bp - pointer to string
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	CallPrintTextObjectMF_CALL	; set text in printing object

	; Calculate the width of index field

	clr	cx			; cx - use the entire string
	mov	ax, MSG_VIS_TEXT_GET_ONE_LINE_WIDTH
	call	CallPrintTextObjectMF_CALL	; returns cx = width of text 
	mov	dx, ds:[printWidth]	; dx - printable width
	shr	dx, 1			
	shr	dx, 1			; divide it by four
	sub	dx, ONE_CHAR_WIDTH 

	cmp	cx, dx			; name longer than quarter of document?
	jle	notWide			; if not, skip

	; If the index field takes up more than quarter of the entire document
	; horizontally, the address string should be printed on the next line

	call	GetCR
notWide:
	call	GetTAB
	pop	es, di

noIndex:
if PZ_PCGEOS
	push	es, di
	mov	cx, es:[di].DBR_zipSize	; cx - # of bytes in addr field
	add	di, es:[di].DBR_toZip	; es:di - point to address string
	
	; Copy the zip string to the text object
	
	call	GetAString
	pop	es, di

	; Add a comma and a space character

	mov	bp, offset CommaAndSpace
	mov	dx, ds			; dx:bp - pointer to string to print
	clr	cx			; null terminated string
	mov	ax, MSG_VIS_TEXT_APPEND
	call	CallPrintTextObjectMF_CALL	; add a comma and space
endif
	push	es, di

	mov	cx, es:[di].DBR_addrSize; cx - # of bytes in addr field
	add	di, es:[di].DBR_toAddr	; es:di - points to address string 

	; Copy the address string to the text object

	call	GetAString
	pop	es, di
		
	; Now, copy the phone number entry strings to the text object

	test	ds:[printFlag], mask PF_ADDRESSES or mask PF_CUR_ADDRESS
	jne	notes				; skip phone if address only

	push	es, di
	mov	dx, es:[di].DBR_noPhoneNo	; dx - number of phone numbers
	add	di, es:[di].DBR_toPhone		; es:di - ptr to phone entries 
phoneLoop:
	push	dx
	tst	es:[di].PE_length		; is this number empty?
	je	next				; if so, check the next number
SBCS <	tst	{byte}es:[di].PE_strings	; is number NULL?	>
DBCS <	tst	{word}es:[di].PE_strings	; is number NULL?	>
	jz	next				; if so, check the next number

	call	GetCR
	call	GetTAB

	; copy a phone entry to text object

	call	GetPhoneEntry
	jmp	next2			; copy the next phone entry
next:
SBCS <	add	di, es:[di].PE_length					>
DBCS <	mov	dx, es:[di].PE_length					>
DBCS <	shl	dx, 1							>
DBCS <	add	di, dx							>
	add	di, size PhoneEntry	; di - ptr to the next phone #
next2:
	pop	dx			; dx - # of phones to be printed
	dec	dx			; are we done printing phone #s?
	jne	phoneLoop		; if not, print the next phone number

	pop	es, di
	
notes:
	; print notes option set?

	test	ds:[printFlag], mask PF_NOTES
	je	noNotes			; if not, skip	

	tst	es:[di].DBR_notes	; is there notes field?
	je	noNotes			; if not, skip

	; Add a comma and a space character

	call	GetCR
	call	GetCR
	test	ds:[printFlag], mask PF_ADDRESSES or mask PF_CUR_ADDRESS
	jne	noNotesTAB
	call	GetTAB
noNotesTAB:
	push	es, di
	mov	di, es:[di].DBR_notes	; di - handle of notes data block
	call	DBLockNO
	mov	di, es:[di]		; es:di - points to the string

	; calculate how many bytes there are now in the notes field

	ChunkSizePtr	es, di, cx		; cx - string size w/ NULL

	; copy the notes field to the text object

	call	GetAString
	call	DBUnlock
	pop	es, di
noNotes:
	call	DBUnlock		; unlock the current record
	call	GetCR			; to separate the records
	ret
GetAnAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append a text string to the text object while replacing
		CR's with CR's + TABS. 

CALLED BY:	(INTERNAL) GenAnAddress

PASS:		es:di - pointer to a string
		cx - string size

RETURN:		text appended

DESTROYED:	ax, bx, cx, dx, si, di 

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	3/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetAString	proc	near
DBCS<	shr	cx, 1			; cx - # of chars in addr field	>
addrLoop:
	; Scan the string for carriage returns

	push	di			; es:di - ptr to string to scan
	LocalLoadChar	ax, C_CR
	LocalFindChar			; scan for a carriage return

	mov	si, di
	tst	cx			; has there been a CR?
	pop	di			; es:di - ptr to string to scan
	je	append			; if no CR, print w/o modification

	; Now, calculate how many characters to print

	push	cx, si			; save length, front ptr
	sub	si, di			; si - # of chars to print
DBCS <	shr	si, 1			; si - # of chars to print	>
	dec	si			; do not include CR
	mov	cx, si			; cx - # of chars to print

	tst	cx			; was CR only char of this line? 
	je	space			; if so, skip

	mov	bp, di
	mov	dx, es			; dx:bp - pointer to string to print
	mov	ax, MSG_VIS_TEXT_APPEND
	call	CallPrintTextObjectMF_CALL ; copy the string to text object
space:
	call	GetCR

	test	ds:[printFlag], mask PF_ADDRESSES or mask PF_CUR_ADDRESS
	jne	noTAB				; skip if address only

	call	GetTAB
noTAB:
	pop	cx, di
	jmp	addrLoop		; check the rest of the string

append:
	mov	bp, di
	mov	dx, es			; dx:bp - pointer to string to print
	clr	cx			; null terminated string
	mov	ax, MSG_VIS_TEXT_APPEND
	call	CallPrintTextObjectMF_CALL ; copy the string to the text object 
	ret
GetAString	endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPhoneEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the phone number string to text object

CALLED BY:	(INTERNAL) GetAnAddress, GetPhoneNumbers

PASS:		es:di - pointer to the phone entry to copy
			PE_type, PE_length

RETURN:		es:di - points to the beginning of the next phone entry

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
	Copy the phone type name to the text object
	Add a space
	Copy the phone number string to the text object
	Adjust es:di pointer past this record.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	8/6/91		Initial version
	witt	1/22/94 	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPhoneEntry	proc	near

	; Get the phone number type name string and print it

	push	es, di
	mov	dl, es:[di].PE_type	; dl - phone number type ID
	mov	di, ds:[gmb.GMB_phoneTypeBlk]	; di - handle of data block
	call	DBLockNO
	mov	di, es:[di]		; di - ptr to beg of data
	mov	si, di			; save the pointer in si 
	clr	dh
	shl	dx, 1			
	tst	dx			; is offset zero?
	jne	nonZero			; if not, skip
	mov	dx, 2			; if so, adjust the offset
nonZero:
	add	si, dx			; si - ptr to offset 
	add	di, es:[si]		; di - ptr to text string

	mov	bp, di
	mov	dx, es			; dx:bp - pointer to string
	clr	cx			; null terminated string
	mov	ax, MSG_VIS_TEXT_APPEND
	call	CallPrintTextObjectMF_CALL	; print phone type name
	call	DBUnlock

	; Now, add a non-breakable space character to the text object

	mov	bp, offset SpaceString
	mov	dx, ds			; dx:bp - pointer to string
	clr	cx			; null terminated string
	mov	ax, MSG_VIS_TEXT_APPEND
	call	CallPrintTextObjectMF_CALL	; add a space character
	pop	es, di			; es:di - beg. of this phone entry

	; copy the phone number to the text object

	mov	cx, es:[di].PE_length	; cx - # of chars in phone number
	push	cx
	add	di, size PhoneEntry	; di - ptr to the phone number
	mov	bp, di
	mov	dx, es			; dx:bp - pointer to string to print
	clr	cx			; null terminated string
	mov	ax, MSG_VIS_TEXT_APPEND
	call	CallPrintTextObjectMF_CALL	; copy the phone number
	pop	cx
DBCS<	shl	cx, 1			; cx - string size		>
	add	di, cx			; update the pointer
	ret
GetPhoneEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPageType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the type of paper we're printing on

CALLED BY:	PrintAnAddress()
PASS:		nothing
RETURN:		ax - PageType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	5/17/95    	Initial version
	grisco	6/ 5/95		Changed from IsLabelPrinting() to return
				PageType

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPageType	proc	near
	RP_PrintInfo	local	PageSizeReport
	uses	cx,dx,bp
	.enter

	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_PAPER_SIZE_INFO
	mov	dx, ss
	lea	bp, RP_PrintInfo
	call	CallSpoolPrintControlMF_CALL	; return RP_PrintInfo
	pop	bp

	mov	ax, RP_PrintInfo.PSR_layout.PL_paper
	and	ax, mask PLP_TYPE

	.leave
	ret
GetPageType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetEnvelopeOrientation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the orientation of the paper we're printing on.
		This is used for envelope printing so we'll know to
		rotate the printed output.

CALLED BY:	PrintAnAddress()
PASS:		nothing
RETURN:		ax - envelopeOrientation
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	6/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetEnvelopeOrientation	proc	near
	RP_PrintInfo	local	PageSizeReport
	uses	cx, dx,bp
	.enter
	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_PAPER_SIZE_INFO
	mov	dx, ss
	lea	bp, RP_PrintInfo
	call	CallSpoolPrintControlMF_CALL	; return RP_PrintInfo
	pop	bp

	mov	ax, RP_PrintInfo.PSR_layout.PL_envelope
	and	ax, mask PLE_ORIENTATION
	mov	cl, offset PLE_ORIENTATION
	shr	ax, cl
	.leave
	ret
GetEnvelopeOrientation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetLabelClipRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a clipping region so that the current record will
		be clipped to one label.

CALLED BY:	PrintAnAddress()
PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	6/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetLabelClipRegion	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	di, ds:[printGState]
	mov	si, PCT_REPLACE			; create a new clip region
	mov	ax, ds:[leftMargin]
	mov	bx, ds:[topMargin]
	mov	cx, ds:[printWidth]
	add	cx, ax
	mov	dx, ds:[printHeight]
	add	dx, bx
	call	GrSetClipRect			; the clip region matches
						; the label minus margins
	.leave
	ret
SetLabelClipRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CenterOnEnvelope
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the starting position for printing the
		envelope address on the center of an envelope.

CALLED BY:	PrintAnAddress()
PASS:		ds - dgroup
RETURN:		dx - beginning x position
		bx - beginning y position
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	6/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CenterOnEnvelope	proc	near
	.enter

	mov	dx, ds:[printWidth]
	mov	bx, ds:[printHeight]

	shr	dx, 1			
	shr	bx, 1			; dx, bx - center of envelope

	add	dx, ds:[leftMargin]
	add	bx, ds:[topMargin]

	.leave
	ret
CenterOnEnvelope	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintAnAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the text object in PrintAll format.

CALLED BY:	(INTERNAL) PrintAllOrPhones, PrintCurRecord

PASS:		printWidth - printable width
		printHeight - printable height
		curYPos - current y position

RETURN:		curYPos - updated

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
	Calculate the height of text object
	Do form feed if at the end of page
	Set paragraph and left margins 
	Set new size for the text object
	Move the text object to the right place
	Clip the text object
	Print the text object
	Update cuYPos

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	8/6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintAnAddress	proc	near

	; Set a new tab

	mov	dx, size VisTextSetTabParams	; dx - size of VTSTP
	sub	sp, size VisTextSetTabParams
	mov	bp, sp				; ss:bp - ptr to VTSTP
	mov	ss:[bp].VTSTP_range.VTR_start.low, 0	
	mov	ss:[bp].VTSTP_range.VTR_start.high, 0	
	mov	ss:[bp].VTSTP_range.VTR_end.low, TEXT_ADDRESS_PAST_END_LOW 
	mov	ss:[bp].VTSTP_range.VTR_end.high, TEXT_ADDRESS_PAST_END_HIGH 
	mov	cx, ds:[printWidth]
	shr	cx, 1				
	shr	cx, 1				; cx - tab position

	; multiply the pixel position by 8

	shl	cx, 1
	shl	cx, 1
	shl	cx, 1

	mov	ss:[bp].VTSTP_tab.T_position, cx	
	mov	ss:[bp].VTSTP_tab.T_grayScreen, (SDM_0 shl offset SDM_MASK)	
	clr	ax
	mov	ss:[bp].VTSTP_tab.T_lineWidth, al
	mov	ss:[bp].VTSTP_tab.T_lineSpacing, al
	mov	ss:[bp].VTSTP_tab.T_attr, (TL_NONE shl offset TA_LEADER) \
		or (TT_LEFT shl offset TA_TYPE)	; tab type
	mov	ss:[bp].VTSTP_tab.T_anchor, C_PERIOD
	mov	ax, MSG_VIS_TEXT_SET_TAB
	call	CallPrintTextObjectMF_CALL_MF_STACK	; set the tab
	add	sp, size VisTextSetTabParams		; restore sp

	; Set the left margin
	
	mov	dx, size VisTextSetMarginParams	; dx - size of VTSMP
	sub	sp, size VisTextSetMarginParams
	mov	bp, sp				; ss:bp - ptr to VTSMP
	mov	ss:[bp].VTSMP_range.VTR_start.low, 0	
	mov	ss:[bp].VTSMP_range.VTR_start.high, 0	
	mov	ss:[bp].VTSMP_range.VTR_end.low, TEXT_ADDRESS_PAST_END_LOW 
	mov	ss:[bp].VTSMP_range.VTR_end.high, TEXT_ADDRESS_PAST_END_HIGH 
	mov	ax, ds:[printWidth]		; ax - printable width
	shr	ax, 1
	shr	ax, 1				; divide AX by four

	; multiply the pixel position by 8

	shl	ax, 1
	shl	ax, 1
	shl	ax, 1

	mov	ss:[bp].VTSMP_position, ax	; set the text's indent level
	mov	ax, MSG_VIS_TEXT_SET_LEFT_MARGIN
	call	CallPrintTextObjectMF_CALL_MF_STACK	; set left margin
	add	sp, size VisTextSetMarginParams		; restore sp

	; Now tell the text object it's new dimmensions

	mov	cx, ds:[printWidth]		; cx - printable width
	mov	dx, ds:[printHeight]		; dx - printable height
	mov	ax, MSG_VIS_SET_SIZE
	call	CallPrintTextObjectMF_CALL

	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	call	CallPrintTextObjectMF_CALL

	; Calculate the height of text object

	mov	cx, ds:[printWidth]		; printable width => CX
	mov	dx, -1				; force calculation
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT
	call	CallPrintTextObjectMF_CALL	; dx - height of text.
	mov	ds:[addrHeight], dx		; save it
	add	dx, ds:[curYPos]		; dx - current height total

	call	GetPageType
	cmp	ax, PT_LABEL			; printing on labels?
	jne	notLabelPrinting		; jump if not

	call	SetLabelClipRegion		; print only on one label
	jmp	noPageBreak

notLabelPrinting:
	cmp	ds:[printHeight], dx		; are we at the end of page?
	jg	noPageBreak			; if not, skip
	tst	ds:[firstPage]
	jz	noPageBreak			; no break if first page
	call	PageBreak			; if so, send page break
noPageBreak:

	; First translate to 0,0
	
	mov	di, ds:[printGState]		; GState => DI
	call	GrSetNullTransform		; go back to 0,0

	; Now move it to the right position

	mov	dx, ds:[leftMargin]		; dx - x position
	mov	bx, ds:[curYPos]		; bx - y position
	call	GetPageType			; ax - PageType
	cmp	ax, PT_ENVELOPE
	jne	notEnvelope
	call	GetEnvelopeOrientation		; ax - EnvelopeOrientation
	mov	ds:[envelopeOrient], ax
	call	CenterOnEnvelope
notEnvelope:
	clr	cx				; no fractions
	clr	ax				; no fractions
	call	GrApplyTranslation		; perform the translation

	call	GetPageType
	cmp	ax, PT_ENVELOPE
	jne	notPortrait			; don't rotate if not envelope

	cmp	ds:[envelopeOrient], EO_LANDSCAPE
	je	notPortrait			; jmp if not landscape
	mov	dx, DEGREES_TO_ROTATE_ENVELOPE	; rotate 90 degrees
	clr	cx
	call	GrApplyRotation
notPortrait:

	; Now actually print
	
	mov	bp, ds:[printGState]		; GState => BP
	mov	cl, mask DF_PRINT
	mov	ax, MSG_VIS_DRAW
	call	CallPrintTextObjectMF_CALL

	; Now update the current y position

	mov	dx, ds:[addrHeight]
	add	ds:[curYPos], dx		
	ret
PrintAnAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPhoneNumbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the text string to text object in PrintPhones format

CALLED BY:	(INTERNAL) PrintAllOrPhones

PASS:		di - handle DB block to print

RETURN:		Text object contains the text to print

DESTROYED:	ax, bx, cx, dx, es, si, di, bp

PSEUDO CODE/STRATEGY:
	Copy the index field string
	For each phone entry
		add a tab character
		copy the string to text object 
		add a carriage return
	Next phone entry

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	8/6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPhoneNumbers	proc	near
	clr	ds:[firstPhone]			; 1st line of text indicator
	call	DBLockNO				
	mov	di, es:[di]			; open up current record

	; Copy the index field string to text object

	push	es, di
	clr	cx				; cx - null terminated string
if PZ_PCGEOS
	tst	es:[di].DBR_phoneticSize	; phonetic field is empty?
	jz	useIndex			; if so, use index field
	add	di, es:[di].DBR_toPhonetic 	; else, use phonetic field.
	jmp	common
useIndex:
endif
	add	di, size DB_Record	
PZ <common:									>
	mov	bp, di
	mov	dx, es				; dx:bp - pointer to string
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	CallPrintTextObjectMF_CALL	; copy text to text object
	pop	es, di

if PZ_PCGEOS
	mov	cx, es:[di].DBR_phoneticSize	; cx - # fo chars in phonetic
	tst	cx				; phonetic field is empty?
	jnz	gotSize				; if not, go ahead.
	mov	cx, es:[di].DBR_indexSize	; cx - # of chars in index field
gotSize:
else
	mov	cx, es:[di].DBR_indexSize	; cx - # of chars in index field
endif
	mov	ds:[indexSize], cx		; save it for later use

	; Now copy the phone entries to text object

	mov	dx, es:[di].DBR_noPhoneNo	; dx - number of phone numbers
	add	di, es:[di].DBR_toPhone		; es:di - ptr to phone entries
phoneLoop:
	push	dx
	tst	es:[di].PE_length		; is this number empty?
	je	next				; if so, check the next number
SBCS <	tst	{byte}es:[di].PE_strings	; is number NULL?	>
DBCS <	tst	{word}es:[di].PE_strings	; is number NULL?	>
	je	next				; if so, check the next number

	; Check to see if we are still on the 1st line of text
	; If we are, do not add a carriage return.

	tst	ds:[firstPhone]	
	je	skip				; do not add a carriage return

	; Add a carriage return between phone entries

	push	es, di
	mov	bp, offset CRString
	mov	dx, ds				; dx:bp - pointer to string
	clr	cx				; null terminated string
	mov	ax, MSG_VIS_TEXT_APPEND
	call	CallPrintTextObjectMF_CALL	; add a carriage return
	pop	es, di
skip:
	; Add a tab character 

	push	es, di
	mov	bp, offset TABString		; dx:bp - pointer to string
	mov	dx, ds
	clr	cx				; null terminated string
	mov	ax, MSG_VIS_TEXT_APPEND
	call	CallPrintTextObjectMF_CALL	; add a tab
	pop	es, di
 
	; Now, copy a phone entry to text object

	call	GetPhoneEntry			
	inc	ds:[firstPhone]			; update the 1st line indicator

	cmp	ds:[firstPhone], 1		; first line of text?
	jne	next2				; if not, just skip

	; If this is the 1st line of text, we need to see if it is going
	; to fit on one line

	clr	cx				; cx - use the entire string
	mov	ax, MSG_VIS_TEXT_GET_ONE_LINE_WIDTH
	call	CallPrintTextObjectMF_CALL	; calc width of text string
	mov	dx, ds:[printWidth]		; dx - printable width
	sub	dx, SPACE_BETWEEN_PHONE_NUMBER_COLUMNS	; room between columns
	shr	dx, 1				; divide it by two

	; Check to see if the text is going to fit on half of entire
	; document horizontally.  If not, add a CR after index field.

	cmp	cx, dx			
	jle	next2				; skip if it fits

	; move the cursor to the place to insert a carriage return

	mov	cx, ds:[indexSize]		; cx - # of chars in index 
	dec	cx				; don't count the CR
	mov	dx, cx
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	call	CallPrintTextObjectMF_CALL

	; Add a carriage return between the name and phone number

	push	es, di
	mov	bp, offset CRString
	mov	dx, ds				; dx:bp - pointer to string
	clr	cx				; null terminated string
	mov	ax, MSG_VIS_TEXT_REPLACE_SELECTION_PTR
	call	CallPrintTextObjectMF_CALL	; insert a carriage return
	pop	es, di
	jmp	next2
next:
SBCS <	add	di, es:[di].PE_length					>
DBCS <	mov	dx, es:[di].PE_length					>
DBCS <	shl	dx, 1							>
DBCS <	add	di, dx							>
	add	di, size PhoneEntry		; di - ptr to the next phone #
next2:
	pop	dx				; # of phones to be printed
	dec	dx				; are we done printing phone #s?
	LONG	jne	phoneLoop		; if not, print the next phone #
	call	DBUnlock			; unlock the current record
	ret
GetPhoneNumbers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintPhoneNumbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the record in PrintPhones format.

CALLED BY:	(INTERNAL) PrintAllOrPhones

PASS:		printWidth - printable width
		printHeight - printable height
		curYPos - current y position

RETURN:		curYPos - updated

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

PSEUDO CODE/STRATEGY:
	Calculate the height of the text
	If we are on column one 
		if we are at the end of page
			re-initialze some variables
		else go to SKIP
	Else 
		if we are at the end of page
			do a form feed
		else set left margin
  SKIP:
	Set a right-justified, dot-leading tab
	Set a new dimension for the text object
	Move it to the right place
	Clip the text object
	Print it!!!!
	Update curYPos

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	8/6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintPhoneNumbers	proc	near

	; Calculate the height of text and update curYPos

	mov	cx, ds:[printWidth]		; cx - printable width
	shr	cx, 1				; divide it by two
	mov	dx, -1				; force calculation
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT
	call	CallPrintTextObjectMF_CALL	; dx - height of text
	mov	ds:[addrHeight], dx		; save it
	add	dx, ds:[curYPos]		; dx - current height total

	call	GetPageType
	cmp	ax, PT_LABEL			; printing on labels?
	jne	notLabelPrinting		; jump if not

	call	SetLabelClipRegion		; print only on one label
	jmp	setATab

notLabelPrinting:
	cmp	ds:[printHeight], dx		; are we at the end of page?
	jg	setATab				; if not, skip to set a tab

	tst	ds:[columnNo]			; are we on column two?
	jne	newPage				; if so, do a form feed

	; Intialize some variables for column two

	mov	dx, ds:[topMargin]
	mov	ds:[curYPos], dx		; re-initialize y position
	inc	ds:[columnNo]			; re-initialize column variable
	jmp	setATab
newPage:
	call	PageBreak			; do a form feed
setATab:
	; Set a right-justified, dot-leading tab

	mov	dx, size VisTextSetTabParams	; dx - size of VTSTP
	sub	sp, size VisTextSetTabParams
	mov	bp, sp				; ss:bp - ptr to VTSTP
	mov	ss:[bp].VTSTP_range.VTR_start.low, 0	; beg of text
	mov	ss:[bp].VTSTP_range.VTR_start.high, 0	
	mov	ss:[bp].VTSTP_range.VTR_end.low, TEXT_ADDRESS_PAST_END_LOW 
	mov	ss:[bp].VTSTP_range.VTR_end.high, TEXT_ADDRESS_PAST_END_HIGH 
	mov	cx, ds:[printWidth]
	sub	cx, SPACE_BETWEEN_PHONE_NUMBER_COLUMNS
	shr	cx, 1				; cx - column one tab position

	; multiply the pixel position by 8

	shl	cx, 1
	shl	cx, 1
	shl	cx, 1

	mov	ss:[bp].VTSTP_tab.T_position, cx	
	mov	ss:[bp].VTSTP_tab.T_grayScreen, (SDM_0 shl offset SDM_MASK)	
	clr	ax
	mov	ss:[bp].VTSTP_tab.T_lineWidth, al
	mov	ss:[bp].VTSTP_tab.T_lineSpacing, al
	mov	ss:[bp].VTSTP_tab.T_attr, (TL_DOT shl offset TA_LEADER) \
		or (TT_RIGHT shl offset TA_TYPE)	; tab type
	mov	ss:[bp].VTSTP_tab.T_anchor, C_PERIOD
	mov	ax, MSG_VIS_TEXT_SET_TAB
	call	CallPrintTextObjectMF_CALL_MF_STACK	; set the tab
	add	sp, size VisTextSetTabParams	; restore sp

	; clear left margin
	
	mov	dx, size VisTextSetMarginParams	; dx - size of VTSMP
	sub	sp, size VisTextSetMarginParams
	mov	bp, sp				; ss:bp - ptr to VTSMP
	mov	ss:[bp].VTSMP_range.VTR_start.low, 0	; beg of text
	mov	ss:[bp].VTSMP_range.VTR_start.high, 0	
	mov	ss:[bp].VTSMP_range.VTR_end.low, TEXT_ADDRESS_PAST_END_LOW 
	mov	ss:[bp].VTSMP_range.VTR_end.high, TEXT_ADDRESS_PAST_END_HIGH 
	mov	ss:[bp].VTSMP_position, 0	; set the text's indent level
	mov	ax, MSG_VIS_TEXT_SET_LEFT_MARGIN
	call	CallPrintTextObjectMF_CALL_MF_STACK	; clear left margin
	add	sp, size VisTextSetMarginParams	; restore sp

	; Now tell the text object it's new dimmensions

	mov	cx, ds:[printWidth]		; cx - printable width
	shr	cx, 1
	mov	dx, ds:[printHeight]		; dx - printable height
	mov	ax, MSG_VIS_SET_SIZE
	call	CallPrintTextObject		; set the tab

	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	call	CallPrintTextObject		; set the tab

	; First translate to 0,0
	
	mov	di, ds:[printGState]		; di - GState
	call	GrSetDefaultTransform		; go back to 0,0

	; Now move it to the right position

	mov	dx, ds:[leftMargin]		; dx - x position
	tst	ds:[columnNo]			; are we on column two?
	je	colOne				; if not, skip
	mov	dx, ds:[printWidth]
	add	dx, ds:[leftMargin]
	add	dx, ds:[leftMargin]
	add	dx, SPACE_BETWEEN_PHONE_NUMBER_COLUMNS 
	shr	dx, 1				; dx - column two x position
colOne:
	mov	bx, ds:[curYPos]		; bx - y position
	clr	cx				; no fractions
	clr	ax				; no fractions
	call	GrApplyTranslation		; perform the translation

	; Now actually print
	
	mov	bp, ds:[printGState]		; GState => BP
	mov	cl, mask DF_PRINT
	mov	ax, MSG_VIS_DRAW
	call	CallPrintTextObjectMF_CALL	; set the tab

	; Now update the current y position

	mov	dx, ds:[addrHeight]
	add	ds:[curYPos], dx		
	ret
PrintPhoneNumbers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageBreak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send page break character to spooler.

CALLED BY:	UTILITY

PASS:		printGState - handle gState

RETURN:		curYPos, columnNo - updated

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	5/2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PageBreak	proc	near	uses	ax, bx, cx, dx, si, di
	.enter

	mov	di, ds:[printGState]	; di - gstate handle

	mov	al, PEC_FORM_FEED
	call	GrNewPage		; do form feed
	inc	ds:[pageCount]		; increment page counter

	test	ds:[printFlag], mask PF_LABELS	; are we printing labels?
	jne	exit			; if so, exit

	mov	dx, ds:[topMargin]
	mov	ds:[curYPos], dx	; re-initialize y position
	clr	ds:[columnNo] 		; re-initialize column variable
exit:
	.leave
	ret
PageBreak	endp

CallSpoolPrintControlMF_CALL	proc	near	uses	 bx, si, di
	.enter

	GetResourceHandleNS	RolPrintControl, bx
	mov	si, offset RolPrintControl
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
CallSpoolPrintControlMF_CALL	endp

if 0
	;; removed because it isn't called; probably useful though (witt)
CallSpoolPrintControlMF_STACK	proc	near	uses	 bx, si, di
	.enter
	GetResourceHandleNS	RolPrintControl, bx
	mov	si, offset RolPrintControl
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
CallSpoolPrintControlMF_STACK	endp
endif

CallSpoolPrintControl	proc	near	uses 	bx, si, di
	.enter

	GetResourceHandleNS	RolPrintControl, bx
	mov	si, offset RolPrintControl
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
CallSpoolPrintControl	endp

CallPrintTextObject	proc	near	uses	 bx, si, di
	.enter

	GetResourceHandleNS	PrintTextEdit, bx
	mov	si, offset PrintTextEdit
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
CallPrintTextObject	endp

CallPrintTextObjectMF_STACK	proc	near	uses	 bx, si, di
	.enter

	GetResourceHandleNS	PrintTextEdit, bx
	mov	si, offset PrintTextEdit
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
CallPrintTextObjectMF_STACK	endp

CallPrintTextObjectMF_CALL_MF_STACK	proc	near	uses	 bx, si, di
	.enter

	GetResourceHandleNS	PrintTextEdit, bx
	mov	si, offset PrintTextEdit
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage

	.leave
	ret
CallPrintTextObjectMF_CALL_MF_STACK	endp

CallPrintTextObjectMF_CALL	proc	near	uses	 bx, si, di
	.enter

	GetResourceHandleNS	PrintTextEdit, bx
	mov	si, offset PrintTextEdit
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
CallPrintTextObjectMF_CALL	endp

ClearAllTabs	proc	near	uses	dx, bp
	.enter

	; clear all previously set tabs

	mov	dx, size VisTextClearAllTabsParams	; dx - size of VTCATP
	sub	sp, size VisTextClearAllTabsParams
	mov	bp, sp					; ss:bp - ptr to VTCATP
	mov	ss:[bp].VTCATP_range.VTR_start.low, 0	; beg of text
	mov	ss:[bp].VTCATP_range.VTR_start.high, 0	
	mov	ss:[bp].VTCATP_range.VTR_end.low, TEXT_ADDRESS_PAST_END_LOW 
	mov	ss:[bp].VTCATP_range.VTR_end.high, TEXT_ADDRESS_PAST_END_HIGH 
	mov	ax, MSG_VIS_TEXT_CLEAR_ALL_TABS
	call	CallPrintTextObjectMF_STACK		; clear all tabs
	add	sp, size VisTextClearAllTabsParams	; restore sp

	.leave
	ret
ClearAllTabs	endp

Print	ends
