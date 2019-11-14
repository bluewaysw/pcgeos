## 9 The INI File

Most programmers are familiar with the structure and function of an 
initialization file, or INI file. GEOS uses one or more INI files depending on 
the setup (network users may have two or more INI files; standalone users 
may have only one).

The INI file for GEOS describes the drivers, fonts, and other items installed 
on the system. It also contains other system configuration information, such 
as the specific UI expected and information about the type of display and 
input devices used. It may also be used by applications for storing their 
configuration information as set by the user.

### 9.1 How to Use the INI File

As a software developer, you will have two uses for the INI file. First, the INI 
file controls your system configuration to a certain extent. For example, if you 
are developing applications for a small-screen pen device, you should know 
the appropriate settings in the INI file to get your system to emulate such a 
device.

Second, you may need to have your application access the INI file to store or 
retrieve information. The kernel offers routines for just this purpose; these 
routines are detailed in Chapter 6 of the Concepts books.

This chapter describes the file itself as well as the categories and keys 
created and used by GEOS. Depending on the system you plan to develop for, 
you may need to set several different keys in certain combinations (e.g. 
setting certain keys emulates a Zoomer configuration). These special 
combinations are described in the special add-on documents that describe 
developing for each system. For more information, contact Geoworks 
Developer Support.

### 9.2 Categories in the INI File

Code Display 9-1 shows a short list, without description, of all the categories 
and keys available in the INI file. Following the display are explanations of 
each category, with a description of each key and the values you can set.

----------

**Code Display 9-1 The GEOS.INI File**

	; This is a listing of many of the categories and keys in the GEOS.INI file.
	; Each category is described in full in the following sections of this
	; chapter, along with the values you can set for each key and what they do.
	; The categories and keys are listed alphabetically.

	[cards]
	deckdir = <directory containing deckfile>
	deckfile = <full name of deck>

	[configure]
	drive <letter> = <drive number>
	helpEditor = <Boolean>
	numberWS = <maximum number of calculator worksheets>>

	[diskswap]
	file = <path of swap file>
	page = <size of swap page>
	size = <size of swap file>

	[envelope]
	count = <number of user-defined size strings>
	newSizes = <list of user-defined size strings> 
	order = <array of DefaultOrderEntry values>

	[envel<num>]
	name = <name string>
	width = <width in points>
	height = <height in points>
	layout = <PageLayout structure>

	[expressMenuControl]
	floatingKeyboard = <Boolean>
	otherAppSubMenu = <Boolean>

	[fileManager]
	dosAssociations = {<list of associations>}
	dosLaunchers = <Boolean>
	dosParameters = <Boolean>
	filenameTokens = {<list of associations>}
	fontID = <font ID of font in folder windows>
	fontSize = <point size of folder window font>
	options = <number>
	startupDrivesLocation = <number>

	[input]
	blinkingCursor = <Boolean>
	clickToType = <Boolean>
	doubleClickTime = <number of ticks>
	keyboardOnly = <Boolean>
	left handed = <Boolean>
	mouseAccelMultiplier = <number>
	mouseAccelThreshold = <number>
	noKeyboard = <Boolean>
	numberOfMouseButtons = <number>
	quickShutdownOnReset = <Boolean>
	reboot on reset = <Boolean>
	selectDisplaysMenu = <Boolean>
	selectRaises = <Boolean>

	[keyboard]
	device = <full device name>
	driver = <driver file name>
	keyboardAltGr = <Boolean>
	keyboardDoesLEDs = <Boolean>
	keyboardShiftRelStr = <Boolean>
	keyboardSwapCtrl = <Boolean>
	keyboardTypematic = <number>

	[label]
	count = <number of user-defined size strings>
	newSizes = <list of user-defined size strings> 
	order = <array of DefaultOrderEntry values>

	[label<num>]
	name = <name string>
	width = <width in points>
	height = <height in points>
	layout = <PageLayout structure>

	[link]
	name = <machine name>
	port = <number>
	baudRate = <number>
	drives = <list of drives>

	[localization]
	currencyDigits = <number of decimal digits for currency>
	currencyLeadingZero = <Boolean>
	currencySymbol = <character of currency symbol>
	day
	decimalDigits
	decimalSeparator
	hoursMins24HourTime
	hoursMinsSecs24HourTime
	hoursMinsSecsTime
	hoursMinsTime
	hoursTime
	longCondensedDate
	longDate
	longDateNoWeekday
	measurementSystem
	minsSecsTime
	month
	monthDayLongDate
	monthDayLongDateNoWeekday
	monthDayShort
	monthYearLong
	monthYearShort
	negativeSignBeforeNumber = <Boolean>
	negativeSignBeforeSymbol = <Boolean>
	quotes
	shortDate
	spaceAroundSymbol = <Boolean>
	symbolBeforeNumber = <Boolean>
	useNegativeSign = <Boolean>
	weekday
	year
	zeroPaddedShortDate

	[math]
	coprocessor = <library name for coprocessor>

	[modem]
	modems = {<modem name list>}
	numberOfModems = <number>

	[<modem name>]
	baudRate = <number>
	handshake = <hardware, software>
	parity = <none, even, odd, mark, space>
	stopBits = <number>
	stopLocal = <dsr, dcd, cts>
	stopRemote = <dtr, rts>
	toneDial = <Boolean>
	wordLength = <number>

	[mouse]
	device = <full device name>
	driver = <driver file name>
	info = <number>
	irq = <number>
	port = <number>

	[netLibrary]
	InitDrivers = {<list of driver geodes>}

	[paper]
	count = <number of user-defined size strings>
	newSizes = <list of user-defined size strings> 
	order = <array of DefaultOrderEntry values>

	[paper<num>]
	name = <name string>
	width = <width in points>
	height = <height in points>
	layout = <PageLayout structure>

	[parallel]
	port <number of parallel port> = <level of port>

	[paths]
	<standard path> = <other paths to merge>
	ini = <additional .INI files to load>
	inisaved = <path of saved .INI file>
	sharedTokenDatabase = <path of shared token db file>

	[printer]
	count = <number>
	defaultPrinter = <number>
	numFacsimiles = <number>
	numPrinters = <number>
	printers = {<list of print devices>} 

	[<printer device name>]
	baudRate = <speed of serial communication>
	device = <full device name>
	driver = <file name of driver>
	handshake = <handshake for serial communication>
	parity = <parity for serial communication>
	port = <port name>
	stopBits = <stop bits for serial communication>
	type = <type of print device>
	wordLength = <word size for serial communication>

	[screen 0]
	device = <full name of device>
	driver = <file name of driver>
	oldDevice = <full name of device formerly used>
	oldDriver = <file name of drivr formerly used)

	[serial]
	port <number of serial port> = <level of port>

	[sound]
	sampleDriver = <driver file name>
	synthDriver = <driver file name>

	[spool]
	uiOptions = <SpoolUIOptions>

	[system]
	continueSetup = <Boolean>
	drive <letter> = <number>
	font = <drivers to be loaded>
	fontid = <font to be used as the default>
	fontsize = <point size of default font>
	fs = <drivers to be loaded>
	handles = <number of handles>
	inkTimeout = <ticks until ink is processed>
	maxTotalHeapSpace = <memory size>
	memory = <swap drivers to be loaded>
	noFontDriver = <Boolean>
	notes = <string>
	noVidMem = <Boolean>
	pda = <Boolean>
	penBased = <Boolean>
	power = <file name of power management driver>
	serialNumber = <serial number of installed GEOS>
	setupMode = <mode for graphical setup application>
	splashcolor = <background color>
	splashscreen = <Boolean>
	splashtext = <text message>

	[text]
	autoCheckSelections = <Boolean>
	autoSuggest = <Boolean>
	dialect = <dialect code>
	dictionary = <file name of dictionary used by spell checker>
	hyphenationDictionary = <file name of dictionary>
	hyphenationLanguage = <name of language>
	language = <language code>
	languageName = <name of language in use>
	resetSkippedWordsWhenBoxCloses = <Boolean>
	smartQuotes = <Boolean>

	[ui]
	autosave = <Boolean>
	autosaveTime = <seconds between autosaves>
	background = <file name of background graphic>
	backgroundattr = <t, c, or x>
	backgroundcolor = <color index of background>
	confirmShutdown = <Boolean>
	deleteStateFilesAfterCrash = <Boolean>
	doNotDisplayResetBox = <Boolean>
	execOnStartup = <list of programs to run on startup>
	generic = <generic UI file name>
	hardIconsLibrary = <string>
	haveEnvironmentApp = <Boolean>
	hwr = <file name of handwriting recognition library>
	kbdAcceleratorMode = <Boolean>
	noClipboard = <Boolean>
	noSpooler = <Boolean>
	noTaskSwitcher = <Boolean>
	noTokenDatabase = <Boolean>
	overstrikeMode = <Boolean>
	password = <Boolean>
	passwordText = <encrypted text>
	penInputDisplayType = <number of display type>
	productName = <name of the product>
	screenBlanker = <Boolean>
	screenBlankerTimeout = <number of minutes>
	showTitleScreen = <Boolean>
	sound = <Boolean>
	specific = <specific UI file name>
	tinyScreen = <Boolean>
	unbuildControllers = <Boolean>
	xScreenSize = <width of screen>
	yScreenSize = <height of screen>

	[<specific ui name>]
	fontid = <font>
	fontsize = <size in points>

	[ui features]
	backupDir = <directory for quick backup files>
	defaultLauncher = <relative path of application launcher>
	docControlFSLevel = <number>
	docControlOptions = <number>
	expressOptions = <number>
	helpOptions = <number>
	interfaceLevel = <number>
	interfaceOptions = <number>
	launchLevel = <number>
	launchModel = <number>
	launchOptions = <number>
	quitOnClose = <Boolean>
	windowOptions = <number>

	[uiFeatures - intro]
	[uiFeatures - beginner]
	[uiFeatures - advanced]

	[welcome]
	enteredprofessionalroom = <Boolean>
	startup = <application name to start>
	startupRoom = <name of startup room>

