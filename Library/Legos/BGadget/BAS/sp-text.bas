sub duplo_ui_ui_ui()

REM *******************************************************************
REM
REM PROJECT:	Legos Builder
REM MODULE:	Properties Boxes
REM FILE:	sp-text.bas
REM
REM AUTHOR:	bkurtin
REM DATE:	8/96
REM
REM DESCRIPTION:
REM
REM     This file implements the special properties box for the text
REM     component.
REM
REM NOTES:
REM
REM     The dialog box is designed so that none of the changes take
REM     effect until the "Apply" button is pressed.  This behavior
REM     follows that of the other properties boxes.
REM
REM ******************************************************************

CONST WHITE 		&Hffffffff
CONST BLACK 		&Hff000000

REM
REM Builder Generated Components Set-Up
REM
REM Note that "control" is substituted in place of "form" for the type of
REM the textSpecPropBox.  And, "top" is substituted for "app" in the
REM second argument to MakeComponent below.
REM

DisableEvents()
Dim textSpecPropBox as control
textSpecPropBox = MakeComponent("control","top")
CompInit textSpecPropBox
proto="textSpecPropBox"
left=0
top=0
End CompInit
Dim group0 as group
group0 = MakeComponent("group",textSpecPropBox)
CompInit group0
proto="group0"
caption=""
tileSpacing=5
tile=1
tileHInset=10
tileVInset=10
sizeVControl=3
sizeHControl=3
left=0
top=0
visible=1
End CompInit
Dim label5 as label
label5 = MakeComponent("label",group0)
CompInit label5
proto="label5"
caption="Initial Text"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
label5.name="label5"
Dim group11 as group
group11 = MakeComponent("group",group0)
CompInit group11
proto="group11"
caption=""
width=200
tileLayout=1
tile=1
sizeVControl=3
visible=1
End CompInit
Dim initialText as text
initialText = MakeComponent("text",group11)
CompInit initialText
proto="initialText"
width=184
filter=1
height=96
End CompInit
initialText.name="initialText"
initialText.visible=1
Dim textScroll as scrollbar
textScroll = MakeComponent("scrollbar",group11)
CompInit textScroll
proto="textScroll"
sizeVControl=0
height=96
sizeHControl=3
maximum=0
visible=1
End CompInit
textScroll.name="textScroll"
group11.name="group11"
Dim group13 as group
group13 = MakeComponent("group",group0)
CompInit group13
proto="group13"
caption=""
height=16
width=200
tileLayout=1
tileHInset=20
visible=1
End CompInit
Dim label1 as label
label1 = MakeComponent("label",group13)
CompInit label1
proto="label1"
caption="Max Chars:"
sizeVControl=3
sizeHControl=3
left=0
top=2
visible=1
End CompInit
label1.name="label1"
Dim maxCharsEntry as entry
maxCharsEntry = MakeComponent("entry",group13)
CompInit maxCharsEntry
proto="maxCharsEntry"
width=60
left=110
top=0
maxChars=5
filter=32
text=""
visible=1
End CompInit
maxCharsEntry.name="maxCharsEntry"
group13.name="group13"
Dim group12 as group
group12 = MakeComponent("group",group0)
CompInit group12
proto="group12"
caption=""
height=16
width=200
visible=1
End CompInit
Dim label2 as label
label2 = MakeComponent("label",group12)
CompInit label2
proto="label2"
caption="Max Lines:"
left=0
top=2
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
label2.name="label2"
Dim maxLinesEntry as entry
maxLinesEntry = MakeComponent("entry",group12)
CompInit maxLinesEntry
proto="maxLinesEntry"
left=110
top=0
width=60
maxChars=5
filter=32
text=""
visible=1
End CompInit
maxLinesEntry.name="maxLinesEntry"
group12.name="group12"
Dim group8 as group
group8 = MakeComponent("group",group0)
CompInit group8
look=1
proto="group8"
caption="Font Style"
sizeHControl=0
sizeVControl=0
width=200
height=40
tileLayout=1
tileHInset=20
tileSpacing=10
visible=1
End CompInit
Dim normalStyle as choice
normalStyle = MakeComponent("choice",group8)
CompInit normalStyle
proto="fontStyleGroup"
caption="Normal"
sizeHControl=3
sizeVControl=3
left=20
top=16
visible=1
End CompInit
normalStyle.name="normalStyle"
Dim boldStyle as choice
boldStyle = MakeComponent("choice",group8)
CompInit boldStyle
proto="fontStyleGroup"
caption="Bold"
sizeHControl=3
sizeVControl=3
left=110
top=16
visible=1
End CompInit
boldStyle.name="boldStyle"
group8.name="group8"
Dim group9 as group
group9 = MakeComponent("group",group0)
CompInit group9
look=1
proto="group9"
caption="Color"
sizeHControl=0
sizeVControl=0
width=200
height=40
tileLayout=1
tileHInset=20
tileSpacing=10
visible=1
End CompInit
Dim blackColor as choice
blackColor = MakeComponent("choice",group9)
CompInit blackColor
proto="colorGroup"
caption="Black"
sizeHControl=3
sizeVControl=3
left=20
top=16
visible=1
End CompInit
blackColor.name="blackColor"
Dim whiteColor as choice
whiteColor = MakeComponent("choice",group9)
CompInit whiteColor
proto="colorGroup"
caption="White"
sizeHControl=3
sizeVControl=3
left=110
top=16
visible=1
End CompInit
whiteColor.name="whiteColor"
group9.name="group9"
Dim group10 as group
group10 = MakeComponent("group",group0)
CompInit group10
look=1
proto="group10"
caption="Background Color"
sizeHControl=0
sizeVControl=0
width=200
height=40
tileLayout=1
visible=1
End CompInit
Dim blackBgColor as choice
blackBgColor = MakeComponent("choice",group10)
CompInit blackBgColor
proto="bgColorGroup"
caption="Black"
sizeHControl=3
sizeVControl=3
left=20
top=16
visible=1
End CompInit
blackBgColor.name="blackBgColor"
Dim whiteBgColor as choice
whiteBgColor = MakeComponent("choice",group10)
CompInit whiteBgColor
proto="bgColorGroup"
caption="White"
sizeHControl=3
sizeVControl=3
left=110
top=16
visible=1
End CompInit
whiteBgColor.name="whiteBgColor"
group10.name="group10"
Dim group14 as group
group14 = MakeComponent("group",group0)
CompInit group14
proto="group14"
caption=""
tileLayout=1
width=200
sizeVControl=1
visible=1
End CompInit
Dim label3 as label
label3 = MakeComponent("label",group14)
CompInit label3
proto="label3"
caption="Filter:"
sizeHControl=3
sizeVControl=3
left=0
top=0
visible=1
End CompInit
label3.name="label3"
Dim filterList as list
filterList = MakeComponent("list",group14)
CompInit filterList
proto="filterList"
sizeHControl=3
sizeVControl=3
look=0
left=45
top=0
End CompInit
filterList.name="filterList"
filterList.visible=1
group14.name="group14"
Dim group15 as group
group15 = MakeComponent("group",group0)
CompInit group15
proto="group15"
caption=""
look=0
sizeHControl=0
sizeVControl=0
width=200
height=40
visible=1
End CompInit
dim lookLabel as label
lookLabel = MakeComponent("label", group15)
lookLabel.name = "lookLabel"
CompInit lookLabel
caption = "Look:"
top = 15
left = 0
visible = 1
End CompInit
dim look as list
look = MakeComponent("list", group15)
look.name    = "look"
look.proto   = "look"
look.look = 0
look.captions[0] = "Border, No CR"
look.captions[1] = "Border, CR"
look.captions[2] = "No Border, No CR"
look.captions[3] = "No Border, CR"
look.left = 38
look.top = 15
look.visible = 1
group0.name="group0"
group0.readOnly=0
textSpecPropBox.name="textSpecPropBox"
Dim warningDialog as dialog
warningDialog = MakeComponent("dialog","app")
CompInit warningDialog
proto="dialog1"
left=299
top=358
caption=""
type=2
tile=1
tileSpacing=5
sizeVControl=0
End CompInit
Dim spacer2 as spacer
spacer2 = MakeComponent("spacer",warningDialog)
CompInit spacer2
proto="spacer2"
width=250
height=1
visible=1
End CompInit
spacer2.name="spacer2"
Dim label4 as label
label4 = MakeComponent("label",warningDialog)
CompInit label4
proto="label4"
caption="Warning!"
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
label4.name="label4"
Dim spacer1 as spacer
spacer1 = MakeComponent("spacer",warningDialog)
CompInit spacer1
proto="spacer1"
look=1
width=250
height=5
visible=1
End CompInit
spacer1.name="spacer1"
Dim warningTextBox as text
warningTextBox = MakeComponent("text",warningDialog)
CompInit warningTextBox
proto="text2"
width=250
readOnly=1
height=30
End CompInit
warningTextBox.name="warningTextBox"
warningTextBox.visible=1
Dim button1 as button
button1 = MakeComponent("button",warningDialog)
CompInit button1
proto="warningDialogOK"
caption="OK"
sizeHControl=3
sizeVControl=3
closeDialog=1
default=1
visible=1
End CompInit
button1.name="button1"
Dim spacer3 as spacer
spacer3 = MakeComponent("spacer",warningDialog)
CompInit spacer3
proto="spacer3"
width=250
height=1
visible=1
End CompInit
spacer3.name="spacer3"
warningDialog.height=122
warningDialog.width=270
warningDialog.name="warningDialog"
EnableEvents()
duplo_start()
end sub

