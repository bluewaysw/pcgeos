# 26 Generic System Classes
The Generic System Objects (GenSystem, GenScreen, and GenField) act as 
the root objects in the GEOS UI. Every application you create will be in a 
generic tree headed by these objects; however, you will rarely need to interact 
with these objects. 

The system objects are created by GEOS automatically; you will never need 
to declare instances of these objects within your code. Whenever an 
application object is instantiated, the system automatically attaches it to the 
generic and visible trees headed by these objects.

This chapter is meant to show you how these objects work within the GEOS 
system, what capabilities they automatically provide for you, and what 
information they contain that may aid in debugging efforts.

## 26.1 The System Objects
The GenSystem, GenScreen, and GenField objects work to create a platform 
for your application to run upon. You will never create these objects, and you 
might never need to communicate with them. Nevertheless, some 
applications will want to send messages to these objects. Also, while you are 
debugging code, you may find it useful to examine the instance data of these 
objects (though you may never change this data). For these reasons, the 
objects are fully documented here.

When GEOS starts up, it creates a single GenSystem object. This object is the 
top-most object of a generic tree which contains all GenApplication objects. It 
also maintains a separate tree which contains the GenScreen objects. 
Whenever GEOS is running, there will be exactly one GenSystem object. All 
generic objects which are displayed on any screen will belong to the generic 
tree headed by the GenSystem. (See Figure 26-1.)

![image info](Figures/Fig26-1.png)  
**Figure 26-1** *Hierarchy of System Objects*  
*The GenApplication maintains a set of links to the GenScreen objects; this is 
distinct from the generic tree headed by the GenSystem. Every GenScreen is 
the parent of a Visible tree; its children are all GenFields displayed on that 
screen.*


GEOS creates a GenScreen for every screen being used by the system. Each 
screen is the head of a Visible tree. (GEOS currently does not support multiple 
screens on a single system; however, future versions may support multiple 
screens.)

GEOS can provide several different environments, all of which may be 
running simultaneously on a single machine. For example, Geoworks 
Ensemble provides "Beginner," "Intermediate," and "Advanced" rooms. Each 
of these environments is represented by a GenField object. Each GenField 
object is a generic child of the GenSystem. It is also a Visible child of the 
appropriate GenScreen.

Every Application object is the child of a GenField. When an application is 
started, its GenApplication is automatically attached to the appropriate 
GenField, which is generally the GenField which was active when the 
application was started. An application may transfer itself to a different 
GenField; this will have the effect of moving the application to a different 
GEOS environment.

## 26.2 The GenSystem Object
Whenever GEOS is running, there is a single GenSystem object. This object 
is the head of the generic tree which contains all generic objects being 
displayed on any screen. (There may be other generic object trees which are 
not connected to the GenSystem; however, these objects will have no user 
interface. For example, every GenDocumentGroup is the head of a separate 
generic object tree.)

### 26.2.1 GenSystem Features
The GenSystem object has many responsibilities. Most of these are of no 
interest to the application. There are a few which applications will want to 
know about:

+ The GenSystem is the head of the generic tree which contains all generic 
objects which are usable on any screen. This makes it a useful reference 
point when searching through generic objects during debugging.

+ The GenSystem keeps track of the specific UI under which GEOS is 
running.

+ The GenSystem keeps track of the default GenScreen object. Whenever 
a new GenField is created, it is made a visible child of that GenScreen.

+ The GenSystem keeps track of the default GenField object. Whenever an 
application is started, the application object will be made a generic child 
of the default GenField.

The GenSystem is also used as a convenient point to alter such system-wide 
features as the mouse pointer image, system modality, and the layering of 
windows. 

### 26.2.2 GenSystem Instance Data
**GenSystemClass** instance data is internal and should never be set or 
altered by your application. It is provided here for reference, in case you need 
to examine the data during debugging. However, your code should not 
examine the data directly; instead, it should use the messages described in 
section 26.2.3 below to examine these fields.

