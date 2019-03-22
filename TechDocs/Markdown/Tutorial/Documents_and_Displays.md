## 7 Documents and Displays

In this chapter, the application starts maintaining real document files and 
allows the user to have more than one document open at a time. This turns 
out to be a rather far-reaching change. Several values can no longer be stored 
in global variables. For example, it would be inappropriate to store the 
document's file handle in a global variable, since there may now be several 
files open. We will take a more object-oriented approach, storing this sort of 
information in instance data of objects representing documents.

### 7.1 Making the Changes

Make the changes to MCHRT.GP and MCHRT.GOC as indicated in Code 
Display 5-1 and Code Display 5-2; as before, places where the code has 
changed are indicated by vertical bars in the margin. After making the 
changes to the source code, re-compile the executable with pmake. 

### 7.2 The Application So Far

Our chart application can now keep track of more than one document at a 
time. It provides UI allowing the user to choose and select document names. 
The system allows for automatic saving of documents. Each document 
appears in a separate window. More than one document window may appear 
at a time; the user may overlap the windows or tile them.

To make these changes, the application uses some new objects and goes 
through some low-level changes. The low-level changes are necessary 
because there will now be several copies of certain objects within the 
application. 

+ The "document group" object keeps track of all open documents. It 
manages all file tasks, including opening, closing, saving, and reverting. 
Our document group object is of GenDocumentGroupClass. This 
object works together with others to automatically create and duplicate 
the objects which represent individual documents. 

+ The "display group" object maintains the multiple windows with which 
we display the multiple documents. We use an object of 
GenDisplayGroupClass; this class knows about the workings of 
GenDocumentGroup objects, and our document group and display group 
automatically work together and take care of the body of work concerning 
managing the multiple document displays.

+ We have a controller object, a GenDocumentControl, which provides UI 
gadgetry by which the user may request various file services from the 
document group. This controller provides the contents of the File menu. 

+ Another controller, a GenDisplayControl, provides the contents of the 
Windows menu. This controller provides UI gadgets allowing the user to 
request actions from the display group.

+ We have created a class to represent a document; it is a subclass of 
GenDocumentClass. GenDocumentClass provides basic behavior for 
saving and updating files; we'll subclass some handlers specific to the 
way we're setting up our UI. Also, we'll add some messages; we'll have 
document objects handle the data management tasks the process object 
was handling before. 

+ We're organizing our document file into two blocks: the first contains our 
linked list of chart data; the other contains the visual objects we're using 
to display that data. Note that it isn't necessary to store the visual 
objects; we could reconstruct them using the information stored in the 
linked list; we're doing things this way only to demonstrate how you 
might save an object within a document file.

### 7.3 MCHRT.GP: New Resources

Our glue parameters file has expanded to accommodate several new 
resources and a new subclass.

~~~
type appl, process
~~~

The application is once again multi-launchable. Since its document name is 
no longer hard-coded, there was no reason to keep it single-launchable. Also, 
in the course of updating the message handlers for multiple documents, we 
had to stop using the shortcuts which kept us from supporting multiple 
running copies of the application. 

~~~
resource CONTENT object read-only shared
resource DISPLAY ui-object read-only shared
~~~

We've changed the CONTENT resource to act as a template. Every time we 
create a new document, our handler creates a copy of this resource. The 
resource now has new flags: read-only and shared. It's marked read-only 
since the original "template" resource is never changed. The DISPLAY 
resource contains generic gadgetry which the GenDocumentGroup 
automatically duplicates for each document.

~~~
resource DOCGROUP object 
~~~

The DOCGROUP resource contains the document group object. We want this 
object as well as the document objects it manages to run in the process 
thread; they assume the document management tasks formerly carried out 
by the MCProcessClass object, 

~~~
export MCDocumentClass 
~~~

We must export our document class so that its symbols are recognized.

### 7.4 MCHRT.GOC: New Structures

The start of the application has changed quite a bit. You may notice that the 
global variables are all missing. These were used by the process object to 
keep track of document information. Now that we have multiple documents 
to keep track of, global variables would no longer be appropriate. Instead, 
we'll set up some appropriate instance data fields in our document class.

~~~
#define MC_DOCUMENT_PROTOCOL_MAJOR 0
#define MC_DOCUMENT_PROTOCOL_MINOR 1
~~~

These two constants define a protocol number for the application's 
documents: 0.1. If we later change the structure of the document, we can 
increment the protocol. We would then subclass GenDocument messages 
which manage opening older documents to add code which would update the 
old documents to the new protocol. For now, we only support one protocol and 
thus won't need this sort of code.

~~~
@class	MCProcessClass, GenProcessClass;
@endc /* end of MCProcessClass definition */
~~~

In past stages of the program, the process class maintained the data 
structures which formed the underlying model of our document. Now we're 
using our new document class for this purpose, so our process class no longer 
needs its special messages.

~~~
@class MCDocumentClass, GenDocumentClass;
~~~

Here we define our document class. Note that there are no objects of this class 
explicitly declared anywhere in the program. The GenDocumentGroup 
creates objects of this class automatically, one for each open document.

~~~
	@message (GEN_DYNAMIC_LIST_QUERY_MSG) MSG_MCD_SET_DATA_ITEM_MONIKER;
	@message void 		MSG_MCD_DELETE_DATA_ITEM();
	@message void 		MSG_MCD_INSERT_DATA_ITEM();
	@message void		MSG_MCD_SET_DATA_ITEM();
~~~

We've moved the process class' messages over to the new document class. 
Also, we changed their names to suit our coding conventions.

~~~
	@instance 	VMBlockHandle 		MCDI_dataFileBlock;
	@instance 	ChunkHandle 		MCDI_dataListHead;
	@instance 	MemHandle 		MCDI_chartMemBlock;
~~~

These three instance data fields, together with some local variables we'll 
define later, take the place of the global variables the application used to 
have. These three fields, together with GenDocumentClass' GDI_fileHandle 
field serves to keep track of where the document's data is stored.

~~~
@endc /* end of MCDocumentClass definition */

@classdecl 	MCDocumentClass;
~~~

We finish the class definition and declare the class. 

~~~
typedef struct {
	LMemBlockHeader	 	DBH_standardHeader;
	word 		DBH_numItems;	/* Number of data items */
	ChunkHandle 		DBH_listHead; 	/* Head of linked list */
	VMBlockHandle 		DBH_chartBlock; /* Block where MCChart is stored */
} DataBlockHeader;
~~~

We've made a couple of new additions to the map block's header structure. 
We're now saving the visible chart object's object block in the document file. 
We'll store its handle in the map block's header so that we'll be able to extract 
it when opening the file.

### 7.5	MCHRT.GOC: Application Objects

~~~
@object GenApplicationClass MCApp = {
 	GI_visMoniker = list { @MCTextMoniker }
 	GI_comp = @MCPrimary;
 	gcnList(MANUFACTURER_ID_GEOWORKS,GAGCNLT_WINDOWS) = @MCPrimary;
 	gcnList(MANUFACTURER_ID_GEOWORKS,MGCNLT_ACTIVE_LIST) =
		@MCDocumentControl, @MCDisplayControl;
 	gcnList(MANUFACTURER_ID_GEOWORKS,MGCNLT_APP_STARTUP) =
		@MCDocumentControl;
 	gcnList(MANUFACTURER_ID_GEOWORKS,GAGCNLT_SELF_LOAD_OPTIONS) =
		@MCDocumentControl, @MCDisplayControl;
}
~~~

The GenApplication object hasn't changed much, except that we have 
entered some of the controller objects on some GCN lists. In general, 
controller objects do their jobs automatically. They get the messages which 
prod them to action only if they are on the proper General Change 
Notification lists.

The MGCNLT_ACTIVE_LIST list holds all objects which need to be built on 
application start-up. Most controller objects fall into this category, and our 
document and display controls are on this list.

The MGCNLT_APP_STARTUP list is for those objects that need to know when 
the application has just started or is about to exit. 

The GAGCNLT_SELF_LOAD_OPTIONS list holds all objects which may need to 
save their options. This comes in handy when trying to maintain the user's 
UI choices. 

