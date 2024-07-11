
sub duplo_ui_ui_ui()

REM *******************************************************************
REM
REM PROJECT:	Legos Builder
REM FILE:	sp-text.bas
REM
REM AUTHOR:	bkurtin
REM DATE:	8/96
REM
REM SYNOPSIS:
REM
REM     This file implements the special properties box for the table
REM     component.
REM
REM NOTES:
REM
REM     The dialog box is designed so that none of the changes take
REM     effect until the "Apply" button is pressed.  This behavior
REM     follows that of the other properties boxes.
REM
REM BUGS:
REM
REM     * If you close and then reopen the properties box while the
REM       special-text-properties page is showing, the system will
REM       hang.
REM
REM     * You can only view the upper left 1024x1024 pixel area of the
REM       initial rows and columns.
REM
REM     * The entries in the insert-query and change-query dialogs
REM       will treat some illegal input as valid.  Most users probably
REM       will never enter such input.  Even if they do, the results are
REM       reasonable.
REM
REM     * Very small rows and columns are difficult to work with, and
REM       they can contain erroneous drawing artifacts.
REM
REM     * The initial values in some of the entries in the in
REM       insert-query and change-query dialogs could be improved by
REM       determing them from the selection.
REM
REM     * After deleting all the rows in the editor, an row insert
REM       operation will not work correctly.  There will be a run-time 
REM       error and incorrect drawing.  This bug is in the table
REM       component.
REM
REM     * I tried to update the table in the editor to reflect the
REM       look when the "Look" list changed, but the code caused a
REM       system crash, so I removed it.
REM
REM REVISION:
REM
REM     $Id: sp-table.bas,v 1.1 98/03/12 20:30:12 martin Exp $
REM
REM ******************************************************************

 REM	Copyright (c) Geoworks 1995 1996 -- All Rights Reserved
 REM	FILE:		stdinc.bh (standard include)

 STRUCT TimeOfDay
  DIM hour as integer
  DIM minute as integer
  DIM second as integer
 END STRUCT

 STRUCT Date
  DIM year as integer
  DIM month as integer
  DIM day as integer
 END STRUCT

 STRUCT Notification
  DIM arg1 as integer
  DIM arg2 as integer
  DIM arg3 as integer
  DIM arg4 as integer
  DIM arg5 as string
  DIM arg6 as complex
 END STRUCT

REM useful color constants
CONST WHITE		&Hffffffff
CONST BLACK		&Hff000000
CONST GRAY_50		&Hff808080, GREY_50		&Hff808080
CONST DARK_GRAY		&Hff555555, LIGHT_GRAY		&Hffaaaaaa
CONST DARK_GREY		&Hff555555, LIGHT_GREY		&Hffaaaaaa
CONST DARK_GREEN	&Hff00aa00, LIGHT_GREEN		&Hff55ff55
CONST DARK_BLUE		&Hff0000aa, LIGHT_BLUE		&Hff5555ff
CONST DARK_CYAN		&Hff00aaaa, LIGHT_CYAN		&Hff55ffff
CONST DARK_PURPLE	&Hffaa00aa, LIGHT_PURPLE	&Hffff55ff
CONST DARK_ORANGE	&Hffaa5500, LIGHT_ORANGE	&Hffff5555
CONST YELLOW		&Hffffff55
CONST RED		&Hffaa0000

REM sound constants
CONST SS_ERROR		0
CONST SS_WARNING	1
CONST SS_NOTIFY		2
CONST SS_NO_INPUT	3
CONST SS_KEY_CLICK	4
CONST SS_ALARM		5

CONST MOUSE_PRESS 1, MOUSE_HOLD 2, MOUSE_DRAG 3, MOUSE_TO 4, MOUSE_RELEASE 5
CONST MOUSE_LOST 6, MOUSE_FLY_OVER 7

dim system as module
system = SystemModule()

 REM end of stdinc.bh

DisableEvents()
Dim tableSpecPropBox as control
tableSpecPropBox = MakeComponent("control","top")
CompInit tableSpecPropBox
proto="tableSpecPropBox"
left=0
top=0
caption=" "
tile=1
tileSpacing=5
tileHInset=10
tileVInset=10
End CompInit
Dim group6 as group
group6 = MakeComponent("group",tableSpecPropBox)
CompInit group6
proto="group6"
caption="Initial Rows and Columns"
look=1
sizeHControl=0
sizeVControl=1
tile=1
tileSpacing=20
width=300
tileVInset=5
visible=1
End CompInit
Dim group10 as group
group10 = MakeComponent("group",group6)
CompInit group10
proto="group10"
caption=""
sizeVControl=3
sizeHControl=3
visible=1
End CompInit
Dim vertScroll as scrollbar
vertScroll = MakeComponent("scrollbar",group10)
CompInit vertScroll
proto="vertScroll"
left=184
top=0
sizeVControl=0
height=184
sizeHControl=0
width=17
visible=1
End CompInit
vertScroll.name="vertScroll"
Dim horizScroll as scrollbar
horizScroll = MakeComponent("scrollbar",group10)
CompInit horizScroll
proto="horizScroll"
left=0
top=184
orientation=1
width=184
sizeVControl=0
height=17
visible=1
End CompInit
horizScroll.name="horizScroll"
Dim group12 as group
group12 = MakeComponent("group",group10)
CompInit group12
proto="group12"
caption="group12"
left=0
top=0
height=184
width=184
look=4
tileHInset=5
tileVInset=5
visible=1
End CompInit
Dim vertClipper as clipper
vertClipper = MakeComponent("clipper",group12)
CompInit vertClipper
proto="clipper2"
left=5
top=26
sizeHControl=0
sizeVControl=0
width=16
height=154
visible=1
End CompInit
Dim vertSelector as table
vertSelector = MakeComponent("table",vertClipper)
CompInit vertSelector
proto="vertSelector"
left=0
top=0
width=16
height=1023
numRows=3
numColumns=1
selectionType=4
look=1
End CompInit
vertSelector.name="vertSelector"
vertSelector.rowHeights[2]=14
vertSelector.rowHeights[1]=14
vertSelector.rowHeights[0]=14
vertSelector.columnWidths[0]=16
vertSelector.visible=1
vertClipper.name="vertClipper"
Dim horizClipper as clipper
horizClipper = MakeComponent("clipper",group12)
CompInit horizClipper
proto="clipper3"
left=26
top=5
sizeHControl=0
sizeVControl=0
width=154
height=16
visible=1
End CompInit
Dim horizSelector as table
horizSelector = MakeComponent("table",horizClipper)
CompInit horizSelector
proto="horizSelector"
left=0
top=0
width=1023
height=16
numRows=1
numColumns=3
selectionType=4
look=1
End CompInit
horizSelector.name="horizSelector"
horizSelector.rowHeights[0]=15
horizSelector.columnWidths[2]=20
horizSelector.columnWidths[1]=20
horizSelector.columnWidths[0]=20
horizSelector.visible=1
horizClipper.name="horizClipper"
Dim initialClipper as clipper
initialClipper = MakeComponent("clipper",group12)
CompInit initialClipper
proto="clipper4"
left=26
top=26
sizeHControl=0
sizeVControl=0
width=154
height=154
visible=1
End CompInit
Dim initialTable as table
initialTable = MakeComponent("table",initialClipper)
CompInit initialTable
proto="initialTable"
left=0
top=0
width=1023
height=1023
numRows=5
numColumns=5
selectionType=5
look=1
End CompInit
initialTable.name="initialTable"
initialTable.rowHeights[4]=25
initialTable.rowHeights[3]=25
initialTable.rowHeights[2]=25
initialTable.rowHeights[1]=25
initialTable.rowHeights[0]=25
initialTable.columnWidths[4]=25
initialTable.columnWidths[3]=25
initialTable.columnWidths[2]=25
initialTable.columnWidths[1]=25
initialTable.columnWidths[0]=25
initialTable.visible=1
initialClipper.name="initialClipper"
group12.name="group12"
group10.name="group10"
Dim buttonGroup as group
buttonGroup = MakeComponent("group",group6)
CompInit buttonGroup
proto="buttonGroup"
caption=""
tile=1
tileLayout=1
tileSpacing=5
visible=1
End CompInit
Dim insertButton as button
insertButton = MakeComponent("button",buttonGroup)
CompInit insertButton
proto="insertButton"
caption="Insert ..."
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
insertButton.name="insertButton"
Dim deleteButton as button
deleteButton = MakeComponent("button",buttonGroup)
CompInit deleteButton
proto="deleteButton"
caption="Delete"
sizeHControl=3
visible=1
End CompInit
deleteButton.name="deleteButton"
Dim changeButton as button
changeButton = MakeComponent("button",buttonGroup)
CompInit changeButton
proto="changeButton"
caption="Change ..."
sizeVControl=3
visible=1
End CompInit
changeButton.name="changeButton"
buttonGroup.name="buttonGroup"
group6.name="group6"
Dim group13 as group
group13 = MakeComponent("group",tableSpecPropBox)
CompInit group13
proto="group13"
caption=""
sizeVControl=1
tileLayout=1
sizeHControl=2
visible=1
End CompInit
Dim label1 as label
label1 = MakeComponent("label",group13)
CompInit label1
proto="label1"
caption="Default Row Height:"
sizeHControl=3
sizeVControl=3
left=10
top=2
visible=1
End CompInit
label1.name="label1"
Dim defaultRowHeightEntry as entry
defaultRowHeightEntry = MakeComponent("entry",group13)
CompInit defaultRowHeightEntry
proto="entry1"
width=76
left=140
top=0
visible=1
End CompInit
defaultRowHeightEntry.name="defaultRowHeightEntry"
group13.name="group13"
Dim group14 as group
group14 = MakeComponent("group",tableSpecPropBox)
CompInit group14
proto="group14"
caption=""
tileLayout=1
sizeHControl=2
sizeVControl=1
visible=1
End CompInit
Dim label2 as label
label2 = MakeComponent("label",group14)
CompInit label2
proto="label2"
caption="Selection Type:"
sizeHControl=3
sizeVControl=3
left=10
top=0
visible=1
End CompInit
label2.name="label2"
Dim selectionList as list
selectionList = MakeComponent("list",group14)
CompInit selectionList
proto="selectionList"
look=2
sizeHControl=3
sizeVControl=3
left=140
top=0
End CompInit
selectionList.name="selectionList"
selectionList.visible=1
group14.name="group14"
Dim group15 as group
group15 = MakeComponent("group",tableSpecPropBox)
CompInit group15
proto="group15"
caption=""
tileLayout=1
sizeHControl=2
sizeVControl=1
visible=1
End CompInit
Dim label3 as label
label3 = MakeComponent("label",group15)
CompInit label3
proto="label3"
caption="Look:"
sizeHControl=3
sizeVControl=3
left=10
top=0
visible=1
End CompInit
label3.name="label3"
Dim lookList as list
lookList = MakeComponent("list",group15)
CompInit lookList
proto="lookList"
look=2
sizeHControl=3
sizeVControl=3
left=140
top=0
End CompInit
lookList.name="lookList"
lookList.visible=1
group15.name="group15"
Dim group9 as group
group9 = MakeComponent("group",tableSpecPropBox)
CompInit group9
proto="group9"
caption=""
sizeVControl=1
sizeHControl=2
tileLayout=1
visible=1
End CompInit
Dim label5 as label
label5 = MakeComponent("label",group9)
CompInit label5
proto="label5"
caption="Clipboardable API:"
sizeHControl=3
sizeVControl=3
left=10
top=0
visible=1
End CompInit
label5.name="label5"
Dim clipboardList as list
clipboardList = MakeComponent("list",group9)
CompInit clipboardList
proto="clipboardList"
look=2
behavior=2
sizeHControl=3
sizeVControl=3
left=140
top=0
End CompInit
clipboardList.name="clipboardList"
clipboardList.visible=1
group9.name="group9"

