COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1998.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	ftp
MODULE:		htftp
FILE:		readme.txt

AUTHOR:		Jeremy Broestl, Jul 29, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jeremyb 	7/29/98   	Initial revision


DESCRIPTION:
			
	Everything you ever wanted to know about Geos ftp.  Yeah right.

	$Id: readme.txt,v 1.1.1.1 98/08/04 14:47:25 jeremyb Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

----------------------------------------------------------------------------
	What do the files in this directory really do:
----------------------------------------------------------------------------

- mkftp.nsc: Original C source file from which the majority of this code is
 ported.  This file should not be compiled in, hence the wacky extension nsc,
 which stands for Netscape C.

- mkftp.nsh: Original header file included for completeness.  Again should not
 be compiled in.

If you want to see the original Netscape code that contains all the
structures Netscape used, see /n/eng/mzhu/nsrc/ns and subdirectories.  The 
names of most of the structures were changed at the end of July to conform
to Geos naming conventions.  The only names that shouldn't have been changed
to conform to Geos conventions are those functions called within the top level
of the state machine (ftp_send_port).  The names of these functions were 
changed to match the FTP states (see later) to make searching easy.  Thus if
you want to see the Netscape analogy to a struct, just go back in time in RCS.
Structures have been pared down greatly.

- htftp.goc: Contains the commonly used routines in the ftp process.  This 
 includes the central routine of the state machine (the switch loop), and the
 routine which fetches responses to client-side messages.

- ftpinit.goc: Contains initialization routines for the ftp process

- ftpget.goc: Contains routines used to actually save the ftp file.  The line 
 between ftpinit and ftpget is very gray.

- ftpexit.goc: Contains cleanup and deallocation code.

- nsftp.goh: Originally intended as the holding file for Netscape structures, 
 this file has grown into the catch-all header file for structure defs and 
 constant enumeration.  If future engineers find it useful to split off 
 Netscape defs from geos-specific ones, go ahead and split it.  If not, a 
 renaming of this file is in order.  For now I keep the same name to avoid 
 confusion with deleted files in RCS, etc.

- CInclude/WWW/htftp.goh: Header file that needs to be included by the 
browser application in order to receive proper notification of ftp events.

---------------------------------------------------------------------------
	What is FTP and why do I care??
---------------------------------------------------------------------------

FTP is documented on the internet in many places.  Try this rfc if you're 
curious:

www.w3.org/Protocols/rfc959/7_Scenario.html

FTP is of course file transfer protocol.  A different library is required,
separate from the browser libs because ftp communicates using a different 
set of protocols.  Instead of merely submitting a request to the server, 
the client must log into the server, figure out how big the file is, where
and how to communicate with the server, where to save the file, then get the
file.  Communication is accomplished using a number of 4-letter sequences.
For example, to log into a server, the client tells the server "USER", 
followed by the user name.  To get a file, the client sends "RETR" followed
by the file name.

Smart ftp clients within browsers allow the browser to be used as a robust
ftp client, as opposed to simply clicking on a link and saving the file.
In principle this is not difficult.  When an ftp address is to be loaded,
the client stares at the extension and does the right thing.  If it's a .txt
or no extension, the ftp server output (the "page") is simply sent off
to some other content handler for display.  If it's a zip file, then this
ftp file saving process is initiated.  

Currently, our ftp client is not smart.  If an ftp address is encountered, 
we save the file and that's all.  See the to-do list.

---------------------------------------------------------------------------
	How does this gizmo work anyway???
---------------------------------------------------------------------------

As you may have noticed from htftp.goc, it's a big fat state machine.

The states in the general order in which they are used:

(Begin switch loop)
FTP_CONTROL_CONNECT
FTP_SEND_USERNAME
FTP_SEND_USERNAME_RESPONSE
FTP_SEND_PASSWORD
FTP_SEND_PASSWORD_RESPONSE
FTP_SEND_REST_ZERO
FTP_SEND_REST_ZERO_RESPONSE
FTP_SEND_SYST
FTP_SEND_SYST_RESPONSE
FTP_FIGURE_OUT_WHAT_TO_DO
FTP_SEND_PASV [FTP_SEND_PORT]
FTP_SEND_PASV_RESPONSE [FTP_SEND_PORT_RESPONSE]
FTP_PASV_DATA_CONNECT [ ]
FTP_GET_FILE_TYPE
FTP_SEND_BIN
FTP_SEND_BIN_RESPONSE
FTP_GET_FILE_SIZE
FTP_GET_FILE_SIZE_RESPONSE
FTP_GET_FILE_MDTM
FTP_GET_FILE_MDTM_RESPONSE
FTP_GET_FILE
FTP_SEND_RETR
FTP_SEND_RETR_RESPONSE
FTP_START_READ_FILE
FTP_READ_FILE
FTP_LOGOUT_AND_DONE
FTP_DONE

In between the FTP_SEND_* and the FTP_SEND_*_RESPONSE, there is an intermediary
state called FTP_WAIT_FOR_RESPONSE which gets the server response to the client
data send in FTP_SEND_*.

The bracketed states indicate an alternative path if the server isn't equipped
to do handle pasv data connections (we talk about this more later).  That is,
figure_out_what_to_do decides whether or not the server can handle passive
connections based on what data has been received from the server (namely, the
server's reply to "PASV"). 

Passive data connections: When the client formally requests a file, another 
connection must be created specifically for the file.  In passive mode, the 
server creates another socket and the client just connects to it.  The server 
dictates to the client the location of the socket in the form of a 32-bit
ip address and 16-bit port number.  If the server denies the ability to
create such an additional connection, then the client creates another socket,
and listens on it for the server to connect to it.

-----------------------------------------------------------------------------
	"How do I debug this damn thing" - Paul Canavese
-----------------------------------------------------------------------------

- So it's breaking and you don't know why.  The best way to figure out
the general location of the problem is printing outgoing data in SocketSend,
as well as incoming data in net_ftp_response.  You can also print out the 
state of ftp at the top of the big switch.  The client receives messages back
from the server preceded by a 3 digit number.  Successful command completion
generally results in a 2 as the first digit.  Errors are indicated by a 5 as
the first digit.

-----------------------------------------------------------------------------
	So what's left to do??
-----------------------------------------------------------------------------

- Allow the user to navigate an ftp server ala Netscape: clickable links.  All
you need to to make a decision based on the extension, then pipe it all to a
different content handler.  Example: ftp://ftp.geoworks.com

- Right now, all we have is anonymous login.

- Speed the thing up!  Consider changes to net_ftp_response.

- The choice of transfer type may not be made correctly.  Waiting for bugs
here.

- The 3 structure model is really unwieldy.  We've got ce, cd, and tmp_con,
and we have to lock and unlock them every function call.  Consider
consolidation.

