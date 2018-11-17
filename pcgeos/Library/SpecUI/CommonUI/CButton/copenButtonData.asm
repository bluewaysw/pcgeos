COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (common code for several specific ui's)
FILE:		openButtonData.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	7/89		Motif extensions, more documentation
	JimG	4/94		Added extensions for Stylus

DESCRIPTION:
	This file contains data for drawing open look buttons.

	$Id: copenButtonData.asm,v 1.4 98/05/04 06:40:20 joon Exp $
------------------------------------------------------------------------------@


;------------------------------------------------------------------------------
;		Button Geometry And Region Definition Tables
;------------------------------------------------------------------------------
;The tables below are used by OLButtonChooseRegionSet (copenButton.asm)
;to indicate to the OLButtonDraw*** routines which region definition
;should be used to draw the button border and interior.  Also provides
;information about how to place the vis moniker.
;THESE TABLES ARE ALSO USED FOR GEOMETRY, SO KEEP THEM IN IDATA.

idata	segment


if _OL_STYLE	;--------------------------------------------------------------

OLBWButtonRegionSet_normal	label	BWButtonRegionSetStruct
	word	OLBWButton_normalBorder
	word	OLBWButton_normalInterior
	byte	(J_LEFT shl offset DMF_X_JUST) or \
		(J_CENTER shl offset DMF_Y_JUST)
	byte	BUTTON_INSET_X
	byte	BUTTON_INSET_Y
	byte	BUTTON_INSET_Y

OLBWButtonRegionSet_default	label	BWButtonRegionSetStruct
	word	OLBWButton_defaultBorder
	word	OLBWButton_normalInterior
	byte	(J_LEFT shl offset DMF_X_JUST) or \
		(J_CENTER shl offset DMF_Y_JUST)
	byte	BUTTON_INSET_X
	byte	BUTTON_INSET_Y
	byte	BUTTON_INSET_Y

endif		;--------------------------------------------------------------

if _CUA_STYLE

MOBWButtonRegionSet_normButton	label	BWButtonRegionSetStruct
	word	MOBWButton_normalBorder
	word	MOBWButton_normalInterior
if _ROUND_NORMAL_BW_BUTTONS
	word	STBWButton_normalBackground
endif ;_ROUND_NORMAL_BW_BUTTONS
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)

	byte	MO_BUTTON_INSET_X
	byte	MO_BUTTON_INSET_Y
MO <	byte	MO_BUTTON_MIN_HEIGHT					>
ISU <	byte	MO_BUTTON_MIN_HEIGHT					>
NOT_MO<	byte	CUA_BUTTON_MIN_HEIGHT					>
if _ROUND_NORMAL_BW_BUTTONS
	byte	ST_NORMAL_BUTTON_INSET_Y_CGA
   	byte	ST_NORMAL_BUTTON_INSET_X_NARROW
else
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW
endif

;  This is for the STYLUS UI, which turns on MOTIF, and thus turns on
;  CUA_STYLE.  It is okay to be here.
if _THICK_DROP_MENU_BW_BUTTONS

STBWButtonRegionSet_thickDropMenuButton	label	BWButtonRegionSetStruct
	word	STBWButton_thickDropMenuBorder	
	word	STBWButton_thickDropMenuInterior	
if _ROUND_NORMAL_BW_BUTTONS
	word	0
endif ;_ROUND_NORMAL_BW_BUTTONS
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)

	byte	MO_BUTTON_INSET_X
	byte	MO_BUTTON_INSET_Y
MO <	byte	MO_BUTTON_MIN_HEIGHT					>
ISU <	byte	MO_BUTTON_MIN_HEIGHT					>
NOT_MO<	byte	CUA_BUTTON_MIN_HEIGHT					>
	byte	ST_THICK_DROP_MENU_BUTTON_INSET_Y_CGA
   	byte	ST_THICK_DROP_MENU_BUTTON_INSET_X_NARROW

endif ;_THICK_DROP_MENU_BW_BUTTONS

MOBWButtonRegionSet_defButton	label	BWButtonRegionSetStruct
	word	MOBWButton_defaultBorder
	word	MOBWButton_defaultInterior
if _ROUND_NORMAL_BW_BUTTONS
	word	0
endif ;_ROUND_NORMAL_BW_BUTTONS
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST) 
	byte	MO_BUTTON_INSET_X
	byte	MO_BUTTON_INSET_Y
MO <	byte	MO_BUTTON_MIN_HEIGHT					>
ISU <	byte	MO_BUTTON_MIN_HEIGHT					>
NOT_MO<	byte	CUA_BUTTON_MIN_HEIGHT					>
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW


if _MOTIF	;--------------------------------------------------------------

;Motif reply bar button region structures

MOBWButtonRegionSet_replyButton	label	BWButtonRegionSetStruct
	word	MOBWButton_replyBorder
	word	MOBWButton_replyInterior
if _ROUND_NORMAL_BW_BUTTONS
	word	0
