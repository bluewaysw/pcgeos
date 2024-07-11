sub duplo_ui_ui_ui()

REM ========================================================================
REM
REM	Copyright (c) Geoworks 1994 
REM                    -- All Rights Reserved
REM
REM	FILE: 	sn-delx.bas
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
REM	$Id: sn-delx.bas,v 1.1 98/03/12 20:24:36 martin Exp $
REM	Revision:   1.34
REM
REM ======================================================================


    const TOOL_WIDTH 60
  DIM BUILDER		as component
    export BUILDER

  dim toolGroup		as group
    
    toolGroup = MakeComponent("group", "top")
    toolGroup.tile = 1
    toolGroup.tileSpacing = 1
    
  dim addToolTool		as button
  dim newTextTool		as button
  dim newTableTool		as button
    
    addToolTool = MakeComponent("button", toolGroup)
REM    addToolTool.width = TOOL_WIDTH
REM    addToolTool.caption = "Add..."
REM    addToolTool.proto = "addToolTool"
REM    addToolTool.visible = 1
    
    newTextTool = MakeToolButton("text")
      newTextTool.width = TOOL_WIDTH
      newTextTool.visible = 1
      newTextTool.graphic = GetComplex(0)
    newTableTool = MakeToolButton("table")
      newTableTool.width = TOOL_WIDTH
      newTableTool.visible = 1
      newTableTool.graphic = GetComplex(1)
      
    
    REM
    REM Dialog for adding aggregates to the palette
    REM
  dim addToolDialog		as dialog
  dim addToolDialogOK		as button
  dim addToolDialogCancel	as button
  dim addToolModule		as entry
  DIM addToolAggToggle		as toggle
    
    addToolDialog = MakeComponent("dialog", "app")
    addToolDialog.caption = "Add Aggregate To Toolbox"
    addToolDialog.tile = 1
    addToolDialog.visible = 0
    
    addToolModule = MakeComponent("entry", addToolDialog)
    addToolModule.caption = "Module to add:"
    addToolModule.proto = "addToolModule"
    addToolModule.visible = 1
    addToolModule.filter = 1
    
    addToolAggToggle = MakeComponent("toggle", addToolDialog)
    addToolAggToggle.proto = "addToolAggToggle"
    addToolAggToggle.caption = "Aggregate in liberty"
    addToolAggToggle.visible = 1

  dim addToolDialogReplyBar as group
    addToolDialogReplyBar = MakeComponent("group", addToolDialog)
    addToolDialogReplyBar.tile = 1
    addToolDialogReplyBar.tileLayout = 1
    addToolDialogReplyBar.tileHAlign = 1
    addToolDialogReplyBar.visible = 1
    
    addToolDialogOK = MakeComponent("button", addToolDialogReplyBar)
    addToolDialogOK.caption = "OK"
    addToolDialogOK.proto = "addToolDialogOK"
    addToolDialogOK.default = 1
    addToolDialogOK.visible = 1
    
    addToolDialogCancel = MakeComponent("button", addToolDialogReplyBar)
    addToolDialogCancel.caption = "Cancel"
    addToolDialogCancel.proto = "addToolDialogCancel"
    addToolDialogCancel.visible = 1
    
    duplo_start()
end sub

sub duplo_start()
    REM parentModule should be set by the module which loaded us
    REM ie, bgadnew

  DIM parentModule as module
  DIM hackIntr as component
    EXPORT parentModule
    
    const	BBM_NORMAL	0
    const	BBM_PLACEMENT	1
    const	BBM_CREATION	2
    const	BBM_RESIZE	3
    
    hackIntr = toolGroup.parent.parent
    
end sub

function duplo_top() as component
    REM Return the top level component for this module
    duplo_top = toolGroup
end function



sub newAggTool_pressed(self as component)

REM
REM Handler for aggregate create tools
REM

    hackIntr!hackSetMode(BBM_CREATION, self)
    parentModule:AddURL(self.aggLibPath, self.aggOnLiberty)
end sub


function newAggTool_createInPlace (self as component, parent as component, count as integer, left as integer, top as integer) as component

REM  SYNOPSIS:	Handler for aggregate create tools.
REM             Called by interpreter when in creation mode, and the user 
REM		clicks on a possible parent.  This version is for aggregates.
REM  CALLED BY:	EXTERNAL, interpreter
REM  PASS:	self	- creation control
REM		parent	- object to add new component under
REM		count	- # of objects of this class already created
REM		left/top- user's click position
    
  dim aggComp  as component
  dim newComp  as component
  dim newClass as string
  dim aggName  as string
    
    newClass = self.classToCreate
    
    REM
    REM CODE FOR AGGREGATE COMPONENTS
    REM
    aggName = self.aggClass + str(count)
    aggComp = MakeComponent(self.aggClass, parent)
    aggComp.left = left
    aggComp.top = top
    aggComp.name  = aggName
    aggComp.proto = aggName
    
    newAggTool_createInPlace = newComp
    