GenSystem itself should also never be subclassed and instances of the class 
may not be statically defined, nor instantiated by applications or libraries 
other than the UI library itself.

----------
**Code Display 26-1 GenSystem Instance Data**

	/* Never access or alter these instance data fields.
	 * They are for internal use only. */

	@instance Handle			GSYI_specificUI;
	@instance Handle			GSYI_defaultUI;
	@instance optr			GSYI_defaultScreen;
	@instance optr			GSYI_defaultField;
	@instance @composite			GSYI_screenComp;

----------
*GSYI_specificUI* stores the handle of the specific UI in use by this system 
object. By default, this specific UI will also be the same specific UI used by all 
applications underneath this system object. 

*GSYI_defaultUI* stores the handle of the default specific UI to use for the next 
loaded application. This may be overridden by a GenField (though this is 
rare). For all intents and purposes, *GSYI_defaultUI* will be the same as 
*GSYI_specificUI*.

*GSYI_defaultScreen* stores an optr of a GenScreen. By default, new GenField 
objects will be made visible children of this GenScreen.

*GSYI_defaultField* stores the optr of a GenField. By default, new application 
objects will be made generic children of this GenField. This may be 
overridden with MSG_GEN_APP_ADD_TO_PARENT, though normal 
applications will not do this.

*GSYI_screenComp* stores the optr of the first GenScreen object child. The 
GenSystem is the head of two object trees. One is a visible tree containing all 
GenScreen objects; the other is a generic tree containing all application 
objects (and their generic children). The generic tree is specified by *GI_comp*, 
as usual.

### 26.2.3 GenSystem Basics
	MSG_GEN_SYSTEM_GET_DEFAULT_SCREEN, 
	MSG_GEN_SYSTEM_GET_DEFAULT_FIELD, 
	MSG_GEN_SYSTEM_SET_DEFAULT_FIELD

Some of the **GenSystemClass** instance data can be examined or changed 
with messages. Applications may find out the current default screen or 
default field with MSG_GEN_SYSTEM_GET_DEFAULT_SCREEN and 
MSG_GEN_SYSTEM_GET_DEFAULT_FIELD, respectively. Applications may 
also set the default field with MSG_GEN_SYSTEM_SET_DEFAULT_FIELD. 
(Only the system may set the default screen.)

You may retrieve the optr of the current default GenScreen object in use by 
the system with MSG_GEN_SYSTEM_GET_DEFAULT_SCREEN. You may not 
change the system's screen object, however.

You may also retrieve the optr of the current default GenField object that 
GenApplications will be attached to when loaded with 
MSG_GEN_SYSTEM_GET_DEFAULT_FIELD. 

----------
#### MSG_GEN_SYSTEM_GET_DEFAULT_SCREEN
	optr	MSG_GEN_SYSTEM_GET_DEFAULT_SCREEN();

This message returns the optr of the default GenScreen. By default, any 
GenFields will be made visible children of this GenScreen.

**Source:** Unrestricted.

**Destination:** The GenSystem object.

**Parameters:** None.

**Return:** The optr of the current default GenScreen object (*GSYI_defaultScreen*).

**Interception:** Not intercepted.

----------
#### MSG_GEN_SYSTEM_GET_DEFAULT_FIELD
	optr	MSG_GEN_SYSTEM_GET_DEFAULT_FIELD();

This message returns the optr of the default GenField. By default, new 
applications will be made generic children of this GenField.

**Source:** Unrestricted.

**Destination:** The GenSystem object.

**Parameters:** None.

**Return:** The optr of the current default GenField object (*GSYI_defaultField*).

**Interception:** Not intercepted.

----------
#### MSG_GEN_SYSTEM_SET_DEFAULT_FIELD
	void	MSG_GEN_SYSTEM_SET_DEFAULT_FIELD(
			optr	defaultField);

