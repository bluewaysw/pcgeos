COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Spooler Library
FILE:		libTables.asm

AUTHOR:		Jim DeFrisco, 8 March 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/9/90		Initial revision
	Don	3/12/91		Utilize new macros

DESCRIPTION:
	This file contains code to generate the width, height, and string
	tables required for the paper sizes.

	$Id: libTables.asm,v 1.1 97/04/07 11:11:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Default page size information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeData		segment	lmem LMEM_TYPE_GENERAL

if PZ_PCGEOS
LocalDefString defaultWidthChunk <"595", 0>		; A4
LocalDefString defaultHeightChunk <"842", 0>
else
LocalDefString defaultWidthChunk <"612", 0>		; 8.5 inches
LocalDefString defaultHeightChunk <"792", 0>		; 11 inches
endif
LocalDefString defaultLayoutChunk <"0", 0>		; paper, portrait
if PZ_PCGEOS
LocalDefString defaultMarginLeftChunk <"28", 0>		; 1 cm
LocalDefString defaultMarginTopChunk <"28", 0>		; 1 cm
LocalDefString defaultMarginRightChunk <"28", 0>	; 1 cm
LocalDefString defaultMarginBottomChunk <"28", 0>	; 1 cm
else
LocalDefString defaultMarginLeftChunk <"18", 0>		; 1/4 inch
LocalDefString defaultMarginTopChunk <"18", 0>		; 1/4 inch
LocalDefString defaultMarginRightChunk <"18", 0>	; 1/4 inch
LocalDefString defaultMarginBottomChunk <"18", 0>	; 1/4 inch
endif

PageSizeData		ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Paper size strings, and default order array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Add new paper sizes by adding another "AddPaperSize" invocation,
; and supplying the appropriate width, height, string, layout, and PaperSizes
; enumeration. You must add the string in ascending width order!!

PAPER_PORTRAIT		equ	PageLayoutPaper<PO_PORTRAIT, PT_PAPER>

PAPER_LANDSCAPE		equ	PageLayoutPaper<PO_LANDSCAPE, PT_PAPER>


AddPaperTable	PaperSizes, paperWidths, paperHeights, paperLayouts

AddPaperSize        0,    0,	PAPER_PORTRAIT, PS_CUSTOM, \
 				"Custom"
AddPaperSize	   73,  105,	PAPER_PORTRAIT, PS_A10, \
				"A10"
AddPaperSize	   88,  125,	PAPER_PORTRAIT, PS_ISO_B10, \
				"ISO B10"
AddPaperSize	   91,  127,	PAPER_PORTRAIT, PS_JIS_B10, \
				"JIS B10"
AddPaperSize	  105,  148,	PAPER_PORTRAIT, PS_A9, \
				"A9"
AddPaperSize	  125,  176,	PAPER_PORTRAIT, PS_ISO_B9, \
				"ISO B9"
AddPaperSize	  127,  181,	PAPER_PORTRAIT, PS_JIS_B9, \
				"JIS B9"
AddPaperSize	  148,  210,	PAPER_PORTRAIT, PS_A8, \
				"A8"
AddPaperSize	  176,  249,	PAPER_PORTRAIT, PS_ISO_B8, \
				"ISO B8"
AddPaperSize	  181,  258,	PAPER_PORTRAIT, PS_JIS_B8, \
				"JIS B8"
AddPaperSize	  210,  297,	PAPER_PORTRAIT, PS_A7, \
				"A7"
AddPaperSize	  249,  354,	PAPER_PORTRAIT, PS_ISO_B7, \
				"ISO B7"
AddPaperSize	  258,  363,	PAPER_PORTRAIT, PS_JIS_B7, \
				"JIS B7"
AddPaperSize	  297,  420,	PAPER_PORTRAIT, PS_A6, \
				"A6"
AddPaperSize	  354,  499,	PAPER_PORTRAIT, PS_ISO_B6, \
				"ISO B6"
AddPaperSize	  363,  516,	PAPER_PORTRAIT, PS_JIS_B6, \
				"JIS B6"
AddPaperSize	  396,  612,	PAPER_PORTRAIT, PS_STATEMENT, \
				"Statement"
AddPaperSize	  420,  595,	PAPER_PORTRAIT, PS_A5, \
				"A5 Size"
