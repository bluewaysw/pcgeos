COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gdgtable.asm

AUTHOR:		RON, Sep 22, 1995

ROUTINES:
	Name			Description
	----			-----------
 ??none TableDerefSI_DI		The table class is subclass of the gadget
				class. In many ways it is like a
				GenDynamicList.  It doesn't store any of
				the data it displays, it just tells the
				user what to draw where and how often.
				
				Buildtime note: The table has an event for
				overallHeightChanged. This has the
				potential to send many events when the the
				component is being created. To avoid this
				(and other similar problems) there is a
				DisableEvents() in duplo_ui_ui_ui to
				prevent these messages from being
				sent. Often the handler for this would
				change properties on a scrollbar that may
				not have been created yet.
				
				$Revision: 1.1 $

    MTD MSG_META_INITIALIZE	Stuff some instance data.

    MTD MSG_ENT_INITIALIZE	Setup default values.

    MTD MSG_GADGET_TABLE_SET_NUM_ROWS
				Set the instance data and resize the chunk
				array.

    MTD MSG_GADGET_TABLE_SET_NUM_ROWS_INTERNAL
				Sets instance data after values have been
				checked.

 ?? INT TableMakeArrayBigger	

    MTD MSG_GADGET_TABLE_GET_NUM_ROWS
				

    MTD MSG_GADGET_TABLE_SET_OVERALL_HEIGHT
				

    MTD MSG_GADGET_TABLE_GET_OVERALL_HEIGHT
				Property Handler

 ?? INT ComputeOverallHeightLow	Computes the total height of all the rows.

    MTD MSG_GADGET_TABLE_SET_NUM_COLUMNS
				Set the instance data and resize the chunk
				array.

    MTD MSG_GADGET_TABLE_SET_NUM_COLUMNS_INTERNAL
				Sets instance data after values have been
				checked.

    MTD MSG_GADGET_TABLE_GET_NUM_COLUMNS
				

    MTD MSG_GADGET_TABLE_ACTION_SET_ROW_HEIGHTS,
	MSG_GADGET_TABLE_ACTION_SET_COLUMN_WIDTHS
				Legos Action Handler

    MTD MSG_GADGET_TABLE_ACTION_GET_ROW_HEIGHTS,
	MSG_GADGET_TABLE_ACTION_GET_COLUMN_WIDTHS
				

 ?? INT GetItemLow		Gets the value for an item in row/columns
				array.

 ?? INT SetItemLow		Adds an item to the array of row heights or
				column widths

    MTD MSG_GADGET_TABLE_ACTION_SHOW_ROW,
	MSG_GADGET_TABLE_ACTION_SCROLL,
	MSG_GADGET_TABLE_ACTION_GET_ROW_AT,
	MSG_GADGET_TABLE_ACTION_GET_COLUMN_AT,
	MSG_GADGET_TABLE_ACTION_GET_Y_POS_AT,
	MSG_GADGET_TABLE_ACTION_GET_X_POS_AT,
	MSG_GADGET_TABLE_ACTION_GET_ABS_Y_POS_AT
				ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableValidateShowRow	ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableValidateScroll	ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableValidateRowAt	ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableValidateColAt	ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableValidateYPosAt	ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableValidateXPosAt	ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableValidateAbsYPosAtRow
				ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

    MTD MSG_GADGET_TABLE_ACTION_UPDATE
				Update(leftColumn as integer, topRow as
				integer, rightColumn as integer, bottomRow
				as integer)

 ?? INT Get4ActionArgs		Get 4 args for actions.

 ?? INT TableDrawPartialLook	Creates gstate that masks out non-wanted
				cells.

 ?? INT TableDrawSelection	Creates gstate that masks out non-wanted
				cells. Draw the current selection or
				current drag selection.

 ?? INT TableInvertRange	Creates gstate that masks out non-wanted
				cells.

 ?? INT TableClipCoordsToTableArea
				Ensures coordinates are in table
				coordinates (not outside last row /columns)
				and in the visbounds (in case a row /col
				should be clipped visually)

 ?? INT TableScrollLow		Scroll to the row (make it the first
				visible row)

 ?? INT TableScrollPixelLow	Scroll to the pixel (make it the first
				visible pixel)

 ?? INT TableRedrawAllVisible	Do any redrawing that is necessary for
				borders and send updates for all affect
				rows.

 ?? INT TableComputeLastVisibleRow
				Determines what the last visible row on the
				screen is.

    MTD MSG_VIS_DRAW		Draw ourself, our children and tell and
				sent legos events so the user can draw data
				in each cell.

 ?? INT TableDrawLook		Does all drawing necessary to get the right
				look.

 ?? INT DrawDottedCell		Helper routine for drawing looks.  Draws a
				dotted cell. It draws the top, left and
				right sides, not the bottom.

 ?? INT TableQueryCells		Sends an event for cell in the
				range. Doesn't check or change the
				visiblity of anything

    INT RaiseRedrawEvent	Create a basic event so the user can draw a
				cell

    INT RaiseSimpleEvent	Create a basic event so the user can draw a
				cell

    INT RaiseTableRedrawEvent	Create a basic event so the user can draw a
				cell

 ?? INT ConvertRowToYPixel	Find the Y Pixel to correspond to a given
				row. (top pixel in row)

 ?? INT ConvertRowToYPixelCarry	Find the Y Pixel to correspond to a given
				row. (top pixel in row)

 ?? INT ConvertRowToAbsYPixel	Find the Y Pixel to correspond to a given
				row. (top pixel in row)

 ?? INT ConvertColToXPixel	Find the X Pixel to correspond to a given
				col.

 ?? INT ConvertRelYPixelToRow	Find the absolute row that the y coordinate
				falls in. Y is considered to be relative to
				the window bounds not document bounds.

 ?? INT ConvertRelYPixelToRowAndClip
				Just like ConvertRelYPixelToRow, but will
				not return a row greater that
				GT_lastVisibleRow.

 ?? INT ConvertAbsYPixelToRow	Find the absolute row that the y coordinate
				falls in. Y is considered to be relative to
				the document bounds not window bounds.

 ?? INT ConvertPixelCommon	counts the number of elements in the array
				until the sum of the values is greater than
				something passed in.

 ?? INT ConvertXPixelToCol	Find the absolute col that the x coordinate
				falls in.

    MTD MSG_GADGET_TABLE_GET_DEFAULT_ROW_HEIGHT
				

    MTD MSG_GADGET_TABLE_SET_DEFAULT_ROW_HEIGHT
				Legos Property Handler

    MTD MSG_GADGET_TABLE_GET_FIRST_VISIBLE_ROW,
	MSG_GADGET_TABLE_GET_LAST_VISIBLE_ROW
				Legos Property Handler

    MTD MSG_GADGET_TABLE_SET_FIRST_VISIBLE_ROW
				Legos Property Handler

    MTD MSG_GADGET_TABLE_SET_LAST_VISIBLE_ROW
				Legos Property Handler

 ?? INT SetLastVisibleRowLow	Sets the last visible row to show up on the
				bottom of the window.

    MTD MSG_META_START_SELECT	Handle mouse clicks for the object.

    MTD MSG_META_PTR		add the current cell the mouse is over the
				drag-select boundary.

 ?? INT DragSelectLow		Invert old selection and new selection. Set
				the dragSelect instance data appropiately.

    MTD MSG_META_END_SELECT	Update selection and end of drag or scroll

 ?? INT TableCreateTranslatedGState
				Creates a gstate for a table to draw
				in. Translates to coordinates of table so
				the top left of the table is the origin.

    MTD MSG_GADGET_TABLE_SET_LEFT_COLUMN
				Legos Property Handler Set leftColumn and
				perhaps rightColumn.

    MTD MSG_GADGET_TABLE_SET_RIGHT_COLUMN
				Legos Property Handler Set rightColumn and
				perhaps leftColumn.

    MTD MSG_GADGET_TABLE_SET_TOP_ROW
				Legos Property Handler Set toprow and
				perhaps leftColumn.

    MTD MSG_GADGET_TABLE_SET_BOTTOM_ROW
				Legos Property Handler Set bottomrow and
				perhaps leftColumn.

    MTD MSG_GADGET_TABLE_ACTION_SET_SELECTION
				Legos Action Handler Sets the selection to
				be the passed rectangle. Returns
				RunTimeError if any args are invalid or
				don't match the table selection
				type. Generates redraw events for previous
				selection if no error.

    MTD MSG_GADGET_TABLE_GET_TOP_ROW,
	MSG_GADGET_TABLE_GET_BOTTOM_ROW,
	MSG_GADGET_TABLE_GET_LEFT_COLUMN,
	MSG_GADGET_TABLE_GET_RIGHT_COLUMN
				

    INT TableVisRedraw		Redraw self, look, visible cells and
				children.

    MTD MSG_GADGET_TABLE_SET_SELECTION_TYPE
				Legos Property Handler

    MTD MSG_GADGET_TABLE_GET_SELECTION_TYPE
				

    MTD MSG_ENT_GET_CLASS	

    MTD MSG_GADGET_GET_LOOK	

    MTD MSG_GADGET_SET_LOOK	LegosPropertyHandler

    MTD MSG_SPEC_BUILD		Create a clipping window to put the table
				in

    MTD MSG_VIS_OPEN_WIN	Create a window to put our children in

    MTD MSG_GADGET_TABLE_SCROLL_UP
				scroll the table up one row if not already
				at the top.

    MTD MSG_GADGET_TABLE_SCROLL_DOWN
				scroll the table down one row if not
				already at the top.

 ?? INT ConvertMouseCoordsToCell
				Converts coords passed by MSG_META_(MOUSE)
				to the cell that it refers to

 ?? INT SendCorrectScrollMessage
				Either sends scroll up or scroll down
				depending on where the mouse is relative
				table

    MTD MSG_GADGET_TABLE_DRAG_UP,
	MSG_GADGET_TABLE_DRAG_DOWN
				After a drag select timer expires, scroll
				the table and start a new timer.  This is a
				common routine for scrolling both up and
				down

 ?? INT CurrentCellForMouse	Return the cell the mouse is over or
				nearest. This is used by the drag select
				mechanism and often the mouse will be
				outside the table.

 ?? INT TableRedrawSelection	Redraws the currently selected cells and
				the selection after a selection change

 ?? INT TableUndrawSelection	Redraws the currently selected cells
				without the selection.

 ?? INT TableGetCellsForSelection
				Converts selection values into rows.
				(accounts for *special* values)

 ?? INT TableStopTimer		Stops a drag scroll timer it if it running

    MTD MSG_ENT_DESTROY		Turn off the timer for good and tell
				ourselves that we don't want it turned back
				on.

?? none TableDerefSI_DI						

 ?? INT TableMakeArrayBigger	

 ?? INT ComputeOverallHeightLow	Computes the total height of all the rows.

 ?? INT GetItemLow		Gets the value for an item in row/columns
				array.

 ?? INT SetItemLow		Adds an item to the array of row heights or
				column widths

 ?? INT TableValidateShowRow	ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableValidateScroll	ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableValidateRowAt	ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableValidateColAt	ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableValidateYPosAt	ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableValidateXPosAt	ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableValidateAbsYPosAtRow
				ShowRow(row as integer) Scroll(yposition as
				integer) GetRowAt(yPos as integer) as
				integer GetColumnAt(xPos as integer) as
				integer GetYPosAt(row as integer) as
				integer GetXPosAt(column as integer) as
				integer GetAbsYPosAt(row as integer) as
				long

 ?? INT TableDrawPartialLook	Creates gstate that masks out non-wanted
				cells.

 ?? INT TableDrawSelection	Creates gstate that masks out non-wanted
				cells. Draw the current selection or
				current drag selection.

 ?? INT TableInvertRange	Creates gstate that masks out non-wanted
				cells.

 ?? INT TableClipCoordsToTableArea
				Ensures coordinates are in table
				coordinates (not outside last row /columns)
				and in the visbounds (in case a row /col
				should be clipped visually)

 ?? INT TableScrollLow		Scroll to the row (make it the first
				visible row)

 ?? INT TableScrollPixelLow	Scroll to the pixel (make it the first
				visible pixel)

 ?? INT TableRedrawAllVisible	Do any redrawing that is necessary for
				borders and send updates for all affect
				rows.

 ?? INT TableComputeLastVisibleRow
				Determines what the last visible row on the
				screen is.

 ?? INT TableDrawLook		Does all drawing necessary to get the right
				look.

 ?? INT TableQueryCells		Sends an event for cell in the
				range. Doesn't check or change the
				visiblity of anything

    INT RaiseRedrawEvent	Create a basic event so the user can draw a
				cell

    INT RaiseSimpleEvent	Create a basic event so the user can draw a
				cell

    INT RaiseTableRedrawEvent	Create a basic event so the user can draw a
				cell

 ?? INT ConvertRowToYPixel	Find the Y Pixel to correspond to a given
				row. (top pixel in row)

 ?? INT ConvertRowToYPixelCarry	Find the Y Pixel to correspond to a given
				row. (top pixel in row)

 ?? INT ConvertRowToAbsYPixel	Find the Y Pixel to correspond to a given
				row. (top pixel in row)

 ?? INT ConvertColToXPixel	Find the X Pixel to correspond to a given
				col.

 ?? INT ConvertRelYPixelToRow	Find the absolute row that the y coordinate
				falls in. Y is considered to be relative to
				the window bounds not document bounds.

 ?? INT ConvertRelYPixelToRowAndClip
				Just like ConvertRelYPixelToRow, but will
				not return a row greater that
				GT_lastVisibleRow.

 ?? INT ConvertAbsYPixelToRow	Find the absolute row that the y coordinate
				falls in. Y is considered to be relative to
				the document bounds not window bounds.

 ?? INT ConvertPixelCommon	counts the number of elements in the array
				until the sum of the values is greater than
				something passed in.

 ?? INT ConvertXPixelToCol	Find the absolute col that the x coordinate
				falls in.

 ?? INT SetLastVisibleRowLow	Sets the last visible row to show up on the
				bottom of the window.

 ?? INT DragSelectLow		Invert old selection and new selection. Set
				the dragSelect instance data appropiately.

 ?? INT TableCreateTranslatedGState
				Creates a gstate for a table to draw
				in. Translates to coordinates of table so
				the top left of the table is the origin.

    INT TableVisRedraw		Redraw self, look, visible cells and
				children.

 ?? INT ConvertMouseCoordsToCell
				Converts coords passed by MSG_META_(MOUSE)
				to the cell that it refers to

 ?? INT SendCorrectScrollMessage
				Either sends scroll up or scroll down
				depending on where the mouse is relative
				table

 ?? INT CurrentCellForMouse	Return the cell the mouse is over or
				nearest. This is used by the drag select
				mechanism and often the mouse will be
				outside the table.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/22/95		Initial revision


DESCRIPTION:

	The table class is subclass of the gadget class.
	In many ways it is like a GenDynamicList.  It doesn't store any
	of the data it displays, it just tells the user what to draw where
	and how often.

	Buildtime note: The table has an event for
	overallHeightChanged. This has the potential to send many
	events when the the component is being created. To avoid this
	(and other similar problems) there is a DisableEvents() in
	duplo_ui_ui_ui to prevent these messages from being sent.
	Often the handler for this would change properties on a
	scrollbar that may not have been created yet.
		

	$Id: gdgtable.asm,v 1.1 98/03/11 04:28:01 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include Objects/winC.def
include Internal/grWinInt.def
include Internal/im.def

TIMER_ID_DONT_START equ -1
; Set the timerID to that when we don't want start another timer
; becuase we already received a destroy message.

ThreeWordsStack	struct
	TWS_word1	word
	TWS_word2	word
	TWS_word3	word
ThreeWordsStack	ends



;
; This next structure is useful to callers of
; TableClipCoordsToTableArea.
;
TABLE_CLIP_COORDS_LOCALS	equ	<\
.warn -unref_local \
leftPixel	local	word \
rightPixel	local	word \
topPixel	local	dword \
bottomPixel	local	dword \
firstVisPixel	local	dword \
visWidth	local	word \
visHeight	local	word \
windowRelative	local	word \
.warn @unref_local \
>



PrintMessage <Ron - fix the inChunk assertion>
Assert_inChunk	macro	expr, chunk, seg
		if 0
		PreserveAndGetIntoReg	dx, expr
		PreserveAndGetIntoReg	si, chunk
		PreserveAndGetIntoReg	ds, seg
		push	bx
		mov	bx, ds:[si]		; ds:bx = ChunkPtr
		Assert	ge dx, bx
		add	bx, ds:[bx].LMC_size
		
		Assert	l dx, bx
		pop	bx
		RestoreReg	ds, seg
		RestoreReg	si, chunk
		RestoreReg	dx, expr
		endif
endm

idata	segment
	GadgetTableClass
idata	ends

GadgetGadgetCode	segment resource

makePropEntry table, numRows, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_GET_NUM_ROWS>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_SET_NUM_ROWS>

makePropEntry table, overallHeight, LT_TYPE_LONG,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_GET_OVERALL_HEIGHT>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_SET_OVERALL_HEIGHT>

makePropEntry table, numColumns, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_GET_NUM_COLUMNS>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_SET_NUM_COLUMNS>

makePropEntry table, defaultRowHeight, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE,<PD_message MSG_GADGET_TABLE_GET_DEFAULT_ROW_HEIGHT>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_SET_DEFAULT_ROW_HEIGHT>

makePropEntry table, firstVisibleRow, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE,<PD_message MSG_GADGET_TABLE_GET_FIRST_VISIBLE_ROW>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_SET_FIRST_VISIBLE_ROW>

makePropEntry table, selectionType, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_GET_SELECTION_TYPE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_SET_SELECTION_TYPE>

makePropEntry table, leftColumn, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_GET_LEFT_COLUMN>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_SET_LEFT_COLUMN>

makePropEntry table, topRow, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_GET_TOP_ROW>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_SET_TOP_ROW>

makePropEntry table, rightColumn, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_GET_RIGHT_COLUMN>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_SET_RIGHT_COLUMN>

makePropEntry table, bottomRow, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_GET_BOTTOM_ROW>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_SET_BOTTOM_ROW>

makePropEntry table, lastVisibleRow, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE,<PD_message MSG_GADGET_TABLE_GET_LAST_VISIBLE_ROW>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TABLE_SET_LAST_VISIBLE_ROW>

makePropEntry table, look, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE,<PD_message MSG_GADGET_GET_LOOK>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_LOOK>


;
; Keep defaultRowHeight before numRows
;
compMkPropTable GadgetTableProperty, table, defaultRowHeight, numRows, overallHeight, numColumns, firstVisibleRow, selectionType, leftColumn, topRow, rightColumn, bottomRow, lastVisibleRow, look

makeActionEntry table, ShowRow, MSG_GADGET_TABLE_ACTION_SHOW_ROW, \
			LT_TYPE_INTEGER, VAR_NUM_PARAMS
makeActionEntry table, Scroll, MSG_GADGET_TABLE_ACTION_SCROLL, \
			LT_TYPE_INTEGER, 1
makeActionEntry table, Update, MSG_GADGET_TABLE_ACTION_UPDATE, \
			LT_TYPE_INTEGER, 4
makeActionEntry table, GetRowAt, MSG_GADGET_TABLE_ACTION_GET_ROW_AT, \
			LT_TYPE_INTEGER, 1
makeActionEntry table, GetColumnAt, MSG_GADGET_TABLE_ACTION_GET_COLUMN_AT, \
			 LT_TYPE_INTEGER, 1
makeActionEntry table, GetYPosAt, MSG_GADGET_TABLE_ACTION_GET_Y_POS_AT, \
			 LT_TYPE_INTEGER, 1
makeActionEntry table, GetXPosAt, MSG_GADGET_TABLE_ACTION_GET_X_POS_AT, \
			 LT_TYPE_INTEGER, 1
makeActionEntry	table, GetAbsYPosAt, MSG_GADGET_TABLE_ACTION_GET_ABS_Y_POS_AT,\
			 LT_TYPE_LONG, 1
