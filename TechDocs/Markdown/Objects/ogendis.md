# 4 GenDisplay / GenPrimary

Applications communicate with users through a "user interface." The system 
needs a way of grouping the user-interface components together. For this 
reason, most applications will have a GenPrimary object. This object serves 
as the top-level object in the user interface tree. 

**GenPrimaryClass** is a subclass of **GenDisplayClass**. The GenDisplay 
object, like the GenPrimary object, manages other pieces of the user interface 
(menus, triggers, text objects, etc.). Furthermore, the GenDisplay object is a 
great boon to applications that need to perform several tasks at once (as, for 
example, a word processor which can have several files open at once). An 
application can have several GenDisplay objects, all of them children of a 
GenDisplayGroup object. Collectively, displays and primaries are called 
windows. All windows have certain functionality in common; that 
functionality can vary according to the specific UI.

The Document Control objects can be set to create GenDisplay objects when 
files are opened and to attach them automatically to a GenDisplayGroup. 
This enormously simplifies managing multiple documents. See 
"GenDocument," Chapter 13, for information on the Document Control 
objects.

These objects are very simple to use. In particular, the GenPrimary is very 
easy to declare and use. Although all applications use the GenPrimary, many 
will not need the GenDisplay. However, because **GenPrimaryClass** is a 
subclass of **GenDisplayClass**, this chapter begins with an overview of 
**GenDisplayClass**, then continues with a full discussion of 
**GenPrimaryClass**, and concludes with advanced information about 
**GenDisplayClass**. Before reading this chapter, you should be familiar with 
the use and creation of generic user interface objects. 

## 4.1 A First Look at GenDisplay

Not all applications will need to use GenDisplay objects. However, almost all 
applications will have a GenPrimary object. Since **GenPrimaryClass** is a 
subclass of **GenDisplayClass**, programmers should be acquainted with 
**GenDisplayClass**. 


This section describes the data fields of **GenDisplayClass** and certain 
useful messages. It does not have all the information you will need to create 
these objects. If you will be using GenDisplay objects in your application, you 
will have to read section 4.3 below.

### 4.1.1 GenDisplay Object Structure

The GenDisplay object is a subclass of **GenClass** and therefore inherits all 
the data fields and attributes of that class. It has few data fields that are set 
by the application; these fields are listed in Code Display 4-1.

----------
**Code Display 4-1 Instance Data of GenDisplayClass**

	/* There are only two instance fields specifically defined for GenDisplayClass.
	 * Also, an instance field for GenClass, GI_attrs, has different defaults in
	 * GenDisplayClass. */

	/* GDI_attributes is a one-byte field for attributes flags. There is only one flag
	 * defined for this field, namely GDA_USER_DISMISSABLE, which is on by default.
	 */
	@instance GenDisplayAttrs	GDI_attributes = GDA_USER_DISMISSABLE;

	/* The GenDisplay object has a datum for a pointer to a document object. If a
	 * Document Control is used to create display objects, it will associate each
	 * display with a document object; each will have an optr to the other.
	 */
	@instance optr				GDI_document;

	/* The default setting of GI_attrs is different in GenDisplayClass than it is in 
	 * GenClass: */
	@default GI_attrs = (@default 
						 | GA_TARGETABLE
						 | GA_KBD_SEARCH_PATH);

	/* The following hints specify whether the display should be minimized or
	 * maximized when it is built, and its appearance when minimized. */
	@vardata void HINT_DISPLAY_MINIMIZED_ON_STARTUP;
	@vardata void HINT_DISPLAY_NOT_MINIMIZED_ON_STARTUP;
	@vardata void HINT_DISPLAY_MAXIMIZED_ON_STARTUP;
	@vardata void HINT_DISPLAY_NOT_MAXIMIZED_ON_STARTUP;
	@vardata void HINT_DISPLAY_USE_APPLICATION_MONIKER_WHEN_MINIMIZED;

	/* The following hints and attributes indicate whether the user should be able to
	 * minimize, maximize, or resize the window. */
	@vardata void ATTR_GEN_DISPLAY_NOT_MINIMIZABLE;
	@vardata void ATTR_GEN_DISPLAY_NOT_MAXIMIZABLE;
	@vardata void HINT_DISPLAY_NOT_RESIZABLE;

	/* ATTR_GEN_DISPLAY_NOT_RESTORABLE indicates that the user should not be able to
	 * de-maximize the display once it is maximized. */
	@vardata void ATTR_GEN_DISPLAY_NOT_RESTORABLE;

	/* ATTR_GEN_DISPLAY_TRAVELING_OBJECTS is the ChunkHandle of a list of "traveling
	 * objects;" these objects are made the children of whichever GenDisplay is on top
	 * in a given display region (see section 4.3.3.4 below.*/
	@vardata ChunkHandle ATTR_GEN_DISPLAY_TRAVELING_OBJECTS;

	/* The following hints and attributes specify whether the display's menu bar 
	 * appears and whether it appears as a "popped out" floating menu. */
	@vardata void HINT_DISPLAY_MENU_BAR_HIDDEN_ON_STARTUP;
	@vardata void TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN;
	@vardata void ATTR_GEN_DISPLAY_MENU_BAR_POPPED_OUT;
	@vardata void HINT_DISPLAY_USE_APPLICATION_MONIKER_WHEN_MENU_BAR_POPPED_OUT;

	/* The GenDisplay uses the following vardata fields to store its
	 * minimized/maximized state across a shutdown. You should not access these
	 * fields. If you want to find out if a GenDisplay is minimized or maximized, send
	 * it MSG_GEN_DISPLAY_GET_MINIMIZED or MSG_GEN_DISPLAY_GET_MAXIMIZED. */
	@vardata		void ATTR_GEN_DISPLAY_MINIMIZED_STATE;
	@vardata		void ATTR_GEN_DISPLAY_MAXIMIZED_STATE;

	/* HINT_DISPLAY_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD specifies the default 
	 * action for the GenDisplay. */
	@vardata void HINT_DISPLAY_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD;

