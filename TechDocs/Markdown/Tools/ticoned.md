# 7 Icon Editor

The Icon Editor allows you to create icons and graphics for your application, including both file icons used by file manager applications and graphical monikers that can be used for Geode UI objects. In addition, the images can be saved as GString or bitmap code, allowing them to be displayed directly on the screen using the appropriate graphics commands.

Furthermore, images created with the Icon Editor can be exported via the clipboard or saved to a graphics file. This allows you to create graphics for any purpose.

The Icon Editor is designed to be easy to use even for non-programmers. This also applies to large parts of this documentation.

The "documents" of the Icon Editor are referred to as "*Icon Database*." The icons in the database are organized into so-called **"Sets"**. Each set contains one or more icons that are used for different screen formats. Every icon has some **Attributes** that describe its intended screen format.

Note the difference between the "Icon Database" - the Icon Editor's document - and the "Token Database," the system's central token database.

### Basic Operation

The Icon Editor can work with multiple icon databases (documents) at the same time. Each database has its own window, and each window contains four views. The view on the far left is the "*Database Viewer*." All icon sets in the document are displayed there. A simple mouse click selects a set for editing. It is then outlined in red. Icon sets can also be "selected" independently of this. You can select multiple sets by dragging a "selection frame" (drag while holding down the left mouse button) or by clicking on a set with the left mouse button while holding down the Ctrl key. The selected sets can be copied together to the clipboard via the "Edit" menu and thus exchanged between different icon databases.

The view in the upper right is the "*Pixel View*." This is where the current icon is displayed and edited. The other two views are located side by side in the lower right area of the window. On the left is the "*Live Preview*," which displays the current icon at its original size in its currently edited state. To the right of it is the "*Icon List*," which displays all icons in the current set. Click an icon to select it for editing.


The Icon Editor can work with two different formats in the clipboard: icon images and icon sets. The "Edit" menu therefore contains two sections, one for images (keyboard shortcuts Ctrl-C and Ctrl-V) and one for icon sets (keyboard shortcuts Ctrl-T and Ctrl-K).

In the "Options" menu, you can customize the Icon Editor's user interface and save these settings in the GEOS.INI file.

 
## 7.1 Creating Icons

### 7.1.1 Basics

The icons in the database are organized into so-called **"sets"**. Each set contains one or more icons used for different screen formats. The icons themselves have a set of attributes that describe their intended use:
- The **Style** describes the basic use. The available styles are **Icon** (for general use) and **Tool** (typically in toolbars).
- The **Display Size** describes the screen size. Available values are **Tiny**, **Standard**, and **Large**. Although another size is defined in the header file ```win.h``` (Huge), it is not currently used by the system and is therefore not offered by the Icon Editor.
- There are two values for the **Aspect Ratio**: **Normal** (VGA) and **Very Squished** (CGA).
- The **DispayClass** describes the color depth required by a screen to display the icon correctly. If the bitmap uses a palette, even a 16-color bitmap may require 256 colors or more. Available values are **Monochrome**, **16 colors** (standard palette), **256 colors** (standard palette), and **True Color**.

An icon set for display in the file manager should include at least the following 4 icons. The tool icons are used for the express menu.
- 48x30 Standard, Icon, 16 standard colors
- 48x30 Standard, Icon, monochrome
- 15x15 Tiny (or Standard), Tool, 16 standard colors
- 15x15 Tiny (or Standard), Tool, monochrome

The following icons are required for CGA screens:
- 48x14 Standard, Icon, monochrome
- 15x10 Standard, Tool, monochrome

Additionally, you can create icons for screens with 256 colors or more.
- 48x30 Standard, Icon, 256 or more colors
- 15x15 Tiny or Standard, Tool, 256 or more colors

If you create icons for purposes other than use in the file manager or on a toolbar, you are not restricted to the specified standard sizes. However, icons intended for use in program code must be smaller than 8 kB because they are stored in resources. It does not matter whether the source code is written as a visMoniker, a bitmap, or a GString for display on the screen using graphics commands. Images intended for use elsewhere can be much larger. The maximum dimensions for images are 1024x1024 pixels.

