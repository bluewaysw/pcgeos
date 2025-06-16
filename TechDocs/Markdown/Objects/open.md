# 21 Pen Object Library
The Pen Library provides routines and object classes which work together to 
form the backbone of a note-book style database storing pen input. 

An Ink object is a visual object and may be used by any application that 
wants to work with pen input. Though any targetable object may accept ink 
(see "Input," Chapter 11 of the Concepts Book), **InkClass** has many 
optimizations for working with ink. 

The Ink Database routines provide a front end to the standard GEOS 
Database (DB) library routines well suited for storing and organizing several 
small pieces of information. These routines allow the storage of notes within 
a hierarchical arrangement of folders. Each note may contain one or more 
pages of textual or ink information.

If you wish to work directly with the incoming pen input, read "Input," 
Chapter 11 of the Concepts Book to find out how to intercept pen events. To 
understand the inner workings of the Ink Database routines, you should be 
familiar with the DB library.

## 21.1 The Ink Object
**InkClass** provides methods for storing multiple pen inputs in a compact 
form. It automatically handles all queries about pen input. It handles 
display, with the power to display the ink in any color, and it allows the use 
of standard or custom background pictures.

To change the way the Ink class (or any other appropriate class) handles ink, 
the messages to subclass are MSG_META_NOTIFY_WITH_DATA_BLOCK (with 
the notification type MANUFACTURER_ID_GEOWORKS, NT_INK), 
MSG_META_QUERY_IF_PRESS_IS_INK, and 
MSG_VIS_QUERY_IF_OBJECT_HANDLES_INK.

### 21.1.1 Instance Data and Messages
When setting up an Ink object, probably the only pieces of instance data the 
application will be concerned with will be *II_flags*, *II_dirtyOutput*, and 
*II_dirtyMsg*.

Most of the flags are easy to understand, with the possible exceptions of the 
IF_HAS_TARGET and IF_DIRTY fields, which should not be set when creating 
the object in any case.

----------
**Code Display 21-1 InkClass Instance Data**

	/* 	II_flags:
	 * 	This field holds flags governing the object's behavior:
	 *		IF_MOUSE_FLAGS, 	
	 * 		IF_SELECTING, 		
	 * 		IF_HAS_TARGET,
	 *		IF_HAS_SYS_TARGET,
	 *		IF_DIRTY,
	 *		IF_ONLY_CHILD_OF_CONTENT, 
	 *		IF_CONTROLLED, (Set if to be used with an InkControl)
	 *		IF_INVALIDATE_ERASURES,
	 * 		IF_HAS_UNDO */
	@instance 	InkFlags 			II_flags = IF_HAS_UNDO;

	/* 	II_tool:
	 * 	This field keeps track of how the user is interacting with the Ink. There
	 * 	are three possible tools: IT_PENCIL, IT_SELECTOR, and IT_ERASER. */
	@instance 	InkTool 		II_tool;

	/* 	II_penColor:
	 * 	The color to use when drawing ink. */
	@instance 	Color 		II_penColor = C_BLACK;

	/* 	II_segments:
	 * 	Do not set this field explicitly. This field is a handle to the chunk array
	 * 	containing the pen segments. The segments are stored as an array of Point
	 * 	structures. The stored coordinates are all positive; any x coordinate with
	 * 	its sign bit set belongs to the last point in a gesture. Thus, a small 
	 * 	cross shape centered at (72, 72) might be stored:
	 * 		(0x0048, 0x0046) 
	 * 		(0x8048, 0x004A) [note sign bit set in x coordinate]
	 * 		(0x0046, 0x0048)
	 * 		(0x804A, 0x0048) [sign bit set in x coordinate]	*/
	@instance 	ChunkHandle 		II_segments;

	/* 	II_dirtyMsg, II_dirtyOutput:
	 * 	Together, these fields form an Action Descriptor. When the Ink processes
	 * 	a point of pen information, erases anything, or handles an undo event the
	 * 	IF_DIRTY flag will be set. If the flag was not set already, then the Ink
	 *	will send the AD's message to the AD's object. The handler for this message
	 * 	should probably clear the IF_DIRTY bit. */
	@instance optr			II_dirtyOutput;
	@instance Message	 	II_dirtyMsg;

	@instance Rectangle 	II_selectBounds;	/* Internal */
	@instance GStateHandle	II_cachedGState;	/* Internal */
	@instance TimerHandle 	II_antTimer;		/* Internal */
	@instance word 			II_antTimerID;		/* Internal */
	@instance byte			II_antMask;			/* Internal */