This message changes the default GenField for the GenSystem. By default, 
new applications will be made generic children of this GenField.

**Source:** Unrestricted.

**Destination:** The GenSystem object.

**Parameters:**  
*optr* - The optr of the new default GenField object.

**Return:** Nothing.

**Interception:** Not intercepted.

### 26.2.4 Advanced GenSystem Usage
	MSG_GEN_SYSTEM_SET_PTR_IMAGE, 
	MSG_GEN_SYSTEM_NOTIFY_SYS_MODAL_WIN_CHANGE, 
	MSG_GEN_SYSTEM_MARK_BUSY, MSG_GEN_SYSTEM_MARK_NOT_BUSY, 
	MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP, 
	MSG_GEN_SYSTEM_LOWER_GEODE_TO_BOTTOM

You may alter the pointer image in use at the system level with 
MSG_GEN_SYSTEM_SET_PTR_IMAGE. Pass this message the **PointerDef** 
image to use and the **PointerImageLevel** for the pointer image to 
represent.

MSG_GEN_SYSTEM_NOTIFY_SYS_MODAL_WIN_CHANGE is sent to the 
GenSystem whenever it needs to check the status of any system-modal 
windows. This message is called by the UI whenever it needs to check this 
information. The message looks for the top window on the screen residing at 
a window priority of WIN_PRIO_MODAL within a window layer of 
LAYER_PRIO_MODAL; it then re-directs input to the owning geode's input 
object. If no system modal window is up, input returns along its normal flow 
pattern.

MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP raises a geode's layer to the top, 
giving the application the focus and target (if it is focusable and/or 
targetable). Applications will not generally send this message; instead, they 
will send MSG_GEN_BRING_TO_TOP to the application object, and its handler 
will send MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP to the GenSystem.

MSG_GEN_SYSTEM_LOWER_GEODE_TO_BOTTOM lowers a geode's layer to 
the bottom, releases the focus and target from the application (if it had 
them), and then determines the most suitable geode to grant the focus and 
target exclusives to. Again, applications will not generally send this message; 
instead, they will send MSG_GEN_LOWER_TO_BOTTOM to the application 
object, and its handler will send 
MSG_GEN_SYSTEM_LOWER_GEODE_TO_BOTTOM to the GenSystem.

----------
#### MSG_GEN_SYSTEM_SET_PTR_IMAGE
	void	MSG_GEN_SYSTEM_SET_PTR_IMAGE(
			optr			ptrImage,
			PtrImageLevel	level);

This message alters the system-wide pointer image. 

**Source:** Unrestricted.

**Destination:** The GenSystem object.

**Parameters:**  
*optr* - A pointer to a **PointerDef** structure.

*level* - The **PtrImageLevel** to use. 

**Return:** Nothing.

**Interception:** Not intercepted.

----------
#### MSG_GEN_SYSTEM_NOTIFY_SYS_MODAL_WIN_CHANGE
	void	MSG_GEN_SYSTEM_NOTIFY_SYS_MODAL_WIN_CHANGE();

This message is sent to the system object by the UI when it needs to check 
the status of any system modal windows.

**Source:** The UI. You should not send this message yourself.

**Destination:** The GenSystem object.

**Interception:** Not intercepted.

----------
#### MSG_GEN_SYSTEM_MARK_BUSY
	void	MSG_GEN_SYSTEM_MARK_BUSY();

This message is called by the GenField or GenApplication object while an 
application is being launched but is not yet on screen. While marked busy, 
the UI will continue to allow mouse events through. Each message sent to the 
system object needs a MSG_GEN_SYSTEM_MARK_NOT_BUSY to undo its 
busy state. Therefore, if multiple MSG_GEN_SYSTEM_MARK_BUSY messages 
are sent, an equal number of the MSG_GEN_SYSTEM_MARK_NOT_BUSY 
messages need to be sent to take down the busy cursor.

**Source:** The UI. You should not send this message yourself.