makeActionEntry	table, GetrowHeights, MSG_GADGET_TABLE_ACTION_GET_ROW_HEIGHTS, LT_TYPE_INTEGER,VAR_NUM_PARAMS
makeActionEntry	table, SetrowHeights, MSG_GADGET_TABLE_ACTION_SET_ROW_HEIGHTS, LT_TYPE_INTEGER,VAR_NUM_PARAMS
makeActionEntry	table, GetcolumnWidths, MSG_GADGET_TABLE_ACTION_GET_COLUMN_WIDTHS, LT_TYPE_INTEGER,VAR_NUM_PARAMS
makeActionEntry	table, SetcolumnWidths, MSG_GADGET_TABLE_ACTION_SET_COLUMN_WIDTHS, LT_TYPE_INTEGER,VAR_NUM_PARAMS
makeActionEntry table, SetSelection, MSG_GADGET_TABLE_ACTION_SET_SELECTION, \
			LT_TYPE_INTEGER, 4

compMkActTable table, ShowRow, Scroll,	\
		 Update, GetRowAt, GetColumnAt, GetYPosAt, GetXPosAt, GetAbsYPosAt, GetrowHeights, SetrowHeights, GetcolumnWidths, SetcolumnWidths, SetSelection

MakeActionRoutines Table, table
MakePropRoutines Table, table

Assert_ValidTableInstanceData macro
		if 0
		Assert	srange ds:[di].GT_numRows, 1, GADGET_TABLE_MAX_ROWS-1
		Assert	srange ds:[di].GT_numCols, 1, GADGET_TABLE_MAX_COLS-1
		
		Assert	ne 0, ds:[di].GT_rowHeights
		Assert	ne 0, ds:[di].GT_columnWidths
		Assert	chunk ds:[di].GT_rowHeights, ds
		Assert	chunk ds:[di].GT_columnWidths, ds

		Assert	srange ds:[di].GT_defaultRowHeight, 0, 1000
		endif
		
endm

TableDerefSI_DI	proc	near
		.enter
		Assert	objectPtr, dssi, GadgetTableClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetTable_offset
		.leave
		ret
TableDerefSI_DI	endp

TABLE_DRAG_TIMER_INTERVAL equ 10


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff some instance data.

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es	= segment of GadgetTableClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:
		Here we set first/lastVisibleRow to 0 even though
		numRows and numColumns =0 --> first/lastVisibleRow should
		be -1.  It's simpler to report "-1" when the user asks
		for first/lastVisibleRow rather than worry about updating
		them whenever numRows or numColumns becomes zero/non-zero.
		See GET_FIRST/LAST_VISIBLE_ROW.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/22/95		Initial version
	jmagasin 7/2/96		Don't init. selections to -1 (except for
				leftSelection.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableMetaInitialize	method dynamic GadgetTableClass, 
					MSG_META_INITIALIZE
		.enter
		mov	di, offset GadgetTableClass
		call	ObjCallSuperNoLock
		call	TableDerefSI_DI

	;
	; Create the arrays in the EntInitialize handler but stuff constants
	; here.
	;
		clr	ax
		mov	ds:[di].GT_numRows, ax
		mov	ds:[di].GT_numCols, ax
		mov	ds:[di].GT_defaultRowHeight, GADGET_TABLE_DEFAULT_DEFAULT_ROW_HEIGHT
		mov	ds:[di].GT_selectionType, GTST_SELECT_ROW

		mov	ds:[di].GT_firstVisibleRow, ax		; (see side
		mov	ds:[di].GT_lastVisibleRow, ax		;  effects)
		mov	ds:[di].GT_leftSelection, GADGET_TABLE_SELECT_NONE
		mov	ds:[di].GT_rightSelection, ax
		mov	ds:[di].GT_topSelection, ax
		mov	ds:[di].GT_bottomSelection, ax
		mov	ds:[di].GI_look, LOOK_TABLE_RECORD_LIST
		mov	ds:[di].GT_dragSelectStart.TC_row, GADGET_TABLE_NO_DRAG_IN_PROCESS
		.leave
		ret
GadgetTableMetaInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup default values.

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es	= segment of GadgetTableClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableEntInitialize	method dynamic GadgetTableClass, 
					MSG_ENT_INITIALIZE
		uses		bp
		.enter
		mov	di, offset GadgetTableClass
		call	ObjCallSuperNoLock

		mov	bp, si			; self
ifdef	TABLE_IN_WINDOW
	;
	; Mark self as being window.  This should be done in META_INITIALIZE
	; for the VisComp, but we don't get that message :(
	; However, it just happened so we can do this now.
	; Also, we want to make sure to do this now, not it SPEC_BUILD because
	; the spui wants it done now.
EC <		call	VisCheckVisAssumption				>
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		BitSet	ds:[di].VI_typeFlags, VTF_IS_WINDOW
endif
		
	;
	; Create rowHeight and colWidthArrays.
	;
		mov	cx, size word		; space for 1 word
		mov	al, mask OCF_DIRTY

		call	LMemAlloc
		jc	errorDone
	; set first element
		mov	si, ax			; new chunk
		mov	di, ds:[si]		; ptr into array
		mov	{word} ds:[di], GADGET_TABLE_DEFAULT_DEFAULT_ROW_HEIGHT

		mov	di, ds:[bp]
		add	di, ds:[di].GadgetTable_offset

		mov	ds:[di].GT_rowHeights, ax

	; now the other array
		Assert	e cx, 2	; size word
		mov	al, mask OCF_DIRTY
		call	LMemAlloc
		jc	errorDone
	; set first element
		mov	si, ax
		mov	di, ds:[si]
		mov	{word} ds:[di], GADGET_TABLE_DEFAULT_COL_WIDTH
		

		mov	di, ds:[bp]
		add	di, ds:[di].GadgetTable_offset
		mov	ds:[di].GT_columnWidths, ax

	; Fixup pen events to only send selection.
	; We will only send these when the correct selection is set.
	; Because the default is row selection, we shouldn't get any
	; pen events.
		CheckHack <GadgetTable_offset eq GadgetGadget_offset>
		and	ds:[di].GGI_gadgetFlags, not ALL_PEN_EVENTS

	;FIXME do something for errors here.
errorDone:		
		
		.leave
		ret
GadgetTableEntInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetNumRows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the instance data and resize the chunk array.

CALLED BY:	MSG_GADGET_TABLE_SET_NUM_ROWS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetNumRows	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SET_NUM_ROWS
		.enter
		mov	bx, di		; instance ptr
		Assert	fptr ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr esdi
		mov	cx, es:[di].CD_data.LD_integer

		cmp	cx, 0
		jge	checkMax
		clr	cx
		jmp	checked
checkMax:
		cmp	cx, GADGET_TABLE_MAX_ROWS
		jl	checked
		mov	cx, GADGET_TABLE_MAX_ROWS - 1
checked:
		mov	ax, MSG_GADGET_TABLE_SET_NUM_ROWS_INTERNAL
		call	ObjCallInstanceNoLock

	;
	; Let the user know he just changed the height of the table.
	;
		mov	di, offset tableHeightChangedString
		call	RaiseSimpleEvent

		call	TableVisRedraw
		.leave
		Destroy	ax, cx, dx
		ret


GadgetTableSetNumRows	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetNumRowsInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets instance data after values have been checked.

CALLED BY:	MSG_GADGET_TABLE_SET_NUM_ROWS_INTERNAL
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es	= segment of GadgetTableClass
		ax	= message #
		cx	= numRows
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		There isn't an 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetNumRowsInternal	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SET_NUM_ROWS_INTERNAL
		.enter
		Assert	ValidTableInstanceData
		push	si		; object
		shl	cx		; convert num elements to num bytes
		push	cx
		tst	cx
		jnz	gotsize
		inc	cx	; make sure our chunk is not zero si
gotsize:
		mov	dx, ds:[di].GT_numRows	; old number rows
		mov	ax, ds:[di].GT_rowHeights
		mov	bx, ds:[di].GT_defaultRowHeight
		call	LMemReAlloc
		shl	dx
		pop	cx
		cmp	cx, dx
	; did we get bigger
		jl	done			; No, we got smaller
bigger::
		call	TableMakeArrayBigger
done:
		pop	si			; object
		Assert	chunk	si, ds
		call	TableDerefSI_DI

	; store the new size
		shr	cx
		clr	dx			; last visible row
		mov	ds:[di].GT_numRows, cx

	; Make sure the first and last row are still valid.
		cmp	ds:[di].GT_firstVisibleRow, cx
		jb	checkLast

	; if cx is zero, then we will set firstVisibleRow to -1, otherwise
	; if firstVisibleRows was -1, set it to zero, otherwise, set it to
	; numRows - 1
		jcxz	setFirst
		cmp	ds:[di].GT_firstVisibleRow, -1
		jne	setFirst
		
		clr	ds:[di].GT_firstVisibleRow
		jmp	checkLast

setFirst:
	; if the table got smaller and the firstVisible row is after
	; the number of rows, set the firstVisibleRow to last row
	; (numRows -1)
		dec	cx
		mov	ds:[di].GT_firstVisibleRow, cx
		inc	cx

checkLast:
	;
	; Compute last visible row if numRows got smaller but is
	; still bigger than firstVisibleRow
		call	TableComputeLastVisibleRow
		Assert	chunk, si, ds
		call	TableDerefSI_DI
		
		mov	ds:[di].GT_lastVisibleRow, dx

	; make sure the selection is still valid
		mov	dx, cx
		jcxz	validateSelection	; Use 0, not -1.
		dec	dx
validateSelection:
		cmp	ds:[di].GT_topSelection, cx
		jl	checkNext
		mov	ds:[di].GT_topSelection, dx
checkNext:
		cmp	ds:[di].GT_bottomSelection, cx
		jl	done2
		mov	ds:[di].GT_bottomSelection, dx
done2:
	.leave
	ret
GadgetTableSetNumRowsInternal	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableMakeArrayBigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		ax	- chunk for table
		bx	- init value for new elements
		cx	- total number of elements in array
		dx	- size of old array
RETURN:		
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableMakeArrayBigger	proc	near
	uses	cx, es
	.enter

	;
	; init all the new elements
		segmov	es, ds
		mov	di, ax			; handle of array
		Assert	chunk	di, es
		mov	di, es:[di]		; es:di <- first element
		Assert	chunkPtr di, es

		add	di, dx			; byte offset of new words
		sub	cx, dx			; size of new words
		shr	cx			; bytes -> words
		Assert	inChunk	di, ax, es
EC <		push	ax						>
		mov	ax, bx			; default row height
		rep	stosw
EC <		dec	di						>
EC <		pop	ax						>
		Assert	inChunk di, ax, es

		.leave
		Destroy	ax, di
		ret
TableMakeArrayBigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableGetNumRows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_TABLE_GET_NUM_ROWS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableGetNumRows	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_GET_NUM_ROWS
	uses	bp
		.enter
		mov	dx, ds:[di].GT_numRows
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr esdi
		mov	es:[di].CD_data.LD_integer, dx
		mov	es:[di].CD_type, LT_TYPE_INTEGER
	.leave
	Destroy	ax, cx, dx
	ret
GadgetTableGetNumRows	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetOverallHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_TABLE_SET_OVERALL_HEIGHT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetOverallHeight	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SET_OVERALL_HEIGHT
		uses	bp
		.enter
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_READONLY_PROPERTY
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTableSetOverallHeight	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableGetOverallHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Property Handler

CALLED BY:	MSG_GADGET_TABLE_GET_OVERALL_HEIGHT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95		Initial version
	jmagasin 7/1/96		Return TYPE_LONG.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableGetOverallHeight	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_GET_OVERALL_HEIGHT
		uses	bp, bx
		.enter
		Assert	ValidTableInstanceData

		call	ComputeOverallHeightLow
		Assert	fptr ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi

		movdw	es:[di].CD_data.LD_long, dxbx
		mov	es:[di].CD_type, LT_TYPE_LONG
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTableGetOverallHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeOverallHeightLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Computes the total height of all the rows.

CALLED BY:	GadgetTableGetOverallHeight, TableScrollPixelLow
PASS:		*ds:si		- Table Object
		ds:di		- instance data
RETURN:		dx:bx		- overall height
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeOverallHeightLow	proc	near
		class	GadgetTableClass
		uses	si, ax, di
		.enter

	;
	; Compute the height by adding all the heights.
	;
		mov	cx, ds:[di].GT_numRows
		mov	di, ds:[di].GT_rowHeights
		mov	si, ds:[di]		; ptr into array

		clrdw	dxbx			; tally
		jcxz	tallied

tally:
		Assert	inChunk	si, di, ds
		lodsw
		add	bx, ax
		adc	dx, 0
		loop	tally
tallied:
		.leave
		ret
ComputeOverallHeightLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetNumColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the instance data and resize the chunk array.

CALLED BY:	MSG_GADGET_TABLE_SET_NUM_COLUMNS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetNumColumns method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SET_NUM_COLUMNS
		.enter
		mov	bx, di		; instance ptr
		Assert	fptr ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr esdi
		mov	cx, es:[di].CD_data.LD_integer

		cmp	cx, 0
		jge	checkMax
		mov	cx, 0
		jmp	checked
checkMax:
		cmp	cx, GADGET_TABLE_MAX_COLS
		jl	checked
		mov	cx, GADGET_TABLE_MAX_COLS
		dec	cx
checked:
		mov	ax, MSG_GADGET_TABLE_SET_NUM_COLUMNS_INTERNAL
		call	ObjCallInstanceNoLock

		call	TableVisRedraw

		.leave
		Destroy	ax, cx, dx
		ret


GadgetTableSetNumColumns	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetNumColumnsInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets instance data after values have been checked.

CALLED BY:	MSG_GADGET_TABLE_SET_NUM_COLUMNS_INTERNAL
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es	= segment of GadgetTableClass
		ax	= message #
		cx	= numColumns
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		There isn't an 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetNumColumnsInternal	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SET_NUM_COLUMNS_INTERNAL
		.enter
		Assert	objectPtr dssi, GadgetTableClass
		Assert	ValidTableInstanceData
		push	si		; object
	; dont go down to zero sized chunk
		shl	cx		; convert num elements to num bytes
		push	cx
		tst	cx
		jnz	gotsize
		inc	cx
gotsize:
		mov	dx, ds:[di].GT_numCols	; old number columns
		mov	ax, ds:[di].GT_columnWidths
		call	LMemReAlloc
		shl	dx
		pop	cx
		cmp	cx, dx
	; did we get bigger
		jl	done			; No, we got smaller
bigger::
		clr	bx			; size of new columns
		call	TableMakeArrayBigger
done:
		pop	si		; object
		call	TableDerefSI_DI

	; store the new size
		shr	cx
		mov	ds:[di].GT_numCols, cx

	; make sure the selection is still valid
		mov	dx, cx
		dec	dx
		cmp	ds:[di].GT_leftSelection, cx
		jl	checkNext
		mov	ds:[di].GT_leftSelection, dx
checkNext:
		cmp	ds:[di].GT_rightSelection, cx
		jl	done2
		cmp	dx, -1
		jne	stuffRightSelection
		inc	dx
stuffRightSelection:
		mov	ds:[di].GT_rightSelection, dx
done2:
	.leave
	ret
GadgetTableSetNumColumnsInternal	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableGetNumColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_TABLE_GET_NUM_COLUMNS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableGetNumColumns	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_GET_NUM_COLUMNS
	uses	bp
		.enter
		mov	dx, ds:[di].GT_numCols
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr esdi
		mov	es:[di].CD_data.LD_integer, dx
		mov	es:[di].CD_type, LT_TYPE_INTEGER
	.leave
	Destroy	ax, cx, dx
	ret
GadgetTableGetNumColumns	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableActionSetRowHeights
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Action Handler

CALLED BY:	MSG_GADGET_TABLE_ACTION_SET_ROW_HEIGHTS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableActionSetRowHeights	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_ACTION_SET_ROW_HEIGHTS,
					MSG_GADGET_TABLE_ACTION_SET_COLUMN_WIDTHS
		.enter
		push	si			; self
		cmp	ax, MSG_GADGET_TABLE_ACTION_SET_COLUMN_WIDTHS
		je	cols
		Assert	e, ax MSG_GADGET_TABLE_ACTION_SET_ROW_HEIGHTS
		mov	si, ds:[di].GT_rowHeights
		mov	cx, ds:[di].GT_numRows
		jmp	setItem
cols:
		mov	si, ds:[di].GT_columnWidths
		mov	cx, ds:[di].GT_numCols

setItem:
		push	ax			; message
		call	SetItemLow
		pop	ax
		pop	si			; self
		Assert	chunk	si, ds
		call	TableComputeLastVisibleRow
		call	TableDerefSI_DI
		mov	ds:[di].GT_lastVisibleRow, dx
		cmp	ax, MSG_GADGET_TABLE_ACTION_SET_ROW_HEIGHTS
		jne	redraw
		mov	di, offset tableHeightChangedString
		call	RaiseSimpleEvent
redraw:
		call	TableVisRedraw
		
done::		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTableActionSetRowHeights	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableActionGetRowHeights
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_TABLE_ACTION_GET_ROW_HEIGHTS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		SPA_compData.CD_type possibly get to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableActionGetRowHeights	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_ACTION_GET_ROW_HEIGHTS,
					MSG_GADGET_TABLE_ACTION_GET_COLUMN_WIDTHS
		.enter
		cmp	ax, MSG_GADGET_TABLE_ACTION_GET_COLUMN_WIDTHS
		je	cols
		Assert	e, ax MSG_GADGET_TABLE_ACTION_GET_ROW_HEIGHTS
		mov	si, ds:[di].GT_rowHeights
		mov	cx, ds:[di].GT_numRows
		jmp	getItem
cols:
		mov	si, ds:[di].GT_columnWidths
		mov	cx, ds:[di].GT_numCols

getItem:
		call	GetItemLow
done::		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTableActionGetRowHeights	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetItemLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the value for an item in row/columns array.

CALLED BY:	GadgetTableActionGetRowHeights
PASS:		cx	= numRows/ cols
		si	= array of widths / cols
		ss:bp	= EntDoActionArgs

RETURN:		
DESTROYED:	ax, bx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetItemLow	proc	near
		uses	es, di
		.enter
	;
	; Get the height specified by the index passed in.
		
		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
		mov	ax, CAE_WRONG_TYPE
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	error
		mov	bx, es:[di].CD_data.LD_integer	; index to array
		cmp	bx, 0
		jl	error
		cmp	bx, cx
		jge	error
		
		shl	bx		; word -> byte offset

		mov	si, ds:[si]	; deref array
		mov	dx, ds:[si][bx]	; value

	;
	; Return the value
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, dx
done:
		
		.leave
		ret
error:
	;
	; Some error, ax contains which one.
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		jmp	done
GetItemLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetItemLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds an item to the array of row heights or column widths

CALLED BY:	GadgetTableActionSetColumnHeights
PASS:		ss:bp	- EntDoActionArgs
		si	- chunk or row/column array
		cx	- num items in array
RETURN:		ss:[bp].EDAA_retval filled in if error.
DESTROYED:	ax, bx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetItemLow	proc	near
		uses	es, di
		.enter

		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		jcxz	error
	;
	; Set the item specified by the index.
	; There is no return value.
	; cx = numRows/ cols
	; si = rowHeights/ colWidths array lptr

		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi

	; get the index arg
		mov	ax, CAE_WRONG_TYPE
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	error
		mov	bx, es:[di].CD_data.LD_integer
	; get the value arg
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_INTEGER
		jne	error
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		mov	dx, es:[di][size ComponentData].CD_data.LD_integer
		cmp	dx, 0
		jge	checkGreater
		clr	dx
		jmp	checkIndex
checkGreater:
		cmp	dx, 1024
		jle	checkIndex
		mov	dx, 1024
checkIndex:
	; make sure the index is valid
		cmp	bx, 0
		jl	error
		cmp	bx, cx			; past end?
		jge	error

		shl	bx			; word -> byte offset

		mov	di, ds:[si]		; deref array
		mov	ds:[di][bx], dx		; value
done:
		.leave
		ret
error:

	;
	; Some error, ax contains which one.
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		jmp	done
SetItemLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableActionScroll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ShowRow(row as integer)
		Scroll(yposition as integer)
		GetRowAt(yPos as integer) as integer
		GetColumnAt(xPos as integer) as integer
		GetYPosAt(row as integer) as integer
		GetXPosAt(column as integer) as integer
		GetAbsYPosAt(row as integer) as long

CALLED BY:	MSG_GADGET_TABLE_ACTION_SCROLL
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es	= segment of GadgetTableClass
		ax	= message #
		ss:bp	= EntDoActionArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95		Initial version
	jmagasin 7/2/96		Replaced TableValidate routines (which were
				empty) with TableGet  routines.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
