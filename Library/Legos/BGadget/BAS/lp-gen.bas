sub duplo_ui_ui_ui()

REM
REM change to &Heexx for DBCS
REM
CONST KEY_CTRL_00 &Hff00
CONST KEY_CTRL_FF &Hffff

	duplo_start()
end sub

sub duplo_start()

REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	lp-gadg.bas
REM	AUTHOR:	David Loftesness, Jun 13, 1995
REM	DESCRIPTION:
REM		This code implements the gadget library property box
REM	$Id: lp-gen.bas,v 1.1 98/03/12 20:30:02 martin Exp $
REM	Revision:   1.39
REM
    dim generalPropCtrl 	as component
      dim visibleBool 		as toggle
      dim enabledBool 		as toggle
      dim readOnlyBool 		as toggle
      dim leftValue		as number
      dim topValue		as number
      dim widthValue		as number
      dim heightValue		as number

    dim geomPropsDirty		as integer

      const LIST_INDENT	50
      const ENTRY_INDENT 100

    geomPropsDirty = 0

REM    generalPropCtrl = MakeComponent("form", "top")
    generalPropCtrl = MakeComponent("control", "top")
    generalPropCtrl.proto = "generalPropCtrl"
    generalPropCtrl.tileHAlign = 2
    generalPropCtrl.tileVAlign = 2
REM    generalPropCtrl.visible = 1

    dim boolGroup as group
    boolGroup = MakeComponent("group", generalPropCtrl)
    SetGroupTiling(boolGroup)
	visibleBool = MakeComponent("toggle", boolGroup)
	   visibleBool.caption = "Visible"
	   visibleBool.visible = 1	

	enabledBool = MakeComponent("toggle", boolGroup)
	   enabledBool.caption = "Enabled"
	   enabledBool.visible = 1	

	readOnlyBool = MakeComponent("toggle", boolGroup)
	   readOnlyBool.caption = "Read Only"
	   readOnlyBool.visible = 1	

	DIM nameEntry		as entry
	  nameEntry = MakeEntry(generalPropCtrl, "Name")
	  nameEntry.proto = "nameEntry"
	  nameEntry.maxChars = 80
	  nameEntry.filter = 1

	DIM protoEntry		as entry
	  protoEntry = MakeEntry(generalPropCtrl, "Proto")
	  protoEntry.proto = "nameEntry"
	  protoEntry.maxChars = 80
	  protoEntry.filter = 1

	DIM captionEntry	as entry
	  captionEntry = MakeEntry(generalPropCtrl, "Caption Text")
	  captionEntry.proto = "captionEntry"