AddPaperSize	  499,  709,	PAPER_PORTRAIT, PS_ISO_B5, \
				"ISO B5 Letter"
AddPaperSize	  504,  648,	PAPER_PORTRAIT, PS_7x9, \
				"7 x 9"
AddPaperSize	  516,  729,	PAPER_PORTRAIT, PS_JIS_B5, \
				"JIS B5 Letter"
AddPaperSize	  538,  781,	PAPER_PORTRAIT, PS_A4_SMALL, \
				"A4 Letter Centered"
if _NIKE_EUROPE
AddPaperSize	  522,  756,	PAPER_PORTRAIT, PS_EXECUTIVE, \
				"Executive"
else
AddPaperSize	  540,  720,	PAPER_PORTRAIT, PS_EXECUTIVE, \
				"Executive"
endif
AddPaperSize	  553,  731,	PAPER_PORTRAIT, PS_LETTER_SMALL, \
				"US Letter Centered"
AddPaperSize	  595,  842,	PAPER_PORTRAIT, PS_A4, \
				"A4 Letter"
AddPaperSize	  595,  842,	PAPER_PORTRAIT, PS_USO_BOLLO, \
				"Uso Bollo - 4 faces"
AddPaperSize	  595,  842,	PAPER_PORTRAIT, PS_PROTOCOLLO, \
				"Protocollo - 4 faces"
AddPaperSize	  595,  864,	PAPER_PORTRAIT, PS_A4_GERMAN, \
				"German A4"
AddPaperSize	  610,  780,	PAPER_PORTRAIT, PS_QUARTO, \
				"Quarto"
AddPaperSize	  612,  792,	PAPER_PORTRAIT, PS_LETTER, \
			  	"US Letter"
AddPaperSize	  612,  936,	PAPER_PORTRAIT, PS_FOLIO, \
				"Folio"
AddPaperSize	  612, 1008,	PAPER_PORTRAIT, PS_LEGAL, \
				"US Legal"
AddPaperSize	  648,  792,	PAPER_PORTRAIT, PS_9x11, \
				"9 in x 11 in"
AddPaperSize	  648,  864,	PAPER_PORTRAIT, PS_9x12, \
				"9 in x 12 in"
AddPaperSize	  680,  792,	PAPER_PORTRAIT, PS_24CMx11IN, \
				"24 cm x 11 in (Italian)"
AddPaperSize	  680,  864,	PAPER_PORTRAIT, PS_24CMx12IN, \
				"24 cm x 12 in (Italian)"
AddPaperSize	  709, 1001,	PAPER_PORTRAIT, PS_ISO_B4, \
				"B4 (ISO)"
AddPaperSize	  720,  936,	PAPER_PORTRAIT, PS_10x13, \
				"10 x 13"
AddPaperSize	  720, 1008,	PAPER_PORTRAIT, PS_10x14, \
				"10 x 14"
AddPaperSize	  729, 1032,	PAPER_PORTRAIT, PS_JIS_B4, \
				"JIS B4"
AddPaperSize	  792,  612,	PAPER_LANDSCAPE, PS_A_SIZE, \
				"A Size (US Letter Rotated)"
AddPaperSize	  792, 1008,	PAPER_PORTRAIT, PS_11x14, \
				"11 in x 14 in"
AddPaperSize	  792, 1063,	PAPER_PORTRAIT, PS_11INx37_5CM, \
				"11 in x 37.5 cm (Italian)"
AddPaperSize	  792, 1224,	PAPER_PORTRAIT, PS_B_SIZE, \
				"B Size/Tabloid/Ledger"
AddPaperSize	  842, 1191,	PAPER_PORTRAIT, PS_A3, \
				"A3 Size"
AddPaperSize	  864, 1063,	PAPER_PORTRAIT, PS_12INx37_5CM, \
				"12 in x 37.5 cm (Italian)"
AddPaperSize	 1001, 1417,	PAPER_PORTRAIT, PS_ISO_B3, \
				"ISO B3"
AddPaperSize	 1032, 1460,	PAPER_PORTRAIT, PS_JIS_B3, \
				"JIS B3"
AddPaperSize	 1191, 1684,	PAPER_PORTRAIT, PS_A2, \
				"A2"
