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
top=90
left=77
sizeHControl=0
sizeVControl=0
tile=1
tileLayout=1
End CompInit
Dim group1 as group
group1 = MakeComponent("group",form1)
CompInit group1
proto="group1"
caption=""
look=1
tile=1
tileSpacing=2
sizeHControl=2
sizeVControl=2
visible=1
End CompInit
Dim gadget1 as gadget
gadget1 = MakeComponent("gadget",group1)
CompInit gadget1
proto="gadget1"
height=100
width=100
visible=1
End CompInit
gadget1.name="gadget1"
Dim group2 as group
group2 = MakeComponent("group",group1)
CompInit group2
proto="group2"
caption=""
tile=1
tileLayout=1
sizeHControl=0
sizeVControl=0
width=150
height=25
tileSpacing=2
visible=1
End CompInit
Dim randomize as button
randomize = MakeComponent("button",group2)
CompInit randomize
proto="randomize"
caption="randomize"
sizeHControl=0
sizeVControl=3
width=72
visible=1
End CompInit
randomize.name="randomize"
Dim reverse as button
reverse = MakeComponent("button",group2)
CompInit reverse
proto="reverse"
caption="reverse"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
reverse.name="reverse"
group2.name="group2"
Dim list1 as list
list1 = MakeComponent("list",group1)
CompInit list1
proto="list1"
width=56
sizeVControl=3
look=2
End CompInit
list1.name="list1"
list1.captions[1]="selection"
list1.captions[0]="bubble"
list1.visible=1
list1.selectedItem=0
Dim sort as button
sort = MakeComponent("button",group1)
CompInit sort
proto="sort"
caption="sort"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
sort.name="sort"
group1.name="group1"
Dim group3 as group
group3 = MakeComponent("group",form1)
CompInit group3
proto="group3"
caption=""
look=1
tile=1
sizeVControl=2
tileHAlign=2
tileVAlign=2
tileSpacing=2
sizeHControl=1
visible=1
End CompInit
Dim label6 as label
label6 = MakeComponent("label",group3)
CompInit label6
proto="label6"
caption="bubble sort"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
label6.name="label6"
Dim group6 as group
group6 = MakeComponent("group",group3)
CompInit group6
proto="group6"
caption="Elements:"
look=1
sizeHControl=2
sizeVControl=3
tile=1
tileLayout=1
visible=1
End CompInit
Dim label5 as label
label5 = MakeComponent("label",group6)
CompInit label5
proto="label5"
caption="N/A"
visible=1
End CompInit
label5.name="label5"
group6.name="group6"
Dim group4 as group
group4 = MakeComponent("group",group3)
CompInit group4
proto="group4"
caption="Compares:"
look=1
sizeHControl=2
sizeVControl=3
tile=1
tileLayout=1
visible=1
End CompInit
Dim label2 as label
label2 = MakeComponent("label",group4)
CompInit label2
proto="label2"
caption="N/A"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
label2.name="label2"
group4.name="group4"
Dim group5 as group
group5 = MakeComponent("group",group3)
CompInit group5
proto="group5"
caption="Swaps:"
look=1
tile=1
tileLayout=1
sizeHControl=2
sizeVControl=3
visible=1
End CompInit
Dim label4 as label
label4 = MakeComponent("label",group5)
CompInit label4
proto="label4"
caption="N/A"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
label4.name="label4"
group5.name="group5"
Dim group8 as group
group8 = MakeComponent("group",group3)
CompInit group8
proto="group8"
caption="Time:"
look=1
sizeHControl=2
sizeVControl=3
tile=1
tileLayout=1
visible=1
End CompInit
Dim label7 as label
label7 = MakeComponent("label",group8)
CompInit label7
proto="label7"
caption="0.000"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
label7.name="label7"
group8.name="group8"
group3.name="group3"
Dim popup1 as popup
popup1 = MakeComponent("popup",form1)
CompInit popup1
proto="popup1"
caption="Help"
visible=1
End CompInit
Dim button4 as button
button4 = MakeComponent("button",popup1)
CompInit button4
proto="button4"
caption="About this program..."
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
button4.name="button4"
popup1.name="popup1"
form1.name="form1"
form1.height=275
form1.width=403
Dim timedate1 as timedate
timedate1 = MakeComponent("timedate","app")
CompInit timedate1
proto="timedate1"
End CompInit
timedate1.name="timedate1"
Dim dialog1 as dialog
dialog1 = MakeComponent("dialog","app")
CompInit dialog1
proto="dialog1"
left=185
top=151
tile=1
caption=""
tileSpacing=1
tileHInset=1
tileVInset=1
End CompInit
Dim text2 as text
text2 = MakeComponent("text",dialog1)
CompInit text2
proto="text2"
sizeHControl=2
sizeVControl=2
readOnly=1
End CompInit
text2.name="text2"
text2.AppendString("This program demonstrates several simple sorting algorithms. It also shows how to use various NewBASIC components including lists, buttons and gadgets.")
text2.visible=1
Dim button10 as button
button10 = MakeComponent("button",dialog1)
CompInit button10
proto="button10"
caption="OK"
sizeHControl=3
sizeVControl=3
closeDialog=1
visible=1
End CompInit
button10.name="button10"
dialog1.name="dialog1"
dialog1.width=225
dialog1.height=145
EnableEvents()
duplo_start()
end sub

