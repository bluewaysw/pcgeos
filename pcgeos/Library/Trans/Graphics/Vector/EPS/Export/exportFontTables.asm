
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		exportFontTables.asm

AUTHOR:		Jim DeFrisco, 4/8/91

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/91		Initial revision
   jfh	10/7/07	try and get sans right - he has SANS mapped to Helvetica?


DESCRIPTION:
	This file holds the tables to map our fonts to PostScript names
		

	$Id: exportFontTables.asm,v 1.1 97/04/07 11:25:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportText	segment	resource

; Table Pointers
; There are a set of FontLists defined by the PostScript Translation Library
; (as part of xlatPS.def).  They are part of the PSFontList enumerated type,
; and each device supported by the PostScript printer driver supplies one
; of these enum values to describe the font set that it contains.  This table
; contains offsets to the mapping tables, one entry here for each enum

fontMapHandles	label	hptr
	hptr	handle StandardFonts		; PSFL_STANDARD_13
	hptr	handle StandardFonts		; PSFL_STANDARD_35N
	hptr	handle StandardFonts		; PSFL_STANDARD_35C
	hptr	handle MoreFonts		; PSFL_AGFA_74
	hptr	handle MoreFonts		; PSFL_DEC_29
	hptr	handle StandardFonts		; PSFL_IBM_17
	hptr	handle MoreFonts		; PSFL_IBM_39
	hptr	handle MoreFonts		; PSFL_IBM_43
	hptr	handle MoreFonts		; PSFL_IBM_47
	hptr	handle MoreFonts		; PSFL_MONOTYPE_8
	hptr	handle MoreFonts		; PSFL_MONOTYPE_70
	hptr	handle MoreFonts		; PSFL_JAPANESE_2
	hptr	handle MoreFonts		; PSFL_JAPANESE_5
	hptr	handle StandardFonts		; PSFL_WANG_14
	hptr	handle MoreFonts		; PSFL_WANG_32
	hptr	handle MoreFonts		; PSFL_ADOBE_TC1
	hptr	handle MoreFonts		; PSFL_ADOBE_TC2
	hptr	handle MoreFonts		; PSFL_ADOBE_FULL_SET
	hptr	handle MoreFonts		; PSFL_QMS_43

fontMapOffsets	label	nptr
	nptr	Standard13		; PSFL_STANDARD_13
	nptr	Standard35N		; PSFL_STANDARD_35N
	nptr	Standard35C		; PSFL_STANDARD_35C
	nptr	Agfa74			; PSFL_AGFA_74
	nptr	DEC29			; PSFL_DEC_29
	nptr	IBM17			; PSFL_IBM_17
	nptr	IBM39			; PSFL_IBM_39
	nptr	IBM43			; PSFL_IBM_43
	nptr	IBM47			; PSFL_IBM_47
	nptr	Monotype8		; PSFL_MONOTYPE_8
	nptr	Monotype70		; PSFL_MONOTYPE_70
	nptr	Japanese2		; PSFL_JAPANESE_2
	nptr	Japanese5		; PSFL_JAPANESE_5
	nptr	Wang14			; PSFL_WANG_14
	nptr	Wang32			; PSFL_WANG_32
	nptr	AdobeTC1		; PSFL_ADOBE_TC1
	nptr	AdobeTC2		; PSFL_ADOBE_TC2
	nptr	FullSet			; PSFL_ADOBE_FULL_SET
	nptr	QMS43			; PSFL_ADOBE_FULL_SET

ExportText	ends

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Standard Font Sets
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

StandardFonts	segment	resource

