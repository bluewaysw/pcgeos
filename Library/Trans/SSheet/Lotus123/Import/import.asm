COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Lotus123 Spreadsheet Translation Library
FILE:		import.asm

AUTHOR:		Cheng, 10/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial revision

DESCRIPTION:
		
	$Id: import.asm,v 1.1 97/04/07 11:41:45 newdeal Exp $


-------------------------------------------------------------------------------@


COMMENT @---------------------------------------------------------------------

FUNCTION:	TransGetFormat

SYNOPSIS:	Determines if the file is of Lotus123 format.	

CALLED BY:	IMPEX (HandleNoIdeaFormat)
PASS:		si	- file handle (open for read)	
RETURN:		ax	- TransError (0 = no error)
		cx	- format number if valid format
			  or NO_IDEA_FORMAT if not

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/24/92		Initial version

-----------------------------------------------------------------------------@

TGFLotusFileHeader	struc
	TGFLFH_bof		word
	TGFLFH_bofSize		word
	TGFLFH_formatVersion	word
	TGFLFH_extraWord1	word
TGFLotusFileHeader	ends

TransGetFormat	proc	far	uses	bx,dx,ds
	locals	local	TGFLotusFileHeader
	.enter

	segmov	ds,ss,ax
	lea	dx, locals
	clr	al				; FileOpen flags
	mov	bx, si				; bx <- file han
	mov	cx, size TGFLotusFileHeader	; specify num bytes
	call	FileRead
	jc	noIdea

	;
	; check to see if this is a Lotus file
	;
	cmp	locals.TGFLFH_bof, 0
	jne	noIdea
	cmp	locals.TGFLFH_bofSize, 2
if DBCS_PCGEOS	;1994-12-09(Fri)TOK ----------------
	jne	noIdea
	cmp	locals.TGFLFH_formatVersion, 0601h
	mov	cx, 0
	je	done
else	;----------------
	jne	checkVer3
	cmp	locals.TGFLFH_formatVersion, 0404h
	jl	noIdea
	mov	cx, 0
	je	done				; = 0404
	cmp	locals.TGFLFH_formatVersion, 0406h
	jl	done				; = 0405
	jg	noIdea

	mov	cx, 1				; version 2.0 - 2.2
	jmp	short done

checkVer3:
	cmp     locals.TGFLFH_bofSize, 1ah
	jne	noIdea
	cmp     locals.TGFLFH_formatVersion, 1000h
	jne	noIdea
	cmp     locals.TGFLFH_extraWord1, 4
	jne	noIdea

	mov	cx, 2				; version 3
	jmp	short done
endif	;-----------------
noIdea:
	mov	cx, NO_IDEA_FORMAT

done:
	clr	ax
	.leave
	ret
TransGetFormat	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	Import

DESCRIPTION:	Create a clipboard item for the import data.

CALLED BY:	EXTERNAL (Impex)

PASS:		ds:si - ImportFrame

RETURN:		ax - TransError or 0
		bx - handle of error msg if ax = TE_CUSTOM
			else clipboardFormat = CIF_SPREADSHEET
		dx:cx - VM chain containing transfer format
		si - ManufacturerID
DESTROYED:	ds,es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
    ImportFrame	struct
	IF_formatNumber		word		; number of format to be used
	IF_importOptions	hptr		; block handle of import
						;  options specific to
						;  translation library
						;  (0 for default)
	IF_transferVMFile	word		; handle of VM file in which
						;  to allocate transfer item
	IF_sourceFile		hptr		; handle of source file
    ImportFrame	ends

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

TransImport	proc	far	uses	di,si
	locals		local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter

	;
	; for that extra feeling of security
	;
