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
top=95
left=100
sizeHControl=0
sizeVControl=0
tile=1
End CompInit
form1.width=320
form1.height=280
form1.name="form1"
EnableEvents()
duplo_start()
end sub

sub duplo_start()
REM place initialization code here

	dim sWin as component
	sWin = MakeComponent("spriteContent", "top")
	CompInit sWin
		width = 300
		height = 150
	end CompInit
	
	dim d1 as component
	d1 = MakeComponent("draw", "top")
	d1.start()
	d1.linecolor(DARK_RED)
	d1.moveto(0,15)
	d1.lineto(5,-5)
	d1.lineto(0,0)
	d1.lineto(-5,-5)
	d1.lineto(0,15)
	d1.linecolor(LIGHT_RED)
	d1.moveto(0,7)
	d1.lineto(2,-2)
	d1.lineto(0,0)
	d1.lineto(-2,-2)
	d1.lineto(0,7)
	d1.stop()
	d1.visible = 1

	dim s1 as component
	s1 = MakeComponent("sprite", sWin)
	CompInit s1
		x = 50
		y = 50
		xVel = 2
		yVel = 3
		color = DARK_RED
		rotation = 3
		imageCount = 1
	end CompInit
	s1.setframe(0,d1.data)
	s1.visible=1

	dim d2 as component
	d2 = MakeComponent("draw", "top")
	d2.start()
	d2.areacolor(LIGHT_GREEN)
	d2.linecolor(LIGHT_GREEN)
	d2.rectangle(5,5,40,40)
	d2.stop()
	d2.visible = 1

	dim s2 as component
	s2 = MakeComponent("sprite", sWin)
	CompInit s2
		x = 120
		y = 30
		xVel = -2
		yVel = -3
		color = LIGHT_GREEN
		rotation = -3
		imageCount = 1
	end CompInit
	s2.setframe(0,d2.data)
	s2.visible=1

	sWin.visible=1
	sWin.start()
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

