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

	$Id: copenButtonData.asm,v 2.66 96/10/07 15:58:11 grisco Exp $
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

if _CUA_STYLE or _MAC	;------------------------------

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
PMAN <	byte	MO_BUTTON_MIN_HEIGHT					>
NOT_MO<	byte	CUA_BUTTON_MIN_HEIGHT					>
MAC<	byte	CUA_BUTTON_MIN_HEIGHT					>
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
PMAN <	byte	MO_BUTTON_MIN_HEIGHT					>
NOT_MO<	byte	CUA_BUTTON_MIN_HEIGHT					>
MAC<	byte	CUA_BUTTON_MIN_HEIGHT					>
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
PMAN <	byte	MO_BUTTON_MIN_HEIGHT					>
NOT_MO<	byte	CUA_BUTTON_MIN_HEIGHT					>
MAC<	byte	CUA_BUTTON_MIN_HEIGHT					>
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
MAC<	byte	CUA_BUTTON_MIN_HEIGHT				>
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
MAC<	byte	CUA_BUTTON_MIN_HEIGHT				>
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
MAC<	byte	CUA_BUTTON_MIN_HEIGHT				>
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
MAC<	byte	CUA_BUTTON_MIN_HEIGHT				>
	byte	MO_BUTTON_INSET_Y_CGA
	byte	MO_BUTTON_INSET_X_NARROW


	;
	; PCV style buttons
	;
if _EDGE_STYLE_BUTTONS and (not _ROUND_NORMAL_BW_BUTTONS)
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

if _PM		;--------------------------------------------------------------

;PM reply bar button region structures

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

;PM listbox button region structures

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
if _JEDIMOTIF
	;
	; JEDI menu buttons can't center because the font height is too
	; tall relative to the actual height of the font data
	;
	byte	(J_CENTER shl offset DMF_X_JUST) \
		or (J_LEFT shl offset DMF_Y_JUST)
