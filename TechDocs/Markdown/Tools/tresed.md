## 8 Resource Editor

The Resource Editor is a tool created by Geoworks to translate the existing 
English language GEOS executables into your local language. 

As with any other application, the best way to learn how to use this tool is by 
experimentation. As you work through these instructions, have a copy of the 
Resource Editor running on one of your machines so that you can try for 
yourself some of the tasks outlined here.

Note that this documentation is somewhat redundant with other parts of the 
GEOS Technical Documentation. This is because we've tried to make ResEdit 
usable by non-programmers. Ideally, the only skills one should need to 
localize an application to a foreign language is knowledge of the source and 
target languages - the translator shouldn't have to work with the source 
code. If you are following this model, you may wish to give just this piece of 
documentation to your translator instead of burdening them with a full 
documentation set.

### 8.1 Glossary

In explaining how to use the Resource Editor, it is important that we use the 
same vocabulary to describe a certain portion of the code or the operation 
which must take place. In order to alleviate confusion, take a look through 
the following definitions, and refer back to them as necessary as you read the 
rest of these instructions:

**Executable (Geode)**  
An executable (also called a geode) is a combination of 
assembly code that may be run and strings or bitmaps which 
may be displayed. Some executables, such as applications, are 
run by the user, while others, like printer drivers, are loaded 
and run automatically by GEOS when the user specifies an 
action like printing.

**Source Executable**  
The original English language executable.

**Destination Executable**  
The local language executable, which is created by translating 
the source executable. 

**Resource**  
Geodes consist of a series of divisions known as resources. 
Resources may contain code that will be executed, data that 
will be referred to, or strings/bitmaps which will be displayed 
to users. GEOS uses the concept of resources to minimize the 
amount of memory an application uses by only loading into 
memory those resources needed. The Resource Editor will only 
allow you to edit those resources which contain strings or 
bitmaps. Each of these will have its own unique number or 
extended name.

**Chunk**  
Chunks (or more formally known as local memory chunks) are 
yet another way GEOS divides up an executable. Inside a 
resource, there are many different kind of chunks, each 
containing a unique piece of information, such as a text string, 
a bitmap or an object structure. All executables have their 
externally visible strings stored in separate chunks, which 
allows you to modify those chunks and create a translation. 
The Resource Editor will only allow you to edit chunks, not the 
lower level of bits and bytes. Each chunk will also have a 
unique number or name.

**Object**  
The GEOS operating system is object oriented, that is, the 
visible items on your screen - windows, triggers, dialog boxes - 
are all objects which are stored in local memory chunks. Each 
object may have a moniker and some objects have keyboard 
accelerators. These two attributes are editable.

**Driver**  
A driver is a special sort of executable that performs a very 
specific function that may not be needed by every user. In 
GEOS, there are DOS, video, mouse, and printer drivers, all 
created to minimize the amount of memory used by the system. 
Most drivers are designed to work with more than one device. 
For example, the EPSON9.GEO printer driver actually supports 
more than 50 printers, and in fact, the names of these printers 
are exactly what you will be able to translate.

**Localization File**  
When a geode is created, an extra file to be used by the 
Resource Editor is created at the same time. This file (which is 
named like the .geo file but with a .vm extension) contains 
localization information about the resources and chunks which 
you will be editing. You cannot edit a geode without this file.

**Translation File**  
The file that the Resource Editor creates is called a translation 
file. The information stored in this file will be merged with the 
source executable to create the destination executable. 
Internally, the file holds a copy of the original English text or 
bitmap, along with your translation and may contain some 
translation instructions.

**Text String**  
Longer text such as error messages.

**Moniker**  
Shorter text which serves as the visual name for objects such 
as menu items, button labels, and dialog box options.

**Mnemonic**  
A key that when pressed with the Alt key will activate a specific 
menu item which has this letter or symbol underlined in its 
moniker.

**GString**  
Graphics string (not editable with current Resource Editor)

**Bitmap**  
Actual bitmap image (not editable with current Resource 
Editor)

**Keyboard Shortcut**  
A combination of keystrokes than when pressed will cause an 
object to perform a specific action. Keyboard shortcuts are 
stored in the chunk containing the object to which they are 
connected.

