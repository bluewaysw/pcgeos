sub duplo_ui_ui_ui()
REM ========================================================================
REM
REM	Copyright (c) 1998 New Deal, Inc. 
REM                    -- All Rights Reserved
REM
REM	FILE: 	draw.bas
REM	AUTHOR:	Martin Turon, July 20, 1998
REM
REM     REVISION HISTORY
REM   		Name	Date		Description
REM   		----	----		-----------
REM   		martin	1998/7/20	Initial Version
REM
REM	DESCRIPTION:	Test routines for the draw component.
REM
REM     $Id$
REM
REM ======================================================================
    DisableEvents()
REM *********************************************************************
REM * 		Define This Module's Components
REM **********************************************************************

    Dim form1 as form
    form1 = MakeComponent("form","app")
    CompInit form1
	proto="form1"
	top=95
	left=100
	sizeHControl=0
	sizeVControl=0
	tile=1
    End CompInit

    Dim button1 as button
    button1 = MakeComponent("button",form1)
    CompInit button1
	proto="button1"
	caption="button1"
	visible=1
    End CompInit
    button1.name="button1"
    form1.width=320
    form1.height=280
    form1.name="form1"
    EnableEvents()
    duplo_start()
end sub

sub duplo_start()
    REM place initialization code here
    dim draw1 as component
    draw1 = MakeComponent("draw", "top")
    draw1.start()
    draw1.rectangle(5,5,25,15)
    rem draw1.moveto(10,10)
    rem draw1.text("draw test")
    draw1.stop()
    button1.graphic=draw1.data
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