AddPaperSize	 1584, 1224,	PAPER_LANDSCAPE, PS_C_SIZE, \
				"C Size"
AddPaperSize	 1417, 2004,	PAPER_PORTRAIT, PS_ISO_B2, \
				"ISO B2"
AddPaperSize	 1460, 2064,	PAPER_PORTRAIT, PS_JIS_B2, \
				"JIS B2"
AddPaperSize	 2448, 1584,	PAPER_LANDSCAPE, PS_D_SIZE, \
				"D Size"
AddPaperSize	 1684, 2384,	PAPER_PORTRAIT, PS_A1, \
				"A1"
AddPaperSize	 2004, 2835,	PAPER_PORTRAIT, PS_ISO_B1, \
				"ISO B1"
AddPaperSize	 2064, 2920,	PAPER_PORTRAIT, PS_JIS_B1, \
				"JIS B1"
AddPaperSize	 2384, 3370,	PAPER_PORTRAIT, PS_A0, \
				"A0"
AddPaperSize	 3168, 2448,	PAPER_LANDSCAPE, PS_E_SIZE, \
				"E Size"
AddPaperSize	 2835, 4008,	PAPER_PORTRAIT, PS_ISO_B0, \
				"ISO B0"
AddPaperSize	 2920, 4127,	PAPER_PORTRAIT, PS_JIS_B0, \
				"JIS B0"

EndPaperTable	PaperSizes

PageSizeData		segment	lmem LMEM_TYPE_GENERAL
if	_GPC
DefaultPaperOrder	chunk	byte
	MakeDefaultOrderEntry	%PS_LETTER
	MakeDefaultOrderEntry	%PS_LEGAL
	MakeDefaultOrderEntry	%PS_A_SIZE
	MakeDefaultOrderEntry	%PS_B_SIZE
	MakeDefaultOrderEntry	%PS_STATEMENT
	MakeDefaultOrderEntry	%PS_EXECUTIVE
	MakeDefaultOrderEntry	%PS_QUARTO
	MakeDefaultOrderEntry	%PS_FOLIO
	MakeDefaultOrderEntry	%PS_A3
	MakeDefaultOrderEntry	%PS_A4
	MakeDefaultOrderEntry	%PS_A4_GERMAN
	MakeDefaultOrderEntry	%PS_A5
DefaultPaperOrder	endc
elseif	_NIKE_EUROPE
DefaultPaperOrder	chunk	byte
	MakeDefaultOrderEntry	%PS_A4
	MakeDefaultOrderEntry	%PS_A5
	MakeDefaultOrderEntry	%PS_A3
	MakeDefaultOrderEntry	%PS_LETTER
	MakeDefaultOrderEntry	%PS_LEGAL
	MakeDefaultOrderEntry	%PS_EXECUTIVE
	MakeDefaultOrderEntry	%PS_ISO_B5
DefaultPaperOrder	endc
elseif	PZ_PCGEOS
DefaultPaperOrder	chunk	byte
	MakeDefaultOrderEntry	%PS_A4
	MakeDefaultOrderEntry	%PS_JIS_B5
	MakeDefaultOrderEntry	%PS_A3
	MakeDefaultOrderEntry	%PS_A5
	MakeDefaultOrderEntry	%PS_JIS_B4
	MakeDefaultOrderEntry	%PS_JIS_B3
DefaultPaperOrder	endc
else
DefaultPaperOrder	chunk	byte
	MakeDefaultOrderEntry	%PS_LETTER
	MakeDefaultOrderEntry	%PS_LEGAL
	MakeDefaultOrderEntry	%PS_A4
	MakeDefaultOrderEntry	%PS_JIS_B5
	MakeDefaultOrderEntry	%PS_A4_GERMAN
	MakeDefaultOrderEntry	%PS_STATEMENT
	MakeDefaultOrderEntry	%PS_A3
	MakeDefaultOrderEntry	%PS_A5
	MakeDefaultOrderEntry	%PS_11x14
	MakeDefaultOrderEntry	%PS_A_SIZE
	MakeDefaultOrderEntry	%PS_B_SIZE
	MakeDefaultOrderEntry	%PS_C_SIZE
	MakeDefaultOrderEntry	%PS_D_SIZE
	MakeDefaultOrderEntry	%PS_E_SIZE
	MakeDefaultOrderEntry	%PS_JIS_B4
	MakeDefaultOrderEntry	%PS_JIS_B3
	MakeDefaultOrderEntry	%PS_QUARTO
	MakeDefaultOrderEntry	%PS_EXECUTIVE
	MakeDefaultOrderEntry	%PS_FOLIO
	MakeDefaultOrderEntry	%PS_10x14
