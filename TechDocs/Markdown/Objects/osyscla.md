
# 1 System Classes

GEOS provides three high-level classes which operate mostly behind the 
scenes. Your application will never include an object of any of these classes, 
though it will include objects of their subclasses. **MetaClass** is the root of the 
GEOS class tree and therefore handles many messages you may never realize 
get handled by your objects. **ProcessClass** is the class that handles creation 
of a primary thread for a process geode. **GenProcessClass**, a subclass of 
**ProcessClass**, handles additional application process behavior such as state 
saving and restoration as well as application opening and closing.

## 1.1 MetaClass

**MetaClass** is the ancestor class of every GEOS object. **MetaClass** is the 
location of basic messages and their handlers. Basic functionality for all 
objects - instantiation, initialization, detach, and destruction - is 
implemented within this class.

The only instance data field defined for **MetaClass** is the object's class 
pointer (the field is named *MI_base*). **MetaClass** has no other inherent data 
fields. You will never need to access the class pointer directly.

**MetaClass** also serves as a sort of placeholder for certain messages. 
Applications writers familiar with mouse input, for instance, know that 
MSG_META_START_SELECT signals a mouse click. This message is actually 
defined at the **MetaClass** level, though **MetaClass** itself has no handler for 
it. However, by defining this message at the Meta level, all classes which 
should be able to handle mouse events agree on the message number 
corresponding to a click. Normally, these messages are defined in the 
appropriate library, then exported. Applications and libraries using these 
messages can import them. For information about importing and exporting 
messages, see "GEOS Programming," Chapter 5 of the Concepts Book.

### 1.1.1 Special Messages

MSG_META_NULL, MSG_META_DUMMY

The following two messages are mainly place holders. They ensure that no 
message will have the value zero or one. (When a message is called, a value 
of zero equates to null.) These are not used by applications or objects in 
general.

----------

#### MSG_META_NULL

`void	MSG_META_NULL();`

This message has no handler and is unused. It essentially ensures that no 
other message will ever have the value zero.

**Interception:** Don't.

----------

#### MSG_META_DUMMY

`void MSG_META_DUMMY();`

This message has no handler. You should not subclass this message to 
provide one. Certain object mechanisms, such as the resolution of a variant 
class, are activated by the object's receipt of MSG_META_DUMMY.

**Interception:** Don't.

### 1.1.2 Utility Messages

**MetaClass** also provides a number of other messages that are used 
throughout the system. These messages have been separated into 
loosely-defined categories and listed in the sections below.

#### 1.1.2.1 Object Creation and Destruction

These messages handle creation, destruction, and initialization of all objects. 
The function and use of many of these messages are given in "GEOS 
Programming," Chapter 5 of the Concepts Book.

----------

#### MSG_META_INITIALIZE

`void MSG_META_INITIALIZE();`

Every object class should provide a handler for this message which should 
call the superclass and then perform any initialization of the instance data 
required. 

Note that **GenClass** and **VisClass** have a default handler that sets up the 
Gen and Vis parts automatically.

**Source:** Object system itself, often in the middle of attempting to deliver 
another message to an object that hasn't yet been initialized.

**Destination:** Object whose instance data is not yet initialized.

**Parameters:** None.

**Return:** Nothing.

**Interception:** Any class wishing to have default instance data values other than all 
zeros should intercept this message to fill in the initial values for its 
instance data. For classes other than master classes, standard 
procedure is to call the superclass first, then perform any additional 
instance data initialization necessary. Master classes should not call 
the superclass, as MSG_META_INITIALIZE is unique among messages 
in that it is sent only to classes within the particular master group that 
needs to be initialized. Handlers of MSG_META_INITIALIZE should 
limit their activities to just stuffing instance data-specifically, object 
messaging is not allowed (though scanning vardata is OK). Object 
classes that inherit instance data (all but **MetaClass**) should call 
MSG_META_INITIALIZE on their superclass to initialize that portion of 
their instance data. In addition, they must initialize their own portion 
of the instance data (start by assuming it's all zeros). The order won't 
matter, so long as the handler doesn't depend on the inherited instance 
data having any particular value. When in doubt, call superclass first.

----------

#### MSG_META_ATTACH

`void MSG_META_ATTACH();`

This message is used for two different purposes: It can be sent to any geode 
that has a process aspect when the geode is first loaded. It can also be sent in 
the object world to notify objects on an "active list" that the application has 
been brought back up from a state file. As the method is used for different 
purposes, the data passed varies based on usage. Because of this difference 
in parameters, normally C applications will use one of the aliases for this 
message (MSG_META_ATTACH_PROCESS, MSG_META_ATTACH_THREAD, 
MSG_META_ATTACH_GENPROCESSCLASS, MSG_META_ATTACH_OBJECT, 
and MSG_META_ATTACH_GENAPPLICATION, each described below.)

----------

#### MSG_META_ATTACH_PROCESS

`@alias (MSG_META_ATTACH)`

	void 	MSG_META_ATTACH_PROCESS(  
	word 	value1,  
	word 	value2);

This message is sent to any geode which has a process when the geode is first 
loaded. By default, the handler for this message does nothing.

**Source:** **GeodeLoad()** kernel routine.

**Destination:** Newly created Process object (but not GenProcess object).

**Parameters:**  
*value1* - Upper half of **GeodeLoad()** *appInfo* argument.

*value2* - Lower half of **GeodeLoad()** *appInfo* argument.

**Return:** Nothing.

**Interception:** No default handling provided, so if you are spawning an extra process 
and that process needs to do some initialization, then intercept this 
message.

----------

#### MSG_META_ATTACH_GENPROCESSCLASS

`@alias (MSG_META_ATTACH)`

	void	MSG_META_ATTACH_GENPROCESSCLASS(  
			MemHandle appLaunchBlock);

This message is sent to the GenProcess object when the geode is first loaded. 
By default, the handler for this message calls 
MSG_PROCESS_STARTUP_UI_THREAD, which checks to see if there are any 
resources of the application which are marked as "ui-object" (they are 
marked this way in the **.gp** file), that is, to be run by a UI thread. If so, it then 
calls MSG_PROCESS_CREATE_UI_THREAD to create that thread, then marks 
the "ui-object" blocks as run by that thread.

The handler next calls one of the following messages:

MSG_GEN_PROCESS_OPEN_APPLICATION  
For applications which are being started up regularly (that is, 
not restoring from a state file) and will appear on screen.

MSG_GEN_PROCESS_OPEN_ENGINE  
For those applications that will operate in engine mode (i.e. 
non-visual).

MSG_GEN_PROCESS_RESTORE_FROM_STATE  
For applications which are restoring from state. This is the 
case for applications that were running at the previous 
shutdown.

**Source:** **GeodeLoad()** kernel routine.

**Destination:** Newly created **GenProcessClass** (or subclass thereof) object.

**Parameters:**  
*appLaunchBlock* - Block handle to block of structure **AppLaunchBlock**.

**Return:** Nothing.  
Note that the passed **AppLaunchBlock** is destroyed.

**Interception:** No default handling provided, so if you are spawning an extra process 
and that process needs to do some initialization, then intercept this 
message.

----------

#### MSG_META_ATTACH_GENAPPLICATION

`@alias (MSG_META_ATTACH)`

	void	MSG_META_ATTACH_PROCESS(  
			MemHandle 	bh1,  
			MemHandle 	bh2);

This message is sent to the GenApplication object by **GenProcessClass** 
when the application starts up (either for the first time, or when being 
restored from a state file).

**Source:** GenProcess object.

**Destination:** GenApplication object.

**Parameters:**  
*bh1* - Block handle to block containing 
**AppLaunchBlock** parameters.

*bh2* - Extra state block from state file, or NULL if none. 
This is the same block as returned from 
MSG_GEN_PROCESS_CLOSE_APPLICATION in 
some previous detach operation.

**Return:** Nothing.  
Note that the **AppLaunchBlock** is destroyed.

**Interception:** Not generally required, since the default handler broadcasts the 
message out to everything on the application's active lists. This act 
causes the interface for the application to come up on screen.

----------

#### MSG_META_ATTACH_OBJECT

`@alias (MSG_META_ATTACH)`

	void 	MSG_META_ATTACH_OBJECT(  
			word	 		flags,  
			MemHandle 		appLaunchBlock,  
			MemHandle 		extraState);

This message is sent to any object on the GenApplication object's active lists, 
or on one of those object's active lists. Note that this will not happen until the 
GenApplication is set usable by the GenProcess object.

**Source:** **GenApplicationClass** object.

**Destination:** Any object.

**Parameters:**  
*flags* - Flags providing state information.

*appLaunchBlock* - Handle of **AppLaunchBlock**, or NULL if none.

*extraState* - Handle of extra state block, or NULL if none. This 
is the same block as returned from 
MSG_GEN_PROCESS_CLOSE_APPLICATION, in 
some previous detach.

**Return:**	Nothing.

**Interception:** Standard UI objects defined as needing to be placed on an active list 
will intercept this message to do whatever it is that they needed to do 
when the application is first loaded. Objects intercepting this message 
should call the superclass, in case it expects to receive this notification 
itself.

**Warnings:** If the specific UI uses this mechanism, then the GenProcessClass will 
have already destroyed the **AppLaunchBlock** and extra state block 
by the time the MSG_META_ATTACH is sent to objects on its active list.

----------

#### MSG_META_ATTACH_THREAD

`@alias (MSG_META_ATTACH)`

	void 	MSG_META_ATTACH_THREAD();

This message is sent to any thread spawned by 
MSG_PROCESS_CREATE_EVENT_THREAD.

**Source:** Kernel.

**Destination:** Newly created thread, specifically the class designated to handle the 
thread's messages (a subclass of **ProcessClass**).

**Parameters:** None.

**Return:** Nothing.

**Interception:** No default handling provided, so if you are spawning an extra process 
and that process needs to do some initialization, then intercept this 
message.

----------

#### MSG_META_APP_STARTUP

	void	MSG_META_APP_STARTUP(
			MemHandle		appLaunchBlock);

This message is related to MSG_META_ATTACH; the message is sent by the 
generic UI to the GenApplication object before it sends MSG_META_ATTACH 
to it. MSG_META_ATTACH is only sent when the application is becoming 
available to the user; if an application should be opened as a server without 
presenting any UI to the user, MSG_META_APP_STARTUP will be the only 
message sent to the application object upon start-up.

The default handler for this message will pass it on to all members of the 
MGCNLT_APP_STARTUP list.

**Source:** **GenProcessClass**; forwarded by **GenApplicationClass** to other 
objects. This message is sent upon application start-up before the UI for 
an application has been attached.

**Destination:** Any object that needs to be notified when the application is launched, 
regardless of whether the user will be interacting with the application.

**Parameters:**  
*appLaunchBlock* - Handle of an **AppLaunchBlock**.

**Return:**	The **AppLaunchBlock** is preserved.

**Interception:** Usually intercepted by any object on the MGCNLT_APP_STARTUP list.

----------

#### MSG_META_UPDATE_WINDOW

	void	MSG_META_UPDATE_WINDOW(
			UpdateWindowFlags		updateFlags,
			VisUpdateMode		updateMode);

This message is sent as part of the system's window update mechanism. 
Typically, this message is sent to windowed objects on the 
GAGNLT_WINDOWS list when the GenApplication object becomes 
GS_USABLE. 

The message passes a bitfield of **UpdateWindowFlags**. These flags 
determine the type of action prompting the window update.

UWF_ATTACHING  
If set, the message is being sent because the application is 
attaching.

UWF_DETACHING  
If set, the message is being sent because the application is 
detaching.

UWF_RESTORING_FROM_STATE  
If set, the application is restoring from state. This flag will only 
be set if UWF_ATTACHING is also set.

UWF_FROM_WINDOWS_LIST  
If set, the message is being sent because the object is on the 
GAGCNLT_WINDOWS list, and not because it was later built on 
demand. This flag will only be set if UWF_ATTACHING is also 
set. 

**Source:** Window update mechanism.

**Destination:** Entries on the Application's GAGCNLT_WINDOWS list.

**Parameters:**  
*updateFlags* - **UpdateWindowFlags**.

*updateMode* - **VisUpdateMode**.

**Interception:** - Generally not intercepted.

----------

#### MSG_META_DETACH

	void	MSG_META_DETACH(
			word	callerID,
			optr	caller);

This message severs the links between an object and the rest of the system. 
The exact way this is handled depends on the object being detached. For full 
information on detaching objects, see "GEOS Programming," Chapter 5 of 
the Concepts Book.

The "state" of the object is left intact, in case an image of the object needs to 
be saved away in a state file for later recreation. MSG_META_DETACH sent to 
an application's process will start the process by which it is detached from the 
system, and then exited. MSG_META_DETACH is asynchronous, in that it 
need not complete its job immediately upon being called. Rather, it may take 
as much time, invoking and waiting for the completion of subsidiary detaches 
(say of child objects needing to perform special actions to detach, or of threads 
created earlier), before it responds with MSG_META_ACK to let its caller 
know that the detach has completed.

**Source:** Kernel, other objects relaying detach message.

**Destination:** GenProcess, GenApplication, objects on active lists.

**Parameters:**  
*callerID* - Object which sent message.

*caller* - Object which should be sent a MSG_META_ACK 
when detaching object has finished.

**Return:** Nothing.

**Interception:** Intercepted as a means of finding out that the application is shutting 
down. Call the superclass in case it needs such notification.
If you create additional threads, or object classes which need to be 
notified when the application is about to be exited, you may need to 
extend the detach mechanism by intercepting MSG_META_DETACH in 
a subclass of an object already receiving that message, such as 
GenApplication, GenControl, GenInteraction dialogs, etc. You must 
make sure that all objects you've sent MSG_META_DETACH to have 
responded with a MSG_META_ACK before your object can reply with 
MSG_META_ACK. Remember that your superclass may be sending 
MSG_META_DETACH. The kernel provides some default behavior in 
MetaClass, and some utility routines, to make this a simpler task. The 
default handler for MSG_META_DETACH, for instance, at a leaf object 
(one which doesn't propagate the MSG_META_DETACH), performs the 
required response (sending a MSG_META_ACK). Thus, leaf objects can 
just intercept MSG_META_DETACH for notification purposes, then call 
the superclass, and worry no more. The utility routines 
**ObjInitDetach()** and **ObjEnableDetach()** work in conjunction with 
a default MSG_META_ACK handler in **MetaClass** to keep track of how 
many outstanding acknowledgments are being waited for, and call 
MSG_META_DETACH_COMPLETE on your object once all 
acknowledgments have returned (the count reaches zero). The default 
handler for MSG_META_DETACH_COMPLETE then generates the 
acknowledgment response required of your object to complete its 
detach. You may optionally call the superclass before sending the 
detach message to your children and dependents, depending on which 
order you want things to detach in. The call to the superclass must 
happen between the **ObjInitDetach()** and **ObjEnableDetach()**, 
however.

----------

#### MSG_META_DETACH_COMPLETE

	void	MSG_META_DETACH_COMPLETE();

This message is sent to an object being detached when all of its children and 
active participants have acknowledged the detach. For full information on 
detaching objects, see "GEOS Programming," Chapter 5 of the Concepts 
Book.

MSG_META_DETACH_COMPLETE is sent to the object which called 
**ObjInitDetach()**. This will happen when as many acknowledgments have 
been received as **ObjIncDetach()** was called, and **ObjEnableDetach()** was 
called. The **MetaClass** handler for this message sends MSG_META_ACK to 
the OD passed to the **ObjInitDetach()** call. This message is provided so that 
an object will know when all of its children have detached. Note that this 
message is received only if **ObjInitDetach()** has been called for this object. 
Note also that your superclass may call **ObjInitDetach()** without your 
knowing.

**Source:** **MetaClass** handler for MSG_META_ACK, if detach count has dropped 
to zero (i.e. no outstanding requests), for objects that are detach nodes 
only (make use of **ObjInitDetach()** or **ObjEnableDetach()**).

**Destination:** Self.

**Parameters:** None.

**Return:** Nothing.

**Interception:** This is a handy message to intercept when using the **ObjInitDetach()** 
mechanism and need to know when all objects asked to detach have 
responded. Calling the superclass at this point in time will cause an 
MSG_META_ACK to go back to whatever object sent the 
MSG_META_DETACH to this object originally. There is no requirement 
to call the superclass at this time, and in fact this is a way to prolong 
the detach cycle for this object - by simply starting up another 
**ObjInitDetach()** sequence, for instance.

----------

#### MSG_META_DETACH_ABORT

	void	MSG_META_DETACH_ABORT();

This message causes a detach to be aborted. This can cause some very 
complex synchronization problems and should not be used lightly. You will 
find very little call to use it.

**Source:** Renegade object on active list, after having received 
MSG_META_DETACH, as an alternative to replying with 
MSG_META_ACK.

**Destination:** The optr passed in MSG_META_DETACH.

**Interception:** Handled by GenField to deal with applications that refuse to die, and 
GenSystem for Fields that have problem applications. Other than that, 
any detach node wishing to provide this service will have to figure out 
a way to do it itself.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_META_APP_SHUTDOWN

	void	MSG_META_APP_SHUTDOWN(
			word		callerID,
			optr		ackOD);

This message is the complement to MSG_META_APP_STARTUP. This message 
is sent to objects on the MGCNLT_APP_STARTUP list before an application 
exits but after the UI for the application is detached. Essentially, it operates 
in the same manner as MSG_META_DETACH except that the receiving object 
sends MSG_META_SHUTDOWN_ACK when its shutdown is complete.

**Source:** Sent by **GenProcessClass** after detaching the UI but before exiting 
the application; if the UI was never attached (i.e. it handled 
MSG_META_APP_STARTUP but not MSG_META_ATTACH) the UI will 
obviously not be detached.

**Destination:** Any object that needs to be notified when the application is about to 
exit.

**Parameters:**  
*callerID* - Word of data for caller's use.

*ackOD* - Optr of object to be sent 
MSG_META_SHUTDOWN_ACK.

**Interception:**	Usually intercepted by objects on the MGCNLT_APP_STARTUP list.

----------

#### MSG_META_SHUTDOWN_COMPLETE

	void	MSG_META_SHUTDOWN_COMPLETE();

This message is sent to the object that initiated the detach sequence after it 
has received MSG_META_SHUTDOWN_ACK for each **ObjIncDetach()** that 
was previously called. This message is only sent if **ObjInitDetach()** was 
previously called passing the message MSG_META_APP_SHUTDOWN.

The default handler for this message sends MSG_META_SHUTDOWN_ACK to 
the object passed in the original **ObjInitDetach()** call.

**Source:** **MetaClass** handler for MSG_META_SHUTDOWN_ACK if detach count 
reaches zero (i.e. no outstanding requests), for objects that are 
shutdown nodes only (i.e. make use of **ObjInitDetach()**.)

**Destination:** The object sends this message to itself.

**Interception:** Intercept if you are using the **ObjInitDetach()** mechanism and need 
to be notified when all objects have been notified of the detach.

----------

#### MSG_META_SHUTDOWN_ACK

	void	MSG_META_SHUTDOWN_ACK(
			word		callerID,
			optr		ackOD);

This message is sent back in response to a MSG_META_APP_SHUTDOWN. 
This message serves to notify the object the object has fulfilled the request.

**Source:** Object having received MSG_META_APP_SHUTDOWN. The default 
handler will dispatch MSG_META_SHUTDOWN_ACK after **MetaClass** 
has processed MSG_META_APP_SHUTDOWN. (You could, of course, 
intercept MSG_META_APP_SHUTDOWN and send 
MSG_META_SHUTDOWN_ACK yourself in your handler.)

**Destination:** Optr passed in MSG_META_APP_SHUTDOWN.

**Parameters:**  
*callerID* - Data passed in MSG_META_APP_SHUTDOWN.

*ackOD* - Object which has completed shutting down.

**Interception:** **MetaClass** provides default handling for this message when using the 
**ObjInitDetach()** mechanism. Objects not using this mechanism will 
want to intercept this message if there is a need to know when the 
object has completed shutting down.

----------
#### MSG_META_ACK

	void	MSG_META_ACK(
			word	callerID,
			optr	caller);

This message acknowledges a detach message. It is sent by objects that have 
been notified of another object's detach. The default handler for 
MSG_META_DETACH simply sends MSG_META_ACK back to the object that 
sent the detach message.

**Source:** Object having received MSG_META_DETACH (default handler in 
**MetaClass** will reflexively respond to any MSG_META_DETACH with a 
MSG_META_ACK, though you can change this behavior either by using 
**ObjInitDetach()** or by not letting the message get to the **MetaClass** 
handler, and responding yourself with a MSG_META_ACK sometime 
later).

**Destination:** The optr passed in MSG_META_DETACH.

**Interception:** **MetaClass** provides default handling of this message, for objects using 
the **ObjInitDetach()** mechanism. Objects not using this mechanism 
will want to intercept this if there is a need to know when the object 
asked to detach earlier has completed its detach.
MSG_META_ACK is normally inherited from **MetaClass** which calls 
**ObjEnableDetach()**. This routine decrements the detach count, and 
when that count reaches zero, sends a MSG_DETACH_COMPLETED to 
the object itself.

**Warnings:** If you are expecting a MSG_META_ACK back from anything, make sure 
you are using the mechanism initiated with **ObjInitDetach()** yourself, 
or you should handle MSG_META_ACK to prevent **MetaClass** from 
assuming you are using such a mechanism.

**Parameters:**  
*callerID* - data passed to MSG_META_ACK

*caller* - object which has completed detaching

**Return:** Nothing.

----------

#### MSG_META_BLOCK_FREE

	void	MSG_META_BLOCK_FREE();

This message initiates a sequence which will free an entire object block when 
received by any object within that block. The block will be freed when its 
in-use count reaches zero and the message queues for the block have been 
cleared.

This is a fairly low-level operation, and should be performed only after the 
objects in the block have been removed from any tree(s) they are attached to, 
and are otherwise "shut down." For generic objects, this generally means first 
calling MSG_GEN_SET_NOT_USABLE, then MSG_GEN_REMOVE_CHILD 
before using this message. For Visible objects, MSG_VIS_REMOVE will both 
visually shut down the visible tree, and then remove it from its parent.

**Source:** Unrestricted.

**Destination:** Any object within a block that is ready to have a low-level delete 
performed on it (i.e. isn't on screen, isn't linked to objects in other 
blocks, etc.).

**Interception:** Unnecessary, as **MetaClass** does the right thing.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_META_OBJ_FREE

	void	MSG_META_OBJ_FREE();

This message initiates a sequence which will free an object. The object will 
be freed after its message queues have been flushed.

This is a fairly low-level operation, and should be performed only after the 
object has been removed from any tree it is attached to and is otherwise "shut 
down." Consider using MSG_GEN_DESTROY for generic objects, 
MSG_VIS_DESTROY for visible ones.

**Source:** Unrestricted.

**Destination:** Any object within a block that is ready to have a low-level delete 
performed on it (i.e. isn't on screen, isn't linked to objects in other 
blocks, etc.).

**Interception:** Unnecessary, as **MetaClass** does the right thing.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_META_DEC_BLOCK_REF_COUNT

	void	MSG_META_DEC_BLOCK_REF_COUNT(
			MemHandle		block1,
			MemHandle		block2);

This message is a utility message to call **MemDecRefCount()** on one or two 
memory handles. 

This message is useful for IACP, which initializes the reference count to the 
number of servers returned by **IACPConnect()** and records this message as 
the message to be returned. After each server has processed its information, 
the reference count will return to zero and the handles will be freed.

**Source:** Unrestricted.

**Destination:** Any object.

**Parameters:**  
*block1* - Handle of a block whose reference count should be 
decremented, or 0 if none.

*block2* - Handle of a block whose reference count should be 
decremented, or 0 if none.

**Interception:** Generally not intercepted.

----------

#### MSG_META_OBJ_FLUSH_INPUT_QUEUE

	void	MSG_META_OBJ_FLUSH_INPUT_QUEUE(
			EventHandle					event,
			ObjFlushInputQueueNextStop	nextStop,
			MemHandle 					objBlock);

This message clears out the message queues associated with an object. This 
is rarely, if ever called from within an application, and there is little call to 
subclass it.

This queue-flushing mechanism is used in the Window, Object, and Object 
Block death mechanisms. Objects that implement their own "hold up input" 
queues must redirect this message through that queue, so that it is flushed 
as well.

**Source:** Kernel (**WinClose()**, **WinSetInfo()**, **ObjFreeObjBlock()**, 
MSG_META_OBJ_FREE, or MSG_META_BLOCK_FREE).

**Destination:** Should first be sent to the Kernel's Input Manager (See the routine 
**ImInfoInputProcess()**). The message is then relayed first to the 
System Input Object (usually the **GenSystemClass** object), then to 
the Geode Input Object (usually a **GenApplicationClass** object), and 
finally to the owning process, which dispatches the passed event.

**Parameters:**  
*event* - Event to dispatch upon conclusion of flush.

*objBlock* - Block Handle that flushing is being performed for 
(generally the handle of the destination object in 
the above event). This is the block from which the 
"OWNING GEODE", as referenced in the 
**ObjFlushInputQueueNextStop** enumerated 
type, is determined.

nextStop - **ObjFlushInputQueueNextStop** (Zero should be 
passed in call to first object, from there is 
sequenced by default **MetaClass** handler)

**Return:** Nothing.

**Structures:**  

	typedef enum {
		OFIQNS_SYSTEM_INPUT_OBJ,
		OFIQNS_INPUT_OBJ_OF_OWNING_GEODE,
		OFIQNS_PROCESS_OF_OWNING_GEODE,
		OFIQNS_DISPATCH
	} ObjFlushInputQueueNextStop;

**Interception:** Default **MetaClass** handler implements relay of message from one 
object to the next, and dispatches the passed event. Must be 
intercepted by any input-flow controlling objects (System object, 
VisContent) which implement "hold-up" queues that hold up 
input-related messages. The handlers in such cases should pipe this 
method through the hold up queue as it does with the other messages, 
and finish up when it comes out by sending this message, with all data 
intact, to the superclass for continued default processing.

#### 1.1.2.2 Class Messages

These messages are utilities that identify the class of a particular object. You 
should not subclass these. Their use is shown in "GEOS Programming," 
Chapter 5 of the Concepts Book.

----------

#### MSG_META_GET_CLASS

	ClassStruct * MSG_META_GET_CLASS();

This message returns a pointer to the **ClassStruct** structure of the recipient 
object's class.

**Source:** Unrestricted.

**Destination:** Any object.

**Parameters:** None.

**Return:** The object's class.

**Interception:** Don't.

----------

#### MSG_META_IS_OBJECT_IN_CLASS

	Boolean	MSG_META_IS_OBJECT_IN_CLASS(
	ClassStruct * class);

This message determines whether the recipient object is a member of a given 
class (or a subclass of the given class). If the return is true, the object is in the 
class. If false, the object is not in the class. If a variant class is encountered 
(when checking to see if the object is an instance of a subclass of the passed 
class), the object will not be grown out past that class in the search. If you 
want to do a complete search past variant classes, send a 
MSG_META_DUMMY first.

**Source:** Unrestricted.

**Destination:** Any object.

**Parameters:**  
*class* - Class to see if object is a member of.

**Return:**	Returns *true* if object is a member of the passed class (or a subclass), 
*false* otherwise.

**Interception:** Don't.

#### 1.1.2.3 Object Management Messages

These messages fill in and resolve an object's instance data. They should 
usually not be subclassed, and will be sent by applications infrequently (if 
ever).

----------

#### MSG_META_RESOLVE_VARIANT_SUPERCLASS

	ClassStruct * MSG_META_RESOLVE_VARIANT_SUPERCLASS(
			word	MasterOffset);

This message is sent by the object system when it needs to know the run-time 
superclass of a particular object's variant master class. The system sends this 
message to the object when it first attempts to deliver a message to the 
superclass of a variant class. The object must examine itself and determine 
what its superclass for that master level should be.

**Source:** Object system.

**Destination:** Any object with a variant class in its class hierarchy.

**Interception:** Because variant master classes tend to be strictly administrative in 
nature, providing useful and very generic functionality to their 
subclasses, all immediate children of a variant master class will need 
to intercept this message and return the appropriate class pointer.

**Parameters:**  
*MasterOffset* - Master offset of the level being resolved. If you 
know there's a variant class above your own, you 
will need to examine this to determine if it is your 
master level whose variant is being resolved, or the 
one above you.

**Return:** Superclass to use.

----------

#### MSG_META_RELOCATE

	Boolean 	MSG_META_RELOCATE(
				word		vMRelocType,
				word		frame);

This message is sent by the object system to evaluate and resolve all of the 
object's relocatable instance data fields (pointers, optrs, etc.). Note that this 
only applies if the class' CLASSF_HAS_RELOC flag is set.

NOTE: The calling of this method is non-standard in that it does not pass 
through the class's method table. Rather, the handler address is placed after 
the method table and a direct call is issued. This means a relocation routine 
should not be bound to MSG_META_RELOCATE but should rather be bound to 
**@reloc**, which Goc understands to mean the handler is for both 
MSG_META_RELOCATE and MSG_META_UNRELOCATE.

Note also that relocation-by-routine happens in addition to (but before) any 
relocation due to the class' relocation table. To suppress relocation-by-table, 
you should initialize the class record with the CLASSF_HAS_RELOC flag to 
prevent Goc from generating a table for the class.

**Source:** Kernel, when loading in object block, general resources, or object blocks 
stored in VM file format.

**Destination:** Individual object needing relocations beyond what the kernel can do 
automatically (or that simply request for this message to be sent by 
having their CLASSF_HAS_RELOC bit set)

**Interception:** Intercepted by any class needing to perform special relocations on its 
instance data. Superclass should be called, in case a superclass also 
needs to perform this operation on its own instance data.

**Parameters:**  
*vmRelocType* - Type giving some context to the relocation.

*frame* - Frame to pass to ObjRelocOrUnRelocSuper().

**Return:** If an error occurred, this will return true.

**Structures:**	

	typedef enum {
		VMRT_UNRELOCATE_BEFORE_WRITE,
		VMRT_RELOCATE_AFTER_READ,
		VMRT_RELOCATE_AFTER_WRITE,
		VMRT_RELOCATE_FROM_RESOURCE,
		VMRT_UNRELOCATE_FROM_RESOURCE
	} VMRelocType;

**Warnings:** This method may not call **LMemAlloc()**, **LMemReAlloc()**, or 
**LMemFree()**.

----------

#### MSG_META_UNRELOCATE

	Boolean 	MSG_META_UNRELOCATE(
				word		vMRelocType,
				word		frame);

This message causes an object to unresolve all its relocatable instance data 
fields, returning them to special index values.

**Source:** Kernel, when loading in object block, general resources, or object blocks 
stored in VM file format.

**Destination:** Individual object needing relocations beyond what the kernel can do 
automatically (or that simply request for this message to be sent by 
having their CLASSF_HAS_RELOC bit set).

**Interception:** Intercepted by any class needing to perform special relocations on its 
instance data. Superclass should be called, in case a superclass also 
needs to perform this operation on its own instance data.

**Parameters:**  
*vmRelocType* - Type giving some context to the relocation.

frame - Frame to pass to ObjRelocOrUnRelocSuper().

**Return:** If an error occurred, this will return true.

**Structures:**	

	typedef enum {
		VMRT_UNRELOCATE_BEFORE_WRITE,
		VMRT_RELOCATE_AFTER_READ,
		VMRT_RELOCATE_AFTER_WRITE,
		VMRT_RELOCATE_FROM_RESOURCE,
		VMRT_UNRELOCATE_FROM_RESOURCE
	} VMRelocType;

**Warnings:** This method may not call **LMemAlloc()**, **LMemReAlloc()**, or 
**LMemFree()**.

#### 1.1.2.4 User Interface Utility Meta Messages

These messages are used primarily by the User Interface. You will have very 
little call to subclass or send them.

----------

#### MSG_META_SET_FLAGS

	void 	MSG_META_SET_FLAGS(
			ChunkHandle 	objChunk,
			ObjChunkFlags 	bitsToSet,
			ObjChunkFlags 	bitsToClear);

This message sets the chunk flags for an object. The chunk flags determine 
how the object is handled with regard to state saving, dirty state, etc.

**Source:** Unrestricted.

**Destination:** Any object.

**Interception:** Unnecessary, as **MetaClass** does the right thing.

**Parameters:**  
*objChunk* - chunk to set flags for.

*bitsToSet* - bits to set.

*bitsToClear* - bits to clear.

**Return:** Nothing.

----------

#### MSG_META_GET_FLAGS

	word 	MSG_META_GET_FLAGS( /* low byte = ObjChunkFlags */
			ChunkHandle 	ch);

This message returns the chunk flags for the object. This works just like the 
ObjGetFlags() routine, but can be used when the object queried is being run 
by a different thread.

**Source:** Unrestricted.

**Destination:** Any object.

**Interception:** Unnecessary, as **MetaClass** does the right thing.

**Parameters:**  
*objChunk* - chunk to get flags for.

**Return:** Word with ObjChunkFlags in low byte, zero in high byte.

----------

#### MSG_META_QUIT

	void 	MSG_META_QUIT();

This message, when sent to a GenApplication object, initiates the shutdown 
sequence for the application. All affected objects are notified.

GenApplication does some error checking for multiple quits or detaches and 
then starts this sequence by passing MSG_META_QUIT(QL_BEFORE_UI) to 
the process. The default process handler for MSG_META_QUIT varies 
depending on the QuitLevel, which is passed in, but only when sent to the 
process (see MSG_META_QUIT_PROCESS alias, below).

The method handler for each level of quit should then send 
MSG_META_QUIT_ACK with the same QuitLevel when it is done. The 
default behavior for a process' MSG_META_QUIT responses are:

QL_BEFORE_UI - Sends MSG_META_QUIT_ACK to self via queue.

QL_UI - Sends MSG_GEN_APPLICATION_INITIATE_UI_QUIT(0) to the 
GenApplication.

QL_AFTER_UI - Sends MSG_META_QUIT_ACK to self via queue.

QL_DETACH - Sends MSG_META_DETACH to self via queue.

QL_AFTER_DETACH - Sends MSG_META_QUIT_ACK to self via queue.

The generic UI objects are first asked to quit via 
MSG_GEN_APPLICATION_INITIATE_UI_QUIT when sent to a GenApplication 
(active list). It will cause MSG_META_QUIT to be sent to all objects on the 
active list that are marked as desiring them. These objects on the active list 
can handle the MSG_META_QUIT any way they please. The process will be 
notified by a MSG_META_QUIT_ACK with the **QuitLevel** set to QL_UI.

**Source:** Unrestricted.

**Destination:** GenApplication object (note that this message has aliases so that it 
may be sent to a Process object, or any object).

**Parameters:** None.

**Return:** Nothing.

**Interception:** Unlikely.

----------

#### MSG_META_QUIT_PROCESS

`@alias (MSG_META_QUIT)`

	void 	MSG_META_QUIT_PROCESS(
			word		quitLevel,
			ChunkHandle 		ackODChunk);

For information about the quit mechanism, see MSG_META_QUIT, above.

The process's MSG_META_QUIT_ACK handler is what causes this walking 
down the **QuitList**; It provides the following behavior for each **QuitLevel**:

QL_BEFORE_UI - Sends MSG_META_QUIT(QL_UI) to self.

QL_UI - Sends MSG_META_QUIT(QL_AFTER_UI) to self.

QL_AFTER_UI - Sends MSG_META_QUIT(QL_DETACH) to self.

QL_DETACH - Sends MSG_META_QUIT(QL_AFTER_DETACH) to self.

QL_AFTER_DETACH - Sends MSG_GEN_PROCESS_FINISH_DETACH to self.

**Source:** Unrestricted.

**Destination:** Process object.

**Parameters:**  
*quitLevel* - What stage of quitting we are in.

*ackODChunk* - Acknowledgment OD to be passed on to 
MSG_META_QUIT_ACK.

**Return:** Nothing.

**Interception:** Unlikely.

**Warnings:** You cannot abort the quit at the QL_DETACH stage or later.

----------

#### MSG_META_QUIT_OBJECT

`@alias (MSG_META_QUIT)`

	void 	MSG_META_QUIT_OBJECT(
	optr 	obj);

For information about the quit mechanism, see MSG_META_QUIT, above.

**Source:** Unrestricted.

**Destination:** Process object.

**Parameters:**  
*obj* - Object to send MSG_META_QUIT_ACK to.

**Return:** Nothing.

**Interception:** Unlikely.

----------

#### MSG_META_QUIT_ACK

	void 	MSG_META_QUIT_ACK(
			word 		quitLevel,
			word 		abortFlag);

This message is sent to a Process object in response to a MSG_META_QUIT. 
The Process object handles this message by continuing the quit sequence.

**Source:** Any object having received MSG_META_QUIT

**Destination:** OD passed in MSG_META_QUIT.

**Parameters:**  
*quitLevel* - **QuitLevel** acknowledging (if responding to a 
process).

*abortFlag* - (non-zero if you want to abort the quit).

**Return:** Nothing.

**Warnings:** For processes that subclass MSG_META_QUIT, you cannot abort the 
quit at the QL_DETACH stage or later.

----------

#### MSG_META_FINISH_QUIT

	void 	MSG_META_FINISH_QUIT(
			Boolean		abortFlag);

This message is sent to the object that initiated MSG_META_QUIT and has 
received MSG_META_QUIT_ACK from each party notified. This message 
informs the object that it has finished sending out all MSG_META_QUIT 
messages and can go on with quitting (or aborting the quit if that is the case).

**Source:** Object that initiated MSG_META_QUIT.

**Destination:** Any object.

**Parameters:**  
*abortFlag* - (non-zero if you want to abort the quit).

#### 1.1.2.5 Event Messages

These messages are used to send classed events to other objects. A classed 
event is typically an event stored earlier with the Goc keyword **@record**.

----------

#### MSG_META_DISPATCH_EVENT

	Boolean	MSG_META_DISPATCH_EVENT(
			AsmPassReturn 	*retVals,
			EventHandle 	eventHandle,
			MessageFlags msgFlags););

