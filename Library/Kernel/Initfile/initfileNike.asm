COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		initfileNike.asm

AUTHOR:		Muhammad Mohsin Hussain, Sep 28, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	9/28/94   	Initial revision


DESCRIPTION:
	Nike uses BatteryBacked RAM to store the .INI file
	This file has all the Nike BatteryBackedRam Routines to
	Load/Save the .ini file for the kernel.


	$Id: initfileNike.asm,v 1.1 97/04/05 01:18:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kinit	segment	resource






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRWriteInitFileHack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Basically reads a table entry and writes to the Init file

CALLED BY:	BBRReadRamWriteInitFile
PASS:		es:0	pointer to the BBR locked down block
		cs:di	pointer to table entry.
		ds	(cs) segment of category
		cx	(cs) seg of key
RETURN:		carryset on error else carry clear
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Don't change the hack table because this code depends on the
	order of entries in the table	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRWriteInitFileHack	proc	near
	uses	si, dx, di
	.enter
	mov	si, cs:[di].BBR_category
	mov	dx, cs:[di].BBR_key
	;
	; The first entry adds a line of execOnStartup for clock app
	;	
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitOffset
	call	BBRGetBoolean	
	tst	bx
	jz	next
	;
	; bx = 1 (true), write the execOnStartup to Initfile
	;
	push	es, di
	segmov	es, cs
	mov	di, cs:[di].BBR_value		; get the handle of the string
	call	InitFileWriteStringSection	; write to init file and we
	pop	es, di				; are done

next:

if (0)	; We don't need lights out launcher anymore.  Screen saver is started
	; by NikeMenu.

	;
	; This adds an execOnStartup line for the Lights Out Launcher only
	; if the Dancing lines is the screen saver.
	;
 	add	di, size BatteryBackedRamTableEntry
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitOffset
	call	BBRGetBoolean			; Screen saver on?
	tst	bx				; non-zero => YES
	jz	done
 	add	di, size BatteryBackedRamTableEntry

;
; This section doesn't seem necessary... Why not have all
; types of savers execOnStartup if the on/off boolean is on?
; Why single out dancing lines?  
;
if 0
	;
 	; Now check if Dancing lines is the selected saver
	;	
	mov	al, cs:[di].BBR_bitWidth
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitOffset
	call	BBRGetNumericValue	
	tst	bx	; 0 corresponds to dancing lines entry
	jnz	done
endif	
	;
	; write the execOnStartup to Initfile
	;
 	add	di, size BatteryBackedRamTableEntry
	mov	si, cs:[di].BBR_category
	mov	dx, cs:[di].BBR_key

	push	es, di
	segmov	es, cs
	mov	di, cs:[di].BBR_value		; get the handle of the string
	call	InitFileWriteStringSection	; write to init file and we
	pop	es, di				; are done

done:
endif	; if (0)

	.leave
	ret
BBRWriteInitFileHack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRReadRamWriteInitFileEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Basically reads a table entry and writes to the ini file

CALLED BY:	BBRReadRamWriteInitFile
PASS:		es:0	pointer to the BBR locked down block
		cs:di	pointer to table entry.
		ds:si	category
		cx:dx	key
RETURN:		carryset on error else carry clear
DESTROYED:	ax,bx,dx,si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BBRReadRamWriteInitFileEntry	proc	near
	uses	bp, di	
	.enter
	Assert	urange 	cs:[di].BBR_byteLocation, 0, BBR_SIZE -1
	;
	; See what type the entry is and jmp to appropriate label
	;
	mov	bl, cs:[di].BBR_type
	clr	bh
	jmp	cs:[bbrTypeTable][bx]		
	; type is either numeric or numericWord
caseNumericInit:
	;
	; Assuming that max # we have to deal with is one word long
	;
	mov	ah, bl	;save type in ah
	mov	al, cs:[di].BBR_bitWidth
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitOffset
	cmp	ah, BBR_NUMERIC
	je	caseNumeric
caseNumericWord::
	push	cx	; save these 2 regs for later
	push	ax
	call	InitFileReadInteger	; don't destroy the value but
	jnc	axValid			; or the value
	clr	ax	
