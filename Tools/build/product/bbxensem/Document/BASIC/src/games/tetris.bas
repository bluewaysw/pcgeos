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
caption="Tetris"
proto="form1"
top=31
left=120
sizeHControl=0
sizeVControl=0
End CompInit
Dim gadget1 as gadget
gadget1 = MakeComponent("gadget",form1)
CompInit gadget1
proto="gadget1"
left=2
top=25
height=341
width=188
visible=1
End CompInit
gadget1.name="gadget1"
Dim popup1 as popup
popup1 = MakeComponent("popup",form1)
CompInit popup1
proto="popup1"
caption="Options"
top=0
left=0
visible=1
End CompInit
Dim NewGameButton as button
NewGameButton = MakeComponent("button",popup1)
CompInit NewGameButton
proto="NewGame"
caption="New Game"
visible=1
End CompInit
NewGameButton.name="NewGameButton"
Dim PauseButton as button
PauseButton = MakeComponent("button",popup1)
CompInit PauseButton
proto="Pause"
caption="Pause"
visible=1
End CompInit
PauseButton.name="PauseButton"
Dim FancyDraw as button
FancyDraw = MakeComponent("button",popup1)
CompInit FancyDraw
proto="FancyDraw"
caption="Plain Tiles"
visible=1
End CompInit
FancyDraw.name="FancyDraw"
popup1.name="popup1"
Dim group1 as group
group1 = MakeComponent("group",form1)
CompInit group1
proto="group1"
caption="group1"
left=4
top=5
height=15
look=2
sizeHControl=2
visible=1
End CompInit
Dim Score as label
Score = MakeComponent("label",group1)
CompInit Score
proto="Score"
caption="Score:"
left=79
top=1
width=98
visible=1
End CompInit
Score.name="Score"
Dim Lines as label
Lines = MakeComponent("label",group1)
CompInit Lines
proto="Lines"
caption="Lines: "
left=3
top=1
width=70
visible=1
End CompInit
Lines.name="Lines"
group1.name="group1"
form1.name="form1"
form1.height=414
form1.width=204
Dim timer1 as timer
timer1 = MakeComponent("timer","app")
CompInit timer1
proto="timer1"
interval=10
End CompInit
timer1.name="timer1"
EnableEvents()
duplo_start()
end sub

sub module_show()
    form1.visible = 1
end sub

sub module_hide()
    form1.visible = 0
end sub

sub duplo_start()
REM FILE: 	 Tetris.bas
REM $Revision:   1.12  $

CONST KEY_UP		144
CONST KEY_LEFT		147
CONST KEY_RIGHT		146
CONST KEY_DOWN		145

STRUCT Block
DIM top as integer
DIM left as integer
DIM bottom as integer
DIM right as integer
DIM index as integer
DIM mask as integer
DIM maskIndex as integer
DIM masks as integer
DIM blockWidth as integer
DIM type as integer
DIM color as long
END STRUCT

dim allBlocks[1000] as STRUCT Block
dim curBlock as integer
dim ticks as integer
dim score as integer
dim lines as integer
dim fancyDraw as integer

rem CONST TRUE 1, FALSE 0
CONST SIZE 17
CONST IDLE 0, TIMER_RING 1, CHAR_INPUT 2

CONST RIGHT 0, LEFT 1, DOWN 2

CONST GRAY  &Hffaaaaaa
CONST BACKGROUND GRAY

REM values telling how high the blocks are in each column

dim columns as integer, rows as integer
rem columns = form1.width/SIZE - 1
rem rows = form1.height/SIZE - 3
columns = 11
rows = 20
fancyDraw = TRUE

dim i as integer
dim grid[rows, columns] as integer
dim boardTop as integer

CONST BT_LINE 0, BT_J 1, BT_L 2, BT_SQUARE 3, BT_SNAKE_R 4, BT_SNAKE_L 5, BT_T 6, BT_MAX 7

dim shapeMasks[BT_MAX * 4] as integer
REM each shape is a 4X$ grid of points, go can be stuff into 16 bits (ie an integer)
InitShapeMasks()

CONST S_NONE 0, S_FALLING 1, S_DONE 2
CONST POS_1 0, POS_2 1, POS_3 2, POS_4 3

STRUCT State
dim     mode            as integer
dim block               as STRUCT Block
dim blockType   as integer
dim posX                as integer
dim posY                as integer
dim busy                as integer
dim turbo               as integer
end STRUCT

dim state as STRUCT State
rem NewGame_pressed(NewGameButton)

end sub

sub timer1_ring(self as timer)