EC<	mov	locals.ISF_signature1, IMPORT_STACK_FRAME_SIG1 >
EC<	mov	locals.ISF_signature2, IMPORT_STACK_FRAME_SIG2 >
	mov	locals.ISF_endRow, -1
	mov	locals.ISF_endCol, -1

	;
	; copy over the info from ImportFrame
	;
	mov	ax, ds:[si].IF_formatNumber
	mov	locals.ISF_formatNumber, ax
	mov	ax, ds:[si].IF_importOptions
	mov	locals.ISF_importOptions, ax

	mov	bx, ds:[si].IF_transferVMFile
	clr	ax,cx				; source id <- 0
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaInitForStorage
	pop	bp

	mov	bx, ds:[si].IF_sourceFile
	mov	locals.ISF_sourceFile, bx

	call	InputCacheAttach		; bx <- cache handle, es dest
	mov	locals.ISF_inputCacheHan, bx

processLoop:
	call	ImportCallProcessingRoutine
	jc	err

	cmp	ax, CODE_EOF
	jne	processLoop

	; set the scrap size, if it wasn't already done
	;
	push	dx,bp
	mov	ax, locals.ISF_endRow		; ax <- max row number
	inc	ax				; ax <- # rows in scrap
	mov	cx, locals.ISF_endCol		; cx <- max col number
	inc	cx				; cx <- # cols in scrap
	mov	dx, ss
	lea	bp, SSM_local			; dx:bp <- SSMetaStruc
	call	SSMetaSetScrapSize
	pop	dx,bp

	;
	; cells have been saved
	;
	mov	dx, SSM_local.SSMDAS_hdrBlkVMHan
	clr	cx
	mov	si, SSM_local.SSMDAS_vmFileHan
	mov	ax, TE_NO_ERROR
	mov	bx, CIF_SPREADSHEET

err:
	push	bx				; preserve error msg handle
	mov	bx, locals.ISF_inputCacheHan
	call	InputCacheDestroy
	pop	bx

	mov	si, MANUFACTURER_ID_GEOWORKS
	.leave
	ret

TransImport	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportCallProcessingRoutine

DESCRIPTION:	

CALLED BY:	INTERNAL (Import)

PASS:		ImportStackFrame

RETURN:		carry set if error, ax = TransError
		carry clear otherwise, ax = Lotus opcode

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

;
; LotusRecordProcessingRoutineLookup 1 & 2
; Structure of table:
;	each entry consists of 2 fields
;	1) a word containing the number of bytes in the Lotus record
;	2) an nptr to the routine to call to process the record
;
; Checks are made thus:
;	1) the number of bytes the Lotus records claims it has is checked
;	   against the table. The number of bytes will not be destroyed.
;	   -1 = variable.
;	2) the routine in the table is called. If the nptr = -1,
;	   ImportIgnoreRecord is called.  All other routines should
;	   call ImportIgnoreRecord, or do the equivalent to leave the
;	   Lotus data stream at the next record.  The routine should
;	   set the carry flag if there is an error, and return TransError
;	   in ax.
;

;	1,	offset CheckZeroOneFF,		; CODE_CALC_ORDER, 3
;	1,	offset CheckZeroOneFF,		; CODE_SPLIT, 4
;	1,	offset CheckZeroFF,		; CODE_SYNC, 5

;
; There is a 123 clone called AsEasyAs which creates these records
; with only 1 byte of data, so treat them as variable length, since
; we don't import footers and headers anyways. --cah 3/14/93
; 
;	242,	offset ImportIgnoreRecord,	; CODE_FOOTER
;	242,	offset ImportIgnoreRecord,	; CODE_HEADER
;	40,	offset ImportIgnoreRecord,	; CODE_SETUP

; If the scrap size is calculated in ImportSaveCell, don't need to
; process RANGE (DIMENSION) record, which just sets the scrap size.  
; (The AEA files did not have this record, so scrap size was 0.)
;
;	8,	offset ImportProcessRange,	; CODE_RANGE

; Some QPro files converted to 123 have lenght of this record = 17
; so use a variable length instead.
;
;	13,	offset ImportProcessNumber,	; CODE_NUMBER, e