**Destination:** The GenSystem object.

**Interception:** Not intercepted.

----------
#### MSG_GEN_SYSTEM_MARK_NOT_BUSY
	void	MSG_GEN_SYSTEM_MARK_NOT_BUSY();

This message is called by the GenField or GenApplication object when an 
application no longer needs to mark an application busy that has been 
brought on-screen.

**Source:** The UI. You should not send this message yourself.

**Destination:** The GenSystem object.

**Interception:** Not intercepted.

----------
#### MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP
	void	MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP(
			word		geode,
			word		layerID,
			Handle		parentWindow);

This message raises a geode's window layer to the top and gives that geode 
the focus and target (if the geode if focusable/targetable). This message is 
called from within the UI to implement "autoraise," the automatic raising of 
a geode and the transferring of the focus and target when clicked upon. This 
message is also called by the GenApplication's handler for 
MSG_GEN_BRING_TO_TOP.

**Source:** Usually the specific UI, in response to an autoraise, or in response to 
MSG_GEN_BRING_TO_TOP.

**Destination:** The GenSystem object.

**Parameters:**  
*geode* - GeodeHandle of the application.

*layerID* - LayerID of window.

*parentWindow* - Handle of the parent window to bring to top.

**Return:** Nothing.

**Interception:** Not intercepted.

----------
#### MSG_GEN_SYSTEM_LOWER_GEODE_TO_BOTTOM
	void	MSG_GEN_SYSTEM_LOWER_GEODE_TO_BOTTOM(
			word		geode,
			word		layerID,
			Handle		parentWindow);

This message lowers a geode's window layer to the bottom, releases any focus 
and target exclusives, and assigns new focus and target exclusives to the 
most suitable remaining geode. This message is called by the 
GenApplication's handler for MSG_GEN_LOWER_TO_BOTTOM.

**Source:** Usually in response to MSG_GEN_LOWER_TO_BOTTOM.

**Destination:** The GenSystem object.

**Parameters:**  
*geode* - GeodeHandle of the application.

*layerID* - LayerID of the window.

*parentWindow* - Handle of the parent window to lower to the 
bottom.

**Return:** Nothing.

**Interception:** Generally not intercepted.

## 26.3 The GenScreen Object
The GenScreen object is an abstract representation of the video screen in use 
by the system. Its visible bounds are the bounds of the associated screen's 
video driver.

Currently, only one screen may be in use at a time, so there will be only one 
GenScreen at any time. (In the future, multiple screens may be supported.) 
Every visible component of your system will therefore be associated with a 
single GenScreen object. 

### 26.3.1 GenScreen Instance Data
GenScreenClass instance data is internal and should never be set or 
altered by your application. It is provided here for reference, in case you need 
to examine the data during debugging.

	@instance Handle			GSCI_videoDriver;

*GSCI_videoDriver* stores the handle of the current video driver in use by the 
system. This video driver will be used in building the visible tree beneath this 
object. You should never set this video driver yourself.

## 26.4 GenField Objects
The GenField object sets the generic field in which all GenApplications 
attached below it will reside. There may be several GenFields at the same 
time; each provides a distinct environment for applications. For example, in 
Geoworks Ensemble, the Beginner, Intermediate, and Advanced Rooms are 
GenFields.

### 26.4.1 GenField Features
GenField objects perform many functions. All of these functions are 
transparent to the application; indeed, most applications can ignore the 
GenField's existence. Among other things, the GenField does the following:

+ It provides a field on which to display windows and other independent UI 
objects (such as icons, detached menus, etc.).

+ It sets the complexity level (novice, advanced, etc.) for all applications 
under it.

+ It manages the Express menu (if one is present).

### 26.4.2 GenField Instance Data
**GenFieldClass** instance data is internal and should never be set or altered 
by your application. It is provided here for reference, in case you need to 
examine the data during debugging.

