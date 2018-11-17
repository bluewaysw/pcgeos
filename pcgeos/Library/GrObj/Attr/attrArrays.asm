COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UI
FILE:		attrArrays.asm

AUTHOR:		Steve Scholl, Nov 15, 1989


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
		

	$Id: attrArrays.asm,v 1.1 97/04/04 18:07:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjAreaAttr	segment	lmem LMEM_TYPE_GENERAL

GOGrObjBaseAreaAttrElements chunk ElementArrayHeader
GOA_base	label	byte
	; Element Array Header
	ElementArrayHeader 	<<1,0,0,size ElementArrayHeader>, 
				EA_FREE_LIST_TERMINATOR>
	; Offset to element
    word GOA_0-GOA_base
	; Data
GOA_NORMAL_AREA_ATTR equ 0
GOA_0	label	byte
	GrObjBaseAreaAttrElement < <<<1,0>>, GOS_NORMAL>, 
			0,0,0,SDM_100,MM_COPY,<PT_SOLID,0>,
			255,255,255,GOAAET_BASE,mask GOAAIR_TRANSPARENT,0,0>
GOGrObjBaseAreaAttrElements endc

GrObjAreaAttr	ends

GrObjLineAttr	segment lmem LMEM_TYPE_GENERAL

GOGrObjBaseLineAttrElements chunk ElementArrayHeader
GOL_base	label	byte
	; Element Array Header
	ElementArrayHeader 	<<1,0,0,size ElementArrayHeader>,
				EA_FREE_LIST_TERMINATOR>
	; Offset to element
    word GOL_0-GOL_base
	; Data
GOL_NORMAL_LINE_ATTR equ 0
GOL_0	label	byte
	GrObjBaseLineAttrElement < <<<1,0>>, GOS_NORMAL>,
			0,0,0,LE_BUTTCAP,LJ_MITERED,
			<0,1>,SDM_100,LS_SOLID,<0xb000,1>,
			GOLAET_BASE,0,45,9,0>
GOGrObjBaseLineAttrElements endc

GrObjLineAttr	ends


GrObjStyle	segment lmem LMEM_TYPE_GENERAL

GOStyles chunk	NameArrayHeader
GOS_base	label	byte
	; Header
    NameArrayHeader <<<1, 0, 0, size NameArrayHeader>,
			EA_FREE_LIST_TERMINATOR>,
			((size GrObjStyleElement)-(size NameArrayElement))>
	; Offsets
    word GOS_0-GOS_base
	; Data
GOS_NORMAL = 0
GOS_0 label byte
    GrObjStyleElement <<<<1, 0>>>, CA_NULL_ELEMENT,
    mask SEF_DISPLAY_IN_TOOLBOX or mask SEF_PROTECTED, <>, <0,0>,
    GOA_NORMAL_AREA_ATTR, GOL_NORMAL_LINE_ATTR>
    lptr NormalString
GOStyles	endc

DBCS <NormalString	chunk.wchar	"Normal",0			>
SBCS <NormalString	chunk.char	"Normal",0			>
	localize	"The name of the normal (default) style", NAME_ARRAY_MAX_NAME_SIZE

GrObjStyle	ends

;---

GrObjCharAttr	segment lmem LMEM_TYPE_GENERAL

GOCharAttrElements chunk TextElementArrayHeader
	CHAR_ATTR_ELEMENT_ARRAY_HEADER 1
GOC_NORMAL_CHAR_ATTR equ 0
	CHAR_ATTR_SS_FONT_SIZE_STYLE_COLOR GOTS_NORMAL, 2, \
				       DEFAULT_GROBJ_FONT, 12, 0, C_BLACK
GOCharAttrElements endc

GrObjCharAttr	ends

GrObjTVCharAttr	segment lmem LMEM_TYPE_GENERAL

GOTVCharAttrElements chunk TextElementArrayHeader
	CHAR_ATTR_ELEMENT_ARRAY_HEADER 1
GOC_NORMAL_CHAR_ATTR equ 0
	CHAR_ATTR_SS_FONT_SIZE_STYLE_COLOR GOTS_NORMAL, 2, \
				       FID_DTC_URW_SANS, 14, 0, C_BLACK
GOTVCharAttrElements endc

GrObjTVCharAttr	ends

;---

GrObjParaAttr	segment	lmem LMEM_TYPE_GENERAL
GOParaAttrElements chunk TextElementArrayHeader
GOP_base	label	byte
	; Element Array Header
	PARA_ATTR_ELEMENT_ARRAY_HEADER 1
	; Offset to element
    word GOP_0-GOP_base
	; Data
GOP_NORMAL_PARA_ATTR equ 0
GOP_0	label	byte
if PZ_PCGEOS
	;sorry, 227 is the magic value for centimeter default tabs
    PARA_ATTR_SS_JUST_LEFT_RIGHT_PARA_TABS GOTS_NORMAL, 2, \
					   J_LEFT, 0, 0, 0, \
					   227, 0
else
    PARA_ATTR_SS_JUST_LEFT_RIGHT_PARA_TABS GOTS_NORMAL, 2, \
					   J_LEFT, 0, 0, 0, \
					   (PIXELS_PER_INCH/2)*8, 0
endif
GOParaAttrElements endc

GrObjParaAttr	ends

;---

GrObjTypeElements	segment	lmem LMEM_TYPE_GENERAL
GOTypeElements chunk TextElementArrayHeader
	; Element Array Header
	TYPE_ELEMENT_ARRAY_HEADER(1)
	; Data
GOT_NORMAL_TYPE = 0
	TYPE_ELEMENT_NONE
GOTypeElements endc

GrObjTypeElements	ends

;---

GrObjGraphicElements	segment	lmem LMEM_TYPE_GENERAL
GOGraphicElements chunk TextElementArrayHeader
	; Element Array Header
	ELEMENT_ARRAY_HEADER TAT_GRAPHICS, VisTextGraphic, <0>
GOGraphicElements endc

GrObjGraphicElements	ends

;---

GrObjNameElements	segment	lmem LMEM_TYPE_GENERAL
GONameElements chunk TextElementArrayHeader
	; name Array Header
	NAME_ARRAY_HEADER(0)
GONameElements endc

GrObjNameElements	ends

;---

GrObjTextStyle	segment lmem LMEM_TYPE_GENERAL

GOTextStyles chunk	NameArrayHeader
GOTS_base	label	byte
	; Header
    NameArrayHeader <<<1, 0, 0, size NameArrayHeader>,
			EA_FREE_LIST_TERMINATOR>,
			((size TextStyleElementHeader)-(size NameArrayElement))>
	; Offsets
    word GOTS_0-GOTS_base
	; Data
GOTS_NORMAL = 0
GOTS_0 label byte
    StyleElementHeader <<<<1, 0>>>, CA_NULL_ELEMENT, 
			mask SEF_DISPLAY_IN_TOOLBOX or mask SEF_PROTECTED, 0>
    word GOC_NORMAL_CHAR_ATTR, GOP_NORMAL_PARA_ATTR
    lptr NormalString2
GOTextStyles	endc

DBCS <NormalString2	chunk.wchar	"Normal",0			>
SBCS <NormalString2	chunk.char	"Normal",0			>
	localize	"The name of the normal (default) text style", NAME_ARRAY_MAX_NAME_SIZE

GrObjTextStyle	ends