DefaultPaperOrder	endc
endif
PageSizeData		ends


			
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Envelope size strings, and default order array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ENV_PORTRAIT_LEFT	equ	\
		PageLayoutEnvelope<EO_PORTRAIT, PT_ENVELOPE>

ENV_LANDSCAPE_UP	equ	\
		PageLayoutEnvelope<EO_LANDSCAPE, PT_ENVELOPE>


AddPaperTable	EnvelopeSizes, envelopeWidths, envelopeHeights, envelopeLayouts

AddPaperSize        0,    0,	ENV_LANDSCAPE_UP, ES_CUSTOM, \
 				"Custom"
AddPaperSize	  323,  230,	ENV_LANDSCAPE_UP, ES_ENVELOPE_C7, \
				"Envelope C7"
AddPaperSize	  459,  323,	ENV_LANDSCAPE_UP, ES_ENVELOPE_C6, \
				"Envelope C6"
AddPaperSize	  468,  261,	ENV_LANDSCAPE_UP, ES_ENVELOPE_6, \
				"Letter Envelope (#6)"
AddPaperSize	  510,  340,	ENV_LANDSCAPE_UP, ES_BUSTA_ORD, \
				"Busta Ordinaria"
AddPaperSize	  540,  279,	ENV_LANDSCAPE_UP, ES_ENVELOPE_MONARCH, \
				"Monarch Envelope"
AddPaperSize	  581,  255,	ENV_LANDSCAPE_UP, ES_ENVELOPE_LONG4, \
				"Envelope 90 x 205"
AddPaperSize	  624,  312,	ENV_LANDSCAPE_UP, ES_ENVELOPE_DL, \
				"Envelope DL"
AddPaperSize	  639,  279,	ENV_LANDSCAPE_UP, ES_ENVELOPE_9, \
				"Envelope #9"
AddPaperSize	  648,  864,	ENV_LANDSCAPE_UP, ES_ENVELOPE_9x12, \
				"Envelope 9in x 12in"
AddPaperSize	  649,  459,	ENV_LANDSCAPE_UP, ES_ENVELOPE_C5, \
				"Envelope C5"
AddPaperSize	  652,  312,	ENV_LANDSCAPE_UP, ES_BUSTA_COM, \
				"Busta Commerciale"
AddPaperSize	  652,  459,	ENV_LANDSCAPE_UP, ES_ENVELOPE_A5, \
				"Envelope A5"
AddPaperSize	  666,  340,	ENV_LANDSCAPE_UP, ES_ENVELOPE_LONG3, \
				"Envelope 120 x 235"
AddPaperSize	  684,  297,	ENV_LANDSCAPE_UP, ES_ENVELOPE_10, \
				"Business Envelope (#10)"
AddPaperSize	  747,  324,	ENV_LANDSCAPE_UP, ES_ENVELOPE_11, \
				"Envelope #11"
AddPaperSize	  792,  342,	ENV_LANDSCAPE_UP, ES_ENVELOPE_12, \
				"Envelope #12"
AddPaperSize	  828,  360,	ENV_LANDSCAPE_UP, ES_ENVELOPE_14, \
				"Envelope #14"
AddPaperSize	  918,  649,	ENV_LANDSCAPE_UP, ES_ENVELOPE_C4, \
				"Envelope C4"
AddPaperSize	  935,  737,	ENV_LANDSCAPE_UP, ES_ENVELOPE_A4, \
				"Envelope A4"
AddPaperSize	 1296,  918,	ENV_LANDSCAPE_UP, ES_ENVELOPE_C3, \
				"Envelope C3"
AddPaperSize	 1837, 1298,	ENV_LANDSCAPE_UP, ES_ENVELOPE_C2, \
				"Envelope C2"
AddPaperSize	 2599, 1837,	ENV_LANDSCAPE_UP, ES_ENVELOPE_C1, \
				"Envelope C1"
