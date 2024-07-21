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
top=25
left=25
sizeHControl=0
sizeVControl=0
tile=1
caption="Artillery!"
End CompInit
Dim group1 as group
group1 = MakeComponent("group",form1)
CompInit group1
proto="group1"
caption=""
look=2
sizeHControl=3
sizeVControl=0
height=300
visible=1
End CompInit
Dim gadget1 as gadget
gadget1 = MakeComponent("gadget",group1)
CompInit gadget1
proto="gadget1"
left=2
top=3
width=500
height=288
visible=1
End CompInit
gadget1.name="gadget1"
group1.name="group1"
Dim group2 as group
group2 = MakeComponent("group",form1)
CompInit group2
proto="group2"
caption="group2"
look=2
sizeHControl=2
sizeVControl=3
tile=1
tileLayout=1
visible=1
End CompInit
Dim groupi as group
groupi = MakeComponent("group",group2)
CompInit groupi
proto="groupi"
caption="Player 1"
look=1
tile=1
tileLayout=1
sizeVControl=3
sizeHControl=0
tileHAlign=2
width=288
enabled=0
visible=1
End CompInit
Dim ang1 as number
ang1 = MakeComponent("number",groupi)
CompInit ang1
proto="ang1"
caption="Angle"
maximum=90
displayFormat=0
sizeHControl=3
sizeVControl=3
value=55
visible=1
End CompInit
ang1.name="ang1"
Dim pow1 as number
pow1 = MakeComponent("number",groupi)
CompInit pow1
proto="pow1"
caption="Powder"
displayFormat=0
maximum=250
sizeHControl=3
sizeVControl=3
value=50
visible=1
End CompInit
pow1.name="pow1"
Dim fire1 as button
fire1 = MakeComponent("button",groupi)
CompInit fire1
proto="fire1"
caption="Fire!"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
fire1.name="fire1"
groupi.name="groupi"
Dim groupii as group
groupii = MakeComponent("group",group2)
CompInit groupii
proto="groupii"
caption="Player 2"
look=1
tile=1
tileLayout=1
sizeHControl=0
sizeVControl=3
enabled=0
width=288
tileHAlign=3
visible=1
End CompInit
Dim ang2 as number
ang2 = MakeComponent("number",groupii)
CompInit ang2
proto="ang2"
caption="Angle"
maximum=90
displayFormat=0
sizeHControl=3
sizeVControl=3
value=55
visible=1
End CompInit
ang2.name="ang2"
Dim pow2 as number
pow2 = MakeComponent("number",groupii)
CompInit pow2
proto="pow2"
caption="Powder"
maximum=250
displayFormat=0
sizeHControl=3
sizeVControl=3
value=50
visible=1
End CompInit
pow2.name="pow2"
Dim fire2 as button
fire2 = MakeComponent("button",groupii)
CompInit fire2
proto="fire2"
caption="Fire!"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
fire2.name="fire2"
groupii.name="groupii"
group2.name="group2"
Dim group5 as group
group5 = MakeComponent("group",form1)
CompInit group5
proto="group5"
caption="Score"
look=1
sizeHControl=2
sizeVControl=3
tile=1
tileHAlign=1
tileLayout=1
visible=1
End CompInit
Dim score1 as label
score1 = MakeComponent("label",group5)
CompInit score1
proto="score1"
caption="Wins: 0"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
score1.name="score1"
Dim newGame as button
newGame = MakeComponent("button",group5)
CompInit newGame
proto="newGame"
caption="New Game"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
newGame.name="newGame"
Dim score2 as label
score2 = MakeComponent("label",group5)
CompInit score2
proto="score2"
caption="Wins: 0"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
score2.name="score2"
group5.name="group5"
Dim popup1 as popup
popup1 = MakeComponent("popup",form1)
CompInit popup1
proto="popup1"
caption="Options"
left=0
top=0
visible=1
End CompInit
Dim terrainMenu as popup
terrainMenu = MakeComponent("popup",popup1)
CompInit terrainMenu
proto="terrainMenu"
caption="Terrain"
left=0
top=0
visible=1
End CompInit
Dim terrPlains as choice
terrPlains = MakeComponent("choice",terrainMenu)
CompInit terrPlains
proto="terrPlains"
caption="Plains"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
terrPlains.name="terrPlains"
Dim terrHills as choice
terrHills = MakeComponent("choice",terrainMenu)
CompInit terrHills
proto="terrHills"
caption="Hills"
sizeHControl=3
sizeVControl=3
status=1
visible=1
End CompInit
terrHills.name="terrHills"
Dim terrMnts as choice
terrMnts = MakeComponent("choice",terrainMenu)
CompInit terrMnts
proto="terrMnts"
caption="Mountains"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
terrMnts.name="terrMnts"
terrainMenu.name="terrainMenu"
Dim windOn as toggle
windOn = MakeComponent("toggle",popup1)
CompInit windOn
proto="windOn"
caption="Wind"
sizeHControl=3
sizeVControl=3
status=1
visible=1
End CompInit
windOn.name="windOn"
Dim trailsOn as toggle
trailsOn = MakeComponent("toggle",popup1)
CompInit trailsOn
proto="trailsOn"
caption="Trails"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
trailsOn.name="trailsOn"
popup1.name="popup1"
form1.width=591
form1.height=417
form1.name="form1"
Dim shot as timer
shot = MakeComponent("timer","app")
CompInit shot
proto="shot"
interval=3
End CompInit
shot.name="shot"
Dim explosion as timer
explosion = MakeComponent("timer","app")
CompInit explosion
proto="explosion"
interval=10
End CompInit
explosion.name="explosion"
EnableEvents()
duplo_start()
end sub

