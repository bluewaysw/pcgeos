# 24 VisComp
**VisCompClass** allows visible objects to have children. VisComp objects are 
the grouping elements within visible object trees.

If you need to have a visible object tree with several levels, or if you need to 
manage the geometry of visible objects, you will want to read this chapter. 
You should already be familiar with **VisClass** and with visible object trees. 
Both of these topics are discussed in "VisClass," Chapter 23. If you have not 
yet read that chapter, you should do so now.

## 24.1 VisCompClass Features
Composite visible objects provide several features and functions that normal 
visible objects can not. **VisCompClass** has several instance data fields above 
and beyond those found in **VisClass** (since **VisCompClass** is a subclass of 
**VisClass**, it inherits all its instance data and methods). Although it only 
handles a few messages not defined in **VisClass**, it provides much more 
functionality. Some of the main features of composite objects are listed below:

+ They can have children.  
Normal visible objects can exist only as leaves of a visible object tree. 
**VisCompClass** can have children, allowing the tree to be built to any 
number of levels. See section 23.5 of chapter 23 for full information on 
visible trees.

+ They can manage their children's geometry.  
A composite's children can be managed arbitrarily by the composite, or 
the composite can use the geometry manager to automatically position 
and size its children. Since a composite can have other composites as its 
children, this sizing can descend recursively throughout the visible tree, 
making the entire tree's geometry completely self-managed. See 
"Managing Geometry" below for information on geometry 
management.

+ They can create and manage their own windows.  
Composite objects can create their own graphics windows. Though this is 
not typically done (except in Specific UI libraries), it is possible. See 
"Managing Graphic Windows" below for more information on 
windows.

+ They support other **VisClass** functions.  
**VisCompClass** inherits all the instance data fields and messages of 
**VisClass**. As such, it can do everything normal **VisClass** objects can do. 
See "VisClass," Chapter 23 for full information on **VisClass**.

## 24.2 VisCompClass Instance Data
As stated above, **VisCompClass** inherits all the instance data fields from 
**VisClass**. All of those fields may be set and reset as they could be for an 
object of that class. Composite objects also have four other instance fields, 
shown in Code Display 24-1.

----------
**Code Display 24-1 VisCompClass Instance Fields**

	/* The VisCompClass instance data fields are shown below and are discussed in
	 * detail throughout the chapter. */

	/* VCI_comp
	 * VCI_comp contains the link to the composite object's first child. */
	@instance @composite		VCI_comp = VI_link;

	/* VCI_gadgetExcl
	 * VCI_gadgetExcl is an optr to the object that currently has the gadget
	 * exclusive. This field is rarely used directly by applications. */
	@instance optr				VCI_gadgetExcl;

	/* VCI_window
	 * VCI_window contains the window handle of the graphics window associated
	 * with this object. This field is rarely accessed directly by
	 * applications; it is set by the visual update mechanism. */
	@instance WindowHandle		VCI_window = NullHandle;

	/* VCI_geoAttrs
	 * VCI_geoAttrs is a record that defines some of the geometry management
	 * information for the composite. None of its values are set by default;
	 * the possible flags in this record are shown after the definition. */
	@instance VisCompGeoAttrs	VCI_geoAttrs = 0;
	/* Possible flags:
	 *	VCGA_ORIENT_CHILDREN_VERTICALLY			0x80
	 *	VCGA_INCLUDE_ENDS_IN_CHILD_SPACING		0x40
	 *	VCGA_ALLOW_CHILDREN_TO_WRAP				0x20
	 *	VCGA_ONE_PASS_OPTIMIZATION				0x10
	 *	VCGA_CUSTOM_MANAGE_CHILDREN				0x08
	 *	VCGA_HAS_MINIMUM_SIZE					0x04
	 *	VCGA_WRAP_AFTER_CHILD_COUNT				0x02
	 *	VCGA_ONLY_DRAWS_IN_MARGINS 				0x01
	 */

	/* VCI_geoDimensionAttrs
	 * VCI_geoDimensionAttrs is a record that contains additional information
	 * about the composite's geometry. This field contains two two-bit fields
	 * among its other flags. The default settings are shown in the definition;
	 * all possible flags and settings are shown following. */
	@instance VisCompGeoDimensionAttrs		VCI_geoDimensionAttrs = 0;
	/* Possible flags:
	 * Width Justification flags (mutually exclusive):
	 * VCGDA_WIDTH_JUSTIFICATION				0xc0
	 *	WJ_LEFT_JUSTIFY_CHILDREN				0x00
	 *	WJ_RIGHT_JUSTIFY_CHILDREN				0x40
	 *	WJ_CENTER_CHILDREN_HORIZONTALLY			0x80
	 *	WJ_FULL_JUSTIFY_CHILDREN_HORIZONTALLY	0xc0
	 *
	 * Height Justification flags (mutually exclusive):
	 * VCGDA_HEIGHT_JUSTIFICATION 				0x0c
	 *	HJ_TOP_JUSTIFY_CHILDREN					0x00
	 *	HJ_BOTTOM_JUSTIFY_CHILDREN,				0x04
	 *	HJ_CENTER_CHILDREN_VERTICALLY			0x08
	 *	HJ_FULL_JUSTIFY_CHILDREN_VERTICALLY		0x0c
	 *
	 * Other flags:
	 *	VCGDA_EXPAND_WIDTH_TO_FIT_PARENT		0x20
	 *	VCGDA_DIVIDE_WIDTH_EQUALLY				0x10
	 *	VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT		0x02
	 *	VCGDA_DIVIDE_HEIGHT_EQUALLY				0x01
	 */

	@default VI_typeFlags = VTF_IS_COMPOSITE;

