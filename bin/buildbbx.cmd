@echo off
rem
rem	Call interactive script to make Ark images
rem
rem	$Id:$
rem
@echo on
perl %ROOT_DIR%\tools\build\product\bbxensem\scripts\buildbbx.pl %*

