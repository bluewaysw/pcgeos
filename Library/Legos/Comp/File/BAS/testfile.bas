sub duplo_ui_ui_ui()
REM ========================================================================
REM
REM	Copyright (c) 1997 New Deal, Inc. 
REM                    -- All Rights Reserved
REM
REM	FILE: 	testfile.bas
REM	AUTHOR:	Martin Turon, December 8, 1997
REM
REM     REVISION HISTORY
REM   		Name	Date		Description
REM   		----	----		-----------
REM   		martin	1997/12/08	Initial Version
REM
REM	DESCRIPTION:	Test routines for the file component.
REM
REM     $Id: testfile.bas,v 1.1 98/05/13 14:49:02 martin Exp $
REM
REM ======================================================================
    DisableEvents()
REM *********************************************************************
REM * 		Define This Module's Components
REM **********************************************************************
    dim mainForm 		as form
    dim outputText		as text
    dim nameEntry		as entry
    dim popup1 			as popup
    dim popup2 			as popup
    dim popup3 			as popup
    dim popup4 			as popup
    dim popup5 			as popup
    dim popup6 			as popup
    dim button1 		as button
    dim button2 		as button
    dim button3 		as button
    dim button4 		as button
    dim button5 		as button
    dim button6 		as button
    dim button7 		as button
    dim button8 		as button
    dim button9 		as button
    dim button10 		as button
    dim button11 		as button
    dim button12 		as button
    dim button13 		as button
    dim button14 		as button
    dim button15 		as button
    dim button16 		as button
    dim button17 		as button
    dim button18 		as button
    dim button19 		as button
    dim button20 		as button
    dim button21 		as button
    dim button22 		as button
    dim button23 		as button
    dim button24 		as button
    dim button25 		as button
    dim button26 		as button
    dim button27 		as button
    dim button28 		as button

    mainForm   = MakeComponent("form",  "app")
    CompInit mainForm
	proto="mainForm"
        top=95
        left=100
	width=445
	height=280
        sizeHControl=0
        sizeVControl=0
    End CompInit

    popup1 = MakeComponent("popup",mainForm)
    CompInit popup1
	proto="popup1"
	caption="Access"
	left=0
	top=0
	visible=1
    End CompInit

    popup2 = MakeComponent("popup",mainForm)
    CompInit popup2
	proto="popup2"
	caption="Disk"
	sizeHControl=3
	sizeVControl=3
	left=0
	top=0
	visible=1
    End CompInit

    popup5 = MakeComponent("popup",mainForm)
    CompInit popup5
	proto="popup5"
	caption="Get"
	sizeHControl=3
	sizeVControl=3
	left=0
	top=0
	visible=1
    End CompInit

    popup6 = MakeComponent("popup",mainForm)
    CompInit popup6
	proto="popup6"
	caption="Set"
	sizeHControl=3
	sizeVControl=3
	left=0
	top=0
	visible=1
    End CompInit

    popup4 = MakeComponent("popup",mainForm)
    CompInit popup4
	proto="popup4"
	caption="Directory"
	sizeHControl=3
	sizeVControl=3
	left=0
	top=0
	visible=1
    End CompInit

    popup3 = MakeComponent("popup",mainForm)
    CompInit popup3
	proto="popup3"
	caption="Tests"
	sizeHControl=3
	sizeVControl=3
	left=0
	top=0
	visible=1
    End CompInit


    outputText = MakeComponent("text" , mainForm)
    CompInit outputText
	proto="outputText"
	top=6
	left=5
	width=420
	height=200
	maxLines=0
	visible=1
    End CompInit

    nameEntry = MakeComponent("entry" , mainForm)
    CompInit nameEntry
	proto="nameEntry"
	top=213
	left=5
	width=420
	height=15
	maxLines=0
	visible=1
    End CompInit

    button1 = MakeComponent("button",popup1)
    CompInit button1
	proto="button1"
	caption="open"
	visible=1
    End CompInit

    button2 = MakeComponent("button",popup1)
    CompInit button2
	proto="button2"
	caption="read"
	sizeHControl=0
	sizeVControl=0
	visible=1
    End CompInit

    button3 = MakeComponent("button",popup1)
    CompInit button3
	proto="button3"
	caption="write"
	visible=1
    End CompInit

    button4 = MakeComponent("button",popup1)
    CompInit button4
	proto="button4"
	caption="close"
	visible=1
    End CompInit

    button5 = MakeComponent("button",popup2)
    CompInit button5
	proto="button5"
	caption="move"
	visible=1
    End CompInit

    button6 = MakeComponent("button",popup2)
    CompInit button6
	proto="button6"
	caption="copy"
	visible=1
    End CompInit

    button7 = MakeComponent("button",popup2)
    CompInit button7
	proto="button7"
	caption="create"
	visible=1
    End CompInit

    button8 = MakeComponent("button",popup2)
    CompInit button8
	proto="button8"
	caption="delete"
	visible=1
    End CompInit

    button9 = MakeComponent("button",popup4)
    CompInit button9
	proto="button9"
	caption="mkdir"
	visible=1
    End CompInit

    button10 = MakeComponent("button",popup4)
    CompInit button10
	proto="button10"
	caption="rmdir"
	visible=1
    End CompInit

    button11 = MakeComponent("button",popup3)
    CompInit button11
	proto="button11"
	caption="peek-a01"
	visible=1
    End CompInit

    button12 = MakeComponent("button",popup3)
    CompInit button12
	proto="button12"
	caption="poke-a01"
	visible=1
    End CompInit

    button13 = MakeComponent("button",popup5)
    CompInit button13
	proto="button13"
	caption="size"
	visible=1
    End CompInit

    button14 = MakeComponent("button",popup5)
    CompInit button14
	proto="button14"
	caption="date"
	visible=1
    End CompInit

    button15 = MakeComponent("button",popup5)
    CompInit button15
	proto="button15"
	caption="time"
	visible=1
    End CompInit

    button17 = MakeComponent("button",popup1)
    CompInit button17
	proto="button17"
	caption="commit"
	visible=1
    End CompInit

    button16 = MakeComponent("button",popup1)
    CompInit button16
	proto="button16"
	caption="dateline"
	visible=1
    End CompInit

    button18 = MakeComponent("button",popup6)
    CompInit button18
	proto="button18"
	caption="size"
	visible=1
    End CompInit

    button19 = MakeComponent("button",popup6)
    CompInit button19
	proto="button19"
	caption="date"
	visible=1
    End CompInit

    button20 = MakeComponent("button",popup6)
    CompInit button20
	proto="button20"
	caption="time"
	visible=1
    End CompInit

    button21 = MakeComponent("button",popup3)
    CompInit button21
	proto="button21"
	caption="seek-a01"
	visible=1
    End CompInit

    button22 = MakeComponent("button",popup3)
    CompInit button22
	proto="button22"
	caption="go-a01"
	visible=1
    End CompInit

    button23 = MakeComponent("button",popup3)
    CompInit button23
	proto="button23"
	caption="go-a02"
	visible=1
    End CompInit

    button24 = MakeComponent("button",popup3)
    CompInit button24
	proto="button24"
	caption="seek-a02"
	visible=1
    End CompInit

    button25 = MakeComponent("button",popup3)
    CompInit button25
	proto="button25"
	caption="error-a01"
	visible=1
    End CompInit

    button26 = MakeComponent("button",popup3)
    CompInit button26
	proto="button26"
	caption="poke-a02"
	visible=1
    End CompInit

    button27 = MakeComponent("button",popup3)
    CompInit button27
	proto="button27"
	caption="goes-a01"
	visible=1
    End CompInit

    button28 = MakeComponent("button",popup3)
    CompInit button28
	proto="button28"
	caption="ends-a01"
	visible=1
    End CompInit

    mainForm.visible=1
    EnableEvents()