----------

### 9.2.1 cards

The cards category contains information used by the cards library. The cards 
library provides routines used by card games. The cards category contains 
information about how to access the file containing the bitmap to be used as 
the card back picture.

#### deckdir
`deckdir = <deck directory>`

This optional field shows the path which contains the file named in the 
deckfile key, described below. If this key is not given, the cards library will 
look for deck files in the USERDATA\DECK directory.

#### deckfile
`deckfile = <deck name>`

The deckfile key defines the full name of the deck to be used by the card 
library. This is most useful in cases like the Zoomer, which must have its own 
card artwork. By default, the cards library will look in the USERDATA\DECK 
directory.

	deckfile = Zoomer Default Deck

----------

### 9.2.2 configure

The configure category contains miscellaneous configuration information for 
GEOS. The drive key is exactly like the drive key in the system category.

#### drive
`drive <letter> = <number>`

This key allows you to override the drive-map initialization done by the 
primary filesystem driver. You can not make a driver believe a nonexistent 
drive exists, but you can change the presumed media or make the driver 
ignore a drive. More than one drive may be remapped.

The letter argument is the drive letter of the drive to be remapped. The 
number argument defines the new drive definition and is one of the following 
values:

	  -1		fixed disk
	   0		ignore the drive
	 360		360 K 5.25-inch disk
	 720		720 K 3.5-inch disk
	1200		1.2 meg 5.25-inch disk
	1440		1.44 meg 3.5-inch disk
	2880		2.88 meg 3.5-inch disk

Some examples of drive remappings are shown below:

	drive d = 0			; ignore drive D:
	drive a = 360		; make GEOS think drive A: is 360K

#### helpEditor

`helpEditor = <Boolean>`

If true, this key indicates that GeoWrite should add a new Help Editor 
feature. This must be on if you are planning on creating help files for your 
application. The Help Editor feature may be turned on by selecting "Fine 
Tune" in the user level dialog box in GeoWrite. More information on the Help 
Editor can be found in the chapter on the help system.

	helpEditor = true
	helpEditor = false

#### numberWS

`numberWS = <number of calculator worksheets>`

When users use the worksheets feature of the calculator, each worksheet 
they use will be loaded into memory. Normally, these worksheets are kept in 
memory so that the user may quickly go back to a worksheet they were using 
previously. Some low-memory devices may prefer that fewer worksheets are 
cached in this manner. The numberWS specifies a maximum number of 
worksheets that may be so cached.

----------

### 9.2.3 diskswap

The diskswap category defines swap information for the GEOS swap file. 
Generally, you won't set these keys individually; GEOS will set them as 
required.

#### file

`file = <path of swap file>`

This category defines the file used by the disk swap driver for swapping.

	file = C:\GEOWORKS\SWAP\EXTRA

#### page

`page = <size of swap page>`

This key defines the page size of a swap page.

	page = 2048

#### size

`size = <size of swap file>`

This key defines the maximum size of the swap file.

	size = 2048

----------

### 9.2.4 envelope

This category keeps track of any customizations the user may have made to 
the list of envelope paper sizes. 

#### count

`count = <number>`

This is the number of user-defined envelope sizes.

#### newSizes

`newSizes = <list of paper size codes>`

This list contains a list of all user-defined envelope sizes. The paper size 
information for each of these sizes will be stored in a catgory named 
[envel*num*], where *num* is the three-letter code in this list.

#### order

`order = <list of paper size codes>`

This list contains a list of all envelope sizes in the order that the user wants 
them to appear in envelope size lists.

---------
### 9.2.5 envel *num*

This category contains size and layout for a user-defined envelope size.

#### height

`height = <number>`

This field holds the envelope's height in points.

#### layout

`layout = <PageLayout value>`

This field holds the envelope's layout information.

#### name

`name = <string>`

This field holds the envelope's full name.

#### width

`width = <number>`

This field holds the envelope's width in points.

----------

### 9.2.6 expressMenuControl

The expressMenuControl category defines the configuration of the express 
menu; see the ui features category for more express menu controls.

#### floatingKeyboard

`floatingKeyboard = <Boolean>`

If true, this key adds an item to the express menu to bring up the floating 
keyboard (used for pen-based systems). The default is false.

	floatingKeyboard = true
	floatingKeyboard = false

#### maxNumDirs

`maxNumDirs = <number>`

If this field exists, then if there are more entries in the Other Apps section of 
the Express Menu than this, the Other Apps section will be forced into a 
submenu (and forced into a subgroup if less than this), regardless of 
"noSubMenus" and "otherAppSubMenu".  Defaults to 25 (the absolute 
maximum number of Other Apps entries).

#### noSubMenus

`noSubMenus = <Boolean>`

If true, the express menu will not allow forcing the main applications,other 
applications, or desk accessories into submenus.

#### otherAppSubMenu

`otherAppSubMenu = <Boolean>`

If true, this key turns the "other applications" section in the express menu 
into a submenu rather than a subgroup. The default is false.

	otherAppSubMenu = true
	otherAppSubMenu = false

#### runningAppSubMenu

`runningAppSubMenu = <Boolean>`

If true, this key causes the express menu include a list of currently running 
GEOS applications as a submenu. If false, the list will be placed directly in 
the express menu.

#### runSubMenu

`runSubMenu = <Boolean>`

If true, top level applications (those placed in the WORLD directory) and top 
level subdirectories (subdirectories of WORLD) will bwe placed in a submenu of the express 
menu. 

----------

### 9.2.7 fileManager

The fileManager category is used by file manager applications such as 
GeoManager. You will probably not find much cause to use these keys during 
your application development.

#### dosAssociations

`dosAssociations = {<list of associations>}`

This key allows a user to associate DOS data files with DOS executables so a 
particular DOS executable will be launched when the user double-clicks the 
data file.

	dosAssociations = {
		*.ZIP = C:\PKUNZIP.EXE
	}

#### dosLaunchers

`dosLaunchers = <Boolean>`

If true, this key allows DOS launchers to launch DOS programs. The default 
is true.

	dosLaunchers = true
	dosLaunchers = false

#### dosParameters

`dosParameters = <Booeans>`

If true, the file manager will allow the passing of parameters to DOS 
executables.

#### filenameTokens

`filenameTokens = {<list of associations>}`

This key allows the user to set icon associations with DOS files. It also allows 
certain text files to be opened by the text file editor. Certain associations are 
made by default and should always appear; these are listed below.

	filenameTokens = {
		*.EXE = "gDOS",0
		*.COM = "gDOS",0
		*.BAT = "gDOS",0
		*.TXT = "FILE",0,"TeEd",0
		*.DOC = "FILE",0,"TeEd",0
		*.HLP = "FILE",0,"TeEd",0
	}

#### fontID

`fontID = <number>`

This key sets the font used by GeoManager (or another file manager) when 
displaying the names and information of files in the folder window. The font 
ID is set the same way as for the system category; if no font ID is named, the 
default system font will be used.

	fondID = berkeley

#### fontSize

`fontSize = <number>`

This key sets the font size used in a folder window. If not specified, it will 
default to the system font.

	fontSize = 10

#### options

`options = <number>`

This key controls various file manager options. The options are set and 
cleared by the user using the file manager's Options menu; the number is a 
decimal number representing the bits set or cleared for various options.

#### startupDrivesLocation

`startupDrivesLocation = <number>`

This key controls the initial location of drive buttons; it is set with the 
Options menu in the file manager.