Dim mouseGroup as group
mouseGroup = MakeComponent("group",tableSpecPropBox)
CompInit mouseGroup
proto="mouseGroup"
caption=""
sizeVControl=1
sizeHControl=2
tileLayout=1
visible=1
End CompInit
Dim mouseLabel as label
mouseLabel = MakeComponent("label",mouseGroup)
CompInit mouseLabel
proto="mouseLabel"
caption="MouseInterest:"
sizeHControl=3
sizeVControl=3
left=10
top=0
visible=1
End CompInit
mouseLabel.name="mouseLabel"
Dim mouseList as list
mouseList = MakeComponent("list",mouseGroup)
CompInit mouseList
proto="mouseList"
look=2
sizeHControl=3
sizeVControl=3
left=140
top=0
End CompInit
mouseList.name="mouseList"
mouseList.visible=1
mouseList.captions[0] = "None"
mouseList.captions[1] = "Enter-Exit"
mouseList.captions[2] = "All"
mouseGroup.name="mouseGroup"

tableSpecPropBox.width=287
tableSpecPropBox.height=338
tableSpecPropBox.name="tableSpecPropBox"
Dim insertQueryDialog as dialog
insertQueryDialog = MakeComponent("dialog","app")
CompInit insertQueryDialog
proto="insertQueryDialog"
left=350
top=200
caption=""
tile=1
tileSpacing=5
type=2
sizeHControl=0
sizeVControl=1
End CompInit
Dim spacer5 as spacer
spacer5 = MakeComponent("spacer",insertQueryDialog)
CompInit spacer5
proto="spacer5"
width=220
height=5
visible=1
End CompInit
spacer5.name="spacer5"
Dim title as label
title = MakeComponent("label",insertQueryDialog)
CompInit title
proto="label6"
caption="Insert"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
title.name="title"
Dim spacer1 as spacer
spacer1 = MakeComponent("spacer",insertQueryDialog)
CompInit spacer1
proto="spacer1"
look=1
width=220
sizeVControl=3
visible=1
End CompInit
spacer1.name="spacer1"
Dim normalQueryGroup as group
normalQueryGroup = MakeComponent("group",insertQueryDialog)
CompInit normalQueryGroup
proto="group16"
caption=""
tileSpacing=5
tile=1
sizeHControl=1
sizeVControl=1
visible=1
End CompInit
Dim group20 as group
group20 = MakeComponent("group",normalQueryGroup)
CompInit group20
proto="group20"
caption=""
height=16
width=220
visible=1
End CompInit
Dim normalWidthOrHeightLabel as label
normalWidthOrHeightLabel = MakeComponent("label",group20)
CompInit normalWidthOrHeightLabel
proto="label7"
left=0
top=2
caption="Row Height:"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
normalWidthOrHeightLabel.name="normalWidthOrHeightLabel"
Dim normalWidthOrHeightEntry as entry
normalWidthOrHeightEntry = MakeComponent("entry",group20)
CompInit normalWidthOrHeightEntry
proto="entry2"
left=140
top=0
width=80
maxChars=5
filter=32
text=""
visible=1
End CompInit
normalWidthOrHeightEntry.name="normalWidthOrHeightEntry"
group20.name="group20"
Dim group21 as group
group21 = MakeComponent("group",normalQueryGroup)
CompInit group21
proto="group21"
caption=""
height=16
width=220
visible=1
End CompInit
Dim normalNumToInsertLabel as label
normalNumToInsertLabel = MakeComponent("label",group21)
CompInit normalNumToInsertLabel
proto="label8"
caption="Number to Insert:"
left=0
top=2
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
normalNumToInsertLabel.name="normalNumToInsertLabel"
Dim normalNumToInsertEntry as entry
normalNumToInsertEntry = MakeComponent("entry",group21)
CompInit normalNumToInsertEntry
proto="entry3"
left=140
top=0
width=80
maxChars=5
filter=32
text=""
visible=1
End CompInit
normalNumToInsertEntry.name="normalNumToInsertEntry"
group21.name="group21"
normalQueryGroup.name="normalQueryGroup"
Dim spacer2 as spacer
spacer2 = MakeComponent("spacer",insertQueryDialog)
CompInit spacer2
proto="spacer2"
width=220
look=1
sizeVControl=3
visible=1
End CompInit
spacer2.name="spacer2"
Dim specialRowQueryGroup as group
specialRowQueryGroup = MakeComponent("group",insertQueryDialog)
CompInit specialRowQueryGroup
proto="group19"
caption=""
height=50
sizeHControl=1
tile=1
tileSpacing=5
visible=1
End CompInit
Dim rowsToggleGroup as group
rowsToggleGroup = MakeComponent("group",specialRowQueryGroup)
CompInit rowsToggleGroup
proto="rowsToggleGroup"
caption=""
height=16
width=220
visible=1
End CompInit
Dim insertRowsToggle as toggle
insertRowsToggle = MakeComponent("toggle",rowsToggleGroup)
CompInit insertRowsToggle
proto="insertRowsToggle"
caption="Insert Rows"
left=0
top=0
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
insertRowsToggle.name="insertRowsToggle"
rowsToggleGroup.name="rowsToggleGroup"
Dim group17 as group
group17 = MakeComponent("group",specialRowQueryGroup)
CompInit group17
proto="group17"
caption=""
height=16
width=220
visible=1
End CompInit
Dim specialHeightLabel as label
specialHeightLabel = MakeComponent("label",group17)
CompInit specialHeightLabel
proto="label9"
caption="Row Height:"
left=0
top=2
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
specialHeightLabel.name="specialHeightLabel"
Dim specialHeightEntry as entry
specialHeightEntry = MakeComponent("entry",group17)
CompInit specialHeightEntry
proto="entry4"
left=140
top=0
width=80
maxChars=5
filter=32
text=""
visible=1
End CompInit
specialHeightEntry.name="specialHeightEntry"
group17.name="group17"
Dim group22 as group
group22 = MakeComponent("group",specialRowQueryGroup)
CompInit group22
proto="group22"
caption=""
height=16
width=220
visible=1
End CompInit
Dim specialRowsToInsertLabel as label
specialRowsToInsertLabel = MakeComponent("label",group22)
CompInit specialRowsToInsertLabel
proto="label10"
caption="Rows to Insert:"
left=0
top=2
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
specialRowsToInsertLabel.name="specialRowsToInsertLabel"
Dim specialRowsToInsertEntry as entry
specialRowsToInsertEntry = MakeComponent("entry",group22)
CompInit specialRowsToInsertEntry
proto="entry5"
left=140
top=0
width=80
maxChars=5
filter=32
text=""
visible=1
End CompInit
specialRowsToInsertEntry.name="specialRowsToInsertEntry"
group22.name="group22"
specialRowQueryGroup.name="specialRowQueryGroup"
Dim spacer3 as spacer
spacer3 = MakeComponent("spacer",insertQueryDialog)
CompInit spacer3
proto="spacer3"
width=220
look=1
sizeVControl=3
visible=1
End CompInit
spacer3.name="spacer3"
Dim specialColumnQueryGroup as group
specialColumnQueryGroup = MakeComponent("group",insertQueryDialog)
CompInit specialColumnQueryGroup
proto="group24"
caption=""
tileSpacing=5
tile=1
sizeHControl=1
sizeVControl=1
visible=1
End CompInit
Dim columnsToggleGroup as group
columnsToggleGroup = MakeComponent("group",specialColumnQueryGroup)
CompInit columnsToggleGroup
proto="columnsToggleGroup"
caption=""
height=16
width=220
visible=1
End CompInit
Dim insertColumnsToggle as toggle
insertColumnsToggle = MakeComponent("toggle",columnsToggleGroup)
CompInit insertColumnsToggle
proto="insertColumnsToggle"
caption="Insert Columns"
left=0
top=0
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
insertColumnsToggle.name="insertColumnsToggle"
columnsToggleGroup.name="columnsToggleGroup"
Dim group26 as group
group26 = MakeComponent("group",specialColumnQueryGroup)
CompInit group26
proto="group26"
caption=""
height=16
width=220
visible=1
End CompInit
Dim specialWidthLabel as label
specialWidthLabel = MakeComponent("label",group26)
CompInit specialWidthLabel
proto="label11"
caption="Column Width:"
left=0
top=2
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
specialWidthLabel.name="specialWidthLabel"
Dim specialWidthEntry as entry
specialWidthEntry = MakeComponent("entry",group26)
CompInit specialWidthEntry
proto="entry6"
left=140
top=0
width=80
maxChars=5
filter=32
text=""
visible=1
End CompInit
specialWidthEntry.name="specialWidthEntry"
group26.name="group26"
Dim group27 as group
group27 = MakeComponent("group",specialColumnQueryGroup)
CompInit group27
proto="group27"
caption=""
height=16
width=220
visible=1
End CompInit
Dim specialColumnsToInsertLabel as label
specialColumnsToInsertLabel = MakeComponent("label",group27)
CompInit specialColumnsToInsertLabel
proto="label12"
caption="Columns to Insert:"
left=0
top=2
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
specialColumnsToInsertLabel.name="specialColumnsToInsertLabel"
Dim specialColumnsToInsertEntry as entry
specialColumnsToInsertEntry = MakeComponent("entry",group27)
CompInit specialColumnsToInsertEntry
proto="specialColumnsToInsertEntry"
left=140
top=0
width=80
maxChars=5
filter=32
text=""
visible=1
End CompInit
specialColumnsToInsertEntry.name="specialColumnsToInsertEntry"
group27.name="group27"
specialColumnQueryGroup.name="specialColumnQueryGroup"
Dim spacer4 as spacer
spacer4 = MakeComponent("spacer",insertQueryDialog)
CompInit spacer4
proto="spacer4"
width=220
look=1
sizeVControl=3
visible=1
End CompInit
spacer4.name="spacer4"
Dim group28 as group
group28 = MakeComponent("group",insertQueryDialog)
CompInit group28
proto="group28"
caption=""
tileLayout=1
tile=1
tileSpacing=10
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
Dim insertQueryCancelButton as button
insertQueryCancelButton = MakeComponent("button",group28)
CompInit insertQueryCancelButton
proto="cancelButton"
caption="Cancel"
sizeHControl=3
sizeVControl=3
cancel=1
visible=1
End CompInit
insertQueryCancelButton.name="insertQueryCancelButton"
Dim insertQueryOKButton as button
insertQueryOKButton = MakeComponent("button",group28)
CompInit insertQueryOKButton
proto="OKButton"
caption="OK"
sizeHControl=3
sizeVControl=3
default=1
visible=1
End CompInit
insertQueryOKButton.name="insertQueryOKButton"
group28.name="group28"
Dim spacer7 as spacer
spacer7 = MakeComponent("spacer",insertQueryDialog)
CompInit spacer7
proto="spacer7"
width=220
height=5
visible=1
End CompInit
spacer7.name="spacer7"
insertQueryDialog.name="insertQueryDialog"
insertQueryDialog.width=240
insertQueryDialog.height=320
Dim warningDialog as dialog
warningDialog = MakeComponent("dialog","app")
CompInit warningDialog
proto="dialog1"
left=299
top=354
caption=""
type=2
tile=1
tileSpacing=5
tileHInset=20
tileVInset=20
End CompInit
Dim label100 as label
label100 = MakeComponent("label",warningDialog)
CompInit label100
proto="label100"
caption="Warning!"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
label100.name="label100"
Dim spacer100 as spacer
spacer100 = MakeComponent("spacer",warningDialog)
CompInit spacer100
proto="spacer100"
sizeHControl=2
sizeVControl=1
look=1
visible=1
End CompInit
spacer100.name="spacer100"
Dim warningTextBox as text
warningTextBox = MakeComponent("text",warningDialog)
CompInit warningTextBox
proto="text2"
width=250
readOnly=1
sizeVControl=1
wordWrap=1
End CompInit
warningTextBox.name="warningTextBox"
warningTextBox.visible=1
Dim warningDialogOKButton as button
warningDialogOKButton = MakeComponent("button",warningDialog)
CompInit warningDialogOKButton
proto="OKButton"
caption="OK"
sizeHControl=3
sizeVControl=3
default=1
visible=1
End CompInit
warningDialogOKButton.name="warningDialogOKButton"
warningDialog.height=126
warningDialog.width=258
warningDialog.name="warningDialog"
Dim changeQueryDialog as dialog
changeQueryDialog = MakeComponent("dialog","app")
CompInit changeQueryDialog
proto="dialog3"
left=350
top=100
caption=""
tile=1
tileVInset=5
tileSpacing=5
type=2
End CompInit
Dim spacer8 as spacer
spacer8 = MakeComponent("spacer",changeQueryDialog)
CompInit spacer8
proto="spacer8"
width=220
height=5
visible=1
End CompInit
spacer8.name="spacer8"
Dim changeQueryDialogTitle as label
changeQueryDialogTitle = MakeComponent("label",changeQueryDialog)
CompInit changeQueryDialogTitle
proto="changeQueryDialogTitle"
caption="Change Rows"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
changeQueryDialogTitle.name="changeQueryDialogTitle"
Dim spacer9 as spacer
spacer9 = MakeComponent("spacer",changeQueryDialog)
CompInit spacer9
proto="spacer9"
width=220
look=1
sizeVControl=3
visible=1
End CompInit
spacer9.name="spacer9"
Dim group23 as group
group23 = MakeComponent("group",changeQueryDialog)
CompInit group23
proto="group23"
caption=""
height=16
width=220
visible=1
End CompInit
Dim changeQueryDialogLabel as label
changeQueryDialogLabel = MakeComponent("label",group23)
CompInit changeQueryDialogLabel
proto="label14"
caption="Row Height:"
left=0
top=2
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
changeQueryDialogLabel.name="changeQueryDialogLabel"
Dim changeQueryDialogEntry as entry
changeQueryDialogEntry = MakeComponent("entry",group23)
CompInit changeQueryDialogEntry
proto="entry8"
left=140
top=0
width=80
maxChars=5
filter=32
text=""
visible=1
End CompInit
changeQueryDialogEntry.name="changeQueryDialogEntry"
group23.name="group23"
Dim spacer10 as spacer
spacer10 = MakeComponent("spacer",changeQueryDialog)
CompInit spacer10
proto="spacer10"
width=220
look=1
sizeVControl=3
visible=1
End CompInit
spacer10.name="spacer10"
Dim group24 as group
group24 = MakeComponent("group",changeQueryDialog)
CompInit group24
proto="group24"
caption=""
tileLayout=1
tile=1
tileSpacing=10
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
Dim button7 as button
button7 = MakeComponent("button",group24)
CompInit button7
proto="cancelButton"
caption="Cancel"
sizeHControl=3
sizeVControl=3
cancel=1
visible=1
End CompInit
button7.name="button7"
Dim button8 as button
button8 = MakeComponent("button",group24)
CompInit button8
proto="OKButton"
caption="OK"
sizeHControl=3
sizeVControl=3
default=1
visible=1
End CompInit
button8.name="button8"
group24.name="group24"
Dim spacer11 as spacer
spacer11 = MakeComponent("spacer",changeQueryDialog)
CompInit spacer11
proto="spacer11"
height=5
width=220
visible=1
End CompInit
spacer11.name="spacer11"
changeQueryDialog.name="changeQueryDialog"
changeQueryDialog.width=240
changeQueryDialog.height=125
EnableEvents()
duplo_start()
end sub