AddPaperSize	 3676, 2599,	ENV_LANDSCAPE_UP, ES_ENVELOPE_C0, \
				"Envelope CO"
EndPaperTable	EnvelopeSizes

PageSizeData		segment	lmem LMEM_TYPE_GENERAL
if	_GPC
DefaultEnvelopeOrder	chunk	byte
	MakeDefaultOrderEntry	%ES_ENVELOPE_6
	MakeDefaultOrderEntry	%ES_ENVELOPE_10
	MakeDefaultOrderEntry	%ES_ENVELOPE_MONARCH
	MakeDefaultOrderEntry	%ES_ENVELOPE_9
	MakeDefaultOrderEntry	%ES_ENVELOPE_11
	MakeDefaultOrderEntry	%ES_ENVELOPE_12
	MakeDefaultOrderEntry	%ES_ENVELOPE_14
	MakeDefaultOrderEntry	%ES_ENVELOPE_C7
	MakeDefaultOrderEntry	%ES_ENVELOPE_C6
	MakeDefaultOrderEntry	%ES_ENVELOPE_C5
	MakeDefaultOrderEntry	%ES_ENVELOPE_C4
	MakeDefaultOrderEntry	%ES_ENVELOPE_DL
	MakeDefaultOrderEntry	%ES_ENVELOPE_A5
	MakeDefaultOrderEntry	%ES_ENVELOPE_A4
DefaultEnvelopeOrder	endc
elseif	_NIKE_EUROPE
DefaultEnvelopeOrder	chunk	byte
	MakeDefaultOrderEntry	%ES_ENVELOPE_C5
	MakeDefaultOrderEntry	%ES_ENVELOPE_DL
	MakeDefaultOrderEntry	%ES_ENVELOPE_6
	MakeDefaultOrderEntry	%ES_ENVELOPE_9
	MakeDefaultOrderEntry	%ES_ENVELOPE_10
	MakeDefaultOrderEntry	%ES_ENVELOPE_11
	MakeDefaultOrderEntry	%ES_ENVELOPE_12
	MakeDefaultOrderEntry	%ES_ENVELOPE_14
	MakeDefaultOrderEntry	%ES_ENVELOPE_9x12
DefaultEnvelopeOrder	endc
elseif PZ_PCGEOS
DefaultEnvelopeOrder	chunk	byte
	MakeDefaultOrderEntry	%ES_ENVELOPE_LONG3
	MakeDefaultOrderEntry	%ES_ENVELOPE_LONG4
DefaultEnvelopeOrder	endc
else
DefaultEnvelopeOrder	chunk	byte
	MakeDefaultOrderEntry	%ES_ENVELOPE_6
	MakeDefaultOrderEntry	%ES_ENVELOPE_9
	MakeDefaultOrderEntry	%ES_ENVELOPE_10
	MakeDefaultOrderEntry	%ES_ENVELOPE_11
	MakeDefaultOrderEntry	%ES_ENVELOPE_12
	MakeDefaultOrderEntry	%ES_ENVELOPE_14
	MakeDefaultOrderEntry	%ES_ENVELOPE_9x12
	MakeDefaultOrderEntry	%ES_ENVELOPE_C7
	MakeDefaultOrderEntry	%ES_ENVELOPE_C6
	MakeDefaultOrderEntry	%ES_ENVELOPE_C5
	MakeDefaultOrderEntry	%ES_ENVELOPE_C4
	MakeDefaultOrderEntry	%ES_ENVELOPE_C3
	MakeDefaultOrderEntry	%ES_ENVELOPE_C2
	MakeDefaultOrderEntry	%ES_ENVELOPE_C1
	MakeDefaultOrderEntry	%ES_ENVELOPE_C0
	MakeDefaultOrderEntry	%ES_ENVELOPE_DL
	MakeDefaultOrderEntry	%ES_ENVELOPE_A5
	MakeDefaultOrderEntry	%ES_ENVELOPE_A4
DefaultEnvelopeOrder	endc
endif
PageSizeData		ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Label size strings, and default order array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddPaperTable	LabelSizes, labelWidths, labelHeights, labelLayouts

AddPaperSize	     0,    0,	<label>, LSS_CUSTOM, \
 				"Custom", 1, 1
AddPaperSize	   120,  120,	<label>, LS_1_67_ROUND, \
				"1 2/3in Round", 4, 6