sub duplo_start()

REM
REM Initialize the scrollbar.
REM

    textScroll.maximum = 1
    textScroll.thumbSize = initialText.height/initialText.fontSize

REM
REM Initialize the list of filters.
REM

    const NUM_FILTERS 5

    filterList.captions[0]="None"
    filterList.captions[1]="Custom"
    filterList.captions[2]="Numeric"
    filterList.captions[3]="Alphanumeric"
    filterList.captions[4]="Alphanumeric Plus Dash"
    
REM
REM Current Values
REM
REM These variables hold the current values in the properties box.  They
REM are initialized by textSpecPropBox_update.  The sp_apply routine
REM copies these values to the component being edited.
REM
REM The current value for the filter function is indexed by
REM filterList.value through the filterValues array above.  The current
REM value for the initial text is initialText.text.
REM

  dim filterValues[NUM_FILTERS] as integer
    
    filterValues[0]=0
    filterValues[1]=1
    filterValues[2]=32
    filterValues[3]=36
    filterValues[4]=42

dim curMaxChars   as long
dim curMaxLines   as long
dim curFontStyle  as integer
dim curColor      as long
dim curBgColor    as long
dim curFilter     as integer
dim curLook       as integer

REM
REM Error Messages
REM
REM Error messages regarding the maxChars and maxLines properties.  These
REM properties are checked for consistency with the initial text in the
REM sp_apply procedure.
REM