sub duplo_start()
REM width of field
CONST G_WIDTH 500
REM 360/2pi
CONST OEOP 57.2958

DIM ground[G_WIDTH] AS INTEGER
DIM px[2] AS INTEGER
DIM score[2] AS INTEGER
DIM wind AS INTEGER

DIM toEnable AS COMPONENT

InitGame()

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

sub gadget1_draw(self as gadget)
DIM i AS INTEGER
DIM x AS INTEGER
DIM y AS INTEGER
DIM c AS LONG

REM draw the sky
FOR i = self.height TO 0 STEP -4
	c = SkyColorForY(self.height-i)
	self.DrawRect(0, i, self.width, i+4, c)
NEXT i

REM draw the ground
FOR i = 0 TO G_WIDTH-1
	self.DrawVLine(self.height, self.height-ground[i], i, DARK_GREEN)
NEXT i

REM draw the players
DrawPlayers()

REM if not playing, draw the title
IF (newGame.enabled) THEN
	x = self.width/2 - self.TextWidth("Artillery!","Sather Gothic", 72, 0)/2
	self.DrawText("Artillery!", x+4, 74, BLACK, "Sather Gothic", 72, 0)	
	self.DrawText("Artillery!", x, 70, YELLOW, "Sather Gothic", 72, 0)
ELSE IF (windOn.status) THEN
	REM draw the arrow to indicate wind speed
	x = self.width/2
	y = 30
	self.DrawHLine(x,x+wind,y-2,YELLOW)
	self.DrawVLine(y-2,y-7,x+wind,YELLOW)
	i = SGN(wind)
	IF (i = 0) THEN
		i = 1
	END IF
	self.DrawLine(x+wind,y-7,x+wind+7*i,y,YELLOW)
	self.DrawLine(x+wind,y+7,x+wind+7*i,y,YELLOW)
	self.DrawVLine(y+2,y+7,x+wind,YELLOW)
	self.DrawHLine(x,x+wind,y+2,YELLOW)
	self.DrawVLine(y-2,y+2,x,YELLOW)

	IF (wind < 0) THEN
		x = x + 15
	ELSE
		x = x - 25
	END IF
	self.DrawText(STR(ABS(wind)), x, y-10, YELLOW, "Berkeley", 14, 0)