----------
#### 4.1.1.1 The GDI_attributes Field

	MSG_GEN_DISPLAY_GET_ATTRS, MSG_GEN_DISPLAY_SET_ATTRS

The GenDisplay object has a one-byte record called *GDI_attributes* to store 
attribute flags. There is only one attribute flag, namely 
GDA_USER_DISMISSABLE. If this attribute is set, the user can dismiss a 
display through the UI (without choosing a command in the application). 
Details of this depend on the specific UI; for example, in OSF/Motif, the user 
could dismiss a display by double-clicking the "Control button."

----------
#### MSG_GEN_DISPLAY_GET_ATTRS

	GenDisplayAttrs 	MSG_GEN_DISPLAY_GET_ATTRS();

This message retrieves the *GDI_attributes* field from the destination object.

**Source:** Unrestricted.

**Destination:** Any GenDisplay or GenPrimary object.

**Return:** A GenDisplayAttrs record. The only flag defined is 
GDA_USER_DISMISSABLE.

**Interception:** This message is not normally intercepted.

----------
#### MSG_GEN_DISPLAY_SET_ATTRS

	void	MSG_GEN_DISPLAY_SET_ATTRS(
			GenDisplayAttrs		attrs);

This message changes the **GenDisplayAttrs** field of the destination object. 

**Source:** Unrestricted.

**Destination:** Any GenDisplay or GenPrimary object.

**Parameters:**  
*attrs* - Field of **GenDisplayAttrs** flags. There is only one 
flag defined, namely GDA_USER_DISMISSABLE.

**Interception:** This message is not normally intercepted.

#### 4.1.1.2 The GDI_document Field

Applications often use the Document Control objects to manage files. With 
this mechanism, every file is associated with a document object. Often, each 
file will have its own GenDisplay object as well. In this case, *GDI_document* 
will contain an optr to the GenDocument object associated with this 
GenDisplay. For more information on this, see section 4.3 below. The 
Document Control objects create and destroy the GenDisplays automatically, 
and set this field accordingly. The GenDisplay object uses this field only when 
the display is closed; see section 4.3.3.1 below. To retrieve the value of 
this field, send MSG_GEN_DISPLAY_GET_DOCUMENT to the display (see 
section 4.3.3.3 below).

### 4.1.2 Minimizing and Maximizing

	MSG_GEN_DISPLAY_SET_MINIMIZED, 
	MSG_GEN_DISPLAY_SET_NOT_MINIMIZED, 
	MSG_GEN_DISPLAY_GET_MINIMIZED, 
	MSG_GEN_DISPLAY_SET_MAXIMIZED, 
	MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED, 
	MSG_GEN_DISPLAY_GET_MAXIMIZED, 
	HINT_DISPLAY_MINIMIZED_ON_STARTUP, 
	HINT_DISPLAY_NOT_MINIMIZED_ON_STARTUP, 
	HINT_DISPLAY_MAXIMIZED_ON_STARTUP, 
	HINT_DISPLAY_NOT_MAXIMIZED_ON_STARTUP, 
	ATTR_GEN_DISPLAY_NOT_MINIMIZABLE, 
	HINT_DISPLAY_NOT_MAXIMIZABLE, 
	ATTR_GEN_DISPLAY_NOT_RESTORABLE,
	HINT_DISPLAY_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD

Windows (i.e. displays and "primary" windows) can be resized by the user. 
How resizing is done depends on the specific UI; for example, in OSF/Motif, a 
user resizes a window by dragging its edge. Most specific UIs also allow the 
user to "minimize" or "maximize" a window. When a window is maximized, it 
is expanded to fill all available space; that is, a primary window will fill the 
screen, while a GenDisplay will fill the display area. Windows can also be 
"minimized." A window's behavior when it is minimized depends on the 
specific UI. For example, in OSF/Motif, a minimized Primary is displayed as 
an icon at the bottom of the screen; a minimized Display is removed from the 
display area, but stays in the display control's display list.

Most of the mechanics of minimizing and maximizing windows is taken care 
of by the specific UI. For example, OSF/Motif provides minimize and 
maximize buttons on all Displays and Primaries which do not specifically 
disable the functionality. However, an application can send messages to 
Primary and Display objects to change their minimized/maximized state, or 
to find out what the current state is.

If you do not wish to have a window be minimizable, you can set the vardata 
flag ATTR_GEN_DISPLAY_NOT_MINIMIZABLE. Similarly, if you do not wish 
the window to be maximizable, you can set the flag 
ATTR_GEN_DISPLAY_NOT_MAXIMIZABLE. These instruct the specific UI not 
to provide the controls for minimizing and maximizing. 

You can find out whether a window is currently minimized by sending it 
MSG_GEN_DISPLAY_GET_MINIMIZED. Similarly, you can find out whether 
the window is maximized by sending MSG_GEN_DISPLAY_GET_MAXIMIZED.

If a GenDisplay or GenPrimary has the vardata 
HINT_DISPLAY_MINIMIZED_ON_STARTUP, the object will be created in its 
minimized state. Similarly, if you set 
HINT_DISPLAY_NOT_MINIMIZED_ON_STARTUP, the display will be created 
in its non-minimized form. If you set 
HINT_DISPLAY_MAXIMIZED_ON_STARTUP, the specific UI will create the 
object in its maximized state; correspondingly, if you set 
HINT_DISPLAY_NOT_MAXIMIZED_ON_STARTUP, the specific UI will create 
the display in a non-maximized state. As with all hints, the specific UI may 
ignore these directives. If you set conflicting hints (for example, both 
HINT_DISPLAY_MINIMIZED_ON_STARTUP and 
HINT_DISPLAY_MAXIMIZED_ON_STARTUP), the results are undefined.

