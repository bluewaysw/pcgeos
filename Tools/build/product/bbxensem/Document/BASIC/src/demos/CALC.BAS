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
Dim calc as form
calc = MakeComponent("form","app")
CompInit calc
caption="calc"
proto="calc"
left=219
top=145
End CompInit
Dim displayFrame as group
displayFrame = MakeComponent("group",calc)
CompInit displayFrame
caption=""
proto="displayFrame"
left=10
top=10
visible=1
End CompInit
displayFrame.name="displayFrame"
displayFrame.drawbox=1
Dim buttonClear as button
buttonClear = MakeComponent("button",calc)
CompInit buttonClear
caption="  C  "
proto="buttonClear"
top=48
left=82
sizeVControl=3
sizeHControl=3
visible=1
End CompInit
buttonClear.name="buttonClear"
Dim buttonClearEntry as button
buttonClearEntry = MakeComponent("button",calc)
CompInit buttonClearEntry
caption="  CE  "
proto="buttonClearEntry"
top=22
left=82
visible=1
End CompInit
buttonClearEntry.name="buttonClearEntry"
Dim buttonSeven as button
buttonSeven = MakeComponent("button",calc)
CompInit buttonSeven
caption="7"
proto="buttonSeven"
left=8
top=22
visible=1
End CompInit
buttonSeven.name="buttonSeven"
Dim buttonEight as button
buttonEight = MakeComponent("button",calc)
CompInit buttonEight
caption="8"
proto="buttonEight"
left=32
top=22
visible=1
End CompInit
buttonEight.name="buttonEight"
Dim buttonNine as button
buttonNine = MakeComponent("button",calc)
CompInit buttonNine
caption="9"
proto="buttonNine"
left=56
top=22
visible=1
End CompInit
buttonNine.name="buttonNine"
Dim buttonDivide as button
buttonDivide = MakeComponent("button",calc)
CompInit buttonDivide
caption="/"
proto="buttonDivide"
left=106
top=96
visible=1
End CompInit
buttonDivide.name="buttonDivide"
Dim buttonFour as button
buttonFour = MakeComponent("button",calc)
CompInit buttonFour
caption="4"
proto="buttonFour"
left=8
top=48
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
buttonFour.name="buttonFour"
Dim buttonFive as button
buttonFive = MakeComponent("button",calc)
CompInit buttonFive
caption="5"
proto="buttonFive"
left=32
top=48
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
buttonFive.name="buttonFive"
Dim buttonSix as button
buttonSix = MakeComponent("button",calc)
CompInit buttonSix
caption="6"
proto="buttonSix"
left=56
top=48
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
buttonSix.name="buttonSix"
Dim buttonMultiply as button
buttonMultiply = MakeComponent("button",calc)
CompInit buttonMultiply
caption="*"
proto="buttonMultiply"
left=82
top=96
visible=1
End CompInit
buttonMultiply.name="buttonMultiply"
Dim buttonOne as button
buttonOne = MakeComponent("button",calc)
CompInit buttonOne
caption="1"
proto="buttonOne"
left=8
top=72
visible=1
End CompInit
buttonOne.name="buttonOne"
Dim buttonTwo as button
buttonTwo = MakeComponent("button",calc)
CompInit buttonTwo
caption="2"
proto="buttonTwo"
left=32
top=72
visible=1
End CompInit
buttonTwo.name="buttonTwo"
Dim buttonThree as button
buttonThree = MakeComponent("button",calc)
CompInit buttonThree
caption="3"
proto="buttonThree"
left=56
top=72
visible=1
End CompInit
buttonThree.name="buttonThree"
Dim buttonSubtract as button
buttonSubtract = MakeComponent("button",calc)
CompInit buttonSubtract
caption="-"
proto="buttonSubtract"
left=106
top=72
visible=1
End CompInit
buttonSubtract.name="buttonSubtract"
Dim buttonZero as button
buttonZero = MakeComponent("button",calc)
CompInit buttonZero
caption="0"
proto="buttonZero"
left=8
top=96
visible=1
End CompInit
buttonZero.name="buttonZero"
Dim buttonDecimal as button
buttonDecimal = MakeComponent("button",calc)
CompInit buttonDecimal
caption="."
proto="buttonDecimal"
left=33
top=96
visible=1
End CompInit
buttonDecimal.name="buttonDecimal"
Dim buttonEquals as button
buttonEquals = MakeComponent("button",calc)
CompInit buttonEquals
caption="="
proto="buttonEquals"
left=55
top=96
visible=1
End CompInit
buttonEquals.name="buttonEquals"
Dim buttonAdd as button
buttonAdd = MakeComponent("button",calc)
CompInit buttonAdd
caption="+"
proto="buttonAdd"
left=82
top=72
visible=1
End CompInit
buttonAdd.name="buttonAdd"
Dim display as label
display = MakeComponent("label",calc)
CompInit display
caption="0"
proto="display"
left=5
top=5
width=84
height=16
visible=1
End CompInit
display.name="display"
calc.name="calc"
calc.height=142
calc.width=136
EnableEvents()
duplo_start()
end sub