REM *********************************************************************
REM * 		Global constants included
REM **********************************************************************

REM file component constants
	CONST EOF			       -1
REM           FileComponentTraps
	CONST FILE_ERROR_NEVER_TRAP		0
	CONST FILE_ERROR_RUNTIME_TRAP		1
	CONST FILE_ERROR_DIALOG_TRAP		2

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

    duplo_start()
end sub

sub duplo_start()
REM *********************************************************************
REM * 		Initialize this Module's global variables
REM **********************************************************************
    dim testdest  as string
    testdest = "test2.out"

    dim testdir  as string
    testdir = "c:\\temp\\testdir"

    dim testfile as component
    testfile 	  = MakeComponent("file","top")
    testfile.name = "test.out"

    dim myfile as component
    myfile      = MakeComponent("file","top")
    myfile.name = "test3.out"

    outputText.text="File Component Test Application (testfile.bas)"+	    \
		    "\r  Test Directory   = "+testdir+			    \
		    "\r  Test Filename    = "+testfile.name+		    \
		    "\r  Test Destination = "+testdest+			    \
		    "\r  -a01 test file	  = "+myfile.name+"\r\r"
    outputText.SetSelectionRange(256,256)

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

sub button1_pressed(self as button)
    outputText.AppendString("Opening: ",testfile.name,"\r")
    testfile.open()
