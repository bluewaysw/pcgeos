## 9 General Change Notification

In a multitasking environment, threads may need to know of condition 
changes that might affect them. In most cases where shared resources or 
multiple threads of execution exist, processes and objects must be sure of the 
integrity of data that they depend on and must be sent notice when that data 
changes.

In GEOS, this functionality is provided through the General Change 
Notification (GCN) mechanism. Although one could set up messages between 
processes and objects manually, the GCN mechanism eliminates the need to 
keep track of all processes that depend on the particular change and to keep 
track of all messages sent out to the various processes and objects.

### 9.1 Design Goals

General Change Notification allows you to keep track of both system and 
application events. Objects or processes interested in a particular change 
may request the GCN mechanism to notify them when that change occurs. 
That change may be system-wide (such as a file system change) or 
application-specific (such as a text style change within a word processor). The 
GCN mechanism allows objects or processes to sign up for such notification 
and intercept messages sent by the system (or the application) so that you 
may respond to different changes on a case by case basis.

The manners in which you sign up for these two types of notification differ 
although the functionality of the notification process is similar. The most 
straightforward way is to use a gcnList field in an application's application 
object; this is the usual approach used to add an application's GenPrimary 
object to the application's window list. We will assume that you know how to 
add an object to a GCN list in this manner, as it is shown in most if not all of 
the sample applications.

You can also sign up for system-wide notification through the use of certain 
routines and intercept system messages when the change occurs. Other 
objects may sign up for application-specific notification supported by 
GenApplicationClass. These application specific notifications should only 
be sent to the GenApplication object.

### 9.2 The Mechanics of GCN

The basic GCN functionality manages lists of objects that are interested in 
specific changes. For each particular change that needs to be monitored, a 
separate list is needed. A completely separate "list of lists" containing an 
inventory of all GCN lists is also created. This will serve as the "search" table, 
while the particular GCN list will serve as the "messaging" list. When an 
event is detected, the GCN mechanism will search through the list of lists, 
seeing if a notification list is interested in a particular change, and send the 
appropriate messages if the objects do indeed wish notification of the event. 

![](Art/Figure_9-1.png)

**Figure 9-1** A GCN List of Lists  
_Organization of a GCN list of lists and several GCN lists._

There are several reasons why you would want to use GCN:

+ Ease of use
The GCN mechanism eliminates the need to monitor and dispatch 
messages relating to system changes.

+ Commonality
The GCN mechanism provides a common platform for communication 
between applications in certain cases.

+ The system expects you to
Many messages sent by the system expect a GCN mechanism to intercept 
them. Although you can intercept these messages manually, it is easier 
to take advantage of GCN's built-in functions.

### 9.3 System Notification

GCNListAdd(), GCNListSend()

The system provides several lists for common system changes which might 
affect your application. After signing up on one of these lists (for example, the 
file change list) you will be notified by the kernel whenever the specified 
change occurs. In most cases, all you need to do is register for notification 
with GCNListAdd() and intercept the kernel's notification message.

The GCN mechanism performs its functions through a common series of 
steps. These steps are:

1. The object registers for notification with GCNListAdd().

2. The change occurs.

3. The GCN mechanism is informed of the change by the acting party (in 
most cases this is the system itself, although a library may also send 
notifications). Applications do not send notifications at the system level.

4. The GCN mechanism dispatches notification messages to all interested 
parties with GCNListSend().

5. The object is informed of the change.  
If you need to perform some work related to this change, you should have 
a message handler to intercept the system messages.

#### 9.3.1 Registering for System Notification

Whenever an object or process needs to be notified of some system change, it 
must call the routine GCNListAdd() to add itself to the list for that 
particular change. GCNListAdd() finds the appropriate general change 
notification list-creating a new one if none currently exists-and adds the 
optr of the new object to the end of that list. You may add the optr to the GCN 
list at any time during the process' or object's life, but it is usually convenient 
for a process to be added in its MSG_GEN_PROCESS_OPEN_APPLICATION or 
for an object that is on the active list to be added in its MSG_META_ATTACH 
handler. 