This message causes an object to **@send** or **@call** a message of another object. 
This is useful for getting one object run by a different thread to call yet 
another object or to send a reply to the first object. This message can cause 
complex synchronization problems if not used with extreme care.

**Source:** Unrestricted.

**Destination:** Any object.

**Interception:** Unnecessary, as **MetaClass** does the right thing.

**Parameters:**  
*retValue* - structure to hold return values.

*eventHandle* - Event which will be sent.

*msgFlags* - flags which will determine how message is sent.

**Return:** If MF_CALL specified, then carry flag return value will be returned.

**Structures:**	

	typedef struct {
		word 	ax;
		word 	cx;
		word 	dx;
		word 	bp;
	} AsmPassReturn;

----------

#### MSG_META_SEND_CLASSED_EVENT

	void	MSG_META_SEND_CLASSED_EVENT(
			EventHandle	 	event,
		****	TravelOption 		whereTo);

This message is similar to several MSG_GEN_SEND_- messages defined in 
**GenClass**. This message sends a previously recorded classed event to a 
certain type of destination defined in the **TravelOption** argument *whereTo*.

This message's interesting behavior is actually added by the User Interface, 
which defines **TravelOption** types. See the message definition in **GenClass** 
for details. The default behavior provided here in **MetaClass** is to destroy 
the event if TO_NULL is passed, else to deliver the event to itself if it is 
capable of handling it (the object is a member of the class stored with the 
event). The event is always freed, whether or not it is deliverable.

**MetaClass** recognizes the following **TravelOption** values:

TO_NULL  
TO_SELF  
TO_OBJ_BLOCK_OUTPUT  
TO_PROCESS

TO_OBJ_BLOCK_OUTPUT sends the event to the object block's output set in 
its block header.

**Source:** Unrestricted.

**Destination:** Any object.