; These tables hold a set of pointers to AdobeFontEntry structures.  Each
; structure contains everything we need to know about a particular font 
; supported in the particular set.  The entries in this table should be in 
; ascending order of FontID.  After the fontID sort, entries with the same
; fontID should be ordered by condensation (thinness, condensed fonts first) 
; then by weight (lower weight first).  For other styles (italic), they are 
; interspersed at the appropriate places in the list.  For example, if we 
; had normal and bold and italic and bold-italic versions of Helvetica and 
; Helvetica Narrow, the order should be:
;	Helvetica Narrow		-\_ normal	\
;	Helvetica Narrow-Italic		-/  before	 \_  Narrow
;	Helvetica Narrow-Bold		-\_ bold	 /
;	Helvetica Narrow-Bold-Italic	-/		/     before
;	Helvetica 	   				\
;	Helvetica-Italic			 	 \_   normal
;	Helvetica Bold			- plain	before	 /	 
;	Helvetica Bold-Italic		- italic	/
;	

Wang14		label	nptr.nptr.AdobeFontEntry
Standard13	label	nptr.nptr.AdobeFontEntry
		nptr	offset Standard13Fonts
		nptr	0

IBM17		label	nptr.nptr.AdobeFontEntry
		nptr	offset Standard13Fonts
		nptr	offset HelvNarrowSet
		nptr	0

Standard35C	label	nptr.nptr.AdobeFontEntry	; same for now
		nptr	offset Standard13Fonts
		nptr	offset Standard35Balance
		nptr	offset HelvCondensedSet
		nptr	0

Standard35N	label	nptr.nptr.AdobeFontEntry	; will change when we
		nptr	offset Standard13Fonts
		nptr	offset Standard35Balance
		nptr	offset HelvNarrowSet
		nptr	0

;------------------------------------------------------------------------
;	Standard Font Lists
;------------------------------------------------------------------------

Standard13Fonts	label	nptr.AdobeFontEntry
		nptr	offset TimesRoman	; FG_SERIF
		nptr	offset TimesItalic
		nptr	offset TimesBold
		nptr	offset TimesBoldItalic
		nptr	offset Helvetica	; FG_SANS_SERIF
		nptr	offset HelvItalic
		nptr	offset HelvBold
		nptr	offset HelvBoldItalic
		nptr	offset Symbol		; FG_SYMBOL
		nptr	offset Courier		; FG_MONO
		nptr	offset CourierItalic
		nptr	offset CourierBold
		nptr	offset CourierBoldItalic
		word	0			; table terminator

Standard35Balance label	nptr.AdobeFontEntry
		nptr	offset NewCentRoman	; FG_SERIF
		nptr	offset NewCentItalic
		nptr	offset NewCentBold
		nptr	offset NewCentBoldItalic
		nptr	offset PalatinoRoman
		nptr	offset PalatinoItalic
		nptr	offset PalatinoBold
		nptr	offset PalatinoBoldItalic
		nptr	offset BookmanLight	; for now, map light -> normal
		nptr	offset BookmanItal	;          and demi  -> bold
		nptr	offset BookmanDemi
		nptr	offset BookmanDemiItal
		nptr	offset Sans		; FG_SANS_SERIF
		nptr	offset SansItalic
		nptr	offset SansBold
		nptr	offset SansBoldItalic
		nptr	offset AvantGarde	; for now, map book -> normal
		nptr	offset AvantGardeObl	;          and demi -> bold
		nptr	offset AvantGardeBold
		nptr	offset AvantGardeBoldObl
		nptr	offset ZapfChancery	; FG_SCRIPT
		nptr	offset ZapfDingbats	
		word	0			; table terminator

HelvNarrowSet	label	nptr.AdobeFontEntry
		nptr	offset HelvNarrow
		nptr	offset HelvNarObl
		nptr	offset HelvNarBold
		nptr	offset HelvNarBoldObl
		nptr	0

HelvCondensedSet label	nptr.AdobeFontEntry
		nptr	offset HelvCondensed
		nptr	offset HelvCondObl
		nptr	offset HelvCondBold
		nptr	offset HelvCondBoldObl
		nptr	0

;------------------------------------------------------------------------
;	Standard Fonts
;------------------------------------------------------------------------

TimesRoman	word	FID_PS_TIMES_ROMAN
		byte	length trname, 0, AFE_STANDARD
trname		char	"/Times-Roman"

TimesItalic	word	FID_PS_TIMES_ROMAN
		byte	length triname, mask TS_ITALIC, AFE_STANDARD