if PZ_PCGEOS
LotusRecordProcessingRoutineLookup1	word \
	-1,	offset ImportIgnoreRecord,	; CODE_BOF
	0,	-1,				; CODE_EOF
	1,	offset ImportIgnoreRecord,	; CODE_CALC_MODE
	-1,	offset ImportIgnoreRecord,	; CODE_CALC_ORDER, 3	?
	-1,	offset ImportIgnoreRecord,	; CODE_SPLIT, 4		?
	-1,	offset ImportIgnoreRecord,	; CODE_SYNC, 5		?
	8,	offset ImportIgnoreRecord,	; CODE_RANGE
	-1,	offset ImportIgnoreRecord,	; CODE_WINDOW1
	3,	offset ImportIgnoreRecord,	; CODE_COLW1
	-1,	offset ImportIgnoreRecord,	; CODE_WINDOW2
	3,	offset ImportIgnoreRecord,	; CODE_COLW2
	-1,	offset ImportProcessName,	; CODE_NAME, b
;1994-07-14(Thu)TOK ----------------
	6,	offset ImportIgnoreRecord,	;in Japanese 1-2-3
;----------------
;1994-07-07(Thu)TOK ----------------
	8,	offset ImportProcessInteger,	;in Japanese 1-2-3
;----------------
	-1,	offset ImportProcessNumber,	; CODE_NUMBER, e
	-1,	offset ImportProcessLabel,	; CODE_LABEL, f
	-1,	offset ImportProcessFormula,	; CODE_FORMULA
	-1,	-1,				; 11h
	-1,	-1,				; 12h
	-1,	-1,				; 13h
	-1,	-1,				; 14h
	-1,	-1,				; 15h
	-1,	-1,				; 16h
	-1,	-1,				; 17h
	25,	offset ImportIgnoreRecord,	; CODE_TABLE
	25,	offset ImportIgnoreRecord,	; CODE_QRANGE
	8,	offset ImportIgnoreRecord,	; CODE_PRANGE
;1994-08-23(Tue)TOK ----------------
	-1,	offset ImportIgnoreRecord,	;in Japanese 1-2-3, for R2.4J
;----------------
	8,	offset ImportIgnoreRecord,	; CODE_FRANGE
;1994-07-07(Thu)TOK ----------------
	10,	offset ImportIgnoreRecord,	;in Japanese 1-2-3
;----------------
	-1,	-1,				; 1eh
	-1,	offset ImportIgnoreRecord,	; 1fh		?
	16,	offset ImportIgnoreRecord,	; CODE_HRANGE
	-1,	offset ImportIgnoreRecord,	; 21h		?
	-1,	-1,				; 22h
;1994-07-07(Thu)TOK ----------------
	10,	offset ImportIgnoreRecord,	;in Japanese 1-2-3