dim messageMaxCharsTooSmall as string
  messageMaxCharsTooSmall = "The number of characters for the initial text is larger than Max Chars.  Max Chars will be enlarged to hold the initial text."

dim messageMaxCharsTooBig as string
  messageMaxCharsTooBig = "The value of Max Chars is too big.  It will be set to its limit of 32767."

dim messageMaxLinesTooSmall as string
  messageMaxLinesTooSmall = "The number of lines for the initial text is larger than Max Lines.	 Max Lines will be enlarged to hold the initial text."

dim messageMaxLinesTooBig as string
  messageMaxLinesTooBig = "The value of Max Lines is too big.  It will be set to its limit of 32767."

REM
REM Synchronization Variable
REM
REM This variable is used for synchronization when a modal dialog is
REM shown.  We use it to ensure that only code for the modal dialog is
REM interpreted once the dialog is shown.  A value of 0 means wait;
REM otherwise, continue.
REM

dim modalSync as integer
modalSync = 0

end sub

function duplo_top() as component

REM ********************************************************************
REM                          duplo_top
REM ********************************************************************
REM
REM SYNOPSIS:	Return the name of the top-level component for the 
REM             properties box.
REM
REM CALLED BY:	the builder
REM 
REM ********************************************************************

    duplo_top = textSpecPropBox
end function

sub textSpecPropBox_update (current as text)

REM ********************************************************************
REM                     textSpecPropBox_update
REM ********************************************************************
REM
REM SYNOPSIS:	Updates the properties in the property box using the
REM             given text component.
REM
REM CALLED BY:	the builder
REM 
REM ********************************************************************

    textSpecPropBox.current = current

REM 
REM  Update text.
REM 

    initialText.text = current.text

REM 
REM  Update maxChars.
REM 

  dim newValFloat as float
    
    newValFloat = current.maxChars

    curMaxChars = current.maxChars
    maxCharsEntry.text = Str(newValFloat)

REM 
REM  Update maxLines.
REM 

    newValFloat = current.maxLines

    curMaxLines = current.maxLines
    maxLinesEntry.text = Str(newValFloat)

REM 
REM  Update fontStyle.
REM 

    if current.fontStyle = 0
	curFontStyle = 0
	normalStyle.status = 1
    else
	curFontStyle = 32
	boldStyle.status = 1
    end if