It may not be entirely obvious which sorts of controllers belong on which GCN 
lists. When using an unfamiliar controller, read its documentation. 

~~~
@object GenPrimaryClass MCPrimary = {
	GI_comp = @MCFileGroup, @MCWindowGroup, @MCDisplayGroup;
	ATTR_GEN_DISPLAY_MENU_BAR_POPPED_OUT;

	HINT_DISPLAY_MENU_BAR_HIDDEN_ON_STARTUP;
}
~~~

Our primary window now has different children. Most of the original children 
are now duplicated for each document's display. The primary's children are 
now a couple of menus and the display group.

Furthermore, we've added a couple of variable data fields which will make a 
bit more room when running the program on a machine with a small screen. 
the ATTR_GEN_DISPLAY_MENU_BAR_POPPED_OUT field indicates that the 
menu bar should be floating and the 
HINT_DISPLAY_MENU_BAR_HIDDEN_ON_STARTUP hint says that the menu 
bar should start out hidden on those systems that support hidden menu bars.

### 7.6 Menus and Controllers

In past stages of the application, we only had one menu (the File menu), 
generated automatically. For this stage of the application, we create our own 
menus, including a File menu which takes the place of the automatically 
generated one. We implement each menu by means of a GenInteraction 
object. Recall that GenInteractions are meant to create logical groupings for 
UI gadgetry; since menus group UI gadgetry it makes sense to implement 
them in this way.

~~~
@object GenInteractionClass MCFileGroup = {
	GI_comp = @MCDocumentControl;
	GII_visibility = GIV_POPUP;
	ATTR_GEN_INTERACTION_GROUP_TYPE = GIGT_FILE_MENU;
}
~~~

The MCFileGroup object manifests as the File menu. It has one child, our 
document control; this means that our UI gadgetry for saving and opening 
documents appears under the File menu, which is where we want it. The 
GII_visibility field determines how the object manifests itself; the GIV_POPUP 
value causes it to appear as a pop-up menu. 

The last field is not a regular instance data field. It is a piece of variable data. 
Like hints, variable data is stored in a buffer at the end of the object's regular 
data. Actually, hints are variable data fields. If you're interested to know how 
hints and other variable data fields are stored, read "GEOS Programming," 
Chapter 5 of the Concepts book. 

The ATTR_GEN_INTERACTION_GROUP_TYPE allows you to specify that a 
GenInteraction should manifest as one of a number of standard UI 
interactions. By using this variable data field with the GIGT_FILE_MENU 
value, we ask that this GenInteraction appear as a File menu appropriate for 
the user's specific user interface. The Motif specific user interface puts a Quit 
trigger in this menu and supply the GenInteraction with the correct moniker 
("File").

~~~
@object GenDocumentControlClass MCDocumentControl = {
	GDCI_documentToken = {"MCht", MANUFACTURER_ID_GEOWORKS } ;
	GDCI_noNameText = "No Document";
	GDCI_documentGroup = MCDocumentGroup;
	GDCI_attrs = @default | GDCA_MULTIPLE_OPEN_FILES;
	GDCI_features = @default & ~GDCF_NAME_ON_PRIMARY;
}
~~~

The document control provides all user gadgetry for manipulating document 
files. It works together with the document group to provide file services. 

We specify a token for our document files in the GDCI_documentToken field. 
When the user wants to open a document, the document control's file selector 
dialog only displays files whose tokens match this value. 

We put the object pointer of the document group object in the document 
control's GDCI_documentGroup instance field. Remember that the document 
group is the object which carries out all file operations; the document control 
sends messages to the document group whenever the user wants to carry out 
one of these file operations. We must set the value in this instance field so 
that the document control knows where to send these messages.

The GDCI_attrs field allows us to set some attributes associated with the 
document control. In this case, the only unusual thing we're doing is allowing 
multiple open files.

We're turning off the GDCF_NAME_ON_PRIMARY flag within the 
GDCI_features instance field. Leaving this flag on would mean that we'd try 
to display the current document name on the title bar of the primary window 
under some circumstances we're not prepared to handle. Even with this flag 
off, the document name still displays when there is a document display which 
is showing full-screen.

~~~
@object GenInteractionClass MCWindowGroup = {
	GI_comp = @MCDisplayControl;
	GII_visibility = GIV_POPUP;
	ATTR_GEN_INTERACTION_GROUP_TYPE = GIGT_WINDOW_MENU;
}
~~~

This interaction manifests as the Windows menu. As with the File menu, it 
uses GIV_POPUP and an ATTR_GEN_INTERACTION_GROUP_TYPE value. It 
has one child, the display control.

~~~
@object GenDisplayControlClass MCDisplayControl = {}
~~~

The display control provides the UI gadgetry for overlapping, tiling, and 
otherwise manipulating the multiple document displays. We aren't doing 
anything extraordinary with our display control, and need set no instance 
data for it. Because we have placed it on the appropriate General Change 
Notification lists, it works automatically.

## 7.7 Display Gadgets

In addition to the display control, we need to set up a display group and some 
objects to represent the display itself.

~~~
@object GenDisplayGroupClass MCDisplayGroup = { }
~~~

This is the object that actually manages the document displays. We aren't 
doing anything very special with our document displays, and don't need to set 
any instance data fields for the object.

~~~
@start 	Display;
~~~

The Display resource is a template resource. The document group 
automatically creates a copy of this resource for each opened document; it 
passes control of the display over to the display group object.

~~~
@object GenDisplayClass MCDisplay = {
	GI_comp = @MCLeftClump, @MCChartView;
	GI_states = @default & ~GS_USABLE;
	ATTR_GEN_DISPLAY_NOT_MINIMIZABLE;
	HINT_ORIENT_CHILDREN_HORIZONTALLY;
}
@end 	Display;
~~~

The MCDisplay object is a window object like MCPrimary. In fact, 
GenPrimaryClass (the class of MCPrimary) is a subclass of 
GenDisplayClass with some extra behavior specific to a primary window. 

The GI_comp and HINT_ORIENT_CHILDREN_HORIZONTALLY fields are set 
up as they were for MCPrimary in the program's previous stage. 

Some other fields have been set up so that the display may work in 
conjunction with the display control. The GI_states field has been set up so 
that the display starts out as not enabled. When an object has been so 
marked, it is normally grayed out and the user won't be allowed to interact 
with the object. Note that by the time the display actually appears, it won't 
be grayed out; the display group automatically enables it. The 
ATTR_GEN_DISPLAY_NOT_MINIMIZABLE variable data field eliminates the 
minimize button; we don't have any behavior set up if the user tries to 
minimize the display, so we won't allow it.

~~~
@start 	Display;
@object GenDynamicListClass MCDataList = {
	GIGI_selection = FAKE_LIST_ITEM;
	GIGI_numSelections = 1;
	GIGI_applyMsg = 0;
	GIGI_destination = (TO_OBJ_BLOCK_OUTPUT);
	GDLI_numItems = 1;
	GDLI_queryMsg = MSG_MCD_SET_DATA_ITEM_MONIKER;
	HINT_ITEM_GROUP_SCROLLABLE;
}

@object GenTriggerClass MCAddTrigger = {
	GI_visMoniker = "Add";
	GTI_destination = (TO_OBJ_BLOCK_OUTPUT);
	GTI_actionMsg = MSG_MCD_INSERT_DATA_ITEM;
}
@object GenTriggerClass MCChangeTrigger = {
	GI_visMoniker = "Change";
	GTI_destination = (TO_OBJ_BLOCK_OUTPUT);
	GTI_actionMsg = MSG_MCD_SET_DATA_ITEM;
}
@object GenTriggerClass MCDeleteTrigger = {
	GI_visMoniker = "Delete";
	GTI_destination = (TO_OBJ_BLOCK_OUTPUT);
	GTI_actionMsg = MSG_MCD_DELETE_DATA_ITEM;
}

@end 	Display;
~~~

These are our old data-entry UI gadgets. They've been moved into the display 
resource and have been set up with different GIGI_destination field 
values-they now send their actions using a travel option rather than the 
process keyword. Travel options are special values that may be placed in 
destination fields; they may be used to send messages to objects based on that 
object's place within the program rather than its object pointer.