;----------------
	1,	offset ImportIgnoreRecord,	; CODE_PROTEC
	-1,	offset ImportIgnoreRecord,	; CODE_FOOTER
	-1,	offset ImportIgnoreRecord,	; CODE_HEADER
	-1,	offset ImportIgnoreRecord,	; CODE_SETUP
	10,	offset ImportIgnoreRecord,	; CODE_MARGINS
	1,	offset ImportProcessLabelFmt,	; CODE_LABELFMT
	16,	offset ImportIgnoreRecord,	; CODE_TITLES
	-1,	-1,				; 2bh
	-1,	-1,				; 2ch
	-1,	offset ImportIgnoreRecord,	; CODE_GRAPH
	-1,	offset ImportIgnoreRecord,	; CODE_NGRAPH
	1,	offset ImportIgnoreRecord,	; CODE_CALC_COUNT
	1,	offset CheckZeroFF,		; CODE_UNFORMATTED
	1,	offset CheckOneTwo,		; CODE_CURSORW12
	144,	offset ImportIgnoreRecord,	; CODE_WINDOW
	-1,	offset ImportIgnoreRecord,	; CODE_STRING
	-1,	-1,				; 34h
	-1,	-1,				; 35h
	-1,	-1,				; 36h
	4,	offset ImportIgnoreRecord,	; CODE_LOCK_PASSWORD
	1,	offset ImportIgnoreRecord,	; CODE_LOCKED
	-1,	-1,				; 39h
	-1,	-1,				; 3ah
	-1,	-1,				; 3bh
	127,	offset ImportIgnoreRecord,	; CODE_QUERY
	16,	offset ImportIgnoreRecord,	; CODE_QUERYNAME
	679,	offset ImportIgnoreRecord,	; CODE_PRINT
	16,	offset ImportIgnoreRecord,	; CODE_PRINTNAME
	499,	offset ImportIgnoreRecord,	; CODE_GRAPH2
	16,	offset ImportIgnoreRecord,	; CODE_GRAPHNAME
	9,	offset ImportIgnoreRecord,	; CODE_ZOOM

	2,	offset ImportIgnoreRecord,	; SYM_SPLIT

	2,	offset ImportIgnoreRecord,	; CODE_NSROWS
	2,	offset ImportIgnoreRecord,	; CODE_NSCOLS
	25,	offset ImportIgnoreRecord,	; CODE_RULER
	25,	offset ImportIgnoreRecord,	; CODE_NNAME
	65,	offset ImportIgnoreRecord,	; CODE_ACOMM
	8,	offset ImportIgnoreRecord,	; CODE_AMACRO
	16,	offset ImportIgnoreRecord,	; CODE_PARSE
	4,	offset ImportIgnoreRecord	; CODE_WKSPWORD
