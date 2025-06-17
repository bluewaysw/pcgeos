## 7 Icon Editor

The Icon Editor tool allows you to create icons for your application, both file 
icons used by file manager applications and simple tool monikers which you 
may use to provide graphic monikers for a geode's UI gadgetry.

### 7.1 Creating Icons

The icons produced by the icon editor are stored in an "icon database" so that 
they can be viewed and retrieved easily. The icon database is the Icon Editor's 
"document", so New/Open, Close, Save As, Make Backup and other 
Document-control commands will operate on the current database. "Save" 
actually saves the currently edited icon into the current icon database, and 
saves the database as well. 

There are 3 standard kinds of icons in use in the system. Each standard type 
of icon has 3 default formats: One for VGA screens, one for MCGA 
(monochrome VGA) screens, and one for CGA screens.

Most icons are used in one of the following ways:

+ File Icons, which are used by GeoManager to display and launch 
applications. The sizes are 48x30, 48x30 (monochrome), 48x14, 32x20, 
and 32x20(monochrome).  
*Note*: The icon editor does not automatically create the 32x20 icon 
formats. You will need to do this yourself, using the Add Format dialog 
available under the Format menu.

+ Tool Icons, which are used by controllers in their toolbox UI. The format 
sizes are 15x15 and 15x10.

+ Mouse Pointers, which are used to provide a cursor tracking the mouse's 
movement. This format has one standard size:16 x 16.

You may also create custom icons, which start with 1 default format. Custom 
icons are limited to 1024 pixels wide or tall, and the formats cannot be larger 
than 64k. 

The first time the icon editor is started it will create a blank file icon named 
"untitled." After that, if there is an icon database available to the icon editor, 
the icon editor will start with the last icon that was being edited before the 
editor was shut down. 

To create a new icon, choose "Create New Icon" from the Icon menu. The 
dialog will present 4 options for the type of icon. If you decide to create a 
custom icon, you should enter the height, width and color scheme for the icon 
in the provided fields. 

### 7.2 Importing Icons

There are 2 other ways to create icons. You can import a graphic such as a 
GIF, TIF, BMP or other supported file format for use as an icon, provided that 
it is less than 64k (which is the limit for GEOS monikers). You do this using 
the "Import Graphic" dialog in the Icon menu. 

The other way to make an icon in the icon database is to import a moniker or 
moniker group from the token database, which is the cache of file monikers 
kept by GeoManager. Select "Token Database" from the Icon menu to get a 
list of monikers that you may import. 

### 7.3 Editing Icons

There are a number of features that are useful when editing icons:

+ You can create a format for the icon, and scale it to help create the other 
formats, using the "Transform Format" dialog under the Format menu. 

+ The pixel-edit size can be set using the Options menu. It defaults to 
8-bit-wide pixels. 

+ The "Preview" dialog allows you to view a format in a generic object. If 
the format is intended for use in a generic object, you can see what it 
looks like inverted, and (in the case of triggers and tools) what it looks 
like with different background colors. 

+ You can add your own formats, or delete existing ones, using commands 
from the Format menu. You might, for example, want to add a SuperVGA 
format for the icon (system supervga file-icons are 64x40). 

+ 256-color icons are technically supported, but no special tools are 
provided for editing them. You can select the red, green, and blue 
components of the area or line color from the "Area Color" and "Line 
Color" dialogs. 256-color icons aren't much use unless either:

    They use colors only from the system's default palette, or

    They are being used in a 24-bit color environment. 

+ You can select the aspect ratio for your icon. This will allow the system to 
make the best choice among formats when selecting from your moniker 
list. The choices are CGA, EGA, and VGA. The "VGA" aspect ratio should 
be used for VGA, MCGA (monochrome VGA), and SVGA formats. 

+ You are not required to create multiple formats for your artwork; 
however we recommend that if you are creating art that could be used 
under many video modes that you create the three standard formats for 
the art (VGA, mono VGA, CGA). This shouldn't be too difficult, since 
there are several tools for working with several formats:

    The "transform format" dialog can be used to create exact 
copies, or transformed copies, of one format to another.

    The "resize format" dialog changes the size and shape of a 
single format.

### 7.4 Writing Source Code

When the icon is finished, make sure it's saved (File->Save), and then choose 
"Write Source Code" from the Icon Menu. Follow these steps to get source 
code:

**1** Enter a DOS 8.3 filename for the source file 

**2** To write only the current format, leave the "Formats" group at "Current 
Format"

**3** To write source for all the formats, choose "All Formats"

**4** Select GOC source (assembler is used in-house) 

A dialog should appear when the source code has been written, saying 
"Source Code Written Successfully". If a problem is encountered in creating 
or writing a file, check the permissions on your document directory, and make 
sure you have enough disk space for the text file (only a few hundred bytes 
should be necessary). 

The file should appear in your document directory. It's a text file with GOC 
moniker source code. This source code can be included in your application 
after you make the following changes: 

+ The formats for the icon will have names like "Moniker0". You should 
give them appropriate names.

+ The monikers must be placed in a resource. You could place them 
between statements like:

    `@start APPMONIKERRESOURCE, data`;

    `@end APPMONIKERRESOURCE;`

    In your .gp file, this resource should have the attributes "lmem, 
read-only, shared".

+ You may wish to add the line "style = tool;" for icons that are going to be 
used as toolbox UI, to assist the specific UI in deciding how to draw them.

+ Your .goc file must `#include <gstring.h>`, an include file in which the 
graphics string data structures used to describe visual monikers are 
described. (Esp programs include **gstring.def**.)

### 7.5 Icon Databases

The icon editor can work with more than one icon database at a time via the 
Multiple Document Interface standard. Each database has its own window, 
each window having four views. The leftmost view is the database. The 
top-right view is the "Pixel View", the main editing area. The two remaining 
views are next to each other in the lower-right portion of the window. The left 
view is the actual-size view of the icon, and is editable. The right window is 
the format list, showing all formats of the icon currently being edited.

Double-clicking an icon in the database viewer will select it for editing. The 
currently-edited icon is important in the following ways: 

+ It is (of course) the only icon being edited in the database associated with 
that window. 

+ Its size determines the shapes of the various views, which will try to 
adjust themselves to fit in the window as best they can.

+ It is the icon that appears in the "Preview" dialog. 

+ It is the icon used in the "Export to Token database" dialog (explained 
below).

+ It is the target of all operations in the Icon and Format menus (except 
"create new icon").

The database viewer supports all clipboard operations except for Undo. Icons 
may be selected and moved or copied between databases. This can be done via 
the Edit menu or quick-transfer. 

The format list is used to switch editing to a different format in the same icon. 
This can only be done with the mouse. 

To get more room for editing, use the Options menu to temporarily hide the 
database viewer or format list while editing. 

### 7.6 Exporting to Database

This is the function that most people associate with an icon editor. the token 
database is a cache of moniker lists used by GeoManager and other 
applications. The token database exists so that every time an application's 
moniker is needed, it is not necessary to start the application in engine mode 
to request the moniker (a slow process). 

The icon editor can change entries in the token database. You cannot change 
the "built in" moniker for a geode using the icon editor. If you make changes 
to the token database and then delete the database, then when it gets rebuilt 
your monikers will no longer be there. 

Given that, it's still likely that people will want to set their own monikers in 
the token database; the icon editor has this ability. 

To change an entry:

+ Make sure you are editing the icon you wish to change.

+ Open the File->Export to Token Database dialog.

+ One of the icon's formats should be visible under the "Change To:" text in 
the dialog. If not, then you are probably editing the wrong icon, or 
perhaps the icon hasn't been saved into the database.

+ Use the file selector to find the application, document, library, or other 
driver whose token database entry you wish to change. Otherwise, enter 
the four token characters for the geode into the Token Characters text 
field. Select the corresponding operation from the list at the lower-right 
of the dialog ("Use File Selector" or "Use Token Chars.")

+ The current token-db entry for the selected geode should appear under 
the "Current Icon" title at the upper-right corner of the dialog. 

+ When you are satisfied with the edited icon, change the moniker with the 
"Change" trigger in the dialog's reply bar. The change will not take effect 
in GeoManager until you select Disk->Rescan Drives in GeoManager.

+ If you wish to revert a token-database entry to the original, built-in 
moniker for the geode, select the geode in the file selector and use the 
"Remove" trigger in the reply bar.

[Debug Utility](tdebug.md) <-- &nbsp;&nbsp; [Table of Contents](../tools.md) &nbsp;&nbsp; --> [Resource Editor](tresed.md)