Most displays which can be maximized can also be "restored"; that is, a 
control is provided which de-maximizes the object, restoring it to the size it 
was before it was maximized. If the object has the attribute 
ATTR_GEN_DISPLAY_NOT_RESTORABLE, this control will not be provided; 
once a display is maximized, the user will not be able to un-maximize it. This 
hint is generally set only for GenDisplay objects that are maximized on 
startup.

If you do not want a user to be able to resize a GenDisplay or GenPrimary, 
set the vardata HINT_DISPLAY_NOT_RESIZABLE. The specific UI will not 
provide the means for the user to resize the window. This hint will not 
prevent the user from minimizing or maximizing the display.

If you want the user to be able to navigate from GenDisplays using TAB 
navigation, add 
HINT_DISPLAY_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD to the 
object's instance data.

----------
#### MSG_GEN_DISPLAY_SET_MINIMIZED

	void	MSG_GEN_DISPLAY_SET_MINIMIZED();

This message instructs a display or primary object to minimize itself. The 
result depends on the specific UI. Primary windows are usually iconified; 
display windows might be iconified or temporarily removed. If the window is 
already minimized, the message has no effect.

**Source:** Unrestricted.

**Destination:** Any GenDisplay or GenPrimary object.

**Interception:** You should not change the behavior of this message. You may intercept 
this message to find out when a window is being minimized; however, 
you should make sure to pass this message on to the superclass.

----------
#### MSG_GEN_DISPLAY_SET_MAXIMIZED

	void	MSG_GEN_DISPLAY_SET_MAXIMIZED();

This message instructs a display or primary object to maximize itself. If the 
window is already maximized, the message has no effect.

**Source:** Unrestricted.

**Destination:** Any GenDisplay or GenPrimary object.

**Interception:** You should not change the behavior of this message. You may intercept 
this message to find out when a window is being maximized; however, 
you should make sure to pass this message on to the superclass.

----------
#### MSG_GEN_DISPLAY_SET_NOT_MINIMIZED

	void	MSG_GEN_DISPLAY_SET_NOT_MINIMIZED();

This message instructs a display or primary object to de-minimize itself. It 
will generally be restored to its position and configuration as of the time it 
was minimized. If the window is not minimized, the message has no effect.

**Source:** Unrestricted.

**Destination:** Any GenDisplay or GenPrimary object.

**Interception:** You should not change the behavior of this message. You may intercept 
this message to find out when a window is being de-minimized; 
however, you should make sure to pass this message on to the 
superclass.

----------
#### MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED

	void	MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED();

This message instructs a display or primary object to de-maximize itself. It 
will generally be restored to its position and configuration as of the time it 
was maximized. If the window is not maximized, the message has no effect.

**Source:** Unrestricted.

**Destination:** Any GenDisplay or GenPrimary object.

**Interception:** You should not change the behavior of this message. You may intercept 
this message to find out when a window is being de-maximized; 
however, you should make sure to pass this message on to the 
superclass.

----------
#### MSG_GEN_DISPLAY_GET_MINIMIZED

	Boolean	MSG_GEN_DISPLAY_GET_MINIMIZED();

This message indicates whether the recipient is minimized.

**Source:** Unrestricted.

**Destination:** Any GenDisplay or GenPrimary object.

**Return:** Returns *true* (i.e. non-zero) if recipient is minimized; otherwise, it 
returns *false* (i.e. zero).

**Interception:** You should not intercept this message.

----------
#### MSG_GEN_DISPLAY_GET_MAXIMIZED

	Boolean	MSG_GEN_DISPLAY_GET_MAXIMIZED();

This message indicates whether the recipient is maximized.

**Source:** Unrestricted.

**Destination:** Any GenDisplay or GenPrimary object.

**Return:** Returns *true* (i.e. non-zero) if recipient is maximized; otherwise, it 
returns *false* (i.e. zero).

**Interception:** You should not intercept this message.

## 4.2 Using the GenPrimary

	MSG_GEN_PRIMARY_GET_LONG_TERM_MONIKER, 
	MSG_GEN_PRIMARY_USE_LONG_TERM_MONIKER, 
	MSG_GEN_PRIMARY_REPLACE_LONG_TERM_MONIKER, 
	HINT_PRIMARY_FULL_SCREEN, HINT_PRIMARY_NO_FILE_MENU, 
	HINT_PRIMARY_NO_EXPRESS_MENU, 
	HINT_PRIMARY_OPEN_ICON_BOUNDS, HINT_PRIMARY_NO_HELP_BUTTON


Almost every application will have a single GenPrimary object. GEOS uses 
the GenPrimary to create and manage the primary window of an application. 
A few applications may have several GenPrimary objects; a very few will 
have no GenPrimary at all. (Applications with no GenPrimary generally do 
not have any user interface; they often are intended to work with other 
applications, communicating via streams.)

The structure of the GenPrimary object is almost the same as that of 
GenDisplay. The instance data definitions for **GenPrimaryClass** are shown 
in Code Display 4-2 below.

----------