else
LotusRecordProcessingRoutineLookup1	word \
	-1,	offset ImportIgnoreRecord,	; CODE_BOF
	0,	-1,				; CODE_EOF
	1,	offset ImportIgnoreRecord,	; CODE_CALC_MODE
	-1,	offset ImportIgnoreRecord,	; CODE_CALC_ORDER, 3	?
	-1,	offset ImportIgnoreRecord,	; CODE_SPLIT, 4		?
	-1,	offset ImportIgnoreRecord,	; CODE_SYNC, 5		?
	8,	offset ImportIgnoreRecord,	; CODE_RANGE
	-1,	offset ImportIgnoreRecord,	; CODE_WINDOW1
	3,	offset ImportIgnoreRecord,	; CODE_COLW1
	-1,	offset ImportIgnoreRecord,	; CODE_WINDOW2
	3,	offset ImportIgnoreRecord,	; CODE_COLW2
	-1,	offset ImportProcessName,	; CODE_NAME, b
	5,	offset ImportIgnoreRecord,	; CODE_BLANK, c
	7,	offset ImportProcessInteger,	; CODE_INTEGER, d
	-1,	offset ImportProcessNumber,	; CODE_NUMBER, e
	-1,	offset ImportProcessLabel,	; CODE_LABEL, f
	-1,	offset ImportProcessFormula,	; CODE_FORMULA
	-1,	-1,				; 11h
	-1,	-1,				; 12h
	-1,	-1,				; 13h
	-1,	-1,				; 14h
	-1,	-1,				; 15h
	-1,	-1,				; 16h
	-1,	-1,				; 17h
	25,	offset ImportIgnoreRecord,	; CODE_TABLE
	25,	offset ImportIgnoreRecord,	; CODE_QRANGE
	8,	offset ImportIgnoreRecord,	; CODE_PRANGE
	8,	offset ImportIgnoreRecord,	; CODE_SRANGE
	8,	offset ImportIgnoreRecord,	; CODE_FRANGE
	9,	offset ImportIgnoreRecord,	; CODE_KRANGE
	-1,	-1,				; 1eh
	-1,	offset ImportIgnoreRecord,	; 1fh		?
	16,	offset ImportIgnoreRecord,	; CODE_HRANGE
	-1,	offset ImportIgnoreRecord,	; 21h		?
	-1,	-1,				; 22h
	9,	offset ImportIgnoreRecord,	; CODE_KRANGE2
	1,	offset ImportIgnoreRecord,	; CODE_PROTEC
	-1,	offset ImportIgnoreRecord,	; CODE_FOOTER
	-1,	offset ImportIgnoreRecord,	; CODE_HEADER
	-1,	offset ImportIgnoreRecord,	; CODE_SETUP
	10,	offset ImportIgnoreRecord,	; CODE_MARGINS
	1,	offset ImportProcessLabelFmt,	; CODE_LABELFMT
	16,	offset ImportIgnoreRecord,	; CODE_TITLES
	-1,	-1,				; 2bh
	-1,	-1,				; 2ch
	-1,	offset ImportIgnoreRecord,	; CODE_GRAPH
	-1,	offset ImportIgnoreRecord,	; CODE_NGRAPH
	1,	offset ImportIgnoreRecord,	; CODE_CALC_COUNT
	1,	offset CheckZeroFF,		; CODE_UNFORMATTED
	1,	offset CheckOneTwo,		; CODE_CURSORW12
	144,	offset ImportIgnoreRecord,	; CODE_WINDOW
	-1,	offset ImportIgnoreRecord,	; CODE_STRING
	-1,	-1,				; 34h
	-1,	-1,				; 35h
	-1,	-1,				; 36h
	4,	offset ImportIgnoreRecord,	; CODE_LOCK_PASSWORD
	1,	offset ImportIgnoreRecord,	; CODE_LOCKED
	-1,	-1,				; 39h
	-1,	-1,				; 3ah
	-1,	-1,				; 3bh
	127,	offset ImportIgnoreRecord,	; CODE_QUERY
	16,	offset ImportIgnoreRecord,	; CODE_QUERYNAME
	679,	offset ImportIgnoreRecord,	; CODE_PRINT
	16,	offset ImportIgnoreRecord,	; CODE_PRINTNAME
	499,	offset ImportIgnoreRecord,	; CODE_GRAPH2
	16,	offset ImportIgnoreRecord,	; CODE_GRAPHNAME
	9,	offset ImportIgnoreRecord,	; CODE_ZOOM

	2,	offset ImportIgnoreRecord,	; SYM_SPLIT

	2,	offset ImportIgnoreRecord,	; CODE_NSROWS
	2,	offset ImportIgnoreRecord,	; CODE_NSCOLS
	25,	offset ImportIgnoreRecord,	; CODE_RULER
	25,	offset ImportIgnoreRecord,	; CODE_NNAME
	65,	offset ImportIgnoreRecord,	; CODE_ACOMM
	8,	offset ImportIgnoreRecord,	; CODE_AMACRO
	16,	offset ImportIgnoreRecord,	; CODE_PARSE
	4,	offset ImportIgnoreRecord	; CODE_WKSPWORD
endif

LotusRecordProcessingRoutineLookup2	nptr \
	32,	offset ImportIgnoreRecord,	; CODE_HIDVEC1
	32,	offset ImportIgnoreRecord,	; CODE_HIDVEC2
	16,	offset ImportIgnoreRecord,	; CODE_PARSERANGES
	25,	offset ImportIgnoreRecord,	; CODE_RRANGES
	-1,	-1,				; 68h
	40,	offset ImportIgnoreRecord,	; CODE_MATRIXRANGES
	-1,	-1,				; 6ah
	-1,	offset ImportIgnoreRecord	; CODE_MYSTERY

;	-1,	offset ImportIgnoreRecord,	; CODE_CPI, 96h
;	-1,	offset ImportIgnoreRecord	; CODE_STYLE, 9dh