**Updating**  
Unfortunately, software changes. As you make changes to the 
English language software, it might become necessary for you 
to take a translation file you created with an older version of a 
particular geode, and update it with the newer version. The 
newest software may contain new strings, have modified 
existing strings, or eliminated some strings. The Resource 
Editor is however able to match these two executables and 
show the newest changes. The process of updating a file will be 
discussed in more detail later in these instructions.

### 8.2 Getting Started

You will need to install localization target version of Ensemble 2.0 in a 
directory of your target machine (for example \TARGET.20); This 
environment will be your destination for new localized executables. As you 
work along, you will replace the English executables in this structure with 
your translated executables. This will be explained in more detail later.

Note: you may wish to not have these directories in your path. We suggest 
that you edit batch files to run each installation.

### 8.3 What Needs to be Translated?

To create a localized version of your applications, you will need to translate 
only the applications, libraries, and drivers you have created. All Geoworks 
software will be translated by Geoworks. 

Most applications will use GEOS system libraries whose own UI is visible 
from the application. For example, an application which includes spell 
checking will have a dialog box containing all the information about the spell 
checking operation which is included from the Spell library. If the Spell 
library is not translated, that UI will always appear in its original form. Your 
application will work with the Spell library, whether or not it has been 
translated.

### 8.4 Translating

At this point you are ready to translate geodes into the target language. The 
following set of steps can be carried out by a non-programmer running the 
ResEdit tool. Of course, the translator should have a good idea of the geode's 
function and use.

#### 8.4.1 Choosing a new translation file

To begin creating new translation files, double click on the "Res Edit" icon in 
the Tools folder of the WORLD directory of the LOCALIZE.20 version of 
Ensemble 2.0. 

This brings up a dialog box which gives you two choices:

+ Create New Translation File

+ Open a Translation File

Choosing the "new" option opens a second dialog box which asks you to select 
the localization (.vm) file for the geode you wish to edit. Choosing the "open" 
option brings up an existing translation file for further editing. In either case, 
the order in which you do the translations is your decision.

The first time you open the Resource Editor, it assumes you will be editing 
geodes in the GEOS20 directory, or whatever installation of GEOS you started 
in. Once you have a translation file open, you can then change the top-level 
directory by clicking on the "Set source directory" in the Project Menu. This 
setting is saved in your .ini file, so the next time you start ResEdit, it will 
automatically set the top-level source directory to what it was when exited.

If you want to create a new translation file for a geode that is not in the 
GEOS20 installation (or whichever installation is currently set as the 
top-level source directory) you must change the top-level source directory 
first.

#### 8.4.2 Main translation screen

After selecting a localization (.vm) file to translate, the Resource Editor will 
then load the information from this file and the corresponding geode into an 
untitled Translation file saved into the DOCUMENT directory. The file will be 
displayed in two views. The left portion of the screen is the Source File, while 
the right portion is the Translation File. When the file is first opened, the two 
sides look the same, since no translations have yet been made. 

The Resource Editor brings up all the strings or bitmaps which need to be 
translated, regardless of their context. The only way you will be able to be 
completely sure that the translation is accurate is to enter the translation 
and then actually run the translated executable (to be discussed later) and 
see how the translations appear in the program.

#### 8.4.3 Translating a Text String

Click on any text string in the right portion of the screen. The blinking text 
editing cursor should appear, and you will be able to edit the text in the right 
screen to reflect the changes necessary for the local language. The text in the 
left portion of the screen acts as a guide and will not change.

At the bottom of the main screen, there are three fields which may have 
important information about how you should translate the selected chunk. 

+ The Minimum and Maximum Length fields show the size limits on the 
number of characters that the selected chunk may have. 

+ The Instructions field shows special characteristics of the selected chunk, 
or may give a context where the specific chunk appears.

If there is nothing in these fields, there are no constraints on the size or 
content of the translation.

You will also notice that one letter of many words in the chunks is underlined. 
This "mnemonic" can be changed by using the two arrows in the upper right 
corner of the main translation screen labeled Mnemonic. Moving up or down 
will move the underscored letter to the left and right in the translated chunk. 
You can also edit a mnemonic by selecting the text in the Mnemonic display 
and replacing it with the new letter. The first occurrence of that letter in the 
text string will now be underlined. if that letter is not in the text, it will 
become parenthesized in the Mnemonic object. This type of mnemonic is 
displayed not as an underlined character in a moniker, but is drawn in 
parenthesis after the moniker text. This type of mnemonic is rarely used, but 
may be helpful if you have mnemonics which conflict. You must be careful not 
to assign the same mnemonic to two monikers whose objects are both in the 
active window at the same time. if there is such a conflict, only one of the two 
objects will be activated by this mnemonic. When you have created the 
executable, you should check that there are no conflicting mnemonics, and 
change any which are found to overlap with others at the same level.