----------
Most of the Ink messages just change or retrieve the values of the instance 
fields. The exceptions are two messages will help those applications which 
need to save or transfer the Ink object's pen data. Use 
MSG_INK_SAVE_TO_DB_ITEM to save the pen data to an arbitrary DB item. 
If the application changes this information and wishes to pass it back to the 
ink object, use MSG_INK_LOAD_FROM_DB_ITEM.

----------
#### MSG_INK_SET_TOOL
	void 	MSG_INK_SET_TOOL(
			InkTool 	tool);

This message allows the Ink to switch between pencil and eraser tools, 
changing the *II_tool* field.

**Source:** Unrestricted.

**Destination:** Any Ink object.

**Parameters:**  
*tool* - A tool, either IT_PENCIL or IT_ERASER.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_INK_GET_TOOL
	InkTool 	MSG_INK_GET_TOOL();

This message returns the Ink's present tool, as stored in *II_tool*.

**Source:** Unrestricted.

**Destination:** Any Ink object.

**Parameters:** None.

**Return:** The present tool, either IT_PENCIL or IT_ERASER.

**Interception:** Unlikely.

----------
#### MSG_INK_SET_PEN_COLOR
	void 	MSG_INK_SET_PEN_COLOR(
			Color 	clr);

This message changes the color used to draw the ink, changing the value in 
*II_penColor*.

**Source:** Unrestricted.

**Destination:** Any Ink object.

**Parameters:**  
*clr* - Index to a palette (e.g. C_RED).

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_INK_SET_DIRTY_AD
	void 	MSG_INK_SET_DIRTY_AD(
			word	 method,
			optr	 object);

This message sets the Action Descriptor to be activated when the user dirties 
the object, changing the values in *II_dirtyMsg* and *II_dirtyOutput*.

**Source:** Unrestricted.

**Destination:** Any Ink object.

**Parameters:**  
*method* - The message to send when the object is dirty.

*object* - The object which should receive the above message.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_INK_SET_FLAGS
	void 	MSG_INK_SET_FLAGS(
			InkFlags 	setFlags,
			InkFlags 	clearFlags);

This message changes the value of the *II_flags* field. Note that something 
which sets the IF_DIRTY bit should probably also perform the action stored 
in the *II_dirtyMsg* and *II_dirtyOutput* fields.

**Source:** Unrestricted.

**Destination:** Any Ink object.

**Parameters:**  
*setFlags* - The flags to turn on.

*clearFlags* - The flags to turn off.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_INK_GET_FLAGS
	InkFlags 	MSG_INK_GET_FLAGS();

This message gets the value of the *II_flags* field.

**Source:** Unrestricted.

**Destination:** Any Ink object.

**Parameters:** None.

**Return:** The present value of the *II_flags* field.

**Interception:** Unlikely.

----------
#### MSG_INK_SAVE_TO_DB_ITEM
	void	MSG_INK_SAVE_TO_DB_ITEM(
			DBReturn		* RetValue,
			InkDBFrame		* ptr);

This message saves the Ink's pen data into the passed DB item. The pen data 
will be stored compressed. Calling this message sets the object not dirty.

**Source:** Unrestricted.

**Destination:** Any Ink object.

**Parameters:**  
*ptr* - A pointer to an **InkDBFrame** structure, shown 
below.

*RetValue* - A pointer to an empty **DBReturn** structure, to be 
filled by the handler.

**Return:** The structure pointed to by *RetValue* will contain the returned 
information.

**Structures:** The **InkDBFrame** and **DBReturn** structures are defined below:

	typedef struct {
		Rectangle			IDBF_bounds;
			/* The bounds of the Ink data */
		VMFileHandle		IDBF_vmFile;
			/* VM file to write to*/
		DBGroupAndItem 		IDBF_DBGroupAndItem;
			/* DB Item to save to 
			 * (or NULL to create a new one) */
		word 				IDBF_DBExtra;
			/* Extra space to skip at start
			 * of block */
	} InkDBFrame;

	typedef struct {
		word		DBR_group;
		word		DBR_item;
		word		DBR_unused1;
		word		DBR_unused2;
	} DBReturn;