dim newBlock as STRUCT Block, block as STRUCT Block
dim i as integer
dim maxtries as integer

ticks = ticks + 1
if ticks MOD 400 = 399 AND self.interval > 3 then
	self.interval = self.interval - 3
end if

select case state^mode
case S_NONE
	REM time to create a new block
	maxtries = 0
do
	state^mode = S_FALLING
	state^blockType = RND() * BT_MAX
rem state^blockType = BT_LINE
rem	newBlock = MakeComponent("gadget", form1)
	state^block = newBlock
	allBlocks[curBlock] = newBlock
	curBlock = curBlock + 1
	newBlock.type = state^blockType
	newBlock.left = (columns/2 - 1) * SIZE
	newBlock.index = 0
	newBlock.blockWidth = 2 * SIZE
	InitBlock(newBlock)
	newBlock.top = -SIZE * GetHeightFromMask(newBlock.mask)
	if CanMove(newBlock, DOWN, 1) OR maxtries > 20 then
		exit do
	end if
	maxtries = maxtries + 1
loop
	if maxtries > 20 then
		state^mode = S_DONE
		form1.caption = "Game Over"
		self.enabled = 0
	else
		DrawBlock(newBlock)
	end if
case S_FALLING
	block = state^block
	block.index = block.index + 1
	EraseBlock(block)

REM     if block.top/SIZE + 6 >= rows then
REM     if AtBottom(block) then
	if NOT CanMove(block, DOWN, state^turbo) then
		state^mode = S_NONE
		DrawBlock(block)
		UpdateBases(block)
	else
		block.top = block.top + SIZE * state^turbo
		DrawBlock(block)
	end if
end select

done:
end sub

sub DrawBlock(block as STRUCT Block)
DrawBlockLow(block, FALSE)
END sub

sub EraseBlock(block as STRUCT Block)
DrawBlockLow(block, TRUE)
END sub

sub DrawBlockLow(block as STRUCT Block, erase as integer)

DrawBlockFromMask(block, erase)

END sub

sub UpdateBases(block as STRUCT Block)

DIM startColumn as integer
startColumn = block.left/SIZE

dim top as integer, left  as integer
top = block.top/SIZE
left = block.left/SIZE

if top < boardTop then
	boardTop = top
end if

dim i as integer, x as integer, y as integer, mask as integer
mask = block.mask
x = 3
y = 3

for i = 15 to 0 step -1
	if top+y >= 0 then
		if GetBitFromMask(mask, i) then
			grid[top+y, left+x] = curBlock
		end if
	end if
	if x = 0 then
		x = 3
		y = y - 1
	else
		x = x - 1
	end if
next

score = score + 10
dim j as integer
dim done as integer

dim compact as integer
compact = FALSE

dim short as integer
if top < 0 then
	short = 3 + top
	top = 0
else
	short = block.bottom - 1
end if

for j = top to top + short
	done = TRUE
	for i = 0 to columns - 1
		if grid[j, i] = 0 then
			done = FALSE
		end if
	next i
	if (done) then
		compact = TRUE
		score = score + 50
		lines = lines + 1
        CompactLine(j)
	end if
next

Score.caption = "Score: " + STR(score)
Lines.caption = "Lines: " + STR(lines)
if compact then
	Update()
	gadget1_redraw(gadget1)
end if

end sub

sub gadget1_char(self as gadget, action as integer, char as integer, buttonState as integer)

dim mask as integer, newmask as integer
dim blockWidth as integer

if action <> 1 then
	goto done
end if

if state^busy OR (state^mode <> S_FALLING) then
	goto done
else
	state^busy = TRUE
end if
dim block as STRUCT Block

block = state^block
select case char 
CASE KEY_LEFT	 	rem ASC("j") 
	if CanMove(block, LEFT, 1) then
		EraseBlock(block)
		block.left = block.left - SIZE
		DrawBlock(block)
	end if
CASE KEY_RIGHT		rem ASC("l")
	if CanMove(block, RIGHT, 1) then
		EraseBlock(block)
		block.left = block.left + SIZE
		DrawBlock(block)
	end if
CASE KEY_UP	 	REM turn clockwise	ASC("a") 
	mask = block.maskIndex
	mask = mask + 1
	if (mask >= block.masks) then
		mask = 0
	end if
	EraseBlock(block)
	newmask = shapeMasks[block.type*4 + mask]
	blockWidth = GetWidthFromMask(newmask)
	if blockWidth <= block.blockWidth then
		block.maskIndex = mask
		block.blockWidth = blockWidth
		block.mask = newmask
    else if CanMove(block, RIGHT, blockWidth - block.blockWidth) then
		block.maskIndex = mask
		block.blockWidth = blockWidth
		block.mask = newmask
	end if

	block.bottom = GetBottomFromMask(block.mask)
	block.right = GetRightFromMask(block.mask)
	DrawBlock(block)

