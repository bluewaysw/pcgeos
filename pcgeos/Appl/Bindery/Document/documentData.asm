COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentData.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains template resources to copy

	$Id: documentData.asm,v 1.1 97/04/04 14:38:35 newdeal Exp $

------------------------------------------------------------------------------@

;-----------------------------------------------------------------------------
;		Template to duplicate to create a map block
;-----------------------------------------------------------------------------
;
; WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
;
; The various versions of Studio expect the various element arrays to be
; at certain offsets. If you need to add any chunks to these resources, add
; them to the end, otherwise the files will be incompatible.
;
; WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING

MapBlockTemp segment lmem LMEM_TYPE_GENERAL

MapBlockHeader <
    {},				;MBH_meta -- filled in by esp

    0,				;MBH_charAttrElements -- filled in later
    0,				;MBH_paraAttrElements -- filled in later
    0,				;MBH_graphicElements -- filled in later
    0,				;MBH_typeElements -- filled in later
    0,				;MBH_nameElements -- filled in later
    0,				;MBH_textStyles -- filled in later

    0,				;MBH_lineAttrElements -- filled in later
    0,				;MBH_areaAttrElements -- filled in later
    0,				;MBH_graphicStyles -- filled in later

    0,				;MBH_grobjBlock -- filled in later
    1,				;MBH_startingSectionNum
    0,				;MBH_totalPages
    <>,				;MBH_pageSize -- filled in later
    <PL_paper <PO_PORTRAIT, PT_PAPER>>, ;MBH_pageInfo
    VLTDM_PAGE,			;MBH_displayMode
    0,				;MBH_draftFont
    0,				;MBH_draftPointSize
    <>,				;MBH_invalidRect
    <>,				;MBH_revisionStamp
    0,				;MBH_currentEmulationState
    <>,				;MBH_userSize -- filled in by emulation when necessary
    <400, 300>,			;MBH_customSize
    MiscStudioDocumentFlags <1,0>,  ;MBH_miscFlags
    0,				;MBH_pageNameGraphicID
    <>				;MBH_reserved
>

;---

SectionArray	chunk	byte
_SA_base label byte
        ; Header
    NameArrayHeader <<<1, 0, 0, size NameArrayHeader>,
                        EA_FREE_LIST_TERMINATOR>,
			(size SectionArrayElement) - (size NameArrayElement)>
        ; Offsets
    word _SA_0-_SA_base
        ; Data
_SA_0 label byte
    SectionArrayElement <
	<<<1, 0>>>,		;SAE_meta
	<>,			;SAE_flags
	1,			;SAE_startingPageNum
	1,			;SAE_numMasterPages
	DEFAULT_NUMBER_OF_COLUMNS, ;SAE_numColumns
	DEFAULT_RULE_WIDTH,	;SAE_ruleWidth
	US_DEFAULT_COLUMN_SPACING, ;SAE_columnSpacing
	STUDIO_DEFAULT_DOCUMENT_LEFT_MARGIN, ;SAE_leftMargin -- custom for Studio
	STUDIO_DEFAULT_DOCUMENT_TOP_MARGIN, ;SAE_topMargin -- custom for Studio
	STUDIO_DEFAULT_DOCUMENT_RIGHT_MARGIN, ;SAE_rightMargin -- custom for Studio
	STUDIO_DEFAULT_DOCUMENT_BOTTOM_MARGIN, ;SAE_bottomMargin -- custom for Studio
	<>,			;SAE_masterPages
	0,			;SAE_charsDeleted
	0,			;SAE_linesDeleted
	<0,0>,			;SAE_spaceDeleted
	0,			;SAE_numPages
	<>			;SAE_reserved
    >
    lptr MainSectionName	

SectionArray endc


;---

; The article array starts empty -- we add the main article to it

ArticleArray	chunk	byte
;;;_AA_base label byte
        ; Header
    NameArrayHeader <<<0, 0, 0, size NameArrayHeader>,
                        EA_FREE_LIST_TERMINATOR>,
			(size ArticleArrayElement) - (size NameArrayElement)>
ArticleArray endc

DBCS <MainSectionName	chunk.wchar	"Main Section",0		>
SBCS <MainSectionName	chunk.char	"Main Section",0		>
	localize	"The name of the main section", NAME_ARRAY_MAX_NAME_SIZE

MapBlockTemp ends

;-----------------------------------------------------------------------------
;	Template to duplicate to create line attribute element array
;-----------------------------------------------------------------------------

LineAttrElementTemp	segment lmem LMEM_TYPE_GENERAL

LineAttrElements chunk ElementArrayHeader
GOUIL_base	label	byte
	; Element Array Header
	ElementArrayHeader 	<<6,0,0,size ElementArrayHeader>,
				EA_FREE_LIST_TERMINATOR>
	; Offset to element
    word GOUIL_0-GOUIL_base
    word GOUIL_1-GOUIL_base
    word GOUIL_2-GOUIL_base
    word GOUIL_3-GOUIL_base
    word GOUIL_4-GOUIL_base
    word GOUIL_5-GOUIL_base
	; Data