**Code Display 4-2 Instance data for GenPrimaryClass**

	/* There is only one instance field specifically defined for GenPrimaryClass. */

	/* A GenPrimary object can have a long moniker, which is displayed at the top of
	 * the window. The moniker is stored in a chunk in the object block containing the
	 * GenPrimary; the attribute GPI_longTermMoniker contains the handle of this
	 * chunk. The long-term moniker is described below.*/
	@instance ChunkHandle				GPI_longTermMoniker;

	/* GenPrimaryClass also modifies the default GI_attrs settings. */
	@default GI_attrs = @default | GA_TARGETABLE;

	/* HINT_PRIMARY_FULL_SCREEN indicates that the primary object should be sized to
	 * fill a large portion of the screen. If this hint is not present, the Primary
	 * will be just large enough to accommodate its children.*/
	@vardata void 			HINT_PRIMARY_FULL_SCREEN;

	/* Ordinarily, every Primary window is created with a File menu. You can suppress
	 * this by including HINT_PRIMARY_NO_FILE_MENU. */
	@vardata void 			HINT_PRIMARY_NO_FILE_MENU;

	/* Also by default, any launched Primary window gets added to the Express Menu. If 
	 * you wish to suppress this behavior, add HINT_PRIMARY_NO_EXPRESS_MENU. */
	@vardata void			HINT_PRIMARY_NO_EXPRESS_MENU;

	/* If a primary object is minimizable, the location of the minimized primary is
	 * stored in the vardata field HHINT_PRIMARY_OPEN_ICON_BOUNDS.
	 */
	@vardata Rectangle			HINT_PRIMARY_OPEN_ICON_BOUNDS

	/* By default, all primary windows have a "help" button; when the user clicks on
	 * it, the window's help text is brought up. If you don't want the primary to
	 * provide help text, you can use the hint HINT_PRIMARY_NO_HELP_BUTTON.
	 */
	@vardata void 		HINT_PRIMARY_NO_HELP_BUTTON;

----------
When a Primary window is created, it is usually sized to contain all of its 
components. However, you can suggest that it be sized to fill almost all the 
screen by setting the hint HINT_PRIMARY_FULL_SCREEN. This hint says 
that the Primary should be sized to fill a large portion of the screen, though 
not all of it. (For example, OSF/Motif sets the Primary to fill the whole screen 
except for a narrow space for icons at the bottom.) If this hint is not present, 
the Primary will be just large enough to accommodate its children.

A GenPrimary normally creates a File menu within its menu bar. To 
suppress creation of this file menu, add HINT_PRIMARY_NO_FILE_MENU. 
GenPrimarys, by default, are also added to the list of active applications 
within the system's express menu. Add 
HINT_PRIMARY_NO_EXPRESS_MENU if you wish to avoid adding the 
launched GenPrimary to the express menu.

When a Primary is minimized, it is displayed as an icon with a caption 
beneath it. The icon and caption will be taken from the Primary's moniker 
list (*GI_visMoniker*). If the Primary lacks either a text moniker or a graphic 
moniker, the missing moniker will be read from the Application object's 
*GI_visMoniker* field. Most applications will not set *GI_visMoniker* in the 
Primary object, since it would usually mean duplicating the monikers 
already in the Application object. However, some applications will set this 
(e.g. because they have several Primary objects and want each one to have a 
different icon when minimized).

When the Primary is expanded from a minimized state, its minimized 
location is stored in the hint HINT_PRIMARY_OPEN_ICON_BOUNDS. The 
next time the Primary is minimized, it will be returned to that location.

*GPI_longTermMoniker* contains a secondary moniker for the Primary object. 
This moniker is displayed along with the Primary moniker, in a way which 
depends on the specific UI. (In OSF/Motif, the Primary's text monikers are 
shown in its title bar: first the text moniker from *GI_visMoniker*, then a dash, 
then the moniker from *GPI_longTermMoniker*.) If the GenPrimary has a 
GenDisplayGroup as a child, the GenDisplayGroup will automatically set 
this field to contain the moniker of the top-most GenDisplay. The application 
can override this by sending the Primary 
MSG_GEN_PRIMARY_USE_LONG_TERM_MONIKER, described below.

Most Primary objects will have help text; under most specific UIs, the 
Primary will have a "help" button to bring up this text. If you don't want to 
provide help text, you should set the hint 
HINT_PRIMARY_NO_HELP_BUTTON.

----------
#### MSG_GEN_PRIMARY_GET_LONG_TERM_MONIKER

	ChunkHandle 	MSG_GEN_PRIMARY_GET_LONG_TERM_MONIKER();

Use this message to find out the moniker of a GenPrimary object. The 
message returns the chunk handle of the moniker; the moniker is in the same 
block as the GenPrimary object.

**Source:** Unrestricted.

**Destination:** GenPrimary.

**Return:** Returns the chunk handle of the primary's long-term moniker. The 
chunk is in the same object block as the GenPrimary.

**Interception:** This message is not ordinarily intercepted.

----------
#### MSG_GEN_PRIMARY_USE_LONG_TERM_MONIKER

	void 	MSG_GEN_PRIMARY_USE_LONG_TERM_MONIKER(
			ChunkHandle		moniker);	/* must be in same object block as
										 * primary */

This message instructs a primary window to change its long-term moniker. 
The new long-term moniker must already be in a chunk in the same object 
block as the Primary. The chunk containing the obsolete long-term moniker 
will not be freed; you must do this manually.

**Source:** Unrestricted.

**Destination:** GenPrimary.

**Parameters:**  
*moniker* - ChunkHandle of chunk in same object block as the 
GenPrimary. The chunk should contain the new 
long-term moniker.

**Interception:** This message is not ordinarily intercepted.

----------
#### MSG_GEN_PRIMARY_REPLACE_LONG_TERM_MONIKER

	void	MSG_GEN_PRIMARY_REPLACE_LONG_TERM_MONIKER(@stack
			VisUpdateMode 			updateMode,
			word 					height, 
			word 					width, 
			word 					length,
			VisMonikerDataType 		dataType,
			VisMonikerSourceType 	sourceType,
			dword 					source);

This message is used to replace a primary's long term moniker with a new 
one. This message's arguments are precisely like those to the message 
MSG_GEN_REPLACE_VIS_MONIKER. Note that a long term moniker is 
ordinarily a simple text string. For more information, see "Managing Visual 
Monikers", section 2.4.2 of chapter 2.

**Source:** Unrestricted.

**Destination:** GenPrimary.

**Parameters:** The parameters are the same as those for 
MSG_GEN_REPLACE_VIS_MONIKER.

**Return:** Returns the chunk handle of the new long-term moniker. The moniker 
will be allocated in the Primary's object block.

