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
REM			primitive components.
REM
REM	$Id: sn-prim.bas,v 1.1 98/03/12 20:30:10 martin Exp $
REM	Revision:   1.9 
REM
REM ======================================================================

	dim toolGroup		as group
	export toolGroup
        dim BUILDER as component
	export BUILDER

	dim newClipperTool      as button
	dim newGadgetTool       as button
	dim newFloaterTool      as button
	dim newSpacerTool       as button
	dim newPictureTool      as button

	toolGroup = MakeComponent("group", "top")
	  toolGroup.tile = 1
	  toolGroup.tileSpacing = 1
	  toolGroup.tileVAlign = 2
	  toolGroup.tileHAlign = 2

	newClipperTool = MakeComponent("button", toolGroup)
	   newClipperTool.graphic = GetComplex(0)
	   newClipperTool.visible = 1

	newGadgetTool = MakeComponent("button", toolGroup)
	   newGadgetTool.graphic = GetComplex(1)
	   newGadgetTool.visible = 1

	newFloaterTool = MakeComponent("button", toolGroup)
	   newFloaterTool.graphic = GetComplex(2)
	   newFloaterTool.visible = 1

	newSpacerTool = MakeComponent("button", toolGroup)
	   newSpacerTool.graphic = GetComplex(3)
	   newSpacerTool.visible = 1

	newPictureTool = MakeComponent("button", toolGroup)
	   newPictureTool.graphic = GetComplex(4)
	   newPictureTool.visible = 1

	duplo_start()
end sub

sub duplo_start()

	const	BBM_NORMAL	0
	const	BBM_PLACEMENT	1
	const	BBM_CREATION	2
	const	BBM_RESIZE	3

	const	FLOATER_HEIGHT	120
	const	FLOATER_WIDTH	100

	REM
	REM This is the easiest way to send messages to the interpreter 
	REM currently...  We need to clean this up at some point and 
	REM introduce a syntax for getting a pointer directly to the 
	REM interpreter, but until then, this'll work.
	REM
	dim hackIntr as component
	 hackIntr = MakeComponent("control","app")

	newClipperTool.classToCreate = "clipper"
	newGadgetTool.classToCreate = "gadget"
	newFloaterTool.classToCreate = "floater"
	newSpacerTool.classToCreate = "spacer"
	newPictureTool.classToCreate = "picture"

	newClipperTool.name        = "newClipperTool"
	newClipperTool.proto        = "createThroughCallbackTool"

	newGadgetTool.name        = "newGadgetTool"
	newGadgetTool.proto        = "createThroughCallbackTool"

	newFloaterTool.name        = "newFloaterTool"
	newFloaterTool.proto       = "createInstantlyTool"

	newSpacerTool.name        = "newSpacerTool"
	newSpacerTool.proto       = "createThroughCallbackTool"

	newPictureTool.name        = "newPictureTool"
	newPictureTool.proto       = "createThroughCallbackTool"

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
REM  SYNOPSIS:
REM	
REM  CALLED BY:	
REM
REM  PASS:	
REM  RETURN:	
REM
REM  REVISION HISTORY
REM   Name	Date		Description
REM   ----	----		-----------
REM   martin	9/21/95		Initial Version
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
setName:
	  newName = newClass + str(count)
	  if hackIntr.hackCheckUniqueName(newName) then
	    newComp.name    = newName
	    newComp.proto   = newName
	  else
	    count = count + 1
	    goto setName
	  end if

	newComp.caption  = newName
	newComp.tile     = 0
	newComp.left 	 = 200
	newComp.top	 = 300
	newComp.visible  = 1 

	hackIntr!hackSetBuildTime(0)	

end sub




sub createThroughCallbackTool_pressed (self as component)
REM **********************************************************************
REM 	Code for creating components through the standard callback
REM	mechanism in BentManager.  BentManager will handle mouse
REM	events and will pass us the count of how many of such component 
REM	has already been created and the coordinates of where the user 
REM	wants their new component to go. 
REM **********************************************************************

