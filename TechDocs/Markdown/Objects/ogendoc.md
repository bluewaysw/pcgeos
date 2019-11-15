# 13 GenDocument
The GEOS document control objects let the programmer ignore most of the 
details of opening, closing, and saving files. The programmer just specifies 
the characteristics the application will expect of its documents. The 
document control presents all dialog boxes and notices to the user, and it 
maintains the "Save," "Save As," "Open," "New," and "Revert" triggers in the 
File menu.

There are three parts to the document control: the GenDocumentControl 
object, which maintains the user interface; the GenDocuments, each of which 
manages a single document; and the GenDocumentGroup object, which 
creates and manages GenDocument objects as needed. These classes can all 
be subclassed to add functionality.

You should be familiar with user interface objects in general before reading 
this chapter (see "The GEOS User Interface," Chapter 10 of the Concepts 
Book). You should also have some knowledge of the GEOS file system (see 
"File System," Chapter 17 of the Concepts Book) and of VM files (see "Virtual 
Memory," Chapter 18 of the Concepts Book).

## 13.1 Document Control Overview
A program that creates or uses files - in short, almost all applications - has 
to deal with many tasks. It has to present dialog boxes to the user so he can 
choose which file to open; it must give alert messages when the user tries to 
do something dangerous, like quit without saving; and it must notice when 
GEOS is being shut down and make sure it saves appropriate data.

The document control objects make these tasks much easier. They take care 
of some of these tasks by themselves; for example, they maintain the File 
menu commands and display dialog and alert boxes as needed. The 
Document Control objects make other application jobs much easier by 
sending messages at appropriate times. They can also manage several 
documents at once, making it much easier for applications to manage 
multiple documents.

Many different document control sample applications are provided with the 
SDK. In most cases, you should be able to get your document control by 
copying over code from the appropriate sample application, then customizing 
it.

### 13.1.1 The Document Control Objects
There are three different classes of objects which together constitute the 
document control. These are **GenDocumentControlClass**, 
**GenDocumentGroupClass**, and **GenDocumentClass**. A document will 
need at least one of each to use the document control technology. The 
relationship between the objects is diagrammed in Figure 13-1.

![image info](Figures/Fig13-1.png)  
**Figure 13-1** *Document Ctrl Object Relationships*  
*This diagram shows the arrangement between the different document control 
objects. Note that the application will not declare GenDocument objects; the 
GenDocumentGroup object will create them at run-time.*

#### 13.1.1.1 GenDocumentControlClass
An application will have one object of class **GenDocumentControlClass**. 
This object manages the user interface: It presents some dialog and alert 
boxes, it manages the File Selector, it creates appropriate entries for the File 
menu, and it updates the enabled/disabled states of these items (e.g. it 
disables the Save trigger after the file has been saved).

The GenDocumentControl is generally made a child of the file menu, which 
is itself a child (or descendant) of the GenPrimary. The GenDocumentControl 
is on the GenPrimary's active list. It has no children, but it does have an optr 
to the GenDocumentGroup object. By convention, the GenDocumentControl 
object is in the same data segment as the GenPrimary object. Certain 
attributes of the GenDocumentControl object will determine the 
characteristics of the File Selector and other UI gadgets.

**GenDocumentControlClass** is a subclass of **GenControlClass**. This 
means that you can set up toolboxes to perform the "Save," "Open," etc., 
actions. For more details, see "Generic UI Controllers," Chapter 12.

#### 13.1.1.2 GenDocumentGroupClass
An application will have one object of class **GenDocumentGroupClass**. 
This object creates and manages the document objects. Ordinarily, the 
document objects belong to **GenDocumentClass**. However, if the program 
wishes to alter the behavior of the document object, it can create a subclass 
of **GenDocumentClass**. In this case, the GenDocumentGroup object will 
contain a pointer to the class definition of the document subclass, and will 
create document objects of this class as needed.

The GenDocumentGroup object is a child of any object. It does not have any 
children when it is declared; however, it will dynamically give itself 
document-object children at run-time. It is in its own data segment. Certain 
of its attributes determine what the attributes of its document children will 
be.

#### 13.1.1.3 GenDocumentClass
Each GenDocument object manages a single open file. It keeps track of the 
volume, path, and filename for the document, the dirty state of the document, 
and other document-related information. It opens and closes files and 
presents file-related dialog boxes (e.g., "Save changes before closing?"). 
Programs often define a subclass of the **GenDocumentClass** which has 
additional, application-related functionality. In this case, objects of the 
subclass are used instead of objects of **GenDocumentClass**.

**GenDocumentClass** is a subclass of **GenContentClass**. Therefore, 
document objects can receive the output of GenView objects. GenDocument 
objects have all the functionality of GenContent objects. GenContent objects 
are themselves subclassed from **GenClass**. Very few applications will use 
the GenContent objects directly; for that reason, they are documented in this 
chapter.

Document objects are not declared in the source code; they are created at 
run-time by the GenDocumentGroup object. The document currently active 
is called the *target document*. 

### 13.1.2 Document Control Interaction
A simple user operation will usually involve all three types of objects. For 
example, suppose the user selects the *Open* trigger from the File menu. The 
following actions will be taken:

1. The Open trigger sends a 
MSG_GEN_DOCUMENT_CONTROL_INITIATE_OPEN_DOC to the 
GenDocumentControl object. The GenDocumentControl object responds 
by displaying a file selector.

2. When the user selects a file and clicks "OK," the GenDocumentControl 
object gets the selected file's path from the file selector object.

3. The GenDocumentControl object sends a 
MSG_GEN_DOCUMENT_GROUP_OPEN_DOC to the GenDocumentGroup, 
passing the name and path of the file to open.

4. The GenDocumentGroup creates a document object, either of class 
**GenDocumentClass** or of a programmer-specified class. The 
GenDocumentGroup object sends a MSG_GEN_DOCUMENT_OPEN to the 
document object, passing the file and path name to be opened.

5. The document object opens the file specified and handles errors 
appropriately. It then sends messages to the application instructing it to 
create the UI and initialize the file.

Most of these steps are transparent to the application programmer. Typically, 
an application will intercept 
MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE; the programmer 
needs only to write this handler, not all the code needed for the above steps.

### 13.1.3 Document Control Models
GEOS allows two distinct models of document control, a *Procedural* model 
and an *Object* model. While the two models use the same objects, they 
embody different programming philosophies.

The *Procedural* model of document control is much like traditional, 
non-object-oriented programming. Under this model, whenever a situation 
arises that needs the application's attention, the document control objects 
will send a message to a single object (generally the Process object). This 
object handles all of these situations.

Under the *Object* model of document control, the application defines a 
subclass of **GenDocumentClass**. This new document class has methods to 
handle situations needing the application's attention. This model is based on 
the philosophy of object-oriented programming; each document object has 
code to handle situations arising for that document.

The main difference between the two models is where the messages are sent. 
Under the Procedural model, messages are sent to the Process object; under 
the Object model, messages are sent to the appropriate document object. 
Every message sent in the Procedural model corresponds to a message sent 
in the Object model.

The Procedural model is simpler to use; it does not require the application to 
subclass objects. It is thus well-suited for simple applications which will have 
only one file open at a time. It may also be an easier model for programmers 
who are new to object-oriented programming. The Object model, on the other 
hand, is best suited for applications which will have may documents open at 
once; the application can let every document object manage a single 
document without worrying about other open documents.

#### 13.1.3.1 The Procedural Model
The *Procedural* model of document control is much like traditional, 
procedure-oriented programming. This model is simpler to implement than 
the object-model. It is well suited for simple applications which have only one 
document open at a time.

Under the Procedural model of document control, every time a situation 
arises which requires the application's attention, the document control 
objects will send an appropriate message to the GenDocumentGroup object's 
output. These messages are imported from **MetaClass**, so all objects can 
handle them. The application will generally use global variables for run-time 
data storage.

For example, when a new document needs to be initialized, the document 
control sends a MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE to 
its output object. The output object takes any appropriate steps (e.g., storing 
the file handle, setting up the map block, etc.).

#### 13.1.3.2 The Object Model
The *Object* model of document control is better suited to advanced 
applications and applications which will have more than one document open 
at a time. Under this model, the application defines a subclass of 
**GenDocumentClass**. This new document class has handlers for situations 
requiring the application's attention. It also has local variables (i.e., instance 
data fields) which store any information the application will need about this 
document. 

Whenever a situation arises that needs the application's attention, the 
relevant document object will send a message to itself. This document object 
will then handle the message. For example, an application might define its 
own document class, **MyAppDocumentClass** (a subclass of 
**GenDocumentClass**). Suppose a new document has been created and 
needs to be initialized. First, the GenDocumentGroup object will create a 
new document object by instantiating an object of **MyAppDocumentClass**. 
Next, the new document object will send itself a 
MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE. 
**MyAppDocumentClass** will have a handler for this message; the handler 
will initialize the file as well as the document object's data structures.

#### 13.1.3.3 Messages Under the Two Models
The simplest way to show the difference between the two models is to see how 
a single event is handled. This section examines one specific case, in which a 
document needs to be initialized; other cases are handled analogously.

Suppose a situation arises needing the application's attention; for example, 
a document is created and needs to be initialized. First, the document object 
will send an appropriate message to itself. In this case, it would send itself 
the message MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE. If the 
application uses a subclass of **GenDocumentClass** and this subclass has a 
handler for MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE, the 
messager will call that method; otherwise, the messager will call the handler 
defined for this message by **GenDocumentClass**. The handler in 
**GenDocumentClass** will find out the GenDocumentGroup object's 
output optr. If this optr is non-null, the handler will send an appropriate 
message (in this case, 
MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE) to the output 
object.

Note that, under normal circumstances, the application will handle only one 
of the two messages. For example, if the application writes a handler for 
MSG_GEN_DOCUMENT_PHYSICAL_SAVE, the handler defined by 
**GenDocumentClass** will not be called; as a result, 
MSG_META_DOC_OUTPUT_PHYSICAL_SAVE will not be sent to the 
GenDocumentGroup object's output. This is not usually a problem, since 
the application will generally handle one message or the other. If, for some 
reason, it needs to have both messages sent, the handler for 
MSG_GEN_DOCUMENT_SAVE should contain a **@callsuper** instruction.

## 13.2 Document Control Data Fields
This section describes the attributes of the two document control classes, 
**GenDocumentControlClass** and **GenDocumentGroupClass**, as well as 
of the **GenDocumentClass**. Note that GenDocument objects are created at 
run-time, and their attributes are initialized by the creating 
GenDocumentGroup object. However, their attributes can be changed with 
the appropriate messages.

Many of the messages to the GenDocumentControl have corresponding 
messages to the GenDocumentGroup. For example, to find out the 
GenDocumentControl's attributes, one can either send a 
MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS to the GenDocumentControl 
or send a MSG_GEN_DOCUMENT_GROUP_GET_UI_ATTRS to the 
GenDocumentGroup. In either case, the message will return the same result. 
It is sometimes more convenient to send a message to the 
GenDocumentGroup object; for example, a document object can do this with:

	@call @genParent::<message>

### 13.2.1 GenDocumentControl Data
The GenDocumentControl handles interaction between the document control 
and the user. It maintains the File menu entries and manages the file 
selector. Its attributes all relate to these duties. A complete list of the 
attributes follows in Code Display 13-1 along with comments and the default 
values.

Some of these data fields can be examined but not set by the application. 
Data fields for purely internal use (which are neither examined, nor set, by 
applications) are not listed.

----------
Code Display 13-1 GenDocumentControl Instance Data

	/* The GDCI_documentToken field specifies the token characters and token ID of
	 * files managed by this document control. All files created by the document
	 * control will have these token characters, and the File Selector object will be
	 * set to allow only such files to be selected. This attribute is ignored if DOS
	 * files are being opened. */
	@instance GeodeToken			GDCI_documentToken = {};

	/* GDCI_selectorType determines which files will be displayed by the File Selector 
	 * generated by this object. Only one of the options may be set. By default, only
	 * documents are visible. */
	@instance GenFileSelectorType	GDCI_selectorType = GFST_DOCUMENTS;
		/* Types available: 
		 *	GFST_DOCUMENTS, 		GFST_EXECUTABLES, 
		 * 	GFST_NON_GEOS_FILES, 	GFST_ALL_FILES */

	/* GDCI_attrs specifies certain characteristics of the file to be opened. The
	 * default setting is shown below. */
	@instance GenDocumentControlAttrs	GDCI_attrs = 
					((GDCM_SHARED_SINGLE << GDCA_MODE_OFFSET) |
					 GDCA_VM_FILE | 
					 GDCA_SUPPORTS_SAVE_AS_REVERT |
					 (GDCT_NEW << GDCA_CURRENT_TASK_OFFSET))
		/* Attributes available:
		 * GDCA_MODE: 
		 *		GDCM_VIEWER, 		GDCM_SHARED_SINGLE,
		 *		GDCM_SHARED_MULTIPLE
		 * GDCA_CURRENT_TASK: 
		 *	 	GDCT_NONE, 			GDCT_NEW, 
		 *	 	GDCT_OPEN, 			GDCT_USE_TEMPLATE, 
		 *		GDCT_SAVE_AS,		GDCT_COPY_TO,
		 *		GDCT_DIALOG,		GDCT_TYPE,
		 *		GDCT_PASSWORD
		 * Other fields: 
		 *	 	GDCA_MULTIPLE_OPEN_FILES,		GDCA_DOS_FILE_DENY_WRITE,
		 *		GDCA_VM_FILE, 					GDCA_NATIVE,
		 *	 	GDCA_SUPPORTS_SAVE_AS_REVERT,	GDCA_DOCUMENT_EXISTS,
		 *		GDCA_DO_NOT_SAVE_FILES
		 */

	/* GDCI_features specifies certain extra features of the document control. The
	 * default setting is shown below. */
	@instance GenDocumentControlFeatures	GDCI_features = 
				(GDCF_READ_ONLY_SUPPORTS_SAVE_AS_REVERT |
				 GDCF_SINGLE_FILE_CLEAN_CAN_NEW_OPEN |
				 GDCF_SUPPORTS_TEMPLATES |
				 GDCF_SUPPORTS_USER_SETTABLE_EMPTY_DOCUMENT |
				 GDCF_SUPPORTS_USER_MAKING_SHARED_DOCUMENTS |
				 GDCF_NAME_ON_PRIMARY);
		/* Flags available: 
		 *	GDCF_READ_ONLY_SUPPORTS_SAVE_AS_REVERT,
		 *	GDCF_SINGLE_FILE_CLEAN_CAN_NEW_OPEN, 
		 * 	GDCF_SUPPORTS_TEMPLATES,
		 *	GDCF_SUPPORTS_USER_SETTABLE_EMPTY_DOCUMENT,
		 *	GDCF_SUPPORTS_USER_SETTABLE_DEFAULT_DOCUMENT,
		 *	GDCF_SUPPORTS_USER_MAKING_SHARED_DOCUMENTS,
		 *	GDCF_NAME_ON_PRIMARY */

	/* GDCI_enableDisableList specifies objects which should be enabled whenever a
	 * document is opened and disabled when all documents are closed. The field is the
	 * handle of a chunk containing a list of optrs to the objects to be enabled and
	 * disabled. The default value is a null handle.*/
	@instance ChunkHandle			GDCI_enableDisableList;

	/* The GDCI_openGroup, GDCI_importGroup, GDCI_useTemplateGroup, GDCI_saveAsGroup,
	 * GDCI_exportGroup, and GDCI_userLevelGroup attributes hold optrs to groups of UI
	 * objects to be added to the "Open," "Import," "Use Template," "Save As,"
	 * "Export," and "User Level", dialog boxes, respectively. The GDCI_dialogGroup
	 * field holds an optr to objects to be added to the opening dialog box. The optr
	 * is to the head of a tree of UI objects. The top object in the tree should be
	 * set "not usable." Default values are all null optrs. */
	@instance optr				GDCI_openGroup;
	@instance optr				GDCI_importGroup;
	@instance optr				GDCI_useTemplateGroup;
	@instance optr				GDCI_saveAsGroup;
	@instance optr				GDCI_exportGroup;
	@instance optr				GDCI_dialogGroup;
	@instance optr				GDCI_userLevelGroup;

	/* If the GDCI_features field includes "displayNameOnPrimary" but no document is
	 * open, the Primary's moniker is set to the string pointed to by the
	 * GDCI_noNameText attribute. The default value is a null chunk handle. */
	@instance ChunkHandle				GDCI_noNameText;

	/* If the GDCA_currentTask section of the GDCI_attrs field is set to
	 * GDCT_NONE on startup, then the file specified by GDCI_defaultFile will be
	 * opened (and, if necessary, created). The file is specified by a chunk handle of
	 * a null-terminated string; this string should specify the file's path relative
	 * to the SP_DOCUMENT standard path.The default value is a null chunk handle,
	 * indicating that if the startup value of GDCA_currentTask is GDCT_NONE, no
	 * documents should be opened. */
	@instance ChunkHandle 				GDCI_defaultFile;

	/* GDCI_templateDir is the chunk handle of a null-terminated text string which
	 * specifies a directory to hold template documents. The directory is specified
	 * relative to SP_TEMPLATE. If not set by you, this defaults to the SP_TEMPLATE
	 * standard path. */
	@instance ChunkHandle				GDCI_templateDir;

	/* GDCI_documentGroup is an optr to the GenDocumentGroup object. You must set
	 * this field. */
	@instance optr			GDCI_documentGroup;

	/* GDCI_targetDocName is a character array. It is set to contain the name of
	 * the current target file. This field is automatically updated by the document
	 * control. */
	@instance FileLongName				GDCI_targetDocName = "";

	/* The Document Control automatically displays a big dialog box at startup which
	 * lets the user choose to create, open, etc. a file. Each option has a button
	 * (with a picture) and an explanatory text. You can override the default graphic
	 * or text by setting any of the following fields:
	 */
	@instance ChunkHandle		GDCI_dialogNewText;
	@instance ChunkHandle		GDCI_dialogTemplateText;
	@instance ChunkHandle		GDCI_dialogOpenDefaultText
	@instance ChunkHandle		GDCI_dialogImportText;
	@instance ChunkHandle		GDCI_dialogOpenText;
	@instance ChunkHandle		GDCI_dialogUserLevelText;

	@instance @visMoniker		GDCI_dialogNewMoniker;
	@instance @visMoniker		GDCI_dialogTemplateMoniker;
	@instance @visMoniker		GDCI_dialogOpenDefaultText
	@instance @visMoniker		GDCI_dialogImportMoniker;
	@instance @visMoniker		GDCI_dialogOpenMoniker;
	@instance @visMoniker		GDCI_dialogUserLevelMoniker;