**Interception:** This message is not ordinarily intercepted.

## 4.3 Using Multiple Displays

Many applications will need to have several similar user interface areas. For 
example, a word processor might have several documents open at once; each 
of these would need its own text area. GEOS provides a facility for this. 

An application can have several GenDisplay objects, each of which must be a 
child of a GenDisplayGroup object. The user can then switch back and forth 
between the displays using the GenDisplayControl (which is usually a child 
of a "Window" menu). The switching is transparent to the application.

If the application uses one display for each document, it should use the 
Document Control objects to create the displays. The Document Control can 
automatically duplicate a resource containing a generic object tree headed by 
a GenDisplay and make that GenDisplay a child of the GenDisplayGroup 
each time a document is opened or created. For details, see "GenDocument," 
Chapter 13.

### 4.3.1 GenDisplayGroup


If an application uses GenDisplay objects, it must have a GenDisplayGroup 
object. This object makes sure there is space in the GenPrimary for the 
displays.

The GenDisplayGroup must be either a child of the GenPrimary (in which 
case the specific UI will decide where to put the display area) or a child of a 
**GenInteraction** which is a child of the GenPrimary (if the application 
wants the display area in a specific part of the GenPrimary). The 
GenDisplayGroup should be run by the UI thread.

**GenDisplayGroupClass** has no instance data which may be set or 
examined by the application. However, **GenDisplayGroupClass** is a 
subclass of **GenClass**, and inherits all of its instance data. When you declare 
a GenDisplayGroup, you may specify its **GenClass** instance data normally; 
you may also include any of the hints described in the following sections.

#### 4.3.1.1 The GenDisplayGroup Instance Data

	HINT_DISPLAY_GROUP_SEPARATE_MENUS, 
	HINT_DISPLAY_GROUP_ARRANGE_TILED, 
	HINT_DISPLAY_GROUP_FULL_SIZED_ON_STARTUP, 
	HINT_DISPLAY_GROUP_OVERLAPPING_ON_STARTUP, 
	HINT_DISPLAY_GROUP_FULL_SIZED_IF_TRANSPARENT_DOC_CTRL_MODE,
	HINT_DISPLAY_GROUP_TILE_HORIZONTALLY, 
	HINT_DISPLAY_GROUP_TILE_VERTICALLY, 
	HINT_DISPLAY_GROUP_SIZE_INDEPENDENTLY_OF_DISPLAYS

GenDisplayGroupClass is a subclass of GenClass. Other than vardata, this 
class adds no other instance data. There are several hints defined for 
**GenDisplayGroupClass**. Most of these hints specify how displays should 
be arranged on startup.

----------

**Code Display 4-3 GenDisplayGroup Instance Data**

	/* GenDisplayGroupClass adds no instance fields. It does modify the default 
	 * GI_attrs settings, however. */
	@default GI_attrs = @default | GA_TARGETABLE;

	/* This hint allows each GenDisplay to contain its own menu bar. */
	@vardata void		HINT_DISPLAY_GROUP_SEPARATE_MENUS;

	/* These hints specify how a GenDisplayGroup will arrange its GenDisplays. */
	@vardata void		HINT_DISPLAY_GROUP_ARRANGE_TILED;
	@vardata void		HINT_DISPLAY_GROUP_FULL_SIZED_ON_STARTUP;
	@vardata void		HINT_DISPLAY_GROUP_OVERLAPPING_ON_STARTUP;
	@vardata void		HINT_DISPLAY_GROUP_FULL_SIZED_IF_TRANSPARENT_DOC_CTRL_MODE;
	@vardata void		HINT_DISPLAY_GROUP_TILE_HORIZONTALLY;
	@vardata void		HINT_DISPLAY_GROUP_TILE_VERTICALLY;
	@vardata void		HINT_DISPLAY_GROUP_SIZE_INDEPENDENTLY_OF_DISPLAYS;

	/* These attributes affect the availability of overlapping and 
	 * full-sized states. */
	@vardata void		ATTR_GEN_DISPLAY_GROUP_NO_FULL_SIZED;
	@vardata void		ATTR_GEN_DISPLAY_GROUP_NO_OVERLAPPING;
	@vardata void		ATTR_GEN_DISPLAY_OVERLAPPING_STATE;

----------
In some specific UIs (such as OSF/Motif), menus which are children of a 
GenDisplay object may appear in two ways: they may be drawn on the 
Primary's menu bar (the default in OSF/Motif), or they may appear in a menu 
bar on the display itself. HINT_DISPLAY_GROUP_SEPARATE_MENUS 
indicates that each display should be given its own menu bar (if the specific 
UI permits this).

There are several hints which specify how the displays should be configured 
when the GenDisplayGroup is built.

HINT_DISPLAY_GROUP_FULL_SIZED_ON_STARTUP indicates that the 
GenDisplayGroup should be in full-size mode on startup; that is, all of its 
children should be maximized.

HINT_DISPLAY_GROUP_OVERLAPPING_ON_STARTUP indicates that the 
GenDisplayGroup should be in overlapping mode on startup; that is, its 
children should be non-maximized.

HINT_DISPLAY_GROUP_FULL_SIZED_IF_TRANSPARENT_DOC_CTRL_MODE 
forces a GenDisplayGroup to start full-sized if the application is in 
"transparent document control" mode, which is set by the user level of the 
application. This hint overrides 
HINT_DISPLAY_GROUP_OVERLAPPING_ON_STARTUP, if present.

HINT_DISPLAY_GROUP_ARRANGE_TILED indicates that the 
GenDisplayGroup should be in overlapping mode on startup, and further 
that the displays should be tiled; that is, they should be non-maximized and 
arranged in a non-overlapping way to fill the display area.

