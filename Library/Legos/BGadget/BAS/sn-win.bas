sub duplo_ui_ui_ui()
REM ========================================================================
REM
REM	Copyright (c) Geoworks 1994 
REM                    -- All Rights Reserved
REM
REM	FILE: 	sn-win.bas
REM	AUTHOR:	Martin Turon, January 24, 1995
REM
REM     REVISION HISTORY
REM   		Name	Date		Description
REM   		----	----		-----------
REM   		martin	1/24/95		Initial Version
REM
REM	DESCRIPTION:	Creates a top level window for various devices
REM
REM	$Id: sn-win.bas,v 1.1 98/03/12 20:30:22 martin Exp $
REM	Revision:   1.11
REM
REM ======================================================================

	dim toolGroup		as group
	export toolGroup
        dim BUILDER as component
	export BUILDER

	toolGroup = MakeComponent("group", "top")
	CompInit toolGroup
	  tile = 1
	  tileSpacing = 1
	  tileHAlign = 2
	  tileVAlign = 2
        end CompInit

	dim newDialogTool       as button
	newDialogTool = MakeComponent("button", toolGroup)
	CompInit newDialogTool
	   name			= "newDialogTool"
	   proto 		= "createInstantlyTool"
	   visible 		= 1
	end CompInit
	newDialogTool.classToCreate		= "dialog"
	newDialogTool.graphic	= GetComplex(0)

	dim newFormTool		as button
	newFormTool = MakeComponent("button", toolGroup)
	CompInit newFormTool
	   name		= "newFormTool"
	   proto		= "createInstantlyTool"
	   visible 		= 1
        end CompInit
	newFormTool.classToCreate  	= "form"
	newFormTool.graphic		= GetComplex(1)

	duplo_start()

end sub

sub duplo_start()
  REM This is the easiest way to send messages to the interpreter 
  REM currently...  We need to clean this up at some point and 
  REM introduce a syntax for getting a pointer directly to the 
  REM interpreter, but until then, this'll work.
  REM
 dim hackIntr as component
  hackIntr = MakeComponent("control","app")

end sub

function duplo_top() as component
    REM Return the top level component for this module
	duplo_top = toolGroup
end function



sub createInstantlyTool_pressed (self as component)
REM **********************************************************************
REM		Define pressed events for all relvant buttons
REM **********************************************************************
 

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

	  REM forms don't have captions anymore
REM	newComp.caption  = newName

	if newClass = "form" then
	    newComp.left = 100
	    newComp.top = 95
	    newComp.width = 320
	    newComp.height = 280
	else if newClass = "dialog" then
	    newComp.left = 300
	    newComp.top = 100
	    newComp.width = 280
	    newComp.height = 140
	end if
	    
	newComp.tile = 1		REM default to tiling
	newComp.visible  = 1 

	hackIntr!hackSetBuildTime(0)	

end sub
