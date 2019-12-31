## 2.6 Routines R-U

----------
#### RangeEnum
Enumerate all cells in a range of cells, calling a callback routine on each.

**Pass:**  
ds:si - Address of a **CellFunctionParameters** structure.  
ss:bp - Address (on stack) of local variables for callback.  
ss:bx - Address (on stack) of **RangeEnumParams** structure.  
dl - **RangeEnumFlags** record with any or all of the following:  
REF_ALL_CELLS - Use callback routine for all cells.  
REF_NO_LOCK - Callback routine will lock and unlock cells.  
REF_COLUMN_FLAGS - Get the **ColumnFlags** for this cell (passed in 
the **RangeEnumParams** structure).  
REF_MATCH_COLUMN_FLAGS - Use callback routine only for cells having 
matching **ColumnFlags** as those passed.

**Pass on stack:**  
NOTE: - These parameters are not to be popped; they are to be 
referenced by their pointers as specified. The stack frame will 
be passed to the callback, which also should not pop them.  
ss:bp - Local variables for callback routine.  
ss:bx - **RangeEnumParams** structure, with the following fields:  
*REP_callback* - Address of the callback routine to process the 
enumerated cells.  
*REP_bounds* - Rectangle structure giving the bounds of the 
range of cells to enumerate.  
*REP_columnFlags* - **ColumnFlags** record for the passed cell.  
*REP_columnFlagsArray* - Address of a **ColumnArrayHeader** 
structure.  
*REP_cfp* - Address of a **CellFunctionParameters** 
structure.  
*REP_matchFlags* - **ColumnFlags** record to indicate which flags 
must be set in a cell for it to be processed. 
Only valid if REF_MATCH_COLUMN_FLAGS 
set in dl.

**Returns:**  
CF - Set if callback routine forced an early abortion of the routine.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:**  
**Passed:**  
ds:si - Address of **CellFunctionParameters** as 
passed to **RangeEnum**.  
ax - Current cell row.  
cx - Current cell column.  
dl - **RangeEnumFlags** passed to **RangeEnum**.  
ss:bp - Address (on stack) of local variables for 
callback routine. See notes above for values 
passed on the stack.  
ss:bx - Address (on stack) of **RangeEnumParams** 
structure passed to **RangeEnum**. See notes 
above for values passed on the stack.
If REF_COLUMN_FLAGS set in **dl**, 
*REP_columnFlagsArray* is a pointer to a 
**ColumnArrayHeader** structure, and 
*REP_columnFlags* is the **ColumnFlags** 
record for the cell.  
CF - Set if the cell has data, clear otherwise.  
*es:di - Segment:Chunk handle of cell's data, if any.  
**Return:**  
CF - Set to abort **RangeEnum**, clear to continue.  
es - Updated segment address of the cell.  
dl - Modified **RangeEnumFlags** to potentially 
include the following flags:  
REF_CELL_ALLOCATED - Set if the callback routine allocated the cell 
for which the callback occurred.  
REF_CELL_FREED - Set if the callback routine freed the cell for 
which the callback occurred.  
REF_OTHER_ALLOC_OR_FREE - Set if the callback routine may have allocated 
or freed a cell other than the one for which 
the callback occurred.  
REF_COLUMN_FLAGS_MODIFIED - Set if the callback routine changed the 
**ColumnFlags** for the cell.  
**May Destroy:**  
Nothing.

**Library:** cell.def

**Warning:**   
If the caller passes REF_ALL_CELLS and REF_NO_LOCK, then the callback 
routine will not know if the cell being called back actually exists or not. In 
this case, the callback parameters ***es:di** and CF are undefined.

If the callback routine allocates the cell which was called back, it should not 
unlock the cell; **RangeEnum** will take care of this.

If the callback routine allocates a different cell, it must unlock the cell and 
return REF_OTHER_ALLOC_OR_FREE.

If the callback routine frees the cell called back, it must unlock the cell before 
freeing it. Otherwise, the block containing the freed cell can not be removed 
(the cell will always be locked). Also, the callback routine must return 
REF_CELL_FREED.

If the callback routine frees a different cell, it must unlock the cell before 
freeing the cell, as outlined above. Also, the callback must return 
REF_OTHER_ALLOC_OR_FREE.

If the callback routine changes the **ColumnFlags** of the cell, it must also 
change the data pointed at by *REP_columnFlagsArray* and return the flag 
REF_COLUMN_FLAGS_MODIFIED.

----------
#### RangeExists
Check for the existence of cells in a given range.

**Pass:**  
ds:si - Address of **CellFunctionParameters** structure.  
ax, cl - Row, Column of first cell in range (inclusive).  
dx, ch - Row, Column of last cell in range (inclusive).

**Returns:**  
CF - Set if one or more cells in the range contain data, clear 
otherwise.

**Destroyed:**  
Nothing.

**Library:** cell.def

----------
#### RangeInsert
Insert or delete a range of cells.

**Pass:**  
ds:si - Address of **CellFunctionParameters** structure.

**Pass on stack:**  
ss:bp - **RangeInsertParams** structure, with the following fields:  
RIP_bounds - Rectangle structure giving the bounds of 
the range to insert or delete.  
RIP_delta - Point structure indicating the distance to 
move the range.  
RIP_cfp - Address of a **CellFunctionParameters** 
block; this field should not be initialized by 
the caller (the others should).

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** cell.def

----------
#### RangeSort
Sort a range of cells either in ascending order or via callback routine.

**Pass:**  
ds:si - Address of **CellFunctionParameters** structure.

**Pass on stack:**  
ss:bp - **RangeSortParams** structure, with the following fields:  
RSP_range - Rectangle structure indicating the range of 
cells to be sorted.  
RSP_active - Point structure indicating the cell in the row 
and column to sort on.  
RSP_callback - Address of the sort callback routine.  
RSP_flags - **RangeSortFlags** record with one or more of 
the following flags set:  
RSF_SORT_ROWS - Sort rows in the range.  
RSF_SORT_ASCENDING - Sort in ascending order.  
RSF_IGNORE_CASE - Ignore case in string comparisons.  
RSF_IGNORE_SPACES - Ignore spaces and punctuation in the sort. 
This is not supported directly by the cell 
library but is put here for convenience.  
NOTE: - The following fields of **RangeSortParams** 
should not be initialized by the caller as they 
are used internally by **RangeSort**.  
*RSP_cfp* - CellFunctionParameters.  
*RSP_sourceChunk* - Chunk for swapping.  
*RSP_destChunk* - Chunk for swapping.  
*RSP_base* - Base position for sort.  
*RSP_lockedEntry* - Currently locked entry, or -1.  
*RSP_cachedFlags* - Flags.

**Returns:**  
ax - RangeSortError value:  
RSE_NO_ERROR - No error; the sort succeeded.  
RSE_UNABLE_TO_ALLOC - The sorting code was unable to allocate a 
temporary block necessary for sorting.

**Destroyed:**  
Nothing.

**Library:** cell.def

----------
#### RowGetFlags
Get flags for specified row.

**Pass:**  
ds:si - Pointer to **CellFunctionParameters** structure.  
ax - row number.

**Returns:**  
CF - Set if row exists; clear otherwise.  
dx - Flags for row (zero if row nonexistent).

**Destroyed:**  
Nothing.

**Library:** cell.def

----------
#### RowSetFlags
Set the flags for a given row.

**Pass:**  
ds:si - Pointer to **CellFunctionParameters** structure.  
ax - Row number.  
dx - Flags for row.

**Returns:**  
CF - Set if row exists; clear otherwise.

**Destroyed:**  
Nothing.

**Library:** cell.def

----------
#### RulerScaleDocToWinCoords
Scale a ruler point in document coordinates to window coordinates.

**Pass:**  
ds:si - Segment:Chunk handle of the VisRuler object.  
dx.cx.ax - **DWFixed** value of point to be scaled.

**Returns:**  
dx.cx.ax - **DWFixed** point, scaled.

**Destroyed:**  
Nothing.

**Library:** ruler.def

----------
#### RulerScaleWinToDocCoords
Scale a ruler point in window coordinates to document coordinates.

**Pass:**  
ds:si - Segment:Chunk handle of the VisRuler object.  
dx.cx.ax - **DWFixed** value of point to be scaled.

**Returns:**  
dx.cx.ax - **DWFixed** point, scaled.

**Destroyed:**  
Nothing.

**Library:** ruler.def

----------
#### SoundAllocMusic
Allocate a handle to play FM sounds from fixed memory

**Pass:**  
bx:si - Buffer to play from in fixed memory  
cx - Number of voices used in buffer

**Returns:**  
CF - Set on error; clear on success.  
bx - On success, handle to **SoundControl** (owned by calling 
thread); otherwise destroyed.  
ax - On error, this will be a **SoundErrors** value; otherwise 
destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundAllocMusicNote
Allocate a note and return its handle.

**Pass:**  
bx - Instrument table seg. (zero for system default)  
si - Instrument number for note  
ax - Frequency  
cx - Volume  
dx - **SoundStreamDeltaTimeType**.  
di - Duration (in **DeltaTimerType** units)	

**Returns:**  
CF - Clear on success; set on error.  
bx - On success, token for sound; otherwise destroyed.  
ax - On error, **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundAllocMusicStream
Allocate a stream to play FM sounds on.

**Pass:**  
ax - **SoundStreamSize**  
bx - Starting priority for sound  
cx - Number of voices for sound  
dx - Starting tempo for sound	

**Returns:**  
CF - Clear on success; set on error.  
bx - Handle to **SoundControl** (owned by calling thread); 
otherwise destroyed.  
ax - On error, **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundAllocNote
Allocate a note structure, define it, and return its handle. A note is a simple 
sound that has a pre-defined sound buffer. The handle returned may be used 
with other sound routines to play or free the sound.

**Pass:**  
bx:si - Address of the note's instrument definition (buffer containing 
sound definition for a given instrument).  
ax - Frequency of the note, in Hz (cycles per second).  
cx - Volume of the note (normally a volume constant).  
dx - **SoundStreamDeltaTimeType** value giving the units of the 
value passed in **di**.  
di - Duration of the time between notes, in units of 
**SoundStreamDeltaTimeType** units as specified in **dx**.

**Returns:**  
bx - Token of the allocated sound.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundAllocSampleStream
Allocate a sound handle for the sound.

**Pass:**  
Nothing.

**Returns:**  
CF - Clear on success; set on error.  
bx - (If CF clear) Handle to **SoundControl**; (If CF set) destroyed.  
ax - (If CF set) **SoundErrors** value; (If CF clear) destroyed.

**Destroyed:**  
bx or ax - See above.

**Library:** sound.def

----------
#### SoundAllocSimple
Allocate a handle to play FM sounds from fixed memory

**Pass:**  
bx:si - Buffer to play from in fixed memory  
cx - Number of voices used in buffer

**Returns:**  
CF - Set on error; clear on success.  
bx - On success, handle to **SoundControl** (owned by calling 
thread); otherwise destroyed.  
ax - On error, this will be a **SoundErrors** value; otherwise 
destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundAllocSimpleFM
Allocate space on the global heap for a simple, frequency-modulated sound 
stream for a song. The song should already be created and located in fixed or 
locked memory. The handle returned references a block containing the sound 
that may then be played or freed.