AddPaperSize	   126,   36,	<label>, LS__5x1_75, \
				"1 3/4in x 1/2in", 4, 20
AddPaperSize	   180,  180,	<label>, LS_2_5_ROUND, \
				"2 1/2in Round", 3, 4
AddPaperSize	   189,   72,	<label>, LS_1x2_625, \
				"Avery #8160 (2 5/8in x 1in)", 3, 10
if	_NIKE_EUROPE
AddPaperSize	   198,   99,	<label>, LS_SBM_24S, \
				"70mm x 35mm", 3, 8
endif

AddPaperSize	   198,  144,	<label>, LS_DISK_3_5_SHORT, \
				"3 1/2in Disk", 1, 2
AddPaperSize	   198,  198,	<label>, LS_DISK_3_5, \
				"3 1/2in Disk", 3, 1
				;Set to one-high since the labels are not
				;centered, and therefore problematic.  This
				;is the best current workaround. This was the
				;size we used for Redwood

AddPaperSize	   204,   72,	<label>, LS_1x2_833, \
				"2 5/6in x 1in", 3, 10
AddPaperSize	   220,  132,	<label>, LS_VIDEO_FACE, \
				"Videotape Face", 2, 5
AddPaperSize	   240,  240,	<label>, LS_3_33_ROUND, \
				"3 1/3in Round", 2, 3
AddPaperSize	   243,  168,	<label>, LS_NAME, \
				"Name Badge", 2, 4
AddPaperSize	   247,   48,	<label>, LS_FOLDER, \
				"File Folder", 2, 15
AddPaperSize	   252,  117,	<label>, LS_AUDIO, \
				"Audio Tape", 2, 6
AddPaperSize	   252,  156,	<label>, LS_CARD_2_17x3_5, \
				"Name Tag", 2, 4
AddPaperSize	   252,  360,	<label>, LS_5x3_5, \
				"Avery #5168 (3.5in x 5in)", 2, 2
if	_NIKE_EUROPE
AddPaperSize	   281,  192,	<label>, LS_SDM_8S, \
				"99.1mm x 67.7mm", 2, 4
endif

AddPaperSize	   288,   72,	<label>, LS_1x4, \
				"4in x 1in", 2, 10
AddPaperSize	   288,   96,	<label>, LS_1_33x4, \
				"4in x 1 1/3in", 2, 7
AddPaperSize	   288,  104,	<label>, LS_DISK_5_25, \
				"5 1/4in Disk", 2, 6
AddPaperSize	   288,  144,	<label>, LS_2x4, \
				"Avery #8163 (4in x 2in)", 2, 5
AddPaperSize	   288,  156,	<label>, LS_ROTARY_CARD, \
				"Rotary Card", 2, 4
AddPaperSize	   288,  216,	<label>, LS_CARD_3x4, \
				"4in x 3in", 2, 3
AddPaperSize	   288,  240,	<label>, LS_3_33x4, \
				"Avery #8164 (4in x 3 1/3in)", 2, 3
if	_NIKE_EUROPE
AddPaperSize	   297,  108,	<label>, LS_SBM_14S, \
				"105mm x 38mm", 2, 7
AddPaperSize	   297,  384,	<label>, LS_SBM_4S, \
				"105mm x 148mm", 2, 2
endif

AddPaperSize	   306,   96,	<label>, LS_1_33x4_25, \
				"4 1/4in x 1 1/3in", 2, 7
AddPaperSize	   306,  144,	<label>, LS_2x4_25, \
				"4 1/4in x 2in", 2, 5
AddPaperSize	   360,  216,	<label>, LS_INDEX_CARD, \
				"Index Card", 1, 3
AddPaperSize	   418,   48,	<label>, LS_VIDEO_SPINE, \
				"Videotape Spine", 1, 15
AddPaperSize	   432,  288,	<label>, LS_POST_CARD, \
				"Post Card", 1, 2
AddPaperSize	   612,  784,	<label>, LS_8_5x11, \
				"US Letter", 1, 1

EndPaperTable	LabelSizes