validateTable	nptr	offset TableGetIntegerArg,  ; TableValidateShowRow,
			offset TableGetLongArg,     ; TableValidateScroll
			offset TableGetIntegerArg,  ; TableValidateRowAt,
			offset TableGetIntegerArg,  ; TableValidateColAt,
			offset TableGetIntegerArg,  ; TableValidateYPosAt,
			offset TableGetIntegerArg,  ; TableValidateXPosAt,
			offset TableGetIntegerArg   ; TableValidateAbsYPosAtRow

actionTable	nptr	offset TableScrollLow,
			offset TableScrollPixelLow,
			offset ConvertRelYPixelToRowAndClip,
			offset ConvertXPixelToCol,
			offset ConvertRowToYPixelCarry,
			offset ConvertColToXPos,
			offset ConvertRowToAbsYPixel

GadgetTableActionScroll	method dynamic GadgetTableClass,
					MSG_GADGET_TABLE_ACTION_SHOW_ROW,
					MSG_GADGET_TABLE_ACTION_SCROLL,
					MSG_GADGET_TABLE_ACTION_GET_ROW_AT,
					MSG_GADGET_TABLE_ACTION_GET_COLUMN_AT,
					MSG_GADGET_TABLE_ACTION_GET_Y_POS_AT,
					MSG_GADGET_TABLE_ACTION_GET_X_POS_AT,
					MSG_GADGET_TABLE_ACTION_GET_ABS_Y_POS_AT
	;
	; The jump table order needs to match the message order.
	;
		CheckHack <MSG_GADGET_TABLE_ACTION_SHOW_ROW + 1 eq \
			   MSG_GADGET_TABLE_ACTION_SCROLL>
		CheckHack <MSG_GADGET_TABLE_ACTION_SCROLL + 1 eq \
			   MSG_GADGET_TABLE_ACTION_GET_ROW_AT>
		CheckHack <MSG_GADGET_TABLE_ACTION_GET_ROW_AT + 1 eq \
			   MSG_GADGET_TABLE_ACTION_GET_COLUMN_AT>
		CheckHack <MSG_GADGET_TABLE_ACTION_GET_COLUMN_AT + 1 eq \
			   MSG_GADGET_TABLE_ACTION_GET_Y_POS_AT>
		CheckHack <MSG_GADGET_TABLE_ACTION_GET_Y_POS_AT + 1 eq \
			   MSG_GADGET_TABLE_ACTION_GET_X_POS_AT>
		CheckHack <MSG_GADGET_TABLE_ACTION_GET_X_POS_AT + 1 eq \
			   MSG_GADGET_TABLE_ACTION_GET_ABS_Y_POS_AT>

		uses	bp
		.enter
		
		Assert	fptr	ssbp
		les	di, ss:[bp].EDAA_argv
		
		sub	ax, MSG_GADGET_TABLE_ACTION_SHOW_ROW
		mov	bx, ax
	;
	; Validate arg and put into ax or dxax.
	;
		shl	bx
		call	{word} cs:[validateTable][bx]
		jc	error
	;
	; Call correct low level routine.  Result goes into ax or dxax.
	;
		call	{word} cs:[actionTable][bx]
	; I don't know how to assert it at compile time, bummer
EC <		mov	di, offset ConvertRowToAbsYPixel		>
EC <		mov	di, cs:[actionTable][12]			>
		Assert	e di, cs:[actionTable][12]
	;
	; if GET_ABS_Y_POS_AT, then return long.
	;
		cmp	bx, 12
		je	returnLong
		mov	cx, LT_TYPE_INTEGER
		mov	dx, ax
		jmp	returnDX
returnLong:
	; dx:ax = value
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_LONG
		movdw	es:[di].CD_data.LD_long, dxax
		jmp	done
error:
		mov	cx, LT_TYPE_ERROR
		mov	dx, CAE_WRONG_TYPE
returnDX:
	; dx = value.
	; cx = type
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, cx
		mov	es:[di].CD_data.LD_integer, dx
done::
		.leave
		ret
GadgetTableActionScroll	endm


;
; Return the integer argument, or error.
;
; Pass: es:di	- fptr to ComponentData
; Retn: ax	- integer (if carry clear)
;       carry	- set if invalid arg
;
;
TableGetIntegerArg	proc	near
		.enter

		Assert	fptr	esdi
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		stc
		jne	done

		mov	ax, es:[di].CD_data.LD_integer
		clc
done:
		.leave
		ret
TableGetIntegerArg	endp

;
; Return the long argument, or error.  Will not promote
; an integer to a long (since no other actions do so now).
;
; Pass: es:di	- fptr to ComponentData
; Retn: dx:ax	- integer (if carry clear)
;       carry	- set if invalid arg
;
;
TableGetLongArg	proc	near
		.enter

		Assert	fptr	esdi
		cmp	es:[di].CD_type, LT_TYPE_LONG
		stc
		jne	done

		movdw	dxax, es:[di].CD_data.LD_long
		clc
done:
		.leave
		ret
TableGetLongArg	endp


if 0
TableValidateScroll	proc	near
		.enter
	;
	; Convert the Y Posistion to a row
	;
if 0; before pixel orientation
		push	dx
		cwd
		call	ConvertAbsYPixelToRow
		pop	dx
		cmp	ax, -1
		jne	done
		clr	ax
done:
endif;
		
		.leave
		ret
TableValidateScroll	endp
endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableActionUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update(leftColumn as integer, topRow as integer,
			rightColumn as integer, bottomRow as integer)

CALLED BY:	MSG_GADGET_TABLE_ACTION_UPDATE
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es	= segment of GadgetTableClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95		Initial version
	jmagasin 7/9/96		Make sure args are legal.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableActionUpdate	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_ACTION_UPDATE
		uses	bp
		.enter
	;
	; If we are in the middle of a drawCell handler, don't cause more
	; to happen.
	;
		mov	ax, ATTR_GADGET_TABLE_DOING_REDRAW
		call	ObjVarFindData
		jc	specificPropError

		call	Get4ActionArgs
		jc	error
	;
	; Make sure args are legal.
	;
		cmp	ax, cx
		jle	gotLeftAndRight
		xchg	ax, cx
gotLeftAndRight:
		tst	ax
		jl	specificPropError		; left<0
		cmp	cx, ds:[di].GT_numCols
		jge	specificPropError		; right too big

		cmp	bx, dx
		jle	gotTopAndBottom			; top>bottom
		xchg	bx, dx
gotTopAndBottom:
		tst	bx
		jl	specificPropError		; top<0
		cmp	dx, ds:[di].GT_numRows
		jge	specificPropError		; bottom too big

	;
	; Now make sure we only draw visible rows
	; If no rows are visible, don't do anything
	;
		cmp	dx, ds:[di].GT_firstVisibleRow
		jl	done		; none visible, go away
		cmp	bx, ds:[di].GT_lastVisibleRow
		jg	done

	; now limit to visible bounds.
		cmp	dx, ds:[di].GT_firstVisibleRow
		jge	checkAfterEnd
		mov	bx, ds:[di].GT_firstVisibleRow
checkAfterEnd:
		cmp	dx, ds:[di].GT_lastVisibleRow
		jle	doCall
		mov	bx, ds:[di].GT_lastVisibleRow

		
doCall:
	;
	; Redraw background of cells
	;
		call	TableDrawPartialLook
		call	TableQueryCells
		call	TableDrawSelection
		Assert	gstate, di
		call	GrDestroyState

done:
		.leave
		ret

specificPropError:
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR

error:
	; ax = error
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		jmp	done
GadgetTableActionUpdate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Get4ActionArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get 4 args for actions.

CALLED BY:	GadgetTableActionUpdate, GadgetTableActionSetSelection
PASS:		ss:bp	= EntDoActionArgs  (4 integer args)
		*ds:si		= Table Object
RETURN:		ax, bx, cx, dx	= args 1-4
		if error, ax = ERROR, carry set
		*ds:di		= instance data, if no error
DESTROYED:	nothing
SIDE EFFECTS:	es

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	5/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Get4ActionArgs	proc	near
		class GadgetTableClass
		.enter
	;
	; Get all the args
	;
		Assert	fptr	ssbp

		les	di, ss:[bp].EDAA_argv
arg1::
		Assert	fptr	esdi
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	wrongType
		mov	ax, es:[di].CD_data.LD_integer
		add	di, size ComponentData
arg2::
		Assert	fptr	esdi
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	wrongType
		mov	bx, es:[di].CD_data.LD_integer
		add	di, size ComponentData
arg3::
		Assert	fptr	esdi
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	wrongType
		mov	cx, es:[di].CD_data.LD_integer
		add	di, size ComponentData
arg4::
		Assert	fptr	esdi
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	wrongType
		mov	dx, es:[di].CD_data.LD_integer
	;
	; make sure the range is valid (> 0 and < max value)
	;
		Assert	chunk	si, ds
		call	TableDerefSI_DI


		cmp	cx, ds:[di].GT_numCols
		jae	valueError		; note the unsigned comparison
checkDX::
		cmp	dx, ds:[di].GT_numRows
		jae	valueError		; leave unsigned to check <0

	;
	; everything is fine
	;
		clc
		jmp	done

valueError:
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		jmp	error
wrongType:
		mov	ax, CAE_WRONG_TYPE
error:
		stc
done:
		.leave
		ret
Get4ActionArgs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableDrawPartialLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates gstate that masks out non-wanted cells.

CALLED BY:	Update action
PASS:		*ds:si		- Table
		ax, bx		- left, top [inclusive]
		cx, dx		- bottom, right [inclusive]
RETURN:		di		- gstate with transformation
				  (needs to be destroyed)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 9/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableDrawPartialLook	proc	near
	;		leftCell	local word	push	ax
		rightCell	local word	push	cx
		topCell		local word	push	bx
		bottomCell	local word	push	dx

		leftPixel	local word
		rightPixel	local word
		topPixel	local word
		bottomPixel	local word
		uses	ax,bx,cx,dx,si,bp
		.enter
	;
	; Get vis bounds for cells.
	;
		call	ConvertColToXPixel
		mov	leftPixel, ax

		mov	ax, rightCell
		inc	ax		; get bound of next cell
		call	ConvertColToXPixel
		mov	rightPixel, ax

		mov	ax, topCell
		call	ConvertRowToYPixel
		mov	topPixel, ax

		mov	ax, bottomCell
		inc	ax		; get bound of next cell
		call	ConvertRowToYPixel
		mov	bottomPixel, ax

		call	TableCreateTranslatedGState
		
		mov	ax, leftPixel
		mov	bx, topPixel
		mov	cx, rightPixel
		mov	dx, bottomPixel
		Assert	gstate, di

	;
	; only draw in the cells to be updated
	;
		push	si			; self
		mov	si, PCT_INTERSECTION
		call	GrSetClipRect
		pop	si			; self
if 0
	;
	; test clip rect
		push	ax, bx, cx, dx
		mov	ax, C_RED
		call	GrSetAreaColor
		clrdw	axbx
		mov	cx, 100
		mov	dx, cx
		call	GrFillRect
		pop	ax, bx, cx, dx
endif

		clr	cx			; DrawFlags
		call	TableDrawLook
		
		.leave
		ret
TableDrawPartialLook	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableDrawSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates gstate that masks out non-wanted cells.
		Draw the current selection or current drag selection.

CALLED BY:	Update action
PASS:		*ds:si		- Table
		di		- gstate

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 9/95	Initial version
	jmagasin 7/18/96	- Updated for new TableClipCoordsToTableArea.
				- Don't draw selection if selectionType is
				  SELECT_NONE or SELECT_CUSTOM

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableDrawSelection	proc	near
			class	GadgetTableClass

		TABLE_CLIP_COORDS_LOCALS
		gstate		local	hptr

		uses	ax,bx,cx,dx,si,di, bp
		.enter
		mov	gstate, di
		
	;
	; Get vis bounds for cells.
	;
		Assert	objectPtr dssi, GadgetTableClass
		Assert	gstate, di
		call	TableDerefSI_DI

		cmp	ds:[di].GT_dragSelectStart.TC_row, GADGET_TABLE_NO_DRAG_IN_PROCESS
		je	normalSelection
		mov	bx, ds:[di].GT_selectionType
		Assert	etype, bx, GadgetTableSelectionType
		Assert	ne, bx, GTST_SELECT_CUSTOM
		Assert	ne, bx, GTST_SELECT_NONE
		shl	bx
		jmp	cs:[TableDrawSelectJumpTable][bx]
	;
	; These "routines" are used for drawing the selection after a
	; forced redraw (due to a drag scroll) while drag selecting.
	; Look farther down to see the normal selection routines.
		
selectRow:
		mov	leftPixel, 0
		mov	ax, ds:[di].GT_dragSelectEnd.TC_row
		mov	bx, ax
		inc	bx
		call	ConvertRowToYPixel
		cwd					; dxax = start
		movdw	topPixel, dxax
		mov_tr	ax, bx				; next row
		call	ConvertRowToYPixel
		cwd					; dxax = end
		movdw	bottomPixel, dxax
		push	bp				; frame
		mov	ax, MSG_VIS_GET_SIZE		
		call	ObjCallInstanceNoLock		; cx <- width
		pop	bp				; frame
		mov	rightPixel, cx
		jmp	drawWindowRelative

selectCol:
		clrdw	topPixel
		mov	ax, ds:[di].GT_dragSelectEnd.TC_col
		mov	bx, ax
		inc	bx
		call	ConvertColToXPixel
		mov	leftPixel, ax
		mov_tr	ax, bx				; next row
		call	ConvertColToXPixel
		mov	rightPixel, ax
		push	bp				; frame
		mov	ax, MSG_VIS_GET_SIZE		
		call	ObjCallInstanceNoLock		; cx <- width
		pop	bp				; frame
		clr	ax
		movdw	bottomPixel, axdx
		jmp	drawWindowRelative

selectCell:
	; FIXME
		mov	ax, ds:[di].GT_dragSelectEnd.TC_row
		mov	cx, ax
		call	ConvertRowToYPixel
		cwd
		movdw	topPixel, dxax
		mov_tr	ax, cx				; end row
		inc	ax
		call	ConvertRowToYPixel
		cwd
		movdw	bottomPixel, dxax

		mov	ax, ds:[di].GT_dragSelectEnd.TC_col
		mov	dx, ax
		call	ConvertColToXPixel
		mov	leftPixel, ax
		mov_tr	ax, dx
		inc	ax
		call	ConvertColToXPixel
		mov	rightPixel, ax
		jmp	drawWindowRelative
		
selectRange:		
	;
	; Instead of drawing the "selection" draw what is currently being
	; selected
		mov	ax, ds:[di].GT_dragSelectStart.TC_row
		mov	cx, ds:[di].GT_dragSelectEnd.TC_row
		cmp	ax, cx
		jle	getSelPixels
		xchg	ax, cx			; make ax first one

getSelPixels:
		call	ConvertRowToYPixel
		cwd
		movdw	topPixel, dxax
		mov_tr	ax, cx
		inc	ax
		call	ConvertRowToYPixel
		cwd
		movdw	bottomPixel, dxax
	; selected
		mov	ax, ds:[di].GT_dragSelectStart.TC_col
		mov	cx, ds:[di].GT_dragSelectEnd.TC_col
		cmp	ax, cx
		jle	getSelPixelsCol
		xchg	ax, cx			; make ax first one

getSelPixelsCol:
		call	ConvertColToXPixel
		mov	leftPixel, ax
		mov_tr	ax, cx
		inc	ax
		call	ConvertColToXPixel
		mov	rightPixel, ax
		jmp	drawWindowRelative

	;
	; Draw what we know is selected, not what is being selected
normalSelection:
		cmp	ds:[di].GT_selectionType, GTST_SELECT_NONE
		je	done
		cmp	ds:[di].GT_selectionType, GTST_SELECT_CUSTOM
		je	done
		mov	ax, ds:[di].GT_leftSelection
		cmp	ax, GADGET_TABLE_SELECT_WHOLE_LINE
		jne	getLeftRight
		mov	leftPixel, 0
		mov	ax, ds:[di].GT_numCols
		call	ConvertColToXPixel
		mov	rightPixel, ax
		jmp	checkTopBottom
getLeftRight:
		cmp	ax, GADGET_TABLE_SELECT_NONE
		je	done
		call	ConvertColToXPixel
		mov	leftPixel, ax

		mov	ax, ds:[di].GT_rightSelection
		inc	ax		; get bound of next cell
		call	ConvertColToXPixel
		mov	rightPixel, ax

checkTopBottom:
		mov	ax, ds:[di].GT_topSelection
		cmp	ax, GADGET_TABLE_SELECT_WHOLE_LINE
		jne	getTopBottom
		clrdw	topPixel
		call	ComputeOverallHeightLow		; dxbx <- height
		movdw	bottomPixel, dxbx, cx
		jmp	drawTableRelative
getTopBottom:
		cmp	ax, GADGET_TABLE_SELECT_NONE
		je	done
		call	ConvertRowToAbsYPixel		; dxax <- ypos
		movdw	topPixel, dxax, cx
		mov	ax, ds:[di].GT_bottomSelection
		inc	ax
		call	ConvertRowToAbsYPixel
		movdw	bottomPixel, dxax, cx

	; Our top/bottomPixels might not be visible.  The are
	; relative to the upper left of the table, i.e., absolute.
drawTableRelative:
		clr	windowRelative
		jmp	draw
		
	; We know our top/bottomPixels are visible.  They are
	; relative to the upper left corner of the table's visible
	; region.
drawWindowRelative:
		mov	windowRelative, -1

draw:
	;
	; make sure coords are clipped to table and vis bounds
	;
		mov	di, gstate
		Assert	gstate, di

		mov	al, MM_INVERT
		call	GrSetMixMode
		mov	ax, C_BLACK
		call	GrSetAreaColor

		call	TableClipCoordsToTableArea
		jc	done
	;		Assert	le ax, cx
	; FIXME: 
	; The following assert fails on selections beyond the end of
	; the screen and I don't have time to fix it right now :(
	;		Assert	le bx, dx

	;
	; Big Ole' hack to get selection to appear to do the right
	; thing under most circumstance for pcv.
		add	ax, 2
		add	bx, 2
		sub	cx, 2
		sub	dx, 1

		call	GrFillRect
done:		
		.leave
		ret

TableDrawSelectJumpTable	nptr	0,	;		- not selectable
				offset	selectCell,
				offset	selectRow,
				offset	selectCol,
				offset	selectRange
		
TableDrawSelection	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableInvertRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates gstate that masks out non-wanted cells.

CALLED BY:	Update action
PASS:		*ds:si		- Table
		di		- gstate
		ax, bx		- left, top cell
		cx, dx		- right, bottom cell

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 9/95	Initial version
	jmagasin 7/18/96	Updated for new TableClipCoordsToTableArea.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableInvertRange	proc	near
			class	GadgetTableClass

		TABLE_CLIP_COORDS_LOCALS
		gstate		local	hptr

		uses	ax,bx,cx,dx,si,di, bp
		.enter
		mov	gstate, di
EC <		call	ECTableCheckLegalCellRange			>
	;
	; Get vis bounds for cells.
	;
		Assert	objectPtr dssi, GadgetTableClass
		Assert	gstate, di

		cmp	ax, cx
		jl	checkVert
		xchg	ax, cx
checkVert:
		cmp	bx, dx
		jl	draw
		xchg	bx, dx

draw:
	; ax, bx  = left, top cell
	; cx, dx  = right, bottom cell
		call	ConvertColToXPixel
		mov	leftPixel, ax
		mov_tr	ax, cx
		inc	ax
		call	ConvertColToXPixel
		mov	rightPixel, ax
		
		mov_tr	ax, bx
		mov	bx, dx				; (save bottom)
		call	ConvertRowToAbsYPixel		; dxax <- yPos
		movdw	topPixel, dxax, cx

		mov_tr	ax, bx
		inc	ax
		call	ConvertRowToAbsYPixel
		movdw	bottomPixel, dxax, cx

		mov	windowRelative, 0		; Table coords.
	;
	; make sure coords are clipped to table and vis bounds
	;
		mov	di, gstate
		Assert	gstate, di

		mov	al, MM_INVERT
		call	GrSetMixMode
		mov	ax, C_BLACK
		call	GrSetAreaColor

		call	TableClipCoordsToTableArea
		jc	done
	;		Assert	le ax, cx
	; FIXME: 
	; The following assert fails on selections beyond the end of
	; the screen and I don't have time to fix it right now :(
	;		Assert	le bx, dx
		
	;
	; Big Ole' hack to get selection to appear to do the right
	; thing under most circumstance for pcv.
		add	ax, 2
		add	bx, 2
		sub	cx, 2
		sub	dx, 1

		call	GrFillRect
