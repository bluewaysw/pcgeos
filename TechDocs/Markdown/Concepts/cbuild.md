## 2 Building Your Application

The GEOS system is complex and provides so many services that the 
documentation at first may seem rather daunting. This chapter is meant to 
help you through the application process by directing you to the proper 
chapters for various functions.

This chapter is by no means a comprehensive list of all functions supported 
by GEOS. It is intended to be a guide to the chapters that cover some of the 
more widely-used functions and features.

### 2.1 What Everyone Should Read

Anyone who wants to program a GEOS application should read at least the 
first several chapters of the Concepts Book. Among the chapters you should 
read before going too far are

+ "System Architecture," Chapter 3  
This chapter describes the GEOS system in an overview format. It can 
give you a good idea of how the system works and the features it might 
provide for your application. You should read this chapter now if you 
haven't already.

+ "First Steps: Hello World," Chapter 4  
This chapter describes the Geode Parameters file as well as an example 
of a simple application. The application puts up a window, uses a menu 
and a dialog box, and draws graphic-based text within a scrolling 
window. It also shows how GEOS messaging works, how a message is sent 
and handled, and how objects interact with each other.

+ "GEOS Programming," Chapter 5  
This chapter details the basics and even many of the finer points of 
programming with the Goc preprocessor. Goc has many keywords used 
for object and class definition, message sending and handling, and 
resource definition. Before programming for GEOS, you must know how 
to use several of these keywords (though you can learn several of the 
most important ones from the sample applications).

+ "The GEOS User Interface," Chapter 10  
This chapter describes the basic generic and visual UI object classes 
available. It also details a simple application which uses visual objects 
that draw themselves in a window, intercept mouse clicks, and allow the 
user to drag them around the screen. The sample application also 
illustrates how to create your own objects from the base GEOS visual 
classes.

### 2.2 Topics Listing

Listed below are many of the topics related to creating an application. 
Accompanying the topic is a list of chapters you will probably want to read to 
fully understand that topic.

#### 2.2.1 Defining Your User Interface

"The GEOS User Interface," Chapter 10, gives an overview of the User 
Interface and which objects you will want to use. Many user interface 
functions, objects, and features are listed below.

+ Overview of all the UI Objects  
All the generic and visual UI classes are discussed in "The GEOS User 
Interface," Chapter 10. This chapter is a must-read for nearly everyone.

+ The Primary Application Window  
Almost all applications will have a primary window. "First Steps: Hello 
World," Chapter 4 and "GenDisplay / GenPrimary," Chapter 4 of the 
Object Reference Book discuss how to create and use the window in 
detail.

+ Menus and Dialog Boxes  
Menus and dialog boxes are created with the use of GenInteraction 
objects, described in "GenInteraction," Chapter 7 of the Object Reference 
Book.

+ Monikers and Icons  
Monikers are labels of objects that are drawn on the screen to represent 
the object. Icons are special monikers. Both of these are discussed in 
"GenClass," Chapter 2 of the Object Reference Book.

+ Scrolling and Non-Scrolling Graphics Windows  
The GenView will be used by most applications. Described in "GenView," 
Chapter 9 of the Object Reference Book is the process of creating a 
graphics window and drawing into it.

+ Triggers and Buttons  
Triggers and buttons are described fully in "GenTrigger," Chapter 5 of 
the Object Reference Book.

+ Lists  
Dynamic, static, and scrolling lists are all described in "The List Objects," 
Chapter 11 of the Object Reference Book.

+ Value Setters  
The GenValue object allows the user to set a value within a given range. 
It is described in "GenValue," Chapter 8 of the Object Reference Book.

+ Tool Boxes and Other Controllers  
An application can define or use controller objects that automatically get 
and apply a user's choices. These controllers can be placed automatically 
within floating "tool boxes" by the user. Controllers and tool boxes are 
discussed in "Generic UI Controllers," Chapter 12 of the Object 
Reference Book.

+ File Selector Dialog Boxes  
A standard dialog box for finding and selecting files is provided by GEOS 
and is described in "GenFile Selector," Chapter 14 of the Object 
Reference Book.

+ Multiple Windows  
Your application can display multiple windows using the GenDisplay and 
GenDisplayControl objects described in "GenDisplay / GenPrimary," 
Chapter 4 of the Object Reference Book.

+ Text Editing, Display, and Input  
All text functions are handled by the text objects, GenText and VisText. 
These are incredibly sophisticated and complete, and they are described 
in "The Text Objects," Chapter 10 of the Object Reference Book.

+ Providing Help  
An application can include an object that automatically provides 
context-sensitive help to the user. This object is discussed in "Help Object 
Library," Chapter 15 of the Object Reference Book.

+ Handling Input  
Many applications may want to track mouse or keyboard input. Input 
management is discussed in "Input," Chapter 11.

#### 2.2.2 Providing Other User Interface

Besides the generic UI functions and objects described above, GEOS provides 
a number of sophisticated graphics commands and powerful graphic objects. 
Graphics must be drawn to a GEOS document and the document displayed in 
a GenView.