sub duplo_start()

	REM calc
	REM ----
	REM Roy Goldman
	REM
	REM Copyright (c) Geoworks 1995 -- All Rights Reserved
	REM $Revision:   1.0  $
	REM
	REM 
	REM A simple calculator to demonstrate how applications
	REM are created in Legos.
	REM 
	REM This top level routine is used for declaring module
	REM variables, constants, and any other initializations
	REM pertinent to the rest of the program.  The UI will
	REM already have been created and set visible by the
	REM time this routine is executed.

	REM Operation "Constants"
	REM Note that there is no need to predeclare variables

	const NONE 0, ADD 1, SUBTRACT 2, MULTIPLY 3, DIVIDE 4

	REM These variables reflect the calculator's state
	REM They will be defined elsewhere, but declare them
	REM here to assure they are treated as module-level
	REM variables.

	REM The first operand for any operation:  
	dim operand1 as float

	REM The current operation, always one of the "constants"
	REM defined above.
	dim op as integer

	REM The string representation of the number currently displayed
	dim numstring as string

	REM The number of remaining spots available in our display
	dim pad as integer

	REM Whether or not a decimal is part of the current number
	REM being entered. Always 0 or 1.
	dim decimal as integer

	REM Whether or not the display should be cleared on the next
	REM keypress; this is the case, for example, after an operation.
	dim clearOnNextKey as integer
	
	REM Note that event handlers may be called as regular subroutines.
	REM We take advantage of this to initialize our calculator
	REM in the exact same way clicking on the Clear button does!
	REM An event handler always takes its matching component as its
	REM only argument.

	buttonClear_pressed(buttonClear)
	
end sub

sub module_show()
    calc.visible=1
end sub

sub module_hide()
    calc.visible=0
end sub

sub buttonClear_pressed(self as component)

	REM Clear all state

	buttonClearEntry_pressed(buttonClearEntry)

	REM Clear is similar to a clear-entry
	REM except we also clear the computational state

	operand1 = 0.0
	op = NONE
end sub

sub buttonClearEntry_pressed(self as component)
	
	REM Clear the current entry but maintain state
	REM of previous operand and current operation if
	REM one exists.

	clearDisplayVariables()
	display.caption = numstring

end sub

sub buttonZero_pressed(self as component)
	REM In this example application, we have a separate
	REM event handler for each digit key.
	REM That is, we have buttonZero_pressed, buttonOne_pressed, ...
	REM buttonNine_pressed, each of which gets called when
	REM the matching button is pressed.
	REM This is easy understand but is inefficient. Future
	REM releases will have ways to "pool" components together
	REM and enable the user to write one handler for multiple
	REM components.

	REM For each digit key, we call our appendDigit routine with
	REM the appropriate argument.
	appendDigit(0)
end sub

sub buttonOne_pressed(self as component)
	appendDigit(1)
end sub

sub buttonTwo_pressed(self as component)
	appendDigit(2)
end sub

sub buttonThree_pressed(self as component)
	appendDigit(3)
end sub

sub buttonFour_pressed(self as component)
	appendDigit(4)
end sub

sub buttonFive_pressed(self as component)
	appendDigit(5)
end sub

sub buttonSix_pressed(self as component)
	appendDigit(6)
end sub

sub buttonSeven_pressed(self as component)
	appendDigit(7)
end sub

sub buttonEight_pressed(self as component)
	appendDigit(8)
end sub

sub buttonNine_pressed(self as component)
	appendDigit(9)
end sub

sub buttonDecimal_pressed(self as component)
	
	REM Append a decimal to the current number,
	REM clearing the current display if necessary.

	if clearOnNextKey = 1 then
		clearDisplayVariables()
	end if

	if decimal = 0 then
		REM Addition of two strings is a simple concatenation
		numstring = numstring + "."

		REM This next line actually changes the visual display
		display.caption = numstring

		decimal = 1
	end if
end sub

sub buttonAdd_pressed(self as component)
	processOp1()
	op = ADD
end sub

sub buttonSubtract_pressed(self as component)
	processOp1()
	op = SUBTRACT
end sub

sub buttonMultiply_pressed(self as component)
	processOp1()
	op = MULTIPLY
end sub

sub buttonDivide_pressed(self as component)
	processOp1()
	op = DIVIDE
end sub

sub buttonEquals_pressed(self as component)

   dim operand2 as float	
   
   if op <> NONE and clearOnNextKey = 0 then

		operand2 = val(numstring)

		select case op
			case ADD
		  		operand1 = operand1 + operand2

			case SUBTRACT
		  		operand1 = operand1 - operand2

			case MULTIPLY
		  		operand1 = operand1 * operand2

			case DIVIDE
		  		operand1 = operand1 / operand2

		end select

		numstring = str(operand1)
	 	display.caption = numstring
   end if

   clearOnNextKey = 1
   op = NONE

end sub

sub processOp1()

	REM Called when a user hits any operation key,
	REM this routine first evaluates the last operation
	REM if needed and then initializes operand1.

	if op <> NONE then
		REM Note that we can safely call event handlers
		REM within our code.
		buttonEquals_pressed(buttonEquals)
	end if

	REM Visual Basic will automatically convert strings into
	REM numbers and vice-versa. Legos currently requires
	REM explict use of the VAL function to convert strings
	REM to numbers and the STR routine to convert numbers
	REM to strings.

	operand1 = val(numstring)
	clearOnNextKey = 1
end sub

sub appendDigit(digit as integer)

	REM Called to process the keypress of any digit.
	
	if clearOnNextKey then
		clearDisplayVariables()
	end if

	if pad > 0 then

		if numstring = "0" and digit > 0 then 

			REM Only a 0 is displayed, replace it with new digit
			numstring = str(digit)
		else

			REM No else if construct yet. Soon. Soon.

			if numstring <> "0" then

				REM First digit isn't a 0 so add anything

				numstring = numstring + str(digit)
				pad = pad - 1
			end if
		end if

		display.caption = numstring
	end if
end sub

sub clearDisplayVariables()

	REM This routine is called in numerous places to 
	REM clear the internal representation of the display.	
	REM We don't update the onscreen display because
	REM different clients may or may not want to embellish
	REM it first.  See appendDigit, buttonClearEntry_pressed,
	REM and buttonDecimal_pressed to see how it is used.

	numstring      = "0"
	pad            = 9
	decimal        = 0
	clearOnNextKey = 0
end sub

