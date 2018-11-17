COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Platform Disk Set
FILE:		README.TXT

DESCRIPTION:

	Release information for the current PC/GEOS platform.  This file is
	shipped with the PC SDK Platform disk set.

	NOTE to authors:  Please date & add new material at the top of the
	file.  Material at the bottom will be removed once incorporated into
	the product documentation.

	$Id: README.TXT,v 1.3.4.1 97/03/29 05:13:49 canavese Exp $

------------------------------------------------------------------------------@


==============================================================================
	6/30/93		README.TXT created
==============================================================================
==============================================================================
	6/30/93		API Changes Made During May and June 1993
==============================================================================
Clipboard:  New
	C stubs for ClipboardRemoteSend/Receive


New GOC and 3 .goh files...
	Added @uses directive, which allows subclassers of certain variant
	classes to bind messages for apparently unrelated classes to their
	methods, if the definer of the variant can say for certain a class
	that will always be at least the ancestor of the class that eventually
	becomes the variant level's superclass. for example, GenText has an
			@uses VisTextClass;
	now.

	Affected .goh files: grobj.goh, gTextC.goh, and gGadgetC.goh



Ink Changes and Additions
	* Added ATTR_INK_MAX_POINTS and MSG_INK_SET_MAX_POINTS

	MSG_INK_SET_MAX_POINTS		message
	;
	;	Sets the maximum # points allowed in the ink object
	;
	;	NOTE: It is possible for the # points to slightly exceed this,
	;	since an erase can, in some circumstances, produce a few more
	;	line segments/points than existed before the erase.
	;
	;	Pass: cx - max # points
	;	Return: nothing
	;	Destroyed: ax, cx, dx, bp


	ATTR_INK_MAX_POINTS		vardata	word
	;
	;	Sets the max # points allowed in the ink object
	;

	* Added InkCompress and InkDecompress routines (and associated C stubs)
	  These can be used to decompress data stored by ink objects.

	global InkCompress:far
	;
	; Takes ink and compresses it.
	;
	; Pass: CX - handle of block containing ink data:
	;		word numPoints
	;		InkPoint
	;		InkPoint
	;		InkPoint
	;		  ...
	;	BX - file in which to create DB Item
	;	AX:DI - DBItem to hold data (pass 0:0 to create a new DBItem)
	;
	; Return: AX:DI - DBItem containing ink data

	global InkDecompress:far
	;
	; Takes compressed ink and decompresses it
	;
	; Pass: BX - file
	;	AX:DI - DBItem
	;
	; Returns: BX - block containing ink data:
	;				
	;		word	NumPoints
	;
	;		InkPoint
	;		InkPoint
	;		InkPoint
	;		 ...

	* If "debugInk=true" is set in the [input] category on an EC system,
	  the IMPenCode resource is locked down and used (not copied) so
	  we more easily get a backtrace on any crashes.



Dialogs
        * UserDoDialog will now raise an app to the top if saves off a
          IACP_NEW_CONNECTION(app-mode, on top) into the queue, allowing
          the user to always be able to respond to the dialog.

        * App-modal dialogs are now promoted to being system-modal, if the
          current app is going to be blocked from finishing its ATTACH as a
          result of it, as the system considers itself to be "busy" during
          this period.  This will keep the busy cursor from appearing above
          such boxes, allow them to be used without a mouse, & allow them to
          be interacted with even if there is another system-modal box up
          (such as the "Activating" dialog).

         * Changed UserDoDialogs to be ignored if the app is cached (but not
           if running in background via AVOID_TRANSPARENT_DETACH) to make
           the behavior more orthogonal & keep cached apps from clogging up
           the heap w/locked code blocks.  The full picture is now:

                                            To    To  Start of
                           Att'ing Bkgrnd  Bkgrd Cache Detach  Cached Det'ing
  App modal
    UserDoDialog from ui      p     n       -      r      r      i      i
    UserDoDialog from app     n     n       -      r      r      i      i
    INITIATEd                 n     n       -      -      -      n      s

  Sys modal
    UserDoDialog from ui      n     n       -      r      r      i      i
    UserDoDialog from app     n     n       -      r      r      i      i
    INITIATEd                 n     n       -      -      -      n      s

  Key:
        n       - normal, standard dialog behavior
        s       - saved to state (will be put up on restore from state)
        p       - promoted to be system modal
        i       - ignored, i.e. the dialog not put up.  IC_NULL returned from
                  UserDoDialog's
        r       - removed, i.e. taken down from the screen.  IC_NULL returned
                  from UserDoDialogs

        * Added MSG_GEN_APPLICATION_GET_TRANSPARENT_DETACH_LIST, so that
          detach GCN behavior could be altered & current state tested.
          (Need for UserDoDialog ignore-if-cached change above).


Document Control
        * Fixed the doc control so that single-threaded apps behave like two-
          threaded ones, in that documents are not restored from state nor
          the default document opened until the application has finishing
          attaching & is on screen.  Prevents the password & document-open-error
          dialogs from coming up before the rest of the app, which can be
          visually confusing on Zoomer where things can be transparently
          detaching in the back.


