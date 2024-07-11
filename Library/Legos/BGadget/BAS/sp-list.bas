sub duplo_ui_ui_ui()

    dim listSpecPropBox as component

    listSpecPropBox = MakeComponent("control","top")
      listSpecPropBox.name  = "listSpecPropBox"
      listSpecPropBox.proto = "listSpecPropBox"

    dim lookGroup as group
    lookGroup = MakeComponent("group", listSpecPropBox)
      lookGroup.name	= "lookGroup"
      lookGroup.tile = 1
      lookGroup.tileLayout = 1
      lookGroup.tileHAlign = 1
      lookGroup.visible = 1

    dim lookLabel as label
    lookLabel = MakeComponent("label", lookGroup)
      lookLabel.name	= "lookLabel"
      lookLabel.caption = "Look:"
      lookLabel.visible = 1

    dim look as list
    look = MakeComponent("list", lookGroup)
      look.name	   = "look"
      look.proto   = "look"
      look.look = 0
      look.captions[0] = "Popup"
      look.captions[1] = "Scrollable"
      look.visible = 1

REM    DIM numVisNum as number
REM	 numVisNum = MakeComponent("number", listSpecPropBox)
REM	 numVisNum.minimum = 1
REM	 numVisNum.maximum = 25
REM	 numVisNum.caption = "numVisibleItems"
REM	 numVisNum.visible = 1

    dim behaviorGroup as group
    behaviorGroup = MakeComponent("group", listSpecPropBox)
      behaviorGroup.name    = "behaviorGroup"
      behaviorGroup.tile = 1
      behaviorGroup.tileLayout = 1
      behaviorGroup.tileHAlign = 1
      behaviorGroup.visible = 1

    dim bLabel as label
    bLabel = MakeComponent("label", behaviorGroup)
      bLabel.name    = "bLabel"
      bLabel.caption = "Behavior:"
      bLabel.visible = 1

    dim behavior as list
    behavior = MakeComponent("list", behaviorGroup)
      behavior.name    = "behavior"
      behavior.proto   = "behavior"
      behavior.look = 0
      behavior.captions[0]="0 or 1 items"
      behavior.captions[1]="one item"
      behavior.captions[2]="0 or many items"
      behavior.visible = 1

    dim editItemEntry as entry
    editItemEntry = MakeComponent("entry", listSpecPropBox)
      editItemEntry.name = "editItemEntry"
      editItemEntry.proto = "editItemEntry"
      editItemEntry.caption = "Edit Item:"
      editItemEntry.visible = 1

    dim editItemGroup as group
    editItemGroup = MakeComponent("group", listSpecPropBox)
      editItemGroup.name = "editItemGroup"
      editItemGroup.tile = 1
      editItemGroup.tileLayout = 1
      editItemGroup.tileHAlign = 0
      editItemGroup.visible = 1

    dim editItemList as list
    editItemList = MakeComponent("list", editItemGroup)
      editItemList.look = 1
      editItemList.name = "editItemList"
      editItemList.proto = "editItemList"
      editItemList.visible = 1

    dim editItemCommands as group
    editItemCommands = MakeComponent("group", editItemGroup)
    editItemCommands.name = "editItemCommands"
    editItemCommands.tile = 1
    editItemCommands.tileHAlign = 2
    editItemCommands.tileVAlign = 2
      editItemCommands.tileSpacing = 0
      editItemCommands.visible = 1

    dim insertItem as button
    insertItem = MakeComponent("button", editItemCommands)
      insertItem.name = "insertItem"
      insertItem.proto = "insertItem"
      insertItem.caption = "Insert"
      insertItem.visible = 1

    dim deleteItem as button
    deleteItem = MakeComponent("button", editItemCommands)
      deleteItem.name = "deleteItem"
      deleteItem.proto = "deleteItem"
      deleteItem.caption = "Delete"
      deleteItem.enabled = 0
      deleteItem.visible = 1

    dim upItem as button
    upItem = MakeComponent("button", editItemCommands)
      upItem.name = "upItem"
      upItem.proto = "upItem"
      upItem.caption = "Nudge Up"
      upItem.visible = 1

    dim downItem as button
    downItem = MakeComponent("button", editItemCommands)
      downItem.name = "downItem"
      downItem.proto = "downItem"
      downItem.caption = "Nudge Down"
      downItem.visible = 1

    dim deselectItem as button
    deselectItem = MakeComponent("button", editItemCommands)
      deselectItem.name = "deselectItem"
      deselectItem.proto = "deselectItem"
      deselectItem.caption = "Deselect"
      deselectItem.visible = 1

    dim clearItems as button
    clearItems = MakeComponent("button", editItemCommands)
      clearItems.name = "clearItems"
      clearItems.proto = "clearItems"
      clearItems.caption = "Clear"
      clearItems.visible = 1


duplo_start()
    
end sub

sub duplo_start()
end sub

sub duplo_revision()