**Interception:** Unlikely.

----------
#### MSG_INK_LOAD_FROM_DB_ITEM
	void	MSG_INK_LOAD_FROM_DB_ITEM(
			InkDBFrame 	*ptr);

This message loads the compressed data into the Ink from the passed DB 
item. If a NULL handle is passed, then the Ink is cleared. This message 
marks the Ink as clean. 

**Source:** Unrestricted.

**Destination:** Any Ink object.

**Parameters:**  
*ptr* - A pointer to an **InkDBFrame** structure.

**Return:** Nothing.

**Structures:** For the **InkDBFrame** structure, see MSG_INK_SAVE_TO_DB_ITEM.

**Interception:** Unlikely.

### 21.1.2 Storing Ink to DB Items
Pen information comes in as a MSG_META_NOTIFY_WITH_DATA_BLOCK of 
type NT_INK accompanied by an array containing the coordinates visited by 
the pen. The pen data keeps track of the coordinates of the pen input. Every 
time pen input comes in, the ink object notes the coordinates. The ink object 
is optimized to save space. For instance, the Ink object eliminates collinear 
points: if three pen events are collinear, it will not record the middle one, 
recognizing it as redundant.

The non-redundant points are written out to the *II_segments* field, a chunk 
array of Point structures. Note that the coordinates are unsigned. If a point's 
x coordinate's sign bit is set, that does not mean that the x coordinate is 
negative; if this sign bit is set this is a signal that this point is the last point 
of a gesture.

![image info](Figures/Fig21-1.png)  
**Figure 21-1** *Typical Pen Input*  
*Normally, pen input to an Ink object will be mostly made up of horizontal 
or vertical strokes.*

When writing pen data to a DB item, the Ink object does some more 
compression. Applications which work with the items used by 
MSG_INK_SAVE_TO_DB_ITEM and MSG_INK_LOAD_FROM_DB_ITEM must 
work with this compression. Since the user is dragging the pen around in a 
continuous gesture, the pen events tend to occur close together. Thus, it is 
nice to have a way to record a coordinate as a small offset from another 
coordinate. Since many strokes are almost horizontal or vertical, quite often 
the horizontal or vertical offset will be zero or one. 

To take advantage of these tendencies, the ink object stores pen input as a 
bitstream. Coordinates may be recorded either as absolute positions or as 
offsets from the last coordinate. See Table 21-1 for a list of components of this 
bitstream. 

**Table 21-1** Components of the Ink's Bitstream

	Bit Pattern					Meaning						Total Bits
	00							0 offset							2
	01							+1 offset							2
	10 00 000					terminate segment					7
	10 00 001					+2 offset							7
	10 00 010					+3 offset							7
	10 00 011 					+4 offset							7
	10 00 100					+5 offset							7
	10 00 101 					+6 offset							7
	10 00 110 					+7 offset							7
	10 00 111 					+8 offset							7
	10 01 000					(reserved for future use)			7
	10 01 001 					-2 offset							7
	10 01 010					-3 offset							7
	10 01 011 					-4 offset							7
	10 01 100					-5 offset							7
	10 01 101 					-6 offset							7
	10 01 110 					-7 offset							7
	10 01 111 					-8 offset							7
	10 10 xxxxxx 				6-bit keyword (reserved)			10
	10 11 xxxx xxxx xxxx xxx	15-bit (unsigned) absolute position	19
	11 							-1 offset							2

When writing out a gesture to a DB item, the first point will always be 
recorded as an absolute position. Thus, first the *x* coordinate will be recorded, 
then the *y* coordinate. Each coordinate will be marked as absolute by the 
1011 bit pattern.

For each subsequent pen point, the algorithm will first make sure that the 
new point is not collinear with the previous two. If it is, then the algorithm 
will make the incoming pen event overwrite the previous event's coordinates.

For each event, the algorithm will first write out the *x* coordinate, then the *y* 
coordinate.

+ If the coordinate is at 0 or 1 offset from the previous coordinate, the 
algorithm will write out the appropriate two-bit code (00, 01, or 11).