In some cases, an object will have a keyboard shortcut in addition to a 
moniker mnemonic. These keyboard shortcuts consists of a combination of 
control keys and character keys or can be function keys (F1-F12). If you see 
"Type : Chunk" in the upper right corner, the currently highlighted chunk 
will contain a non-editable textual representation of the object's keyboard 
shortcut. The keyboard shortcut trigger will now be enabled (the Shortcut 
button in the middle of the main translation screen), and you can pop up a 
dialog box containing buttons and text which will be used to modify the 
shortcut. Currently, only text-based shortcuts are displayed, and are 
therefore, modifiable. Again, it is important to watch out for overlapping 
shortcuts, as these cannot be detected by the Resource Editor.

#### 8.4.4 Moving between chunks

+ Use the mouse to click on any chunk.

+ Type Ctrl .(Ctrl-period) to move to the next chunk or Ctrl , (Ctrl-comma) 
to move to the previous chunk.

+ Click on Next Chunk/Previous Chunk in the Utilities menu.

+ Click on the Chunk pop-up menu in the upper left corner of the screen 
and  choose any chunk.

#### 8.4.5 Moving between resources

+ Type Ctrl > (Ctrl-greater) to move to the next resource or Ctrl < 
(Ctrl-less) to move to the previous resource. 

+ Click on Next Resource/Previous Resource in the Utilities menu.

+ Click on the Resource pop-up menu in the upper left corner of the screen 
and choose any resource.

### 8.5 Resource Editor Menus

Many of these features available in the Resource Editor are identical to those 
in the Ensemble 2.0 software. The quick overview of the menu items below 
should give you the necessary information to use all of the features.

#### 8.5.1 File Menu

**New/Open:**  
brings up the New/Open dialog box, allowing you to open a new           
translation file or an existing one.

**Close:**  
closes the active translation file.

**Save:**  
saves the open translation file.

**Save As:**  
saves the open translation file under a different name.

**Backup:**  
makes a backup of the open translation file or restores from a backup           file.

**Other:**

+ **Copy To:**  
creates a copy of the translation file and places it in a user              
selected directory.

+ **Discard Changes:**  
discards all changes since last saved version of the translation 
file.

+ **Rename:**  
gives the translation file a new name.

+ **Edit Document Notes:**  
edits the notes for the translation file.

+ **Set Document Password:**  
creates a document password.

+ **Set Document Type:**  
allows the user to choose between a normal, read-only, or public 
document.

**New Name and User Notes:**  
allows user to change geode name and make annotations to the file for 
later reference.

**Create a New Executable:**  
takes the translation file, merges it with the source code and creates a 
new localized executable. The process of creating executables will be 
discussed in more detail later in this document.

**Update:**

+ **Update Translation file:**  
using a new or updated geode, matches chunks in the old file 
with those in the new file, creating an updated translation file 
which shows new or changed chunks and groups deleted 
chunks at the end.

+ **Commit the update:**  
deletes intermediate matching information, showing only the 
newest version of the translation file

**Exit:**  
exits the Resource Editor

#### 8.5.2 Edit Menu

**Cut:**  
takes highlighted information and moves it to the clipboard

**Copy:**  
takes highlighted information and copies it to the clipboard, leaving a 
copy in place

**Paste:**  
pastes information from the clipboard to the location of the cursor

**Undo:**  
reverts to previous saved version of individual chunk

**Find and Replace:**  
allows user to search for designated words throughout the translation file 
and replace text in the translation file (as displayed in the right view) 
with local language translation. You can limit a forward or backward 
search by selecting filters for certain types of chunks from the Filters 
menu.

#### 8.5.3 Project Menu

The items in this menu keep track of how your project is organized.

**Source directory:**  
Set the top level directory holding source geodes.

**Destination directory:**  
Set the top level directory holding modified geodes.

