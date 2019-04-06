## 1 Introduction

Congratulations on taking the first step towards programming for GEOS. 
This system will most likely be unlike anything you have programmed for 
before; among the main goals of the system design were to simplify 
development of applications and to incorporate many common application 
and User Interface features within the system software.

### 1.1 Overview of The Documentation

These manuals represent the initial non-Beta release of technical 
documentation for the GEOS operating system. These manuals should 
provide you with all the knowledge, both conceptual and reference, to write 
programs for GEOS.

#### 1.1.1 What You Will Learn

This documentation provides everything you need to write a complete GEOS 
application. It includes in-depth conceptual and reference material about 
every exported kernel routine and system object.

These books will teach you about GEOS-how the operating system works, 
from file management to messaging to object creation and destruction. If you 
read everything in these books, you should be able to create the source code 
for not only simple applications but even applications of medium complexity.

#### 1.1.2 What You Are Expected To Know

This documentation relies heavily on the reader's knowledge of the C 
programming language and of Object-Oriented Programming (OOP) 
concepts. If you are unfamiliar with either of these topics, you should become 
familiar with them before continuing.

You are also expected to have a working familiarity with Geoworks® 
products. Working familiarity with the software is important to understand 
the features of the system from the user's perspective. In addition, many 
User Interface concepts are illustrated with examples from the retail 
products.

#### 1.1.3 Roadmap to the Development Kit

The developer kit documentation is separated into several books. Each of 
these books has a primary purpose; together, they should give you all the 
information you need to know about GEOS and how to program for it. The 
books are

**Tutorial**  
The Tutorial describes how to set up your system, how to begin running 
the tools, and how to get started programming GEOS applications. It 
takes you step-by-step through modifying, compiling, and debugging a 
sample program.

**Concepts Book**  
This is the Concepts Book. This book explains the structure and concepts 
of creating a GEOS application. It will help you plan and create the 
structure of your applications and libraries, and it details all the 
functions of the GEOS kernel. It describes which system objects you will 
want to use for various situations and to get various results.

**Objects Book**  
The Objects Book contains C reference information and detailed, 
in-depth discussion of each of the system-provided objects. This book is a 
hybrid of the traditional reference and conceptual manuals; each chapter 
contains both a detailed description of and a detailed reference for each 
object. In most cases, each object is given its own chapter. In some cases, 
however, several related objects share a single chapter.

**Esp Manual**  
The Esp manual describes Esp, GEOS's OOP assembly language, the 
language in which most of the GEOS kernel is written. Using Esp, you 
will be able to write optimized routines and applications to handle your 
most processing-intensive tasks.

**C Reference Book**  
The Routines Book details the data structures, routines, and other 
typical reference material you'll need. It focuses on the routines and 
functions provided by the GEOS kernel including the Graphics System 
and Memory Management.

**Esp Reference Book**  
The Esp reference book provides Esp (assembly-language) information 
for the structures and routines used by the GEOS kernel and the system 
libraries.

**Tools Manual**  
The Tools manual describes all the tools included with the SDK. It 
includes descriptions of the system setup, the Swat debugger, the icon 
editor, the localization tools, the GEOS initialization file, and all the other 
tools in the system. In addition, it also details the Tool Command 
Language, which allows you to extend Swat's functionality for your own 
purposes.

**Objects Quick-Reference Manual**  
The Quick-Reference manual is a handy booklet that has not text 
information, but rather all the pass and return and definition 
information for all the object classes in GEOS. It should be used after 
you've become familiar with the concepts of the system.

#### 1.1.4 Typographical Cues

Throughout these manuals, you will see several words in bold or italics, and 
you will read several code examples. For the most part, there are four types 
of typographical cues that you will encounter:

+ Book Symbols  
Each book in this developer kit documentation is designated a special 
shape to help you identify it quickly on the shelf. Wherever possible, this 
shape is used along with the book title (in cross-references, for example).

+ Boldface Text  
Boldface text is used to denote GEOS class names, routine and function 
names, and data structures. It is also used for file names, as-typed 
commands, and headers of many lists.

+ Italic Text  
Italic text is used to denote terms that can be found in the glossary, 
parameters passed to routines and messages, and flags. Variables are 
often also designated with italics. Note, however, that flags that are all 
capital letters are not in italics.

+ Monospace Font  
Monospace font is used for all code samples and illustrations of 
commands. It is also used as a subheading for sections that describe 
particular routines, messages, and data structures.

### 1.2 Chapters in the Books