----------
**Code Display 26-2 GenField Instance Data**

	/* All of these instance fields are internal. They are listed 
	 * and described here for background information only. */

	@instance GenFieldFlags		GFI_flags = 0;

	typedef ByteFlags GenFieldFlags;
	#define GFF_DETACHING				0x80
	#define GFF_LOAD_BITMAP				0x40
	#define GFF_RESTORING_APPS			0x20
	#define GFF_NEEDS_WORKSPACE_MENU	0x10

	@instance optr			GFI_visParent = 0;
	@instance byte			GFI_numDetachedApps = 0;
	@instance byte			GFI_numRestartedApps = 0;
	@instance byte			GFI_numAttachingApps = 0;
	@instance ChunkHandle	GFI_apps = 0;
	@instance ChunkHandle	GFI_processes = 0;
	@instance ChunkHandle	GFI_genApplications = 0;
	@instance byte			GFI_numAppsToCheck = 0;
	@instance optr			GFI_notificationDestination = 0;

----------
*GFI_flags* stores the **GenFieldFlags** of the GenField object. These flags are 
for internal bookkeeping purposes.

*GFI_visParent* stores the optr of the GenScreen object that acts as this 
GenField's visible parent. This is typically set just before setting the 
GenField GS_USABLE (although it may be left to the specific UI to fill in.) 
During MSG_META_DETACH, this field is cleared; it may not be saved to a 
state file.

*GFI_numDetachedApps* stores the number of applications that were detached 
by the system upon MSG_META_DETACH. These applications and their 
associated state data will be saved to the *GFI_apps* chunk so that they will be 
brought up in their previous state.

*GFI_numRestartedApps* stores the number of applications that have been 
restarted from state files upon MSG_META_ATTACH. These restarted 
applications should reflect the applications detached during the previous 
system shutdown.

*GFI_numAttachingApps* stores the number of applications currently trying to 
attach to the system. The system keeps track of these applications in case the 
system must shutdown during an application's attach cycle.

*GFI_apps* stores a chunk array of **AppInstanceReference** structures. This 
data is used on MSG_META_ATTACH to bring up applications to their 
previous state.

*GFI_processes* similarly stores a chunk array of processes in progress under 
this GenField. This chunk array is saved to state so that these processes may 
continue when GEOS is restarted.

*GFI_genApplications* stores the number of GenApplications currently 
launched within the GenField. This data is not saved to state.

*GFI_numAppsToCheck* stores the number of applications the UI must check 
with before shutting down.

*GFI_notificationDestination* stores the object that should receive the Field's 
notification messages (MSG_META_FIELD_NOTIFY_DETACH, 
MSG_META_FIELD_NOTIFY_NO_FOCUS, 
MSG_META_FIELD_NOTIFY_START_LANUCHER_ERROR).

#### 26.4.2.1 GenField Messages
**GenFieldClass** provides a variety of messages to communicate with the 
system object and applications. Most of these messages are internal, and 
those that are not internal are rarely needed. You may in rare cases find it 
useful to subclass GenField objects, in which case you may need to intercept 
some of the following messages.

##### Background Bitmaps
	MSG_GEN_FIELD_RESET_BG, MSG_GEN_FIELD_ENABLE_BITMAP

The GenField object may have a bitmap attached to it, to display in the field 
below the applications.

##### Field Start-up and Shutdown
	MSG_GEN_FIELD_EXIT_TO_DOS, MSG_GEN_FIELD_ABOUT_TO_CLOSE, 
	MSG_GEN_FIELD_NO_APPS_RESTORED, 
	MSG_GEN_FIELD_OPEN_WINDOW_LIST, 
	MSG_GEN_FIELD_GET_TOP_GEN_APPLICATION, 
	MSG_GEN_FIELD_GET_LAUNCH_MODEL