triname		char	"/Times-Italic"

TimesBold	word	FID_PS_TIMES_ROMAN
		byte	length trbname, mask TS_BOLD, AFE_STANDARD
trbname		char	"/Times-Bold"

TimesBoldItalic	word	FID_PS_TIMES_ROMAN
		byte	length trbiname, mask TS_BOLD or mask TS_ITALIC, AFE_STANDARD
trbiname	char	"/Times-BoldItalic"

NewCentRoman	word	FID_PS_CENTURY_SCHOOLBOOK
		byte	length ncname, 0, AFE_STANDARD
ncname		char	"/NewCenturySchlbk-Roman"

NewCentItalic	word	FID_PS_CENTURY_SCHOOLBOOK
		byte	length nciname, mask TS_ITALIC, AFE_STANDARD
nciname		char	"/NewCenturySchlbk-Italic"

NewCentBold	word	FID_PS_CENTURY_SCHOOLBOOK
		byte	length ncbname, mask TS_BOLD, AFE_STANDARD
ncbname		char	"/NewCenturySchlbk-Bold"

NewCentBoldItalic	word	FID_PS_CENTURY_SCHOOLBOOK
		byte	length ncbiname, mask TS_BOLD or mask TS_ITALIC, AFE_STANDARD
ncbiname	char	"/NewCenturySchlbk-BoldItalic"

PalatinoRoman	word	FID_PS_PALATINO
		byte	length pname, 0, AFE_STANDARD
pname		char	"/Palatino-Roman"

PalatinoItalic	word	FID_PS_PALATINO
		byte	length piname, mask TS_ITALIC, AFE_STANDARD
piname		char	"/Palatino-Italic"

PalatinoBold	word	FID_PS_PALATINO
		byte	length pbname, mask TS_BOLD, AFE_STANDARD
pbname		char	"/Palatino-Bold"

PalatinoBoldItalic	word	FID_PS_PALATINO
		byte	length pbiname, mask TS_BOLD or mask TS_ITALIC, AFE_STANDARD
pbiname		char	"/Palatino-BoldItalic"

BookmanLight	word	FID_PS_BOOKMAN
		byte	length bname, 0, AFE_STANDARD
bname		char	"/Bookman-Light"

BookmanItal	word	FID_PS_BOOKMAN
		byte	length biname, mask TS_ITALIC, AFE_STANDARD
biname		char	"/Bookman-LightItalic"

BookmanDemi	word	FID_PS_BOOKMAN
		byte	length bbname, mask TS_BOLD, AFE_STANDARD
bbname		char	"/Bookman-Demi"

BookmanDemiItal	word	FID_PS_BOOKMAN
		byte	length bbiname, mask TS_BOLD or mask TS_ITALIC, AFE_STANDARD
bbiname		char	"/Bookman-DemiItalic"

Helvetica	word	FID_PS_HELVETICA
		byte	length hname, 0, AFE_STANDARD
hname		char	"/Helvetica"

HelvItalic	word	FID_PS_HELVETICA
		byte	length hiname, mask TS_ITALIC, AFE_STANDARD
hiname		char	"/Helvetica-Oblique"

HelvBold	word	FID_PS_HELVETICA
		byte	length hbname, mask TS_BOLD, AFE_STANDARD
hbname		char	"/Helvetica-Bold"

HelvBoldItalic	word	FID_PS_HELVETICA
		byte	length hbiname, mask TS_BOLD or mask TS_ITALIC, AFE_STANDARD
hbiname		char	"/Helvetica-BoldOblique"

HelvNarrow	word	FID_PS_HELVETICA
		byte	length hnname, 0, AFE_STANDARD
hnname		char	"/Helvetica-Narrow"

HelvNarObl	word	FID_PS_HELVETICA
		byte	length hniname, mask TS_ITALIC, AFE_STANDARD
hniname		char	"/Helvetica-Narrow-Oblique"

HelvNarBold	word	FID_PS_HELVETICA
		byte	length hnbname, mask TS_BOLD, AFE_STANDARD
