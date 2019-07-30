## 22 PCCom Library

The PCCom library provides a simple way to allow a geode to provide and 
monitor a PCCom connection. If you are familiar with the SDK, you probably 
think of pccom as a tool which allows the target machine to receive 
commands from the host machine. While the target machine runs the pccom 
tool, the host machine can upload and download files and otherwise 
manipulate the target machine.

The PCCom library allows a geode to start up a PCCom thread monitoring a 
serial port for purposes other than debugging. For instance, it allows the 
GEOS machine to receive files sent over a serial line by another machine 
running pcsend or another program using pccom's file transfer protocol. This 
allows file transfers and other pccom operations to go on in the background 
while the user continues to interact with GEOS.

If you're not familiar with the pccom tool, you should probably read the 
pccom section of "Using Tools," Chapter 10 of the Tools Book-perhaps not 
the whole section, but at least enough to understand basic usage.

### 22.1 PCCom Library Abilities

Your geode needn't do much to support PCCom. The PCCom library acts as a 
passive pccom machine-it will only accept orders from a remote machine. 

All you need to do to support PCCom is start up a PCCom process, ideally 
freeing it when done. Geodes using the PCCom library have the option of 
receiving notification when pccom would display text.

### 22.2 What To Do

PCCOMINIT(), PCCOMEXIT(), PCCOMABORT()

When you are ready to start monitoring a serial port for pccom-style 
communications, call PCCOMINIT(). This routine is an entry point for the 
library, accessible via ProcGetLibraryEntry() as the first entry point in the 
library, and it may also be called as a normal routine. PCCOMINIT() starts up 
a new thread which will monitor the passed serial port. If it cannot make the 
connection, it will return an error.

When you are done with PCCom, call PCCOMEXIT(), invocable as a library 
entry point or as a normal routine, which closes down the monitor thread and 
frees the serial port for other uses. After calling this routine, you must call 
PCCOMINIT() again if you wish to re-establish the pccom connection.

You may call the PCCOMABORT() routine at any time; this routine aborts any 
pccom file transfer that may be in progress, but leaves the PCCom connection 
intact.

### 22.3 Staying Informed

The sections above tell you everything you need to let your geode interact 
with pccom. It is possible to do more: your geode can receive notification 
whenever the pccom tool would display some text. The pccom tool displays 
text to show the user what's going on. Text signals the successful or 
unsuccessful completion of certain operations; a spinning baton shows that a 
file transfer is in progress. Your geode can also find out if the machine on the 
other side of the pccom link has quit pccom.

When calling PCCOMINIT(), your geode can specify an object which should 
receive notification when pccom has text to display or senses that the other 
side of the pccom link has quit. If an object is so specified, it will receive 
notification messages at these times. You must also set the 
PCComInitFlags argument to PCCOMINIT() such that the appropriate 
kinds of notification will be sent; there is one flag which asks for display text 
notification and another flag which asks for notification when the other side 
of the pccom connection exits.

Notification will come in the form of MSG_META_NOTIFY or 
MSG_META_NOTIFY_WITH_DATA_BLOCK. There are three possible forms of 
notification:

MSG_META_NOTIFY:GWNT_PCCOM_DISPLAY_CHAR
If the passed notification type is 
GWNT_PCCOM_DISPLAY_CHAR, then the notification's data 
word contains a character that pccom would display.

MSG_META_NOTIFY_WITH_DATA_BLOCK:GWNT_PCCOM_DISPLAY_STRING
If the passed notification type is 
GWNT_PCCOM_DISPLAY_STRING, then the data in the 
notification's data block is a string of characters.

MSG_META_NOTIFY:GWNT_PCCOM_EXIT_PCCOM
If the passed notification type is GWNT_PCCOM_EXIT_PCCOM, 
then the pccom process on the other side of the pccom 
connection has exited; the notification's data word contains a 
PCComReturnType indicating the success the other side had 
in exiting. The other side of the connection signals that it is 
exiting by sending an EX escape code over the pccom 
connection. A data value of PCCRT_NO_ERROR is a sign of a 
successful exit; other return values might signal that the exit 
was the result of an error.

[Using Streams](cstream.md) <-- &nbsp;&nbsp; [table of contents](../concepts.md) &nbsp;&nbsp; --> [Graphics Environment](cgraph.md)