There is a difference between the color depth of the icon's bitmap and the color depth of the screen (the DisplayClass). Below is a list of the icons that are suitable for a particular DisplayClass.
If GEOS cannot find an icon for the current DisplayClass, it selects 
the closest matching icon. In particular, an 16 color icon with custom 
(non-standard) palette is used for 256-colorDisplayClass if available and 
no other colored 256-color-DisplayClass icon is available.

- DisplayClass: Monochrome
	- Monochrome icons only
- DisplayClass: 16 colors (standard palette)
	- 16 color icons without palette (uses standard palette)
	- All monochrome icons
- DisplayClass: 256 colors (standard palette)
	- 16 color icons width a subset of the 256 color standard palette
	- 256 color icons without palette (uses standard palette)
	- All icons suitable for 16-color DispayClass
- DisplayClass: true color
	- All icons, in particular  16 color icons with a custom (non-standard) palette and 256 color icons with a custom (non-standard) palette


### 7.1.2 Creating a New Icon Set

There are several ways to create a new icon set.
1. Create a new, empty icon set using the "Icon Set" menu.
2. Duplicate an existing set (using the "Icon Set" menu).
3. Paste one or more sets from the clipboard (via the "Edit" menu). These sets must first have been copied from another icon database to the clipboard.
4. Paste an image from the clipboard (via the "Edit" menu). There, you have several options, including the possibility to create a new icon set.
5. Paste a graphic via the "File" menu - "Import Graphic." Here, too, you have the option to create a new icon set.
6. Import a token via the "File" menu - "Import from Token Database."

When you create a new, empty icon set using the "Icon Set" menu, do the following
- Select one of the available templates, such as "Tool Icons." The different templates differ only in the icons they provide, which are initially added to the set. You can add more icons, change their properties, or delete icons later.
- Select the icons you want your set to contain initially. For custom icons, you can also specify the size, attributes, and bitmap colors.
- If the set can contain multiple icons initially, you must specify a prefix for the icon names. The icon name generated by the program will then consist of the prefix and the icon's properties.
- Click on "Create New Set."

You can change any settings you configure here at a later time.


**Mouse pointer sets** are a special case. They can contain only mouse pointers, and mouse pointers always have a fixed size of 16x16 pixels. Although additional sizes are defined in the header file ```graphics.h```, these are not currently supported by the system and are therefore not offered by the Icon Editor.

### 7.1.3 Creating a New Icon

There are many ways to create a new icon.
1. Create a new, blank icon using the "Icon" menu.
2. Duplicate an existing icon (using the "Icon" menu).
3. Paste an image from the clipboard (via the "Edit" menu). There, you have several options, including the ability to create a new icon in the current set.
4. Import an image via the "File" menu - "Import Graphic". Here, too, you have the option to create a new icon in the current set.

When creating a new, empty icon using the "Icon" menu, you should do the following:
- Select the size, attributes, and color depth of the bitmap. If the color depth is 16 or 256 colors, the default palette is used.
- Enter a name for the icon. The name should describe the icon's purpose and will be used later in the program to identify the icon.
- Click "Add Icon".

Below the name input field, you'll find a list of the standard icons used in GEOS. Here, you can set the icon's size, attributes, and color depth with a single click.

Tip: If you want the bitmap to contain colors other than the standard ones later on, select "True Color" initially.

### 7.1.4 Importing Icons

#### Import from a graphics file (via the "File" menu) or from the clipboard (via the "Edit" menu).

When importing from the clipboard, both bitmaps and GStrings (Graphic Strings, e.g., GeoDraw drawings) can be imported. GStrings must first be converted to a bitmap. A dialog box will open where you must select the color depth for this bitmap. If in doubt, choose a higher color depth; you can always reduce it later. The "Add one Extra Pixel for Savety" option adds a border, since GStrings occasionally extend beyond their own boundaries. If necessary, you can crop the image later.