sub duplo_start()

REM
REM Define structs.
REM

    struct InsertInfo
      dim rowsToAdd as integer
      dim columnsToAdd as integer
      dim rowHeight as integer
      dim columnWidth as integer
    end struct

    struct NumberInfo
      dim valid as integer
      dim value as integer
      dim overflow as integer
    end struct

REM
REM Initialize lists.
REM

    selectionList.captions[0] = "Not Selectable"
    selectionList.captions[1] = "Select Cell"
    selectionList.captions[2] = "Select Row"
    selectionList.captions[3] = "Select Column"
    selectionList.captions[4] = "Select Drag Area"
    selectionList.captions[5] = "Custom Selection"

    lookList.captions[0] = "Record List"
    lookList.captions[1] = "Dotted Cells"
    lookList.captions[2] = "Dotted Horizontal Lines"
    lookList.captions[3] = "Blank"

    const FOCUSABLE	 0
    const CLIPBOARDABLE	 1
    const DELETABLE	 2
    const COPYABLE	 3
    
    clipboardList.captions[FOCUSABLE]	   = "Focusable"
    clipboardList.captions[CLIPBOARDABLE]  = "Clipboardable"
    clipboardList.captions[DELETABLE]	   = "Deletable"
    clipboardList.captions[COPYABLE]	   = "Copyable"