----------

### 9.2.8 input

The input category contains a number of keys that define how input is 
handled by the system. It affects the keyboard and mouse setup as well as 
how the UI responds to various user actions.

#### blinkingCursor

`blinkingCursor = <Boolean>`

If true, this key forces the text cursor to be a blinking cursor; it defaults to 
true. The screen dumper application requires a non-blinking cursor.

	blinkingCursor = true
	blinkingCursor = false

#### clickToType

`clickToType = <Boolean>`

If true, this key requires the user to click in a window before the focus will 
change to that window. When this key is false, the UI will invoke a "real 
estate" mode, wherein the user's typing will go to the window under the 
mouse, whether the mouse was clicked there or not. The default is true (click 
required).

	clickToType = true
	clickToType = false

#### doubleClickTime

`doubleClickTime = <number of ticks>`

This field specifies the time threshhold between clicks which should be 
recognized as a double-click. This time is expressed in 1/60th second "ticks". 
The default value is 20.

#### keyboardOnly

`keyboardOnly = <Boolean>`

If true, this key indicates that GEOS is running on a system with only a 
keyboard (no mouse) for input. The default is false.

	keyboardOnly = true
	keyboardOnly = false

#### left handed

`left handed = <Boolean>`

If true, this key switches the left and right mouse button significance. For 
single-button mice, there is no effect; for three-button mice, the middle 
button stays the same. The default is false.

	left handed = true
	left handed = false

#### mouseAccelMultiplier

`mouseAccelMultiplier = <number>`

This key gives a multiplier to allow mouse acceleration along the following 
rule: any single event pixel movement beyond a given threshold (see 
mouseAccelThreshold) is multiplied by the multiplier. The multiplier 
defaults to one, which provides no acceleration. (A multiplier of three or four 
is fast.)

	mouseAccelMultiplier = 1					; no acceleration
	mouseAccelMultiplier = 4					; very fast

#### mouseAccelThreshold

`mouseAccelThreshold = <number>`

This key gives the mouse acceleration threshold used with 
mouseAccelMultiplier (above) to provide mouse acceleration. This threshold 
is the number of pixels the mouse must move before acceleration is invoked.

	mouseAccelThreshold = 5

#### noKeyboard

`noKeyboard = <Boolean>`

If true, this key indicates that the system running GEOS has no keyboard. 
The default is false.

	noKeyboard = true
	noKeyboard = false

#### numberOfMouseButtons

`numberOfMouseButtons = <number>`

This key defines the number of buttons the mouse has. This may be the value 
one, two, or three. The default is three.

	numberOfMouseButtons = 1
	numberOfMouseButtons = 2
	numberOfMouseButtons = 3

#### quickShutdownOnReset

`quickShutdownOnReset = <Boolean>`

If true, this key forces a Ctrl-Alt-Del sequence to force a dirty shutdown of 
GEOS. This defaults to true.

	quickShutdownOnReset = true
	quickShutdownOnReset = false

#### reboot on reset

`reboot on reset = <Boolean>`

If true, this key causes a Ctrl-Alt-Del sequence to warm-boot the machine 
rather than exit quickly to DOS. The default is false.

	reboot on reset = true
	reboot on reset = false

#### selectDisplaysMenu

`selectDisplaysMenu = <Boolean>`

If true, this key reverses the left and right mouse buttons with respect to 
menus in some specific UIs. (For example, the left (select) button will open 
the menu, but the right (features) button will show and execute the default 
menu item.) The default is false.

	selectDisplaysMenu = true
	selectDisplaysMenu = false

#### selectRaises

`selectRaises = <Boolean>`

If true, this key causes a select-button click to raise the window in which the 
click occurred, if the window was behind other windows. The window will not 
be raised above other windows that are always kept on top (e.g. the help 
window and desk accessory applications). The default is true.

	selectRaises = true
	selectRaises = false

----------

### 9.2.9 keyboard

#### device

`device = <full device name>`

This key defines the keyboard in use. It must be the keyboard device's full 
name; in general, this should only be set by the Preferences manager 
application.

	device = U.S. Keyboard

#### driver

`driver = <driver file name>`

This key goes with the device key and defines the driver file name to be 
loaded. This should be set by the Preferences manager.

	driver = kbd.geo

#### keyboardTypematic

`keyboardTypematic = <number>`

This key defines both the repeat speed and delay before repeat for the 
keyboard. The number is an integer less than 128 (the high bit is ignored), 
and it is interpreted as three separate fields, as below:

	bit 7		ignored
	bit 6-5		DELAY (see below)
	bit 4-3		PE (exponent portion of repeat period)
	bit 2-0		PM (mantissa portion of repeat period)
	The delay is calculated by the following formula:
	delay = 1 second + (DELAY * 250 ms) +/- 20%
	The period is calculated by the following formula
	period = (8 + PM) * (2^PE) * 0.00417 seconds

If no typematic number is specified, GEOS sets the default to 44, which 
represents a medium delay and a medium repeat period.

	keyboardTypematic = 0				; short delay, fast repeat
	keyboardTypematic = 127				; long dalay, slow repeat

#### keyboardDoesLEDs

`keyboardDoesLEDs = <Boolean>`

If true, this key tells GEOS that the XT-class machine it's running on supports 
BIOS-updated LEDs for Num Lock, Caps Lock, and Scroll Lock. Most XT-class 
machines do not support updating these LEDs. This field is unnecessary on 
AT-class and more advanced machines.

	keyboardDoesLEDs = true
	keyboardDoesLEDs = false

#### keyboardAltGr

`keyboardAltGr = <Boolean>`

If true, this key makes the right Alt key function like Ctrl-Alt, as with many 
European setups.

	keyboardAltGr = true
	keyboardAltGr = false

#### keyboardShiftRelStr

`keyboardShiftRelStr = <Boolean>`

If true, this key makes the Shift keys release the Caps Lock, as with 
typewriters.

	keyboardShiftRelStr = true
	keyboardShiftRelStr = false

#### keyboardSwapCtrl

`keyboardSwapCtrl = <Boolean>`

If true, this key swaps the left Ctrl key with the Caps Lock key so the 
keyboard acts like many non-PC keyboards.

	keyboardSwapCtrl = true
	keyboardSwapCtrl = false

----------

### 9.2.10 label

This category keeps track of any customizations the user may have made to 
the list of label paper sizes. 

### count

`count = <number>`

This is the number of user-defined label sizes.

#### newSizes

`newSizes = <list of paper size codes>`

This list contains a list of all user-defined label sizes. The paper size 
information for each of these sizes will be stored in a catgory named 
[label*num*], where *num* is the three-letter code in this list.

#### order

`order = <list of paper size codes>`

This list contains a list of all label sizes in the order that the user wants them 
to appear in label size lists.

----------

### 9.2.11 label*num*

This category contains size and layout for a user-defined label size.

#### height

`height = <number>`

This field holds the label's height in points.

#### layout

`layout = <PageLayout value>`

This field holds the label's layout information.

#### name

`name = <string>`

This field holds the label's full name.

#### width

`width = <number>`

This field holds the label's width in points.

----------

### 9.2.12 link

These fields are used by the Remote File System Driver to describe the 
machine to other machines that wish to access its drives. You may specify a 
name for the machine by which others may identify it and also set up 
communications parameters.

#### baudRate

`baudRate = <number>`

This SerialBaud value defines the communication speed this machine 
supports for RFSD.

#### drives

`drives = <list of drives>`

Normally, all of your drives will be accessible by the remote machine. This 
field allows you to specify exactly which drives are accessible. For instance, 
to restrict remote machines to accessing your C: and E: drives, use the 
following entry:

	drives = {
	C: E:
	}

#### name

`name = <machine name>`

A string by which remote machines may identify you. When the remote 
machine sees your drives, their names will be  
<machine-name>-<drive-letter>:.

#### port

`port = <SerialPortNum>`

This number specifies which serial port is to be used for RFSD. 

----------

### 9.2.13 localization

The localization key defines various configuration aspects of the system as 
set by the user in the Preferences manager application. Each of the keys in 
this category specifies one aspect of the user's system, typically an aspect 
defined by the country the user lives in. Because all of these keys are set in 
the Preferences manager application, they are not listed here. In general, 
keys which encode characters or strings will do so using ASCII values (e.g. 
"decimalSeparator = 2E" means that '.' is the decimal separator). The kernel 
also provides a number of routines to get and set the localization parameters; 
for more information, see the chapter on Localization in the Concepts books.

----------

### 9.2.14 math

`coprocessor = <driver name>`