else
	byte	(J_CENTER shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
endif
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
if _JEDIMOTIF
	word	MOBWButton_normalBorder
	word	MOBWButton_normalInterior	
else
	word	MOBWButton_outlineBoxButtonBorder
	word	MOBWButton_systemMenuButtonInterior
endif ;_JEDIMOTIF
if _ROUND_NORMAL_BW_BUTTONS
	word	0
endif ;_ROUND_NORMAL_BW_BUTTONS
	byte	(J_LEFT shl offset DMF_X_JUST) \
		or (J_CENTER shl offset DMF_Y_JUST)
if _PM
	byte	2	; So app defined system menu monikers will look better
else
	byte	0
endif
	byte	0
MO <	byte	MO_BUTTON_MIN_HEIGHT					>
PMAN <	byte	MO_BUTTON_MIN_HEIGHT					>
NOT_MO<	byte	CUA_BUTTON_MIN_HEIGHT					>
MAC<	byte	CUA_BUTTON_MIN_HEIGHT					>
	byte	0
	byte	0

;Menu item: for buttons and menu buttons INSIDE MENUS
;(Note that in Motif, we supply a border region, to use when the item
;is CURSORED.)

MOBWButtonRegionSet_menuItem	label	BWButtonRegionSetStruct
NOT_MO<	word	NULL							>
MAC<	word	NULL							>
MO <	word	MOBWButton_outlineBoxButtonBorder			>
PMAN <	word	MOBWButton_outlineBoxButtonBorder			>
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

if _CUA_STYLE or _MAC	;------------------------------

;normal button border

MOBWButton_normalBorder		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if not _REDMOTIF ;----------------------- Not needed for Redwood project
if (not _MOTIF) and (not _PM)	;CUA ------------------------------------------
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

if _JEDIMOTIF
; Two pixel thick borders.
;	word	-1,						EOREGREC ;jedi
;	word	0,		2, PARAM_2-3,			EOREGREC ;jedi
;	word	1,		1, PARAM_2-2,			EOREGREC ;jedi
;	word	2,		0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC ;jedi
;	word	PARAM_3-3,	0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC ;jedi
;	word	PARAM_3-2,	1, PARAM_2-2, 			EOREGREC ;jedi
;	word	PARAM_3-1,	2, PARAM_2-3,			EOREGREC ;jedi
;	word	EOREGREC						 ;jedi

; One pixel thick borders.
	word	-1,						EOREGREC ;jedi
	word	0,		1, PARAM_2-2,			EOREGREC ;jedi
	word	PARAM_3-2,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC ;jedi
	word	PARAM_3-1,	1, PARAM_2-2,			EOREGREC ;jedi
	word	EOREGREC						 ;jedi

else
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
endif	;_JEDIMOTIF

endif		;_MOTIF--------------------------------------------------------
if _PM		;--------------------------------------------------------------
	word	-1,						EOREGREC
	word	0,		1, PARAM_2-2,			EOREGREC
	word	PARAM_3-2,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project


;normal button interior

MOBWButton_normalInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if not _REDMOTIF ;----------------------- Not needed for Redwood project
if (not _MOTIF) and (not _PM)	;CUA ------------------------------------------
	word	1,						EOREGREC
	word	2,		5, PARAM_2-6,			EOREGREC
	word	4,		3, PARAM_2-4,			EOREGREC

	word	PARAM_3-6,	2, PARAM_2-3,			EOREGREC

	word	PARAM_3-4,	3, PARAM_2-4,			EOREGREC
	word	PARAM_3-3,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------
if _MOTIF	;--------------------------------------------------------------

if _JEDIMOTIF
; Interior of two pixel thick borders.
;	word	1,						EOREGREC ;jedi
;	word	PARAM_3-3,	2, PARAM_2-3,			EOREGREC ;jedi
;	word	EOREGREC						 ;jedi

; Interior of one pixel thick borders.
	word	0,						EOREGREC ;jedi
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC ;jedi
	word	EOREGREC						 ;jedi
else
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
if _RUDY
;extend to bounds for Rudy
	word	PARAM_3-1,	1, PARAM_2-1,			EOREGREC
else
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
endif
	word	EOREGREC
endif	;_ROUND_NORMAL_BW_BUTTONS
endif	;DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY
endif	;_JEDIMOTIF

endif		;_MOTIF--------------------------------------------------------
if _PM		;--------------------------------------------------------------
	word	0,						EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project


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

if not _REDMOTIF ;----------------------- Not needed for Redwood project
if (not _MOTIF)	and (not _PM)	;CUA ------------------------------------------
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
if _JEDIMOTIF
; Two pixel thick borders.
	word	-1,						EOREGREC ;jedi
	word	0,		2, PARAM_2-3,			EOREGREC ;jedi
	word	1,		1, PARAM_2-2,			EOREGREC ;jedi
	word	2,		0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC ;jedi
	word	PARAM_3-3,	0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC ;jedi
	word	PARAM_3-2,	1, PARAM_2-2, 			EOREGREC ;jedi
	word	PARAM_3-1,	2, PARAM_2-3,			EOREGREC ;jedi
	word	EOREGREC						 ;jedi
else
	word	0,						EOREGREC
	word	2,		1, PARAM_2-1,			EOREGREC
	word	PARAM_3-3,	1, 3, PARAM_2-3, PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	1, PARAM_2-1,			EOREGREC
	word	EOREGREC
endif	; _JEDIMOTIF
endif		;--------------------------------------------------------------
if _PM		;--------------------------------------------------------------
	word	-1,						EOREGREC
	word	0,		1, PARAM_2-2,			EOREGREC
	word	1,		0, PARAM_2-1,			EOREGREC
	word	PARAM_3-3,	0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC
	word	PARAM_3-2,	0, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project


;default button interior

MOBWButton_defaultInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if not _REDMOTIF ;----------------------- Not needed for Redwood project
if (not _MOTIF) and (not _PM)	;CUA ------------------------------------------
	word	1,						EOREGREC
	word	2,		5, PARAM_2-6,			EOREGREC
	word	4,		3, PARAM_2-4,			EOREGREC

	word	PARAM_3-6,	2, PARAM_2-3,			EOREGREC

	word	PARAM_3-4,	3, PARAM_2-4,			EOREGREC
	word	PARAM_3-3,	5, PARAM_2-6,			EOREGREC
	word	EOREGREC

endif		;--------------------------------------------------------------
if _MOTIF	;--------------------------------------------------------------
if _JEDIMOTIF
; Interior of two pixel thick borders.
	word	1,						EOREGREC ;jedi
	word	PARAM_3-3,	2, PARAM_2-3,			EOREGREC ;jedi
	word	EOREGREC						 ;jedi
else
	word	0,						EOREGREC
	word	PARAM_3-2,	2, PARAM_2-2,			EOREGREC
	word	EOREGREC
endif	; _JEDIMOTIF
endif		;--------------------------------------------------------------
if _PM		;--------------------------------------------------------------
	word	1,						EOREGREC
	word	PARAM_3-3,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC
endif		;--------------------------------------------------------------
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project


;menu button border (FOR BUTTONS IN MENU BAR)

MOBWButton_menuButtonBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if not _REDMOTIF ;----------------------- Not needed for Redwood project

if _JEDIMOTIF	;JEDIMOTIF ----------------------------------------------------
	word	0,						EOREGREC
	word	1
	word		1, PARAM_2-2,				EOREGREC
	word	PARAM_3-2
	word		0, 0
	word		PARAM_2-1, PARAM_2-1,			EOREGREC
	word	PARAM_3-1
	word		1, PARAM_2-2,				EOREGREC
	word	EOREGREC
else		;--------------------------------------------------------------
if _MOTIF	;MOTIF --------------------------------------------------------
	word	-1,						EOREGREC
	word	PARAM_3-1
	word		0, 0
	word		PARAM_2-1, PARAM_2-1,			EOREGREC
	word	EOREGREC
endif 		;(MOTIF) ------------------------------------------------------
endif		;(JEDIMOTIF) --------------------------------------------------

if _PM		;PM -----------------------------------------------------------
	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	EOREGREC
endif		;(PM) ---------------------------------------------------------

if (not _MOTIF) and (not _PM)	;CUA ------------------------------------------
	;CUA/PM: button sits on top and bottom lines of menu bar, so do not
	;draw top or bottom line.

	word	0,						EOREGREC
	word	PARAM_3-2
	word		0, 0
	word		PARAM_2-1, PARAM_2-1,			EOREGREC
	word	EOREGREC
endif		;(CUA) --------------------------------------------------------
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project

;menu button interior (FOR BUTTONS IN MENU BAR)

MOBWButton_menuButtonInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if not _REDMOTIF ;----------------------- Not needed for Redwood project
if _JEDIMOTIF	;JEDIMOTIF ----------------------------------------------------
	word	1,						EOREGREC
	word	PARAM_3-2
	word		1, PARAM_2-2,				EOREGREC
	word	EOREGREC
else	;----------------------------------------------------------------------
if _MOTIF	;MOTIF --------------------------------------------------------
	word	-1,						EOREGREC
	word	PARAM_3-1
	word		1, PARAM_2-2,				EOREGREC
	word	EOREGREC
endif 		;(MOTIF) ------------------------------------------------------
endif 		;(JEDIMOTIF) --------------------------------------------------

if _PM		;PM -----------------------------------------------------------
	word	-1,						EOREGREC
	word	EOREGREC
endif		;(PM) ---------------------------------------------------------

if (not _MOTIF) and (not _PM)	;CUA ------------------------------------------
	;CUA/PM: button sits on top and bottom lines of menu bar, so do not
	;draw top or bottom line.
	word	0,						EOREGREC
	word	PARAM_3-2
	word		1, PARAM_2-2,				EOREGREC
	word	EOREGREC
endif		;(CUA) --------------------------------------------------------
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project


;menu item interior (button in menu)

MOBWButton_menuItemInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if not _REDMOTIF ;----------------------- Not needed for Redwood project
if _PM		;PM -----------------------------------------------------------
	word	-1,						EOREGREC
	word	EOREGREC
endif		;(PM) ---------------------------------------------------------

if (not _PM)	; -------------------------------------------------------------
	word	-1,						EOREGREC
	word	PARAM_3-1
	word		0, PARAM_2-1,				EOREGREC
	word	EOREGREC
endif		;(not _PM) ----------------------------------------------------

endif		;CUA_STYLE --------------------------------------
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project



if _MOTIF	;--------------------------------------------------------------

; Reply bar default button region

MOBWButton_defReplyBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if not _REDMOTIF ;----------------------- Not needed for Redwood project
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
if _JEDIMOTIF
; Two pixel thick borders.
	word	0,		2, PARAM_2-3,			EOREGREC ;jedi
	word	1,		1, PARAM_2-2,			EOREGREC ;jedi
	word	2,		0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC ;jedi
	word	PARAM_3-3,	0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC ;jedi
	word	PARAM_3-2,	1, PARAM_2-2, 			EOREGREC ;jedi
	word	PARAM_3-1,	2, PARAM_2-3,			EOREGREC ;jedi
	word	EOREGREC						 ;jedi
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
endif	; _JEDIMOTIF
endif
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project

;Reply button, interior

MOBWButton_replyInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if not _REDMOTIF ;----------------------- Not needed for Redwood project
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
if _JEDIMOTIF
; Interior of one pixel thick borders.
	word	0,						EOREGREC ;jedi
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC ;jedi
	word	EOREGREC						 ;jedi
else
	word	MO_REPLY_BUTTON_INSET_Y,			EOREGREC
	word	PARAM_3-MO_REPLY_BUTTON_INSET_Y-2,	\
		 MO_REPLY_BUTTON_INSET_X+1, PARAM_2-MO_REPLY_BUTTON_INSET_X-2,\
								EOREGREC
	word	EOREGREC
endif	; _JEDIMOTIF
endif
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project
      
;Reply bar normal button region

MOBWButton_replyBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if not _REDMOTIF ;----------------------- Not needed for Redwood project
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
if _JEDIMOTIF
; One pixel thick borders.
	word	-1,						EOREGREC ;jedi
	word	0,		1, PARAM_2-2,			EOREGREC ;jedi
	word	PARAM_3-2,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC ;jedi
	word	PARAM_3-1,	1, PARAM_2-2,			EOREGREC ;jedi
	word	EOREGREC						 ;jedi
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
endif	; _JEDIMOTIF
endif
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project

;===============================================================================
; CGA VERSIONS OF THE ABOVE REGIONS:
; Reply bar default button region
;	MO_BUTTON_INSET_Y_CGA = 2

MOCGAButton_defReplyBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if not _REDMOTIF ;----------------------- Not needed for Redwood project
if _JEDIMOTIF
; Two pixel thick borders.
	word	-1,						EOREGREC ;jedi
	word	0,		2, PARAM_2-3,			EOREGREC ;jedi
	word	1,		1, PARAM_2-2,			EOREGREC ;jedi
	word	2,		0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC ;jedi
	word	PARAM_3-3,	0, 1, PARAM_2-2, PARAM_2-1,	EOREGREC ;jedi
	word	PARAM_3-2,	1, PARAM_2-2, 			EOREGREC ;jedi
	word	PARAM_3-1,	2, PARAM_2-3,			EOREGREC ;jedi
	word	EOREGREC						 ;jedi
else
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
endif	; _JEDIMOTIF
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project

;Reply button, interior

MOCGAButton_replyInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if not _REDMOTIF ;----------------------- Not needed for Redwood project
if _JEDIMOTIF
; Interior of two pixel thick borders.
	word	1,						EOREGREC ;jedi
	word	PARAM_3-3,	2, PARAM_2-3,			EOREGREC ;jedi
	word	EOREGREC						 ;jedi
else
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
endif	; _JEDIMOTIF
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project
      
;Reply bar normal button region

MOCGAButton_replyBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if not _REDMOTIF ;----------------------- Not needed for Redwood project
if _JEDIMOTIF
; One pixel thick borders.
	word	-1,						EOREGREC ;jedi
;	word	0,		1, PARAM_2-2,			EOREGREC ;jedi
;	word	PARAM_3-2,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC ;jedi
;	word	PARAM_3-1,	1, PARAM_2-2,			EOREGREC ;jedi
;use inner portion
	word	0,						EOREGREC ;jedi
	word	1,		2, PARAM_2-3,			EOREGREC ;jedi
	word	PARAM_3-3,	1, 1, PARAM_2-2, PARAM_2-2,	EOREGREC ;jedi
	word	PARAM_3-2,	2, PARAM_2-3,			EOREGREC ;jedi
	word	EOREGREC						 ;jedi
else
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
endif	; _JEDIMOTIF
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project

endif		;MOTIF---------------------------------------------------------


if _PM		;--------------------------------------------------------------

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
			PARAM_2-OL_MARK_WIDTH-2, PARAM_2-OL_MARK_WIDTH-2, \
			PARAM_2-1, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

MOBWButton_listBoxInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	PARAM_3-2,	PARAM_2-OL_MARK_WIDTH-2,
				PARAM_2-2,			EOREGREC
	word	EOREGREC

endif		;PM -----------------------------------------------------------



if _CUA_STYLE	;--------------------------------------------------------------

;system menu button border (button which opens a system menu)

MOBWButton_outlineBoxButtonBorder	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

if not _REDMOTIF ;----------------------- Not needed for Redwood project
	word	-1,						EOREGREC
	word	0
	word		0, PARAM_2-1,				EOREGREC
	word	PARAM_3-2
	word		0, 0
	word		PARAM_2-1, PARAM_2-1,			EOREGREC
MO <	word	PARAM_3-1						>
MO <	word		0, PARAM_2-1,				EOREGREC>
PMAN <	word	PARAM_3-1						>
PMAN <	word		0, PARAM_2-1,				EOREGREC>
	word	EOREGREC
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project

;system menu button interior (button which opens a system menu)

if not _JEDIMOTIF
MOBWButton_systemMenuButtonInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
endif

if not _REDMOTIF ;----------------------- Not needed for Redwood project
	word	0,						EOREGREC
	word	PARAM_3-2
	word		1, PARAM_2-2,				EOREGREC
	word	EOREGREC
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project

endif		;CUA_STYLE ----------------------------------------------------

if _CUA_STYLE and (not _MOTIF) and (not _PM) 	;------------------------------

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


if	_PM	;--------------------------------------------------------------

;IMPORTANT: to save bytes in copenButton.asm, we assume that region definitions
;DO NOT start at the beginning of a resource. Therefore, a region offset
;of zero means "no region".

DummyWord2	word	DummyWord2

NormalCBR	label	ColorButtonRegions
	word	CBRborderLT, CBRborderRB, CBRinterior, CBRexterior

DefaultCBR	label	ColorButtonRegions
	word	CBRdefBorderLT, CBRdefBorderRB, CBRdefInterior, CBRdefExterior

MenuBarCBR	label	ColorButtonRegions
	word	CBRmenuBarBorderLT, CBRmenuBarBorderRB, \
		CBRmenuBarInterior, CBRnullExterior

SystemCBR	label	ColorButtonRegions				
	word	CBRsysBorderLT, CBRsysBorderRB, CBRsysInterior, CBRnullExterior

ToolBoxCBR	label	ColorButtonRegions
	word	CBRtoolBoxBorderLT, CBRtoolBoxBorderRB, \
		CBRtoolBoxInterior, CBRnullExterior

ListBoxCBR	label	ColorButtonRegions
	word	CBRlistBoxBorderLT, CBRlistBoxBorderRB, \
		CBRlistBoxInterior, CBRlistBoxExterior

;
; Normal button regions ------------------------------------------------
CBRborderLT	label	Region
	word	1, 1, PARAM_2-2, PARAM_3-2	;bounds

	word	0,						EOREGREC
	word	1,		1, PARAM_2-2,			EOREGREC
	word	PARAM_3-3,	1, 1, 				EOREGREC
	word	EOREGREC
	
; button, not default, right and bottom part
  
CBRborderRB	label	Region
	word	1, 1, PARAM_2-2, PARAM_3-2	;bounds

	word	1,						EOREGREC
	word	PARAM_3-3,	PARAM_2-2, PARAM_2-2,		EOREGREC

	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC

; button, not default, interior

CBRinterior	label	Region
	word	1, 1, PARAM_2-2, PARAM_3-2	;bounds

	word	1,						EOREGREC
	word	PARAM_3-3,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC
	
CBRexterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, PARAM_2-1,			EOREGREC
	word	PARAM_3-2,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC
	
;
; Default button regions -----------------------------------------------
CBRdefBorderLT	label	Region
	word	1, 1, PARAM_2-2, PARAM_3-2	;bounds

	word	1,						EOREGREC
	word	2,		2, PARAM_2-3,			EOREGREC
	word	PARAM_3-4,	2, 2, 				EOREGREC
	word	EOREGREC
	
; button, not default, right and bottom part
  
CBRdefBorderRB	label	Region
	word	1, 1, PARAM_2-2, PARAM_3-2	;bounds

	word	2,						EOREGREC
	word	PARAM_3-4,	PARAM_2-3, PARAM_2-3,		EOREGREC

	word	PARAM_3-3,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC

; button, not default, interior

CBRdefInterior	label	Region
	word	1, 1, PARAM_2-2, PARAM_3-2	;bounds

	word	2,						EOREGREC
	word	PARAM_3-4,	3, PARAM_2-4,			EOREGREC
	word	EOREGREC
	

CBRdefExterior	label	Region
	word	1, 1, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	1,		2, PARAM_2-3,			EOREGREC
	word	PARAM_3-3,	1, 1, PARAM_2-2, PARAM_2-2,	EOREGREC
	word	PARAM_3-2,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC

;
; Extra (black) border for default and toolbox buttons
CBRdefExtraExterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0, 1, PARAM_2-2,				EOREGREC
	word	1, 0, 0, PARAM_2-2, PARAM_2-1,			EOREGREC
	word	PARAM_3-3, 0, 0, PARAM_2-1, PARAM_2-1,		EOREGREC
	word	PARAM_3-2, 0, 1, PARAM_2-2, PARAM_2-1,		EOREGREC
	word	PARAM_3-1, 1, PARAM_2-2,			EOREGREC
	word	EOREGREC

;
; Menubar button regions -----------------------------------------------
CBRmenuBarBorderLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		1, PARAM_2-2,			EOREGREC
	word	PARAM_3-1,	1, 1, 				EOREGREC
	word	EOREGREC
	
; button, not default, right and bottom part
  
CBRmenuBarBorderRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	PARAM_3-1,	PARAM_2-1, PARAM_2-1,		EOREGREC
	word	EOREGREC

; button, not default, interior

CBRmenuBarInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	1,						EOREGREC
	word	PARAM_3-3,	2, PARAM_2-3,			EOREGREC
	word	EOREGREC
	
;
; System and menu item regions -----------------------------------------
CBRsysBorderLT	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, PARAM_2-2,			EOREGREC
	word	PARAM_3-2,	0, 0, 				EOREGREC
	word	EOREGREC
	
; button, not default, right and bottom part
  
CBRsysBorderRB	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	PARAM_3-2,	PARAM_2-1, PARAM_2-1,		EOREGREC

	word	PARAM_3-1,	1, PARAM_2-1,			EOREGREC
	word	EOREGREC

; button, not default, interior

CBRsysInterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	0,						EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC

;
; An empty exterior region
CBRnullExterior	label	Region
	word	0, 0, 0, 0			;bounds

	word	0,						EOREGREC
	word	EOREGREC

;
; ToolBox button regions -----------------------------------------------
CBRtoolBoxBorderLT	label	Region
	word	1, 1, PARAM_2-2, PARAM_3-2	;bounds

	word	0,						EOREGREC
	word	1,		1, PARAM_2-2,			EOREGREC
	word	2,		1, PARAM_2-3,			EOREGREC
	word	PARAM_3-4,	1, 2,				EOREGREC
	word	PARAM_3-3,	1, 1, 				EOREGREC
	word	EOREGREC
	

CBRtoolBoxBorderRB	label	Region
	word	1, 1, PARAM_2-2, PARAM_3-2	;bounds

	word	0,						EOREGREC
	word	2,		PARAM_2-2, PARAM_2-2,		EOREGREC
	word	PARAM_3-4,	PARAM_2-3, PARAM_2-2,		EOREGREC
	word	PARAM_3-3,	2, PARAM_2-2,			EOREGREC
	word	PARAM_3-2,	1, PARAM_2-2,			EOREGREC
	word	EOREGREC


CBRtoolBoxInterior	label	Region
	word	3, 3, PARAM_2-4, PARAM_3-4	;bounds

	word	2,						EOREGREC
	word	PARAM_3-4,	3, PARAM_2-4,			EOREGREC
	word	EOREGREC

;
; ListBox button regions
CBRlistBoxBorderLT	label	Region
	word	1, 1, PARAM_2-1, PARAM_3-1	;bounds
	word	0,						EOREGREC
	word	1,	   PARAM_2-OL_MARK_WIDTH-2, PARAM_2-2,	EOREGREC
	word	PARAM_3-2, PARAM_2-OL_MARK_WIDTH-2, PARAM_2-OL_MARK_WIDTH-2,\
			   PARAM_2-1, PARAM_2-1,		EOREGREC
	word	PARAM_3-1, 0, PARAM_2-1,			EOREGREC
	word	EOREGREC
	
CBRlistBoxBorderRB	label	Region
	word	1, 1, PARAM_2-1, PARAM_3-1	;bounds
	word	1,						EOREGREC
	word	PARAM_3-3, PARAM_2-2, PARAM_2-2,\
								EOREGREC
	word	PARAM_3-2, PARAM_2-OL_MARK_WIDTH-2, PARAM_2-2,	EOREGREC
	word	EOREGREC

CBRlistBoxInterior	label	Region
	word	1, 1, PARAM_2-OL_MARK_WIDTH-2, PARAM_3-1
	word	1,						EOREGREC
	word	PARAM_3-3, 2, PARAM_2-OL_MARK_WIDTH-4,		EOREGREC
	word	EOREGREC

CBRlistBoxExterior	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0, 0, PARAM_2-1,				EOREGREC
	word	PARAM_3-2, 0, 0, PARAM_2-OL_MARK_WIDTH-3,\
				 PARAM_2-OL_MARK_WIDTH-3,	EOREGREC
	word	EOREGREC
	
endif		;PM  ---------------------------------------------------------

if _FXIP
DrawColorRegions	ends
else
DrawColor ends
endif

endif		; if not _ASSUME_BW_ONLY