+ If the coordinate is at an offset from the previous coordinate between 2 
and 8, then the algorithm will write out the appropriate 7 bit code 
(1000xxx for a positive offset, 1001xxx for a negative offset).

+ If the coordinate is more than 8 points from the previous coordinate, the 
algorithm writes out 1011 followed by the absolute coordinate, 
represented as a 15 bit unsigned quantity.

When the input is finished, the algorithm writes a 1000000 bit pattern, 
signalling the end of the segment.

Decompressing the data is a matter of traversing the bitstream and detecting 
the appropriate patterns.

As an example of how the algorithm compresses pen input, suppose the Ink 
object were writing the following gesture to a DB item:

	(72, 71)
	(82, 74)
	(84, 74)
	(85, 72)

The first coordinate is 72, so the algorithm will write out:  
*1011* (signals absolute coordinate) *000000001001000*  
The second coordinate is 71, so after handling the second coordinate, the 
stream will be:  
1011 000000001001000 *1011* *000000001000111*  
The *x* coordinate of the second point is 82, which is 10 points away from the 
previous *x* coordinate. Unfortunately, this is too far to express as a short 
offset, so the algorithm writes another absolute coordinate (the new part of 
the stream is shown in italics):  
1011 000000001001000 1011 000000001000111 *1011* *000000001010010*  
The *y* coordinate of the second point is 74, at a positive 3 offset from the 
previous *y* value, so the algorithm will write out the appropriate offset code 
instead of an absolute position code:  
...1011 000000001000111 1011 000000001010010 *10 00 010*  
The third point's *x* coordinate is 84, at a +2 offset from 82. The *y* coordinate 
is 74, the same as the previous point's *y* coordinate:  
...1011 000000001000111 1011 000000001010010 10 00 010 *10 00 001 00*  
The last point's *x* coordinate is one higher than the previous; its *y* coordinate 
is two less.  
...1011 000000001010010 10 00 010 10 00 001 00 *01 10 01 001*  
Since it has reached the end of the pen input (this was a suspiciously short 
gesture, a somewhat contrived example), the algorithm then writes an 
end-of-segment code:  
...1011 000000001010010 10 00 010 10 00 001 00 01 10 01 001 *10 00 000*  
If the Ink object were holding more than one gesture of information, it would 
write the next gesture's elements starting after the end-of-segment code of 
the first.

## 21.2 Working with the Ink DB
The Ink Database provides a simplified, specialized API to the database 
library. It allows the user to organize pieces of information on notes stored in 
a hierarchy of folders. Each note may have one or more pages, with each page 
corresponding to the contents of an ink or text object. The data stored in each 
page is a DB item returned by MSG_INK_SAVE_TO_DB_ITEM (for Ink objects) 
or MSG_VIS_TEXT_GET_ALL_DB_ITEM (for Text objects).

Notes and folders are specified by means of a dword identifier. This identifier 
has nothing to do with where the note's (or folder's) data is stored, or where 
it appears in the folder tree. Applications should use the **InkLoadPage()** 
and **InkSavePage()** routines to work with a note's data, and use the 
routines described below to determine where a note or folder appears in the 
folder tree.

### 21.2.1 Getting Started
	InkDBInit()

To create an Ink Database, an application needs a file handle, perhaps the 
file holding a GenDocument's data. Before calling any other Ink Database 
functions, call **InkDBInit()** to set up the file correctly; this routine should be 
called exactly once per Ink DB. If the database is part of a GenDocument, 
then this routine should be called within the 
MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE. Other routines 
(described below) which might be appropriate when first setting up an Ink 
Database include **InkSetDocPageInfo()** and **InkSetDocGString()**.

### 21.2.2 Displaying the Data
	InkNoteLoadPage(), InkNoteSavePage(), InkGetDocPageInfo(), 
	InkSetDocPageInfo(), InkSetDocGString(), 
	InkGetDocGString(), InkNoteGetNoteType()

Assuming that the application is using text and ink objects to display the 
information held in the Ink DB, use **InkNoteLoadPage()** and 
**InkNoteSavePage()** to transfer information between the Ink object and the 
Ink DB. **InkNoteLoadPage()** loads an ink or text object with the data stored 
within the passed note. Use **InkNoteGetNoteType()** to determine what 
sort of data is stored within the note. Once the user has made changes, those 
changes should be stored to the database. Call **InkNoteSavePage()** to write 
the changes. 