The math category allows the user to override the way GEOS normally treats 
math coprocessors. The single key (coprocessor) specifies the coprocessor 
library to use; the math library will load that particular library, and the 
library will check to ensure the proper coprocessor chip exists. If the chip is 
present, the library will be used; if the chip is absent, the math library will 
use software emulation of a coprocessor.

	coprocessor = none				; use software emulation
	coprocessor = intx87.geo					; Intel 80387, 80486
	coprocessor = intx8087.geo					; Intel 80287, 8087

----------

### 9.2.15 modem

The modem category defines the modems attached to the system. Each 
modem must have its name listed in the name list, and each modem named 
in the list must have its own category (see the modem name category, below).

#### modems

`modems = {<modem name list>}`

This key defines all the modems attached to the system. Each modem in the 
list must have its own category in the .INI file, as shown below.

	modems = My Modem
	modems = { My Slow Modem
		     My Fast Modem }

#### numberOfModems

`numberOfModems = <number>`

This key defines the number of modems specified in the modems list (above).

	numberOfModems = 1
	numberOfModems = 2

----------

### 9.2.16 *modem name*

Each modem listed in the modems keyword in the modem category must have 
its own category. The category is named for the modem name in the list. 
Thus, the following example shows that each modem in the system has its 
own category:

	[modem]
	numberOfModems = 2
	modems = {My Slow Modem
		     My Fast Modem }

	[My Slow Modem]
	port = COM1
	baudRate = 300
	toneDial = true
	parity = none
	wordLength = 8
	stopBits = 1
	handshake = software

	[My Fast Modem]
	port = COM3
	baudRate = 19200
	toneDial = true
	parity = none
	wordLength = 8
	stopBits = 1
	handshake = software

#### baudRate

`baudRate = <number>`