**Pass:**  
bx:si - Buffer to play from in fixed memory  
cx - Number of voices used in buffer

**Returns:**  
CF - Set on error; clear on success.  
bx - On success, handle to **SoundControl** (owned by calling 
thread); otherwise destroyed.  
ax - On error, this will be a **SoundErrors** value; otherwise 
destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundChangeOwner
Change the owner of a sound.

**Pass:**  
bx - Handle of the sound to be changed.  
ax - Geode handle of the sound's new owner.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundChangeOwnerMusic
Change the owner of a sound.

**Pass:**  
bx - Handle of the sound to be changed.  
ax - Geode handle of the sound's new owner.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundChangeOwnerSimple
Change the owner of a sound.

**Pass:**  
bx - Handle of the sound to be changed.  
ax - Geode handle of the sound's new owner.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundChangeOwnerStream
Change the owner of a sound stream.

**Pass:**  
bx - Handle of the sound to be changed.  
ax - Geode handle of the sound's new owner.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundDisableSampleStream
Removes the association of DAC and the sound.

**Pass:**  
bx - Handle for **SoundControl**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundEnableSampleStream
Associate a real DAC device to a sound.

**Pass:**  
bx - Handle of **SoundControl**  
ax - Priority for DAC (**SoundPriority**)  
cx - Rate for sample  
dx - **ManufacturerID** of sample  
si - **DACSampleFormat** of sample

**Returns:**  
CF - Clear on success; set on error.  
ax - On error, **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundFreeMusic
Free up a simple FM sound stream.

**Pass:**  
bx - Handle for **SoundControl**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundFreeMusicNote
Free up an allocated music note.

**Pass:**  
bx - Token of note.	

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundFreeMusicStream
Free an FM sound stream.

**Pass:**  
bx - Handle for **SoundControl**.	

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundFreeNote
Free the given note originally allocated with **SoundAllocNote**; the note 
must not be playing when it is freed. If the note may be playing, call 
**SoundStopNote** before freeing it.

**Pass:**  
bx - Handle of the note to be freed.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundFreeSampleStream
Frees up the Sound structure of the sound.

**Pass:**  
bx - Handle of **SoundControl**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundFreeSimple
Free up a simple FM sound stream.

**Pass:**  
bx - Handle for **SoundControl**.	

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundFreeSimpleFM
Free a simple frequency-modulated sound originally allocated with 
**SoundAllocSimpleFM**. The sound must not be playing; if it may be playing, 
call **SoundStopStream** before freeing it.

**Pass:**  
bx - Handle of the simple sound to be freed.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundGetExclusive
Get exclusive access to the sound driver, blocking if it is currently in use. 
Generally, applications will call the higher level sound routines rather than 
access the sound driver's strategy routine directly. If you do call this routine, 
be sure to call **SoundReleaseExclusive** when done with the sound driver.

**Pass:**  
Nothing.

**Returns:**  
cx:dx - Address of the sound library's strategy routine.  
bx:di - Address of the DAC driver's strategy routine.  
ax:si - Address of the synthesizer driver's strategy routine.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundGetExclusiveNB
Get exclusive access to the sound driver, returning with the carry flag set if 
it is currently in use. Generally, applications will call the higher level sound 
routines rather than access the sound driver's strategy routine directly. If 
you do call this routine and gain exclusive access to the sound driver, be sure 
to call **SoundReleaseExclusive** when done with the sound driver.

**Pass:**  
Nothing.

**Returns:**  
CF - Set if another thread has exclusive access, clear if access 
gained.  
cx:dx - Address of the sound library's strategy routine.  
bx:di - Address of the DAC driver's strategy routine.  
ax:si - Address of the synthesizer driver's strategy routine.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundInitMusic
Initialize a pre-defined simple FM sound structure.

**Pass:**  
bx - Handle to block with empty **SoundControl**.  
cx - Number of voices for sound.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundInitSimple
Initialize a pre-defined simple FM sound structure.

**Pass:**  
bx - Handle to block with empty **SoundControl**.  
cx - Number of voices for sound.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundInitSimpleFM
Initialize a pre-defined simple frequency-modulated sound structure. This 
routine is automatically called when a note is allocated with 
**SoundAllocNote** or **SoundAllocSimpleFM**.

**Pass:**  
bx - Handle to block with empty **SoundControl**.  
cx - Number of voices for sound.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundPlayMusic
Play a simple FM sound.

**Pass:**  
bx - Handle for **SoundControl**.  
ax - Starting priority for sound  
cx - Starting tempo setting for sound  
dl - **EndOfSongFlags** for sound

**Returns:**  
CF - Clear on success; set on error.  
ax - On error, a **SoundErrors** value; otherwise, destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundPlayMusicNote
Play a note of music.

**Pass:**  
bx - Token of music note.  
ax - Starting priority for sound  
cx - Starting tempo setting for sound  
dl - **EndOfSongFlags** for sound

**Returns:**  
CF - Clear on success; set on error.  
ax - On error, a **SoundErrors** value; otherwise, destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundPlayNote
Play the given note according to the other parameters. If the note is currently 
playing, it will be stopped and immediately restarted. This routine is 
identical to **SoundPlaySimpleFM**.

**Pass:**  
bx - Handle of the note as returned by **SoundAllocNote**.  
ax - **SoundPriority** of the note.  
cx - Tempo of the note (only used if the song requires a tempo).  
dl - **EndOfSongFlags** record indicating how the note should be 
handled after being played.

**Returns:**  
CF - Set if the sound library was unavailable, clear otherwise.  
ax - On error, a **SoundErrors** value; otherwise, destroyed.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundPlaySimple
Play a note of music.

**Pass:**  
bx - Token of music note.  
ax - Starting priority for sound  
cx - Starting tempo setting for sound  
dl - **EndOfSongFlags** for sound

**Returns:**  
CF - Clear on success; set on error.  
ax - On error, a **SoundErrors** value; otherwise, destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundPlaySimpleFM
Play the given note according to the other parameters. If the sound is 
currently playing, it will be restarted at the beginning with the new tempo 
and priority.

**Pass:**  
bx - Handle of the note as returned by **SoundAllocSimpleFM**.  
ax - **SoundPriority** of the note.  
cx - Tempo of the note (only used if the song requires a tempo).  
dl - **EndOfSongFlags** record indicating how the note should be 
handled after being played.

**Returns:**  
CF - Set if the sound library was unavailable, clear otherwise.  
ax - On error, a **SoundErrors** value; otherwise, destroyed.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundPlayToMusicStream
Play an FM sound to a stream.

**Pass:**  
bx - Handle for **SoundControl**  
dx:si - Start of event buffer to write to sound stream  
cx - Bytes in buffer (zero if unknown)	

**Returns:**  
CF - Clear on success; set on error.  
ax - On error, a **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundPlayToSampleStream
Play a given piece of DAC data to the DAC device.

**Pass:**  
bx - Handle of **SoundControl**  
dx:si - Buffer of DAC data to put on stream  
cx - Length of buffer (in bytes)  
ax:bp - **SampleFormatDescription** of buffer	

**Returns:**  
CF - Clear on success; set on error.  
ax - On error, a **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundReallocMusic
Change the song setting for a simple stream.

**Pass:**  
bx - Handle for **SoundControl**  
ds:si - New sound buffer	

**Returns:**  
CF - Clear on success; set on error.  
ax - On error, a **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundReallocMusicNote
Change the settings of the given note. The note must not be playing; if it may 
be, call SoundStopNote before reallocating the note.

**Pass:**  
bx - Handle for **SoundControl**  
ax - Frequency for note  
cx - Volume for note  
dx - Timer type  
di - Timer value  
ds:si - New instrument setting

**Returns:**  
CF - Clear on success; set on error.  
ax - On error, a **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundReallocNote
Change the settings of the given note. The note must not be playing; if it may 
be, call **SoundStopNote** before reallocating the note.

**Pass:**  
bx - Handle of the note as returned by **SoundAllocNote**.  
ax - New frequency of the note.  
cx - New volume of the note.  
dx - New delay timer type for the note.  
di - New delay value for the note, in the units of the new type.  
ds:si - Address of the new instrument for the note.

**Returns:**  
CF - Set if the sound library is unavailable, clear otherwise.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundReallocSimple
Change the song setting for a simple stream.

**Pass:**  
bx - Handle for **SoundControl**  
ds:si - New sound buffer	

**Returns:**  
CF - Clear on success; set on error.  
ax - On error, a **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundReallocSimpleFM
Change the settings for a simple note or simple song's stream. This routine 
restarts the song with the new sound buffer, but it leaves the voices in the 
state they were in at the end of the last song. This allows playing a very long 
song by segmenting it into smaller buffers. Each buffer section must end with 
a GE_END_OF_SONG token, however.

**Pass:**  
bx - Handle of the simple note or stream, as returned by 
**SoundAllocSimpleFM** or **SoundAllocStreamFM**.  
ds:si - Address of the new sound buffer as would be passed to the 
sound allocation routine.

**Returns:**  
CF - Set if the library is unavailable, clear otherwise.  
ax - On error, a **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundReleaseExclusive
Release exclusive access to the sound library and sound driver routines. Any 
thread that calls **SoundGrabExclusive** or **SoundGrabExclusiveNB** 
must call this routine after grabbing the exclusive. In general, a thread 
should retain exclusive access only as long as it absolutely needs to.

**Pass:**  
Nothing.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundSampleDriverInfo
Get information on Sample Driver.

**Pass:**  
Nothing.

**Returns:**  
ax - Number of DACs  
bx - **SoundDriverDACCapability**

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundStopMusic
Stop a simple stream.

**Pass:**  
bx - Handle of **SoundControl**.

**Returns:**  
CF - Clear on success; set on error.  
ax - On error, a **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundStopMusicNote
Stop a music note.

**Pass:**  
bx - Token of music note.

**Returns:**  
CF - Clear on success; set on error.  
ax - On error, a **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundStopMusicStream
Stop a music stream.

**Pass:**  
bx - Handle of **SoundControl**.

**Returns:**  
CF - Clear on success; set on error.  
ax - On error, a **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundStopNote
Stop a note that is playing. This routine should be called before freeing, 
changing, or reallocating a note if that note could be playing at the time.

**Pass:**  
bx - Handle of the note.

**Returns:**  
CF - Set if the library was unavailable, clear otherwise.  
ax - On error, a **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SoundStopSimple
Stop a music stream.

**Pass:**  
bx - Handle of **SoundControl**.

**Returns:**  
CF - Clear on success; set on error.  
ax - On error, a **SoundErrors** value; otherwise destroyed.

**Destroyed:**  
See above.

**Library:** sound.def

----------
#### SoundStopSimpleFM
Stop a simple frequency-modulated sound from playing. This is similar in 
usage to **SoundStopNote**.

**Pass:**  
bx - Handle of the simple sound.

**Returns:**  
CF - Set if the library was unavailable, clear otherwise.  
ax - On error, a **SoundErrors** value; otherwise destroyed.

**Library:** sound.def

----------
#### SoundSynthDriverInfo
Get information on the synthesizer driver.

**Pass:**  
Nothing.

**Returns:**  
ax - Number of Voices  
bx - **SupportedInstrumentFormat**  
cx - **SoundDriverCapability**

**Destroyed:**  
Nothing.

**Library:** sound.def