endif ;_ROUND_NORMAL_BW_BUTTONS
	byte	(J_CENTER shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
	byte	MO_REPLY_BUTTON_INSET_X
	byte	MO_BUTTON_INSET_Y
MO <	byte	MO_BUTTON_MIN_HEIGHT+MO_REPLY_BUTTON_INSET_Y	>
NOT_MO<	byte	CUA_BUTTON_MIN_HEIGHT				>
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW

MOBWButtonRegionSet_defReplyButton	label	BWButtonRegionSetStruct
	word	MOBWButton_defReplyBorder
	word	MOBWButton_replyInterior
if _ROUND_NORMAL_BW_BUTTONS
	word	0
endif ;_ROUND_NORMAL_BW_BUTTONS
	byte	(J_CENTER shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST) 
	byte	MO_REPLY_BUTTON_INSET_X
	byte	MO_REPLY_BUTTON_INSET_Y
MO <	byte	MO_BUTTON_MIN_HEIGHT+MO_REPLY_BUTTON_INSET_Y	>
NOT_MO<	byte	CUA_BUTTON_MIN_HEIGHT				>
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW

MOCGAButtonRegionSet_replyButton	label	BWButtonRegionSetStruct
	word	MOCGAButton_replyBorder
	word	MOCGAButton_replyInterior
if _ROUND_NORMAL_BW_BUTTONS
	word	0
endif ;_ROUND_NORMAL_BW_BUTTONS
	byte	(J_CENTER shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
	byte	MO_REPLY_BUTTON_INSET_X
	byte	MO_BUTTON_INSET_Y_CGA
MO <	byte	MO_BUTTON_MIN_HEIGHT+MO_REPLY_BUTTON_INSET_Y	>
NOT_MO<	byte	CUA_BUTTON_MIN_HEIGHT				>
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW

MOCGAButtonRegionSet_defReplyButton	label	BWButtonRegionSetStruct
	word	MOCGAButton_defReplyBorder
	word	MOCGAButton_replyInterior
if _ROUND_NORMAL_BW_BUTTONS
	word	0
endif ;_ROUND_NORMAL_BW_BUTTONS
	byte	(J_CENTER shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST) 
	byte	MO_REPLY_BUTTON_INSET_X
	byte	MO_BUTTON_INSET_Y_CGA
MO <	byte	MO_BUTTON_MIN_HEIGHT+MO_REPLY_BUTTON_INSET_Y	>
NOT_MO<	byte	CUA_BUTTON_MIN_HEIGHT				>
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW


	;
	; PCV style buttons
	;
if _EDGE_STYLE_BUTTONS and not _ROUND_NORMAL_BW_BUTTONS
MOBWButtonRegionSet_upperRightButton	label	BWButtonRegionSetStruct
	word	MOBWButton_upperRightBorder
	word	MOBWButton_upperRightInterior
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
	byte	3			; x inset
	byte	3			; y inset
	byte	MO_BUTTON_MIN_HEIGHT
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW
	byte	1			; right inset
	byte	2			; bottom inset

	byte	1			; graphic x inset
	byte	0			; graphic y inset
	byte	0			; graphic right inset
	byte	2			; graphic bottom inset

MOBWButtonRegionSet_lowerRightButton	label	BWButtonRegionSetStruct
	word	MOBWButton_lowerRightBorder
	word	MOBWButton_lowerRightInterior
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
	byte	3			; x inset
	byte	2			; y inset
	byte	MO_BUTTON_MIN_HEIGHT
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW
	byte	1			; right inset
	byte	4			; bottom inset

	byte	1			; graphic x inset
	byte	0			; graphic y inset
	byte	0			; graphic right inset
	byte	1			; graphic bottom inset
endif	; endif of if _EDGE_STYLE_BUTTONS and (not _ROUND_NORMAL_BW_BUTTONS)

if _BLANK_STYLE_BUTTONS
MOBWButtonRegionSet_blankButton	label	BWButtonRegionSetStruct
	word	MOBWButton_blankBorder
	word	MOBWButton_blankInterior
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
	byte	0			; x inset
	byte	0			; y inset
	byte	2			; min height
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW
	byte	0			; right inset
	byte	0			; bottom inset

	byte	0			; graphic x inset
	byte	0			; graphic y inset
	byte	0			; graphic right inset
	byte	0			; graphic bottom inset
endif	; endif of if _BLANK_STYLE_BUTTONS

if _TOOL_STYLE_BUTTONS
MOBWButtonRegionSet_toolButton	label	BWButtonRegionSetStruct
	word	MOBWButton_toolBorder
	word	MOBWButton_toolInterior
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
	byte	1			; x inset
	byte	1			; y inset
	byte	6			; min height
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW
	byte	2			; right inset
	byte	3			; bottom inset

	byte	0			; graphic x inset
	byte	0			; graphic y inset
	byte	0			; graphic right inset
	byte	2			; graphic bottom inset
endif	; endif of if _TOOL_STYLE_BUTTONS

if _WINDOW_CONTROL_BUTTONS
MOBWButtonRegionSet_windowControlButton	label	BWButtonRegionSetStruct
	word	MOBWButton_windowControlBorder
	word	MOBWButton_windowControlInterior
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
	byte	1			; x inset
	byte	1			; y inset
	byte	MO_BUTTON_MIN_HEIGHT
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW
	byte	1			; right inset
	byte	2			; bottom inset

	byte	0			; graphic x inset
	byte	0			; graphic y inset
	byte	0			; graphic right inset
	byte	1			; graphic bottom inset

endif	; endif of if _WINDOW_CONTROL_BUTTONS

if _COMMAND_STYLE_BUTTONS
MOBWButtonRegionSet_commandButton	label	BWButtonRegionSetStruct
	word	MOBWButton_commandBorder
	word	MOBWButton_commandInterior
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)

	byte	3			; x inset
	byte	2			; y inset
	byte	6			; min height
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW
	byte	3			; right margin
	byte	3			; bottom margin

	byte	1			; graphic x inset
	byte	0			; graphic y inset
	byte	0			; graphic right inset
	byte	2			; graphic bottom inset

endif ; _COMMAND_STYLE_BUTTONS


	;
	; End of PCV style buttons
	;

endif		;--------------------------------------------------------------

if _ISUI	;--------------------------------------------------------------

;ISUI reply bar button region structures

MOBWButtonRegionSet_replyButton		label	BWButtonRegionSetStruct
	word	MOBWButton_replyBorder
	word	MOBWButton_replyInterior
	byte	(J_CENTER shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
	byte	MO_REPLY_BUTTON_INSET_X
	byte	MO_BUTTON_INSET_Y
	byte	MO_BUTTON_MIN_HEIGHT+MO_REPLY_BUTTON_INSET_Y
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW

MOBWButtonRegionSet_defReplyButton	label	BWButtonRegionSetStruct
	word	MOBWButton_defReplyBorder
	word	MOBWButton_replyInterior
	byte	(J_CENTER shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
	byte	MO_REPLY_BUTTON_INSET_X
	byte	MO_REPLY_BUTTON_INSET_Y
	byte	MO_BUTTON_MIN_HEIGHT+MO_REPLY_BUTTON_INSET_Y
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW

;ISUI listbox button region structures

MOBWButtonRegionSet_listBoxButton	label	BWButtonRegionSetStruct
	word	MOBWButton_listBoxButton
	word	MOBWButton_listBoxInterior
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
	byte	MO_BUTTON_INSET_X
	byte	MO_BUTTON_INSET_Y
	byte	MO_BUTTON_MIN_HEIGHT
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW

endif		;--------------------------------------------------------------

;Note for menu buttons- in many cases the border and interior are always
;drawn together, although in certain cases only the border is drawn.
;Menu button: for menu buttons IN THE MENU BAR.

MOBWButtonRegionSet_menuButton	label	BWButtonRegionSetStruct
	word	MOBWButton_menuButtonBorder
	word	MOBWButton_menuButtonInterior
if _ROUND_NORMAL_BW_BUTTONS
	word	0
endif ;_ROUND_NORMAL_BW_BUTTONS
	byte	(J_CENTER shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
	byte	MO_MENU_BUTTON_INSET_X
	byte	MO_MENU_BUTTON_INSET_Y

;	;CUA/PM: reduce by 1, since no etch lines to worry about, and the
;	;menu button is not responsible for drawing its top line.
;NOT_MO<byte	MO_MENU_BUTTON_INSET_Y-1				>
;				;(this will affect B&W and color CUA)

	byte	MO_MENU_BUTTON_MIN_HEIGHT
	byte	MO_MENU_BUTTON_INSET_Y_CGA
	byte	MO_MENU_BUTTON_INSET_X_NARROW

;System Menu Button: for menu buttons in the title area

MOBWButtonRegionSet_systemMenuButton	label	BWButtonRegionSetStruct
	word	MOBWButton_outlineBoxButtonBorder
	word	MOBWButton_systemMenuButtonInterior
if _ROUND_NORMAL_BW_BUTTONS
	word	0
endif ;_ROUND_NORMAL_BW_BUTTONS
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
if _ISUI
	byte	2
else
	byte	0
endif
	byte	0
MO <	byte	MO_BUTTON_MIN_HEIGHT					>
ISU <	byte	MO_BUTTON_MIN_HEIGHT					>
NOT_MO<	byte	CUA_BUTTON_MIN_HEIGHT					>
	byte	0
	byte	0

;Menu item: for buttons and menu buttons INSIDE MENUS
;(Note that in Motif, we supply a border region, to use when the item
;is CURSORED.)

MOBWButtonRegionSet_menuItem	label	BWButtonRegionSetStruct
NOT_MO<	word	NULL							>
MO <	word	MOBWButton_outlineBoxButtonBorder			>
ISU <	word	MOBWButton_outlineBoxButtonBorder			>
	word	MOBWButton_menuItemInterior
if _ROUND_NORMAL_BW_BUTTONS
	word	0
endif ;_ROUND_NORMAL_BW_BUTTONS
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
	byte	MO_MENU_ITEM_INSET_X
	byte	MO_MENU_ITEM_INSET_Y
	byte	MO_MENU_ITEM_MIN_HEIGHT		
	byte	MO_MENU_ITEM_INSET_Y_CGA
	byte	MO_MENU_ITEM_INSET_X_NARROW


if _BLANK_STYLE_BUTTONS
MOBWButtonRegionSet_blankButton	label	BWButtonRegionSetStruct
	word	MOBWButton_blankBorder
	word	MOBWButton_blankInterior
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
	byte	0			; x inset
	byte	0			; y inset
	byte	2			; min height
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW
	byte	0			; right inset
	byte	0			; bottom inset

	byte	0			; graphic x inset
	byte	0			; graphic y inset
	byte	0			; graphic right inset
	byte	0			; graphic bottom inset
endif	; endif of if _BLANK_STYLE_BUTTONS


endif		;CUA_STYLE --------------------------------
idata	ends

;-----------------------


if _FXIP
DrawBWRegions	segment resource
else
DrawBW	segment	resource
endif


;------------------------------------------------------------------------------
;		Black&White Region Definitions and Bitmaps
;------------------------------------------------------------------------------
;IMPORTANT: to save bytes in copenButton.asm, we assume that region definitions
;DO NOT start at the beginning of a resource. Therefore, a region offset
;of zero means "no region".

DummyWord	word	DummyWord			;DO NOT REMOVE THIS

if _OL_STYLE	;--------------------------------------------------------------

;normal button border

OLBWButton_normalBorder		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		5, PARAM_2-6,			EOREGREC
	word	1,		3, 4, PARAM_2-5, PARAM_2-4,	EOREGREC
	word	2,		2, 2, PARAM_2-3, PARAM_2-3,	EOREGREC
	word	4,		1, 1, PARAM_2-2, PARAM_2-2,	EOREGREC

	word	PARAM_3-6,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC

	word	PARAM_3-4,	1, 1, PARAM_2-2, PARAM_2-2,	EOREGREC
	word	PARAM_3-3,	2, 2, PARAM_2-3, PARAM_2-3,	EOREGREC
	word	PARAM_3-2,	3, 4, PARAM_2-5, PARAM_2-4,	EOREGREC
	word	PARAM_3-1,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC

;normal button interior

OLBWButton_normalInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	1,						EOREGREC
	word	2,		5, PARAM_2-6,			EOREGREC
	word	3,		4, PARAM_2-5,			EOREGREC
	word	4,		3, PARAM_2-4,			EOREGREC

	word	PARAM_3-6,	2, PARAM_2-3,			EOREGREC

	word	PARAM_3-5,	3, PARAM_2-4,			EOREGREC
	word	PARAM_3-4,	4, PARAM_2-5,			EOREGREC
	word	PARAM_3-3,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC

;default button border

OLBWButton_defaultBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		5, PARAM_2-6,			EOREGREC
	word	1,		3, PARAM_2-4,			EOREGREC
	word	2,		2, 4, PARAM_2-5, PARAM_2-3,	EOREGREC
	word	3,		1, 3, PARAM_2-4, PARAM_2-2,	EOREGREC
	word	4,		1, 2, PARAM_2-3, PARAM_2-2,	EOREGREC

	word	PARAM_3-6,	0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC

	word	PARAM_3-5,	1, 2, PARAM_2-3, PARAM_2-2,	EOREGREC
	word	PARAM_3-4,	1, 3, PARAM_2-4, PARAM_2-2,	EOREGREC
	word	PARAM_3-3,	2, 4, PARAM_2-5, PARAM_2-3,	EOREGREC
	word	PARAM_3-2,	3, PARAM_2-4,			EOREGREC
	word	PARAM_3-1,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC

;default button interior

OLBWButton_defaultInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	1,						EOREGREC
	word	3,		5, PARAM_2-6,			EOREGREC
	word	4,		4, PARAM_2-5,			EOREGREC

	word	PARAM_3-6,	3, PARAM_2-4,			EOREGREC

	word	PARAM_3-5,	4, PARAM_2-5,			EOREGREC
	word	PARAM_3-4,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC

endif		;--------------------------------------------------------------

if _CUA_STYLE

;normal button border

MOBWButton_normalBorder		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if (not _MOTIF) and (not _ISUI) ;CUA -----------------------------------------
	word	0,						EOREGREC
	word	1,		5, PARAM_2-6,			EOREGREC
	word	2,		3, 4, PARAM_2-5, PARAM_2-4,	EOREGREC
	word	4,		2, 2, PARAM_2-3, PARAM_2-3,	EOREGREC

	word	PARAM_3-6,	1, 1, PARAM_2-2, PARAM_2-2,	EOREGREC

	word	PARAM_3-4,	2, 2, PARAM_2-3, PARAM_2-3,	EOREGREC
	word	PARAM_3-3,	3, 4, PARAM_2-5, PARAM_2-4,	EOREGREC
	word	PARAM_3-2,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------
if _MOTIF	;--------------------------------------------------------------

if DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY
if _PCV_STYLE_BW_SHADOWS
	word	-1,						EOREGREC
	word	0,		2, PARAM_2-3,			EOREGREC
	word	1,		1, 1, PARAM_2-2, PARAM_2-2,	EOREGREC
	word	PARAM_3-4,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-3, 	0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	PARAM_3-1,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC
else	; else of if _PCV_STYLE_BW_SHADOWS
	word	-1,						EOREGREC
	word	0,		0, PARAM_2-2,			EOREGREC
	word	PARAM_3-3,	0, 0, PARAM_2-2, PARAM_2-1,	EOREGREC
	word	PARAM_3-2, 	0, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	1, PARAM_2-1,			EOREGREC
	word	EOREGREC
endif	; end of else of if _PCV_STYLE_BW_SHADOWS
else
if _ROUND_NORMAL_BW_BUTTONS
	word	-1,						EOREGREC
	word	0,		3, PARAM_2-4,			EOREGREC
	word	1,		1, PARAM_2-2,			EOREGREC
	word	2,		1, 3, PARAM_2-4, PARAM_2-2,	EOREGREC
	word	3,		0, 2, PARAM_2-3, PARAM_2-1,	EOREGREC
	word	PARAM_3-5,	0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC
	word	PARAM_3-4,	0, 2, PARAM_2-3, PARAM_2-1,	EOREGREC
	word	PARAM_3-3,	1, 3, PARAM_2-4, PARAM_2-2,	EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	PARAM_3-1,	3, PARAM_2-4,			EOREGREC
	word	EOREGREC
else
	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	PARAM_3-2,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC
endif	;_ROUND_NORMAL_BW_BUTTONS
endif	;DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY

endif		;_MOTIF--------------------------------------------------------
if _ISUI	;--------------------------------------------------------------
	word	-1,						EOREGREC
	word	0,		1, PARAM_2-2,			EOREGREC
	word	PARAM_3-2,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------


;normal button interior

MOBWButton_normalInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if (not _MOTIF) and (not _ISUI) ;CUA -----------------------------------------
	word	1,						EOREGREC
	word	2,		5, PARAM_2-6,			EOREGREC
	word	4,		3, PARAM_2-4,			EOREGREC

	word	PARAM_3-6,	2, PARAM_2-3,			EOREGREC

	word	PARAM_3-4,	3, PARAM_2-4,			EOREGREC
	word	PARAM_3-3,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------
if _MOTIF	;--------------------------------------------------------------

if	DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY
if _PCV_STYLE_BW_SHADOWS
	word	1,						EOREGREC
	word	PARAM_3-4,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC
else	; else of if _PCV_STYLE_BW_SHADOWS
	word	0,						EOREGREC
	word	PARAM_3-3,	1, PARAM_2-3,			EOREGREC
	word	EOREGREC
endif	; end of else of if _PCV_STYLE_BW_SHADOWS
else
if 	_ROUND_NORMAL_BW_BUTTONS
	word	1,						EOREGREC
	word	2,		4, PARAM_2-5,			EOREGREC
	word	3,		3, PARAM_2-4,			EOREGREC
	word	PARAM_3-5,	2, PARAM_2-3,			EOREGREC
	word	PARAM_3-4,	3, PARAM_2-4,			EOREGREC
	word	PARAM_3-3,	4, PARAM_2-5,			EOREGREC
	word	EOREGREC
	
else
	word	0,						EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC
endif	;_ROUND_NORMAL_BW_BUTTONS
endif	;DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY

endif		;_MOTIF--------------------------------------------------------
if _ISUI	;--------------------------------------------------------------
	word	0,						EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------


if 	_ROUND_NORMAL_BW_BUTTONS

STBWButton_normalBackground	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	-1,						EOREGREC
	word	0,		3, PARAM_2-4,			EOREGREC
	word	2,		1, PARAM_2-2,			EOREGREC
	word	PARAM_3-4,	0, PARAM_2-1,			EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	PARAM_3-1,	3, PARAM_2-4,			EOREGREC
	word	EOREGREC

endif 	;_ROUND_NORMAL_BW_BUTTONS

; Buttons with the drop menu down mark are drawn rectangular with
; thick (2-pixel) borders if _THICK_DROP_MENU_BW_BUTTONS is TRUE.
; This is a stylus feature.
  
if _THICK_DROP_MENU_BW_BUTTONS

STBWButton_thickDropMenuBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	1,		0, PARAM_2-1,			EOREGREC
	word	PARAM_3-3,	0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC
	
STBWButton_thickDropMenuInterior label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	
	word	1,						EOREGREC
	word	PARAM_3-3,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC

endif ;_THICK_DROP_MENU_BW_BUTTONS

; If using round thick dialogs, the buttons in the title bars have a
; special shape.  This is a Stylus UI attribute.  

if _ROUND_THICK_DIALOGS

; These depend upon the shape of the dialog window, as defined in
; cwinClassCommon.asm (label: windowRegionBW) and in
; Stylus/Win/winDraw.asm (label: STWindow_thickDialogBorder).

STBWButton_titleLeftInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	
	word	0,						EOREGREC
	word	1,		3, PARAM_2-2,			EOREGREC
	word	2,		2, PARAM_2-2,			EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC
	
STBWButton_titleRightInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	
	word	0,						EOREGREC
	word	1,		1, PARAM_2-4,			EOREGREC
	word	2,		1, PARAM_2-3,			EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC

endif ;_ROUND_THICK_DIALOGS

;default button border

MOBWButton_defaultBorder		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if (not _MOTIF)	and (not _ISUI) ;CUA -----------------------------------------
	word	-1,						EOREGREC
	word	0,		5, PARAM_2-6,			EOREGREC
	word	1,		3, PARAM_2-4,			EOREGREC
	word	2,		2, 4, PARAM_2-5, PARAM_2-3,	EOREGREC
	word	4,		1, 2, PARAM_2-3, PARAM_2-2,	EOREGREC
	word	PARAM_3-6,	0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC
	word	PARAM_3-4,	1, 2, PARAM_2-3, PARAM_2-2,	EOREGREC
	word	PARAM_3-3,	2, 4, PARAM_2-5, PARAM_2-3,	EOREGREC
	word	PARAM_3-2,	3, PARAM_2-4,			EOREGREC
	word	PARAM_3-1,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------
if _MOTIF	;--------------------------------------------------------------
	word	0,						EOREGREC
	word	2,		1, PARAM_2-1,			EOREGREC
	word	PARAM_3-3,	1, 3, PARAM_2-3, PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	1, PARAM_2-1,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------
if _ISUI	;--------------------------------------------------------------
	word	-1,						EOREGREC
	word	0,		1, PARAM_2-2,			EOREGREC
	word	1,		0, PARAM_2-1,			EOREGREC
	word	PARAM_3-3,	0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC
	word	PARAM_3-2,	0, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------


;default button interior

MOBWButton_defaultInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if (not _MOTIF) and (not _ISUI) ;CUA -----------------------------------------
	word	1,						EOREGREC
	word	2,		5, PARAM_2-6,			EOREGREC
	word	4,		3, PARAM_2-4,			EOREGREC

	word	PARAM_3-6,	2, PARAM_2-3,			EOREGREC

	word	PARAM_3-4,	3, PARAM_2-4,			EOREGREC
	word	PARAM_3-3,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC

endif		;--------------------------------------------------------------
if _MOTIF	;--------------------------------------------------------------
	word	0,						EOREGREC
	word	PARAM_3-2,	2, PARAM_2-2,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------
if _ISUI	;--------------------------------------------------------------
	word	1,						EOREGREC
	word	PARAM_3-3,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------


;menu button border (FOR BUTTONS IN MENU BAR)

MOBWButton_menuButtonBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if _MOTIF	;MOTIF --------------------------------------------------------
	word	-1,						EOREGREC
	word	PARAM_3-1
	word		0, 0
	word		PARAM_2-1, PARAM_2-1,			EOREGREC
	word	EOREGREC
endif 		;(MOTIF) ------------------------------------------------------

if _ISUI	;ISUI --------------------------------------------------------
	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	EOREGREC
endif		;(ISUI) ------------------------------------------------------

if (not _MOTIF) and (not _ISUI) ;CUA -----------------------------------------
	;CUA/PM: button sits on top and bottom lines of menu bar, so do not
	;draw top or bottom line.

	word	0,						EOREGREC
	word	PARAM_3-2
	word		0, 0
	word		PARAM_2-1, PARAM_2-1,			EOREGREC
	word	EOREGREC
endif		;(CUA) --------------------------------------------------------

;menu button interior (FOR BUTTONS IN MENU BAR)

MOBWButton_menuButtonInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if _MOTIF or _ISUI  ;MOTIF or ISUI--------------------------------------------
	word	-1,						EOREGREC
	word	PARAM_3-1
	word		1, PARAM_2-2,				EOREGREC
	word	EOREGREC
endif 		;(MOTIF) ------------------------------------------------------

if (not _MOTIF) and (not _ISUI) ;CUA -----------------------------------------
	;CUA/PM: button sits on top and bottom lines of menu bar, so do not
	;draw top or bottom line.
	word	0,						EOREGREC
	word	PARAM_3-2
	word		1, PARAM_2-2,				EOREGREC
	word	EOREGREC
endif		;(CUA) --------------------------------------------------------


;menu item interior (button in menu)

MOBWButton_menuItemInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	PARAM_3-1
	word		0, PARAM_2-1,				EOREGREC
	word	EOREGREC

endif		;CUA_STYLE --------------------------------------



if _MOTIF	;--------------------------------------------------------------

; Reply bar default button region

MOBWButton_defReplyBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if	DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY
if	_PCV_STYLE_BW_SHADOWS
	word	-1,						EOREGREC
	word	0,	0, PARAM_2-1,				EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y-1,			\
			0, 0,					\
			PARAM_2-1, PARAM_2-1,			EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y,			\
			0, 0,					\
			MO_REPLY_BUTTON_INSET_X+2, 		\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-3,	\
			PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y+1,			\
			0, 0,					\
			MO_REPLY_BUTTON_INSET_X+1,		\
			MO_REPLY_BUTTON_INSET_X+1,		\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-2,	\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-2,	\
			PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-4,		\
			0, 0,					\
			MO_REPLY_BUTTON_INSET_X,		\
			MO_REPLY_BUTTON_INSET_X,		\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-1,	\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-1,	\
			PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-3,		\
			0, 0,					\
			MO_REPLY_BUTTON_INSET_X,		\
			MO_REPLY_BUTTON_INSET_X+1,		\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-2,	\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-1,	\
			PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2,		\
			0, 0,					\
			MO_REPLY_BUTTON_INSET_X+1,		\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-2,	\
			PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1,		\
			0, 0,					\
			MO_REPLY_BUTTON_INSET_X+2,		\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-3,	\
			PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-2,	0, 0,  PARAM_2-1, PARAM_2-1, 	EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC
else	; else of if _PCV_STYLE_BW_SHADOWS
	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y-1, 0, 0, PARAM_2-1, PARAM_2-1,EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y, 0, 0, \
		   MO_REPLY_BUTTON_INSET_X, PARAM_2-MO_REPLY_BUTTON_INSET_X-2,\
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-3, 0, 0, \
		   MO_REPLY_BUTTON_INSET_X, MO_REPLY_BUTTON_INSET_X, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-2, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1, \
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2, 0, 0, \
		   MO_REPLY_BUTTON_INSET_X, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1,\
		   MO_REPLY_BUTTON_INSET_X, MO_REPLY_BUTTON_INSET_X, \
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1, 0, 0, \
		   MO_REPLY_BUTTON_INSET_X+1, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1,\
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-2, 0, 0,  PARAM_2-1, PARAM_2-1, 	EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC
endif	; end of else of if _PCV_STYLE_BW_SHADOWS
else
	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y-1, 0, 0, PARAM_2-1, PARAM_2-1,EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y, 0, 0, \
		   MO_REPLY_BUTTON_INSET_X, PARAM_2-MO_REPLY_BUTTON_INSET_X-1,\
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2, 0, 0, \
		   MO_REPLY_BUTTON_INSET_X, MO_REPLY_BUTTON_INSET_X, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1, \
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1, 0, 0, \
		   MO_REPLY_BUTTON_INSET_X+1, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1,\
		   MO_REPLY_BUTTON_INSET_X, MO_REPLY_BUTTON_INSET_X, \
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-2, 0, 0,  PARAM_2-1, PARAM_2-1, 	EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC
endif

;Reply button, interior

MOBWButton_replyInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if	DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY
if	_PCV_STYLE_BW_SHADOWS
	word	MO_REPLY_BUTTON_INSET_Y,			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-3,	\
		 MO_REPLY_BUTTON_INSET_X+1, PARAM_2-MO_REPLY_BUTTON_INSET_X-2,\
								EOREGREC
	word	EOREGREC
else	; else of if _PCV_STYLE_BW_SHADOWS
	word	MO_REPLY_BUTTON_INSET_Y,			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-3,	\
		 MO_REPLY_BUTTON_INSET_X+1, PARAM_2-MO_REPLY_BUTTON_INSET_X-3,\
								EOREGREC
	word	EOREGREC
endif	; end of else of if _PCV_STYLE_BW_SHADOWS
else
	word	MO_REPLY_BUTTON_INSET_Y,			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2,	\
		 MO_REPLY_BUTTON_INSET_X+1, PARAM_2-MO_REPLY_BUTTON_INSET_X-2,\
								EOREGREC
	word	EOREGREC
endif
      
;Reply bar normal button region

MOBWButton_replyBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if	DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY
if	_PCV_STYLE_BW_SHADOWS
	word	MO_REPLY_BUTTON_INSET_Y-1,			EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y,			\
			MO_REPLY_BUTTON_INSET_X+2,		\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-3,	EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y+1,			\
			MO_REPLY_BUTTON_INSET_X+1,		\
			MO_REPLY_BUTTON_INSET_X+1,		\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-2,	\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-2,	EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-4,		\
			MO_REPLY_BUTTON_INSET_X,		\
			MO_REPLY_BUTTON_INSET_X,		\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-1,	\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-1,	EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-3,		\
			MO_REPLY_BUTTON_INSET_X,		\
			MO_REPLY_BUTTON_INSET_X+1,		\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-2,	\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-1,	EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2,		\
			MO_REPLY_BUTTON_INSET_X+1,		\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-2,	EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1,		\
			MO_REPLY_BUTTON_INSET_X+2,		\
			PARAM_2-MO_REPLY_BUTTON_INSET_X-3,	EOREGREC
	word	EOREGREC
else	; else of if _PCV_STYLE_BW_SHADOWS
	word	MO_REPLY_BUTTON_INSET_Y-1,			EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y,
		 MO_REPLY_BUTTON_INSET_X, PARAM_2-MO_REPLY_BUTTON_INSET_X-2,\
								EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-3,\
		 MO_REPLY_BUTTON_INSET_X, MO_REPLY_BUTTON_INSET_X, \
		 PARAM_2-MO_REPLY_BUTTON_INSET_X-2, \
		 PARAM_2-MO_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2,\
		 MO_REPLY_BUTTON_INSET_X, PARAM_2-MO_REPLY_BUTTON_INSET_X-1,\
								EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1,\
		 MO_REPLY_BUTTON_INSET_X+1, PARAM_2-MO_REPLY_BUTTON_INSET_X-1,\
								EOREGREC
	word	EOREGREC
endif	; end of else of if _PCV_STYLE_BW_SHADOWS
else
	word	MO_REPLY_BUTTON_INSET_Y-1,			EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y,
		 MO_REPLY_BUTTON_INSET_X, PARAM_2-MO_REPLY_BUTTON_INSET_X-1,\
								EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2,\
		 MO_REPLY_BUTTON_INSET_X, MO_REPLY_BUTTON_INSET_X, \
		 PARAM_2-MO_REPLY_BUTTON_INSET_X-1, \
		 PARAM_2-MO_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1,\
		 MO_REPLY_BUTTON_INSET_X, PARAM_2-MO_REPLY_BUTTON_INSET_X-1,\
								EOREGREC
	word	EOREGREC
endif

;===============================================================================
; CGA VERSIONS OF THE ABOVE REGIONS:
; Reply bar default button region
;	MO_BUTTON_INSET_Y_CGA = 2

MOCGAButton_defReplyBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if	DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY
	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	MO_CGA_REPLY_BUTTON_INSET_Y-1, 0,0, PARAM_2-1,PARAM_2-1,EOREGREC
	word	MO_CGA_REPLY_BUTTON_INSET_Y, 0, 0, \
		   MO_CGA_REPLY_BUTTON_INSET_X, \
		   PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-2,\
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_CGA_REPLY_BUTTON_INSET_Y-3, 0, 0, \
		   MO_CGA_REPLY_BUTTON_INSET_X, MO_CGA_REPLY_BUTTON_INSET_X, \
		   PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-2, \
		   PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1, \
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_CGA_REPLY_BUTTON_INSET_Y-2, 0, 0, \
		   MO_CGA_REPLY_BUTTON_INSET_X, \
		   PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1,\
		   MO_CGA_REPLY_BUTTON_INSET_X, MO_CGA_REPLY_BUTTON_INSET_X, \
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_CGA_REPLY_BUTTON_INSET_Y-1, 0, 0, \
		   MO_CGA_REPLY_BUTTON_INSET_X+1, \
		   PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1,\
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-2, 0, 0,  PARAM_2-1, PARAM_2-1, 	EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC
else
	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	MO_CGA_REPLY_BUTTON_INSET_Y-1, 0,0, PARAM_2-1,PARAM_2-1,EOREGREC
	word	MO_CGA_REPLY_BUTTON_INSET_Y, 0, 0, \
		   MO_CGA_REPLY_BUTTON_INSET_X, \
		   PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1,\
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_CGA_REPLY_BUTTON_INSET_Y-2, 0, 0, \
		   MO_CGA_REPLY_BUTTON_INSET_X, MO_CGA_REPLY_BUTTON_INSET_X, \
		   PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1, \
		   PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1, \
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_CGA_REPLY_BUTTON_INSET_Y-1, 0, 0, \
		   MO_CGA_REPLY_BUTTON_INSET_X+1, \
		   PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1,\
		   MO_CGA_REPLY_BUTTON_INSET_X, MO_CGA_REPLY_BUTTON_INSET_X, \
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-2, 0, 0,  PARAM_2-1, PARAM_2-1, 	EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC
endif

;Reply button, interior

MOCGAButton_replyInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if	DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY
	word	MO_CGA_REPLY_BUTTON_INSET_Y,			EOREGREC
	word	PARAM_3-MO_CGA_REPLY_BUTTON_INSET_Y-3,	\
		  MO_CGA_REPLY_BUTTON_INSET_X+1, \
		  PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-3,	EOREGREC
	word	EOREGREC
else
	word	MO_CGA_REPLY_BUTTON_INSET_Y,			EOREGREC
	word	PARAM_3-MO_CGA_REPLY_BUTTON_INSET_Y-2,	\
		  MO_CGA_REPLY_BUTTON_INSET_X+1, \
		  PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-2,	EOREGREC
	word	EOREGREC
endif
      
;Reply bar normal button region

MOCGAButton_replyBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if	DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY
	word	MO_CGA_REPLY_BUTTON_INSET_Y-1,			EOREGREC
	word	MO_CGA_REPLY_BUTTON_INSET_Y,
		 MO_CGA_REPLY_BUTTON_INSET_X, \
		 PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-2,		EOREGREC
	word	PARAM_3-MO_CGA_REPLY_BUTTON_INSET_Y-3,\
		 MO_CGA_REPLY_BUTTON_INSET_X, MO_CGA_REPLY_BUTTON_INSET_X, \
		 PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-2, \
		 PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-MO_CGA_REPLY_BUTTON_INSET_Y-2,\
		 MO_CGA_REPLY_BUTTON_INSET_X, \
		 PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-MO_CGA_REPLY_BUTTON_INSET_Y-1,\
		 MO_CGA_REPLY_BUTTON_INSET_X+1, \
		 PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	EOREGREC
else
	word	MO_CGA_REPLY_BUTTON_INSET_Y-1,			EOREGREC
	word	MO_CGA_REPLY_BUTTON_INSET_Y,
		 MO_CGA_REPLY_BUTTON_INSET_X, \
		 PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-MO_CGA_REPLY_BUTTON_INSET_Y-2,\
		 MO_CGA_REPLY_BUTTON_INSET_X, MO_CGA_REPLY_BUTTON_INSET_X, \
		 PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1, \
		 PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-MO_CGA_REPLY_BUTTON_INSET_Y-1,\
		 MO_CGA_REPLY_BUTTON_INSET_X, \
		 PARAM_2-MO_CGA_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	EOREGREC
endif

endif		;MOTIF---------------------------------------------------------


if _ISUI	;--------------------------------------------------------------

;Reply bar normal button region

MOBWButton_replyBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	1,		2, PARAM_2-3,			EOREGREC
	word	PARAM_3-3,	1, 1, PARAM_2-2, PARAM_2-2,	EOREGREC
	word	PARAM_3-2,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC

;Reply button, interior

MOBWButton_replyInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	2,						EOREGREC
	word	PARAM_3-4,	3, PARAM_2-4,			EOREGREC
	word	EOREGREC

;Reply bar default button region

MOBWButton_defReplyBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		1, PARAM_2-2,			EOREGREC
	word	1,		0, PARAM_2-1,			EOREGREC
	word	PARAM_3-3,	0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC
	word	PARAM_3-2,	0, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC


;Listbox button region

MOBWButton_listBoxButton	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	PARAM_3-2,	0, 0, \
		PARAM_2-OL_DOWN_MARK_WIDTH-1, PARAM_2-OL_DOWN_MARK_WIDTH-1, \
			PARAM_2-1, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

MOBWButton_listBoxInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	PARAM_3-2,	PARAM_2-OL_DOWN_MARK_WIDTH,
				PARAM_2-2,			EOREGREC
	word	EOREGREC

endif		;ISUI --------------------------------------------------------



if _CUA_STYLE	;--------------------------------------------------------------

;system menu button border (button which opens a system menu)

MOBWButton_outlineBoxButtonBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0
	word		0, PARAM_2-1,				EOREGREC
	word	PARAM_3-2
	word		0, 0
	word		PARAM_2-1, PARAM_2-1,			EOREGREC
MO <	word	PARAM_3-1						>
MO <	word		0, PARAM_2-1,				EOREGREC>
ISU <	word	PARAM_3-1						>
ISU <	word		0, PARAM_2-1,				EOREGREC>
	word	EOREGREC

;system menu button interior (button which opens a system menu)

MOBWButton_systemMenuButtonInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	PARAM_3-2
	word		1, PARAM_2-2,				EOREGREC
	word	EOREGREC

endif		;CUA_STYLE ----------------------------------------------------

if _CUA_STYLE and (not _MOTIF) and (not _ISUI) ;------------------------------

;checkmark for CUA settings which are in menus

;mSettingCheckBM label	word
CUASMenuSettingCheckmarkBM	label	word
	word	16
	word	11
	byte	0, BMF_MONO
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00110000b
	byte	00000000b, 00100000b
	byte	00000000b, 01100000b
	byte	00000000b, 01000000b
	byte	00000000b, 11000000b
	byte	00011000b, 10000000b
	byte	00001101b, 10000000b
	byte	00000111b, 00000000b
	byte	00000010b, 00000000b

endif			;------------------------------------------------------

if	 _WINDOW_CLOSE_BUTTON_IS_BIG_X

; Special border used for the close button when using the BigX button.  This
; doesn't have a right edge so there is a white (no) separation between the
; button and the title bar.

STBWButton_closeButtonBorder		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0
	word		0, PARAM_2-1,				EOREGREC
	word	PARAM_3-2
if GRADIENT_TITLE_BAR
;
; If the title bar is gradient filled, then we will draw a right
; border.
;
	word		0, 0, PARAM_2-1, PARAM_2-1,		EOREGREC
else
	word		0, 0,					EOREGREC
endif
	word	PARAM_3-1
	word		0, PARAM_2-1,				EOREGREC
	word	EOREGREC

endif	;_WINDOW_CLOSE_BUTTON_IS_BIG_X


	;
	; PCV style buttons
	;
if _EDGE_STYLE_BUTTONS
MOBWButton_upperRightBorder		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	-1,						EOREGREC
	word	PARAM_3-4,	0, 0,				EOREGREC
	word	PARAM_3-3,	0, 1,				EOREGREC
	word	PARAM_3-2, 	1, PARAM_2-2,			EOREGREC
	word	PARAM_3-1,	2, PARAM_2-1,			EOREGREC
	word	EOREGREC

MOBWButton_upperRightInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	-1,						EOREGREC
	word	PARAM_3-4,	1, PARAM_2-1,			EOREGREC
	word	PARAM_3-3,	2, PARAM_2-1,			EOREGREC
	word	EOREGREC


MOBWButton_lowerRightBorder		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	-1,						EOREGREC
	word	0,		2, PARAM_2-1,			EOREGREC
	word	1,		1, 1,				EOREGREC
	word	PARAM_3-1,	0, 0,				EOREGREC
	word	EOREGREC

MOBWButton_lowerRightInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	0,						EOREGREC
	word	1,		2, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	1, PARAM_2-1,			EOREGREC
	word	EOREGREC
endif 		; endif of if _EDGE_STYLE_BUTTONS

if _COMMAND_STYLE_BUTTONS
MOBWButton_commandBorder		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	-1,						EOREGREC
	word	0,		2, PARAM_2-3,			EOREGREC
	word	1,		1, 1, PARAM_2-2, PARAM_2-2,	EOREGREC
	word	PARAM_3-4,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-3, 	0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	PARAM_3-1,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC

;normal button interior

MOBWButton_commandInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	1,						EOREGREC
	word	PARAM_3-4,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC

endif	; COMMAND_STYLE_BUTTONS


if _BLANK_STYLE_BUTTONS
MOBWButton_blankBorder		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	PARAM_3-1,					EOREGREC
	word	EOREGREC

MOBWButton_blankInterior	label	Region
	MakeRectRegion	0, 0, PARAM_2-1, PARAM_3-1
endif		; endif of if _BLANK_STYLE_BUTTONS

if _TOOL_STYLE_BUTTONS
MOBWButton_toolBorder		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	0,						EOREGREC
	word	1,		0, 0, PARAM_2-2, PARAM_2-2,	EOREGREC
	word	PARAM_3-4,	PARAM_2-1, PARAM_2-1,		EOREGREC
	word	PARAM_3-3,	0, 0,	PARAM_2-2, PARAM_2-1,	EOREGREC
	word	PARAM_3-2,	0, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC

MOBWButton_toolInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	0,						EOREGREC
	word	1,		1, PARAM_2-3,			EOREGREC
	word	PARAM_3-4,	0, PARAM_2-2,			EOREGREC
	word	PARAM_3-3,	1, PARAM_2-3,			EOREGREC
	word	EOREGREC
endif		; endif of if _TOOL_STYLE_BUTTONS

if _WINDOW_CONTROL_BUTTONS
MOBWButton_windowControlBorder		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	0,						EOREGREC
	word	1,		0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-3,					EOREGREC
	word	PARAM_3-2,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

MOBWButton_windowControlInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	1,						EOREGREC
	word	PARAM_3-3,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC
endif		; endif of if _WINDOW_CONTROL_BUTTONS
	;
	; End of PCV style buttons
	;


if _FXIP
DrawBWRegions	ends
else
DrawBW ends
endif


;------------------------------------------------------------------------------
;			Tables for Color buttons
;------------------------------------------------------------------------------
if not _ASSUME_BW_ONLY

if _FXIP
DrawColorRegions	segment resource
else
DrawColor segment resource
endif

if	_OL_STYLE or _MOTIF ;-----------------------------


;IMPORTANT: to save bytes in copenButton.asm, we assume that region definitions
;DO NOT start at the beginning of a resource. Therefore, a region offset
;of zero means "no region".

DummyWord2	word	DummyWord2

DefaultCBR	label	ColorButtonRegions
OLS <	word	CBRdefBorderLT, CBRdefBorderRB, CBRdefInterior		>
MO <	word	CBRdefBorderLT, CBRdefBorderRB, CBRdefInterior		>

NormalCBR	label	ColorButtonRegions
OLS <	word	CBRborderLT, CBRborderRB, CBRinterior			>
MO <	word	CBRborderLT, CBRborderRB, CBRinterior			>

if _MOTIF and DOUBLE_BORDERED_GADGETS
SystemCBR	label	ColorButtonRegions				
	word	CBRsysBorderLT, CBRsysBorderRB, CBRsysInterior		
endif

;	 button, default, left and top part

if _MOTIF	;--------------------------------------------------------------
ReplyNormalCBR	label	ColorButtonRegions
	word	CBRreplyBorderLT, CBRreplyBorderRB, CBRreplyInterior

ReplyDefaultCBR	label	ColorButtonRegions
	word	CBRreplyDefBorderLT, CBRreplyDefBorderRB, CBRreplyInterior

;
; Normal button regions
  
if	DOUBLE_BORDERED_GADGETS ;------------------------------------------
	
;
; Normal button regions
CBRborderLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	1, 		0, PARAM_2-2, 		  	EOREGREC
	word	PARAM_3-3,	0, 1, 				EOREGREC
	word	PARAM_3-2,	0, 0, 				EOREGREC
	word	EOREGREC
	
; button, not default, right and bottom part
  
CBRborderRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	1,		PARAM_2-1, PARAM_2-1,		EOREGREC
	word	PARAM_3-3,	PARAM_2-2, PARAM_2-1,		EOREGREC

	word	PARAM_3-2, 	1, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

; button, not default, interior

CBRinterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	1,						EOREGREC
	word	PARAM_3-3,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC
	
;
; Reply bar default button regions
CBRreplyDefBorderLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y-1, PARAM_2-1, PARAM_2-1,EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y, \
		   MO_REPLY_BUTTON_INSET_X, PARAM_2-MO_REPLY_BUTTON_INSET_X-2,\
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y+1, \
		   MO_REPLY_BUTTON_INSET_X, PARAM_2-MO_REPLY_BUTTON_INSET_X-3,\
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2, \
		   MO_REPLY_BUTTON_INSET_X, MO_REPLY_BUTTON_INSET_X+1, \
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1, \
		   MO_REPLY_BUTTON_INSET_X, MO_REPLY_BUTTON_INSET_X, \
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-2, 	PARAM_2-1, PARAM_2-1, 		EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

;	 button, default, right and bottom part

CBRreplyDefBorderRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y-1, 0, 0,		EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y, 0, 0, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-3, 0, 0, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-2, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2, 0, 0, \
		   MO_REPLY_BUTTON_INSET_X+2, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1, 0, 0, \
		   MO_REPLY_BUTTON_INSET_X+1, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-1,	0, 0,				EOREGREC
	word	EOREGREC

;	 button, default, interior

CBRreplyInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	MO_REPLY_BUTTON_INSET_Y+1,			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-3,	\
		 MO_REPLY_BUTTON_INSET_X+2, PARAM_2-MO_REPLY_BUTTON_INSET_X-3,\
								EOREGREC
	word	EOREGREC
      
; button, not default, left and top part

;
; Reply bar normal button regions
CBRreplyBorderLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	MO_REPLY_BUTTON_INSET_Y-1,			EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y,
		 MO_REPLY_BUTTON_INSET_X, PARAM_2-MO_REPLY_BUTTON_INSET_X-2,\
								EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y+1,
		 MO_REPLY_BUTTON_INSET_X, PARAM_2-MO_REPLY_BUTTON_INSET_X-3,\
								EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2,\
		 MO_REPLY_BUTTON_INSET_X, MO_REPLY_BUTTON_INSET_X+1, EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1,\
		 MO_REPLY_BUTTON_INSET_X, MO_REPLY_BUTTON_INSET_X, EOREGREC
	word	EOREGREC

; button, not default, right and bottom part

CBRreplyBorderRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	MO_REPLY_BUTTON_INSET_Y,			EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y+1,\
		 PARAM_2-MO_REPLY_BUTTON_INSET_X-1, \
		 PARAM_2-MO_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-3,\
		 PARAM_2-MO_REPLY_BUTTON_INSET_X-2, \
		 PARAM_2-MO_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2,\
		 MO_REPLY_BUTTON_INSET_X+2, PARAM_2-MO_REPLY_BUTTON_INSET_X-1,\
								EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1,\
		 MO_REPLY_BUTTON_INSET_X+1, PARAM_2-MO_REPLY_BUTTON_INSET_X-1,\
								EOREGREC
	word	EOREGREC


;
; Default button regions (couldn't tell the difference between this and normal
; buttons, so I used the same regions -- sorry if this turns out to be wrong.)
; -cbh
;
CBRdefBorderLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	1, 		0, PARAM_2-2, 		  	EOREGREC
	word	PARAM_3-3,	0, 1, 				EOREGREC
	word	PARAM_3-2,	0, 0, 				EOREGREC
	word	EOREGREC
	
; button, not default, right and bottom part
  
CBRdefBorderRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	1,		PARAM_2-1, PARAM_2-1,		EOREGREC
	word	PARAM_3-3,	PARAM_2-2, PARAM_2-1,		EOREGREC

	word	PARAM_3-2, 	1, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

; button, not default, interior

CBRdefInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC
	
; system buttons

CBRsysBorderLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, PARAM_2-2,			EOREGREC
	word	PARAM_3-2,	0, 0, 				EOREGREC
	word	EOREGREC
	
; button, not default, right and bottom part
  
CBRsysBorderRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	PARAM_3-2,	PARAM_2-1, PARAM_2-1,		EOREGREC

	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

; button, not default, interior

CBRsysInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC
	

else ; not DOUBLE_BORDER_GADGETS ----------------------------------------------
     
;
; Normal button regions

CBRborderLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, PARAM_2-2,			EOREGREC
	word	PARAM_3-2,	0, 0, 				EOREGREC
	word	EOREGREC
	
; button, not default, right and bottom part
  
CBRborderRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	PARAM_3-2,	PARAM_2-1, PARAM_2-1,		EOREGREC

	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

; button, not default, interior

CBRinterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	1,						EOREGREC
	word	PARAM_3-3,	1, PARAM_2-3,			EOREGREC
	word	EOREGREC
	
;
; Reply bar default button regions
CBRreplyDefBorderLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y-1, PARAM_2-1, PARAM_2-1,EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y, \
		   MO_REPLY_BUTTON_INSET_X, PARAM_2-MO_REPLY_BUTTON_INSET_X-1,\
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1, \
		   MO_REPLY_BUTTON_INSET_X, MO_REPLY_BUTTON_INSET_X, \
		   PARAM_2-1, PARAM_2-1, 			EOREGREC
	word	PARAM_3-2, 	PARAM_2-1, PARAM_2-1, 		EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

;	 button, default, right and bottom part

CBRreplyDefBorderRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y, 0, 0,			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2, 0, 0, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1, 0, 0, \
		   MO_REPLY_BUTTON_INSET_X+1, \
		   PARAM_2-MO_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-1,	0, 0,				EOREGREC
	word	EOREGREC

;	 button, default, interior

CBRreplyInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	MO_REPLY_BUTTON_INSET_Y,			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2,	\
		 MO_REPLY_BUTTON_INSET_X+1, PARAM_2-MO_REPLY_BUTTON_INSET_X-2,\
								EOREGREC
	word	EOREGREC
      
; button, not default, left and top part

;
; Reply bar normal button regions
CBRreplyBorderLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	MO_REPLY_BUTTON_INSET_Y-1,			EOREGREC
	word	MO_REPLY_BUTTON_INSET_Y,
		 MO_REPLY_BUTTON_INSET_X, PARAM_2-MO_REPLY_BUTTON_INSET_X-1,\
								EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1,\
		 MO_REPLY_BUTTON_INSET_X, MO_REPLY_BUTTON_INSET_X, EOREGREC
	word	EOREGREC

; button, not default, right and bottom part

CBRreplyBorderRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	MO_REPLY_BUTTON_INSET_Y,			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2,\
		 PARAM_2-MO_REPLY_BUTTON_INSET_X-1, \
		 PARAM_2-MO_REPLY_BUTTON_INSET_X-1,		EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-1,\
		 MO_REPLY_BUTTON_INSET_X+1, PARAM_2-MO_REPLY_BUTTON_INSET_X-1,\
								EOREGREC
	word	EOREGREC


;
; Default button regions
CBRdefBorderLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, PARAM_2-2,			EOREGREC
	word	PARAM_3-1,	0, 0, 				EOREGREC
	word	EOREGREC

;	 button, default, right and bottom part

CBRdefBorderRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	PARAM_3-2,	PARAM_2-1, PARAM_2-1,		EOREGREC

	word	PARAM_3-1,	1, PARAM_2-1,			EOREGREC
	word	EOREGREC

;	 button, default, interior

CBRdefInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC
      
endif		;DOUBLE_BORDER_GADGETS ----------------------------------------
		
endif		;MOTIF --------------------------------------------------------

if _OL_STYLE	;--------------------------------------------------------------

CBRdefBorderLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		5, PARAM_2-6,			EOREGREC
	word	1,		3, PARAM_2-4,			EOREGREC
	word	2,		2, 4, PARAM_2-5, PARAM_2-3,	EOREGREC
	word	3,		1, 3, PARAM_2-4, PARAM_2-4,	EOREGREC
	word	4,		1, 2, 				EOREGREC

	word	PARAM_3-6,	0, 1, 				EOREGREC

	word	PARAM_3-4,	1, 2, 				EOREGREC
	word	EOREGREC

;	 button, default, right and bottom part

CBRdefBorderRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	2,						EOREGREC
	word	4,		PARAM_2-3, PARAM_2-2,		EOREGREC

	word	PARAM_3-6,	PARAM_2-2, PARAM_2-1,		EOREGREC

	word	PARAM_3-5,	PARAM_2-3, PARAM_2-2,		EOREGREC
	word	PARAM_3-4,	PARAM_2-4, PARAM_2-2,		EOREGREC
	word	PARAM_3-3,	2, 4, PARAM_2-5, PARAM_2-3,	EOREGREC
	word	PARAM_3-2,	3, PARAM_2-4,			EOREGREC
	word	PARAM_3-1,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC

;	 button, default, interior

CBRdefInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	1,						EOREGREC
	word	2,		5, PARAM_2-6,			EOREGREC
	word	3,		4, PARAM_2-5,			EOREGREC
	word	4,		3, PARAM_2-4,			EOREGREC

	word	PARAM_3-6,	2, PARAM_2-3,			EOREGREC

	word	PARAM_3-5,	3, PARAM_2-4,			EOREGREC
	word	PARAM_3-4,	4, PARAM_2-5,			EOREGREC
	word	PARAM_3-3,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC
      
; button, not default, left and top part

CBRborderLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		5, PARAM_2-6,			EOREGREC
	word	1,		3, 4, PARAM_2-5, PARAM_2-4,	EOREGREC
	word	2,		2, 2, PARAM_2-3, PARAM_2-3,	EOREGREC
	word	4,		1, 1, 				EOREGREC

	word	PARAM_3-6,	0, 0, 				EOREGREC

	word	PARAM_3-4,	1, 1, 				EOREGREC
	word	EOREGREC

; button, not default, right and bottom part

CBRborderRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	2,						EOREGREC
	word	4,		PARAM_2-2, PARAM_2-2,		EOREGREC

	word	PARAM_3-6,	PARAM_2-1, PARAM_2-1,		EOREGREC

	word	PARAM_3-4,	PARAM_2-2, PARAM_2-2,		EOREGREC
	word	PARAM_3-3,	2, 2, PARAM_2-3, PARAM_2-3,	EOREGREC
	word	PARAM_3-2,	3, 4, PARAM_2-5, PARAM_2-4,	EOREGREC
	word	PARAM_3-1,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC

; button, not default, interior

CBRinterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	1,		5, PARAM_2-6,			EOREGREC
	word	2,		3, PARAM_2-4,			EOREGREC
	word	4,		2, PARAM_2-3,			EOREGREC

	word	PARAM_3-6,	1, PARAM_2-2,			EOREGREC

	word	PARAM_3-4,	2, PARAM_2-3,			EOREGREC
	word	PARAM_3-3,	3, PARAM_2-4,			EOREGREC
	word	PARAM_3-2,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC
endif		;OL_STYLE -----------------------------------------------------

endif ;OL_STYLE or MOTIF -----------------------------------------


if	_ISUI	;--------------------------------------------------------------

;IMPORTANT: to save bytes in copenButton.asm, we assume that region definitions
;DO NOT start at the beginning of a resource. Therefore, a region offset
;of zero means "no region".

DummyWord2	word	DummyWord2

NormalCBR	ColorButtonRegions <
			CBRborderOuterLT, CBRborderOuterRB, 
			CBRborderInnerLT, CBRborderInnerRB,
			CBRinterior,
			(C_WHITE shl 8) or C_BLACK,
			(C_BLACK shl 8) or C_WHITE,
			(C_WHITE shl 8) or C_DARK_GRAY,
			(C_DARK_GRAY shl 8) or C_WHITE
		>

DefaultCBR	ColorButtonRegions <
			CBRdefBorderOuterLT, CBRdefBorderOuterRB,
			CBRdefBorderInnerLT, CBRdefBorderInnerRB,
			CBRdefInterior,
			(C_WHITE shl 8) or C_BLACK,
			(C_DARK_GRAY shl 8) or C_DARK_GRAY,
			(C_WHITE shl 8) or C_DARK_GRAY,
			(C_LIGHT_GRAY shl 8) or C_LIGHT_GRAY
		>

MenuCBR		ColorButtonRegions <
			CBRnullRegion, CBRnullRegion,
			CBRnullRegion, CBRnullRegion,
			CBRmenuBarInterior,
			(C_BLACK shl 8) or C_BLACK,
			(C_BLACK shl 8) or C_BLACK,
			(C_BLACK shl 8) or C_BLACK,
			(C_BLACK shl 8) or C_BLACK
		>

ListBoxCBR	ColorButtonRegions <
			CBRlistBoxBorderOuterLT, CBRlistBoxBorderOuterRB,
			CBRlistBoxBorderInnerLT, CBRlistBoxBorderInnerRB,
			CBRlistBoxInterior,
			(C_DARK_GRAY shl 8) or C_WHITE,
			(C_DARK_GRAY shl 8) or C_WHITE,
			(C_BLACK shl 8) or C_LIGHT_GRAY,
			(C_BLACK shl 8) or C_LIGHT_GRAY
		>

;-----------------------------------------------------------------------
;			Normal button regions
;-----------------------------------------------------------------------
CBRborderOuterLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, PARAM_2-2,			EOREGREC
	word	PARAM_3-2,	0, 0, 				EOREGREC
	word	EOREGREC
	
CBRborderOuterRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	PARAM_3-2,	PARAM_2-1, PARAM_2-1,		EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

CBRborderInnerLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	1,		1, PARAM_2-3,			EOREGREC
	word	PARAM_3-3,	1, 1, 				EOREGREC
	word	EOREGREC
	
CBRborderInnerRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	PARAM_3-3,	PARAM_2-2, PARAM_2-2,		EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC

CBRinterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	1,						EOREGREC
	word	PARAM_3-3,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC
	
;-----------------------------------------------------------------------
;			Default button regions
;-----------------------------------------------------------------------
CBRdefBorderOuterLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	1,		1, PARAM_2-3,			EOREGREC
	word	PARAM_3-3,	1, 1, 				EOREGREC
	word	EOREGREC
	
CBRdefBorderOuterRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	PARAM_3-3,	PARAM_2-2, PARAM_2-2,		EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC

CBRdefBorderInnerLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	1,						EOREGREC
	word	2,		2, PARAM_2-4,			EOREGREC
	word	PARAM_3-4,	2, 2, 				EOREGREC
	word	EOREGREC
	
CBRdefBorderInnerRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	1,						EOREGREC
	word	PARAM_3-4,	PARAM_2-3, PARAM_2-3,		EOREGREC
	word	PARAM_3-3,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC

CBRdefInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	2,						EOREGREC
	word	PARAM_3-4,	3, PARAM_2-4,			EOREGREC
	word	EOREGREC
	

CBRdefExterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	PARAM_3-2,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

;-----------------------------------------------------------------------
;			Menu button regions
;-----------------------------------------------------------------------
CBRnullRegion	label	Region
	word	0, 0, 0, 0			;bounds

	word	0,						EOREGREC
	word	EOREGREC

CBRmenuBarInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC
	
;-----------------------------------------------------------------------
;			ListBox button regions
;-----------------------------------------------------------------------
CBRlistBoxBorderOuterLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,	   0, PARAM_2-2,			EOREGREC
	word	2,	   0, 0,				EOREGREC
	word	PARAM_3-5, 0, 0, PARAM_2-4, PARAM_2-4,		EOREGREC
	word	PARAM_3-4, 0, 0,
			   PARAM_2-OL_DOWN_MARK_WIDTH-1,
			   PARAM_2-4,				EOREGREC
	word	PARAM_3-2, 0, 0, 				EOREGREC
	word	EOREGREC
	
CBRlistBoxBorderOuterRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	2,	   PARAM_2-1, PARAM_2-1,		EOREGREC
	word	3,	   PARAM_2-OL_DOWN_MARK_WIDTH-1, PARAM_2-5,
			   PARAM_2-1, PARAM_2-1,		EOREGREC
	word	PARAM_3-5, PARAM_2-OL_DOWN_MARK_WIDTH-1,
			   PARAM_2-OL_DOWN_MARK_WIDTH-1,
			   PARAM_2-1, PARAM_2-1,		EOREGREC
	word	PARAM_3-2, PARAM_2-1, PARAM_2-1,		EOREGREC
	word	PARAM_3-1, 0, PARAM_2-1,			EOREGREC
	word	EOREGREC

CBRlistBoxBorderInnerLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	1,	   1, PARAM_2-3,			EOREGREC
	word	PARAM_3-4, 1, 1, PARAM_2-3, PARAM_2-3,		EOREGREC
	word	PARAM_3-3, 1, 1,
			   PARAM_2-OL_DOWN_MARK_WIDTH-2,
			   PARAM_2-3,				EOREGREC
	word	EOREGREC
	
CBRlistBoxBorderInnerRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	1,	   PARAM_2-2, PARAM_2-2,		EOREGREC
	word	2,	   PARAM_2-OL_DOWN_MARK_WIDTH-2, PARAM_2-4,
			   PARAM_2-2, PARAM_2-2,		EOREGREC
	word	PARAM_3-4, PARAM_2-OL_DOWN_MARK_WIDTH-2,
			   PARAM_2-OL_DOWN_MARK_WIDTH-2,
			   PARAM_2-2, PARAM_2-2,		EOREGREC
	word	PARAM_3-3, PARAM_2-2, PARAM_2-2,		EOREGREC
	word	PARAM_3-2, 1, PARAM_2-2,			EOREGREC
	word	EOREGREC

CBRlistBoxInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
 
	word	1,						EOREGREC
	word	PARAM_3-3, 2, PARAM_2-OL_DOWN_MARK_WIDTH-3,	EOREGREC
	word	EOREGREC

CBRlistBoxExterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	1,						EOREGREC
	word	2,	   PARAM_2-OL_DOWN_MARK_WIDTH-2, 
			   PARAM_2-2,				EOREGREC
	word	PARAM_3-4, PARAM_2-OL_DOWN_MARK_WIDTH-2,
			   PARAM_2-OL_DOWN_MARK_WIDTH-2,
			   PARAM_2-3, PARAM_2-3,		EOREGREC
	word	PARAM_3-3, PARAM_2-OL_DOWN_MARK_WIDTH-2,
			   PARAM_2-2,				EOREGREC
	word	EOREGREC
	
endif		;ISUI --------------------------------------------------------

if _FXIP
DrawColorRegions	ends
else
DrawColor ends
endif

endif		; if not _ASSUME_BW_ONLY