----------

#### 13.2.1.1 The Document Token
	GDCI_documentToken, MSG_GEN_DOCUMENT_CONTROL_GET_TOKEN, 
	MSG_GEN_DOCUMENT_GROUP_GET_TOKEN

The document control's file selector will display only those files whose 
document token matches the GenDocumentControl object's 
*GDCI_documentToken* attribute. All files created by the application will have 
the specified document tokens. There are no messages to alter the token 
attributes at run-time. (If the document control is used to manage DOS files, 
the file selector will show all non-GEOS files.)

A token is defined by a **GeodeToken** structure. The format of this structure 
is shown below. The first field, *GT_chars*, will vary for each document type. 
The second, *GT_manufID*, will be the same for the tokens of all applications 
and documents created by a given company.

	typedef struct {
		char 				GT_chars[TOKEN_CHARS_LENGTH]; 
							/* TOKEN_CHARS_LENGTH = 4 */
		ManufacturerID 		GT_manufID;
							/* word-sized integer */
	} GeodeToken;

The message MSG_GEN_DOCUMENT_CONTROL_GET_TOKEN instructs the 
GenDocumentControl object to write a copy of the document token to a 
specified address. The message has one argument: the address of a 
**GeodeToken**. MSG_GEN_DOCUMENT_GROUP_GET_TOKEN functions 
identically, but it is sent to the GenDocumentGroup object.

You can also find out the application's token by sending 
GEN_DOCUMENT_CONTROL_GET_CREATOR or 
GEN_DOCUMENT_GROUP_GET_CREATOR to the appropriate object. The 
application's token will be used as the "creator token" for any documents 
created by the document control.

----------
#### MSG_GEN_DOCUMENT_CONTROL_GET_TOKEN
	void 	MSG_GEN_DOCUMENT_CONTROL_GET_TOKEN(
			GeodeToken *	token); /* address to copy token to */

This message gets the document token values for all documents created by 
this document control.

**Source:** Unrestricted.

**Destination:** Any GenDocumentControl object.

**Parameters:**  
*token* - A pointer to an empty **GeodeToken** structure.

**Return:** The document **GeodeToken** is written to the variable whose address 
is passed.

**Interception:** You should not subclass this message.

----------
#### MSG_GEN_DOCUMENT_GROUP_GET_TOKEN
	void 	MSG_GEN_DOCUMENT_GROUP_GET_TOKEN(
			GeodeToken *	token); /* address to copy token to */

This is the same as MSG_GEN_DOCUMENT_CONTROL_GET_TOKEN, except 
that it is sent to the GenDocumentGroup object instead of the 
GenDocumentControl object.

**Source:** Unrestricted.

**Destination:** Any GenDocumentGroup object.

**Parameters:**  
*token* - A pointer to an empty **GeodeToken** structure.

**Return:** The document **GeodeToken** is written to the variable whose address 
is passed.

**Interception:** You should not subclass this message.

----------
#### MSG_GEN_DOCUMENT_CONTROL_GET_CREATOR
	void 	MSG_GEN_DOCUMENT_CONTROL_GET_CREATOR(
			GeodeToken *	token); /* address to copy token to */

This message gets the token for the application; this token is the "creator 
token" for all files created by the document control.

**Source:** Unrestricted.

**Destination:** Any GenDocumentControl object.

**Parameters:**  
*token* - A pointer to an empty **GeodeToken** structure.

**Return:** The document **GeodeToken** is written to the variable whose address 
is passed.

**Interception:** You should not subclass this message.

----------
#### MSG_GEN_DOCUMENT_GROUP_GET_CREATOR
	void 	MSG_GEN_DOCUMENT_GROUP_GET_CREATOR(
			GeodeToken *	token); /* address to copy token to */

This is the same as MSG_GEN_DOCUMENT_CONTROL_GET_CREATOR, 
except that it is sent to the GenDocumentGroup object instead of the 
GenDocumentControl object.

**Source:** Unrestricted.

**Destination:** Any GenDocumentGroup object.

**Parameters:**  
*token* - A pointer to an empty **GeodeToken** structure.

**Return:** The document **GeodeToken** is written to the variable whose address 
is passed.

**Interception:** You should not subclass this message.

#### 13.2.1.2 The GDCI_selectorType Field
	GDCI_selectorType

The *GDCI_selectorType* field determines what files will be displayed by and 
can be opened with the file selector. The options are stored as a byte-sized 
enumerated type. The options are:

GFST_DOCUMENTS  
This is the default option. The file selector will display those 
documents with the appropriate tokens.

GFST_EXECUTABLES  
The file selector will display executable files as well as 
appropriate document files.

GFST_NON_GEOS_FILES  
The file selector will display all non-GEOS files (and only 
non-GEOS files). 

GFST_ALL_FILES  
 The file selector will display all files.

#### 13.2.1.3 The GDCI_attrs Field
	GDCI_attrs, MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS, 
	MSG_GEN_DOCUMENT_GROUP_GET_UI_ATTRS

The GenDocumentControl object has eight attribute flags stored in the 
word-sized bitfield *GDCI_attrs*. They may be retrieved by sending 
MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS to the GenDocumentControl 
object or by sending MSG_GEN_DOCUMENT_GROUP_GET_UI_ATTRS to the 
GenDocumentGroup object. The attributes are set at coding time; there is no 
way for an application to change the attributes at run-time, although the 
GenDocumentControl will change some of the attributes to reflect its current 
state.

The attributes are

GDCA_MULTIPLE_OPEN_FILES  
Allow several documents to be open at once. If this attribute is disabled, 
the "New" and "Open" triggers will be disabled when a document is open 
(however, see also the description of the flag 
GDCF_SINGLE_FILE_CLEAN_CAN_NEW_OPEN below). This 
attribute defaults to off.

GDCA_MODE  
This is a two-bit field. GDCA_MODE is a mask of all the bits in this field; 
the offset of this field is equal to the constant GDCA_MODE_OFFSET. The 
field has the following possible settings:

+ GDCM_VIEWER  
All documents are opened in read-only mode; the New, Save, 
Save As, and Revert triggers are permanently disabled. Other 
applications can open the file for read/write access.

+ GDCM_SHARED_SINGLE  
Documents are opened for reading and writing. When a 
document is open, it is marked "deny-write" so other 
applications can open the file only for read-only access. The 
user can mark a document as a "public" document, in which 
case the default is to open a file "read-only." The default 
GDCA_MODE setting is GDCM_SHARED_SINGLE.

+ GDCM_SHARED_MULTIPLE  
This mode is designed for documents that can have multiple 
writers, such as multi-user databases. Documents are 
ordinarily opened as in GDCM_SHARED_SINGLE mode above; 
however, a user can designate a file as a "multi-user" file, which 
means that it can be opened by several applications at once for 
read/write access.

The default setting of the GDCA_MODE flag is GDCM_SHARED_SINGLE. 
If you want a different value, first clear the two-bit field, then set the new 
setting, like this:

	GDCI_attrs = (@default & ~GDCA_MODE) \
			| (GDCM_VIEWER << GDCA_MODE_OFFSET);

Note that the GDCA_MODE attribute has a slightly different effect if the 
document control manages DOS files. For details, see 
GDCA_DOS_FILE_DENY_WRITE below.

GDCA_DOS_FILE_DENY_WRITE  
This attribute does not matter for VM files. If a DOS file is opened while 
the GDCA_DOS_FILE_DENY_WRITE bit is set, no other application will be 
able to write to that file. This is true even if the DOS file was opened for 
read-only access; however, if the file is a multi-user document opened in 
"shared-multiple" mode, other applications will be able to write to it 
regardless of whether the GDCA_DOS_FILE_DENY_WRITE attribute is 
set. By default, GDCA_DOS_FILE_DENY_WRITE is off.

GDCA_VM_FILE  
This attribute specifies whether the document control objects will open 
GEOS Virtual Memory files (if GDCA_VM_FILE is on), or DOS files (if 
GDCA_VM_FILE is off). The default value is on.

GDCA_NATIVE  
If this bit is set and GDCA_VM_FILE is not set, documents will be stored 
in the format native to the file-system.

GDCA_SUPPORTS_SAVE_AS_REVERT  
This attribute is ordinarily set only for GEOS files. If the attribute is on, 
the application will use the backup functionality of VM files to support 
"Save As" and "Revert" functionality. If the attribute is off, the file will be 
altered whenever it is updated to disk. The default value is on. DOS files 
do not normally support "Save As" and "Revert." Applications can 
implement "Save As" and "Revert" functionality for DOS files by defining 
a subclass of **GenDocumentClass** with handlers for 
MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS and 
MSG_GEN_DOCUMENT_PHYSICAL_REVERT, but this is not 
recommended. Ordinarily, this attribute should be off for DOS files.

GDCA_DOCUMENT_EXISTS  
This attribute is set and maintained at run-time by the 
GenDocumentControl code. The attribute is on if at least one document 
is open.

GDCA_CURRENT_TASK  
This three-bit attribute has a dual function: It determines the 
application's behavior at start-up, and it indicates what task the 
application is currently performing. The mask GDCA_CURRENT_TASK is 
a mask of all the bits in this field; the field's offset is equal to the constant 
GDCA_CURRENT_TASK_OFFSET. The possible settings are as follows:

+ GDCT_NONE  
If a default file has been specified (see section 13.2.1.7 below), that file will be opened; otherwise, the application will 
start with no file opened.

+ GDCT_NEW  
A new document will be created at startup. If the 
GDCF_DIALOG_BOX_FOR_NEW flag is set, a dialog box will be 
presented at startup.

+ GDCT_OPEN  
The "Open File" dialog box will be presented at startup.

+ GDCT_USE_TEMPLATE  
The "Use Template" dialog box will be presented at startup.

+ GDCT_SAVE_AS  
This is not a valid initial setting. The GDCA_CURRENT_TASK 
field has this setting between when a user chooses the "Save 
As" command and when the document is saved.

+ GDCT_COPY_TO  
This is not a valid initial setting. The GDCA_CURRENT_TASK 
field has this setting between when the user chooses the "Copy 
To" command and when the command has been fully executed.

+ GDCT_DIALOG 

+ GDCT_TYPE 

+ GDCT_PASSWORD  
None of these are valid initial settings.

If a document is passed in to be opened at startup (as, for example, when a 
user launches an application by double-clicking a file created by the 
application), that file will be opened, and the initial setting of 
GDCA_CURRENT_TASK will be ignored. The document control automatically 
maintains this bitfield to correspond to whatever action the document control 
is currently taking. The application can find out what the document control 
is doing by reading the attributes and checking this field.

GDCA_DO_NOT_SAVE_FILES  
If this bit is set, the application will not be able to save files. By setting 
this bit, you can turn your application into a fully-functioning demo.

----------
#### MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS
	GenDocumentControlAttrs 	MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS();

Use this message to find out what the GenDocumentControl object's 
*GDCA_attrs* flags are. The attributes cannot be changed by a message; they 
can only be read.

**Source:** Unrestricted.

**Destination:** Any GenDocumentControl object.

**Parameters:** None.

**Return:** Returns a word-length bitfield containing *GDCA_attrs* flag.

**Interception:** You should not subclass this message.

----------
#### MSG_GEN_DOCUMENT_GROUP_GET_UI_ATTRS
	GenDocumentControlAttrs 	MSG_GEN_DOCUMENT_GROUP_GET_UI_ATTRS();

This message is the same as the 
MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS message (see above) except 
that it is sent to the GenDocumentGroup object.

**Source:** Unrestricted.

**Destination:** Any GenDocumentGroup object.

**Parameters:** None.

**Return:** A word-length record containing the *GDCA_attrs* field.

**Interception:** You should not subclass this message.