axValid:
	mov_tr	cx, ax
	pop	ax
	mov	ah, cs:[di].BBR_tableLength
	mov	bp, cs:[di].BBR_value
	call	BBRGetNumericWordValue
	pop	cx
	jmp	caseNumCommon
caseNumeric:
	call	BBRGetNumericValue
caseNumCommon:
	mov	bp, bx	; Put value in bp	
	call	InitFileWriteInteger
	jmp	done
caseString:
	;   call the BBR string routine to do the job
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitWidth
	call	BBRWriteStringToInitFile
	jmp	done
caseStringSection:
	call	BBRWriteStringSectionToInitFile
	jmp	done
caseStruct:
	call	BBRWriteStructToInitFile
	jmp	done
caseTable:
	;
	; Assuming that max # we have to deal with is one word long
	; Atable is the same as a numeric number except that the # is
	; the index in the table
	;
	mov	al, cs:[di].BBR_bitWidth
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitOffset
	call	BBRGetNumericValue
	mov	bh, cs:[di].BBR_tableLength
	cmp	bl, bh 
	jge	error
	push	di, es
	mov	di, cs:[di].BBR_value
	call	BBRFindEntryFromIndex
	;
	; We have the offset of the string; write to init file
	; es:di point to string
	;
	segmov	es, cs
	call	InitFileWriteString
	pop	di, es
	jmp	done
caseBoolean:
	;
	; In case of bool we assume it only has one bit (0/1)
	;	
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitOffset
	call	BBRGetBoolean
	mov_tr	ax, bx			; mov 0 or 1 in ax
	call	InitFileWriteBoolean
done:
	clc
exit:
	.leave
	Destroy	ax,bx,dx,si
	ret
error:
	stc
	jmp	exit

bbrTypeTable	nptr	\
	offset	caseNumericInit,
	offset  caseBoolean,		; caseNumeric
	offset	caseString,
	offset	caseStringSection,
	offset	caseTable,
	offset  caseNumericInit,	; caseNumericWord
	offset  caseStruct

BBRReadRamWriteInitFileEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRFindEntryFromIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the offset of the table entry whose index is passed

CALLED BY:	BBRWriteTableTypeEntry
PASS:		bl	index of table
		di	offset	of table
RETURN:		di	offset of the table element whose # is passed
		di	zero if # is out of range for table
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRFindEntryFromIndex	proc	near
	;
	; offset of the element whose index is passed is detemined by
	; mult by 2 cos all tables are tables of nptr's (2 bytes) 
	;
	clr	bh
	shl	bx, 1
	mov	di, cs:[di][bx]
exit::
	ret
BBRFindEntryFromIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRGetMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the word mask.

CALLED BY:	BBRGetNumericValue
PASS:		al	bitWidth
		ah	bitOffset
RETURN:		ax	bit mask
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/ 4/94    	Initial version
	Joon	5/11/95		Rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRGetMask	proc	near
	uses	cx
	.enter
	;
	; Shift left by # of bit offsets
	; Shift left by 16 - ( offset + width ) and shift back
	;
	mov	cl, ah		; cl = bitOffset
	mov	ch, al		; ch = bitWidth
	mov	ax, 1111111111111111b
	shl	ax, cl		; zero out low bits
	add	ch, cl		; ch = bitWidth + bitOffset
	mov	cl, 16
	sub	cl, ch		; cl = 16 - (bitWidth + bitOffset)
EC <	ERROR_C	-1		; should not be negative		>
	shl	ax, cl		; zero out high bits
	shr	ax, cl		; shift back
	.leave
	ret
BBRGetMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRGetNumericValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the numeric value in the BBR at a given word location

CALLED BY:	BBRReadRamWriteInitFileEntry	
PASS:		es:0	BBR
		al	bitWidth
		bl	wordLocation
		bh 	bitOffset
RETURN:		bx	numeric value
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/ 4/94    	Initial version
	Joon	5/11/95		Rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRGetNumericValue	proc	near
	uses	ax, cx
	.enter
	;
	; Assuming that max # we have to deal with is one word long
	;
	mov	cl, bh			; cl = bitOffset
	mov	ah, bh			; ah = bitOffset
	clr	bh
	mov	bx, es:[bx]		; bx = BBR word
	call	BBRGetMask		; ax = mask
	andnf	bx, ax
	shr	bx, cl

	.leave
	ret
BBRGetNumericValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRGetNumericWordValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the numeric value in the BBR at a given byte location
		and converts to a word /byte value according to the NTW_<type>
		passed.

CALLED BY:	BBRReadRamWriteInitFileEntry	
PASS:		
		al	bitWidth
		ah	NTW_<type>
		bl	byteLocation
		bh 	bitOffset
		bp	BBR_value
		cx	 Orignal value in .ini , 0 if none
RETURN:		bx	numeric value
DESTROYED:	ax, cx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRGetNumericWordValue	proc	near
	.enter
	;
	; Get the numeric value first
	;
	call	BBRGetNumericValue
	cmp	ah, NWT_MULTIPLE
	je	caseMult
	xchg	cx, bp
	dec	cx
	shl	bx, cl	;mov the lowest bits to the left value # times
			;to make them most significant bits
	cmp	ah, NWT_HIGH_WORD
	je	exit
caseBitWord::
	;
	; Make the bits higher than our boolean bit zero and we are done
	;
	inc	cx 
	mov	ax, NUM_BITS_IN_WORD
	sub	ax, cx
	mov_tr	cx, ax
	shl	bx, cl		; zero out the left insignificant bits
	shr	bx, cl
	ornf	bx, bp	; or with the orignal value 
	jmp	exit
caseMult:
	;
	; We know that both the numeric value and BBR_value can fit in
	; 1-byte from table, simplify multiplication
	;
	xchg	bx, bp	; put numeric value in bp and then in ax
	mov_tr	ax, bp
	mul	bl
	mov_tr	bx, ax
exit:
	.leave
	Destroy	ax, cx, bp
	ret
BBRGetNumericWordValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRWriteStringToInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a string to Init file by passing it on the stack.

CALLED BY:	BBRReadRamWriteInitFileEntry
PASS:		es:0	BBR
		cx:dx	Key
		ds:si   Category
		bl 	byteLocation
		bh 	bitWidth
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
***NOTE***	Potential Bug in the code; string can be null terminated if less
		than max length: Don't copy all max length chars on stack.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRWriteStringToInitFile	proc	near
	uses	ax, di, bp
	.enter
	;
	; Divide the # of bits by 3 to get # of chars and make enough space
	; on stack: ss:sp points to buffer
	;
	push	es
	shr 	bh, 1
	shr 	bh, 1
	shr 	bh, 1
	mov_tr	ax, cx		; save Key segment 
	mov	bp, sp		; save old stack value

	clr	ch
	mov	cl, bh
	inc	cx
	sub	sp, cx		; room for #chars+1 bytes 
DBCS<	sub	sp, cx						>	
	mov	di, sp		; initialize di
	push	ds, si		; category passed in
	
	dec	cx
	push	cx
	;
	; Load the string on the stack
	; ds:si pts to source string now and es:di to dest
	; 

	clr	bh		; bx->si has the byteLocation
	mov	si, bx   
	segmov	ds, es
	segmov	es, ss
	mov_tr	bx, ax		; save Key segment
	;
	; Copy string on stack using DBCS stuff and null terminate it
	; 
	LocalCopyNString
	LocalLoadChar	ax, C_NULL
	LocalPutChar	esdi, ax

	pop	ax		; # of chars on stack
	inc	ax
	sub	di, ax
	mov	cx, bx
	pop	ds, si
	call	InitFileWriteString
	mov	sp, bp	; put sp back
	pop	es
	.leave
	ret
BBRWriteStringToInitFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRWriteStringSectionToInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a StringSection to the InitFile using the table
NOTE:	I'm assuming that the bitwidth is eq to the # of elts in the table

