sub duplo_ui_ui_ui()
REM ========================================================================
REM
REM	Copyright (c) 1998 New Deal, Inc. 
REM                    -- All Rights Reserved
REM
REM	FILE: 	print.bas
REM	AUTHOR:	Martin Turon, May 27, 1998
REM
REM     REVISION HISTORY
REM   		Name	Date		Description
REM   		----	----		-----------
REM   		martin	1998/5/27	Initial Version
REM
REM	DESCRIPTION:	Test routines for the fileSelector component.
REM
REM     $Id: printgdg.bas,v 1.1 98/07/12 05:04:14 martin Exp $
REM
REM ======================================================================
    DisableEvents()
REM *********************************************************************
REM * 		Define This Module's Components
REM **********************************************************************
    dim mainForm 		as form
    mainForm   = MakeComponent("form",  "app")
    CompInit mainForm
	proto="mainForm"
        top=95
        left=100
	width=550
	height=125
        sizeHControl=0
        sizeVControl=0
	events=0
    End CompInit

    DIM mainMenu as popup
    mainMenu = MakeComponent("popup", mainForm)
    CompInit mainMenu
	proto="mainMenu"
	caption="Main"
	visible=1
    End CompInit
    
    DIM sentenceMenu as popup
    sentenceMenu = MakeComponent("popup", mainForm)
    CompInit sentenceMenu
	proto="sentenceMenu"
	caption="Sentence"
	visible=1
    End CompInit

    dim print as component
    print = MakeComponent("printControl", mainMenu)
    CompInit print
	proto="print"
	visible=1
    End CompInit

    dim extraEntry  as entry
    extraEntry       = MakeComponent("entry",mainForm)
    CompInit extraEntry
	proto="extraEntry"
	top=5
	left=5
	width=300
	height=25
	visible=1
    End CompInit

    dim sentence1Button as button
    sentence1Button      = MakeComponent("button",sentenceMenu)
    CompInit sentence1Button
	proto="sentence1Button"
	caption="This is the first sentence."
	visible=1
    End CompInit

    dim sentence2Button as button
    sentence2Button      = MakeComponent("button",sentenceMenu)
    CompInit sentence2Button
	proto="sentence2Button"
	caption="This next sentence confirms that printing correctly occurs."
	visible=1
    End CompInit

    dim sentence3Button as button
    sentence3Button      = MakeComponent("button",sentenceMenu)
    CompInit sentence3Button
	proto="sentence3Button"
	caption="An oblique stream of cryptic print symbols will be sent."
	visible=1
    End CompInit

    dim sentence4Button as button
    sentence4Button      = MakeComponent("button",sentenceMenu)
    CompInit sentence4Button
	proto="sentence4Button"
	caption="... .. . . .  ....^.. . .  ... .  .. .  .. . . . . .. .  . .  . . . . . .... . . .  . . . . . .. .. .. . .. .. .. .. ....  .  ...    .   .."
	visible=1
    End CompInit

    dim sentence5Button as button
    sentence5Button      = MakeComponent("button",sentenceMenu)
    CompInit sentence5Button
	proto="sentence5Button"
	caption="This is a test of the printing system . . . ."
	visible=1
    End CompInit

    dim sentence6Button as button
    sentence6Button      = MakeComponent("button",sentenceMenu)
    CompInit sentence6Button
	proto="sentence6Button"
	caption="These sentences should print to a page after a Main->Print."
	visible=1
    End CompInit

rem ****************************************
rem * gadget component instantiation
rem ****************************************
    dim printGadget as gadget
    printGadget      = MakeComponent("gadget",mainForm)
    CompInit printGadget
	proto="printGadget"
        top=25
        left=5
	width=530
	height=100
	visible=1
    End CompInit
    printGadget.text="This is the first sentence."
    print.output     = printGadget

    mainForm.visible=1
    duplo_start()

    EnableEvents()
end sub

sub duplo_start()
REM *********************************************************************
REM * 		Initialize this Module's global variables
REM **********************************************************************
end sub

sub module_show()
REM *********************************************************************
REM * 		HANDLE UI_EVENTS
REM **********************************************************************
    REM code for making this module appear
    mainForm.visible=1
end sub

sub module_hide()
    REM code for making this module disappear
    mainForm.visible=0
end sub

sub extraEntry_entered(self as entry)
    printGadget_redraw(printGadget, self.text)
end sub

sub sentence1Button_pressed(self as button)
    printGadget_redraw(printGadget, self.caption)
end sub

sub sentence2Button_pressed(self as button)
    printGadget_redraw(printGadget, self.caption)
end sub

sub sentence3Button_pressed(self as button)
    printGadget_redraw(printGadget, self.caption)
end sub

sub sentence4Button_pressed(self as button)
    printGadget_redraw(printGadget, self.caption)
end sub

sub sentence5Button_pressed(self as button)
    printGadget_redraw(printGadget, self.caption)
end sub

sub sentence6Button_pressed(self as button)
    printGadget_redraw(printGadget, self.caption)
end sub

sub printGadget_draw(self as gadget)
    CONST BOLD		32
    CONST BLACK 	&Hff000000
    self.ClearClipRect()
    self.DrawText(self.text, 5, 5, BLACK, "Sather Gothic", 18, BOLD)    
    self.DrawHLine(5, 530, 55, BLACK)
end sub

sub printGadget_redraw(self as gadget, text as string)
    self.text=text
    self.visible=0
    self.visible=1
end sub