CASE ASC("d") REM turn counter clockwise
	mask = block.maskIndex
	mask = mask - 1
	if (mask < 0) then
		mask = block.masks - 1
	end if
	EraseBlock(block)
	newmask = shapeMasks[block.type*4 + mask]
	blockWidth = GetWidthFromMask(newmask)
	if blockWidth <= block.blockWidth then
		block.maskIndex = mask
		block.blockWidth = blockWidth
		block.mask = newmask
    else if CanMove(block, RIGHT, blockWidth - block.blockWidth) then
		block.maskIndex = mask
		block.blockWidth = blockWidth
		block.mask = newmask
	end if

	block.bottom = GetBottomFromMask(block.mask)
	block.right = GetRightFromMask(block.mask)
	DrawBlock(block)
CASE KEY_DOWN rem ASC(" ")


if 0 then REM drop straight to bottom
dim i as integer
i = boardTop - block.top/SIZE + 4

do
	if NOT CanMove(block, DOWN, i) then
		i = i - 1
		exit do
	end if
	i = i + 1
loop

	state^turbo = i
timer1_ring(timer1)
state^turbo = 1
end if 
    state^turbo = 8
	do
		if NOT CanMove(block, DOWN, state^turbo) then
			if state^turbo > 1 then
				state^turbo = state^turbo/2
			else
				exit do
			end if
		else
			timer1_ring(timer1)
		end if
	loop
end select

state^busy = FALSE
done:

end sub

sub DrawBlockSquare(x as integer, y as integer, erase as integer, color as long)

	if erase THEN
	        color = GRAY
	end if
		
    gadget1.DrawRect(x+1, y+1, x+SIZE, y+SIZE, color)

    IF not erase AND fancyDraw THEN
		
		DIM lcolor as long
		lcolor = color + &H00323232
		if color MOD &H00000100 = -1 THEN
		        lcolor = &Hffaaaaff
		end if

		gadget1.DrawHLine(x+1, x+(SIZE-1), y+1, lcolor)
		gadget1.DrawHLine(x+1, x+(SIZE-1), y+(SIZE-1), BLACK)
		gadget1.DrawVLine(y+1, y+(SIZE-1), x+1, lcolor)
		gadget1.DrawVLine(y+1, y+(SIZE-1), x+(SIZE-1), BLACK)

		gadget1.DrawHLine(x+3, x+(SIZE-3), y+3, lcolor)
		gadget1.DrawHLine(x+3, x+(SIZE-3), y+(SIZE-3), BLACK)
		gadget1.DrawVLine(y+3, y+(SIZE-3), x+3, lcolor)
		gadget1.DrawVLine(y+3, y+(SIZE-3), x+(SIZE-3), BLACK)
    END IF

end sub

sub gadget1_redraw(self as gadget)

dim i as integer, j as integer

self.DrawHLine(0, self.width, 0, BLACK)
self.DrawVLine(0, self.height, 0, BLACK)
self.DrawHLine(0, self.width, self.height-1, WHITE)
self.DrawVLine(0, self.height, self.width-1, WHITE)

if 0 then
for i = 0 to curBlock - 1
	DrawBlock(allBlocks[i])
next i
else
	dim block as STRUCT Block
	dim index as integer
	for j = 0 to rows - 1
		for i = 0 to columns - 1
			index = grid[j, i]
			if index then
				block = allBlocks[index-1]
				DrawBlockSquare(i*SIZE, j*SIZE, 0, block.color)
REM				self.DrawRect(i*SIZE,j*SIZE,i*SIZE+(SIZE-1),j*SIZE+(SIZE-1), block.red, block.blue, block.green, 255)
			end if
		next
	next
end if          
end sub

sub InitShapeMasks()


REM BT_LINE (VERT and HORIZONTAL)
CONST BT_LINE_VERT_MASK (BT_LINE*4), BT_LINE_HORIZ_MASK (BT_LINE*4)+1
shapeMasks[BT_LINE_VERT_MASK] = 8738  REM 2222h
shapeMasks[BT_LINE_HORIZ_MASK] = 3840     REM 0f00h

REM BT_SQUARE
CONST BT_SQUARE_MASK (BT_SQUARE*4)
shapeMasks[BT_SQUARE_MASK] = 13056      REM 3300h