CALLED BY:	BBRReadRamWriteInitFileEntry
PASS:		es:0	BBR
		cx:dx	Key
		ds:si   Category
		cs:di	ptr to tableEntry
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRWriteStringSectionToInitFile	proc	near
	uses	ax, bx, bp
	.enter
	;CheckHack< cs:[di].BBR_tableLength eq  cs:[di].BBR_bitWidth >
	;
	; First get the numric value 
	;
	mov	al, cs:[di].BBR_bitWidth
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitOffset
	call	BBRGetNumericValue	; bl has the bits
	tst	bx
	jz	exit
	;
	; see which bits are on and write those table entries to InitFile
	;
	push	es, di
	segmov	es, cs			; mov cs into es for ptr ro
					; correct tableEntry for InitFileWrite
	mov	al, cs:[di].BBR_tableLength
	clr	ah
	mov_tr	bp, ax
	mov	di, cs:[di].BBR_value	; mov table offset in di
writeLoop:
	;
	; We look at each bit at a time , see if it is on. If yes we
	; write the corresponding tableEntry to InitFile else we check
	; the next one until we have gone through the whole table
	;
	dec	bp		; see if bit is ON/OFF
	xchg	bp, cx
	mov	ax, 1
	shl 	ax, cl
	andnf	ax, bx
	xchg	bp, cx
	tst	ax
	jz	bitOff
	;
	; Now bit is ON, mult the entry# by 2 to offset correctly
	;
	push	di
	shl	bp, 1
	mov	di, cs:[di][bp]
	shr	bp, 1		; restore table index 
	call	InitFileWriteStringSection
	pop	di
bitOff:
	tst	bp
	jnz	writeLoop
	pop	es, di
exit:
	.leave
	ret
BBRWriteStringSectionToInitFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRWriteStructToInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a Struct to the InitFile using the passed struct 

CALLED BY:	BBRReadRamWriteInitFileEntry
PASS:		es:0	BBR
		cx:dx	Key
		ds:si   Category
		cs:di	ptr to tableEntry
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Note : This is a very specific routine for a special case.
		It also Assumes that this key exists in the InitFile, for NIKE
		this is True

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRWriteStructToInitFile	proc	near
scrollBar	local	ScrollBarStruct
	uses	ax, bx	
	.enter
	;
	; First get the numric value 
	;
	mov	al, cs:[di].BBR_bitWidth
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitOffset
	call	BBRGetNumericValue	; bx has the bits

	push	cx
	mov	ax, bx
	mov	cl, offset GVCA_SHOW_VERTICAL
	shl	ax, cl
	pop	cx
	;
	; Read the data in the local variable 
	;
	push	es, di		; save bbr seg & tableEntry offset
	segmov	es, ss
	lea	di, ss:[scrollBar]
	push	cx, bp
	mov	bp, size ScrollBarStruct
	call	InitFileReadData
	pop	cx, bp
	;
	; OR the scrollbar bits with original and write to InitFile   
	;
	mov	bx, not (mask GVCA_SHOW_HORIZONTAL or mask GVCA_SHOW_VERTICAL)
	andnf	ss:scrollBar.attrs, bx
	ornf	ss:scrollBar.attrs, ax
	mov	bx, bp		
	mov	bp, size ScrollBarStruct
	call	InitFileWriteData
	mov	bp, bx		; restore base ptr
	pop	es, di
	.leave
	ret
BBRWriteStructToInitFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRGetBoolean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the requested bit from the BBR

CALLED BY:	BBRReadRamWriteInitFileEntry
PASS:		es:0	BBR
		bl	byte location
		bh	bit offset
RETURN:		bx	0	False
		bx	1	True
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRGetBoolean	proc	near
	uses	cx
	.enter
	;
	;  Load the byte in bl
	;
	mov	cx, bx
	clr	bh
	mov	bx, es:[bx]
	mov	cl, ch	; offset in cl	
	;
	; Extract the bh'th bit from bl
	;
	mov	ch, 1	; Now ch is 00000001 
	shl	ch, cl
	and	bl, ch
	jz	false
true::
	mov	bx,1
	jmp	done
false:
	clr	bx
done:
	.leave
	ret
BBRGetBoolean	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRReadInitFileWriteRamEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Basically reads a table entry, then reads
		corresponding InitFile entry and writes to buffer

CALLED BY:	BBRReadInitFileWriteRam
PASS:		es:0	pointer to the BBR locked down block
		cs:di	poiter to table entry.
		cx:dx 	key 
		ds:si 	category
