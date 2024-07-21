sub duplo_ui_ui_ui()
 REM		$Id$
 REM	Copyright (c) New Deal 1997 -- All Rights Reserved
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
CONST DARK_RED		&Hffaa0000, LIGHT_RED		&Hffff5555
CONST BROWN		&Hffaa5500, YELLOW		&Hffffff55

REM useful text style constants
CONST UNDERLINE		1
CONST STRIKE_THRU	2
CONST SUBSCRIPT		4
CONST SUPERSCRIPT	8
CONST ITALIC		16
CONST BOLD		32

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

CONST MOUSE_PRESS 1, MOUSE_HOLD 2, MOUSE_DRAG 3, MOUSE_TO 4, MOUSE_RELEASE 5
CONST MOUSE_LOST 6, MOUSE_FLY_OVER 7

CONST C_SYS_00			&Hff00
CONST C_SYS_FF			&Hffff
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

REM date formats
CONST DTF_LONG				0
CONST DTF_LONG_CONDENSED		1
CONST DTF_LONG_NO_WEEKDAY		2
CONST DTF_LONG_NO_WEEKDAY_CONDENSED	3
CONST DTF_SHORT				4
CONST DTF_ZERO_PADDED_SHORT		5
CONST DTF_MD_LONG			6
CONST DTF_MD_LONG_NO_WEEKDAY		7
CONST DTF_MD_SHORT			8
CONST DTF_MY_LONG			9
CONST DTF_MY_SHORT			10
CONST DTF_YEAR				11
CONST DTF_MONTH				12
CONST DTF_DAY				13
CONST DTF_WEEKDAY			14
REM time formats
CONST DTF_HMS				15
CONST DTF_HM				16
CONST DTF_H				17
CONST DTF_MS				18
CONST DTF_HMS_24HOUR			19
CONST DTF_HM_24HOUR			20

REM pi
CONST PI 3.14159265359

REM Format() constants
CONST FFAF_SCIENTIFIC		&H100
CONST FFAF_PERCENT		&H80
CONST FFAF_USE_COMMAS		&H40
CONST FFAF_NO_TRAIL_ZEROS	&H20
CONST FFAF_NO_LEAD_ZERO		&H10

REM dim system as module
REM system = SystemModule()

 REM end of stdinc.bh

DisableEvents()
Dim form1 as form
form1 = MakeComponent("form","app")
CompInit form1
caption="form1"
proto="form1"
top=68
left=95
sizeVControl=1
End CompInit
Dim text1 as text
text1 = MakeComponent("text",form1)
CompInit text1
proto="text1"
left=13
top=48
width=240
height=64
End CompInit
text1.name="text1"
text1.visible=1
Dim label1 as label
label1 = MakeComponent("label",form1)
CompInit label1
proto="label1"
caption="Main Text:"
left=18
top=25
visible=1
End CompInit
label1.name="label1"
Dim group1 as group
group1 = MakeComponent("group",form1)
CompInit group1
look=1
tile=1
proto="group1"
caption="Text to add:"
left=12
top=117
height=94
width=234
tileVAlign=2
tileSpacing=5
visible=1
End CompInit
Dim AddEntry as entry
AddEntry = MakeComponent("entry",group1)
CompInit AddEntry
proto="AddEntry"
visible=1
End CompInit
AddEntry.name="AddEntry"
Dim label3 as label
label3 = MakeComponent("label",group1)
CompInit label3
proto="label3"
caption="At position:"
visible=1
End CompInit
label3.name="label3"
Dim AddPosition as number
AddPosition = MakeComponent("number",group1)
CompInit AddPosition
proto="AddPosition"
visible=1
End CompInit
AddPosition.name="AddPosition"
Dim AddButton as button
AddButton = MakeComponent("button",group1)
CompInit AddButton
proto="AddButton"
caption="Add"
visible=1
End CompInit
AddButton.name="AddButton"
Dim AppendButton as button
AppendButton = MakeComponent("button",group1)
CompInit AppendButton
proto="AppendButton"
caption="Append"
visible=1
End CompInit
AppendButton.name="AppendButton"
group1.name="group1"
Dim group2 as group
group2 = MakeComponent("group",form1)
CompInit group2
look=1
proto="group2"
caption="Describe selection"
left=280
top=44
width=150
visible=1
End CompInit
Dim label4 as label
label4 = MakeComponent("label",group2)
CompInit label4
proto="label4"
caption="Start"
left=6
top=22
visible=1
End CompInit
label4.name="label4"
Dim label5 as label
label5 = MakeComponent("label",group2)
CompInit label5
proto="label5"
caption="End"
left=10
top=43
visible=1
End CompInit
label5.name="label5"
Dim SelectionStart as number
SelectionStart = MakeComponent("number",group2)
CompInit SelectionStart
proto="SelectionStart"
left=45
top=21
visible=1
End CompInit
SelectionStart.name="SelectionStart"
Dim SelectionEnd as number
SelectionEnd = MakeComponent("number",group2)
CompInit SelectionEnd
proto="SelectionEnd"
left=45
top=42
visible=1
End CompInit
SelectionEnd.name="SelectionEnd"
Dim SelectionGet as button
SelectionGet = MakeComponent("button",group2)
CompInit SelectionGet
proto="SelectionGet"
caption="Get"
left=14
top=73
visible=1
End CompInit
SelectionGet.name="SelectionGet"
Dim SelectionSet as button
SelectionSet = MakeComponent("button",group2)
CompInit SelectionSet
proto="SelectionSet"
caption="Set"
left=72
top=73
visible=1
End CompInit
SelectionSet.name="SelectionSet"
group2.name="group2"
Dim group3 as group
group3 = MakeComponent("group",form1)
CompInit group3
look=1
proto="group3"
caption="Delete Text:"
left=283
top=206
width=218
tile=1
sizeVControl=0
visible=1
End CompInit
Dim DeleteButton as button
DeleteButton = MakeComponent("button",group3)
CompInit DeleteButton
proto="DeleteButton"
caption="Delete text in range"
sizeHControl=0
sizeVControl=0
width=129
height=22
visible=1
End CompInit
DeleteButton.name="DeleteButton"
group3.name="group3"
Dim group4 as group
group4 = MakeComponent("group",form1)
CompInit group4
look=1
tile=1
proto="group4"
caption="Replace:"
left=9
top=277
width=234
tileSpacing=5
visible=1
End CompInit
Dim ReplaceEntry as entry
ReplaceEntry = MakeComponent("entry",group4)
CompInit ReplaceEntry
proto="ReplaceEntry"
visible=1
End CompInit
ReplaceEntry.name="ReplaceEntry"
Dim ReplaceButton as button
ReplaceButton = MakeComponent("button",group4)
CompInit ReplaceButton
proto="ReplaceButton"
caption="Replace Selection"
visible=1
End CompInit
ReplaceButton.name="ReplaceButton"
group4.name="group4"
Dim label6 as label
label6 = MakeComponent("label",form1)
CompInit label6
proto="label6"
caption="Replace and Delete use this range:"
left=283
top=28
visible=1
End CompInit
label6.name="label6"
Dim group5 as group
group5 = MakeComponent("group",form1)
CompInit group5
look=1
tile=1
proto="group5"
caption="GetText:"
left=267
top=261
height=99
width=254
tileSpacing=4
visible=1
End CompInit
Dim text2 as text
text2 = MakeComponent("text",group5)
CompInit text2
proto="text2"
width=220
height=60
End CompInit
text2.caption=""
text2.name="text2"
text2.visible=1
Dim GetText as button
GetText = MakeComponent("button",group5)
CompInit GetText
proto="GetText"
caption="GetRange"
visible=1
End CompInit
GetText.name="GetText"
group5.name="group5"

