sub duplo_ui_ui_ui()
duplo_start()
end sub

sub duplo_start()
    
REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	lp-serv.bas
REM	AUTHOR:	David Loftesness, Jun 13, 1995
REM	DESCRIPTION:
REM		This code implements the gadget library property box
REM		for service components
REM	$Id: lp-serv.bas,v 1.1 98/03/12 20:26:41 martin Exp $
REM	Revision:   1.9 
REM

REM
REM change to &Heexx for DBCS
REM
CONST KEY_CTRL_00 &Hff00
CONST KEY_CTRL_FF &Hffff
    
  dim servicePropCtrl 	as control
  dim nameEntry             as entry
  dim protoEntry             as entry
  dim idEntry as entry
  dim idGroup as component
    
    const ENTRY_INDENT 60
    
    servicePropCtrl = MakeComponent("control", "top")
    servicePropCtrl.proto = "servicePropCtrl"
    
    nameEntry = MakeEntry(servicePropCtrl, "Name")
    nameEntry.proto = "nameEntry"
    nameEntry.maxChars = 80
    nameEntry.filter = 1
    
    protoEntry = MakeEntry(servicePropCtrl, "Proto")
    protoEntry.proto = "nameEntry"
    protoEntry.maxChars = 80
    protoEntry.filter = 1

    idEntry = MakeEntry(servicePropCtrl, "uniqueID")
    idEntry.maxChars = 80
    idGroup = idEntry.parent
    idGroup.visible = 0

end sub

function duplo_top() as component
    REM Return the top level component for this module
    duplo_top = servicePropCtrl
end function

sub servicePropCtrl_update(current as component)
  servicePropCtrl.current = current
  
  if (current.class = "alarm") then
    idGroup.visible = 1
    idEntry.text = current.uniqueID
  else
    idGroup.visible = 0
    idEntry.text = ""
  end if

  nameEntry.text = current.name
  protoEntry.text = current.proto
  
end sub

sub sp_apply()
 dim current as component
 dim tempControl as component
  
  current = servicePropCtrl.current
  tempControl = servicePropCtrl
  
  if tempControl.hackCheckUniqueName(nameEntry.text) then
    current.name = nameEntry.text
  else
    nameEntry.text = current.name
  end if
  
  current.proto = protoEntry.text
  
  if (current.class = "alarm") then
    current.uniqueID = idEntry.text
  end if

end sub

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
	visible = 1
    END CompInit
    g.visible = 1

    MakeEntry = e
END function

function nameEntry_filterChar(self as entry, newChar as integer, replaceStart as integer, replaceEnd as integer, endOfGroup as integer) as integer
    REM
    REM Don't allow these characters TO be part of the components name or
    REM BAD things will happen!
    REM
    select case newChar
      case asc("A") to asc("Z"), asc("a") to asc("z"), \
	asc("0") to asc("9"), asc("_") 
	nameEntry_filterChar = newChar
      case KEY_CTRL_00 to KEY_CTRL_FF
	nameEntry_filterChar = newChar
      case else
	nameEntry_filterChar = 0
    END select
END function
