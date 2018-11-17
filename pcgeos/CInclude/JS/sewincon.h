/* sewincon.h  Classes needed to manage the Windows display
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

#if ( defined(__JSE_WIN16__) || defined(__JSE_WIN32__) ) \
 && !defined(_SEWINCON_H)
#define _SEWINCON_H
#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/* unused  extern VAR_DATA(uint) gInstanceCount; */ /* how many instances of this program are running? */

#  if defined(JSE_WINDOW)

#     if defined(__JSE_WINCE__)
#        define KEYBOARD_BUFFER_MAX   500
#     elif defined(__JSE_WIN16__)
#        define KEYBOARD_BUFFER_MAX   1000
#     else
#        define KEYBOARD_BUFFER_MAX   5000
#     endif

      /*class SubClassedWindows;
       *class ToolkitAppData;
       *struct _EXTENSION_CONTROL_BLOCK;
       */

      struct jseMainWindow {
         jsechar jseClassName[3/*jse*/+8/*instance*/+1/*NULL*/];
#        if defined(JSE_WIN_SUBCLASSWINDOW)
            FARPROC SubclassProcInstance; /* our subclass for predefined classes */
            struct SubClassedWindows * SubclassedWindowList;
#        endif

#        if !defined(__CGI__)
            sword16 KeyboardBuffer[KEYBOARD_BUFFER_MAX];
            int KeysInKeyboardBuffer;
            sword16 MyFGetCLookahead;
#        endif

         HBRUSH hBrush;
         COLORREF Foreground, Background; /* text and background drawing colors */

         HWND   hWindow;
         HINSTANCE hInstance;
         void _FAR_ *appData;

         uint SubTitleDepth;

#        if !defined(__CGI__)
            int painted;
            int cxWindow,cyWindow;
            int cxChar, cyChar;
            int cxClient, cyClient;
            int scrWidth, scrHeight;
            int MaxNumLines, NumLines;
            int CursorCol, CursorRow;
            int nVscrollMax, nHscrollMax;
            int nVscrollPos, nHscrollPos;
            jsebool ScrolledToBottom;
            jsecharptr *Data;

            /* selected text */
            jsebool Selected;   /* true if any text is selected */
            RECT SelectedRect;
            jsebool Selecting;  /* true while selecting text */
            POINT SelectingStart, SelectingRecent;  /* where started, and most recent selected point */

            jsebool CapturedMouse;   /* true if we're capturing the mouse */
            int SelectTextTimerCol, SelectTextTimerRow;

            HFONT hFont;               /* font selected if not UsingSystemFont; if NULL then */
                                       /* using system font */
            LOGFONT LogicalFont;       /* save characteristics of current logical font */
            /* HBRUSH hBrush; */
            /* COLORREF Foreground, Background; text and background drawing colors */
            int tmInternalLeading; /* extra space at top of font to be ignored */

            jsebool DisplayedAlready;
            jsebool AlreadyWritingToStdOut;

#        endif  /* !defined(__CGI__) */
#        if defined(__CENVI__) && !defined(__CGI__)
            jsecharptr MarqueeMessage; /* NULL if no marquee message */
#        endif
      };

      struct jseMainWindow * NEAR_CALL jsemainwindowNew(void _FAR_ *appData,HINSTANCE hInstance,
                                                        jsecharptr ClassName);
      void NEAR_CALL jsemainwindowDelete(struct jseMainWindow *This); /* these two were private members */
      jsebool NEAR_CALL jsemainwindowWriteToWindow(struct jseMainWindow *This,
                                                   const jsecharptr buffer);
      WINDOWS_CALLBACK_FUNCTION(long) jsemainwindowMainWindowProcedure(HWND hwnd,UINT message,WPARAM wParam,LPARAM lParam);
      void jsemainwindowWinSetScreenSize(struct jseMainWindow *This,uint width,uint height);
      void jsemainwindowWinSetRowMemory(struct jseMainWindow *This,uint RowsRemembered);
      void jsemainwindowWinGetScreenSize(struct jseMainWindow *This,uint *width,uint *height);
      void jsemainwindowWinScreenClear(struct jseMainWindow *This);
      void jsemainwindowWinGetCursorPosition(struct jseMainWindow *This,uint *col,uint *row);
      void jsemainwindowWinSetCursorPosition(struct jseMainWindow *This,uint col,uint row);
      void NEAR_CALL jsemainwindowRegisterDefaultChildWindow(struct jseMainWindow *This);
         /* register if not already registered */
      void NEAR_CALL jsemainwindowMakeDefaultProcInstance(struct jseMainWindow *This);
         /* make subclass procedure if not already made */

#     if defined(__JSE_WIN16__)
         extern VAR_DATA(uint) jsemainwindowCallbackDepth;
         /* 0 if not in a callback routine, else increments;
          * VARIABLE_DATA(uint) jseMainWindow::CallbackDepth = 0;
          * variable_data ok because only used in win16
          */
#     endif

#     if !defined(__CGI__)
         void NEAR_CALL jsemainwindowMouseCapture(struct jseMainWindow *This,
            jsebool set/*else release*/);  /* OK to call to release if not captured */
#     endif

      void jsemainwindowUnRegisterDefaultChildWindowForever(struct jseMainWindow *This);
      void jsemainwindowFreeDefaultProcInstanceForever(struct jseMainWindow *This);

#     define SUSPEND_TIMER_ID  678

#     if defined(JSE_SCREEN_SETFOREGROUND)
         jseLibFunc(ScreenSetForegrnd);
#     endif
#     if defined(JSE_SCREEN_SETBACKGROUND)
         jseLibFunc(ScreenSetBackgrnd);
#     endif

#  endif /* defined(JSE_WINDOW) */

#  if defined(JSE_WIN_SUBCLASSWINDOW)
      extern WINDOWS_CALLBACK_FUNCTION(long) SubclassedWindowProcedure(HWND hwnd,UINT message,WPARAM wParam,LPARAM lParam);
#  endif

#ifdef __cplusplus
}
#endif /* __cplusplus */
#endif
