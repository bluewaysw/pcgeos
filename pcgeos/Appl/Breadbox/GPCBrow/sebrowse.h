/* sebrowse.h
 */

/* (c) COPYRIGHT 1993-98           NOMBAS, INC.
 *                                 64 SALEM ST.
 *                                 MEDFORD, MA 02155  USA
 * 
 * ALL RIGHTS RESERVED
 * 
 * This software is the property of Nombas, Inc. and is furnished under
 * license by Nombas, Inc.; this software may be used only in accordance
 * with the terms of said license.  This copyright notice may not be removed,
 * modified or obliterated without the prior written permission of Nombas, Inc.
 * 
 * This software is a Trade Secret of Nombas, Inc.
 * 
 * This software may not be copied, transmitted, provided to or otherwise made
 * available to any other person, company, corporation or other entity except
 * as specified in the terms of said license.
 * 
 * No right, title, ownership or other interest in the software is hereby
 * granted or transferred.
 * 
 * The information contained herein is subject to change without notice and
 * should not be construed as a commitment by Nombas, Inc.
 */

/*
 * Written 12/02/97 - 12/08/97  Richard Robinson
 *         12/19/98             Richard Robinson, updated to C
 *         10/23/98 - 11/05/98  Richard Robinson, rewrite
 *                                 (with interruption for vacation)
 *
 * This file's comments contain a lot of information, please
 * read them as well as those in sebrowse.c. The bottom of
 * the file has a description of the routines that are provided
 * to do 'standard' browser things.
 *
 * NOTE: This library is not based on the DOM as defined by W3C because this
 * was created before that document, and it is not clear that any widely-
 * adopted browsers are using that model.  Future versions may want to work
 * with or implement that model as defined at:
 * http://www.w3.org/TR/REC-DOM-Level-1/ecma-script-language-binding.html
 */

