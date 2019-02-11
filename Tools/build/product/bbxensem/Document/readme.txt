
     ***************************************************
     *                                                 *
     *                 E N S E M B L E                 *
     *        I N S T A L L A T I O N   H E L P        *
     *                                                 *
     ***************************************************

        You must have DOS version 3.0 or newer, OS/2
       version 2.0 or newer, or Windows 95/98 or newer.

 You may want to print this document as a handy reference for
 installation and troubleshooting. See the instructions about
 printing in your computer's user manual.

 ********************************************************************
     TABLE OF CONTENTS
 ********************************************************************

 SECTION            TITLE

   1...............Checking your Hardware
   2...............Disk Space
   3...............Conventional Memory
   4...............Operating Systems
   5...............Previous Versions
   6...............Running Ensemble with DOS
   7...............Running Ensemble with Windows
   8...............If Ensemble does not work
   9...............Error Messages
  10...............Incomplete Installation


 ********************************************************************
     Section 1 -  Checking your hardware
 ********************************************************************

 1. Checking and Verifying your Hard Drive

   It's always a good idea to back up any important files on your
   system. Now would be an excellent time to remove any files that
   you no longer use. Also, you should run a diagnostic program such
   as CHKDSK or SCANDISK to make sure your hard drive is in good
   working order.

   For more information about these utilities, consult your DOS
   or Windows manual.

 2. DISK DRIVES

   With some computers, you may need to put disks in ALL available
   drives in order to proceed.

   If, after installation of Ensemble, you have difficulty reading
   any of your drives or if any phantom drives show up that do not
   exist, try editing the GEOS.INI file to tell the software the
   exact drive specifications. You can edit In the [system] section
   of the GEOS.INI file you could add the line:

      drive b = 0

   This tells the software to ignore drive b. Using the format

      drive <letter> = <number>

   you can use any of the following drive specifications

      0       =>      Ignore the drive
      360     =>      360K Low Density 5.25" floppy disk
      720     =>      720K Low Density 3.5" floppy disk
      1200    =>      1.2Mb High Density 5.25" floppy disk
      1440    =>      1.44Mb High Density 3.5" floppy disk
      2880    =>      2.88Mb 3.5" floppy disk
      65535   =>      Hard drive

   If trouble reading, copying, or formatting diskettes persists,
   try putting the line

      waitpost = false

   in the [system] section of the GEOS.INI file.

 ********************************************************************
     Section 2 -  Disk Space
 ********************************************************************

 The installation will not proceed normally if you do not have enough
 free disk space on your hard drive. You will need at least 15 MB
 (fifteen megabytes) of free disk space. If the installation fails,
 check to see how much space you have left on your hard drive by
 entering the following command at a DOS prompt:

      DIR     <ENTER>

 At the end of the list of files you will see the number of bytes
 free on the hard drive.

 ********************************************************************
     Section 3 -  Conventional Memory
 ********************************************************************

 If you get the error "Not enough memory to install" or if the
 installation procedure fails before it can copy any files to your
 hard drive, you may not have enough free conventional memory to run
 the installer. The installer requires approximately 520K of free
 conventional memory. Try removing any unnecessary TSRs and device
 drivers from your CONFIG.SYS and AUTOEXEC.BAT files, or boot your
 computer from a system diskette to free more conventional memory.

 ********************************************************************
     Section 4 -  Operating Systems
 ********************************************************************

 Your computer must have one of the following disk operating
 systems installed before you can install Ensemble:

      - MS-DOS 3.3 or later
      - PC-DOS 3.3 or later
      - DR-DOS 5.0 or later
      - Caldera Open DOS
      - Novell DOS 7
      - Datalight ROM DOS 5.0 or later
      - Windows 95
      - Windows 98
      - Windows ME
      - Windows NT*
      - Windows 2000*
      - Windows XP*
      - OS/2 version 3 or later*
      - Linux with a DOS emulator (for example, DosEMU)*

     *Note: Certain features of Ensemble, like sound support, may
      not be available when using the disk operating systems
      marked with an asterisk, because these disk operating 
      systems can prevent Ensemble from accessing some hardware 
      devices on the computer.


 ********************************************************************
     Section 5 -  Previous Versions
 ********************************************************************

 1. DOCUMENTS FROM PREVIOUS VERSIONS

   Documents and fonts from previous versions of the software may
   be used with this software. Applications that work with previous
   versions of Ensemble or with Geoworks Ensemble 2.0 or NDO98/2000
   should work with this version.

 2. INSTALLING OVER PREVIOUS VERSIONS

   DO NOT install this over a previous version. Install this
   version in its own new directory. Once you have Ensemble up
   and running you may move or copy files from earlier versions
   as described below.

 3. TRANSFERRING EARLIER FILES TO ENSEMBLE

   You may move or copy all of your previous documents from the
   Document folder of an earlier version to Ensemble's Document
   folder.  If you have Breadbox add on packages or third party
   programs, we recommend that you install them into Ensemble from
   their original install disks, since it may not be obvious what
   files these programs may use in addition to the main program
   that shows up as an icon in the World folder.

 ********************************************************************
     Section 6 -  Running Ensemble with DOS
 ********************************************************************

 1. HOW TO RUN ENSEMBLE

   The program is in a directory called Ensemble and the command to
   start the program is Ensemble or Ensemble. Therefore to start
   software from the C:\ prompt (which is your hard disk drive)
   type:
                C:                    [ENTER]
                CD\Ensemble           [ENTER]
                Ensemble              [ENTER]

 2. DOS PATH

   The install program will check your AUTOEXEC.BAT to determine if
   the Ensemble directory needs to be placed in the path. If the
   installation modifies your AUTOEXEC.BAT, you will need to reboot
   your computer after the installation for the changes to take
   effect.

 3. NOVELL NETWORK

   If you are connected to a NOVELL network, you may need to create a
   SHELL.CFG file in the root directory of C: drive. To create the
   file, enter the following command at the DOS prompt:

              echo file handles = 100 > shell.cfg
              (then hit the enter key)

   "file handles = 100" will be the only line in the file.

 ********************************************************************
     Section 7 -  Running Ensemble with Windows
 ********************************************************************

  1. RUNNING ENSEMBLE WITH WINDOWS FOR WORKGROUPS (v3.11)

   If you wish to run the software from Windows for Workgroups 3.11,
   you must disable 32-bit file access. Here are the easy steps to
   disable 32-bit file access:
     A. Double Click on Control Panel
     B. Double Click on Enhanced
     C. Double Click on Virtual Memory
     D. Uncheck the box for 32-Bit File Access

 2. CREATING A SHORTCUT IN WINDOWS 95 (or later) FOR ENSEMBLE

   A shortcut can be created within Windows by following the steps
   for your Windows version.  The file that Windows needs to run
   is LOADER.EXE in your Ensemble directory.  We have provided an
   icon for Windows to use - GWICON.ICO in the same directory.

 3. ENSEMBLE RUNNING UNDER WINDOWS 95, 98, ME

    1. Right click the shortcut (icon) you use to run Ensemble and
       choose Properties from the menu.
    2. On the Program tab, check the Cmd line and Working boxes
       to make sure they name the drive and folder where
       Ensemble is installed (usually C:\Ensemble).
    3. Make sure a check mark appears next to
       [X] Close on exit.
    4. In Windows 95 or 98, click the Advanced button and 
       clear the check boxes for all three options:
       [ ] Prevent MS-DOS Based programs from detecting Windows
       [ ] Suggest MS-DOS Mode as necessary
       [ ] MS-DOS mode
       In Windows ME, clear the check box for the first 
       option only.
    5. On the Screen tab, set Screen Usage to Full-screen:
       [X] Full-screen
       [ ] Window
    6. On the Misc tab, clear and check these options:
       [ ] Allow screen saver
       [X] Mouse exclusive mode
       For Windows shortcut keys, clear the check boxes for
       Alt+Esc, Ctrl+Esc, and Alt+Space. Leave the others selected.
    7. Click APPLY.

 4. ENSEMBLE RUNNING UNDER WINDOWS NT, 2000, XP

   While going through the install process you will be asked if you
   want to change the settings in your AUTOEXEC.BAT and/or
   CONFIG.SYS files.  Say "No" to both.  You will change your
   CONFIG.NT file in step 5 below.

    1. Right click the shortcut you use to run Ensemble and choose
       Properties from the menu.
    2. On the Shortcut tab, check the Target and Start in
       boxes to make sure they name the drive and folder where
       Ensemble is installed (usually C:\Ensemble).
    3. In XP, on the Compatibility tab set Ensemble to run in 
       Windows 95 mode.
    4. Click APPLY.
    5. Using Windows Notepad or a text editor, examine your CONFIG.NT 
       file (usually located in C:\WINNT[or WINDOWS]\SYSTEM32).
       It should contain these settings:
         device=%SystemRoot%\system32\himem.sys
         dos=high, umb
         files=120
         ntcmdprompt
    NOTE: Ensemble will run only in full screen mode, and you may 
          need to adjust your Ensemble and/or your Windows screen 
          resolution and color depth to match.  In some cases
	  Ensemble may run in only 640x480 16 colors.  For more on
          running Enesmble in NT/2000/XP please the see the section
          in the Links area of the Breadbox web site (www.breadbox.com).

 5. PRINTING CONFLICTS AND WINDOWS 95 (or later)

   On some computers, Windows and Ensemble may both try to control
   the printer port. Some quick and easy solutions to this
   problem are as follows (use second or third solutions if the first 
   does not resolve the conflict):

   (from Ensemble)
     A. Run Preferences, Computer
     B. Change the setting for your LPT to "DOS"

   (Solution 2 - from Windows)
     A. Double Click on My Computer
     B. Double Click on Printer Folder
     C. Click on your printer icon
     D. Click on File, Click on Properties
     E. Click on the Details Tab
     F. Click on Spool Settings
     G. Change Spool option from Spool after first page is printed to
        Spool after last page is printed

   (Solution 3 - from Windows)
     A. Double Click on My Computer
     B. Double Click on Printer Folder
     C. Click on your printer icon
     D. Click on File, Click on Properties
     E. Click on the Details Tab
     F. Click on Port Settings
     G. Make sure the [ ] Spool MS-DOS print jobs is unchecked.


 6. MOUSE PROBLEMS WITH WINDOWS 95 (or later)

   Windows takes over control of the mouse. Here is the easiest way
   to customize your machine to allow both Ensemble and
   Windows  to work together.
     A. Load up Ensemble 
     B. Use your arrow keys navigate to the Preferences icon and
        press the ENTER key to run Preferences
     C. Use the TAB key to navigate to the Mouse button.
     D. Press the SPACEBAR to run the Mouse Preferences module.
     E. Press the TAB key to navigate to the Change button.
     F. Select Windows 95 mouse support already installed
        (Alternatives: Generic, Nothing else works, or No Idea)
     G. Press the ENTER key.

 ********************************************************************
     Section 8 -  If Ensemble does not work
 ********************************************************************

 1. NOMEM TEST

   If you have extended or expanded memory (any RAM beyond 640K) and
   you are having problems running your software, try starting
   Ensemble by typing:
            Ensemble /nomem
   at the DOS prompt in the directory where you installed Ensemble.
   You must type this in lowercase letters. The nomem
   parameter instructs the software to ignore any extended or expanded
   memory in your system. If using nomem solves your problem, it was
   probably caused by a TSR such as a RAM disk, memory manager,
   etc.., that uses your expanded or extended memory in your
   computer.

 2. TO MAKE THE NOMEM SETTING PERMANENT

   Run Preferences and click on the Computer icon. Select None for 
   Extra Memory and accept the setting. Close Preferences.

 3. SUPER VGA MONITORS THAT ONLY WORK IN NORMAL VGA

   Ensemble currently supports high resolution on most
   Super VGA systems. VESA Super VGA is the closest thing to a 
   Super VGA standard. If you are not sure what kind of Super VGA
   card you have, you may want to try our VESA compatible Super 
   VGA driver. If none of the drivers seem to work, the video board
   itself may not be prepared to utilize Super VGA mode. To fix this,
   run the setup program that came with your video board. If even
   then super VGA mode does not work, you may need to use Standard VGA
   at 640x480.

 4. SCREEN BLANKERS / SCREEN SAVERS

   Ensemble is not compatible with most screen blankers.
   Once they blank the screen, you will probably have to restart your
   computer before you can use Ensemble again. Disable all
   screen blanking software before you run the software. We
   include screen savers. To select an Ensemble screen saver,
   double click on Preferences and click on Lights Out.

 5. PRINTER PROBLEMS

   Our #1 Printer troubleshooting hint.
      A. Double click the Preference icon.
      B. Select Computer
      C. Select BIOS on the parallel port you are using to print 
         (typically LPT1).
      D. Click OK

   Setting the port to BIOS tells Ensemble to use a method
   of printing similar to that used by MS-DOS. If the BIOS setting
   doesn't work, try the DOS setting. Note that the DOS setting may
   produce a strange error message No Formatted disk in drive if the
   printer is off-line. This is a result of the way DOS reports the
   error. If neither BIOS nor DOS works, try the 7 setting for
   printing on LPT1 or the 5 setting for printing on LPT2.

 6. DOES IT PRINT WITH OTHER SOFTWARE?

   If you cannot print at all from Ensemble, you may not
   have the printer hooked up to the computer properly. Check to see
   if you can print from other software programs. If not, then you
   need to double check the printer connections. If you can print
   from another program, make a note of what LPT port the printer is
   set up for in that software and tell Ensemble to use
   that same port.

 7. DISTORTED OR GARBLED PRINTOUTS

   If your printer is printing strange characters or output appears
   distorted, you may have chosen the wrong printer driver. Try using
   other printer drivers on the list by double clicking Preferences,
   then click Printer and click on New. If your printer does not
   appear on the list of supported printers, check the printers
   documentation. Maybe your printer emulates (mimics) some other
   brand or model.

   NOTE: Always check and make sure that Default Sizes are correct,
   whenever you change your printer drivers.

 8. MOUSE PROBLEMS

   There are no known mouse problems at this time. If you are using
   Windows 95 or later on your computer, please check the Windows 
   section elsewhere in this guide.

 9. OS/2

   You can install under OS/2 in a regular DOS full screen window.
   The DOS_STARTUP_DRIVE setting on the session page should be blank.
   Increase the number of DOS_FILES available to that DOS box to at
   least 80. Make sure that the HW_TIMER setting is on. All other
   values can be left as the defaults.

   If you are installing from an OS/2 DOS session you may receive an
   error message indicating that you don't have enough room on your
   hard drive. NOTE: The install program will allow you to continue
   if you are sure that there is enough space.

   After installing Ensemble and before running setup you may need to
   edit your geos.ini file as follows:
   Change
      [system]
      fs = ms4.geo
   to
      [system]
      fs = os2.geo
   
   You might get a "SYS Error 0005. Access Denied" error while
   installing under OS/2, because OS/2 thinks there is an extended
   attribute set for all of the files on the installation disks.

   To change this extended attribute:
                              
   A. Use the DISKCOPY command to copy each installation disk to a
      diskette that is not write protected.
                              
   B. Run CHKDSK /f on each diskette. OS/2 will correct what it
      thinks is an extended attribute error on every file.

   C. Then install from the copies.

 10. PROBLEMS RE-STARTING AFTER CRASH

   If you have problems re-starting Ensemble after a crash you may
   need to run Reset.bat which is located in the Ensemble directory.
   To run Reset.bat simply type "reset" from a DOS prompt (or
   window) in the C:\Ensemble (or where ever you installed Ensemble) 
   directory.  Then restart Ensemble normally.

 ********************************************************************
     Section 9 -  Error Messages
 ********************************************************************

 1. SHARE TABLE OVERFLOW

   This error means that the DOS utility program SHARE.EXE is not set
   high enough for Ensemble. You should check the
   AUTOEXEC.BAT for a line such as

       C:\DOS\SHARE.EXE /f:4096

   If this line does not exist or there is no /f:4096, you should add
   it. If the line is correct and you still get the error message,
   try increasing the number 4096 in increments of 2048 until the
   error message stops.

 2. GEOS.INI FILE HAS BEEN CORRUPTED

   The GEOS.INI file will be located in the C:\Ensemble directory if
   you installed the program into that drive and directory. Should
   the file ever become damaged, you can copy the file from the
   original install installation files.

   If you have installed Ensemble into a directory other
   than C:\Ensemble, substitute the appropriate drive and directory in
   these commands.

 3. SYSTEM ERROR: KR-07, KR-09

   System error: KR-09 or System Error: KR-07 can be caused by memory
   (RAM) conflicts, damaged files, or faulty program instructions.

   Primary reasons for getting system errors.
     A. A one-in-a-million fluke
     B. Problems in your AUTOEXEC.BAT or CONFIG.SYS file
     C. Corrupt files or bad sectors on your hard drive
     D. Damaged document files
     E. A conflict with other software
     F. Low on hard disk space
     G. Low on memory (RAM)
     H. A virus
     I. KR-07, KR-09 and Windows

 DIAGNOSIS AND TREATMENT

 These problems are usually easy to track down and fix. Go through
 the following steps, in order, to locate and fix the source of the
 error.

  A. A ONE-IN-A-MILLION FLUKE

     Turn off your computer. Wait a few seconds, then turn it on
     again. Go back into Ensemble. Do exactly what you were
     doing when the error message appeared. If you don't get another
     error message, it was probably a one-time fluke. If you only get
     the error in one specific document, skip to section D, Damaged
     Documents.

  B. CHECK YOUR AUTOEXEC.BAT AND CONFIG.SYS FILES

     Check your configuration files for problems. To edit these
     files, use a text editor such as the Text File Editor, the MS-DOS
     Edit command, or the DR-DOS Editor. First enter VER at
     a DOS prompt to find out which version of DOS you're using. Then
     look under the appropriate section below.

     MS-DOS - CONFIG.SYS
      -  Make sure you have a line that reads BUFFERS=30 (or higher)
      -  Make sure you have FILES=30 (or FILES=120 if you use
         DOSSHELL)
      -  If you have a line that refers to SHARE.EXE, follow the
         instructions above about raising the value of the /f:
         parameter. (It is recommended to load SHARE.EXE in the
         AUTOEXEC.BAT file)
      -  If you see a line that includes FASTOPEN, delete the line
         (or put REM at the beginning of the line).

     MS-DOS - AUTOEXEC.BAT
      -  If you see a line that includes FASTOPEN, delete the line
         (or put REM at the beginning of the line).
      -  If you have a line that refers to SHARE.EXE, follow the
         instructions above about raising the value of the /f:
         parameter.

     DR-DOS - CONFIG.SYS
      -  Make sure you have the line FILES=120 (or higher)
      -  Make sure you have BUFFERS=30 (or HIBUFFERS=30)

     Save the files, then reboot your computer so the changes can
     take effect. Now try to reproduce the steps that gave you the
     error.

  C. BAD SECTORS ON YOUR HARD DISK

     The first thing to do is use the DOS CHKDSK command. To run
     CHKDSK, completely exit any program you're in and enter 
     CHKDSK /f at a DOS prompt. If CHKDSK displays Cross-linked
     files, you need to delete the cross-linked files and reinstall
     the software. Over time, it's not unusual for hard disks to
     develop small surface defects that result in bad sectors. The
     only ways to check for and fix bad sectors are to use a
     commercial hard disk utility program, such as Norton Disk Doctor
     or PC Tools DiskFix or the old method: backup the hard drive,
     reformat it, and restore your files from the backup. With
     MS-DOS 6.0 and higher, there is a utility called SCANDISK
     which is comparable to the utilities named above. To maintain
     hard disk integrity, it is also a good idea to run a hard
     disk defragmentation utility like SPEEDISK from Norton or DEFRAG
     with MS-DOS 6.0 or higher. 
    
     You could also try installing the software into a new,
     different directory on the hard drive. Make sure you use the CD
     command to change to this directory before typing Ensemble
     to start Ensemble (otherwise you may run the original
     copy). If you don't experience problems, your original copy of
     Ensemble is either damaged or is written on bad
     sectors of your hard drive. If you find errors: Once you've
     fixed the hard disk problems, you should re-install Ensemble.
     Use your original installation disks, and choose the
     New Install option. Re-installing this way won't delete or copy
     over your personal documents.

  D. DAMAGED DOCUMENTS

     If you only get the error message when working on one document,
     the document is damaged. Use your backup copy to replace the
     file. If you don't have a backup copy, you'll have to re-create
     the document from scratch. You should backup any files that you
     don't want to re-create. It is always a good idea to save and
     backup important work.

  E. SOFTWARE CONFLICTS

     Quick and easy test for software conflicts:
    
     At the DOS prompt and enter
        Ensemble /nomem
     This tells Ensemble to ignore any expanded or extended
     memory, which is usually where conflicting software resides. If
     you still get the error, try the more thorough test outlined
     below. If you no longer get the error, you have a software
     conflict. You can either go into Preferences, Computer and change
     the Extra Memory option to None, or perform the more thorough
     test below.

     More thorough test: Boot from a clean floppy disk. You can make
     a boot disk (also called a system disk) from the DOS prompt by
     entering FORMAT A: /S. On this floppy, put a CONFIG.SYS file
     with only the lines you absolutely need to make your computer
     work (generally that's only FILES=30 and BUFFERS=30). If you
     run any disk compression utilities like Stacker or SuperStor,
     you'll need to include any statements from your configuration
     files that make those programs run. Don't include your mouse
     driver, expanded memory managers, or any disk caching programs
     (such as SMARTDRV). If you don't get the errors after booting
     from the clean floppy disk, you can add lines from your original
     CONFIG.SYS and AUTOEXEC.BAT to the CONFIG.SYS and AUTOEXEC.BAT
     on the bootable diskette. Add one line, save the file, reboot,
     and run Ensemble. Eventually you'll find the line that's
     causing the problem.

  F. LOW ON HARD DISK SPACE

     You should have at least 2 megabytes of free hard disk space
     for the program to work properly, and preferably more for
     improved performance. You can free up some space by backing up
     rarely used programs or documents to disk and deleting them from
     the hard drive.

  G. LOW ON CONVENTIONAL MEMORY (BELOW 640K)

     Low on memory (RAM) - Ensemble requires 520K of free
     conventional memory to run. If you are loading a lot of device
     drivers and memory-resident programs before you load the
     software, you might be running out of memory. The DOS command
     CHKDSK tells you the amount of free conventional memory. At the
     very end of the CHKDSK report, you'll see a number labeled
     x bytes free. "x" is the amount of free conventional memory.
     This number should be at least 524,288. If it's lower, you need
     to disable some of the programs that are loading into your
     conventional memory. You can do this by inserting REM at the
     beginning of the line that loads the program in your
     AUTOEXEC.BAT or CONFIG.SYS file. You'll need to reboot for the
     changes to take effect.

  H. VIRUS ATTACKS

     Check your computer's hard drive for viruses. Use any reputable
     virus-checking software. If you find a virus, remember to also
     check every floppy in your home or office. In the unlikely event
     that you do have a virus, cure it and re-install Ensemble.

  I. KR-07, KR-09 and Windows

     Windows automatically loads its own drivers for your
     hardware. Should you have any of the following DOS-based drivers
     loaded in your CONFIG.SYS or AUTOEXEC.BAT files, they may be
     conflicting with the Windows drivers and you may need to 
     remove them in order to run Ensemble.

     Possible Problem Drivers
     -  CD-ROM Drivers
     -  Mouse Drivers
     -  Network Drivers

  4. UNABLE TO WRITE TO DISK

   The vast majority of the time this error message does not indicate
   a real problem, but a phantom one.  Simply press the A key to
   make the error message go away.  If this error message shows up
   often enough to become a nuisance try setting your LPT port from
   DOS to 7 in the Preferences Computer module.

  5. OTHER SUGGESTIONS

   If you are using MS-DOS 5 or MS-DOS 6 or Novell DOS 7, try raising
   the number of FILES = x in your CONFIG.SYS file to 80 or 100. If
   you are using DR DOS 6 or DOSSHELL, be sure you have FILES = 120
   (or a higher number) in your CONFIG.SYS file.

 ********************************************************************
     Section 10 -  Incomplete Installation
 ********************************************************************

 If you do not complete the installation, a residual directory may
 exist. The directory name will be ISFYQVO.TWJ and may contain a file
 called SWAPFILE.HDR.

 To delete the FILE, enter the following at the DOS prompt:

       del isfyqvo.twj\*.*
       (press the enter key)

 You will then see the following:

       All files in directory will be deleted!
       Are you sure (Y/N)?

 Press the "y" key and then the Enter key.


 To delete the DIRECTORY, enter the following at the DOS prompt:

       rd isfyqvo.twj

 ********************************************************************
               End of README.TXT
 ********************************************************************