To find out the document size associated with an Ink Database, call 
**InkGetDocPageInfo()**. To change the page size, call 
**InkSetDocPageInfo()**.

The Ink DB routines support the notion of a background picture for ink 
information. There is one background picture for the entire database. To set 
the background picture, use **InkSetDocGString()**. To find out the current 
background picture, call **InkGetDocGString()**.

The background GString is stored in VM; call **GrLoadGString()** and 
**GrDrawGString()** to draw it.

### 21.2.3 Titles and Keywords
	InkNoteSetKeywords(), InkNoteSetKeywordsFromTextObject(), 
	InkNoteGetKeywords(), InkNoteSendKeywordsToTextObject(), 
	InkGetTitle(), InkSendTitleToTextObject(), 
	InkFolderSetTitle(), InkFolderSetTitleFromTextObject(), 
	InkNoteSetTitle(), InkNoteSetTitleFromTextObject()

Each note may have two text strings which are helpful for identification: a 
title and a set of keywords. These words may be used as the fields for a 
computed search if the application supports these; regardless, the user will 
certainly find these fields useful for organizing notes.

To set a note's title, call **InkNoteSetTitle()**. There is a corresponding 
**InkFolderSetTitle()** for setting the title of a folder. Since applications may 
wish to set the titles of these items based upon the user's entry in a text 
object, there are two routines **InkNoteSetTitleFromTextObject()** and 
**InkFolderSetTitleFromTextObject()** which take an item's name from a 
text object. **InkGetTitle()** gets any item's title, and 
**InkSendTitleToTextObject()** is a specialized function used to update the 
passed text object's text to hold the item's title. The maximum length of any 
title should be INK_DB_MAX_TITLE_SIZE.

Notes may have keywords: words which should not appear in the title but 
which are still useful for searches. Folders do not have keywords. To set a 
note's keywords, use **InkNoteSetKeywords()**; to use the contents of a text 
object as the keywords, use **InkNoteSetKeywordsFromTextObject()**. To 
retrieve the keywords, call **InkNoteGetKeywords()**. 
**InkNoteSendKeywordsToTextObject()** replaces a text object's text with 
the passed note's keywords. The maximum length of any keyword should be 
INK_DB_MAX_NOTE_KEYWORDS_SIZE.

### 21.2.4 Navigating the Folder Tree
	InkDBGetDisplayInfo(), InkDBSetDisplayInfo(), 
	InkDBGetHeadFolder(), InkGetParentFolder(), 
	InkFolderGetContents(), InkFolderGetNumChildren(), 
	InkFolderDisplayChildInList(), InkFolderGetChildInfo(), 
	InkFolderGetChildNumber(), InkNoteGetNumPages()

Assuming the application allows the existence of more than one folder, it 
must allow some way to move around within the folder tree. If the application 
allows the user to change the structure of the folder tree, then it will need UI 
which allows the user to navigate an arbitrary tree. There are routines to find 
out and change which page is being displayed. For those applications which 
will need to get information about the folder tree, there are routines to get 
information about the folder tree.

To find the application's current location within the DB, call 
**InkDBGetDisplayInfo()**. This routine returns the current folder ID, the 
note ID if any is selected, and the page number within the note. To go to a 
different location, call **InkDBSetDisplayInfo()**. To use this routine, the 
application must pass a folder ID, along with a valid note ID and page number 
if a note is to be selected. 

Chances are the user will be maneuvering within the folder tree. To get the 
ID of the root folder, use **InkDBGetHeadFolder()**. To find the parent folder 
of the passed parent or note, call **InkGetParentFolder()**. 
**InkFolderGetContents()** returns two chunk arrays, one containing the 
double word identifiers of all the folder's subfolders, the other containing the 
identifiers of the folder's child notes. **InkFolderGetNumChildren()** 
returns the number of subfolders and notes within a folder. 

To display a note or folder's name in a GenDynamicList, use 
**InkFolderDisplayChildInList()**. This routine comes in handy when 
constructing UI for navigating the folder tree. To copy the icon and folder or 
note name of a folder or note into the visual moniker of an entry in a list, call 
**InkNoteCopyMoniker()**.