sub duplo_start()
	REM declare globals here
	dim list[200] as integer
	dim numElements as integer
	dim numCompares as integer
	dim numSwaps as integer
	
	REM set the number of elements to the height or 200
	numElements = 200
	if (gadget1.height < 200) then
		numElements = gadget1.height
	end if
	label5.caption = str(numElements)
	draw_array(list, numElements, gadget1)
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

sub random_array(list[] as integer, num as integer, max as integer)
dim i as integer

for i = 0 to num-1
	list[i] = rnd()*max
next i
end sub

sub draw_array(list[] as integer, num as integer, gadget as component)
	dim i as integer
	
	for i = 0 to num-1
		draw_element(list[i], i, -1, gadget)
	next i
end sub

sub randomize_pressed(self as button)
	random_array(list, numElements, gadget1.width)
	draw_array(list, numElements, gadget1)
end sub

sub bubble_sort(list[] as integer, min as integer, max as integer)
dim i as integer
dim j as integer
dim temp as integer
dim sorted as integer

i = min
sorted = 0
do while (i < max AND NOT(sorted))
	sorted = 1
	i = i + 1
	for j = min to max-i
		numCompares = numCompares + 1
		if (list[j] > list[j+1]) then
			temp = list[j]
			list[j] = list[j+1]
			list[j+1] = temp
			sorted = 0
			numSwaps = numSwaps + 1
		end if
		draw_element(list[j+1], j+1, j+1, gadget1)
		draw_element(list[j], j, -1, gadget1)
	next j
loop

end sub

sub draw_element(value as integer, index as integer, interest as integer, gadget as component)
dim color as long

if (index = interest) then
	color = &hff0000aa	REM dark blue 100%
else
	color = &hffffffff	REM white 100%
end if
gadget.DrawHLine(0, value, index, color)
gadget.DrawHLine(value+1, gadget.width, index, &hff000000)

end sub

sub sort_pressed(self as button)
	dim starttime as long
	dim seconds as integer
	
	starttime = timedate1.systemClock

	numSwaps = 0
	numCompares = 0
	
	select case list1.selectedItem
		case 0
			bubble_sort(list, 0, numElements-1)
		case 1
			selection_sort(list, 0, numElements-1)
	end select
	
	REM redraw the array sorted	
	draw_array(list, numElements, gadget1)
	
	REM calculate the time we took to sort and display it
	seconds = timedate1.systemClock - starttime
	label7.caption = str(seconds/1000)+"."+str(seconds mod 1000)
	
	REM display the number of comparisons and swaps
	label2.caption = str(numCompares)
	label4.caption = str(numSwaps)
end sub

sub reverse_pressed(self as button)
dim i as integer
dim value as integer

value = gadget1.width
for i = 0 to numElements-1
	list[i] = value
	value = value - rnd()*3 + 1
	if value < 0 then
		value = 0
	end if
next i
draw_array(list, numElements, gadget1)
end sub

sub list1_changed(self as list, index as integer)
	self.caption = self.captions[index]
	label6.caption = self.captions[index] + " sort"
end sub

sub selection_sort(list[] as integer, min as integer, max as integer)
dim i as integer
dim j as integer
dim bestValue as integer
dim bestJ as integer

for i = min to max-1
	bestValue = list[i]
	bestJ = i
	for j = i+1 to max
		numCompares = numCompares + 1
		if list[j] < bestValue then
			bestValue = list[j]
			bestJ = j
		end if
	next j
	list[bestJ] = list[i]
	list[i] = bestValue
	numSwaps = numSwaps + 1
	draw_element(list[i], bestJ, bestJ, gadget1)
	draw_element(list[bestJ], i, -1, gadget1)
next i
end sub

sub gadget1_draw(self as gadget)
	REM redraw ourselves in case the window moves
	draw_array(list, numElements, self)
end sub

SUB heap_push_down(list[] AS INTEGER, min AS INTEGER, max AS INTEGER)
DIM temp AS INTEGER
DIM j AS INTEGER
temp = list[min]
DO
	j = 2*min
	numCompares = numCompares + 1
	IF (j < max) THEN
		REM make j point to the larger child
		numCompares = numCompares + 1
		IF (j < max) THEN
			numCompares = numCompares + 1
			IF (list[j+1] > list[j]) THEN
				j = j + 1
			END IF
		END IF
		
		numCompares = numCompares + 1
		IF (list[j] > temp) THEN
			list[min] = list[j]
			min = j
		ELSE
			EXIT DO
		END IF
	ELSE
		EXIT DO
	END IF
LOOP
numSwaps = numSwaps + 1
list[min] = temp

END SUB

sub button4_pressed(self as button)
	dialog1.visible = 1
end sub