rem removed for M5, dl
REM      dim captionGraphic	as label
rem	captionGraphic = MakeComponent("label", generalPropCtrl)
rem	   captionGraphic.caption = "Graphic"
rem	   captionGraphic.visible = 1

      DIM hSizeGroup	as group
      DIM hSizeList	as list
	hSizeGroup = MakeLabeledGroup(generalPropCtrl, "Width")
	hSizeList = MakeComponent("list", hSizeGroup)
	  hSizeList.captions[0] = "As specified"
	  hSizeList.captions[1] = "As small as possible"
	  hSizeList.captions[2] = "As big as possible"
	  hSizeList.captions[3] = "As needed"
	  CompInit hSizeList
	      look = 0
	      selectedItem = 0
	      proto = "hSizeList"
	      top = 0
	      left = LIST_INDENT
	      visible = 1
	  END CompInit
	hSizeGroup.visible = 1

      DIM vSizeGroup	as group
      DIM vSizeList	as list
	vSizeGroup = MakeLabeledGroup(generalPropCtrl, "Height")
	vSizeList = MakeComponent("list", vSizeGroup)
	  vSizeList.captions[0] = "As specified"
	  vSizeList.captions[1] = "As small as possible"
	  vSizeList.captions[2] = "As big as possible"
	  vSizeList.captions[3] = "As needed"
	  CompInit vSizeList
	      look = 0
	      selectedItem = 0
	      proto = "vSizeList"
	      top = 0
	      left = LIST_INDENT
	      visible = 1
	  END CompInit
	vSizeGroup.visible = 1


        dim leftTopGroup as group
	   leftTopGroup = MakeComponent("group", generalPropCtrl)
	   leftTopGroup.tileLayout = 1
	   SetGroupTiling(leftTopGroup)

        dim widthHeightGroup as group
	   widthHeightGroup = MakeComponent("group", generalPropCtrl)
	   widthHeightGroup.tileLayout = 1
	   SetGroupTiling(widthHeightGroup)

	leftValue = MakeComponent("number", leftTopGroup)
	   leftValue.caption = "Left"
	   leftValue.proto = "geomNumber"
	   leftValue.maximum = 9999
	   leftValue.visible = 1
	topValue = MakeComponent("number", leftTopGroup)
	   topValue.caption = "Top"
	   topValue.proto = "geomNumber"
	   topValue.maximum = 9999
	   topValue.visible = 1
	widthValue = MakeComponent("number", widthHeightGroup)
	   widthValue.caption = "Width"
	   widthValue.proto = "geomNumber"
	   widthValue.maximum = 9999
	   widthValue.visible = 1
	heightValue = MakeComponent("number", widthHeightGroup)
	   heightValue.caption = "Height"
	   heightValue.proto = "geomNumber"
	   heightValue.maximum = 9999
	   heightValue.visible = 1
end sub

function duplo_top() as component
    REM Return the top level component for this module
	duplo_top = generalPropCtrl
end function

sub hSizeList_changed(self as list, index as integer)
    REM width value should only be enabled if "as specified"
    widthValue.enabled = (index = 0)
END sub

sub vSizeList_changed(self as list, index as integer)
    REM height value should only be enabled if "as specified"
    heightValue.enabled = (index = 0)
END sub

sub generalPropCtrl_update(current as component)
REM
REM Update the UI of this property group to reflect the current selection
REM
    generalPropCtrl.current = current
    visibleBool.status = current.visible

    if (NOT HasProperty(current, "enabled"))
      enabledBool.enabled = 0
    else 
      enabledBool.enabled = 1
      enabledBool.status = current.enabled
    end if

    if (NOT HasProperty(current, "readOnly"))
      readOnlyBool.enabled = 0
    else
      readOnlyBool.enabled = 1
      readOnlyBool.status = current.readOnly
    end if

    REM
    REM disable the caption for certain classes
    REM
    IF HasProperty(current, "caption") THEN
	captionEntry.enabled = 1
	captionEntry.text = current.caption
    ELSE
	captionEntry.enabled = 0
	captionEntry.text = "none"
    END IF
    
    nameEntry.text = current.name
    
    IF HasProperty(current, "proto") then
	protoEntry.text = current.proto
    ELSE 
	protoEntry.text = current.name
    END if

rem    captionGraphic.graphic = current.graphic
    
    IF (current.class = "popup") THEN
	vSizeGroup.enabled = 0
	hSizeGroup.enabled = 0
	leftTopGroup.enabled = 0
	widthHeightGroup.enabled = 0
    ELSE
	vSizeGroup.enabled = 1
	hSizeGroup.enabled = 1
	leftTopGroup.enabled = 1
	widthHeightGroup.enabled = 1

	leftValue.value = current.left
	topValue.value = current.top
	widthValue.value = current.width
	heightValue.value = current.height
    
	hSizeList.selectedItem = current.sizeHControl
	hSizeList_changed(hSizeList, hSizeList.selectedItem)
    
	vSizeList.selectedItem = current.sizeVControl
	vSizeList_changed(vSizeList, vSizeList.selectedItem)
    