----------
#### SpoolAddJob
Add the passed job (a GString file) to the print queue. If the spooler thread 
has not started, or if there is no queue for the desired device and port, this 
routine will start them.

**Pass:**  
dx:si - Address of a **JobParameters** structure. This structure 
includes information on the document, the paper, the print 
mode, the number of copies, the port, the device, and the 
printer.

**Returns:**  
cx - ID of the print job. This ID may be used to track or modify jobs 
with other spooler routines.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolConvertPaperSize
Convert a width and height pair to a paper size index. This is the complement 
to **SpoolGetPaperSize**.

**Pass:**  
cx - Width, in points.  

dx - Height, in points.  
bp - **PageType** value: PT_PAPER, PT_ENVELOPE, PT_LABEL.

**Returns:**  
ax - -1 if no page index for the passed size, otherwise
Page size number as returned by **SpoolCreatePaperSize**.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolCreatePaperSize
Create a new paper size index and store it in the GEOS.INI file.

**Pass:**  
es:di - Address of a null-terminated text string holding the name of 
the new size.  
bp - **PageType** value: PT_PAPER, PT_ENVELOPE, PT_LABEL.  
cx - Width of new paper size, in points.  
dx - Height of new paper size, in points.  
ax - Default **PageLayout** record for the new size.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Paper size number of the new size.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolCreatePrinter
Create a new printer, adding it to the end of the list of installed printers. This 
routine does not initialize all the information for the printer but only adds it 
to the installed list.

**Pass:**  
es:di - Address of the null-terminated printer name string. (Must be 
at most GEODE_MAX_DEVICE_NAME_SIZE bytes.)  
cl - **PrinterDriverType** of the new printer.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Index number of the new printer in the installed list.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolCreateSpoolFile
Create and open a new, unique spool file in the SP_SPOOL directory.

**Pass:**  
dx:si - Address for the null-terminated 8.3 file name (must be at 
least 13 bytes long and locked or fixed).

**Returns:**  
dx:si - Address of the new null-terminated filename.  
ax - File handle of the new file. Null handle returned if the file 
could not be opened.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolDelJob
Delete a job from the spooler queue, given a job ID.

**Pass:**  
cx - ID of print job, as returned by **SpoolAddJob**.

**Returns:**  
ax - **SpoolOpStatus** value giving the status of the queue.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolDelayJob
Move the specified job to the end of the spooler queue.

**Pass:**  
cx - ID of print job, as returned by **SpoolAddJob**.

**Returns:**  
ax - **SpoolOpStatus** value giving the status of the queue.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolDeletePaperSize
Delete a paper size from the paper size list.

**Pass:**  
bp - **PageType** value: PT_PAPER, PT_ENVELOPE, PT_LABEL.  
ax - Paper size index as returned by **SpoolCreatePaperSize**.

**Returns:**  
CF - Set if error, clear otherwise.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolDeletePrinter
Delete a printer from the list of currently installed printers.

**Pass:**  
ax - Index in list of printer to delete.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolGetDefaultPageSizeInfo
Return the default page information for the spooler.

**Pass:**  
ds:si - Address of an empty **PageSizeReport** structure.

**Returns:**  
ds:si - Address of the filled **PageSizeReport** structure containing 
the default page information in the following fields:  
*PSR_width* - Width of the page.  
*PSR_height* - Height of the page.  
*PSR_layout* - **PageLayout** record defining layouts.  
*PSR_margins* - **PCMarginParams** structure giving 
document margins.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolGetNumPaperSizes
Return the number of defined paper sizes for the given type.

**Pass:**  
bp - **PageType** value: PT_PAPER, PT_ENVELOPE, PT_LABEL.

**Returns:**  
cx - Number of paper sizes defined for the type.  
dx - Index of the default size for the given type.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolGetNumPrinters
Return the number of printers installed for the given driver type.

**Pass:**  
cl - **PrinterDriverType**: PDT_PRINTER, PDT_PLOTTER, 
PDT_FACSIMILE, PDT_CAMERA, PDT_OTHER.  
ch - Non-zero requests that only local numbers be counted; zero 
asks that all printers be counted.

**Returns:**  
ax - Number of installed printers for the driver type.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolGetPaperSize
Return the dimensions of the requested paper size. This is the complement 
to **SpoolConvertPageSize**.

**Pass:**  
ax - Index of the paper size to convert.  
bp - **PageType** value: PT_PAPER, PT_ENVELOPE, PT_LABEL.

**Returns:**  
cx - Width of paper, in points.  
dx - Height of paper, in points.  
ax - Default **PageLayout** record for the paper size.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolGetPaperSizeOrder
Return the paper size order array for the given page type.

**Pass:**  
bp - **PageType** of the array to get.  
es:di - Address of a locked or fixed buffer to hold the returned array 
(must be at least MAX_PAPER_SIZES bytes).  
ds:si - Address of a locked or fixed buffer to hold the array of 
user-defined sizes (must be at least MAX_PAPER_SIZES 
bytes).

**Returns:**  
es:di - Address of the filled paper size array. Each entry in the array 
corresponds to the paper size having that index and is a 
single byte, the value of which determines its meaning:  
0-127 - Pre-defined paper size.  
128-255 - User-defined paper size.  
ds:si - Address of the filled user-defined size array. Each entry in the 
array corresponds to a single user-defined size, ordered as in 
the order array (**es:di**). Each entry in this array is a single 
byte, whose value signifies the following:  
0 - Paper size is in-use (displayed to the user).  
1 - Paper size is not in-use (not displayed).  
dx - Number of unused (non-displayed) paper sizes.  
cx - Number of ordered sizes (number of entries in the array 
pointed to by **es:di**).

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolGetPaperString
Return the paper size string for the specified paper size and page type.

**Pass:**  
ax - Index of the paper size.  
bp - **PageType** value: PT_PAPER, PT_ENVELOPE, PT_LABEL.  
es:di - Address of a locked or fixed buffer for the returned string. 
The buffer must be at least MAX_PAPER_STRING_LENGTH 
bytes long.

**Returns:**  
CF - Set if error, clear otherwise.  
cx - Length of returned string, not including the null terminator.  
es:di - Address of the returned null-terminated name string.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolGetPrinterString
Return the printer name string for the specified printer.

**Pass:**  
ax - Index of the printer on the installed printer list.  
es:di - Address of a locked or fixed buffer for the returned string. 
This must be at least GEODE_MAX_DEVICE_NAME_SIZE 
bytes long.

**Returns:**  
CF - Set if error, clear otherwise.  
cx - Length of the returned name string, not including the null 
terminator.  
dl - **PrinterDriverType** of the installed printer.  
es:di - Address of the returned null-terminated printer name string.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolHurryJob
Move the given print job to the front of the spooler's queue.

**Pass:**  
cx - ID of the print job to be hurried.

**Returns:**  
ax - **SpoolOpStatus** value.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolInfo
Return information about either the spooler's jobs or the spooler's queue.

**Pass:**  
cx - SpoolInfoType value:  
SIT_JOB_INFO - Return information about a job in the 
spooler's job queue.  
SIT_QUEUE_INFO - Return the spool's queue listing.  
If SIT_JOB_INFO passed in cx:  
dx - ID of the print job to retrieve.  
If SIT_QUEUE_INFO passed in cx:  
dx:si - Address of a **PrintPortInfo** structure 
defining which port's queue to return. If **dx** is 
passed -1, only a value indicating whether 
ports are active will be returned (not 
information about the ports or queues).

**Returns:**  
If SIT_JOB_INFO passed in **cx**:  
ax - **SpoolOpStatus** indicating success or failure 
of the query.  
bx - If successful, the handle of a block containing 
the **JobStatus** structure for the specified job. 
If the job is currently printing and has been 
aborted, or if the job can not be found in the 
queue, this will be reflected in the returned 
**ax**.  
If SIT_QUEUE_INFO passed in **cx**:  
ax - **SpoolOpStatus** indicating success or failure 
of the query. If dx was passed -1, only 
SPOOL_QUEUE_NOT_EMPTY or 
SPOOL_QUEUE_EMPTY will be returned.  
bx - If successful, the handle of a block containing 
an array of print job IDs. This array is 
chronological with the active job as the firs 
element and subsequent jobs following.  
cx - The number of job IDs returned in the block 
referenced by **bx**.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolMapToPrinterFont
Map the GEOS font passed to the closest printer font available.