Then the actual import dialog box appears, which offers a wide range of options.
- **Crop Image** (in the Reply Bar): A dialog box opens where you can select a portion of the image. Only this selected portion will be imported. You can repeat this step multiple times before importing (e.g., first roughly, then precisely).
- **Create new Icon**. During import, a new icon is created in the current set. You should first configure the properties of the new icon. A suitable name is generated during this process. You can still change this name before importing, if you wish. The size of the new icon corresponds to the size of the imported graphic
- **Create a new Icon Set**. The new icon is not created in the current set, but in a new, empty set.
- **Draw to Current Icon**. **This is the most powerful option.** The imported graphic is drawn into the current icon (which, by the way, may also be empty). The options "*Relative to Selected area*" and "*Limited to Selected Area*" are only active if an area in the current icon has been selected beforehand using the selection tool.
  + Select the ***Draw Position***. For example, "*Bottom right*" means that the bottom-right corner of the imported graphic will be drawn in the bottom-right corner of the current icon. If the graphic is larger than the icon, it will be cropped.
  + ***Relative to Selected Area***. The drawing position is not relative to the icon, but to the area selected with the selection tool.
  + ***Limited to Selected Area***. This crops the imported graphic after positioning so that only the selected area is overwritten.

#### Importing from Token Database

The Token Database file is the central location where GEOS stores file icons (more precisely: icon sets). Only icons that are in the Token Database can be displayed by the File Manager. The icon sets are referenced via a **Token**. This is a combination of 4 letters (*Token Chars*) and a 16-bit number (*Token-ID*).

In the dialog for importing a token from the Token Database, a representative icon and the corresponding Token-ID are displayed for all tokens present in the Token Database. Even tokens that have only text and no graphical moniker are displayed here.
The tokens are sorted by their ID. In the bottom area of the dialog, you can specify the range of IDs to be displayed.

To import a token, follow these steps:
- Click on the token. Information about this token and all icons associated with it will be displayed below the list.
- To view the dimensions and color depth of an icon, click on it.
- Click "Import Token." A new icon set will be created that contains all of the token's icons. Any text monikers that exist will also be imported and can be viewed and edited as needed via the "Icon Set" menu. When re-exporting to the token database, the text monikers will also be exported.
- Tokens that do not have graphical monikers cannot be imported.

## 7.2 Editing Icons

### 7.2.1 Basic Functions

To edit an icon, there are two essential elements in the program: the toolbar with the bitmap tools and the "Icon" menu. You can also customize the appearance of the user interface via the "Options" menu. Of particular importance here are the pixel size in Pixel View and the background color in Pixel View. Both can also be accessed directly via keyboard shortcuts.

The dialog boxes for setting colors can be found in the "Graphics" menu. For icons that have a palette, the correct palette is displayed here, not the system colors. Note that, for this reason, each icon saves its own current colors. This means that when you switch icons, the current line and area colors usually change as well.

#### The Bitmap Tools

The following bitmap tools are available:
+ **Selection Tool**: You can select an area in the bitmap (using the left mouse button), move this area with the right mouse button, or copy it to the clipboard. You can also access the image cropping dialog directly from here.
+ **Pencil Tool**: Set individual pixels to the current area color.
+ **Eraser Tool**: Erase individual pixels. These pixels then become transparent.
+ **Line Tool**: Draw straight lines. You can specify the line thickness and style.
+ **Filled Rectangle**: Draw a rectangle filled with the area color.
+ **Rectangle Tool**: Draw an (empty) rectangle in the current line color. You can specify the line thickness and line style.
+ **Filled Ellipse**: Draw an ellipse filled with the area color.
+ **Ellipse**: Draw an (empty) ellipse in the current line color. You can specify the line thickness and line style.
+ **Flood Fill**: Fill contiguous areas with the current area color. This tool can also be applied to transparent areas.
+ **Fill Transparent**: Make contiguous areas transparent.
+ **Edit Mask**: Edit the mask layer directly by making individual pixels transparent or opaque.
+ **Pick Color**: Select a color directly from the image to use it as a line or area color.

Hold down the Shift key to draw squares, circles, or diagonal lines.

You can also access all bitmap tools via the "Graphics" - "Bitmap Tools" menu, if, for example, you have hidden the toolbar.

Also for monochrome icons, the Icon Editor makes a difference between white and transparent. You should only use white, non-transparent pixels in *monochrome* icons when it is **absolutely necessary**.

#### The "Icon" Menu
The "Icon" menu gives you access to functions that are not drawing operations in the traditional sense.
+ **Transform Icon**: Rotate and flip the image.
+ **Crop Icon**: The cropped image can be used to replace the current icon, saved as a new icon in the current set, or saved as the first icon in a new set.
+ **Shift Image**: The image content can be moved one or more pixels to the left, right, up, or down.
+ Change **Colors and Size**: This is described in detail in the next chapter.