MSG_GEN_FIELD_EXIT_TO_DOS is sent when the field should exit the system 
and return to the DOS prompt. This message is sent to the GenField object so 
that fields may intercept it and perform their own shutdown maintenance. 
You should only intercept this if you create a custom GenField.

MSG_GEN_FIELD_ABOUT_TO_CLOSE is sent by a GenField environment 
application (such as Welcome) to tell the field that it is about to be closed. If 
`quitOnClose' is set in the field's .INI file, the GenField will attempt to quit all 
applications running in that GenField. Otherwise, the GenField does 
nothing; it waits until all open applications are exited, at which point 
MSG_META_FIELD_NOTIFY_NO_FOCUS will be sent to the GenField.

MSG_GEN_FIELD_NO_APPS_RESTORED is sent to the GenField object when 
the Field has been restarted to inform it that no applications have been 
restarted from the state file.

MSG_GEN_FIELD_OPEN_WINDOW_LIST is sent to the GenField to bring up a 
window list dialog. Certain specific UIs (such as Presentation Manager) 
support this. Other specific UIs may ignore this message.

MSG_GEN_FIELD_GET_TOP_GEN_APPLICATION returns the top (visual) 
GenApplication for the GenField sent this message. 

MSG_GEN_FIELD_GET_LAUNCH_MODEL retrieves the **UILaunchModel** in 
use for this field.

----------
#### MSG_GEN_FIELD_EXIT_TO_DOS
	void	MSG_GEN_FIELD_EXIT_TO_DOS();

This message requests the GenField to exit the system and return to DOS. 
The message is sent to the GenField so that custom fields (such as Welcome) 
can intercept the message and react accordingly by initiating shutdown 
procedures.

**Source:** Usually the UI.

**Destination:** GenField object.

**Interception:** May be intercepted if you have a custom GenField object that needs to 
perform certain shutdown procedures before exiting to DOS (such as 
shutting down applications).

----------
#### MSG_GEN_FIELD_ABOUT_TO_CLOSE
	void	MSG_GEN_FIELD_ABOUT_TO_CLOSE();

This message is sent by an environment application (like Welcome) to inform 
a GenField that it is about to be closed. The GenField then has the option of 
quitting any applications or waiting until the applications themselves are 
closed by the user. If `quitOnClose' is set the GenField's .INI file category, 
then the GenField will quit all open applications. Otherwise, it will ignore 
the request to quit.

**Source:** Unrestricted, though usually an environment application resident on 
top of a GenField object.

**Destination:** The GenField object.

**Interception:** May be intercepted if you have a custom GenField.

----------
#### MSG_GEN_FIELD_NO_APPS_RESTORED
	void	MSG_GEN_FIELD_NO_APPS_RESTORED();

This message serves as notification that no processes have been restarted 
from the state file.

**Source:** The kernel

**Destination:** GenField object

**Interception:** May be intercepted to support custom behavior for a custom GenField 
object.

----------
#### MSG_GEN_FIELD_OPEN_WINDOW_LIST
	void	MSG_GEN_FIELD_OPEN_WINDOW_LIST();

This message may be sent by any object that wishes to bring up a GenField's 
window list dialog (if available).

**Source:** Unrestricted.

**Destination:** GenField object under a specific UI that supports window list dialogs.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_FIELD_GET_TOP_GEN_APPLICATION
	optr	MSG_GEN_FIELD_GET_TOP_GEN_APPLICATION();

This message returns the GenField's top application object.

**Source:** Unrestricted.

**Destination:** GenField object.

**Return:** optr of top visual GenApplication object.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_FIELD_GET_LAUNCH_MODEL
	word	MSG_GEN_FIELD_GET_LAUNCH_MODEL();

This message returns the GenField's **UILaunchModel** in use.

**Source:** Unrestricted.

**Destination:** GenField object.

**Return:** **UILaunchModel** in use by the GenField.

**Interception:** Generally not intercepted.

[VisContent](oviscnt.md) <-- [Table of Contents](../objects.md)

