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
REM     $Id: print.bas,v 1.1 98/07/12 05:03:52 martin Exp $
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
	width=450
	height=300
        sizeHControl=0
        sizeVControl=0
	events=0
    End CompInit

    dim print as component
    print = MakeComponent("printControl", mainForm)
    CompInit print
	proto="print"
        top=5
        left=5
	visible=1
    End CompInit
    print.output = mainForm

    dim extraButton as button
    extraButton      = MakeComponent("button",mainForm)
    CompInit extraButton
	proto="extraButton"
	caption="extra"
        top=5
        left=60
	visible=1
    End CompInit

    dim fileEntry as entry
    fileEntry      = MakeComponent("entry",mainForm)
    CompInit fileEntry
	proto="fileEntry"
	caption="Path of selected file:"
        top=35
        left=5
	width=260
	visible=1
    End CompInit

rem ****************************************
rem * fileSelector component instantiation
rem *
rem *   dim myfilesel as fileSelector
rem ****************************************
    dim myfilesel as component
    myfilesel      = MakeComponent("fileSelector",mainForm)
    CompInit myfilesel
	proto="myfilesel"
        top=60
        left=5
	visible=1
	size=7
    End CompInit

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

sub extraButton_pressed(self as button)
    DIM   print as component
    print        = MakeComponent("printControl", "top")
    print.output = self
    print.show()
    print.print()
end sub