END IF

end sub

sub FireShot(startX AS INTEGER, startY AS INTEGER, angle AS INTEGER, power AS INTEGER, signX AS INTEGER)

shot.x = startX
shot.y = startY+1
shot.dx = COS(angle/OEOP)*(power*0.15)*signX
shot.dy = SIN(angle/OEOP)*(power*0.15)

shot.enabled = 1

end sub

sub fire1_pressed(self as button)
	self.enabled = 0
	groupi.enabled = 0
	toEnable = groupii
	FireShot(px[0], ground[px[0]], ang1.value, pow1.value, 1)
end sub

sub fire2_pressed(self as button)
	self.enabled = 0
	groupii.enabled = 0
	toEnable = groupi
	FireShot(px[1], ground[px[1]], ang2.value, pow2.value, -1)
end sub

sub DrawPlayers()
DIM i AS INTEGER
DIM x AS INTEGER
DIM y AS INTEGER

REM draw the players
FOR i = 0 TO 1
	x = px[i]
	y = gadget1.height-ground[px[i]]
	gadget1.DrawRect(x-4, y-4, x+4, y+4, WHITE)
NEXT i

end sub

sub InitGame()

DIM i AS INTEGER
DIM p AS INTEGER
DIM g AS INTEGER
DIM rc AS INTEGER
DIM rcc AS INTEGER

rc = 7
rcc = 3
IF (terrPlains.status) THEN
	rc = 0
	rcc = 0
ELSE IF (terrMnts.status) THEN
	rc = 15
	rcc = 7
END IF

REM randomize the ground
ground[i] = 60
FOR i = 1 to G_WIDTH-1
	ground[i] = ground[i-1]+RND()*rc-rcc
	if (ground[i] < 0) then
		ground[i] = 0
	end if
NEXT i

REM randomize position of players
px[0] = RND()*G_WIDTH/4 + 10
px[1] = G_WIDTH-RND()*G_WIDTH/4 - 10
FOR p = 0 to 1
	g = ground[px[p]]+5
	FOR i = px[p]-5 to px[p]+5
		ground[i] = g
	NEXT i
NEXT p

REM randomize the wind speed
IF (windOn.status) THEN
	wind = RND()*39-19
ELSE
	wind = 0
END IF

end sub

sub explosion_ring(self as timer)
DIM xi AS INTEGER
DIM yi AS INTEGER
DIM e AS INTEGER
DIM c AS LONG
CONST EXPL_SIZE_MAX 20
xi = shot.x
yi = shot.y
IF (explosion.size <= EXPL_SIZE_MAX) THEN
	e = explosion.size
	DrawExplosion(xi, yi, e, DARK_GREY)
ELSE IF (explosion.size > EXPL_SIZE_MAX) THEN
	e = explosion.size-EXPL_SIZE_MAX
	REM DARK_BLUE means the sky color, not solid blue
	DrawExplosion(xi, yi, e, DARK_BLUE)
END IF
explosion.size = explosion.size + 2
IF (explosion.size > EXPL_SIZE_MAX*2) THEN
	self.enabled = 0
	explosion.size = 0
	GameEnded()
END IF
end sub

sub newGame_pressed(self as button)
	NewGame()
	newGame.enabled = 0
	terrainMenu.enabled = 0
	windOn.enabled = 0
	
	REM randomly choose player to start
	if (RND()<0.5) THEN
		groupi.enabled = 1
		groupii.enabled = 0
	ELSE
		groupi.enabled = 0
		groupii.enabled = 1
	END IF
	fire1.enabled = 1
	fire2.enabled = 1	
end sub

sub terrPlains_changed(self as choice)
	NewGame()
end sub

sub NewGame()
	
	REM initialize the field and draw it
	InitGame()
	gadget1.Redraw()

end sub

sub terrHills_changed(self as choice)
	NewGame()
end sub