ImportCallProcessingRoutine	proc	near	uses	bx
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	call	ImportInputGetWord	; ax <- Lotus opcode
	jc	exit

	mov	locals.ISF_lotusToken, ax
	mov	bx, ax
	shl	bx, 1			;
	shl	bx, 1			; bx <- offset into lookup table

	cmp	ax, CODE_WKSPWORD	; end of 1st table
	jbe	table1			; branch if opcode is in 1st table

	cmp	ax, CODE_HIDVEC1	; start of 2nd table
	jb	errBadData		; branch if bogus

	cmp	ax, CODE_MYSTERY	; end of 2nd table
	jbe	table2			; branch if opcode is in 2nd table

	;-----------------------------------------------------------------------
	; deal with the stragglers

if DBCS_PCGEOS	;1994-08-22(Mon)TOK ----------------
	cmp	ax, 94h	;94h = FONTS
	je	DoneCheck
	cmp	ax, 95h	;95h = PAPER
	je	DoneCheck
endif	;----------------
	cmp	ax, CODE_CPI
	jne	checkStyle

if DBCS_PCGEOS	;1994-08-22(Mon)TOK ----------------
DoneCheck:
endif	;----------------
	mov	bx, offset ImportIgnoreRecord
	jmp	short callRoutineDirect

checkStyle:
	cmp	ax, CODE_STYLE
	jne	errBadData

	mov	bx, offset ImportIgnoreRecord

callRoutineDirect:
	call	ImportInputGetWord	; ax <- number of bytes
	jc	exit

callRoutineDirectHaveLength:
	call	ImportInputBufferLotusRecord
	jc	exit
	call	bx
	call	ImportInputClearLotusRecord	; flags intact
	jc	errBadData
	jmp	short callDone

	;-----------------------------------------------------------------------
	; modify bx if necessary and call the processing routine

table1:
	add	bx, offset LotusRecordProcessingRoutineLookup1
	jmp	short callRoutineIndirect

table2:
	sub	bx, CODE_HIDVEC1 shl 2	; make offset 0 based
	add	bx, offset LotusRecordProcessingRoutineLookup2

callRoutineIndirect:
	;
	; cs:bx = entry containing size of record and offset to processing
	; routine
	;
	call	ImportInputGetWord	; ax <- number of bytes
	jc	exit

	cmp	{word} cs:[bx], -1	; variable length record?
	je	callProcessingRoutine	; branch if so

	cmp	ax, {word} cs:[bx]
	jne	errBadData

callProcessingRoutine:
	add	bx, 2			; point bx at the routine offset
	cmp	{word} cs:[bx], -1
	jne	reallyCallRoutine

	;
	; ignore
	;
	mov	bx, offset ImportIgnoreRecord
	jmp	callRoutineDirectHaveLength
	
reallyCallRoutine:
	call	ImportInputBufferLotusRecord
	jc	exit
	call	cs:[bx]				; ax <- TransError
	call	ImportInputClearLotusRecord	; flags intact
	jc	exit

callDone:
	mov	ax, locals.ISF_lotusToken	; retrieve opcode
	clc

exit:
	.leave
	ret

errBadData:
	mov	ax, TE_INVALID_FORMAT
	stc
	jmp	short exit

ImportCallProcessingRoutine	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportProcessRange

DESCRIPTION:	Process the particular Lotus record.

CALLED BY:	INTERNAL (ImportCallProcessingRoutine)

PASS:		ImportStackFrame
		ax - number of bytes in the record

RETURN:		

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@
if 0
ImportProcessRange	proc	near	uses	cx
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	lodsw				; ax <- start col
	mov	SSM_local.SSMDAS_col, ax

	lodsw				; ax <- start row
	mov	SSM_local.SSMDAS_row, ax

	lodsw				; ax <- end col

	sub	ax, SSM_local.SSMDAS_col
	inc	ax
	mov	SSM_local.SSMDAS_scrapCols, ax
	mov	cx, ax

	lodsw				; ax <- end row

	sub	ax, SSM_local.SSMDAS_row
	inc	ax
	mov	SSM_local.SSMDAS_scrapRows, ax

	push	dx,bp
	mov	dx, ss
	lea	bp, SSM_local
	call	SSMetaSetScrapSize		; set scrap size now
	pop	dx,bp

	clc

	.leave
	ret