You can specify a preference for how the displays should be tiled by setting 
HINT_DISPLAY_GROUP_TILE_HORIZONTALLY or 
HINT_DISPLAY_GROUP_TILE_VERTICALLY. 
HINT_DISPLAY_GROUP_TILE_HORIZONTALLY indicates that you want tiled 
displays to be arranged horizontally, with each display tall enough to fill the 
display area. Similarly, HINT_DISPLAY_GROUP_TILE_VERTICALLY indicates 
that you want tiled displays to be arranged vertically, with each display wide 
enough to fill the display area. If both hints are set, the result varies 
depending on the specific UI.

HINT_DISPLAY_GROUP_SIZE_INDEPENDENTLY_OF_DISPLAYS sizes a 
GenDisplayGroup by what its parent wants rather than what any of its 
children GenDisplays want. This may improve geometry performance in a 
complex GenPrimary/GenDisplay combination.

#### 4.3.1.2 Arranging Displays in the Display Group

	MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING, 
	MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED, 
	MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED, 
	MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS, 
	ATTR_GEN_DISPLAY_GROUP_NO_FULL_SIZED, 
	ATTR_GEN_DISPLAY_GROUP_NO_OVERLAPPING, 
	ATTR_GEN_DISPLAY_GROUP_OVERLAPPING_STATE

The GenDisplayGroup can be in "full-sized" or "overlapping" mode. If the 
GenDisplayGroup is in "full-size" mode, all of its children are maximized 
(except any displays which are set "non-maximizable"). If it is not in 
full-sized mode, it is said to be in "overlapping" mode; that is, none of its 
children are maximized. When a user maximizes any display which belongs 
to a GenDisplayGroup, the GenDisplayGroup automatically goes into 
"full-size" mode and maximizes all of its children.

If you include ATTR_GEN_DISPLAY_GROUP_NO_FULL_SIZED, the 
GenDisplayControl will not be able to go into full-size mode; it will always be 
in overlapping mode. Similarly, if set 
ATTR_GEN_DISPLAY_GROUP_NO_OVERLAPPING, the GenDisplayControl 
will not be able to go into overlapping mode; it will always be in full-sized 
mode, and all displays will always be maximized. Naturally, you may not 
include both of these attributes at once; if you do, results are undefined.

Messages are provided which switch the GenDisplayGroup into one or 
another of these modes. You might not need to use any of these messages. If 
you use a GenDisplayControl object, the user will be able to switch from 
overlapping to full-size and also to tile the displays by using that object. 
However, you can also send the following messages directly.

You can set a GenDisplayGroup to full-sized mode by sending it the message 
MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED. This message causes the 
GenDisplayGroup to maximize every one of its children. Children which 
cannot be maximized will be unaffected. The window layering and 
focus/target settings are not changed.

You can set a GenDisplayGroup to overlapping mode by sending it the 
message MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING. This message 
causes a GenDisplayGroup object to de-maximize all of its children. Children 
which are not restorable will be unaffected. The window layering and 
focus/target settings are not changed.

You can find out whether a GenDisplayGroup object is in full-sized mode by 
sending it MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED. If the 
GenDisplayGroup is in full-sized mode, this message will return true.

You can also put a GenDisplayGroup into "tiled" mode. This is a special case 
of overlapping mode. When a GenDisplayGroup is put in tiled mode, it first 
puts itself in overlapping mode. It then attempts to arrange and resize its 
display children so they fill the display area without overlapping. To put a 
GenDisplayGroup into tiled mode, send it the message 
MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS.

The GenDisplayGroup keeps track of its overlapping state across shutdowns. 
It does this by setting ATTR_GEN_DISPLAY_GROUP_OVERLAPPING_STATE. 
Applications may not set or change this attribute directly.

----------
#### MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED

	void	MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED();

This message instructs a GenDisplayGroup to put itself in "full-sized" mode; 
that is, all of its maximizable children will be maximized. This message is 
ignored if the GenDisplayGroup has the vardata attribute 
ATTR_GEN_DISPLAY_GROUP_NO_FULL_SIZED.

**Source:** Unrestricted.

**Destination:** GenDisplayGroup.

**Interception:** Not generally intercepted.

----------
#### MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING

	void	MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING();

This message instructs a GenDisplayGroup to put itself in "overlapping" 
mode. This message is ignored if the GenDisplayGroup has the vardata 
attribute ATTR_GEN_DISPLAY_GROUP_NO_OVERLAPPING.

**Source:** Unrestricted.

**Destination:** GenDisplayGroup.

**Interception:** Not generally intercepted.

----------
#### MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED

	Boolean	MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED();

This message finds out whether a GenDisplayGroup is in "full-sized" mode.

**Source:** Unrestricted.

**Destination:** GenDisplayGroup.

**Return:** Returns *true* (i.e. non-zero) if the GenDisplayGroup is in full-sized 
mode; otherwise, it returns *false* (i.e. zero).

**Interception:** Not generally intercepted.
#### MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS

	void	MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS;

This message instructs a GenDisplayGroup to put itself in "tiled" mode. That 
is, it should first put itself in "overlapping" mode; it should then arrange and 
resize the displays so they fill the display area without overlapping. The 
message is ignored if the GenDisplayGroup has the vardata attribute 
ATTR_GEN_DISPLAY_GROUP_NO_OVERLAPPING.

**Source:** Unrestricted.

**Destination:** GenDisplayGroup.

**Interception:** Not generally intercepted.

#### 4.3.1.3 Selecting a Display

	MSG_GEN_DISPLAY_GROUP_SELECT_DISPLAY

Ordinarily, the user switches from one display to another in one of two ways. 
The user may use the specific UI's way of switching displays (e.g. clicking on 
the display); or he may use the GenDisplayControl (described below) to 
switch displays. The application can also force the Display Group to bring a 
certain display to the top by sending it 
MSG_GEN_DISPLAY_GROUP_SELECT_DISPLAY. However, this is not usually 
done; applications should generally let the user switch displays with the 
GenDisplayControl.