#### 13.2.1.4 The GDCI_features Flags
	GDCI_features, MSG_GEN_DOCUMENT_CONTROL_GET_FEATURES, 
	MSG_GEN_DOCUMENT_GROUP_GET_UI_FEATURES, 
	MSG_GEN_CONTROL_CONFIGURE_FILE_SELECTOR

The *GDCI_features* attribute specifies whether certain optional functionality 
of the Document Control technology is enabled. The features are determined 
at coding time; there is no message to change features at run-time. To 
retrieve the features, send 
MSG_GEN_DOCUMENT_CONTROL_GET_FEATURES.

+ GDCF_READ_ONLY_SUPPORTS_SAVE_AS_REVERT  
If this feature is on, the "Save As" and "Revert" triggers are enabled when 
read-only documents are opened. Once the user chooses "Save As," the 
new file will no longer be opened as "Read Only"; the "Save" trigger will 
be enabled. If this feature is off, "Save As" and "Revert" triggers are 
disabled for read-only files. By default, this feature is on.

+ GDCF_SINGLE_FILE_CLEAN_CAN_NEW_OPEN  
This feature is ignored if the attribute GDCA_MULTIPLE_OPEN_FILES is 
on. If GDCF_SINGLE_FILE_CLEAN_CAN_NEW_OPEN is on and 
GDCA_MULTIPLE_OPEN_FILES is off, the "New" and "Open" triggers are 
enabled when the document is "clean" (i.e., the document has not been 
marked "dirty" since it was opened/created or saved); that is, "New" and 
"Open" are enabled whenever "Save" is disabled. If the user chooses 
"New" or "Open" when the document is "clean," the target document is 
closed and the new document is opened or created. If both 
GDCA_MULTIPLE_OPEN_FILES and 
GDCF_SINGLE_FILE_CLEAN_CAN_NEW_OPEN are off, the "New" and 
"Open" triggers are disabled whenever a document is open. By default, 
this attribute is on.

+ GDCF_SUPPORTS_TEMPLATES  
If this feature is enabled, the user can save files as templates. If the user 
chooses the command "Use Template," a copy of the template is opened 
as a "new" document, and the template is left unchanged. If this feature 
is disabled, the application cannot create templates. By default, this 
feature is on.

+ GDCF_SUPPORTS_USER_SETTABLE_EMPTY_DOCUMENT  
If this feature is enabled, the user can designate a file to be the model for 
all new documents. When the user chooses "New," this "model" document 
will be copied and the copy will be opened. By default, this feature is on. 

+ GDCF_SUPPORTS_USER_SETTABLE_DEFAULT_DOCUMENT  
If this attribute is on, the user can choose a default document (one which 
will automatically be opened when the application is launched). (See 
section 13.2.1.8 below.)

+ GDCF_SUPPORTS_USER_MAKING_SHARED_DOCUMENTS  
If this attribute is on, the user can save a document as "shared," allowing 
several processes to access it at once. By default, the attribute is on.

+ GDCF_NAME_ON_PRIMARY  
If this attribute is on, the name of the target document is displayed at the 
top of the Primary window. The GenDocumentControl object does this by 
changing the moniker of the GenPrimary object to the name of the target 
document. If there is no open document, the GenPrimary will display the 
string specified by the attribute *GDCI_noNameText*. By default, this 
attribute is on.

+ GDCF_DIALOG_BOX_FOR_NEW  
If this attribute is on, whenever a user selects "New," he will be presented 
with a dialog box. By default, this dialog box contains only triggers for 
"OK" and "Cancel;" the application can add other UI objects to give it 
functionality. If this attribute is off, whenever the user selects "New," a 
new document will open with the name specified by the 
**GenDocumentGroup** attribute *GDCI_defaultName*, if it is set; the file's 
name and location will be prompted for the first time the user saves the 
file. By default, this attribute is off.

For an added degree of control, you can use 
MSG_GEN_DOCUMENT_CONTROL_CONFIGURE_FILE_SELECTOR to change 
the attributes of the document control's file selector.

----------
#### MSG_GEN_DOCUMENT_CONTROL_GET_FEATURES
	GenDocumentControlFeatures 	MSG_GEN_DOCUMENT_CONTROL_GET_FEATURES();

Use this message to retrieve the current *GDCI_features* flags. The flags 
cannot be changed at run-time.

**Source:** Unrestricted.

**Destination:** Any GenDocumentControl object.

**Parameters:** None.

**Return:** The GenDocumentControl's *GDCI_features* flags.

**Interception:** You should not subclass this message.

----------
#### MSG_GEN_DOCUMENT_GROUP_GET_UI_FEATURES
	GenDocumentControlFeatures 	MSG_GEN_DOCUMENT_GROUP_GET_UI_FEATURES();

Use this message to retrieve the current *GDCI_features* flags. The flags 
cannot be changed at run-time.

**Source:** Unrestricted.

**Destination:** Any GenDocumentGroup object.

**Parameters:** None.

**Return:** The GenDocumentControl's *GDCI_features* flags.

**Interception:** You should not subclass this message.

----------
#### MSG_GEN_DOCUMENT_CONTROL_CONFIGURE_FILE_SELECTOR
	void 	MSG_GEN_DOCUMENT_CONTROL_CONFIGURE_FILE_SELECTOR(
			optr 		fileSelector, 
			word 		flags); /* GenDocumentControlAttrs */

Configure file selector. This message can be sub-classed to modify the 
behavior of the file selectors that the document control uses.

#### 13.2.1.5 The GDCI_enableDisableList Field
	GDCI_enableDisableList

The GenDocumentControl can be set to enable certain UI objects when 
documents are open. This is done using the *GDCI_enableDisableList* 
attribute. This attribute is the chunk handle of a list of object-pointers. Each 
of the referenced objects should start as disabled. Whenever a document is 
opened, a MSG_GEN_SET_ENABLED is sent to each object in the list. When 
the last document is closed, a MSG_GEN_SET_NOT_ENABLED is sent to each 
object in the list.

#### 13.2.1.6 Adding to the Dialog Boxes
	GDCI_openGroup, GDCI_importGroup, GDCI_useTemplateGroup, 
	GDCI_saveAsGroup, GDCI_exportGroup, GDCI_dialogGroup, 
	GDCI_userLevelGroup

The GenDocumentControl object manages the dialog boxes for many 
different user actions. The programmer can specify a tree of UI objects to be 
included with each of these dialog boxes. For example, to add a group of 
objects to the "Use Template" dialog box, the programmer should put them 
all in a tree (perhaps by making them all children of a GenInteraction object) 
and store an object-pointer to the head of the tree in the 
*GDCI_useTemplateGroup* attribute. The top object in the tree should be set 
"not usable."

#### 13.2.1.7 The GDCI_noNameText Field
	GDCI_noNameText

The GenDocumentControl object can be set to display the name of the 
current target document in the moniker of the **GenPrimary** window. If this 
feature is enabled, and no document is opened, the **GenPrimary** will have 
its moniker change to the string specified by *GDCI_noNameText*. If the 
feature GDCF_DISPLAY_NAME_ON_PRIMARY is disabled, *GDCI_noNameText* 
is ignored.

#### 13.2.1.8 The GDCI_defaultFile Field
	GDCI_defaultFile

If the attribute GDCA_CURRENT_TASK is initially set to GDCT_NONE and a 
default file is specified, the default file is automatically opened at startup. If 
GDCA_CURRENT_TASK is not initially set to GDCT_NONE, this attribute is 
ignored. This field holds the chunk handle of a null-terminated string. The 
string specifies the file's path relative to the SP_DOCUMENT. If the feature 
GDCF_SUPPORTS_USER_SETTABLE_DEFAULT_DOCUMENT is enabled, this 
attribute can be changed by the user at run-time. If the file specified does not 
exist, it is created as an empty document; if the document exists but cannot 
be opened, no file is opened at startup. If the named document exists but is 
inappropriate (e.g. it was created by another application), no document is 
opened at startup. 

#### 13.2.1.9 The GDCI_templateDir Field
	GDCI_templateDir

If templates are supported, this is the default directory for opening and 
saving them. This string specifies a subdirectory to the standard path 
SP_TEMPLATE. If not explicitly set in the source code, the template directory 
will default to SP_TEMPLATE.

#### 13.2.1.10 The GDCI_documentGroup Field
	GDCI_documentGroup

The GenDocumentControl and the GenDocumentGroup communicate with 
each other via messages. To do this, each needs the optr of the other. 
*GDCI_documentGroup* is the optr of the **GenDocumentGroup** object for 
this application. It is set in the source code and may not be changed at run 
time.

#### 13.2.1.11 The GDCI_targetDocName Field
	GDCI_targetDocName

This attribute contains the name of the target document. The document 
control automatically sets and updates this field when necessary.

### 13.2.2 GenDocumentGroup Data
The GenDocumentGroup object creates and manages the document objects. 
In the "process" model of document control, it sends messages to the process 
object (or some other designated object) when the application needs to take 
some action. (It sends these messages even when the "object" model is being 
followed; however, the messages are ignored.)

A list of data fields for the GenDocumentGroup object follows in Code 
Display 13-2. Some of the data fields can be changed at run-time, and others 
cannot; a discussion of the data fields follows the listing. If a data field cannot 
be set or read by the application, it is not discussed.

----------
**Code Display 13-2 GenDocumentGroupClass instance data**

	/* GDGI_attrs is a record that specifies
	 * certain basic characteristics of the documents to be managed. The attributes
	 * are set in the source code and are not changed at run-time. The default settings
	 * are below. */
	@instance GenDocumentGroupAttrs 	GDGI_attrs = (GDGA_VM_FILE |
					GDGA_SUPPORTS_AUTO_SAVE |
					GDGA_AUTOMATIC_CHANGE_NOTIFICATION |
					GDGA_AUTOMATIC_DIRTY_NOTIFICATION |
					GDGA_APPLICATION_THREAD |
					GDGA_AUTOMATIC_UNDO_INTERACTION |
					GDGA_CONTENT_DOES_NOT_MANAGE_CHILDREN);
		/* The following flags are available: 
		 * 	GDGA_VM_FILE,			
		 *	GDGA_SUPPORTS_AUTO_SAVE, 
		 *	GDGA_AUTOMATIC_CHANGE_NOTIFICATION,
		 * 	GDGA_AUTOMATIC_DIRTY_NOTIFICATION, 
		 * 	GDGA_APPLICATION_THREAD,
		 *	GDGA_VM_FILE_CONTAINS_OBJECTS,
		 *	GDGA_CONTENT_DOES_NOT_MANAGE_CHILDREN,
		 * 	GDGA_LARGE_CONTENT,
		 * 	GDGA_AUTOMATIC_UNDO_INTERACTION */

	/* GDGI_untitledName is the name suggested when a new document is
	 * first saved. */
	@instance ChunkHandle			GDGI_untitledName;

	/* The GenDocumentGroup object creates a document object for each document
	 * opened. The attribute GDGI_documentClass is a pointer to the class definition
	 * which will be used for document objects. By default, it points to the
	 * definition of GenDocumentClass, so document objects belong to GenDocumentClass.
	 * If you use a subclass of GenDocumentClass, you must change this attribute to
	 * point to the new class. */
	@instance ClassStruc *			GDGI_documentClass = 
					(ClassStruc *) &GenDocumentClass;

	/* Ordinarily, the Document Group creates document objects by instantiating an
	 * object of the class indicated by GDGI_documentClass. However, it can be
	 * instructed instead to duplicate a specific document object for each new
	 * document. To arrange this, set the GDGI_genDocument to point to the document
	 * object to duplicate. */
	@instance optr 			GDGI_genDocument;

	/* If the Procedural model is used, whenever the application needs to take an
	 * action, messages will be sent to the output of the GenDocumentGroup.
	 * Ordinarily, the output will be the process object. If the Object model is used,
	 * this attribute is generally left as a null pointer. */
	@instance optr			GDGI_output;

	/* The GenDocumentGroup object communicates with the GenDocumentControl
	 * object through messages. To do this, each one needs an object-pointer to the
	 * other. This is set in the source code. */
	@instance optr			GDGI_documentControl;

	/* The GenDocument (or subclass) objects can behave as Content objects. The
	 * document control can automatically connect GenDocument objects to the GenView
	 * if told to do so. The GDGI_genView field is an object-pointer to a GenView
	 * object. */
	@instance optr			GDGI_genView;

	/* In a multiple-document model, the document control can be set up to work with
	 * the display control. When this functionality is enabled, the
	 * GenDocumentGroup will automatically duplicate a specified block (generally
	 * one containing a GenDisplay object), attach the Display object to the specified
	 * GenDisplayGroup object, and set the header for the GenDisplay to the name of
	 * the document. When the document is closed, the block is freed. */
	@instance optr			GDGI_genDisplay; 
	/* GDGI_genDisplayGroup points to GenDisplayGroup which manages the GenDisplays. */
	@instance optr			GDGI_genDisplayGroup;

	/* Each GEOS document has a protocol number, which identifies the version of
	 * the application that created it. The GDGI_protocolMajor and
	 * GDGI_protocolMinor attributes specify the protocol number to be assigned to
	 * all documents created by the document control. */
	@instance word			GDGI_protocolMajor = 1;
	@instance word			GDGI_protocolMinor = 0;

----------
#### 13.2.2.1 The GDGI_attrs Field
	GDGI_attrs, MSG_GEN_DOCUMENT_GROUP_GET_ATTRS

This attribute specifies certain characteristics of the documents to be opened. 
These attributes are generally set in the source code and can not be changed 
at run-time. They are stored in a word-sized bitfield.

GDGA_VM_FILE  
This attribute is on if the documents to be opened are GEOS Virtual 
Memory files. By default, it is on.