LINE_ATTR_NORMAL	=	0
GOUIL_0	label	byte
	GrObjBaseLineAttrElement < <<<1,0>>, GRAPHIC_STYLE_NORMAL>,
			0,0,0,LE_BUTTCAP,LJ_MITERED,
			<0,1>,SDM_100,LS_SOLID,<0xb000,1>,
			GOLAET_BASE,0,15,10,0>
LINE_ATTR_FLOW_REGION	=	1
GOUIL_1	label	byte
		; flow regions have a 50% draw mask
	GrObjBaseLineAttrElement < <<<1,0>>, GRAPHIC_STYLE_FLOW_REGION>,
			0,0,0,LE_BUTTCAP,LJ_MITERED,
			<0,0>,SDM_50,LS_SOLID,<0xb000,1>,
			GOLAET_BASE,0,15,10,0>
LINE_ATTR_RULE		=	2
GOUIL_2	label	byte
		; rule lines are 2 wide
	GrObjBaseLineAttrElement < <<<1,0>>, GRAPHIC_STYLE_RULE>,
			0,0,0,LE_BUTTCAP,LJ_MITERED,
			<0,1>,SDM_100,LS_SOLID,<0xb000,1>,
			GOLAET_BASE,0,15,10,0>
LINE_ATTR_HEADER_FOOTER	=	3
GOUIL_3	label	byte
		; rule lines are 1 wide
	GrObjBaseLineAttrElement < <<<1,0>>, GRAPHIC_STYLE_HEADER_FOOTER>,
			0,0,0,LE_BUTTCAP,LJ_MITERED,
			<0,1>,SDM_0,LS_SOLID,<0xb000,1>,
			GOLAET_BASE,0,15,10,0>
LINE_ATTR_WRAP_FRAME	=	4
GOUIL_4	label	byte
		; wrap frames
	GrObjBaseLineAttrElement < <<<1,0>>, GRAPHIC_STYLE_WRAP_FRAME>,
			0,0,0,LE_BUTTCAP,LJ_MITERED,
			<0,1>,SDM_100,LS_SOLID,<0xb000,1>,
			GOLAET_BASE,0,15,10,0>
LINE_ATTR_HOTSPOT	=	5
GOUIL_5	label	byte
		; wrap frames
	GrObjBaseLineAttrElement < <<<1,0>>, GRAPHIC_STYLE_WRAP_FRAME>,
			0,0,0,LE_BUTTCAP,LJ_MITERED,
			<0,0>,SDM_50 or mask SDM_INVERSE,LS_SOLID,<0xb000,1>,
			GOLAET_BASE,0,15,10,0>
LineAttrElements endc

	ForceRef LineAttrElements

LineAttrElementTemp	ends

;-----------------------------------------------------------------------------
;		Template to duplicate to create area attribute element array
;-----------------------------------------------------------------------------

AreaAttrElementTemp	segment	lmem LMEM_TYPE_GENERAL

AreaAttrElements chunk ElementArrayHeader
GOUIA_base	label	byte
	; Element Array Header
	ElementArrayHeader 	<<6,0,0,size ElementArrayHeader>, 
				EA_FREE_LIST_TERMINATOR>
	; Offset to element
    word GOUIA_0-GOUIA_base
    word GOUIA_1-GOUIA_base
    word GOUIA_2-GOUIA_base
    word GOUIA_3-GOUIA_base
    word GOUIA_4-GOUIA_base
    word GOUIA_5-GOUIA_base
	; Data
AREA_ATTR_NORMAL	=	0
GOUIA_0	label	byte
	GrObjBaseAreaAttrElement < <<<1,0>>, GRAPHIC_STYLE_NORMAL>,
			0,0,0,SDM_100,MM_COPY,<PT_SOLID,0>,
			255,255,255,GOAAET_BASE,mask GOAAIR_TRANSPARENT,0,0>
AREA_ATTR_FLOW_REGION	=	1
GOUIA_1	label	byte
		; flow regions have a null draw mask and are transparent
	GrObjBaseAreaAttrElement < <<<1,0>>, GRAPHIC_STYLE_FLOW_REGION>,
			0,0,0,SDM_0,MM_COPY,<PT_SOLID,0>,
			255,255,255,GOAAET_BASE,mask GOAAIR_TRANSPARENT,0,0>
AREA_ATTR_RULE		=	2
GOUIA_2	label	byte
	GrObjBaseAreaAttrElement < <<<1,0>>, GRAPHIC_STYLE_RULE>,
			0,0,0,SDM_100,MM_COPY,<PT_SOLID,0>,
			255,255,255,GOAAET_BASE,mask GOAAIR_TRANSPARENT,0,0>
AREA_ATTR_HEADER_FOOTER	=	3
GOUIA_3	label	byte
	GrObjBaseAreaAttrElement < <<<1,0>>, GRAPHIC_STYLE_HEADER_FOOTER>,
			0,0,0,SDM_100,MM_COPY,<PT_SOLID,0>,
			255,255,255,GOAAET_BASE,mask GOAAIR_TRANSPARENT,0,0>