PageSizeData		segment	lmem LMEM_TYPE_GENERAL
if	_GPC
DefaultLabelOrder	chunk	byte
	MakeDefaultOrderEntry	%LS_1x2_625
	MakeDefaultOrderEntry	%LS_2x4
	MakeDefaultOrderEntry	%LS_3_33x4
	MakeDefaultOrderEntry	%LS_5x3_5
	MakeDefaultOrderEntry	%LS_1x2_833
	MakeDefaultOrderEntry	%LS_1x4
	MakeDefaultOrderEntry	%LS_1_33x4
	MakeDefaultOrderEntry	%LS_CARD_3x4
	MakeDefaultOrderEntry	%LS_1_33x4_25
	MakeDefaultOrderEntry	%LS_2x4_25

	MakeDefaultOrderEntry	%LS_DISK_3_5
	MakeDefaultOrderEntry	%LS_VIDEO_FACE
	MakeDefaultOrderEntry	%LS_VIDEO_SPINE

	MakeDefaultOrderEntry	%LS_NAME
	MakeDefaultOrderEntry	%LS_INDEX_CARD
DefaultLabelOrder	endc
elseif	_NIKE_EUROPE
DefaultLabelOrder	chunk	byte
	MakeDefaultOrderEntry	%LS_SBM_24S
	MakeDefaultOrderEntry	%LS_SDM_8S
	MakeDefaultOrderEntry	%LS_SBM_14S
	MakeDefaultOrderEntry	%LS_SBM_4S
DefaultLabelOrder	endc
else
DefaultLabelOrder	chunk	byte
	MakeDefaultOrderEntry	%LS__5x1_75
	MakeDefaultOrderEntry	%LS_1x2_625
	MakeDefaultOrderEntry	%LS_1x2_833
	MakeDefaultOrderEntry	%LS_1x4
	MakeDefaultOrderEntry	%LS_1_33x4
	MakeDefaultOrderEntry	%LS_2x4
	MakeDefaultOrderEntry	%LS_CARD_3x4
	MakeDefaultOrderEntry	%LS_3_33x4
	MakeDefaultOrderEntry	%LS_1_33x4_25
	MakeDefaultOrderEntry	%LS_2x4_25
	MakeDefaultOrderEntry	%LS_8_5x11

	MakeDefaultOrderEntry	%LS_DISK_3_5
	MakeDefaultOrderEntry	%LS_DISK_5_25

	MakeDefaultOrderEntry	%LS_VIDEO_FACE
	MakeDefaultOrderEntry	%LS_VIDEO_SPINE
	MakeDefaultOrderEntry	%LS_AUDIO

	MakeDefaultOrderEntry	%LS_1_67_ROUND
	MakeDefaultOrderEntry	%LS_2_5_ROUND
	MakeDefaultOrderEntry	%LS_3_33_ROUND

	MakeDefaultOrderEntry	%LS_NAME
	MakeDefaultOrderEntry	%LS_ROTARY_CARD
	MakeDefaultOrderEntry	%LS_INDEX_CARD
	MakeDefaultOrderEntry	%LS_POST_CARD
	MakeDefaultOrderEntry	%LS_CARD_2_17x3_5
	MakeDefaultOrderEntry	%LS_FOLDER
DefaultLabelOrder	endc
endif
PageSizeData		ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Postcard size strings, and default order array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

POSTCARD_PORTRAIT equ	PageLayoutPaper<PCO_PORTRAIT, PT_POSTCARD>

POSTCARD_LANDSCAPE equ	PageLayoutPaper<PCO_LANDSCAPE, PT_POSTCARD>

AddPaperTable	PostcardSizes, postcardWidths, postcardHeights, postcardLayouts

AddPaperSize        0,    0,	POSTCARD_PORTRAIT, PCS_CUSTOM, \
 				"Custom"
AddPaperSize	  420,  284,	POSTCARD_PORTRAIT, PCS_J_CARD, \
				"J Postcard 100 x 148"
AddPaperSize	  567,	420,	POSTCARD_LANDSCAPE, PCS_J_CARD2, \
				"J Postcard 148 x 200"

EndPaperTable	PostcardSizes

PageSizeData		segment	lmem LMEM_TYPE_GENERAL
DefaultPostcardOrder	chunk	byte
	MakeDefaultOrderEntry	%PCS_J_CARD
	MakeDefaultOrderEntry	%PCS_J_CARD2
DefaultPostcardOrder	endc
PageSizeData		ends