CONST BT_T_1_MASK BT_T*4, BT_T_2_MASK BT_T_1_MASK+1, BT_T_3_MASK BT_T_2_MASK+1, BT_T_4_MASK BT_T_3_MASK+1
shapeMasks[BT_T_1_MASK] = 9984  REM 2700h
shapeMasks[BT_T_4_MASK] = 8992  REM 2320h
shapeMasks[BT_T_3_MASK] = 29184  REM 7200h
shapeMasks[BT_T_2_MASK] = 4880  REM 1310h

CONST BT_SNAKE_R_1_MASK BT_SNAKE_R*4, BT_SNAKE_R_2_MASK BT_SNAKE_R_1_MASK+1
shapeMasks[BT_SNAKE_R_1_MASK] = 8976   REM 2310h
shapeMasks[BT_SNAKE_R_2_MASK] = 13824  REM 3600h

CONST BT_SNAKE_L_1_MASK BT_SNAKE_L*4, BT_SNAKE_L_2_MASK BT_SNAKE_L_1_MASK+1
shapeMasks[BT_SNAKE_L_1_MASK] = 4896   REM 1320h
shapeMasks[BT_SNAKE_L_2_MASK] = 25344  REM 6300h

CONST BT_L_1_MASK BT_L*4, BT_L_2_MASK BT_L_1_MASK+1, BT_L_3_MASK BT_L_2_MASK+1, BT_L_4_MASK BT_L_3_MASK+1
shapeMasks[BT_L_1_MASK] = 12560   REM 3110h
shapeMasks[BT_L_4_MASK] = 5888    REM 1700h
shapeMasks[BT_L_3_MASK] = 8752   REM 2230h
shapeMasks[BT_L_2_MASK] = 29696   REM 7400h

CONST BT_J_1_MASK BT_J*4, BT_J_2_MASK BT_J_1_MASK+1, BT_J_3_MASK BT_J_2_MASK+1, BT_J_4_MASK BT_J_3_MASK+1
shapeMasks[BT_J_1_MASK] = 12832   REM 3220h
shapeMasks[BT_J_4_MASK] = 28928   REM 7100h
shapeMasks[BT_J_3_MASK] = 4400   REM 1130h
shapeMasks[BT_J_2_MASK] = 18176    REM 4700h

end sub

sub DrawBlockFromMask(block as STRUCT Block, erase as integer)

dim mask as integer
mask = block.mask
DIM color as long

if erase THEN
        color = GRAY
ELSE
        color = block.color
end if

dim bit as integer, i as integer
bit = -32767    REM 8000h

dim x as integer, y as integer
x = 0
y = 0
for i = 0 to 15
	if GetBitFromMask(mask, i) then
                DrawBlockSquare(block.left+x*SIZE, block.top+y*SIZE, erase, color)
	end if
	if (x = 3) then
		x = 0
		y = y + 1
	else
		x = x + 1
	end if
next
end sub

sub InitBlock(block as STRUCT Block)

dim mask as integer

block.bottom = 4
block.right = 4

select case block.type
	case BT_LINE
	        block.color = DARK_BLUE
			block.masks = 2
	case BT_SQUARE
	        block.color = DARK_RED
		block.masks = 1
	case BT_J
	        block.color = LIGHT_BLUE
			block.masks = 4
	case BT_L
	        block.color = DARK_PURPLE
			block.masks = 4
	case BT_SNAKE_R
	        block.color = DARK_CYAN
			block.masks = 2
	case BT_SNAKE_L
	        block.color = DARK_GRAY
			block.masks = 2
	case BT_T
	        block.color = DARK_GREEN
			block.masks = 4
end select

mask = block.masks * RND()
block.maskIndex = mask
block.mask = shapeMasks[block.type * 4 + mask]
block.bottom = GetBottomFromMask(block.mask)
block.right = GetRightFromMask(block.mask)
dim dummy as integer
dummy = GetWidthFromMask(block.mask)
block.blockWidth = dummy

end sub

function GetBitFromMask(mask as integer, bit as integer)

dim i as integer, m as integer

if bit = 15 then
	if (mask < 0) then 
		GetBitFromMask = TRUE
	else
		GetBitFromMask = FALSE
	end if
else
	if (mask < 0) then
		dim l as long
		l = mask
		l = l + 32768
		mask = l
	end if
	m = 16384 REM 4000h
	for i = 14 to 0 step -1
		if (i <> bit AND mask >= m) then
			mask = mask - m
		end if
		if (i <> 0) then
			m = m / 2
		end if
	next i
	GetBitFromMask = mask