done::
		.leave
		ret
TableInvertRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableClipCoordsToTableArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures coordinates are in table coordinates (not outside
		last row /columns) and in the visbounds (in case a row /col
		should be clipped visually)

CALLED BY:
PASS:		ss:bp		- TABLE_CLIP_COORDS_LOCALS
				    leftPixel
				    rightPixel
					left/right in table coords, which
					are equivalent to window coords.
				    topPixel
				    bottomPixel
					top/bottom are either relative to
					table or to window.  See windowRela-
					tive.
				    firstVisPixel
				    visWidth
				    visHeight
					Workspace for us.  Caller doesn't
					touch these.
				    windowRelative
					If 0, top/bottom are relative to
					the table.
					If non-zero, top/bottom are relative
					to the visible part of the table
					(its "window").

		*ds:si		- Table Component

RETURN:		ax, bx, cx, dx	- valid coords relative to *WINDOW*,
				  depending on carry flag
				- CARRY SET if none of the range
				  was valid
		ss:bp		- leftPixel, topPixel, rightPixel,
				  bottomPixel:  pixels that are both
				  visible and in the table, in TABLE
				  coordinates
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Note 1:
		If calling routine wishes to draw the selected
		cells, it should check the carry.  Possible that
		scroll occurred so no selected cells are visible.

	Note 2:
		Tables don't scroll horizontally.  This simplifies
		the range check for the passed left/right as follows:
		(comparisons in table coordinates, not screen coords)

			left >= 0
			right < min( visible area's right edge,
				     right edge of rightmost column )

		Top/bottom checking is more complicated since the
		visible window can "slide" along the table.


		 _______________________
		|			|
		|			|
		|			| The large box represents the
		|			| table, with 0,0 at the upper left.
		|===========		| The smaller box represents the
		|	    |		| visible window.  It may extend
		|	    |		| beyond the right edge of the table,
		|	    |		| and beyond the bottom edge of the
		|	    |		| table.  It must line up on the 
		|	    |		| left edge, though.
		|	    |		|
		|===========		|
		|			|
		|			|
		|			|
		|			|
		 -----------------------

		top >= first pixel showing of first visible row
		bottom <= min( last visible pixel of last visible row,
			        bottom of table )

	Note 3:
		The calling routine may pass topPixel and bottomPixel
		relative to the table or relative to the visible region
		(window) of the table.  (There's no difference between
		table/window coords as far as leftPixel and rightPixel are
		concerned.)  We look at the windowRelative variable to
		determine whether we're table relative (zero) or window
		relative (non-zero).



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/14/95    	Initial version
	jmagasin 7/17/96	- Return carry set for invalid ranges.
				- Corrected to check in table coords, not
				  screen coords.
				- Return screen coords, not table coords.
				- Inherit locals so that can more easily
				  handle dword for top/bottom pixel.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableClipCoordsToTableArea	proc	near
		class	GadgetTableClass

		TABLE_CLIP_COORDS_LOCALS
		
		uses	bp, di
		.enter inherit

		Assert	objectPtr dssi, GadgetTableClass
	;
	; If we've got no rows or columns, bail.
	;
		call	TableDerefSI_DI
		tst	ds:[di].GT_numRows
		cmc
		jz	exit
		tst	ds:[di].GT_numCols
		cmc
		jz	exit
	;
	; Figure out first visible pixel.
	;
		mov	ax, ds:[di].GT_firstVisibleRow
		call	ConvertRowToAbsYPixel		; dx.ax <- pixel
		mov_tr	cx, ax
		mov_tr	bx, dx				; bx.cx = pixel
		mov	ax, ds:[di].GT_topClipped
		clr	dx				; dx.ax = clip amt.
		adddw	bxcx, dxax
		movdw	firstVisPixel, bxcx

	;
	; If we've been passed top/bottomPixel in window coords,
	; convert them to table coords.
	;
		tst	windowRelative
		jz	startClipping
		adddw	topPixel, bxcx
		adddw	bottomPixel, bxcx

	;
	; Clip in table coordinates.
	;	Clip left at 0.
	;	Clip right at min( rightmost visible pixel in table,
	;			   rightmost pixel in window )
	;	Clip top to first visible pixel in table.
	;	Clip bottom to min( bottommost visible pixel in table,
	;			    bottommost pixel in window )
	;
startClipping:
EC <		cmpdw	topPixel, 0					>
		Assert	carryClear
EC <		cmpdw	bottomPixel, 0					>
		Assert	carryClear
		Assert	ge, leftPixel, 0
		Assert	ge, rightPixel, 0
		push	bp
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjCallInstanceNoLock
		pop	bp
		test	cx, dx				; degenerate table
		cmc					; cf<-1
		jz	exit
		mov	visWidth, cx
		mov	visHeight, dx
		
		cmp	leftPixel, 0
		jge	checkRight
		mov	leftPixel, 0
checkRight:
		cmp	rightPixel, cx
		jl	checkRightBorder
		dec	cx
		mov	rightPixel, cx
checkRightBorder:
		mov	ax, ds:[di].GT_numCols
		call	ConvertColToXPixel
		dec	ax
		cmp	rightPixel, ax
		jle	checkTop
		mov	rightPixel, ax

checkTop:
		cmpdw	firstVisPixel, topPixel, ax
		jle	checkBottomOverall
		movdw	topPixel, firstVisPixel, ax
checkBottomOverall:
		call	ComputeOverallHeightLow		; dx:bx <- height
		cmpdw	dxbx, bottomPixel, ax
		jg	checkBottomVisible
		decdw	dxbx
		movdw	bottomPixel, dxbx
checkBottomVisible:
		movdw	cxbx, firstVisPixel
		mov	ax, visHeight
		clr	dx
		adddw	cxbx, dxax			; cxbx = max possible
							; last vis pixel+1
		cmpdw	cxbx, bottomPixel
		jg	validate
		decdw	cxbx
		movdw	bottomPixel, cxbx

	;
	; Anything left to draw (still have table coords).
	;
validate:
		mov	ax, leftPixel
		mov	cx, rightPixel
	; check leftPixel against right edge
		cmp	ax, cx
		jle	checkVerticalRange
		stc					; they crossed
		jmp	exit
checkVerticalRange:
		cmpdw	bottomPixel, topPixel, bx
		jc	exit

	;
	; Finally, return screen coords.  Left/right already okay.
	;
		push	cx,ax
		movdw	cxax, firstVisPixel
		movdw	dxbx, topPixel
		subdw	dxbx, cxax			; bx has top
		Assert	e, dx, 0
		push	bx

		movdw	bxdx, bottomPixel
		subdw	bxdx, cxax			; dx has bottom
		Assert	e, bx, 0
		
		pop	bx				; bx has top
		pop	cx,ax				; ax/cx = left/right
		clc
exit:
		.leave
		ret
TableClipCoordsToTableArea	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableScrollLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scroll to the row (make it the first visible row)

CALLED BY:	Internal
PASS:		ax		- row
		*ds:si		- table component
RETURN:		ax		- row
DESTROYED:	nothing
SIDE EFFECTS:	will change GT_firstVisibleRow, GT_lastVisibleRow
		and send out events

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableScrollLow	proc	near
		class	GadgetTableClass
		uses	dx,di, bp, bx, cx
		.enter
		call	TableDerefSI_DI
	;
	; make sure its valid
	;
		cmp	ax, 0
		jge	checkAbove
		clr	ax
checkAbove:
		cmp	ax, ds:[di].GT_numRows
		jl	ok
		mov	ax, ds:[di].GT_numRows
		dec	ax
ok:
		mov	ds:[di].GT_firstVisibleRow, ax
		clr	ds:[di].GT_topClipped
		call	TableComputeLastVisibleRow
		mov	ds:[di].GT_lastVisibleRow, dx
	;
	; inform the user of the scroll
	;
		mov	di, offset tableScrolledString
		call	RaiseSimpleEvent

		mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
		call	ObjCallInstanceNoLock
		
	.leave
	ret
TableScrollLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableScrollPixelLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scroll to the pixel (make it the first visible pixel)

CALLED BY:	Internal
PASS:		dx:ax		- pixel
		*ds:si		- table component
RETURN:		ax		- pixel
DESTROYED:	nothing
SIDE EFFECTS:	will change GT_firstVisibleRow, GT_lastVisibleRow
		and send out events

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/26/95    	Initial version
	jmagasin 7/1/96		Work with longs, not ints.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableScrollPixelLow	proc	near
		class	GadgetTableClass
		uses	dx,di, bp, bx, cx
		.enter
		call	TableDerefSI_DI
	;
	; make sure its valid
	;
		cmpdw	dxax, 0
		jge	checkAbove
		clrdw	dxax
checkAbove:
		push	dx				; save hi word
		call	ComputeOverallHeightLow		; dx:bx <- height
		pop	cx				; cx:ax = passed pixel
		cmpdw	cxax, dxbx
		jl	ok
		movdw	cxax, dxbx
		decdw	cxax				; overallHeight - 1
ok:
		xchg	cx, dx				; cx:bx = overall
							; dx:ax = passed pixel
	;
	; convert the pixel to the firstVisibleRow but keep the offset
	; around
	;
		call	ConvertAbsYPixelToRow
		mov	ds:[di].GT_firstVisibleRow, ax
		mov	ds:[di].GT_topClipped, dx
		call	TableComputeLastVisibleRow
		mov	ds:[di].GT_lastVisibleRow, dx

	;
	; Infor the user we scrolled, then cause an update
		mov	di, offset tableScrolledString
		call	RaiseSimpleEvent
		mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
		call	ObjCallInstanceNoLock
		
	.leave
	ret
TableScrollPixelLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableRedrawAllVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do any redrawing that is necessary for borders and send
		updates for all affect rows.

CALLED BY:	TableScrollLow
PASS:		*ds:si		- TableComponent
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableRedrawAllVisible	proc	near
		class	GadgetTableClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		Assert	objectPtr dssi, GadgetTableClass
	;
	; If its not visible, don't redraw
	;
		mov	ax, MSG_ENT_GET_FLAGS
		call	ObjCallInstanceNoLock
		test	al, mask EF_VISIBLE
		jz	done

		call	TableDerefSI_DI
	; if not initialized yet, dont ask for it.
		cmp	ds:[di].GT_numRows, 0
		je	done

		mov	bx, ds:[di].GT_firstVisibleRow
		mov	dx, ds:[di].GT_lastVisibleRow
		mov	cx, ds:[di].GT_numCols
		jcxz	done
		dec	cx		; inclusive values
		clr	ax
		call	TableQueryCells
done:
		.leave
	ret
TableRedrawAllVisible	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableComputeLastVisibleRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines what the last visible row on the screen is.

CALLED BY:	
PASS:		
		*ds:si	- Table Component
RETURN:		dx	- last visible row
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableComputeLastVisibleRow	proc	near
		uses	ax,cx, bp
		.enter

		Assert	objectPtr dssi, GadgetTableClass
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjCallInstanceNoLock
		mov	ax, dx			; height
		call	ConvertRelYPixelToRow
		mov	dx, ax			; row
		.leave
		ret
TableComputeLastVisibleRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw ourself, our children and tell and sent legos events
		so the user can draw data in each cell.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es 	= segment of GadgetTableClass
		ax	= message #
		cl	= DrawFlags
		^hbp	= GState
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		When we get a VisDraw, when tell each cell draw.  The drawing
		of each cell will force a new VisDraw.  If this happens, don't
		draw again.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableVisDraw	method dynamic GadgetTableClass, 
					MSG_VIS_DRAW
		.enter
	;
	; Are we already in a redraw?
		mov	ax, ATTR_GADGET_TABLE_DOING_REDRAW
		call	ObjVarFindData
		jc	done

		push	cx		; DrawFlags
		clr	cx
		call	ObjVarAddData
		pop	cx		; DrawFlags
	;
	; Send a Redraw event way before the gadget gets a chance to.
	; The user shouldn't be drawing here as DrawLook will erase everything.
	; This should only be used as a place to allow the user to
	; position children.
	;
		call	RaiseTableRedrawEvent

		push	bp, cx		; gstate, DrawFlags
		mov	di, bp		; gstate

	; Lets be sure about this ...
		call	TableComputeLastVisibleRow
		mov	bx, ds:[si]
		add	bx, ds:[bx].GadgetTable_offset
		mov	ds:[bx].GT_lastVisibleRow, dx
		
	;
	; Translate all coordinates to be relative table, not window.
	;
		call	GrSaveState
;;
;; At some point we might want the table to be a window so it clips,
;; but not yet.
ifndef	TABLE_IN_WINDOW
		; needed if table not in own window
		
		mov	ax, MSG_VIS_GET_POSITION
		call	ObjCallInstanceNoLock
		mov	bx, dx		; y
		clr	ax
		mov	dx, cx		; x
		clr	cx
		call	GrApplyTranslation
endif		; needed if table not in own window
	

	; Draw our looks
		
		call	TableDrawLook

		pop	cx		; DrawFlags
		test	cl, mask DF_OBJECT_SPECIFIC
		jnz	afterCells
		

	; Send redraw events for visible cells.

		call	TableRedrawAllVisible
		call	TableDrawSelection
afterCells:
		
		call	GrRestoreState

	;
	; tell superclass to do its thing (draw children)
	;

		mov	ax, ATTR_GADGET_TABLE_DOING_REDRAW
		call	ObjVarDeleteData
		pop	bp		; gstate

done:
		mov	ax, MSG_VIS_DRAW
		mov	di, offset GadgetTableClass
		call	ObjCallSuperNoLock

		.leave
		ret
GadgetTableVisDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableDrawLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does all drawing necessary to get the right look.

CALLED BY:	GadgetTableVisDraw
PASS:		di		- gstate	(translated so 0,0 is origin
						 of table )
		cl		- DrawFlags
		*ds:si		- Table component
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/28/95    	Initial version
	jmagasin 7/18/96	Updated for new TableClipCoordsToTableArea.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableDrawLook	proc	near
		class	GadgetTableClass

		TABLE_CLIP_COORDS_LOCALS
		instData	local	nptr
		wide		local	word
		height		local	word
		ypos		local 	word
		gstate		local	word
		colArray	local	nptr
		
		uses	ax,bx,cx,dx,di,bp, si
		.enter
		Assert	objectPtr dssi, GadgetTableClass
	;
	; Draw background
	;
		call	GrSaveState
		push	bp			; frame ptr
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjCallInstanceNoLock
		pop	bp			; frame ptr
		clr	leftPixel
		clrdw	topPixel
		mov	rightPixel, cx
		clr	ax
		movdw	bottomPixel, axdx
		mov	windowRelative, -1	; Vis-window relative.
		push	cx, dx			; vis left top
		call	TableClipCoordsToTableArea 
		mov	ss:[wide], cx
		mov	ss:[height], dx
	; fill in Border area in grey
		pop	ax, bx			; vis left top
		jc	blank
		xchg	ax, cx
		xchg	bx, dx
		push	ax			; width
ifdef GREY_PATTERN_BACKGROUND
		mov	ax, C_LIGHT_GRAY
		call	GrSetAreaColor
else
		mov	ax, C_WHITE
		call	GrSetAreaColor
		clr	bx			; redraw all
endif
		
	;
	; Draw once in white to erase everything in the border
		clr	ax
		call	GrFillRect

	;horiz border
;; why was this here?
;;		clr	ax
;;		call	GrFillRect
		pop	ax			; width
	;vert border
ifdef GREY_PATTERN_BACKGROUND
		push	bx	; vert border
		clr	bx
		call	GrFillRect
		
	; Draw again to get a better look
	;
	; vert border
		push	ax
		mov	ax, SDM_TILE
		call	GrSetAreaMask
		mov	ax, C_BLACK
		call	GrSetAreaColor
		pop	ax
		
		call	GrFillRect
	; horiz border
		clr	ax
		pop	bx	; vert border
		call	GrFillRect
		

		clrdw	axbx

		push	si			; self
		mov	si, PCT_INTERSECTION
		call	GrSetClipRect
		pop	si			; self

		mov	ax, C_WHITE
		call	GrSetAreaColor

		mov	cx, ss:[wide]
		mov	dx, ss:[height]

		mov	al, SDM_100
		call	GrSetAreaMask
		
		clr	ax, bx
		call	GrFillRect

else
		clrdw	axbx
		push	si			; self
		mov	si, PCT_INTERSECTION
		call	GrSetClipRect
		pop	si			; self

endif
		clr	ax			; set to black
		call	GrSetLineColor
	;
	; set area color back to black so DrawPoint works!
		call	GrSetAreaColor

	;
	; DECIDE what to on lines based on look
	;
		Assert	objectPtr, dssi, GadgetTableClass
		mov	bx, ds:[si]
		add	bx, ds:[bx].GadgetTable_offset
	; if no rows, don't try to do anything.
		cmp	ds:[bx].GT_numRows, 0
		je	blank
		Assert	etype, ds:[bx].GI_look, GadgetTableLook
		mov	ss:[instData], bx
		mov	bl, ds:[bx].GI_look
		clr	bh
		shl	bx
		jmp	cs:[TableDrawLookJumpTable][bx]


blank:

		call	GrRestoreState

	.leave
	ret
TableDrawLookJumpTable	nptr	offset	recordList,
				offset	dottedCells,
				offset	dottedRows,
				offset  blank

		

;;---------------------------------------------------------------
;;--------------- dotted cells look -------------------------------
;;---------------------------------------------------------------

ifdef I_AM_WRITING_IN_C
{
    ypos = -topClipped;
    row = firstVisibleRow;
    while (row != lastVisibleRow) {
	cellheight = self.rowheights[row];

	
	col = 0;
	xpos = 0;
	while (col < numCols)
	{
	    
	    cellwidth = self.colwidths[col]
	    DrawDottedCell(xpos, ypos, cellwidth, cellheight);
	    col++;
	    xpos += cellwidth;
		
	}
	row++;
	ypos += cellheight;
	
    }
}
endif
		
dottedCells:
	;
	; Draw grid lines
	;

		mov	ax, LS_DOTTED
		clr	bl
		call	GrSetLineStyle

		mov	ax, C_BLACK
		call	GrSetAreaColor		; needed for drawing points

		mov	bx, ss:[instData]
		mov	ss:[gstate], di
		
		mov	si, ds:[bx].GT_rowHeights
		mov	cx, ds:[bx].GT_firstVisibleRow
		shl	cx

		Assert	chunk si, ds
		mov	si, ds:[si]
		Assert	chunkPtr si, ds
		add	si, cx			; first row
		shr	cx

		mov	di, ds:[bx].GT_columnWidths
		Assert	chunk di, ds
		mov	di, ds:[di]
		Assert	chunkPtr di, ds
		mov	ss:[colArray], di

	; start at top of first visible row, though it may get clipped.
		mov	ax, ds:[bx].GT_topClipped
		neg	ax
		mov	ss:[ypos], ax

	; cx = row
	; ds:[bx] =  instance data
	; ds:[si] =  array of rows, current row.
;; while (row < lastVisibleRow)
		mov	di, ss:[gstate]
		cmp	cx, ds:[bx].GT_lastVisibleRow
		jg	blank

	;
	; FIXME: perhaps it would be better to use the lodsw in the
	; inner loop and grab the array from the stack in the outer
	; loop, but it is a minor speed thing.
		
whileRowLoop:
		cmp	cx, ds:[bx].GT_lastVisibleRow
		jg	drawLastRow
		push	cx		; row 

		lodsw
	; 		ax		; cellheight
		clr	cx		; col
		clr	bx		; xpos

whileColLoop:
		mov	di, ss:[instData]
		cmp	cx, ds:[di].GT_numCols
		jge	finishRowLoop
		mov	di, ss:[colArray]
		add	di, cx
		add	di, cx			; point into array of words.
		mov	dx, ds:[di]		; cell width
		push	cx			; loop counter
		mov	cx, ss:[ypos]
	; xpos = bx, ypos = cx, cellwidth = dx, cellheight = ax
		mov	di, ss:[gstate]
		call	DrawDottedCell		; 
		pop	cx			; loop counter
		inc	cx			; col++
		add	bx, dx			; xpos += cellwidth
		jmp	whileColLoop