sub terrMnts_changed(self as choice)
	NewGame()
end sub

sub GameEnded()
	newGame.enabled = 1
	groupi.enabled = 0
	groupii.enabled = 0
	score1.caption = "Wins: "+STR(score[0])
	score2.caption = "Wins: "+STR(score[1])
	windOn.enabled = 1
	terrainMenu.enabled = 1
end sub

sub ang2_changed(self as number, value as integer)
	fire2.enabled = 1
end sub

sub pow2_changed(self as number, value as integer)
	fire2.enabled = 1
end sub

sub pow1_changed(self as number, value as integer)
	fire1.enabled = 1
end sub

sub ang1_changed(self as number, value as integer)
	fire1.enabled = 1
end sub

function SkyColorForY(y AS INTEGER) AS LONG
DIM foo AS LONG
foo = (gadget1.height-y)*255.0/gadget1.height
SkyColorForY = foo BITOR &HFF000000
end function

sub DrawExplosion(xc AS INTEGER, yc AS INTEGER, radius AS INTEGER, mode AS FLOAT)
DIM xl AS INTEGER
DIM yl AS INTEGER
DIM al AS INTEGER
DIM a AS FLOAT
DIM c1 AS LONG
DIM c2 AS LONG

FOR al = 0 TO 90 STEP 3
	a = al/OEOP
	xl = COS(a)*radius
	yl = SIN(a)*radius
	SELECT CASE(mode)
	CASE DARK_BLUE
		c1 = SkyColorForY(yc-yl)
		c2 = SkyColorForY(yc+yl)
	CASE ELSE
		c1 = mode
		c2 = mode
	END SELECT
	gadget1.DrawHLine(xc-xl,xc+xl,gadget1.height-(yc-yl),c1)
	gadget1.DrawHLine(xc-xl,xc+xl,gadget1.height-(yc+yl),c2)
NEXT al
	
end sub

sub shot_ring(self as timer)
DIM i AS INTEGER
DIM done AS INTEGER
DIM c AS LONG
DIM xi AS INTEGER
DIM yi AS INTEGER
DIM msk AS LONG

done = FALSE
shot.ox = shot.x
shot.oy = shot.y
shot.x = shot.x + shot.dx + (wind*.05)
shot.y = shot.y + shot.dy
shot.dy = shot.dy-0.15
xi = shot.ox
yi = shot.oy
c = SkyColorForY(yi) BITAND &H00FFFFFF
IF (trailsOn.status) THEN
	msk = &H80000000
ELSE
	msk = &HFF000000
END IF
gadget1.DrawRect(xi-1,gadget1.height-yi-1, xi+1, gadget1.height-yi+1, c BITOR msk)
xi = shot.x
yi = shot.y
gadget1.DrawRect(xi-1,gadget1.height-yi-1,xi+1,gadget1.height-yi+1, WHITE)

REM see if we've gone off the left edge
IF (shot.x<0) THEN
	done = TRUE
END IF

REM see if we've gone off the right edge
IF (shot.x > G_WIDTH-1) THEN
	done = TRUE
END IF

REM see if we've hit the ground
IF (NOT(done)) THEN
	IF (shot.y <= ground[shot.x]) THEN
		done = TRUE
	END IF
	
	REM see if we hit anything
	FOR i = 0 TO 1
		IF (shot.x < px[i]+6 AND shot.x > px[i]-6 AND shot.y < ground[shot.x] + 5) THEN
			REM we hit something
			shot.y = ground[shot.x]
			explosion.size = 0
			explosion.enabled = 1
			score[1-i] = score[1-i] + 1
			done = TRUE
		END IF
	NEXT i
END IF

IF (done) THEN
	toEnable.enabled = 1
	shot.enabled = 0
	xi = shot.x
	yi = shot.y
	gadget1.DrawRect(xi-1,gadget1.height-yi-1,xi+1,gadget1.height-yi+1, BLACK)
END IF

REM redraw the players
DrawPlayers()

end sub