REM	Copyright (c) Geoworks 1995 
REM		       -- All Rights Reserved
REM
REM	FILE:	sp-list.bas
REM	AUTHOR: Martin Turon, Oct 3, 1995
REM	Revision is in label
REM	$Id: sp-list.bas,v 1.1 98/03/12 20:30:18 martin Exp $
REM	Revision:   1.16 

end sub

function duplo_top() as component
    duplo_top = listSpecPropBox
end function

sub listSpecPropBox_update (current as list)
  
  listSpecPropBox.current	= current
  behavior.selectedItem	= current.behavior
  look.selectedItem		= current.look
REM    numVisNum.value		= current.numVisibleItems
  
 dim i as integer
  if current.numItems > 0 then
    for i = 0 to current.numItems-1
      editItemList.captions[i] = current.captions[i]
    next
  end if
  
  REM Extra code to make sure the property box doesn't have too	
  REM many items...  Real fix for this should be done by run-time
  REM list component (see gdglist.asm: GadgetListSetNumItems)
  if current.numItems < editItemList.numItems then
    for i = editItemList.numItems-1 to current.numItems step -1
      editItemList.Delete(i)
    next 
  end if
  
rem    editItemList.numItems	= current.numItems
  editItemList.selectedItem	= current.selectedItem
  
end sub


sub insertItem_pressed(self as button)
REM  SYNOPSIS:	Insert an item before the current
REM		selection, and update the selection
REM		to be the new item
 dim selected as integer
  selected = editItemList.selectedItem
  if selected = -1 then
    REM if no selection yet, default to first item
    editItemList.captions[0] = editItemEntry.text
    editItemList.selectedItem = 0
  else
    editItemList.Insert(selected, editItemEntry.text)
    editItemList.selectedItem = selected
  end if
  
end sub

sub deleteItem_pressed(self as button)
  editItemList.Delete(editItemList.selectedItem)
end sub

sub deselectItem_pressed(self as button)
  editItemList.selectedItem = -1
end sub


sub clearItems_pressed(self as button)
  editItemList.Clear()
end sub

sub upItem_pressed(self as button)
REM  SYNOPSIS:	Moves the currently selected item
REM		up in the list.
  
 dim selected as integer
  
  selected = editItemList.selectedItem 
  if selected > 0 then
   dim curText as string
   dim upText as string
    
    curText = editItemList.captions[selected]
    upText  = editItemList.captions[selected-1]
    
    editItemList.captions[selected-1] = curText
    editItemList.captions[selected] = upText
    
    editItemList.selectedItem = selected - 1
  end if
  
end sub

sub downItem_pressed(self as button)
REM ********************************************
REM		downItem_pressed
REM ********************************************
REM
REM  SYNOPSIS:	Moves the currently selected item
REM		down in the list.
REM	
REM  CALLED BY:
REM  PASS:
REM  RETURN:
REM
REM  REVISION HISTORY
REM   Name	Date		Description
REM   ----	----		-----------
REM   martin	8/3/95		Initial version
REM
REM ********************************************

	dim selected as integer

	selected = editItemList.selectedItem 
	if selected < editItemList.numItems  then
	   dim curText	as string
	   dim downText as string

	   curText  = editItemList.captions[selected]
	   downText = editItemList.captions[selected+1]

	   editItemList.captions[selected+1] = curText
	   editItemList.captions[selected] = downText

	   editItemList.selectedItem = selected + 1
	end if

end sub

sub editItemEntry_entered(self as entry)
REM ********************************************
REM		editItemEntry_entered
REM ********************************************
REM
REM  SYNOPSIS:	
REM	
REM  CALLED BY:
REM  PASS:
REM  RETURN:
REM
REM  REVISION HISTORY
REM   Name	Date		Description
REM   ----	----		-----------
REM   martin	8/3/95		Initial version
REM
REM ********************************************

	dim selected as integer

	selected = editItemList.selectedItem 
	if selected = -1  then
	   REM
	   REM If nothing selected, add to end
	   REM
	   editItemList.captions[editItemList.numItems] = editItemEntry.text
	else
	   editItemList.captions[selected] = editItemEntry.text
	end if
	editItemEntry.text = ""

end sub

sub sp_apply()
  
 dim current as component
 DIM visState as integer
  
  current = listSpecPropBox.current
REM
REM make not visible so that certain properties will take effect
REM
  visState = current.visible
  IF (visState) then
    current.visible = 0
  END if
  
  current.Clear()
  current.behavior	= behavior.selectedItem
  editItemList.behavior = behavior.selectedItem
  
 dim i as integer
  for i = 0 to editItemList.numItems-1
    current.captions[i] = editItemList.captions[i]
  next
  
REM	current.numItems     = editItemList.numItems	read-only prop
  current.selectedItem = editItemList.selectedItem
REM	current.numVisibleItems = numVisNum.value
  
  current.look = look.selectedItem

  IF (visState) then
    current.visible = 1
  END if
end sub

sub editItemList_changed(self as list, index as integer)
  if self.selectedItem = -1 then
    deleteItem.enabled = 0
  else
    deleteItem.enabled = 1
  end if
end sub
