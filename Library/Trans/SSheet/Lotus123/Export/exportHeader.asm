
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		exportHeader.asm

AUTHOR:		Cheng, 10/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial revision

DESCRIPTION:
	Lotus file header template.  The export code will copy the template
	and modify the necessary fields.

	JUSTIFICATION: A strategy utilizing a template is used because the
	header is pretty much standard.  Among the few things that we would
	be modifying is the range.  Also, dealer with the header one record
	at a time is slow and arguably code-space intensive.  I took this
	track originally and I have preserved the code (untested) in
	exportOld.asm.

	IMPORTANT: If you add to the template, make sure the following are
	done:
		add a field to the LotusFileHeader structure
		add bytes to the LotusFileHeader template
		add a check in ExportCheckFileHeader
		
NOTES:
In my test file, I see this sequence:
	BOF		0h
	RANGE
	6B?		I'm not adding this to the header
	CPI
	CALC_COUNT
	CALC_MODE
	CALC_ORDER
	SPLIT
	SYNC
	WINDOW1		07h, 32 bytes, documented as having 31 bytes
	HIDVEC1		64h
	TABLE		18h
	QRANGE		19h
	PRANGE		1ah
	UNFORMATTED	30h
	FRANGE		1ch
	SRANGE		1bh
	KRANGE		1dh
	KRANGE2		23h
	RRANGES		67h
	MATRIXRANGES	69h
	HRANGE		20h
	PARSERANGES	66h
	PROTEC		24h
	FOOTER		25h
	HEADER		26h
	SETUP		27h
	MARGINS		28h
	LABELFMT	29h, value=27h
	TITLES		2ah
	GRAPH		2dh, 443 bytes, documented as having 437 bytes
		
	$Id: exportHeader.asm,v 1.1 97/04/07 11:41:51 newdeal Exp $

-------------------------------------------------------------------------------@

LotusFileHeader		struct			; running total
	LFH_bof		byte 6 dup (?)		; 6
	LFH_range	byte 12 dup (?)		; 18
	LFH_cpi		byte 10 dup (?)		; 28
	LFH_calcCount	byte 5 dup (?)		; 33
	LFH_calcMode	byte 5 dup (?)		; 38
	LFH_calcOrder	byte 5 dup (?)		; 43
	LFH_split	byte 5 dup (?)		; 48
	LFH_sync	byte 5 dup (?)		; 53
	LFH_window1	byte 36 dup (?)		; 89
	LFH_hidvec1	byte 36 dup (?)		; 125
	LFH_table	byte 29 dup (?)		; 154
	LFH_qrange	byte 29 dup (?)		; 183
	LFH_prange	byte 12 dup (?)		; 195
	LFH_unformatted	byte 5 dup (?)		; 200
	LFH_frange	byte 12 dup (?)		; 212
	LFH_srange	byte 12 dup (?)		; 224
	LFH_krange	byte 13 dup (?)		; 237
	LFH_krange2	byte 13 dup (?)		; 250
	LFH_rrange	byte 29 dup (?)		; 279
	LFH_matrixrange	byte 44 dup (?)		; 323
	LFH_hrange	byte 20 dup (?)		; 343
	LFH_parserange	byte 20 dup (?)		; 363
	LFH_protection	byte 5 dup (?)		; 368
	LFH_footer	byte 246 dup (?)	; 614
	LFH_header	byte 246 dup (?)	; 860
	LFH_setup	byte 44 dup (?)		; 904
	LFH_margins	byte 14 dup (?)		; 918
	LFH_labelfmt	byte 5 dup (?)		; 923
	LFH_titles	byte 20 dup (?)		; 943
	LFH_graph	byte 447 dup (?)	; 1390
LotusFileHeader		ends


ImpexLmemResource	segment	lmem	LMEM_TYPE_GENERAL

LotusFileHeaderStart	label	byte

LotusFileHeaderBof	label	byte
	word	CODE_BOF
	word	2
	word	LOTUS_BOF_ID

LotusFileHeaderRange	label	byte
	word	CODE_RANGE
	word	8
	word	4 dup (0)		; *** will be filled in ***

LotusFileHeaderCpi	label	byte
	word	CODE_CPI
	word	6
	word	0
	word	0
	byte	1
	byte	0

LotusFileHeaderCalcCount	label	byte
	word	CODE_CALC_COUNT
	word	1
	byte	1			; iteration count

LotusFileHeaderCalcMode	label	byte
	word	CODE_CALC_MODE
	word	1
	byte	0ffh			; automatic recalc

LotusFileHeaderCalcOrder	label	byte
	word	CODE_CALC_ORDER
	word	1
	byte	0			; natural recalc

LotusFileHeaderSplit	label	byte
	word	CODE_SPLIT
	word	1
	byte	0			; no window split