----------
### 24.2.1 VCI_comp
Normal visible objects have just one instance field for tree construction: the 
*VI_link* field that points to the object's next sibling. For an object to have 
children, it must also have an instance field declared with the keyword 
**@composite**; this field, in **VisCompClass**, is *VCI_comp*. The composite field 
contains the optr of the object's first child; the link field contains a pointer to 
either the object's next sibling or its parent.

Applications should never access the *VI_link* or *VI_comp* fields directly; 
instead, these fields can be altered or queried with the following messages 
(all defined in **VisClass**):

MSG_VIS_ADD_CHILD  
This message adds a new child object to the composite.

MSG_VIS_REMOVE_CHILD  
This message removes a child from the composite.

MSG_VIS_MOVE_CHILD  
This message moves a child within the composite's list of 
children.

MSG_VIS_GET_PARENT  
This message returns a pointer to the object's parent.

Several other messages may also be used to change or query any visible 
object's *VI_link* and *VCI_comp* fields. These are discussed in "Working with 
Visible Object Trees" in "VisClass," Chapter 23.

### 24.2.2 VCI_gadgetExcl
Since the composite object must manage several other objects, it must also 
keep track of certain hierarchies used by the UI; the gadget exclusive is one 
of these. Within each branch of the visible object tree, only one visible object 
may have the gadget exclusive at a time. The gadget exclusive is kept track 
of via a path of pointers from the top of the tree down to the object having the 
exclusive.

The *VCI_gadgetExcl* field determines which child of the composite has the 
gadget exclusive. The child indicated in this field may or may not actually 
have the gadget exclusive for the entire visible tree; if the branch does not 
have the exclusive, neither will the child object. The gadget exclusive is 
similar to the other hierarchies of the input manager and acts the same way.

Applications never access the *VCI_gadgetExcl* field of a composite directly. 
Instead, this field may be set with the following three **VisClass** messages:

MSG_VIS_TAKE_GADGET_EXCL  
This message causes a visible object to set itself as having the 
gadget exclusive. The object's parent composite will set its 
*VCI_gadgetExcl* field appropriately.

MSG_VIS_RELEASE_GADGET_EXCL  
This message causes a visible object to relinquish its hold on 
the gadget exclusive. The object's parent composite will set its 
*VCI_gadgetExcl* field appropriately.

MSG_VIS_LOST_GADGET_EXCL  
This message is sent to the object having the gadget exclusive 
for that branch when it has lost the exclusive.

The above messages are detailed in "The Gadget Exclusive and Focus 
Hierarchy" in "VisClass," Chapter 23.

### 24.2.3 VCI_window
Every visible object has a window associated with it in which it will be drawn. 
Normal **VisClass** objects have no control over what window they're 
associated with; they must be in the same window as their composite 
parents. Composites may need to appear in different windows from their 
parents, however. Thus, **VisCompClass** has the *VCI_window* field, which 
contains the window handle of the window in which the composite's branch 
will be drawn.