Dim list1 as list
list1 = MakeComponent("list",form1)
CompInit list1
proto="list1"
left=282
top=173
width=142
height=13
End CompInit
list1.name="list1"
list1.captions[0]="Cooperstown"
list1.captions[1]="Cranbrook"
list1.captions[2]="Sather Gothic"
list1.captions[3]="Shattuck Avenue"
list1.captions[4]="Superb"
list1.captions[5]="URW Mono"
list1.captions[6]="URW Roman"
list1.captions[7]="URW Sans"
list1.captions[8]="URW SymbolPS"
list1.selectedItem=1
list1.visible=1

Dim list2 as list
list2 = MakeComponent("list",form1)
CompInit list2
proto="list2"
left=473
top=173
width=13
height=13
End CompInit
list2.name="list2"
list2.captions[0]="8"
list2.captions[1]="10"
list2.captions[2]="12"
list2.captions[3]="14"
list2.captions[4]="18"
list2.captions[5]="24"
list2.captions[6]="36"
list2.selectedItem=1
list2.visible=1

form1.width=550
form1.height=398
form1.name="form1"

EnableEvents()
duplo_start()
end sub

sub duplo_start()
	REM $Revision:   1.0  $
end sub

sub module_show()
	form1.visible=1
end sub

sub module_hide()
	form1.visible = 0
end sub

sub AddButton_pressed(self as button)
	text1.InsertString(AddEntry.text, AddPosition.value)
end sub

sub AppendButton_pressed(self as button)
	text1.AppendString(AddEntry.text)
end sub

sub ReplaceButton_pressed(self as button)
	text1.ReplaceString(ReplaceEntry.text, SelectionStart.value, SelectionEnd.value)
end sub

sub DeleteButton_pressed(self as button)
	text1.DeleteRange(SelectionStart.value, SelectionEnd.value)
end sub

sub SelectionSet_pressed(self as button)
	text1.startSelect = SelectionStart.value
	text1.endSelect = SelectionEnd.value
end sub

sub SelectionGet_pressed(self as button)
	SelectionStart.value = text1.startSelect
	SelectionEnd.value = text1.endSelect
end sub

sub GetText_pressed(self as button)
	text2.text = text1.GetString(SelectionStart.value, SelectionEnd.value)
end sub

sub list1_changed(self as list, index as integer)
	text1.font = self.Getcaptions(index)
end sub

sub list2_changed(self as list, index as integer)
	text1.fontSize = Val(self.Getcaptions(index))
end sub

