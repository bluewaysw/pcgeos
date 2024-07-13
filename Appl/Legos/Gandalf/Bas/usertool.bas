sub duplo_ui_ui_ui()
 REM	Copyright (c) Geoworks 1995 -- All Rights Reserved
 REM	FILE:		STDINC.BH
 REM	$Id: usertool.bas,v 1.1 97/12/02 14:57:16 gene Exp $

dim system as module
system = SystemModule()

 REM end of stdinc.bh

DisableEvents()
Dim userToolTop as control
userToolTop = MakeComponent("control","top")
CompInit userToolTop
proto="userToolTop"
caption=" "
left=0
top=0
sizeHControl=0
sizeVControl=0
width=250
height=190
End CompInit
Dim bParent as button
bParent = MakeComponent("button",userToolTop)
CompInit bParent
proto="bParent"
caption="Parent"
left=5
top=10
look=3
visible=1
End CompInit
bParent.name="bParent"
Dim bChild as button
bChild = MakeComponent("button",userToolTop)
CompInit bChild
proto="bChild"
caption="Child"
left=5
top=65
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
bChild.name="bChild"
Dim nChild as number
nChild = MakeComponent("number",userToolTop)
CompInit nChild
proto="nChild"
left=5
top=30
width=70
visible=1
End CompInit
nChild.name="nChild"
Dim compName as label
compName = MakeComponent("label",userToolTop)
CompInit compName
proto="compName"
caption="<name>"
left=130
top=40
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
compName.name="compName"
Dim upName as label
upName = MakeComponent("label",userToolTop)
CompInit upName
proto="upName"
caption="<parent>"
left=130
top=15
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
upName.name="upName"
Dim downName as label
downName = MakeComponent("label",userToolTop)
CompInit downName
proto="downName"
caption="<child>"
left=130
top=65
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
downName.name="downName"
Dim list1 as list
list1 = MakeComponent("list",userToolTop)
CompInit list1
proto="list1"
look=2
left=7
top=90
width=120
End CompInit
list1.name="list1"
list1.captions[5]="Align Center (vert)"
list1.captions[4]="Align Center (horiz)"
list1.captions[3]="Align Right"
list1.captions[2]="Align Left"
list1.captions[1]="Align Bottom"
list1.captions[0]="Align Top"
list1.visible=1
list1.selectedItem=5
Dim bDoStuff as button
bDoStuff = MakeComponent("button",userToolTop)
CompInit bDoStuff
proto="bDoStuff"
caption="Apply"
left=160
top=120
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
bDoStuff.name="bDoStuff"
Dim bReset as button
bReset = MakeComponent("button",userToolTop)
CompInit bReset
proto="bReset"
caption="Reset"
left=111
top=120
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
bReset.name="bReset"
Dim bAdd as button
bAdd = MakeComponent("button",userToolTop)
CompInit bAdd
proto="bAdd"
caption="Add"
left=6
top=120
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
bAdd.name="bAdd"
Dim bRemove as button
bRemove = MakeComponent("button",userToolTop)
CompInit bRemove
proto="bRemove"
caption="Remove"
left=46
top=120
sizeHControl=3
sizeVControl=3
visible=1
End CompInit
bRemove.name="bRemove"

dim toggleAutoAdd as toggle
toggleAutoAdd = MakeComponent("toggle", userToolTop)
CompInit toggleAutoAdd
proto="toggleAutoAdd"
caption="Auto-add"
left=6
top=145
visible=1
end CompInit
toggleAutoAdd.name="toggleAutoAdd"

Dim entry1 as entry
entry1 = MakeComponent("entry",userToolTop)
CompInit entry1
proto="entry1"
left=6
top=170
width=220
visible=1
End CompInit
entry1.name="entry1"
userToolTop.name="userToolTop"
EnableEvents()
duplo_start()
end sub

sub duplo_start()
REM     $Revision: 1.1 $
 
    const TRUE 1
    const FALSE 0

    REM BUILDER is a component that represents the builder.  It is
    REM initialized after this module is loaded.  It has a "current"
    REM property which represents the currently-selected component.
  DIM BUILDER as component

   REM Array of selected components.  This is resized as necessary
   REM when components are added and removed from the selection list.
  DIM selected[0] as component
  
   userToolTop.visible = 1
end sub

sub ConnectToBuilder(c as component)
    REM Called when this prop box is enabled
    BUILDER = c
end sub

sub userToolTop_update(current as component)
 DIM i as integer
 DIM p as component
  
  REM control components get this event whenever the current selected
  REM component changes.

  if IsNullComponent(current) then
    compName.caption = "<null>"
    exit sub
  end if

  if (toggleAutoAdd.status<>0) then
    AddComponent(current)
  end if

  compName.caption = GetName(current)

  IF HasProperty(current, "parent") then
    p = current.parent
  END if

  REM Sorry for the ugly code, but Legos OR does not short circuit
  REM aargh.

  if (IsNullComponent(p)) then
      goto IsNull
  end if
  if (p.class = "app") then