REM
REM The targetTable variable refers to the table we are editing
REM (the table passed in the most recent call to 
REM tableSpecPropBox_update).
REM

REM this needs to be a component, not a table, as we dont want byte compiled
REM properties, because BENT needs to catch the MSG_ENT_SET_PROOERTY to update
REM its list of properties it needs to spit out
  dim targetTable as component
  
REM
REM The modalSync variable is used for synchronization when a modal dialog is
REM shown.  We use it to ensure that only code for the modal dialog is
REM interpreted once the dialog is shown.  It can take the following
REM values:
REM	0    wait
REM	1    continue
REM

  dim modalSync as integer
    modalSync = 0

REM
REM The modalReturn variable indicates which of the dismissal buttons
REM in a modal dialog was pressed.  It can have the following values.
REM	0    cancel
REM	1    okay
REM

  dim modalReturn as integer

REM
REM Warning messages.
REM

  dim warnEmptyWidth as string
    warnEmptyWidth = "You must enter a width between 0 and 1024 in the Column Width field."

  dim warnWidthTooBig as string
    warnWidthTooBig = "The value of the Column Width field is too big.	It will be set to its maximum of 1024."

  dim warnEmptyHeight as string
    warnEmptyHeight = "You must enter a height between 0 and 1024 in the Row Height field."

  dim warnHeightTooBig as string
    warnHeightTooBig = "The value of the Row Height field is too big.  It will be set to its maximum of 1024."

  dim warnEmptyRowsToInsert as string
    warnEmptyRowsToInsert = "You must enter a value in the Rows to Insert field."

  dim warnEmptyColumnsToInsert as string
    warnEmptyColumnsToInsert = "You must enter a value in the Columns to Insert field."

  dim warnTooManyRows as string
    warnTooManyRows = "You are trying to add too many rows.  The maximum total number of rows allowed is 3999.	The Rows to Insert field will be set to the maximium allowed."

  dim warnTooManyColumns as string
    warnTooManyColumns = "You are trying to add too many columns.  The maximum total number of columns allowed is 3999.	 The Columns to Insert field will be set to the maximium allowed."

  dim warnInvalidDefaultRowHeight as string
    warnInvalidDefaultRowHeight = "You should enter an integer between 0 and 1024 for the Default Row Height field.  The previous value will be applied."
    
end sub

sub tableSpecPropBox_update(current as table)

REM ********************************************************************
REM			tableSpecPropBox_update
REM ********************************************************************
REM
REM SYNOPSIS:	Updates the properties in the property box using the
REM		given table component.
REM
REM CALLED BY:	the builder
REM 
REM ********************************************************************


REM
REM Set targetTable.
REM

    targetTable = current

REM
REM Update Initial Rows and Columns editor.
REM

    horizSelector.numColumns = targetTable.numColumns
    vertSelector.numRows = targetTable.numRows

    initialTable.numRows = targetTable.numRows
    initialTable.numColumns = targetTable.numColumns

    copyTargetTableArraysToEditor()

    REM
    REM Clear the selection.
    REM

    horizSelector.selectionType = horizSelector.selectionType
    vertSelector.selectionType = vertSelector.selectionType

    syncTableEditorUIWithState()


REM
REM Update Default Row Height.
REM

  dim floatVal as float
    floatVal = targetTable.defaultRowHeight
    defaultRowHeightEntry.text = Str(floatVal)

REM
REM Update Selection Type and mouseInterest
REM

    selectionList.selectedItem = targetTable.selectionType
    mouseList.selectedItem = targetTable.mouseInterest
    REM update enabled status of mouseList based on selectionType
    selectionList_changed(selectionList, selectionList.selectedItem)

REM
REM Update Look.
REM

    lookList.selectedItem = targetTable.look

REM
REM Update Clipboardable API.
REM

    clipboardList.selections[FOCUSABLE] = targetTable.focusable
    clipboardList.selections[CLIPBOARDABLE] = targetTable.clipboardable
    clipboardList.selections[DELETABLE] = targetTable.deletable
    clipboardList.selections[COPYABLE] = targetTable.copyable

end sub

sub sp_apply()

REM ********************************************************************
REM			      sp_apply
REM ********************************************************************
REM
REM SYNOPSIS:	Applies the properties in the properties box to the
REM		current table component (targetTable).
REM
REM CALLED BY:	the builder
REM 
REM ********************************************************************

REM
REM Apply initial rows.
REM

    targetTable.numRows = vertSelector.numRows

  dim i as integer
    for i = 0 to vertSelector.numRows - 1
	targetTable.rowHeights[i] = vertSelector.rowHeights[i]
    next i

REM
REM Apply initial columns.
REM

    targetTable.numColumns = horizSelector.numColumns

    for i = 0 to horizSelector.numColumns - 1
	targetTable.columnWidths[i] = horizSelector.columnWidths[i]
    next i

