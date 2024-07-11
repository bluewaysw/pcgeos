sub duplo_ui_ui_ui()
duplo_start()
end sub


sub duplo_start()
REM ========================================================================
REM
REM     Copyright (c) Geoworks 1994 
REM                    -- All Rights Reserved
REM
REM     FILE:   lp-child.bas
REM     AUTHOR: Martin Turon, December 21, 1994
REM
REM     REVISION HISTORY
REM             Name    Date            Description
REM             ----    ----            -----------
REM             martin  12/21/94        Initial Version
REM
REM     DESCRIPTION:
REM             This code implements the basic geometry property box for 
REM             all components that have such properties (all components 
REM             that are somehow subclassed off of GoolGeomClass.)
REM
REM	$Id: lp-child.bas,v 1.1 98/03/12 20:30:16 martin Exp $
REM     Revision:   1.20
REM
REM ======================================================================

REM *********************************************************************
REM *           Define This Module's Components
REM **********************************************************************

    const LIST_INDENT 100
	dim childCtrl	     as component
	export childCtrl
	dim childCtrlGroup   as group
rem	dim compactBool      as component
	dim tileToggle      as toggle
	dim managedUIGroup   as group
	dim tileSpacingNum   as number
	dim hInsetValue	     as number
	dim vInsetValue	     as number

	childCtrl = MakeComponent("control", "top")
REM	childCtrl = MakeComponent("form", "top")
	   childCtrl.proto = "childCtrl"
	   childCtrl.tileHAlign = 2
	   childCtrl.tileVAlign = 2
REM	   childCtrl.visible = 1


REM *********************************************************************
REM *           Define the childCtrl user interface.
REM **********************************************************************

	childCtrlGroup = MakeComponent("group", childCtrl)
	   childCtrlGroup.drawbox = 0
	   childCtrlGroup.sizeHControl = 1
	   SetGroupTiling(childCtrlGroup)

	tileToggle = MakeComponent("toggle", childCtrlGroup)
	   tileToggle.proto   = "tileToggle"
	   tileToggle.caption = "Auto Layout"
	   tileToggle.visible = 1	
	   tileToggle.status = 1

	managedUIGroup = MakeComponent("group", childCtrlGroup)
	   managedUIGroup.drawbox = 0
	   SetGroupTiling(managedUIGroup)

      DIM layoutGroup	as group
      dim layoutList	as list
	layoutGroup = MakeLabeledGroup(managedUIGroup, "Layout")
	layoutList = MakeComponent("list", layoutGroup)
	   layoutList.captions[0] = "Vertical"
	   layoutList.captions[1] = "Horizontal"
	   layoutList.selectedItem = 0
	   layoutList.top = 0
	   layoutList.left = LIST_INDENT
	   layoutList.look = 0
	   layoutList.visible = 1
	layoutGroup.visible = 1
	   
      DIM hAlignGroup	as group
      dim hAlignList	as list
	hAlignGroup = MakeLabeledGroup(managedUIGroup, "Align Horizontal")
	hAlignList = MakeComponent("list", hAlignGroup)
	   hAlignList.captions[0] = "Center"
	   hAlignList.captions[1] = "Full" 
	   hAlignList.captions[2] = "Left"
	   hAlignList.captions[3] = "Right"
	   hAlignList.look = 0
	   hAlignList.selectedItem = 0
	   hAlignList.top = 0
	   hAlignList.left = LIST_INDENT
	   hAlignList.visible = 1
	hAlignGroup.visible = 1

      DIM vAlignGroup	as group
      dim vAlignList	as list
	vAlignGroup = MakeLabeledGroup(managedUIGroup, "Align Vertical")
	vAlignList = MakeComponent("list", vAlignGroup)
	   vAlignList.captions[0] = "Center"
	   vAlignList.captions[1] = "Full" 
	   vAlignList.captions[2] = "Top"
	   vAlignList.captions[3] = "Bottom"
	   vAlignList.selectedItem = 0
	   vAlignList.look = 0
	   vAlignList.top = 0
	   vAlignList.left = LIST_INDENT
	   vAlignList.visible = 1
	vAlignGroup.visible = 1

	tileSpacingNum = MakeComponent("number", managedUIGroup)
	   tileSpacingNum.minimum = 0
	   tileSpacingNum.maximum = 64
	   tileSpacingNum.value = 2
	   tileSpacingNum.caption = "Tile Spacing"
	   tileSpacingNum.visible = 1
	hInsetValue = MakeComponent("number", managedUIGroup)
	   hInsetValue.caption = "Horiz. Inset"
	   hInsetValue.maximum = 64
	   hInsetValue.minimum = 0
	   hInsetValue.visible = 1
	vInsetValue = MakeComponent("number", managedUIGroup)
	   vInsetValue.caption = "Vertical Inset"
	   vInsetValue.maximum = 64
	   vInsetValue.minimum = 0
	   vInsetValue.visible = 1