end sub

sub button2_pressed(self as button)
    dim contents as string
    outputText.AppendString("Reading: \r")
    contents = testfile.read(100)
    outputText.AppendString(contents, "\r")
end sub

sub button3_pressed(self as button)
    dim contents as string
    outputText.AppendString("Writing: \r")
    contents = "Write over TEST!........."
    testfile.write(contents, 20)
end sub

sub button4_pressed(self as button)
    outputText.AppendString("Closing: ",testfile.name,"\r")
    testfile.close()
end sub

sub button5_pressed(self as button)
    outputText.AppendString("Moving to: "+testdest+"\r")
    testfile.move(testdest)
end sub

sub button6_pressed(self as button)
    outputText.AppendString("Copying to: "+testdest+"\r")
    testfile.copy(testdest)
end sub

sub button7_pressed(self as button)
    outputText.AppendString("Creating: ",testfile.name,"\r")
    testfile.create()
end sub

sub button8_pressed(self as button)
    outputText.AppendString("Deleting: ",testfile.name,"\r")
    testfile.delete()
end sub

sub button9_pressed(self as button)
    outputText.AppendString("Making Directory: ",testdir,"\r")
    testfile.mkdir(testdir)
end sub

sub button10_pressed(self as button)
    outputText.AppendString("Removing Directory: ",testdir,"\r")
    testfile.rmdir(testdir)
end sub

sub button11_pressed(self as button)
    dim i as integer

    outputText.AppendString("Executing: peek-a01 test sequence\r")

    myfile.open()
    for i = 1 to 255
	outputText.AppendString(Chr(myfile.peek()))
    next i
    myfile.close()

    outputText.AppendString("\r")
end sub

sub button12_pressed(self as button)
    dim i as integer
    dim j as integer

    outputText.AppendString("Executing: poke-a01 test sequence\r")
    myfile.open()
    for i = 1 to 23
    	for j = 46 to 122
	    myfile.poke(j)    	
    	next j
        myfile.poke(10)
    next i
    myfile.close()
end sub

sub button13_pressed(self as button)
    outputText.AppendString("Size = ",Str(testfile.size)," bytes \r")
end sub

sub button14_pressed(self as button)
    outputText.AppendString("Date = "+Str(testfile.date)+"  (FileDate)\r")
end sub

sub button15_pressed(self as button)
    outputText.AppendString("Time = "+Str(testfile.time)+"  (FileDateTime)\r")
end sub

sub button16_pressed(self as button)
    outputText.AppendString("Dateline (full) = "+			\
			    testfile.dateline(DTF_HMS)+" -- "+		\
			    testfile.dateline()+"\r")
end sub

sub button17_pressed(self as button)
    outputText.AppendString("Commiting: ",testfile.name,"\r")
    testfile.commit()
end sub

sub button18_pressed(self as button)
    outputText.AppendString("setting Size = 10  (Truncated!)\r")
    testfile.size = 10
end sub

sub button19_pressed(self as button)
    outputText.AppendString("setting Date = 9105\r")
    testfile.date = 9105