end function



sub createTool_pressed(self as component)

REM
REM Handler for create tools
REM
    hackIntr!hackSetMode(BBM_CREATION, self)
end sub


function createTool_createInPlace(self as component, parent as component, count as integer, left as integer, top as integer) as component

REM  SYNOPSIS:	Handler for create tools.
REM             Called by interpreter when in creation mode, and the user 
REM		clicks on a possible parent.
REM  CALLED BY:	EXTERNAL, interpreter
REM  PASS:	self	- creation control
REM		parent	- object to add new component under
REM		count	- # of objects of this class already created
REM		left/top- user's click position
    
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
    if newClass = "table" then
	newComp.width = 60
	newComp.height = 80
	newComp.defaultRowHeight = 14
	newComp.numRows = 3
	newComp.numColumns = 3
	newComp.columnWidths[0]=20
	newComp.columnWidths[1]=20
	newComp.columnWidths[2]=20
	
    end if
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


sub createTool_destroyInPlace(self as component, comp as component)

REM  CALLED BY:	EXTERNAL, interpreter
REM  PASS:	self	- creation control
REM		comp	- object to destroy

    hackIntr!hackSetUIDirty()
    hackIntr!hackDeselectComponent()
end sub


sub InitializePosition(self as component, left as integer, top as integer)
  dim parent as component

REM SYNOPSIS:	Initialize the size and position of the given object 
REM		based on its class.
    
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
	
REM	if self.class = "list" then
REM Make scrolllist a scrolllist
REM	    self.look = 1
REM	end if
	
    end if
    
end sub

sub addAggToPalette(aggLibPath as string, aggOnLiberty as integer)
  
  REM
  REM Add tool dialog
  REM
  
 dim m as module
 dim newAggButton as button
 dim agg_class as string
  
  REM
  REM Check if aggLibPath is already present.  If not, load the module
  REM and create a new trigger for it.
  REM
  REM FIXME can load more than once
  m = LoadModuleShared(aggLibPath)
  agg_class = GetExport(m)
  
  if (agg_class = "") then
    UnloadModule(m)
    REM FIXME: put up a nice error dialog "Doesn't export, bozo!"
    exit sub
  end if
  
  newAggButton = MakeToolButton(agg_class)
  newAggButton.proto = "newAggTool"
  newAggButton.width = TOOL_WIDTH
  newAggButton.visible = 1
  newAggButton.aggLibPath = aggLibPath
  newAggButton.aggClass = agg_class
  newAggButton.aggOnLiberty = aggOnLiberty
end sub

sub addToolTool_pressed(self as button)
    addToolModule.text = "DOS://~D/"
    addToolDialog.visible = 1
    addToolModule.filter = 1
end sub

sub addToolDialogOK_pressed(self as button)
    REM
    REM If the user accidentally includes ".BC" in the module name, be sure TO
    REM strip it out...
    REM
    addToolDialog.visible = 0
    IF (right(addToolModule.text, 3) = ".BC") THEN
	addAggToPalette(left(addToolModule.text, len(addToolModule.text) - 3), addToolAggToggle.status)
    ELSE 
	addAggToPalette(addToolModule.text, addToolAggToggle.status)
    END IF
end sub

sub addToolDialogCancel_pressed(self as button)
    addToolDialog.visible = 0
end sub



function MakeToolButton(caption as string) as button

REM
REM Miscellaneous utility routine
REM

  DIM b as button

    b = MakeComponent("button", toolGroup)
    b.caption = caption

    REM Illegal to ask for width of non-visible, non-SIZE_AS_SPECIFIED
    REM component.
    REM IF (b.width < TOOL_WIDTH) then
    REM    b.width = TOOL_WIDTH
    REM    b.caption = caption
    REM END IF

    b.name = "new"+caption+"Tool"
    b.proto = "createTool"
    REM b.visible = 1		Let caller do after setting width.
    b.classToCreate = caption

    MakeToolButton = b
END function

function addToolModule_filterChar(self as entry, newChar as integer, replaceStart as integer, replaceEnd as integer, endOfGroup as integer) as integer

REM
REM Miscellaneous utility routine
REM

    IF ((newChar >= asc("a")) and (newChar <= asc("z"))) THEN
	newChar = newChar - asc("a") + asc("A")
    END IF
    addToolModule_filterChar = newChar
END function
	