rem	 SetTop(managedUIRight)

end sub

function duplo_top() as component
    REM Return the top level component for this module

	duplo_top = childCtrl

end function

sub childCtrl_update (current as component)

REM **********************************************************************
REM                     childCtrl_update
REM **********************************************************************
REM
REM  SYNOPSIS:  Code to update the UI of this controller
REM     
REM  CALLED BY: duplo
REM  PASS:      current = component whose properties we want to reflect
REM  RETURN:    nothing
REM
REM  REVISION HISTORY
REM   Name      Date            Description
REM   ----      ----            -----------
REM   martin    12/21/94        Initial Version
REM
REM **********************************************************************

    dim jval as integer
    dim newX as integer
    dim newY as integer
    dim propVal as integer

    childCtrl.current = current

REM if ((current.class = "group") or (current.class = "form")) then
    if (HasProperty(current, "tile") and not (current.class = "gadget" or current.class = "table")) then
	childCtrlGroup.enabled = 1

	layoutList.selectedItem = current.tileLayout

	tileSpacingNum.value = current.tileSpacing

	tileToggle.status = current.tile
	managedUIGroup.enabled = tileToggle.status

	hAlignList.selectedItem = current.tileHAlign
	vAlignList.selectedItem = current.tileVAlign
	hInsetValue.value = current.tileHInset
	vInsetValue.value = current.tileVInset
    else
	childCtrlGroup.enabled = 0
    end if

REM    zoneSelector!set(newX, newY)
	       
end sub



sub sp_apply()
REM **********************************************************************
REM                     sp_apply
REM **********************************************************************
REM
REM  SYNOPSIS:  Code to set properties of the current component to reflect
REM             the UI in the child management property box.
REM     
REM  CALLED BY: duplo
REM  PASS:      current = component whose properties we want to reflect
REM  RETURN:    nothing
REM
REM  REVISION HISTORY
REM   Name      Date            Description
REM   ----      ----            -----------
REM   martin    12/21/94        Initial Version
REM
REM **********************************************************************
  dim current      as component    	REM component being altered
  dim tempvis as integer
    REM
    REM if we are visible and were tiled and are not going to be
    REM anymore, then save all the childrens positions.
    REM
  dim c as integer
    REM
    REM this can change to use user-defined variables on the children
    REM instead of arrays, but I don't want to write that data out
    REM incase we ever get to that point.
  dim xpos[50] as integer
  dim ypos[50] as integer
  dim i as integer
  dim child as component
	    
    current = childCtrl.current
    tempvis = current.visible

    c = 0
    if tempvis AND (current.tile) AND (NOT tileToggle.status) then
	c = current.numChildren
	if c <> 0 then
	    for i = 0 to c -1
		child = current.children[i]
		if HasProperty(child, "left") AND HasProperty(child, "top") then
		    xpos[i] = child.left
		    ypos[i] = child.top
		end if
	    next i
	end if
    end if
	      
    current.visible 		= 0

    current.tile 		= tileToggle.status

    if current.tile then
	current.tileHAlign = hAlignList.selectedItem
	current.tileVAlign = vAlignList.selectedItem

	current.tileLayout 		= layoutList.selectedItem
	current.tileSpacing		= tileSpacingNum.value
	current.tileHInset		= hInsetValue.value
	current.tileVInset		= vInsetValue.value

rem      current.justifychildren 	= newAlign
	rem      current.compact 		= compactBool.selection + 1
    end if
    if c <> 0 then
	for i = 0 to c -1
	    child = current.children[i]
	    if HasProperty(child, "left") AND HasProperty(child, "top") then
		child.left = xpos[i]
		child.top = ypos[i]
	    end if
	next i
    end if

    current.visible = tempvis

end sub

sub tileToggle_changed (self as toggle)
    managedUIGroup.enabled = self.status
end sub

function MakeChoice(parent as group,name as string,value as integer) as choice
    REM currently unused

    REM pass value = -1 if you don't want a value set
    
  DIM c as choice
    c = MakeComponent("choice", parent)
    c.caption = name
    IF (value <> -1) THEN
	c.value = value
    END IF
    c.visible = 1
    MakeChoice = c
END function

function MakeLabeledGroup(parent as component, name as string) as group
  DIM l as label
  DIM g as group
    g = MakeComponent("group", parent)
    l = MakeComponent("label", g)
    compinit l
	top = 0
	left = 0
	visible = 1
    END compinit
    l.caption = name

    MakeLabeledGroup = g
END function

sub SetGroupTiling(g as group)
    g.tile = 1
    g.tileSpacing = 1
    g.tileHAlign = 2
    g.tileVAlign = 2
    g.visible = 1
END sub