Application State Saving and Resurrection
        * Tightened detach synchronization by moving the "update app state to
          indicate no longer in app mode" code & "call MSG_GEN_APPLICATION_APP_
          MODE_COMPLETE to figure out what to do next" code into a single place,
          named MSG_GEN_APPLICATION_CLOSE_COMPLETE.

          New:
                MSG_GEN_APPLICATION_CLOSE_COMPLETE

          Changed:
                MSG_GEN_APPLICATION_APP_MODE_COMPLETE and MSG_GEN_APPLICATION_
                IACP_NO_MORE_CONNECTIONS no longer require attach/quit flag
                to be passed in cx.  (Also nuked quit code which was never used)

        * Added "AS_REAL_DETACHING" flag to the app object state flags, which
          indicates that the app is detaching beyond the point of no return.
          Used for EC, but I also have a feeling that it may come in handy
          to distinguish between the steady state scenerio.

          New:
                AS_REAL_DETACHING

        * Fixed problem w/MSG_GEN_PROCESS_OPEN_APPLICATION not being passed
          the just-returned state block when resurrecting.

          The extra state block returned from MSG_GEN_PROCESS_CLOSE_APPLICATION
          is now stored in TEMP_GEN_APPLICATION_EXTRA_STATE_BLOCK, until
          it is either passed back in MSG_GEN_PROCESS_OPEN_APPLICATION in
          the resurrection case, or saved out to the state file if exiting.

          NOTE:  Required the removal of "extra state block" support from
          CUSTOM & ENGINE application modes.  Documentation for ENGINE didn't
          show this support existed before & so is ironically now correct.

          Parameters no longer returned (as-of-yet-unused method):

              extra state block, by MSG_GEN_PROCESS_CLOSE_CUSTOM

        * Broadened meaning of AS_RESTORING_FROM_STATE to cover any case
          of opening the app up other than fresh with no state file, as this
          seems to most closely match current use & needs.  Change docs
          for AS_STATE_FILE_PASSED to more accurately reflect what it's
          really about as well -- that the app was truly launched to restore
          itself according to a specific state file.

          Changed resurrection MSG_GEN_OPEN_APPLICATION to pass
          AS_RESTORING_FROM_STATE if the app had previously been in app
          mode before, as the app otherwise has no warning that the UI tree's
          already been in use (i.e. might already be set up).  Keeps the UI
          from invoking MSG_META_LOAD_OPTIONS, & keeps the spui from
          following "ON_STARTUP" hints.  Added AS_RESTORING_FROM_QUIT to cover
          the one problem case I could find, that of the document control
          needing to start afresh if coming back to life after a quit, wherein
          it closes all documents & needs to start over.


Errata, Spool:
          In the documentation for the Spool library, the first
          paramenter to MSG_PRINT_NOTIFY_PRINT_DB is printControlOD.
          However, in the C interface header file, the name is
          printCtrlOD.

Text:
	This is not really an API change, but a clarification on how
	the user modified state should be used with MSG_META_TEXT_USER_MODIFIED.
	If you handle MSG_META_TEXT_USER_MODIFIED simply for notification the
	text has become dirtied (as all but two known uses do) and do not
	reset the user modified state, no changes are necessary.

	MSG_META_TEXT_USER_MODIFIED	message	MetaTextMessages
	;
	;	Sent when the user modifies the text
	;	This message is sent to the text object itself first.
	;
	; NOTE:  the text object sends this notification first to its
	; destination, & then to itself for internal update.  If you intercept
	; this message at the destination, be aware the text object's MODIFIED
	; state has not yet been updated, & so operations that modify that
	; state, such as MSG_VIS_TEXT_SET_NOT_USER_MODIFIED, or
	; MSG_GEN_TEXT_SET_MODIFIED_STATE, may not be synchronously called.
	; If you need to perform such operations, such as the case where you
	; need to clear the modified status in order to receive notification
	; on every keypress, use the MF_FORCE_QUEUE and MF_PLACE_AT_FRONT
	; flags when sending the message, so as to allow the text
	; object to first finish updating itself.
	; 
	;	Pass:	cx:dx - object
	;	Return:	none

	ATTR_VIS_TEXT_SEND_CONTEXT_NOTIFICATIONS_EVEN_IF_NOT_FOCUSED	vardata
	;
	;	This sends out context notifications even if the object is
	;	not focused. Apps should beware when using this, to make sure
	;	the object that this is on does *not* get modified while another
	;	text object has the focus.


Token Database:
	* TokenLockTokenMoniker now returns with the semaphore for the
	appropriate token database file grabbed. The registers it returns
	have not changed.

	* TokenUnlockTokenMoniker
	IMPORTANT: No token database call may be made between a call to
	TokenLockTokenMoniker and the corresponding call to
	TokenUnlockTokenMoniker, which will release the semaphore for
	the appropriate token database file. Making such a call will hang
	the system.


Help Controller:
	* Added support for ATTR_GEN_PATH_DATA in the HelpControl.  Allows
	double-clicking on a help file / info document to open it
	anywhere, instead of just in USERDATA\HELP.
	NOTE: For links to other files, the other files must reside in the
	same directory the info document was opened in.


ProcessClass
	MSG_PROCESS_CREATE_EVENT_THREAD_WITH_OWNER		message
	;
	; This is a utility method that one can send to oneself to create a new
	; event-driven thread. It cannot be used to create a non-event-driven
	; thread (use ThreadCreate instead). This is implemented at ProcessClass
	; and takes care of all the cruft of creating a new event-driven thread.
	; The thread will always receive a MSG_META_ATTACH as its first event.
	;
	; Context:	Process utility message
	; Source:	Unrestricted
	; Destination:	Any process
	; Interception:	Not necessary
	; Pass:		cx:dx	- object class for the new thread
	;		     If you don't have any special methods to handle in
	;		     this thread, besides those intended for objects run
	;		     by the thread, you can just specify ProcessClass as
	;		     the object class.
	; 		bp	- stack size for the new thread, or NULL for the
	;			  default stack size (512 bytes)
	;		si - geode to own the thread
	; Return:	carry clear if thread created:
	;		ax	- handle of new thread
	;		cx, dx, bp - destroyed