GDGA_SUPPORTS_AUTO_SAVE  
If this attribute is on, the documents will be periodically auto-saved. It 
works only with VM files (unless you subclass GenDocument to handle 
MSG_GEN_DOCUMENT_PHYSICAL_UPDATE; see "Working with DOS 
files" below). It works by periodically updating the file to disk. It 
should probably be turned off if "Save As" and "Revert" are disabled. By 
default, the attribute is on. The program can temporarily disable 
auto-save for a document by sending the document object 
MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE.

GDGA_AUTOMATIC_CHANGE_NOTIFICATION  
If this attribute is on, the GenDocumentGroup object will periodically 
check all open documents to see if they have been changed by another 
process. If a document has changed, the document control will send 
MSG_META_DOC_OUTPUT_DOCUMENT_HAS_CHANGED to the 
application. This attribute is useful if the application may be reading 
multi-user files.

GDGA_AUTOMATIC_DIRTY_NOTIFICATION  
This attribute is relevant only for GEOS files. If the attribute is on, 
whenever a file is marked "dirty," the file system will automatically notify 
the document control. The document control will then take appropriate 
actions (enable the "Save" trigger, etc.). The document control will also 
present a "Save changes before closing" dialog box if the document is 
closed before being saved. If GDGA_AUTOMATIC_DIRTY_NOTIFICATION 
is off, or if the documents are DOS files, the application will have to notify 
the document control when the document is dirty. It does this by sending 
a MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY to the 
GenDocumentGroup object (under the procedure model), or by sending a 
MSG_GEN_DOCUMENT_MARK_DIRTY to the document object (under the 
object model). By default, GDGA_AUTOMATIC_DIRTY_NOTIFICATION is 
on.

GDGA_APPLICATION_THREAD  
If this attribute is on, the GenDocumentGroup object is run by the 
application thread, as are its (document-object) children. By default, it is 
on.

GDGA_VM_FILE_CONTAINS_OBJECTS  
If the document control manages Virtual Memory Object files, this 
attribute should be set to on. By default, this attribute is off.

GDGA_CONTENT_DOES_NOT_MANAGE_CHILDREN  
The application's main VisContent, if any, does not manage its children. 
By default, this attribute is on.

GDGA_LARGE_CONTENT  
The application's main VisContent uses the large model. By default, this 
attribute is off.

GDGA_AUTOMATIC_UNDO_INTERACTION  
The application sends out undo set-context messages automatically as 
necessary.

----------
#### MSG_GEN_DOCUMENT_GROUP_GET_ATTRS
	GenDocumentGroupAttrs 	MSG_GEN_DOCUMENT_GROUP_GET_ATTRS();

Use this message to find out the attributes of the GenDocumentGroup object. 
Note that the attributes cannot be changed at run-time; they can only be 
examined.

**Source:** Unrestricted.

**Destination:** Any GenDocumentGroup object.

**Parameters:** None.

**Return:** Flags in *GDGI_attrs* bitfield.

**Interception:** You should not subclass this message.

#### 13.2.2.2 The GDGI_untitledName Field
	GDGI_untitledName, MSG_GEN_DOCUMENT_GROUP_GET_DEFAULT_NAME

The first time a new document is saved, the document control presents a 
"Save As" dialog box. If the GDGI_untitledName field is set to point to a 
string, that string will be suggested as the name of the document. If the 
attribute is not set, no name will be suggested. The current default name can 
be retrieved by sending 
MSG_GEN_DOCUMENT_GROUP_GET_DEFAULT_NAME to the 
GenDocumentGroup object.

----------
#### MSG_GEN_DOCUMENT_GROUP_GET_DEFAULT_NAME
	GenDocumentGroupAttrs 	MSG_GEN_DOCUMENT_GROUP_GET_DEFAULT_NAME(
				char *buffer); /* Address to write default name */

This message instructs the GenDocumentGroup object to copy the 
*GDGI_defaultName* attribute to the specified address. In addition, the 
message will return the *GDGI_attrs* word of the GenDocumentGroup object. 
If you just want the attributes, use 
MSG_GEN_DOCUMENT_GROUP_GET_ATTRS.

**Source:** Unrestricted.

**Destination:** Any GenDocumentGroup object.

**Parameters:**  
*buffer* - A pointer to a character buffer. This buffer should 
be of length FILE_LONGNAME_BUFFER_SIZE or 
greater.

**Return:** The record of flags stored in *GDGI_attrs*. 

**buffer* - Null-terminated name string.

**Interception:** You should not subclass this message.

Warnings:	Make sure the buffer is long enough to hold any file name. Otherwise, 
the method may overwrite data after the buffer. The constant 
FILE_LONGNAME_BUFFER_SIZE, defined in file.def, is equal to the 
maximum file name length, counting the null terminator.

#### 13.2.2.3 The GDGI_documentClass Field
	GDGI_documentClass

Each time a document is opened, the GenDocumentGroup creates a 
document object. Ordinarily, the document object is a member of 
**GenDocumentClass**. However, sometimes the programmer will want to 
add functionality to the document objects, doing so by defining a subclass of 
**GenDocumentClass**. (For example, in the object model of document 
control, the program implements most functionality by defining new methods 
for the document class.) If this is the case, the programmer will have to make 
sure the GenDocumentGroup object creates document objects from the new 
class. One can do this by setting the *GDGI_documentClass* field to point to the 
class structure of the new document object class. By default, this field points 
to **GenDocumentClass**.

#### 13.2.2.4The GDGI_genDocument Field
	GDGI_genDocument

Ordinarily, the document group creates new document objects by 
instantiating objects from the class specified in *GDGI_documentClass*. 
However, you can instead provide a document object for the document group 
to duplicate. To do this, set the *GDGI_genDocument* field to the optr of the 
"template" document object. This object should be marked "not usable."

#### 13.2.2.5 The GDGI_output Field
	GDGI_output, MSG_GEN_DOCUMENT_GROUP_GET_OUTPUT, 
	MSG_GEN_DOCUMENT_GROUP_SET_OUTPUT

Every time something happens which needs to be handled by the application, 
the document control notifies the application in two ways: The relevant 
document object sends a message to itself, and the GenDocumentGroup 
object sends a message to its designated output object. In the Procedural 
model of document control, the document-object messages are ignored, and 
the GenDocumentGroup messages are sent to an object (usually the process 
object) which has handlers for the messages. In the Object model, the 
*GDGI_output* attribute is left as a null pointer, and **GenDocumentClass** is 
subclassed to handle the messages.

----------
#### MSG_GEN_DOCUMENT_GROUP_GET_OUTPUT
	optr	MSG_GEN_DOCUMENT_GROUP_GET_OUTPUT();

Under the Procedural model of document control, the GenDocumentGroup 
sends messages to a designated output object. To get the optr of that output 
object, send this message to the GenDocumentGroup object.

**Source:** Unrestricted.

**Destination:** Any GenDocumentGroup object.

**Return:** Returns the optr of the document group's output object.

**Interception:** You should not subclass this message.

----------
#### MSG_GEN_DOCUMENT_GROUP_SET_OUTPUT
	void	MSG_GEN_DOCUMENT_GROUP_SET_OUTPUT(
			optr	output); /* The new recipient of the GenDocumentGroup's
			output messages */

Under the Procedural model of document control, the GenDocumentGroup 
object sends messages to a designated output object. Use this message to 
change the recipient of the output.

**Source:** Unrestricted.

**Destination:** Any GenDocumentGroup object.

**Parameters:**  
*output* - The optr of the object which will receive the output.

**Interception:** You should not subclass this message.

#### 13.2.2.6 The GDGI_documentControl Field
	GDGI_documentControl

The GenDocumentControl and the GenDocumentGroup communicate with 
each other via messages. To do this, each needs an optr to the other. 
*GDCI_documentControl* is an optr to the GenDocumentGroup object for this 
application. It is set in the source code and is not changed at run time.

#### 13.2.2.7 Dynamically Creating Displays
	GDGI_genDisplay, GDGI_genDisplayGroup, 
	MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY, 
	MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY_GROUP

In a multi-document application, each document will ordinarily have its own 
GenDisplay object and often many other UI objects as well. The document 
control can be instructed to dynamically create a number of objects for each 
new document and destroy these objects when the document is closed. 

If an application is going to have the document control create and manage 
GenDisplay objects, it must declare a GenDisplayGroup object. The 
GenDisplayGroup should be declared normally; however, it should be given 
no children. In the source code, the GenDocumentGroup object's 
*GDGI_genDisplayGroup* data field should contain an optr to the 
GenDisplayGroup object.

The application should also declare a template resource. This resource 
should contain a single generic tree; the top object in this tree should be a 
GenDisplay object which is set "not usable." The GenDocumentGroup object's 
*GDGI_genDisplay* field should contain an optr to that GenDisplay.

When a new document object is created, the document control will 
automatically copy the resource containing the GenDisplay referenced by 
*GDGI_genDisplay*, make the new GenDisplay a child of the GenDisplayGroup 
referenced by *GDGI_genDisplayGroup*, and set the new GenDisplay as 
"usable." When the document object is destroyed (because the document is 
closed), the document control will automatically destroy that document's 
copy of the resource.

----------
#### MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY
	optr	MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY();

The *GDGI_genDisplay* field can be set to point to a GenDisplay object. If 
*GDGI_genDisplay* is not a null optr, then the document control will duplicate 
the resource containing the referenced GenDisplay whenever a new 
document object is created. The duplicate GenDisplay is made a child of the 
GenDisplayGroup object indicated by *GDGI_genDisplayGroup*. By using this 
message, you can get an optr to that "template" display object. Any changes 
made to that object will be copied whenever a new document object is created.

**Source:** Unrestricted.

**Destination:** Any GenDocumentGroup object.

**Return:** Returns the optr of the "template" GenDisplay.

**Interception:** You should not subclass this message.

----------
#### MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY_GROUP
	optr	MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY_GROUP();

If a GenDisplayGroup object is used to manage GenDisplay objects, the 
GenDocumentGroup object will contain an optr to the GenDisplayGroup. By 
using this message, you can get an optr to the GenDisplayGroup object.

**Source:** Unrestricted.

**Destination:** Any GenDocumentGroup object.

**Return:** Returns the optr of the GenDocumentGroup object.

**Interception:** You should not subclass this message.

#### 13.2.2.8 Connecting Documents with a GenView
	GDGI_genView, MSG_GEN_DOCUMENT_GROUP_GET_VIEW

The document control can be instructed to automatically connect the output 
of a GenView to the document object associated with the view. That way, the 
document object can handle all the messages relating to the view. This is 
naturally only done when the application is using the Object model; if it is 
using the Procedural model, a GenView will most likely send its messages to 
the Process object.

There are two ways to enable this functionality. One way is appropriate only 
to single-document applications; the other is appropriate to multi-document 
applications.

A single-document application using the Object model should declare the 
GenView normally as part of the generic tree. (It might well be placed on the 
GenDocumentControl object's *GDCI_enableDisableList*.) The source code 
should set the *GDGI_genView* field to be an optr to the GenView. When a 
document is opened, the document control will automatically set the 
GenView object to direct its output to the document object.

A multi-document application using the Object model should use the 
document control's ability to create and manage GenDisplay objects. The 
application will have a resource which is duplicated for each open document. 
This resource will contain a generic tree, at the head of which is a 
GenDisplay. To use a GenView, all the application has to do is put a GenView 
in the tree headed by that GenDisplay, and set *GDGI_genView* to point to that 
GenView. When a document object is created, the document control will 
automatically have the new GenView (in the duplicate resource) send its 
output to the new GenDocument.

----------
#### MSG_GEN_DOCUMENT_GROUP_GET_VIEW
	optr MSG_GEN_DOCUMENT_GROUP_GET_VIEW();

The GenDocumentGroup object can be set to automatically link document 
objects to **GenView** objects. Use this message to find out what the 
designated **GenView** is. If there is no such **GenView**, this message will 
return a null optr.

**Source:** Unrestricted.

**Destination:** Any GenDocumentGroup object.

**Return:** The optr of the **GenView** object (specified in GDGI_genView).

**Interception:** You should not subclass this message.

#### 13.2.2.9 Document Protocols
	GDGI_protocolMajor, GDGI_protocolMinor, 
	MSG_GEN_DOCUMENT_GROUP_GET_PROTOCOL

Every GEOS file (and each application that creates such files) has a protocol 
associated with it. Protocols are used to make sure an application knows if a 
given document was created by a different version of the application. They 
are stored in the file's FEA_PROTOCOL extended attributes (see 
"File System," in Chapter 17 of the Concepts Book). The protocol is of the form 
"MAJOR.MINOR," where both "MAJOR" and "MINOR" are 16-bit unsigned 
integers. The application's protocol is specified by the *GDGI_protocolMajor* 
and *GDGI_protocolMinor* attributes of the GenDocumentGroup object. 

All documents created by an application will have the application's protocol 
number. If a document has the same major protocol number as the 
application but a lower minor protocol number, the document is compatible 
with the application. If the document has a lower major protocol number, the 
document is incompatible with the application; it can be opened only if a 
routine has been defined to upgrade the document. If the document has a 
higher protocol than the application (i.e. its major protocol number is higher, 
or it has the same major protocol number and a higher minor protocol 
number), the document control will not open the file; it will present an error 
message. By default, the GenDocumentGroup object has a 
*GDGI_protocolMajor* of one and a *GDGI_protocolMinor* of zero.

When the user opens an earlier but compatible document, the 
GenDocumentGroup opens the file and attaches it to a document object. 
Then, the (newly-created) document object sends itself 
MSG_GEN_DOCUMENT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT; the 
GenDocumentGroup then sends its output object the message 
MSG_META_DOC_OUTPUT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT. If 
neither of these messages is handled, the document will be opened as if it 
were of the current protocol (since it is compatible). Often an application will 
not handle these messages.

If the user tries to open an earlier and incompatible document, the 
GenDocumentGroup opens the file and attaches it to a document object. 
Then, the document object sends a 
MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT to 
itself, and the GenDocumentGroup sends a 
MSG_META_DOC_OUTPUT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
 to its output. If neither message is handled, the GenDocumentGroup closes 
the file unchanged and removes the document object, and the 
GenDocumentControl presents an error message (since the document is 
incompatible). If either message is handled, the document will be opened 
normally after the handler exits.

Note that the document control will not automatically change the protocol 
number for a file after it has been updated. If you wish this done, you should 
have the handler for the message call one of the routines to change the 
FEA_PROTOCOL extended attribute.

----------
#### MSG_GEN_DOCUMENT_GROUP_GET_PROTOCOL
	dword	MSG_GEN_DOCUMENT_GROUP_GET_PROTOCOL();

Use this message to get the protocol number associated with the 
GenDocumentGroup. A protocol number is composed of two parts, a major 
component and a minor component. This message returns a double-word; the 
high word is the major component, and the low word is the minor component. 

**Source:** Unrestricted.

**Destination:** GenDocumentGroupClass.

**Return:** Returns a dword-sized value; the high word contains the major protocol 
number, and the low word contains the minor protocol number.

**Interception:** You should not subclass this message.

### 13.2.3 GenDocument Attributes
There are very few **GenDocumentClass** attributes that you will need to be 
concerned with. The GenDocumentGroup object creates and updates 
document objects as needed. Ordinarily, the application will not look at the 
**GenDocumentClass** instance data. If the program defines a subclass of 
**GenDocumentClass**, the subclass's methods should use only the subclass's 
instance data.

There is only one attribute which the program should change at run-time, 
and that is the GDA_PREVENT_AUTO_SAVE bit of the *GDI_attrs* field. This bit 
can be changed with the messages 
MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE and 
MSG_GEN_DOCUMENT_ENABLE_AUTO_SAVE.

**GenDocumentClass** is a subclass of **GenContentClass** and has all the 
functionality of that class. Since GenContent objects are rarely used directly, 
the class does not have its own chapter; instead, it is documented in section 
13.2.3.4 below. The main thing to know about the GenContent is that, 
like a VisContent, it is displayed in a GenView and can have visible children. 
It can also have generic children, though it may not have both visible and 
generic children at the same time.

#### 13.2.3.1 The GDI_attrs Field
	GDI_attrs, MSG_GEN_DOCUMENT_GET_ATTRS, 
	MSG_GEN_DOCUMENT_ENABLE_AUTO_SAVE, 
	MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE, 
	MSG_GEN_DOCUMENT_AUTO_SAVE

The *GDI_attrs* word contains flags indicating the status of the document. The 
application can read or change any of these attributes; however, only the 
attribute GDA_PREVENT_AUTO_SAVE should actually be changed at 
run-time.

GDA_READ_ONLY  
This attribute is set if the document in question is opened for 
read-only access.

GDA_READ_WRITE  
This attribute is set if the document is opened for read/write 
access.

GDA_FORCE_DENY_WRITE  
If this attribute is set, while the document is open, no other 
process will be allowed to open that document for read/write 
access.

GDA_SHARED_MULTIPLE  
The document is opened in "shared multiple" mode. 

GDA_SHARED_SINGLE  
The document is opened in "shared single" mode. 

GDA_UNTITLED  
The document is newly-created and has not yet been saved; it 
is still untitled.

GDA_DIRTY  
The document has been marked dirty since the last time it was 
saved.

GDA_CLOSING  
The document is in the process of being closed.

GDA_ATTACH_TO_DIRTY_FILE  
The document object is being attached to a dirty file (e.g., when 
restarting GEOS).

GDA_SAVE_FAILED  
The user attempted to save the document, and it could not be 
saved (e.g., someone else denied write access, or the volume 
was no longer accessible).

GDA_OPENING  
The document is in the process of being opened.

GDA_AUTO_SAVE_STOPPED  
Auto-save was stopped while in progress.

GDA_PREVENT_AUTO_SAVE  
This bit can be changed by the application at run-time. While 
the bit is on, auto-save is disabled.

----------
#### MSG_GEN_DOCUMENT_GET_ATTRS
	GenDocumentAttrs 	MSG_GEN_DOCUMENT_GET_ATTRS();

Use this message to get the *GDI_attrs* flags for a given document. These 
attribute flags give information about the document's permissions as well as 
about any operations currently in progress.

**Source:** Unrestricted - objects subclassed from **GenDocumentClass** often 
send this message to themselves.

**Destination:** Any GenDocument object.

**Return:** The object's word-sized *GDI_attrs* field.

**Interception:** You should not subclass this message.

----------
#### MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE
	void	MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE();

Sometimes an application needs to temporarily disable auto-save for a 
specific document (for example, if it is in the middle of making elaborate 
changes to the file). It can do this by sending this message to the document 
object. The document's GDA_PREVENT_AUTO_SAVE bit will be turned on, and 
auto-save will be disabled until the document receives a 
MSG_GEN_DOCUMENT_ENABLE_AUTO_SAVE.

**Source:** Unrestricted - objects subclassed from **GenDocumentClass** often 
send this message to themselves.

**Destination:** Any GenDocument object.

**Interception:** You should not subclass this message.

----------
#### MSG_GEN_DOCUMENT_ENABLE_AUTO_SAVE
	void	MSG_GEN_DOCUMENT_ENABLE_AUTO_SAVE();

This message turns off a document's GDA_PREVENT_AUTO_SAVE bit. If the 
bit is already off (i.e., auto-save is enabled), the message has no effect.

**Source:** Unrestricted - objects subclassed from **GenDocumentClass** often 
send this message to themselves.

**Destination:** Any GenDocument object.

**Interception:** You should not subclass this message.

----------
#### MSG_GEN_DOCUMENT_AUTO_SAVE
	void	MSG_GEN_DOCUMENT_AUTO_SAVE();

This message forces the document object to immediately auto-save its file.

**Source:** Unrestricted. The document object may send this message to itself.

**Destination:** Any GenDocument object.

**Interception:** This message is not generally subclassed.

#### 13.2.3.2 The GDI_operation Attribute
	GDI_operation, MSG_GEN_DOCUMENT_GET_OPERATION

A single user action can result in many routines being called and many 
messages being sent out. To help keep track of what's going on, 
**GenDocumentClass** has a byte-length field, *GDI_operation*. If the 
document control is in the midst of handling a user action for a given 
document, it will set the *GDI_operation* byte accordingly. The current 
operation is a member of the **GenDocumentOperation** enumerated type. 
This type has the following possible values:

GDO_NORMAL  
This is the usual setting. If the document is not currently 
handling a user action, this is the setting.

GDO_SAVE_AS  
When the user chooses "Save As," the byte is set to this value. 
It remains at this value until the new document has been 
opened and saved.

GDO_REVERT  
The setting from the time the user chooses "Revert" until the 
file has been restored to its last-saved state.

GDO_REVERT_QUICK  
The setting from the time the user chooses "restore from 
backup" until the file has been restored.

GDO_ATTACH  
The setting while the UI is being created for and attached to a 
given document. When a file document is created or opened, the 
*GDI_operation* field is set to this after GEOS has opened the file, 
and it remains at this setting until the application finishes 
attaching the UI.

GDO_DETACH  
The setting while the UI is being detached from a given 
document, but before the actual file is closed.

GDO_NEW  
The setting while a new file is being created. When the file is 
created and initialized, the *GDI_operation* will change to 
GDO_ATTACH.

GDO_OPEN  
The setting while an existing file is being opened. When the file 
is created and initialized, the *GDI_operation* will change to 
GDO_ATTACH.

GDO_SAVE  
The setting while a document is being saved. 

GDO_CLOSE  
After the UI has been detached, the *GDI_operation* byte is set to 
this value until the document object is destroyed.

GDO_AUTO_SAVE  
The setting while a file is being updated (i.e. auto-saved) to 
disk.

----------
#### MSG_GEN_DOCUMENT_GET_OPERATION
	GenDocumentOperation 	MSG_GEN_DOCUMENT_GET_OPERATION();

Use this message to find out what user action a given document object is in 
the midst of processing. This is useful if you are handling some message and 
want to find out the context in which that message was sent. Note that 
although the message returns a word-length value, the *GDI_operation* 
enumerated type is byte-length; it is thus safe to cast the return value to a 
byte-length variable. 

**Source:** Unrestricted-objects subclassed from **GenDocumentClass** often 
send this message to themselves.

**Destination:** Any GenDocument object.

**Return:** Returns a member of the **GenDocumentOperation** enumerated type 
corresponding to the document object's current operation.

**Interception:** You should not subclass this message.

#### 13.2.3.3 File Information
	GDI_fileHandle, GDI_diskHandle, GDI_volumeName, 
	GDI_fileName, MSG_GEN_DOCUMENT_GET_FILE_NAME, 
	MSG_GEN_DOCUMENT_GET_FILE_HANDLE

The document object stores certain data about the file associated with it. In 
particular, the instance data records the document's path, its full file name, 
and the handles of the file and the disk volume containing the file. This data 
can be retrieved by sending messages to the document object.

----------
#### MSG_GEN_DOCUMENT_GET_FILE_NAME
	void	MSG_GEN_DOCUMENT_GET_FILE_NAME(
			char *buffer); /* Address to write file name to */

This message instructs a GenDocument to write the name of its file (without 
the path) to the specified address.

**Source:** Unrestricted-objects subclassed from **GenDocumentClass** often 
send this message to themselves.

**Destination:** Any GenDocument object

**Parameters:**  
*buffer* - Buffer of length FILE_LONGNAME_BUFFER_SIZE.

**Return:** Writes file's virtual name into the passed buffer as a null-terminated 
string.

**Warnings:** Make sure the buffer passed is of length 
FILE_LONGNAME_BUFFER_SIZE; otherwise the method might 
overwrite other data.

**Interception:** You should not subclass this message.

----------
#### MSG_GEN_DOCUMENT_GET_FILE_HANDLE
	FileHandle 	MSG_GEN_DOCUMENT_GET_FILE_HANDLE();

This message returns the handle of the file associated with a given 
GenDocument object.

**Source:** Unrestricted-objects subclassed from **GenDocumentClass** often 
send this message to themselves.

**Destination:** Any GenDocument object.

**Return:** Returns handle of file associated with that document object.

**Interception:** You should not subclass this message.

#### 13.2.3.4 GenContentClass
The GenContent generic object is similar to the VisContent visible object in 
that it interacts directly with the GenView. While the VisContent allows an 
application to display a visible hierarchy of objects within the view, however, 
the GenContent allows either generic or visible object hierarchies or to be 
displayed. This is the one case where you may ordinarily have visible objects 
be children of a generic object. Note that you should not have both visible and 
generic objects as children of the same GenContent; if you do so, results are 
undefined.

**GenContentClass** is a subclass of **GenClass** and therefore inherits all the 
instance data, messages, and hints of all generic objects. The GenContent 
also has two other instance data fields, however; these are

	@instance byte			GCI_attrs = 0;
	@instance optr			GCI_genView;

The *GCI_attrs* field contains a record of **VisContentAttrs** and is used by 
document objects for visual updates and interaction with the GenView. This 
record may be retrieved with MSG_GEN_CONTENT_GET_ATTRS or set with 
MSG_GEN_CONTENT_SET_ATTRS.

The *GCI_genView* field contains the optr of the GenView object displaying the 
GenContent. This, too, is used by document objects to manage interaction 
with the GenView.

----------
#### MSG_GEN_CONTENT_GET_ATTRS
	byte	MSG_GEN_CONTENT_GET_ATTRS();

This message returns the record of **VisContentAttrs** set in the 
GenContent's *GCI_attrs* field.

**Source:** Unrestricted.

**Destination:** Any GenContent object

**Parameters:** None.

**Return:** The *GCI_attrs* settings.

**Interception:** Unlikely.

----------
#### MSG_GEN_CONTENT_SET_ATTRS
	void	MSG_GEN_CONTENT_SET_ATTRS(
			byte	attrsToSet,
			byte	attrsToClear);

This message sets the attributes in the GenContent's *GCI_attrs* record.

**Source:** Unrestricted.

**Destination:** Any GenContent object.

**Parameters:**  
*attrsToSet* - A record of **VisContentAttrs** indicating which 
flags should be set. Those set in *attrsToSet* will be 
set in *GCI_attrs*.

*attrsToClear* - A record of **VisContentAttrs** indicating which 
flags should be cleared. Those cleared in 
*attrsToClear* will be cleared in *GCI_attrs*. Note that 
if a flag is set in both parameters, it will end up 
cleared.

**Return:** Nothing.

**Interception:** Unlikely.

## 13.3 Basic DC Messages
The document control objects use messages for many things. Since well over 
half a dozen classes of objects (counting file selectors, GenDisplayGroup 
objects, menu triggers, etc.) and far more actual objects are involved in 
intricate tasks, many messages are continually sent back and forth. Most of 
these messages are transparent to the programmer. The programmer need 
only know about them if the program subclasses a message to add 
functionality to it; this is an advanced technique which few programs will 
ever need to use.

There are two basic types of messages the programmer needs to know about. 
First, there are messages which are sent to document control objects; these 
objects may query information, toggle some functionality, or otherwise 
instruct the DC objects to take some action. Second, there are messages the 
DC objects send when the programmer's code needs to take some action. Each 
type of message is treated in a separate section.

### 13.3.1 Other Document Group Messages
The following are the messages a program might ordinarily send to the 
GenDocumentGroup object. Many of these messages request information 
about the GenDocumentControl object or the target document; others 
request information about the GenDocumentGroup object or instruct it to 
take actions. Many of the messages require, as an argument, an optr to a 
document object; however, a null object-pointer can be passed, thus 
indicating the target document. This is especially useful under 
single-document models; the application doesn't need to keep track of the 
document object's optr, since it is always the target document.

----------
#### MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY
	void	MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY(
			optr	document); /* document to mark dirty */

This message notifies the GenDocumentGroup object that the specified 
document has been dirtied. The GenDocumentGroup will enable and disable 
file menu triggers as appropriate. If the argument is a null pointer, the target 
document will be marked dirty.

**Source:** Unrestricted.

**Destination:** Any GenDocumentGroup object.

**Parameters:**  
*document* - optr of document to mark dirty. If a null optr is 
passed, the target document will be dirtied.

**Interception:** You should not subclass this message.

**Tips:** If the document is a VM file and the GenDocumentGroup attribute 
GDGA_AUTOMATIC_DIRTY_NOTIFICATION is set, the VM routines will 
notify the GenDocumentGroup that the document has been dirtied 
whenever the **VMDirty()** (or **DBDirty()**, **CellDirty()**, etc.) routine is 
called. However, if you change a data cache without changing the 
actual file, you should send this message (or 
MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE) to insure that 
the changes to the cache will be saved.

----------
#### MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE
	void	MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE(
			FileHandle 	file); /* file handle of document to mark dirty */

This message notifies the GenDocumentGroup that the file with the specified 
handle has been dirtied. The GenDocumentGroup will enable and disable file 
menu triggers as appropriate. The document is specified by file handle, not 
document optr.

**Source:** Unrestricted

**Destination:** Any GenDocumentGroup object.

**Parameters:** file	The handle of the file to dirty.

**Interception:** You should not subclass this message.

**Tips:** If the document is a VM file and the GenDocumentGroup attribute 
GDGA_AUTOMATIC_DIRTY_NOTIFICATION is set, the VM routines will 
notify the GenDocumentGroup that the document has been dirtied 
whenever the **VMDirty()** (or **DBDirty()**, **CellDirty()**, etc.) routine is 
called. However, if you change a data cache without changing the 
actual file, you should send this message (or 
MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY) to insure that the 
changes to the cache will be saved.

----------
#### MSG_GEN_DOCUMENT_GROUP_GET_DOC_BY_FILE
	optr	MSG_GEN_DOCUMENT_GROUP_GET_DOC_BY_FILE(
			FileHandle 	file);

Use this message if you know the file handle of a document and you need to 
get an object-pointer to the document object corresponding to the file. In the 
inverse situation (you know the object, and need to get the file handle), send 
MSG_GEN_DOCUMENT_GET_FILE_HANDLE directly to the document object.

**Source:** Unrestricted.

**Destination:** Any GenDocumentGroup object.

**Parameters:**  
*file* - The handle of file whose document object is needed.

**Return:** Returns the optr of document object

**Interception:** You should not subclass this message.

----------
#### MSG_GEN_DOCUMENT_GROUP_SAVE_AS_CANCELLED
	void	MSG_GEN_DOCUMENT_GROUP_SAVE_AS_CANCELLED();

If you are in the midst of handling a "Save As" operation, and you need to 
cancel it, send this message to the GenDocumentGroup object.

**Source:** Unrestricted

**Destination:** Any GenDocumentGroup object.

**Interception:** This message is not generally subclassed.

### 13.3.2 From the Doc Control Objects
Often the document control will need to notify the application to take an 
action. For example, when a document is created, the application needs to be 
told to initialize the document and the user interface. There are two basic 
models for handling these situations: the "Procedure" model and the "Object" 
model. (The differences between these models are discussed at more length 
in the section "Document Control Models" above.) Each model has its 
own way of messaging.

Under the Procedure model, every time the application needs to be notified, 
the document control sends a message to the GenDocumentGroup's output 
object, which is ordinarily the process object. Under the Object model, the 
affected document object will send a message to itself; this message has no 
handler under **GenDocumentClass**, so the application must use a subclass 
of **GenDocumentClass** with handlers for these messages.

A single user action can generate several messages. For example, when the 
user opens a document, four messages are sent: MSG\_-_PHYSICAL_OPEN, 
MSG\_-_READ_CACHED_DATA_FROM_FILE, 
MSG\_-_CREATE_UI_FOR_DOCUMENT, and 
MSG\_-_ATTACH_UI_TO_DOCUMENT. Furthermore, a given message might 
be sent as the result of several different user actions; for example, the 
message MSG_-_CREATE_UI_FOR_DOCUMENT is sent when the user 
creates a new file or opens an existing one. If a handler needs to know what 
user action precipitated a given message, it can send a 
MSG_GEN_DOCUMENT_GET_OPERATION to the document object.

#### 13.3.2.1 Messages Handled under the Procedure Model

Whenever the application needs to be notified to take an action, a message 
will be sent to the GenDocumentGroup's output object. Two arguments 
accompany such messages: A pointer to the relevant document object and the 
handle of the file associated with that document. All of these messages are 
exported from **MetaClass**, so they can be handled by objects of any class.

Each of these messages corresponds to a document-model message, all of 
which are described in section 13.3.2.2 below. These are just the basic 
messages; for more advanced functionality, see the message listings in the 
advanced section.

----------
#### MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE
	void	MSG_META_DOC_OUTPUT_INITIALIZE_FILE(
			optr		document, /* document object to initialize */
			FileHandle	file);	/* Handle of file to initialize */

The GenDocumentGroup object sends this message out when a new 
document has been created and needs to be initialized. Applications which 
use VM files will allocate the map block and initialize it. If an application 
maintains data caches for its files, it should initialize the caches at this point.

Note that the handler for this message should not take any UI-related 
actions. These should be left to the handlers for 
MSG_META_DOC_OUTPUT_CREATE_UI_FOR_DOCUMENT and 
MSG_META_DOC_OUTPUT_ATTACH_UI_FOR_DOCUMENT.

**Source:** The GenDocumentGroup object.

**Destination:** The output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*document* - The optr of the document object which has just 
been created.

*file* - The **FileHandle** of the file which has just been 
created or opened.

**Interception:** If you are using the Procedure model, you must write a handler for this 
message in whatever class will be receiving it (usually the process 
class).

----------
#### MSG_META_DOC_OUTPUT_CREATE_UI_FOR_DOCUMENT
	void	MSG_META_DOC_OUTPUT_CREATE_UI_FOR_DOCUMENT(
			optr		document, /* Pointer to document object */
			FileHandle	file); /* Handle of file associated with 
				 * document object */

The GenDocumentGroup object sends this message after a document has 
been created or opened. Before this message is sent, the 
GenDocumentControl object will enable those objects on its 
*GDCI_enableDisableList*, and the GenDocumentGroup object will copy the 
GenDisplay resource for the document (if one is defined).

Applications that use dynamic UI objects will commonly respond to this 
message by creating the objects for the newly-opened document. Applications 
that use static UI objects will commonly respond to this message by enabling 
the objects.

**Source:** The GenDocumentGroup object.

**Destination:** The output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*document* - The optr of the appropriate document object.

*file* - The FileHandle of the appropriate file.

**Interception:** If you are using the Procedure model, you must write a handler for this 
message in whatever class will be receiving it (usually the process 
class).

----------
#### MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT
	void	MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT(
			optr		document, /* optr of document object */
			FileHandle 	file); /* handle of file for this document */

The GenDocumentGroup object sends this message when the UI for a 
newly-opened document has been created. It also sends this message when 
re-opening a document as part of restoring GEOS from a state file. 
Applications may respond to this by attaching dynamic UI objects and setting 
the values of static UI objects.

**Source:** The GenDocumentGroup object.

**Destination:** Output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*document* - The optr of the document object.

*file* - The FileHandle of the appropriate file.

----------
#### MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT
	void 	MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT(
			optr		document, /* pointer to document object /
			FileHandle 	file); /* handle of file for this document */

The GenDocumentGroup sends this message when a document is being 
closed, whether because a user closes the file or because the application is 
being closed. It also sends this message when GEOS is in the process of saving 
itself to a state file prior to shutting down. Applications generally respond to 
this by detaching dynamic UI objects. Note that the GenDocumentControl 
object will automatically disable any objects in its *GDCI_enableDisableList*. 

**Source:** The GenDocumentGroup object.

**Destination:** Output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*document* - The optr of the appropriate document object.

*file* - The FileHandle of the appropriate file.

**Interception:** If you are using the Procedure model, you must write a handler for this 
message in whatever class will be receiving it (usually the process 
class).

----------
#### MSG_META_DOC_OUTPUT_DESTROY_UI_FOR_DOCUMENT
	void	MSG_META_DOC_OUTPUT_DESTROY_UI_FOR_DOCUMENT(
			optr		document, /* pointer to document object */
			FileHandle 	file); /* handle of file for this document */

The GenDocumentGroup object sends this message out when a document is 
being closed, whether because a user closes the file or because the application 
is being closed. Applications will generally disable static display objects and 
delete dynamic display objects. Note that the GenDocumentControl object 
will automatically disable all objects in its *GDCI_enableDisableList*, and the 
GenDocumentGroup will delete the display block it created for a document, 
if any.

**Source:** The GenDocumentGroup object.

**Destination:** Output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*document* - The optr of the appropriate document object.

*file* - The FileHandle of the appropriate file.

**Interception:** If you are using the Procedure model, you must write a handler for this 
message in whatever class will be receiving it (usually the process 
class).

----------
#### MSG_META_DOC_OUTPUT_ATTACH_FAILED
	void	MSG_META_DOC_OUTPUT_ATTACH_FAILED(
			optr		document, /* pointer to document object */
			FileHandle 	File); /* (former) handle of file for this document */

When GEOS restores itself from state, the document control tries to reattach 
all documents which were attached when GEOS was shut down. If this is 
impossible (as for example if a document was deleted after GEOS shut down), 
the GenDocumentGroup object will send this message to its output.

**Source:** The GenDocumentGroup object.

**Destination:** Output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*document* - The optr of the appropriate document object.

*file* - The FileHandle of the appropriate file.

**Interception:** If you are using the Procedure model, you must write a handler for this 
message in whatever class will be receiving it (usually the process 
class).

#### 13.3.2.2 Messages Handled under the Object Model
If an application uses the Object model of document control, it will generally 
not handle the messages to the GenDocumentGroup's output. Instead, it will 
define a subclass of **GenDocumentClass**; this subclass will have methods 
for those situations which require the application's attention. Note that 
**GenDocumentClass** does not have handlers for any of these messages; if 
the application does not define a method for a given message, that message 
will have no effect.

----------
#### MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE
	Boolean	MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE();

When a new document is created, the document object sends this message to 
itself. VM file based applications will generally respond to this message by 
allocating and initializing the map block. DOS file based applications will 
commonly initialize data structures for a default file. If an application 
maintains data caches for its files, it should initialize the caches at this point.

The application should not take any UI-related actions; those should be 
postponed until the messages 
MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT and 
MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT are received.

**Source:** A GenDocument object.

**Destination:** The document object sends this message to itself.

**Parameters:** Nothing.

**Return:** If the handler could not initialize the file, it should return true; the 
document control will then destroy the new file.

----------
#### MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT
	void	MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT();

The GenDocument object sends this message to itself after a document has 
been created or opened. Before this message is sent, the 
GenDocumentControl object will enable those objects on its 
*GDCI_enableDisableList*, and the GenDocumentGroup object will copy the 
GenDisplay block for the document (if one is defined).

Applications that use dynamic UI objects will commonly respond to this 
message by creating the objects for the newly-opened document. Applications 
that use static UI objects will commonly respond to this message by enabling 
the objects.

**Source:** A GenDocument object.

**Destination:** The document object sends this message to itself.

----------
#### MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	void	MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT();

The document object sends this message to itself when the UI for a 
newly-opened document has been created. It also sends this message when 
re-opening a document as part of restoring GEOS from a state file. 
Applications may respond to this by attaching dynamic UI objects and setting 
the values of static UI objects.

**Source:** A GenDocument object.

**Destination:** The document object sends this message to itself.

----------
#### MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	void	MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT();

The document object sends this message when a document is being closed, 
whether because a user closes the file or because the application is being 
closed. It also sends this message when GEOS is in the process of saving itself 
to a state file prior to shutting down. Applications generally respond to this 
by detaching dynamic UI objects. Note that the GenDocumentControl object 
will automatically disable any objects in its *GDCI_enableDisableList*.

**Source:** A GenDocument object.

**Destination:** The document object sends this message to itself.

----------
#### MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT
	void	MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT();

The GenDocumentGroup object sends this message out when a document is 
being closed, whether because a user closes the file or because the application 
is being closed. Applications will generally disable static display objects and 
delete dynamic display objects. Note that the GenDocumentControl object 
will automatically disable all objects in its *GDCI_enableDisableList*, and the 
GenDocumentGroup will delete the display block it created for a document, 
if any.

**Source:** A GenDocument object.

**Destination:** The document object sends this message to itself.

----------
#### MSG_GEN_DOCUMENT_ATTACH_FAILED
	void	MSG_GEN_DOCUMENT_ATTACH_FAILED();

When GEOS restores itself from state, the document control tries to reattach 
all documents which were attached when GEOS was shut down. If this is 
impossible (as for example if a document was deleted after GEOS shut down), 
the document object will send this message to itself.

**Source:** A GenDocument object.

**Destination:** The document object sends this message to itself.

#### 13.3.2.3 Messages Associated with Common User Actions
A single user action can precipitate several application-handled messages. 
This section lists the messages associated with each of several common user 
actions. Note that some messages are sent as the result of many user actions. 
If a handler needs to find out what user action caused a message to be sent, 
it should send MSG_GEN_DOCUMENT_GET_OPERATION to the document 
object.

If a message is not ordinarily handled, it is enclosed in [brackets] below. 
These messages are documented in the advanced usage section. Actions 
taken by the document control objects (other than messages sent) are listed 
in italics. The messages listed are sent by the appropriate GenDocument 
object to itself. If the message is not subclassed by the GenDocument object, 
it sends a corresponding procedural-model message (of the form 
MSG_META_DOC_OUTPUT...) to the GenDocumentGroup object's output. The 
one exception is MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS; as noted below, this message does not have a corresponding 
MSG_META_DOC_OUTPUT_PHYSICAL_SAVE_AS.

+ New document is created:  
[MSG_GEN_DOCUMENT_PHYSICAL_CREATE]  
*new file is created*  
*VM files: initialize VM attributes, token, protocol*  
MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE  
*if saveAs/Revert supported, save file so revert will return to this state*  
[MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE]  
[MSG_GEN_DOCUMENT_PHYSICAL_SAVE]  
MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT  
MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

+ Document is opened:  
[MSG_GEN_DOCUMENT_PHYSICAL_OPEN]  
[MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE]  
MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT  
MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

+ Document is saved:  
[MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE]  
[MSG_GEN_DOCUMENT_PHYSICAL_SAVE]  
*VM files: call made to VMSave*

+ Document is "Saved As":  
[MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE]  
[MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS]  
[DOS files: MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE]  
*VM files: VMSaveAs called*  
[MSG_GEN_DOCUMENT_SAVE_AS_COMPLETED]  

+ Document is reverted to last-saved version:  
MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT  
[MSG_GEN_DOCUMENT_PHYSICAL_REVERT]  
*VM: VMRevert called*  
[MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE]  
MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

+ Document is about to be closed:  
[MSG_GEN_DOCUMENT_PHYSICAL_CHECK_FOR_MODIFICATIONS]  
**If document is modified & user wants to save changes:**
[MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE]  
[MSG_GEN_DOCUMENT_PHYSICAL_SAVE]  
*VM: VMSave called*  
MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT  
MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT  
**If document is modified and user does not want to save changes:**  
MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT  
[MSG_GEN_DOCUMENT_PHYSICAL_REVERT]  
*VM: VMRevert called*  
MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT  
[MSG_GEN_DOCUMENT_PHYSICAL_CLOSE]  
**If document is not modified:**  
MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT  
MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT  
[MSG_GEN_DOCUMENT_PHYSICAL_CLOSE]  
**If document is not modified and untitled:**  
MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT  
MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT  
[MSG_GEN_DOCUMENT_PHYSICAL_CLOSE]  
[MSG_GEN_DOCUMENT_PHYSICAL_REVERT]

+ GEOS restoring from state, document being attached:  
[MSG_GEN_DOCUMENT_PHYSICAL_OPEN]  
[MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE]  
MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

+ GEOS restoring from state, attach failed:  
MSG_GEN_DOCUMENT_ATTACH_FAILED  
MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT

+ GEOS shutting down, document being detached:  
[MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT]  
[MSG_GEN_DOCUMENT_PHYSICAL_UPDATE]  
*VM files: VMUpdate called*  
MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT  
[MSG_GEN_DOCUMENT_PHYSICAL_CLOSE]

## 13.4 Advanced DC Usage
By now, you should know enough for most uses of the document control. For 
single-document applications which manage GEOS Virtual Memory files and 
use a generic interface, the above documentation should be sufficient. 
However, there are some needs which require more advanced techniques. 
This section details these techniques.

This section discusses the use of document protocols to smooth the process of 
upgrading software. It also discusses using the document control to manage 
multiple documents simultaneously and to manage DOS files. Finally, it 
discusses those messages which an application might need to handle but 
would not ordinarily need to know about.

### 13.4.1 Document Protocols
	MSG_META_DOC_OUTPUT_OPEN_EARLIER_COMPATIBLE_DOCUMENT, 
	MSG_META_DOC_OUTPUT_OPEN_EARLIER_INCOMPATIBLE_DOCUMENT, 
	MSG_GEN_DOCUMENT_OPEN_EARLIER_COMPATIBLE_DOCUMENT, 
	MSG_GEN_DOCUMENT_OPEN_EARLIER_INCOMPATIBLE_DOCUMENT

One difficulty in upgrading software is that an obsolete program may have 
created many documents. If the new version can't read those documents, 
people who used the old version will be inconvenienced; however, if the new 
versions always use the same document formats as the old versions, options 
for improvement will be limited. Above all, if document formats change, the 
new version should detect this gracefully, without crashing or damaging the 
old file.

The header for a GEOS Virtual Memory file contains two words for protocol 
numbers. The document control objects use the protocol numbers to insure 
that a document is compatible with the version of the application which is 
opening it. There are two parts to the protocol number: the *major* protocol 
number, and the *minor* protocol number. (If a document has a major protocol 
number of 3 and a minor number of 11, it is referred to has having protocol 
3.11.) By convention, versions of an application with entirely compatible 
document formats will have the same major protocol number; if a new 
version of an application cannot read older documents without converting 
them in some way, it will have a higher major protocol number, and the minor 
number will be reset to zero.

When the GenDocumentGroup object opens a file, it checks the major and 
minor protocol numbers. It will then take appropriate action:

+ If the document's major and minor protocol numbers match the protocol 
attributes of the GenDocumentGroup object, the document will be 
opened normally. 

+ If the document has a higher protocol number than the 
GenDocumentGroup (i.e. either the document has a higher major 
protocol number, or the document and the GenDocumentGroup have the 
same major protocol number and the document has a higher minor 
protocol number), the document control will display an appropriate alert 
box, after which it will close the file and delete the document object. (It 
will do all of this automatically, without any attention from the 
application.) 

+ If the document has lower major protocol number than the document 
control, the document control will send 
MSG_META_DOC_OUTPUT_UPDATE_EARLIER_INCOMPATIBLE_DOCUM
ENT (and a corresponding MSG_GEN_DOCUMENT_-). If neither message 
is handled, or if a handler returns an error, the document control will 
display an alert box and will close the file and delete the document object. 

+ If the document has the same major but a lower minor protocol number 
than the GenDocumentGroup, the document control will send 
MSG_META_DOC_OUTPUT_UPDATE_EARLIER_COMPATIBLE_DOCUME
NT (and a corresponding MSG_GEN_DOCUMENT_-). After this, it will 
proceed normally, whether the messages were handled or not (since the 
document is presumed to be compatible). If a handler returns an error, it 
will close the file and free the document object.

Note that the document control will not change the file under any of these 
circumstances. In particular, if it opens an earlier document, it will not 
change the document's protocol number. If the application wishes to do this, 
it should do it explicitly (generally in the handlers for the 
"UPDATE_-_DOCUMENT" messages). The protocol numbers are among a 
file's extended attributes. For information about changing extended 
attributes, see section 17.5.3 of "File System," Chapter 17 of the Concepts 
Book.

----------
#### MSG_META_DOC_OUTPUT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT
	Boolean	MSG_META_DOC_OUTPUT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT(
			word *		error, 			/* Return error code from FileError */
			optr 		document,		/* pointer to document object */
			FileHandle 	file); 			/* handle of file opened */

The GenDocumentGroup object sends this message to its output when the 
user tries to open a document with the same major protocol number as the 
document control and a lower minor protocol number. Applications will 
commonly respond to this message by changing the document's protocol 
number to bring it up-to-date. If the application can't use the document, it 
should return *true* and set **error*. (File access error codes are members of the 
**FileError** enumerated type, defined in **file.h**.) With an error, the document 
control will close the document unchanged. If the application successfully 
updates the document, it should return zero and set **error* to zero.

**Source:** The GenDocumentGroup object.

**Destination:** Output of GenDocumentGroup (usually the Process object)

**Parameters:**  
*error* - A pointer to a word in which an error should be 
returned.

*document* - The optr of the appropriate document object.

*file* - The FileHandle of the appropriate file.

**Return:** *true* if error occurs.  
**error* - **FileError** code (or zero if there is no error).

**Interception:** You must write a handler for this message in whatever class will be 
receiving it (usually the process class).

----------
#### MSG_GEN_DOCUMENT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT
	Boolean	MSG_GEN_DOCUMENT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT(
			word *	error); /* Return error code from FileError type */

The document object sends this message when the user tries to open a 
document with the same major protocol number as the document control and 
a lower minor protocol number. Applications will commonly respond to this 
message by changing the document's protocol number to bring it up-to-date. 
If the application can't use the document, it should return *true* and put an 
error code in **error*. (File access error codes are members of the **FileError** 
enumerated type, defined in **file.h**.) With an error, the document control will 
close the document unchanged. If the application successfully updates the 
document, it should return zero and set **error* to zero.

**Source:** A GenDocument object.

**Destination:** The document object sends this message to itself.

**Parameters:**  
*error* - A pointer to a word in which an error should be 
returned.

**Return:** *true* if error occurs.  
**error* - FileError code (or zero if there is no error).

----------
#### MSG_META_DOC_OUTPUT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
	Boolean MSG_META_DOC_OUTPUT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT(
									/* Return true if error */
			word	*error,		/* Return error code from FileError enum. type */
			optr	document,	/* pointer to document object */
			FileHandle file);	/* handle of file opened */

The GenDocumentGroup object sends this message to its output when the 
user tries to open a document with a lower major protocol number than the 
document control. Applications respond to the message by making any 
changes to the document necessary to make it compatible with the 
application. The application should also change the document's protocol 
numbers. If the application can't use the document, it should return *true* and 
put an error code in **error*. (File access error codes are members of the 
**FileError** enumerated type, defined in **file.h**.) With an error, the document 
control will close the document unchanged. If the application successfully 
updates the document, it should return zero and set **error* to zero.

**Source:** The GenDocumentGroup object.

**Destination:** Output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*error* - A pointer to a word in which an error should be 
returned.

*document* - The optr of the appropriate document object.

*file* - The FileHandle of the appropriate file.

**Return:** *true* if error occurs.  
**error* - FileError code (or zero if there is no error).

**Interception:** You must write a handler for this message in whatever class will be 
receiving it (usually the process class)

----------
#### MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
	Boolean	MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT(
			word *	error); /* Return error code from FileError type */

The document object sends this message when the user tries to open a 
document with a lower major protocol number than the document control. 
Applications respond to this message by making any changes to the 
document necessary to make it compatible with the application. The 
application should also change the document's protocol numbers. If the 
application can't use the document, it should return *true* and put an error 
code in **error*. (File access error codes are members of the **FileError** 
enumerated type, defined in **file.h**.) With an error, the document control will 
close the document unchanged. If the application successfully updates the 
document, it should return zero and set **error* to zero.

**Source:** A GenDocument object.

**Destination:** The document object sends this message to itself.

**Parameters:**  
*error* - A pointer to a word in which an error should be 
returned.

**Return:** *true* if error occurs.  
**error* - **FileError** code (or zero if there is no error).

### 13.4.2 Multiple Document Model
The Object model of document control makes it easy to manage several 
documents at once. Effectively, each document object acts as a 
special-purpose application dedicated to handling one file. The display 
control lets the user change documents at will. The document control and 
display control take care of most of the nuts and bolts of file switching, so the 
application doesn't have to worry about them.

#### 13.4.2.1 Subclassing GenDocumentClass
Under the object model of document control, a document's functionality is 
implemented as methods in the document class. Much of the switching 
between documents is thus transparent to the application. When the target 
changes, all user actions will result in messages being sent to the new target 
document; whenever a document gets a message, it knows the message 
pertains to itself, not some other document (and thus knows that it is the 
target document).

In order to implement this functionality, the application must declare a 
subclass of **GenDocumentClass**. This subclass will have its own methods 
for application-handled messages.

#### 13.4.2.2 Using the Display Group
The simplest way to manage multiple documents is to use the display control. 
The display control lets the user change documents transparently to the 
application. In order to do this, the application must define a resource of 
objects which should be copied each time a document is opened or created. 
The GenDocumentGroup object's *GDGI_genDisplay* attribute should be set to 
point to a GenDisplay object in that resource; the GenDisplay should be set 
"not usable" and should be the head of a tree of objects. Also, the application 
should define an object of **GenDisplayGroupClass**, and the 
GenDocumentGroup's *GDGI_genDisplayGroup* attribute should be set to 
point to it. The display control will then automatically switch displays 
whenever the user chooses an entry from the display control.

### 13.4.3 Working with DOS files
	MSG_META_DOC_OUTPUT_PHYSICAL_SAVE, 
	MSG_GEN_DOCUMENT_PHYSICAL_SAVE, 
	MSG_META_DOC_OUTPUT_PHYSICAL_UPDATE, 
	MSG_GEN_DOCUMENT_PHYSICAL_UPDATE, 
	MSG_META_DOC_OUTPUT_PHYSICAL_SAVE_AS_FILE_HANDLE, 
	MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE, 
	MSG_META_DOC_OUTPUT_PHYSICAL_REVERT, 
	MSG_GEN_DOCUMENT_PHYSICAL_REVERT

The document control can be used to handle DOS files. However, there are 
special issues to be aware of. When you use GEOS Virtual Memory files, the 
system takes care of swapping sections of the file in and out of memory as 
needed. You can use high-level commands to mark parts of the file as dirty, 
and when you need the document saved, only the dirty sections will be copied 
to the disk. The details of reading from and writing to the disk are 
transparent to the application.

When you use DOS files, on the other hand, you have to take care of all of 
these details yourself. It is usually impractical to keep all of a document in 
memory at one time, so you have to have some way of managing the data 
(perhaps by creating a temporary VM file and copying the DOS file into that).

For this reason, the document control sends out messages when it does many 
low-level things (such as save files). If the application needs to take special 
actions, it can define handlers for these messages. Most of these messages 
can be ignored if you are working with GEOS files. 

If you want to implement "Save As" and "Revert" for DOS files, you will have 
to do most of it by hand. If you leave "Save As" and "Revert" enabled, the 
Document Control will do some of the work for you. For example, when the 
user chooses "Save As", the Document Control will first present a File 
Selector, letting the user choose a file name and location. The Document 
Control will then create the new file. After this it will send out 
MSG_META_DOC_OUTPUT_PHYSICAL_SAVE_AS_FILE_HANDLE and 
MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE, passing the 
handle of the newly-created file. The application is responsible for writing the 
current version of the document to the new file, and reverting the original file 
to its last-saved state. The Document Control will automatically close the 
original file and update all Document Control instance data as necessary.

----------
#### MSG_META_DOC_OUTPUT_PHYSICAL_SAVE
	Boolean	MSG_META_DOC_OUTPUT_PHYSICAL_SAVE(
			word *			error, 
			optr 			document,
			FileHandle 		file);

If you need to take special steps to save a file, you should have a handler for 
either this message or MSG_GEN_DOCUMENT_PHYSICAL_SAVE. The 
handler should write the file completely to the disk. If an error occurs, return 
*true* and write the error code in **error.* (File access error codes are members 
of the **FileError** enumerated type, defined in **file.h**.)

If, for example, you copy a DOS file into a temporary VM file while you work 
on it, you would probably respond to this message by copying the data from 
the temporary file back to the DOS file.

**Source:** The GenDocumentGroup object.

**Destination:** Output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*error* - A pointer to a word in which an error should be 
returned.

*document* - The optr of the appropriate document object.

*file* - The FileHandle of the appropriate file.

**Interception:** DOS-based applications must handle either this message or 
MSG_GEN_DOCUMENT_PHYSICAL_SAVE. Applications which use 
GEOS data files will generally not intercept this message.

**Return:** *true* if error occurs.  
**error* - **FileError** code (or zero if there is no error).

----------
#### MSG_GEN_DOCUMENT_PHYSICAL_SAVE
	Boolean	MSG_GEN_DOCUMENT_PHYSICAL_SAVE(
		word *	error); 		/* Error code from FileError type */

This message is sent when the user saves a file. If you need to take special 
steps to save a file, you should have a handler for either this message or 
MSG_META_DOC_OUTPUT_PHYSICAL_SAVE. The handler should write the 
file completely to the disk. If an error occurs, return *true* and write the error 
code in **error*. (File access error codes are members of the **FileError** 
enumerated type, defined in **file.h**.)

If, for example, you copy a DOS file into a temporary VM file while you work 
on it, you would probably respond to this message by copying the data from 
the temporary file back to the DOS file.

**Source:** The GenDocument object.

**Destination:** The document object sends this message to itself.

**Parameters:**  
*error* - A pointer to a word in which an error should be 
returned.

**Return:** *true* if error occurs.  
**error* - **FileError** code (or zero if there is no error).

**Interception:** DOS-based applications must handle either this message or 
MSG_META_DOC_OUTPUT_PHYSICAL_SAVE. Applications which use 
GEOS data files will generally not intercept this message.

----------
#### MSG_META_DOC_OUTPUT_PHYSICAL_UPDATE
	Boolean	MSG_META_DOC_OUTPUT_PHYSICAL_UPDATE(occurred */
			word *		error, 		/* Error code from FileError type */
			optr 		document,	/* Pointer to document object */
			FileHandle 	file);		/* Handle of DOS file */

This message is sent when the file is auto-saved (if this is enabled), and when 
the document is detached as part of a GEOS shutdown. If you need to take 
special steps to save a file, you should have a handler for either this message 
or MSG_GEN_DOCUMENT_PHYSICAL_UPDATE. The handler should write 
the file completely to the disk. If an error occurs, return *true* and write the 
error code in **error*. (File access error codes are members of the **FileError** 
enumerated type, defined in **file.h**.)

If, for example, you copy a DOS file into a temporary VM file while you work 
on it, you would probably respond to this message by copying the data from 
the temporary file back to the DOS file.

**Source:** The GenDocumentGroup object.

**Destination:** Output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*error* - A pointer to a word in which an error should be 
*returned.

document* - The optr of the appropriate document object.

*file* - The FileHandle of the appropriate file.

**Return:** *true* if error occurs.  
**error* - **FileError** code (or zero if there is no error).

**Interception:** DOS-based applications which will have auto-save capability must 
handle either this message or 
MSG_GEN_DOCUMENT_PHYSICAL_UPDATE. Applications which use 
GEOS data files will generally not intercept this message.

----------
#### MSG_GEN_DOCUMENT_PHYSICAL_UPDATE
	Boolean	MSG_GEN_DOCUMENT_PHYSICAL_UPDATE(
			word *	error); 		/* Error code from FileError type */

This message is sent when the file is auto-saved (if this is enabled), and when 
the document is detached as part of a GEOS shutdown. If you need to take 
special steps to save a file, you should have a handler for either this message 
or MSG_META_DOC_OUTPUT_PHYSICAL_UPDATE. The handler should write 
the file completely to the disk. If an error occurs, return *true* and write the 
error code in **error*. (File access error codes are members of the **FileError** 
enumerated type, defined in **file.h**.)

If, for example, you copy a DOS file into a temporary VM file while you work 
on it, you would probably respond to this message by copying the data from 
the temporary file back to the DOS file.

**Source:** A GenDocument object.

**Destination:** The document object sends this message to itself.

**Parameters:**  
*error* - A pointer to a word in which an error should be 
returned.

**Return:** true if error occurs.  
**error* - **FileError** code (or zero if there is no error).

**Interception:** DOS-based applications which will have auto-save capability must 
handle either this message or 
MSG_META_DOC_OUTPUT_PHYSICAL_UPDATE. Applications which 
use GEOS data files will generally not intercept this message.

----------
#### MSG_META_DOC_OUTPUT_PHYSICAL_SAVE_AS_FILE_HANDLE
	Boolean	MSG_META_DOC_OUTPUT_PHYSICAL_SAVE_AS_FILE_HANDLE(
			word *			error,
			optr			document,
			FileHandle		file);

This message is sent when the Document Control is ready to "save-as" a DOS 
file. The Document Control will have asked the user what the new file should 
be, and will have created an appropriate file. The handler for this message 
must write the current version of the document to the new file, and restore 
the original file to its last-saved state.

**Source:** The GenDocumentGroup object.

**Destination:** The output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*error* - A pointer to a word in which an error code should 
be returned.

*document* - The optr of the appropriate document object.

*file* - The handle of the newly-opened file. The current 
version of the document should be saved to this file.

**Return:** *true* if an error occurred.  
**file* - A member of the **FileError** enumerated type (if an 
error occurred).

**Interception:** DOS-file applications must intercept this message (or 
MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE) if they 
wish to implement save-as/revert functionality. 

----------
#### MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE
	Boolean	MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE(
			word *			error,
			FileHandle		file);

This message is sent when the Document Control is ready to "save-as" a DOS 
file. The Document Control will have asked the user what the new file should 
be, and will have created an appropriate file. The handler for this message 
must write the current version of the document to the new file, and restore 
the original file to its last-saved state.

**Source:** A GenDocument.

**Destination:** The GenDocument object sends this message to itself.

**Parameters:**  
*error* - A pointer to a word in which an error code should 
be returned.

*file* The handle of the newly-opened file. The current 
version of the document should be saved to this file.

**Return:** *true* if an error occurred.  
**error* - A member of the **FileError** enumerated type (if an 
error occurred).

**Interception:** DOS-file applications must intercept this message (or 
MSG_META_DOC_OUTPUT_PHYSICAL_SAVE_AS_FILE_HANDLE) if 
they wish to implement save-as/revert functionality. 

----------
#### MSG_META_DOC_OUTPUT_PHYSICAL_REVERT
	Boolean	MSG_META_DOC_OUTPUT_PHYSICAL_REVERT(
			word *		error,
			optr		document,
			FileHandle		file);

The Document Control sends this message to revert a DOS file to its 
last-saved state. The handler must restore the file to its condition as of the 
last time it was saved.

**Source:** The GenDocumentGroup object.

**Destination:** The output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*error* - A pointer to a word in which an error should be 
returned.

*document* - The optr of the appropriate document object.

*file* - The FileHandle of the appropriate file.

**Return:** *true* if error occurs.  
**error* - **FileError** code (or zero if there is no error).

**Interception:** DOS-file applications must intercept this message (or 
MSG_GEN_DOCUMENT_PHYSICAL_REVERT) if they wish to implement 
save-as/revert functionality. 

----------
####MSG_GEN_DOCUMENT_PHYSICAL_REVERT
	Boolean	MSG_GEN_DOCUMENT_PHYSICAL_REVERT(
			word *			error,
			FileHandle		file);

The Document Control sends this message to revert a DOS file to its 
last-saved state. The handler must restore the file to its condition as of the 
last time it was saved.

**Source:** The GenDocumentGroup object.

**Destination:** The output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*error* - A pointer to a word in which an error should be 
returned.

*file* - The FileHandle of the appropriate file.

**Return:** *true* if error occurs.  
**error* - **FileError** code (or zero if there is no error).

**Interception:** DOS-file applications must intercept this message (or 
MSG_META_DOC_OUTPUT_PHYSICAL_REVERT) if they wish to 
implement save-as/revert functionality. 

### 13.4.4 Special-Purpose Messages
In addition to the basic messages discussed above, there are messages the 
document control sends out which do not ordinarily need to be handled. Some 
of these messages have been discussed above; most of the rest are described 
here.

#### 13.4.4.1 Caching Data in Memory
	MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE, 
	MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE, 
	MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE, 
	MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE

Sometimes an application will want to keep frequently-accessed data in 
memory. For example, if you are managing Virtual Memory files, you may 
want to copy the map block to a fixed memory block instead of locking the 
block every time you need to read or change it. This is known as caching data.

If you cache data, you must make sure that the application's version of the 
data is consistent with the disk file. The document control helps keep track 
of this. Whenever the file (or the state) is saved, the document control will 
first send a message instructing the application to write the cache to the file, 
then it will save the file. Similarly, when the file is opened or GEOS is 
restarted from state, the document control will send a message instructing 
the application to reload the cached data from the file.

There is one special concern. The user cannot save a file unless it has been 
marked dirty; also, the document control does not send 
MSG_-_WRITE_CACHED_DATA_TO_FILE to documents which are not dirty. 
Therefore, if you change the data cache without actually altering the file, you 
should send a MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY to the 
GenDocumentGroup.

----------
#### MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE
	void	MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE(
			optr 		document,	/* optr of document object */
			FileHandle 	file);		/* FileHandle of associated file */

The GenDocumentGroup sends this message when the document needs to 
read cached data. In particular, it sends this when a document is opened, 
when a document is reverted to its last-saved state, and when a document is 
re-opened as GEOS restores from state. If the application maintains a data 
cache, it should read the data from the file at this point. If the document does 
not cache data, it can ignore this message.

Note that if the document control notices that the file has changed on disk, it 
will not send this message; it will, however, send a 
MSG_META_DOC_OUTPUT_DOCUMENT_HAS_CHANGED. The handler for 
that message should reread the cache or call the handler for this message.

**Source:** The GenDocumentGroup object.

**Destination:** Output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*document* - The optr of the appropriate document object.

*file* - The FileHandle of the appropriate file.

**Interception:** You must write a handler for this message in whatever class will be 
receiving it (usually the process class).

----------
#### MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE
	void	MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE();

The document object sends this message to itself when the document needs 
to read cached data. In particular, it sends this when a document is opened, 
when a document is reverted to its last-saved state, and when a document is 
re-opened as GEOS restores from state. If the application maintains a data 
cache, it should read the data from the file at this point. If the document does 
not cache data, it can ignore this message.

Note that if the document control notices that the file has changed on disk, it 
will not send this message; it will, however, send a 
MSG_GEN_DOCUMENT_DOCUMENT_HAS_CHANGED. The handler for that 
message should reread the cache or call the handler for this message.

**Source:** A GenDocument object.

**Destination:** The document object sends this message to itself.

----------
#### MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE
	void	MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE(
			optr 		document,	/* optr of document object */
			FileHandle 	file);		/* FileHandle of associated file */

The GenDocumentGroup object sends this message when the document 
needs to write cached data back to the file. In particular, it sends this 
message just before a document is saved, auto-saved, or "Saved As," and 
before the document is closed as GEOS shuts down. The document should 
write its cached data back to the file. If the document does not cache data, it 
can ignore this message.

**Warnings:** This message will not be sent if the document is clean. Therefore, if you 
change the data cache without changing the file, you should send a 
MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE to the 
GenDocumentGroup object.

**Source:** The GenDocumentGroup object.

**Destination:** Output of GenDocumentGroup (usually the Process object)

**Parameters:**  
*document* - The optr of the appropriate document object.

*file* - The FileHandle of the appropriate file.

**Interception:** You must write a handler for this message in whatever class will be 
receiving it (usually the process class).

----------
#### MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE
	void	MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE();

The document object sends this message to itself when the document needs 
to write cached data back to the file. In particular, it sends this message just 
before a document is saved, auto-saved, or "Saved As," and before the 
document is closed as GEOS shuts down. The document should write its 
cached data back to the file. If the document does not cache data, it can ignore 
this message.

**Warnings:** This message will not be sent if the document is clean. Therefore, if you 
change the data cache without changing the file, you should send a 
MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE to the 
GenDocumentGroup object.

**Source:** A GenDocument object.

**Destination:** The document object sends this message to itself.

#### 13.4.4.2 Other Messages To Know About
There are a few other messages which are worth knowing about. These 
messages alert the application to special situations. Most applications can 
ignore these messages; however, for a few, these messages should be handled.

----------
#### MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED
	void	MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED(
			optr 		document,	/* optr of document object */
			FileHandle 	file);		/* FileHandle of associated file */

The GenDocumentGroup object sends this message when a "Save As" 
operation has been successfully completed.

**Source:** The GenDocumentGroup object.

**Destination:** Output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*document* - The optr of the appropriate document object.

*file* - The FileHandle of the appropriate file.

**Interception:** You must write a handler for this message in whatever class will be 
receiving it (usually the process class).

----------
#### MSG_GEN_DOCUMENT_SAVE_AS_COMPLETED
	void	MSG_GEN_DOCUMENT_SAVE_AS_COMPLETED();

The document object sends this message to itself when a "Save As" operation 
has been successfully completed. 

**Source:** A GenDocument object.

**Destination:** The document object sends this message to itself.

----------
#### MSG_META_DOC_OUTPUT_DOCUMENT_HAS_CHANGED
	void	MSG_META_DOC_OUTPUT_DOCUMENT_HAS_CHANGED(
			optr 		document,	/* optr of document object */
			FileHandle 	file);		/* FileHandle of associated file */

If the GDGA_AUTOMATIC_CHANGE_NOTIFICATION attribute of the 
GenDocumentGroup object is set to on, a timer will periodically check to see 
if any open documents have been changed by another application. If they 
have, the GenDocumentGroup object will send this message out. The 
application should respond by redisplaying the data on the screen and 
rereading any cached data from the file.

**Source:** The GenDocumentGroup object.

**Destination:** Output of GenDocumentGroup (usually the Process object).

**Parameters:**  
*document* - The optr of the appropriate document object.

*file* - The FileHandle of the appropriate file.

**Interception:** You must write a handler for this message in whatever class will be 
receiving it (usually the process class).

----------
#### MSG_GEN_DOCUMENT_DOCUMENT_HAS_CHANGED
	void	MSG_GEN_DOCUMENT_DOCUMENT_HAS_CHANGED();

If the GDGA_AUTOMATIC_CHANGE_NOTIFICATION attribute of the 
GenDocumentGroup object is set to on, a timer will periodically check to see 
if any open documents have been changed by another application. If they 
have, the document object will send this message out. The application should 
respond by redisplaying the data on the screen and rereading any cached 
data from the file.

**Source:** A GenDocument object.

**Destination:** The document object sends this message to itself.

### 13.4.5 Forcing Actions
	MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG, 
	MSG_GEN_DOCUMENT_CONTROL_INITIATE_NEW_DOC, 
	MSG_GEN_DOCUMENT_CONTROL_INITIATE_USE_TEMPLATE_DOC, 
	MSG_GEN_DOCUMENT_CONTROL_INITIATE_USE_TEMPLATE_DOC, 
	MSG_GEN_DOCUMENT_CONTROL_INITIATE_OPEN_DOC, 
	MSG_GEN_DOCUMENT_CONTROL_INITIATE_IMPORT_DOC, 
	MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_DOC, 
	MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC, 
	MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_TEMPLATE_DOC, 
	MSG_GEN_DOCUMENT_CONTROL_INITIATE_COPY_TO_DOC, 
	MSG_GEN_DOCUMENT_CONTROL_INITIATE_EXPORT_DOC, 
	MSG_GEN_DOCUMENT_CONTROL_INITIATE_SET_TYPE_DOC, 
	MSG_GEN_DOCUMENT_CONTROL_INITIATE_SET_PASSWORD_DOC(

If you wish, you can force the document control to take certain actions as if 
the user had requested them. You do this by sending the message which 
would ordinarily trigger such an action. For example, when the user selects 
the "save" trigger, that trigger sends the message 
MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_DOC to the Document 
Control object. If you wish, you can force a save by sending this message 
manually; the document control will behave as if the user had selected that 
action.

----------
#### MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
	void	MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG();

This message forces the document control to display the opening "New/Open" 
dialog box, as if the user had selected the "New/Open" trigger on the File 
menu.

**Source:** Unrestricted.

**Destination:** The GenDocumentControl object.

**Parameters:** None.

**Interception:** This message is not normally intercepted.

----------
#### MSG_GEN_DOCUMENT_CONTROL_INITIATE_NEW_DOC
	void	MSG_GEN_DOCUMENT_CONTROL_INITIATE_NEW_DOC();

This message forces the document control to create a new file, exactly as if 
the user had requested it.

**Source:** Unrestricted.

**Destination:** The GenDocumentControl object.

**Parameters:** None.

**Interception:** This message is not normally intercepted.

----------
#### MSG_GEN_DOCUMENT_CONTROL_INITIATE_USE_TEMPLATE_DOC
	void	MSG_GEN_DOCUMENT_CONTROL_INITIATE_USE_TEMPLATE_DOC();

This message forces the document control to create a new file from a template 
(bringing up an appropriate file selector), exactly as if the user had requested 
it.

**Source:** Unrestricted.

**Destination:** The GenDocumentControl object.

**Parameters:** None.

**Interception:** This message is not normally intercepted.

----------
#### MSG_GEN_DOCUMENT_CONTROL_INITIATE_OPEN_DOC
	void	MSG_GEN_DOCUMENT_CONTROL_INITIATE_OPEN_DOC();

This message forces the document control to open a file (bringing up the 
appropriate file selector), exactly as if the user had requested it.

**Source:** Unrestricted.

**Destination:** The GenDocumentControl object.

**Parameters:** None.

**Interception:** This message is not normally intercepted.

----------
#### MSG_GEN_DOCUMENT_CONTROL_INITIATE_IMPORT_DOC
	void	MSG_GEN_DOCUMENT_CONTROL_INITIATE_IMPORT_DOC();

This message forces the document control to import a file (bringing up the 
appropriate file selector), exactly as if the user had requested it.

**Source:** Unrestricted.

**Destination:** The GenDocumentControl object.

**Parameters:** None.

**Interception:** This message is not normally intercepted.

----------
#### MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_DOC
	void	MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_DOC();

This message forces the document control to save the active file, exactly as if 
the user had requested it.

**Source:** Unrestricted.

**Destination:** The GenDocumentControl object.

**Parameters:** None.

**Interception:** This message is not normally intercepted.

----------
#### MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC
	void	MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC();

This message forces the document control to save the active file under a new 
name (bringing up the appropriate file selector), exactly as if the user had 
requested it.

**Source:** Unrestricted.

**Destination:** The GenDocumentControl object.

**Parameters:** None.

**Interception:** This message is not normally intercepted.

----------
#### MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_TEMPLATE_DOC
	void	MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_TEMPLATE_DOC();

This message forces the document control to save the active file as a template 
(bringing up the appropriate file selector), exactly as if the user had 
requested it.

**Source:** Unrestricted.

**Destination:** The GenDocumentControl object.

**Parameters:** None.

**Interception:** This message is not normally intercepted.

----------
#### MSG_GEN_DOCUMENT_CONTROL_INITIATE_COPY_TO_DOC
	void	MSG_GEN_DOCUMENT_CONTROL_INITIATE_COPY_TO_DOC();

This message forces the document control to copy the active file to a new 
name (bringing up the appropriate file selector), exactly as if the user had 
requested it.

**Source:** Unrestricted.

**Destination:** The GenDocumentControl object.

**Parameters:** None.

**Interception:** This message is not normally intercepted.

----------
#### MSG_GEN_DOCUMENT_CONTROL_INITIATE_EXPORT_DOC
	void	MSG_GEN_DOCUMENT_CONTROL_INITIATE_EXPORT_DOC();

This message forces the document control to export the active file (bringing 
up the appropriate file selector), exactly as if the user had requested it.

**Source:** Unrestricted.

**Destination:** The GenDocumentControl object.

**Parameters:** None.

**Interception:** This message is not normally intercepted.

----------
#### MSG_GEN_DOCUMENT_CONTROL_INITIATE_SET_TYPE_DOC
	void	MSG_GEN_DOCUMENT_CONTROL_INITIATE_SET_TYPE_DOC();

This message forces the document control to change the type (public, 
read-only, etc.) of the active file (bringing up the appropriate dialog box), 
exactly as if the user had requested it.

**Source:** Unrestricted.

**Destination:** The GenDocumentControl object.

**Parameters:** None.

**Interception:** This message is not normally intercepted.

----------
#### MSG_GEN_DOCUMENT_CONTROL_INITIATE_SET_PASSWORD_DOC
	void	MSG_GEN_DOCUMENT_CONTROL_INITIATE_SET_PASSWORD_DOC();

This message forces the document control to set the password of the active 
file (bringing up the appropriate dialog box), exactly as if the user had 
requested it.

**Source:** Unrestricted.

**Destination:** The GenDocumentControl object.

**Parameters:** None.

**Interception:** This message is not normally intercepted.

[Generic UI Controllers](ogenctl.md) <-- [Table of Contents](../objects.md) &nbsp;&nbsp; --> [GenFile Selector](ogenfil.md)