finishRowLoop:
		pop	cx			; row
		inc	cx
		add	ss:[ypos], ax		; ypos += cellheight
		mov	bx, ss:[instData]
		jmp	whileRowLoop
		

drawLastRow:
		mov	di, ss:[gstate]
		jmp	blank
		
;;---------------------------------------------------------------
;;--------------- record list look -------------------------------
;;---------------------------------------------------------------

recordList:
	;
	; Draw grid lines
	;

		mov	bx, ss:[instData]
		mov	si, ds:[bx].GT_rowHeights
		mov	cx, ds:[bx].GT_firstVisibleRow
EC <		mov	dx, si						>
		shl	cx		; change to byte offset in array
		Assert	chunk si, ds
		mov	si, ds:[si]
		Assert	chunkPtr si, ds
		add	si, cx		; points at first visible row
		mov	cx, ds:[bx].GT_lastVisibleRow
		sub	cx, ds:[bx].GT_firstVisibleRow
		inc	cx

		jcxz	blank
	; start at top of first visible row, though it may get clipped.
		mov	bx, ds:[bx].GT_topClipped
		neg	bx
	; ds:si, ptr to row to start drawing from.

drawRowLine:
		Assert	inChunk si, dx, ds
		push	cx			; loop counter
	; draw top border
		mov	ax, 2
		mov	cx, ss:[wide]
		sub	cx, ax
		call	GrDrawHLine

	; Now draw corner for this row
		inc	bx
		mov	ax, 1
		call	GrDrawPoint
		mov	ax, ss:[wide]
		dec	ax
		call	GrDrawPoint
		inc	bx
	; draw side borders
		lodsw				; height of row
		push	ax			; row height
		mov	dx, bx
		add	dx, ax
		sub	dx, 4
		clr	ax
		call	GrDrawVLine
		mov	ax, ss:[wide]
		call	GrDrawVLine
		sub	bx, 2
		pop	ax			; row height
		add	bx, ax
		
	; draw the corner pixels on the bottom
		mov	ax, 1
		dec	bx
		call	GrDrawPoint
		mov	ax, ss:[wide]
		dec	ax
		call	GrDrawPoint
		inc	bx
	; point at current row again

		pop	cx			; loop counter
		loop	drawRowLine
rowsDrawn::
	; now draw the bottom row
		mov	ax, 2
		mov	cx, ss:[wide]
		sub	cx, ax
		mov	bx, dx			; height
		add	bx, ax
		call	GrDrawHLine
		jmp	blank
;;---------------------------------------------------------------
;;--------------- dotted row look -------------------------------
;;---------------------------------------------------------------

dottedRows:
	;
	; Draw grid lines
		mov	bx, ss:[instData]
	;
	; If there are no lines to draw, don't draw any.
		cmp	ds:[bx].GT_numRows, 1
		jle	blank
	;
	; FIXME: this next section is copied from above and a common
	; routine can probably be called to save space.
		mov	si, ds:[bx].GT_rowHeights
		mov	cx, ds:[bx].GT_firstVisibleRow
EC <		mov	dx, si						>
		shl	cx		; change to byte offset in array
		Assert	chunk si, ds
		mov	si, ds:[si]
		Assert	chunkPtr si, ds
		add	si, cx		; points at first visible row
		mov	cx, ds:[bx].GT_lastVisibleRow
		sub	cx, ds:[bx].GT_firstVisibleRow
		inc	cx

		jcxz	blank
	; The lines need to be dotted.
		push	bx			; inst data
		mov	ax, LS_DOTTED
		clr	bl
		call	GrSetLineStyle
		pop	bx			; inst data
	; start at top of first visible row, though it may get clipped.
		mov	bx, ds:[bx].GT_topClipped
		neg	bx
	; ds:si, ptr to row to start drawing from.
		dec	cx			; don't draw bottom line


drawDottedLine:
		Assert	inChunk si, dx, ds
		push	cx			; loop counter

	; draw horizontal line
		lodsw				; height of row

		add	bx, ax
		clr	ax
		mov	cx, ss:[wide]
		call	GrDrawHLine

		pop	cx			; loop counter
		loop	drawDottedLine
		jmp	blank


;;---------------------------------------------------------------
;;--------------- 	grid look -------------------------------
;;---------------------------------------------------------------
		
ifdef MOTIF_COMPONENT_SET
if 0	; if 0'd for color stuff
		
gridLines:
	;
	; Draw grid lines
	;

		mov	bx, ss:[instData]
		mov	si, ds:[bx].GT_rowHeights
		mov	cx, ds:[bx].GT_firstVisibleRow
EC <		mov	dx, si						>
		shl	cx		; change to byte offset in array
		Assert	chunk si, ds
		mov	si, ds:[si]
		Assert	chunkPtr si, ds
		add	si, cx		; points at first visible row
		mov	cx, ds:[bx].GT_lastVisibleRow
		sub	cx, ds:[bx].GT_firstVisibleRow
		inc	cx

		jcxz	rowsDrawn
	; start at top of first visible row, though it may get clipped.
		mov	bx, ds:[bx].GT_topClipped
		neg	bx
	; ds:si, ptr to row to start drawing from.

drawRowLine:
		Assert	inChunk si, dx, ds
		push	cx			; loop counter
		lodsw
		add	bx, ax
		clr	ax
		mov	cx, ss:[wide]
		call	GrDrawHLine
		pop	cx
		loop	drawRowLine
rowsDrawn:

	; Draw Columns

		mov	bx, ss:[instData]
		mov	si, ds:[bx].GT_columnWidths
		mov	cx, ds:[bx].GT_numCols
		mov	dx, ss:[height]
		jcxz	linesDrawn

		Assert	chunk si, ds
		mov	si, ds:[si]
		Assert	chunkPtr	si, ds

		clr	bx
		push	bp		; frame
	; start a line before because of Geos imaging model
	; no need to worry about GT_topClipped here.
		mov	bp, -1
drawColLine:
		Assert	e bx, 0
		lodsw
		add	bp, ax
		mov	ax, bp
		
		call	GrDrawVLine
		loop	drawColLine
		pop	bp		; frame
linesDrawn:
endif	; 0
endif	; MOTIF_COMPONENT_SET


TableDrawLook	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDottedCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Helper routine for drawing looks.  Draws a dotted cell.
		It draws the top, left and right sides, not the bottom.

CALLED BY:	TableDrawLook
PASS:		ax		; cellHeight
		bx		; xpos
		cx		; ypos
		dx		; cellwidth
		di		; gstate
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	2/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDottedCell	proc	near
	uses	ax,bx,cx,dx,si,di,bp
		.enter
		sub	dx, 3			; leave space between cells.
		xchg	ax, bx			; ax <- xpos
		xchg	bx, cx			; bx <- ypos, cx <- cellHeight
		xchg	cx, dx			; cx <- width, dx <- height
		add	cx, ax			; cx <- xEnd
		add	dx, bx

		mov	si, 2
		call	GrDrawRoundRect
if 0		
		add	ax, 2
		sub	cx, 2			; leave a corner
	
	; draw top line
		call	GrDrawHLine
		dec	ax
		inc	bx
		call	GrDrawPoint		; Top left
		
	; draw bottom line
		add	bx, dx
		dec	bx
		call	GrDrawPoint		; bottom left
		inc	bx
		inc	ax
		call	GrDrawHLine

		sub	bx, dx
		sub	ax, 2
		
	; draw  left line
		add	dx, bx
		sub	dx, 2
		add	bx, 2
		call	GrDrawVLine
	; draw right line
		xchg	ax, cx
		add	ax, 4
		call	GrDrawVLine
endif
		
		.leave
		ret
DrawDottedCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableQueryCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends an event for cell in the range.
		Doesn't check or change the visiblity of anything

CALLED BY:
PASS:		ax, bx		- left, top [inclusive]
		cx, dx		- right, bottom	[inclusive]
		*ds:si		- Table Component
		
		Its assumed the values are valid
RETURN:		nada
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableQueryCells	proc	near
		left	local	word	push	ax
		
		.enter
		Assert	objectPtr dssi, GadgetTableClass

rowLoop:
		cmp	bx, dx			; top < bottom?
		jg	done
		mov	ax, ss:[left]

colLoop:
		cmp	ax, cx			; left < right
		jle	doCall
		inc	bx		; advance to next row
		jmp	rowLoop
doCall:
	; do the call here
	; bx = row
	; ax = col
		call	RaiseRedrawEvent
		inc	ax
		jmp	colLoop
done:		

		.leave
		ret
TableQueryCells	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RaiseRedrawEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a basic event so the user can draw a cell

CALLED BY:	INTERNAL
PASS:		bx	- row	, TYPE_INTEGER
		ax	- col   , TYPE_INTEGER
		*ds:si	- Table Component
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
tableRedrawString TCHAR "drawCell", 0

RaiseRedrawEvent	proc	near
 		params		local	EntHandleEventStruct
		result		local	ComponentData
		ForceRef	result
		uses	ax, cx, dx, bp, si, di, bp
		.enter
		Assert	objectPtr dssi, GadgetTableClass

		push	ax
		mov	ax, bx
		call	ConvertRowToYPixel
		mov	dx, ax
		pop	ax

		push	ax
		call	ConvertColToXPixel
		mov	cx, ax
		pop	ax

		mov	di, offset tableRedrawString
		movdw	ss:[params].EHES_eventID.EID_eventName, csdi
		lea	di, result
		movdw	ss:[params].EHES_result, ssdi
		mov	ss:[params].EHES_argc, 4
		mov	ss:[params].EHES_argv[0].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[0].CD_data.LD_integer, bx

		mov	ss:[params].EHES_argv[size ComponentData].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[size ComponentData].CD_data.LD_integer, ax

		mov	ss:[params].EHES_argv[2*(size ComponentData)].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[2*(size ComponentData)].CD_data.LD_integer, cx

		mov	ss:[params].EHES_argv[3*(size ComponentData)].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[3*(size ComponentData)].CD_data.LD_integer, dx
		
		lea	dx, ss:[params]
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock

		.leave
	ret
RaiseRedrawEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RaiseSimpleEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a basic event so the user can draw a cell

CALLED BY:	INTERNAL
PASS:		*ds:si	- Table Component
		cs:di	- event name
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
tableChangedString TCHAR "selectionChanged", 0
tableScrolledString TCHAR "scrolled", 0
tableHeightChangedString TCHAR "overallHeightChanged", 0

RaiseSimpleEvent	proc	near
 		params		local	EntHandleEventStruct
		result		local	ComponentData
		ForceRef	result
		uses	ax, cx, dx, bp, si, di, bp
		.enter
		Assert	objectPtr dssi, GadgetTableClass

		movdw	ss:[params].EHES_eventID.EID_eventName, csdi
		lea	di, result
		movdw	ss:[params].EHES_result, ssdi
		mov	ss:[params].EHES_argc, 0
		lea	dx, ss:[params]
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock

		.leave
		ret
RaiseSimpleEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RaiseTableRedrawEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a basic event so the user can draw a cell

CALLED BY:	INTERNAL
PASS:		*ds:si	- Table Component
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		FIXME, merge with RaiseChangedEvent, save some code space!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
tableRedrawString2 TCHAR "aboutToDraw", 0

RaiseTableRedrawEvent	proc	near
 		params		local	EntHandleEventStruct
		result		local	ComponentData
		ForceRef	result
		uses	ax, cx, dx, bp, si, di, bp
		.enter
		Assert	objectPtr dssi, GadgetTableClass

		mov	di, offset tableRedrawString2
		movdw	ss:[params].EHES_eventID.EID_eventName, csdi
		lea	di, result
		movdw	ss:[params].EHES_result, ssdi
		mov	ss:[params].EHES_argc, 0
		lea	dx, ss:[params]
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock

		.leave
		ret
RaiseTableRedrawEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertRowToYPixel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the Y Pixel to correspond to a given row.
		(top pixel in row)

CALLED BY:	
PASS:		ax	- row
		*ds:si	- TableComponent
RETURN:		ax	- y pixel: 0 if row is completely above visible
			  range, sum of all visible rows if passed
			  row is below visible range.
			  Negative number if row is partially visible, but
			  clipped.  (Magnitude of ax will equal the number
			  of clipped pixels.)
			  CF set if not in visible range at all
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		YPixel = visible row heights until row = passed row

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertRowToYPixel	proc	near
		class	GadgetTableClass
		uses	dx,bx,cx,si,di
		.enter
EC <		call	ECTableCheckLegalRow				>
		Assert	objectPtr dssi, GadgetTableClass
		mov	bx, ax


		mov	dx, 0

		call	TableDerefSI_DI
		mov	ax, ds:[di].GT_firstVisibleRow
		mov	cx, ds:[di].GT_lastVisibleRow
		cmp	bx, cx		; after end?
		jle	checkNext
		dec	dx
checkNext:
		cmp	bx, ax		; before beginning?
		jge	okay
		dec	dx
		push	dx
		clr	dx
		jmp	done
okay:
		push	dx		; flag for valid
		mov	dx, ds:[di].GT_topClipped
		neg	dx
	;
	; cycle through the array of row heights
	;
		mov	cx, bx
		sub	cx, ax			; cx <- num visible rows\
						; before desired row

		mov	di, ds:[di].GT_rowHeights
		mov	si, ds:[di]		; ptr to first element
		shl	ax			; change to byte offset
		add	si, ax			; ptr to first visible element
		jcxz	done
tally:
		Assert	inChunk	si, di, ds
		lodsw
		add	dx, ax
		loop	tally

done:
		mov	ax, dx
		pop	dx
		add	dx, 1		; sets carry if was -1
		
	.leave
	ret
ConvertRowToYPixel	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertRowToYPixelCarry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find they pixel correspoding to the start of a
		specified row.