REM 
REM  Update color.
REM 

    if current.color = BLACK
	curColor = BLACK
	blackColor.status = 1
    else
	curColor = WHITE
	whiteColor.status = 1
    end if

REM 
REM  Update bgColor.
REM 

    if current.bgColor = BLACK
	curBgColor = BLACK
	blackBgColor.status = 1
    else
	curBgColor = WHITE
	whiteBgColor.status = 1
    end if

REM 
REM  Update filter.
REM 

  dim i as integer

    for i = 0 to NUM_FILTERS - 1

	if filterValues[i] = current.filter then
	    curFilter = current.filter
	    filterList.selectedItem = i
	end if

    next i

REM 
REM  Update look.
REM 

    look.selectedItem = current.look

end sub

sub sp_apply ()

REM ********************************************************************
REM                           sp_apply
REM ********************************************************************
REM
REM SYNOPSIS:	Applies the properties in the properties box to the
REM             current text component.
REM
REM CALLED BY:	the builder
REM 
REM ********************************************************************

  dim text as component

    text = textSpecPropBox.current


    translateMaxChars()
    translateMaxLines()
    
    text.text = initialText.text
    text.maxChars = curMaxChars
    text.maxLines = curMaxLines
    text.fontStyle =curFontStyle
    text.color = curColor
    text.bgColor = curBgColor
    text.filter = curFilter
    text.look = look.selectedItem
end sub

sub translateMaxChars()

REM ********************************************************************
REM                        translateMaxChars
REM ********************************************************************
REM
REM SYNOPSIS:	Tranlates the current value for maxChars from the text
REM             form in the entry and saves it.
REM
REM CALLED BY:	sp_apply
REM 
REM ********************************************************************

	dim newValFloat as float

	newValFloat = Val(maxCharsEntry.text)
	curMaxChars = newValFloat

	checkMaxChars()
end sub

sub translateMaxLines()

REM ********************************************************************
REM                        translateMaxLines
REM ********************************************************************
REM
REM SYNOPSIS:	Tranlates the current value for maxLines from the text
REM             form in the entry and saves it.
REM
REM CALLED BY:	sp_apply
REM 
REM ********************************************************************

	dim newValFloat as float

	newValFloat = Val(maxLinesEntry.text)
	curMaxLines = newValFloat

	checkMaxLines()
end sub

sub fontStyleGroup_changed(self as choice)

REM ********************************************************************
REM                      fontStyleGroup_changed
REM ********************************************************************
REM
REM SYNOPSIS:	Handle _changed event for the fontStyleGroup.
REM
REM CALLED BY:	builder UI
REM 
REM ********************************************************************

REM
REM Ensure a Selection
REM
REM This line ensures that one of the choices is always selected.  The
REM Legos API allows for all the choices in a group to unselected, which
REM is not what we want.
REM

    self.status = 1 

    if self = boldStyle then
	curFontStyle = 32
    else
	curFontStyle = 0
    end if
end sub

sub colorGroup_changed(self as choice)

REM ********************************************************************
REM                        colorGroup_changed
REM ********************************************************************
REM
REM SYNOPSIS:	Handle _changed event for the colorGroup.
REM
REM CALLED BY:	builder UI
REM 
REM ********************************************************************

REM
REM Ensure a Selection
REM
REM This line ensures that one of the choices is always selected.  The
REM Legos API allows for all the choices in a group to unselected, which
REM is not what we want.
REM

    self.status = 1

    if self = blackColor then
	curColor = BLACK
    else
	curColor = WHITE
    end if
end sub

sub bgColorGroup_changed(self as choice)

REM ********************************************************************
REM                        bgColorGroup_changed
REM ********************************************************************
REM
REM SYNOPSIS:	Handle _changed event for the bgColorGroup.
REM
REM CALLED BY:	builder UI
REM 
REM ********************************************************************

REM
REM Ensure a Selection
REM
REM This line ensures that one of the choices is always selected.  The
REM Legos API allows for all the choices in a group to unselected, which
REM is not what we want.
REM

    self.status = 1

    if self = blackColor then
	curBgColor = BLACK
    else
	curBgColor = WHITE
    end if
end sub

sub filterList_changed(self as list, index as integer)

REM ********************************************************************
REM                        filterList_changed
REM ********************************************************************
REM
REM SYNOPSIS:	Handle _changed event for the filterList.
REM
REM CALLED BY:	builder UI
REM 
REM ********************************************************************

    curFilter = filterValues[index]
end sub

sub warnUser(message as string)

