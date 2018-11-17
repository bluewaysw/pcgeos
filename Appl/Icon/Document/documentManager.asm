COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Icon Editor
FILE:		documentManager.asm

AUTHOR:		Steve Yegge, Sep  2, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/ 2/92		Initial revision

DESCRIPTION:
 

	$Id: documentManager.asm,v 1.1 97/04/04 16:06:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	iconGeode.def
include token.def

; include any other .def files local to this module

include	documentConstant.def

;-----------------------------------------------------------------------------
;		class instances
;-----------------------------------------------------------------------------

idata	segment

	IconProcessClass
	IconApplicationClass
	IconBitmapClass
	IconFatbitsClass
	DBViewerClass
	BMOVisContentClass
	TokenValueClass
	ImportValueClass

idata	ends

;; method	PROC_NAME,		CLASS_NAME, 	MSG_NAME

;-----------------------------------------------------------------------------
;  methods defined for DBViewerClass in the Preview Module
;-----------------------------------------------------------------------------

method	dynamic	DBViewerUpdatePreviewArea,		DBViewerClass, \
				MSG_DB_VIEWER_UPDATE_PREVIEW_AREA
method	dynamic	DBViewerSetPreviewObject, 		DBViewerClass, 	\
				MSG_DB_VIEWER_SET_PREVIEW_OBJECT
method	dynamic DBViewerApplyPreviewColorChanges,	DBViewerClass,	\
				MSG_DB_VIEWER_APPLY_PREVIEW_COLOR_CHANGES

;-----------------------------------------------------------------------------
; methods defined for DBViewerClass in the Source module
;-----------------------------------------------------------------------------

method	dynamic	DBViewerWriteSource,	DBViewerClass,	\
				MSG_DB_VIEWER_WRITE_SOURCE

;-----------------------------------------------------------------------------
; methods defined in the Format module for DBViewerClass
;-----------------------------------------------------------------------------

method	dynamic DBViewerAddFormat,		DBViewerClass, 	\
				MSG_DB_VIEWER_ADD_FORMAT
method	dynamic	DBViewerDeleteFormat, 		DBViewerClass,	\
				MSG_DB_VIEWER_DELETE_FORMAT
method	dynamic	DBViewerSwitchFormat, 		DBViewerClass,	\
				MSG_DB_VIEWER_SWITCH_FORMAT	
method	dynamic	DBViewerResizeFormat, 		DBViewerClass, 	\
				MSG_DB_VIEWER_RESIZE_FORMAT
method	dynamic	DBViewerTransformFormat,	DBViewerClass, 	\
				MSG_DB_VIEWER_TRANSFORM_FORMAT
method	dynamic	DBViewerCancelTransform, 	DBViewerClass, 	\
				MSG_DB_VIEWER_CANCEL_TRANSFORM
method	dynamic	DBViewerTestTransform, 		DBViewerClass, 	\
				MSG_DB_VIEWER_TEST_TRANSFORM
method	dynamic	DBViewerInitTFDialog,		DBViewerClass, \
				MSG_DB_VIEWER_INIT_TF_DIALOG
method	dynamic DBViewerTFSetSourceFormat,	DBViewerClass, 	\
				MSG_DB_VIEWER_TF_SET_SOURCE_FORMAT
method	dynamic	DBViewerTFSetDestFormat,	DBViewerClass,	\
				MSG_DB_VIEWER_TF_SET_DEST_FORMAT
method	dynamic	DBViewerRotateFormat, 		DBViewerClass, \
				MSG_DB_VIEWER_ROTATE_FORMAT

; defined in WriteFileCode but Format module

method	dynamic	DBViewerWriteToFile,		DBViewerClass, \
				MSG_DB_VIEWER_WRITE_TO_FILE

;-----------------------------------------------------------------------------
;  methods defined in the Viewer module for DBViewerClass
;-----------------------------------------------------------------------------

method	dynamic	DBViewerRescanDatabase,		DBViewerClass, \
				MSG_DB_VIEWER_RESCAN_DATABASE
method	dynamic	DBViewerGetDatabase,		DBViewerClass, \
				MSG_DB_VIEWER_GET_DATABASE
method	dynamic	DBViewerGetDisplay,		DBViewerClass, \
				MSG_DB_VIEWER_GET_DISPLAY
method	dynamic	DBViewerInvalidate,		DBViewerClass, \
				MSG_DB_VIEWER_INVALIDATE
method	dynamic	DBViewerAddChild,		DBViewerClass, \
				MSG_DB_VIEWER_ADD_CHILD
method	dynamic	DBViewerSetSingleSelection,	DBViewerClass, \
				MSG_DB_VIEWER_SET_SINGLE_SELECTION
method	dynamic	DBViewerSetSelection,		DBViewerClass, \
				MSG_DB_VIEWER_SET_SELECTION
method	dynamic	DBViewerGetFirstSelection,	DBViewerClass, \
				MSG_DB_VIEWER_GET_FIRST_SELECTION
method	dynamic	DBViewerGetNumSelections,	DBViewerClass, \
				MSG_DB_VIEWER_GET_NUM_SELECTIONS
method	dynamic	DBViewerGetMultipleSelections,	DBViewerClass, \
				MSG_DB_VIEWER_GET_MULTIPLE_SELECTIONS
method	dynamic	DBViewerIconToggled,		DBViewerClass, \
				MSG_DB_VIEWER_ICON_TOGGLED
method	dynamic	DBViewerShowSelection,		DBViewerClass, \
				MSG_DB_VIEWER_SHOW_SELECTION
method	dynamic	DBViewerEnableUI,		DBViewerClass, \
				MSG_DB_VIEWER_ENABLE_UI

method	dynamic	DBViewerStartSelect,		DBViewerClass, \
				MSG_META_START_SELECT
method	dynamic	DBViewerPtr,			DBViewerClass, \
				MSG_META_PTR
method	dynamic	DBViewerEndSelect,		DBViewerClass, \
				MSG_META_END_SELECT
method	dynamic	DBViewerLostGadgetExcl,		DBViewerClass, \
				MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL
method	dynamic	DBViewerVisDraw,		DBViewerClass, \
				MSG_VIS_DRAW
method	dynamic	DBViewerGetChildSpacing,	DBViewerClass, \
				MSG_VIS_COMP_GET_CHILD_SPACING
method	dynamic	DBViewerGetMargins,		DBViewerClass, \
				MSG_VIS_COMP_GET_MARGINS
method	dynamic	DBViewerVisOpen,		DBViewerClass, \
				MSG_VIS_OPEN
method	dynamic	DBViewerKbdChar,		DBViewerClass, \
				MSG_META_KBD_CHAR

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include	documentDocument.asm
include documentApplication.asm		
include	documentAddIcon.asm
include	documentSaveIcon.asm
include	documentIcon.asm
include documentVisBitmap.asm
include	documentUtils.asm
include documentOptions.asm		
include	documentDatabase.asm
include	documentImpex.asm
include	documentToken.asm
include documentTransfer.asm		
include documentUI.asm