**Reset Source Geode Path:**  
Reset the path of the source geode if it moves to a different subdirectory.

#### 8.5.4 Filter Menu

Each of these menu items is a radio button, which allows you to turn on or      
off as many of these filters as you like. These options can be helpful when         
editing updated translation files.

**Don't show Text:**

**Don't show Monikers:**

**Don't show GStrings:**

**Don't show Bitmaps:**

**Don't show Objects:**

Each of these menu items is a radio button which allows you to view specific 
chunks affected by updating the translation file.

**Show changed chunks:**

**Show new chunks:**

**Show deleted chunks:**

#### 8.5.5 Utilities Menu

These menu items allow for quick movement between chunks and resources.

**Next Chunk:**

**Previous Chunk:**

**Next Resource:**

**Previous Resource:**

#### 8.5.6 Window Menu

These menu items make manipulation of multiple translation files easy, by       
opening overlapping windows or tiling active windows.

**Overlapping:**

**Full-Sized:**

**Tile:**

### 8.6 Creating an Executable

After all of the chunks and resources in the selected .vm file have been 
translated and saved in a translation file, a new local language executable 
can be created in the target installation. 

The first step to placing the new executable in the correct place is making 
sure that the localization target kit has been placed in another directory on 
your hard drive, for example \TARGET.20. 

Then select the Destination directory option from the Project menu. It will 
ask you to choose the top level GEOS directory that will hold the modified 
executables. In this case, you would choose the Path button, move to the C:\ 
directory, and choose \TARGET.20. You will need to do this each time restart 
the Resource Editor, since the destination path is not saved in your .INI file.

You need not have a full GEOS installation in the target directory. However, 
when new executables are created, they are placed into the same 
subdirectory as the original geode. For example, if you were to translate 
GeoWrite which is in the WORLD directory, and you had the destination 
directory set to TARGET20, the directory TARGET20\WORLD must exist 
when you try to create the new executable. If it doesn't you will get an error 
message saying that the target could not be created.

This new geode will have the identical English language long name as the 
original geode (unless you have changed the name in the File Menu's New 
Name and User Notes dialog) and will therefore overwrite the English file. 
However, you may wish to rename several of the geodes, especially those in 
the WORLD directory and the Screen Savers, to reflect local language names. 
In this case, the new geode will not overwrite the original one, and you will 
have to go back and delete the old one to avoid duplicates. 

### 8.7 Updating an Executable

Even after all the translations are complete, there may be a need to replace 
a certain executable with a newer version containing a bug fix or a feature 
enhancement. You will be able to do this quickly and effectively by using the 
Update feature in the File menu.

To have this feature work, you must first put the updated geode and .vm file 
in the proper directory, overwriting the original files. Then, by clicking 
Update Translation file (in the Update menu), the existing translation file 
will be compared with the new strings in the geode, showing the new or 
changed chunks, as well as the ones left unchanged. The deleted chunks will 
be grouped in a separate resource named "Deleted chunks" at the end of the 
resource list. You will then be able to make the necessary modifications to 
this file to bring it up to date with the newest version of the geode.

After updating the translation file, you can then create an updated local 
language executable as out lined above. 

If it is clear that there have been no changes to the geode affecting editable 
chunks (as when code changes for a bug fix), it is also possible to simply 
rebuild the new geode from the existing translation file using the Create A 
New Executable feature in the File menu. 

After viewing the updated translation file and making any necessary 
changes, you can remove the updating information from the translation file 
by clicking on the Commit the Update trigger in the File/Update menu. This 
will remove information which marks the chunks as "new" or "changed" and 
will delete the Deleted Chunks resource.

### 8.8 Testing Your New Executables

You may find that you would like to be able to test your translations as soon 
as you make them. At any point during a translation, you can create an 
executable.

Simply exit the LOCALIZE.20 directory, move to your destination directory 
(for example \TARGET.20) restart that installation of Ensemble 2.0 and test 
your new geode.

If your product will run under several video drivers (e.g. if it runs on desktop 
PCs), we suggest that you take a look at the localized UI under the CGA video 
driver to make sure that everything fits. You should also observe it under the 
EGA video mode with a large UI font size.

[Icon Editor](ticoned.md) <-- &nbsp;&nbsp; [Table of Contents](../tools.md) &nbsp;&nbsp; --> [The INI file](tini.md)