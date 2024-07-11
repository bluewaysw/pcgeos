sub duplo_ui_ui_ui()
REM ========================================================================
REM
REM	Copyright (c) 1998 New Deal, Inc. 
REM                    -- All Rights Reserved
REM
REM	FILE: 	printtxt.bas
REM	AUTHOR:	Martin Turon, June 3, 1998
REM
REM     REVISION HISTORY
REM   		Name	Date		Description
REM   		----	----		-----------
REM   		martin	1998/6/3	Initial Version
REM
REM	DESCRIPTION:	Test routines for the printControl component.
REM			Test routines for text object print handling.
REM
REM     $Id: printtxt.bas,v 1.1 98/07/12 05:04:41 martin Exp $
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
	width=425
	height=270
        sizeHControl=0
        sizeVControl=0
	events=0
    End CompInit

    dim print as component
    print = MakeComponent("PrintControl", mainForm)
    CompInit print
	proto="print"
        top=5
        left=5
	visible=1
    End CompInit

    dim extraButton as button
    extraButton      = MakeComponent("button",mainForm)
    CompInit extraButton
	proto="extraButton"
	caption="extra"
        top=5
        left=60
	visible=1
    End CompInit

    Dim list1 as list
    list1 = MakeComponent("list",mainForm)
    CompInit list1
	proto="list1"
	top=5
	left=110
	width=142
	height=13
    End CompInit
	list1.name="list1"
	list1.captions[0]="Cooperstown"
	list1.captions[1]="Cranbrook"
	list1.captions[2]="Sather Gothic"
	list1.captions[3]="Shattuck Avenue"
	list1.captions[4]="Superb"
	list1.captions[5]="URW Mono"
	list1.captions[6]="URW Roman"
	list1.captions[7]="URW Sans"
	list1.captions[8]="URW SymbolPS"
	list1.selectedItem=1
	list1.visible=1

    Dim list2 as list
    list2 = MakeComponent("list",mainForm)
    CompInit list2
	proto="list2"
	top=5
	left=290
	width=13
	height=13
    End CompInit
	list2.name="list2"
	list2.captions[0]="8"
	list2.captions[1]="10"
	list2.captions[2]="12"
	list2.captions[3]="14"
	list2.captions[4]="18"
	list2.captions[5]="24"
	list2.captions[6]="36"
	list2.selectedItem=1
	list2.visible=1

rem ****************************************
rem * text component instantiation
rem ****************************************
    dim printText as text
    printText      = MakeComponent("text",mainForm)
    CompInit printText
	proto="printText"
        top=30
        left=5
	width=400
	height=200
	visible=1
    End CompInit
    print.output = printText

    mainForm.visible=1
    EnableEvents()
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

sub extraButton_pressed(self as button)
    DIM   print as component
    print        = MakeComponent("printControl", "top")
    print.output = self
    print.show()
    print.print()
end sub


sub list1_changed(self as list, index as integer)
	printText.font = self.Getcaptions(index)
end sub

sub list2_changed(self as list, index as integer)
	printText.fontSize = Val(self.Getcaptions(index))
end sub