To get information about a folder's child, call **InkFolderGetChildInfo()**. 
This routine returns a bit specifying whether the child is a folder or note, 
along with the child's ID number. The **InkFolderGetChildNumber()** 
routine returns the passed child's place number within the folder.

### 21.2.5 Managing Notes and Folders
	InkFolderCreateSubFolder(), InkFolderMove(), 
	InkFolderDelete(), InkNoteCreate(), InkNoteDelete(), 
	InkNoteMove(), InkNoteCreatePage()

Some Ink DB applications might just create a hierarchy of notes and not 
allow the user to move or change notes. Applications that will move notes and 
folders should use the following functions to make changes.

The **InkFolderCreateSubFolder()** routine creates a new folder as a child 
of the passed existing folder. Use **InkFolderMove()** to move a folder to a 
new parent folder. **InkNoteMove()** similarly moves a note to a new parent 
folder. **InkFolderDelete()** deletes a folder and all subfolders and notes that 
folder contained. **InkNoteCreate()** creates a new note. **InkNoteDelete()** 
deletes a note. **InkNoteCreatePage()** adds a new page to a note.

### 21.2.6 Manipulating Notes
	InkNoteGetPages(), InkNoteGetNumPages(), 
	InkNoteSetModificationDate(), 
	InkNoteGetModificationDate(), InkNoteGetCreationDate(), 
	InkNoteSetNoteType(), InkNoteGetNoteType()
	
Normally, the note will store information supplied by an Ink or Text object. 
However, applications may work with a note's information directly. Call 
**InkNoteGetPages()** to get the DB item in which the note's information is 
stored. The DB item contains a chunk array; each entry of the array contains 
the information for one page (the DB item associated with an Ink or Text 
object). To find out how many pages there are in a given note, call 
**InkNoteGetNumPages()**.

The note will be expecting either text or ink; call **InkNoteSetNoteType()** to 
specify what sort of data will be coming in. The note type is specified by 
means of a NoteType value: NT_INK or NT_TEXT. To find out a note's type, 
call **InkNoteGetNoteType()**.

When writing changes, you may wish to update the note's modification date. 
Call **InkNoteSetModificationDate()** to update this information. To find 
out the date last modified, call **InkNoteGetModificationDate()**. To find out 
the date the note was created, call **InkNoteGetCreationDate()**.

### 21.2.7 Searching and Traversing the Tree
	InkNoteFindByTitle(), InkNoteFindByKeywords(), 
	InkFolderDepthFirstTraverse()

Sometimes the user will remember what a note is called, but has lost it in the 
tree of folders. Sometimes the user will want to find all notes which contain 
a certain keyword. Use **InkNoteFindNoteByTitle()** to get a buffer 
containing IDs of all notes whose titles match the passed string. 
**InkNoteFindNoteByKeywords()** similarly returns a buffer containing the 
IDs of all notes with matching keywords.

For more complicated commands, **InkFolderDepthFirstTraverse()** allows 
the application to perform a depth-first traversal of the folder tree, calling the 
passed routine with all encountered folders.

## 21.3 InkControlClass
**InkControlClass**, a subclass of **GenControlClass**, provides a menu which 
allows the user to select an Ink tool for use with an Ink object.

----------
**Code Display 21-2 InkControlClass Features**

	typedef ByteFlags 	InkControlFeatures;
	/* These features may be combined using | and &:
		ICF_PENCIL_TOOL,
		ICF_ERASER_TOOL 
		ICF_SELECTION_TOOL */

	typedef ByteFlags 	InkControlToolboxFeatures;
	/* These features may be combined using | and &:
		ICTF_PENCIL_TOOL,
		ICTF_ERASER_TOOL 
		ICTF_SELECTION_TOOL */

	#define IC_DEFAULT_FEATURES 			(ICF_PENCIL_TOOL | ICF_ERASER_TOOL | \
											 ICF_SELECTION_TOOL)
	#define IC_DEFAULT_TOOLBOX_FEATURES 	(ICTF_PENCIL_TOOL | ICTF_ERASER_TOOL | \
											 ICTF_SELECTION_TOOL)

	/* Add this controller to the application's self-load options GCN list. */

----------

[Spreadsheet Objects](ossheet.md) <-- [Table of Contents](../objects.md) &nbsp;&nbsp; --> [Config Library](oconfig.md)