REM
REM Apply defaultRowHeight.
REM

  dim numberInfo as struct NumberInfo
    numberInfo = processNonNegativeInt(defaultRowHeightEntry.text)

    if (numberInfo.valid = 0) or (numberInfo.overflow = 1) or (numberInfo.value > 1024)

	warnUser(warnInvalidDefaultRowHeight)
	
      dim floatVal as float
	floatVal = targetTable.defaultRowHeight
	defaultRowHeightEntry.text = Str(floatVal)

    else
	targetTable.defaultRowHeight = numberInfo.value
    end if

REM
REM Apply selectionType and mouseInterest -- mouseInterest must come after
REM selectionType.
REM

    targetTable.selectionType = selectionList.selectedItem
    if (targetTable.selectionType = 5) then
	targetTable.mouseInterest = mouseList.selectedItem
    end if

REM
REM Apply look.
REM

    targetTable.look = lookList.selectedItem

REM
REM Apply clipboardable API.
REM

    targetTable.focusable = clipboardList.selections[FOCUSABLE]
    targetTable.clipboardable = clipboardList.selections[CLIPBOARDABLE]
    targetTable.deletable = clipboardList.selections[DELETABLE]
    targetTable.copyable = clipboardList.selections[COPYABLE]

end sub

function duplo_top() as component

REM ********************************************************************
REM			     duplo_top
REM ********************************************************************
REM
REM SYNOPSIS:	Return the name of the top-level component for the 
REM		properties box.
REM
REM CALLED BY:	the builder
REM 
REM ********************************************************************

    duplo_top = tableSpecPropBox
end function

sub selectionList_changed(self as list, index as integer)
  dim newStatus as integer
    if (index = 5) then
	newStatus = 1
    else
	newStatus = 0
    end if

    if (mouseList.enabled <> newStatus) then
	mouseList.enabled = newStatus
    end if
end sub

sub copyTargetTableArraysToEditor()

REM ********************************************************************
REM		     copyTargetTableArraysToEditor
REM ********************************************************************

REM
REM Copy rowHeights.
REM

  dim i as integer
    for i = 0 to targetTable.numRows - 1
	initialTable.rowHeights[i] = targetTable.rowHeights[i]
	vertSelector.rowHeights[i] = targetTable.rowHeights[i]
    next i

REM
REM Copy columnWidth.
REM

    for i = 0 to targetTable.numColumns - 1
	initialTable.columnWidths[i] = targetTable.columnWidths[i]
	horizSelector.columnWidths[i] = targetTable.columnWidths[i]
    next i

end sub

sub horizSelector_selectionChanged(self as table)

REM ********************************************************************
REM		     horizSelector_selectionChanged
REM ********************************************************************

    REM
    REM Clear the row selection.
    REM

    vertSelector.selectionType = vertSelector.selectionType

    syncTableEditorUIWithState()

end sub

sub vertSelector_selectionChanged(self as table)

REM ********************************************************************
REM		     vertSelector_selectionChanged
REM ********************************************************************

    REM
    REM Clear the column selection.
    REM

    horizSelector.selectionType = horizSelector.selectionType

    syncTableEditorUIWithState()

end sub

sub insertButton_pressed(self as button)

REM ********************************************************************
REM			insertButton_pressed
REM ********************************************************************

REM
REM Run the insert dialog.
REM
REM The insert dialog is configured according to two factors: the
REM selection and the number of rows and columns.  The parameters
REM indicate whether the dialog should ask about rows and columns.
REM They also indicate whether special questions should be asked if
REM there are either no rows or columns.
REM

  dim insertInfo as struct InsertInfo

    if (horizSelector.numColumns = 0)
	if (vertSelector.numRows = 0)
	    insertInfo = runInsertQueryDialog(0, 1, 1)
	else if (vertSelector.leftColumn <> -1)
	    insertInfo = runInsertQueryDialog(1, 0, 1)
	else
	    insertInfo = runInsertQueryDialog(0, 0, 1)
	end if
    else if (vertSelector.numRows = 0)
	if (horizSelector.leftColumn <> -1)
	    insertInfo = runInsertQueryDialog(2, 1, 0)
	else
	    insertInfo = runInsertQueryDialog(0, 1, 0)
	end if
    else if (horizSelector.leftColumn <> -1)
	insertInfo = runInsertQueryDialog(2, 0, 0)
    else	
	insertInfo = runInsertQueryDialog(1, 0, 0)
    end if

REM
REM Insert rows and columns.
REM

    insertRows(insertInfo.rowsToAdd, insertInfo.rowHeight)
    insertColumns(insertInfo.columnsToAdd, insertInfo.columnWidth)

REM
REM Sync the UI.
REM
    syncTableEditorUIWithState()

end sub


sub insertColumns(howMany as integer, width as integer)

REM ********************************************************************
REM			  insertColumns
REM ********************************************************************
REM
REM SYNOPSIS:	Insert columns into the initialTable and horizSelector
REM		at the first position in the column selection.
REM
REM STRATEGY:	1. Add columns to the end.
REM		2. Shift columns to the right.
REM		3. Set the widths of the appropriate columns.
REM
REM ********************************************************************

  dim startColumn as integer
  dim endColumn as integer
  dim i as integer

    if howMany <> 0

	REM
	REM Add columns to the end.
	REM

	horizSelector.numColumns = horizSelector.numColumns + howMany
	initialTable.numColumns = initialTable.numColumns + howMany
	
	REM
	REM Shift columns to the right.
	REM

	if horizSelector.numColumns = 1
	    startColumn = 0
	else
	    startColumn = horizSelector.leftColumn
	end if

	endColumn = horizSelector.numColumns - howMany - 1
    
	for i = endColumn to startColumn step -1

	    horizSelector.columnWidths[i + howMany] = horizSelector.columnWidths[i]


	    initialTable.columnWidths[i + howMany] = initialTable.columnWidths[i]

	next i

	REM
	REM Set the widths of the appropriate columns.
	REM
	
	endColumn = startColumn + howMany - 1
	for i = startColumn to endColumn
	    horizSelector.columnWidths[i] = width
	    initialTable.columnWidths[i] = width
	next i
	
    end if

end sub

sub insertRows(howMany as integer, height as integer)

REM ********************************************************************
REM			  insertRows
REM ********************************************************************
REM
REM SYNOPSIS:	Insert rows into the initialTable and vertSelector
REM		at the first position in the row selection.
REM
REM STRATEGY:	1. Add rows to the end.
REM		2. Shift rows down.
REM		3. Set the heights of the appropriate rows.
REM
REM ********************************************************************

  dim startRow as integer
  dim endRow as integer
  dim i as integer

    if howMany <> 0

	REM
	REM Add rows to the end.
	REM

	vertSelector.numRows = vertSelector.numRows + howMany
	initialTable.numRows = initialTable.numRows + howMany

	REM
	REM Shift rows down.
	REM

	if vertSelector.numRows = 1
	    startRow = 0
	else
	    startRow = vertSelector.topRow
	end if

	endRow = vertSelector.numRows - howMany - 1
    
	for i = endRow to startRow step -1

	    vertSelector.rowHeights[i + howMany] = vertSelector.rowHeights[i]


	    initialTable.rowHeights[i + howMany] = initialTable.rowHeights[i]

	next i
	
	REM
	REM Set the heights of the appropriate rows.
	REM

	endRow = startRow + howMany - 1
	for i = startRow to endRow
	    vertSelector.rowHeights[i] = height
	    initialTable.rowHeights[i] = height
	next i

    end if

end sub

sub deleteButton_pressed(self as button)

REM ********************************************************************
REM			 deleteButton_pressed
REM ********************************************************************
REM
REM SYNOPSIS:	Delete selected rows or columns from the selectors and 
REM		initialTable.
REM
REM ********************************************************************

  dim i as integer
  dim selectCount as integer

    if horizSelector.leftColumn <> -1

REM
REM Delete columns.
REM

	selectCount = horizSelector.rightColumn - horizSelector.leftColumn + 1

	REM
	REM Shift columns left.
	REM

	i = horizSelector.leftColumn
	do while i + selectCount < horizSelector.numColumns

	    horizSelector.columnWidths[i] = horizSelector.columnWidths[i + selectCount]

	    initialTable.columnWidths[i] = initialTable.columnWidths[i + selectCount]
	    
	    i = i + 1
	loop

	REM
	REM Delete columns from the end.
	REM

	horizSelector.numColumns = horizSelector.numColumns - selectCount
	initialTable.numColumns = initialTable.numColumns - selectCount

    else if vertSelector.leftColumn <> -1

