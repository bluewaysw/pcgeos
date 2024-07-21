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
top=104
left=96
End CompInit
Dim scrollbar1 as scrollbar
scrollbar1 = MakeComponent("scrollbar",form1)
CompInit scrollbar1
proto="scrollbar1"
left=9
top=58
height=89
increment=0
visible=1
End CompInit
scrollbar1.caption="scrollbar1"
scrollbar1.name="scrollbar1"
Dim group1 as group
group1 = MakeComponent("group",form1)
CompInit group1
look=1
proto="group1"
caption=""
left=57
top=53
height=104
width=110
visible=1
End CompInit
Dim table1 as table
table1 = MakeComponent("table",group1)
CompInit table1
numRows=8
numColumns=2
proto="table1"
left=2
top=2
width=100
height=100
defaultRowHeight=50
End CompInit
Dim b1 as button
b1 = MakeComponent("button",table1)
CompInit b1
proto="b1"
caption="hi"
left=1
top=50
sizeHControl=1
sizeVControl=1
visible=1
End CompInit
b1.name="b1"
table1.caption=""
table1.name="table1"
table1.rowHeights[7]=30
table1.rowHeights[6]=50
table1.rowHeights[5]=50
table1.rowHeights[4]=50
table1.rowHeights[3]=30
table1.rowHeights[2]=25
table1.rowHeights[1]=10
table1.rowHeights[0]=20
table1.columnWidths[1]=40
table1.columnWidths[0]=40
table1.visible=1
group1.name="group1"
form1.width=285
form1.height=278
form1.name="form1"
EnableEvents()
duplo_start()
end sub

sub duplo_start()
	REM $Revision:   1.1  $
  dim updateOk as integer
    REM
    REM Currently, you can do
    REM scrollbar1.maximum = table1.overallHeight
    REM because scrollbar1.maximum is an integer and
    REM tabel1.overallHeight is a long.
    REM Later they will both be longs and the conversion
    REM would happen automatically if they aren't.  For now
    REM do this
  Dim heightInt as integer
    heightInt = table1.overallHeight
    scrollbar1.maximum = heightInt - table1.height +1
    updateOk = 1
    REM force redraw
    table1.firstVisibleRow = 0

end sub

sub module_show()
form1.visible=1
end sub

sub module_hide()
form1.visible=0
end sub

sub table1_drawCell(self as table, row as integer, col as integer, x as integer, y as integer)

    if updateOk then
	self!DrawText(str(row) + ":" + str(col), x, y, BLACK, "URW Roman", 10, 1)
    end if

end sub

sub scrollbar1_changed(self as scrollbar, scrollType as integer)
    const ST_DRAG 1
    const ST_DECREMENT 2
    const ST_INCREMENT 3
    const ST_PAGE_UP 4
    const ST_PAGE_DOWN 5
    
    select case scrollType
      case ST_DRAG
	table1.Scroll(self.value)
      case ST_PAGE_UP
	ScrollUpPage(self)
      case ST_PAGE_DOWN
	ScrollDownPage(self)
      case ST_DECREMENT
	ScrollUpRow(self)
      case ST_INCREMENT
	ScrollDownRow(self)
    end select
    
	
end sub

Sub ScrollUpRow(self as scrollbar)
    REM
    REM If not the first line, scroll the table up a line
    REM and put the thumb at the right place.
    REM

    if (table1.GetYPosAt(table1.firstVisibleRow) <0 ) then
	table1.firstVisibleRow = table1.firstVisibleRow
    else if table1.firstVisibleRow <> 0 then
	table1.firstVisibleRow = table1.firstVisibleRow -1
    end if
    
    self.value = table1.GetAbsYPosAt(table1.firstVisibleRow)
End Sub

Sub ScrollDownRow(self as scrollbar)
    REM
    REM If not the first line, scroll the table up a line
    REM and put the thumb at the right place.
    REM

    REM
    REM If the last row is not completly visible, make
    REM it so, else go down one more row.
    REM If the next line starts past the height, its not
    REM completely visible

    if (table1.numRows <> table1.firstVisibleRow +1) then
	table1.firstVisibleRow = table1.firstVisibleRow + 1
    end if

    self.value = table1.GetAbsYPosAt(table1.firstVisibleRow)
End Sub

Sub ScrollUpPage(self as scrollbar)
    REM
    REM If not on the first page, then scroll the table up a page
    REM and put the thumb at the right place
    REM
  dim ypos as integer
    table1.lastVisibleRow = table1.firstVisibleRow
    self.value = table1.GetAbsYPosAt(table1.firstVisibleRow)
    
End Sub

Sub ScrollDownPage(self as scrollbar)
    REM
    REM If not on the last page, then scroll the table down a page
    REM and put the thumb at the right place
    REM
    table1.firstVisibleRow = table1.lastVisibleRow
    self.value = table1.GetAbsYPosAt(table1.firstVisibleRow)
End Sub

sub table1_tableRedraw(self as table)

	REM If row 5 is visible,place b1 there, else make it not visible
	dim h as integer
	h = table1.GetYPosAt(5)
	if h = -1 then
		b1.visible = 0
		b1.top = -1
	else
		REM don't set if not necessary as that causes another redraw.
		b1.visible = 1
		if b1.top <> h then
			b1.top = h
			b1.left = 42
		end if
	end if
	
end sub