Applications will not access this field directly. Typically, composites will be 
drawn in the window associated with their parent composites or contents. 
Sometimes, however, an application will want a visible branch to appear in a 
window different from that of the rest of the visible tree. The composite then 
must use other **VisClass** messages for creating and associating a window. 
This process is discussed in more detail in section 24.3.2 below.

### 24.2.4 VCI_geoAttrs
The most-used feature of composite objects is their ability to manage the 
sizing and placement of their children. This is known as managing the 
composite's geometry.

The geometry management behavior implemented by a particular composite 
object is determined by its *VCI_geoAttrs* and *VCI_geoDimensionAttrs* fields. 
Both of these fields may be set and altered by applications as their geometry 
needs change. The *VCI_geoAttrs* field, specifically, determines the type of 
geometry management employed by the composite.

The *VCI_geoAttrs* field may contain any or all of the following eight flags:

VCGA_ORIENT_CHILDREN_VERTICALLY  
This flag indicates that the composite's children should be 
arranged vertically rather than the default (horizontally).

VCGA_INCLUDE_ENDS_IN_CHILD_SPACING  
When the composite is using full justification (see 
*VCI_geoDimensionAttrs*), this flag indicates that there should 
be as much space before the first child and after the last child 
as there is between the children. If this flag is not set, there will 
be no space outside the first and last children.

VCGA_ALLOW_CHILDREN_TO_WRAP  
This flag will allow the children to wrap if their combined 
lengths won't allow them to fit within the composite's bounds. 
The composite will keep within the bounds of its parent, and its 
children will wrap as necessary. If this flag is not set, the 
composite will try to grow to be as large as necessary to fit all 
children.

VCGA_ONE_PASS_OPTIMIZATION  
This flag makes the geometry manager make only one pass at 
managing the children. It should only be set if the children can 
be guaranteed not to wrap or resize.

VCGA_CUSTOM_MANAGE_CHILDREN  
This flag indicates that the composite will manage its children 
without using the geometry manager. This allows the 
composite or its children to manually determine their positions 
and sizes. If this flag is set, the composite will keep its own 
bounds in its *VI_bounds* field, just as other Vis objects. This flag 
in a composite indicates custom management for the 
composite's entire branch, not just its children.

VCGA_HAS_MINIMUM_SIZE  
This flag indicates that the composite has a minimum size. The 
geometry manager will query the composite for this minimum 
and will ensure the object never gets smaller than that 
regardless of the size of its children. The minimum size must 
be returned by a custom MSG_VIS_COMP_GET_MINIMUM_SIZE 
handler.

VCGA_WRAP_AFTER_CHILD_COUNT  
Used in conjunction with VCGA_ALLOW_CHILDREN_TO_WRAP, 
this flag will cause child wrapping after a certain number of 
children. This can cause wrapping based on the number of 
children rather than on child size. The geometry manager will 
query the composite with MSG_VIS_COMP_GET_WRAP_COUNT.

VCGA_ONLY_DRAWS_IN_MARGINS  
This flag is used for optimized visual updates. It causes only 
the margins of the composite to be drawn when its image is 
marked invalid; all children of the composite must have their 
own images marked invalid if they are to be redrawn as well.

### 24.2.5 VCI_geoDimensionAttrs
The *VCI_geoDimensionAttrs* field determines how the composite manages its 
children in each dimension. It provides the geometry information not given 
in *VCI_geoAttrs* such as child justification and certain sizing behavior.

It contains three fields for each dimension (horizontal and vertical): The first 
field represents the justification of the children in that dimension. This field 
is two bits and can be one of four different enumerations. The second and 
third fields are sizing flags. These fields are listed below:

VCGDA_WIDTH_JUSTIFICATION  
This is a two-bit field that can be set to any one of four possible 
width justifications. If the name of this field is used in place of 
one of the four values, full justification will be used. The 
justification can be set as a normal flag. The four different 
values are:  
WJ_LEFT_JUSTIFY_CHILDREN - Left justify the children.  
WJ_RIGHT_JUSTIFY_CHILDREN - Right justify the children.  
WJ_CENTER_CHILDREN_HORIZONTALLY - Center the children horizontally.  
WJ_FULL_JUSTIFY_CHILDREN_HORIZONTALLY - Full justify the children. Horizontal full justification is only 
meaningful if the children are oriented horizontally (by 
clearing VCGA_ORIENT_CHILDREN_VERTICALLY in 
*VCI_geoAttrs*).

