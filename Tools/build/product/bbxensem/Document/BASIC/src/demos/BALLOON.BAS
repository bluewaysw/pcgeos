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
Dim form1 as form
form1 = MakeComponent("form","app")
CompInit form1
proto="form1"
top=90
left=95
sizeHControl=0
sizeVControl=0
caption="How to create Balloon Help"
End CompInit
Dim popup1 as popup
popup1 = MakeComponent("popup",form1)
CompInit popup1
proto="popup1"
caption="Information..."
left=0
top=0
visible=1
End CompInit
Dim button1 as button
button1 = MakeComponent("button",popup1)
CompInit button1
proto="button1"
caption="About the Author"
visible=1
End CompInit
button1.name="button1"
popup1.name="popup1"
Dim gadget1 as gadget
gadget1 = MakeComponent("gadget",form1)
CompInit gadget1
proto="gadget1"
width=85
height=11
left=3
top=-5
visible=1
End CompInit
Dim gadget2 as gadget
gadget2 = MakeComponent("gadget",gadget1)
CompInit gadget2
proto="gadget2"
left=0
top=0
width=75
height=7
visible=1
End CompInit
gadget2.name="gadget2"
gadget1.name="gadget1"
Dim group1 as group
group1 = MakeComponent("group",form1)
CompInit group1
proto="group1"
caption="group1"
left=15
top=31
height=88
width=100
look=1
visible=1
End CompInit
Dim choice1 as choice
choice1 = MakeComponent("choice",group1)
CompInit choice1
proto="choice1"
caption="choice1"
left=15
top=22
width=40
sizeVControl=3
visible=1
End CompInit
choice1.name="choice1"
Dim choice2 as choice
choice2 = MakeComponent("choice",group1)
CompInit choice2
proto="choice2"
caption="choice2"
left=15
top=38
visible=1
End CompInit
choice2.name="choice2"
Dim gadget3 as gadget
gadget3 = MakeComponent("gadget",group1)
CompInit gadget3
proto="gadget3"
left=32
top=23
width=80
height=14
visible=1
End CompInit
gadget3.name="gadget3"
Dim gadget4 as gadget
gadget4 = MakeComponent("gadget",group1)
CompInit gadget4
proto="gadget4"
left=32
top=38
width=80
height=14
visible=1
End CompInit
gadget4.name="gadget4"
Dim gadget5 as gadget
gadget5 = MakeComponent("gadget",group1)
CompInit gadget5
proto="gadget5"
left=32
top=53
width=80
height=14
visible=1
End CompInit
gadget5.name="gadget5"
Dim choice3 as choice
choice3 = MakeComponent("choice",group1)
CompInit choice3
proto="choice3"
caption="choice3"
sizeHControl=0
left=15
top=54
sizeVControl=0
width=30
height=10
visible=1
End CompInit
choice3.name="choice3"
group1.name="group1"
Dim gadget6 as gadget
gadget6 = MakeComponent("gadget",form1)
CompInit gadget6
proto="gadget6"
left=142
top=45
width=90
height=70
visible=1
End CompInit
Dim gadget7 as gadget
gadget7 = MakeComponent("gadget",gadget6)
CompInit gadget7
proto="gadget7"
left=10
top=10
height=50
width=70
visible=1
End CompInit
Dim button3 as button
button3 = MakeComponent("button",gadget7)
CompInit button3
proto="button3"
caption="button3"
left=10
top=10
width=50
sizeVControl=0
height=30
visible=1
End CompInit
button3.name="button3"
gadget7.name="gadget7"
gadget6.name="gadget6"
Dim label3 as label
label3 = MakeComponent("label",form1)
CompInit label3
proto="label3"
caption="Examen the source code for information"
left=18
top=131
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
label3.name="label3"
Dim label4 as label
label4 = MakeComponent("label",form1)
CompInit label4
proto="label4"
caption="erikaj@worldonline.nl"
left=18
top=148
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
label4.name="label4"
Dim gadget8 as gadget
gadget8 = MakeComponent("gadget",form1)
CompInit gadget8
proto="gadget8"
left=120
top=148
width=180
height=80
visible=1
End CompInit
Dim gadget9 as gadget
gadget9 = MakeComponent("gadget",gadget8)
CompInit gadget9
proto="gadget9"
left=14
top=10
width=156
height=58
visible=1
End CompInit
Dim text2 as text
text2 = MakeComponent("text",gadget9)
CompInit text2
proto="text2"
left=11
top=9
width=123
height=42
maxChars=2000
maxLines=0
End CompInit
text2.name="text2"
text2.AppendString("Buy the book Now!\r")
text2.AppendString("Zen and the Art of Stupidity")
text2.visible=1
gadget9.name="gadget9"
gadget8.name="gadget8"
Dim picture6 as picture
picture6 = MakeComponent("picture",form1)
CompInit picture6
proto="picture6"
left=9
top=167
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
picture6.graphic=GetComplex(0)
picture6.name="picture6"
form1.width=320
form1.height=275
form1.name="form1"
Dim floater1 as floater
floater1 = MakeComponent("floater","app")
CompInit floater1
proto="floater1"
left=160
top=93
height=15
width=206
type=5
End CompInit
Dim picture1 as picture
picture1 = MakeComponent("picture",floater1)
CompInit picture1
proto="picture1"
sizeHControl=3
sizeVControl=3
left=0
top=0
visible=1
End CompInit
picture1.name="picture1"
picture1.graphic=GetComplex(1)
floater1.name="floater1"
floater1.caption="floater1"
Dim dialog1 as dialog
dialog1 = MakeComponent("dialog","app")
CompInit dialog1
proto="dialog1"
left=272
top=149
tile=1
caption=""
tileSpacing=10
helpContext=""
End CompInit
Dim label1 as label
label1 = MakeComponent("label",dialog1)
CompInit label1
proto="label1"
caption="Do you really care?"
sizeHControl=0
sizeVControl=3
width=125
visible=1
End CompInit
label1.name="label1"
Dim button2 as button
button2 = MakeComponent("button",dialog1)
CompInit button2
proto="button2"
caption="No"
default=1
closeDialog=1
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
button2.name="button2"
dialog1.name="dialog1"
dialog1.width=200
dialog1.height=90
Dim floater2 as floater
floater2 = MakeComponent("floater","app")
CompInit floater2
proto="floater2"
left=190
top=175
type=5
tile=1
width=94
height=18
End CompInit
Dim picture2 as picture
picture2 = MakeComponent("picture",floater2)
CompInit picture2
proto="picture2"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
picture2.name="picture2"
picture2.graphic=GetComplex(2)
floater2.name="floater2"
floater2.caption="floater2"
Dim floater3 as floater
floater3 = MakeComponent("floater","app")
CompInit floater3
proto="floater3"
left=190
top=191
tile=1
type=5
width=96
height=15
End CompInit
Dim picture3 as picture
picture3 = MakeComponent("picture",floater3)
CompInit picture3
proto="picture3"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
picture3.graphic=GetComplex(3)
picture3.name="picture3"
floater3.caption="floater3"
floater3.name="floater3"
Dim floater4 as floater
floater4 = MakeComponent("floater","app")
CompInit floater4
proto="floater4"
left=190
top=207
height=16
width=96
type=5
End CompInit
Dim picture4 as picture
picture4 = MakeComponent("picture",floater4)
CompInit picture4
proto="picture4"
left=0
top=0
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
picture4.graphic=GetComplex(4)
picture4.name="picture4"
floater4.caption="floater4"
floater4.name="floater4"
Dim dialog2 as dialog
dialog2 = MakeComponent("dialog","app")
CompInit dialog2
proto="dialog2"
left=236
top=148
caption=""
End CompInit
Dim label2 as label
label2 = MakeComponent("label",dialog2)
CompInit label2
proto="label2"
caption="Just another useless Dialog Box"
sizeHControl=3
sizeVControl=3
left=29
top=13
visible=1
End CompInit
label2.name="label2"
Dim button4 as button
button4 = MakeComponent("button",dialog2)
CompInit button4
proto="button4"
caption="Ok"
sizeHControl=3
closeDialog=1
default=1
left=112
top=30
sizeVControl=3
visible=1
End CompInit
button4.name="button4"
dialog2.name="dialog2"
dialog2.width=260
dialog2.height=90
Dim floater5 as floater
floater5 = MakeComponent("floater","app")
CompInit floater5
proto="floater5"
left=320
top=190
height=18
tile=1
width=108
End CompInit
Dim picture5 as picture
picture5 = MakeComponent("picture",floater5)
CompInit picture5
proto="picture5"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
picture5.name="picture5"
picture5.graphic=GetComplex(5)
floater5.name="floater5"
floater5.caption="floater5"
EnableEvents()
duplo_start()
end sub