LotusFileHeaderSync	label	byte
	word	CODE_SYNC
	word	1
	byte	0ffh			; windows synchronized
	
LotusFileHeaderWindow1	label	byte
	word	CODE_WINDOW1
	word	32
	word	0			; cursor col = 0
	word	1			; cursor row = 1
	byte	LOTUS_FORMAT_GENERAL	; cell format
	byte	0			; zero1
	word	LOTUS_DEFAULT_COL_WIDTH	; col width
	word	8			; screen cols
	word	20			; screen rows
	word	0			; leftmost col
	word	0			; top row
	word	0			; title cols
	word	0			; title rows
	word	0			; left title col
	word	0			; top title row
	word	LOTUS_DEFAULT_BORDER_WIDTH_COL	; border width col
	word	LOTUS_DEFAULT_BORDER_WIDTH_ROW	; border width row
	word	72			; window width
	word	0			; zero2

LotusFileHeaderHidvec	label	byte
	word	CODE_HIDVEC1
	word	32
	byte	32 dup (0)

LotusFileHeaderTable	label	byte
	word	CODE_TABLE
	word	25
	byte	0			; no table
	word	0ffffh
	word	0
	word	0ffffh
	word	0
	word	0ffffh
	word	0
	word	0ffffh
	word	0
	word	0ffffh
	word	0
	word	0ffffh
	word	0

LotusFileHeaderQRange	label	byte
	word	CODE_QRANGE
	word	25
	word	0ffffh			; range
	word	0
	word	0ffffh
	word	0
	word	0ffffh			; range
	word	0
	word	0ffffh
	word	0
	word	0ffffh			; range
	word	0
	word	0ffffh
	word	0
	byte	0			; command

LotusFileHeaderPRange	label	byte
	word	CODE_PRANGE
	word	8
	word	0ffffh			; start col
	word	0			; start row
	word	0ffffh			; end col
	word	0			; end row

LotusFileHeaderUnformatted	label	byte
	word	CODE_UNFORMATTED
	word	1
	byte	0

LotusFileHeaderFRange	label	byte
	word	CODE_FRANGE
	word	8
	word	0ffffh			; start col
	word	0			; start row
	word	0ffffh			; end col
	word	0			; end row

LotusFileHeaderSRange	label	byte
	word	CODE_SRANGE
	word	8
	word	0ffffh			; start col
	word	0			; start row
	word	0ffffh			; end col
	word	0			; end row

LotusFileHeaderKRange	label	byte
	word	CODE_KRANGE
	word	9
	word	0ffffh			; start col
	word	0			; start row
	word	0ffffh			; end col
	word	0			; end row
	byte	0			; order - descending

LotusFileHeaderKRange2	label	byte
	word	CODE_KRANGE2
	word	9
	word	0ffffh			; start col
	word	0			; start row
	word	0ffffh			; end col
	word	0			; end row
	byte	0			; order - descending

LotusFileHeaderRRange	label	byte
	word	CODE_RRANGES
	word	25
	word	0ffffh			; range
	word	0
	word	0ffffh
	word	0
	word	0ffffh			; range
	word	0
	word	0ffffh
	word	0
	word	0ffffh			; range
	word	0
	word	0ffffh
	word	0
	byte	0			; command

LotusFileHeaderMatrixRange	label	byte
	word	CODE_MATRIXRANGES
	word	40
	word	0ffffh			; inversion source start col
	word	0			; start row
	word	0ffffh			; end col
	word	0			; end row
	word	0ffffh			; inversion dest start col
	word	0			; start row
	word	0ffffh			; end col
	word	0			; end row
	word	0ffffh			; multiplicand range start col
	word	0			; start row
	word	0ffffh			; end col
	word	0			; end row
	word	0ffffh			; multiplier range start col
	word	0			; start row
	word	0ffffh			; end col
	word	0			; end row
	word	0ffffh			; product range start col
	word	0			; start row
	word	0ffffh			; end col
	word	0			; end row

LotusFileHeaderHRange	label	byte
	word	CODE_HRANGE
	word	16
	word	0ffffh			; range
	word	0
	word	0ffffh
	word	0
	word	0ffffh			; range
	word	0
	word	0ffffh
	word	0

LotusFileHeaderParseRange	label	byte
	word	CODE_PARSERANGES
	word	16
	word	0ffffh			; range
	word	0
	word	0ffffh
	word	0
	word	0ffffh			; range
	word	0
	word	0ffffh
	word	0

LotusFileHeaderProtection	label	byte
	word	CODE_PROTEC
	word	1
	byte	0			; no global protection

LotusFileHeaderFooter	label	byte
	word	CODE_FOOTER
	word	242
	byte	242 dup (0)

LotusFileHeaderHeader	label	byte
	word	CODE_HEADER
	word	242
	byte	242 dup (0)

LotusFileHeaderSetup	label	byte
	word	CODE_SETUP
	word	40
	byte	40 dup (0)