----------
#### MSG_GEN_DISPLAY_GROUP_SELECT_DISPLAY

	void	MSG_GEN_DISPLAY_GROUP_SELECT_DISPLAY(
			word	displayNum);

This message instructs a display group to select a certain display, bringing it 
to the top and making it the focus. Applications should not ordinarily need to 
send this.

**Source:** Usually GenDisplayControl or its associated objects; however, any 
object can send this.

**Destination:** GenDisplayGroup.

**Parameters:**  
*displayNum* - The display to select. This is an integer specifying 
the position of the desired display among the 
GenDisplayGroup's children; that is, its first child 
is number zero, its next child is number one, and so 
on.

**Interception:** This message is not ordinarily intercepted.

**Tips:** You can find a display's position number by sending 
MSG_GEN_FIND_CHILD to the GenDisplayGroup, passing the optr of 
the desired display. See section 2.5.1 of chapter 2.

### 4.3.2 GenDisplayControl


The GenDisplayGroup object does half the job of managing display objects: it 
creates a space for the displays and manages them as its children. However, 
the display group does very little interaction with the user. Instead, the user 
works mainly with the GenDisplayControl object.

The GenDisplayControl is usually a child of a "Window" GenInteraction, 
which is itself a child of the primary. **GenDisplayControlClass** is a 
subclass of **GenControlClass**, and it has all the functionality of that class. 
For more information, see "Generic UI Controllers," Chapter 12.

**GenDisplayControlClass** is based very closely on **GenControlClass**. The 
differences between it and **GenControlClass** are shown below in Code 
Display 4-4.

----------

**Code Display 4-4 Instance Data of GenDisplayControlClass**

	/* GDCII_attrs is a byte-length flag field. There is currently only one flag,
	 * namely GDCA_MAXIMIZED_NAME_ON_PRIMARY; this specifies that if the active
	 * display is maximized, its name should be shown as the primary's long-term 
	 * moniker. */
	@instance 		GenDisplayControlAttributes		GDCII_attrs =
						(GDCA_MAXIMIZED_NAME_ON_PRIMARY);

	@default		GI_states = @default | GS_ENABLED;
	@default 		GCI_output = {TO_APP_TARGET};

	typedef WordFlags GDCFeatures;
	#define GDCF_OVERLAPPING_MAXIMIZED		0x0004
	#define GDCF_TILE						0x0002
	#define GDCF_DISPLAY_LIST				0x0001

	typedef WordFlags GDCToolboxFeatures;
	#define GDCTF_OVERLAPPING_MAXIMIZED		0x0004
	#define GDCTF_TILE						0x0002
	#define GDCTF_DISPLAY_LIST				0x0001

	#define GDC_DEFAULT_FEATURES 	(GDCF_OVERLAPPING_MAXIMIZED | GDCF_TILE 
									| GDCF_DISPLAY_LIST)

	#define GDC_DEFAULT_TOOLBOX_FEATURES (GDCF_DISPLAY_LIST)

	/* A GenDisplayControl also features a single hint which affects the display of 
	 * the features list. */
		@vardata void HINT_DISPLAY_CONTROL_NO_FEATURES_IF_TRANSPARENT_DOC_CTRL_MODE;

----------



The *GDCII_attrs* field contains a set of **GenDisplayControlAttributes**. 
There is currently only one flag defined among these attributes:

GDCA_MAXIMIZED_NAME_ON_PRIMARY  
If this attribute is set and the active display is maximized, the 
name of the selected display will be shown in the long term 
moniker of the GenPrimary.

HINT_DISPLAY_CONTROL_NO_FEATURES_IF_TRANSPARENT_DOC_CTRL_M
ODE suppresses display of the features list if the application is running in 
"transparent document control" mode, as selected by the user level of the 
application.

### 4.3.3Using GenDisplayClass Objects

All GenDisplay objects must be children of a GenDisplayGroup object. 
GenDisplay objects can be created in several ways: an application can declare 
them in its code; it can instantiate them at run-time and make them children 
of the GenDisplayGroup; or, if the application uses the Document Control 
objects, it can have the Document Control create a new display automatically 
whenever a document is opened. (For details about using a Document 
Control to create GenDisplay objects, see "GenDocument," Chapter 13.)

#### 4.3.3.1 Closing GenDisplays

	MSG_GEN_DISPLAY_CLOSE

Most specific UIs provide a way for the user to close windows. For example, 
OSF/Motif lets a user close a window by double-clicking the control button. 
When the user uses the specific UI's close mechanism, the Display or Primary 
is sent MSG_GEN_DISPLAY_CLOSE. 

**GenDisplayClass** does only one thing when it receives 
MSG_GEN_DISPLAY_CLOSE: it sends MSG_GEN_DOCUMENT_CLOSE to the 
document specified by *GDI_document*. The **GenDisplayClass** handler for 
MSG_GEN_DISPLAY_CLOSE does not, in fact, destroy the display. If the 
display is linked to a GenDocument, the GenDocument will respond to 
MSG_GEN_DOCUMENT_CLOSE by closing the application and removing the 
GenDisplay. Otherwise, you will have to remove the GenDisplay yourself by 
writing a handler for MSG_GEN_DISPLAY_CLOSE.

The **GenPrimaryClass** handler for MSG_GEN_DISPLAY_CLOSE closes the 
application. If you want to add to or replace this behavior, you may have your 
Primary subclass this message.

----------
#### MSG_GEN_DISPLAY_CLOSE

	void	MSG_GEN_DISPLAY_CLOSE();

This message is sent to a Display to close it. The system sends it when the 
user uses the specific UI's way of closing a window. The GenDisplayClass 
handler does nothing but send a MSG_GEN_DOCUMENT_CLOSE to the 
Document object specified in *GDI_document*. The GenPrimaryClass 
handler closes the application.

**Source:** Unrestricted.

**Destination:** GenDisplay.