CALLED BY:	
PASS:		ax	- row whose starting y pos is desired
RETURN:		ax	- y position of start of passed row,
			  or -32768 if row is not visible
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This routine depends on convertRowToPixel calculating
		the sum of all rows if passed numRows (as opposed to
		just returning "error, invalid row."
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	?/?/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertRowToYPixelCarry	proc	near
	uses	di, dx, cx
	class	GadgetTableClass
	.enter

	mov	cx, ax
	call	ConvertRowToYPixel		; ax <- y
	jnc	done

	;
	; If we asked for the y pos of the numRows'th row and
	; lastVisibleRow = numRows-1,  then we've got a valid
	; value in ax.
	;
	call	TableDerefSI_DI
	mov	dx, ds:[di].GT_lastVisibleRow
	inc	dx
	cmp	dx, ds:[di].GT_numRows		; Is lastVisibleRow =
	jne	nonVisRow			;    numRows - 1?
	cmp	cx, dx				; Wanted numRows'th row?
	jne	nonVisRow
		
done:
	.leave
	ret

nonVisRow:
	mov	ax, -32768
	jmp	done
ConvertRowToYPixelCarry endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertRowToYAbsPixel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the Y Pixel to correspond to a given row.
		(top pixel in row)

CALLED BY:	
PASS:		ax	- row
		*ds:si	- TableComponent
RETURN:		dx.ax	- y pixel
		cx	- size of row
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		YPixel = visible row heights until row = passed row

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertRowToAbsYPixel	proc	near
		class	GadgetTableClass
		uses	bx,si,di, bp
		.enter
EC <		call	ECTableCheckLegalRow				>
		Assert	objectPtr dssi, GadgetTableClass

		clrdw	dxbx		

		call	TableDerefSI_DI

	; Are before beginning or past the end?
		clr	cx			; return 0 for size of row
		cmp	ax, 0
		jle	done

		clr	bp			; not on last row, bp =0
		mov	cx, ds:[di].GT_numRows
		cmp	ax, cx
		jl	compute
		mov	bp, 1			; on last row, bp =1
		mov	ax, cx
	; just return the overallHeight
compute:  
		
	;
	; cycle through the array of row heights
	;
		mov	cx, ax
		mov	di, ds:[di].GT_rowHeights
		mov	si, ds:[di]		; ptr to first element
		jcxz	done
tally:
		Assert	inChunk	si, di, ds
		lodsw
		add	bx, ax
		adc	dx, 0
		loop	tally
	; save the size of this row
		mov	cx, ax		; size of last row
		cmp	bp, 0
		je	done
		lodsw
		mov	cx, ax		; size of desired row

done:
		mov	ax, bx		; dx.ax = result

		
	.leave
	ret
ConvertRowToAbsYPixel	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertColToXPixel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the X Pixel to correspond to a given col.

CALLED BY:	
PASS:		ax	- col
		*ds:si	- TableComponent
RETURN:		ax	- x pixel: 0 if column is to left of visible
			  range, sum of all visible columns if passed
			  column is to right of visible range.
			  highest col is
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		YPixel = visible row heights until row = passed row

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertColToXPixel	proc	near
		class	GadgetTableClass
	uses	cx,bx,dx,si,di
		.enter

EC <		call	ECTableCheckLegalColumn				>

		Assert	objectPtr dssi, GadgetTableClass
		clr	dx		
		call	TableDerefSI_DI
		mov	cx, ds:[di].GT_numCols
		cmp	ax, cx
		jle	checkBefore
		mov	ax, cx
checkBefore:
		cmp	ax, 0
		jge	okay
		clr	ax
okay:
	;
	; cycle through the array of col widths
	;
		mov	cx, ax			; cx <- num visible cols\
						; before desired col

		
		mov	si, ds:[di].GT_columnWidths
EC <		mov	bx, si						>
		mov	si, ds:[si]		; ptr to first element
		Assert	chunkPtr si, ds

	; ds:si <- ptr to first visible column
		jcxz	done
tally:
		Assert	inChunk	si, bx, ds
		lodsw
		add	dx, ax
		loop	tally

done:
		mov	ax, dx			; width
		
	.leave
	ret
ConvertColToXPixel	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertColToXPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wrapper for ConvertColToXPixel -- returns -32768
		instead of 0 if specified column is not visible.

CALLED BY:	GadgetTableActionScroll( GET_X_POS_AT )
PASS:		ax	- col
		*ds:si	- TableComponent
RETURN:		ax	- x pixel, -32768 if not in visible range
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 7/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertColToXPos	proc	near
		class	GadgetTableClass
		.enter
	;
	; Check desired column.
	;
		tst	ax
		jl	badCol
		push	di
		call	TableDerefSI_DI
		cmp	ax, ds:[di].GT_numCols
		pop	di
		jge	badCol
	;
	; Alright, it's legitimate.
	;
		call	ConvertColToXPixel
done:
		.leave
		ret
badCol:
		mov	ax, -32768		
		jmp	done
ConvertColToXPos	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertRelYPixelToRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the absolute row that the y coordinate falls in.
		Y is considered to be relative to the window bounds not
		document bounds.  NOTE!!  This routine may return a
		non-visible row that falls below the bottom of the
		table's visual bounds.*

CALLED BY:	Internal
PASS:		ax		- y coord
		*ds:si		- Table Component
RETURN:		ax		- absolute row or -1 if not visible.
DESTROYED:	nothing
SIDE EFFECTS:
		*This is useful to TableComputeLastVisibleRow which
		 needs only to skip upper non-visible rows.

PSEUDO CODE/STRATEGY:
		Starting from the first visible row add the row heights
		until we reach the y coord the subtract a row.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertRelYPixelToRow	proc	near
		class	GadgetTableClass
	uses	bx,cx,dx,si,di,bp
	.enter
		call	TableDerefSI_DI

	; skip the non-visible rows
		mov	si, ds:[di].GT_rowHeights
		mov	bp, si			; chunk of array
		mov	si, ds:[si]		;ds:[si] first element of array
		mov	bx, ds:[di].GT_firstVisibleRow
		shl	bx			; byte to word
		add	si, bx
		mov	bx, ds:[di].GT_numRows
		sub	bx, ds:[di].GT_firstVisibleRow
	; make it relative to the top of the first visible row, not
	; relative to the top of the window.
		mov	cx, ds:[di].GT_topClipped
		neg	cx			; start relative to first row

		cwd				; dx:ax = pixel
		
		call	ConvertPixelCommon
	; add the non-visilble rows back in to the count.
		add	ax, ds:[di].GT_firstVisibleRow
	.leave
	ret
ConvertRelYPixelToRow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertRelYPixelToRowAndClip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just like ConvertRelYPixelToRow, but will not
		return a row greater that GT_lastVisibleRow.

CALLED BY:
PASS:		ax		- y coord
		*ds:si		- Table Component
RETURN:		ax		- absolute row or -1 if not visible.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 7/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertRelYPixelToRowAndClip	proc	near
.warn -private
	uses	di
	.enter

		call	ConvertRelYPixelToRow
		call	TableDerefSI_DI
		cmp	ax, ds:[di].GT_lastVisibleRow
		jle	done
		mov	ax, ds:[di].GT_lastVisibleRow
done:
	.leave
	ret
.warn @private
ConvertRelYPixelToRowAndClip	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertAbsYPixelToRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the absolute row that the y coordinate falls in.
		Y is considered to be relative to the document bounds not
		window bounds.

CALLED BY:	Internal (TableScrollPixelRow)
PASS:		dx:ax		- y coord
		*ds:si		- Table Component
RETURN:		ax		- absolute row or -1 if not visible.
		dx		- amount chopped of first row.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Starting from the first visible row add the row heights
		until we reach the y coord the subtract a row.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertAbsYPixelToRow	proc	near
		class	GadgetTableClass
	uses	bx,cx,si,di,bp
	.enter
		call	TableDerefSI_DI

		mov	si, ds:[di].GT_rowHeights
		mov	bp, si			; chunk of array
		mov	si, ds:[si]		;ds:[si] first element of array
		mov	bx, ds:[di].GT_numRows

		clr	cx			; start from 0
		call	ConvertPixelCommon
	; add the non-visilble rows back in to the count.
	.leave
	ret
ConvertAbsYPixelToRow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertPixelCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	counts the number of elements in the array until the sum
		of the values is greater than something passed in.

CALLED BY:	
PASS:		^fds:si		- element of array to start searching from
		dx:ax		- size to compare against
		bx		- max number of array elements to check
		bp		- chunk of array
				  Hmmm... EC only seems to care about bp
		cx		- starting tally (often -GT_topClipped)
				- not allowed to be less than neg(height of
				  first element in array)
RETURN:		ax		- one less than the number of array
				  elements summed up, or -1 if
				  passed bx=0
		dx		- amount of top row chopped (if passed
				  bx > 0)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/26/95    	Initial version
	jmagasin 7/1/96		Modified to handle dword pixel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertPixelCommon	proc	near
	uses	bx, cx, si, bp

		push	di
EC <		mov	di, bp		;chunk of array for assert	>
maxEltsToCheck	local	word		push	bx
maxPixel	local	dword		push	dx, ax
	.enter

		mov_tr	ax, cx
		cwd			     
		mov_tr	cx, ax		     ; dx:cx = pixel running total
		
		clr	bx		     ; element running total
		tst	ss:[maxEltsToCheck]  ; 0 rows?
		jle	done

	; ds:si = fptr to first visible element in array
	; dx:cx = tally

tally:
		Assert	inChunk		si, di, ds
		lodsw
		add	cx, ax
		adc	dx, 0		     ; Update dx:cx, total height.
		
		inc	bx		     ; Update row number.
		
		cmpdw	dxcx, ss:[maxPixel]
		jg	done		     ; signed comparsion
		cmp	ss:[maxEltsToCheck], bx
		je	done
		jmp	tally
done:
	; amount chopped in this row =
	;  current_rowHeight - (totalHeight - desired pixel)
		subdw	dxcx, ss:[maxPixel]
		sub	ax, cx
		mov	dx, ax		; amount of top row chopped
		
		dec	bx		; we passed it.
		mov	ax, bx		; array element: row /col

		.leave
		pop	di
		ret
ConvertPixelCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertXPixelToCol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the absolute col that the x coordinate falls in.

CALLED BY:	Internal
PASS:		ax		- x coord
		*ds:si		- Table Component
RETURN:		ax		- absolute row or -1 if not visible.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertXPixelToCol	proc	near
		class	GadgetTableClass
	uses	bx,cx,dx,si,di,bp
	.enter
		call	TableDerefSI_DI
		
		mov	si, ds:[di].GT_columnWidths
		mov	bp, si			; chunk of array
		mov	si, ds:[si]		;ds:[si] first element of array
		mov	bx, ds:[di].GT_numCols

		clr	cx			; start search from 0
		cwd				; dx:ax = pixel
		call	ConvertPixelCommon
	.leave
	ret
ConvertXPixelToCol	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableGetDefaultRowHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_TABLE_GET_DEFAULT_ROW_HEIGHT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/29/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableGetDefaultRowHeight	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_GET_DEFAULT_ROW_HEIGHT
		uses	bp
		.enter
		mov	dx, ds:[di].GT_defaultRowHeight
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_data.LD_integer, dx
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTableGetDefaultRowHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetDefaultRowHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_TABLE_SET_DEFAULT_ROW_HEIGHT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/29/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetDefaultRowHeight	method dynamic GadgetTableClass, 
				MSG_GADGET_TABLE_SET_DEFAULT_ROW_HEIGHT
		uses	bp
		.enter
		mov	si, di			; instance data
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	dx, es:[di].CD_data.LD_integer
		mov	ds:[si].GT_defaultRowHeight, dx

		.leave
		Destroy	ax, cx, dx
		ret
GadgetTableSetDefaultRowHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableGetFirstVisibleRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_TABLE_GET_FIRST_VISIBLE_ROW
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If numRows or numColumns is 0, then first/lastVisibleRow
		should be -1.  But it's simpler to check for this case
		here rather than to update first/lastVisibleRow each time
		numRows/numColumns becomes zero/non-zero. -jmagasin

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 5/95   	Initial version
	jmagasin 7/9/96		Handle case where numRows or numColumns is 0.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableGetFirstVisibleRow	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_GET_FIRST_VISIBLE_ROW,
					MSG_GADGET_TABLE_GET_LAST_VISIBLE_ROW
		uses	bp
		.enter

		call	TableCheckIfNoRowsOrNoColumns
		mov	dx, -1
		jz	haveReturnVal
		
		mov	dx, ds:[di].GT_firstVisibleRow
		cmp	ax, MSG_GADGET_TABLE_GET_FIRST_VISIBLE_ROW
		je	haveReturnVal
		Assert	e, ax, MSG_GADGET_TABLE_GET_LAST_VISIBLE_ROW
		mov	dx, ds:[di].GT_lastVisibleRow
haveReturnVal:
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, dx
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTableGetFirstVisibleRow	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableCheckIfNoRowsOrNoColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If numRows or numColumns is 0, then return the zf set.

CALLED BY:	
PASS:		ds:di	- instance data of GadgetTable object
RETURN:		zf	- set if numRows or numColumns is 0,
			  otherwise clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 7/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableCheckIfNoRowsOrNoColumns	proc	near
		.enter
.warn -private
		Assert	ValidTableInstanceData
		tst	ds:[di].GT_numRows
		jz	done
		tst	ds:[di].GT_numCols
done:
.warn @private
		.leave
		ret
TableCheckIfNoRowsOrNoColumns	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetFirstVisibleRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_TABLE_SET_FIRST_VISIBLE_ROW
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetFirstVisibleRow	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SET_FIRST_VISIBLE_ROW
		.enter
		les	di, ss:[bp].SPA_compDataPtr
		mov	ax, es:[di].CD_data.LD_integer
		call	TableScrollLow
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTableSetFirstVisibleRow	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetLastVisibleRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_TABLE_SET_LAST_VISIBLE_ROW
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Make sure the bottom of the row appears at the bottom of
		the visible window.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/15/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetLastVisibleRow	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SET_LAST_VISIBLE_ROW
		.enter
		les	bx, ss:[bp].SPA_compDataPtr
		Assert	fptr, esbx
		mov	ax, es:[bx].CD_data.LD_integer
		cmp	ax, 0
		jge	checkAbove
		clr	ax
checkAbove:
		mov	dx, ds:[di].GT_numRows
		cmp	ax, dx
		jl	okToSet
		mov_tr	ax, dx
		dec	ax
okToSet:
		call	SetLastVisibleRowLow
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTableSetLastVisibleRow	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetLastVisibleRowLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the last visible row to show up on the bottom of
		the window.  

CALLED BY:	GadgetTableSetLastVisibleRow
PASS:		ax	- row to make appear at bottom
RETURN:		
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetLastVisibleRowLow	proc	near

		uses	bp
		.enter
	; Get the pixel of the following row.
		inc	ax
		call	ConvertRowToAbsYPixel
		pushdw	dxax			; y pixel
	; scroll so the next row is below the bottom.
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjCallInstanceNoLock
		mov	bx, dx			; height of table
		popdw	dxax
	; We will want to make sure the entire row is visible on
	; the bottom and we need to adjust by a pixel.
	; this seems like the best spot.
	; (if you don't do this, setting last visible row is usually
	; off by one)
		inc	bx			
	; subtract size of table
		sub	ax, bx
		sbb	dx, 0

	; if < 0, then make 0.
		tstdw	dxax
		jgedw	dxax, 0, foundPos

		clrdw	dxax

foundPos:
		call	TableScrollPixelLow
		
		
		.leave
		ret
SetLastVisibleRowLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableMetaStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle mouse clicks for the object.

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es 	= segment of GadgetTableClass
		ax	= message #
		bp	= ButtonInfo
RETURN:		cx:dx	= PointerImage if needed
DESTROYED:	cx, dx, bp, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If custom selection, let the user get the Pen event
		defined on gadget by passing up to superclass.
		Else select what they want.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetTableMetaStartSelect	method dynamic GadgetTableClass, 
					MSG_META_START_SELECT

		.enter
	;
	; If there is a child, send the message on to it.
	;
		push	ds:[LMBH_handle]
		push	cx, dx, bp		; args for superclass
		call	VisCallChildUnderPoint
		jc	popDone
		pop	cx, dx, bp		; args for superclass
		pop	bx
		call	MemDerefDS
		Assert	objectPtr, dssi, GadgetTableClass
		call	TableDerefSI_DI
	;
	; If the user wants to deal with it, let him by letting
	; the super class send him a Pen event
		cmp	ds:[di].GT_selectionType, GTST_SELECT_CUSTOM
		je	callSuper
		cmp	ds:[di].GT_selectionType, GTST_SELECT_NONE
		je	callSuper
	;
	; Unselect the old selection
	;

		call	TableCreateTranslatedGState
		call	TableDrawSelection
		mov	bp, di				; gstate

		call	ConvertMouseCoordsToCell
		jz	redrawDone

		Assert	objectPtr, dssi, GadgetTableClass
		call	TableDerefSI_DI
		
		mov	bx, ds:[di].GT_selectionType
		Assert	etype, bx, GadgetTableSelectionType
		Assert	ne, bx, GTST_SELECT_CUSTOM
		Assert	ne, bx, GTST_SELECT_NONE
		shl	bx
		jmp	cs:[TableSelectJumpTable][bx]
	; cx = col, dx = row, ds:di= instance Data

	;
	; FIXME: We probably should allow deselection
	;
selectCell:
		mov	ds:[di].GT_leftSelection, cx
		mov	ds:[di].GT_rightSelection, cx
		mov	ds:[di].GT_topSelection, dx
		mov	ds:[di].GT_bottomSelection, dx
		mov	ds:[di].GT_dragSelectStart.TC_row, dx
		mov	ds:[di].GT_dragSelectEnd.TC_row, dx
		mov	ds:[di].GT_dragSelectStart.TC_col,cx
		mov	ds:[di].GT_dragSelectEnd.TC_col, cx
		jmp	redraw
selectRow:
		mov	ax, ds:[di].GT_numCols
		dec	ax
		mov	ds:[di].GT_leftSelection, \
			GADGET_TABLE_SELECT_WHOLE_LINE
		mov	ds:[di].GT_rightSelection, ax
		mov	ds:[di].GT_topSelection, dx
		mov	ds:[di].GT_bottomSelection, dx
		mov	ds:[di].GT_dragSelectStart.TC_row, dx
		mov	ds:[di].GT_dragSelectEnd.TC_row, dx
		mov	ds:[di].GT_dragSelectStart.TC_col, \
			GADGET_TABLE_SELECT_WHOLE_LINE
		mov	ds:[di].GT_dragSelectEnd.TC_col, ax
		mov_tr	cx, ax				; right col
		clr	ax				; left col
		mov	bx, dx				; row
		jmp	invertRange
selectCol:
		mov	ax, ds:[di].GT_numRows
		dec	ax
		mov	ds:[di].GT_topSelection, GADGET_TABLE_SELECT_WHOLE_LINE
		mov	ds:[di].GT_bottomSelection, ax
		mov	ds:[di].GT_leftSelection, cx
		mov	ds:[di].GT_rightSelection, cx
		mov	ds:[di].GT_dragSelectStart.TC_row, \
			GADGET_TABLE_SELECT_WHOLE_LINE
		mov	ds:[di].GT_dragSelectEnd.TC_row, ax
		mov	ds:[di].GT_dragSelectStart.TC_col, cx
		mov	ds:[di].GT_dragSelectEnd.TC_col, cx
		mov_tr	dx, ax				; bottom row
		clr	bx				; top row
		mov	ax, cx				; column
		jmp	redraw
selectRange:
	;
	; store the first cell for later use
	;
		mov	ds:[di].GT_dragSelectStart.TC_row, dx
		mov	ds:[di].GT_dragSelectStart.TC_col, cx
		mov	ds:[di].GT_dragSelectEnd.TC_row, dx
		mov	ds:[di].GT_dragSelectEnd.TC_col, cx
		mov	ax, cx
		mov	bx, dx
	; Draw the new selection range using cool routine
		
invertRange:
	; ax, cx 	left, right
	; bx, dx	top, bottom

		Assert	gstate, bp
		mov	di, bp
		call	TableInvertRange
		jmp	redrawDone
		
callSuper:
		mov	ax, MSG_META_START_SELECT
		mov	di, offset GadgetTableClass
		call	ObjCallSuperNoLock
exit:
		.leave
		ret
popDone:
	;
	; Fixup the stack for four pushes, but don't trash cx, dx
	; as they may be pointer image fptr.
	;
		add	sp, 4 * size word
		jmp	exit

redraw:
		Assert	gstate, bp
		mov	di, bp			; gstate
		call	TableDrawSelection
redrawDone:
	;
	; Grab the mouse.  Have the GadgetGadgetClass routine do the
	; grab because it will set our flags.  Note that if we neglect
	; setting GGF_HAS_MOUSE_GRAB and the table's window gets nuked
	; before the table releases the mouse, the app object could
	; crash if it thinks the active mouse grab window is still around.
	; Ask Jonathan for details. -jmagasin 8/16/96
	;
	; Note that it would be better style for GadgetGadget to
	; provide a message for grabbing the mouse.  But replacing all
	; the GadgetGadget grabs with a message would slow everything down
	; just for this one case.
	;
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGadget_offset
		call	GadgetGadgetGrabMouse		; OOP faux paus:
							; touches inst data

		mov	di, bp				; gstate
		mov	ax, mask MRF_PROCESSED
		call 	GrRestoreState
		call	GrDestroyState

		jmp	exit

TableSelectJumpTable	nptr	0,	;		- not selectable
				offset	selectCell,
				offset	selectRow,
				offset	selectCol,
				offset	selectRange
		
GadgetTableMetaStartSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableMetaPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add the current cell the mouse is over the drag-select
		boundary.

CALLED BY:	MSG_META_PTR
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es 	= segment of GadgetTableClass
		ax	= message #
		bp high	UIFunctionsActive
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The current cell and the first cell clicked in create the
		bounding rectangle for the selection.

		Don't set instance data for the bounding rectangle yet,
		just draw the selection.

		Set the instance data / property on the end_select.

		This will flicker because we delselect and reselect everything
		rather than only select or deselect the new range.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/ 5/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableMetaPtr	method dynamic GadgetTableClass, 
					MSG_META_PTR
		.enter

	; Make sure we are drag selecting, otherwise pass on to superclass
	;
		cmp	ds:[di].GT_selectionType, GTST_SELECT_CUSTOM
		je	callsuper
		cmp	ds:[di].GT_selectionType, GTST_SELECT_NONE
		je	callsuper

checkSelect::

		mov	bx, bp
		test	bh, mask UIFA_SELECT
		jz	callsuper
	;
	; Check to see if they dragged up or down to see if we should scroll.
	;

	; if a timer is progress, don't do anything.
	; This will happen when you move back into visible after dragging out.
	; or just while moving around outside the visible area
	;
		test	bh, mask UIFA_IN
		jnz	afterScroll

		cmp	ds:[di].GT_timerHandle, 0
		jne	processed

		call	SendCorrectScrollMessage
		jc	processed
afterScroll:
	;
	; Stop the timer if there is one going
	;
		call	TableStopTimer

afterTimer::

		call	ConvertMouseCoordsToCell	; cx <- col, dx <-row
		jz	processed
		
		call	TableDerefSI_DI
	; if the pen is still in the same cell as last time
	; don't do anything.
	;
		mov	bx, ds:[di].GT_selectionType
		Assert	etype, bx, GadgetTableSelectionType
		Assert	ne, bx, GTST_SELECT_CUSTOM
		Assert	ne, bx, GTST_SELECT_NONE
		shl	bx
		jmp	cs:[TablePtrPreSelectJumpTable][bx]
preSelectRow:
		cmp	dx, ds:[di].GT_dragSelectEnd.TC_row
		je	processed
		jmp	okayToInv
preSelectCol:
		cmp	cx, ds:[di].GT_dragSelectEnd.TC_col
		je	processed
		jmp	okayToInv
preSelectCell:
preSelectRange:
		cmp	dx, ds:[di].GT_dragSelectEnd.TC_row
		jne	okayToInv
		cmp	cx, ds:[di].GT_dragSelectEnd.TC_col
		je	processed


okayToInv:
		call	DragSelectLow

processed:
		mov	ax, mask MRF_PROCESSED
done:
		
		.leave
		ret
callsuper:
		mov	di, offset GadgetTableClass
		call	ObjCallSuperNoLock
		jmp	done
		
TablePtrPreSelectJumpTable	nptr	0,	;		- not selectable
				offset	preSelectCell,
				offset	preSelectRow,
				offset	preSelectCol,
				offset	preSelectRange
		
GadgetTableMetaPtr	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DragSelectLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert	old selection and new selection.
		Set the dragSelect instance data appropiately.

CALLED BY:	GadgetTableMetaPtr, GadgetTableDragUp
PASS:		cx		= new column
		dx		= new row
		ds:di		= Table instance data
		*ds:si		= Table object
RETURN:		
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:	

		The checks to make sure that we are in a new cell should
		be made before this.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DragSelectLow	proc	near
		class	GadgetTableClass
		.enter
		push	dx			; row 
		push	cx			; col
		
	;
	; Invert old selection
		mov	bx, ds:[di].GT_dragSelectStart.TC_row
		mov	ax, ds:[di].GT_dragSelectStart.TC_col
		mov	dx, ds:[di].GT_dragSelectEnd.TC_row
		mov	cx, ds:[di].GT_dragSelectEnd.TC_col

	; convert special values to real rows / columns
		cmp	ax, GADGET_TABLE_SELECT_WHOLE_LINE
		jne	checkSpecialRow
		clr	ax
		mov	cx, ds:[di].GT_numCols
		dec	cx
		mov	bx, dx
checkSpecialRow:
		cmp	bx, GADGET_TABLE_SELECT_WHOLE_LINE
		jne	okayToDraw
		clr	bx
		mov	dx, ds:[di].GT_numRows
		dec	dx
		mov	ax, cx
okayToDraw:

		call	TableCreateTranslatedGState
		call	TableInvertRange

		pop	cx
		pop	dx
		xchg	bp, di			; bp <- gstate
		call	TableDerefSI_DI

	;
	; jump to right label to deal with the selection type
	;
		push	bx
		mov	bx, ds:[di].GT_selectionType
		Assert	etype, bx, GadgetTableSelectionType
		Assert	ne, bx, GTST_SELECT_CUSTOM
		Assert	ne, bx, GTST_SELECT_NONE
		shl	bx
		jmp	cs:[TablePtrSelectJumpTable][bx]
	; ax	- left cell
	; cx	- right	cell
	; dx 	- bottom cell
	; bp	- gstate
	; ds:[di] - instance data
	; on stack - top cell
		
selectRow:
		add	sp, size word			; don't need top
		mov	ds:[di].GT_dragSelectEnd.TC_row, dx
		clr	ax
		mov	cx, ds:[di].GT_numCols
		dec	cx
		mov	bx, dx
		jmp	invert
selectCell:
		pop	bx
		mov	ds:[di].GT_dragSelectEnd.TC_row, dx
		mov	ds:[di].GT_dragSelectEnd.TC_col, cx
	; Have to reset start so it inverts correctly the
	; next time through
		
		mov	ds:[di].GT_dragSelectStart.TC_row, dx
		mov	ds:[di].GT_dragSelectStart.TC_col, cx		
		mov	bx, dx
		mov	ax, cx
		jmp	invert
selectCol:
		add	sp, size word			; don't need top
		mov	ds:[di].GT_dragSelectEnd.TC_col, cx
		clr	bx
		mov	dx, ds:[di].GT_numRows
		dec	dx
		mov	ax, cx
		jmp	invert
selectRange:
		pop	bx
		mov	ds:[di].GT_dragSelectEnd.TC_row, dx
		mov	ds:[di].GT_dragSelectEnd.TC_col, cx
invert:

		xchg	bp, di			; di <- gstate
		call	TableInvertRange
		call	GrDestroyState
		.leave
		ret
TablePtrSelectJumpTable	nptr	0,	;		- not selectable
				offset	selectCell,
				offset	selectRow,
				offset	selectCol,
				offset	selectRange
DragSelectLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableMetaEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update selection and end of drag or scroll

CALLED BY:	MSG_META_END_SELECT
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es 	= segment of GadgetTableClass
		ax	= message #
		cx, dx	= mouse pos
		bp	= UIActionFlags
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/10/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableMetaEndSelect	method dynamic GadgetTableClass, 
					MSG_META_END_SELECT

		.enter
	;
	; Stop the drag scroll timer if it is on
	;
		mov	bx, ds:[di].GT_timerHandle
		cmp	bx, 0
		je	timerOff
		mov	ax, ds:[di].GT_timerID
		call	TimerStop
		mov	ds:[di].GT_timerHandle, 0
		mov	ds:[di].GT_timerID, 0

timerOff:
	;
	; If custom selection, call superclass.
	; cx, dx, bp: as passed in.
		cmp	ds:[di].GT_selectionType, GTST_SELECT_CUSTOM
		je	callSuper
	;
	; If no selection, let superclass do nothing.
	;
		cmp	ds:[di].GT_selectionType, GTST_SELECT_NONE
		je	callSuper

	;
	; Set the new selection
		mov	ax, ds:[di].GT_dragSelectStart.TC_col
		mov	cx, ds:[di].GT_dragSelectEnd.TC_col
		mov	bx, ds:[di].GT_dragSelectStart.TC_row
		mov	dx, ds:[di].GT_dragSelectEnd.TC_row

	;
	; indicate that we are done with drag
	;
		mov	ds:[di].GT_dragSelectStart.TC_row, GADGET_TABLE_NO_DRAG_IN_PROCESS
		xchg	bp, bx
		mov	bx, ds:[di].GT_selectionType
		Assert	etype, bx, GadgetTableSelectionType

		Assert	ne, bx, GTST_SELECT_CUSTOM
		Assert	ne, bx, GTST_SELECT_NONE
		shl	bx
		xchg	bp, bx
		jmp	cs:[TableEndSelectJumpTable][bp]

selectCell:
		mov	ds:[di].GT_leftSelection, cx
		mov	ds:[di].GT_rightSelection, cx
selectRow:
		mov	ds:[di].GT_topSelection, dx
		mov	ds:[di].GT_bottomSelection, dx
		jmp	releaseMouse
selectCol:
		mov	ds:[di].GT_leftSelection, cx
		mov	ds:[di].GT_rightSelection, cx

		jmp	releaseMouse
selectRange:		
		cmp	ax, cx
		jle	checkVert
		xchg	ax, cx
checkVert:
		cmp	bx, dx
		jle	saveEnd
		xchg	bx, dx
saveEnd:
		mov	ds:[di].GT_topSelection, bx
		mov	ds:[di].GT_bottomSelection, dx
		mov	ds:[di].GT_leftSelection, ax
		mov	ds:[di].GT_rightSelection, cx

releaseMouse:
	; release the mouse grab, if any
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGadget_offset
		call	GadgetGadgetReleaseMouse	; OOP faux paus:
							; touches inst data

	;
	; now send an event.

		mov	di, offset tableChangedString
		call	RaiseSimpleEvent

done:		
		.leave
		mov	ax, mask MRF_PROCESSED
		ret
callSuper:
		mov	ax, MSG_META_END_SELECT
		mov	di, offset GadgetTableClass
		call	ObjCallSuperNoLock
		jmp	done

		
TableEndSelectJumpTable	nptr	offset  releaseMouse, ;	- not selectable
				offset	selectCell,
				offset	selectRow,
				offset	selectCol,
				offset	selectRange,
				offset  releaseMouse ; - custom select
GadgetTableMetaEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableCreateTranslatedGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a gstate for a table to draw in.
		Translates to coordinates of table so the top left
		of the table is the origin.

CALLED BY:	
PASS:		*ds:si		- table object
RETURN:		di		- gstate		(must be destroyed)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableCreateTranslatedGState	proc	near
	uses	bp, ax, cx, dx, bx
		.enter

		Assert	objectPtr dssi, GadgetTableClass
	;
	; Create gstate
	;
ifndef TABLE_IN_WINDOW
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		mov	di, bp
else
EC <		call	VisCheckVisAssumption				>
		mov	di, ds:[si]
		add	di, ds:[di].VisComp_offset
		mov	di, ds:[di].VCI_window
		call	GrCreateState
endif

	; Draw in table, not on form.

ifndef TABLE_IN_WINDOW
		mov	ax, MSG_VIS_GET_POSITION
		call	ObjCallInstanceNoLock
		mov	bx, dx		; y
		mov	dx, cx		; x
		clrdw	axcx
		call	GrSaveState
		call	GrApplyTranslation
else
		call	GrSaveState
endif
		.leave
		ret
TableCreateTranslatedGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetLeftColumn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler
		Set leftColumn and perhaps rightColumn.

CALLED BY:	MSG_GADGET_TABLE_SET_LEFT_COLUMN
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		On column and cell selection, left and right should
		always be equal.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	5/27/96   	Initial version
	jmagasin 7/2/96		Maintain leftColumn <= rightColumn.
				Raise RTE for out of range value.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetLeftColumn	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SET_LEFT_COLUMN
		uses	bp
		.enter
		les	bx, ss:[bp].SPA_compDataPtr
		Assert	fptr	esbx
	;
	; Ignore if our selectionType is "row."
	;
		mov	dx, ds:[di].GT_selectionType
		cmp	dx, GTST_SELECT_ROW
		je	done

	;
	; If out of range, raise an error.
	;
		mov	cx, es:[bx].CD_data.LD_integer
		cmp	cx, -1				; special value
		je	setLeft
		tst	cx
		jl	error				; neg. value
		cmp	cx, ds:[di].GT_numCols
		jge	error				; value too big

	;
	; Maintain leftColumn <= rightColumn.
	;
		cmp	cx, ds:[di].GT_rightSelection
		jle	setLeft
		xchg	cx, ds:[di].GT_rightSelection	; switcheroo
	;
	; It's a keeper.
	;
setLeft:
		mov	ds:[di].GT_leftSelection, cx
		cmp	cx, -1
		je	done
		cmp	dx, GTST_SELECT_COLUMN
		je	setRight
		cmp	dx, GTST_SELECT_CELL
		jne	done
setRight:
		mov	ds:[di].GT_rightSelection, cx

done:
		.leave
		Destroy	ax, cx, dx
		ret
error:
		GOTO	TableSetLeftRightTopBottomError, bp
GadgetTableSetLeftColumn	endm

;
; Common code to return an error when setting right/left/top/bottom
; row/column.  Pass es:bx = component data of SetPropertyArgs
;
TableSetLeftRightTopBottomError	proc	far
		Assert	fptr	esbx
		mov	es:[bx].CD_type, LT_TYPE_ERROR
		mov	es:[bx].CD_data.LD_error, CPE_SPECIFIC_PROPERTY_ERROR
		FALL_THRU_POP	bp			; pushed by caller
		Destroy	ax, cx, dx
		ret
TableSetLeftRightTopBottomError	endp
		



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetRightColumn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler
		Set rightColumn and perhaps leftColumn.

CALLED BY:	MSG_GADGET_TABLE_SET_RIGHT_COLUMN
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		On column and cell selection, left and right should
		always be equal.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	5/27/96   	Initial version
	jmagasin 7/2/96		Maintain leftColumn <= rightColumn.
				Raise RTE for out of range value.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetRightColumn	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SET_RIGHT_COLUMN
		uses	bp
		.enter
		les	bx, ss:[bp].SPA_compDataPtr
		Assert	fptr	esbx
	;
	; Ignore if our selectionType is "row."
	;
		mov	dx, ds:[di].GT_selectionType
		cmp	dx, GTST_SELECT_ROW
		je	done

	;
	; If out of range, raise an error.
	;
		mov	cx, es:[bx].CD_data.LD_integer
		tst	cx
		jl	error					; neg. value
		cmp	cx, ds:[di].GT_numCols
		jge	error					; too big

	;
	; Maintain leftColumn <= rightColumn.
	;
		cmp	cx, ds:[di].GT_leftSelection
		jge	setRight
		xchg	cx, ds:[di].GT_leftSelection		; switcheroo

	;
	; It's a keeper.
	;
setRight:
		mov	ds:[di].GT_rightSelection, cx
		cmp	dx, GTST_SELECT_COLUMN
		je	setLeft
		cmp	dx, GTST_SELECT_CELL
		jne	done
setLeft:
		mov	ds:[di].GT_leftSelection, cx

done:
		.leave
		Destroy	ax, cx, dx
		ret
error:
		GOTO	TableSetLeftRightTopBottomError, bp
GadgetTableSetRightColumn	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetTopRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler
		Set topRow and perhaps bottomRow.

CALLED BY:	MSG_GADGET_TABLE_SET_TOP_ROW
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		On row and cell selection, top and bottom should
		always be equal.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	5/27/96   	Initial version
	jmagasin 7/2/96		Maintain topRow <= bottomRow
				Raise RTE for out of range value.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetTopRow	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SET_TOP_ROW
		uses	bp
		.enter
		les	bx, ss:[bp].SPA_compDataPtr
		Assert	fptr	esbx

	;
	; If selectionType = "column," then we don't care about top.
	;
		mov	dx, ds:[di].GT_selectionType
		cmp	dx, GTST_SELECT_COLUMN
		je	done
		
	;
	; Error if out of range.
	;
		mov	cx, es:[bx].CD_data.LD_integer
		tst	cx
		jl	error					; neg. value
		cmp	cx, ds:[di].GT_numRows
		jge	error					; too big

	; if we are doing SELECT_CELL, then top and bottom both get set
	; to whatever the new value is
		cmp	dx, GTST_SELECT_CELL
		je	setTop
	; this is also trur for SELECT_ROW
		cmp	dx, GTST_SELECT_ROW
		je	setTop
		
	;
	; Maintain topRow <= bottomRow.
	;
		cmp	cx, ds:[di].GT_bottomSelection
		jle	setTop
		xchg	cx, ds:[di].GT_bottomSelection		; switcheroo

	;
	; It's a keeper.
	;
setTop:
		mov	ds:[di].GT_topSelection, cx
		cmp	dx, GTST_SELECT_ROW
		je	setBottom
		cmp	dx, GTST_SELECT_CELL
		jne	done
setBottom:
		mov	ds:[di].GT_bottomSelection, cx

done:
		.leave
		Destroy	ax, cx, dx
		ret
error:
		GOTO	TableSetLeftRightTopBottomError, bp
GadgetTableSetTopRow	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetBottomRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler
		Set bottomRow and perhaps topRow.

CALLED BY:	MSG_GADGET_TABLE_SET_BOTTOM_ROW
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		On row and cell selection, bottom and bottom should
		always be equal.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	5/27/96   	Initial version
	jmagasin 7/2/96		Maintain topRow <= bottomRow
				Raise RTE for out of range value.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetBottomRow	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SET_BOTTOM_ROW
		uses	bp
		.enter
		les	bx, ss:[bp].SPA_compDataPtr
		Assert	fptr	esbx

	;
	; If selectionType = "column," then we don't care about bottom.
	;
		mov	dx, ds:[di].GT_selectionType
		cmp	dx, GTST_SELECT_COLUMN
		je	done
		
	;
	; Error if out of range.
	;
		mov	cx, es:[bx].CD_data.LD_integer
		tst	cx
		jl	error				; neg. value
		cmp	cx, ds:[di].GT_numRows
		jge	error				; too big

	;
	; Maintain topRow <= bottomRow.
	;
		cmp	cx, ds:[di].GT_topSelection
		jge	setBottom
		xchg	cx, ds:[di].GT_topSelection	; switcheroo

	;
	; It's a keeper.
	;
setBottom:
		mov	ds:[di].GT_bottomSelection, cx
		cmp	dx, GTST_SELECT_ROW
		je	setTop
		cmp	dx, GTST_SELECT_CELL
		jne	done
setTop:
		mov	ds:[di].GT_topSelection, cx
done:
		
		.leave
		Destroy	ax, cx, dx
		ret
error:
		GOTO	TableSetLeftRightTopBottomError, bp		
GadgetTableSetBottomRow	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableActionSetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Action Handler
		Sets the selection to be the passed rectangle.
		Returns RunTimeError if any args are invalid or don't match
		the table selection type.
		Generates redraw events for previous selection if no error.

CALLED BY:	MSG_GADGET_TABLE_ACTION_SET_SELECTION
		SetSelection(left, top, right, bottom)
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	5/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableActionSetSelection	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_ACTION_SET_SELECTION
	uses	bp
		.enter
	;
	; If we are in the middle of a drawCell handler, don't cause more
	; to happen.
	;
		mov	ax, ATTR_GADGET_TABLE_DOING_REDRAW
		call	ObjVarFindData
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		jc	error

		call	Get4ActionArgs
		jc	error
		
	;
	; Check for correct args
	;
		cmp	ds:[di].GT_selectionType, GTST_SELECT_NONE
		je	done
		cmp	ds:[di].GT_selectionType, GTST_SELECT_CUSTOM
		je	done
		cmp	ds:[di].GT_selectionType, GTST_SELECT_ROW
		je	verifyRow
		cmp	ds:[di].GT_selectionType, GTST_SELECT_COLUMN
		je	verifyColumn
		cmp	ds:[di].GT_selectionType, GTST_SELECT_CELL
		je	verifyCell
		cmp	ds:[di].GT_selectionType, GTST_SELECT_RANGE
		je	verifyRange
	;
	; ax = left, bx = top
	; cx = right, dx = bottom
verifyRow:
	; 
		mov	dx, bx
		mov	ax, GADGET_TABLE_SELECT_WHOLE_LINE
		mov	cx, ds:[di].GT_numCols
		dec	cx
		jmp	okay
verifyColumn:
		mov	cx, ax
		mov	bx, GADGET_TABLE_SELECT_WHOLE_LINE
		mov	dx, ds:[di].GT_numRows
		dec	dx
		jmp	okay

verifyCell:
		mov	cx, ax
		mov	dx, bx
		jmp	okay

verifyRange:
		cmp	ax, cx
		jbe	checkYValues
		xchg	ax, cx
checkYValues:
		cmp	bx, dx
		jbe	okay
		xchg	bx, dx

okay:
	;
	; redraw previously selected cells without selection
		call	TableUndrawSelection
	;
	; select new cells.
		call	TableDerefSI_DI
		mov	ds:[di].GT_leftSelection, ax
		mov	ds:[di].GT_rightSelection, cx
		mov	ds:[di].GT_topSelection, bx
		mov	ds:[di].GT_bottomSelection, dx
	;
	; Draw selection
		call	TableRedrawSelection
done:
		.leave
	Destroy	ax, cx, dx
		ret
error:
	; ax = error
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		jmp	done
		
GadgetTableActionSetSelection	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableGetTopRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_TABLE_GET_TOP_ROW
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableGetTopRow	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_GET_TOP_ROW,
					MSG_GADGET_TABLE_GET_BOTTOM_ROW,
					MSG_GADGET_TABLE_GET_LEFT_COLUMN,
					MSG_GADGET_TABLE_GET_RIGHT_COLUMN
		.enter
		sub	ax, MSG_GADGET_TABLE_GET_LEFT_COLUMN
		mov	bx, ax
		mov	bx, cs:[selectionOffsetTable][bx]
		call	TableDerefSI_DI
		mov	cx, ds:[di][bx]
	;
	; Fixup special values.
	;
		cmp	cx, GADGET_TABLE_SELECT_WHOLE_LINE
		jne	notSpecial
		mov	cx, 0
notSpecial:

		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_data.LD_integer, cx
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTableGetTopRow	endm

.warn -private
selectionOffsetTable nptr offset GT_leftSelection,
			  offset GT_rightSelection,
			  offset GT_topSelection,
			  offset GT_bottomSelection
		.assert offset GT_leftSelection + 2 eq offset GT_rightSelection
		.assert offset GT_rightSelection + 2 eq offset GT_topSelection
		.assert offset GT_topSelection + 2 eq offset GT_bottomSelection
		.assert MSG_GADGET_TABLE_SET_LEFT_COLUMN + 2 eq  MSG_GADGET_TABLE_SET_RIGHT_COLUMN
		.assert MSG_GADGET_TABLE_SET_RIGHT_COLUMN + 2 eq MSG_GADGET_TABLE_SET_TOP_ROW
		.assert MSG_GADGET_TABLE_SET_TOP_ROW + 2 eq MSG_GADGET_TABLE_SET_BOTTOM_ROW
.warn @private



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableVisRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw self, look, visible cells and children.

CALLED BY:	INTERNAL
PASS:		*ds:si		= Table Component
RETURN:		nada
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableVisRedraw	proc	near
	uses	ax,cx,dx,bp
		.enter
		Assert	objectPtr, dssi, GadgetTableClass
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock
		.leave
		ret
TableVisRedraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetSelectionType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler
CALLED BY:	MSG_GADGET_TABLE_SET_SELECTION_TYPE
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		set the selection type.
		clear all selections.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/12/95   	Initial version
	jmagasin 7/8/96		Only change leftColumn (to -1) when
				setting selectionType.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetSelectionType	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SET_SELECTION_TYPE

		
		.enter
	; Make sure the selection is in range
		
		CheckHack<GTST_SELECT_CUSTOM gt GTST_SELECT_NONE>
		
		les	bx, ss:[bp].SPA_compDataPtr
		Assert	fptr	esbx

	;has to  be less than GTST_SELECT_CUSTOM
		mov	cx, es:[bx].CD_data.LD_integer
		cmp	cx, GTST_SELECT_CUSTOM
		jg	setError

	; and greater than GTST_SELECT_NONE
		cmp	cx, GTST_SELECT_NONE
		jl	setError

		mov	ds:[di].GT_selectionType, cx
	;
	; Make sure the pen events match the selection type.
	;
		CheckHack <GadgetTable_offset eq GadgetGadget_offset>
		cmp	cx, GTST_SELECT_CUSTOM
		je	addPen
	; remove any pen events
		and	ds:[di].GGI_gadgetFlags, not ALL_PEN_EVENTS
		jmp	done
addPen:
		or	ds:[di].GGI_gadgetFlags, mask GGF_PEN or mask GGF_READY_PEN_MOVE
done:
		call	TableUndrawSelection
		call	TableDerefSI_DI
		mov	ds:[di].GT_leftSelection, GADGET_TABLE_SELECT_NONE

leaving:
		.leave
		Destroy	ax, cx, dx
		ret

setError:
	;
	; selectionType is set with value out of range
	;

		mov	es:[bx].CD_type, LT_TYPE_ERROR
		mov	es:[bx].CD_data.LD_error, CPE_SPECIFIC_PROPERTY_ERROR
		jmp	leaving
		
		
GadgetTableSetSelectionType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableGetSelectionType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_TABLE_GET_SELECTION_TYPE
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableGetSelectionType	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_GET_SELECTION_TYPE
		.enter
		mov	cx, ds:[di].GT_selectionType
		Assert	etype, cx, GadgetTableSelectionType
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_data.LD_integer, cx
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTableGetSelectionType	endm

GadgetTableGetClass	method dynamic GadgetTableClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetTableString
		mov	dx, offset GadgetTableString
		ret
GadgetTableGetClass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GTGadgetGadgetSetPen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignore set if selectionType != 5

CALLED BY:	MSG_GADGET_GADGET_SET_PEN
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es 	= segment of GadgetTableClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/8/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GTGadgetGadgetSetPen	method dynamic GadgetTableClass, 
					MSG_GADGET_GADGET_SET_PEN
		.enter
		cmp	ds:[di].GT_selectionType, GTST_SELECT_CUSTOM
		jne	done
		mov	di, offset GadgetTableClass
		call	ObjCallSuperNoLock
done:
		.leave
		ret
GTGadgetGadgetSetPen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSetLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LegosPropertyHandler

CALLED BY:	MSG_GADGET_SET_LOOK
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSetLook	method dynamic GadgetTableClass, 
					MSG_GADGET_SET_LOOK
		.enter

	;
	; have our superclass set the look
	;
		mov	di, offset GadgetTableClass
		call	ObjCallSuperNoLock
	;
	; redraw the table
	;

		call	TableVisRedraw
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTableSetLook	endm


ifdef	TABLE_IN_WINDOW

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a clipping window to put the table in

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es 	= segment of GadgetTableClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/ 4/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableSpecBuild	method dynamic GadgetTableClass, 
					MSG_SPEC_BUILD
		.enter

	;
	; 	Mark ourself as having a window so we can really
	; 	clip our GenChildren.
EC <		call	VisCheckVisAssumption				>
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		BitSet	ds:[di].VI_typeFlags, VTF_IS_WINDOW
	;
	; Let superclass do its thing

		mov	ax, MSG_SPEC_BUILD
		mov	di, offset GadgetTableClass
		call	ObjCallSuperNoLock
		
		.leave
		ret
GadgetTableSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableVisOpenWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a window to put our children in

CALLED BY:	MSG_VIS_OPEN_WIN
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es 	= segment of GadgetTableClass
		ax	= message #
		^bp	= parent window window
RETURN:		
DESTROYED:	
SIDE EFFECTS:
		stores new window in VCI_window

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/ 5/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableVisOpenWin	method dynamic GadgetTableClass, 
					MSG_VIS_OPEN_WIN
		.enter

		push	si			; self
	;
	; Create a window on the screen
	;
		clr	bx
		push	bx	; Layer ID
		call	GeodeGetProcessHandle
		push	bx	; geode to own window = current


		push	bp	; handle of field window
		clr	bx
		push	bx	; high word for region
		push	bx	; low word for region
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock
		push	dx	; bottom
		push	cx 	; right
		push	bp	; top
		push	ax	; left
		

		mov	cx, ds:[LMBH_handle]
		mov	dx, si			; ^lcx:dx = input object = self
		movdw	dibp, cxdx		; ExposureObj = self
		mov	ax, (WinColorFlags <
			0,		; WCF_RGB
			1,	; WCF_TRANSPARENT: window has background color
			0,	; WCF_PLAIN: window requires exposures
			ColorMapMode <	; WCF_MAP_MODE
				0,	; not drawing on black
				CMT_CLOSEST
			>
		> shl 8 ) 

		mov	si, mask WPF_SAVE_UNDER or \
			mask WPF_CREATE_GSTATE

		call	WinOpen

		pop	si	; self
EC <		call	VisCheckVisAssumption				>
		mov	si, ds:[si]
		add	si, ds:[si].VisComp_offset
		mov	ds:[si].VCI_window, bx

		.leave
		ret

GadgetTableVisOpenWin	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableScrollUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	scroll the table up one row if not already at the top.

CALLED BY:	MSG_GADGET_TABLE_SCROLL_UP
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es 	= segment of GadgetTableClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	Marks timer as not in use.
		If you call this, you need to stop the timer.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableScrollUp	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SCROLL_UP
		uses	ax
		.enter

		mov	ax, ds:[di].GT_firstVisibleRow


	;
	; if partial line at top, show whole line
		cmp	ds:[di].GT_topClipped, 0
		jne	ScrollIt
	;
	; if at top, do nothing
		cmp	ax, 0
		je	done
	;
	; Show next line up.
		dec	ax
ScrollIt:
		call	TableScrollLow

		
done:
		.leave
		ret
GadgetTableScrollUp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableScrollDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	scroll the table down one row if not already at the top.

CALLED BY:	MSG_GADGET_TABLE_SCROLL_DOWN
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es 	= segment of GadgetTableClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	Marks timer as not in use.
		If you call this, you need to stop the timer.


PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableScrollDown	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_SCROLL_DOWN
		uses	ax
		.enter
		mov	ax, ds:[di].GT_lastVisibleRow

	;
	; If the last row is not fully visible, make it so.
	; (Check to see if the beginning of the next row is visible)
		inc	ax			; ax = next row
		push	ax			; ax = next row
		call	ConvertRowToYPixel
		Assert	ge, ax, 0
		dec	ax	
		push 	ax			; y coord of end of visible row
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjCallInstanceNoLock
		pop	bx			; y coord of end of visibleRow
		pop	ax			; next row
		cmp	bx, dx
		jle	checkLast
	; make current row fully visible
		dec	ax			; current last visible row
		jmp	ScrollIt

checkLast:
	;
	; If the last row is numRows -1, don't do anyting
						; At end

						; lastVisibleRow = NumRows -1
		cmp	ax, ds:[di].GT_numRows
		je	done
ScrollIt:
	;
	; Set the LastVisibleRow to one more than current
	; ax = next row to make visible

		call	SetLastVisibleRowLow

done:
		.leave
		ret
GadgetTableScrollDown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertMouseCoordsToCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts coords passed by MSG_META_(MOUSE) to the cell
		that it refers to

CALLED BY:	
PASS:		cx		- x coord
		dx		- y coord
RETURN:		cx		- col
		dx		- row
		zf		- set if either row or column is -1,
				  meaning the y or x coord is not
				  visible

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/10/96    	Initial version
	jmagasin 8/28/96	Return zero flag.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertMouseCoordsToCell	proc	near
		uses	bp, ax, bx
		.enter
	;
	; Change X,Y to be relative to us.
		push	cx, dx		; x, y
		mov	ax, MSG_VIS_GET_POSITION
		call	ObjCallInstanceNoLock
		pop	ax, bx		; x, y 
		sub	ax, cx		; translated x
		jns	horizOk
		clr	ax
horizOk:
		sub	bx, dx		; translated y
		jns	vertOk
		clr	bx
vertOk:
		
	;
	; Get the cell clicked in
	;
		call	ConvertXPixelToCol
		mov	cx, ax			; col

		mov	ax, bx
		call	ConvertRelYPixelToRow
		mov	dx, ax			; row

		inc	ax
		jz	done			; Jump if row is -1.
		cmp	cx, -1
done:
		.leave
		ret
ConvertMouseCoordsToCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendCorrectScrollMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Either sends scroll up or scroll down depending on where
		the mouse is relative table

CALLED BY:	GadgetTableMetaPtr
PASS:		cx, dx		= mouse pos
RETURN:		nothing
DESTROYED:	carry set iff timer message send and no work needed now
SIDE EFFECTS:	can eventually call into basic code.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendCorrectScrollMessage	proc	near
		class	GadgetTableClass
	uses	ax,bx,cx,dx,bp
		.enter
		cmp	ds:[di].GT_timerHandle, 0
		jne	done
		cmp	ds:[di].GT_timerID, TIMER_ID_DONT_START
		je	done
		
		push	dx			; y pos
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock
		pop	ax			; y pos
		cmp	ax, bp
		jg	checkBelow
		mov	dx, MSG_GADGET_TABLE_DRAG_UP
		jmp	sendMessage

checkBelow:
		cmp	ax, dx
		jl	done
		
		mov	dx, MSG_GADGET_TABLE_DRAG_DOWN
sendMessage:
	; dx = message to send
		mov	ax, TIMER_EVENT_ONE_SHOT
		mov	bx, ds:[LMBH_handle]	; send event to self
		mov	cx, TABLE_DRAG_TIMER_INTERVAL		; ticks 
		call	TimerStart
		call	TableDerefSI_DI
		mov	ds:[di].GT_timerHandle, bx
		mov	ds:[di].GT_timerID, ax

		stc
		jmp	bye
done:
		clc
bye:
		.leave
		ret
SendCorrectScrollMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableDragUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	After a drag select timer expires, scroll the table
		and start a new timer.  This is a common routine for
		scrolling both up and down

CALLED BY:	MSG_GADGET_TABLE_DRAG_UP, MSG_GADGET_TABLE_DRAG_DOWN
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es 	= segment of GadgetTableClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		A timer has gone off signalling we should drag scroll
		another row.

		if endselect has happened, the timer will have stopped
		and we shouldn't be here.

		if the mouse moved back in the visible bounds we'll get here
		one last time.

		In order to get drag scroll to work we need to do 3 things:
		1) Scroll list (redrawing old selection )
		2) update dragSelect instance data (deselecting selection
		 	and drawing new one.
		3) Start the timer again.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableDragUp	method dynamic GadgetTableClass, 
					MSG_GADGET_TABLE_DRAG_UP,
					MSG_GADGET_TABLE_DRAG_DOWN
		.enter