REM
REM Disable left/top if parent is tiling or the component has no parent
REM (which would be a form, dialog etc...)
REM
	if (NOT IsNullComponent(current.parent)) then
	    if HasProperty(current.parent, "tile") then
		if current.parent.tile then
		    leftValue.enabled = 0
		    topValue.enabled = 0
		else
		    leftValue.enabled = 1
		    topValue.enabled = 1
		end if
	    
	    else
		leftValue.enabled = 1
		topValue.enabled = 1
	    end if
	else
	    REM event though forms don't have parents, they still
	    REM do have positions, now.  Ron 9/19/95
	    leftValue.enabled = 1
	    topValue.enabled = 1
	end if
    
	leftValue.dirty = 0
	topValue.dirty = 0
	widthValue.dirty = 0
	heightValue.dirty = 0

    END IF
    
end sub

sub sp_apply ()
  dim current as component
    current = generalPropCtrl.current

    current.visible = 0
    if (enabledBool.enabled = 1)
      current.enabled = enabledBool.status
    end if
    if (readOnlyBool.enabled = 1) then
      current.readOnly = readOnlyBool.status
    end if
REM
REM Some other components aren't supposed to have captions, particularly
REM if they already have a graphic...
REM
    IF (HasProperty(current, "caption")) THEN
      if (HasProperty(current, "graphic")) then
	if (IsNullComplex(current.graphic)) then
	  REM
	  REM Annoying... have to split up IF clauses, else we'll hit an 
	  REM RTE on components without a graphic property...
	  REM
	  current.caption = captionEntry.text
	end if
      else
	current.caption = captionEntry.text
      end if
    end if

REM dont allow naming a component if another component already has
REM that name
    IF generalPropCtrl.hackCheckUniqueName(nameEntry.text) THEN
	current.name = nameEntry.text
    ELSE
	nameEntry.text = current.name
    END IF

    current.proto = protoEntry.text
    
    current.sizeHControl = hSizeList.selectedItem
    current.sizeVControl = vSizeList.selectedItem

REM
REM force re-setting of width/height if we're calling for AS_SPECIFIED
REM

REM    if (current.sizeHControl = 0) then
REM 	current.width = widthValue.value
REM     end if
REM    if (current.sizeVControl = 0) then
REM	current.height = heightValue.value
REM    end if

    if leftValue.enabled then
	current.left = leftValue.value
    end if
    if topValue.enabled then
	current.top = topValue.value
    end if
    if widthValue.enabled then
	current.width = widthValue.value
    end if
    if heightValue.enabled then
	current.height = heightValue.value
    end if

    current.visible = visibleBool.status

    REM
    REM re-read properties (in case caption changes size), but
    REM only if we're still visible
    REM

    if (current.visible) then
	generalPropCtrl_update(current)
    end if

end sub


sub geomNumber_changed(self as number, value as integer)
    self.dirty = 1
end sub

function nameEntry_filterChar(self as entry, newChar as integer, replaceStart as integer, replaceEnd as integer, endOfGroup as integer) as integer
    REM
    REM Don't allow these characters TO be part of the components name or
    REM BAD things will happen!
    REM
  nameEntry_filterChar = 0
    select case newChar
     case asc("A") to asc("Z"), asc("a") to asc("z"), \
      asc("0") to asc("9"), asc("_") 
      nameEntry_filterChar = newChar
  case KEY_CTRL_00 to KEY_CTRL_FF
      nameEntry_filterChar = newChar
     case else
    END select
END function


function MakeChoice(parent as group,name as string,value as integer) as choice
    REM unused
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

sub SetGroupTiling(g as group)
    g.tile = 1
    g.tileSpacing = 1
    g.tileHAlign = 2
    g.tileVAlign = 2
    g.visible = 1
END sub

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

function MakeEntry(parent as component, caption as string) as entry
  DIM e as entry
  DIM g as group

    g = MakeLabeledGroup(parent, caption)
    e = MakeComponent("entry", g)
    CompInit e
	top = 0
	left = ENTRY_INDENT
	width = 100
	height = 20
	visible = 1
    END CompInit
    g.visible = 1

    MakeEntry = e
END function
