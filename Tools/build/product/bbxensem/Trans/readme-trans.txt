* --------------------------------------------------
*           How translation works
* --------------------------------------------------

This file briefly describes how the translation process into another language 
works. The translation into German is used as an example.

It is assumed that you know how to create a translation file, edit it, update 
it and create the translated geode to test the translation. The .GEO and .VM 
files required to create a translation file can be found on github 
(https://github.com/bluewaysw/pcgeos/releases/tag/CI-latest) in the file 
pcgeos-ensemble_loc.zip.

A few rules must be respected to ensure that everything works properly.
1. The DOS file name of the translation file must be in CAPITAL letters. There
   is no restriction for the GEOS name, but it should be self-explanatory.
2. The source of the translation is an English GEOS installation. This means 
   that the path to the original file must refer to the English folder 
   (e.g. "World\Games"), even if the folder has a different name in German
   (e.g. "World\Spiele"). 
3. The translation files that are to be taken into account must be placed in
   the folder pcgeos\Tools\build\product\bbxensem\Trans\german. Subfolders are
   not included.
   The pcgeos\Tools\build\product\bbxensem\Trans\german\unreleased folder 
   stores translation files that translate geodes (programs or libraries) that
   are not currently in use.

Internally, the translation process works as follows:
-----------------------------------------------------
As the target installation, a GEOS installation is used that already contains 
those files in German that do not need to be translated. This applies, for 
example, to help files or templates. The bbxensem.filetree file, which is 
located in the pcgeos\Tools\build\product\bbxensem folder, specifies which 
files are affected.
In this target installation, the geodes to be translated and the associated
folders still have their English names, e.g. "World\Games\Battle Raft".

The actual translation is done by an automated ResEdit in a separate GEOS 
installation. The program reads all translation files from the 
pcgeos\Tools\build\product\bbxensem\Trans\german folder, translates the
corresponding geodes and writes the translated geode to the target 
installation. 
The GEOS name is modified (translated), but the DOS name is not changed.
"Battle Raft" is now called "Schiffe versenken", but the DOS name is still
BATTLE.GEO.
The names of the folders are also unchanged, e.g. "World\Games".

As the final step, the names of the folders are translated by replacing the
corresponding @dirname.000 files. You can find which folders this affects under
pcgeos\Tools\build\product\bbxensem\Trans\DirNames\german. The translated 
@dirname.000 files are stored there in the corresponding subfolders. These 
files are simply copied to the target installation.

The DOS name of the folder is not changed. For example, Battle Raft can be 
found under DOS as "WORLD\GAMES\BATTLE.GEO", in the German-translated GEOS it
can be found under "World\Spiele\Schiffe versenken".


For programmers or experienced users: 
How to create a translated GEOS installation locally.
-----------------------------------------------------
GEOS installations (targts) are built with the perl script buildbbx in the 
folder pcgeos\Tools\build\product\bbxensem\Scripts. We need three 
installations, which must either be in different locations or have different
names.

1. Build the source installation:
	Answers: platform: nt 		EC Image: n 		DBCS Image: n 
	Copy Geodes: y			Copy resouce (.vm) files: y
2. Build the target installation
   To do this, the environment variable TARGET_LANG must be set to
   TARGET_LANG=german first. 
	Answers: platform: nt 		EC Image: n 		DBCS Image: n 
	Copy Geodes: y			Copy resouce (.vm) files: n
3. Build the tools installation that performs the translation process.
	Answers: platform: nttools 	EC Image: n 		DBCS Image: n 
	Copy Geodes: y			Copy resouce (.vm) files: n
   This installation must be named 'ensemble'.
4. Copy the files from pcgeos\Tools\build\product\bbxensem\Trans\german to 
   another location.
   The translation process can modify (update) these files so that git 
   recognizes them as changed. We do not want that.
5. Call the script prodLoc (under Windows: prodLoc.cmd)
   This script is located under pcgeos\bin. You must pass this script the paths
   to the three GEOS installations and to the folder with the translation files
   (see script for order). The script starts the tools installation and returns 
   a log of the translation process. The target installation now contains the 
   translated geodes.
6. Copy the @dirname.000 from the folder 
   pcgeos\Tools\build\product\bbxensem\Trans\DirNames\german into the 
   corresponding directories of your target installation. This can be done with
   xcopy or similar.

R.B. 01/2024   