ImportProcessRange	endp

endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportProcessLabelFmt

DESCRIPTION:	Process a Lotus Label format

CALLED BY:	INTERNAL ImportCallProcessingRoutine

PASS:		ImportStackFrame
		ax - number of bytes in the record
		ds:si - Lotus record

RETURN:		ds:si - pointing past label format byte

DESTROYED:	ax, bx, es, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

------------------------------------------------------------------------------@

ImportProcessLabelFmt	proc	near
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	lodsb				; al <- data

	cmp	al, 27h
	je	ok
	cmp	al, 22h
	je	ok
	cmp	al, 5eh
	mov	ax, TE_INVALID_FORMAT
	stc
	jne	exit
ok:
	clc
exit:
	.leave
	ret
ImportProcessLabelFmt	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportIgnoreRecord

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		ax - number of bytes to ignore

RETURN:		ImportStackFrame
		carry set if error
		al - last byte read

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

ImportIgnoreRecord	proc	near
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	add	si, ax
	clc

	.leave
	ret
ImportIgnoreRecord	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CheckZeroOne

DESCRIPTION:	Checks for a valid value. Assumes that the Lotus record has one
		byte for data.

CALLED BY:	INTERNAL ()

PASS:		ImportStackFrame

RETURN:		carry set if error
		Lotus data stream positioned at the next record

DESTROYED:	al

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

CheckZeroOne	proc	near
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	lodsb					; al <- data
	tst	al
	je	ok

	cmp	al, 1
	stc
	mov	ax, TE_INVALID_FORMAT
	jne	exit

ok:
	clc

exit:
	.leave
	ret
CheckZeroOne	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CheckZeroFF

DESCRIPTION:	Checks for a valid value. Assumes that the Lotus record has one
		byte for data.

CALLED BY:	INTERNAL ()

PASS:		ImportStackFrame

RETURN:		carry set if error
		Lotus data stream positioned at the next record

DESTROYED:	al

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

CheckZeroFF	proc	near
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	lodsb					; al <- data
	tst	al
	je	ok

	cmp	al, 0ffh
	stc
	mov	ax, TE_INVALID_FORMAT
	jne	exit

ok:
	clc

exit:
	.leave
	ret
CheckZeroFF	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CheckZeroOneFF

DESCRIPTION:	Checks for a valid value. Assumes that the Lotus record has one
		byte for data.

CALLED BY:	INTERNAL ()

PASS:		ImportStackFrame

RETURN:		carry set if error
		Lotus data stream positioned at the next record

DESTROYED:	al

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

CheckZeroOneFF	proc	near
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	lodsb					; al <- data
	tst	al
	je	ok

	cmp	al, 1
	je	ok

	cmp	al, 0ffh
	stc
	mov	ax, TE_INVALID_FORMAT
	jne	exit

ok:
	clc

exit:
	.leave
	ret
CheckZeroOneFF	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CheckOneTwo

DESCRIPTION:	Checks for a valid value. Assumes that the Lotus record has one
		byte for data.

CALLED BY:	INTERNAL ()

PASS:		ImportStackFrame

RETURN:		carry set if error
		Lotus data stream positioned at the next record

DESTROYED:	al

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

CheckOneTwo	proc	near
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	lodsb					; al <- data
	cmp	al, 1
	je	ok

	cmp	al, 2
	stc
	mov	ax, TE_INVALID_FORMAT
	jne	exit

ok:
	clc

exit:
	.leave
	ret
CheckOneTwo	endp