Any object block can have an "object block output". This "object block output" 
is merely an object which expects to receive certain messages from objects 
within the block. The object block output object need not be within the block 
for which it is the output. When the document group sets up the document 
and display objects, the document object was automatically set up as the 
object block output for the Display object block.

The TO_OBJ_BLOCK_OUTPUT travel option tells our generic UI gadgetry to 
send their messages to the Display block's object block output, which in this 
case is the document object associated with the display's document. Since our 
document object is now in charge of maintaining the data for each object, the 
gadgets which work with the data use the appropriate travel option to reach 
the document.

### 7.8	Document Group

~~~
@start 	DocGroup;
@object GenDocumentGroupClass MCDocumentGroup = {
	GDGI_attrs = (@default | GDGA_VM_FILE_CONTAINS_OBJECTS );
	GDGI_untitledName = "UntitledChart";
	GDGI_documentClass = (ClassStruct *) &MCDocumentClass;
	GDGI_documentControl = MCDocumentControl;
	GDGI_genDisplayGroup = MCDisplayGroup;
	GDGI_genView = MCChartView;
	GDGI_genDisplay = MCDisplay;
	GDGI_protocolMajor = MC_DOCUMENT_PROTOCOL_MAJOR;
	GDGI_protocolMinor = MC_DOCUMENT_PROTOCOL_MINOR;
}
@end 	DocGroup;
~~~

MCDocumentGroup is our document group object, the object which 
manages our multiple documents. It must be in a resource which runs under 
the application's process thread, and is. It interacts with many objects and  
has many important object pointers stored in its instance data. Note that 
MCDocumentGroup doesn't appear in the application's generic tree; it isn't 
the child of any object, but only appears in the GDCI_documentGroup field of 
the GenDocumentControl.

The GDGI_attrs allows you to specify some special attributes for the 
document group. Our document files include an object block, the block which 
contains the visible objects. This is somewhat unusual, and we must set the 
GDGA_VM_FILE_CONTAINS_OBJECTS flag here, as the document group has 
to do some extra file work to handle saving the objects.

The GDGI_untitledName field specifies a document name to use for untitled 
documents. If another untitled document is created, it will be called "Untitled 
Chart 1". Further untitled documents will be given names with successive 
numbers.

Remember that we aren't explicitly declaring any document objects; instead 
we pass the address of our document class in the GDGI_documentClass field. 
The document group automatically creates an object of this class for each 
open document. The document group sends appropriate messages to the 
document object when the user wants to perform some file operation upon the 
document. 

The Document group needs to work with the document control and display 
group objects, and their object pointers are stored in its 
GDGI_documentControl and GDGI_genDisplayGroup fields. The 
GDGI_genView field tells the document where it displays within the 
duplicated resource. The GDGI_genDisplay resource provides the location of 
the GenDisplay's resource within the duplicated Display resource and 
incidentally provides the address of the Display resource itself; the document 
group uses this value to determine which resource it should automatically 
duplicate.

The last two instance fields contain protocol numbers. If we later revised the 
application in a way that changed the structure of the document files, we 
would change the document protocol. We could then write handlers in our 
document class for updating old documents, which would be recognized by 
their low protocol numbers. 

### 7.9 Altered Handlers