LotusFileHeaderMargins	label	byte
	word	CODE_MARGINS
	word	10
	word	4			; left margin
	word	4ch			; right margin
	word	42h			; page length
	word	2			; top margin
	word	2			; bottom margin

LotusFileHeaderLabelFmt	label	byte
	word	CODE_LABELFMT
	word	1
	byte	27h			; label alignment = left

LotusFileHeaderTitles	label	byte
	word	CODE_TITLES
	word	16
	word	0ffffh			; range
	word	0
	word	0ffffh
	word	0
	word	0ffffh			; range
	word	0
	word	0ffffh
	word	0

LotusFileHeaderGraph	label	byte
	word	CODE_GRAPH
	word	443			; =01bbh
	byte	104 dup (0ffh)		; running total = 104
	byte	4			; running total = 105
	byte	2 dup (0)		; running total = 107
	byte	6 dup (3)		; running total = 113
	byte	320 dup (0)		; running total = 433
	byte	2 dup (71h)		; running total = 435
	byte	1			; running total = 436
	byte	7 dup (0)		; running total = 443

LotusFileHeaderEnd	label	byte

LOTUS_HEADER_SIZE	= LotusFileHeaderEnd - LotusFileHeaderStart

ForceRef	LotusFileHeaderBof
ForceRef	LotusFileHeaderRange
ForceRef	LotusFileHeaderCpi
ForceRef	LotusFileHeaderCalcCount
ForceRef	LotusFileHeaderCalcMode
ForceRef	LotusFileHeaderCalcOrder
ForceRef	LotusFileHeaderSplit
ForceRef	LotusFileHeaderSync
ForceRef	LotusFileHeaderWindow1
ForceRef	LotusFileHeaderHidvec
ForceRef	LotusFileHeaderTable
ForceRef	LotusFileHeaderQRange
ForceRef	LotusFileHeaderPRange
ForceRef	LotusFileHeaderUnformatted
ForceRef	LotusFileHeaderFRange
ForceRef	LotusFileHeaderSRange
ForceRef	LotusFileHeaderKRange
ForceRef	LotusFileHeaderKRange2
ForceRef	LotusFileHeaderRRange
ForceRef	LotusFileHeaderMatrixRange
ForceRef	LotusFileHeaderHRange
ForceRef	LotusFileHeaderParseRange
ForceRef	LotusFileHeaderProtection
ForceRef	LotusFileHeaderFooter
ForceRef	LotusFileHeaderHeader
ForceRef	LotusFileHeaderSetup
ForceRef	LotusFileHeaderMargins
ForceRef	LotusFileHeaderLabelFmt
ForceRef	LotusFileHeaderTitles
ForceRef	LotusFileHeaderGraph

ImpexLmemResource	ends


ExportCode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportCheckFileHeader

DESCRIPTION:	Error check the LotusFileHeader lookup table by making sure
		that its entries are in synch with the LotusFileHeader
		structure.

CALLED BY:	INTERNAL ()

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing, dies if assertions fail

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

if 0
if ERROR_CHECK

ExportCheckFileHeader	proc	near	uses	ax,bx,ds,si
	.enter
	pushf

	mov	bx, handle ImpexLmemResource
	call	MemLock
	mov	ds, ax
	mov	si, offset LotusFileHeaderStart

	cmp	{word} ds:[si].LFH_bof, CODE_BOF
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_range, CODE_RANGE
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_cpi, CODE_CPI
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_calcCount, CODE_CALC_COUNT
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_calcMode, CODE_CALC_MODE
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_calcOrder, CODE_CALC_ORDER
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_split, CODE_SPLIT
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_sync, CODE_SYNC
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_window1, CODE_WINDOW1
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_hidvec1, CODE_HIDVEC1
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_table, CODE_TABLE
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_qrange, CODE_QRANGE
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_prange, CODE_PRANGE
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_unformatted, CODE_UNFORMATTED
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_frange, CODE_FRANGE
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_srange, CODE_SRANGE
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_krange, CODE_KRANGE
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_krange2, CODE_KRANGE2
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_rrange, CODE_RRANGES
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_matrixrange, CODE_MATRIXRANGES
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_hrange, CODE_HRANGE
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_parserange, CODE_PARSERANGES
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_protection, CODE_PROTEC
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_footer, CODE_FOOTER
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_header, CODE_HEADER
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_setup, CODE_SETUP
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_margins, CODE_MARGINS
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_labelfmt, CODE_LABELFMT
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_titles, CODE_TITLES
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	cmp	{word} ds:[si].LFH_graph, CODE_GRAPH
	ERROR_NE IMPEX_INVALID_DATA_IN_EXPORT_TABLE

	call	MemUnlock
	popf
	.leave
	ret
ExportCheckFileHeader	endp

endif
endif

ExportCode	ends