VCGDA_EXPAND_WIDTH_TO_FIT_PARENT  
If this flag is set, the composite will try to expand to fill the 
available width of its parent. By default, this flag is not set; the 
composite will be only as wide as its children require.

VCGDA_DIVIDE_WIDTH_EQUALLY  
If this flag is set, the composite will try to divide space equally 
between all its manageable, horizontally-oriented children. 
The composite will only suggest sizes - the children may or 
may not cooperate.

VCGDA_HEIGHT_JUSTIFICATION  
This is a two-bit field that can be set to any one of four height 
justifications. If the name of this field is used in place of one of 
the four values, full justification will be used. The justification 
can be set as a normal flag. The four different values are:  
HJ_TOP_JUSTIFY_CHILDREN - Justify the children to the composite's top bound.  
HJ_BOTTOM_JUSTIFY_CHILDREN - Justify the children to the composite's bottom bound.  
HJ_CENTER_CHILDREN_VERTICALLY - Center the children vertically.  
HJ_FULL_JUSTIFY_CHILDREN_VERTICALLY - Full justify the children. Vertical full justification is only 
meaningful if the children are oriented vertically (by setting 
VCGA_ORIENT_CHILDREN_VERTICALLY in *VCI_geoAttrs*).

VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT  
If this flag is set, the composite will try to expand to fill the 
available height of its parent. By default, this flag is not set; the 
composite will be only as tall as its children require.

VCGDA_DIVIDE_HEIGHT_EQUALLY  
If this flag is set, the composite will try to divide space equally 
between all its manageable, vertically-oriented children. The 
composite will only suggest sizes - the children may or may not 
cooperate.

### 24.2.6 Managing Instance Data
	MSG_VIS_COMP_GET_GEO_ATTRS, MSG_VIS_COMP_SET_GEO_ATTRS

To retrieve the flags currently set in both *VCI_geoAttrs* and 
*VCI_geoDimensionAttrs*, use MSG_VIS_COMP_GET_GEO_ATTRS. To set the 
attributes in either or both fields, use MSG_VIS_COMP_SET_GEO_ATTRS. 
both of these messages are detailed below.

----------
#### MSG_VIS_COMP_SET_GEO_ATTRS
	void	MSG_VIS_COMP_SET_GEO_ATTRS(
			word	attrsToSet,
			word	attrsToClear);

This message sets the flags in the composite object's *VCI_geoAttrs* and 
*VCI_geoDimensionAttrs* fields. The high byte of each parameter represents 
the dimension attributes, and the low byte represents the geometry 
attributes. This message does not invalidate or update the object's geometry.

**Source:** Unrestricted.

**Destination:** Any visible composite object.

**Parameters:**  
*attrsToSet* - A word of attributes that should be set for the 
object. The high byte is a record of 
**VisCompGeoDimensionAttrs**, and the low byte 
is a record of **VisCompGeoAttrs**. The attributes 
set in this parameter will be set for the object.

*attrsToClear* - A word of attributes to be cleared from the object's 
instance data. It has the same form as *attrsToSet*, 
above. Any attribute set in this parameter will be 
cleared in the instance fields.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_VIS_COMP_GET_GEO_ATTRS
	word	MSG_VIS_COMP_GET_GEO_ATTRS();
This message retrieves the flags set in the object's *VCI_geoAttrs* and 
*VCI_geoDimensionAttrs* fields. The high byte of the return value represents 
the dimension attributes, and the low byte represents the geometry 
attributes. This message does not invalidate or update the object's geometry.

**Source:** Unrestricted.

**Destination**: Any visible composite object.

**Parameters:** None.

**Return:** A word of flags. The high byte is a record of type 
**VisCompGeoDimensionAttrs**; the low byte is a record of type 
**VisCompGeoAttrs**. The high byte represents the attributes set in the 
object's *VCI_geoDimensionAttrs* field, and the low byte represents the 
attributes set in the object's *VCI_geoAttrs* field.