sub duplo_start()
REM place initialization code here

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

sub gadget1_pen(self as gadget, action as integer, flag as integer, X as integer, Y as integer, modifier as integer)
floater1.visible =0
end sub

sub gadget2_pen(self as gadget, action as integer, flag as integer, X as integer, Y as integer, modifier as integer)
floater1.visible = 1
end sub

sub button1_pressed(self as button)
dialog1.visible =1
end sub

sub gadget3_pen(self as gadget, action as integer, flag as integer, X as integer, Y as integer, modifier as integer)
floater2.visible = 1
floater3.visible = 0
floater4.visible = 0

end sub

sub gadget4_pen(self as gadget, action as integer, flag as integer, X as integer, Y as integer, modifier as integer)
floater2.visible = 0
floater3.visible = 1
floater4.visible = 0
end sub

sub gadget5_pen(self as gadget, action as integer, flag as integer, X as integer, Y as integer, modifier as integer)
floater2.visible = 0
floater3.visible = 0
floater4.visible = 1
end sub

sub button3_pressed(self as button)
dialog2.visible = 1
end sub

sub gadget7_pen(self as gadget, action as integer, flag as integer, X as integer, Y as integer, modifier as integer)
floater5.visible =1
end sub

sub gadget6_pen(self as gadget, action as integer, flag as integer, X as integer, Y as integer, modifier as integer)
floater5.visible = 0
end sub

sub gadget8_pen(self as gadget, action as integer, flag as integer, X as integer, Y as integer, modifier as integer)
picture6.visible = 0
end sub

sub gadget9_pen(self as gadget, action as integer, flag as integer, X as integer, Y as integer, modifier as integer)
picture6.visible = 1
end sub