RETURN:		carryset on error else carry clear
DESTROYED:	ax,bx,dx,si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRReadInitFileWriteRamEntry	proc	near
	uses	di	
	.enter
	Assert	urange 	cs:[di].BBR_byteLocation, 0, BBR_SIZE -1
	;
	; See what type the entry is and jmp to appropriate label
	;
	mov	bl, cs:[di].BBR_type
	clr	bh
	jmp	cs:[bbrTypeTable1][bx]		
	; type is either numeric or numericWord
caseNumericInit:
	;
	; Assuming that max # we have to deal with is one word long
	;
	call	InitFileReadInteger
	jc	noMatchNumber
	cmp	bl, BBR_NUMERIC
	je 	caseNumeric
caseNumericWord::
	mov	bl, cs:[di].BBR_tableLength
	mov	dx, cs:[di].BBR_value
	call	BBRSetNumericWordValue 	; put in ax
caseNumeric:
	mov	dl, cs:[di].BBR_bitWidth
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitOffset
	call	BBRSetNumericValue
noMatchNumber:
	jmp	done
caseTable:
	;
	; Assuming that max # we have to deal with is one word long
	; A table is the same as a numeric number except that the # is
	; the index in the table
	;
	push	bp, cx				; save bp
	clr	bp				; always allocate
	call	InitFileReadString
	jc	noMatchTable
	mov	bp, cs:[di].BBR_value
	call	BBRFindIndexFromEntry
	jc	noMatchTable

	mov	dl, cs:[di].BBR_bitWidth
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitOffset
	call	BBRSetNumericValue

noMatchTable:
	pop	bp, cx
	jmp	done
caseBoolean:
	;
	; In case of bool we store it as only one bit (0/1)
	;
	call	InitFileReadBoolean
	jc	noMatchBool
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitOffset
	call	BBRSetBoolean
noMatchBool:
	jmp	done
caseStringSection:
	call	BBRWriteStringSectionToRam
	jmp	done
caseStruct:
	call	BBRWriteStructToRam
	jmp	done
caseString:
	;
	; Read string and get string in a buffer 
	;
	push	bp, cx				; save bp
	clr	bp				; always allocate
	call	InitFileReadString
	jc	noMatchStr
	mov	al, cs:[di].BBR_byteLocation
	mov	ah, cs:[di].BBR_bitWidth
	call	BBRWriteStringToRam
noMatchStr:
	pop	bp, cx
done:
	clc
exit:
	.leave
	Destroy	ax, bx, dx, si
	ret
error::
	stc
	jmp	exit


bbrTypeTable1	nptr	\
	offset	caseNumericInit,
	offset  caseBoolean,		; caseNumeric
	offset	caseString,
	offset	caseStringSection,
	offset	caseTable,
	offset  caseNumericInit,	; caseNumericWord
	offset  caseStruct

BBRReadInitFileWriteRamEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRSetNumericValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the numeric value in the corresponding bits/ byte
		location in the BBR 

CALLED BY:	BBBReadWriteInitFileEntry
PASS:		es:0	block to write 
		bl	word location
		bh	bit offset
		dl	bit width
		ax	integer value
RETURN:		nothing
DESTROYED:	ax, bx, si, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRSetNumericValue	proc	near
	uses	cx
	.enter
	;
	; Get the bit mask
	;
	xchg	ax, dx			; al = bitWidth, dx = value
	mov	ah, bh			; ah = bitOffset
	call	BBRGetMask		; ax = mask
	;
	; Load the byte from buffer
	;
	mov	cl, bh			; cl = bitOffset
	clr	bh
	mov 	si, {word}es:[bx]	; si = BBR word
	;
	; mask out the old numeric value
	;
	not	ax			; ax = ~mask
	andnf	si, ax			; si = masked BBR word
	not	ax
	;
	; Put the numeric value in the buffer
	;
	shl	dx, cl			; dx = value shl bitOffset
	andnf	dx, ax			; dx = masked (value shl bitOffset)
	ornf	si, dx			; combine value and BBR word
	mov	{word}es:[bx], si

	.leave
	ret
BBRSetNumericValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRSetNumericWordValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transforms the integer value according to the
		NWT_<type> and returns the integer to be stored in BBR

CALLED BY:	BBBReadWriteInitFileEntry
PASS:		dx	BBR_value
		bl	NWT_<type>
		ax	integer value
RETURN:		ax	integer value to store
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRSetNumericWordValue	proc	near
	.enter
	;
	; Make the significant bits to be least significant
	;
	cmp	bl, NWT_MULTIPLE
	je	caseMult
caseBitHighWord::
	xchg	cx, dx	; save cx, use cx and restore cx back
	dec	cx
	shr	ax, cl
	inc	cx
	xchg	cx, dx
	jmp	exit
caseMult:
	div	dl	; divide the number by the multiple i.e
	tst	ah	; BBR_value to store in the ini
	jnz	error
	clr	ah	; ax has the number%BBR_value
exit:	
	.leave
	ret
error:
	clr	ah
	jmp	exit
BBRSetNumericWordValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRWriteStringToRam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the string in the bytes corresponding to the
		entry's allocated bytes in the BBR

CALLED BY:	BBBReadWriteInitFileEntry
PASS:		es:0	block to write 
		bx	buffer in which string is stored
		al	byte location
		ah	bit width
RETURN:		Carry set if error else carry clear
DESTROYED:	ax, bx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Make sure the size of buffer is <= to bit width
		write to buffer Ram and delete the string buffer 
		after done 
	Note : Max length of DBCS is 256 bits cos bitwidth is a byte val
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRWriteStringToRam	proc	near
	uses	cx, ds, dx
	.enter
	;
	; Lock the block and find the length of the string
	;
	push	es
	mov_tr	dx, ax	; save ax
	call	MemLock
	mov_tr	es, ax
	clr	di
	call	LocalStringLength
	;
	; If length > bitwidth then take the first bitwidth chars
	; 
	mov	ax, dx	; restore ax
	mov	ch, cl	; mov length to ch
	mov	cl , 3	
	shr	ah, cl	; get # of bytes by div by 8( bits)	
DBCS<	shr	ah, cl							>
	mov	cl, ch
	clr	ch
	cmp	ah, cl
	jl	extraChars
	jmp	moveChars
extraChars:
	mov	cl, ah		; cx has the # of bytes to copy
moveChars:
	
	;
	; Copy the characters using DBCS routines if num chars < #
	; chars allowed null terminate string
	;
	segmov	ds, es
	clr	dh
	pop	es
	clr	si		; ds:si is the source now
	mov	di, dx		; es:di is the target string
DBCS<	shr	cl, 1		; change # bytes to # of DBCS chars	>
	mov	al, cl		; save cl for later
	LocalCopyNString
	cmp	al, ah		; compare # of chars written and max # chars
	je	done
	LocalLoadChar 	ax, C_NULL
	Assert	fptr, esdi
	LocalPutChar	esdi, ax
done:
	call	MemFree
	Destroy	ax, si, di
	.leave
	ret
BBRWriteStringToRam	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRWriteStructToRam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes one's in the bits corresponding to the entry's
		allocated bits ( in the BBR ) for the struct entries which
		need to be stored

CALLED BY:	BBBReadWriteInitFileEntry
PASS:		es:0	block to write 
		cs:di	ptr  to TableEntry
		cx:dx	key
		ds:si	Category
RETURN:		Carry set if error else carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRWriteStructToRam	proc	near
scrollBar	local	ScrollBarStruct
	uses	ax, bx, cx, dx, si
	.enter
	;
	; Read the data in the local variable. 
	;
	push	es, di
	segmov	es, ss
	lea	di, ss:[scrollBar]
	push	bp
	mov	bp, size ScrollBarStruct
	call	InitFileReadData
	pop	bp
	pop	es, di
	;
	; Get the set bits
	;
	mov	ax, ss:scrollBar.attrs
	and	ax, mask GVCA_SHOW_HORIZONTAL or mask GVCA_SHOW_VERTICAL
	mov	cl, offset GVCA_SHOW_VERTICAL
	shr	ax, cl
	;
	;    ax has the numeric value, so set it in BBRam
	;
	mov	dl, cs:[di].BBR_bitWidth
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitOffset
	call	BBRSetNumericValue
	.leave
	ret