**Interception:** Unlikely.

## 24.3 Using VisCompClass
With the exception of the geometry flags mentioned above and the 
management of children, the use of **VisCompClass** is little different from 
the use of **VisClass**. In fact, most of the functionality designed for 
**VisCompClass** is built directly into **VisClass**; for example, nearly all 
geometry management and object tree management messages are defined in 
**VisClass**. Some reminders are listed below, however.

Not all composite objects will have something to draw. Some composites will 
be used simply as grouping objects to manage visible children. In these cases, 
you will not have to subclass **VisCompClass** but can instead use the class 
directly.

Many composite objects will have something to draw, though. For example, a 
composite may want to draw a box around its children or wash a different 
background color behind them. If this is the case, the object must be a 
subclass of **VisCompClass** and must handle MSG_VIS_DRAW.

One of the primary functions of **VisCompClass** is to pass input events and 
other messages down and up the tree to the proper objects. This is done 
automatically. You can, however, change this behavior by subclassing 
**VisCompClass** and intercepting the messages in which the object will be 
interested.

### 24.3.1 Managing Geometry
	MSG_VIS_COMP_GET_CHILD_SPACING, 
	MSG_VIS_COMP_GET_MINIMUM_SIZE, MSG_VIS_COMP_GET_MARGINS, 
	MSG_VIS_COMP_GET_WRAP_COUNT

A special feature of **VisCompClass**, and one that can be used in many ways, 
is its ability to automatically manage its children. By setting various flags in 
the composite's instance fields, you can have it control its children's sizing 
and position without additional code in your application.

Most of the flags you can set in *VCI_geoAttrs* and *VCI_geoDimensionAttrs* are 
explained fully in section 24.2 above. You should especially be aware 
that if you do not want to use the geometry management capabilities of 
**VisCompClass**, you should set VCGA_CUSTOM_MANAGE_CHILDREN in 
*VCI_geoAttrs*.

In addition to the messages provided in **VisClass** for geometry management, 
**VisCompClass** has four that return information about its current geometry. 
These are necessary because composites may be children of other composites, 
and therefore they may be managed. These messages are detailed below.

Most of the issues of geometry management are discussed in "Positioning 
Visible Objects" in "VisClass," Chapter 23.

----------
#### DWORD_CHILD_SPACING
	word	DWORD_CHILD_SPACING(val);
			SpacingAsDWord val;
This macro extracts the child spacing from the given **SpacingAsDWord** 
value. Use it with MSG_VIS_COMP_GET_CHILD_SPACING.

----------
#### DWORD_WRAP_SPACING
	word	DWORD_WRAP_SPACING(val);
			SpacingAsDWord val;
This macro extracts the wrap spacing from the given **SpacingAsDWord** 
value. Use it with MSG_VIS_COMP_GET_CHILD_SPACING.

----------
#### MAKE_SPACING_DWORD
	SpacingAsDWord	MAKE_SPACING_DWORD(child, wrap);
					word	child;
					word	wrap;

This macro creates a **SpacingAsDWord** dword from the two given 
arguments. The *child* argument is the child spacing, and the *wrap* argument 
is the wrap spacing. Use this macro in your handler (if any) for the message 
MSG_VIS_COMP_GET_CHILD_SPACING.

----------
#### MSG_VIS_COMP_GET_CHILD_SPACING
	SpacingAsDWord	MSG_VIS_COMP_GET_CHILD_SPACING();
This message returns the child spacing used by the composite. The high word 
of the return value is the spacing between lines of wrapped children; the low 
word is the horizontal spacing between children.

**Source:** Unrestricted.

**Destination:** Any visible composite object - typically sent by a composite to itself 
during geometry calculations.

**Parameters:** None.

**Return:** A dword containing the child spacing used by the composite. The dword 
contains two values: The child spacing - the amount of spacing placed 
between the composite's children - can be extracted from the return 
value with the macro DWORD_CHILD_SPACING. The wrap 
spacing - the amount of space placed between lines of wrapped 
children - can be extracted from the return value with the macro 
DWORD_WRAP_SPACING.

**Interception:** If a composite wants special child or wrap spacing other than the 
default, it should subclass this message and return the desired values. 
There is no need to call the superclass in the method.