This section of this chapter lists all the chapters in each of the main books of 
this documentation.

#### 1.2.1 The Concepts Book

The Concepts Book describes not only the concepts of the GEOS system but 
also the steps and components of applications. Typically, a reader will read 
straight through the first six chapters and then choose whichever order of 
chapters suits her or him best after that. The book is designed for sequential 
reading, however.

1. Concepts Introduction  
This chapter describes the structure and components of the developer kit 
documentation and of each book in it. You are reading the Concepts 
Introduction now.

2. Building an Application  
This gives a terse, feature-by-feature listing of chapters you will want to 
read for various topics. It is much like this section except it is by feature 
rather than by sequence.

3. System Architecture  
This describes the architecture of GEOS and the part that each of its 
components plays. It describes how applications and libraries fit into the 
scheme of GEOS as a whole, and it enumerates the mechanisms used 
throughout the system.

4. First Steps: Hello World  
This is an in-depth look at the basics of a GEOS application through a 
detailed example. It uses a program appropriately titled Hello World; 
this program draws a primary window, creates a scrolling window, draws 
text in the window, and uses a menu and dialog box to allow the user to 
change the color of the text.

5. GEOS Programming  
This describes all the keywords available in the GEOS Goc programming 
language. It also discusses data types and the GEOS object system. It 
describes how objects are created and destroyed and how classes are 
used.

6. Applications and Geodes  
This details how an application and other geodes (GEOS executables) are 
loaded and shut down. This chapter also discusses several things that 
may be of importance to application programmers such as saving user 
options and other system utilities.

7. The Clipboard  
This is about the Clipboard and the quick-transfer data transfer 
mechanism. The Clipboard implements the cut, copy, and paste features 
usually found in the Edit menu of an application. The quick-transfer 
mechanism implements the "drag-and-drop" functionality inherent in 
text objects and available to applications for all data formats.

8. Localization  
This discusses how developers can localize their applications for 
international markets. It discusses not only the Localization Driver but 
also how to plan ahead when writing your applications.

9. General Change Notification  
This discusses the General Change Notification (GCN) mechanism of the 
kernel. This mechanism allows objects to register interest in a particular 
event so that whenever that event occurs, the object will be notified of the 
change.

10. The GEOS User Interface  
This describes in detail how the GEOS User Interface works. It gives a 
sample application using visible objects (objects that you use to draw 
graphics and to interact with the user). This chapter is the "visible world" 
counterpart to the Hello World application of chapter three.

11. The Input Manager  
This describes how GEOS accepts, manages, and passes on input events. 
An input event can be motion of the mouse, use of a stylus, a press on the 
keyboard, a click on a mouse button, or some other event.

12. The Geometry Manager  
This describes various ways you can manage the size, position, and 
geometry behavior of generic User Interface objects (e.g. windows, dialog 
boxes, and scrolling view windows).

13. Sound Library  
This details how to use the GEOS sound library with different sound 
generators.

14. Handles  
This discusses in detail the concept, implementation, and use of GEOS 
handles. Handles are an integral part of the GEOS system for memory 
management, file management, graphics drawing, and message passing.

15. Memory Management  
This details the GEOS memory model and how to allocate, use, and free 
up memory for your application.

16. Local Memory  
This describes how to use local memory. Local memory is a mechanism 
used to store the instance data of objects as well as small chunks of data 
such as strings, small graphics, and database items.

17. File Systems  
This describes how GEOS interacts with the DOS or other file-access 
system in use. This chapter details how GEOS applications can open, edit, 
close, and manipulate all kinds of files. It also discusses how to access 
disks and drives directly.

18. Virtual Memory  
This discusses the GEOS Virtual Memory model. Virtual Memory is used 
not only to manage memory swapping but also for storing GEOS data and 
object files. The Virtual Memory mechanism is an integral part of GEOS 
and will be used by many applications and libraries.

19. Database  
This details the Database Library provided with GEOS. The Database 
Library provides the low-level routines to create, edit, free up, and 
organize individual database items.

20. Parse Library  
This details the Parse Library. This library implements a special 
mathematical description language.

21. Streams  
This discusses the concept and use of streams, a data-transfer 
mechanism to pass data either through hardware ports or across threads 
in GEOS. Included in this chapter are the Parallel Driver and Serial 
Driver, integral in accessing the PC's communication ports.

22. Graphics Environment  
This describes in detail the GEOS coordinate and graphics system. It 
covers the coordinate space, how graphics are drawn, the drawing 
algorithms, and many other topics. Described herein are GEOS "graphic 
states" and "graphic strings," both integral parts of GEOS.