Each optr in a GCN list should have a notification ID attached to it. (The 
combination of a manufacturer ID and a notification type comprises an 
element's specific notification ID.) GCNListAdd() must be passed the optr of 
the object to add, along with a notification ID. For each separate notification 
ID, a separate GCN list is needed and will be created automatically. 

The GCN routines use a word of data, GCNStandardListType, to represent 
the notification type. The currently recognized GCNStandardListType 
types for MANUFACTURER_ID_GEOWORKS are

+ GCNSLT_FILE_SYSTEM  
This GCNStandardListType is used for notification of a file system 
change. Parties on this list will receive the system messages 
MSG_NOTIFY_FILE_CHANGE and MSG_NOTIFY_DRIVE_CHANGE.

+ GCNSLT_APPLICATION  
This GCNStandardListType is used for notification of a starting or 
exiting application. Parties on this list will receive the system messages 
MSG_NOTIFY_APP_STARTED and MSG_NOTIFY_APP_EXITED.

+ GCNSLT_DATE_TIME  
This GCNStandardListType is used for notification of a date/time 
change in the system's internal clock. Note that this will not tell you 
about timer ticks-the only time changes that will come up are those 
resulting from system restarts and time changes by the user. Parties on 
this list will receive the system message 
MSG_NOTIFY_DATE_TIME_CHANGE. This message does not pass any 
further information, so your message handler should be able to take care 
of any changes by itself (such as calling the internal clock for an updated 
value).

+ GCNSLT_DICTIONARY  
This GCNStandardListType is used for notification of a user 
dictionary change. Parties on this list will receive the system message 
MSG_NOTIFY_USER_DICT_CHANGE.

+ GCNSLT_KEYBOARD_OBJECTS  
This list is used for notification when the user has chosen a different 
keyboard layout. Parties on this list will receive the system message 
MSG_NOTIFY_KEYBOARD_LAYOUT_CHANGE.

+ GCNSLT_EXPRESS_MENU_CHANGE  
This GCNStandardListType notifies various system utilities that an 
express menu has been created or destroyed. The recipient receives the 
optr of the Express Menu Control. This list should be used in conjunction 
with the GCNSLT_EXPRESS_MENU_OBJECTS list. Objects on this list 
receive MSG_NOTIFY_EXPRESS_MENU_CHANGE, which itself passes a 
GCNExpressMenuNotificationType (either GCNEMNT_CREATED or 
GCNEMNT_DESTROYED) and the optr of the Express Menu Control 
affected. 

+ GCNSLT_INSTALLED_PRINTERS  
This list notifies objects when a printer is either installed or removed. 
The recipient of MSG_PRINTER_INSTALLED_REMOVED might want to 
call SpoolGetNumPrinters() to learn if any printer or fax drivers are 
currently installed.

+ GCNSLT_SHUTDOWN_CONTROL  
This GCNStandardListType is used for system shutdown control. 
Parties on a list of this type will receive the system message 
MSG_META_CONFIRM_SHUTDOWN which itself passes a 
GCNShutdownControlType (either GCNSCT_SUSPEND, 
GCNSCT_SHUTDOWN, or GCNSCT_UNSUSPEND). Shutdown Control is 
documented in "Applications and Geodes," Chapter 6.

+ GCNSLT_TRANSFER_NOTIFICATION  
This list notifies objects that a transfer item within the clipboard has 
changed (or been freed). Parties on this list will receive the system 
message MSG_META_CLIPBOARD_
NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED and 
MSG_META_CLIPBOARD_NOTIFY_TRANSFER_ITEM_FREED.

+ GCNSLT_EXPRESS_MENU_OBJECTS  
This list contains all Express Menu Control objects in the system. 
Typically this list is used to add a control panel item or a DOS task list 
item to all express menu Control objects. This can be done by sending 
MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM to the GCN list with 
GCNListSend().

+ GCNSLT_TRANSPARENT_DETACH  
This list contains all application objects that may be transparently 
detached if the system runs short of heap space, in least recently used 
(LRU) order. This list should only be used if transparent launch mode is 
in use.

+ GCNSLT_TRANSPARENT_DETACH_DA  
This list contains a list of transparently detachable desk accessories if 
the system runs short of heap space. This list should only be used if 
transparent launch mode is in use. Objects should not be detached unless 
all detachable, full-screen applications have been detached.

+ GCNSLT_REMOVABLE_DISK  
This list is used to store all application and document control objects that 
originate from a removable drive. If the disk they originate on is 
removed, they will be notified to shut themselves down with 
MSG_META_DISK_REMOVED.

These pre-defined notification types are intended only for use with 
MANUFACTURER_ID_GEOWORKS. Other manufacturers wishing to 
intercept their own system changes must define their own change types 
under their respective manufacturer IDs if they are unable to use 
MANUFACTURER_ID_GEOWORKS.

---
Code Display 9-1 Adding a Process Object to a GCN List
~~~
@method MyProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION {
    optr			myThread;

    @callsuper;			/* Do default MSG_GEN_PROCESS_OPEN_APPLICATION */

/* Casts the return value for the process handle into an optr */

    myThread = ConstructOptr(GeodeGetProcessHandle(), NullChunk);

/* myThread (the process) is added to notification of file changes */

    GCNListAdd(myThread, MANUFACTURER_ID_GEOWORKS, GCNSLT_FILE_SYSTEM);
}
~~~

#### 9.3.2 Handling System Notification

MSG_NOTIFY_FILE_CHANGE, MSG_NOTIFY_DRIVE_CHANGE, 
MSG_NOTIFY_APP_STARTED, MSG_NOTIFY_APP_EXITED, 
MSG_NOTIFY_USER_DICT_CHANGE, 
MSG_NOTIFY_EXPRESS_MENU_CHANGE

When an identified change occurs, either the system (or a library) will call the 
routine GCNListSend(), passing it the appropriate notification message. 
This routine scans the list of all GCN lists and dispatches notification to all 
appropriate objects that had requested knowledge of the specified change. If 
any additional information relating to the change cannot be included in the 
message, the system allows GCNListSend() to pass data in a global heap 
block. For example, additional information about a file change (name of file, 
etc.) must be passed in a global heap block.

The object or process originally requesting notification of the change should 
be required to handle the appropriate message. If additional data about the 
change is passed in a global heap block, the process should access that 
information with MemLock() and MemUnlock(). You should always call 
the process's superclass in your message handler to make sure that the global 
heap block will be automatically freed by MetaClass. Therefore, do not free 
a global heap block manually in a notification handler.

The system provides several messages which you may want to handle. These 
messages provide notification of file system changes, application start-up or 
shut-down, system clock changes, etc. These messages are mentioned with 
the list they correspond to in "Registering for System Notification" on page 
357. Messages which require more detailed explanation are also mentioned 
below.

The kernel sends MSG_NOTIFY_FILE_CHANGE whenever a change to the file 
system occurs. All objects signed up on the GCN list GCNSLT_FILE_CHANGE 
will receive this message.

MSG_NOTIFY_FILE_CHANGE passes a FileChangeNotificationType 
specifying the change that occurred. Some types indicate the presence of a 
data block (of type FileChangeNotificationData) containing, if applicable, 
the name of the file changed, the disk handle of the file changed, and the ID 
of the affected file. 

The notification type should be one of the following:

FCNT_CREATE  
This type indicates that a file or directory was created. 
FCND_id stores the ID of the containing directory; FCND_name 
contains the name of the new file or directory that was created.

FCNT_RENAME  
This type indicates that a file or directory was renamed. 
FCND_id stores the ID of the file or directory that was renamed; 
FCND_name contains its new name.

FCNT_OPEN  
This type indicates that a file was opened. FCND_id stores the 
ID of the file. FCND_name is undefined, and may or may not be 
present. (You can check the size of the block to see if it is indeed 
present.) This notification type is generated after a call to 
FileEnableOpenCloseNotification().

FCNT_DELETE  
This type indicates that a file or directory was deleted. 
FCND_id stores the ID of the file or directory that was deleted. 
FCND_name is undefined and may or may not be present.

FCNT_CONTENTS  
This type indicates that a file's contents have changed. 
FCND_id stores the ID of the file. FCND_name is undefined and 
may or may not be present. This notification type is generated 
after a call to FileCommit() or FileClose() that results in a 
file modification.

FCNT_ATTRIBUTES  
This type indicates that a file's attributes have changed. 
FCND_id stores the ID of the file. FCND_name is undefined and 
may or may not be present. This notification type is generated 
upon completion of all changes in a FileSetAttributes(), 
FileSetHandleExtAttributes(), or 
FileSetPathExtAttributes() call.

FCNT_DISK_FORMAT  
This type indicates that a disk has been formatted. Both 
FCND_id and FCND_name are undefined and may not be 
present.

FCNT_CLOSE  
This type indicates that a file has been closed. FCND_id stores 
the identifier of the file. FCND_name is undefined and may not 
be present. This notification type is generated only after a call 
to FileEnableOpenCloseNotification().

FCNT_BATCH  
This type indicates that this file change notification is actually 
a group of notifications batched together. In this case, 
MSG_NOTIFY_FILE_CHANGE passes the MemHandle of a 
FileChangeBatchNotificationData block instead. This data 
block stores a batch of FileChangeBatchNotificationItem 
structures, each referring to an operation (with its own 
notification type, disk handle, file name, and file ID). Note that 
in this batched case, you must assume that all file names and 
file IDs that are optional (i.e. are undefined) are not present.

FCNT_ADD_SP_DIRECTORY  
This type indicates that a directory has been added as a 
StandardPath. FCND_disk contains the StandardPath that 
was added. This notification type is generated after a call to 
FileAddStandardPathDirectory().

FCNT_DELETE_SP_DIRECTORY  
This type indicates that a directory has been deleted as a 
StandardPath. FCND_disk contains the StandardPath that 
was deleted. This notification type is generated after a call to 
FileDeleteStandardPathDirectory().

You may access this data (after locking the block) and perform whatever 
actions you need within your message handler.

The kernel also sends MSG_NOTIFY_DRIVE_CHANGE to GCN lists of type 
GCNSLT_FILE_CHANGE. This message passes a 
GCNDriveChangeNotificationType specifying whether a drive is being 
created or destroyed and the ID of the affected drive.

The kernel sends MSG_NOTIFY_APP_STARTED whenever any application 
starts up within the system and MSG_NOTIFY_APP_EXITED whenever an 
application shuts down. All objects signed up on the GCN list 
GCNSLT_APPLICATION will receive these messages after the change occurs. 
MSG_NOTIFY_APP_STARTED passes the MemHandle of the application 
starting up, which you may access to perform any required actions. In a 
similar manner, MSG_NOTIFY_APP_EXITED passes the MemHandle of the 
application shutting down.

The kernel sends MSG_NOTIFY_USER_DICT_CHANGE whenever the system 
changes the current user dictionary in use. All objects signed up for the GCN 
list GCNSLT_USER_DICT_CHANGE will receive this message after the change 
occurs. MSG_NOTIFY_USER_DICT_CHANGED passes the MemHandle of the 
Spell Box causing the change and the MemHandle of the user dictionary 
being changed, both of which you may access in your message handler.

#### 9.3.3 Removal from a System List

You should use GCNListRemove() to remove an object from a system GCN 
list. You must pass the notification ID (GCNStandardListType and 
Manufacturer ID) and the optr of the object to be removed. The optr of the 
object in question will only be removed from the list of the particular change 
specified. If the optr is on several GCN lists, those other lists will remain 
unchanged. 

An object or process in the course of dying must remove itself from all GCN 
lists that it is currently on. You should therefore keep track of all GCN lists 
you add a particular object to. It is usually convenient for a process to remove 
itself from these lists within its MSG_GEN_PROCESS_CLOSE_APPLICATION 
message handler or for an object to remove itself in its MSG_META_DETACH 
handler.

---
Code Display 9-2 Removing a Process from a GCN list
~~~
@method MyProcessClass, MSG_GEN_PROCESS_CLOSE_APPLICATION {
	optr 		myThread;
	myThread = ConstructOptr(GeodeGetProcessHandle(), NullChunk);
	GCNListRemove(myThread, MANUFACTURER_ID_GEOWORKS, GCNSLT_FILE_CHANGE);
	@callsuper;
}
~~~

### 9.4 Application Local GCN Lists

The GCN mechanism not only allows you to keep track of system changes but 
also allows you to keep track of changes within a specific application. These 
application-specific GCN lists operate in slightly different manners than the 
system-wide application lists. There are an extensive number of pre-defined 
application lists for MANUFACTURER_ID_GEOWORKS. You may use these if 
you like, but in most cases you will want to create your own list and 
notification types for your application.

The GenControl objects make extensive use of these types of GCN lists when 
implementing changes. For a complete discussion of using these lists within 
the context of a GenControl, see "Generic UI Controllers," Chapter 12 of the 
Object Reference Book.

If you will be creating custom GenControl objects or just wish to set up a 
notification system within your application, you will want to create your own 
application GCN lists when using this mechanism. To do this, you must follow 
a few preliminary steps:

+ Create a new list of type YourCompanyNameGenAppGCNListTypes 
within an appropriate yourCompanyName.h file.

+ Create an GCN notification type of 
YourCompanyNameNotificationTypes for the above list type within 
the yourCompanyName.h file.

The GCN mechanism in this case performs its functions through a common 
series of steps. These steps are similar to the steps needed for system-wide 
notification:

1. The object registers for notification with MSG_META_GCN_LIST_ADD.

2. The change occurs within your application and invokes your own custom 
method. Because the change occurs within your application, you are 
responsible for detecting the change and sending out notification 
yourself.

3. Record the notification event with MSG_META_NOTIFY or 
MSG_META_NOTIFY_WITH_DATA_BLOCK, the notification list type to 
use, and the data block to pass (if applicable).

4. Use MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST to pass the event. 
You may have to pass some GCNListSendFlags with this message. This 
message acts as a dispatch routine, sending all interested parties the 
recorded event MSG_META_NOTIFY.

5. The object is informed of the change with MSG_META_NOTIFY or 
MSG_META_NOTIFY_WITH_DATA_BLOCK. If you need to perform some 
work related to this change, you should have a message handler to 
intercept these messages.

#### 9.4.1 Creating Types and Lists

It is a relatively simple matter to create your own notification types. Within 
an appropriate company-specific file merely create your own types and lists. 
(For example, all Geoworks application-local lists are within the file 
geoworks.h.)

---
Code Display 9-3 Creating New Notification Types and Lists
~~~
/* These types should be placed within an appropriate yourCompnayName.h file. */

/* First create a group of Notification types to use for your MANUFACTURER_ID. */

typedef enum {
    <yourCompanyName>_NT_CUSTOM_NOTIFICATION_NUMBER_ONE
    <yourCompanyName>_NT_CUSTOM_NOTIFICATION_NUMBER_TWO
    ...
} <yourCompanyName>NotificationTypes;

/* Then create whatever Notification list types you need. These list types
 * usually correspond one-to-one to the types enumerated above. It is possible,
 * however, for several lists to be interested in a single notification type. */

typedef enum {
    <yourCompanyName>_GAGCNLT_CUSTOM_LIST_TYPE_ONE
    <yourCompanyName>_GAGCNLT_CUSTOM_LIST_TYPE_TWO
    ...
} <yourCompanyName>GenAppGCNListTypes;
~~~

#### 9.4.2 Registering for Notification

MSG_META_GCN_LIST_ADD 

Registering for application notification is simple once you have created your 
own custom notification lists. Whenever an object or process needs to be 
notified of an application change, you should call MSG_META_GCN_LIST_ADD 
to add that object or process to the list interested in that particular change. 
MSG_META_GCN_LIST_ADD finds the appropriate custom GCN list and adds 
the optr of the new object to the end of that list. (If no space for the list 
currently exists because it is empty, the message will allocate space for the 
list automatically.) You may add the interested optr at any time during the 
process' or object's life, but it is usually convenient for a process to be added 
in its MSG_GEN_PROCESS_OPEN_APPLICATION or for an object to be added 
in its MSG_META_ATTACH handler. 

Each optr in a GCN list should have a notification ID attached to it. The 
combination of a manufacturer ID and a notification type comprises an 
element's specific notification ID. MSG_META_GCN_LIST_ADD must pass the 
optr of the object to add, along with a notification ID. For each separate 
notification ID, a separate GCN list is needed and will be created 
automatically. 

Geoworks has several pre-defined GCN lists of type 
GeoWorksGenAppGCNListType for use by applications. You will 
probably have only limited use for these; these list types are used mostly by 
the UI controllers. For information on these types and how the various 
classes use them, see "Generic UI Controllers," Chapter 12 of the Object 
Reference Book.

---
Code Display 9-4 Adding Yourself to a Custom GCN List
~~~
@method MyProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION {

    @callsuper;			/* Do default MSG_GEN_PROCESS_OPEN_APPLICATION */

    myThread = ConstructOptr(GeodeGetProcessHandle(), NullChunk);

/* myThread (the process) is added to notification of TYPE_ONE changes */

    @call MyApplication::MSG_META_GCN_LIST_ADD(myThread,
	yourCompanyName_GAGCNLT_CUSTOM_LIST_TYPE_ONE,
	MANUFACTURER_ID_yourCompanyName);
}
~~~

#### 9.4.3 Handling Application Notification

MSG_META_NOTIFY, MSG_META_NOTIFY_WITH_DATA_BLOCK, 
MSG_META_GCN_LIST_SEND

When a change occurs in the application that needs to send out notification, 
you must set up the notification message and send it to the interested list. 
You may attach a data block to this notification for use by the objects on the 
notification list. To send out these notifications, you should use 
MSG_META_NOTIFY or MSG_META_NOTIFY_WITH_DATA_BLOCK (when 
passing data). 

In the simplest case without the need to pass data, you should encapsulate 
MSG_META_NOTIFY with the particular Notification ID (notification type and 
Manufacturer ID) that should be notified. You should then send 
MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST to your application object 
with this event and the particular GCN list interested in this change. (Note 
that you will have to keep track of which lists are interested in which 
notification types.) Make sure that you perform a send (not a call) when using 
this message as the message may cross threads.

---
Code Display 9-5 Using MSG_META_NOTIFY
~~~
@method MyProcessClass, MSG_SEND_CUSTOM_NOTIFICATION {

    MessageHandle event;

/* First encapsulate the MSG_META_NOTIFY with the type of list and manufacturer ID
 * interested in the change. Since this message is being recorded for no class in
 * particular, use NullClass.*/

    event = @record (optr) NullClass::MSG_META_NOTIFY(
	MANUFACTURER_ID_yourCompanyName,
	yourCompanyName_NT_CUSTOM_TYPE_ONE);

/* Then send this MSG_META_NOTIFY using MSG_META_GCN_LIST_SEND. You must make sure
 * to pass the particular GCN list interested in the changes encapsulated in the
 * above message. */

    @send MyProcess::MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST (
	(word) 0, 			/* GCNListSendFlags */
	event,			/* Handle to MSG_NOTIFY event above. */
	0,			/* No data passed, so no data block. */
	/* Pass the list interested in NT_CUSTOM_TYPE_ONE notification types. */
	yourCompanyName_GAGCNLT_APP_CUSTOM_LIST_ONE,
	/* Pass your manufacturer ID. */
	MANUFACTURER_ID_yourCompanyName);
}
~~~

If instead you need to pass a data block along with the notification, you 
should use MSG_META_NOTIFY_WITH_DATA_BLOCK. You should set up the 
structure to pass beforehand. You must also make sure to add a reference 
count to the data block equal to the number of lists (not objects) you wish to 
send the notification. To do this, call MemInitRefCount() with the data 
block and the total number of lists you are sending the notification to. (In 
most cases, you will only send notification to one list, although, of course, that 
list may have several objects.) 

---
Code Display 9-6 MSG_META_NOTIFY_WITH_DATA_BLOCK
~~~
@method MyProcessClass, MSG_SEND_CUSTOM_NOTIFICATION {

    typedef struct {
	int number;
	char letterToLookFor;
    } MyDataStructure;

    MemHandle myDataBlock;
    MyDataStructure *myDataPtr;
    MessageHandle event;

/* Allocate and lock down a block for the data structure. This will be passed
 * along with the notification. NOTE: data blocks must be sharable! */

    myDataBlock = MemAlloc(sizeof(MyDataStructure), (HF_DYNAMIC | HF_SHARABLE),
			 HAF_STANDARD);

    myDataPtr = MemLock(myDataBlock);

/* Load up the structure with pertinent information. */
    myDataPtr->count = 200;
    myDataPtr->letterToLookFor = `z';

/* Unlock it and set its reference count to 1 as we are only sending this to one
 * list. */
    MemUnlock(myDataBlock);
    MemInitRefCount(myDataBlock, (word) 1);

/* Now encapsulate a MSG_META_NOTIFY_WITH_DATA_BLOCK message. Since it is being
 * recorded for no particular class, use NullClass as its class type. */

    event = @record (optr) NullClass::MSG_META_NOTIFY_WITH_DATA_BLOCK(
			MANUFACTURER_ID_yourCompanyName,				/* Manufacturer ID */
			NT_CUSTOM_TYPE_ONE,				/* List type. */
			myDataBlock);				/* handle of data block */

/* Finally, send the message off to our process. The GCNListSendFlags depend on
 * the situation. */

    @send MyProcess::MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST(
			(word) 0,			/* GCNListSendFlags */
			event,			/* Handle to message */
			myDataBlock,			/* Handle of data block */
	/* Pass the type of list interested in NT_CUSTOM_TYPE_ONE notification. */
			GAGCNLT_APP_CUSTOM_LIST_ONE,
			MANUFACTURER_ID_yourCompanyName);

/* All done! myDataBlock will be MemFree()'d automatically. */
}
~~~

The object or process originally requesting notification of the change will 
want to provide a handler for the MSG_META_NOTIFY or 
MSG_META_NOTIFY_WITH_DATA_BLOCK. If additional data about the 
change is passed in a data block, the process should access that information 
with MemLock() and MemUnlock(). You should always call the process's 
superclass in your message handler, to make sure that the global heap block 
will be automatically freed by MetaClass. Therefore, do not free a 
notification data block manually in a notification handler.

---
Code Display 9-7 Intercepting an Application Notification Change
~~~
/* Code to implement when MyObjectClass receives MSG_META_NOTIFY with a certain
 * notification type. */

@method MyObjectClass, MSG_META_NOTIFY {

    MyDataStructure myData;				/* Stores the passed data block. */

/* Lock the data structure. */

    myData = MemLock(data);

/* Check the notification type and implement the changes you wish to occur in
 * response to the previous event. */

    if ((notificationType == yourCompanyName_NT_CUSTOM_TYPE_ONE) & 
	(manufID == MANUFACTURER_ID_yourCompanyName)){
	/* Code to implement for your object. */
    }

    MemUnlock(data);

    @callsuper;				/* Important! Frees data block. */
}
~~~

#### 9.4.4 Removal from Application Lists

You should use MSG_META_GCN_LIST_REMOVE to remove an object from an 
application GCN list. You must pass the routine the notification ID 
(yourCompanyNameAppGCNListTypes and Manufacturer ID) and the 
optr of the object to remove. Note that the optr of the object in question will 
only be removed from the list of the particular change specified. If the optr is 
on several GCN lists, those other lists will remain unchanged. 

An object or process in the course of dying must remove itself from all GCN 
lists that it is currently on, both from the system and from an application. 
You should therefore keep track of all GCN lists you add a particular object 
to. It is usually convenient for a process to remove itself from these lists 
within its MSG_GEN_PROCESS_CLOSE_APPLICATION message handler or 
for an object to remove itself at MSG_META_DETACH time.

---
Code Display 9-8 Removing from an Application GCN List
~~~
@method MyProcessClass, MSG_GEN_PROCESS_CLOSE_APPLICATION {

    @send MyApplication::MSG_META_GCN_LIST_REMOVE(
			MyObject,			/* optr to remove from list. */
			yourCompanyName_NT_CUSTOM_LIST_ONE,
					/* list to remove object from. */
		/* Manufacturer ID of list to remove object from. */
			MANUFACTURER_ID_yourCompanyName);

    @callsuper;
}
~~~

[Localization](clocal.md) <-- &nbsp;&nbsp; [table of contents](../Concepts.md) &nbsp;&nbsp; --> [The Geos User Interface](cuiover.md)
