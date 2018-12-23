set SDK_TARGET=%1
rd /S /Q %SDK_TARGET%
mkdir %SDK_TARGET%
mkdir %SDK_TARGET%\Installed\
mkdir %SDK_TARGET%\Installed\Include\
mkdir %SDK_TARGET%\CInclude\
mkdir %SDK_TARGET%\Include\
mkdir %SDK_TARGET%\Include\Appl\SDK_C\
mkdir %SDK_TARGET%\Include\Appl\SDK_Asm\
mkdir %SDK_TARGET%\Include\Library\SDK_C\
mkdir %SDK_TARGET%\Tools\swat\lib.new\
mkdir %SDK_TARGET%\bin\

xcopy /s %ROOT_DIR%\Installed\*.geo %SDK_TARGET%\Installed\ 
xcopy /s %ROOT_DIR%\Installed\*.sym %SDK_TARGET%\Installed\
xcopy /s %ROOT_DIR%\Installed\*.gym %SDK_TARGET%\Installed\
xcopy /s %ROOT_DIR%\Installed\*.exe %SDK_TARGET%\Installed\
xcopy /s %ROOT_DIR%\Installed\*.com %SDK_TARGET%\Installed\

xcopy /s %ROOT_DIR%\Installed\Include\*.plt %SDK_TARGET%\Installed\Include\ 
xcopy /s %ROOT_DIR%\Installed\Include\*.ldf %SDK_TARGET%\Installed\Include\ 

xcopy %ROOT_DIR%\Include\*.* %SDK_TARGET%\Include\ 
xcopy %ROOT_DIR%\CInclude\*.* %SDK_TARGET%\CInclude\ 
xcopy %ROOT_DIR%\bin\*.* %SDK_TARGET%\bin\

xcopy /s %ROOT_DIR%\CInclude\Objects\*.* %SDK_TARGET%\CInclude\Objects\
xcopy /s %ROOT_DIR%\CInclude\Mailbox\*.* %SDK_TARGET%\CInclude\Mailbox\
xcopy /s %ROOT_DIR%\Include\Mailbox\*.* %SDK_TARGET%\Include\Mailbox\
xcopy /s %ROOT_DIR%\Include\Objects\*.* %SDK_TARGET%\Include\Objects\
xcopy /s %ROOT_DIR%\Include\Win32\*.* %SDK_TARGET%\Include\Win32\
xcopy /s %ROOT_DIR%\CInclude\Ansi\*.* %SDK_TARGET%\CInclude\Ansi\
xcopy /s %ROOT_DIR%\CInclude\SDK_C\*.* %SDK_TARGET%\CInclude\SDK_C\

xcopy /s /exclude:%~dp0\filter.txt %ROOT_DIR%\Appl\SDK_C\*.* %SDK_TARGET%\Appl\SDK_C\
xcopy /s /exclude:%~dp0\filter.txt %ROOT_DIR%\Appl\SDK_Asm\*.* %SDK_TARGET%\Appl\SDK_Asm\
xcopy /s /exclude:%~dp0\filter.txt %ROOT_DIR%\Library\SDK_C\*.* %SDK_TARGET%\Library\SDK_C\

xcopy /s %ROOT_DIR%\Tools\swat\lib.new\*.* %SDK_TARGET%\Tools\swat\lib.new\