REM
REM Delete rows.
REM

	selectCount = vertSelector.bottomRow - vertSelector.topRow + 1

	REM
	REM Shift rows up.
	REM

	i = vertSelector.topRow
	do while i + selectCount < vertSelector.numRows

	    vertSelector.rowHeights[i] = vertSelector.rowHeights[i + selectCount]

	    initialTable.rowHeights[i] = initialTable.rowHeights[i + selectCount]
	    
	    i = i + 1
	loop

	REM
	REM Delete rows from the end.
	REM

	vertSelector.numRows = vertSelector.numRows - selectCount
	initialTable.numRows = initialTable.numRows - selectCount

    end if

REM
REM Sync the UI.
REM
    syncTableEditorUIWithState()

end sub

sub changeButton_pressed(self as button)

REM ********************************************************************
REM			 deleteButton_pressed
REM ********************************************************************
REM
REM SYNOPSIS:	For the selected rows/columns, change the height/width
REM		in the vertSelector/horizSelector and initialTable.
REM
REM ********************************************************************

  dim newWidthOrHeight as integer
  dim i as integer

    if horizSelector.leftColumn <> -1

	newWidthOrHeight = runChangeQueryDialog(0)

	if newWidthOrHeight <> -1
	    for i = horizSelector.leftColumn to horizSelector.rightColumn
		horizSelector.columnWidths[i] = newWidthOrHeight
		initialTable.columnWidths[i] = newWidthOrHeight
	    next i
	end if
	    
    else

	newWidthOrHeight = runChangeQueryDialog(1)

	if newWidthOrHeight <> -1
	    for i = vertSelector.topRow to vertSelector.bottomRow
		vertSelector.rowHeights[i] = newWidthOrHeight
		initialTable.rowHeights[i] = newWidthOrHeight
	    next i
	end if

    end if


REM
REM Sync the UI.
REM
    syncTableEditorUIWithState()

end sub

sub syncTableEditorUIWithState()

REM ********************************************************************
REM			syncTableEditorUIWithState
REM ********************************************************************
REM
REM SYNOPSIS:	Ensure that user inteface elements in the table
REM             editor reflect the state of the initialTable.
REM
REM ********************************************************************

REM
REM Update buttons.
REM

    if (horizSelector.leftColumn = -1) and (vertSelector.leftColumn = -1)
	if (horizSelector.numColumns = 0) or (vertSelector.numRows = 0)
	    insertButton.enabled = 1
	else
	    insertButton.enabled = 0
	end if

	deleteButton.enabled = 0
	changeButton.enabled = 0
    else
	insertButton.enabled = 1
	deleteButton.enabled = 1
	changeButton.enabled = 1
    end if

REM
REM Turn off selection for selectors if they are empty.
REM

    if (horizSelector.numColumns = 0)
	horizSelector.selectionType = 0
    else if (horizSelector.selectionType <> 4)
	horizSelector.selectionType = 4
    end if
	
    if (vertSelector.numRows = 0)
	vertSelector.selectionType = 0
    else if (vertSelector.selectionType <> 4)
	vertSelector.selectionType = 4
    end if

REM
REM Update horizScroll.
REM

  dim right as integer

    if (horizSelector.numColumns = 0)
	right = 0
    else
      dim lastColumn as integer
	lastColumn = horizSelector.numColumns - 1
	
	right = horizSelector!GetXPosAt(lastColumn) + horizSelector.columnWidths[lastColumn]
    end if

    if right = 0
	right = 1
    end if

    horizScroll.maximum = right
    horizScroll.thumbSize = horizClipper.width
    horizScroll.increment = 10

REM
REM Update vertScroll.
REM

  dim bottom as integer

    REM GetYPosAt does not seem to work properly.
    REM Add one in order to make sure that the bottom is visible.
    bottom = vertSelector.overallHeight + 1
    
    vertScroll.maximum = bottom
    vertScroll.thumbSize = vertClipper.height
    vertScroll.increment = 10

end sub

sub modalWait()

REM ********************************************************************
REM			       modalWait
REM ********************************************************************
REM
REM SYNOPSIS:	Wait in a loop (until a modal dialog is dismissed).
REM
REM CALLED BY:	general purpose
REM 
REM ********************************************************************

    do while (modalSync = 0)
    loop

    modalSync = 0
end sub

function runInsertQueryDialog(normalQuery as integer, specialRowQuery as integer, specialColumnQuery as integer) as struct InsertInfo

REM ********************************************************************
REM                        runInsertQueryDialog
REM ********************************************************************
REM
REM SYNOPSIS:	Run the insert query dialog and return info for
REM             insert operation.
REM
REM NOTES:
REM
REM     The insert query dialog is configured according to two
REM     factors: the selection and the number of rows and columns.
REM     The parameters indicate whether the dialog should ask about
REM     rows and columns.  They also indicate whether special
REM     questions should be asked if there are either no rows or
REM     columns.
REM
REM ********************************************************************

REM
REM Set up the components for this query.
REM

    setupInsertQueryDialogComponents(normalQuery, specialRowQuery, specialColumnQuery)

REM
REM Center the dialog.
REM

  dim left as integer
  dim top as integer

    left = (640 - insertQueryDialog.width) / 2
    top = (480 - insertQueryDialog.height) / 2

    insertQueryDialog.left = left
    insertQueryDialog.top = top


REM
REM Show the dialog.
REM

    insertQueryDialog.visible = 1

REM
REM Wait until valid input is entered or the dialog is canceled.
REM

  dim return as struct InsertInfo
    runInsertQueryDialog = return

  dim dialogDone as integer
    dialogDone = 0

    do
	modalWait()
	if modalReturn = 1
	    if processInsertQueryDialogEntries(normalQuery, runInsertQueryDialog) = 1
		dialogDone = 1
	    end if
	else
	    dialogDone = 1
	end if
    loop until dialogDone = 1

REM
REM Hide the dialog.
REM

    insertQueryDialog.visible = 0

end function

function processInsertQueryDialogEntries(normalQuery as integer, insertInfo as struct InsertInfo) as integer

REM ********************************************************************
REM                   processInsertQueryDialogEntries
REM ********************************************************************
REM
REM SYNOPSIS:	Check to make sure that all of the entries in
REM             the insert query dialog contain valid text.
REM
REM ********************************************************************

    processInsertQueryDialogEntries = 1

  dim checkReturn as integer

REM
REM Process normalWidthOrHeightEntry
REM
    
    if normalQuery = 1
	checkReturn = checkWidthOrHeight(normalWidthOrHeightEntry, warnEmptyHeight, warnHeightTooBig)

	if checkReturn = -1
	    processInsertQueryDialogEntries = 0
	else
	    insertInfo.rowHeight = checkReturn
	end if
    else if normalQuery = 2
	checkReturn = checkWidthOrHeight(normalWidthOrHeightEntry, warnEmptyWidth, warnWidthTooBig)

	if checkReturn = -1
	    processInsertQueryDialogEntries = 0
	else
	    insertInfo.columnWidth = checkReturn
	end if
    end if

REM
REM Process normalNumToInsertEntry
REM

    if normalQuery = 1
	checkReturn = checkNumberToInsert(normalNumToInsertEntry, warnEmptyRowsToInsert, warnTooManyRows)

	if checkReturn = -1
	    processInsertQueryDialogEntries = 0
	else
	    insertInfo.rowsToAdd = checkReturn
	end if
    else if normalQuery = 2
	checkReturn = checkNumberToInsert(normalNumToInsertEntry, warnEmptyColumnsToInsert, warnTooManyColumns)

	if checkReturn = -1
	    processInsertQueryDialogEntries = 0
	else
	    insertInfo.columnsToAdd = checkReturn
	end if
    end if

REM
REM Process specialHeightEntry
REM

    if specialRowQueryGroup.visible = 1 and specialHeightLabel.enabled = 1
	checkReturn = checkWidthOrHeight(specialHeightEntry, warnEmptyHeight, warnHeightTooBig)

	if checkReturn = -1
	    processInsertQueryDialogEntries = 0
	else
	    insertInfo.rowHeight = checkReturn
	end if
    end if

REM
REM Process specialRowsToInsertEntry
REM

    if specialRowQueryGroup.visible = 1 and specialHeightLabel.enabled = 1
	checkReturn = checkNumberToInsert(specialRowsToInsertEntry, warnEmptyRowsToInsert, warnTooManyRows)

	if checkReturn = -1
	    processInsertQueryDialogEntries = 0
	else
	    insertInfo.rowsToAdd = checkReturn
	end if
    end if

