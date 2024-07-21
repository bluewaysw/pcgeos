sub duplo_ui_ui_ui()
 REM		$Id$
 REM	Copyright (c) Geoworks 1995 -- All Rights Reserved
 REM	FILE:		STDINC.BH

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
CONST WHITE 		&Hffffffff
CONST BLACK 		&Hff000000
CONST GRAY_50 		&Hff808080, GREY_50 		&Hff808080
CONST DARK_GRAY 	&Hff555555, LIGHT_GRAY		&Hffaaaaaa
CONST DARK_GREY 	&Hff555555, LIGHT_GREY		&Hffaaaaaa
CONST DARK_GREEN	&Hff00aa00, LIGHT_GREEN 	&Hff55ff55
CONST DARK_BLUE 	&Hff0000aa, LIGHT_BLUE		&Hff5555ff
CONST DARK_CYAN		&Hff00aaaa, LIGHT_CYAN		&Hff55ffff
CONST DARK_PURPLE	&Hffaa00aa, LIGHT_PURPLE	&Hffff55ff
CONST DARK_ORANGE	&Hffaa5500, LIGHT_ORANGE	&Hffff5555
CONST YELLOW		&Hffffff55
CONST RED		&Hffaa0000

REM useful Boolean constants
CONST TRUE		1
CONST FALSE		0

REM sound constants
CONST SS_ERROR		0
CONST SS_WARNING	1
CONST SS_NOTIFY		2
CONST SS_NO_INPUT	3
CONST SS_KEY_CLICK	4
CONST SS_ALARM		5

CONST PEN_PRESS 1, PEN_HOLD 2, PEN_DRAG 3, PEN_TO 4, PEN_RELEASE 5
CONST PEN_LOST 6, PEN_FLY_OVER 7

CONST C_SYS_BACKSPACE		&Hff08
CONST C_SYS_TAB			&Hff09
CONST C_SYS_ENTER		&Hff0d
CONST C_SYS_ESCAPE		&Hff1b
CONST C_SYS_F1			&Hff80
CONST C_SYS_F2			&Hff81
CONST C_SYS_F3			&Hff82
CONST C_SYS_F4			&Hff83
CONST C_SYS_F5			&Hff84
CONST C_SYS_F6			&Hff85
CONST C_SYS_F7			&Hff86
CONST C_SYS_F8			&Hff87
CONST C_SYS_F9			&Hff88
CONST C_SYS_F10			&Hff89
CONST C_SYS_F11			&Hff8a
CONST C_SYS_F12			&Hff8b
CONST C_SYS_F13			&Hff8c
CONST C_SYS_F14			&Hff8d
CONST C_SYS_F15			&Hff8e
CONST C_SYS_F16			&Hff8f
CONST C_SYS_UP			&Hff90
CONST C_SYS_DOWN		&Hff91
CONST C_SYS_RIGHT		&Hff92
CONST C_SYS_LEFT		&Hff93
CONST C_SYS_HOME		&Hff94
CONST C_SYS_END			&Hff95
CONST C_SYS_PREVIOUS		&Hff96
CONST C_SYS_NEXT		&Hff97
CONST C_SYS_INSERT		&Hff98
CONST C_SYS_CLEAR		&Hff99	rem Not used in Geos.
CONST C_SYS_DELETE		&Hff9a
CONST C_SYS_PRINT_SCREEN	&Hff9b
CONST C_SYS_HELP		&Hff9d	rem Not used in Geos.
CONST C_SYS_BREAK		&Hff9e
CONST C_SYS_CAPS_LOCK		&Hffe8
CONST C_SYS_NUM_LOCK		&Hffe9
CONST C_SYS_SCROLL_LOCK		&Hffea
CONST C_SYS_LEFT_ALT		&Hffe0
CONST C_SYS_RIGHT_ALT		&Hffe1
CONST C_SYS_LEFT_CTRL		&Hffe2
CONST C_SYS_RIGHT_CTRL		&Hffe3
CONST C_SYS_LEFT_SHIFT		&Hffe4
CONST C_SYS_RIGHT_SHIFT		&Hffe5


CONST KEY_BS 		&Hff08
CONST KEY_DEL 		&Hff9a
CONST KEY_ENTER 	&Hff0d
CONST KEY_KP_RETURN 	&Hffff
CONST KEY_HOME		&Hff94
CONST KEY_TAB		&Hff09
CONST KEY_END		&Hff93
CONST KEY_ESC		&Hff1b
CONST KEY_UP_ARROW	&Hff90
CONST KEY_LEFT_ARROW	&Hff93
CONST KEY_RIGHT_ARROW	&Hff92
CONST KEY_DOWN_ARROW	&Hff91
REM dim system as module
REM system = SystemModule()

 REM end of stdinc.bh