This key defines the modem`s baud rate.

	baudRate = 2400
	baudRate = 9600

#### handshake

`handshake = <hardware, software>`

This key indicates the type of handshake used by the modem. It must be one 
of the values specified.

	handshake = hardware
	handshake = software

#### parity

`parity = <none, even, odd, mark, space>`

This key indicates the modem's parity type. It must be one of the values 
shown above.

	parity = none
	parity = even

#### stopBits

`stopBits = <number>`

This key specifies the number of stop bits used by the modem. This should be 
1, 1.5, or 2.

	stopBits = 1
	stopBits = 1.5
	stopBits = 2

#### stopLocal

`stopLocal = <dsr, dcd, cts>`

If hardware handshaking is used, this key specifies which line the serial 
driver will watch for the stop signal.

	stopLocal = dsr
	stopLocal = dcd
	stopLocal = cts

#### stopRemote

`stopRemote = <dtr, rts>`

If hardware handshaking is used, this key specifies which line the serial 
driver will use to make the remote side of the connection stop.

	stopRemote = dtr
	stopRemote = rts

#### toneDial

`toneDial = <Boolean>`

If true, this key indicates that the modem may use tone dialing. The default 
is true.

	toneDial = true
	toneDial = false

#### wordLength

`wordLength = <number>`

This key indicates the communication word length. This should be a number 
between five and eight inclusive.

	wordLength = 8

----------

### 9.2.17 mouse

The mouse category defines the mouse driver and specifics of the mouse 
attached to the GEOS system. Both the device and driver keys are required; 
the others are optional.

#### device

`device = <device name>`

This key defines the type of mouse attached. It must be the full device name 
and is typically set during setup of the system.

	device = Logitech Bus Mouse
	device = No idea

#### driver

`driver = <file name>`

This key defines the file name of the mouse driver in use.

	logibus.geo
	logibuse.geo
	genmouse.geo

#### info

`info = <number>`

This key defines the "extra word" of data for the mouse. This is an internal 
structure set by the mouse driver.

#### irq

`irq = <number>`

This key allows you to set the interrupt level of a mouse that needs it; most 
mice do not need to be told their interrupt level.

	irq = 4

#### port

`port = <number>`

This key specifies the port of a serial mouse, if necessary. The port number is 
one, two, three, or four, appropriate to the COM port being used.

	port = 3

----------

### 9.2.18 net library

`InitDrivers = { <list of driver geodes> }`

This is a list of network drivers to use. The Net library will attempt to load 
these driver geodes.

----------

### 9.2.19 paper

This category keeps track of any customizations the user may have made to 
the list of paper sizes. 

#### count

`count = <number>`

This is the number of user-defined paper sizes.

#### newSizes

`newSizes = <list of paper size codes>`

This list contains a list of all user-defined paper sizes. The paper size 
information for each of these sizes will be stored in a catgory named 
[paper*num*], where *num* is the three-letter code in this list.

#### order

`order = <list of paper size codes>`

This list contains a list of all paper sizes in the order that the user wants 
them to appear in paper size lists.

----------

### 9.2.20 paper*num*

This category contains size and layout for a user-defined paper size.

#### height

`height = <number>`

This field holds the page's height in points.

#### layout

`layout = <PageLayout value>`

This field holds the paper's layout information.

#### name

`name = <string>`

This field holds the paper's full name.

#### width

`width = <number>`

This field holds the paper's width in points.

----------

### 9.2.21 parallel

`port <number> = <level>`

The parallel category defines all the parallel ports available on the machine 
running GEOS. If a port is not defined in this category, GEOS will not 
recognize its existence. The single key in this category may be used 
numerous times, once for each available parallel port.

The port key defines the hardware interrupt level for the specified port. The 
normal entries for the three base parallel ports are shown in the examples 
below. If no level is provided for a port, the parallel driver will assign the 
values shown below; if no interrupt level is available for a port, GEOS will 
instead spawn a background thread for it. Setting any port's value will 
override other defaults (e.g. if you set port two to have level seven, port one 
will be set to level five, unless GEOS is on an XT- or PC-class machine).

	port 1 = 7
	port 2 = 5
	port 3 = 0

----------

### 9.2.22 paths

The paths category defines other directories to add into a standard path as 
well as additional INI files and the location of the shared token database. 
Adding directories to standard paths is useful both in network situations and 
if you want your application installed in a special directory but linked to the 
WORLD directory. This category uses five different keys, as shown below.

#### standard paths

`<standard path> = <additional paths>`

Each standard path is its own key, and you can merge other directories into 
any standard path. Some examples are shown below.

	top = C:\GEOWORKS C:\PCGEOS
	world = E:\INSTALL\NEWAPP
	userdata font = N:\NETFONTS F:\SPECFONT

#### ini

`ini = <file names>`

This key defines up to three additional INI files to be loaded read-only. When 
GEOS searches for a key, the local (current) INI file is scanned first, followed 
by the additional INI files in the order they're defined. The first occasion of 
the key will be used; thus, the local INI file can supersede other settings.

	ini = personal.ini INI\mydevice.ini n:\shared.ini

#### inisaved

`inisaved = <files>`

This key is used only if GEOS is run with the /psaved argument. That is, if 
the user runs GEOS thus:

	C>GEOS /psaved

then GEOS will look for the inisaved key rather than the ini key for additional 
INI files. Similarly, if the user instead runs

	C>GEOS /pxxx

GEOS will look for a key called inixxx for the names of the files to be used.

	inisaved = net.ini
	inisaved = demo.ini net.ini

#### sharedTokenDatabase

`sharedTokenDatabase = <path>`

This key defines the location of the shared token database file. This key is 
most useful in network situations, when many users may be sharing a single 
token database.

	sharedTokenDatabase = N:\NETFILES\TOKEN_DA.000

----------

### 9.2.23 printer

The printer category defines all the printers configured for the system 
running GEOS. The printers key within this category (see below) defines the 
printer names, each of which must then have its own category in the INI file 
(see the following section under printer device name).

#### count

`count = <number>`

This key indicates the number of printers installed.

	count = 0			; no printers installed
	count = 2			; two printers installed

#### defaultPrinter

`defaultPrinter = <number>`

This key specifies the number of the installed printer that will act as the 
default device.

	defaultPrinter = 2				; printer #2 is the default

#### numFacsimiles

`numFacsimiles = <number>`

This key specifies the number of installed print devices which are actually 
fax drivers rather than printer drivers.

	numFacsimiles = 1

#### numPrinters

`numPrinters = <number>`

This key specifies the number of installed print devices which are actually 
printers (as opposed to faxes or other devices).

	numPrinters = 2

#### printers

`printers = {<list of devices>}`

This key defines all the installed print devices. Each entry in the list is the 
device name; the list must be a blob, with one printer named per line as in 
the example below. Each entry in the list must also have its own category 
defining the driver, device name, port, and type.

	printers = { My Printer
			 My PostScript to file }

----------

### 9.2.24 *printer device name*

Each printer defined in the printers key of the printer category (see above) 
must have its own category. The name of the category must be the same as 
the printer named in the installed printers list of the printer category. The 
keys below define the printer's characteristics.

#### baudRate

`baudRate = <number>`

This key defines the printer's communication rate, for those printers which 
communicate via a serial connection.

#### device

`device = <device name>`

This key defines the device name of the installed print device.

	device = Apple LaserWriter Plus v38.0 (PostScript)

#### driver

`driver = <file name>`

This key defines the print driver used for the installed print device.

	driver = PostScript driver

#### handshake

`handshake = <hardware, software>`

This key indicates the type of handshake used by the printer for those 
printers which communciate via a serial connection. It must be one of the 
values specified above.

	handshake = hardware
	handshake = software

#### parity

`parity = <none, even, odd, mark, space>`

This key indicates the printer's parity type for those printers which 
communicate via a serial connection. It must be one of the values shown 
above.

	parity = none
	parity = even

#### port

`port = <port name>`

This key specifies the port to which the device is attached. This must be one 
of the values shown in the following examples.

	port = LPT1
	port = LPT2
	port = LPT3
	
	port = COM1
	port = COM2
	port = COM3
	port = COM4

	port = FILE

#### stopBits

`stopBits = <number>`

This key specifies the number of stop bits used by the  printer for those 
printers which communciate via a serial connection. This should be 1, 1.5, or 
2.

	stopBits = 1
	stopBits = 1.5
	stopBits = 2

#### type

`type = <number>`

This key defines the type of device this installed print device is. The number 
indicates the PrinterDriverType as defined in spool.goh.

	type = 0		; PDT_PRINTER
	type = 3		; PDT_CAMERA

#### wordLength

`wordLength = <number>`

This key indicates the communication word length  for those printers which 
communciate via a serial connection. This should be a number between five 
and eight inclusive.

	wordLength = 8

----------

### 9.2.25 screen 0

The screen N category is used to define the characteristics of each screen in 
the system. Currently, GEOS completely supports only one screen, which is 
called screen 0. This screen's characteristics are defined by the screen 0 
category.

#### device

`device = <device name>`

This key specifies the full device name of the screen's device. The standard 
devices are shown in the examples below.

	device = Hercules HGC: 720x348 Mono
	device = IBM MCGA: 640x480 Mono
	device = CGA: 640x200 Mono
	device = EGA: 640x350 16-color
	device = VGA: 640x480 16-color

#### driver

`driver = <file name>`

This key specifies the file name of the driver used to run this screen.

	driver = vga.geo

#### olddevice

`olddevice = <device name>`

When the user switches between video drivers, the system keeps track of the 
old device name in case the user made a mistake and wants to switch back. 
It will store the old value of the "device" field in this field.

#### olddriver

`olddriver = <file name>`

When the user switches between video drivers, the system keeps track of the 
old driver name in case the user made a mistake and wants to switch back. 
It will store the old value of the "driver" field in this field.

#### userdevice

`userdevice = <device name>`

GEOS doesn't use this field. The Debug utility uses this field to store the 
user's personal video device choice when simulating hardware devices that 
would not support the choice.

#### userdriver

`userdriver = <file name>`

GEOS doesn't use this field. The Debug utility uses this field to store the 
user's personal video driver choice when simulating hardware devices that 
would not support the choice.

----------

### 9.2.26 serial

`port <number> = <level>`

The serial category defines all the serial ports available on the machine 
running GEOS. If a port is not defined in this category, GEOS will not 
recognize its existence. The single key in this category may be used 
numerous times, once for each available serial port.

The port key defines the hardware interrupt level for the specified port. The 
normal entries for the four base serial ports are shown in the examples below. 
If no value is specified, GEOS will try to generate an interrupt for the port and 
set the value itself. (It only checks levels three and four, though.) Note also 
that on an AT-class machine, level two for a card is actually level nine 
specified here.

	port 1 = 4
	port 2 = 3
	port 3 = 4			; may not work if port 1 is in use
	port 4 = 3			; may not work if port 2 is in use

----------

### 9.2.27 sound

The sound category is used by the sound library to determine which sound 
driver is selected for the system running GEOS.

#### sampleDriver

`sampleDriver = <driver file name>`

This key specifies the sound driver that will be used to process all the 
sampled sounds produced by the system. If this key is not set, the standard 
sound driver (standard.geo) will be used.

	sampleDriver = sblaster.geo

#### synthDriver

`synthDriver = <driver file name>`

This key specifies the sound driver that will be used for all synthesized 
sounds (beeps, UI sounds, etc.) If this key is not set, the standard sound 
driver (standard.geo) will be used.

	synthDriver = standard.geo

----------

### 9.2.28 spool

`simpleUI = <Boolean>`

The spool category has a single key used by the print spooler to configure its 
user interface. If true, the simpleUI key will display only a simple UI scheme; 
this is especially useful for small-screen devices because it significantly 
reduces the size of the print control dialog box. The default is false.

	simpleUI = true
	simpleUI = false

----------

### 9.2.29 system

The system category defines system configuration and setup. Most of the keys 
in this category are set and maintained by the Preferences manager 
application. These keys, with their formats and possible values, are shown in 
the following sections.

#### continueSetup

`continueSetup = <Boolean>`

If this key is set true, GEOS will begin by running the graphical setup 
program in the proper setup modes. If false, GEOS will bypass the graphical 
setup. After running, the graphical setup program will reset this field to 
false. This field overrides the execOnStartup key of the ui category.

	continueSetup = true
	continueSetup = false

#### drive

`drive <letter> = <number>`

This key allows you to override the drive-map initialization done by the 
primary filesystem driver. You can not make a driver believe a nonexistent 
drive exists, but you can change the presumed media or make the driver 
ignore a drive. More than one drive may be remapped.

The letter argument is the drive letter of the drive to be remapped. The 
number argument defines the new drive definition and is one of the following 
values:

	  -1		fixed disk
	   0		ignore the drive
	 360		360 K 5.25-inch disk
	 720		720 K 3.5-inch disk
	1200		1.2 meg 5.25-inch disk
	1440		1.44 meg 3.5-inch disk
	2880		2.88 meg 3.5-inch disk

Some examples of drive remappings are shown below:

	drive d = 0			; ignore drive D:
	drive a = 360		; make GEOS think drive A: is 360K

#### font

`font = <driver file names>`

This key causes the named font driver to be loaded. If this key doesn't exist, 
**nimbus.geo** will automatically be loaded (the default driver). More than one 
driver may be specified on a single line or in a blob format, as shown in the 
examples below. (Note, though, that at current only nimbus.geo is 
recognized.)

	font = nimbus.geo otherdrv.geo
	font = { nimbus.geo
		   otherdrv.geo }

#### fontid

`fontid = <font name>`

This key specifies the default font used in the event a requested font does not 
exist. This font will also be used when putting up system alert boxes (such as 
Abort/Retry boxes). The only available default font currently is Berkeley; 
typically, this will be a bitmap font rather than an outline font.

	fontid = berkeley

#### fontmenu

`fontmenu = <string of numbers>`

This field specifies the order of fonts which should appear in font menus 
presented by font control objects. This is encoded as a string of numbers, four 
hex digits for each font, those four digits containing the font ID of the 
appropriate font. Thus, if the font ID's for the URW Roman and Berkeley fonts 
are 0x3000 and 0x0202, respectively, then if they are to be the first fonts in 
the font menu, the fontmenu field would read:

	fontmenu = 30000202

#### fontsize

`fontsize = <number>`

This key specifies the point size of the default font. If an application requests 
a font that can't be found, the default point size specified here is used with 
the font specified with fontid. Berkeley supports 9, 10, 12, 14, and 18, though 
18 is normally too large for many applications.

	fontsize = 10

#### fonttool

`fontmenu = <string of numbers>`

This field specifies the order of fonts which should appear in font pop-up list 
presented by font control objects. This is encoded as a string of numbers, four 
hex digits for each font, those four digits containing the font ID of the 
appropriate font. Thus, if the font ID's for the URW Roman and Berkeley fonts 
are 0x3000 and 0x0202, respectively, then if they are to be the first fonts in 
the font pop-up list, the fontool field would read:

	fonttool = 30000202

#### fs

`fs = <driver file names>`

This key defines the file system drivers to be loaded. The kernel will by 
default attempt to load the primary IFS driver for the detected version of 
DOS; if it can not determine the primary IFS driver, the proper driver must 
be specified in the INI file under this key. Multiple file system drivers may be 
specified either on a single line or in blob format. The current secondary IFS 
drivers available are

**netware.geo**  
Used for Novell Netware systems.

**msnet.geo**  
Used for LANtastic and other networks that support the 
standard DOS device redirection calls.

**cdrom.geo**  
Used for CD-ROM drives accessed through MSCDEX.EXE.

	fs = netware.geo
	fs = { msnet.geo
		 cdrom.geo }

#### handles

`handles = <number>`

This key specifies the number of handles GEOS should set as the maximum 
in the handle table. This should be set to something most likely 2000 or 
above, and it may be set in the Preferences manager application. If nothing 
is set in this key, the kernel will assume a default of 1000 handles.

	handles = 2000

#### inkTimeout

`inkTimeout = <number>`

This key sets the number of ticks (60 ticks in a second) the system will wait 
after the user has stopped drawing before processing ink input. The default 
is nine tenths of a second, or 54.

	inkTimeout = 54

#### maxTotalHeapSpace

`maxTotalHeapSpace = <size of heap in paragraphs>`

This field causes the **GeodeLoad()** routine to operate in transparent launch 
mode. The value given represents the overall size of the heap, in paragraphs, 
excepting system libraries that are always in memory. It should be 
determined on the target machine itself, by starting up, then running the 
TCL function "heapspace total". A common value for this field is around 
31000.

#### memory

`memory = <driver file names>`

This key defines the swap drivers that should be loaded. Swap drivers allow 
GEOS to use memory above the conventional 640 K. The kernel attempts to 
determine what type of memory is available and load the appropriate swap 
driver. This key is settable by the user with the Preferences manager 
application. The four driver names recognized are

**emm.geo**  
LIM 4.0 standard expanded memory driver. A DOS-level 
memory driver must be loaded (e.g. EMM.SYS), typically in 
CONFIG.SYS.

**extmem.geo**  
80286 extended memory driver.

**xms.geo**  
XMS/HIMEM.SYS driver. A DOS-level driver must also be loaded 
(e.g. HIMEM.SYS), typically in CONFIG.SYS.

**disk.geo**  
Disk swap driver. This should be loaded in all cases where a 
disk swap file is desired.

	memory = disk.geo
	memory = { disk.geo
		     xms.geo }

#### noFontDriver

`noFontDriver = <Boolean>`

If true, this key tells GEOS not to load the font driver; this is useful only when 
it is known beforehand that outline fonts are not available; it will reduce 
startup time of GEOS. If the key does not exist, it defaults to false. If used 
improperly, this key can cause bad things to happen in the system.

	noFontDriver = true
	noFontDriver = false

#### notes

`notes = <string>`

This field isn't used by GEOS proper. The Debug utility will search for this 
field when looking for text describing a platform which the .ini file simulates.

#### noVidMem

`noVidMem = <Boolean>`

If true, this key tells GEOS not to load the vidmem driver, which is used for 
printing; it will reduce startup time of GEOS and should be used only if it is 
known beforehand that printing will not be attempted. If the key does not 
exist, it defaults to false. If used improperly, this key can cause bad things to 
happen in the system.

	noVidMem = true
	noVidMem = false

#### pda

`pda = <Boolean>`

This field indicates whether GEOS is running on a PDA device. Currently this 
field is only used by the UI to provide alternate error strings. 

#### penBased

`penBased = <Boolean>`

If true, this key tells GEOS that it is running on a pen-based system and that 
some objects will want to receive ink or other pen input. If the key is not set, 
it defaults to false.

	penBased = true
	penBased = false

#### power

`power = <driver file name>`

This key defines the power management drivers to be loaded, if any. If no 
driver is specified, the kernel will try to identify whether one is needed and 
then load it if necessary.

	power = casio.geo

#### serialNumber

`serialNumber = <number>`

This key holds a predefined serial number for use by developers. This number 
will be given to you by Geoworks either directly or in the package you receive 
containing GEOS. Normally, this number is entered by the user when GEOS 
first finishes its graphical setup program.

#### setupMode

`setupMode = <number>`

This key indicates the mode of the graphical setup program. This should be 
a number from zero to three; for full graphical setup, set it to zero. Other 
modes are internal in nature and should not be set.

	setupMode = 0

#### splashColor

`splashColor = <Color value>`

If the splashscreen option has been turned on, this field will determine the 
background color of any text splash screens shown.

#### splashscreen

`splashscreen = <Boolean>`

This permits the GEOS loader to display a message on one of the five simple 
graphics mode screens while GEOS is loading.

#### splashText

`splashText = <string>`

If the splashscreen option has been turned on, this field will determine the 
text of the message to display.

----------

### 9.2.30 text

The text category defines various characteristics of GEOS for the text objects, 
the spelling checker, and localization.

#### autoCheckSelections

`autoCheckSelections = <Boolean>`

If true, this key instructs the spelling checker to check the spelling of the 
selected text automatically when the user brings up the spell-check box. The 
default is true.

	autoCheckSelections = true
	autoCheckSelections = false

#### autoSuggest

`autoSuggest = <Boolean>`

If true, this key instructs the spelling checker to suggest other spellings 
automatically if a misspelling is found. The default is false.

	autoSuggest = true
	autoSuggest = false

#### dialect

`dialect = <dialect code>`

This key defines the dialect code used by the dictionary for spelling. Different 
dictionaries use different dialects within their own language. The Each 
dialect is represented by a number; the default setting is 128. The different 
dialects are listed below, by dictionary.

	English		 32	IZE British		(realize/colour)
				 64	ISE British		(realise/colour)
				128	American		(realize/color)

	Dutch		 64	Standard and non-preferred forms
				128	Standard Dutch forms only

	French		 64	Accents on uppercase characters
				128	No accents on uppercase characters

	German		 64	German Doppel s
				128	German Scharfes s

	Norwegian	 64	Nynorsk standard
				128	Bokmal standard

	Portuguese	 64	Brazilian Portuguese
				128	Iberian Portuguese

Some examples of setting the dialect are shown below.

	dialect = 64
	dialect = 128

#### dictionary

`dictionary = <file name>`

This key allows the user or the Preferences manager application to set the 
dictionary used by the spelling checker. The dictionary is set by specifying 
the file name of the dictionary data file; the default value is that for the 
English dictionary.

	dictionary = IDNF9111.DAT					; Danish
	dictionary = IENC9121.DAT					; English
	dictionary = IFRF9121.DAT					; French
	dictionary = IGRF9112.DAT					; German
	dictionary = IITF9110.DAT					; Italian
	dictionary = IPOF9110.DAT					; Portuguese
	dictionary = ISPF9110.DAT					; Spanish

#### language

`language = <number>`

This key specifies the language in use by GEOS. The number is a language 
code (as shown in the examples below), and the user may set the language 
with the Preferences manager application. The default is English, 16.

	language = 5				; French
	language = 6				; German
	language = 7				; Swedish
	language = 8				; Spanish
	language = 9				; Italian
	language = 10				; Danish
	language = 11				; Dutch
	language = 12				; Portuguese
	language = 13				; Norwegian
	language = 14				; Finnish
	language = 15				; Swiss
	language = 16				; English

#### languageName

`languageName = <name of language>`

This key specifies the name of the language in use; the default is American 
English. This key is normally set by the Preferences manager application.

	languageName = American English

#### resetSkippedWordsWhenBoxCloses

`resetSkippedWordsWhenBoxCloses = <Boolean>`

If true, this key instructs the spelling checker to reset its list of skipped 
words when the user closes the spelling check box. The default is true.

	resetSkippedWordsWhenBoxCloses = true
	resetSkippedWordsWhenBoxCloses = false

#### smartQuotes

`smartQuotes = <Boolean>`

If true, this key instructs the text object to use "smart quotes," quotation 
marks that curl themselves appropriately to their positions when typed. If 
this key is false, standard typewriter-style quotation marks will be used. The 
default is false; this is settable by the user in the Preferences manager 
application.

	smartQuotes = true
	smartQuotes = false

----------

### 9.2.31 ui

#### autosave

`autosave = <Boolean>`

If true, this key tells GEOS to turn on the automatic backup feature; this may 
be set in the Preferences manager application.

	autosave = true
	autosave = false

#### autosaveTime

`autosaveTime = <number>`

This key indicates the number of seconds between autosave operations, if the 
autosave keyword is set to true. This may be set with the Preferences 
manager application.

	autosaveTime = 300

#### background

`background = <filename>`

This key defines the file containing the picture to use as the background 
graphic. This is normally set by the Preferences manager application.

	background = Bricks

#### backgroundattr

`backgroundattr = <t, c, or x>`

This key defines how the background picture should be displayed; it is 
normally set by the Preferences manager application.

**t** - Tile the picture.

**c** - Center the picture on the screen.

**x** - Place picture in upper-left corner of the screen.

	backgroundattr = c
	backgroundattr = t

#### backgroundcolor

`backgroundcolor = <number>`

This key defines the color of the background graphic. This is normally set by 
the Preferences manager application. The number is the color index of the 
color to be used.

	backgroundcolor = 0
	backgroundcolor = 12

#### deleteStateFilesAfterCrash

`deleteStateFilesAfterCrash = <Boolean>`

If true, this key tells GEOS to delete state files after every non-clean 
shutdown. If you set this, you will probably want to set the 
doNotDisplayResetBox key true as well.

	deleteStateFilesAfterCrash = true
	deleteStateFilesAfterCrash = false

#### doNotDisplayResetBox

`doNotDisplayResetBox = <Boolean>`

If true, this key tells GEOS not to display the system dialog box asking 
whether the user wants to reset the system or not after a crash. If you set this 
true, you should also set deleteStateFilesAfterCrash true, or some crashes 
may allow bad state files to keep GEOS from restarting properly.

	doNotDisplayResetBox = true
	doNotDisplayResetBox = false

#### execOnStartup

`execOnStartup = <program list>`

This key defines applications to be run when the UI is loaded (when GEOS 
starts up), named for their GEOS long names. The default is not to execute 
any additional programs.

	execOnStartup = {Lights Out Launcher
					 CD Player Application }

#### generic

`generic = <file name>`

This key defines the generic UI library that is to be used by GEOS. You will 
not need to set this; it will default to ui.geo.

	generic = ui.geo
	generic = uiec.geo

#### hardIconsLibrary

`hardIconsLibrary = <string>`

This is the long name of the library which provides the hard icon UI for a 
PC-based demo of a PDA device.

#### haveEnvironmentApp

`haveEnvironmentApp = <Boolean>`

If true, this key indicates that GEOS is using an environment application 
such as Welcome. If an environment application is being used, that 
application must be specified in the defaultLauncher key in the uiFeatures 
category. During debugging, you may set this key false and set the 
execOnStartup key to the application you're debugging to have GEOS come up 
directly into your application.

	haveEnvironmentApp = true
	haveEnvironmentApp = false

#### hwr

`hwr = <file name>`

This key indicates the handwriting recognition library to be loaded, if any. If 
GEOS is not on a pen-based system (penBased = true in the system category), 
then no handwriting recognition library will be loaded.

	hwr = palm.geo

#### kbdAcceleratorMode

kbdAcceleratorMode = <Boolean>

If false , this key tells GEOS to ignore keyboard accelerators. By default, this 
is true and keyboard accelerators are allowed; this is independent of whether 
the accelerators are drawn or not. See also the uiFeatures category's 
windowOptions key.

	kbdAcceleratorMode = true
	kbdAcceleratorMode = false

#### noClipboard

`noClipboard = <Boolean>`

If true, this key prevents the UI from opening the clipboard file on startup. 
This is an optimization used when we want to open the clipboard only later 
on in a particular application.

#### noSpooler

`noSpooler = <Boolean>`

If true, this key prevents the UI from launching the spooler. This can be used 
to improve startup time if the system running GEOS knows beforehand that 
the spooler is not required. Very few systems will set this true.

	noSpooler = true
	noSpooler = false

#### noTaskSwitcher

`noTaskSwitcher = <Boolean>`

If true, this key prevents the UI from loading a task switch driver. This may 
be used to improve startup time if the system running GEOS knows in 
advance it will never use a task switcher.

	noTaskSwitcher = true
	noTaskSwitcher = false

#### noTokenDatabase

`noTokenDatabase = <Boolean>`

If true, this key prevents the token database from being initialized. This is 
useful as an optimization when GEOS will not need icons-that is, when 
GEOS starts up and runs just a single application.

	noTokenDatabase = true
	noTokenDatabase = false

#### overstrikeMode

`overstrikeMode = <Boolean>`

If false , this key prevents the user from switching into overstrike mode; it 
defaults to true, and it is settable in the Preferences manager application.

	overstrikeMode = true
	overstrikeMode = false

#### password

`password = <Boolean>`

This field turns the system password on or off.

#### passwordText

`passwordText = <string>`

Encrypted text of the password string, if any.

#### penInputDisplayType

`penInputDisplayType = <number>`

This key defines the PenInputDisplayType to be shown when the 
PenInputControl object is brought up. The PenInputControl object displays 
the floating keyboard in one of several display types. See the 
PenInputDisplayType enumerated type for definitions of its values.

	penInputDisplayType = 1					; floating keyboard
	penInputDisplayType = 7					; handwriting area

#### productName

`productName = <name>`

This key holds the string displayed in the GEOS shutdown dialog box; for 
example, it will put up a string similar to "Are you sure you want to exit 
`<productName>`?"

	productName = GEOS

#### screenBlanker

`screenBlanker = <Boolean>`

If this field true, then the user wishes to save the screen after an idle time 
period specified by means of the screenBlankerTimeout field.

#### screenBlankerTimeout

`screenBlankerTimeout = <number of minutes>`

If the user has turned on screen blanking, this is the number of minutes the 
system will stand idle before screen-saving turns on.

#### showTitleScreen

`showTitleScreen = <Boolean>`

If true, this key instructs GEOS to put up a title screen. This defaults to false.

	showTitleScreen = true
	showTitleScreen = false

#### sound

`sound = <Boolean>`

If true, this key instructs GEOS to turn sound on. If it's false, sound will be 
off. This is settable by the Preferences manager application.

	sound = true
	sound = false

#### specific

`specific = <file name>`

This key defines specific UI libraries to be loaded by GEOS. It defaults to 
motif.geo.

	specific = motif.geo

#### tinyScreen

`tinyScreen = <Boolean>`

If true, this key tells GEOS that it's running on a small-screened device such 
as the Zoomer; it defaults to false. You can use this key during development 
if you're working on applications for a small-screen platform; it affects 
certain characteristics of the UI.

	tinyScreen = true
	tinyScreen = false

#### unbuildControllers

`unbuildControllers = <Boolean>`

If true, the UI will destroy the child blocks of controllers when the controller's 
menu/dialog box is closed. The child block will have to be regenerated every 
time the menu/dialog is opened-this is a memory for time tradeoff.

#### xScreenSize

`xScreenSize = <number>`

This key tells GEOS the screen width, in GEOS coordinates. If this key isn't 
set explicitly, the kernel will set it to the default screen size. This key is used 
primarily when developing for small-screen platforms such as Zoomer.

	xScreenSize = 256

#### yScreenSize

`yScreenSize = <number>`

This key tells GEOS the screen height, in GEOS coordinates. If this key isn't 
set explicitly, the kernel will set it to the default screen size. This key is used 
primarily when developing for small-screen platforms such as Zoomer.

	yScreenSize = 344

----------

### 9.2.32 *specific ui name*

Each specific UI may have a category with options; this category should be 
named after the specific UI, e.g. [motif].

#### fontid

`fontid = <font>`

This field allows the user to specify a font that the specific UI should use 
when drawing text monikers for gadgets such as menus and buttons.

#### fontsize

`fontsize = <size in points>`

This field allows the user to specify a font size that the specific UI should use 
when drawing text monikers for gadgets such as menus and buttons.

----------

### 9.2.33 ui features

The ui features category defines the UI configuration used by the 
environment application (e.g. Welcome) and all applications on the 
execOnStartup list in the ui category. On systems with no environment 
application, this category defines the UI configuration for all applications.

Related categories, uiFeatures - intro, uiFeatures - beginner, and 
uiFeatures - advanced, support the same keys. Each of these categories 
defines the configuration for a specific "room" of the Welcome application. 
Other environment applications will also use these keys for different 
"rooms."

#### backupDir

`backupDir = <relative path>`

This key defines the directory in which the document control object will place 
quick-backup copies of document files. The default is PRIVDATA\BACKUP.

	backupDir = DOCUMENT\BACKUP

#### defaultLauncher

`defaultLauncher = <relative path>`

This key defines the directory and application that acts as the default 
application launcher. This key should always have some application 
specified; otherwise, no application will start when GEOS loads. The path 
specified should be relative to the WORLD directory.

	defaultLauncher = Utilities\GeoManager

#### docControlFSLevel

`docControlFSLevel = <number>`

This key specifies the document control's file selector user level. The file 
selector box has three different configurations; set the appropriate number 
(below) to determine which configuration is used.

	0		No directories
	1		Directories shown, simple UI configuration
	2,3		Directories shown, complete UI configuration

An example of setting the file selector level is shown below.

	docControlFSLevel = 2

#### docControlOptions

`docControlOptions = <number>`

This key turns on or off a number of other features in the document control 
object. The features are controlled by the bits set or clear in the number 
given. The five most significant bits of a 16-bit integer are used and have the 
following meanings, from most significant bit:

DCO\_BYPASS\_BIG_DIALOG  
If set, this indicates that the big dialog box normally presented 
for New File/Open File/Use Template operations should be 
bypassed (not used). For advanced users, this bit should be 
clear. For novice users, this bit should be set.

DCO\_TRANSPARENT_DOC  
If set, this indicates that a "Switch Document" metaphor 
should be used in place of the New/Open/Close metaphor for 
document management. This will allow only a single document 
open at a time and will immediately prompt if no document is 
open. For introductory and novice users, this bit should be set.

DCO\_HAVE\_FILE_OPEN  
If set, this indicates that there is an Open button in the File 
menu (subject to specific UI rules). This is typically not set.

DCO\_FS\_CANNOT_CHANGE  
If set, this indicates that the file selector used by the document 
control object can not change configuration; that is, the file 
selector will not offer the option of switching between full and 
simple configurations.

DCO\_NAVIGATE\_ABOVE_DOC  
If set, this indicates that the document control object's file 
selector will allow the user to navigate directories. If cleared, 
the user may not navigate above the default document 
directory.

Some examples of usage of the docControlOptions key are shown below, with 
their translations into bit representation (five most-significant bits only are 
shown).

	docControlOptions = 16384		; Introductory
									; 16384 = 0x4000 = 01000...
	docControlOptions = 0			; Beginner
									; 0 = 0x0 = 00000...
	docControlOptions = 4096		; Advanced
									; 4096 = 0x1000 = 00010...

#### expressOptions

`expressOptions = <number>`

This key defines the configuration of the express menu. It sets and clears 
features based on the least significant 11 bits of a 16-bit number. Each bit, 
from the most significant used (bit 10) down to the least significant, is 
detailed below.

UIEO\_GEOS\_TASKS_LIST  
If set, this indicates that the express menu should contain a list 
of currently-running applications.

UIEO\_DESK\_ACCESSORY_LIST  
If set, this indicates that the express menu should contain a list 
of applications in the World\Desk Accessories directory.

UIEO\_MAIN\_APPS_LIST  
If set, this indicates that the express menu should contain a list 
of applications in the World directory.

UIEO\_OTHER\_APPS_LIST  
If set, this indicates that the express menu should contain a 
hierarchical list of applications in subdirectories of the World 
directory.

UIEO\_CONTROL_PANEL  
If set, this indicates that the express menu should contain a 
control panel area.

UIEO\_DOS\_TASKS_LIST  
If set, this indicates that the express menu should contain a list 
of available DOS tasks accessible by a task switcher.

UIEO\_UTILITIES_PANEL  
If set, this indicates that the express menu should contain a 
utilities panel area.

UIEO\_EXIT\_TO_DOS  
If set, this indicates that the express menu should contain an 
"Exit to DOS" type of trigger.

UIEO_POSITION  
This is a three-bit field indicating where the express menu 
should appear. Three different values are allowed:

	0	No express menu
	1	In the top of the Primary window
	2	In the lower left (just below the bottom
		of the screen)

Some examples of this key are shown below.

	expressOptions = 617	; Introductory
							;  617 = 0x0269 = 0000 0010 0110 1001
							; The bits turned on are listed below:
							; UIEO_DESK_ACCESSORY_LIST
							; UIEO_CONTROL_PANEL
							; UIEO_DOS_TASKS_LIST
							; UIEO_EXIT_TO_DOS
							; UIEO_POSITION = 1, upper left of window
	expressOptions = 889	; Beginner
							;  889 = 0x0379 = 0000 0011 0111 1001
	expressOptions = 2041	; Advanced
							; 2041 = 0x07F9 = 0000 0111 1111 1001

#### helpOptions

`helpOptions = <number>`

This key defines the configuration used by the help controller object. 
Specifically, it determines whether the help controller will automatically 
provide help triggers in the GenPrimary and in dialog boxes. The default is 
to allow help triggers to be created and displayed. Only the least significant 
bit of a 16-bit number is used, and that bit's significance is shown below.

UIHO\_HIDE\_HELP_BUTTONS  
If set, this indicates that the help controller should not display 
help triggers in the GenPrimary or in dialog boxes.

	helpOptions = 1				; hide help triggers
	helpOptions = 0				; display help triggers

#### interfaceLevel

`interfaceLevel = <number>`

This key determines the interface level of applications that use the ui 
features category for their configurations. The four values allowed are shown 
in the examples below.

	interfaceLevel = 0				; Introductory
	interfaceLevel = 1				; Beginner
	interfaceLevel = 2				; Intermediate
	interfaceLevel = 3				; Advanced

#### interfaceOptions

`interfaceOptions = <number>`

This key determines two different features of the UI in general. It uses the 
two most significant bits of a 16-bit integer; the two bits have the following 
meanings.

UIIO\_OPTIONS_MENU  
If set, this indicates that an Options menu should exist.

UIIO\_DISABLE\_POPOUTS  
If set, this indicates that the UI should not allow GIV_POPOUT 
GenInteraction objects to pop in an out.

	interfaceOptions = 16384			; No Options menu
	interfactOptions = 32768			; Popouts not allowed

#### launchLevel

`launchLevel = <number>`

This key controls the interface level of the applications allowed to be 
launched under the particular field ("room" of the environment application). 
It allows four values as shown in the examples below.

	launchLevel = 0			; Introductory
	launchLevel = 1			; Beginner
	launchLevel = 2			; Intermediate
	launchLevel = 3			; Advanced

#### launchModel

`launchModel = <number>`

This key controls how applications are started and exited. It allows four 
values, each of which defines a different level of user.

	launchModel = 0			; Transparent (user does not
							; realize he is starting an
							; application)
	launchModel = 1			; Single instance only
	launchModel = 2			; Multiple instances allowed
	launchModel = 3			; Advanced features allowed

#### launchOptions

`launchOptions = <number>`

This key controls how applications are started and exited; specifically, it has 
a single flag which determines whether any applications are allowed to be in 
desk accessory mode. This defaults to true to allow desk accessories. The 
single flag is the most significant bit of a 16-bit integer.

UILO\_DESK_ACCESSORIES  
If set, this indicates that desk accessories should be allowed.

	launchOptions = 32768			; allow desk accessories
	launchOptions = 0				; do not allow them

#### quitOnClose

`quitOnClose = <Boolean>`

If true, this key forces the closure of all applications in a room before that 
room may be exited. This will cause state saving to be turned off. The default 
for this flag is false. One note: setting quitOnClose = true and launchModel =
 0 can result in undesirable behavior.

	quitOnClose = true
	quitOnClose = false

#### windowOptions

`windowOptions = <number>`

This key controls different window system options. The precise 
interpretation of each flag is up to the specific UI. The high 8 bits form a mask 
of the bits to affect. The low 8 bits indicated whether the masked bits should 
be turned on or off. Of the eight bits, the high one is meaningless; the seven 
flags are listed below. You should not set these, however, unless you are 
familiar with the workings of the UI and the specific UI.

UIWO\_MAXIMIZE\_ON_STARTUP  
If true, application primary windows will come up maximized. 
Desk accessory applications may override this behavior.

UIWO\_COMBINE\_HEADER\_AND\_MENU\_IN\_MAXIMIZED_WINDOWS  
If true, the title bar and menu bar areas of maximized windows 
will be combined to save screen space. Only the window 
gadgetry and menus are retained; title strings are eliminated.

UIWO\_PRIMARY\_MIN\_MAX\_RESTORE_CONTROLS  
If true, window gadgetry for maximizing, minimizing, and 
restoring the window will be included on the screen.

UIWO\_WINDOW_MENU  
If true, a Window menu for keyboard control of minimize, 
maximize, restore, move, resize, and close operations will be 
provided. If false, only a "close" button will appear in the 
menu's place.

UIWO\_PINNABLE_MENUS  
If true, menus will be pinnable.

UIWO\_KBD_NAVIGATION  
If true, keyboard accelerators and keyboard navigation will be 
enabled.

UIWO\_POPOUT\_MENU_BAR  
If true, menu bars will be allowed to pop out to be dialog boxes. 
This should be used in limited situations because specific UIs 
may not provide gadgetry to restore the menu bar if the dialog 
is closed.

----------

### 9.2.34 welcome

The welcome category defines configuration and usage characteristics of the 
Welcome environment application. Its keys may be useful to you during 
development, though you will probably not need them for your applications.

#### startupRoom

`startupRoom = <name of room>`

This key defines the room in which Welcome will start when GEOS is run. 
This is settable in the Preferences manager application; you will probably 
want to set this to the room most appropriate for your application to speed 
startup when debugging. The default is no setting, which will cause Welcome 
to present its title screen.

	startupRoom = 1				; Beginner
	startupRoom = 2				; Intermediate
	startupRoom = 3				; Advanced

[Resource Editor](tresed.md) <-- &nbsp;&nbsp; [Table of Contents](../tools.md) &nbsp;&nbsp; --> [Using Tools](ttools.md)