**Interception:** If the Display is not associated with a GenDocument, you will need to 
subclass this message for it to have any effect at all. If the display is 
associated with a GenDocument object, you should probably subclass 
your Document object's MSG_GEN_DOCUMENT_CLOSE instead. 
Primary objects may subclass this message if they want to alter or 
replace the default behavior (of closing the application).

#### 4.3.3.2 Menu Bar PopOuts

	ATTR_GEN_DISPLAY_MENU_BAR_POPPED_OUT

Some objects contain the ability to "pop out" of their sub-group locations and 
become floating dialog boxes.The menu bar of a GenDisplay is one such 
GenInteraction. If the menu bar of a GenDisplay is currently in the 
"popped-out" state, it will contain the vardata entry 
ATTR_GEN_DISPLAY_MENU_BAR_POPPED_OUT.

#### 4.3.3.3 Messages sent to GenDisplays

	MSG_GEN_DISPLAY_UPDATE_FROM_DOCUMENT, 
	MSG_GEN_DISPLAY_GET_DOCUMENT

Many of the messages which can be sent to GenDisplay objects have already 
been discussed above in section 4.1. However, there are a few messages which 
are ordinarily sent to Displays but not to Primaries. These messages are 
discussed here.

GenDisplay objects often work in close conjunction with the Document 
Control objects. It is common for every open document to have its own 
GenDisplay object as well as its own GenDocument. The two objects work in 
conjunction, sending messages back and forth to communicate. You can send 
or intercept these messages yourself to add functionality.

When the document object changes in certain significant ways, the Display 
has to be brought into accord with it. For example, if the name of the file 
changes, the GenDisplay's moniker will have to be changed to reflect this. 
Whenever a significant change takes place, the Document Control objects 
send a MSG_GEN_DISPLAY_UPDATE_FROM_DOCUMENT to the appropriate 
Display. The Display then requests all necessary information from the 
GenDocument and makes any necessary changes to its own instance data. 
You can force this updating by sending the message directly to the Display. 
You can also subclass this message if you want to add special updating 
behavior; however, you should be sure to pass this message to the superclass' 
handler.

You can find out which Document object is associated with a given Display by 
sending MSG_GEN_DISPLAY_GET_DOCUMENT to the Display. The message 
will return an optr to the corresponding Document object.

----------
#### MSG_GEN_DISPLAY_UPDATE_FROM_DOCUMENT

	void	MSG_GEN_DISPLAY_UPDATE_FROM_DOCUMENT();

This message instructs a GenDisplay to update its instance data from its 
associated GenDocument object (if any). This message is ordinarily sent by 
the Document Control objects.

**Source:** Unrestricted-ordinarily sent only by Document Control objects.

**Destination:** GenDisplay.

**Interception:** Normally not intercepted. If you subclass this message to add special 
updating behavior, be sure to end with an @**callsuper**.

----------
#### MSG_GEN_DISPLAY_GET_DOCUMENT

	optr	MSG_GEN_DISPLAY_GET_DOCUMENT();

This message returns the optr of the GenDocument associated with a given 
GenDisplay. This is equal to the value of the GenDisplay's *GDI_document* 
field.

**Source:** Unrestricted - ordinarily sent only by Document Control objects.

**Destination:** GenDisplay.

**Interception:** Normally not intercepted. 

#### 4.3.3. Traveling Objects

ATTR_GEN_DISPLAY_TRAVELLING_OBJECTS

If you use multiple GenDisplay objects, it is sometimes useful to set up a 
group of "traveling objects." Traveling objects are children of whichever 
display is active. When a different GenDisplay is brought to the top, all 
traveling objects will be set "not usable" and removed from the Generic tree. 
They will then be added as children of the new top display and set "usable." 
(Any children of the traveling objects will naturally move with them.) 
Traveling objects are most commonly Toolbox Interactions, but they can be 
any kind of generic object.

Traveling objects can only be used under certain circumstances. Every 
display must belong to its own object block, and all of these object blocks must 
be copies of the same original. This is because the traveling objects are added 
as children to a specified chunk in whichever object block contains the new 
top display. If you want to use traveling objects, you should declare a special 
"template" object block which contains a GenDisplay and its children. 
Whenever you need to create a GenDisplay, you should duplicate this object 
block. The traveling objects should be in another resource altogether. If you 
use the Document Control objects to create displays, the objects will use this 
technique, duplicating an object block for each new display; this will let you 
use traveling objects.

Every traveling object is indicated by a **TravelingObjectReference** 
structure (see Code Display 4-5). To attach traveling objects to the active 
display, create a chunk which contains a list of **TravelingObjectReference** 
structures; this chunk must be in the same object block as the active display. 
Then set the Display's ATTR_GEN_DISPLAY_TRAVELING_OBJECTS to the 
ChunkHandle of the list. The list will automatically be moved to the block of 
the active display whenever the traveling objects are moved.

----------

**Code Display 4-5 TravelingObjectReference**

	typedef struct {
		optr		TIR_travelingObject;	/* optr to traveling object whose
											 * reference this is */

		ChunkHandle		TIR_parent;			/* Chunk Handle of object in Display's
											 * block that will be the parent of this
											 * object */

		word		TIR_compChildFlags;		/* CompChildFlags to use when
											 * adding the traveling object */
	} TravelingObjectReference;

----------

The **TravelingObjectReference** structure has the following three fields:

*TIR_travelingObject*  
This field is an optr to the traveling object whose reference this 
is.

*TIR_parent*  
This field holds the chunk handle of an object in the display 
block. When the traveling object is added to a display block, it 
will be made a child of the object whose chunk handle this is.

*TIR_compChildFlags*  
This is the set of CompChildFlags which will be used when 
attaching this object to its new parent.

[GenApplication](ogenapp.md) <-- [Table of Contents](../objects.md) &nbsp;&nbsp; --> [GenTrigger](ogentrg.md)