REM
REM Process specialWidthEntry
REM

    if specialColumnQueryGroup.visible = 1 and specialWidthLabel.enabled = 1
	checkReturn = checkWidthOrHeight(specialWidthEntry, warnEmptyWidth, warnWidthTooBig)

	if checkReturn = -1
	    processInsertQueryDialogEntries = 0
	else
	    insertInfo.columnWidth = checkReturn
	end if
    end if

REM
REM Process specialColumnsToInsertEntry
REM

    if specialColumnQueryGroup.visible = 1 and specialWidthLabel.enabled = 1
	checkReturn = checkNumberToInsert(specialColumnsToInsertEntry, warnEmptyColumnsToInsert, warnTooManyColumns)

	if checkReturn = -1
	    processInsertQueryDialogEntries = 0
	else
	    insertInfo.columnsToAdd = checkReturn
	end if
    end if

end function

sub warnUser(message as string)

REM ********************************************************************
REM				warnUser
REM ********************************************************************
REM
REM SYNOPSIS:	Show a modal dialog with a warning message and "OK"
REM		button.
REM
REM CALLED BY:	general purpose
REM 
REM ********************************************************************

REM
REM Setup text box.
REM

    warningTextBox.text = message

    REM
    REM It would be better if we determined the necessary height by 
    REM checking the numLines property of the text component.
    REM Unfortunately, the text component does not calculate the
    REM numLines until it is visible.  We use 60, which is big
    REM enough for all warning messages.
    REM

    warningTextBox.height = 60

  dim left as integer
  dim top as integer

REM
REM Center the dialog.
REM

    left = (640 - warningDialog.width) / 2
    top = (480 - warningDialog.height) / 2

    warningDialog.left = left
    warningDialog.top = top

REM
REM Show the dialog.
REM

    warningDialog.visible = 1

REM
REM Wait until the "OK" button is pressed.
REM

    modalWait()

REM
REM Hide the dialog.
REM

    warningDialog.visible = 0

end sub

function checkWidthOrHeight(entry as entry, emptyWarning as string, tooBigWarning as string) as integer

REM ********************************************************************
REM			   checkWidthOrHeight
REM ********************************************************************
REM
REM SYNOPSIS:	Check a width or height entry in the insert query
REM             dialog.  
REM
REM ********************************************************************

    if entry.text = ""
	checkWidthOrHeight = -1

	warnUser(emptyWarning)
    else 

      dim floatVal as float
      dim longVal as long

	floatVal = Val(entry.text)
	longVal = floatVal

	if longVal > 1024
	    checkWidthOrHeight = -1

	    warnUser(tooBigWarning)
	    
	    longVal = 1024
	    floatVal = longVal
	    
	    entry.text = Str(floatVal)
	else
	    checkWidthOrHeight = longVal
	end if
    end if

end function

function checkNumberToInsert(entry as entry, emptyWarning as string, tooManyWarning as string) as integer

REM ********************************************************************
REM			   checkNumberToInsert
REM ********************************************************************
REM
REM SYNOPSIS:	Check either a "Rows to Insert" or "Columns to Insert"
REM             entry in the insert query dialog.
REM
REM ********************************************************************

    if entry.text = ""
	checkNumberToInsert = -1

	warnUser(emptyWarning)
    else 

      dim floatVal as float
      dim longVal as long

	floatVal = Val(entry.text)
	longVal = floatVal

	if longVal + horizSelector.numColumns > 3999
	    checkNumberToInsert = -1

	    warnUser(tooManyWarning)
	    
	    longVal = 3999 - horizSelector.numColumns
	    floatVal = longVal

	    entry.text = Str(floatVal)
	else
	    checkNumberToInsert = longVal
	end if
    end if

end function

sub setupInsertQueryDialogComponents(normalQuery as integer, specialRowQuery as integer, specialColumnQuery as integer)

REM ********************************************************************
REM                   setupInsertQueryDialogComponents
REM ********************************************************************
REM
REM SYNOPSIS:	Configure the components of the insert-query dialog.
REM
REM NOTES:
REM
REM     The insert query dialog is configured according to two
REM     factors: the selection and the number of rows and columns.
REM     The parameters indicate whether the dialog should ask about
REM     rows and columns.  They also indicate whether special
REM     questions should be asked if there are either no rows or
REM     columns.
REM
REM ********************************************************************

  dim floatVal as float
  dim intVal as integer

REM
REM Configure the normal-query group.
REM
REM Normal queries are when neither the number of rows or columns
REM is zero.
REM

    select case normalQuery
      case 0	REM No normal query.
	spacer2.visible = 0
	normalQueryGroup.visible = 0
      case 1	REM Normal query about rows.
	normalQueryGroup.visible = 1
	normalWidthOrHeightLabel.caption = "Row Height:"
	normalNumToInsertLabel.caption = "Rows to Insert:"

	normalWidthOrHeightEntry.text = defaultRowHeightEntry.text
	normalNumToInsertEntry.text = numberCellsSelectedString(0)

      case 2	REM Normal query about columns.
	normalQueryGroup.visible = 1
	normalWidthOrHeightLabel.caption = "Column Width:"
	normalNumToInsertLabel.caption = "Columns to Insert:"

	normalWidthOrHeightEntry.text = "30"
	normalNumToInsertEntry.text = numberCellsSelectedString(1)
    end select

REM
REM Configure the special-row-query group.
REM
REM The special row query occurs when the number of rows is zero.
REM
    select case specialRowQuery
      case 0
	spacer2.visible = 0
	specialRowQueryGroup.visible = 0
      case 1
	if normalQuery <> 0
	    spacer2.visible = 1
	else
	    spacer2.visible = 0
	end if
	
	if (normalQuery = 0)
	    rowsToggleGroup.visible = 0
	    specialHeightLabel.enabled = 1
	    specialHeightEntry.enabled = 1
	    specialRowsToInsertLabel.enabled = 1
	    specialRowsToInsertEntry.enabled = 1
	else
	    rowsToggleGroup.visible = 1
	    insertRowsToggle.status = 0
	    specialHeightLabel.enabled = 0
	    specialHeightEntry.enabled = 0
	    specialRowsToInsertLabel.enabled = 0
	    specialRowsToInsertEntry.enabled = 0
	end if

	specialHeightEntry.text = defaultRowHeightEntry.text
	specialRowsToInsertEntry.text = numberCellsSelectedString(0)

	specialRowQueryGroup.visible = 1
    end select

REM
REM Configure the special-column-query group.
REM
REM The special column query occurs when the number of columns is zero.
REM
    select case specialColumnQuery
      case 0
	spacer3.visible = 0
	specialColumnQueryGroup.visible = 0
      case 1
	if (normalQuery <> 0) or (specialRowQuery = 1)
	    spacer3.visible = 1
	else
	    spacer3.visible = 0
	end if

	if (normalQuery = 0)
	    columnsToggleGroup.visible = 0
	    specialWidthLabel.enabled = 1
	    specialWidthEntry.enabled = 1
	    specialColumnsToInsertLabel.enabled = 1
	    specialColumnsToInsertEntry.enabled = 1
	else
	    columnsToggleGroup.visible = 1
	    insertColumnsToggle.status = 0
	    specialWidthLabel.enabled = 0
	    specialWidthEntry.enabled = 0
	    specialColumnsToInsertLabel.enabled = 0
	    specialColumnsToInsertEntry.enabled = 0
	end if
	
	specialWidthEntry.text = "30"
	specialColumnsToInsertEntry.text = numberCellsSelectedString(1)

	specialColumnQueryGroup.visible = 1
    end select

REM
REM Set the title of the insert-query dialog.
REM

    if normalQuery = 1
	title.caption = "Insert Rows"
    else if normalQuery = 2
	title.caption = "Insert Columns"
    else if specialRowQuery = 1 and specialColumnQuery = 1
	title.caption = "Insert Rows and Columns"
    else if specialRowQuery = 1
	title.caption = "Insert Rows"
    else
	title.caption = "Insert Columns"
    end if

end sub

function numberCellsSelectedString(rowsOrColumns as integer) as string