AREA_ATTR_WRAP_FRAME	=	4
GOUIA_4	label	byte
	GrObjBaseAreaAttrElement < <<<1,0>>, GRAPHIC_STYLE_WRAP_FRAME>,
			0,0,0,SDM_0,MM_COPY,<PT_SOLID,0>,
			255,255,255,GOAAET_BASE,mask GOAAIR_TRANSPARENT,0,0>
AREA_ATTR_HOTSPOT	=	5
GOUIA_5	label	byte
		; flow regions have a null draw mask and are transparent
	GrObjBaseAreaAttrElement < <<<1,0>>, GRAPHIC_STYLE_FLOW_REGION>,
			0,0,0,SDM_0,MM_INVERT,<PT_SOLID,0>,
			255,255,255,GOAAET_BASE,mask GOAAIR_TRANSPARENT,0,0>
AreaAttrElements endc

	ForceRef AreaAttrElements

AreaAttrElementTemp	ends

;-----------------------------------------------------------------------------
;		Template to duplicate to create graphic style array
;-----------------------------------------------------------------------------

GraphicStyleTemp	segment lmem LMEM_TYPE_GENERAL
GraphicStyleArray chunk	NameArrayHeader
GOUIS_base	label	byte
	; Header
    NameArrayHeader <<<5, 0, 0, size NameArrayHeader>,
			EA_FREE_LIST_TERMINATOR>,
			((size GrObjStyleElement)-(size NameArrayElement))>
	; Offsets
    word GOUIS_0-GOUIS_base
    word GOUIS_1-GOUIS_base
    word GOUIS_2-GOUIS_base
    word GOUIS_3-GOUIS_base
    word GOUIS_4-GOUIS_base
	; Data
GRAPHIC_STYLE_NORMAL = 0
GOUIS_0 label byte
    GrObjStyleElement <<<<1, 0>>>, CA_NULL_ELEMENT, mask SEF_PROTECTED, <>, <0,0>,
    AREA_ATTR_NORMAL, LINE_ATTR_NORMAL>
    lptr NormalName	
GRAPHIC_STYLE_FLOW_REGION = 1
GOUIS_1 label byte
    GrObjStyleElement <<<<1, 0>>>, CA_NULL_ELEMENT, mask SEF_PROTECTED, <>, <0,0>,
    AREA_ATTR_FLOW_REGION, LINE_ATTR_FLOW_REGION>
    lptr FlowRegionName
GRAPHIC_STYLE_RULE = 2
GOUIS_2 label byte
    GrObjStyleElement <<<<1, 0>>>, CA_NULL_ELEMENT, mask SEF_PROTECTED, <>, <0,0>,
    AREA_ATTR_RULE, LINE_ATTR_RULE>
    lptr RuleLinesName	
GRAPHIC_STYLE_HEADER_FOOTER = 3
GOUIS_3 label byte
    GrObjStyleElement <<<<1, 0>>>, CA_NULL_ELEMENT, mask SEF_PROTECTED, <>, <0,0>,
    AREA_ATTR_HEADER_FOOTER, LINE_ATTR_HEADER_FOOTER>
    lptr HeaderFooterName
GRAPHIC_STYLE_WRAP_FRAME = 4
GOUIS_4 label byte
    GrObjStyleElement <<<<1, 0>>>, CA_NULL_ELEMENT, mask SEF_PROTECTED, <>, <0,0>,
    AREA_ATTR_WRAP_FRAME, LINE_ATTR_WRAP_FRAME>
    lptr GraphicsFrameName	
GraphicStyleArray	endc

DBCS <NormalName	chunk.wchar	"Normal",0			>
SBCS <NormalName	chunk.char	"Normal",0			>
	localize	"The name of the normal (default) graphics style", NAME_ARRAY_MAX_NAME_SIZE

DBCS <FlowRegionName	chunk.wchar	"Flow Region",0			>
SBCS <FlowRegionName	chunk.char	"Flow Region",0			>
	localize	"The name of the graphics style for flow regions", NAME_ARRAY_MAX_NAME_SIZE

DBCS <RuleLinesName	chunk.wchar	"Rule Lines",0			>
SBCS <RuleLinesName	chunk.char	"Rule Lines",0			>
	localize	"The name of the graphics style for rule lines", NAME_ARRAY_MAX_NAME_SIZE

DBCS <HeaderFooterName	chunk.wchar	"Header / Footer",0		>
SBCS <HeaderFooterName	chunk.char	"Header / Footer",0		>
	localize	"The name of the graphics style for the header/footer", NAME_ARRAY_MAX_NAME_SIZE

DBCS <GraphicsFrameName	chunk.wchar	"Graphics Frame",0		>
SBCS <GraphicsFrameName	chunk.char	"Graphics Frame",0		>
	localize	"The name of the graphics style for graphics frames", NAME_ARRAY_MAX_NAME_SIZE

	ForceRef GraphicStyleArray

GraphicStyleTemp	ends
