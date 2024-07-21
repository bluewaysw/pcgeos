sub duplo_ui_ui_ui()
 REM	Copyright (c) Geoworks 1995 -- All Rights Reserved
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

 REM end of stdinc.bh

Dim form1 as form
form1 = MakeComponent("form","app")
CompInit form1
name="form1"
caption="Form Test"
proto="form1"
top=61
left=91
height=175
width=230
sizeHControl=3
sizeVControl=3
End CompInit
Dim button3 as button
button3 = MakeComponent("button",form1)
CompInit button3
name="button3"
proto="button3"
caption="Open Dialog"
left=4
top=4
visible=1
End CompInit
Dim button0 as button
button0 = MakeComponent("button",form1)
CompInit button0
name="button0"
proto="button0"
caption="Close Dialog"
left=5
top=26
visible=1
End CompInit
Dim label1 as label
label1 = MakeComponent("label",form1)
CompInit label1
name="label1"
proto="label1"
caption="Form Opened:  0"
left=4
top=48
visible=1
End CompInit
Dim label2 as label
label2 = MakeComponent("label",form1)
CompInit label2
name="label2"
proto="label2"
caption="Form Closed:  0"
left=4
top=64
visible=1
End CompInit
Dim label4 as label
label4 = MakeComponent("label",form1)
CompInit label4
name="label4"
proto="label4"
caption="Opened should always be Closed + 1"
left=6
top=81
visible=1
End CompInit
Dim button4 as button
button4 = MakeComponent("button",form1)
CompInit button4
name="button4"
proto="button4"
caption="Bring To Front"
left=7
top=97
visible=1
End CompInit
Dim button6 as button
button6 = MakeComponent("button",form1)
CompInit button6
name="button6"
proto="button6"
caption="Modal"
left=13
top=129
visible=1
End CompInit
Dim button7 as button
button7 = MakeComponent("button",form1)
CompInit button7
name="button7"
proto="button7"
caption="SysModal"
left=75
top=128
visible=1
End CompInit
form1.visible=1
Dim dialog0 as dialog
dialog0 = MakeComponent("dialog","app")
CompInit dialog0
name="dialog0"
caption="Dialog Test"
proto="dialog0"
tile=1
width=116
height=109
left=101
top=232
sizeHControl=3
sizeVControl=3
End CompInit
Dim button1 as button
button1 = MakeComponent("button",dialog0)
CompInit button1
name="button1"
proto="button1"
caption="Open Form"
visible=1
End CompInit
Dim button2 as button
button2 = MakeComponent("button",dialog0)
CompInit button2
name="button2"
proto="button2"
caption="Close Form"
visible=1
End CompInit
Dim label3 as label
label3 = MakeComponent("label",dialog0)
CompInit label3
name="label3"
proto="label3"
caption="Dialog Opened:  0"
visible=1
End CompInit
Dim label0 as label
label0 = MakeComponent("label",dialog0)
CompInit label0
name="label0"
proto="label0"
caption="Dialog Closed:  0"
visible=1
End CompInit
dialog0.visible=1
Dim dialog1 as dialog
dialog1 = MakeComponent("dialog","app")
CompInit dialog1
name="dialog1"
caption="Dummy Dialog"
proto="dialog1"
tile=1
width=100
height=100
left=297
top=231
End CompInit
Dim button5 as button
button5 = MakeComponent("button",dialog1)
CompInit button5
name="button5"
proto="button5"
caption="Close"
visible=1
End CompInit
dialog1.visible=1
duplo_start()
end sub

sub duplo_start()
	dim formOpened as integer
	dim formClosed as integer
	dim dlogOpened as integer
	dim dlogClosed as integer
end sub

sub module_show()
form1.visible=1
end sub

sub module_hide()
form1.visible=0
end sub

function duplo_revision()

REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	formdlog.bas
REM	AUTHOR:	dloft, Sep 25, 1995
REM	dloft
REM	$Revision:   1.0  $
REM

end function

sub button3_pressed(self as button)
	dialog0.visible = 1
end sub

sub button0_pressed(self as button)
	dialog0.visible = 0
end sub

sub button1_pressed(self as button)
	form1.visible = 1
end sub

sub button2_pressed(self as button)
	form1.visible = 0
end sub

sub form1_aboutToOpen(self as form)
	formOpened = formOpened + 1
	label1.caption = "Form Opened: " + str(formOpened)
end sub

sub form1_aboutToClose(self as form)
	formClosed = formClosed + 1
	label2.caption = "Form Closed:  " + str(formClosed)
end sub

sub dialog0_aboutToOpen(self as dialog)
	dlogOpened = dlogOpened + 1
	label3.caption = "Dialog Opened:  " + str(dlogOpened)
end sub

sub dialog0_aboutToClose(self as dialog)
	dlogClosed = dlogClosed + 1
	label0.caption = "Dialog Closed:  " + str(dlogClosed)
end sub

sub button4_pressed(self as button)
	dialog0.BringToFront()
end sub

sub button5_pressed(self as button)
	dialog1.visible = 0
end sub

sub button6_pressed(self as button)
	dialog1.visible = 0
	dialog1.modal = 1
	dialog1.visible = 1
end sub

sub button7_pressed(self as button)
	dialog1.visible = 0
	dialog1.modal = 2
	dialog1.visible = 1
end sub

