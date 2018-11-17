# Microsoft Developer Studio Project File - Name="pmake" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=pmake - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "pmake.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "pmake.mak" CFG="pmake - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "pmake - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "pmake - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName "pmake"
# PROP Scc_LocalPath "."
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "pmake - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib  kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib  kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /GZ  /c
# ADD CPP /nologo /W3 /Gm /GX /ZI /Od /I "C:\prg\perforce\pcgeos\Tools\pmake\src\lib\include" /I "C:\prg\perforce\pcgeos\Tools\include" /I "C:\prg\perforce\pcgeos\Tools\pmake\lib\lst" /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /GZ  /c
# SUBTRACT CPP /X
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib  kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib  kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib lstd.lib winutild.lib tcld.lib compatd.lib ntcursesd.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept /libpath:"C:\prg\perforce\pcgeos\Tools\vc++\lib"
# SUBTRACT LINK32 /nodefaultlib

!ENDIF 

# Begin Target

# Name "pmake - Win32 Release"
# Name "pmake - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\arch.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\compat.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\cond.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\customslib.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\dir.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\job.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\main.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\make.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\parse.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\rmt.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\rpc.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\str.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\suff.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\targ.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\var.c

!IF  "$(CFG)" == "pmake - Win32 Release"

!ELSEIF  "$(CFG)" == "pmake - Win32 Debug"

# ADD CPP /I "$(ROOT_DIR)\Tools\vc++\include $(ROOT_DIR)\Tools\include"

!ENDIF 

# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\arch.h
# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\buf.h
# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\include\config.h
# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\include\hash.h
# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\job.h
# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\src\lib\lst\lst.h
# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\make.h
# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\pmjob.h
# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\prototyp.h
# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\rmt.h
# End Source File
# Begin Source File

SOURCE=..\..\..\..\Tools\pmake\pmake\rpc.h
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# End Group
# End Target
# End Project