23. PCCom Library  
This explains the use of the PC communications library. It explains how 
a geode may use the library to monitor a serial port, or to transfer files 
and information to or from a remote machine.

24. Graphics  
This is an extension of the discussion of chapter twenty-one and explains 
how to draw various shapes. It enumerates your options for drawing 
graphics in GEOS, from simple graphics routines to complex graphical 
objects provided in the Graphic Object Library.

The Concepts Book also has four appendixes: The first gives a background of 
the PC architecture. The second gives an in-depth discussion of threads and 
thread management. The third describes how to create GEOS libraries. The 
fourth describes the GEOS floating-point math library.

#### 1.2.2 The Object Reference Book

The Object Reference Book is a hybrid of traditional conceptual and 
traditional reference books. Each chapter gives both in-depth conceptual and 
usage information as well as specific reference material for the subject 
objects. It is assumed that you will read through a major portion of the 
Concepts Book before embarking on the Object Reference chapters; the 
Concepts Book will direct you to the individual objects you will need to read 
about in the Object Reference.

1. System Classes  
This details the three system classes that handle many of the messages 
and provide much of the built-in functionality for most objects. These 
classes are MetaClass, the root of the GEOS class tree; ProcessClass, 
the main class of an application's process thread; and 
GenProcessClass, the superclass of ProcessClass.

2. GenClass  
This details GenClass and much of the common functionality of all 
generic objects. It describes generic object trees, messaging between 
generic objects, and using monikers with generic objects. It also discusses 
input issues with respect to the generic hierarchies.

3. GenApplication  
This covers GenApplicationClass, the class of all application objects. 
Every application will have an application object as the root of its generic 
object tree. This object has no visual representation but handles loading 
and shutting down of the application geode.

4. GenDisplay/GenPrimary  
This describes the window objects in GEOS. The GenPrimary object 
provides an application's primary window; the GenDisplay and Display 
Control objects provide window objects for individual documents. With 
these objects, an application can provide multiple scrolling displays 
within its primary window.

5. GenTrigger  
This covers GenTriggerClass, the class that implements basic triggers 
and buttons in the User Interface.

6. GenGlyph  
This covers the Glyph class, which allows an application to display a 
small portion of text or graphics without the overhead of other, more 
complex objects.

7. GenInteraction  
This discusses GenInteractionClass, a versatile class that implements 
both menus and dialog boxes.

8. GenValue  
This discusses the GenValue object. This object allows the user to set a 
value within a specified range.

9. GenView  
This covers the GenView object. The GenView provides a scrolling 
window for applications to draw graphics or otherwise display objects or 
data in.

10. The Text Objects  
This describes how text is used throughout GEOS. Any application that 
expects to display text, accept text input, or provide text formatting 
features will use one of the text objects provided by GEOS. This chapter 
describes how and when to use each of these objects.

11. The List Objects  
This details the different types of lists you can create with the various 
list-related classes including GenBoolean, GenBooleanGroup, GenItem, 
GenItemGroup, and GenDynamicList.

12. GenControl/GenToolControl  
This details the controller and toolbox classes that allow an application 
to use and create controllers. Controller objects automatically build 
menus and dialog boxes to manage a certain feature set of an application. 
The Tool Control object allows the user to configure his or her system to 
place certain tools either in a floating tool box or in various menus.

13. GenDocument  
This describes the GenDocument and the document control objects. 
These objects help applications manage data files (documents) and 
provide the common functionality of New, Open, Close, Save, SaveAs, 
and Revert.

14. GenFileSelector  
This describes how and when to use a GenFileSelector object. The 
GenFileSelector provides the user interface that allows users to traverse 
their file systems and view their directories. It also lets them select a file 
for opening or other operations.

15. Help Object Library  
This details the Help Object Library. The help object allows your 
application to provide context-sensitive help text in a system-standard 
way. The help object will create the user interface and will automatically 
provide text linking through your help documents.

16. Import/Export Library  
This describes the import and export mechanism used by GEOS. The 
Impex Library connects GEOS to individual translation libraries. This 
chapter describes not only how to create new translation libraries but 
also how to link them into GEOS.

17. Spool Object Library  
This describes the Spool Object Library. This library exports classes 
which allow applications to print and otherwise interact with the GEOS 
spooler.

18. Graphic Object Library  
This details the Graphic Object Library. This library offers several 
objects and classes that provide full graphic object editing and display 
features. Graphic objects include line, rectangle, ellipse, spline, polyline, 
and polygon, among others.

