This monorepo is for creating code for the 16-bit PC/GEOS operating environment for DOS from the late 80s, early 90, also known as
GeoWorks Ensemble, Breadbox Ensemble, NewDeal Office.

The layout of the repo is:
Appl/ – sample + system apps (GeoWrite/GeoDraw-style code lives around here)
Library/ – GEOS libraries (UI, graphics, VM/DB, etc.)
Driver/ – DOS/video/mouse/printer drivers
Include/ - headers for ESP, the PC/GEOS object oriented assembler and link defs
CInclude/ – headers for GOC/C and link defs
Tools/ – source of build/debug tools (pmake, swat pieces, build scripts)
Loader/ – boot/loader bits
TechDocs/ – the SDK docs (use TechDocs/Markdown first, as it contains the latest version of the docs)
Installed/ - this folder contains "Appl", "Library" and "Driver" again. Code is being built here.
bin/ – where the tools land once they have been built.

GEOS Coding and Behavior Guidelines:
- Generate code in **GOC language**, which transpiles to **Watcom C 16-bit** using the `goc` tool.
- Generated code must follow the C89 standard: Variables must be declared at the **top of functions** (not blocks!), no new blocks are introduced solely for the purpose of introducing variables mid-function.
- Cast all void pointers like this: `(void*)0`.
- Always indent C-Code with 4 spaces, ASM (ESP) code with tabs according to the surrounding code.
- Put curly braces always on a new line when creating functions, for blocks inside a function put the opening `{` on the same line and the closing `}` on a new line.
- Memory management usually follows the `MemAlloc` (always use `HAF_ZERO_INIT` as the last parameter), `MemLock`, and `MemFree` pattern.
- Handles and pointers are always distinguished and named clearly with a trailing H for Handles and a trailing P for Pointers.
- Use `WWFixed` math instead of `float` whenever applicable.
- Callbacks must be constructed and used like this:
`
...
typedef Boolean _pascal ProgressCallback(word percent);
typedef Boolean _pascal pcfm_ProgressCallback(word percent, void *pf);
...
int _export _pascal ReadCGM(FileHandle srcFile,word settings, ProgressCallback *callback)
{
...
}
...
if(((pcfm_ProgressCallback *)ProcCallFixedOrMovable_pascal)(pct,callback))
{
...
}
`

By default, don't try to compile applications you've created. Setting up the system so that it can be used to compile "Geodes" (the GEOS executables) requires somes steps that can take up quite a bit of time. Only follow the following steps when requested to do so.

1) The system needs: perl sed wget unzip xdotool SDL2 SDL2_net

2) Install Open Watcom from here https://github.com/open-watcom/open-watcom-v2/releases/download/2020-12-01-Build/ow-snapshot.tar.gz

3) Add environment varaibles simililar to this:

export WATCOM=~/watcom
export ROOT_DIR=~/pcgeos
export LOCAL_ROOT=~
export PATH=$WATCOM/binl:$ROOT_DIR/bin:$PATH

4) Before an individual Geode can be compiled, the special GEOS tools must be compiled:

Build pmake tool:

    `cd %ROOT_DIR%/Tools/pmake/pmake
    wmake install`

Build all the other SDK Tools:

    `cd %ROOT_DIR%/Installed/Tools
    pmake install`

Build all PC/GEOS (target) components:

    `cd %ROOT_DIR%/Installed
    pmake`

5) To compile an individual Geode for testing (sample):

`cd %ROOT_DIR%/Installed/Appl/Bounce
yes | clean
mkmf
pmake depend
pmake -L 4 full