BBRWriteStructToRam	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRWriteStringSectionToRam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes one's in the bits corresponding to the entry's
		allocated bits ( in the BBR ) for the strings which
		exists.

CALLED BY:	BBBReadWriteInitFileEntry
PASS:		es:0	block to write 
		cs:di	ptr  to BatteryBackedRamTableEntry
		cx:dx	key
		ds:si	Category
RETURN:		Carry set if error else carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRWriteStringSectionToRam	proc	near
maskValidEntries	local	word
	uses	ax,bx,dx,si
	.enter
	;
	; Read string and get string in a buffer 
	;
	clr	ax, ss:maskValidEntries
readLoop:
	push	cx
	push	bp
	clr	bp			; always allocate
	call	InitFileReadStringSection
	jc	done
	inc	ax
	mov	cx, ax		;save ax in cx
	mov	bp, cs:[di].BBR_value
	call	BBRFindIndexFromEntry
	jc	noMatch	
	;
	; set the bit corresponding to the index (ax) to 1
	;
	xchg	ax, cx			; restore the counter back and put
					; Index in cx  
	pop	bp
	mov	bx, 1
	shl	bx, cl	
	ornf	ss:maskValidEntries, bx
	pop	cx
	jmp	readLoop
noMatch:		; go through the loop again looking for next entry
	pop	bp
	pop	cx
	jmp	readLoop
done:
	pop	bp
	pop	cx
	mov	ax, ss:maskValidEntries
	mov	dl, cs:[di].BBR_bitWidth
	mov	bl, cs:[di].BBR_byteLocation
	mov	bh, cs:[di].BBR_bitOffset
	call	BBRSetNumericValue	; destroys si		
exit::
	.leave
	ret
BBRWriteStringSectionToRam	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRFindIndexFromEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the index of the entry passed, in the table
		
CALLED BY:	Numerous BBR routines
PASS:		bx	block handle of string  buffer
		cs:bp	segmant plus offset of Table ( BBR_value )
RETURN:		ax 	index of string
		carry clear if match found else carry set
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRFindIndexFromEntry	proc	near
	uses	cx, si, di, bp, es, ds
	.enter
	;
	; Lock the string that we read in from the init file and
	; compare it against the entries in the table.
	push	bx
 	call	MemLock
	mov_tr	ds, ax		; source string ds:si
	segmov	es, cs
	clr	ax, si, cx
strCmpLoop:
	mov	di, es:[bp]
	call	LocalCmpStringsNoSpaceCase
	jz	matchFound
	inc	ax
	add	bp, size nptr
	cmp	{ word } es:[bp], END_OF_TABLE
	jne	strCmpLoop
noMatch::
EC <	WARNING -1 >
   	stc
	jmp	done
matchFound:
	clc	
done:
	pop	bx
	pushf
	call	MemFree
	popf

	.leave
	ret
BBRFindIndexFromEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BBRSetBoolean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets 0/1 crresponding to the entry's allocated bit in the
		BBR file.
CALLED BY:	BBBReadWriteInitFileEntry
PASS:		es:0	block to write 
		ax	0 	FALSE
			ffff 	TRUE
		bl	byte location
		bh	bit offset
RETURN:		nothing
DESTROYED:	ax, bx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BBRSetBoolean	proc	near
	uses	cx
	.enter
	;
	; Load the bx 'th byte
	;	
	mov	cl, bh	;offset in dl
	clr	bh
	mov	si, bx	; save byte location in si
	mov	{ byte } bl, es:[si]
	;
	; Clear the bit
	;
	mov	ch, 1
	shl	ch, cl
	not	ch
	andnf	bl, ch
	;
	;  load 0/1 in ax
	;
	tst	ax
	jz	done
	;
	; Extract the bh'th bit from bl
	;
	mov	ax, 1
	shl	al, cl
	ornf	bl, al
done:
	mov	{ byte } es:[si], bl
	.leave
	ret
BBRSetBoolean	endp

kinit	ends