end if

done:
end function

function CanMove(block as STRUCT Block, move as integer, amount as integer)

dim top as integer, left as integer
select case move
	case RIGHT
	top = block.top/SIZE
	left = block.left/SIZE + amount
case LEFT
	top = block.top/SIZE
	left = block.left/SIZE - amount
case DOWN
	top = block.top/SIZE + amount
	left = block.left/SIZE
end select

if left < 1-block.right OR top > rows - block.bottom OR left > columns - block.blockWidth then
	CanMove = FALSE
	goto done
end if

REM check grid to see if its open
dim mask as integer, i as integer, x as integer, y as integer
mask = block.mask
x = 0
y = 0
CanMove = TRUE
for i = 0 to 15
	if top+y >= 0 then
		if GetBitFromMask(mask, i) then
			if grid[top+y, left+x] then
				CanMove = FALSE
				exit for
			end if
		end if
	end if
	if x = 3 then
		x = 0
		y = y + 1
	else
		x = x + 1
	end if
next
done:
end function

function GetWidthFromMask(mask as integer) as integer

dim i as integer, j as integer
GetWidthFromMask = 0
for i = 3 to 0 step -1
	for j = 3 to 0 step -1
		if GetBitFromMask(mask, j * 4 + i) then
			GetWidthFromMask = i + 1
		end if
	next
	if GetWidthFromMask <> 0 then
		exit for
	end if
next

	
end function

sub CompactLine(line as integer)

dim i as integer, j as integer

for j = line to boardTop step -1
	for i = 0 to columns - 1
		grid[j, i] = grid[j-1, i]
	next
	EraseLine(j)
next



end sub

sub RedrawLine(line as integer)

dim i as integer

dim index as integer
dim block as STRUCT Block

gadget1.DrawRect(0, line*SIZE, (columns-1)*SIZE+(SIZE-1), line*SIZE+(SIZE-1), GRAY)

dim l as long
for l = 0 to 100000
next

for i = 0 to columns - 1
	index = grid[line, i]
 	if index then
		block = allBlocks[index-1]
		gadget1.DrawRect(i*SIZE,line*SIZE,i*SIZE+(SIZE-1),line*SIZE+(SIZE-1), block.color)
	end if
next
          
end sub

sub EraseLine(line as integer)

gadget1.DrawRect(1, line*SIZE + 1, columns*SIZE, (line+1)*SIZE, GRAY)
          
end sub

sub NewGame_pressed(self as button)

dim i as integer, j as integer

for j = 0 to rows - 1
	for i = 0 to columns - 1
		grid[j, i] = 0
	next
	EraseLine(j)
next

boardTop = rows
state^mode = S_NONE
state^busy = FALSE
state^turbo = 1
curBlock = 0
timer1.interval = 20
timer1.enabled = 1
score = 0
lines = 0
Score.caption = "Score: 0"
Lines.caption = "Lines: 0"
end sub

sub Pause_pressed(self as button)

if self.caption = "Continue" then
	self.caption = "Pause"
	timer1.enabled = 1
else
	self.caption = "Continue"
	timer1.enabled = 0
end if

end sub

sub FancyDraw_pressed(self as button)

if fancyDraw = TRUE then
	fancyDraw = FALSE
	FancyDraw.caption = "Fancy Tiles"
else
	fancyDraw = TRUE
	FancyDraw.caption = "Plain Tiles"
end if

gadget1_redraw(gadget1)

end sub

function GetHeightFromMask(mask as integer) as integer

dim i as integer, j as integer
GetHeightFromMask = 0

for i = 15 to 0 step -1
	if GetBitFromMask(mask, i) then
		exit for
	end if
next

for j = 0 to i
	if GetBitFromMask(mask, i) then
		GetHeightFromMask = i/4 - j/4 + 1
		exit for
	end if
next

end function

function GetBottomFromMask(mask as integer) as integer

dim i as integer, j as integer
GetBottomFromMask = 4

for i = 15 to 0 step -1
	if GetBitFromMask(mask, i) then
		GetBottomFromMask = i/4 + 1
		exit for
	end if
next


end function

function GetRightFromMask(mask as integer) as integer

dim i as integer, j as integer
GetRightFromMask = 0
for i = 0 to 3
	for j = 0 to 3
		if GetBitFromMask(mask, j * 4 + i) then
			GetRightFromMask = i + 1
		end if
	next
	if GetRightFromMask <> 0 then
		exit for
	end if
next

	
end function