hnbname		char	"/Helvetica-Narrow-Bold"

HelvNarBoldObl	word	FID_PS_HELVETICA
		byte	length hnbiname, mask TS_BOLD or mask TS_ITALIC, \
					AFE_STANDARD
hnbiname	char	"/Helvetica-Narrow-BoldOblique"

HelvCondensed	word	FID_PS_HELVETICA
		byte	length hcname, 0, AFE_STANDARD
hcname		char	"/Helvetica-Condensed"

HelvCondObl	word	FID_PS_HELVETICA
		byte	length hciname, mask TS_ITALIC, AFE_STANDARD
hciname		char	"/Helvetica-Condensed-Oblique"

HelvCondBold	word	FID_PS_HELVETICA
		byte	length hcbname, mask TS_BOLD, AFE_STANDARD
hcbname		char	"/Helvetica-Condensed-Bold"

HelvCondBoldObl	word	FID_PS_HELVETICA
		byte	length hcbiname, mask TS_BOLD or mask TS_ITALIC, \
					AFE_STANDARD
hcbiname	char	"/Helvetica-Condensed-BoldOblique"

; jfh - changing Helvetica to Sans here...
Sans		word	FID_PS_URW_SANS
		byte	length sname, 0, AFE_STANDARD
;sname		char	"/Helvetica"
sname		char	"/Sans"

SansItalic	word	FID_PS_URW_SANS
		byte	length siname, mask TS_ITALIC, AFE_STANDARD
;siname		char	"/Helvetica-Oblique"
siname		char	"/Sans-Oblique"

SansBold	word	FID_PS_URW_SANS
		byte	length sbname, mask TS_BOLD, AFE_STANDARD
;sbname		char	"/Helvetica-Bold"
sbname		char	"/Sans-Bold"

SansBoldItalic	word	FID_PS_URW_SANS
		byte	length sbiname, mask TS_BOLD or mask TS_ITALIC, AFE_STANDARD
;sbiname		char	"/Helvetica-BoldOblique"
sbiname		char	"/Sans-BoldOblique"

AvantGarde	word	FID_PS_AVANTE_GARDE
		byte	length agname, 0, AFE_STANDARD
agname		char	"/AvantGarde-Book"

AvantGardeObl	word	FID_PS_AVANTE_GARDE
		byte	length aginame, mask TS_ITALIC, AFE_STANDARD
aginame		char	"/AvantGarde-BookOblique"

AvantGardeBold	word	FID_PS_AVANTE_GARDE
		byte	length agbname, mask TS_BOLD, AFE_STANDARD
agbname		char	"/AvantGarde-Demi"

AvantGardeBoldObl word	FID_PS_AVANTE_GARDE
		byte	length agbiname, mask TS_BOLD or mask TS_ITALIC, AFE_STANDARD
agbiname	char	"/AvantGarde-DemiOblique"

Courier		word	FID_PS_COURIER
		byte	length cname, 0, AFE_STANDARD
cname		char	"/Courier"

CourierItalic	word	FID_PS_COURIER
		byte	length ciname, mask TS_ITALIC, AFE_STANDARD
ciname		char	"/Courier-Oblique"

CourierBold	word	FID_PS_COURIER
		byte	length cbname, mask TS_BOLD, AFE_STANDARD
cbname		char	"/Courier-Bold"

CourierBoldItalic word	FID_PS_COURIER
		byte	length cbiname, mask TS_BOLD or mask TS_ITALIC, AFE_STANDARD
cbiname		char	"/Courier-BoldOblique"

Symbol		word	FID_PS_SYMBOL
		byte	length syname, 0, AFE_SYMBOL
syname		char	"/Symbol"

ZapfChancery	word	FID_PS_ZAPF_CHANCERY
		byte	length zcname, mask TS_ITALIC, AFE_STANDARD
zcname		char	"/ZapfChancery-MediumItalic"

ZapfDingbats	word	FID_PS_ZAPF_DINGBATS
		byte	length zdname, 0, AFE_SPECIAL
zdname		char	"/ZapfDingbats"

StandardFonts	ends