REM **********************************************************************
REM		  createThroughCallbackTool_pressed
REM **********************************************************************
REM
REM  SYNOPSIS:	
REM	
REM  CALLED BY:	
REM
REM  PASS:	
REM  RETURN:	
REM
REM  REVISION HISTORY
REM   Name	Date		Description
REM   ----	----		-----------
REM   martin	9/21/95		Initial Version
REM
REM **********************************************************************

	hackIntr!hackSetMode(BBM_CREATION, self)

end sub


sub InitializePosition(self as component, left as integer, top as integer)
REM **********************************************************************
REM			InitializePositon           
REM **********************************************************************
REM
REM   SYNOPSIS:  Initialize the size and position of the given object 
REM		 based on its class.
REM
REM   martin	9/21/95 	Initial Version
REM
REM **********************************************************************
	dim parent as component

	REM
	REM If our parent is not managing its childrens' geometry, 
	REM we must set our size and position now
	REM
	parent = self.parent
	if (HasProperty(parent, "tile")) then
	   if parent.tile = 0 then

		self.left = left
		self.top  = top

	   end if
	end if

end sub

function createThroughCallbackTool_createInPlace (self as component, parent as component, count as integer, left as integer, top as integer) as component

REM **********************************************************************
REM			createThroughCallbackTool_createInPlace           
REM **********************************************************************
REM
REM  SYNOPSIS:	Called by interpreter when in creation mode, and the user 
REM		clicks on a possible parent.
REM	
REM  CALLED BY:	duplo
REM  PASS:	self   as component	- creation control
REM		parent as component	- object to add new component under
REM		count as integer
REM		left as integer
REM		top as integer
REM				
REM
REM  RETURN:	nothing
REM
REM  REVISION HISTORY
REM   Name	Date		Description
REM   ----	----		-----------
REM   martin	9/21/95 	Initial Version
REM
REM **********************************************************************
	
	dim newComp  as component
	dim newClass as string
	dim newName  as string

	REM
	REM CODE FOR NORMAL COMPONENTS
	REM
   	newClass = self.classToCreate
	newName = newClass + str(count)
	onerror goto fixParent
	newComp = MakeComponent(newClass, parent)
setName:
	  newName = newClass + str(count)
	  if hackIntr.hackCheckUniqueName(newName) then
	    newComp.name    = newName
	    newComp.proto   = newName
	  else
	    count = count + 1
	    goto setName
	  end if

	InitializePosition(newComp, left, top)

	newComp.visible = 1 

	createThroughCallbackTool_createInPlace = newComp

	exit function

fixParent:
	REM
	REM Assume the error is due to invalid parent.  
	REM Try to add to parent's parent, if there is one...
	REM
	if IsNullComponent(parent) then
	  exit function
	end if
	left = left + parent.left
	top = top + parent.top
	parent = parent.parent
	resume
end function


sub createThroughCallbackTool_destroyInPlace (self as component, comp as component)

REM **********************************************************************
REM			createThroughCallbackTool_destroyInPlace           
REM **********************************************************************
REM
REM  SYNOPSIS:	Called by interpreter when in creation mode, and the user 
REM		clicks on a possible parent.
REM	
REM  CALLED BY:	duplo
REM  PASS:	self   as component	- creation control
REM		parent as component	- object to add new component under
REM		position as long	- x high, y low 
REM					  (will make this x as int, y as int)
REM
REM  RETURN:	nothing
REM
REM  REVISION HISTORY
REM   Name	Date		Description
REM   ----	----		-----------
REM   martin	9/21/95 	Initial Version
REM
REM **********************************************************************
	
   REM Eventually, change these hackSetInterpreterMode actions to be sent
   REM directly to the BuilderManager component in LEGOS...

	hackIntr!hackSetUIDirty()
	hackIntr!hackDeselectComponent()
end sub

