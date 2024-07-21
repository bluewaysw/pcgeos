sub duplo_ui_ui_ui()
REM ========================================================================
REM
REM	Copyright (c) 1998 New Deal, Inc. 
REM                    -- All Rights Reserved
REM
REM	FILE: 	testfsel.bas
REM	AUTHOR:	Martin Turon, May 4, 1998
REM
REM     REVISION HISTORY
REM   		Name	Date		Description
REM   		----	----		-----------
REM   		martin	1998/5/4	Initial Version
REM		martin	1998/5/18	Added selection and path properties
REM		martin	1998/5/20	Added events property to GadgetGeom
REM
REM	DESCRIPTION:	Test routines for the fileSelector component.
REM
REM     $Id$
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

    dim tall as button
    tall      = MakeComponent("button",mainForm)
    CompInit tall
	proto="tall"
	caption="tall"
        top=5
        left=5
	visible=1
    End CompInit

    dim small as button
    small      = MakeComponent("button",mainForm)
    CompInit small
	proto="small"
	caption="small"
        top=5
        left=45
	visible=1
    End CompInit

    dim show as button
    show      = MakeComponent("button",mainForm)
    CompInit show
	proto="show"
	caption="show"
        top=5
        left=95
	visible=1
    End CompInit

    dim hide as button
    hide      = MakeComponent("button",mainForm)
    CompInit hide
	proto="hide"
	caption="hide"
        top=5
        left=145
	visible=1
    End CompInit

    dim path as button
    path      = MakeComponent("button",mainForm)
    CompInit path 
	proto="path"
	caption="path"
        top=5
        left=190
	visible=1
    End CompInit

    dim selection as button
    selection      = MakeComponent("button",mainForm)
    CompInit selection
	proto="selection"
	caption="selection"
        top=5
        left=235
	visible=1
    End CompInit

    dim view as button
    view      = MakeComponent("button",mainForm)
    CompInit view
	proto="view"
	caption="view"
        top=5
        left=305
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

    dim viewLabel as label
    viewLabel      = MakeComponent("label",mainForm)
    CompInit viewLabel
	proto="viewLabel"
	top=220
	left=5
	visible=1
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

sub small_pressed(self as button)
    myfilesel.size = 5
end sub

sub tall_pressed(self as button)
    myfilesel.size = 13
end sub

sub show_pressed(self as button)
    myfilesel.visible = 1
end sub

sub hide_pressed(self as button)
    myfilesel.visible = 0
end sub

sub path_pressed(self as button)
    fileEntry.text = myfilesel.path
end sub

sub selection_pressed(self as button)
    fileEntry.text = myfilesel.selection
end sub

sub view_pressed(self as button)
    DIM myfile as component
    myfile = MakeComponent("file","top")
    myfile.name = myfilesel.selection 
    myfile.trap = 2

    myfile.open()
    viewLabel.caption = myfile.read(100)
    myfile.close()
    
end sub

sub fileEntry_focusChanged(self as entry, previous as integer)
    self.text = myfilesel.path
end sub