**Pass:**  
cx - **FontID** of the requested font.  
dx - Point size requested.  
bl - Pitch value requested.  
es - Segment address of the **PState** structure defining the 
printer to be mapped to.  
ds - Segment address of the device information resource (the 
locked device resource referenced in the *PS_deviceInfo* field of 
the **PState** structure pointed to by **es**.

**Returns:**  
cx - **FontID** of the mapped font.  
dx - New point size (equal or next smaller value, if available; 
otherwise, average width of the string is computed and the 
font is treated like a fixed pitch font).  
bl - New pitch value (equal or next larger pitch value, if 
available; otherwise, closest smaller value).

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolModifyPriority
Modify the priority of a spool queue's thread.

**Pass:**  
cx - ID of a print job; the thread running this job will have its 
priority modified.  
dl - New thread priority to set.

**Returns:**  
ax - **SpoolOpStatus** value.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolSetDefaultPageSizeInfo
Set the default page information for the system.

**Pass:**  
ds:si - Address of a **PageSizeReport** structure defining the new 
default settings for page width, height, layout, and margins.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolSetDefaultPrinter
Set the printer to be used as the system default.

**Pass:**  
ax - Index of the printer to be used as the system default.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolSetDocSize
Set the document size for a given application.

**Pass:**  
ds:si - Address of a **PageSizeReport** structure defining the page 
width, height, layout, and margins.  
cx - If true (i.e., non-zero) Document is currently open. 
If false (i.e., zero) Document is currently closed.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolSetPaperSizeOrder
Set a new order in which paper sizes should be displayed, for a particular 
page type.

**Pass:**  
bp - **PageType** value: PT_PAPER, PT_ENVELOPE, PT_LABEL.  
ds:si - Address of the new array of paper sizes. This array is one 
byte per element, with each byte containing the 
corresponding paper size number. These numbers signify the 
following:  
0-127 - Pre-defined paper size.  
128-255 - User-defined paper size.  
cx - Number of entries in the array in **ds:si**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolUpdateTranslationTable
Initialize the translation table in the passed  -  structure. This routine 
is called any time a change in font or country occurs resulting in a change in 
the ISO substitutions. It is also called once on startup of any print job. This 
routine is rarely called directly by applications; it is usually called only by the 
spooler.

**Pass:**  
es - Segment address of the locked **PState** structure.  
dx - Handle of the printer driver's extended driver information 
resource.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SpoolVerifyPrinterPort
Verify the existence of a printer port.

**Pass:**  
ds:si - Address of a locked **PrintPortInfo** structure giving the 
printer port type and the port parameters.

**Returns:**  
ax - SpoolOpStatus value.

**Destroyed:**  
Nothing.

**Library:** spool.def

----------
#### SysGetDosEnvironment
Retrieve the value of a DOS environment variable from the environment 
buffer.

**Pass:**  
ds:si - Address of the null-terminated name of the variable to get.  
es:di - Address of the destination buffer to hold the value.  
cx - Maximum number of bytes, including terminating null, to 
retrieve.

**Returns:**  
CF - Set if environment variable not found, clear otherwise.  
es:di - Address of the returned null-terminated value string.

**Destroyed:**  
Nothing.

**Library:** system.def

----------
#### SysGetECLevel
Return the current **ErrorCheckingFlags** record set for the system and the 
block, if ECF_BLOCK_CHECKSUM is set. For full information, see the 
reference entry for **ErrorCheckingFlags**.

**Pass:**  
Nothing.

**Returns:**  
ax - **ErrorCheckingFlags** record.  
bx - Handle of the error checking block, if 
ECF_BLOCK_CHECKSUM is set in ax.

**Destroyed:**  
Nothing.

**Library:** ec.def

----------
#### SysGetInfo
Return general system information dependent on the type passed.

**Pass:**  
ax - **SysGetInfoType** value (one of the following):  
SGIT_TOTAL_HANDLES - Return the total number of handles in the 
handle table (in **ax**).  
SGIT_HEAP_SIZE - Return the total heap size (in **ax**).  
SGIT_LARGEST_FREE_BLOCK - Return the largest contiguous free block on 
the heap (in **ax**).  
SGIT_TOTAL_COUNT - Return the total number of ticks GEOS has 
been running (in **dx:ax**).  
SGIT_NUMBER_OF_VOLUMES - Return the number of registered volumes (in 
**ax**).  
SGIT_TOTAL_GEODES - Return the total number of geodes loaded (in 
**ax**).  
SGIT_NUMBER_OF_PROCESSES - Return the total number of process threads 
running (in **ax**).  
SGIT_NUMBER_OF_LIBRARIES - Return the total number of libraries loaded 
(in **ax**).  
SGIT_NUMBER_OF_DRIVERS - Return the total number of drivers loaded (in 
**ax**).  
SGIT_CPU_SPEED - Return the CPU speed as a ratio of this CPU 
relative to a base XT processor times ten (in 
**ax**).  
SGIT_SYSTEM_DISK - Return the handle of the disk on which GEOS 
resides (in **dx:ax**).

**Returns:**  
Depending on the **SysGetInfoType** passed:  
ax - Return value if the requested value is one word or one byte.  
dx:ax - Return value if the requested value is size dword.

**Destroyed:**  
dx, if not returning value.

**Library:** sysstats.def

----------
#### SysLocateFileInDosPath
Search for a file along the path specified in the DOS PATH environment 
variable.

**Pass:**  
ds:si - Address of the null-terminated file name to search for.  
es:di - Address of a buffer in which to store the resultant path. The 
buffer must be locked or fixed and at least 
DOS_PATH_BUFFER_SIZE bytes long.

**Returns:**  
CF - Set if error, clear if successful.  
ax - Error code: ERROR_FILE_NOT_FOUND.  
es:di - Address of the full null-terminated path name, including 
drive.  
bx - Disk handle of the disk containing the file.  
cx - Length of path, including null (in bytes).

**Destroyed:**  
Nothing.

**Library:** system.def

----------
#### SysLockBIOS
Gain exclusive access to the BIOS or DOS. Use of this routine is strongly 
discouraged.

**Pass:**  
Nothing.

**Returns:**  
Nothing.

**Destroyed:**  
Flags are destroyed.

**Library:** system.def

**Warning:**   
This is a dangerous routine.

----------
#### SysNotify
Put the **SysNotify** dialog box (the white box with black borders) on the 
screen. The dialog may have two strings printed in it, which are passed with 
this routine. This box is typically used for unrecoverable errors, but it may be 
used for other notifications. Most often an application will use a standard 
dialog rather than a **SysNotify** for notification messages.

**Pass:**  
ax - **SysNotifyFlags** record with zero or more of these flags:  
SNF_RETRY - Provide "Retry" option to the user.  
SNF_EXIT - Provide "Exit Cleanly" option to the user.  
SNF_ABORT - Provide "Abort" option to the user.  
SNF_CONTINUE - Provide "Continue" option to the user. This 
implies the notification dialog is not a real 
error but simply a notification.  
SNF_REBOOT - Provide "Reboot" option to the user, executing 
a dirty shutdown followed by a restart of 
GEOS. This option will not return.  
SNF_BIZARRE - Indicates the notification is unexpected and 
that the user should be directed to the 
trouble-shooting guide.  
ds:si - Address of the first string. Must be null-terminated and 
either locked or fixed. If no string, pass **si** = zero.  
ds:di - Address of the second string. Must be null-terminated and 
either locked or fixed. If no string, pass **di** = zero.

**Returns:**  
ax - Selected option if SNF_RETRY, SNF_ABORT, SNF_CONTINUE, 
or SNF_EXIT is passed and selected by the user. If 
SNF_REBOOT passed and selected, this routine does not 
return.

**Destroyed:**  
Nothing (except SNF_REBOOT).

**Library:** system.def

----------
#### SysRegisterScreen

Register a new screen with the error mechanism, creating a new window and 
GState. Use of this routine is strongly discouraged.

**Pass:**  
cx - WindowHandle of the new screen's root window.  
dx - DriverHandle of the video driver for the new screen.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** system.def

----------
#### SysSetECLevel
Set the current error-checking flags.

**Pass:**  
ax - **ErrorCheckingFlags** record containing the flags to set. 
Flags not set will be cleared. See the reference entry for 
**ErrorCheckingFlags** for full details.

bx - Handle of the error-checking block for 
ECF_BLOCK_CHECKSUM (if any).

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** ec.def

----------
#### SysSetExitFlags
Set the record of exit flags for use with task-switching drivers. The exit flags 
are also used for other purposes. Use of this routine is strongly discouraged. 
For full information on the flags, see the reference entry for **ExitFlags**.

**Pass:**  
bh - **ExitFlags** to clear.  
bl - **ExitFlags** to set. Flags in both **bh** and **bl** will be cleared.

**Returns:**  
bl - ExitFlags record as set by the routine. The flags are  
EF_PANIC - Exit is a panic, so the GEOS.INI file should 
not be written to disk.  
EF_RUN_DOS - Exit is to run a DOS program.  
EF_OLD_EXIT - Exit is old-style DOS exit (if GEOS was 
accidentally run under DOS 1.X).  
EF_RESET - Exit should reset the machine.  
EF_RESTART - Exit should immediately restart GEOS.

**Destroyed:**  
bh is destroyed.

**Library:** system.def

**Warning:**   
This is a dangerous routine.

----------
#### SysShutdown
Cause the system to exit based on the **SysShutdownType** passed.
**Pass:**  
ax - **SysShutDownType**. Each shutdown type takes its own 
parameters, as defined below:  
SST_CLEAN  
Shut down applications cleanly, allowing those that wish to 
abort the shutdown. This type will cause 
MSG_META_CONFIRM_SHUTDOWN to be sent out via the 
MANUFACTURER_ID_GEOWORKS: 
GCNSLT_SHUTDOWN_CONTROL list.  
cx:dx - The optr of the object to receive notification 
once all other objects have acknowledged the 
shutdown. Pass 0:0 to simply notify the UI in 
the standard MSG_META_DETACH fashion.  
bp - The message to be sent to the **cx:dx** object. 
The message will pass **cx** = 0 if the shutdown 
request has been denied and **cx** = non-zero if 
the shutdown may proceed.  
SST_CLEAN_FORCED  
Shut down applications cleanly, but do not send 
MSG_META_CONFIRM_SHUTDOWN (do not allow them to 
abort the shutdown). Nothing but the shutdown type is 
passed.  
SST_DIRTY  
Do not shut down applications, but attempt to exit device 
drivers and close all open files before shutting down. No 
notification is sent out.  
ds:si - Address of a null-terminated text string 
giving a reason for the shutdown. This string 
will be displayed to the user. If no string is 
passed, pass  -  = -1.  
SST_PANIC  
Do not shut down applications, and do not close files; exit 
device drivers marked GA_SYSTEM. This type of shutdown 
can be disastrous to the system and should be used only in 
the most dire of circumstances. Nothing is passed but the 
shutdown type.  
SST_REBOOT  
Like SST_DIRTY, this shuts down drivers and closes files; 
after the shutdown, however, it attempts to warm-boot the 
machine rather than exit to DOS. Nothing is passed but the 
shutdown type.  
SST_RESTART  
Like SST_CLEAN_FORCED in shutdown actions, but reloads 
the system rather than exiting fully to DOS. Nothing is 
passed but the shutdown type.  
SST_SUSPEND  
Suspend system operation in preparation for switching to a 
new DOS task. This uses the same shutdown confirmation as 
used by SST_CLEAN (see above).  
cx:dx - The optr of the object to receive notification 
once all other objects have acknowledged the 
shutdown. Pass 0:0 to simply notify the UI in 
the standard MSG_META_DETACH fashion.  
bp - The message to be sent to the **cx:dx** object. 
The message will pass **cx** = 0 if the shutdown 
request has been denied and **cx** = non-zero if 
the shutdown may proceed.  
SST_CONFIRM_START  
Called by the recipient of 
MSG_META_CONFIRM_SHUTDOWN to allow proper ordering 
of shutdown confirmation dialog boxes. This shutdown type 
does not actually cause shutdown but grabs "exclusive 
access" to the user for shutdown confirmation; the caller of 
this type will block until its turn to confirm comes. If another 
thread has already aborted the shutdown, the routine will 
return with CF set, indicating the confirmation dialog for the 
caller should not be put up. Nothing is passed but the 
shutdown type. After you are done with the confirmation 
sequence, you must call this routine with 
SST_CONFIRM_END.  
SST_CONFIRM_END  
Called after a call to this routine with SST_CONFIRM_START 
to relinquish "exclusive access" to the user for shutdown 
confirmation.  
cx - Zero to deny the shutdown.
Non-zero to allow the shutdown.

**Returns:**  
The return value of **SysShutdown** depends on the shutdown type passed:  
SST_CLEAN - CF set if another shutdown is in progress.  
SST_CLEAN_FORCED - Returns nothing.  
SST_DIRTY - Does not return.  
SST_PANIC - Does not return.  
SST_REBOOT - Does not return.  
SST_RESTART - Returns only if could not restart.  
SST_SUSPEND - CF set if another shutdown is in progress.  
SST_CONFIRM_START - CF set if another caller denied the shutdown.  
SST_CONFIRM_END - Returns nothing.

**Destroyed:**  
ax, bx, cx, dx, bp

**Library:** system.def

----------
#### SysStatistics
Return system performance statistics.

**Pass:**  
es:di - Address of a buffer for the returned **SysStats** structure.

**Returns:**  
es:di - Address of the filled **SysStats** structure. This structure has 
the following fields:  
*SS_idleCount* - Number of "idle ticks" in the last second.  
*SS_swapOuts* - Outward-bound swap activity.  
*SS_swapIns* - Inward-bound swap activity.  
*SS_contextSwitches* - Context switches in the last second.  
*SS_interrupts* - Interrupts during the last second.  
*SS_runQueue* - Number of runnable threads at the end of the 
last second.

**Destroyed:**  
Nothing.

**Library:** sysstats.def

----------
#### SysUnlockBIOS
Relinquish exclusive access to BIOS or DOS, originally gained with 
**SysLockBIOS**. Use of these routines is strongly discouraged.

**Pass:**  
Nothing.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing (flags preserved).

**Library:** system.def

----------
#### TextAllocClipboardObject
This utility routine allocates a temporary object associated with the 
clipboard file for purposes of producing a transfer item. 

**Pass:**  
al - **VisTextStorageFlags** for object.  
ah - Non-zero to create regions for object.  
bx - File to associate object with (or zero for clipboard file).

**Returns:**  
bx:si - Handle of created object.

**Destroyed:**  
Nothing.

**Library:** vTextC.def

----------
#### TextFindDefaultCharAttr
Given an **VisTextCharAttr** structure, determine if it is one of the default 
character attributes.

**Pass:**  
ss:bp - **VisTextCharAttr** structure.

**Returns:**  
CF - Set if passed character attribute is one of the defaults.  
ax - **VisTextDefaultCharAttr**

**Destroyed:**  
Nothing.

**Library:** vTextC.def

----------
#### TextFinishWithClipboardObject
Finish with an object created by TextAllocClipboardObject.

**Pass:**  
^lbx:si - Object  
ax - **TextClipboardOption**  
cx:dx - owner for clipboard item  
es:di - Name for clipboard item (**di** = -1 for default)	

**Returns:**  
ax - Transfer item handle (if **ax** passed non-zero)

**Destroyed:**  
Nothing

**Library:** vTextC.def

----------
#### TextGetSystemCharAttrRun
This routine returns the system character attribute run for this object's 
specific UI. 

**Pass:**  
*ds:si - Object to get character attributes for.  
al - Flags to allocate LMem chunk with (if any) (type 
**ObjChunkFlags**).

**Returns:**  
CF - Clear if we needed to allocate a chunk, set if a default 
character attribute run returned.  
ax - New chunk or constant (allocated in passed **ds** block).  
ds - Updated to point at segment of same block as on entry. 
Chunk handles in this segment may have moved; be sure to 
dereference them.

**Destroyed:**  
Nothing.

**Library:** vTextC.def

**Warning:**   
This routine may resize LMem or object blocks, moving them on the heap and 
invalidating stored segment pointers to them.

----------
#### TextSearchInHugeArray
This routine finds an occurrence of a string within another string.

**Pass:**  
ss:bp - Pointer to **TextSearchInHugeArrayFrame**.
**TextSearchInHugeArrayFrame** struct:  
*TSIHAF_str1Size* dword (?) Total length of string to search in (str1).
*TSIHAF_curOffset* dword (?) 
Offset (from start of str1) to first char to check
*TSIHAF_endOffset* dword (?) 
Offset (from start of str1) to last char to check.
Will only match words that start <= TSIHAF_endOffset. To 
check to start of string (backward searches only) pass zero To 
check to end of string (forward searches only) pass
*TSIHAF_str1Size*-1  
*TSIHAF_searchFlags* **SearchOptions**  
ds:si - Pointer to string to search for. This string may contain 
C_WILDCARD or C_SINGLE_WILDCARD.  
cx - Number of characters in string to search for (or zero if 
null-terminated).

**Returns:**  
CF - Set if string not found, clear if found.  
dx:ax - Offset to match found.  
bp:cx - Number of characters in match.

**Destroyed:**  
Nothing.

**Library:** vTextC.def

----------
#### TextSearchInString
This routine finds an occurrence of a string within another string (both 
strings must be less than 64K in size. 

As an example of how to set up the registers for a search, consider the case 
where you want to search for the string "foo" in "I want some food", but wish 
to start your search from the "w".  
**es:bp** should point to the "I".  
**es:di** should point to the "w".  
**es:bx** should point to the "d".

**Pass:**  
es:bp - Pointer to first character in string we are searching in.  
es:di - Pointer to character at which to start searching. This is a 
position within the string to search in, allowing you to find 
multiple instances.  
es:bx - Pointer to last character to include in search. This is a 
character within the string to search in. For forward 
searches, this routine will not match any word that begins 
after this character, but will match words that start before or 
at this character and extend beyond it.  
dx - Number of characters pointed to by **es:bp** (zero if string is 
null-terminated).  
ds:si - Pointer to string to search for. This string may contain 
C_WILDCARD or C_SINGLE_WILDCARD.  
cx - Number of characters in string to search for (or zero if 
null-terminated).  
al - **SearchOptions**.

**Returns:**  
CF - Set if string not found, clear if found.  
es:di - If found, pointer to start of string found; if not found, pointer 
to last character checked.  
cx - Number of characters matched.

**Destroyed:**  
Nothing.

**Library:** vTextC.def

----------
#### TextSetSpellLibrary
This routine sets the handle of the spell library to make calls to. 

**Pass:**  
bx - Handle of spell library.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** vTextC.def

----------
#### ThreadAllocSem
Allocate a semaphore with the initial passed value. The initial value is the 
number of locks the semaphore can legally have before it causes users to 
block. This number is nearly always one.

**Pass:**  
bx - Initial value.

**Returns:**  
bx - Handle of the semaphore.

**Destroyed:**  
Nothing.

**Library:** sem.def

----------
#### ThreadAllocThreadLock
Allocate a thread lock semaphore; this type of semaphore allows a single 
thread to lock it multiple times without hitting deadlock.

**Pass:**  
Nothing.

**Returns:**  
bx - Handle of the thread lock semaphore.

**Destroyed:**  
Nothing.

**Library:** sem.def

----------
#### ThreadAttachToQueue
Attach a thread to an event queue, blocking on the queue until an event is 
received by it.

**Pass:**  
bx - Handle of the event queue to attach to. If null handle passed 
(zero), the caller wants to "re-attach" to the thread's current 
queue. This is used when a function will not return but still 
needs to field events so its application object can detach 
properly.  
cx:dx - Address of the class that will be bound to the thread. This 
argument is only used if a null handle is passed in bx.

**Returns:**  
Does not return.

**Destroyed:**  
Does not return.

**Library:** thread.def

----------
#### ThreadCreate
Create a new procedural thread. When the thread is started, it begins 
execution at the routine specified. If you really want to create an event thread 
(one that runs objects), send MSG_PROCESS_CREATE_EVENT_THREAD to 
your process object instead.

You can call the C stub for this routine, THREADCREATE, directly if you like; 
this allows passing a virtual segment pointer to the thread's execution 
routine. The routine may also return an exit code in **ax**. When calling 
THREADCREATE, however, you must pass the arguments on the stack. The 
kernel will take care of everything else, including calling **ThreadDestroy** 
with the proper exit code.

**Pass:**  
di - Size of stack for new thread. For most threads, 1024 is a good 
stack size. Threads that do no file-related work can probably 
use 512 bytes. If the thread will run objects that use keyboard 
navigation (e.g. dialog boxes), you may need to make it 3072.  
bp - Geode handle of the owner of the thread. If you're in the 
application's process thread, you can call 
**GeodeGetProcessHandle** to get the right owner value. If 
you're in a UI thread and have **ds** or **es** pointing to a 
non-shared LMem block owned by the application, you can 
**mov bx, ds:[LMBH_handle]** and call **MemOwner**.  
al - Priority number for the new thread. Usually one of
PRIORITY_TIME_CRITICAL  
PRIORITY_HIGH  
PRIORITY_UI  
PRIORITY_FOCUS  
PRIORITY_STANDARD  
PRIORITY_LOW  
PRIORITY_LOWEST  
bx - Value to pass to the new thread (the startup routine, defined 
below) in the **cx** register.  
cx:dx - Address of the thread's startup routine. This routine will be 
executed by the thread; it may send messages and call other 
routines, but when it is done executing, it jumps to 
**ThreadDestroy** and kills the thread. The routine's 
parameters are listed below:  
 - ds = es - Owning geode's dgroup segment.  
 - cx - Value passed in bx to ThreadCreate.  
 - dx, y - Zero.  
 - si - Handle of the owning geode.  
 - di - LCT_NEW_CLIENT_THREAD.  
 - flags, ax, bp - Undefined.

**Returns:**  
CF - Set if error, clear otherwise. The error, quite infrequent, is if 
the kernel could not allocate enough fixed stack space for the 
new thread.  
bx - Handle of the new thread.  
cx - Zero.

**Destroyed:**  
ax, dx, si, di, bp

**Library:** thread.def

----------
#### ThreadDestroy
Exit the current process or thread and destroy it.

**Pass:**  
cx - Exit code indicating the reason for or method of exit. This exit 
code should be defined by the application and should be 
meaningful to all other threads of the application.  
dx:bp - The optr of the object to receive MSG_META_ACK after the 
thread is destroyed.  
si - A word of data to pass with MSG_META_ACK. This message 
takes **dx:bp** as the optr of the source of the acknowledgment, 
but only the **dx** portion is used in response to 
**ThreadDestroy**.

**Returns:**  
Does not return.

**Destroyed:**  
Does not return.

**Library:** thread.def

----------
#### ThreadFreeSem
Free a semaphore allocated with **ThreadAllocSem**.

**Pass:**  
bx - Handle of semaphore as returned by **ThreadAllocSem**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sem.def

----------
#### ThreadFreeThreadLock
Free a semaphore allocated with **ThreadGrabThreadLock**.

**Pass:**  
bx - Handle of semaphore as returned by **ThreadAllocSem**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sem.def

----------
#### ThreadGetDGroupDS
Load the **ds** register with the segment of the current thread's dgroup.

**Pass:**  
Nothing.

**Returns:**  
ds - Segment of the caller thread's dgroup.

**Destroyed:**  
Nothing.

**Library:** resource.def

----------
#### ThreadGetInfo
Return information about a thread, depending on the type passed.

**Pass:**  
ax - **ThreadGetInfoType** value:  
TGIT_PRIORITY_AND_USAGE - Return the thread's recent CPU usage in the 
high byte of the returned word and the 
thread's priority level in the low byte.  
TGIT_THREAD_HANDLE - Return the thread's handle.  
TGIT_QUEUE_HANDLE - Return the handle of the thread's queue.  
bx - Handle of the thread to get information on, or zero for the 
caller thread.

**Returns:**  
ax - Value dependent on the **ThreadGetInfoType** passed.

**Destroyed:**  
Nothing.

**Library:** thread.def

----------
#### ThreadGrabThreadLock
Grab a thread lock (like doing a "P" on a semaphore). A thread that grabs a 
thread lock it already holds will not deadlock. A thread that grabs a thread 
lock held by another thread will block until the thread lock is available.

**Pass:**  
bx - Handle of the thread lock as returned by 
**ThreadAllocThreadLock**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sem.def

----------
#### ThreadHandleException
Define a handler function so a thread may handle one of the processor 
exceptions.

**Pass:**  
ax - **ThreadException** to be handled by the routine:  
TE_DIVIDE_BY_ZERO  
TE_OVERFLOW  
TE_BOUND  
TE_FPU_EXCEPTION  
TE_SINGLE_STEP  
TE_BREAKPOINT  
bx - Handle of the thread that will handle the exception, or zero 
to specify the current (caller) thread.  
cx:dx - Address of the fixed-memory handler routine. Pass 0:0 to 
return to using the kernel's default handler for the exception.

**Returns:**  
bx - Handle of the thread that was modified to run the routine.

**Destroyed:**  
Nothing.

**Library:** thread.def

----------
#### ThreadModify
Change a thread's base priority, and/or set the thread's recent CPU usage to 
zero.

**Pass:**  
bx - Handle of the thread to be modified, or zero to modify the 
current (caller) thread.  
al - **ThreadModifyFlags** record, with one or both of the 
following:  
TMR_BASE_PRIO - Modify the thread's base priority.  
TMR_ZERO_USAGE - Set the thread's recent CPU usage to zero.  
al - The new base priority, if TMR_BASE_PRIO is set in **ah**.

**Returns:**  
bx - Handle of the thread modified.

**Destroyed:**  
ax

**Library:** thread.def

----------
#### ThreadPrivAlloc
Allocate a block of contiguous words in the thread's private data area.

**Pass:**  
cx - Number of words to be allocated.  
bx - Geode handle of the geode that will "own" the block.

**Returns:**  
CF - Set if no block large enough for allocation.  
bx - Offset to the start of the range (token for use with other 
private data management routines).

**Destroyed:**  
Nothing.

**Library:** thread.def

----------
#### ThreadPrivFree
Free a range of thread-private space owned by the geode. This space must 
have been allocated with **ThreadPrivAlloc**.

**Pass:**  
bx - Offset to the words being freed (as returned by 
**ThreadPrivAlloc**).  
cx - Number of words to be freed.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** thread.def

----------
#### ThreadPSem
Grab a semaphore (perform a "P" operation on it). If another thread has the 
semaphore, the caller will block until the semaphore is available. If the 
calling thread has the semaphore, the thread will deadlock. This routine 
provides no deadlock checking.

**Pass:**  
bx - Handle of the semaphore to be grabbed.

**Returns:**  
ax - **SemaphoreError** value:  
SE_NO_ERROR  
SE_PREVIOUS_OWNER_DIED

**Destroyed:**  
Nothing.

**Library:** sem.def

----------
#### ThreadPTimedSem
Grab a semaphore as with **ThreadPSem**, except return an error if the 
semaphore is not available within a certain time limit. If the timeout is 
returned, the caller should not proceed with the protected action but should 
take other action.

**Pass:**  
bx - Handle of the semaphore to be grabbed.  
cx - Number of ticks before timeout.

**Returns:**  
ax - SemaphoreError value:  
SE_TIMEOUT  
SE_NO_ERROR  
SE_PREVIOUS_OWNER_DIED

**Destroyed:**  
Nothing.

**Library:** sem.def

----------
#### ThreadReleaseThreadLock
Release a thread lock grabbed with **ThreadGrabThreadLock**. A thread 
should call this routine once and only once for each time it grabbed the thread 
lock.

**Pass:**  
bx - Handle of the thread lock semaphore.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** sem.def

----------
#### ThreadVSem
Release a semaphore (perform a "V" operation on it). This routine should be 
called once and only once for each call to **ThreadPSem** on the semaphore by 
the calling thread.

**Pass:**  
bx - Handle of the semaphore to be released.

**Returns:**  
ax - SemaphoreError value:  
SE_NO_ERROR  
SE_PREVIOUS_OWNER_DIED

**Destroyed:**  
Nothing.

**Library:** sem.def

----------
#### TimerGetCount
Return the system time counter, reflecting the total number of ticks since 
GEOS was started.

**Pass:**  
Nothing.

**Returns:**  
ax - Low word of 32-bit time counter.  
bx - High word of 32-bit time counter.

**Destroyed:**  
Nothing (flags preserved).

**Library:** timer.def

----------
#### TimerGetDateAndTime
Return the current date and time.

**Pass:**  
Nothing.

**Returns:**  
ax - Year (zero-based integer where 0 = 1980).  
bl - Month (1 through 12).  
bh - Day (1 through 31).  
cl - Day of the week (zero-based integer where 0 = Sunday).  
ch - Hours (0 through 23).  
dl - Minutes (0 through 59).  
dh - Seconds (0 through 59).

**Destroyed:**  
Nothing.

**Library:** timedate.def

----------
#### TimerSetDateAndTime
Set the system's date and time. This routine should not normally be called by 
any application other than the GEOS Preferences Manager.

**Pass:**  
cl - **SetDateTimeParams** record. One or both of  
TIME_SET_DATE - Set the year, month, and day.  
TIME_SET_TIME - Set the hour, minute, and second.  
ax - Year (zero-based integer where 0 = 1980).  
bl - Month (1 through 12).  
bh - Day (1 through 31).  
ch - Hours (0 through 23).  
dl - Minutes (0 through 59).  
dh - Seconds (0 through 59).

**Returns:**  
Nothing.

**Destroyed:**  
ax, bx, cx, dx

**Library:** timedate.def

----------
#### TimerSleep
Block the calling thread for the given length of time. This routine is not an 
acceptable substitute for the use of semaphores when synchronizing threads.

**Pass:**  
ax - Number of ticks to sleep (sixty ticks per second).

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** timer.def

----------
#### TimerStart
Start an event or routine timer, either continual or one-shot. A routine timer 
calls a specified routine when time is up; an event timer sends a specified 
message. A one-shot timer counts only once; a continual timer counts until 
stopped (with **TimerStop**), sending the message or calling the routine each 
time the specified interval has passed. You can also start a millisecond timer.

For routine timers, the routine called must have the following specifications:  
**Passed:**  
ax - The word passed in dx to TimerStart.  
cx:dx - The tick count as returned by 
**TimerGetCount**.  
**Return:**  
Nothing.  
**May Destroy:**  ax, bx, cx, dx, si, di, bp, ds, es

For event timers, the message sent will carry the following parameters and 
may return nothing:  
**Passed:**  
ax - Message number sent.  
cx:dx - The tick count as returned by 
**TimerGetCount**.  
bp - The Timer ID for one-shot timers, or
The timer interval, for continual timers.

For timers of type TIMER_MS_ROUTINE_ONE_SHOT, the routine must have 
the following specifications:  
**Passed:**  
ax - The word passed in **dx** to **TimerStart**.  
 - Interrupts will be off.  
**Return:**  
Nothing.  
**May Destroy:**  
ax, bx, si, ds

**Pass:**  
al - **TimerType** value:  
TIMER_ROUTINE_ONE_SHOT - Start a one-shot routine timer.  
TIMER_ROUTINE_CONTINUAL - Start a continual routine timer.  
TIMER_EVENT_ONE_SHOT - Start a one-shot event timer.  
TIMER_EVENT_CONTINUAL - Start a continual event timer.  
TIMER_MS_ROUTINE_ONE_SHOT - Start a one-shot routine timer with 
millisecond accuracy.  
bx:si - The optr of the object to receive the event message (in the 
case of TIMER_EVENT...), or
The far pointer to the routine to be invoked (in the case of 
TIMER_ROUTINE...).  
cx - Number of ticks to count until first timeout, for all timer 
types except TIMER_MS_ROUTINE_ONE_SHOT. For this type, 
**cx** contains the number of milliseconds to count.  
dx - Message to send, for event timers, or
A word of data passed to the routine in **ax** for routine timers.  
di - Ticks between timeouts (timer interval), for continual timers.

**Returns:**  
ax - Timer ID number (needed for **TimerStop**).  
bx - Timer handle of the timer.

**Destroyed:**  
Nothing. Interrupts are in the same state as before.

**Library:** timer.def

----------
#### TimerStartSetOwner
This routine is exactly the same as **TimerStart**, above, except that it allows 
the caller to set the timer's owner. All other aspects of the timer are the same. 
See **TimerStart** for complete details.

**Pass:**  
See **TimerStart**.  
bp - Geode handle of the new owner of the timer.

**Returns:**  
See **TimerStart**.

**Destroyed:**  
See **TimerStart**.

**Library:** timer.def

----------
#### TimerStop
Stop a timer and remove it. This routine is typically called for continual 
timers. Note that a continual event timer may have sent one or more events 
that may be in the recipient's event queue; therefore, you can not assume 
that all timer notifications have been handled when this routine is called.

**Pass:**  
bx - Handle of the timer to be removed.  
ax - Timer ID as returned by the **TimerStart** routines. Pass zero 
for continual timers.

**Returns:**  
CF - Set if the timer was not found, clear otherwise.

**Destroyed:**  
ax, bx

**Library:** timer.def

----------
#### TocAddDisk
Add a disk to the disk array

**Pass:**  
ds:si - Full name of disk  
cx:dx - **TocDiskStruct** structure	

**Returns:**  
bx - Disk token (element number in array).

**Destroyed:**  
Nothing

**Library:** config.def

----------
#### TocCreateNewFile
create a new TOC file in the current working directory. All subsequent TOC 
routines will operate on this new file.

**Pass:**  
Nothing.	

**Returns:**  
CF - Set on error; clear on success.  
ax - On error, a **FileError** value; otherwise, destroyed.

**Destroyed:**  
Nothing.

**Library:** config.def

----------
#### TocDBlock
Lock a DB item in the config library's TOC file.

**Pass:**  
ax:di - **DBItem** to lock.	

**Returns:**  
*ds:si - Item.

**Destroyed:**  
Nothing.

**Library:** config.def

----------
#### TocFindCategory
Find a category in the Toc file. 

**Pass:**  
es:di - Buffer of size **TocCategoryStruct** to be filled in.

**Returns:**  
CF - Set if not found, otherwise clear.

**Destroyed:**  
Nothing.

**Library:** config.def

----------
#### TocGetFileHandle
Return the TOC file handle.

**Pass:**  
Nothing.

**Returns:**  
bx - TOC file handle.

**Destroyed:**  
Nothing.

**Library:** config.def

----------
#### TocNameArrayAdd
Add an element to a TOC name array.

**Pass:**  
ax:di - **DBItem** (nameArray) if **ax** = 0, then the map item will be 
used.  
cx:dx - buffer containing data to add  
ds: - fptr to name to search for	

**Returns:**  
bx - Element number.

**Destroyed:**  
Nothing.

**Library:** config.def

----------
#### TocNameArrayFind
Find a name in the passed name array. 

**Pass:**  
ax:di - **DBItem** (nameArray) in which to find name. **If** ax is zero, 
then the map item will be used.  
cx:dx - Buffer to fill with data. If **cx** is zero, will not return any data.  
ds:si - fptr to name to search for.

**Returns:**  
bx - Name token, or CA_NULL_ELEMENT if not found.

**Destroyed:**  
Nothing.

**Library:** config.def

----------
#### TocNameArrayGetElement
Return data about an element, given its number. 

**Pass:**  
ax:di - **DBItem** (nameArray) in which to find name. If **ax** is zero, 
then the map item will be used.  
bx - Element number  
cx:dx - Buffer to fill with data. If **cx** is zero, will not return any data.

**Returns:**  
ax - Length of data returned in **cx:dx**.

**Destroyed:**  
Nothing.

**Library:** config.def

----------
#### TocSortedNameArrayAdd
Add an element to the name array, inserting it in the proper order.

**Pass:**  
di - VM handle of name array  
ds:si - name  
cx:dx - data to add, pass **cx** = zero if no data  
bx - **NameArrayAddFlags**	

**Returns:**  
**ax** New element number

**Destroyed:**  
Nothing

**Library:** config.def

----------
#### TocSortedNameArrayFind
Find a name in a sorted name array.

**Pass:**  
di - VM handle of **SortedNameArray**  
ds:si - name to find  
cx:dx - buffer for data (**cx** = null to not store data)  
bl - **SortedNameArrayFindFlags**	

**Returns:**  
CF - Set if found; clear otherwise.  
ax - Element number if found; otherwise element number where 
element would appear if it were in the list.

**Destroyed:**  
Nothing.

**Library:** config.def

----------
#### TocUpdateCategory
Create the category if it doesn't exist, and update the file lists by scanning 
the current directory for files.

**Pass:**  
ss:bp - **TocUpdateCategoryParams** structure  
CWD - Current working directory is directory where files reside.	

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** config.def

----------
#### TokenDefineToken
This routine adds a new token and moniker list to the token database. If the 
token already exists in the token database, the old token will be replaced. 
This routine may only be called by the thread capable of locking the block 
which the passed Moniker or MonikerList resides in.

**Pass:**  
ax, bx, si - Six bytes of token. The **ax** and **bx** registers contain the four 
characters of the token and **si** contains the manufacturer ID.  
cx:dx - Handle:chunk of moniker list

bp - **TokenFlags**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.This routine may legally move locked LMem blocks (token database 
items), invalidating any stored segment pointers to them.

**Library:** token.def

----------
#### TokenExitTokenDB
Close the token database file.

**Pass:**  
Nothing.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing

**Library:** token.def

----------
#### TokenGetTokenInfo
Get information about a token. 

**Pass:**  
ax, bx, si - Six bytes of token.

**Returns:**  
CF - Clear if token exists in database, set otherwise.  
bp - **TokenFlags** for the token (if found).

**Destroyed:**  
Nothing.

**Library:** token.def

----------
#### TokenInitTokenDB
Open the local token database file read/write and, if the path for a globally 
shared token database appears in the .INI file, open that file shared-multiple 
read-only.

**Pass:**  
Nothing.	

**Returns:**  
CF - Set on error; clear on success.  
dx - On error, this will be a TokenError value, one of 
ERROR_OPENING_SHARED_TOKEN_DATABASE_FILE, 
ERROR_OPENING_LOCAL_TOKEN_DATABASE_FILE, and 
BAD_PROTOCOL_IN_SHARED_TOKEN_DATABASE_FILE

**Destroyed:**  
Nothing.

**Library:** token.def

----------
#### TokenListTokens
Make a list of the tokens in the token.db file and return it in a memory block 
as an array of **GeodeToken** structures. Along with the list, the number of 
items in the list is returned. Because groups are mixed in with tokens, we 
have to do a preliminary pass to count the tokens, then allocate space and 
run through again grabbing tokens. 

**Pass:**  
ax - Zero if only tokens with GString monikers are requested. 
Non zero to request all monikers.  
bx - Number of bytes to reserve for header in created block. If 
zero, token list will begin at top of returned block.  
cx - **ManufacturerID** of tokens for list, if the 
TRF_ONLY_PASSED_MANUFID is set in **ax**

**Returns:**  
bx - Handle of global memory block containing the list.  
ax - Number of items in list.

**Destroyed:**  
Nothing.

**Library:** token.def

----------
#### TokenLoadMoniker
This routine loads a specified token's moniker. 

If you ask that this routine create an LMem block for you, and ds or es is 
pointing to that LMem block, you must fix **ds** or **es** yourself. E.g.:

	push ds:[LMBH_handle] ; save LMem block handle  
	(set up params)  
	call TokenLoadMoniker  
	pop bx  
	call MemDerefDS

**Pass:**  
ax, bx, si - Six bytes of token.  
dh - **DisplayType**.  
cx:di - Moniker destination.  
If **cx** is zero, then a new global memory chunk will be 
allocated for the moniker.  
If **di** is zero, then **cx** is interpreted as the handle of the 
LMem block in which to allocate an LMem chunk for the 
moniker.  
Otherwise, **cx:di** is interpreted as the address to copy the 
moniker to.  
ss:bp - Search flags and buffer size. Note that these arguments will 
be removed from the stack by this routine.

**Pass on stack:**  
(Pushed in this order):  
(word) **VisMonikerSearchFlags**.  
(word) Size of buffer

**Returns:**  
CF - Clear if token exists in database, set otherwise.  
cx - Number of bytes in moniker.  
di - Global memory block handle, or LMem chunk handle.

**Destroyed:**  
Nothing.

**Library:** token.def

----------
#### TokenLoadToken
Load **TokenEntry** structure for a token into a buffer. 

If you ask that this routine create an LMem block for you, and **ds** or **es** is 
pointing to that LMem block, you must fix **ds** or **es** yourself. E.g.:

	push ds:[0] ; save LMem block handle
	call TokenLoadToken
	pop bx
	call MemDerefDS

**Pass:**  
ax, bx, si - Six bytes of token.  
cx:di - Moniker destination.  
If **cx** is zero, then a new global memory chunk will be 
allocated for the moniker.
If **di** is zero, then **cx** is interpreted as the handle of the LMem 
block in which to allocate an LMem chunk for the moniker.  
Otherwise, **cx:di** is interpreted as the address to copy the 
moniker to.

**Returns:**  
CF - Clear if token exists in database, set otherwise.  
cx - Number of bytes in **TokenEntry**.  
di - Global memory block handle, or LMem chunk handle.

**Destroyed:**  
Nothing.

**Library:** token.def

----------
#### TokenLockTokenMoniker
Lock moniker for drawing. 

**Pass:**  
cx:dx - Group:Item for drawing.  
ax - Zero if token is in shared token DB file; non-zero if token is in 
local token DB file.

**Returns:**  
*ds:bx - Segment:Chunk of moniker.

**Destroyed:**  
Nothing.

**Library:** token.def

----------
#### TokenLookupMoniker
Get the specific moniker for a token, given display type and other attributes. 

**Pass:**  
ax, bx, si - Six bytes of token. The **ax** and **bx** registers hold the token 
characters, and **si** holds the manufacturer ID.  
dh - **DisplayType**  
bp - **VisMonikerSearchFlags** (VSMF_COPY_CHUNK and 
VMSF_REPLACE_LIST ignored).

**Returns:**  
CF - Clear if token exists in database, set otherwise.  
cx:dx - Group:Item of moniker (if found).  
ax - Zero if token found in shared token DB file; non-zero if found 
in local token DB file.

**Destroyed:**  
Nothing.

**Library:** token.def

----------
#### TokenRemoveToken
Get information about a token. 

**Pass:**  
ax, bx, si - Six bytes of token. The **ax** and **bx** registers hold the token 
characters, and **si** holds the manufacturer ID.

**Returns:**  
CF - Clear if token successfully deleted.

**Destroyed:**  
Nothing.

**Library:** token.def

----------
#### TokenUnlockTokenMoniker
This routine unlocks a moniker that had been locked with 
**TokenLockMoniker**(). Pass a pointer to the locked moniker, as returned by 
the locking routine. 

**Pass:**  
ds - Segment of moniker.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** token.def

----------
#### UserAddAutoExec
Add an application to the list of those that are to be loaded when the system 
is booted. This works with the "execOnStartup" field of the initialization 
field. Welcome is an example of an application that might be executed on 
startup.

**Pass:**  
ds:si - Name of application to be loaded on startup. The geode 
should reside in SP_APPLICATION or SP_SYS_APPLICATION.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserAddItemToGroup
Add a font GenItem to the list, set it usable and set its action/data

**Pass:**  
\*ds:si - Parent  
bx - Handle of parent block  
dx - Chunk of font entry (i.e. ^lGenListEntry)  
cx - Action/data for entry (**FontID**)	

**Returns:**  
ds - Updated to point at segment of same block as on entry.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserAllocObjBlock
Allocate a block on the heap, to be used for holding UI objects.

**Pass:**  
bx - Handle of thread to run block (0 for current thread).

**Returns:**  
bx - Handle of block.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserCallApplication
Call application object of process which owns block passed.

**Pass:**  
ax - Message to send to application.  
cx, dx, bp - Data to send on to application.  
ds - Any object block (for fixup).

**Returns:**  
CF - If there was no call, or if message was not handled, will 
return clear. Otherwise, the message handler will set the 
return value.  
ds - Updated to point at segment of same block as on entry.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserCallFlow
Call the UI flow object.

**Pass:**  
ax - Message to pass to system object.  
di - Flags as in **ObjMessage()**.  
cx, dx, bp - Data to pass to message handler.

**Returns:**  
CF - Set by message handler.  
di, cx, dx, bp - Data returned by message handler.  
ds, es - Updated segments (depending on flags passed in  - ).

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserCheckAcceleratorChar
Returns carry set if passed an accelerator-type character.

**Pass:**  
cl - Character.  
dl - **CharFlags**.  
dh - **ShiftState**.  
bp - (high byte) scan code: (low byte) ToggleState.

**Returns:**  
CF - Set if accelerator character.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserCheckInsertableCtrlChar
Checks passed key to see if it is a control character that maps to an insertable 
ASCII character.

**Pass:**  
cx - Character value.  
dl - **CharFlags**.  
dh - **ShiftState**.  
bp - Low byte: **ToggleState**

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserCopyChunkOut
This routine copies part of a local memory chunk to another location.

**Pass:**  
ds:bp - Pointer to source chunk.  
cx - Zero to request that a global memory block be allocated, and 
that the chunk's contents be copied to this block;
Otherwise, meaning of **cx** depends on **dx**.  
dx - Zero to specify that **cx** should be treated as the handle of an 
LMem block to copy to;
Otherwise, **cx:dx** will be treated as the address to copy to.  
ax - Offset specifying where in chunk to start copying. Use zero to 
start at the beginning.  
bx - Flag specifying whether a null terminator should be 
appended at the end of the copy. One to request a null 
terminator, zero to omit it.  
di - Offset specifying where to stop copying. This is an offset in 
chunk past the end. Use zero to copy to the end.

**Returns:**  
ax - Chunk handle, if one created. Note that if created, the copied 
chunk is marked as dirty. The caller must clear the flags to 
set it otherwise.  
cx - Number of characters copied (not including added null 
terminator, if any).  
ds - Updated to point at segment of same block as on entry (only 
relevant if copying to lmem chunk).

**Destroyed:**  
bx, dx, di, bp.

**Library:** ui.def

----------
#### UserCreateDialog
Duplicates a template dialog block, attaches the dialog to an application 
object, and sets it fully usable. The dialog at this point may be used with 
**UserDoDialog()**. The dialog should be removed and destroyed by the caller 
when no longer needed.

**Pass:**  
bx:si - Template object block, chunk offset of GenInteractionClass 
within it to invoke. The block must be sharable, read-only, 
and the top GenInteraction must not be linked into any 
generic tree.

**Returns:**  
bx:si - Created, fully usable dialog (or zero if unable to create).

**Destroyed:**  
Nothing.

**Warning:**   
This routine may resize LMem and/or object blocks, moving them on the heap 
and invalidating stored segment pointers to them.

**Library:** ui.def

----------
#### UserCreateInkDestinationInfo
This routine creates an **InkDestinationInfo** structure to be returned with 
MSG_META_QUERY_IF_PRESS_IS_INK.

**Pass:**  
cx, dx - optr  
bp - gstate for ink to be drawn through (or zero)  
ax - width/height of ink (or zero for default)  
bx:di - virtual fptr of callback routine (to be passed to 
**ProcCallFixedOrMovable**) to determine whether a stroke 
is a gesture or not (BX:DI=0 if none)	

**Returns:**  
bp - handle of an **InkDestinationInfo** structure (or zero if 
couldn't allocate).

**Destroyed:**  
Nothing

**Library:** ui.def

----------
#### UserCreateItem
Create a GenItem for a given string.

**Pass:**  
es:di - ptr to font string (NULL terminated)  
*ds:si - parent  
bx - block of parent  
ds - pointing to a "fixupable" block  
dx - mask OCF_IGNORE_DIRTY if created entry should be marked 
ignore dirty, 0 if not	

**Returns:**  
dx - lmem handle of new list entry  
ds - updated to point at segment of same block as on entry

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserDestroyDialog
Duplicates a template dialog block, attaches the dialog to an application 
object, and sets it fully usable. The dialog at this point may be used with 
**UserDoDialog()**. The dialog should be removed and destroyed by the caller 
when no longer needed.

**Pass:**  
bx:si - Dialog to destroy as object block:chunk offset.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserDiskRestore
Front-end for **DiskRestore** that automatically passes a callback function to 
prompt for the disk, if **DiskRestore** can't do it by itself.

**Pass:**  
ds:si - Buffer to which the disk handle was saved.

**Returns:**  
CF - Set if disk could not be restored; clear if disk restored.  
ax - On error, **DiskRestoreError**; on success, handle of disk for 
this invocation of GEOS.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserDoDialog
This routine allows the application to invoke a dialog (GenInteraction set up 
to be a modal dialog) and block until the user responds. The passed object 
must be linked into a generic tree and be fully usable. Where possible, use 
MSG_GEN_INTERACTION_INITIATE instead. All objects making up the 
dialog must reside within a single block. The dialog must be self-contained. 
I.e. it may not rely on messages sent or called on objects outside of itself. 

**Pass:**  
bx:si - The optr of the GenInteractionClass object to invoke. Must be 
linked into a generic tree and be fully usable before this 
routine may be called on it. 

**Returns:**  
ax - **InteractionCommand** response value.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserGetDefaultMonikerFont
Get the UI moniker font, size for the passed object.

**Pass:**  
ds:si - Object to get the display type for (for future expansion 
possibilities).

**Returns:**  
cx - **FontID**.

dx - Point size.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserGetDisplayType
Get the display type for the passed object. Currently reads the global variable 
**uiDisplayType**, set by GenScreen in 
MSG_GEN_SCREEN_SET_VIDEO_DRIVER.

**Pass:**  
*ds:si - Object to get the display type for (for future expansion 
possibilities)	

**Returns:**  
ah - **DisplayType**

al - *flag*: true (i.e., non-zero) if **uiDisplayType** has been set 
(should only be false before first screen object is put up)

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserGetInitFileCategory
Utility routine to fetch .ini category for an object. Test application 
optimization flag for single category, to avoid recursive search if possible.

**Pass:**  
*ds:si - Object needing .ini category  
cx:dx - Pointer to buffer needing filled

**Returns:**  
CF - Set if buffer filled.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserGetKbdAcceleratorMode
Returns keyboard accelerator mode status.

**Pass:**  
Nothing.

**Returns:**  
ZF - Clear if accelerator mode on; set if off.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserGetOverstrikeMode
Returns overstrike mode status.

**Pass:**  
Nothing.

**Returns:**  
ZF - Clear if overstrike mode on; set if off.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserGetSpecUIProtocolRequirement
Returns any protocol number that should be passed to **GeodeUseLibrary** in 
any attempt to load a specific user interface for use with this geode.

**Pass:**  
Nothing.

**Returns:**  
bx - Major protocol number.  
ax - Minor protocol number.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserHaveProcessCopyChunkIn
This routine figures out which process runs the destination block and sends 
MSG_PROCESS_COPY_CHUNK_IN to it.

**Pass:**  
dx - Number of bytes on stack  
ss:bp - Pointer to **CopyChunkInFrame** structure.	

**Returns:**  
ax - Chunk handle of created chunk  
cx - Number of bytes copied over  
es,ds - Updated if they moved (were the destination block)

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserHaveProcessCopyChunkOut
This routine figures out which process runs the source block and sends 
MSG_PROCESS_COPY_CHUNK_OUT to it. The source optr must be in an 
object block (the **otherInfo** field must be a thread handle).

**Pass:**  
dx - Number of bytes on stack  
ss:bp - Pointer to **CopyChunkOutFrame** structure.

**Returns:**  
ax - Chunk handle of created chunk/block handle (if any)  
cx - Number of bytes copied  
es,ds - Updated if they moved (were the destination block)

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserHaveProcessCopyChunkOver
This routine figures out which process runs the destination block and sends 
MSG_PROCESS_COPY_CHUNK_OVER to it.

**Pass:**  
dx - Number of bytes on stack  
ss:bp - Pointer to **CopyChunkOverFrame** structure.

**Returns:**  
ax - Chunk handle of created chunk/block handle (if any)  
cx - Number of bytes copied  
es,ds - Updated if they moved (were the destination block)

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserLoadApplication
Loads a GEOS application. Changes to standard application directory before 
attempting GeodeLoad on filename passed. Stores the filename being 
launched into the **AppLaunchBlock**, so that information needed to restore 
this application instance will be around later if needed.

Ownership of the launch block is transferred to the new geode and will be 
freed by it. If the application cannot be loaded, the block will be freed here. 
On no account should a passed AppLaunchBlock be referred to after this 
function returns.

**Pass:**  
ah - **AppLaunchFlags** (zero for default). The 
ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE should 
be set if the actual launch should be done later by the UI, in 
a safe memory situation (no error code will be returned in 
this case). If this flag is clear, then the caller should be calling 
from a fixed memory space, such that none of their movable 
code segments are locked. This is to provide the most 
favorable conditions for the new application to be loaded in.  
cx - Application attach mode message. This may be one of the 
following:  
Zero: - Use *ALB_appMode* in **AppLaunchBlock** passed, or if 
there is none, use the default mode. If this is non-zero, any 
*ALB_appMode* in the launch block is overridden.  
MSG_GEN_PROCESS_RESTORE_FROM_STATE: - State file 
must be passed, no data should be passed.  
MSG_GEN_PROCESS_OPEN_APPLICATION: - State file should 
normally not be passed, although one could be to accomplish 
UI templates. A data file may be passed into the application 
as well.  
MSG_GEN_PROCESS_OPEN_ENGINE: - State file normally 
should not be passed. The data file on which the engine will 
operate must be passed. If zero, the default data file should 
be used (this is enforced by the application, not 
**GenProcessClass**).  
dx - Block handle of structure **AppLaunchBlock** (must be 
sharable) or zero for default case. This default case results in 
a mode of MSG_GEN_PROCESS_OPEN_APPLICATION, no data 
file, no template state file, launch to take place in the current 
default field, current directory is the data directory passed to 
the application.  
ds:si - If the pathname is not in the **AppLaunchBlock**, then this 
may be a pointer to the absolute path of the file to load, or the 
file name of a file in either SP_APPLICATION or 
SP_SYS_APPLICATION.  
si - If the fill pathname, filename, and diskhandle are stored in 
the **AppLaunchBlock**, then **si** is -1.  
bx - If the path is specified in **ds:si**, then **bx** contains the disk 
handle, or a standard path (SP_APPLICATION or 
SP_SYS_APPLICATION). Otherwise, this register is ignored.

**Returns:**  
bx - Geode process handle.  
CF - Clear if no error; set if error.  
ax - If no error, segment of geode's core block. If there was an 
error, this register will hold the error code, of type 
**GeodeLoadError**.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserLoadExtendedDriver
Load an extended driver given the category of the .INI file in which to find the 
"device" and "driver" keys for the thing.

**Pass:**  
ax - **StandardPath** enum for directory to look in  
bx - Value to pass in bx to DRE_TEST_DEVICE and 
DRE_SET_DEVICE; may be garbage if driver being loaded 
doesn't expect anything.  
cx.dx - Protocol number expected  
ds:si - Category

**Returns:**  
CF - Clear if successful; set on error.  
bx - On success, handle of loaded and initialized driver.  
ax - On error, **GeodeLoadError**.

**Destroyed:**  
cx, dx, di, si.

**Library:** ui.def

----------
#### UserMessageIM
Send a message to the input manager.

**Pass:**  
ax - Message to send.  
di - Flags as in **ObjMessage()**.  
cx, dx, bp - Data to pass with message.

**Returns:**  
CF - Returned as set by message handler.  
di, cx, dx, bp - Data returned by message handler.  
ds, es - Updated segments (depending on flags passed in **di**).

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserRegisterForTextContext
Registers the passed object to receive context data.

**Pass:**  
^lcx:dx - Object to register

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserRemoveAutoExec
Remove an application from the list of those to be launched on start-up.

**Pass:**  
ds:si - Name of application to remove.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserScreenRegister
Register another screen for GenScreen.

**Pass:**  
cx - Handle of root window for screen  
dx - Handle of video driver for screen

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserSendToApplicationViaProcess
Call the application object, but only after a method has been passed fully 
through the owning application's process.

**Pass:**  
*ds:si - Generic object whose application object we'd like to send a 
method to delayed via stack  
ax - Message to send to application object  
cx, dx, bp - Message's arguments.	

**Returns:**  
ds - Updated to point at same segment of same block as on entry.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserSetDefaultMonikerFont
Set the font and font size to use when drawing UI monikers.

**Pass:**  
cx - **FontID**.  
dx - Point size.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserSetOverstrikeMode
Sets the overstrike mode in the initialization file.

**Pass:**  
al - Zero for no overstrike. 0xff to turn it on.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UserStandardSound
Play a standard sound.

**Pass:**  
di - **StandardSoundType**.

cx - If playing a stream, this is the stream handle.  
If playing a buffer, this is the segment of the buffer.  
If playing a note, this is the frequency.  
dx - If playing a buffer, this is the offset of the buffer.  
If playing a note, this is its duration.  
ds - DGroup.

**Returns:**  
Nothing.

**Destroyed:**  
di.

**Library:** ui.def

----------
#### UserUnregisterForTextContext
Unregisters the passed object to receive context data.

**Pass:**  
^lcx:dx - Object to unregister.	

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UtilAsciiToHex32
Converts a null-terminated ASCII string into a dword. The string may be 
signed or unsigned.

**Pass:**  
ds:si - String to convert.

**Returns:**  
CF - Set if error, clear if no error.  
dx:ax - DWord value if no error. The **ax** register will hold a 
**UtilAsciiToHexError** value otherwise.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### UtilHex32ToAscii
Converts 32-bit unsigned number to its ASCII representation. The number 
may be signed or unsigned.

**Pass:**  
dx:ax - String to convert.  
cx - **UtilHexToAsciiFlags**, allowing the placement of leading 
zeros and/or a null terminator.  
es:di - Buffer in which to place string. Should be of minimum size 
UHTA_NO_NULL_TERM_BUFFER_SIZE or 
UHTA_NULL_TERM_BUFFER_SIZE.

**Returns:**  
CF - Set if error, clear if no error.  
dx:ax - DWord value if no error. The ax register will hold a 
**UtilAsciiToHexError** value otherwise.  
cx - Length of the string, not including null.

**Destroyed:**  
Nothing.

**Library:** ui.def

[Routines M-Q](asmm_q.md) <-- [Table of Contents](../asmref.md) &nbsp;&nbsp; --> [Routines V-Z](asmv_z.md)