REM ********************************************************************
REM                   numberCellsSelectedString
REM ********************************************************************
REM
REM SYNOPSIS:	Returns a string which is the number of rows or
REM             or columns selected.
REM
REM ********************************************************************

  dim intVal as integer
  dim floatVal as float

    if rowsOrColumns = 0
	if vertSelector.leftColumn <> -1
	    intVal = vertSelector.bottomRow - vertSelector.topRow + 1
	else
	    intVal = 1
	end if
    else
	if horizSelector.leftColumn <> -1
	    intVal = horizSelector.rightColumn - horizSelector.leftColumn + 1
	else
	    intVal = 1
	end if
    end if

    floatVal = intVal
    numberCellsSelectedString = Str(floatVal)

end function

sub insertRowsToggle_changed(self as toggle)

REM ********************************************************************
REM                   insertRowsToggle_changed
REM ********************************************************************
REM
REM SYNOPSIS:	Disable or enable the components for the special
REM             row query.
REM
REM ********************************************************************

    if self.status = 0
	specialHeightLabel.enabled = 0
	specialHeightEntry.enabled = 0
	specialRowsToInsertLabel.enabled = 0
	specialRowsToInsertEntry.enabled = 0
    else 
	specialHeightLabel.enabled = 1
	specialHeightEntry.enabled = 1
	specialRowsToInsertLabel.enabled = 1
	specialRowsToInsertEntry.enabled = 1
    end if
end sub

sub insertColumnsToggle_changed(self as toggle)

REM ********************************************************************
REM                   insertColumnsToggle_changed
REM ********************************************************************
REM
REM SYNOPSIS:	Disable or enable the components for the special
REM             column query.
REM
REM ********************************************************************

    if self.status = 0
	specialWidthLabel.enabled = 0
	specialWidthEntry.enabled = 0
	specialColumnsToInsertLabel.enabled = 0
	specialColumnsToInsertEntry.enabled = 0
    else 
	specialWidthLabel.enabled = 1
	specialWidthEntry.enabled = 1
	specialColumnsToInsertLabel.enabled = 1
	specialColumnsToInsertEntry.enabled = 1
    end if
end sub

function runChangeQueryDialog(rowsOrColumns as integer) as integer

REM ********************************************************************
REM                        runChangeQueryDialog
REM ********************************************************************
REM
REM SYNOPSIS:	Run the change-query dialog and return new
REM             width/height.
REM
REM ********************************************************************

REM
REM Setup components.
REM

    if (rowsOrColumns = 0)
	changeQueryDialogTitle.caption = "Change Columns"
	changeQueryDialogLabel.caption = "Column Width:"
	changeQueryDialogEntry.text = "30"
    else
	changeQueryDialogTitle.caption = "Change Rows"
	changeQueryDialogLabel.caption = "Row Height:"
	changeQueryDialogEntry.text = defaultRowHeightEntry.text
    end if

REM
REM Center the dialog.
REM

  dim left as integer
  dim top as integer

    left = (640 - changeQueryDialog.width) / 2
    top = (480 - changeQueryDialog.height) / 2

    changeQueryDialog.left = left
    changeQueryDialog.top = top


REM
REM Show the dialog.
REM

    changeQueryDialog.visible = 1

REM
REM Wait until valid input is entered or the dialog is canceled.
REM

  dim dialogDone as integer
    dialogDone = 0

    do
	modalWait()
	if modalReturn = 1
	    runChangeQueryDialog = processChangeQueryDialogEntry(rowsOrColumns)

	    if runChangeQueryDialog <> -2
		dialogDone = 1
	    end if
	else
	    runChangeQueryDialog = -1
	    dialogDone = 1
	end if
    loop until dialogDone = 1

REM
REM Hide the dialog.
REM

    changeQueryDialog.visible = 0

end function

function processChangeQueryDialogEntry(rowsOrColumns) as integer

REM ********************************************************************
REM                 processChangeQueryDialogEntry
REM ********************************************************************
REM
REM SYNOPSIS:	Check to make sure that the entry in the
REM             change-query dialog contains valid text.
REM
REM ********************************************************************

  dim checkReturn as integer

    if rowsOrColumns = 0
	checkReturn = checkWidthOrHeight(changeQueryDialogEntry, warnEmptyWidth, warnWidthTooBig)
	
	if checkReturn = -1
	    processChangeQueryDialogEntry = -2
	else
	    processChangeQueryDialogEntry = checkReturn
	end if
    else 
	checkReturn = checkWidthOrHeight(changeQueryDialogEntry, warnEmptyHeight, warnHeightTooBig)
	
	if checkReturn = -1
	    processChangeQueryDialogEntry = -2
	else
	    processChangeQueryDialogEntry = checkReturn
	end if
    end if

end function

sub cancelButton_pressed(self as button)

REM ********************************************************************
REM                     cancelButton_pressed
REM ********************************************************************

    modalReturn = 0
    modalSync = 1

end sub

sub OKButton_pressed(self as button)

REM ********************************************************************
REM                       OKButton_pressed
REM ********************************************************************

    modalReturn = 1
    modalSync = 1

end sub

function processNonNegativeInt(text as string) as struct NumberInfo

REM ********************************************************************
REM                    processNonNegativeInt
REM ********************************************************************
REM
REM SYNOPSIS:	Process a string as a nonnegative integer and return
REM             information about it.
REM
REM STRATEGY:
REM
REM This function implements a DFA to recognize nonnegative integers.
REM Specifically, it recognizes strings which match the following
REM regular expression:
REM     <space>*[0-9]+<space>* 
REM
REM ********************************************************************

  dim return as struct NumberInfo
    return.valid = 0
    return.value = 0
    return.overflow = 0

REM
REM States
REM
REM 0	 Finish
REM 1	 Start
REM 2	 Leading white-space
REM 3	 Numbers
REM 4	 Trailing white-space
REM 

  dim state as integer
  dim index as integer
  dim curChar as string
  dim curVal as integer

    state = 1
    index = 1

    do while state <> 0
	if index > Len(text)

	    select case state
	      case 1, 2
		state = 0
	      case 3, 4
		return.valid = 1
		state = 0
	    end select

	else

	    curChar = Mid(text, index, 1)

	    select case curChar
	      case " "
		select case state
		  case 1
		    state = 2
		  case 3
		    state = 4
		end select

	      case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
		select case state
		  case 1, 2, 3
		    curVal = charToInt(curChar)

		    if (return.value > 3276) or ((return.value = 3276) and (curVal > 7))
			return.overflow = 1
		    else 
			return.value = return.value * 10 + curVal
		    end if

		    state = 3
		  case 4
		    state = 0
		end select

	      case else
		state = 0
	    end select

	end if

	index = index + 1
    loop

    processNonNegativeInt = return

end function

function charToInt(char as string) as integer

REM ********************************************************************
REM                           charToInt
REM ********************************************************************

    charToInt = Asc(char) - Asc("0")

end function

sub horizScroll_changed(self as scrollbar, scrollType as integer)

REM ********************************************************************
REM                      horizScroll_changed
REM ********************************************************************

    horizSelector.left = -self.value
    initialTable.left = -self.value

end sub

sub vertScroll_changed(self as scrollbar, scrollType as integer)

REM ********************************************************************
REM                       vertScroll_changed
REM ********************************************************************

    vertSelector.top = -self.value
    initialTable.top = -self.value

end sub

sub horizSelector_drawCell(self as table, row as integer, column as integer, x as integer, y as integer)

REM ********************************************************************
REM                     horizSelector_drawCell
REM ********************************************************************
REM
REM SYNOPSIS:	Draw the column number of the cell in its center.
REM
REM ********************************************************************

  dim floatVal as float
  dim drawString as string
    floatVal = column
    drawString = Str(floatVal)

  dim drawX as integer
  dim drawY as integer

    drawX = x + (self.columnWidths[column] - self!TextWidth(drawString, "", 12, 1))/2
    drawY = y + (self.rowHeights[0] - 12)/2

    self!DrawText(drawString, drawX, drawY, BLACK, "", 12, 1)

end sub

sub vertSelector_drawCell(self as table, row as integer, column as integer, x as integer, y as integer)

REM ********************************************************************
REM                      vertSelector_drawCell
REM ********************************************************************
REM
REM SYNOPSIS:	Draw the row number of the cell in its center.
REM
REM ********************************************************************

  dim floatVal as float
  dim drawString as string
    floatVal = row
    drawString = Str(floatVal)

  dim drawX as integer
  dim drawY as integer

    drawX = x + (self.columnWidths[0] - self!TextWidth(drawString, "", 12, 1))/2
    drawY = y + (self.rowHeights[row] - 12)/2

    self!DrawText(drawString, drawX, drawY, BLACK, "", 12, 1)

end sub