REM ********************************************************************
REM                             warnUser
REM ********************************************************************
REM
REM SYNOPSIS:	Show a modal dialog with a warning message and "OK"
REM             button.
REM
REM CALLED BY:	general purpose
REM 
REM ********************************************************************

    warningTextBox.text = message

  dim left as integer
  dim top as integer

REM
REM Center the dialog.
REM

    left = (640 - warningDialog.width) / 2
    top = (480 - warningDialog.height) / 2

    warningDialog.left = left
    warningDialog.top = top

    warningDialog.visible = 1

REM
REM Wait until the dialog is dismissed to continue executing.
REM

    modalWait()
end sub

sub warningDialogOK_pressed(self as button)

REM ********************************************************************
REM                     warningDialogOK_pressed
REM ********************************************************************
REM
REM SYNOPSIS:	Handle _pressed event for the "OK" button of
REM             warning dialog.
REM
REM CALLED BY:	builder UI
REM 
REM ********************************************************************

	warningTextBox.text = ""
	warningDialog.visible = 0
	
	modalSync = 1
end sub

sub checkMaxChars()

REM ********************************************************************
REM                           checkMaxChars
REM ********************************************************************
REM
REM SYNOPSIS:	Do consistency checks on curMaxChars and show a
REM             warning dialog if necessary.
REM
REM CALLED BY:	translateMaxChars
REM 
REM ********************************************************************

REM
REM Check if curMaxChars is too small.
REM

    if (initialText.numChars > curMaxChars)
	warnUser(messageMaxCharsTooSmall)

	curMaxChars = initialText.numChars
    end if

REM
REM Check if curMaxChars is too big.
REM

    if (curMaxChars > 32767)
	warnUser(messageMaxCharsTooBig)

	curMaxChars = 32767
    end if

REM
REM Update the maxCharsEntry.
REM

      dim floatTemp as float
	floatTemp = curMaxChars
	maxCharsEntry.text = Str(floatTemp)
end sub

sub checkMaxLines()

REM ********************************************************************
REM                           checkMaxLines
REM ********************************************************************
REM
REM SYNOPSIS:	Do consistency checks on curMaxLines and show a
REM             warning dialog if necessary.
REM
REM CALLED BY:	translateMaxLines
REM 
REM ********************************************************************

REM
REM Check if curMaxLines is too small.
REM

    if (initialText.numLines > curMaxLines) and (curMaxLines <> 0)
	warnUser(messageMaxLinesTooSmall)

	curMaxLines = initialText.numLines
    end if

REM
REM Check if curMaxLines is too big.
REM

    if (curMaxLines > 32767)
	warnUser(messageMaxLinesTooBig)

	curMaxLines = 32767
    end if

REM
REM Update the maxLinesEntry.
REM

      dim floatTemp as float
	floatTemp = curMaxLines
	maxLinesEntry.text = Str(floatTemp)
end sub

sub modalWait()

REM ********************************************************************
REM                            modalWait
REM ********************************************************************
REM
REM SYNOPSIS:	Wait in a loop (until a modal dialog is dismissed).
REM
REM CALLED BY:	warnUser
REM 
REM ********************************************************************

    do while (modalSync = 0)
    loop

    modalSync = 0
end sub

sub initialText_numLinesChanged(self as text)

REM ********************************************************************
REM                     initialText_numLinesChanged
REM ********************************************************************
REM
REM SYNOPSIS:	Handle the _numLinesChanged event for the initialText.
REM
REM CALLED BY:	builder UI
REM 
REM ********************************************************************

  dim newMax as integer

    newMax = self.numLines
    
    if newMax < 1
	textScroll.maximum = 1
    else
	textScroll.maximum = newMax
    end if

end sub

sub textScroll_changed(self as scrollbar, scrollType as integer)

REM ********************************************************************
REM                       textScroll_changed
REM ********************************************************************
REM
REM SYNOPSIS:	Handle the _changed event for the textScroll.
REM
REM CALLED BY:	builder UI
REM 
REM ********************************************************************

    initialText.firstVisibleLine = self.value

end sub

sub initialText_scrolled(self as text)

REM ********************************************************************
REM                       initialText_scrolled
REM ********************************************************************
REM
REM SYNOPSIS:	Handle the _scrolled event for the initialText.
REM
REM CALLED BY:	builder UI
REM 
REM ********************************************************************

    textScroll.value = self.firstVisibleLine

end sub


sub duplo_revision()

REM	
REM	$Id: sp-text.bas,v 1.1 98/03/12 20:30:37 martin Exp $
REM

end sub