CheckHack <MSG_GADGET_TABLE_DRAG_DOWN eq MSG_GADGET_TABLE_SCROLL_DOWN +2>
CheckHack <MSG_GADGET_TABLE_DRAG_UP eq MSG_GADGET_TABLE_SCROLL_UP +2>

	;
	; Tell the table to scroll in the correct direction
		push	ax		; message, it goes back on the timer
		
		sub	ax, 2	; convert drag message to scroll message
		call	ObjCallInstanceNoLock
		call	TableDerefSI_DI

		call	CurrentCellForMouse	; cx, dx <- cell
		call	TableDerefSI_DI
		call	DragSelectLow

		pop	dx		; message
		mov	ax, TIMER_EVENT_ONE_SHOT
		mov	bx, ds:[LMBH_handle]
		mov	cx, TABLE_DRAG_TIMER_INTERVAL
		call	TableDerefSI_DI
		cmp	ds:[di].GT_timerID, TIMER_ID_DONT_START
		je	done
		call	TimerStart
		mov	ds:[di].GT_timerHandle, bx
		mov	ds:[di].GT_timerID, ax
done:
		.leave
		ret
GadgetTableDragUp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CurrentCellForMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the cell the mouse is over or nearest.
		This is used by the drag select mechanism and often the
		mouse will be outside the table.