**Tips:** In your handler, you can use the macro MAKE_SPACING_DWORD to 
form the return value from the two spacing values.

----------
#### MSG_VIS_COMP_GET_MINIMUM_SIZE
	SizeAsDWord 	SG_VIS_COMP_GET_MINIMUM_SIZE();
This message returns the minimum size of the composite. It is used by the 
geometry manager if the composite has VCGDA_HAS_MINIMUM_SIZE set. 
This message does not invalidate or update the object's geometry.

**Source:** Unrestricted.

**Destination:** Any visible composite object - typically sent by a composite to itself 
during geometry calculations.

**Parameters:** None.

**Return:** A dword containing the minimum size of the composite. The high word 
is the width, and the low word is the height. Use the macros 
DWORD_WIDTH and DWORD_HEIGHT to extract the individual values 
from the **SizeAsDWord** structure.

**Interception:** Any composite that wants a minimum size should subclass this 
message and return its desired size. There is no need to call the 
superclass in your handler.

**Tips:** In your handler, use the macro MAKE_SIZE_DWORD to create the 
**SizeAsDWord** return value from the width and height. This macro has 
the same format as MAKE_SPACING_DWORD.

----------
#### MSG_VIS_COMP_GET_MARGINS
	void	MSG_VIS_COMP_GET_MARGINS(
			Rectangle *retValue);
This message returns the margins the composite should use when 
recalculating its child spacing. If you want a special left, top, right, or bottom 
margin around the composite's children, intercept this message and return 
the margin(s) in the appropriate field(s) of the **Rectangle** structure.

**Source:** Unrestricted.

**Destination:** Any visible composite object - typically sent by a composite to itself 
during geometry calculations.

**Parameters:**  
*retValue* - A pointer to an empty **Rectangle** structure that 
will be filled with the composite's desired margins.

**Return:** The pointer to the filled Rectangle structure is preserved. The 
structure contains the four margins desired by the object outside of its 
bounds (e.g. if *retValue->R_top* is 100 upon return, the composite is 
requesting 100 points of extra "margin" spacing below its top bound 
before its children are placed).

**Interception:** Any composite that wants extra margin space added to its bounds 
when geometry is calculated should subclass this message and return 
its desired margins. There is no need to call the superclass in your 
handler.

----------
#### MSG_VIS_COMP_GET_WRAP_COUNT
	word	MSG_VIS_COMP_GET_WRAP_COUNT();
This message returns the number of children to be counted before wrapping 
if the composite has VCGA_WRAP_AFTER_CHILD_COUNT set.

**Source:** Unrestricted.

**Destination:** Any visible composite object - typically sent by a composite to itself 
during geometry calculations.

**Parameters:** None.

**Return:** The number of children that will be allowed before the composite wraps 
additional children to a new line.

**Interception:** Any composite that wants to wrap after a certain number of children 
should subclass this message and return the proper number of 
children. There is no need to call the superclass in your handler.

### 24.3.2 Managing Graphic Windows
It is very rare that a visible object will want to create its own window without 
using a generic object. This practice is highly discouraged as well because it 
will almost certainly violate some principles of most specific UI specifications. 
You can, however, set up a visible object to have its own window with the 
following steps:

1. Set up the VisComp object as a window group.  
Either instantiate a new VisComp object or set it up and load it in, 
off-screen. Then set the flags VTF_IS_WINDOW and VTF_IS_WIN_GROUP 
in the composite to make it a window and the top of the visible tree.

2. Add visible children to the window object.  
Using MSG_VIS_ADD_CHILD, add any visible object children to the 
window group as you need. If some of the children had possibly been 
removed from the visible tree earlier, you may have to mark them 
invalid.

3. Add your window to the field window.  
Determine the handle of the parent window you need, then set your 
window group object as a child of the parent.

4. Set the top object in your window group visible.  
Set VA_VISIBLE using MSG_VIS_SET_ATTR to mark the window group 
visible. The window will be opened, and it will receive a 
MSG_META_EXPOSED indicating that it and all its children should draw 
themselves.

[VisClass](ovis.md) <-- [Table of Contents](../objects.md) &nbsp;&nbsp; --> [VisContent](oviscnt.md)
