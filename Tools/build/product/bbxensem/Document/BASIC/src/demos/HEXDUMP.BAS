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
proto="form1"
top=60
left=117
tile=1
End CompInit
Dim out as text
out = MakeComponent("text",form1)
CompInit out
proto="out"
width=420
height=200
End CompInit
out.name="out"
out.visible=1
Dim popup1 as popup
popup1 = MakeComponent("popup",form1)
CompInit popup1
proto="popup1"
caption="File"
left=100
top=11
visible=1
End CompInit
Dim OpenMenu as button
OpenMenu = MakeComponent("button",popup1)
CompInit OpenMenu
proto="Open"
caption="Open..."
sizeHControl=0
sizeVControl=0
visible=1
End CompInit
OpenMenu.name="OpenMenu"
popup1.name="popup1"
Dim group3 as group
group3 = MakeComponent("group",form1)
CompInit group3
proto="group3"
caption="group3"
look=2
tile=1
tileLayout=1
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
Dim Open as button
Open = MakeComponent("button",group3)
CompInit Open
proto="Open"
caption="Open"
sizeHControl=3
sizeVControl=0
height=19
visible=1
End CompInit
Open.name="Open"
Dim Clear1 as button
Clear1 = MakeComponent("button",group3)
CompInit Clear1
proto="Clear"
caption="Clear"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
Clear1.name="Clear1"
group3.name="group3"
form1.width=456
form1.height=282
form1.name="form1"
Dim dialog1 as dialog
dialog1 = MakeComponent("dialog","app")
CompInit dialog1
proto="dialog1"
left=322
top=89
tile=1
End CompInit
Dim group1 as group
group1 = MakeComponent("group",dialog1)
CompInit group1
proto="group1"
caption="Select file to view"
look=1
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
group1.name="group1"
Dim group2 as group
group2 = MakeComponent("group",dialog1)
CompInit group2
proto="group2"
caption="group2"
look=2
tile=1
tileLayout=1
visible=1
End CompInit
Dim spacer1 as spacer
spacer1 = MakeComponent("spacer",group2)
CompInit spacer1
proto="spacer1"
height=25
width=5
visible=1
End CompInit
spacer1.name="spacer1"
Dim Clear2 as button
Clear2 = MakeComponent("button",group2)
CompInit Clear2
proto="Clear"
caption="Clear Viewer"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
Clear2.name="Clear2"
Dim DumpHex as button
DumpHex = MakeComponent("button",group2)
CompInit DumpHex
proto="DumpHex"
caption="Dump the Hex!"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
DumpHex.name="DumpHex"
Dim spacer2 as spacer
spacer2 = MakeComponent("spacer",group2)
CompInit spacer2
proto="spacer2"
height=20
width=5
visible=1
End CompInit
spacer2.name="spacer2"
group2.name="group2"
dialog1.name="dialog1"
dialog1.width=280
dialog1.height=140
EnableEvents()
duplo_start()
end sub

sub duplo_start()
	' FILE:	HEXDUMP.BAS
	' AUTHOR:	Martin Turon
	' DATE:	1998/10/22
	'	$Id$

	DIM filesel1 AS COMPONENT
	filesel1 = MakeComponent("fileSelector",group1)
	CompInit filesel1
	   proto="filesel1"
	   visible=1
	End CompInit
end sub

sub module_goTo(context as string)

end sub

function module_getContext()
module_getContext = ""
end function

sub module_show()
REM code for making this module appear
form1.visible=1
end sub

sub module_hide()
REM code for making this module disappear
form1.visible=0
end sub

sub module_exit()
end sub

function FullHex(l as long) as string
	' Returns a full length hexidecimal string
	' corresponding to the given byte.
	' 1998/10/22 (c)turon
	FullHex = Hex(l)
	if Len(FullHex) < 2
		FullHex = "0"+FullHex
	end if	
end function

sub Open_pressed(self as button)
	dialog1.visible=1
end sub

sub DumpHex_pressed(self as button)
	dialog1.visible = 0
	out.font = "URW Mono"

	DIM filename AS STRING
	filename = filesel1.filename

	DIM in AS COMPONENT			' in will be our file
	in = MakeComponent("file","top")
	in.name = filename
	in.trap = 0					' 2 = verbose error dialogs
	in!open()
   	out.AppendString("\rDumping ",filename," in hexidecimal:\r")
	out.AppendString("\r  OFFSET			HEX					ASCII")
	DO WHILE in.goes() AND in.tell()<1024 	' enforce 1K limit
		out.AppendString("\r  0x",Hex(in.tell()))
 		out.AppendString("   	",FullHex(in.peek()))
		out.AppendString(FullHex(in.peek()))	
		out.AppendString(FullHex(in.peek()))	
		out.AppendString(FullHex(in.peek()))
 		out.AppendString(" ",FullHex(in.peek()))
		out.AppendString(FullHex(in.peek()))
		out.AppendString(FullHex(in.peek()))
		out.AppendString(FullHex(in.peek()))
 		out.AppendString(" ",FullHex(in.peek()))
		out.AppendString(FullHex(in.peek()))
		out.AppendString(FullHex(in.peek()))
		out.AppendString(FullHex(in.peek()))
 		out.AppendString(" ",FullHex(in.peek()))
		out.AppendString(FullHex(in.peek()))
		out.AppendString(FullHex(in.peek()))
		out.AppendString(FullHex(in.peek()))
	LOOP
	in!close()
end sub

sub Clear_pressed(self as button)
	out.DeleteRange(0,30000)
end sub

