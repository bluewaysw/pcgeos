sub duplo_ui_ui_ui()
REM ========================================================================
REM
REM	Copyright (c) Geoworks 1994 
REM                    -- All Rights Reserved
REM
REM	FILE: 	sn-serv.bas
REM	AUTHOR:	Martin Turon, January 24, 1995
REM
REM     REVISION HISTORY
REM   		Name	Date		Description
REM   		----	----		-----------
REM   		martin	9/21/95		Initial Version
REM
REM	DESCRIPTION:	Specific new control (creation tools) for gadget 
REM			service components.
REM
REM	$Id: sn-serv.bas,v 1.1 98/03/12 20:30:24 martin Exp $
REM	Revision:   1.16
REM
REM ======================================================================

	dim toolGroup		as group
	export toolGroup

        dim BUILDER as component
	export BUILDER


	toolGroup = MakeComponent("group", "top")
	  toolGroup.tile = 1
	  toolGroup.tileSpacing = 1
	  toolGroup.tileVAlign = 2
	  toolGroup.tileHAlign = 2

	dim newTimeDateTool	as button
	dim newAlarmTool	as button
	dim newTimerTool	as button
	dim newClipboardTool	as button
	dim newDatabaseTool	as button
	dim newDisplayTool	as button
	dim newBusyTool 	as button
	dim newSoundTool        as button
	  

	dim dialogBox as dialog
	    REM This must be under "top" instead of APP so it doesn't
	    REM get found when looking for component to write out.
	    dialogBox = MakeComponent("dialog", "app")
	    dialogBox.tile = 1
	    dialogBox.sizeVControl = 3
	    REM
	    REM Keep the dialog box modal so gandalf never looks for it
	    REM when you run.  (make sure it goes away before you interact
	    REM with gandalf again)
	    dialogBox.type = 2
	dim dialogText as text
	    dialogText = MakeComponent("text", dialogBox)
	    dialogText.visible = 1
	    dialogText.readOnly = 1
	    dialogText.sizeVControl = 1
	dim dialogButton as button
	    dialogButton = MakeComponent("button", dialogBox)
	    dialogButton.cancel = 1
	    dialogButton.closeDialog = 1
	    dialogButton.caption = "OK"
	    dialogButton.visible = 1

	    
	  
	newTimeDateTool = MakeComponent("button", toolGroup)
	   newTimeDateTool.graphic = GetComplex(0)
	   newTimeDateTool.visible = 1

	newAlarmTool = MakeComponent("button", toolGroup)
	   newAlarmTool.graphic = GetComplex(1)
	   newAlarmTool.visible = 1

	newTimerTool = MakeComponent("button", toolGroup)
	   newTimerTool.graphic = GetComplex(2)
	   newTimerTool.visible = 1

	newClipboardTool = MakeComponent("button", toolGroup)
	   newClipboardTool.graphic = GetComplex(3)
	   newClipboardTool.visible = 1

	newDatabaseTool = MakeComponent("button", toolGroup)
	   newDatabaseTool.graphic = GetComplex(4)
	   newDatabaseTool.visible = 1

	newDisplayTool = MakeComponent("button", toolGroup)
	   newDisplayTool.graphic = GetComplex(5)
	   newDisplayTool.visible = 1

	newBusyTool = MakeComponent("button", toolGroup)
	   newBusyTool.graphic = GetComplex(6)
	   newBusyTool.visible = 1

	newSoundTool = MakeComponent("button", toolGroup)
	   newSoundTool.graphic = GetComplex(7)
	   newSoundTool.visible = 1

	duplo_start()
end sub

function duplo_top() as component
    REM Return the top level component for this module
	duplo_top = toolGroup
end function

sub duplo_start()

	const	BBM_NORMAL	0
	const	BBM_PLACEMENT	1
	const	BBM_CREATION	2
	const	BBM_RESIZE	3

	REM
	REM This is the easiest way to send messages to the interpreter 
	REM currently...  We need to clean this up at some point and 
	REM introduce a syntax for getting a pointer directly to the 
	REM interpreter, but until then, this'll work.
	REM
	dim hackIntr as component
	 hackIntr = MakeComponent("control","app")

	newTimeDateTool.classToCreate = "timedate"
	newAlarmTool.classToCreate    = "alarm"
	newTimerTool.classToCreate    = "timer"
	newClipboardTool.classToCreate    = "clipboard"
	newDatabaseTool.classToCreate    = "database"
	newBusyTool.classToCreate  = "busy"
	newSoundTool.classToCreate = "sound"
	newDisplayTool.classToCreate  = "display"

	newTimeDateTool.name	= "newTimeDateTool"
	newTimeDateTool.proto	= "createInstantlyTool"

	newAlarmTool.name	= "newAlarmTool"
	newAlarmTool.proto	= "createInstantlyTool"

	newTimerTool.name	= "newTimerTool"
	newTimerTool.proto	= "createInstantlyTool"

	newClipboardTool.name	= "newClipboardTool"
	newClipboardTool.proto	= "createInstantlyTool"

	newDatabaseTool.name    = "newDatabaseTool"
	newDatabaseTool.proto	= "createInstantlyTool"

	newBusyTool.name        = "newBusyTool"
	newBusyTool.proto	= "createInstantlyTool"

	newSoundTool.name       = "newSoundTool"
	newSoundTool.proto	= "createInstantlyTool"

	newDisplayTool.name     = "newDisplayTool"
	newDisplayTool.proto	= "createInstantlyTool"

end sub

sub createInstantlyTool_pressed (self as component)
REM **********************************************************************
REM			createInstantlyTool_pressed
REM **********************************************************************
REM
REM  SYNOPSIS:	The way this routine is currently implemented includes bugs 
REM		involving the count of forms and dialogs (components created 
REM		without any communication with the builder.)  The count will 
REM		not be correct after loads or strange deletion/creation 
REM		combinations. 
REM	
REM  CALLED BY:	
REM
REM  PASS:	
REM  RETURN:	
REM
REM  REVISION HISTORY
REM   Name	Date		Description
REM   ----	----		-----------
REM   martin	1/24/95		Initial Version
REM
REM **********************************************************************


rem	dim hackIntr as component
rem	hackIntr = MakeComponent("control","app")
	hackIntr!hackSetBuildTime(1)	
	
	dim count    as integer
	dim newName  as string
	dim newClass as string
	dim newComp  as component


	REM Create the new component, and ask the interpreter (BentManager) 
	REM for the count of how many other components of that class have 
	REM been created.  Since the count that is returned has been 
	REM auto-incremented after the creation command, subtract one to 
	REM get the real count.	 Sorry it works out to be weird like that...
	REM -martin 10/11/95
	newClass = self.classToCreate
	newComp  = MakeComponent(newClass, "app")
	BUILDER!AddComponentToDestroyList(newComp)
	count 	 = hackIntr!hackGetClassCount(newComp) - 1
	newName  = newClass + str(count)

setName:
	  newName = newClass + str(count)
	  if hackIntr.hackCheckUniqueName(newName) then
	    newComp.name    = newName
	    newComp.proto   = newName
	  else
	    count = count + 1
	    goto setName
	  end if

	  hackIntr!hackSetBuildTime(0)


	  REM Put up a dialog box to let the user know what is going on.

	  if (self.classToCreate = "alarm") then
	      
	      dialogText.text = "You have added an " + self.classToCreate +" component."
	  else
	      dialogText.text = "You have added a " + self.classToCreate +" component."
	  end if
	  dialogBox.visible = 1

end sub