end sub

sub button20_pressed(self as button)
    outputText.AppendString("setting Time = 9105\r")
    testfile.time = 32100123
end sub

sub button21_pressed(self as button)
    dim i as integer
    outputText.AppendString("Executing: seek-a01 test sequence\r"+	\
			    "   offset from start to 63 (?) = ")
    myfile.open()
    for i = 0 to 255
	REM peek automatically increments file position,
	REM so seek only for testing purposes.
	myfile.seek(0)
	peek63(i)
    next i    
    myfile.close()

    outputText.AppendString("\r")
end sub

sub button22_pressed(self as button)
    dim i as integer
    outputText.AppendString("Executing: go-a01 test sequence\r"+	\
			    "   offset from start to 63 (?) = ")
    myfile.open()
    for i = 0 to 255
	myfile.go(i)
	peek63(i)
    next i    
    myfile.close()

    outputText.AppendString("\r")
end sub

sub button23_pressed(self as button)
    dim i as integer
    outputText.AppendString("Executing: go-a02 test sequence\r"+	\
			    "   offset from end to 63 (?) = ")
    myfile.open()
    for i = 1 to 255
	myfile.go(-i)
	peek63(i)
    next i    
    myfile.close()

    outputText.AppendString("\r")
end sub

sub button24_pressed(self as button)
    dim i as integer
    outputText.AppendString("Executing: seek-a02 test sequence\r"+	\
			    "   offset from end to 63 (?) = ")
    myfile.open()
    myfile.go(-1)
    for i = 1 to 255
	peek63(i)
	myfile.seek(-2)
    next i    
    myfile.close()

    outputText.AppendString("\r")
end sub

sub peek63 (i as integer)
	if (myfile.peek() = 63) then
    	   outputText.AppendString(Str(i)+", ")
	end if    
end sub

sub button25_pressed(self as button)
    outputText.AppendString("Executing: error-a01 test sequence\r")
    REM   This test sequence turns on the error dialog trap
    REM   and raises a few errors with the file component.
    REM   The dialog trap will try to handle all errors 
    REM   encountered while executing file actions.
    myfile.trap  = FILE_ERROR_DIALOG_TRAP
    myfile.error = 1
    myfile.error = 2
    myfile.error = 5
    myfile.trap  = FILE_ERROR_NEVER_TRAP
end sub

sub button26_pressed(self as button)
    dim i as integer
    dim j as integer

    outputText.AppendString("Executing: poke-a02 test sequence\r")
    myfile.open()
    for i = 1 to 23
    	for j = 122 to 46 step -1
	     REM  direct file manipulation can be done with
	     REM file actions, or through the larger set of
	     REM file.buffer actions which eventually will
	     REM cache file manipulation until file.commit()
	     REM is called.
	     myfile.buffer.putc(j)
    	next j
	myfile.poke(10)    	
    next i
    myfile.close()
end sub

sub button27_pressed(self as button)
    dim nextChar as integer
    outputText.AppendString("Executing: goes-a01 test sequence\r")
    testfile.open()
    nextChar = testfile.peek()
    do while testfile.goes()
	outputText.AppendString(Chr(nextChar))
    	nextChar = testfile.peek()
    loop
    testfile.close()
    outputText.AppendString("\r")
end sub

sub button28_pressed(self as button)
    dim nextChar as integer
    outputText.AppendString("Executing: ends-a01 test sequence\r")
    testfile.open()
    nextChar = testfile.peek()
    do 
	outputText.AppendString(Chr(nextChar))
    	nextChar = testfile.peek()
    loop until testfile.ends()
    testfile.close()
    outputText.AppendString("\r")
end sub

sub button29_pressed(self as button)
    outputText.AppendString("Executing: chdir-a01 test sequence\r")
    testfile.chdir("c:\\")
    testfile.name = "config.sys"
    if testfile.exists() then
    	outputText.AppendString("c:\\config.sys exists!")
    end if
    testfile.name = "autoexec.bat"
    if testfile.exists() then
    	outputText.AppendString("c:\\autoexec.bat exists!")
    end if
end sub