CALLED BY:	GadgetTableDragUp
PASS:		*ds:si		- Table object
RETURN:		cx		- table column
		dx		- table row
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Sometimes Convert MouseCoordsToCell return the row
		after the visible row. (I haven't figure out why).
		Since it only happens when this called from Dragging
		down outside the bounds, I will look for problem and
		fix it up here.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CurrentCellForMouse	proc	near
		class	GadgetTableClass
		
		uses	ax,bx,bp
		Assert	objectPtr, dssi, GadgetTableClass
		.enter
	;
	; send out another MSG_META_PTR
		mov	ax, MSG_VIS_QUERY_WINDOW
		call	ObjCallInstanceNoLock
		mov	di, cx
		call	ImGetMousePos
		call	ConvertMouseCoordsToCell
		call	TableDerefSI_DI
		cmp	dx, ds:[di].GT_lastVisibleRow
		jle	done
	; FIXME: figure out why this fixup is needed and if it implies
	; that other things are broken.  You can get here by drag
	; scrolling down. Sometimes it is next row down, sometimes
	; more.
		mov	dx, ds:[di].GT_lastVisibleRow

done:
		.leave
		ret
CurrentCellForMouse	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableRedrawSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraws the currently selected cells and the selection after
		a selection change

CALLED BY:	SET selection property handlers
PASS:		*ds:si		- Table object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Raises _drawCell events.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableRedrawSelection	proc	near
	uses	di,bp, ax, bx, cx, dx
		.enter
		call	TableGetCellsForSelection
		jc	done
		call	TableDrawPartialLook
		call	TableQueryCells
		call	TableDrawSelection
		Assert	gstate, di
		call	GrDestroyState
done:
		.leave
		ret
TableRedrawSelection	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableUndrawSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraws the currently selected cells without the selection.

CALLED BY:	SET selection property handlers
PASS:		*ds:si		- Table object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Raises _drawCell events.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableUndrawSelection	proc	near
	uses	di,bp, ax, bx, cx, dx
		.enter
		call	TableGetCellsForSelection
		jc	done
		call	TableDrawPartialLook
		call	TableQueryCells
		Assert	gstate, di
		call	GrDestroyState
done:
		.leave
		ret
TableUndrawSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableGetCellsForSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts selection values into rows.  (accounts for
		*special* values)

CALLED BY:	
PASS:		*ds:si	-	GadgetTableObject
RETURN:		
		ax, bx		- left, top [inclusive]
		cx, dx		- bottom, right [inclusive]
		Carry set	if no cells are selected.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableGetCellsForSelection	proc	near
		class	GadgetTableClass
		.enter
		call	TableDerefSI_DI
		mov	ax, ds:[di].GT_leftSelection
		mov	bx, ds:[di].GT_topSelection
		mov	cx, ds:[di].GT_rightSelection
		mov	dx, ds:[di].GT_bottomSelection
		cmp	ax, GADGET_TABLE_SELECT_NONE
		je	none
		cmp	bx, GADGET_TABLE_SELECT_NONE
		je	none

		cmp	ax, GADGET_TABLE_SELECT_WHOLE_LINE
		jne	checkCol
		mov	ax, 0
		mov	cx, ds:[di].GT_numCols
		dec	cx
checkCol:
		cmp	bx, GADGET_TABLE_SELECT_WHOLE_LINE
		jne	cellsSet
		mov	bx, ds:[di].GT_firstVisibleRow
		mov	dx, ds:[di].GT_lastVisibleRow
		
cellsSet:
		stc
none:
		cmc		; equality comparisons cleared carry
		.leave
		ret
TableGetCellsForSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableStopTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stops a drag scroll timer it if it running

CALLED BY:	GadgetTableMetaPtr, GadgetTableEntDestroy
PASS:		*ds:si		- table
RETURN:		nothing
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableStopTimer	proc	near
		class	GadgetTableClass
		.enter
		call	TableDerefSI_DI
		mov	bx, ds:[di].GT_timerHandle
		cmp	bx, 0
		je	done	; 
		mov	ax, ds:[di].GT_timerID
		Assert	ne, ax, TIMER_ID_DONT_START
		cmp	ax, TIMER_ID_DONT_START
		je	done
		clr	ds:[di].GT_timerHandle
		clr	ds:[di].GT_timerID
		call	TimerStop
done:
		.leave
		ret
TableStopTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTableEntDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off the timer for good and tell ourselves that we
		don't want it turned back on.

CALLED BY:	MSG_ENT_DESTROY
PASS:		*ds:si	= GadgetTableClass object
		ds:di	= GadgetTableClass instance data
		ds:bx	= GadgetTableClass object (same as *ds:si)
		es 	= segment of GadgetTableClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTableEntDestroy	method dynamic GadgetTableClass, 
					MSG_ENT_DESTROY
		.enter
		call	TableStopTimer

	;notify ourself we don't want to ever turn the timer back on.
		mov	ds:[di].GT_timerID, TIMER_ID_DONT_START

		mov	ax, MSG_ENT_DESTROY
		mov	di, offset GadgetTableClass
		call	ObjCallSuperNoLock
		
		
		.leave
		ret
GadgetTableEntDestroy	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECTableCheckLegalRow/Column
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure a row/column is legal within the table.
		However, row/column may extend one beyond table's last
		row/column (i.e., legal cols from 0 to GT_numCols).

CALLED BY:	Error checking utility
PASS:		*ds:si	- table
		ax	- row/column to check
RETURN:		fatal error if illegal row/column
DESTROYED:	nothing
SIDE EFFECTS:

	We allow the row to be -1, which is equal to
	GADGET_TABLE_NO_DRAG_IN_PROCESS.

PSEUDO CODE/STRATEGY:
	We accept row/columns equal to GT_numRows/Cols so that
	ConvertRowToYPixel and ConvertColToXPixel can find the
	height/width of the table.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 7/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECTableCheckLegalRow	proc	near
.warn -private
		uses	di
		.enter

		CheckHack < GADGET_TABLE_NO_DRAG_IN_PROCESS eq -1 >
		Assert	ge, ax, GADGET_TABLE_NO_DRAG_IN_PROCESS
		call	TableDerefSI_DI
		Assert	le, ax, ds:[di].GT_numRows
		
		.leave
		ret
.warn @private
ECTableCheckLegalRow	endp

ECTableCheckLegalColumn	proc	near
.warn -private
		uses	di
		.enter

		Assert	ge, ax, 0
		call	TableDerefSI_DI
		Assert	le, ax, ds:[di].GT_numCols
		
		.leave
		ret
.warn @private
ECTableCheckLegalColumn	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECTableCheckLegalCellRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure a cell range is legal within a table, but
		allow row/col to extend one more than last visible
		row/col (i.e., row may be from 0 to GT_numRows).

CALLED BY:	Error checking utilitiy
PASS:		*ds:si	- table
		ax	- left column
		bx	- top row
		cx	- right column
		dx	- bottom row
RETURN:		fatal error if illegal range
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 7/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECTableCheckLegalCellRange	proc	near
		uses	ax
		.enter

		call	ECTableCheckLegalColumn		; check left
		mov	ax, cx
		call	ECTableCheckLegalColumn		; check right
		mov	ax, bx
		call	ECTableCheckLegalRow		; check top
		mov	ax, dx
		call	ECTableCheckLegalRow		; check bottom
		
		.leave
		ret
ECTableCheckLegalCellRange	endp
endif

GadgetGadgetCode	ends


;;; Code I started to write to deal with only selecting the new row /col
;;; dragged in without inverting everything twice.
;;; It belongs in the middle of MSG_META_PTR
if 0		; darken
	;
	; If (sign(end - start) == sign(new - end))
	; then moving away;{
	;	if (end > start) /* moving down */ )
	; 		Invert (end+1, new)
	;	else	/* moving up */
	;		Invert (end, new-1)
	; OPTIMIZE above by adding 1...
	; else /* moving toward */
	;	if (end > start && new < start) || (end <start && new > start)
	; 		crossed start, do something special
	;		(does this cover case of getting back to only 1 row?)
	;	else check (up/down) and do Invert.
		
	;
	; If the row is the same row we were in last time, just update
	; the column.
	;
	;	AX = last row we dragged to
	;	DX = current row mouse is in
	;	? | ? | ?
		
		mov	ax, ds:[di].GT_dragSelectEnd.TC_row
		cmp	dx, ax
		je	checkCol
	;	LAST != CURRENT
		
	; The mouse entered a new row, either select it or deselect the old
	; rows we left.
	;
		cmp	ax, ds:[di].GT_dragSelectStart.TC_row
		jge	newRowSelectedCheck
	;	LAST != CURRENT
	;	LAST < START
	;	LSC or CLS or LCS
	; we were dragging up, not down
	; if current before end, then away, else toward
		mov	cx, 1			; moving up
		Assert	e, ax, ds:[di].GT_dragSelectEnd.TC_row
		cmp	dx, ax		; CLS?
		jl	newRowSelected

	; either LSC or LCS, LCS is the easy one...
	; if LCS == LSC, treat as LCS
		cmp	dx, ds:[di].GT_dragSelectStart.TC_row
		jg	aboveStart

aboveStart:
	; LSC, do the right thing
		

newRowSelectedCheck:
		clr	cx			; 0 if we are moving down
		cmp	ax, ds:[di].GT_dragSelectEnd.TC_row
		jne	moveDown
		inc	cx			; moving up
moveDown:
		cmp	dx, ax
		jg	newRowSelected

newRowSelected:
	;
	; cx = 0 if we are moving down, 1 if moving up
	; dx = current row of mouse
		mov	bx, ds:[di].GT_dragSelectEnd.TC_row
		jcxz	getHoriz
		xchg	bx, dx
		dec	dx
		dec	bx		; just to avoid a jump

getHoriz:
		inc	bx
		mov	ax, ds:[di].GT_dragSelectStart.TC_col
		mov	cx, ds:[di].GT_dragSelectEnd.TC_col
		call	TableInvertRange


checkCol:
endif	; darken