~~~
@method MCDocumentClass, MSG_MCD_SET_DATA_ITEM_MONIKER {
	if (item==FAKE_LIST_ITEM) {
		optr 	moniker;
		moniker = ConstructOptr(OptrToHandle(list),
				OptrToChunk(@FakeItemMoniker));
		@send list::MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR(
				FAKE_LIST_ITEM, moniker);}
~~~

In this code fragment we can see the first side effect of supporting multiple 
documents. In the previous stage of the program, there was only one copy of 
each resource. This time we've duplicated the resource which contains 
FakeItemMoniker. Thus, if we were to refer to it directly, the value 
@FakeItemMoniker would be ambiguous-we can't know which resource it 
would refer to. Thus we construct an object pointer. We know that the block 
containing the dynamic list object contains the moniker, so we extract its 
block handle. We use our knowledge of the moniker's object pointer to get its 
chunk handle. Finally, we create a new object pointer by combining these 
handles and use that to reference the duplicated moniker.

~~~
	else /* item > FAKE_LIST_ITEM */ {
		ChunkHandle 		tempListItem;
		ListNode 		*tempNode;
		char 		monikerString[LOCAL_DISTANCE_BUFFER_SIZE];
		word 		data;
		MemHandle		dataListBlock;
		MemHandle		*dataListBlockPtr = &dataListBlock;
		word 		ordinal = item;

		VMLock(pself->GDI_fileHandle,
		 pself->MCDI_dataFileBlock,
		 dataListBlockPtr);

		for(tempNode = LMemDerefHandles(dataListBlock,
						pself->MCDI_dataListHead);
		 ordinal > 1;
		 --ordinal)
			{
			 tempListItem = tempNode->LN_next;
			 tempNode = LMemDerefHandles(dataListBlock, tempListItem);
			}
		data = tempNode->LN_data;
		VMUnlock(dataListBlock);
~~~

Here we're absorbing the function of the MCListGetDataItem() routine 
and absorbing it back into our handler. This isn't necessarily good coding 
practice, but makes this a more readable tutorial.

Note that instead of using global variables to store the document's file handle 
(difficult to do since there may be several document files open), we're using 
the document's automatically maintained GDI_fileHandle instance field.

There is one other change, rather trivial: because the document has taken 
over the data maintenance tasks, the data list's head is now stored in a 
MCDocumentClass instance field, MCDI_dataListHead instead of in an 
MCProcessClass field.

~~~
@method MCDocumentClass, MSG_MCD_INSERT_DATA_ITEM {
	ChunkHandle 	newListItem;
	ListNode 	*newNode;
	WWFixedAsDWord	value;
	word 		ordinal;
	MemHandle 	dataListBlock;
	MemHandle 	*dataListBlockPtr = &dataListBlock;
	optr 		ourList;
	optr 		ourValue;
	optr 		ourChart;
	DataBlockHeader *dataBlockHeader;

	ourList = ConstructOptr(pself->GDI_display,
				OptrToChunk(@MCDataList));
	ordinal = @call ourList::MSG_GEN_ITEM_GROUP_GET_SELECTION();
	ourValue = ConstructOptr(pself->GDI_display,
				 OptrToChunk(@MCValue));
	value = @call ourValue::MSG_GEN_VALUE_GET_VALUE();
~~~

Where in previous stages of the program we sent messages to objects by 
simply using the object's name as the target of an @call, now we must make 
it clear which object we are sending the message to; all of these objects have 
been duplicated. The document's GDI_display field contains the object block 
handle of the duplicate display resource. Combining that with the chunk part 
of whichever object we want, we construct a new object pointer which we use 
as the recipient of the message. 

~~~
	dataBlockHeader = VMLock(pself->GDI_fileHandle,
		 		 pself->MCDI_dataFileBlock,
				 dataListBlockPtr);
~~~

Again, instead of using global variables to reference data, we instead use 
instance data fields of the document object.

~~~
	if (ordinal==FAKE_LIST_ITEM)
	 {
		newNode->LN_next = pself->MCDI_dataListHead;
		pself->MCDI_dataListHead = newListItem;
	 }
	else
	 {
		ListNode 	*tempNode;
		ChunkHandle 	tempListItem;
		word 		count = ordinal;

		for (tempNode = LMemDerefHandles(dataListBlock,
						 pself->MCDI_dataListHead);
		 count > 1;
		 --count)
		 {
			tempListItem = tempNode->LN_next;
			tempNode = LMemDerefHandles(dataListBlock,
					 	 tempListItem);
		 }
		newNode->LN_next = tempNode->LN_next;
		tempNode->LN_next = newListItem;
	 }
~~~

There are more scattered places where we must use the instance fields to 
refer to the data. Notice the use of the MCDI_dataListHead field to refer to 
the head of the linked list data structure.

~~~
	dataBlockHeader->DBH_listHead = pself->MCDI_dataListHead;
	dataBlockHeader->DBH_numItems++;
~~~

We're also updating the file header information. While the document object 
is handling all file management chores for us, we make sure that the file's 
header information stays up to date. This makes it easier to deal with 
automatic saves and closing the document. 

~~~
	@send ourList::MSG_GEN_DYNAMIC_LIST_ADD_ITEMS(ordinal+1, 1);
	@send ourList::MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION(ordinal+1,
								 FALSE);

	ourChart = ConstructOptr(pself->MCDI_chartMemBlock,
				 OptrToChunk(@MCChart));
	@send ourChart::MSG_MCC_INSERT_BAR(ordinal, WWFixedToInt(value));
} /* end of MSG_MCD_INSERT_DATA_ITEM */
~~~

Here are more cases of objects being referred to by constructed object pointers 
instead of by their names.

~~~
@method MCDocumentClass, MSG_MCD_DELETE_DATA_ITEM {
	word 		ordinal;
	word 		count;
	ChunkHandle 	oldItem;
	ListNode	*oldNode;
	MemHandle 	dataListBlock;
	MemHandle 	*dataListBlockPtr = &dataListBlock;
	ChunkHandle 	tempListItem;
	ListNode 	*tempNode;
	optr 		ourList;
	optr 		ourChart;
	DataBlockHeader *dataBlockHeader;

	ourList = ConstructOptr(pself->GDI_display,
				OptrToChunk(MCDataList));

	ordinal = @call ourList::MSG_GEN_ITEM_GROUP_GET_SELECTION();
	if (ordinal==FAKE_LIST_ITEM) return;
	count = ordinal ;

	dataBlockHeader = VMLock(pself->GDI_fileHandle,
	 			 pself->MCDI_dataFileBlock,
	 			 dataListBlockPtr);

	if (ordinal == 1) {
		oldNode = LMemDerefHandles(dataListBlock,
					 pself->MCDI_dataListHead);
		tempListItem = oldNode->LN_next;
		LMemFreeHandles(dataListBlock, pself->MCDI_dataListHead);
		pself->MCDI_dataListHead = tempListItem;
	 }

	else {
		for (tempNode=LMemDerefHandles(dataListBlock,
					 pself->MCDI_dataListHead);
		 count > 2;
		 --count)
		 {
			tempListItem = tempNode->LN_next;
			tempNode = LMemDerefHandles(dataListBlock,
						 tempListItem);
		 }
		oldItem = tempNode->LN_next;
		oldNode = LMemDerefHandles(dataListBlock, oldItem);

		tempNode->LN_next = oldNode->LN_next;
		LMemFreeHandles(dataListBlock, oldItem);
	 }

	dataBlockHeader->DBH_listHead = pself->MCDI_dataListHead;
	dataBlockHeader->DBH_numItems--;

	VMDirty(dataListBlock);
	VMUnlock(dataListBlock);

	@send ourList::MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS(ordinal, 1);
	@send ourList::MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION(ordinal-1,
								 FALSE);

	ourChart = ConstructOptr(pself->MCDI_chartMemBlock,
				 OptrToChunk(@MCChart));

	@send ourChart::MSG_MCC_DELETE_BAR(ordinal-1);
} /* end of end of MSG_MCD_DELETE_DATA_ITEM */ 

@method MCDocumentClass, MSG_MCD_SET_DATA_ITEM {
	word 		ordinal;
	WWFixedAsDWord 	value;
	char 		monikerString[LOCAL_DISTANCE_BUFFER_SIZE];
	word 		count;
	MemHandle 	dataListBlock;
	MemHandle	*dataListBlockPtr = &dataListBlock;
	ChunkHandle 	tempListItem;
	ListNode 	*tempNode;
	optr 		ourList;
	optr 		ourValue;
	optr 		ourChart;

	ourList = ConstructOptr(pself->GDI_display,
				OptrToChunk(MCDataList));
	ordinal = @call ourList::MSG_GEN_ITEM_GROUP_GET_SELECTION();
	if (ordinal == FAKE_LIST_ITEM) return;

	ourValue = ConstructOptr(pself->GDI_display,
				 OptrToChunk(MCValue));
	value = @call ourValue::MSG_GEN_VALUE_GET_VALUE();

	VMLock(pself->GDI_fileHandle,
	 pself->MCDI_dataFileBlock,
	 dataListBlockPtr);
	for (tempNode = LMemDerefHandles(dataListBlock,
					 pself->MCDI_dataListHead),
	 count = ordinal-1;
	 count > 0;
	 --count)
	 {
		tempListItem = tempNode->LN_next;
		tempNode = LMemDerefHandles(dataListBlock, tempListItem);
	 }
	tempNode->LN_data = WWFixedToInt(value);

	VMDirty(dataListBlock);
	VMUnlock(dataListBlock);

	LocalFixedToAscii(monikerString, value, 0);
	@call ourList::MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT(
							ordinal,
							monikerString);

	ourChart = ConstructOptr(pself->MCDI_chartMemBlock,
				 OptrToChunk(@MCChart));
	@send ourChart::MSG_MCC_RESIZE_BAR(ordinal-1, WWFixedToInt(value));
} /* end of MSG_MCD_SET_DATA_ITEM */
~~~

These message handlers have been changed in ways similar to that for 
MSG_MCD_INSERT_DATA_ITEM. We won't explore each change; there are 
just more cases of using document instance data to refer to data structures 
and constructing optrs to refer to objects.

### 7.10 Maintaining the Document

We have three message handlers to maintain our data structures within the 
document file whenever the file is saved or opened.

~~~
@method MCDocumentClass, MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE {
	VMBlockHandle 		chartFileBlock;
	MemHandle 		dataListBlock;
	MemHandle 		*dataListBlockPtr = &dataListBlock;
	DataBlockHeader 	*dataBlockHeader;

	if (@callsuper()) return(TRUE); 
	pself = ObjDerefGen(oself);
~~~

Our first message handler is for the case in which we create a new document 
file. First we call the superclass behavior. We do this to give the document's 
GenDocumentClass behavior a chance to create the document file. We 
don't know the specifics of how GenDocumentClass handles this message, 
and in fact the pself pointer may no longer be valid by the time the 
@callsuper command returns. To be safe, we call ObjDerefGen() to update 
the pself value.

~~~
	pself->MCDI_chartMemBlock =
			ObjDuplicateResource(OptrToHandle(@MCChart), 0, 0);
	chartFileBlock = VMAttach(pself->GDI_fileHandle,
				 0,
				 pself->MCDI_chartMemBlock);
	VMPreserveBlocksHandle(pself->GDI_fileHandle, chartFileBlock);
~~~

Though the document group is nicely duplicating our display block, we must 
duplicate the CONTENT block ourselves. To get the block handle of the object 
block we want to duplicate, we use OptrToHandle(), passing @MCChart, 
the object pointer of one of the objects within the block. We duplicate the 
entire resource by means of the ObjDuplicateResource() routine.

We want the duplicated object block to be saved whenever the document is 
saved; we call VMAttach() to attach our memory block to the document's 
associated VM file. Finally, we call VMPreserveBlocksHandle() to 
preserve handles within the object block.

~~~
	pself->MCDI_dataFileBlock = VMAllocLMem(pself->GDI_fileHandle,
						LMEM_TYPE_GENERAL,
						sizeof(DataBlockHeader));
	VMSetMapBlock(pself->GDI_fileHandle, pself->MCDI_dataFileBlock);
	dataBlockHeader = VMLock(pself->GDI_fileHandle,
		 		 pself->MCDI_dataFileBlock,
		 		 dataListBlockPtr);
	dataBlockHeader->DBH_listHead = NULL;
	dataBlockHeader->DBH_numItems = 1;
	dataBlockHeader->DBH_chartBlock = chartFileBlock;
	VMDirty(dataListBlock);
	VMUnlock(dataListBlock);

	return(FALSE); 
} /* end of MSG_GEN_DOCUMENT_INITALIZE_DOCUMENT_FILE */
~~~

The rest of the handler corresponds closely the part of our old 
MSG_GEN_PROCESS_OPEN_APPLICATION handler for MCProcessClass 
which was in charge of creating new files.

~~~
@method MCDocumentClass, MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT {
	MemHandle 		dataListBlock;
	MemHandle 		*dataListBlockPtr = &dataListBlock;
	DataBlockHeader *dataBlockHeader;
	word 			numItems;
	optr 			ourList;
	VMBlockHandle		chartFileBlock;
	optr 			ourChart;

	@callsuper();
	pself = ObjDerefGen(oself);

	pself->MCDI_dataFileBlock = VMGetMapBlock(pself->GDI_fileHandle);
	dataBlockHeader = VMLock(pself->GDI_fileHandle,
				 pself->MCDI_dataFileBlock,
				 dataListBlockPtr);

	pself->MCDI_dataListHead = dataBlockHeader->DBH_listHead;
	numItems = dataBlockHeader->DBH_numItems;
	chartFileBlock = dataBlockHeader->DBH_chartBlock;
	VMUnlock(dataListBlock);
~~~

This portion of code corresponds closely to that part of the old 
MCProcessClass' MSG_GEN_PROCESS_OPEN_APPLICATION handler in 
charge of extracting information from a chart file's data header.

~~~
	pself->MCDI_chartMemBlock = VMVMBlockToMemBlock(pself->GDI_fileHandle,
							chartFileBlock);
	ourChart = ConstructOptr(pself->MCDI_chartMemBlock,
				 OptrToChunk(@MCChart));
	@send self::MSG_VIS_ADD_NON_DISCARDABLE_VM_CHILD(ourChart, CCO_FIRST);

	ourList = ConstructOptr(pself->GDI_display,
				OptrToChunk(@MCDataList));
	@send ourList::MSG_GEN_DYNAMIC_LIST_INITIALIZE(numItems);
	@send ourList::MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION(0, FALSE);
} /* end of MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT */
~~~

This portion of code initializes the UI in the old manner, the only difference 
being that we must construct the objects' optrs.

~~~
@method MCDocumentClass, MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT {
	optr 			ourChart;

	@callsuper();

	ourChart = ConstructOptr(pself->MCDI_chartMemBlock,
				 OptrToChunk(@MCChart));
	@call ourChart::MSG_VIS_REMOVE_NON_DISCARDABLE( VUM_MANUAL );
}
~~~

This message handler removes the document's chart object from the visual 
tree preparatory to storing it. The document takes care of all other UI chores 
automatically.

---
Code Display 5-1 MCHRT.GP
~~~
name mchrt.app 

longname "MyChart" 

type appl, process

class MCProcessClass 

appobj MCApp 

tokenchars "MCht"
tokenid 0 

library geos
library ui 

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource CONTENT object read-only shared
resource DISPLAY ui-object read-only shared
resource DOCGROUP object 

export MCChartClass
export MCDocumentClass 
~~~

---
Code Display 5-2 MCHRT.GOC
~~~
/**************************************************************
 *	Copyright (c) GeoWorks 1993 -- All Rights Reserved
 *
 * MChrt is a charting application. It maintains a list of
 * numbers and constructs a bar chart to display them.
 *
 * Our process object is in charge of maintaining the data
 * structure which holds the list of numbers.
 *
 **************************************************************/

@include <stdapp.goh>

/* CONSTANTS */
/* In the list gadget which represents our data, the first item
 * isn't going to represent anything; it's just a place holder.
 * The FAKE_LIST_ITEM constant will be used when checking for this item 
 */
#define FAKE_LIST_ITEM 	0

/* When drawing the pieces of the chart, we'll use the following 
 * constants to compute the coordinates at which to draw.
 */
#define VIEW_RIGHT	360	/* Width of the Chart View */
#define VIEW_BOTTOM	288	/* Height of Chart View */
#define CHART_BOTTOM 	268	/* y = 0 line of Chart */
#define CHART_LEFT 20	/* Left bound of Leftmost bar */
#define BAR_WIDTH	30	/* Width of each bar */
#define BAR_WIDTH_ALLOW	36	/* Distance between left edges of bars */
#define BORDER_MARGIN	10	/* Arbitrary margin width at edges */

/* The following constants are the document protocol. If we ever change
 * our document format, we should increment either the major or minor
 * protocol number. 
 */
#define MC_DOCUMENT_PROTOCOL_MAJOR 0
#define MC_DOCUMENT_PROTOCOL_MINOR 1

@class	MCProcessClass, GenProcessClass;
@endc /* end of MCProcessClass definition */

@class MCDocumentClass, GenDocumentClass;
/* For information about the messages listed below, see the
 * headers for their handlers, later in this file. 
 */
	@message (GEN_DYNAMIC_LIST_QUERY_MSG) MSG_MCD_SET_DATA_ITEM_MONIKER;
	@message void 	MSG_MCD_DELETE_DATA_ITEM();
	@message void MSG_MCD_INSERT_DATA_ITEM();
	@message void	MSG_MCD_SET_DATA_ITEM();
/* MCDI_dataFileBlock: handle of map block, where we store a linked list. */
	@instance 	VMBlockHandle 	MCDI_dataFileBlock;
/* MCDI_dataListHead: handle of head of linked list. */
	@instance 	ChunkHandle 	MCDI_dataListHead;
/* MCDI_chartMemBlock: Object block holding our MCChart object. */
	@instance 	MemHandle 	MCDI_chartMemBlock;
@endc /* end of MCDocumentClass definition */

@class MCChartClass, VisClass;
/* For information about the messages listed below, see the
 * headers for their handlers, later in this file. 
 */
	@message void 	MSG_MCC_INSERT_BAR(word ordinal, word value);
	@message void 	MSG_MCC_DELETE_BAR(word ordinal);
	@message void 	MSG_MCC_RESIZE_BAR(word ordinal, word value);
/* MCCI_numBars:	The number of bars in the chart. Internal. */
	@instance word MCCI_numBars = 0;
/* MCCI_barArray:	Chunk handle of array to hold bar info. */
	@instance ChunkHandle MCCI_barArray;
@endc /* end of MCChartClass definition */

@classdecl 	MCProcessClass, neverSaved;
@classdecl 	MCChartClass;
@classdecl 	MCDocumentClass;

/* Global STRUCTURES and VARIABLES */

/* This structure will hold information about our document, and will form
 * the header of a block in our data file. The first item of this structure
 * MUST be an LMemBlockHeader. 
 */
typedef struct {
	LMemBlockHeader	 DBH_standardHeader;
	word 		DBH_numItems;	/* Number of data items */
	ChunkHandle 		DBH_listHead; 	/* Head of linked list */
	VMBlockHandle 		DBH_chartBlock; /* Block where MCChart is stored */
} DataBlockHeader;

/* The data points which are to be charted are stored in
 * a linked list of chunks, all of which are contained within
 * a single block of memory. Each element of the list will be
 * stored in a ListNode structure. 
 */
typedef struct {
	word		LN_data;
	ChunkHandle		LN_next;
} ListNode;

/* OBJECT Resources */
/* APPRESOURCE will hold the application object and other information
 which the system will want to load when it wants to find out about
 the application but doesn't need to run the application. */
@start	AppResource;
@object GenApplicationClass MCApp = {
 GI_visMoniker = list { @MCTextMoniker }
 GI_comp = @MCPrimary;
 gcnList(MANUFACTURER_ID_GEOWORKS,GAGCNLT_WINDOWS) = @MCPrimary;
 gcnList(MANUFACTURER_ID_GEOWORKS,MGCNLT_ACTIVE_LIST) =
	@MCDocumentControl, @MCDisplayControl;
 gcnList(MANUFACTURER_ID_GEOWORKS,MGCNLT_APP_STARTUP) =
	@MCDocumentControl;
 gcnList(MANUFACTURER_ID_GEOWORKS,GAGCNLT_SELF_LOAD_OPTIONS) =
	@MCDocumentControl, @MCDisplayControl;
}

@visMoniker MCTextMoniker = "MyChart Application";

@end	AppResource;

/* The INTERFACE resource holds the bulk of our Generic UI gadgetry. */
@start Interface;
@object GenPrimaryClass MCPrimary = {
	GI_comp = @MCFileGroup, @MCWindowGroup, @MCDisplayGroup;
	/*
	 * When the specific UI permits, let's not show the menu bar on
	 * startup; this can be useful on the small screen of a pen-based
	 * system since it gives some extra space.
	 */
	ATTR_GEN_DISPLAY_MENU_BAR_POPPED_OUT;
	HINT_DISPLAY_MENU_BAR_HIDDEN_ON_STARTUP;
}

@object GenInteractionClass MCFileGroup = {
	GI_comp = @MCDocumentControl;
	GII_visibility = GIV_POPUP;
	ATTR_GEN_INTERACTION_GROUP_TYPE = GIGT_FILE_MENU;
}

@object GenDocumentControlClass MCDocumentControl = {
	GDCI_documentToken = {"MCht", MANUFACTURER_ID_GEOWORKS } ;
	GDCI_noNameText = "No Document";
	GDCI_documentGroup = MCDocumentGroup;
	GDCI_attrs = @default | GDCA_MULTIPLE_OPEN_FILES;
	GDCI_features = @default & ~GDCF_NAME_ON_PRIMARY;
}

@object GenInteractionClass MCWindowGroup = {
	GI_comp = @MCDisplayControl;
	GII_visibility = GIV_POPUP;
	ATTR_GEN_INTERACTION_GROUP_TYPE = GIGT_WINDOW_MENU;
}

@object GenDisplayControlClass MCDisplayControl = {}

@object GenDisplayGroupClass MCDisplayGroup = { }

@end 	Interface;

/* The DISPLAY resource is a template which will be duplicated for
 * each open document. It contains all generic UI associated with
 * a document. 
 */
@start	Display;
@object GenDisplayClass MCDisplay = {
	GI_comp = @MCLeftClump, @MCChartView;
	GI_states = @default & ~GS_USABLE;
	ATTR_GEN_DISPLAY_NOT_MINIMIZABLE;
	HINT_ORIENT_CHILDREN_HORIZONTALLY;
}

@object GenInteractionClass MCLeftClump = {
	GI_comp = @MCDataList, @MCAddTrigger, @MCDeleteTrigger,
		 @MCChangeTrigger, @MCValue;
}

@object GenViewClass MCChartView = {
	GVI_horizAttrs = @default | GVDA_NO_SMALLER_THAN_CONTENT |
			 GVDA_NO_LARGER_THAN_CONTENT;
	GVI_vertAttrs = @default | GVDA_NO_SMALLER_THAN_CONTENT |
			GVDA_NO_LARGER_THAN_CONTENT;
}

@end	Display;

/* The CONTENT resource is a template resource, and a duplicate of this
 * resource will be made for each newly created document.
 */ 
@start Content, notDetachable;

@object MCChartClass MCChart = {
	VI_bounds = { 0, 0, VIEW_RIGHT, VIEW_BOTTOM };
	MCCI_barArray = BarDataChunk;
}

@chunk word BarDataChunk[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

@end 	Content;

@start 	Display;
@object GenDynamicListClass MCDataList = {
	GIGI_selection = FAKE_LIST_ITEM;
	GIGI_numSelections = 1;
	GIGI_applyMsg = 0;
	GIGI_destination = (TO_OBJ_BLOCK_OUTPUT);
	GDLI_numItems = 1;
	GDLI_queryMsg = MSG_MCD_SET_DATA_ITEM_MONIKER;
	HINT_ITEM_GROUP_SCROLLABLE;
}

@visMoniker FakeItemMoniker = "Data:";
@localize "This string will appear at the head of the list";

@object GenTriggerClass MCAddTrigger = {
	GI_visMoniker = "Add";
	GTI_destination = (TO_OBJ_BLOCK_OUTPUT);
	GTI_actionMsg = MSG_MCD_INSERT_DATA_ITEM;
}

@object GenTriggerClass MCChangeTrigger = {
	GI_visMoniker = "Change";
	GTI_destination = (TO_OBJ_BLOCK_OUTPUT);
	GTI_actionMsg = MSG_MCD_SET_DATA_ITEM;
}

@object GenTriggerClass MCDeleteTrigger = {
	GI_visMoniker = "Delete";
	GTI_destination = (TO_OBJ_BLOCK_OUTPUT);
	GTI_actionMsg = MSG_MCD_DELETE_DATA_ITEM;
}


@object GenValueClass MCValue = {
	GVLI_minimum = MakeWWFixed(0);
	GVLI_maximum = MakeWWFixed(0x7ffe);
	GVLI_value = MakeWWFixed(123);
}

@end 	Display;

/* The DOCGROUP resource contains our GenDocumentGroup object, and
 * will contain any GenDocument objects created by the GenDocumentGroup.
 */ 
@start 	DocGroup;
@object GenDocumentGroupClass MCDocumentGroup = {
	GDGI_attrs = (@default | GDGA_VM_FILE_CONTAINS_OBJECTS );
	GDGI_untitledName = "UntitledChart";
	GDGI_documentClass = (ClassStruct *) &MCDocumentClass;
	GDGI_documentControl = MCDocumentControl;
	GDGI_genDisplayGroup = MCDisplayGroup;
	GDGI_genView = MCChartView;
	GDGI_genDisplay = MCDisplay;
	GDGI_protocolMajor = MC_DOCUMENT_PROTOCOL_MAJOR;
	GDGI_protocolMinor = MC_DOCUMENT_PROTOCOL_MINOR;
}

@end 	DocGroup;

/* CODE for MCDocumentClass */

/* MSG_MCD_SET_DATA_ITEM_MONIKER for MCDocumentClass
	SYNOPSIS: Set the moniker for one of our Data List's items.
	CONTEXT: The Data List will send this message to the process
		 whenever it needs to display the moniker of a given
		 item. We should respond with one of the
		 MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_... messages.
	PARAMS: void (optr list, word item)
*/
@method MCDocumentClass, MSG_MCD_SET_DATA_ITEM_MONIKER {
/* If we're looking for the moniker of the "Data:" item,
 * just return that moniker. Otherwise, look up the
 * numerical value of the item as stored in the linked list. 
 */
	if (item==FAKE_LIST_ITEM) {
		optr 	moniker;
		moniker = ConstructOptr(OptrToHandle(list),
				OptrToChunk(@FakeItemMoniker));
		@send list::MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR(
				FAKE_LIST_ITEM, moniker);}

	else /* item > FAKE_LIST_ITEM */ {
		ChunkHandle 	tempListItem;
		ListNode 	*tempNode;
		char 		monikerString[LOCAL_DISTANCE_BUFFER_SIZE];
		word 		data;
		MemHandle	dataListBlock;
		MemHandle	*dataListBlockPtr = &dataListBlock;
		word 		ordinal = item;

		VMLock(pself->GDI_fileHandle,
		 pself->MCDI_dataFileBlock,
		 dataListBlockPtr);

		for(tempNode = LMemDerefHandles(dataListBlock,
						pself->MCDI_dataListHead);
		 ordinal > 1;
		 --ordinal)
			{
			 tempListItem = tempNode->LN_next;
			 tempNode = LMemDerefHandles(dataListBlock, tempListItem);
			}
		data = tempNode->LN_data;
		VMUnlock(dataListBlock);

		LocalFixedToAscii(monikerString, MakeWWFixed(data), 0);
		@call list::MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT(
						 item, monikerString);
	}
} /* end of MSG_MCD_SET_DATA_ITEM_MONIKER */

/* MSG_MCD_INSERT_DATA_ITEM for MCDocumentClass
 *
 *	SYNOPSIS: Add a new number to our list of data.
 *	CONTEXT: User wants to add a new piece of data.
 *	PARAMS: void(void)
 */
@method MCDocumentClass, MSG_MCD_INSERT_DATA_ITEM {
	ChunkHandle 	newListItem;
	ListNode 	*newNode;
	WWFixedAsDWord	value;
	word 		ordinal;
	MemHandle 	dataListBlock;
	MemHandle 	*dataListBlockPtr = &dataListBlock;
	optr 		ourList;
	optr 		ourValue;
	optr 		ourChart;
	DataBlockHeader *dataBlockHeader;
/* Query list and data objects to find out where to insert item
 * and what value to insert there. 
 */
	ourList = ConstructOptr(pself->GDI_display,
				OptrToChunk(@MCDataList));
	ordinal = @call ourList::MSG_GEN_ITEM_GROUP_GET_SELECTION();
	ourValue = ConstructOptr(pself->GDI_display,
				 OptrToChunk(@MCValue));
	value = @call ourValue::MSG_GEN_VALUE_GET_VALUE();

/* Lock the data block so we can insert data into the linked list. */
	dataBlockHeader = VMLock(pself->GDI_fileHandle,
		 	 pself->MCDI_dataFileBlock,
				 dataListBlockPtr);

/* Create a new linked list element. */
	newListItem = LMemAlloc(dataListBlock, sizeof(ListNode));
	newNode = LMemDerefHandles(dataListBlock, newListItem);
	newNode->LN_data = WWFixedToInt(value);

/* Check to see if the item we're adding will be the
 * new head of the data list and handle that case. 
 */
	if (ordinal==FAKE_LIST_ITEM)
	 {
		newNode->LN_next = pself->MCDI_dataListHead;
		pself->MCDI_dataListHead = newListItem;
	 }
	else
/* We're not adding to the head of the list. Traverse the
 * list using the tempListItem and tempNode variables, then
 * insert the new item. 
 */
	 {
		ListNode 	*tempNode;
		ChunkHandle 	tempListItem;
		word 		count = ordinal;

		for (tempNode = LMemDerefHandles(dataListBlock,
						 pself->MCDI_dataListHead);
		 count > 1;
		 --count)
		 {
			tempListItem = tempNode->LN_next;
			tempNode = LMemDerefHandles(dataListBlock,
					 	 tempListItem);
		 }
		newNode->LN_next = tempNode->LN_next;
		tempNode->LN_next = newListItem;
	 }

	dataBlockHeader->DBH_listHead = pself->MCDI_dataListHead;
	dataBlockHeader->DBH_numItems++;

/* We've changed the data, so before we unlock the block, we mark
 * it dirty. 
 */
	VMDirty(dataListBlock);
	VMUnlock(dataListBlock);

/* Update the data list gadget. */
	@send ourList::MSG_GEN_DYNAMIC_LIST_ADD_ITEMS(ordinal+1, 1);
	@send ourList::MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION(ordinal+1,
								 FALSE);

/* Update the chart */
	ourChart = ConstructOptr(pself->MCDI_chartMemBlock,
				 OptrToChunk(@MCChart));
	@send ourChart::MSG_MCC_INSERT_BAR(ordinal, WWFixedToInt(value));
} /* end of MSG_MCD_INSERT_DATA_ITEM */

/* MSG_MCD_DELETE_DATA_ITEM for MCDocumentClass
 *
 *	SYNOPSIS: Destroys one data item.
 *	CONTEXT: User has just clicked on the "Delete" trigger.
 *	PARAMS: void (void)
 */
@method MCDocumentClass, MSG_MCD_DELETE_DATA_ITEM {
	word 		ordinal;
	word 		count;
	ChunkHandle 	oldItem;
	ListNode	*oldNode;
	MemHandle 	dataListBlock;
	MemHandle 	*dataListBlockPtr = &dataListBlock;
	ChunkHandle 	tempListItem;
	ListNode 	*tempNode;
	optr 		ourList;
	optr 		ourChart;
	DataBlockHeader *dataBlockHeader;

	ourList = ConstructOptr(pself->GDI_display,
				OptrToChunk(MCDataList));

	ordinal = @call ourList::MSG_GEN_ITEM_GROUP_GET_SELECTION();
	if (ordinal==FAKE_LIST_ITEM) return;
	count = ordinal ;

	dataBlockHeader = VMLock(pself->GDI_fileHandle,
	 			 pself->MCDI_dataFileBlock,
	 			 dataListBlockPtr);

	if (ordinal == 1) {
		oldNode = LMemDerefHandles(dataListBlock,
					 pself->MCDI_dataListHead);
		tempListItem = oldNode->LN_next;
		LMemFreeHandles(dataListBlock, pself->MCDI_dataListHead);
		pself->MCDI_dataListHead = tempListItem;
	 }

	else {
		for (tempNode=LMemDerefHandles(dataListBlock,
					 pself->MCDI_dataListHead);
		 count > 2;
		 --count)
		 {
			tempListItem = tempNode->LN_next;
			tempNode = LMemDerefHandles(dataListBlock,
						 tempListItem);
		 }
		oldItem = tempNode->LN_next;
		oldNode = LMemDerefHandles(dataListBlock, oldItem);

		tempNode->LN_next = oldNode->LN_next;
		LMemFreeHandles(dataListBlock, oldItem);
	 }

	dataBlockHeader->DBH_listHead = pself->MCDI_dataListHead;
	dataBlockHeader->DBH_numItems--;

	VMDirty(dataListBlock);
	VMUnlock(dataListBlock);

	@send ourList::MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS(ordinal, 1);
	@send ourList::MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION(ordinal-1,
								 FALSE);

	ourChart = ConstructOptr(pself->MCDI_chartMemBlock,
				 OptrToChunk(@MCChart));

	@send ourChart::MSG_MCC_DELETE_BAR(ordinal-1);
} /* end of end of MSG_MCD_DELETE_DATA_ITEM */ 

/* MSG_MCD_SET_DATA_ITEM for MCDocumentClass
 *
 *	SYNOPSIS: Change the data number of one item in the data list.
 *	CONTEXT: User has clicked the "Change" button.
 *	PARAMS: void(void)
 */
@method MCDocumentClass, MSG_MCD_SET_DATA_ITEM {
	word 		ordinal;
	WWFixedAsDWord 	value;
	char 		monikerString[LOCAL_DISTANCE_BUFFER_SIZE];
	word 		count;
	MemHandle 	dataListBlock;
	MemHandle	*dataListBlockPtr = &dataListBlock;
	ChunkHandle 	tempListItem;
	ListNode 	*tempNode;
	optr 		ourList;
	optr 		ourValue;
	optr 		ourChart;

/* Find out which item we're changing. */
	ourList = ConstructOptr(pself->GDI_display,
				OptrToChunk(MCDataList));
	ordinal = @call ourList::MSG_GEN_ITEM_GROUP_GET_SELECTION();
	if (ordinal == FAKE_LIST_ITEM) return;

/* Find out what the item's new value should be. */
	ourValue = ConstructOptr(pself->GDI_display,
				 OptrToChunk(MCValue));
	value = @call ourValue::MSG_GEN_VALUE_GET_VALUE();

/* Lock the data block so that we can change the data. */
	VMLock(pself->GDI_fileHandle,
	 pself->MCDI_dataFileBlock,
	 dataListBlockPtr);
/* Find the appropriate item in the linked list and change its value. */
	for (tempNode = LMemDerefHandles(dataListBlock,
					 pself->MCDI_dataListHead),
	 count = ordinal-1;
	 count > 0;
	 --count)
	 {
		tempListItem = tempNode->LN_next;
		tempNode = LMemDerefHandles(dataListBlock, tempListItem);
	 }
	tempNode->LN_data = WWFixedToInt(value);

/* We changed the data so mark it dirty before unlocking it. */
	VMDirty(dataListBlock);
	VMUnlock(dataListBlock);

/* Update the data list gadget. */
	LocalFixedToAscii(monikerString, value, 0);
	@call ourList::MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT(
							ordinal,
							monikerString);

/* Update the chart. */
	ourChart = ConstructOptr(pself->MCDI_chartMemBlock,
				 OptrToChunk(@MCChart));
	@send ourChart::MSG_MCC_RESIZE_BAR(ordinal-1, WWFixedToInt(value));
} /* end of MSG_MCD_SET_DATA_ITEM */

/* MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE for MCDocumentClass
 *
 *	SYNOPSIS: Duplicate blocks and create a blank header.
 *	CONTEXT: Creating a new document.
 * 	PARAMS: Boolean(void);
 */
@method MCDocumentClass, MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE {
	VMBlockHandle 		chartFileBlock;
	MemHandle 		dataListBlock;
	MemHandle 		*dataListBlockPtr = &dataListBlock;
	DataBlockHeader 	*dataBlockHeader;

/* If superclass hits an error while trying to create the file, return
 * immediately, signalling that we hit an error. 
 */
	if (@callsuper()) return(TRUE); 
	pself = ObjDerefGen(oself);

/* Create the block which will hold our MCChart. */
	pself->MCDI_chartMemBlock =
			ObjDuplicateResource(OptrToHandle(@MCChart), 0, 0);
	chartFileBlock = VMAttach(pself->GDI_fileHandle,
				 0,
				 pself->MCDI_chartMemBlock);
	VMPreserveBlocksHandle(pself->GDI_fileHandle,
			 chartFileBlock);

/* Create the block which will hold our linked list */
	pself->MCDI_dataFileBlock = VMAllocLMem(pself->GDI_fileHandle,
						LMEM_TYPE_GENERAL,
						sizeof(DataBlockHeader));
	VMSetMapBlock(pself->GDI_fileHandle, pself->MCDI_dataFileBlock);
	dataBlockHeader = VMLock(pself->GDI_fileHandle,
		 		 pself->MCDI_dataFileBlock,
		 		 dataListBlockPtr);
	dataBlockHeader->DBH_listHead = NULL;
	dataBlockHeader->DBH_numItems = 1;
	dataBlockHeader->DBH_chartBlock = chartFileBlock;
	VMDirty(dataListBlock);
	VMUnlock(dataListBlock);

/* Assume no error encountered */
	return(FALSE); 
} /* end of MSG_GEN_DOCUMENT_INITALIZE_DOCUMENT_FILE */

/* MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT for MCDocumentClass
 *
 * 	SYNOPSIS: Load in chart block, initialize data list gadget.
 *	CONTEXT: Opening a file.
 *	PARAMS: void(void) 
 */
@method MCDocumentClass, MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT {
	MemHandle 		dataListBlock;
	MemHandle 		*dataListBlockPtr = &dataListBlock;
	DataBlockHeader *dataBlockHeader;
	word 			numItems;
	optr 			ourList;
	VMBlockHandle		chartFileBlock;
	optr 			ourChart;

	@callsuper();
	pself = ObjDerefGen(oself);

/* Get the block that contains our linked list and header info */
	pself->MCDI_dataFileBlock = VMGetMapBlock(pself->GDI_fileHandle);
	dataBlockHeader = VMLock(pself->GDI_fileHandle,
				 pself->MCDI_dataFileBlock,
				 dataListBlockPtr);

/* Extract the header info. */
	pself->MCDI_dataListHead = dataBlockHeader->DBH_listHead;
	numItems = dataBlockHeader->DBH_numItems;
	chartFileBlock = dataBlockHeader->DBH_chartBlock;
	VMUnlock(dataListBlock);

/* Made the MCChart a child of the document object. */
	pself->MCDI_chartMemBlock = VMVMBlockToMemBlock(pself->GDI_fileHandle,
							chartFileBlock);
	ourChart = ConstructOptr(pself->MCDI_chartMemBlock,
				 OptrToChunk(@MCChart));
	@send self::MSG_VIS_ADD_NON_DISCARDABLE_VM_CHILD(ourChart, CCO_FIRST);

/* Initialize the data list gadget. */
	ourList = ConstructOptr(pself->GDI_display,
				OptrToChunk(@MCDataList));
	@send ourList::MSG_GEN_DYNAMIC_LIST_INITIALIZE(numItems);
	@send ourList::MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION(0, FALSE);
} /* end of MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT */

/* MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
 *
 *	SYNOPSIS: Remove the chart object.
 * 	CONTEXT: Closing the document.
 *	PARAMS: void(void)
 */
@method MCDocumentClass, MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT {
	optr 			ourChart;

	@callsuper();

/* Remove the chart from the document. */
	ourChart = ConstructOptr(pself->MCDI_chartMemBlock,
				 OptrToChunk(@MCChart));
	@call ourChart::MSG_VIS_REMOVE_NON_DISCARDABLE( VUM_MANUAL );
}

/* CODE for MCChartClass */
/* MSG_VIS_DRAW for MCChartClass
 *
 *	SYNOPSIS: Draw the chart.
 *	CONTEXT: System has asked the chart object to draw itself.
 *	PARAMS: void(DrawFlags drawFlags, GStateHandle gstate)
 */
@method MCChartClass, MSG_VIS_DRAW {
	word 	count;
	word 	*barArray;
/* Draw the axis markers */
	GrDrawVLine(gstate,
		 CHART_LEFT-BORDER_MARGIN,
		 BORDER_MARGIN,
		 CHART_BOTTOM);
	GrDrawHLine(gstate,
		 CHART_LEFT,
		 CHART_BOTTOM+BORDER_MARGIN,
		 VIEW_RIGHT - BORDER_MARGIN);
	barArray = LMemDerefHandles(OptrToHandle(oself),
				 pself->MCCI_barArray);

/* Draw the bars */
	for (count = 0; count < pself->MCCI_numBars; count++)
	 {
		word 	top, bottom, left, right;

		bottom = CHART_BOTTOM;
		top = bottom - barArray[count];
		left = CHART_LEFT + (count * BAR_WIDTH_ALLOW);
		right = left + BAR_WIDTH;
		GrFillRect(gstate, left, top, right, bottom);
	 }
} /* end of MSG_VIS_DRAW */

/* MSG_MCC_INSERT_BAR
 *
 *	SYNOPSIS: Add another bar to bar chart.
 *	CONTEXT: The user has added another data item to the list.
 *	PARAMS: void(word ordinal, word value);
 */
@method MCChartClass, MSG_MCC_INSERT_BAR {
	word 		count;
	word 		*barArray;
/* Insert new bar into array, shifting other bars over */
	barArray = LMemDerefHandles(OptrToHandle(oself), pself->MCCI_barArray);
	for(count=pself->MCCI_numBars; count > ordinal; --count)
	 {
		barArray[count] = barArray[count-1];
	 }
	barArray[ordinal] = value;
	ObjMarkDirtyHandles(OptrToHandle(oself), pself->MCCI_barArray);

	pself->MCCI_numBars++;

/* Mark ourself as in need of a redraw. */
	@call self::MSG_VIS_MARK_INVALID(VOF_IMAGE_INVALID,
					 VUM_DELAYED_VIA_APP_QUEUE);
} /* end of MSG_MCC_INSERT_BAR */

/* MSG_MCC_DELETE_BAR
 *
 *	SYNOPSIS: Remove a bar from the bar chart.
 *	CONTEXT: User has deleted a data item from the list.
 *	PARAMS: void(word ordinal);
 */
@method MCChartClass, MSG_MCC_DELETE_BAR {
	word 		count;
	word 		*barArray;

/* Update our instance data and data array */
	pself->MCCI_numBars -=1;
	barArray = LMemDerefHandles(OptrToHandle(oself),
				 pself->MCCI_barArray);
	for(count=ordinal; count < pself->MCCI_numBars; count++)
	 {
		barArray[count] = barArray[count+1];
	 }
	ObjMarkDirtyHandles(OptrToHandle(oself), pself->MCCI_barArray);

/* Mark ourselves as in need of a redraw. */
	@call self::MSG_VIS_MARK_INVALID(VOF_IMAGE_INVALID,
					 VUM_DELAYED_VIA_APP_QUEUE);
} /* end of MSG_MCC_DELETE_BAR */

/* MSG_MCC_RESIZE_BAR
 *
 *	SYNOPSIS: Resize a bar.
 *	CONTEXT: User has changed the value of a data item.
 *	PARAMS: void(word ordinal, word value);
 */
@method MCChartClass, MSG_MCC_RESIZE_BAR {
	word 		*barArray;

/* Update the array */
	barArray = LMemDerefHandles(OptrToHandle(oself),
				 pself->MCCI_barArray);
	barArray[ordinal] = value;
	ObjMarkDirtyHandles(OptrToHandle(oself), pself->MCCI_barArray);

/* Mark ourself as in need of a redraw. */
	@call self::MSG_VIS_MARK_INVALID(VOF_IMAGE_INVALID,
					 VUM_DELAYED_VIA_APP_QUEUE);
} /* end of MSG_MCC_RESIZE_BAR */
~~~

[Views and Visual Objects](Views_and_Visual_Objects.md) <-- &nbsp;&nbsp; [table of contents](../Tutorial.md) &nbsp;&nbsp; --> [Troubleshooting Communications](Troubleshooting_Communications.md)