IsNull:
    bParent.enabled = FALSE
    upName.caption = "<null>"
    nChild.value = 0
    nChild.enabled = FALSE
  else
    bParent.enabled = TRUE
    upName.caption = GetName(p)
    nChild.enabled = TRUE
    nChild.maximum = p.numChildren-1
    nChild.value = 0
    if (p.children[nChild.value] <> current) then
      nChild.value = FindChildIndex(current)
    end if
  end if

  onerror goto noChildren
  if (current.numChildren <> 0) then
    bChild.enabled = TRUE
    downName.caption = GetName(current.children[0])
  else
noChildrenResume:
    bChild.enabled = FALSE
    downName.caption = "<null>"
  end if
  exit sub

noChildren:
  resume noChildrenResume
end sub

function GetName(c as component) as string
  REM Return a string that uniquely identifies the component

  if (HasProperty(c, "name")) then
    GetName = c.name
  else if (c.proto <> "") then
    GetName = "(" + c.proto + ")"
  else
    GetName = "?none?"
  end if
end function

function FindChildIndex(c as component)
 dim p as component
 dim i as integer

  FindChildIndex = -1
  p = c.parent
  if IsNullComponent(p) then
    exit function
  end if

  for i = 0 to p.numChildren-1
    if p.children[i] = c then
      FindChildIndex = i
      exit function
    end if
  next i

end function

sub bChild_pressed(self as component)
  nChild.value = 0
  BUILDER.selection = BUILDER.selection.children[0]
end sub

sub bParent_pressed(self as component)
  BUILDER.selection = BUILDER.selection.parent
end sub

sub nChild_changed(self as number, value as integer)
  BUILDER.selection = BUILDER.selection.parent.children[nChild.value]
end sub

sub bAdd_pressed(self as button)
  AddComponent(BUILDER.selection)
end sub

sub bRemove_pressed(self as button)
  RemoveComponent(BUILDER.selection)
end sub

sub bReset_pressed(self as button)
  redim selected[0]
  Status()
end sub

sub AddComponent(c as component)
  REM Add component to our array of selections
  REM Do not add if the component is already in the array

  dim size as integer
  dim i as integer
  
  size = GetArraySize(selected, 0)
  for i = 0 to size-1
    if selected[i] = c then
      exit sub
    end if
  next i
  
  redim preserve selected[size+1]
  selected[size] = c
  Status()
end sub

sub RemoveComponent(c as component)
  REM Remove component from our array of selections
  REM Do not remove if component isn't already in the array

  dim size as integer
  dim i as integer
  
  size = GetArraySize(selected, 0)
  for i = 0 to size-1
    if selected[i] = c then
      selected[i] = selected[size-1]
      redim preserve selected[size-1]
      exit sub
    end if
  next i
  Status()
end sub

sub Status()
  REM Update our display of selected components
  
  dim size as integer
  dim i as integer
  dim s as string

  size = GetArraySize(selected,0)
  s = STR(size)+":"
  for i = 0 to size-1
    s = s + GetName(selected[i])+","
  next i
  entry1.text = s
end sub

sub bDoStuff_pressed(self as button)
  REM Perform the alignment operation specified by list1

  REM These numbers correspond with the list items in list1
  const ALIGN_TOP 0
  const ALIGN_BOTTOM 1
  const ALIGN_LEFT 2
  const ALIGN_RIGHT 3
  const ALIGN_HCENTER 4
  const ALIGN_VCENTER 5
  
  const SCALE_OPPOSITE_EDGE 1
  const SCALE_MIDDLE 2

    dim listItem as integer
  dim size as integer
  dim max as integer
  dim i as integer
  
  size = GetArraySize(selected, 0)

  listItem = list1.selectedItem
  select case listItem
  case ALIGN_TOP
    AlignProp("top")
  case ALIGN_BOTTOM
    AlignPropComplex("top", "height", SCALE_OPPOSITE_EDGE)
  case ALIGN_LEFT
    AlignProp("left")
  case ALIGN_RIGHT
    AlignPropComplex("left", "width", SCALE_OPPOSITE_EDGE)
  case ALIGN_HCENTER
    AlignPropComplex("top", "height", SCALE_MIDDLE)
  case ALIGN_VCENTER
    AlignPropComplex("left", "width", SCALE_MIDDLE)

REM
REM Add new cases here
REM    

  case else
  end select

end sub

sub AlignProp(prop as string)
  REM Give all selected components the same value for <prop>
  REM Take the value from the first selected component

  dim size as integer
  dim i as integer
  
  size = GetArraySize(selected, 0)

  for i = 1 to size-1
    selected[i].(prop) = selected[0].(prop)
  next i
end sub

sub AlignPropComplex(prop1 as string, prop2 as string, scale as integer)
  REM Adjust the <prop1> property of all selected components so that
  REM <prop1> + <prop2>/<scale> is the same for all of them
  REM
  REM If <scale> is 1, this is useful for aligning to RIGHT and BOTTOM
  REM If <scale> is 2, this is useful for center-aligning

  dim size as integer
  dim i as integer
  dim value as integer
  dim c as component
  
  size = GetArraySize(selected, 0)
  if size = 0 then
    exit sub
  end if
  value = selected[0].(prop1) + selected[0].(prop2) / scale
  for i = 1 to size-1
    c = selected[i]
    c.(prop1) = value - c.(prop2) / scale
  next i
end sub