+ The GEOS Graphics System  
The GEOS coordinate space is based on real-world units and is 
device-independent. It is described in full in "Graphics Environment," 
Chapter 23.

+ Creating Your Own UI Objects  
Using the visible classes, you can create your own objects that draw 
themselves, handle user input, and do any number of other things. See 
"The GEOS User Interface," Chapter 10 and "VisClass," Chapter 23 of 
the Object Reference Book for descriptions of the visible object classes 
and how to use them.

+ Drawing Standard Graphics  
Graphics may be drawn by calling several different graphics commands. 
These commands are described in "Drawing Graphics," Chapter 24.

+ Using Graphic Objects  
The Graphic Object Library provides many different graphic objects that 
know how to position, resize, and draw themselves as well as handle user 
input. This library is described in "Drawing Graphics," Chapter 24 and 
"Graphic Object Library," Chapter 18 of the Object Reference Book.

#### 2.2.3 Documents and Data Structures

Applications that save files, print documents, or display multiple documents 
will be concerned with several of the topics listed below.

+ Creating and Using Documents  
The GenDocument and document control objects provide standard 
document management including document file management and 
interaction with the display objects. See "GenDocument," Chapter 13 of 
the Object Reference Book.

+ Importing and Exporting Data Formats  
Data of other applications can be imported and GEOS data files exported 
to other formats via the Impex Library and its associated format 
translators. These are discussed in "Impex Library," Chapter 16 of the 
Object Reference Book.

+ Using Memory  
"Memory Management," Chapter 15 describes the GEOS memory model 
and memory manager and how an application can use them.

+ Using Files  
Applications that save document files should use the document objects 
(see above). Otherwise, the application will use either GEOS virtual 
memory files (see "Virtual Memory," Chapter 18) or normal files (see "File 
System," Chapter 17).

+ Keeping Track of Database Items  
GEOS provides an item database manager that you can use to 
manipulate database items and files. This is described in "Database 
Library," Chapter 19.

+ Using an Entire Spreadsheet  
GEOS also provides a spreadsheet object that implements the basic 
functionality of a spreadsheet and which can be included in an 
application. This object is described in "Spreadsheet Objects," 
Chapter 20 of the Object Reference Book.

+ Printing  
If your application will print anything to a printer or to a file, you should 
read "The Spool Library," Chapter 17 of the Object Reference Book.

#### 2.2.4 Accessing Hardware

GEOS is designed to allow applications to be as device-independent as 
possible. Some applications will need to access hardware directly, however.

+ Serial and Parallel Ports  
An application that needs to access the serial and parallel ports can do so 
using streams and the serial and parallel drivers. These are discussed in 
"Using Streams," Chapter 21.

+ Disks, Drives, and CD ROM Drives  
Applications that work directly with disks and drives (utility programs 
especially) will use many of the features described in "File System," 
Chapter 17.

+ Sound Hardware  
The standard PC speaker can be accessed through the sound library, 
discussed in "Sound Library," Chapter 13. Drivers and libraries to allow 
applications to use more sophisticated sound hardware may be added 
later.

+ Video Hardware  
In general, GEOS takes care of all video driver operations; applications 
deal with the graphics system, which sends commands to the video 
drivers. For more information, see "Graphics Environment," Chapter 23.

#### 2.2.5 Programming Topics

A number of programming topics specific to Goc are described in "GEOS 
Programming," Chapter 5. This chapter discusses the various Goc keywords 
and their uses. It also describes how to create and destroy objects, how to 
create classes, and how to send and receive messages. You should read this 
chapter if you plan on programming for GEOS using the C programming 
language.

For information on programming in assembly, see the Esp manual. It 
explains GEOS's extensions to standard 80x86 assembly-language 
programming

#### 2.2.6 Other Topics

Many other topics are discussed throughout the documentation. Some of 
those more commonly used are listed below.

+ Saving User Options  
Generic objects typically provide the features of option saving. If you 
need to enhance this, however, you can use the GEOS.INI file to save 
application-specific user options or information. This is discussed in 
"Applications and Geodes," Chapter 6.

+ Using Event Timers  
Many applications and libraries will use event timers. Timers are 
discussed in "Applications and Geodes," Chapter 6.

+ Supporting Quick-Transfer and Using the Clipboard  
To support the Edit menu's Cut, Copy, and Paste functions, see "The 
Clipboard," Chapter 7.

+ Serving International Markets  
GEOS is designed to allow easy translation of applications and libraries 
to other languages. See "Localization," Chapter 8 for full details.

+ Using Multiple Threads  
Because GEOS is multithreaded, any application can create new threads 
for itself at any time. The issues and procedures of multiple threads are 
described in "Threads and Semaphores," Appendix B.

[Introduction](cintro.md) <-- &nbsp;&nbsp; [table of contents](../Concepts.md) &nbsp;&nbsp; --> [System Architecture](carch.md)