#if !defined(_SEBROWSE_H) && defined(JSE_BROWSEROBJECTS)
#define _SEBROWSE_H
#ifdef __cplusplus
   extern "C" {
#endif

void InitializeInternalLib_BrowserLib(jseContext jsecontext);

/* ---------------------------------------------------------------------- */

/* Used to store information on a plugin. When calling the API to add the
 * plugins to the Javascript code, you may chain multiple plugins togethor
 * for a single call, or you may call the routine multiple times. Once
 * the routine returns, the plugin structure is no longer needed.
 */

struct BrowserPlugin {
  struct BrowserPlugin *next;

  jsecharptr description;
  jsecharptr filename;
  jsecharptr name;

  struct BrowserMimeType *types;       /* a linked list of all supported types */
};


/* You may use this like plugins - i.e. use the 'next' field for one
 * chained call, or call a bunch of times.
 */

struct BrowserMimeType {
  struct BrowserMimeType *next;

  jsecharptr description;
  jsecharptr suffixes;
  jsecharptr type;
};


/* NOTE: when your routines are called back, a pointer to a structure called
 *       BrowserWindow is used. This structure is a magic cookie, and you
 *       should pass a pointer (casted to struct BrowserWindow *) to whatever
 *       internal data structure you use to keep track of the windows.
 *
 *       BrowserLocation and BrowserDocument are handled similarly - you return
 *       a magic cookie when asked for, and know how to use it to retrieve
 *       information about the state of your browser.
 *
 *
 *       The caching information from the previous version is no longer
 *       applicable; the engine stores a tree of all the browser-related
 *       information rather than dynamically looking up the information each
 *       time it is accessed. Whenever the script changes the information
 *       in the tree, a corresponding routine is called to tell your browser
 *       about it. If your browser changes something that the script should
 *       know about, you must call the corresponding browserUpdate() routine
 *       to tell that section of the tree to do its updates. See the comments
 *       in sebrowse.c for information on how you go about doing this.
 */

struct BrowserWindow {int x;};   /* optr to URLFrame */
struct BrowserLinksArray {int x;};  /* reference to links array in URLText */
struct BrowserLocation {int x;}; /* optr to URLFrame or reference to link in URLText */
struct BrowserDocument {int x;}; /* optr to URLFrame */
struct BrowserFormsArray { int x;};  /* reference to forms array in URLText */
struct BrowserForm {int x;};     /* reference to form array element in URLText */
struct BrowserTimeout {int x;};
struct BrowserImagesArray { int x;};  /* reference to images array in URLText */
struct BrowserImage {int x;};    /* reference to image array element in URLText */
struct BrowserElement {int x;};  /* reference to form array element in URLText */


/* This version of the library is only usable if one thread at a time is
 * running Javascript. This is the case for all of our customers to date.
 * This allowed many optimizations to be made. You can use our code in
 * multiple threads, but each must have its own context with its own
 * separate window hierarchy and the two threads will be completely
 * independent.
 */

/* ---------------------------------------------------------------------- */

/* This is the structure used to pass information back and forth
 * about URLs. The given strings must be valid when the structure is returned,
 * but they do not hang around long - if you want to do something more than
 * read them (such as save the pointers) then you must make a copy.
 */
struct BrowserURLContents {
  NameToken protocol;
  NameToken hostname;
  NameToken port;       /* usually "", but could be "1080" for example - NOT NULL! */
  NameToken pathname;
  NameToken search;
  NameToken hash;

  NameToken target;     /* For links, for locations make it NULL. */

  NameToken host;       /* the host/port, again for convenience only when reading */
  NameToken href;       /* the whole formatted href. This is only used
                         * when reading the URL - when writing it is ignored
                         * in favor of the specific fields.
                         */
};


struct BrowserImageContents
{
  uint border;
  jsebool complete;
  uint height;
  uint hspace;
  NameToken lowsrc;
  NameToken name;
  NameToken src;
  uint vspace;
  uint width;
};


struct BrowserFormContents {
   NameToken action;
   NameToken encoding;
   NameToken method;
   NameToken target;

   NameToken name;  /* the name for it to be given as in 'documents.name' */
};


/* Note: elements are all different based on what kind of element it is.
 *       it is the browser's job to make this distinction. For the element
 *       methods, simply don't do anything if the method does not apply.
 *       For the element properties, each property has a corresponding
 *       boolean indicating if that property applies. If set False,
 *       that property will not be used for this element.
 */
struct BrowserElementContents {
   jsebool checked;                jsebool checked_used;
   jsebool defaultChecked;         jsebool dc_used;
   NameToken defaultValue;         jsebool dv_used;
   ulong num_options;              jsebool options_used;
   ulong selectedIndex;            jsebool si_used;
   NameToken value;                jsebool value_used;
   
   /* all elements must have a type string */
   NameToken type;

   NameToken name; /* the name for the elements to be given in 'document' */
};


struct BrowserOptionContents {
  jsebool defaultSelected;
  uint index;
  jsebool selected;
  NameToken text;
  NameToken value;
};


/* ----------------------------------------------------------------------
 * The following functions you must provide! Each should be pretty
 * self-explanatory. Each function maps to some aspect of item in
 * question. To get more information about each item, the reference I
 * use is "Javascript: The Definitive Guide 2nd edition." It has an
 * alphabetical reference to all the browser objects in it which you
 * can use to see what these routines will be trying to do.
 *
 * Like all information passed both ways, any strings are copied
 * immediately if needed, so you can pass a pointer to some internal
 * string secure in the knowledge that by the time any code in your
 * browser is again called, that string pointer can be freed if needed.
 * ---------------------------------------------------------------------- */

/* Return the top (active) window. */
struct BrowserWindow *browserGetTopWindow(jseContext jsecontext,
                                          struct BrowserWindow *current_window);


/* Return the parent of this window, or NULL if this is a top-level window. */
struct BrowserWindow *browserGetParentWindow(jseContext jsecontext,
                                             struct BrowserWindow *current_window);



/* Return the window that called 'open()' to open this window, or NULL if
 * none did (this is the only window for example.)
 */
struct BrowserWindow *browserGetOpenerWindow(jseContext jsecontext,
                                             struct BrowserWindow *current_window);


/* Return the window's name */
NameToken browserGetNameOfWindow(jseContext jsecontext,
                                 struct BrowserWindow *current_window);


/* Get the default value of the status line for this window */
NameToken browserGetDefaultStatus(jseContext jsecontext,
                                  struct BrowserWindow *current_window);


/* Set the default value of the status line for this window */
void browserSetDefaultStatus(jseContext jsecontext,
                             struct BrowserWindow *current_window,
                             const jsecharptr text);


/* Get the current value of the status line for this window. */
NameToken browserGetStatus(jseContext jsecontext,
                           struct BrowserWindow *current_window);


/* Set the current value of the status line for this window */
void browserSetStatus(jseContext jsecontext,
                      struct BrowserWindow *current_window,
                      const jsecharptr text);



/*
 * build complete frame list within one HTML file,
 * using depth-first search
 */
void browserGetFrameList(jseContext jsecontext,
			 struct BrowserWindow *parent,
			 optr *list);


/* Return the location magic cookie for this window */
struct BrowserLocation *browserGetLocation(jseContext jsecontext,
                                           struct BrowserWindow *current_window);


/* Return the document magic cookie for this window */
struct BrowserDocument *browserGetDocument(jseContext jsecontext,
                                           struct BrowserWindow *current_window);


/* Display an alert and return - the alert should be non-modal (i.e. return
 * immediately while the alert is displayed in the background.)
 */
void browserDisplayAlertDialog(jseContext jsecontext,
                               struct BrowserWindow *current_window,
                               const jsecharptr msg);


/* Display an alert with 'OK' and 'CANCEL' buttons and wait for a response
 * (i.e. it should be modal.) Return a boolean indicating whether 'OK'
 * was selected.
 */
jsebool browserDisplayQuestionDialog(jseContext jsecontext,
                                     struct BrowserWindow *current_window,
                                     const jsecharptr msg);


/* Make the given window lose the keyboard focus. If the window is a frame,
 * then give keyboard focus to the top level window containing the frame,
 * otherwise cycle the window to the bottom of the window stack.
 */
void browserBlurWindow(jseContext jsecontext,
                       struct BrowserWindow *current_window);


/* Give the keyboard focus to the given window. */
void browserGiveFocusToWindow(jseContext jsecontext,
                              struct BrowserWindow *current_window);


/* Opens a new window and returns a handle to it. The url will always
 * be a string, but it may be blank (i.e. ""). The name and features arguments
 * will be NULL if not included. 'replace' defaults to False. Look up the
 * expected behavior in a Javascript book, as it is complex and lengthy.
 *
 * At some point, you will need to call browserInitWindow() on the given
 * magic cookie if this is a new window (and not a reference to an
 * existing window.)
 */
struct BrowserWindow *browserOpenWindow(jseContext jsecontext,
                                        struct BrowserWindow *opener,
                                        const jsecharptr url,
                                        const jsecharptr name,
                                        const jsecharptr features,
                                        jsebool replace,
					jsebool force);


NameToken browserWindowPrompt(
                        jseContext jsecontext,
                        struct BrowserWindow *win,
                        const jsecharptr msg,
                        const jsecharptr def,
                        Boolean *didCancel) ;

/* Close the given window. In Netscape, only windows opened via Javascript
 * can be closed in this manner, and you may want to make the same rule.
 * Even though the window is closed, the magic cookie 'current_window' cannot
 * be discarded, but should be marked as 'closed'. These magic cookies
 * must remain until the browser exits.
 */
void browserCloseWindow(jseContext jsecontext,
                        struct BrowserWindow *current_window);


/* This returns whether or not the given window has been closed. */
jsebool browserIsWindowClosed(jseContext jsecontext,
                              struct BrowserWindow *current_window);


/* Scroll the given window to the given location. The coordinate system
 * is undefined (most likely in pixels), but 0,0 is the top-left corner.
 * Note that the given location is absolute, not relative.
 */
void browserScrollWindow(jseContext jsecontext,
                         struct BrowserWindow *current_window,
                         ulong x, ulong y);


/* Move the given window to the given absolute location.
 */
void browserMoveWindowAbs(jseContext jsecontext,
			  struct BrowserWindow *current_window,
                          ulong x, ulong y);


/* Move the given window to the relative location.
 */
void browserMoveWindowRel(jseContext jsecontext,
			  struct BrowserWindow *current_window,
			  ulong x, ulong y);


/* Like typing in a new URL in the window's URL entry field. If replace is TRUE,
 * then replace the history with the new document rather than appending it.
 */
void browserGotoURL(jseContext jsecontext,
                    struct BrowserLocation *location,
                    const jsecharptr url_text,
                    jsebool replace);


/* Cause the given location to be reloaded, if it has been modified
 * since last load. If the 'force' boolean is true, reload it regardless.
 * The thisvar parameter has been passed as the last variable so you can
 * easily call browserUpdate() on it if necessary.
 */
void browserReloadLocation(jseContext jsecontext,
                           struct BrowserLocation *location,
                           jsebool force,
                           jseVariable thisvar);


/* Shortcut if only the URL itself is requested */
NameToken browserGetURL(jseContext jsecontext,
                        struct BrowserLocation *location,
                        NameToken *target);

/* Fill in the URL structure with the values for the given location */
void browserGetLocationValue(jseContext jsecontext,
                             struct BrowserLocation *location,
                             struct BrowserURLContents *fill_me_in);


void browserSetLocationURL(jseContext jsecontext,
			   struct BrowserLocation *location,
			   const jsecharptr url_text,
			   const jsecharptr target_text,
			   jsebool replace);

/* Change the given location to the values in the structure. This really
 * means change the location, so for example if the 'location' magic cookie
 * represents the window's current URL, the window must be updated to point
 * at the new URL. If the location is for a link, do what is appropriate.
 */
void browserSetLocationValue(jseContext jsecontext,
                             struct BrowserLocation *location,
                             struct BrowserURLContents *fill_me_in);


/* Get the number of entries in the given window's history list. */
ulong browserGetHistoryLength(jseContext jsecontext,
                              struct BrowserWindow *current_window);


/* Get a history item */
NameToken browserGetHistoryItem(jseContext jsecontext,
                                struct BrowserWindow *current_window,
                                ulong itemnum);


/* Go to a location relative to the current one. The offset species the location.
 * offset of '-1' means go back one, '1' means forward one, etc.
 */
void browserHistoryGo(jseContext jsecontext,
                      struct BrowserWindow *current_window,
                      long offset);


/* Fill in the Image structure with the information about the given image
 * magic cookie. If the value is NULL, fill it whatever 'default' values you
 * like (this will be for a new Image().)
 */
void browserGetImage(jseContext jsecontext,
                     struct BrowserImage *image,
                     struct BrowserImageContents *fill_in);


/* Update using the Image structure with the information about the given image
 * magic cookie. If the cookie is NULL, it is an image not attached to anything
 * and generated via new Image(), probably trying to point to some image to get
 * it preloaded.
 */
void browserSetImage(jseContext jsecontext,
                     struct BrowserImage *image,
                     struct BrowserImageContents *update_to_match);

/* ---------------------------------------------------------------------- */


enum DocumentColors {
  AlinkColor,
  LinkColor,
  VlinkColor,
  BgColor,
  FgColor
};


/* Sets one of the document color properties. See a Javascript book for
 * documentation on the format of the 'color_value' string - you can
 * actually implement it any way you like, as this value is just passed along.
 */
void browserSetDocumentColor(jseContext jsecontext,
                             struct BrowserDocument *document,
                             enum DocumentColors color,
                             const jsecharptr color_value);


/* Gets one of the document color properties */
NameToken browserGetDocumentColor(jseContext jsecontext,
                                  struct BrowserDocument *document,
                                  enum DocumentColors color);


/* Opens the document so to write new contents to it, erasing any old
 * contents.
 */
void browserOpenDocument(jseContext jsecontext,
                         struct BrowserDocument *document,
                         const jsecharptr mimetype);


/* Writes some text to the document. If the document is not open,
 * implictly do an open for "text/html".
 */
void browserDocumentWrite(jseContext jsecontext,
                          struct BrowserDocument *document,
                          const jsecharptr text);


/* An open document is an output stream for text. When it is closed,
 * all the text has been output and it can be displayed.
 */
void browserCloseDocument(jseContext jsecontext,
                          struct BrowserDocument *document);


/* Gets the values of the cookies for this document in the form
 * "name=value;name=value;..."
 */
NameToken browserGetCookie(jseContext jsecontext,
                           struct BrowserDocument *document);


/* Sets the cookie value by adding a single "name=value" item which must
 * be integrated into the cookie list. It can have an 'expires' clause,
 * 'path' clause, 'domain' clause, and 'secure' clause.
 */
void browserSetCookie(jseContext jsecontext,
                           struct BrowserDocument *document,
                           const jsecharptr cookie);


/* Returns a text string which is the date of the last modified field
 * or Jan 1st, 1970 (midnight) if none. The date should be in the format:
 *
 * 'Wed Dec 3 12:46:52 1997'
 */
NameToken browserGetLastModified(jseContext jsecontext,
                                 struct BrowserDocument *document);


/* Return the location magic cookie for this document */
struct BrowserLocation *browserGetDocumentLocation(jseContext jsecontext,
                                                   struct BrowserDocument *document);


/* Get a string representing the complete URL of the referring document,
 * or the empty string if none.
 */
NameToken browserGetReferrer(jseContext jsecontext,
                             struct BrowserDocument *document);


/* Get a string representing the title of the document. */
NameToken browserGetTitle(jseContext jsecontext,
                          struct BrowserDocument *document);


/* Reset all the fields of the form. */
void browserFormReset(jseContext jsecontext,
                      struct BrowserForm *form);


/* Submit the form. */
void browserFormSubmit(jseContext jsecontext,
                       struct BrowserForm *form);


/* Fill in the Form structure with the values from this form. */
void browserGetForm(jseContext jsecontext,
                    struct BrowserForm *form,
                    struct BrowserFormContents *fill_in);


/* Update the form with any changes in the Form structure. */
void browserSetForm(jseContext jsecontext,
                    struct BrowserForm *form,
                    struct BrowserFormContents *read_changes_from);


/* Fills in an Element structure based on the element. */
void browserGetElement(jseContext jsecontext,
                       struct BrowserElement *elem,
                       struct BrowserElementContents *fill_in);

/* Gets the next element with the same name, if any */
struct BrowserElement *browserNextArrayElement(jseContext jsecontext,
                                               struct BrowserElement *elem);

/* Updates the element */
void browserSetElement(jseContext jsecontext,
                       struct BrowserElement *elem,
                       struct BrowserElementContents *fill_in);


/* Standard element actions */
void browserElementBlur(jseContext jsecontext,
                        struct BrowserElement *elem);
void browserElementClick(jseContext jsecontext,
                         struct BrowserElement *elem);
void browserElementFocus(jseContext jsecontext,
                         struct BrowserElement *elem);
void browserElementSelect(jseContext jsecontext,
                          struct BrowserElement *elem);


/* Read the state of an option of an element (only applies to
 * select elements.)
 */
void browserGetElementOption(jseContext jsecontext,
                             struct BrowserElement *elem,
                             ulong index,
                             struct BrowserOptionContents *fill_in,
			     Boolean removeFromHeap);


/* Set the state of an option of an element (only applies to
 * select elements.) Note that if the Option's index is one past
 * the end of the array, a new options is being added and you
 * must allow that to work.
 */
void browserSetElementOption(jseContext jsecontext,
                             struct BrowserElement *elem,
                             struct BrowserOptionContents *fill_in);

/* Add (or update) new option to select list */
struct BrowserElement *browserAssignElementOption(jseContext jsecontext,
						  struct BrowserElement *parent,
						  struct BrowserOptionContents *opt);

/* Remove option from select list */
void browserRemoveElementOption(jseContext jsecontext,
				struct BrowserElement *parent,
				word index);

/* ---------------------------------------------------------------------- */


/* You must handle timeouts. After the specified time has gone by, run
 * the Javascript code. You could run it in a new context (but with the
 * same current window) or you could run it in the original context
 * (but then you must wait for any currently executing code to finish.)
 */

/* Register some code to be called within the context of the given
 * window in a given number of milliseconds. The return is a magic handle
 * that can be used to cancel the timeout code. The code is to be executed
 * once when the timeout goes off.
 */
struct BrowserTimeout *browserSetTimeout(jseContext jsecontext,
                                         struct BrowserWindow *current_window,
                                         const jsecharptr js_code,
                                         ulong timeout_in_millisecs);


/* Clear a previously-set timeout if possible. */
void browserClearTimeout(jseContext jsecontext,
                         struct BrowserWindow *current_window,
                         struct BrowserTimeout *tm);

struct BrowserTimeout *browserSetInterval(jseContext jsecontext,
                                         struct BrowserWindow *current_window,
                                         const jsecharptr js_code,
                                         ulong timeout_in_millisecs);

void browserClearInterval(jseContext jsecontext,
                         struct BrowserWindow *current_window,
                         struct BrowserTimeout *tm);


/* ---------------------------------------------------------------------- */

/* Get number of frames.
 */
ulong browserGetFramesLength(jseContext jsecontext,
			     struct BrowserWindow *frameArray);

/* Get magic cookie for frame array item.
 */
struct BrowserWindow *browserGetFrameItem(jseContext jsecontext,
					  struct BrowserWindow *frameArray,
					  ulong index);

/* Get magic cookie for frame array item from name.
 */
struct BrowserWindow *browserGetFrameItemFromName(jseContext jsecontext,
						  struct BrowserWindow *frameArray,
						  const jsecharptr name);

/* Get magic cookie for link array.
 */
struct BrowserLinksArray *browserGetLinksArray(jseContext jsecontext,
					       struct BrowserDocument *doc);

/* Get magic cookie for link array item.
 */
struct BrowserLocation *browserGetLinkItem(jseContext jsecontext,
					   struct BrowserLinksArray *links,
					   ulong index);

/* Get magic cookie for link array item from name.
 */
struct BrowserLocation *browserGetLinkItemFromName(jseContext jsecontext,
						   struct BrowserLinksArray *links,
						   const jsecharptr name);

/* Get number of links.
 */
ulong browserGetLinksLength(jseContext jsecontext,
			    struct BrowserLinksArray *links);


/* Get magic cookie for form array.
 */
struct BrowserFormsArray *browserGetFormsArray(jseContext jsecontext,
					       struct BrowserDocument *doc);

/* Get magic cookie for form array item.
 */
struct BrowserForm *browserGetFormItem(jseContext jsecontext,
				       struct BrowserFormsArray *forms,
				       ulong index);

/* Get magic cookie for form array item from name.
 */
struct BrowserForm *browserGetFormItemFromName(jseContext jsecontext,
					       struct BrowserFormsArray *forms,
					       const jsecharptr name);

/* Get number of forms.
 */
ulong browserGetFormsLength(jseContext jsecontext,
			    struct BrowserFormsArray *forms);

/* Get magic cookie for window containing specified form.
 */
struct BrowserWindow *browserGetFormWindow(jseContext jsecontext,
					   struct BrowserForm *bf);


/* Get magic cookie for image array.
 */
struct BrowserImagesArray *browserGetImagesArray(jseContext jsecontext,
						 struct BrowserDocument *doc);

/* Get magic cookie for image array item.
 */
struct BrowserImage *browserGetImageItem(jseContext jsecontext,
					 struct BrowserImagesArray *images,
					 ulong index);

/* Get magic cookie for image array item from name.
 */
struct BrowserImage *browserGetImageItemFromName(jseContext jsecontext,
						 struct BrowserImagesArray *images,
						 const jsecharptr name);

/* Get number of images.
 */
ulong browserGetImagesLength(jseContext jsecontext,
			     struct BrowserImagesArray *images);

/* Get magic cookie for window containing specified image.
 */
struct BrowserWindow *browserGetImageWindow(jseContext jsecontext,
					   struct BrowserImage *bi);


/* Get magic cookie for element array item.
 */
struct BrowserElement *browserGetElementItem(jseContext jsecontext,
					     struct BrowserForm *form,
					     ulong index);

/* Get magic cookie for element array item from name.
 */
struct BrowserElement *browserGetElementItemFromName(jseContext jsecontext,
						     struct BrowserForm *form,
						     const jsecharptr name);

/* Get number of elements.
 */
ulong browserGetElementsLength(jseContext jsecontext,
			       struct BrowserForm *form);

/* Get magic cookie for window containing specified element.
 */
struct BrowserWindow *browserGetElementWindow(jseContext jsecontext,
					      struct BrowserElement *be);

/* Get form number containing specified element.
 */
word browserGetElementForm(jseContext jsecontext,
			   struct BrowserElement *be);


/* Get magic cookie for option array item.
 */
Boolean browserGetOptionItem(jseContext jsecontext,
			     struct BrowserElement *elem,
			     ulong index);

/* Get number of options.
 */
ulong browserGetOptionsLength(jseContext jsecontext,
			      struct BrowserElement *elem);


/* ---------------------------------------------------------------------- */

/* routines provided for common Javascript operations. These routines
 * are built on top of the API, so you can do the work yourself if these
 * routines don't do it exactly as you'd like. Use the code for the
 * routines (found in sebrowse.c) to find out how you can do certain
 * things.
 *
 * As always, read the comments both in this file and in the sebrowse.c
 * file. At times, I try to merge the comments, but then no information
 * pops into my head as I am updating something, so it is to your benefit
 * to look in both places for useful information.
 */



/* Whenever a part of a window changes, you must have that and all of its
 * children rebuilt. To do this, every object 'node' has a 'browserUpdate()'
 * wrapper function (which is jseDontEnum, so it is hidden.) You should arrange
 * to call it. For instance, if the document in your window changed, you
 * would want to call 'document.browserUpdate().' You do this EXACTLY like
 * calling an event handler as described above. This means looking up
 * 'document' to get the 'this' variable and 'document.browserUpdate()'
 * to find the function to call then using jseCallFunction().
 *
 * Do not get too agressive with these changes. Its my thought that minor
 * changes are unlikely. What can the user really do? The user can change
 * what url a window has loaded meaning the whole window needs to be reloaded.
 * But can the user change the forms in a document once its loaded? Nope, the
 * script can, but nothing outside the script can. Thus, these update calls
 * should be rare. Note that if you update some element, its children are
 * assumed to be invalid and rebuilt. For instance, if you update a document,
 * the document's fields are reinitialized and any added variables are still
 * there (if you did 'document.foo = 10;' for instance). However, the old
 * element array is discarded and rebuilt from scratch. If you had done
 * 'document.elema.foo = 10;' that variable is now lost because even if
 * 'elema' still exists, it is thought to be a different elema.
 *
 * Because the document tree is stored as a normal Javascript object
 * hierarchy, you are free to manipulate it to do spot updates as you desire.
 * For instance, you can, using the API, lookup 'document.color' and
 * check its contents or change it. You can do this to update certain
 * minor things yourself.
 *
 * For your convenience, a browserUpdate() API call is provided. Pass the
 * jseVariable representing the item you want to update (for instance, use
 * the API to lookup 'document.forma.elemb' and then pass the result as
 * the variable to update. It will rebuild that item from scratch. As
 * described above, the item will have all its fields recomputed, but any
 * other properties remain. All children will be discarded and rebuilt so
 * other properties in the children are lost.
 */
void browserUpdate(jseContext jsecontext,jseVariable var_to_update);


/*
 * Each window needs to be initialized. A new object is associated with
 * that window internally and all necessary bookkeeping is handled
 * behind the scenes. This tells the browser library about your window.
 * It will use the handle to call many of the above routines to get all
 * the information on the state of your browser.
 */
void browserInitWindow(jseContext jsecontext,struct BrowserWindow *window);


/* interpret a <SCRIPT></SCRIPT> fragment. Use this function to do a stock
 * interpret of a script in a particular window. The return is NULL if there
 * was some error, else it is a variable that was the result of the script
 * and must be destroyed with jseDestroyVariable().
 */
jseVariable browserInterpret(jseContext jsecontext,struct BrowserWindow *window,
                             const jsecharptr txt);


/* Handling event handlers functions. First, you must define such a function
 * by giving the name of the event handle ("onClick" or whatever), the
 * text of the function "var a = 10;" and the jseVariable to associate it
 * with (for instance, the element object that it is a handler for.) You look
 * it up originally in the same way you look it up to call it, described next.
 *
 * Later, to call the wrapper function, you look it up and call jseCallFunction().
 * For instance, if it was 'document.forma.elemb.onClick()', you would use
 * the standard jseMember() et all functions to look up 'document' in the
 * window object, then look up 'forma' in that result, then 'elemb' in that
 * result. Now you have the value that should be passed as the 'this' variable.
 * Finally, you look up 'onClick()' in that result to get the variable that
 * is the function to call.
 *
 * The function to add such a event handler returns the jseVariable associated
 * with the function, which you DON'T free and is valid until you close the
 * window. You can save the two variables if you want to avoid doing a lookup
 * later, but the lookup isn't particularly slow and saves you from having
 * to have a parallel tree to store all this information in.
 */
   jseVariable
browserEventHandler(jseContext jsecontext,
                    struct BrowserWindow *window,
                    const jsecharptr eventname,
                    const jsecharptr event_source_txt,
                    jseVariable container);

   void
browserCallFunction(jseContext jsecontext,jseVariable jsefunction,jseStack jsestack,jseVariable *returnVar,jseVariable thisVar,struct BrowserWindow *window);


/* Indicates the given window no longer exists. This will complete get rid
 * of the window, erasing all Javascript information about it. If the window
 * is still being used by a script (perhaps assigned to a variable), that will
 * hold the window in memory until that reference disappears. Otherwise the
 * script in question would crash.
 */
void browserTermWindow(jseContext jsecontext,struct BrowserWindow *window);


void browserSetWindow(jseContext jsecontext,struct BrowserWindow *window);
void browserCleanup(jseContext jsecontext);

      
void browserGeneralInfo(jseContext jsecontext,const jsecharptr appCodeName,const jsecharptr appName,
                        const jsecharptr appVersion,const jsecharptr platform,
			const jsecharptr language,jsebool javaEnabled);
void browserAddPlugin(jseContext jsecontext,struct BrowserPlugin *plugin);
void browserAddMimeType(jseContext jsecontext,struct BrowserMimeType *type);

#ifdef __cplusplus
}
#endif
#endif