19. Ruler Library  
This details the Ruler Library; this library contains vertical and 
horizontal ruler objects which can be connected to text, graphic, and 
spreadsheet views.

20. Spreadsheet Object Library  
This covers the Spreadsheet Object Library. This library exports several 
classes that can be used as the basis of a spreadsheet application when 
used with the Cell, and Parse libraries.

21. Pen Object Library  
This describes the built-in pen and Ink support of GEOS. Pen input can 
be managed by a set of special objects that an application may interact 
with.

22. VisClass  
This details VisClass, the basic visible object class of GEOS. VisClass 
can be used to create objects that can draw themselves and accept input. 
VisClass is also the ancestor class of many special objects in GEOS (e.g. 
the Ruler Object, the Spreadsheet Object, etc.).

23. Config Library  
This discusses how to write Preferences modules. This is useful for 
programmers who are defining new fields in the GEOS.INI file.

24. VisComp  
This details VisCompClass. This is a subclass of VisClass and provides 
additional features such as object tree manipulation and automatic 
geometry management of a visible object's children.

25. VisContent  
This details VisContentClass, a subclass of VisCompClass. The 
VisContent is used to display a visible object tree within a GenView 
graphic window and to manage the geometry of several visible objects 
within the window.

26. Generic System Classes  
This covers several generic system classes that will not ever be used 
directly by application programmers. They are provided here, however, to 
give reference information about the messages that can be sent to them. 
Included in this chapter are GenSystem, GenScreen, and GenField.

#### 1.2.3 The Tools Reference Manual

The Tools Reference manual describes many things about the tools and the 
development station setup that you will need to know throughout your 
development period. It contains the following chapters:

1. Introduction  
This is an outline of the Tools Reference Manual.

2. System Configuration  
This describes the host and target machine setups after the SDK has been 
installed and is working.

3. Swat Introduction  
This introduces you to Swat, the powerful system debugger supplied in 
the SDK. This chapter also gives you the most popular Swat commands 
and explains how you can put them to use for you.

4. Swat Reference  
This gives detailed command reference entries for each Swat command. 
You should use this section when you need to know the specifics of one or 
more Swat commands.

5. Debug  
This explains how to use the Debug tool, which allows you to simulate a 
number of GEOS platforms and hardware configurations.

6. Tool Command Language  
This describes Tcl, the Tool Command Language that allows you to 
extend Swat's functionality. Nearly all Swat commands are programmed 
in Tcl, and most are accessible as functions within other Tcl commands. 
By using Tcl, you can write your own debugger commands or extend the 
functionality of Swat's provided commands.

7. Icon Editor  
This describes how to use the GEOS icon editor tool.

8. Resource Editor  
This describes how to use the GEOS resource editor tool for localization.

9. The INI File  
This describes the various categories and keys of the GEOS.INI file used 
by GEOS.

10. Using Tools  
This details all the other tools in the system, including the 
communications utilities, the make utilities, GOC, Glue, and others.

#### 1.2.4 The Esp Book

The Esp book describes how to use Esp, the GEOS object-oriented assembly 
language. You can use this language to recode computation-intensive 
routines, or to write optimized applications, libraries, or drivers.

1. Introduction  
This chapter provides a brief introduction to Esp, and contains a 
roadmap to the Esp book.

2. Esp Basics  
This chapter describes the differences between Esp and other 80x86 
assembly languages (such as MASM). It also describes how to define 
classes.

3. Routine Writing  
This chapter describes how to write routines and methods (message 
handlers). It also describes Esp's special facilities for managing stack 
frames and sending messages.

4. The User-Interface Compiler  
This chapter describes UIC, a tool for generating object-blocks for Esp 
programs.

### 1.3 Suggestions for Study

If you are unfamiliar with programming, you will most likely not be able to 
follow this documentation well. You should have working familiarity with the 
C programming language and with Object-Oriented Programming concepts. 
This documentation will not attempt to teach those subjects. If you are not 
familiar with these subjects, you may have trouble following some of the 
discussions throughout.

For those ready to begin, it is suggested that you read the first six chapters 
of this book before branching out into different in-depth concepts. From 
there, you should read about the Generic UI objects, with focus on 
GenInteraction, GenTrigger, GenPrimary, and GenView. These will build on 
the introduction you gained from the first chapters of the Concepts Book.

 &nbsp;&nbsp; [table of contents](../Concepts.md) &nbsp;&nbsp; --> [Building Your Application](cbuild.md)