DisableEvents()
Dim DBForm1 as form
DBForm1 = MakeComponent("form","app")
CompInit DBForm1
proto="form1"
top=80
left=6
sizeHControl=0
sizeVControl=0
tile=1
caption="DB App?"
tileSpacing=10
End CompInit
Dim group1 as group
group1 = MakeComponent("group",DBForm1)
CompInit group1
proto="group1"
caption="DB Fields"
look=1
tile=1
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
Dim DBEntry1 as entry
DBEntry1 = MakeComponent("entry",group1)
CompInit DBEntry1
proto="entry1"
visible=1
End CompInit
DBEntry1.name="DBEntry1"
Dim spacer5 as spacer
spacer5 = MakeComponent("spacer",group1)
CompInit spacer5
proto="spacer5"
visible=1
End CompInit
spacer5.name="spacer5"
Dim DBEntry2 as entry
DBEntry2 = MakeComponent("entry",group1)
CompInit DBEntry2
proto="entry2"
visible=1
End CompInit
DBEntry2.name="DBEntry2"
Dim spacer6 as spacer
spacer6 = MakeComponent("spacer",group1)
CompInit spacer6
proto="spacer6"
visible=1
End CompInit
spacer6.name="spacer6"
Dim DBEntry3 as entry
DBEntry3 = MakeComponent("entry",group1)
CompInit DBEntry3
proto="entry3"
visible=1
End CompInit
DBEntry3.name="DBEntry3"
Dim spacer7 as spacer
spacer7 = MakeComponent("spacer",group1)
CompInit spacer7
proto="spacer7"
visible=1
End CompInit
spacer7.name="spacer7"
Dim RecordCount as number
RecordCount = MakeComponent("number",group1)
CompInit RecordCount
proto="number1"
caption="Record"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
RecordCount.name="RecordCount"
group1.name="group1"
Dim DBbuttonGroup as group
DBbuttonGroup = MakeComponent("group",DBForm1)
CompInit DBbuttonGroup
proto="group2"
caption="DB Controls"
look=1
tile=1
tileLayout=1
sizeHControl=3
tileSpacing=15
sizeVControl=3
visible=1
End CompInit
Dim SaveButton as button
SaveButton = MakeComponent("button",DBbuttonGroup)
CompInit SaveButton
proto="button1"
caption="  Save"
sizeHControl=0
sizeVControl=3
width=56
visible=1
End CompInit
SaveButton.name="SaveButton"
Dim button4 as button
button4 = MakeComponent("button",DBbuttonGroup)
CompInit button4
proto="button4"
caption=" Delete"
sizeHControl=0
sizeVControl=3
width=56
destructive=1
visible=1
End CompInit
button4.name="button4"
DBbuttonGroup.name="DBbuttonGroup"
Dim dbtest as database
dbtest = MakeComponent("database",DBForm1)
CompInit dbtest
proto="database1"
End CompInit
dbtest.name="dbtest"
DBForm1.width=320
DBForm1.height=280
DBForm1.name="DBForm1"
EnableEvents()
duplo_start()
end sub

sub duplo_start()
REM place initialization code here
DIM dbRecNum AS string
DIM vdbRecNum AS integer
DIM dbName AS string
DIM vdbName AS string
DIM dbAddress AS string
DIM vdbAddress AS string
DIM dbPhone AS string
DIM vdbPhone AS string
DIM dbExists AS integer
DIM dbNew AS integer
DIM db0New AS integer
DIM db1New AS integer
DIM db2New AS integer
DIM dbClosed AS integer
DIM dbdbName AS string
dbRecNum = "Record"
dbName = "Name"
dbAddress = "Address"
dbPhone = "Phone"
dbdbName = "Phonbook"
dbExists = dbtest.OpenDatabase( dbdbName, 2)
IF dbExists <> 0 THEN
dbNew = dbtest.CreateDatabase( dbdbName, 4, 0, dbRecNum, "integer", 1, 0)
db0New = dbtest.AddField( dbName, "string", 1)
db1New = dbtest.AddField( dbAddress, "string", 4)
db2New = dbtest.AddField( dbPhone, "string", 3)
END IF
IF dbNew <> 0 AND db0New <> 0 AND db1New <> 0 AND db2New <> 0 THEN
	DBEntry1.text = "Couldn't create database & fields"
END IF

end sub

sub module_goTo(context as string)

end sub

function module_getContext()

module_getContext = ""

end function

sub module_show()
REM code for making this module appear
DBForm1.visible=1

end sub

sub module_hide()
REM code for making this module disappear
DBForm1.visible=0

end sub

sub module_exit()
dbClosed = dbtest.CloseDatabase()
IF dbClosed <> 0 THEN
	DBEntry1.text = "Database didn't close"
END IF
end sub

sub button1_pressed(self as button)
DIM newRec AS integer
DIM success AS integer
DIM firstField AS integer
DIM secondField AS integer
DIM thirdField AS integer

newRec = dbtest.NewRecord()
IF newRec <> 0 THEN
	DBEntry1.text = "No Record was created"
END IF
firstField = dbtest.PutField(dbName, vdbName)
secondField = dbtest.PutField(dbAddress, vdbAddress)
thirdField = dbtest.PutField(dbPhone, vdbPhone)
IF firstField <> 0 AND secondField <>0 AND thirdField <> 0 THEN
DBEntry1.text = "Fields weren't replaced"
END IF
success = dbtest.PutRecord()
IF success <>0 THEN
	DBEntry3.text = "Record didn't get saved"
END IF

end sub

sub entry1_entered(self as entry)
vdbName = self.text
end sub

sub entry2_entered(self as entry)
vdbAddress = self.text
end sub

sub entry3_entered(self as entry)
vdbPhone = self.text
end sub

sub number1_changed(self as number, value as integer)

end sub