### 7.2.2 Changing Colors and Size

In this dialog box, you can create a new icon in the current set. The concept here is to copy the icon and change the size and/or color depth of the bitmap.

GEOS icons are usually not true-color images. Therefore, scaling and color reduction can be a challenge. The most significant problems are:
1. Scaling can result in "intermediate colors" that do not appear in the original image.
2. When scaling the mask, a pixel that is actually colored may become transparent, and vice versa.
3. During color reduction, colors must be replaced with other colors that are as similar as possible. Whether and how well these are available depends on the specific situation.

The Icon Editor solves these problems as follows:
+ There are two scaling methods:
    1. *Sampling*. This is the "system" method. It copies the nearest pixel.
    2. *Bilinear/Area Resampling*. This method generates a true-color intermediate image and then reduces its color depth.
+ There are two methods of color reduction: replacement with the nearest color value and Floyd-Steinberg dithering.
+ For images reduced to 16 or 256 colors, a palette optimized for the image (i.e., non-standard) can be generated and used.

The result is highly dependent on the specific icon image. In general, the scaled or color-reduced image will still need to be manually edited.

The typical procedure in this dialog box is:
- Take time to make your selection. Try out several options. This time is well spent.
- Select the **New Color** for the new icon. "**16 colors**" and "**256 colors**" mean that the image does not have its own palette; instead, the standard palette is used. "**16 colors, palette**" and "**256 colors, palette**" cause the Icon Editor to generate a customized palette, which is then used.
- Select the desired **New Size** for the new icon. The "standard sizes" can be selected directly. If necessary, you can still change the values.
- Choose whether the **original image** should be **scaled** or not. Depending on the scaling method selected, the image may be partially cropped. Selecting "*Independently*" scales the image in both dimensions. This may change the aspect ratio.
- Select the **position** in the new icon where the (scaled) original image should be placed. The available options depend on the settings you just selected. Unnecessary or meaningless options are not displayed.
- Select the name and attributes for the new icon.
- Options
  + **Create Preview Images Automatically** immediately creates new preview images whenever the settings are changed. This is useful on fast systems.
  + **Add Opaque Preview Images**: The mask issue mentioned above (Issue #2) can lead to the loss of potentially important pixels. This option causes an additional preview image to be generated for each preview image, in which the mask is present but set to "completely opaque."
- Click "**Create Preview Images**." Depending on the settings above, the Icon Editor will now create up to 8 new images. These differ based on how they were generated.
- Click on one of the preview images to see which methods were used to create it. The file size is also displayed.
- Select the image you like best. If in doubt, choose the image with the smaller file size. Then click "**Create New Icon**".

Tips:
1. You can select multiple preview images one after another and create an icon from each one. You can then make your final decision later.
2. It's often worth comparing several versions, such as 16 colors with a palette and 256 colors without a palette. Create an icon for each version and then compare the details in Pixel View.


### 7.2.3 Icon Preview

Before you write the icons as source code or export them to the token database, you should check how they look in different environments. To do this, select "Preview Icon" from the "Icon" menu.
- Use **Object Type** to select the UI object for which the VisMoniker is to be used.
- **Preview for DispayClass** allows you to preview the icon for DispayClasses with lower color depth. Internally, a bitmap with the selected color depth is created, and the icon is drawn into it. The icon set should contain at least one icon that looks good on black-and-white screens and one that looks good on 16-color screens.
     - The DispayClass stored in the icon is shown on the right, below the colors.
- **Unselected Colors** and **selected Colors** only apply to objects that can be "selected." Otherwise, they are disabled. Here you can see what the monikers look like if the user has set different UI colors for their interface than you have. The programmer can also explicitly define these colors in their UI code.
- The **Allow Mixed Colors** option supports the use of the ```HINT_GADGET_BACKGROUND_COLORS``` hint by the programmer. The hint specifies two "selected" and two "unselected" colors. The system then "mixes" both colors. This is particularly useful for 16-color environments.
- The Icon Editor supports only 16 colors for the color preview, but the UI and the ```HINT_GADGET_BACKGROUND_COLORS``` hint can use all 256 standard colors.

You can leave the preview dialog box open while making changes to the icon. The changes will be displayed when you click "Update" or press F4.

## 7.3 Write Source Code

Once the icons are finished, you can select "Write Source Code" from the "Icon Set" menu. Before doing so, make sure that all icon names match how they should be named in the program. This saves a lot of work for the programmer.

## 7.3.1 Writing the Code

On the left, you'll see a list of the icons to be written. If any icons are marked in the list, there is a conflict. You'll find a description of the conflict in the text box below. For resolvable conflicts, the text box is yellow, and the code can be written. A red text field indicates that the problem cannot be resolved, e.g., because one of the icons is too large. The code then cannot be written. You should *always* try to avoid conflicts.

1. Select how the icons should be written. This decision must be made by the programmer whose program will use the icons.

You have the following options:
- Write only the current icon or all icons from the set
- The **Header** determines the data format to be used.
	+ **VisMoniker**: A visMoniker structure is written. VisMonikers are used as file icons or as graphical labels for UI objects. This is the main function of the Icon Editor.
    + **GString Chunk**: GStrings are graphics that can be drawn using the GEOS routine GrDrawGString(). The icon-specific attributes (such as style, DispayClass, etc.) are not used.
    + **Bitmap Chunk**: Only the raw bitmap data is written to a chunk. Here, too, the icon attributes are not used. To draw the image, the GrDrawBitmap() routine is used.
	+ **PointerDef**: This is the special format in which mouse pointer chunks are written.
	+  Note for non-programmers: A **chunk** is a small area of memory within a memory block. GEOS store various things in it; for example, each icon is stored in a single chunk. Chunks are addressed in the program by their name. The Icon Editor uses the icon's name as the name for the chunk.

- **Language** refers to the programming language
	+ **GOC Source**: The GOC code must be written to a .goc or .goh file.
    + **UI Source**: Assembler code is written, which must be saved in a .ui file.
- **Compress Icons**: Icons are normally stored in a compressed format. In very rare cases, an uncompressed icon may require less memory than a compressed one. Therefore, "Minimize Size" is generally the best choice. The Icon Editor checks which variant requires less memory. However, uncompressed images are displayed slightly faster. This can be important for animations.
- All icons created with the Icon Editor have a **transparency mask**. It is possible to remove them while writing the source code, but in most cases this is not useful.

2. Choose an appropriate **File Name** in **DOS 8.3** format and the path to the file. The Icon Editor saves the path in GEOS.INI so that it is immediately available the next time you open this dialog box.

3. Click "**Write Code**". The Icon Editor creates the file in the specified folder. Usually, the programmer must then move the individual icons into the appropriate files in their project.

### 7.3.2 Using VisMonikers, Bitmaps and GStrings in your Program

This section is intended for programmers who have little experience with this topic.

#### Including File Icons in your Program

The following code snippets from the Icon Editor code demonstrate how to do this.
+ The VisMoniker, bitmap, and GString chunks generated by the Icon Editor must be placed in a data resource. The moniker list is required to install the document token.
```
@start AppMonikerResource, data;

@visMoniker AppVGAMoniker = { … };
@visMoniker AppVGAMonoMoniker = { … };
….
@visMoniker DocVGAMoniker = { … };
@visMoniker DocVGAMonoMoniker = { … };
….

@visMoniker IconDocMonikerList = list { @DocVGAMoniker, @DocVGAMonoMoniker, ... };

@end AppMonikerResource;
```
In your .gp file, this resource should have the attributes “lmem, read-only, shared.”

```
resource	AppMonikerResource	lmem read-only shared
```
+ Your .goc file must contain `#include <gstring.h>`. This file defines the graphics string data structures used to display visual monikers.
+ Esp programs include ```gstring.def``` instead. The VisMonikers, bitmap chunks, and GString chunks written by the Icon Editor must be located within resources in a .ui file. The syntax for an .asm file is different.

#### *Installing the Application Token*

+ The token (Token-Chars and Token-ID) is declared in the .gp file.
```
tokenchars  “ICON”
tokenid     0
```
+ The application object must have a list of all program icons as VisMonikers.
```
@object IconApplicationClass IconApp = {
    GI_visMoniker = list { @AppVGAMoniker, …  @IconTextMoniker };
    …
    }
```
+ The default handler for **MSG_GEN_PROCESS_INSTALL_TOKEN** then installs this token in the token database.

#### *Installing a Document Token*
+ For each additional token to be installed in the token database, you need a moniker list.
+ Overwrite the MSG_GEN_PROCESS_INSTALL_TOKEN method in your process class. Since the document moniker list is located in the same resource as the monikers, relocation is not required.
```
@method IconProcessClass, MSG_GEN_PROCESS_INSTALL_TOKEN {
GeodeToken docToken = { “IDOC”, 0 };
dword    tokenDW;

    @callsuper();        /* installs the app token */

    memcpy(&tokenDW, &docToken.GT_chars[0], 4);
    TokenDefineToken( tokenDW, docToken.GT_manufID,  @IconDocMonikerList,0);
}
```


#### Using Bitmaps and GStrings

The bitmap and GString chunks written by the Icon Editor must also be placed in a data resource (see above).

To draw a bitmap from a bitmap chunk into a GState (e.g., the screen), use the GrDrawBitmap() command. For monochrome bitmaps without a mask, the GrFillBitmap() command may sometimes be useful as well.
```
void DemoDrawBitmap(GStateHandle gstate, int x, int y, optr bmpOp) {
Bitmap 	*bPtr;

    MemLock(OptrToHandle(bmpOp));
    bPtr = LMemDeref(bmpOp);
    GrDrawBitmap(gstate, x, y, bPtr, 0);
    MemUnlock(OptrToHandle(bmpOp));
}
```
Typically, monochrome icons contain only black and transparent pixels. However, the Icon Editor can also create white, non-transparent pixels. You should only use these, though, when it is truly necessary. When writing monochrome icons as source code, the GrFillBitmap command is used instead of GrDrawBitmap whenever possible. This requires significantly less memory. However, GrFillBitmap cannot be used if
- the image contains white, non-transparent pixels.
- the image is written as a bitmap chunk.


To draw a GString from a GString chunk, use the GrDrawGString() statement.
```
void DemoDrawGString(GStateHandle gstate, int x, int y, optr gsOp) {
byte 	*bPtr;
Handle	monikerGString;
word	lElem;	

    MemLock(OptrToHandle(gsOp));
    bPtr = LMemDeref(gsOp);

    monikerGString = GrLoadGString(PtrToSegment(bPtr), GST_PTR, PtrToOffset(bPtr));
    GrDrawGString(gstate, monikerGString, x, y, 0, &lElem);
    GrDestroyGString(monikerGString, NULL, GSKT_LEAVE_DATA);

    MemUnlock(OptrToHandle(gsOp));
}
```



## 7.4 Exporting to the Token Database

The Token Database file is the central location where GEOS stores file icons (more precisely: icon sets). Only icons that are in the Token Database can be displayed by the file manager. The icon sets are referenced via a **Token**. This is a combination of 4 letters (*Token Chars*) and a 16-bit number (*Token ID*).

The standard procedure is for the icons created by the Icon Editor to be written into the program as VisMoniker source code. The PC/GEOS program then installs the icons into the Token Database automatically. However, there are also a few reasons why icon sets should be written directly into the token database. Some of the most common reasons include:
- You want to assign a different icon to a program for your own use. In this case, the token remains the same, but the images are changed.
- You want to make a new icon available for a folder or a DOS association.
- You want to modify an existing token, for example, by adding a tool icon to the Express Menu. In this case, you should consider whether the following method is not better:
	- Add the new icon to the program's source code.
    - Recompile the program.
    - Delete the old token from the Token Database, e.g., using the Icon Editor's TokenDeleter.
    - Open the program in the File Manager. The program will then automatically install the new token.
- You want to create an icon for an **R-BASIC** program. **R-BASIC** cannot generate icons on its own. When creating the program launcher, it copies the icons from the token database into the launcher.

**Important!** If you make changes to the token database and then delete it, your monikers will no longer be available when the database is rebuilt.


After opening the "**Export to Token Database**" dialog via the "File" menu, you have the following options:
+ On the left, you'll see the list of icons to be exported. If any icons are marked in the list, there is a conflict. A description of this can be found in the text field below.
   - The icon names are ignored. They are only needed when writing source code.
   - If conflicts can be resolved, the text field is yellow, and the set can be exported.  You should *always* try to avoid conflicts.
   - A red text field indicates that the problem cannot be resolved, e.g., because one of the icons is too large. The export to the token database will then be rejected.
   - The most common problem is that multiple icons have the same combination of screen size, DispayClass, icon style, and aspect ratio. Since GEOS searches specifically for this combination, one or more icons would never be found anymore.
+ **Compress Icons**: Normally, icons are exported to the token database in a compressed format. In very rare cases, an uncompressed icon may require less memory than a compressed one. Therefore, "Minimize Size" is generally the best choice. The Icon Editor checks which variant requires less memory.
+ All icons created with the Icon Editor have a **transparency mask**. It is possible to remove it when exporting to the token database, but in most cases this is not useful.
+ Specify a **Token** (Token Chars and ID). At the top, you'll see a representative icon for the token currently stored in the token database as well as for the new token. You can
   - Enter the token manually.
   - Select a Geode (an application, a document, a library, or a driver) from the GEOS system whose entry in the token database you want to change.
+ If you are satisfied with everything, change the token entry using the "**Export/Replace Token**" button. The token will be added or, if it was already in the token database, replaced. The change will not take effect in GeoManager until you refresh the displayed folder.
+ The Icon Editor remembers the token used for the icon set during export. This simplifies the export process if you make further changes to the icons later.


## 7.5 Additional Features

The Icon Editor has many other capabilities that, with one exception, will not be explained in detail here. The most important ones include:
- Deleting tokens from the token database (Token Deleter)
- Sorting icons within a set
- Sorting icon sets in the icon database (the Icon Editor document)
- Moving icons to a different set
- Animation preview when icons in a set are to be used as frames in an animation.

#### How to Program an Animation (General Procedure):
- Create an icon set in which the icons represent the individual frames of the animation.
- Save the set as bitmap chunks (recommended) or as GString chunks. If the frames do not require transparency, disable the associated option.

*If the animation frames do not require transparency:*
- Create a gstate for an object that is visible on the screen. This is often a VisContent.
- Program the VIS_DRAW handler for this object so that it always draws the current frame. Otherwise, artifacts may occur if the animation object is briefly obscured by other objects, such as dialog boxes.
- Start a timer whose handler does the following:
    - Check whether the animation is still running, e.g., whether the gstate still exists
    - Draw the current frame to the screen, i.e., into the gstate created above.
	- Select the next frame.
- To stop the animation:
    - Stop the timer
    - Destroy the gstate and set it to zero. The timer handler can then detect that the animation is no longer running.
- Ensure that the animation is stopped in your MSG_GEN_PROCESS_CLOSE_APPLICATION handler if it is still running.

*If the animation frames are transparent:*
- Create an unmasked bitmap (shadow bitmap) large enough to hold the individual frames (size, color depth). Create a gstate on it.
- Clear the shadow bitmap with the desired background color.
- Draw the first frame into the bitmap.
- Create a gstate (screen gstate) for an object that is visible on the screen. This is often a VisContent.
- Program this object's VIS_DRAW handler so that it always draws the shadow bitmap. Otherwise, artifacts may occur if the animation object is briefly obscured by other objects, such as dialog boxes.
- Start a timer whose handler does the following:
    - Check whether the animation is still running, e.g., whether the screen gstate still exists
	- Draw the *shadow bitmap* to the screen, i.e., into the screen gstate.
    - Select the next frame.
    - Clear the shadow bitmap using the desired background color.
    - Draw the new frame into the shadow bitmap.
- To stop the animation
    - Stop the timer.
	- Destroy the screen gstate and set it to zero. The timer handler can then detect that the animation is no longer running.
    - Destroy the shadow bitmap and its associated gstate.
- Ensure that the animation is stopped in your MSG_GEN_PROCESS_CLOSE_APPLICATION handler if it is still running.


[Debug Utility](tdebug.md) <-- &nbsp;&nbsp; [Table of Contents](../tools.md) &nbsp;&nbsp; --> [Resource Editor](tresed.md)


