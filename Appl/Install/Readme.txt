The Universal Installer Tools
-----------------------------

The tools create or install "installation packages" with which programs and
other file collections can be conveniently distributed and installed. 
By considering the protocol and release numbers, it is guaranteed that newer
versions (e.g. of libraries) are not overwritten by older versions.

The original code is written in German. Therefore, many comments are still in
German. 

Folders
-------
INSTC	Code for the Install Creator application
	It creates, manages and modifies installation packages 
	
INSTF	Code for the Uni Installer application
	It installs the installation packages 
	The App-Icons for both apps can be found in INSTC/Art
	
Shared	Files that are used for both, the Install Creator and the Uni Installer

German	Additional files, which are needed to build the German version:
	German help file, Ferman translation files for both apps.