**Interception:** By default, **MetaClass** handlers deal with just the most primitive of 
the **TravelOption** values. Object classes can add new **TravelOption** 
types, but must then intercept this message to implement them (calling 
the superclass if it doesn't recognize the **TravelOption** passed).

**Parameters:**  
*event* - Classed event, probably created using **@record**.

*whereTo* - **TravelOption** describing target of message.

**Return:** Nothing.

----------

#### MSG_META_GET_OBJ_BLOCK_OUTPUT

	optr	MSG_META_GET_OBJ_BLOCK_OUTPUT();

This message returns the output optr of an object block that contains the 
object that sent the message.

**Source:** Unrestricted.

**Destination:** Any object (except a process object).

**Return:** Optr of the block's output field.

**Interception:** Generally not intercepted.

----------

#### MSG_META_SET_OBJ_BLOCK_OUTPUT

	void	MSG_META_SET_OBJ_BLOCK_OUTPUT(
			optr		output);

This message sets the object block output - the block containing the object 
that sent the message - to the passed optr. 

**Source:** Unrestricted.

**Destination:** Any object (except a process object).

**Parameters:**  
*output* - Optr of the object to act as the block's output.

**Interception:** Generally not intercepted.

----------

#### MSG_META_GET_OPTR

	optr	MSG_META_GET_OPTR();

This message returns the object's optr. This is useful when combined with 
MSG_GEN_GUP_CALL_OBJECT_OF_CLASS to get the optr of an object of a 
given class somewhere up in a Generic Tree.

Note: MSG_GEN_GUP_CALL_OBJECT_OF_CLASS dies if an object of the class 
doesn't exist. Use MSG_GEN_GUP_TEST_FOR_OBJECT_OF_CLASS before 
using MSG_GEN_GUP_CALL_OBJECT_OF_CLASS if there is some question as 
to whether an object of a given class exists.

**Source:** Unrestricted.

**Destination:** Any object.

**Interception:** Unlikely.

**Parameters:** None.

**Return:** The object's optr.

----------

#### MSG_META_GET_TARGET_AT_TARGET_LEVEL

	void	MSG_META_GET_TARGET_AT_TARGET_LEVEL(
			GetTargetParams *retValue,
			TargetLevel level);

This message returns the **GetTargetParams** structure containing, among 
other things, the current target object at a given target level. The **MetaClass** 
handler simply returns information about the current object since it is 
assumed to be the current target. See "Input," Chapter 11 of the Concepts 
Book, for information on target.

**Source:** Unrestricted.

**Destination:** Any object.

**Interception:** Must be handled by target nodes to correctly pass the request on down 
to the next target below current node in hierarchy.

**Parameters:**  
*level* - Zero for leaf, otherwise TargetLevel, as defined by 
UI.

*retValue* - Structure to hold return value.

**Return:** Nothing returned explicitly.  
*retValue* - Filled with return values.

**Structures:**

	typedef struct {
		ClassStruct 		*GTP_class;
		optr 				GTP_target;
	} GetTargetParams;

#### 1.1.2.6 Variable Data Messages

Variable data is instance data that can appear or not appear within the 
object's instance chunk. For information on variable data and how these 
three messages are used, see "GEOS Programming," Chapter 5 of the 
Concepts Book.

----------

#### MSG_META_ADD_VAR_DATA

	void	MSG_META_ADD_VAR_DATA(@stack
			word	dataType,
			word	dataSize,
			word	*data)

This message adds a variable data type to the recipient object's instance data. 
If the variable data field was already present, this will change its value. This 
is useful for adding hints to generic objects at run-time.

Note that the object will be marked dirty even if nothing was changed.

NOTE: The dataType should have VDF_SAVE_TO_STATE set as desired. 
VDF_EXTRA_DATA is ignored; it will be set correctly by this routine.

**Source:** Unrestricted.

**Destination:** Any object.

**Interception:** Generally not intercepted; default **MetaClass** handling performs the 
desired function.

**Parameters:**  
*dataType* - Data type (e.g. ATTR_PRINT_CONTROL_APP_UI).

*dataSize* - Size of data, if any.

*data* - If no extra data, NULL. If *dataSize* is non-zero, then 
this may be a pointer to data to initialize data with.

**Return:** Nothing. Object marked dirty even if data type already exists.

----------

#### MSG_META_DELETE_VAR_DATA

	Boolean	MSG_META_DELETE_VAR_DATA(
			word	dataType);

This message removes a particular variable data entry from the recipient 
object's instance data. This is useful for removing hints from generic objects 
at run-time.

**Source:** Unrestricted.

**Destination:** Any object.

**Interception:** Generally not intercepted; default **MetaClass** handling performs the 
desired function.

**Parameters:**  
*dataType* - Data type to delete. **VarDataFlags** ignored.

**Return:**	Returns false if data deleted, true if data was not found. Object marked 
dirty if data type found and deleted.

----------

#### MSG_META_INITIALIZE_VAR_DATA

	word	MSG_META_INITIALIZE_VAR_DATA(
			word	dataType);

This message is sent to an object any time the **ObjVarDerefData()** routine 
is called and the data type is not found. It should be subclassed by any object 
that defines a variable type that will be used with **ObjVarDerefData()**. The 
object must create and initialize the data and return its offset.

Sent to an object having a variable data entry which code somewhere is 
attempting to access via **ObjVarDerefData()**. It is the object that defines 
the variable data entry type's responsibility to create the data entry and 
initialize it at this time, and to return a pointer to the extra data (if any), as 
returned by **ObjVarAddData()**.

**Source:** **ObjVarDerefData()** routine. Should not be used as a replacement for 
**ObjVarAddData()**, or MSG_ADD_VAR_DATA_ENTRY, but may be used 
any time code is ready to access a particular piece of variable data 
instance data, knows that the variable data has not yet been created, 
and wishes to ensure that it does exist.

**Destination:** Any object stored in an LMem Object block.

**Interception:** Required by any class which defines a variable data entry type that 
needs to be initialized before usage. Objects handling this message 
should first compare the passed data type against variable data types 
it understands, and pass any unknown types onto the superclass for 
handling.

**Parameters:** Variable data type.

**Return:** Offset to extra data created (or, if no extra data, the start of data entry 
plus the size of **VarDataEntry**). Normally, this would just be the offset 
returned by the call to **ObjVarAddData()**.

----------

#### MSG_META_GET_VAR_DATA

	word MSG_META_GET_VAR_DATA( /* returns size of data returned in buf;
              * -1 if not found */
			word 	dataType,
			word 	bufSize,
			void 	*buf);

This message fetches variable data of a given type from an object.

**Source:** Unrestricted.

**Destination:** Any object.

**Interception:** Generally not intercepted; default **MetaClass** handling performs the 
desired function.

**Parameters:**  
*dataType* - The variable data category to return.

*bufSize* - Size available to return data.

*buf* - Pointer to buffer to hold returned data.

**Return:** The size of the data returned. If the vardata entry was not found, then 
message will return -1.

*buf* - Filled with vardata's data, if any.

#### 1.1.2.7 Notification Messages

These messages are used by the various notification mechanisms throughout 
the system.

----------

#### MSG_META_NOTIFY

	void	MSG_META_NOTIFY(
			ManufacturerID manufID,
			word	notificationType,
			word 	data);

This message notifies the recipient that some change or action has taken 
place. The object must have registered for the notification. The type of change 
that has occurred depends on the notificationType argument.

One word of notification data is allowed, but this should not reference a 
handle which must at some point be destroyed. See 
MSG_META_NOTIFY_WITH_DATA_BLOCK for such requirements.

**Source:** Unrestricted.

**Destination:** Any object, or any of the **GCNListSend()** routines.

**Interception:** No general requirements, though particular notification types may 
place restrictions or requirements on such handling.

**Parameters:**  
*manufID* - Manufacturer ID associated with notification type.

*notificationType* - What sort of notification is being announced. 

*data* - One word of data, which will be placed in a vardata 
field. If more than one word is necessary, use 
MSG_META_NOTIFY_WITH_DATA_BLOCK, below.

**Return:** Nothing.

----------

#### MSG_META_NOTIFY_WITH_DATA_BLOCK

	void	MSG_META_NOTIFY_WITH_DATA_BLOCK(
			ManufacturerID manufID,
			word	notificationType,
			MemHandle data);

This message acts like MSG_META_NOTIFY, but it also carries a handle of a 
block of data. It is absolutely imperative that if this message is subclassed, 
the object call its superclass in the handler.

The data block must be set up to use the Block "reference count" mechanism, 
i.e. be sharable and initialized with **MemInitRefCount()**. Details on the 
count are noted below.

**Source:** Unrestricted.

**Destination:** Any object, or any of the GCNListSend- routines

**Interception:** Message must eventually arrive at the **MetaClass** handler, with the 
handle to the data block with the reference count intact, in order for the 
block to be freed when no longer referenced. Failure to do so will result 
in garbage being left on the heap, which will kill the system with 
repetitive occurrences.

**Parameters:**  
*manufID* - Manufacturer ID associated with notification type.

*notificationType* - What sort of notification is being announced.

*data* - SHARABLE data block having a "reference count" 
initialized via **MemInitRefCount()**.

NOTE on data block reference counts:  
The reference count should hold the total number of references of this data 
block. This count should be incremented before sending a message holding a 
reference to this block (using **MemIncRefCount()**). Any messages passing 
such reference either must have a **MetaClass** handler which decrements 
this count and frees the block if it reaches zero or must call 
**MemDecRefCount()** (which does exactly that). **GCNListSend()** and 
similar functions add in the number of optrs in any list to which a message 
referring to this block is sent. Thus, when creating a block which will only be 
sent using **GCNListSend()**, this count should be initialized to zero. If the 
block is to be sent to one or more objects or **GCNListSend()** calls, the calling 
routine should call **MemIncRefCount()** before making the calls, being sure 
to call **MemIncRefCount()** additionally for any objects that the message is 
sent to, and then call **MemDecRefCount()** after the calls, to balance the 
increment call at the start.

**Return:** Nothing.

**Warnings:** This message must eventually reach the default **MetaClass** handler, 
so that the block can be freed when no longer referenced.

----------

#### MSG_META_GCN_LIST_ADD

	Boolean	MSG_META_GCN_LIST_ADD(@stack
			optr			dest,
			word 		listType,
			ManufacturerID 		listManuf);

This message adds the passed object to a particular notification list. It 
returns true if the object was successfully added, false otherwise. This 
message is the equivalent of **GCNListAdd()** for individual object GCN list.

**Source:** Unrestricted.

**Destination:** Object providing GCN services.

**Interception:** Unnecessary, as **MetaClass** does the right thing.

**Parameters:**  
*dest* - Object to be added to list.

*listType* - **GCNListType** to add object to.

*listManuf* - Manufacturer ID associated with GCN list.

**Return:**	Returns true if optr added, false otherwise.

----------

#### MSG_META_GCN_LIST_REMOVE

	Boolean	MSG_META_GCN_LIST_REMOVE(@stack
			optr	dest,
			word	listType,
			ManufacturerID listManuf);

This message removes the passed object from a particular notification list. It 
returns true if the object was successfully removed, false otherwise. This 
message is the equivalent of **GCNListRemove()** for an individual object's 
GCN list.

**Source:** Unrestricted.

**Destination:** Object providing GCN services.

**Interception:** Unnecessary, as **MetaClass** does the right thing.

**Parameters:**  
*dest* - Object to be removed from list.

*listType* - Which list to remove object from.

*listManuf* - Manufacturer ID associated with GCN list.

**Return:** Returns true if optr found and removed, otherwise returns false.

----------

#### MSG_META_GCN_LIST_SEND

	void	MSG_META_GCN_LIST_SEND(@stack
			GCNListSendFlags 		flags,
			EventHandle		event,
			MemHandle 		block,
			word		listType,
			ManufacturerID 		listManuf);

This message sends the given event to all objects in a particular notification 
list. The event will be freed after being sent. This message is the equivalent 
of **GCNListSend()** for an individual object GCN list.

**Parameters:**  
*flags* - Flags to pass on to GCNListSend().

*event* - Classed event to send to the list.

*block* - Handle of extra data block, if used, else NULL. This 
block must have a reference count, which may be 
initialized with **MemInitRefCount()** and 
incremented for any new usage with 
**MemIncRefCount()**. Methods in which they are 
passed are considered such a new usage, and must 
have **MetaClass** handlers which call 
**MemDecRefCount()**. 

*listType* - Which GCN list to send event to.

*listManuf* - Manufacturer ID associated with GCN list.

**Return:** Nothing.

**Structures:**  

	typedef WordFlags GCNListSendFlags;
	/* These flags may be combined using | and &:
		GCNLSF_SET_STATUS,
		GCNLSF_IGNORE_IF_STATUS_TRANSITIONING */

GCNLSF_SET_STATUS  
Additionally saves the message as the list's current "status." 
The "status" message is automatically sent to any object adding 
itself to the list at a later point in time.

GCNLSF_IGNORE_IF_STATUS_TRANSITIONING  
Optimization bit used to avoid lull in status when transitioning 
between two different sources - such as when the source is the 
current target object, and one has just lost, and another may 
soon gain, the exclusive. (The bit should be set only when 
sending the "null," "lost," or "not selected" status, as this is the 
event that should be discarded if another non-null status comes 
along shortly). Implementation is not provided by the kernel 
primitive routines, which ignore this bit, but may be provided 
by objects managing their own GCN lists. GenApplication 
responds to this bit by delaying the request until after the UI 
and application queues have been cleared, and then only sets 
the status as indicated if no other status has been set since the 
first request. Other objects may use their own logic to 
implement this optimization as is appropriate. Mechanisms 
which can not tolerate the delayed status setting nature of this 
optimization, or require that all changes are registered, should 
not pass this bit set.

----------

#### MSG_META_GCN_LIST_FIND_ITEM

	Boolean	MSG_META_GCN_LIST_FIND_ITEM(@stack
			optr		dest,
			word		listType,
			ManufacturerID		listManuf);

This message checks whether an object is on a particular GCN list.

**Source:** Unrestricted.

**Destination:** Any object providing GCN services.

**Parameters:**  
*dest* - Optr of object that we are checking.

*listType* - GCNListType.

*listManuf* - ManufacturerID.

**Return:** *true* if object is on the GCN list.

**Interception:**	Unnecessary.

----------

#### MSG_META_GCN_LIST_DESTROY

	void	MSG_META_GCN_LIST_DESTROY();

This message completely destroys the GCN setup for the caller. It frees all 
GCN lists, cached events, and overhead data storage. This should only be 
used when the object is being freed. You will likely never handle or call this 
message.

**Source:** Object providing GCN services, often in handler for 
MSG_META_FINAL_OBJ_FREE.

**Destination:** Self.

**Interception:** Unnecessary, as **MetaClass** does the right thing.

**Parameters:** Nothing.

**Return:** Nothing.

----------

#### MSG_META_NOTIFY_OBJ_BLOCK_INTERACTIBLE

	void	MSG_META_NOTIFY_OBJ_BLOCK_INTERICTABLE(
			MemHandle objBlock);

This message is sent to an object block's output object when the block changes 
from being not in-use to being in-use. An object may handle this message to 
monitor changes of in-use status.

**Source:** Kernel.

**Destination:** Object which is set as the output of an object block resource either by 
**ObjBlockSetOutput()**, or by being pre-defined in an application 
resource.

**Interception:** May be intercepted to learn about change in object block interactable 
status. No default handling is provided, though you may wish to pass 
the message onto the superclass in case it is interested in this data as 
well.

**Parameters:**  
*objBlock* - Handle of object block.

**Return:** Nothing.

----------

#### MSG_META_NOTIFY_OBJ_BLOCK_NOT_INTERACTIBLE

	void	MSG_META_NOTIFY_OBJ_BLOCK_NOT_INTERACTIBLE(
			MemHandle objBlock);

This message is sent to an object block's output object when the block changes 
from being not in-use to being in-use. An object may handle this message to 
monitor changes of in-use status.

**Source:** Kernel.

**Destination:** Object which is set as the output of an Object Block resource either by 
**ObjBlockSetOutput()**, or by being pre-defined in an application 
resource.

**Interception:** May be intercepted to learn about change in object block interactable 
status. No default handling is provided, though you may wish to pass 
the message onto the superclass in case it is interested in this data as 
well.

**Parameters:**  
*objBlock* - Handle of object block.

**Return:** Nothing.

----------

#### MSG_META_VM_FILE_DIRTY

	void	MSG_META_VM_FILE_DIRTY(
			FileHandle file);

This message is sent to all processes that have a VM file open when a block 
in the file becomes marked dirty for the first time. This is useful if many 
processes may be sharing a VM file. The VM file must be marked 
VMA_NOTIFY_DIRTY in its attributes.

**Source:** Kernel VM code.

**Destination:** ProcessClass object.

**Interception:** May be intercepted at process to do whatever is desired on this 
occurrence of this event. Default behavior in **GenProcessClass** sends 
notification to the current model **GenDocumentGroupClass** object.

***Parameters:**  
file* - Handle open to the VM file, from the receiving 
process's perspective.

Return:	Nothing.

#### 1.1.2.8 Options Messages

These messages are used by the User Interface when working with the 
GEOS.INI files. You will probably never need to subclass or call these 
messages.

----------

#### MSG_META_SAVE_OPTIONS

	void	MSG_META_SAVE_OPTIONS();

This message saves an object's options to the .INI file for an object. It is sent 
via the UI's active list mechanism.

**Source:** Unrestricted.

**Destination:** GenApplication object, which in turn broadcasts to everything on list of 
objects having options needing to be saved

**Interception:** Objects having options to save should intercept this. Superclass should 
be called in case any of the superclasses needs similar notification.

----------

#### MSG_META_LOAD_OPTIONS

	void	MSG_META_SAVE_OPTIONS();

This message loads the object's setting from the .INI file.

**Source:** Unrestricted.

**Destination:** Any object.

**Interception:** Any object that should load its options should intercept this. Behavior 
is currently implemented for Generic UI objects.

----------

#### MSG_META_RESET_OPTIONS

	void	MSG_META_RESET_OPTIONS();

This message resets the object's settings from the .INI file to their initial 
state.

**Source:** Unrestricted. Sent to all objects on the 
GAGCNLT_SELF_LOAD_OPTIONS and 
GAGCNLT_STARTUP_LOAD_OPTIONS lists.

**Destination:** Any object.

**Interception:** Any object that wants to reset its options should intercept this. 
Behavior is currently implemented for Generic UI objects.

----------

#### MSG_META_GET_INI_CATEGORY

	void	MSG_META_GET_INI_CATEGORY(
			char	*buf);

This message returns the .INI file category of the object.

**Source:** Unrestricted, though generally self.

**Destination:** Object having options.

**Interception:** Default handler walks up tree, eventually finding name of application. 
Can be intercepted at any level to change the category for a branch.

**Parameters:**  
*buf* - The buffer for .INI category string. This buffer size 
cannot store more than 64 bytes.

**Return:** Nothing returned explicitly.  
*buf* - String filled with category string.

#### 1.1.2.9 Suspending and Unsuspending

MSG_META_SUSPEND and MSG_META_UNSUSPEND work together to allow 
objects to optimize recalculation when doing a series of actions. These 
messages are implemented by various objects in the system (such as the text 
object and the grobj body). This mechanism is used by **GenControlClass** to 
optimize recalculation stemming from multiple controller outputs.

An object typically implements these messages by keeping a suspend count 
and a record of the calculations that were aborted because the object was 
suspended. When the suspend count reaches zero, the object will perform the 
calculations. 

An object implementing this mechanism should always call its superclass 
since multiple class levels could be implementing this mechanism.

----------

#### MSG_META_SUSPEND

	void 	MSG_META_SUSPEND();

Suspend calculation in an object.

**Source:** Normally sent by a controller object but can be sent by anything.

**Destination:** Any object that implements the mechanism described above.

**Interception:** An object that wants to implement the mechanism described above.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_META_UNSUSPEND 

	void 	MSG_META_UNSUSPEND();

Unsuspend calculation in an object.

**Source:** Normally sent by a controller object but can be sent by anything.

**Destination:** Any object that implements the mechanism described above.

**Interception:** An object that wants to implement the mechanism described above.

**Parameters:** None.

**Return:** Nothing.

#### 1.1.2.10 Help Files

	MSG_META_GET_HELP_FILE, MSG_META_SET_HELP_FILE, 
	MSG_META_BRING_UP_HELP

These help messages are contained within MetaClass to allow help files 
within any object in the GEOS system.

----------

#### MSG_META_GET_HELP_FILE

	void	MSG_META_GET_HELP_FILE(
			char		*buf);

This message returns the name of the help file attached to the object sent this 
message. If no help file is found, the default MetaClass handler walks up the 
tree.

**Source:** Unrestricted.

**Destination:** Object in object tree containing help.

**Parameters:**  
*buf* - Pointer to buffer to store the help file name.

**Return:** Buffer filled in.

**Interception:** The default handler walks up the tree; you may intercept to change the 
help file for a branch.

----------

#### MSG_META_SET_HELP_FILE

	void	MSG_META_SET_HELP_FILE(
			char		*buf);

This message sets the help file for the object sent this message.

**Source:** Unrestricted, though generally an object sends this to itself.

**Destination:** An object within a tree.

**Parameters:**  
*buf* - Pointer to help file name. This buffer's size must be 
at least FILE_LONGNAME_BUFFER_SIZE.

**Interception:** Generally not intercepted.

----------

#### MSG_META_BRING_UP_HELP

	void	MSG_META_BRING_UP_HELP();

This message finds a help context for the current object tree and sends a 
notification to bring up help with that context.

**Source:** Unrestricted, though generally an object sends this to itself.

**Destination:** An object within a tree.

**Interception:** The default handler for this message walks up the visual tree (not the 
generic tree) eventually finding a **GenClass** object with 
ATTR_GEN_HELP_CONTEXT. You may intercept at any level to change 
the help context for a branch.

### 1.1.3 Exported Message Ranges

**MetaClass** exports a number of ranges of messages for use by its subclasses 
(such as **GenClass** and **VisClass**) for various purposes. In most cases, you 
will not need to use any of these ranges for your own messages. The names 
of these ranges, however, are listed below. For information on exporting and 
importing message ranges, see "GEOS Programming," Chapter 5 of the 
Concepts Book.

+ MetaWindowMessages  
These messages alert a window's input object and output descriptor to 
certain important events. For example, MSG_META_EXPOSED 
announces that part of a window has been exposed and needs to be 
redrawn.

+ MetaInputMessages  
These are very low-level messages, and will only be used by those geodes 
which wish to circumvent the Input Manager. To work with the Input 
Manager correctly, see the selection messages in the MetaUIMessages 
range.

+ MetaUIMessages  
These messages may be used by objects which will interact with the UI. 
While messages for working with the Input Manager and Clipboard are 
detailed in this chapter, information on other messages may be found in 
"GenDocument," Chapter 13.

+ MetaSpecificUIMessages  
These messages are internal.

+ MetaApplicationMessages  
These messages don't have any meaning attached to them; no class 
defined in the system or any library has a handler for any of these 
messages. Any object class defined within an application may have a 
handler for any of these messages.
This message range was set up so that two or more classes defined within 
an application could agree on some message numbers. 
Thus, your application could contain the header listed below, and then 
write handlers for the message in two completely unrelated 
application-defined classes:

	@importMessage MetaApplicationMessages,  
		type0	MSG_MYAPP_DO_SOMETHING(  
				type1		arg1,  
				type2		arg2);  
	/* - \*/  
	@method MyProcessClass, MSG_MYAPP_DO_SOMETHING  
	/* -Insert Handler here \*/  
	/* - \*/  
	@method MyDocumentClass, MSG_MYAPP_DO_SOMETHING  
	/* -Insert Handler here */
+ MetaGrObjMessages  
This message range is reserved for notification messages associated with 
the graphic object library.

+ MetaPrintMessages  
For information on these messages, see "The Spool Library," Chapter 17.

+ MetaSearchSpellMessages  
These messages are sent out by the SearchReplace and Spell controllers. 
For information on these messages, see "The Text Objects," Chapter 10.

+ MetaGCNMessages  
There are several system-defined General Change Notification lists 
which objects may belong to. This message range holds those messages 
which will be sent to objects on system-defined lists.

+ MetaTextMessages  
See "The Text Objects," Chapter 10.

+ MetaStyleMessages  
See "Generic UI Controllers," Chapter 12.

+ MetaColorMessages  
See "Generic UI Controllers," Chapter 12.

+ MetaFloatMessages  
These messages are sent out by the FloatFormat controller. For 
information on these messages, see "Generic UI Controllers," 
Chapter 12.

+ MetaSpreadsheetMessages  
See "Spreadsheet Objects," Chapter 20.

+ MetaIACPMessages  
These messages are used to communicate to other objects using the 
Inter-Application Communication Protocol. IACP is discussed in 
"Applications and Geodes," Chapter 6 of the Concepts Book.

#### 1.1.3.1 Window Messages

Because many objects, both Generic UI objects and others, work together to 
control the behavior of the system windows, a number of messages have been 
set up in an exported range so that they may be shared among classes.

#### Window Update Messages

The following messages are sent to objects responsible for updating views, 
and if you subclass content objects, you may wish to intercept these 
messages.

----------

#### MSG_META_EXPOSED

	@importMessage MetaWindowMessages, void MSG_META_EXPOSED(
			WindowHandle win);

This message is sent to a Window's exposure object any time a portion of the 
window is visible on screen, has become invalid, and needs to be redrawn. 
Correct response is to create a GState on the passed window, call 
**GrBeginUpdate()** with it, redraw the window, and finish by calling 
**GrEndUpdate()** and freeing the GState. Drawing will be clipped to the 
invalid area of the window at the time that **GrBeginUpdate()** is called. 
Invalidations occurring during the redraw will result in the reduction in the 
size of the update region, and result in another MSG_META_EXPOSED being 
generated, to repair the new "invalid" area.

**Source:** Window system.

**Destination:** Individual window's exposure object; View's output descriptor.

**Interception:** Required, in order for window to be properly updated. Note that 
**VisContentClass** provides default handler which creates GState, 
calls **GrBeginUpdate()**, calls MSG_VIS_DRAW on itself, then calls 
**GrEndUpdate()**.

**Parameters:**  
*win* - Window handle which may be passed to 
**GrCreateGState**().

**Return:** Nothing.

#### Messages Sent to Objects Further Up the Input Hierarchy

The following messages are part of the high level windowing mechanism. 
Most of these messages are passed around at the GenSystem level, and most 
object classes defined by applications will not intercept them. Instead, 
system objects will intercept these messages and pass appropriate messages 
on to application objects.

----------

#### MSG_META_WIN_CHANGE

	@importMessage MetaWindowMessages, void MSG_META_WIN_CHANGE();

Sent to the System Input Object (Normally the UI's GenSystem obj), when 
the pointer position, as passed to the window system in calls to 
**WinMovePtr()**, has possibly moved outside of the window that it was in. The 
object should respond by calling **WinChangeAck()**, which will cause enter 
and leave events to be generated for all windows affected by the pointer's 
change. 

**Source:** Window system (**WinMovePtr()**).

**Destination:** System Input object (usually the GenSystem object).

**Interception:** Must be handled via call to **WinChangeAck()**.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_META_IMPLIED_WIN_CHANGE

	@importMessage MetaWindowMessages, void MSG_META_IMPLIED_WIN_CHANGE(
			optr 			inputObj,
			WindowHandle 	ptrWin);

Sent to the System Input Object (Normally the UI's GenSystem obj) in 
response to a call to **WinChangeAck()**, to inform it which window the mouse 
has moved into. The system input object is responsible for passing this 
message on to the Input object of affected geodes. 

**Source:** Window system (**WinChageAck()**).

**Destination:** Initially System Input Object (usually the **GenSystemClass** object), 
though is relayed on to Geode Input Object (usually a 
**GenApplicationClass** object).

**Interception:** May be intercepted to learn when an implied window change has 
occurred, but subclasses should not change any default functionality.

**Parameters:**  
*inputObj* - Window which has implied grab (or zero if there is 
no implied grab).

*ptrWin* - Window that pointer is in.

**Return:** Nothing.

----------

#### MSG_META_RAW_UNIV_ENTER

	@importMessage MetaWindowMessages, void MSG_META_RAW_UNIV_ENTER(
		optr 			inputObj,
		WindowHandle 	ptrWin);

This message is generated by the window system whenever the mouse 
crosses into a window. This message is sent to the window's input object. This 
is sent whenever the mouse pointer crosses a window boundary, regardless of 
any existing window grab. 

**Source:** Window system (**WinChangeAck()**).

**Destination:** Initially System input object (usually the **GenSystemClass** object), 
though is relayed on to Geode Input Object (usually a 
**GenApplicationClass** object), and finally onto individual Window's 
Input Object.

**Interception:** May be intercepted to track current status of whether mouse is within 
window or not. Specific UIs rely on these messages to control 
auto-raise, click-to-raise arming, and correct implied and active mouse 
grab interaction behavior.

**Parameters:**  
*inputObj* - Input Object of window method refers to.

*ptrWin* - Window that method refers to.

**Return:** Nothing.

----------

#### MSG_META_RAW_UNIV_LEAVE

	@importMessage MetaWindowMessages, void MSG_META_RAW_UNIV_LEAVE(
			optr 			inputObj,
			WindowHandle 	ptrWin);

This message is generated by the window system whenever the mouse 
crosses out of a window. This message is sent to the window's input object. 
This is sent whenever the mouse pointer crosses a window boundary, 
regardless of any existing window grab. 

**Source:** Window system (**WinChangeAck()**).

**Destination:** Initially System Input Object (usually the **GenSystemClass** object), 
though is relayed on to Geode Input Object (usually a 
**GenApplicationClass** object), and finally onto individual Window's 
Input Object.

**Interception:** May be intercepted to track current status of whether mouse is within 
window or not. Specific UIs rely on these messages to control 
auto-raise, click-to-raise arming, and correct implied and active mouse 
grab interaction behavior.

**Parameters:**  
*inputObj* - Input Object of window method refers to.

*ptrWin* - Window that method refers to.

**Return:** Nothing.

#### 1.1.3.2 Input Messages

These messages contain "raw" input events; events which have not yet been 
processed by the Input Manager. Most applications intercepting input events 
should intercept events which have been so processed, as described in the next section.

----------

#### MSG_META_MOUSE_BUTTON

	@importMessage MetaInputMessages, void MSG_META_BUTTON(
			word 	xPosition,
			word 	yPosition,
			word 	inputState); 

This message is sent out on any button press or release.

**Parameters:**  
*xPosition* - X-coordinate of mouse event.

*yPosition* - Y-coordinate of mouse event.

*inputState* - High byte is a ShiftState; low byte is ButtonInfo.

**Return:** Nothing.

----------

#### MSG_META_MOUSE_PTR

	@importMessage MetaInputMessages, void MSG_META_PTR(
			word 	xPosition,
			word 	yPosition,
			word 	inputState); 

This message is sent out on any mouse movement.

**Parameters:**  
*xPosition* - X-coordinate of mouse event.

*yPosition* - Y-coordinate of mouse event.

*inputState* - High byte is a ShiftState; low byte is ButtonInfo.

**Return:** Nothing.

----------

#### MSG_META_KBD_CHAR

	@importMessage MetaInputMessages, void MSG_META_KBD_CHAR(
		word 	character,
		word 	flags, /* low byte = CharFlags, high byte = ShiftState */
		word 	state);/* low byte = ToggleState, high byte = scan code */

This is the message sent out on any keyboard press or release. To determine 
whether the message is in response to a press or a release, check the 
CF_RELEASE bit of the flags field.

**Parameters:**  
*character* - Low byte contains Char value of incoming 
character.

*flags* - High byte is ShiftState; low byte is CharFlags.

*state* - High byte is raw PC scan code; low byte is 
ToggleState.

**Return:** Nothing.

----------

#### MSG_META_MOUSE_DRAG

	@importMessage MetaInputMessages, void MSG_META_MOUSE_DRAG(
			word 	xPosition,
			word 	yPosition,
			word 	inputState);

This is a very low-level message, signalling that the user is dragging the 
mouse.

**Parameters:**  
*xPosition* - X-coordinate of mouse event.

*yPosition* - Y-coordinate of mouse event.

*inputState* - High byte is a ShiftState; low byte is ButtonInfo.

**Return:** Nothing.

#### 1.1.3.3 UI Messages

The User Interface generates many messages which may alert objects to 
events which will allow them to work with the user. These events include 
those generated from the actions of input devices and clipboard-related 
events.

#### Clipboard Messages

The following messages are used to implement common clipboard functions.

----------

#### MSG_META_CLIPBOARD_CUT

	@importMessage MetaUIMessages, void 	MSG_META_CLIPBOARD_CUT();

This message is sent to an object which is supposed to be the destination of a 
clipboard operation. MSG_META_CLIPBOARD_CUT should register the 
current selection with the UI as the new clipboard item, but also delete the 
current selection. 

**Source:** Sent by anyone to perform clipboard operation.

**Destination:** Object which will support clipboard operations. By default, a 
GenEditControl sends this message to the targeted object.

**Interception:** May be intercepted to add clipboard support to existing class that 
doesn't currently have clipboard support or to enhance or replace 
functionality of object that does support the clipboard.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_META_CLIPBOARD_COPY

	@importMessage MetaUIMessages, void 	MSG_META_CLIPBOARD_COPY();

This message is sent to an object which is supposed to be the destination of a 
clipboard operation. MSG_META_CLIPBOARD_COPY should be handled by 
registering the current selection with UI as the new clipboard item.

**Source:** Sent by anyone to perform clipboard operation.

**Destination:** Object which will support clipboard operations. By default, a 
GenEditControl sends this message to the targeted object.

**Interception:** May be intercepted to add clipboard support to existing class that 
doesn't currently have clipboard support or to enhance or replace 
functionality of object that does support the clipboard.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_META_CLIPBOARD_PASTE

	@importMessage MetaUIMessages, void 	MSG_META_CLIPBOARD_PASTE();

This message is sent to an object which is supposed to be the destination of a 
clipboard operation. MSG_META_CLIPBOARD_PASTE should replace the 
current selection with the current clipboard item, which can be obtained from 
the UI.

**Source:** Sent by anyone to perform clipboard operation.

**Destination:** Object which will support clipboard operations. By default, a 
GenEditControl sends this message to the targeted object.

**Interception:** May be intercepted to add clipboard support to existing class that 
doesn't currently have clipboard support or to enhance or replace 
functionality of object that does support the clipboard.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_FEEDBACK

	@importMessage MetaUIMessages, 
		void	MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_FEEDBACK(
				ClipboardQuickNotifyFlags flags);

This message is sent to the source of a quick transfer item when a potential 
destination provides feedback to the user indicating whether a move, a copy 
or no operation will occur. The default behavior is determined by the 
destination, but the user may be able to override with the MOVE or COPY 
override keys.

**Source:** Sent by quick-transfer mechanism.

**Destination:** Sent to optr passed to **ClipboardStartQuickTransfer()**. Handled if 
the quick-transfer source needs to know what quick-transfer operation 
a potential destination will perform. Handler need not call superclass.

**Interception:** Message sent directly to destination, no need to intercept.

**Parameters:**  
*flags* - Quick transfer cursor action specified by source 
(see **ClipboardSetQuickTransferFeedback()**).

**Return:** Nothing.

----------

#### MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_CONCLUDED

	@importMessage MetaUIMessages, 
		void	MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_FEEDBACK(
				ClipboardQuickNotifyFlags 	flags);

This message is sent to the source of a quick transfer item when the 
operation is completed. The **ClipboardQuickNotifyFlags** are set by any 
MSG_META_END_MOVE_COPY handler. This is only sent out if the source 
requests notification with the CQTF_NOTIFICATION flag passed to 
**ClipboardStartQuickTransfer()**.

**Source:** Sent by quick-transfer mechanism.

**Destination:** Sent to optr passed to **ClipboardStartQuickTransfer()**. Handled if 
the quick-transfer source needs to know what quick-transfer operation 
was performed. Handler need not call superclass.

**Interception:** Message sent directly to source of transfer; no need to intercept.

**Parameters:**  
*flags* - Quick transfer cursor action specified by source 
(see **ClipboardSetQuickTransferFeedback()**).

**Return:** Nothing.

----------

#### MSG_META_CLIPBOARD_NOTIFY_TRANSFER_ITEM_FREED

	@importMessage MetaUIMessages, 
		void 	MSG_META_CLIPBOARD_NOTIFY_TRANSFER_ITEM_FREED(
				VMFileHandle 	itemFile,
				VMBlockHandle 	itemBlock);

Sent to all ODs in Transfer Notify List to help maintain integrity of transfer 
items from VM files other than the UI's transfer VM file. Only sent if VM file 
handle of transfer item that is being freed is different from UI's transfer VM 
file handle. If a transfer item from a VM file other than the UI's transfer VM 
file is registered, the VM blocks in that transfer item cannot be freed and the 
VM file cannot be closed until notification is sent saying that the transfer item 
has been freed. Registrars of such transfer items should keep track of the VM 
file handle and VM block handle of the item to check against the info sent by 
this message.

**Source:** Sent by the clipboard mechanism.

**Destination:** Sent to optrs on transfer notification list, added with 
**ClipboardAddToNotificationList()**. Handled if clipboard changes 
need to be monitored.

**Interception:** Unlikely.

**Parameters:**  
*itemFile* - File containing the transfer item.

*itemBlock* - Block containing the transfer item.

**Return:** Nothing.

----------

#### MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED

	@importMessage MetaUIMessages, 
		void 	MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED();

Sent to all ODs in Transfer Notify List to help with updating of Cut, Copy, and 
Paste button states. Recipients can call **ClipboardQueryItem()** to check if 
the new normal transfer item contains formats that the recipient supports. 
If not, Paste button can be disabled.

**Source:** Sent by the clipboard mechanism, relayed by GenEditControl.

**Destination:** Sent to optrs on transfer notification list, added with 
**ClipboardAddToNotificationList()**. Handled if clipboard changes 
need to be monitored.

**Interception:** Unlikely.

**Parameters:** None.

**Return:** Nothing.

#### Undo Messages

These messages implement the "undo" mechanism which allows objects to 
store a chain of actions which can later be undone. For more information 
about Undo, see "GenProcessClass".

----------

#### MSG_META_UNDO

	@importMessage MetaUIMessages, 
		void 	MSG_META_UNDO(AddUndoActionStruct *data);

This message is sent to an object which is supposed to be the destination of a 
clipboard operation.

**Source:** Sent by anyone to perform clipboard operation.

**Destination:** Object which will support clipboard operations. By default, a 
GenEditControl sends this message to the targeted object.

**Interception:** May be intercepted to add clipboard support to existing class that 
doesn't currently have clipboard support or to enhance or replace 
functionality of object that does support the clipboard.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_META_UNDO_FREEING_ACTION

	@importMessage MetaUIMessages,
		void 	MSG_META_UNDO_FREEING_ACTION(
				AddUndoActionStruct *data);

This message is sent to an object which is supposed to be the destination of a 
clipboard operation. This message is used to undo those actions which may 
free an important block of memory.

**Source:** Sent by anyone to perform clipboard operation.

**Destination:** Object which will support clipboard operations. By default, a 
GenEditControl sends this message to the targeted object.

**Interception:** May be intercepted to add clipboard support to existing class that 
doesn't currently have clipboard support or to enhance or replace 
functionality of object that does support the clipboard.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_META_SELECT_ALL

	@importMessage MetaUIMessages, void MSG_META_SELECT_ALL();

This message is sent to an object which is supposed to be the destination of a 
clipboard operation.

**Source:** Sent by anyone to perform clipboard operation.

**Destination:** Object which will support clipboard operations. By default, a 
GenEditControl sends this message to the targeted object.

**Interception:** May be intercepted to add clipboard support to existing class that 
doesn't currently have clipboard support or to enhance or replace 
functionality of object that does support the clipboard.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_META_DELETE

	@importMessage MetaUIMessages, void MSG_META_DELETE();

This message is sent to an object which is supposed to be the destination of a 
clipboard operation. 

**Source:** Sent by anyone to perform clipboard operation.

**Destination:** Object which will support clipboard operations. By default, a 
GenEditControl sends this message to the targeted object.

**Interception:** May be intercepted to add clipboard support to existing class that 
doesn't currently have clipboard support or to enhance or replace 
functionality of object that does support the clipboard.

**Parameters:** None.

**Return:** Nothing.

#### Input Messages

These are perhaps the most often intercepted messages, allowing objects to 
detect input events.

----------

#### MSG_META_GAINED_MOUSE_EXCL

	@importMessage MetaUIMessages, void MSG_META_GAINED_MOUSE_EXCL();

The object will receive this message when it has received the mouse 
exclusive.

----------

#### MSG_META_LOST_MOUSE_EXCL

	@importMessage MetaUIMessages, void MSG_META_LOST_MOUSE_EXCL();

The object will receive this message when it has lost the mouse exclusive.

----------

#### MSG_META_GAINED_KBD_EXCL

	@importMessage MetaUIMessages, void MSG_META_GAINED_KBD_EXCL();

The object will receive this message when it has received the keyboard 
exclusive.

----------

#### MSG_META_LOST_KBD_EXCL

	@importMessage MetaUIMessages, void MSG_META_LOST_KBD_EXCL();

The object will receive this message when it has lost the keyboard exclusive.

----------

#### MSG_META_GAINED_PRESSURE_EXCL

	@importMessage MetaUIMessages, void MSG_META_GAINED_PRESSURE_EXCL();

The object will receive this message when it has received the pressure 
exclusive, meaning it will get certain low-level mouse events.

----------

#### MSG_META_LOST_PRESSURE_EXCL

	@importMessage MetaUIMessages, void MSG_META_LOST_PRESSURE_EXCL();

The object will receive this message when it has lost the pressure exclusive.

----------

#### MSG_META_GAINED_DIRECTION_EXCL

	@importMessage MetaUIMessages, void MSG_META_GAINED_DIRECTION_EXCL();

The object will receive this message when it has received the direction 
exclusive, meaning it will get certain low-level mouse events.

----------

#### MSG_META_LOST_DIRECTION_EXCL

	@importMessage MetaUIMessages, void MSG_META_LOST_DIRECTION_EXCL();

The object will receive this message when it has lost the direction exclusive.

#### Hierarchical Messages

These messages allow object to detect changes in the makeup of the three 
hierarchies which affect the paths of input and actions within the system: the 
Focus, Target, and Model hierarchies. These hierarchies are discussed in 
"Input," Chapter 11 of the Concepts Book.

----------

#### MSG_META_GRAB_FOCUS_EXCL

	@importMessage MetaUIMessages, void MSG_META_GRAB_FOCUS_EXCL();

May be passed to any visible or generic object to cause it to become the active 
focus within its focus level. The leaf object in the hierarchy which gains the 
focus exclusive will automatically be given the keyboard exclusive, and will 
thereby receive MSG_META_KBD_CHAR events that follow.

Commonly sent to text objects and other gadgets to switch the current focus. 
May also be passed to GenPrimarys, GenDisplays, independently realizable 
GenInteractions, GenDisplayControl, GenViews, etc. (windowed things) to 
cause them to become the active focus window within their level of the focus 
hierarchy, if possible (specific UI's having real-estate focus, for instance, 
would ignore this request).

Note that the object will not actually gain the focus exclusive until all other 
nodes above it in the hierarchy also have the focus in their levels.

This is the message equivalent of HINT_DEFAULT_FOCUS on generic objects.

----------

#### MSG_META_RELEASE_FOCUS_EXCL

	@importMessage MetaUIMessages, void MSG_META_RELEASE_FOCUS_EXCL();

Opposite of MSG_META_GRAB_FOCUS_EXCL. If the object does not currently 
have the exclusive, nothing will be done.

----------

#### MSG_META_GET_FOCUS_EXCL

	@importMessage MetaUIMessages, Boolean MSG_META_GET_FOCUS_EXCL(
			optr 	*focusObject);

May be sent to any visible or generic object which is a focus node, to get 
current focus object directly below the node, if any, regardless of whether 
current node is active (has the exclusive itself).

Focus nodes in Generic UI library: GenSystem, GenField, GenApplication, 
GenPrimary, GenDisplayGroup, GenDisplay, GenView, GenInteraction 
(independently displayable only). Focus nodes in Visible UI library: 
VisContent.

**Parameters:**  
*focusObject* - This will be filled with return value, the focus 
object below the object receiving the message.

**Return:** Will return true if message responded to. Will return false if the 
message was sent to an object which is not a focus node.  
*focusObject* - The focus node under the object receiving the 
message.

**Warnings:** This is a bad way to go about sending a message to currently active 
objects. For example, if you call from the application thread to the UI 
thread to find out which is the current focus gadget and then send a 
message to it, it is possible for the active gadget to change between the 
two calls. Use MSG_META_SEND_CLASSED_EVENT for this type of 
operation if at all possible.

----------

#### MSG_META_GRAB_TARGET_EXCL

	@importMessage MetaUIMessages, void MSG_META_GRAB_TARGET_EXCL();

May be passed to any visible or generic object to cause it to become the active 
target within the target level that it is in. The active target hierarchy is the 
path for the transmission of messages via TO_TARGET request of 
MSG_META_SEND_CLASSED_EVENT.

Commonly sent to text objects and views to switch which is the current 
target. May also be passed to GenPrimarys, GenDisplays, independently 
realizable GenInteractions, GenDisplayControl, GenViews, etc. (windowed 
things) to cause them to become the active target window within their level f 
the target hierarchy.

The specific UI will automatically grab the Target exclusive for an object on 
any mouse press within the object if it is marked as GA_TARGETABLE. 

Note that the object will not actually gain the target exclusive until all other 
nodes above it in the hierarchy also have the target exclusive within their 
levels. This is the message equivalent of HINT_DEFAULT_TARGET.

----------

#### MSG_META_RELEASE_TARGET_EXCL

	@importMessage MetaUIMessages, void MSG_META_RELEASE_TARGET_EXCL();

Opposite of MSG_META_GRAB_TARGET_EXCL. If the object does not 
currently have the exclusive, nothing will be done.

----------

#### MSG_META_GET_TARGET_EXCL

	@importMessage MetaUIMessages, void MSG_META_GET_TARGET_EXCL(
			optr targetObject);

May be sent to any visible or generic object which is a target node, to get the 
current target object directly below the node, if any, regardless of whether the 
current node is active (has the exclusive itself).

Target nodes in Generic UI library: GenSystem, GenField, GenApplication, 
GenPrimary, GenDisplay, GenView, GenInteraction (independently 
displayable only). Target nodes in Visible UI library: VisContent.

**Parameters:**  
*targetObject* - This will be filled with return value, the target 
object below the object receiving the message.

**Return:** Will return true if message responded to. Will return false if the 
message was sent to an object which is not a target node.  
*targetObject* - The target node under the object receiving the 
message.

**Warnings:** This is a bad way to go about sending a message to currently active 
objects. For example, if you call from the application thread to the UI 
thread to find out which is the current target display, and then send a 
message to it, it is possible for the active display to change between the 
two calls. Use MSG_META_SEND_CLASSED_EVENT for this type of 
operation if at all possible.

----------

#### MSG_META_GRAB_MODEL_EXCL

	@importMessage MetaUIMessages, void MSG_META_GRAB_MODEL_EXCL();

May be passed to any visible or generic object to cause it to become the active 
model within the model level that it is in. The active model hierarchy is the 
override path for the transmission of messages via TO_MODEL of 
MSG_META_SEND_CLASSED_EVENT. (If no model hierarchy exists, the 
messages will be sent down the Target hierarchy.)

Note that the object will not actually gain the model exclusive until all other 
nodes above it in the hierarchy also have the model exclusive within their 
levels. This is the message equivalent of HINT_MAKE_DEFAULT_MODEL.

----------

#### MSG_META_RELEASE_MODEL_EXCL

	@importMessage MetaUIMessages, void MSG_META_RELEASE_MODEL_EXCL();

Opposite of MSG_META_GRAB_MODEL_EXCL. If the object does not currently 
have the exclusive, nothing will be done.

----------

#### MSG_META_GET_MODEL_EXCL

	@importMessage MetaUIMessages, void MSG_META_GET_MODEL_EXCL(
			optr targetObject);

May be sent to any visible or generic object which is a model node, to get 
current model object directly below the node, if any, regardless of whether 
current node is active (has the exclusive itself).

Model nodes in Generic UI library: GenSystem, GenApplication, 
GenDocumentControl, GenDocumentGroup.

**Parameters:**  
*modelObject* - This will be filled with return value, the target 
object below the object receiving the message.

**Return:** Will return true if message responded to. Will return false if the 
message was sent to an object which is not a target node.  
*modelObject* - The target node under the object receiving the 
message.

**Warnings:** This is a bad way to go about sending a message to currently active 
objects. For example, if you call from the application thread to the UI 
thread to find out which is the current model display, and then send a 
message to it, it is possible for the active display to change between the 
two calls. Use MSG_META_SEND_CLASSED_EVENT for this type of 
operation if at all possible.

----------

#### MSG_META_GAINED_FOCUS_EXCL

	@importMessage MetaUIMessages, void MSG_META_GAINED_FOCUS_EXCL();

See description for this and other gained/lost exclusive messages below.

**Special note** on MSG_META_GAINED_FOCUS_EXCL and 
MSG_META_LOST_FOCUS_EXCL: If the object receiving 
MSG_META_GAINED_FOCUS_EXCL is the leaf object in the hierarchy, 
meaning that it is either not a node itself, or if it is a node, does not have any 
object below it which has grabbed the exclusive, then the object will 
automatically be granted the MSG_META_GAINED_KBD_EXCL as well, and 
thereby receive any MSG_META_KBD_CHAR messages which are generated. 
The object will receive MSG_META_LOST_KBD_EXCL before 
MSG_META_LOST_FOCUS_EXCL.

----------

#### MSG_META_LOST_FOCUS_EXCL

	@importMessage MetaUIMessages, void MSG_META_LOST_FOCUS_EXCL();

See description for this and other gained/lost exclusive messages below.

**Special note** on MSG_META_GAINED_FOCUS_EXCL and 
MSG_META_LOST_FOCUS_EXCL: If the object receiving 
MSG_META_GAINED_FOCUS_EXCL is the leaf object in the hierarchy, 
meaning that it is either not a node itself, or if it is a node, does not have any 
object below it which has grabbed the exclusive, then the object will 
automatically be granted the MSG_META_GAINED_KBD_EXCL as well, and 
thereby receive any MSG_META_KBD_CHAR messages which are generated. 
The object will receive MSG_META_LOST_KBD_EXCL before 
MSG_META_LOST_FOCUS_EXCL.

----------

#### MSG_META_GAINED_SYS_FOCUS_EXCL

	@importMessage MetaUIMessages, void MSG_META_GAINED_SYS_FOCUS_EXCL();

See description for this and other gained/lost exclusive messages below.

----------

#### MSG_META_LOST_SYS_FOCUS_EXCL

	@importMessage MetaUIMessages, void MSG_META_LOST_SYS_FOCUS_EXCL();

See description for this and other gained/lost exclusive messages below.

----------

#### MSG_META_GAINED_TARGET_EXCL

	@importMessage MetaUIMessages, void MSG_META_GAINED_TARGET_EXCL();

See description for this and other gained/lost exclusive messages below.

----------

#### MSG_META_LOST_TARGET_EXCL

	@importMessage MetaUIMessages, void MSG_META_LOST_TARGET_EXCL();

See description for this and other gained/lost exclusive messages below.

----------

####MSG_META_GAINED_SYS_TARGET_EXCL

	@importMessage MetaUIMessages, void MSG_META_GAINED_SYS_TARGET_EXCL();

See description for this and other gained/lost exclusive messages below.

----------

#### MSG_META_LOST_SYS_TARGET_EXCL

	@importMessage MetaUIMessages, void MSG_META_LOST_SYS_TARGET_EXCL();

See description for this and other gained/lost exclusive messages below.

----------

#### MSG_META_GAINED_MODEL_EXCL

	@importMessage MetaUIMessages, void	MSG_META_GAINED_MODEL_EXCL();

See description for this and other gained/lost exclusive messages below.

----------

#### MSG_META_LOST_MODEL_EXCL

	@importMessage MetaUIMessages, void MSG_META_LOST_MODEL_EXCL();

See description for this and other gained/lost exclusive messages below.

----------

#### MSG_META_GAINED_SYS_MODEL_EXCL

	@importMessage MetaUIMessages, void MSG_META_GAINED_SYS_MODEL_EXCL();

See description for this and other gained/lost exclusive messages below.

----------

#### MSG_META_LOST_SYS_MODEL_EXCL

	@importMessage MetaUIMessages, void MSG_META_LOST_SYS_MODEL_EXCL();

These paired gained/lost messages for the Focus, Target, and Model 
hierarchies are sent, always in the order GAINED, then at some point LOST, 
to objects on the hierarchy. The GAINED message is sent only when the object 
in question and all nodes in the hierarchy above that object have gained the 
exclusive from the node above them, all the way up to the application object. 

In other words, just grabbing the exclusive from the next node up doesn't 
always guarantee you'll get a GAINED message; the node you're grabbing 
from must have itself received a GAINED message but not yet the LOST 
message. Your object will receive the LOST message if it has either released 
the exclusive, or the node from which you grabbed the exclusive itself 
received a LOST message.

The GAINED_SYS and LOST_SYS messages behave similarly, except that an 
object can only gain the SYS_EXCL (System exclusive) if it and all nodes 
above it to the GenSystem object have the grab from the next node up. An 
object will never receive a GAINED_SYS_EXCL message if it has not already 
received an (Application) GAINED_EXCL message also. Similarly, an object 
will always receive a LOST_SYS_EXCL message before it receives an 
(Application) LOST_EXCL message.

**Source:** Do not send these messages to objects yourself, unless you are 
implementing or extending the above mechanism. These messages 
should be sent only by the node object which is above the object 
receiving the message.

**Destination:** Any **MetaClass** object which has grabbed and not yet released the 
focus exclusive.

**Interception:** Generic UI objects, **VisTextClass**, and all node objects provide default 
behavior for processing this message. If you intercept above any of 
these levels, be sure to call the superclass to let these objects know the 
exclusive has been gained.

#### Miscellaneous Input Messages

----------

#### MSG_META_GRAB_KBD

	@importMessage MetaUIMessages, void MSG_META_GRAB_KBD();

This message grabs the keyboard for an object. The grab will not be taken 
away from another object if it currently has the keyboard grab. To forcefully 
grab the keyboard in this case, use MSG_META_FORCE_GRAB_KBD.

----------

#### MSG_META_FORCE_GRAB_KBD

	@importMessage MetaUIMessages, void MSG_META_FORCE_GRAB_KBD();

This message forcefully grabs the keyboard for an object, tasking the grab 
away from another object, if necessary.

----------

#### MSG_META_RELEASE_KBD

	@importMessage MetaUIMessages, void MSG_META_RELEASE_KBD();

This message releases the keyboard grab for an object.

----------

#### MSG_META_RELEASE_FT_EXCL

	@importMessage MetaUIMessages, void 	MSG_META_RELEASE_FT_EXCL();

This message releases exclusive(s) that the object may have on the Focus and 
Target hierarchies.

----------

#### MSG_META_GAINED_DEFAULT_EXCL

	@importMessage MetaUIMessages, void MSG_META_GAINED_DEFAULT_EXCL();

Sent out in response to this object receiving MSG_VIS_VUP_QUERY with 
SVQT_TAKE_DEFAULT_EXCLUSIVE, to notify a GenTrigger that it has gained 
the default exclusive.

----------

#### MSG_META_LOST_DEFAULT_EXCL

	@importMessage MetaUIMessages, void MSG_META_LOST_DEFAULT_EXCL();

Sent out in response to this object receiving MSG_VIS_VUP_QUERY with 
SVQT_RELEASE_DEFAULT_EXCLUSIVE, to notify a GenTrigger that it has 
lost the default exclusive.

----------

#### MSG_META_GAINED_FULL_SCREEN_EXCL

	@importMessage MetaUIMessages, void MSG_META_GAINED_FULL_SCREEN_EXCL();

This message is sent to GenFields or GenApplications upon gain of the 
"full-screen" exclusive. The full-screen exclusive grants the object the top 
screen-dominating object at its level.

----------

#### MSG_META_LOST_FULL_SCREEN_EXCL

	@importMessage MetaUIMessages, void MSG_META_LOST_FULL_SCREEN_EXCL();

This message is sent to GenFields or GenApplications upon loss of the 
"full-screen" exclusive. The full-screen exclusive grants the object the top 
screen-dominating object at its level.

----------

#### MSG_META_MOUSE_BUMP_NOTIFICATION

	@importMessage MetaUIMessages, void MSG_META_MOUSE_BUMP_NOTIFICATION(
			sword 	xBump,
			sword 	yBump);

This message is an event that the input manager places in the input queue 
to notify the UI that it has bumped the mouse position past this point in the 
queue. This method is sent only when **IMBumpMouse()** is called.

**Parameters:**  
*xBump* - Horizontal relative bump.

*yBump* - Vertical relative bump.

----------

#### MSG_META_FUP_KBD_CHAR

	@importMessage MetaUIMessages, Boolean MSG_META_FUP_KBD_CHAR(
			word 	character,
			word 	flags,
			word 	state);

When a leaf object in the focus hierarchy gets a MSG_META_KBD_CHAR, and 
does not care about the character, it sends this message to itself to see if a 
parent object wants to handle it.

**Parameters:**  
*character* - The low byte contains a **Char** value.

*flags* - High byte is a **ShiftState** field; low byte is a 
**CharFlags** field.

*inputState* - High byte is the raw PC scan code; low byte is a 
**ToggleState** field.

**Return:**	Will return true if the character was handled by someone (and should 
not be used elsewhere).

----------

#### MSG_META_PRE_PASSIVE_KBD_CHAR

	@importMessage MetaUIMessages, 
		KbdReturnFlags MSG_META_PRE_PASSIVE_KBD_CHAR(
			word 	character,
			word 	flags,
			word 	state);

This message sends a keyboard character to any object requesting preview of 
the keyboard events.

**Parameters:**  
*character* - The low byte contains a **Char** value.

*flags* - High byte is a **ShiftState** field; low byte is a 
**CharFlags** field.

*inputState* - High byte is the raw PC scan code; low byte is a 
**ToggleState** field.

**Return:** Flags field specifying what should happen to event.

**Structures:**

	typedef WordFlags 	KbdReturnFlags;
	#define KRF_PREVENT_PASS_THROUGH 0x8000
	/* Set for passive keyboard routines if event should
	 * be destroyed and not passed on to implied or
	 * default grab. */

----------

#### MSG_META_POST_PASSIVE_KBD_CHAR

	@importMessage MetaUIMessages, 
		KbdReturnFlags MSG_META_POST_PASSIVE_KBD_CHAR(
			word 	character,
			word 	flags,
			word 	state);

This message passes keyboard characters to all objects having registered 
interest in getting keyboard events after they have been handled.

**Parameters:**  
*character* - The low byte contains a **Char** value.

*flags* - High byte is a **ShiftState** field; low byte is a 
**CharFlags** field.

*inputState* - High byte is the raw PC scan code; low byte is a 
**ToggleState** field.

**Return:** Flags field specifying what should happen to event.

**Structures:**

	typedef WordFlags 	KbdReturnFlags;
	#define KRF_PREVENT_PASS_THROUGH 0x8000
	/* Set for passive keyboard routines if event should
	 * be destroyed and not passed on to implied or
	 * default grab. */

----------

#### MSG_META_QUERY_IF_PRESS_IS_INK

	@importMessage MetaUIMessages, 
		InkReturnValue MSG_META_QUERY_IF_PRESS_IS_INK(
			sword 	xPosition,
			sword 	yPosition);

Return whether or not a MSG_META_START_SELECT should be passed on to 
the object, or whether it should be intercepted and turned into ink.

**Source:** Sent by any object (usually VisComp) to determine if one of its children 
wants ink.

**Destination:** Any object in the Vis linkage that may be clicked on with the mouse.

**Interception:** The default handler returns IRV_NO_INK. Objects that want presses to 
be turned into ink need to return IRV_DESIRES_INK. Some objects that 
need to do work on another thread (such as a GenView) to determine 
whether the press should be ink or not can return IRV_WAIT, which 
holds up the MSG_META_START_SELECT until a 
MSG_GEN_APPLICATION_INK_QUERY_REPLY is sent to the 
application object. By default, clicks on VisComp-derived objects will 
not be ink. To change this, set **VisCompMakePressesInk()** as the 
handler for this message.

**Parameters:**  
*xPosition* - X-coordinate of selection start.

*yPosition* - Y-coordinate of selection start.

**Return:** Indication whether object thinks the press was ink.

----------

#### MSG_META_LARGE_QUERY_IF_PRESS_IS_INK

	@importMessage MetaUIMessages, 
		void MSG_META_LARGE_QUERY_IF_PRESS_IS_INK(
			InkReturnParams		*retVal,
			LargeMouseData		*largeMouseDataStruct);

This message is sent by the system to children with the 
VCNA_LARGE_DOCUMENT_MODEL bit set to determines whether or not a 
MSG_META_LARGE_START_SELECT should be processed as ink.

**Source:** Sent by any object (usually VisComp) to determine if one of its children 
wants ink.

**Destination:** Any object in the Vis linkage that may be clicked on with the mouse.

**Parameters:**  
*retVal* - Pointer to an **InkReturnParams** structure that 
will be filled in by the handler for this message.

*largeMouseDataStruct* - Pointer to a **LargeMouseData** struct that stores 
information about the large mouse event.

**Interception:** The default handler returns IRV_NO_INK. Objects that want presses to 
be turned into ink need to return IRV_DESIRES_INK. Some objects that 
need to do work on another thread (such as a VisContent) to determine 
whether the press should be ink or not can return IRV_WAIT, which 
holds up the MSG_META_LARGE_START_SELECT until a 
MSG_GEN_APPLICATION_INK_QUERY_REPLY is sent to the 
application object. 

#### Mouse Input Messages

The following messages allow an application to detect the nature and 
behavior of pointing devices within the system.

----------

#### MSG_META_START_SELECT

	@importMessage MetaUIMessages, void MSG_META_START_SELECT(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_END_SELECT

	@importMessage MetaUIMessages, void MSG_META_END_SELECT(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_START_MOVE_COPY

	@importMessage MetaUIMessages, void MSG_META_START_MOVE_COPY(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_END_MOVE_COPY

	@importMessage MetaUIMessages, void MSG_META_END_MOVE_COPY(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_START_FEATURES

	@importMessage MetaUIMessages, void MSG_META_START_FEATURES(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_END_FEATURES

	@importMessage MetaUIMessages, void MSG_META_END_FEATURES(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_START_OTHER

	@importMessage MetaUIMessages, void MSG_META_START_OTHER(
	
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_END_OTHER

	@importMessage MetaUIMessages, void MSG_META_END_OTHER(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_DRAG_SELECT

	@importMessage MetaUIMessages, void MSG_META_DRAG_SELECT(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_DRAG_MOVE_COPY

	@importMessage MetaUIMessages, void MSG_META_DRAG_MOVE_COPY(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_DRAG_FEATURES

	@importMessage MetaUIMessages, void MSG_META_DRAG_FEATURES(
			MouseReturnParams 		*retVal,
			sword 		xPosition,
			sword 		yPosition,
			word, 		inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_DRAG_OTHER

	@importMessage MetaUIMessages, void MSG_META_DRAG_OTHER(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_PRE_PASSIVE_BUTTON

	@importMessage MetaUIMessages, void MSG_META_PRE_PASSIVE_BUTTON(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_POST_PASSIVE_BUTTON

	@importMessage MetaUIMessages, void MSG_META_POST_PASSIVE_BUTTON(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_PRE_PASSIVE_START_SELECT

	@importMessage MetaUIMessages, void MSG_META_PRE_PASSIVE_START_SELECT(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_POST_PASSIVE_START_SELECT

	@importMessage MetaUIMessages, void MSG_META_POST_PASSIVE_START_SELECT(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_PRE_PASSIVE_END_SELECT

	@importMessage MetaUIMessages, void MSG_META_PRE_PASSIVE_END_SELECT(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_POST_PASSIVE_END_SELECT

	@importMessage MetaUIMessages, void MSG_META_POST_PASSIVE_END_SELECT(
			MouseReturnParams 	*retVal,
			sword 				xPosition,
			sword 				yPosition,
			word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_PRE_PASSIVE_START_MOVE_COPY

	@importMessage MetaUIMessages, 
		void MSG_META_PRE_PASSIVE_START_MOVE_COPY(
				MouseReturnParams 	*retVal,
				sword 				xPosition,
				sword 				yPosition,
				word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_POST_PASSIVE_START_MOVE_COPY

	@importMessage MetaUIMessages, 
		void MSG_META_POST_PASSIVE_START_MOVE_COPY(
				MouseReturnParams 	*retVal,
				sword 				xPosition,
				sword 				yPosition,
				word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_PRE_PASSIVE_END_MOVE_COPY

	@importMessage MetaUIMessages, 
		void MSG_META_PRE_PASSIVE_END_MOVE_COPY(
				MouseReturnParams 	*retVal,
				sword 				xPosition,
				sword 				yPosition,
				word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_POST_PASSIVE_END_MOVE_COPY

	@importMessage MetaUIMessages, 
		void MSG_META_POST_PASSIVE_END_MOVE_COPY(
				MouseReturnParams 	*retVal,
				sword 				xPosition,
				sword 				yPosition,
				word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_PRE_PASSIVE_START_FEATURES

	@importMessage MetaUIMessages, 
		void MSG_META_PRE_PASSIVE_START_FEATURES(
				MouseReturnParams 	*retVal,
				sword 				xPosition,
				sword 				yPosition,
				word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_POST_PASSIVE_START_FEATURES

	@importMessage MetaUIMessages, 
		void MSG_META_POST_PASSIVE_START_FEATURES(
				MouseReturnParams 	*retVal,
				sword 				xPosition,
				sword 				yPosition,
				word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_PRE_PASSIVE_END_FEATURES

	@importMessage MetaUIMessages, 
		void MSG_META_PRE_PASSIVE_END_FEATURES(
				MouseReturnParams 	*retVal,
				sword 				xPosition,
				sword 				yPosition,
				word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_POST_PASSIVE_END_FEATURES

	@importMessage MetaUIMessages, 
		void MSG_META_POST_PASSIVE_END_FEATURES(
				MouseReturnParams 	*retVal,
				sword 				xPosition,
				sword 				yPosition,
				word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_PRE_PASSIVE_START_OTHER

	@importMessage MetaUIMessages, 
		void MSG_META_PRE_PASSIVE_START_OTHER(
				MouseReturnParams 	*retVal,
				sword 				xPosition,
				sword 				yPosition,
				word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_POST_PASSIVE_START_OTHER

	@importMessage MetaUIMessages, 
		void MSG_META_POST_PASSIVE_START_OTHER(
				MouseReturnParams 	*retVal,
				sword 				xPosition,
				sword 				yPosition,
				word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_PRE_PASSIVE_END_OTHER

	@importMessage MetaUIMessages, 
		void MSG_META_PRE_PASSIVE_END_OTHER(
				MouseReturnParams 	*retVal,
				sword 				xPosition,
				sword 				yPosition,
				word, 				inputState);

For description of this and other button messages, see below.

----------

#### MSG_META_POST_PASSIVE_END_OTHER

	@importMessage MetaUIMessages, 
		void MSG_META_POST_PASSIVE_END_OTHER(
				MouseReturnParams 	*retVal,
				sword 				xPosition,
				sword 				yPosition,
				word, 				inputState);

The above messages are the standard button functions generated by the UI 
upon receiving MSG_META_BUTTON events from the Input Manager. These 
messages are sent out to whatever object has the implied grab (whichever 
window the mouse is over), until the mouse is "grabbed" by an object, after 
which the messages go there until the mouse is released (ungrabbed).

**Parameters:**  
*retVal* - Structure to hold return values.

*xPosition* - X-coordinate of press.

*yPosition* - Y-coordinate of press.

*inputState* - High byte is **UIFunctionsActive** structure; low 
byte is **ButtonInfo** structure.

**Structures:**

	typedef struct {
		word 				unused;
		MouseReturnFlags 	flags;
		optr 				ptrImage;
	} MouseReturnParameters;
	typedef WordFlags MouseReturnFlags;
	/* These flags may be combined using | and &:
		MRF_PROCESSED,
		MRF_REPLAY,
		MRF_PREVENT_PASS_THROUGH,
		MRF_SET_POINTER_IMAGE,
		MRF_CLEAR_POINTER_IMAGE */

----------

#### MSG_META_LARGE_PTR

	@importMessage MetaUIMessages, void MSG_META_LARGE_PTR(
		MouseReturnParams 	*retVal,
		LargeMouseData 		*largeMouseDataStruct);

See below for information about this and other large mouse messages.

----------

#### MSG_META_LARGE_START_SELECT

	@importMessage MetaUIMessages, void MSG_META_LARGE_START_SELECT(
		MouseReturnParams 	*retVal,
		LargeMouseData 		*largeMouseDataStruct);

See below for information about this and other large mouse messages.

----------

#### MSG_META_LARGE_END_SELECT

	@importMessage MetaUIMessages, void MSG_META_LARGE_END_SELECT(
		MouseReturnParams 	*retVal,
		LargeMouseData 		*largeMouseDataStruct);

See below for information about this and other large mouse messages.

----------

#### MSG_META_LARGE_START_MOVE_COPY

	@importMessage MetaUIMessages, void MSG_META_LARGE_START_MOVE_COPY(
		MouseReturnParams 	*retVal,
		LargeMouseData 		*largeMouseDataStruct);

See below for information about this and other large mouse messages.

----------

#### MSG_META_LARGE_END_MOVE_COPY

	@importMessage MetaUIMessages, void MSG_META_LARGE_END_MOVE_COPY(
		MouseReturnParams 	*retVal,
		LargeMouseData 		*largeMouseDataStruct);

See below for information about this and other large mouse messages.

----------

#### MSG_META_LARGE_START_FEATURES

	@importMessage MetaUIMessages, void MSG_META_LARGE_START_FEATURES(
		MouseReturnParams 	*retVal,
		LargeMouseData 		*largeMouseDataStruct);

See below for information about this and other large mouse messages.

----------

#### MSG_META_LARGE_END_FEATURES

	@importMessage MetaUIMessages, void MSG_META_LARGE_END_FEATURES(
		MouseReturnParams 	*retVal,
		LargeMouseData 		*largeMouseDataStruct);

See below for information about this and other large mouse messages.

----------

#### MSG_META_LARGE_START_OTHER

	@importMessage MetaUIMessages, void MSG_META_LARGE_START_OTHER(
		MouseReturnParams 	*retVal,
		LargeMouseData 		*largeMouseDataStruct);

See below for information about this and other large mouse messages.

----------

#### MSG_META_LARGE_END_OTHER

	@importMessage MetaUIMessages, void MSG_META_LARGE_END_OTHER(
		MouseReturnParams 	*retVal,
		LargeMouseData 		*largeMouseDataStruct);

See below for information about this and other large mouse messages.

----------

#### MSG_META_LARGE_DRAG_SELECT

	@importMessage MetaUIMessages, void MSG_META_LARGE_DRAG_SELECT(
		MouseReturnParams 	*retVal,
		LargeMouseData 		*largeMouseDataStruct);

See below for information about this and other large mouse messages.

----------

#### MSG_META_LARGE_DRAG_MOVE_COPY

	@importMessage MetaUIMessages, void MSG_META_LARGE_DRAG_MOVE_COPY(
		MouseReturnParams 	*retVal,
		LargeMouseData 		*largeMouseDataStruct);

See below for information about this and other large mouse messages.

----------

#### MSG_META_LARGE_DRAG_FEATURES

	@importMessage MetaUIMessages, void MSG_META_LARGE_DRAG_FEATURES(
		MouseReturnParams 	*retVal,
		LargeMouseData 		*largeMouseDataStruct);

See below for information about this and other large mouse messages.

----------

#### MSG_META_LARGE_DRAG_OTHER

	@importMessage MetaUIMessages, void MSG_META_LARGE_DRAG_OTHER(
		MouseReturnParams 	*retVal,
		LargeMouseData 		*largeMouseDataStruct);

Objects which have been set up with 32-bit coordinate spaces must be 
prepared to handle large mouse events along with regular mouse events.

These messages are available by request for use within 32-bit visible 
document models. Mouse position data is in full 32-bit integer, 16-bit fraction 
format, as generated by GenView.

**Parameters:**  
*retVal* - Structure to hold return values.

*largeMouseDataStruct* - Structure to hold pass values.

**Return:** Nothing returned explicitly.  
*retVal* - Filled with return values.

**Structures:**

	typedef struct {
		PointDWFixed 		LMD_location;
		byte 				LMD_buttonInfo;
		UIFunctionsActive 	LMD_uiFunctionsActive;
	} LargeMouseData;
	typedef struct {
		word 				unused;
		MouseReturnFlags 	flags;
		optr 				ptrImage;
		/* Pointer image to use, if MRF_SET_PTR_IMAGE
		 * returned */
	} MouseReturnParams;

----------

#### MSG_META_ENSURE_MOUSE_NOT_ACTIVELY_TRESPASSING

	@importMessage MetaUIMessages, 
		MouseReturnFlags MSG_META_ENSURE_MOUSE_NOT_ACTIVELY_TRESPASSING();

Sent to the passive, active, or implied mouse grab chain whenever modality 
status changes within the system - any object receiving this message which 
has a window grabbed should make sure that it has a legitimate right to have 
the window grab active - if not, it should be released (along with the mouse). 
In particular, menus in stay-up mode should come down, any interaction 
between the mouse and primary, display, menu, or view windows should be 
terminated. MSG_GEN_APPLICATION_TEST_WIN_INTERACTABILITY is 
useful; this message will test any passed OD against the list of window(s) 
which the mouse is allowed to interact with (Generally, top most system 
modal window, else top most application modal window, else all windows), 
and return a flag indicating the result.

**Parameters:** None.

**Return:** Flags field which system normally ignores.

----------

#### MSG_META_ENSURE_NO_MENUS_IN_STAY_UP_MODE

	@importMessage MetaUIMessages, 
	MouseReturnFlags MSG_META_ENSURE_NO_MENUS_IN_STAY_UP_MODE();

Sent to the passive, active/implied mouse grab chain whenever we want to 
make sure all of an application's menus are closed. Sent directly to the Flow 
object from the global shortcut code. Any menus receiving this message 
which are in stay-up mode should dismiss themselves.

**Parameters:** None.

**Return:** Flags field, normally ignored by system.

----------

#### MSG_META_ENSURE_ACTIVE_FT

	@importMessage MetaUIMessages, void MSG_META_ENSURE_ACTIVE_FT();

Makes sure that some object with the Focus/Target node to which this 
message may be sent has the Focus and Target exclusives. Called from 
within the UI, usually when windowed objects below the node have closed, or 
moved to the back, to give the Focus and/or Target to the most suitable 
window.

Behavior as implemented in **GenApplicationClass**:
Checks to make sure that something within the application has the Focus 
and Target exclusives. Called from within the UI, usually on the closure of a 
window, to give the Focus and/or Target to the next best location.

Typical click-to-type model is implemented using the following rules:
For Target, the priority order is:

1	Anything already having the exclusive.  
2	Top targetable PRIO_STD priority level window.  
3	Top targetable PRIO_COMMAND priority level window. 

For Focus, priority goes to:

1	Anything already having the exclusive.  
2	Top system modal window.  
3	Top application modal window.  
4	Last non-modal window to have or request the exclusive.  
5	Window having Target exclusive.  
6	Top focusable PRIO_COMMAND priority level window.

**Source:** Most always internally from the UI, though is unrestricted.

**Destination:** Focus/Target node, specifically: GenSystem, GenField, or 
GenApplication object.

**Interception:** No reason to intercept. Default behavior is provided by above objects. 
Could possibly be replaced, but as default behavior varies by specific 
UI, results could be unpredictable.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE

	@importMessage MetaUIMessages, 
		void MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE();

Notification from Focus node MSG_META_ENSURE_ACTIVE_FT handler that 
it was unable to keep/find an object below it suitable for being the focus. The 
most likely cause is that the last focusable geode/object running below this 
point has been shut down/closed.

**Source:** Focus node, MSG_META_ENSURE_ACTIVE_FT handler

**Destination:** Self

**Interception:** Intercepted to find something safe to do for the user, such as push this 
field/application to the back, or mark this object as no longer 
"focusable" and call MSG_META_ENSURE_ACTIVE_FT on the node 
above this one, in an attempt to find something for the user to access. 
If there's nothing left at all in the system, the last focusable application 
has exited, so it's time to shut down.

**Parameters:** None.

**Return:** Nothing.

#### Miscellaneous Meta Messages

----------

#### MSG_META_UI_FORCE_CONTROLLER_UPDATE

	@importMessage MetaUIMessages, 
		void MSG_META_UI_FORCE_CONTROLLER_UPDATE(
			ManufacturerID	manufID,
			word			changeID);

This message forces an object to update one or all of the GCN notification lists 
that it communicates with.

**Source:** Usually sent by a controller to its output.

**Destination:** Any object.

**Parameters:**  
*manufID* - ManufacturerID of GCN lists.

*changeID* - Notification list ID.  
This value may be 0xffffh if all notification lists 
should be updated or 0xfffeh to generate the 
standard notifications.

**Interception:** Objects that send notification for controllers should respond to this 
message.

----------

#### MSG_META_GEN_PATH_RESTORE_DISK_PROMPT

	@importMessage MetaUIMessages, 
		Boolean MSG_META_GEN_PATH_RESTORE_DISK_PROMPT(
			DiskRestoreError			*error,
			GenPathDiskRestoreArgs		*args);

This message prompts the user to insert a particular disk into a particular 
drive when restoring a disk handle for the object's path.

**Source:**	Sent by the callback passed to **DiskRestore()** when a disk handle 
saved in an object's path is being restored after a shutdown.

**Destination:** Any object possessing a path.

**Parameters:**  
*error* - Pointer to store an error code. This error code will 
be returned to **DiskRestore()**.

*args* - **GenPathDiskRestoreArgs**.

**Structures:**

	typedef struct {
		word				GPDRA_pathType;
		word				GPDRA_savedDiskType;
		char				*GPDRA_driveName;
		char				*GPDRA_diskName;
		DiskRestoreError	GPDRA_errorCode;
	} GenPathDiskRestoreArgs;

*GPDRA_pathType* stores the vardata tag holding the path.

*GPDRA_savedDiskType* stores the vardata tag holding the saved disk handle.

*GPDRA_driveName* and *GPDRA_diskName* store pointers to the 
null-terminated drive and disk names.

*GPDRA_errorCode* stores the error code that is returned to **DiskRestore()**.

**Interception:** May be intercepted if the object has more information to provide to the 
user, or if the object doesn't wish to prompt the user. If this message is 
intercepted, it should not call its superclass.

----------

#### MSG_META_PAGED_OBJECT_GOTO_PAGE

	@importMessage MetaUIMessages, void MSG_META_PAGED_OBJECT_GOTO_PAGE(
		word	page);

This message instructs a GenDocument to go to the passed page.

This message is sent out by the GenPageControl object and is handled by a 
GenApplication's subclassed GenDocument object.

**Source:** GenPageControl object.

**Destination:** GenDocument object.

**Parameters:**  
*page* - Page to set the GenDocument to display.

**Interception:** You may intercept to provide custom paging behavior.

----------

#### MSG_META_PAGED_OBJECT_NEXT_PAGE

	@importMessage MetaUIMessages, void MSG_META_PAGED_OBJECT_NEXT_PAGE();

This message instructs a GenDocument to go to the next page.

This message is sent out by the GenPageControl object and is handled by a 
GenApplication's subclassed GenDocument object.

**Source:** GenPageControl object.

**Destination:** GenDocument object.

**Interception:** You may intercept to provide custom paging behavior.

----------

#### MSG_META_PAGED_OBJECT_PREVIOUS_PAGE

	@importMessage MetaUIMessages, 
		void MSG_META_PAGED_OBJECT_PREVIOUS_PAGE();

This message instructs a GenDocument to go to the previous page.

This message is sent out by the GenPageControl object and is handled by a 
GenApplication's subclassed GenDocument object.

**Source:** GenPageControl object.

**Destination:** GenDocument object.

**Interception:** You may intercept to provide custom paging behavior.

----------

#### MSG_META_DELETE_RANGE_OF_CHARS

	@importMessage MetaUIMessages, 
		void MSG_META_DELETE_RANGE_OF_CHARS(@stack
			VisTextRange		rangeToDelete);

This message instructs an object to delete a range of characters passed in a 
**VisTextRange**. Generally, this message is sent out when the user crosses 
out characters within a HWR grid.

**Source:** GenPenInputControl.

**Destination:** Any focused object.

**Parameters:**  
*rangeToDelete* - **VisTextRange** of characters to delete. Objects that 
are not text objects will need to know how to 
interpret this value.

**Interception:** May intercept to provide custom deletion behavior.

----------

#### MSG_META_NOTIFY_TASK_SELECTED

	@importMessage MetaUIMessages, void MSG_META_NOTIFY_TASK_SELECTED();

This message is sent when a task list item of an application in the Express 
Menu is selected. The default behavior brings the application to the front and 
gives it the focus.

----------

#### MSG_META_FIELD_NOTIFY_DETACH

	@importMessage MetaUIMessages, void MSG_META_FIELD_NOTIFY_DETACH(
		optr		field,
		word		shutdownFlag);

This message is sent by the GenField object when it is detaching.

**Source:** GenField.

**Destination:** The notification destination of the GenField object.

**Parameters:**  
*field* - Optr of the GenField sending notification.

*shutdownFlag* - true if the GenField is detaching because of a 
shutdown.

**Interception:** The object receiving notification may handle as desired. As this is a 
notification only, you should not call the superclass.

----------

#### MSG_META_FIELD_NOTIFY_NO_FOCUS

	@importMessage MetaUIMessages, void MSG_META_FIELD_NOTIFY_NO_FOCUS(
		optr		field,
		word		shutdownFlag);

This message is sent by the GenField when it no longer has any applications 
in the focus hierarchy.

**Source:** GenField.

**Destination:** The notification destination of the GenField object.

**Parameters:**  
*field* - Optr of the GenField sending notification.

*shutdownFlag* - true if the GenField lost its focus applications 
because of a shutdown.

**Interception:** The object receiving notification may handle as desired. As this is a 
notification only, you should not call the superclass.

----------

#### MSG_META_FIELD_NOTIFY_START_LAUNCHER_ERROR

	@importMessage MetaUIMessages, 
		void MSG_META_FIELD_NOTIFY_START_LAUNCHER_ERROR(
			optr		field);

This message is sent by the GenField when an error occurs while attempting 
to run the launcher for the field object.

**Source:** GenField.

**Destination:** The notification destination of the GenField object.

**Parameters:**  
*field* - Optr of the GenField sending notification.

**Interception:** The object receiving notification may handle as desired. As this is a 
notification only, you should not call the superclass.

----------

#### MSG_META_TEST_WIN_INTERACTIBILITY

	@importMessage MetaUIMessages, 
		Boolean MSG_META_TEST_WIN_INTERACTIBILITY(
			optr			inputOD,
			WindowHandle	window);

This message checks whether a pointing device (usually a mouse) can 
interact with the passed window.

**Source:**	

**Destination:** A windowed object.

**Parameters:**  
*inputOD* - Input optr of the windowed object to check.

*window* - Window to check.

**Return:** true if window is interactable.

----------

#### MSG_META_CHECK_IF_INTERACTIBLE_OBJECT

	@importMessage MetaUIMessages, 
		Boolean MSG_META_CHECK_IF_INTERACTIBLE_OBJECT(
			optr	obj);

This message is sent to objects on the 
GAGCNLT_ALWAYS_INTERACTABLE_WINDOWS GCN list. 

**Source:** GenApplication object.

**Destination:** Objects on the GAGCNLT_ALWAYS_INTERACTABLE_WINDOWS GCN 
list.

**Parameters:**  
*obj* - Object whose interactable state is being checked.

**Return:** true if object is interactable.

**Interception:** May intercept.

#### 1.1.3.4 Standard GCN Messages

There are several standard messages which objects adding themselves to the 
appropriate GCN lists may receive and handle.

----------

#### MSG_NOTIFY_FILE_CHANGE

	@importMessage MetaGCNMessages, void MSG_NOTIFY_FILE_CHANGE(
			MemHandle 		data);

This notification is sent out whenever the file system changes in any way.

**Source:** GCN mechanism.

**Destination:** Object on the GCNSLT_FILE_SYSTEM GCN list.

**Parameters:**  
*data* - Handle of a **FileChangeNotificationData** block.

**Return:** Nothing.

**Structures:**

	typedef struct {
		PathName			FCND_pathname;
		DiskHandle			FCND_diskHandle;
		FileChangeType		FCND_changeType;
	} FileChangeNotificationData;
	typedef ByteEnum FileChangeType;
	/* These flags may be combined using | and &:
		FCT_CREATE
		FCT_DELETE
		FCT_RENAME
		FCT_CONTENTS
	FCT_DISK_FORMAT */

----------

#### MSG_NOTIFY_DRIVE_CHANGE

	@importMessage MetaGCNMessages, void MSG_NOTIFY_DRIVE_CHANGE(
		GCNDriveChangeNotificationType 		type,
		word 								driveNum);

This is sent to notify various system utilities that a drive has been created or 
destroyed or has changed ownership from one installable file system driver 
to another.

Note that during system initialization, the ownership of a drive may change 
several times as more-specialized drivers are loaded. This means the 
recipient should not be surprised if it's told a drive has been created that it 
thought already existed.

**Source:** The kernel issues this notification whenever a filesystem driver creates 
or destroys a drive it manages. This includes when a specialized 
filesystem driver takes control of an existing drive.

**Destination:** Any object that has added itself to the GCNSLT_FILE_SYSTEM GCN list. 
It is intended for system objects, such as the GenFileSelector.

**Parameters:**  
*type* - **GCNDriveChangeNotificationType**.

*driveNum* - Number of the affected drive.

**Return:** Nothing.

----------

#### MSG_NOTIFY_APP_STARTED

	@importMessage MetaGCNMessages, void MSG_NOTIFY_APP_STARTED();

This message is sent out when an application attaches to the UI.

**Source:** GCN Mechanism.

**Destination:** Any object on the GCNSLT_APPLICATION system GCN list.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_NOTIFY_APP_EXITED

	@importMessage MetaGCNMessages, void MSG_NOTIFY_APP_EXITED();

This message is sent out when an application thread exits.

**Source:** GCN Mechanism.

**Destination:** Any object on the GCNSLT_APPLICATION system GCN list.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_NOTIFY_DATE_TIME_CHANGE

	@importMessage MetaGCNMessages, void MSG_NOTIFY_DATE_TIME_CHANGE();

This message is sent out when the date or time changes - whenever the 
system comes back or the system time is altered (e.g. by the User in 
Preferences). 

**Source:** GCN Mechanism.

**Destination:** Any object on the GCNSLT_DATE_TIME system GCN list.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_NOTIFY_USER_DICT_CHANGE

	@importMessage MetaGCNMessages, void MSG_NOTIFY_USER_DICT_CHANGE(
			MemHandle 		sendingSpellBox,
			MemHandle 		userDictChanged);

This message is sent out when an application attaches to the UI.

**Source:** GCN Mechanism.

**Destination:** Any object on the GCNSLT_DICTIONARY system GCN list.

**Parameters:**  
*sendingSpellBox* - Handle of SpellBox that sent out the notification.

*userDictChanged* - Handle of user dictionary that changed.

**Return:** - Nothing.

----------

#### MSG_NOTIFY_KEYBOARD_LAYOUT_CHANGE

	@importMessage MetaGCNMessages, 
			void MSG_NOTIFY_KEYBOARD_LAYOUT_CHANGE();

This message is sent out when the keyboard layout is changing. Usually this 
involves a change in status of the floating keyboard. When passing this event 
to **GCNListSend()**, you must be sure to pass the GCNLSF_FORCE_QUEUE 
flag. (Otherwise, if you have a **GenPenInputControl** running on the same 
thread, it may try to remove itself from the list while you are sending this 
message.)

**Source:** GCN Mechanism.

**Destination:** Any object on the GCNSLT_KEYBOARD_OBJECT system GCN list.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_NOTIFY_EXPRESS_MENU_CHANGE

	@importMessage MetaGCNMessages, void MSG_NOTIFY_EXPRESS_MENU_CHANGE(
			GCNExpressMenuNotificationTypes 	type,
			optr 								affectedField);

This message is sent to notify various system utilities that an express menu 
has been created or destroyed. The recipient receives the optr of the field to 
which the affected express menu belongs, as all access to the express menu 
is via messages sent to the field.

**Source:** The UI issues this notification whenever a GenField object creates or 
destroys its express menu.

**Destination:** Any object that has added itself to the GCNSLT_EXPRESS_MENU. GCN 
list. It is intended for system utilities, such as the print spooler or a 
task-switching driver, that need to add objects to each express menu in 
the system.

**Parameters:**  
*type* - What happened to the field.

*affectedField* - Which field of the menu was affected. (This will not 
be the optr of the express menu itself.)

**Return:** Nothing.

**Structures:**	

	typedef enum {
		GCNEMNT_CREATED,
		GCNEMNT_DESTROYED
	} GCNExpressMenuNotificationTypes;

----------

#### MSG_PRINTER_INSTALLED_REMOVED

	@importMessage MetaGCNMessages, 
			void MSG_PRINTER_INSTALLED_REMOVED();

This message is sent whenever a printer is installed or removed. The 
recipient of this message might call **SpoolGetNumPrinters()** to determine 
if any printers or fax machines are currently installed.

**Source:** GCN Mechanism.

**Destination:** Any object on the GCNSLT_INSTALLED_PRINTERS system GCN list.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_META_CONFIRM_SHUTDOWN

	@importMessage MetaGCNMessages, void MSG_META_CONFIRM_SHUTDOWN(
			GCNShutdownControlType 		type);

This message is sent out when the system is about to shut down.

All applications which need to keep the system from shutting down must add 
themselves to GCNSLT_SHUTDOWN_CONTROL and handle this message.

**Source:** The task switch mechanism, through GCN.

**Destination:** Any object on the GCNSLT_SHUTDOWN_CONTROL system GCN list.

**Parameters:** None.

**Return:** Nothing.

**Interception:** If the system is about to be suspended or shut down (if the passed 
**GCNShutDownControlType** is GCNSCT_SUSPEND or 
GCNSCT_SHUTDOWN), then any object receiving this message must 
call **SysShutdown()**, passing SST_CONFIRM_START before it puts up 
any dialog box it uses to ensure the user isn't doing something foolish. 
If **SysShutdown()** returns true (indicating something has already 
denied the shutdown request), the caller should not put up its 
confirmation box, nor need it call **SysShutdown()** again.
Once the object has received a response from the user, either 
affirmative or negative, it must call **SysShutdown()**, passing 
SST_CONFIRM_ACK or SST_CONFIRM_DENY as appropriate. This will 
allow any other confirmations to happen, as well as sending the final 
result to the original caller of **SysShutdown()**.
If the passed control type is GCNSCT_UNSUSPEND, no response is 
required.

#### 1.1.3.5 IACP Meta Messages

IACP is fully discussed in "Applications and Geodes," Chapter 6 of the 
Concepts Book.

#### MSG_META_IACP_PROCESS_MESSAGE

	@importMessage MetaIACPMessages, void MSG_META_IACP_PROCESS_MESSAGE(
			EventHandle		msgToSend,
			TravelOption	topt,
			EventHandle		completionMsg);

This message dispatches an IACP message to its proper destination, sending 
a completion message back when that has finished.

**Source:** **IACPSendMessage()**.

**Destination:** Any object registered as an IACP server, or the GenApplication object 
of a geode that is a client of such a server.

**Parameters:**  
*msgToSend* - EventHandle of recorded message that the other 
side of the connection is actually sending.

*topt* - **TravelOption** (or -1 if msgToSend should be 
dispatched via **MessageDispatch()** or delivered 
via MSG_META_SEND_TO_CLASSED_EVENT.

*completionMsg* - **EventHandle** of recorded message to send when 
the message in msgToSend has been handled. If 
null, then no completion message will be sent.

**Interception:** if you have an object other than the GenApplication object that is an 
IACP server, you will need to intercept this message. You do not want 
to pass it on to the superclass in this case; usually, you will just want 
to call **IACPProcessMessage()**.

----------

#### MSG_META_IACP_NEW_CONNECTION

	@importMessage MetaIACPMessages, void MSG_META_IACP_NEW_CONNECTION(
			MemHandle			appLaunchBlock,
			Boolean				justLaunched,
			IACPConnection		connection);

This message informs servers that a new client has connected to the server.

**Source:** **IACPConnect()**.

**Destination:** - Any object registered as an IACP server.

**Parameters:**  
*appLaunchBlock* - Handle of **AppLaunchBlock** passed to 
**IACPConnect()**. Do not free this block.

*justLaunched* - true if the recipient was just launched (i.e. it 
received the **AppLaunchBlock** in its 
MSG_META_ATTACH call).

*connection* - **IACPConnection** that is now open.

**Interception:** Must intercept if you want to do anything about receiving the new 
client; there is not default handler for this message. If you do not 
intercept this message, no harm is done.

----------

#### MSG_META_IACP_LOST_CONNECTION

	@importMessage MetaIACPMessages, void MSG_META_IACP_LOST_CONNECTION(
			IACPConnection		connection,
			word				serverNum);

This message informs a server (or client) that one of its clients (or servers) 
has shut down.

**Source:**	**IACPShutdown()**.

**Destination:** Any object registered as an IACP server, or the GenApplication object 
of a geode who is a client of such.

**Parameters:**  
*connection* - IACPConnection being closed.

*serverNum* - Server number that shut down, or 0 if this was a 
client that shut down (and thus it is a server being 
notified through this message).

**Interception:** Must be intercepted to provide custom behavior upon losing a 
connection, as there is no default handler for this message. 
**IACPLostConnection()** is a good routine for servers to call to ensure 
that connections don't linger after a client has shut down its end.

----------

#### MSG_META_IACP_SHUTDOWN_CONNECTION

	@importMessage MetaIACPMessages, 
			void MSG_META_IACP_SHUTDOWN_CONNECTION(
				IACPConnection		connection);

This message shuts down the appropriate side of the indicated connection.

**Source:** **IACPLostConnection()**, though after a delay.

**Destination:** Any IACP server object.

**Parameters:**  
*connection* - **IACPConnection** to shutdown.

**Interception:** Must be intercepted to finish the work of a call to 
**IACPLostConnection()**. Call **IACPShutdownConnection()** to get 
default handling of this message.

----------

#### MSG_META_IACP_DOC_OPEN_ACK

	@importMessage MetaIACPMessages, void MSG_META_IACP_DOC_OPEN_ACK(
			IACPDocOpenAckParams		*params);

This message is sent when a document has been opened; the document must 
have previously been passed in the **AppLaunchBlock** when the IACP 
connection was made. The optr of the GenDocument object managing the 
document is passed so that messages can be sent to it explicitly, though these 
messages must always be sent via IACP (with a **TravelOption** of -1) to allow 
the application to exit at any time.

**Source:** GenDocumentGroup.

**Destination:** IACP client (usually the GenApplication object of the client 
application).

**Parameters:**  
*params* - Pointer to an **IACPDocOpenAckParams** 
structure.

**Structures:**

	typedef struct {
		optr				IDOAP_docObj;
		IACPConnection		IDOAP_connection;
		word				IDOAP_serverNum;
	} IACPDocOpenAckParams;

*IDOAP_docObj* stores the optr of the document object managing the 
document.

*IDOAP_connection* stores the **IACPConnection** over which the open request 
was received.

*IDOAP_serverNum* stores the server number of the GenApplication object 
acting as the document object's server, or zero if the connection is through 
some other object.

**Interception:** No default handler is defined. You must intercept this message to 
provide custom behavior.

----------

#### MSG_META_IACP_DOC_CLOSE_ACK

	@importMessage MetaIACPMessages, void MSG_META_IACP_DOC_CLOSE_ACK(
			IACPDocCloseAckParams		*params);

This message acts as the acknowledgment sent by a GenDocument object 
after it successfully processes MSG_GEN_DOCUMENT_CLOSE. Documents 
opened via IACP always operate in transparent mode; i.e. if you close a dirty 
file, it will be saved. If you don't want this behavior, you will have to send a 
message to revert the document.

**Source:** GenDocument object.

**Destination:** IACP client.

**Parameters:**  
*params* - Pointer to a **IACPDocCloseAckParams** 
structure.

**Structures:**	

	typedef struct {
		optr				IDCAP_docObj;
		IACPConnection		IDCAP_connection;
		word				IDCAP_serverNum;
		word				IDCAP_status;
	} IACPDocCloseAckParams;

*IDCAP_docObj* stores the optr of the document object that was managing the 
document.

*IDCAP_connection* stores the **IACPConnection** over which the close request 
was received.

*IDCAP_serverNum* stores the server number of the GenApplication object 
acting as the document object's server, or zero if the connection is through 
some other object.

*IDCAP_status* stores the **DocQuitStatus** of the close operation.

**Interception:** No default handler is defined. You must intercept this message to 
provide custom behavior.

## 1.2 ProcessClass

**ProcessClass** implements all the functionality for creating and managing 
the process aspect of a geode. It creates the process thread and associated 
message queues. **ProcessClass** is a subclass of **MetaClass** and is the 
superclass of **GenProcessClass**, below. You will probably not use 
**ProcessClass** directly, but you will almost certainly use **GenProcessClass**.

Those rare geodes which will use this class probably won't explicitly declare 
a Process object, but instead pass **ProcessClass** as an argument to that 
function as discussed in Appendix B of the Concepts manual.

**ProcessClass** has no instance data fields of its own. The messages defined 
by it are listed below:

----------

#### MSG_PROCESS_NOTIFY_PROCESS_EXIT

	void	MSG_PROCESS_NOTIFY_PROCESS_EXIT(
			GeodeHandle 		exitProcess,
			word				exitCode);

This is sent to a Process object when one of its child processes exits. Many 
types of processes do not need to know when a child process exists; these 
processes need not handle this message.

**Source:** Kernel

**Destination:** Process of creating geode of child process exiting.

**Parameters:** This message is provided as notification only, i.e. there is no default 
handling of it. May be intercepted as desired.

**Parameters:**  
*exitProcess* - Child process that exited.

*exitCode* - Exit code. May be an error code.

**Return:**	Nothing.

----------

#### MSG_PROCESS_NOTIFY_THREAD_EXIT

	void	MSG_PROCESS_NOTIFY_THREAD_EXIT(
			ThreadHandle		exitProcess,
			word				exitCode);

This message is sent to a Process object when a thread owned by it (via the 
**ThreadCreate()** routine) exits.

**Source:** Kernel.

**Destination:** Process owning thread which is exiting.

**Interception:** This message is provided as notification only (i.e. there is no default 
handling of it). May be intercepted as desired.

**Parameters:**  
*exitProcess* - Handle of thread that exited.

*exitCode* - Exit code (may be an error code).

**Return:**	Nothing.

----------

#### MSG_PROCESS_MEM_FULL

	void	MSG_PROCESS_MEM_FULL(
			word 	type);

This message is sent to a Process object by the memory manager when the 
heap is getting full. A Process object receiving this message should try to free 
memory (or mark it discardable) if possible.

**Source:** Kernel's heap manager.

**Destination:** All processes.

**Interception:** Any process which can adjust the amount of memory that it is using 
should respond to this message by reducing its demands on the system 
heap. For instance, buffers or UI object trees kept purely for 
performance reasons could be freed or reduced in number.

**Parameters:**  
*type* - HeapCongestion.

**Return:** Nothing.

**Structures:**

	typedef enum {
		/* HC_SCRUBBING: 
		 * Heap is being scrubbed. */
		HC_SCRUBBING,
		/* HC_CONGESTED:
		 * Scrubber couldn't free a satisfactory 
		 * amount of memory. */
		HC_CONGESTED,
		/* HC_DESPERATE:
		 * Heap is perilously close to overflowing. */
		HC_DESPERATE
	} HeapCongestion;

----------

#### MSG_PROCESS_CREATE_UI_THREAD

	Boolean		MSG_PROCESS_CREATE_UI_THREAD(
				ThreadHandle		*newThread,
				ClassStruct 		*class,
				word 				stackSize);

This is a low-level utility message requesting that the process create the UI 
thread for an application. Does nothing more than 
MSG_PROCESS_CREATE_EVENT_THREAD, but is split out to allow for 
interception or to change class or stack size.

**Source:** First thread of application process if geode has one or more resources 
marked as "ui-object" blocks.

**Destination:** First thread of application process.

**Interception:** May be intercepted to change class or stack size before calling 
superclass, or to replace default handling completely.

**Parameters:**  
*newThread* - Pointer to a **ThreadHandle** buffer to store the 
created thread handle.

*class* - Object class for the new thread. If you don't have 
any special messages to handle in this thread, 
besides those intended for objects run by the 
thread, you can just specify **ProcessClass** as the 
object class.

*stackSize* - Stack size for the new thread (3K bytes is probably 
reasonable).

**Return:** true if the thread was not created because of some problem.

**Warnings:** Be careful of deadlock situations.

----------

#### MSG_PROCESS_CREATE_EVENT_THREAD

	Boolean		MSG_PROCESS_CREATE_EVENT_THREAD(
				ThreadHandle		*newThread
				ClassStruct 		*class,
				word				stackSize);

This message is a utility that creates a new event-driven thread owned by the 
recipient Process object. Typically, a Process object will send this message to 
itself when it needs an additional event thread. (It cannot be used to create 
a non-event driven thread. Use **ThreadCreate()** for this purpose instead.) 
This is implemented at ProcessClass and takes care of all the details of 
creating a new event-driven thread. The thread will always receive a 
MSG_META_ATTACH as its first event.

**Source:** Unrestricted.

**Destination:** Any process. This process will own the thread.

**Interception:** Not necessary, as the default handler provides the message's utility.

**Parameters:**  
*newThread* - Pointer to a **ThreadHandle** buffer to store the 
created thread handle.

*class* - Object class for the new thread. If you don't have 
any special messages to handle in this thread 
besides those intended for objects run by the 
thread, you can just specify **ProcessClass** as the 
object class.

*stackSize* - Stack size for the new thread. 512 bytes is probably 
reasonable. If the thread will be running any 
objects that can undergo keyboard navigation (like 
dialog boxes and triggers and so forth), you'll 
probably want to make it 1K. The kernel already 
adds some extra space for handling interrupts 
(about 100 bytes).

**Return:** true if the thread was not created because of some problem.

**Warnings:** Be careful of deadlock situations.

## 1.3 GenProcessClass


**GenProcessClass** is the class that you will use to define the Process object 
of your applications. This class includes some functionality for opening and 
closing geodes as well as saving to and restoring from state files. Typically, 
your application will define its own subclass of **GenProcessClass**; this 
subclass will be used as your Process object and will receive all messages 
destined for the Process.

In this subclass you can alter the **GenProcessClass**, **ProcessClass**, or 
**MetaClass** messages you need. More often, however, the subclass will be 
used to define new messages that are application-global or that should be 
handled by your Process object.

### 1.3.1 Starting and Stopping

For information about the steps involved in stopping, starting, or restoring 
an application (and to get context information about the messages described 
below), see "GEOS Programming," Chapter 5 of the Concepts Book.

Many of the following messages need AppAttachFlags to tell them how the 
process is attaching:

	typedef WordFlags AppAttachFlags;
	#define AAF_RESTORING_FROM_STATE		0x8000
	#define AAF_STATE_FILE_PASSED			0x4000
	#define AAF_DATA_FILE_PASSED			0x2000
	#define AAF_RESTORING_FROM_QUIT			0x1000

+ AAF_RESTORING_FROM_STATE indicates that the application is coming 
up from a previous state, either by re-launching using a state file, or 
re-entering application mode from engine mode in the same session. The 
UI trees will be in whatever state they were left in, which may be 
different than the statically declared UI tree, depending on what 
occurred in the application when the state file was written out (for 
example, a dialog box may have been on-screen). If this flag is false, the 
application is starting up fresh. If this flag is true, the UI does not call 
MSG_META_LOAD_OPTIONS and ignores any "ON_STARTUP" hints or 
attributes.

+ AAF_STATE_FILE_PASSED indicates that the application is restoring 
from the state file passed in an **AppLaunchBlock**, presumably passed 
as an argument in the message also. If this flag is set, 
AAF_RESTORING_FROM_STATE will also be set.

+ AAF_DATA_FILE_PASSED indicates that the passed **AppLaunchBlock** 
contains the name of a data file that should be opened.

+ AAF_RESTORING_FROM_QUIT indicates that the application was in the 
process of quitting, reached engine mode, and is now being started back 
up into application mode. If set, will also be set, and we will be brought 
up in whatever state we originally entered engine mode.

----------

#### MSG_GEN_PROCESS_RESTORE_FROM_STATE

	void 	MSG_GEN_PROCESS_RESTORE_FROM_STATE(
			AppAttachFlags 		attachFlags,
			MemHandle 			launchBlock,
			MemHandle 			extraState);

This message is sent by the User Interface when an application is being 
loaded from a state file. This is sent to the process itself from 
MSG_META_ATTACH, whenever the application is being invoked as in 
MSG_GEN_PROCESS_RESTORE_FROM_STATE mode. Data passed is the 
same as that in MSG_META_ATTACH. The default handler fetches the 
application mode message, either MSG_GEN_PROCESS_OPEN_APPLICATION 
or MSG_GEN_PROCESS_OPEN_ENGINE, as saved in the application object, 
and sends that message to the process.

Note that the blocks passed need not be freed, as this is done by the caller 
upon return.

**Source:** Default **GenProcessClass** handler for MSG_META_ATTACH.

**Destination:** Self.

**Interception:** Intercepted generally only so that application can retrieve previously 
saved data out of the state block passed.

**Parameters:**  
*attachFlags* - Flags with information about the state and data 
files.

*launchBlock* - Handle of AppLaunchBlock, or zero if none. This 
block contains the name of any document file 
passed into the application on invocation.

*extraState* - Handle of extra state block, or zero if none. This is 
the same block as returned from 
MSG_GEN_PROCESS_CLOSE_APPLICATION or 
MSG_GEN_PROCESS_CLOSE_ENGINE, in some 
previous MSG_META_DETACH. Process objects 
often use this extra block to save global variables to 
state files.

**Return:** Nothing.

----------

#### MSG_GEN_PROCESS_OPEN_APPLICATION

	void	MSG_GEN_PROCESS_OPEN_APPLICATION(
		AppAttachFlags		attachFlags,
		MemHandle			launchBlock,
		MemHandle 			extraState);

This message is sent by the User Interface when an application is being 
loaded from its resource blocks. Applications will often intercept this 
message to set up certain things before being put on-screen. This is the 
handler in which, for example, you would register for certain notifications 
such as the quick-transfer notification.

This is sent to the process itself from MSG_META_ATTACH, whenever the 
application is being restored to application mode (as opposed to engine 
mode), or whenever it is being invoked as in application mode. Data passed 
is the same as that in MSG_META_ATTACH. The default handler sets the 
GenApplication object GS_USABLE, and brings the UI up on screen.

This message may be intercepted to open up any data file passed, before the 
UI for the application is actually set GS_USABLE. Note that the blocks passed 
need not be freed, as this is done by the caller upon return.

**Source:** **GenProcessClass** default handler for MSG_META_ATTACH only.

**Destination:** Same object.

**Interception:** Frequently intercepted by an application's own process class to find out 
when an application is first coming alive in the system. You must pass 
this message on to the superclass, or the application will never come 
up. Be aware that the entire UI tree for the application is the 
equivalent of not usable (~GS_USABLE) before the superclass is called, 
and is usable and up on screen visually after it is called. Thus, it is best 
to do non-UI related things, and changing of generic attributes and 
hints before calling the superclass. You must wait until after calling the 
superclass to perform any operations which require that objects be 
fully usable (e.g. bringing up a dialog box).

**Parameters:**  
*attachFlags* - State information about the state and data files.

*launchBlock* - Handle of **AppLaunchBlock**, or zero if none. This 
block contains the name of any document file 
passed into the application on invocation.

*extraState* - Handle of extra state block, or zero if none. This is 
the same block as returned from 
MSG_GEN_PROCESS_CLOSE_APPLICATION or 
MSG_GEN_PROCESS_CLOSE_ENGINE, in some 
previous MSG_META_DETACH.
Is freed by caller-subclasses should not free the 
extra state block.

**Return:** Nothing.

----------

#### MSG_GEN_PROCESS_CLOSE_APPLICATION

	MemHandle MSG_GEN_PROCESS_CLOSE_APPLICATION();

This message is sent by the User Interface whenever the application is being 
shut down (during a detach) and it had been launched in application (as 
opposed to engine) mode.

**Source:** **GenProcessClass** default handler for MSG_META_DETACH only

**Destination:** Self

**Interception:** Convenient place for code that needs to be executed before application 
exits, for non-engine mode cases. Superclass must be called.

**Parameters:** None.

**Return:** Handle of block to save (or NULL for none). Process objects often save 
global variables to a state file in an extra block. This is the handle of 
that block.

----------

#### MSG_GEN_PROCESS_OPEN_ENGINE

	void 	MSG_GEN_PROCESS_OPEN_ENGINE(
			AppAttachFlags 		attachFlags,
			MemHandle 			launchBlock);

This is sent to the process itself from MSG_META_ATTACH, whenever the 
application is being restored to engine mode, or whenever it is being invoked 
as in engine mode. Data passed is the same as that in MSG_META_ATTACH. 
There is no default handler.

This message may be intercepted to open up any data file passed, before any 
engine commands are delivered to the process. Note that the blocks passed 
need not be freed, as this is done by the caller upon return.

**Source:** **GenProcessClass** default handler for MSG_META_ATTACH only.

**Destination:** Self.

**Interception:** Generally unnecessary, though can be intercepted if notification of 
going into this mode is necessary.

**Parameters:**  
*attachFlags* - State of state and data files.

*launchBlock* - Handle of **AppLaunchBlock**, or NULL if none. 
This block contains the name of any document file 
passed into the application on invocation.

**Return:** Nothing.

----------

#### MSG_GEN_PROCESS_CLOSE_ENGINE

	void 	MSG_GEN_PROCESS_CLOSE_ENGINE();

This message is sent by the User Interface whenever the application is being 
shut down (during a detach) and it had been launched in "engine" mode.

**Source:** **GenProcessClass** default handler for MSG_META_DETACH only.

**Destination:** Self.

**Interception:** Convenient place for code that needs to be executed before the 
application exits, for engine mode cases. Superclass must be called.

----------

#### MSG_GEN_PROCESS_CLOSE_CUSTOM

	MemHandle MSG_GEN_PROCESS_CLOSE_CUSTOM();

This message is sent by the User Interface whenever the application is being 
shut down (during a detach) and it had been launched in some custom mode 
(not application or engine) that **GenProcessClass** doesn't know about.

**Source:** Subclass of **GenProcessClass**.

**Destination:** Self.

**Interception:** Convenient place for code that needs to be executed before the 
application exits, for custom mode cases. Superclass must be called.

**Parameters:** None.

**Return:** Handle of block to save (or NULL for none).

----------

####MSG_GEN_PROCESS_ATTACH_TO_PASSED_STATE_FILE

	MemHandle 	MSG_GEN_PROCESS_ATTACH_TO_STATE_FILE(
				AppAttachFlags		attachFlags,
				MemHandle			launchBlock);

This message is sent by the User Interface whenever the application is being 
attached to a state file. This message is sent when either restoring from state 
or detaching. May be subclassed to provide forced state behavior.

**Source:** **GenProcessClass** default handler for MSG_META_ATTACH.

**Destination:** Self.

**Interception:** May be intercepted to force use of a particular state file (by changing 
the name of the state file to use before calling superclass).

**Parameters:**  
*attachFlags* - **AppAttachMode** (matches that in 
**AppLaunchBlock**).

*launchBlock* - Block of structure **AppLaunchBlock**.

**Return:**	Handle of extra block of state data (zero for none).

----------

#### MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE

	word	MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE(
			MemHandle appInstanceReference);

This replaces MSG_GEN_PROCESS_ATTACHED_TO_PASSED_STATE_FILE if 
no state file had been specified in that message. This message's default 
handler will create a new state file and attach it normally. Can be subclassed 
to provide forced state file usage (e.g. use a different naming scheme).

**Source:** **GenProcessClass** default handler for MSG_META_DETACH, if not 
quitting.

**Destination:** Self.

**Interception:** May be intercepted to change name of state file to create.

**Parameters:**  
*appInstanceReference* - Block handle to block of structure 
**AppInstanceReference**.

**Return:** VM file handle (NULL if you want no state file).

----------

#### MSG_GEN_PROCESS_DETACH_FROM_STATE_FILE

	void 	MSG_GEN_PROCESS_DETACH_FROM_STATE_FILE(
			MemHandle 		extraState,
			word 			appStates);

This message is sent by the User Interface when the application is detaching 
or quitting (may or may not be attached to a state file) and the detach is 
nearly complete.

**Source:** **GenProcessClass** default handler for MSG_META_DETACH, if not 
quitting.

**Destination:** Self.

**Interception:** Not generally done. Default behavior is what you want.

**Parameters:**  
*extraState* - Block handle of extra block to be saved (as returned 
from MSG_GEN_PROCESS_CLOSE_APPLICATION, 
MSG_GEN_PROCESS_CLOSE_ENGINE or 
MSG_GEN_PROCESS_CLOSE_CUSTOM). If the 
block is not transferred to the state file), it must be 
freed (if non-zero) by the handler for this message.

**appStates** - **ApplicationStates** record with information about 
the application state.

**Return:** Nothing.

----------

#### MSG_GEN_PROCESS_INSTALL_TOKEN

	void 	MSG_GEN_PROCESS_INSTALL_TOKEN();

This message is sent by the desktop to a process to get that process to install 
its token and moniker lists into the token database.

**Source:** Generally whatever geode launched this application in engine mode 
(e.g. GeoManager).

**Destination:** **GenProcessClass** object of any geode launched in engine mode.

**Interception:** May be intercepted to install additional tokens. Default behavior 
installs only application icon.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_GEN_PROCESS_GET_PARENT_FIELD

	optr 	MSG_GEN_PROCESS_GET_PARENT_FIELD();

This message is sent by process-libraries (such as the Spool Object Library) 
to find out which field object is its parent. This message will return the field 
of the first client of the library.

**Source:** Unrestricted.

**Destination:** **GenProcessClass** object.

**Interception:** Not necessary, as default behavior implements utility.

**Parameters:** Nothing.

**Return:** Parent field.

----------

#### MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST

	void	MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST(@stack
			word				sendFlags,
			EventHandle 		event,
			MemHandle 			block,
			word				manufListType,
			ManufacturerID 		manufID);

This message sends the specified event to all the objects registered with the 
passed GCN list. This message should be subclassed by UI Controller objects.

The handler here merely sends the request on to GenApplication using 
MSG_META_GCN_LIST_SEND. Controllers should use this message, however, 
over direct communication with the application object, to ensure orderly 
updating of the list status event. One such failure case which is fixed is two 
target text objects, one run by the process thread in a view, the other a 
GenText run by the UI thread. If the GenText has the target and the user 
clicks quickly on view then GenText, the GenText may process both messages 
about the target being lost and gained before the process text object receives 
its gained and lost pair. If both objects sent MSG_META_GCN_LIST_SEND 
directly to the GenApplication object, the GenText's status would be wiped 
out by the subsequent reporting by the process text object. This problem is 
avoided by having both process and UI objects call here to pass status update 
info. This works because target changes start out ordered in the UI thread, 
and that order is passed on to the process thread in either of the two cases.

**Source:** Any object wishing to update an application GCN list. Don't use 
queue-order altering message flags such as MF_PLACE_IN_FRONT 
when sending this message. As a convention must be established for 
the flag MF_FORCE_QUEUE in order to ensure orderly results, the 
convention in use is this: Don't pass it. 
A typical call should use only the MF_STACK, MF_FIXUP_DS, and/or 
MF_FIXUP_ES flags, if needed. 

**Destination:** **GenProcessClass** (application process) only.

**Interception:** Should not generally be intercepted, as GenProcessClass provides 
correct behavior. If intercepted and not sent onto superclass, event 
passed must be destroyed and data block reference count decremented, 
to avoid leaving obsolete data on the heap.

**Parameters:**  
*sendFlags* - Flags to pass on to **GCNListSend()**.

*event* - Classed event to pass on to the list.

*block* - Handle of extra data block, if used (otherwise 
NULL). Blocks of this type must have a reference 
count, which may be initialized with 
**MemInitRefCount()** and be incremented for any 
new usage with **MemIncRefCount()**. Methods in 
which they are passed are considered such a new 
usage, and must have **MetaClass** handlers which 
call **MemDerefCount()**. Current messages 
supported are 
MSG_META_NOTIFY_WITH_DATA_BLOCK and 
MSG_NOTIFY_FILE_CHANGE.

*manufListType* - This may be a **GCNStandardListType** or any 
other word which acts as a GCN list ID.

*manufID* - Manufacturer ID, which helps identify the GCN list.

### 1.3.2 Undo Mechanism

The Undo mechanism is implemented at the GenProcess level; this allows 
the undo mechanism to be applicable to any application or process. In 
general, Undo allows a process, usually within an application, but possibly 
within a library, to reverse changes made in the state of other objects. GEOS 
allows an almost unlimited number of stored and reversible Undo actions; 
the practical limit is somewhere around 100 actions.

Undo actions are stored within undo chains. These chains allow queued 
actions to be undone in reverse order. Each element in an undo chain is made 
up of an **UndoActionStruct**. These structures are usually added with an 
**AddUndoActionStruct**. This structure has several elements:

	typedef struct {
		UndoActionStruct		AUAS_data;
		optr					AUAS_output;
		AddUndoActionFlags		AUAS_flags;
	} AddUndoActionStruct

A chain of undo actions is stored for each object. If you want your object to 
recognize undo-able actions, you must add the undo actions yourself and 
intercept MSG_META_UNDO when those actions are played back. The object 
should be able to understand the data within the **UndoActionStruct** to 
perform the Undo action.

There are two **AddUndoActionFlags** which affect when and how undo 
notification occurs. If AUAF_NOTIFY_BEFORE_FREEING or 
AUAF_NOTIFY_IF_FREED_WITHOUT_BEING_PLAYED_BACK is set in the 
**AddUndoActionFlags**, it not only receives MSG_META_UNDO but also 
receives MSG_META_UNDO_FREEING_ACTION when the undo mechanism 
frees the action. You can check the flags in the **AddUndoActionStruct** 
passed with this message to decide what action to take.

The object wishing to register an action for undo sends the process 
MSG_GEN_PROCESS_UNDO_START_CHAIN. For each action in this undo 
chain (there may be multiple actions in a single chain) send 
MSG_GEN_PROCESS_UNDO_ADD_ACTION; pass this message the 
**AddUndoActionStruct** action of the action to add. Finally, send 
MSG_GEN_PROCESS_UNDO_END_CHAIN to mark the end of this undo chain. 
Undo chains may be nested within each other.

The messages following this section also describe supplemental behavior 
that you may find useful. In addition to these messages, GenProcessClass 
also provides the following routines:

**GenProcessUndoGetFile()** returns a file handle of a Huge Array or DB 
item to hold undo information. Use this routine to get a file to put such undo 
information into.

**GenProcessUndoCheckIfIgnoring()** allows an application or library to 
check whether an application is ignoring undo information; in this case, it 
can avoid creating unnecessary undo information.

----------

#### MSG_GEN_PROCESS_UNDO_START_CHAIN

	void 	MSG_GEN_PROCESS_UNDO_START_CHAIN(@stack
			optr 	title,
			optr 	owner);

This message notifies the process of the start of an undo-able action. Note 
that all this message does is increment a count - a new undo chain is created 
when the count goes from zero to one. This allows a function to perform a 
number of undo-able actions and have them all grouped as a single undo-able 
action.

**Source:** Any object wanting to register an action for undo.

**Destination:** **GenProcessClass** only.

**Interception:** In general, should not be intercepted.

**Parameters:**  
*title* - The null-terminated title of this action. If NULL, 
then the title of the undo action will be the title 
passed with the next UNDO_START_CHAIN.

*owner* - The object which owns this action.

**Return:** Nothing.

----------

#### MSG_GEN_PROCESS_UNDO_END_CHAIN

	void 	MSG_GEN_PROCESS_UNDO_END_CHAIN(
			BooleanWord 	flushChainIfEmpty);

This message notifies the process of the end of an undo-able action. Note that 
all this message does is decrement a count - the current undo chain is 
terminated when the count goes from one to zero. This allows a function to 
perform a number of undo-able actions and have them all grouped as a single 
undo-able action.

**Source:** Any object wanting to register an action for undo.

**Destination:** **GenProcessClass** only.

**Interception:** In general, should not be intercepted.

**Parameters:**  
*flushChainIfEmpty* - Non-zero if you want to delete the chain if it has no 
actions; zero if the chain is OK without actions 
(actions will be added later).

**Return:** Nothing.

#### MSG_GEN_PROCESS_UNDO_ABORT_CHAIN

	void	MSG_GEN_PROCESS_UNDO_ABORT_CHAIN();

This message aborts the current undo chain, destroying all actions in place 
on the current chain, and instructs the undo mechanism to ignore any undo 
information until the current undo chain is ended. This latter behavior is 
needed because the current chain may be nested within several chains, so we 
must ignore undo chain actions until the outermost chain is ended.

**Source:** Unrestricted.

**Destination:** GenProcess object.

**Interception:** Do not intercept.

----------

#### MSG_GEN_PROCESS_UNDO_ADD_ACTION

	VMChain 	MSG_GEN_PROCESS_UNDO_ADD_ACTION(
				AddUndoActionStruct 	*data);

This message adds a new undo action to the current undo chain.

**Source:** Any object wanting to register an action for undo.

**Destination:** GenProcessClass.

**Interception:** In general, should not be intercepted.

**Parameters:**  
*data* - Structure containing information which may be 
used to undo action.

**Return:** Will return NULL if we are ignoring undo messages. 
If the value passed in *UAS_datatype* was UADT_PTR or 
UADT_VMCHAIN, then will return a VMChain or DBItem which may 
be used to undo the action. If neither of the above cases is true, return 
value is meaningless.

----------

#### MSG_GEN_PROCESS_UNDO_GET_FILE

	VMFileHandle MSG_GEN_PROCESS_UNDO_GET_FILE();

This message returns a VM file handle to store undo actions. This message is 
useful to access undo data in either a huge array or DB item. You may also 
use **GenProcessUndoGetFile()** to retrieve this file instead.

**Source:** Any object wanting to access the undo file.

**Interception:** Should not be intercepted.

**Parameters:** None.

**Return:** File handle of VM file with undo information.

----------

#### MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS

	void 	MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS();

This message flushes the current undo chain (frees all undo actions, notifies 
edit control that there is no undo item).

**Source:** Any object using undo.

**Interception:** Should not be intercepted.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_GEN_PROCESS_UNDO_SET_CONTEXT

	dword 	MSG_GEN_PROCESS_UNDO_SET_CONTEXT(
			dword 	context);

This message sets the current undo context. This allows the application to 
have separate undo chains associated with various documents or modes. This 
should be sent out before any other undo related messages. The document 
control automatically takes care of this when a document gets the model 
exclusive.

Passing NULL_UNDO_CONTEXT as the new context will trigger some zealous 
EC code if any other undo messages are sent while the context is null.

**Source:** Any object using undo.

**Interception:** Generally, should not be intercepted. Applications wanting to override 
the default behavior should at least flush out the current undo actions, 
as they will probably not be valid in the new context.

**Parameters:**  
*context* - New context (this has no meaning to the undo 
mechanism - it's just a value).

**Return:**	Old context.

**Structures:**

	#define NULL_UNDO_CONTEXT 0

----------

#### MSG_GEN_PROCESS_UNDO_GET_CONTEXT

	dword 	MSG_GEN_PROCESS_UNDO_GET_CONTEXT();

This message gets the current undo context.

**Source:** Any object using undo.

**Interception:** Generally, should not be intercepted.

**Parameters:** None.

**Return:** Current context.

----------

#### MSG_GEN_PROCESS_UNDO_PLAYBACK_CHAIN

	void 	MSG_GEN_PROCESS_UNDO_PLAYBACK_CHAIN();

This message plays back the current undo chain, one action at a time. It 
simultaneously creates a "redo" chain, so the undone action can be redone.

**Source:** Edit control.

**Interception:** Generally, should not be intercepted.

**Parameters:** None.

**Return:** Nothing.

----------

#### MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS

	void 	MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS(
			Boolean		flushActions);

This message causes a process to reject any undo messages.

**Source:** Edit control.

**Parameters:**  
*flushActions* - true to flush the queue.

**Interception:** Generally, should not be intercepted.

----------

#### MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS

	void 	MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS();

This message causes a process to accept undo messages again.

**Source:** Edit control.

**Interception:** Generally, should not be intercepted.

----------

#### MSG_GEN_PROCESS_UNDO_CHECK_IF_IGNORING

	Boolean 	MSG_GEN_PROCESS_UNDO_CHECK_IF_IGNORING();

This message checks to see if the system is currently ignoring undo actions.

**Source:** Edit control.

**Interception:** Generally, should not be intercepted.

**Parameters:** None.

**Return:** Will return true if ignoring actions.

[Table of Contents](../objects.md) &nbsp;&nbsp; --> [GenClass](ogen.md)