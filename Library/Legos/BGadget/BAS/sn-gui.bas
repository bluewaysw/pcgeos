sub duplo_ui_ui_ui()

REM ========================================================================
REM
REM	Copyright (c) Geoworks 1994 
REM                    -- All Rights Reserved
REM
REM	FILE: 	newctrl.bas
REM	AUTHOR:	Martin Turon, January 24, 1995
REM
REM     REVISION HISTORY
REM   		Name	Date		Description
REM   		----	----		-----------
REM   		martin	1/24/95		Initial Version
REM
REM	DESCRIPTION:
REM
REM	$Id: sn-gui.bas,v 1.1 98/03/12 20:30:08 martin Exp $
REM	Revision:   1.17
REM
REM ======================================================================


	dim toolGroup		as group
	export toolGroup
        dim BUILDER as component
	export BUILDER

	dim crosshairsTool	as button
	dim newButtonTool	as button
	dim newChoiceTool       as button
	dim newEntryTool	as button
	dim newGroupTool	as button
	dim newLabelTool	as button
	dim newListTool		as button
	dim newNumberTool	as button
	dim newPopupTool        as button
	dim newScrollbarTool	as button
	dim newToggleTool       as button

	toolGroup = MakeComponent("group", "top")
	  toolGroup.tile = 1
	  toolGroup.tileSpacing = 1
	  toolGroup.tileHAlign = 2
	  toolGroup.tileVAlign = 2

REM	crosshairsTool = MakeComponent("button", toolGroup)
REM	   crosshairsTool.caption       = "+"
REM	   crosshairsTool.visible	= 1
REM	   crosshairsTool.name		= "crosshairsTool"
REM	   crosshairsTool.proto		= "crosshairsTool"

	newButtonTool = MakeToolButton("button")
	newButtonTool.graphic = GetComplex(0)
	newChoiceTool = MakeToolButton("choice")
	newChoiceTool.graphic = GetComplex(1)
	newEntryTool = MakeToolButton("entry")
	newEntryTool.graphic = GetComplex(2)
	newGroupTool = MakeToolButton("group")
	newGroupTool.graphic = GetComplex(3)
	newLabelTool = MakeToolButton("label")
	newLabelTool.graphic = GetComplex(4)
	newListTool = MakeToolButton("list")
	newListTool.graphic = GetComplex(5)
	newNumberTool = MakeToolButton("number")
	newNumberTool.graphic = GetComplex(9)
	newPopupTool = MakeToolButton("popup")
	newPopupTool.graphic = GetComplex(8)
	newScrollbarTool = MakeToolButton("scrollbar")
	newScrollbarTool.graphic = GetComplex(6)
	newToggleTool = MakeToolButton("toggle")
	newToggleTool.graphic = GetComplex(7)

	duplo_start()
end sub

sub duplo_start()

    const TOOL_WIDTH	62

	const	BBM_NORMAL	0
	const	BBM_PLACEMENT	1
	const	BBM_CREATION	2
	const	BBM_RESIZE	3

	const	GROUP_HEIGHT	120
	const	GROUP_WIDTH	100

	REM This is the easiest way to send messages to the interpreter 
	REM currently...  We need to clean this up at some point and 
	REM introduce a syntax for getting a pointer directly to the 
	REM interpreter, but until then, this'll work.
	REM
	dim hackIntr as component
	hackIntr = toolGroup.parent.parent
end sub

function duplo_top() as component
    REM Return the top level component for this module
    duplo_top = toolGroup
end function


sub crosshairsTool_pressed (self as component)
    hackIntr!hackSetMode(BBM_NORMAL, 0)
end sub

sub createTool_pressed (self as component)
REM **********************************************************************
REM 	Code for creating components through the standard callback
REM	mechanism in BentManager.  BentManager will handle mouse
REM	events and will pass us the count of how many of such component 
REM	has already been created and the coordinates of where the user 
REM	wants their new component to go. 
REM **********************************************************************

REM **********************************************************************
REM		  createTool_pressed
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
REM   martin	1/24/95		Initial Version
REM
REM **********************************************************************

	hackIntr!hackSetMode(BBM_CREATION, self)

end sub

sub InitializeCaption(self as component, name as string)
REM **********************************************************************
REM			InitializeCaption           
REM **********************************************************************
REM
REM   SYNOPSIS:  Initialize the caption of the given component
REM		 based on its class.
REM
REM   martin	1/24/95 	Initial Version
REM
REM **********************************************************************

	    if (HasProperty(self, "caption")) then
		select case self.class
		  case "entry"
		  case "number"
		  case else
		    self.caption = name
		end select
	    end if
end sub

sub InitializePosition(self as component, left as integer, top as integer)
REM **********************************************************************
REM			InitializePositon           
REM **********************************************************************
REM
REM   SYNOPSIS:  Initialize the size and position of the given object 
REM		 based on its class.
REM
REM   martin	1/24/95 	Initial Version
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

		if (self.class = "group") then
                    self.height = GROUP_HEIGHT
                    self.width  = GROUP_WIDTH
	      	end if

	   end if
	end if

end sub

function createTool_createInPlace (self as component, parent as component, count as integer, left as integer, top as integer) as component

REM **********************************************************************
REM			createTool_createInPlace           
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
REM   martin	1/24/95 	Initial Version
REM
REM **********************************************************************
	
	dim newComp  as component
	dim newClass as string
	dim newName  as string

	REM
	REM CODE FOR NORMAL COMPONENTS
	REM
   	newClass = self.classToCreate
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

	InitializeCaption(newComp, newName)
	InitializePosition(newComp, left, top)

	REM FIXME	
	REM hack that will go away when the default look for
	REM groups changes
	REM
	const GROUP_LOOK_DRAW_IN_BOX 1
	if newClass = "group" then
	    newComp.look = GROUP_LOOK_DRAW_IN_BOX
	end if

	REM
	REM The buttons to bring up popup lists are
	REM 13 x 13 in PCV
	
	if newClass = "list" then
	    newComp.width = 13
	    newComp.height = 13
	end if
	

	newComp.visible = 1 

	createTool_createInPlace = newComp

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


sub createTool_destroyInPlace (self as component, comp as component)

REM **********************************************************************
REM			createTool_destroyInPlace           
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
REM   martin	1/24/95 	Initial Version
REM
REM **********************************************************************
	
   REM Eventually, change these hackSetInterpreterMode actions to be sent
   REM directly to the BuilderManager component in LEGOS...

	hackIntr!hackSetUIDirty()
	hackIntr!hackDeselectComponent()
end sub




function MakeToolButton(caption as string) as button
  DIM b as button

REM
REM Miscellaneous utility routine
REM

    b = MakeComponent("button", toolGroup)
    b.width = TOOL_WIDTH
    b.name = "new"+caption+"Tool"
    b.caption = caption
    b.proto = "createTool"
    b.visible = 1
    b.classToCreate = caption

    MakeToolButton = b
END function
