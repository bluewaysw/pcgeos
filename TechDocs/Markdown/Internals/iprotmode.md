## 1 Protected Mode

This chapter describes how #FreeGEOS runs as a protected mode DPMI client
(issue #665), and documents the parts of the system that had to be adapted
for protected mode beyond the obvious segment-versus-selector changes. Its main topic is the system restart
(`SysShutdown(SST_RESTART)`), which works fundamentally differently from
the real-mode version.

### 1.1 Overview

In protected mode, GEOS runs as a DPMI client. Three components are
involved:

- **The DPMI host.** The distribution ships `HDPMI16.EXE`
  (`Tools/build/product/bbxensem/Template/HDPMI16.EXE`), which is started
  before the loader (see the `[autoexec]` section of `bin/basebox.conf`).
- **The loader** (`Loader32`, built as `loader.exe`/`loaderec.exe`). It
  switches into protected mode (`int 2Fh/1687h`, then the DPMI mode switch
  entry), sets up the heap and loads the kernel just like the real-mode
  loader does. Unlike the real-mode loader, it **stays resident** for the
  whole lifetime of the system, because it implements the GPMI.
- **The GPMI** ("GEOS Protected Mode Interface", `Loader32/gpmi.asm`):
  a thin layer on top of DPMI `int 31h` services that the kernel uses to
  allocate memory blocks with selectors, create aliases, map real-mode
  segments, hook interrupts and exceptions, and so on.

Protected-mode specific code in the kernel and in libraries is
conditional on `PROTECTED_MODE` (and in a few places `PRODUCT_GEOS32`).
Both are set by `Tools/scripts/perl/product_flags`. Note that
`product_flags` currently defines `-DPROTECTED_MODE` for *every* product,
so the regular (non-product) targets such as `geosec.geo` and `ui.geo`
are protected-mode builds.

#### 1.1.1 Protected Mode and CPU Word Size

Protected mode and CPU word size are separate aspects. The protected mode
support is meant to cover both 16-bit and 32-bit protected mode in the
future, so the protected-mode mechanisms should not be described or
designed in terms of "32-bit GEOS".

- **Protected mode** is what this chapter is about: running as a DPMI
  client with selectors instead of segments. That covers the resident
  loader, the GPMI selector management, and restart and exit handling.
  New code for this should be conditional on `PROTECTED_MODE`.
- **The CPU word size** of the client (16-bit or 32-bit DPMI client) is
  orthogonal to that. It determines register widths in DPMI calls, the
  size of offsets and of interrupt/exception frames, and the code
  segment default size.

The current implementation is a **16-bit** protected mode client (started
under `HDPMI16`). Some existing identifiers carry "32" for historical
reasons and do not mean 32-bit protected mode: the `GEOS32` product name
and `PRODUCT_GEOS32`, and the directory names `Loader32` and
`Tools/swat/Stub32`.

The restart mechanism described in [1.4](#14-system-restart) does not
depend on the word size. The following places do assume a 16-bit client
and have to be revisited for 32-bit protected mode:

- Saving and restoring the debug exception handler in `InitSys` and
  `EndGeos`. They keep only `CX:DX`, while a 32-bit client uses
  `CX:EDX` for DPMI `0202h`/`0203h`, and the offset is stored as a word in
  `oldDebugExceptionHandler`.
- The loader snapshot and the selector table walk, which use 16-bit
  offsets and `rep movsb` within one 64 KB segment.
- `GPMIFreeRealModeCallback` and the other GPMI wrappers, which pass
  16-bit offsets.

### 1.2 The GPMI

#### 1.2.1 Calling GPMI Services

The loader exports the GPMI through a table of far pointers,
`GPMIVectorTable` in `Loader32/gpmi.asm`. The table is terminated by a
null pointer. At startup, `IGPMIFixupVectorTable` replaces the
real-mode segments in the table with the loader's code selector. The
loader passes the table's address to the kernel in
`KernelLoaderVars.KLV_GPMIVectorTable`.

The entries are indexed by `GPMICallType` (`Include/gpmi.def`), whose
values are byte offsets into the table. The kernel calls a service like
this (see the `GPMI*` wrappers at the end of `Heap/heapCore.asm`):

~~~
les     si, ds:[loaderVars].KLV_GPMIVectorTable
call    {fptr}es:[si+GPMI_CALL_ALLOCATE_BLOCK]
~~~

New entries must only ever be **appended** in front of the terminator,
and the matching enum value must be appended to `GPMICallType`. Because
an older loader has its null terminator in the slot of a newer entry, the
kernel can detect an unsupported service by checking for a segment of 0
(see [1.4.6](#146-compatibility)).

The last entry is `GPMI_CALL_RESTART_LOADER`. It is not a DPMI service
but the loader's restart entry point, and it is the only entry that must
be **jumped to** rather than called (see [1.4](#14-system-restart)).

#### 1.2.2 The Selector Table

The GPMI keeps one `GPMISelector` entry (`Include/Internal/gpmiInt.def`)
for every possible LDT selector below `GPMI_HIGH_SELECTOR_VALUE`
(`0F000h`), which gives `GPMI_NUM_SELECTORS` (7680) entries. The entry
for a selector is at offset `selector & SELECTOR_INDEX_MASK` in a
separately allocated data block (`GPMI_dataSelector`).

| `GPMIS_type` | Meaning | `GPMIS_data1`/`data2` |
|---|---|---|
| `NOT_USED` | Slot not allocated | 0 |
| `EMPTY` | Descriptor allocated, no purpose yet | – |
| `MEMORY` | Descriptor with a DPMI memory block | DPMI block handle (SI:DI for `0502h`) |
| `ALIAS` | Alias of another selector | aliased selector |
| `PHYSICAL_ADDRESS` | Mapped physical address or real-mode segment (`GPMIMapRealSegment`) | address / segment |
| `REAL_SEGMENT` | Selector from DPMI `0002h` (`GPMIAccessRealSegment`) | segment |
| `NOT_PRESENT` | Discarded block, selector kept | 0 |

`GPMIS_flags` (`GPMISelectorFlags`) carries `GPMISF_allocated`,
`GPMISF_isCode`, `GPMISF_isNotPresent` and `GPMISF_resident`.
`GPMISF_resident` marks selectors that belong to the loader itself and
must survive a system restart (see [1.4.4](#144-freeing-the-old-incarnation)).

Selectors that the GPMI obtains directly from DPMI without going through
its own allocation routines are not tracked in the table. Examples are
the GPMI data block itself, and the PSP and environment selectors
provided by the DPMI host. Real-mode callbacks and DOS memory blocks are
not tracked either (see [1.6](#16-real-mode-callbacks-and-dos-memory)).

### 1.3 The Resident Loader

In real mode, the kernel frees the loader's memory once it has
initialized (`Boot/bootInit.asm`). In protected mode this code is
excluded, because the kernel keeps calling into the loader for every GPMI
service. The loader's code segment, its data (written through an alias,
`loaderDSSelector`) and its stack therefore remain valid until GEOS
exits to DOS.

This has two consequences that matter for restarting:

1. There is no need, and no way, to load `loader.exe` again. The loader
   that is already in memory can simply be re-entered.
2. The loader's static variables (`loaderVars`, `kdataSize`,
   `simpleAllocPtr`, the strings buffer, and so on) still hold the state
   left over from the first load, and they must be reset before the
   kernel can be loaded again.

### 1.4 System Restart

`SysShutdown(SST_RESTART)` shuts the system down completely and starts it
again in the same DOS session. This is used, for example, when
configuration changes in Preferences require a restart. On restart the
loader re-reads the `.ini` files, which is what makes the new
configuration take effect.

#### 1.4.1 Why the Real-Mode Restart Cannot Work

In real mode, `DosExecPrepareForRestart` (`Dosappl/dosapplMain.asm`)
copies the position-independent routine `DosExecRestartSystem` into a
fixed code block and points `reloadSystemVector` at it. After the
shutdown, `EndGeos` jumps there. The routine then reloads `loader.exe`
on top of `dgroup` with `MSDOS_EXEC`/`MSESF_LOAD_OVERLAY` and jumps to
its entry point.

None of this works in protected mode:

- The routine is copied by writing through a code selector, and the
  routine then loads a code selector into SS. Both cause a general
  protection fault.
- `int 21h/4B03h` (load overlay) is not translated by DPMI hosts when the
  load segment is a selector.
- Even if the overlay load succeeded, the freshly loaded real-mode loader
  would try to enter protected mode again from inside a running DPMI
  client.

In protected mode these routines are therefore excluded
(`ifndef PROTECTED_MODE`). `DosExecLocateLoader` stays in the build,
because `geos.gp` exports it.

#### 1.4.2 Restart Sequence

1. **`SysShutdown(SST_RESTART)`** calls the protected-mode version of
   `DosExecPrepareForRestart`. It does three things:
   - It reads the `GPMI_CALL_RESTART_LOADER` entry from the GPMI vector
     table. If the segment is 0, the loader is too old, and the routine
     returns carry set, so the restart is refused.
   - It stores the entry in `reloadSystemVector` and sets `EF_RESTART` in
     `exitFlags`.
   - Unless `SCF_RESTARTED` is already set, it prepends `/r` to the PSP
     command tail, so the next incarnation sees `SCF_RESTARTED`. The PSP
     is the same one as before, accessed through the
     `KLV_pspSegment` selector. If the tail has no room left (more than
     124 characters), `/r` is skipped rather than overflowing the PSP.
2. **Shutdown proceeds** as for `SST_CLEAN_FORCED`: applications and
   fields detach, and the UI calls back with `SST_FINAL`, which ends in
   `EndGeos`.
3. **`EndGeos`** (`Boot/bootBoot.asm`) exits the system geodes, file
   system and drivers as usual. It also restores the DPMI debug exception
   handler (see [1.4.5](#145-kernel-state-that-must-be-undone)) and
   notifies the debug stub with `DEBUG_RESTART_SYSTEM`. In real mode,
   `DosExecRestartSystem` sent that notification. Finally it jumps through
   `reloadSystemVector` into the loader.
4. **`LoaderRestartSystem`** (`Loader32/main.asm`) runs as follows:
   - It switches to the loader's own stack, using `loaderSSSelector` and
     `loaderInitialSP`, which were saved at the first start. The kernel's
     stack is about to be freed.
   - It clears ES, FS and GS so that no segment register holds a
     selector that is about to be freed.
   - It puts back all protected-mode interrupt vectors and exception
     handlers the old incarnation left changed (`LoaderRestoreVectors`).
   - It calls `GPMIFreeNonResident` to free every selector and memory
     block of the old kernel incarnation.
   - It copies the loader snapshot back over the loader's data (see
     [1.4.3](#143-the-loader-snapshot)).
   - It jumps to `LoaderRestartEntry` in `LoadGeos`, right behind the
     one-time protected-mode setup.
5. **`LoadGeos`** continues exactly as on a cold start, from video
   detection and the splash screen through reading the `.ini` files and
   initializing the heap, up to loading the kernel. The one-time steps
   are not repeated: `LimitLoaderSize`, `GPMIStartup`, creating the
   loader's data alias, and installing the GPF handler.

If no snapshot could be taken at startup (out of memory),
`LoaderRestartSystem` exits to DOS instead.

#### 1.4.3 The Loader Snapshot

Rather than resetting each loader variable individually, which is easy
to get wrong whenever a variable is added, the loader keeps a copy of
its pristine state.

`LoaderSaveRestartSnapshot` is called once in `LoadGeos`, right after
the loader has entered protected mode and filled in `loaderDSSelector`,
`loaderSSSelector`, `loaderInitialSP`, `KLV_pspSegment` and
`KLV_envSegment`. It does three things:

1. It allocates a GPMI block for the snapshot and the vector table
   (see [1.4.5](#145-kernel-state-that-must-be-undone)) and stores its
   selector in `loaderRestartSnapshot`. This happens *before* copying,
   so the snapshot contains the selector as well.
2. It calls `GPMIMarkResident`.
3. It copies the range `[LoaderRestartSnapshotStart,
   LoaderRestartSnapshotEnd)` of `kcode` into the block.
4. It records all protected-mode interrupt vectors and exception
   handlers (`LoaderSaveVectors`).

The saved range deliberately excludes two areas:

- **`NotifyStub` and the word before it.** `LoaderRestartSnapshotStart`
  is placed directly behind `NotifyStub`, so a hook that Swat patched
  into `NotifyStub` is not overwritten by a restart.
- **The stack.** The loader runs on it while restoring. The stack is a
  separate segment behind `kcode`. `LoaderRestartSnapshotEnd` is the last
  label in `kcode` (at the end of `Loader32/Text/loader.asm`), so the
  stack is not part of the range.

**Both ends of the range must be labels in the same segment.** The
first version used the start of the `stack` segment as the end of the
range. Esp/Glue do not compute the difference of labels in two
different segments of a group group-relative: `offset cgroup:startStack
- offset cgroup:LoaderRestartSnapshotStart` came out as `0 - 0Bh`, i.e.
almost 64 KB, although the map file showed the right offsets. The
snapshot then covered the loader *and everything behind it* in
conventional memory, and every restart wrote that stale copy back. That
included HDPMI's real-mode stack for the client. The result was a
system whose first mouse click after a restart froze the machine, and
whose input died after a while. If you change the snapshot range, check
the computed size, not only the map file.

The snapshot is about 10 KB and covers code as well as data. Restoring
code bytes is harmless, since they are identical. However, it does
remove any breakpoints that Swat has placed in loader code after the
first start.

#### 1.4.4 Freeing the Old Incarnation

The kernel's heap does not free its blocks when the system exits. In
real mode this does not matter, because the whole memory image is
discarded. In protected mode, every selector and DPMI memory block of
the old incarnation would leak. A handful of restarts would then exhaust
the LDT, given the roughly 3500 handles configured in a typical
`geos.ini`.

The cleanup is based on `GPMISF_resident`:

- `GPMIMarkResident` sets the flag on every selector that is in use when
  the snapshot is taken. At that point these are the loader's own
  selectors, such as the data alias and the snapshot block. Everything
  allocated later (kdata, the handle table, kernel resources, and all
  blocks of the running system) is kernel-owned.
- `GPMIFreeNonResident` walks the whole selector table and frees each
  entry that is not resident, according to its type:
  - `MEMORY`: DPMI `0502h` with the handle stored in `data1:data2`, then
    the descriptor is freed.
  - `NOT_PRESENT`, `ALIAS`, `EMPTY` and `PHYSICAL_ADDRESS`: only the
    descriptor is freed.
  - `REAL_SEGMENT`: kept. Selectors returned by DPMI `0002h` cannot be
    freed, and the host hands out the same selector again for the same
    segment.

The table offset becomes a selector by OR-ing in the TI and RPL bits,
which are taken from CS.

#### 1.4.5 Kernel State That Must Be Undone

Anything the kernel installs *outside* its own memory must be removed in
`EndGeos`, because after a restart the code it points to no longer
exists. Most of this was already handled for exiting to DOS:
`ThreadRestoreExceptions`, `SysResetIntercepts` and
`RestoreTimerInterrupt` all restore their vectors through the GPMI. One
item was missing:

- `InitSys` installs `SysContextSwitchReflector` as the DPMI handler for
  the debug exception (exception 1) when the system does not run under
  Swat. It now first saves the previous handler (via
  `GPMI_CALL_GET_EXCEPTION_HANDLER`) in `oldDebugExceptionHandler`
  (`udata`, `Sys/sysVariable.def`). `EndGeos` restores it right after
  `ThreadRestoreExceptions`.

**The loader puts all protected-mode interrupt vectors and exception
handlers back.** When a DPMI client ends, the DPMI host resets everything
the client hooked; a restart inside the same client must do that itself.
`LoaderRestoreVectors` compares every protected-mode interrupt vector
(DPMI `0204h`) and exception handler (`0202h`) with the values recorded
at the first start, before anything is freed, and sets back each one
that differs (`0205h`/`0203h`). Setting a vector back to the DPMI host's
default also makes the host remove its own real-mode hooks for it.
The kernel currently leaves the hardware interrupt vectors `09h`–`0Fh`
and `70h`–`77h` and the vectors `80h`–`8Fh` pointing into its code after
exit. Without the restore, the next incarnation crashes as soon as one of
these interrupts occurs, for example IRQ 12 on a mouse click. Vectors set
by the Swat stub before the loader started are part of the recorded
state and therefore survive.

When adding protected-mode code that hooks DPMI exceptions, interrupts or
real-mode callbacks, still pair the hook with a restore in the exit
path. The loader's restore is a safety net, not a replacement.
The host interface's event interrupt is a special case of this rule,
because the host keeps raising it after GEOS is gone (see
[1.7](#17-the-host-interface-event-interrupt)).

#### 1.4.6 Compatibility

- **New kernel, old loader:** the GPMI table has its terminator in the
  `GPMI_CALL_RESTART_LOADER` slot, so `DosExecPrepareForRestart` returns
  carry and `SysShutdown(SST_RESTART)` fails cleanly.
- **Old kernel, new loader:** the old kernel never jumps to the new
  entry. It still attempts the real-mode restart, which does not work in
  protected mode, exactly as before.
- **Real-mode builds** (no `PROTECTED_MODE`) are unchanged.

### 1.5 Rebooting the Machine

`SST_REBOOT` (also used by `SysNotify` when
`SYS_NOTIFY_USE_REBOOT_IF_RESTART` is set) used to write the warm-start
flag to segment `40h` and then do `jmp BIOSSeg:Reset`. Both fault in
protected mode. The protected-mode version of `resetMachine` in
`EndGeos` instead does the following:

1. It maps the BIOS data area with `SysMapRealSegment` and sets
   `BIOS_RESET_FLAG` to `BRF_WARM_START`.
2. It pulses the CPU reset line through the keyboard controller: it
   waits for the input buffer to empty, then writes `0FEh` to port `64h`.
3. If the machine is still running after a short delay, it exits to DOS
   rather than hanging.

In `Boot/bootConstant.def`, the `Reset` label is excluded under
`PROTECTED_MODE` to avoid an unused-symbol warning. The segment `BIOSSeg`
itself stays, because `geos.gp` lists it as a resource.

This path has not been tested yet.

### 1.6 Real-Mode Callbacks and DOS Memory

`SysAllocRealModeCallback` and `SysFreeRealModeCallback` wrap DPMI
`0303h`/`0304h`. Two bugs prevented callbacks from ever being freed:

- `GPMIFreeRealModeCallback` in the loader was a copy of `GPMIFreeAlias`.
  It now calls DPMI `0304h` with the callback address in `CX:DX`.
- `GPMIFreeRealModeCallbackFar` in the kernel (`Heap/heapCore.asm`)
  called `GPMIFreeAlias`. It now calls `GPMIFreeRealModeCallback`.

DPMI hosts provide only a small number of callbacks, so leaking them
breaks the system after a few restarts.

Real-mode callbacks and DOS memory blocks (`SysAllocDOSBlock`, DPMI
`0100h`) are **not** recorded in the GPMI selector table, so
`GPMIFreeNonResident` cannot clean them up. Drivers that allocate them
must free them in their exit routines. A callback that is left installed
in a real-mode driver (for example a mouse driver's event handler) calls
into freed code after a restart.

### 1.7 The Host Interface Event Interrupt

The HostIf library (`Library/HostIf`) talks to basebox, the DOSBox-based
emulator. Besides synchronous calls through I/O port `38FFh`, the host can
notify GEOS asynchronously: after `HIF_SET_EVENT_INTERRUPT`, basebox raises
software interrupt `A0h` whenever it queues an event, for example a socket
state change, the completion of an asynchronous socket or SSL operation,
or a display size change. `HostIfInterrupt` then posts
`MSG_HOSTIF_PROCESS_EVENTS` to HostIf's process, which fetches the events
with `HIF_GET_EVENT`.

#### 1.7.1 Why the Interrupt Needs Special Care

The host side has three properties that matter for shutdown and restart
(see `src/geos/geoshost.cpp` in pcgeos-basebox):

- **It cannot be turned off.** `HIF_SET_EVENT_INTERRUPT` ignores its
  parameter and always uses vector `A0h`, in the CPU mode that was active
  when it was registered. No command unregisters it. Events keep coming
  after GEOS has shut down, for instance from host sockets that are
  still open.
- **It only fires on the empty-to-non-empty transition** of its event
  queue. Events left in the queue keep a new registration from ever
  being notified.
- **The real-mode end of the vector is not set up.** Once nobody handles
  `INT A0h` in protected mode, the DPMI host reflects it to the real-mode
  vector. DOSBox only initializes vectors `00h`–`5Fh` and `68h`–`6Fh`, so
  real-mode `A0h` is `0000:0000`. Simply restoring the previous vector
  turns "jump into freed GEOS memory" into "jump to address 0".

A further complication: HostIf is a library with its own process, and
nothing detaches such a process at system exit. Applications are detached
by their field, and `RemoveGeodes` only calls `DR_EXIT` on drivers.
HostIf itself is never unloaded, because `vga16` keeps a reference to it.
HostIf is loaded while the UI process is still attaching (`vga16` is
loaded from `UserMakeScreens`), so it cannot register as an application
either.

#### 1.7.2 How HostIf Handles It

- **At attach** (`HostIfAttach`), and only if `HostIfDetect(HIF_API_HOST)`
  reports a host:
  1. `HostIfGuardRealModeVector` points the real-mode `INT A0h` vector at
     the BIOS dummy interrupt handler, an IRET at `F000:FF53`. It does this
     only if the vector is still `0000:0000` and only after checking that
     the IRET byte really is there. The vector is deliberately left that
     way after GEOS exits.
  2. It hooks the protected-mode vector with `SysCatchInterrupt`.
  3. It drains events left over from an earlier session or incarnation.
  4. It registers the interrupt with `HIF_SET_EVENT_INTERRUPT`.
- **At shutdown**, `HostIfShutdown` (exported, protocol 1.1, safe to call
  more than once) does the following:
  1. It sets `hostIfDetached`, so a late interrupt no longer posts to the
     process.
  2. It restores the protected-mode vector.
  3. It drains the host's event queue.

  After that, a host event ends at the IRET. This holds after exit to DOS,
  during a restart, and in the next DPMI client before HostIf hooks the
  vector again. Asynchronous host operations cannot complete after
  `HostIfShutdown`.
- **Who calls `HostIfShutdown`:** the common video driver exit `VidExit`
  (`Driver/Video/VidCom/vidcomInfo.asm`), under `ifdef __HOSTIF`, so only
  in drivers that include `hostif.def` (currently `vga16`). The video
  driver is a system driver, so this happens only at system exit
  (`ExitSystemDrivers`), while the system is still alive. `hsttcpip` must
  not call it: its `DR_EXIT` also runs when the socket driver is unloaded
  during normal operation.
- `HostIfDetach` also calls `HostIfShutdown`, which covers the case of the
  library really being unloaded.
- An asynchronous result for a slot that has no waiter is dropped (EC
  warning `HOSTIF_ASYNC_RESULT_WITHOUT_WAITER`) instead of being written
  through a null pointer.

A cleaner long-term solution would need a basebox change:
`HIF_SET_EVENT_INTERRUPT` would honour the vector in its parameter, treat
vector 0 as "disable", and clear the queue on (re)registration.

### 1.8 Zero-Initialized Reallocation of Discarded Blocks

`MemReAlloc` with `HAF_ZERO_INIT` on a **discarded** block must return
zeroed memory. Drivers rely on this, for example the TrueType driver's
variable block, which is allocated discarded and brought in by
`TrueType_InitFonts` with `HAF_ZERO_INIT`.

In protected mode, `DoReAlloc` (`Library/Kernel/Heap/heapLow.asm`) brings
a discarded block back with `GPMIMakePresent`. That path ignored
`HAF_ZERO_INIT`, so the block contained whatever DPMI memory (`0501h`)
handed out, which is not zeroed. The first DPMI client in a fresh session
usually gets zero memory by chance. Later clients, and the incarnation
after a restart, get memory still holding data from before. With
TrueType this crashed the system on the first text output:
`TrueType_Free_Face` found a stale face name in the uninitialized
variables and closed a face through stale pointers.

The protected-mode branch now zero-fills the whole block after
`GPMIMakePresent` when `HAF_ZERO_INIT` is passed. When reviewing
protected-mode heap code, check that every allocation path honours
`HAF_ZERO_INIT`. With DPMI memory, "it was zero in my test" proves
nothing.

### 1.9 Swat Support

The Swat stub (`Tools/swat/Stub32`) is itself the DPMI client: it enters
protected mode, loads the loader into its session (`MSESF_LOAD`), and the
loader finds protected mode already active. A restart can therefore not
start a new DPMI client without ending the stub and the connection to
Swat. This is one reason why the restart is done inside the client.

In real mode, the stub sends Swat two messages for a restart:
`RPC_DOS_RUN` at `DEBUG_RESTART_SYSTEM`, and `RPC_RELOAD_SYS` when it
sees the `int 21h/4B03h` that reloads the loader. On `RPC_DOS_RUN`, Swat
drops all patients and makes the loader the current patient with a
current thread. Since there is no such `int 21h` call in protected mode,
`RestartSys` in `Tools/swat/Stub32/kernel.asm` sends both messages right
away, in the same order. Without `RPC_DOS_RUN`, Swat keeps the old
kernel's patients and fails with "no current thread". The hook in the
loader's `NotifyStub` stays in place, so the loader's
`DEBUG_LOADER_MOVED` and `DEBUG_KERNEL_LOADED` notifications re-attach
Swat to the new kernel.

To build the stub, run `pmake SUBDIRS=LowMem LowMem/swat.exe` in
`Installed/Tools/swat/Stub32` and copy `LowMem/swat.exe` into the
target's `ensemble` directory.

#### 1.9.1 Exit to DOS Under the Stub

In real mode the stub gets control back when GEOS's final `int 21h/4Ch`
terminates the loader process: the loader's DOS terminate address
(`PSP_saveQuit`) points to `MainGeosExited`, which sends `RPC_EXIT` to
Swat. In protected mode the stub, the loader and GEOS share one DPMI
session. The session belongs to the loader's process, because the stub
loads the loader first (`4B01h`) and only then enters protected mode
through the loader's GPMI. GEOS's `4Ch` therefore ends the session, and
DOS returns to `MainGeosExited` in real mode, where none of the stub's
selectors are valid. Swat never got `RPC_EXIT` and hung after
"Thread 0 of ui exited". This problem existed independently of the
restart work.

The stub now installs a protected-mode `int 21h` hook
(`MainHookDOSExit`, `StubInt21` in `Stub32/main.asm`) before the loader
starts, so the loader records it with all other vectors and keeps it
across restarts:

- When GEOS calls `4Ch` (`geosgone` not set yet), the hook jumps to
  `MainGeosExited` while still in protected mode. That path sends
  `RPC_EXIT` to Swat, or exits directly if no Swat host is connected;
  both end in `RpcExit`.
- When `RpcExit` finally calls `4Ch` itself (`geosgone` set), the hook
  first points the loader PSP's terminate address at `MainRMExit`, a
  real-mode routine that terminates the stub as well. The DPMI host
  then ends the session, DOS terminates the loader process and returns
  to `MainRMExit`, and that returns control to the DOS shell.

After `GEOS Exited`, Swat stops at its prompt and shows a leftover
position. Nothing is running anymore at that point.

Right after the exit, Swat still reads memory of blocks GEOS has
already freed. `Kernel_ReadAbs` checked selectors with `VERR`, which
ignores the present bit, so such a read faulted inside the stub
("Segment not present"). `KernelSelectorPresent` (`LAR`, bit 15) now
guards `Kernel_ReadAbs`, `Kernel_WriteAbs` and `Kernel_FillAbs`.
`Kernel_ReadAbs` also passed the selector to `GPMITestPresent` in `BX`,
while that routine expects it in `AX`.

#### 1.9.2 Test Status

Tested with the Swat host attached (the Linux build of Swat): exit to
DOS, three restarts in a row, and a restart followed by exit to DOS.
Swat re-attaches after each restart and shows `GEOS Exited` at the end;
DOS continues.

Open: under the stub **without** a Swat host connected, a restart hangs
before the video driver exits. This also happens with the stub before
the exit hook, and not with a host attached.

### 1.10 Testing the Restart

The restart can be tested without user interaction. Use a small test
application that runs from `execOnStartup` and does the following each
time it starts:

- It increments a counter in `geos.ini`.
- It records the free DPMI memory (`int 31h/0500h`).
- It calls `SysShutdown(SST_RESTART)` until the counter reaches a limit,
  and then calls `SST_CLEAN_FORCED`.

Run the target headless in basebox with an `[autoexec]` like the
following:

~~~
mount c: <gbuild>/localpc
c:
cd ensemble
hdpmi16
loaderec
echo finished > c:\done.txt
exit
~~~

To run it, set `SDL_VIDEODRIVER=dummy` and `SDL_AUDIODRIVER=dummy` and
call `basebox -noprimaryconf -nolocalconf -conf test.conf`. Each
incarnation logs `GEOSHOST: Set video mode` once, so the number of boots
within a single `loaderec` run can be counted in the basebox log.

To make the test meaningful, the test application also renders some
TrueType text in every incarnation. That opens the TrueType driver's
face and cache, which exposed the problem described in
[1.8](#18-zero-initialized-reallocation-of-discarded-blocks). To test
separate sessions as well, run several `loader` commands in a row in one
DOS session. That needs `hdpmi16 -r`: without `-r`, HDPMI unloads when
its last client exits.

Results with the final build:

| Build | Scenario | Result |
|---|---|---|
| EC, without restart support | restart | 1 boot, then back to DOS |
| NC | 20 restarts with TrueType text | 20 boots, clean exit |
| EC | 20 restarts with TrueType text | 20 boots, clean exit |
| NC, EC | 20 restarts under the Swat stub (no host attached) | 20 boots, clean exit |
| NC | 5 separate `loader` runs with TrueType text | 5 clean runs |
| NC, EC | after a restart: keys, mouse move, click, keys | input keeps working |

Input was sent into basebox with `xdotool` under `Xvfb`. For tracing
during development, writing single characters to COM1 (port `3F8h`,
waiting for the transmitter to be empty) works in every context,
including interrupt handlers. basebox can pass COM1 on to a TCP
listener (`serial1=nullmodem server:127.0.0.1 port:7000 transparent:1`).
The Swat stub uses COM1 itself, so this does not work under the stub.

If the free memory stays constant, nothing leaks between incarnations.
LDT descriptors (counted by allocating them until DPMI refuses) stayed
exactly constant as well. If selectors leaked, the LDT would run out
within a few boots.

### 1.11 Building on Linux

The protected-mode system builds on Linux with the Open Watcom snapshot
from the main README. A few points are specific to this branch:

- `Loader32/gpmi.asm` must include `Internal/gpmiInt.def` with a forward
  slash. A backslash only works on Windows.
- `Installed/Library/User/Makefile` must not list the `GEOS32` product in
  `PRODUCTS`. The product-specific variant fails to assemble, and it is not
  needed, because the regular target is already a protected-mode build
  (see [1.1](#11-overview)).
- On current Perl versions, `buildbbx.pl` needs
  `perl -I Tools/build/product/bbxensem/Scripts ...` to find
  `newgetopt.pl`.
- `pmake -L <n>` builds several targets in parallel.
- An interrupted build can leave truncated object files behind. `glue`
  then reports "invalid object module (not VM or MS format)". Delete the
  affected `.obj`/`.eobj` file and build again.

### 1.12 Video Driver Re-Initialization and videoSem

`DriverStrategy` (`Driver/Video/VidCom/vidcomEntry.asm`) serializes the
drawing functions with `videoSem`, but dispatches escape codes without
it. On a host display size change, the UI's screen object
(`OLScreenNotify`, `CommonUI/CWin/cwinScreen.asm`) calls the escape
`VID_ESC_UPDATE_DEVICE` on the UI thread, while other threads may be in
the middle of drawing. In `vga16` this escape re-initializes the device
through `DRE_SET_DEVICE`, which:

- runs on the driver's single shared stack (`VidCallMod`, `endVidStack`),
- rewrites the mode, the video memory windows and the segments the
  drawing code is using.

In real mode the race produced drawing glitches at most. In protected
mode it crashed a concurrent text output with a protection violation in
`SlowGenClip` (`mov ds, fs:[currentWin]`), seen in the browser while the
display was rescaled in a DPI mode. `VidEscSetDeviceAgain`
(`vga16Escape.asm`) now holds `videoSem` while it re-initializes the
device. `DRE_SET_DEVICE` does not call back into `DriverStrategy`, so
this cannot deadlock.

The general lesson: code that relied on a race being harmless in real
mode, because a stale segment value only produced garbage, now faults
in protected mode, because loading a stale selector raises an
exception.

### 1.13 Real-Mode Buffers for BIOS Calls

Protected-mode code that calls a real-mode service through DPMI `0300h`
(`SysRealInterrupt`) needs real-mode memory for buffers and for the
real-mode stack. That memory must be **allocated** (`SysAllocDOSBlock`),
not taken from a fixed segment.

`VidSetVESA` and `VidTestVESA` in `vga16` (`vga16Admin.asm`) used the
fixed segment `2000h` for the VESA info and mode info buffers, at offset
0, and for the real-mode stack, at offset `600h`. On every display
change this wrote into whatever DOS, the DPMI host, the loader or the
Swat stub kept at linear address `20000h`. Hardware interrupts that
occur while the DPMI host is in real mode for the BIOS call are handled
on the same real-mode stack, including the host's switch to the
protected-mode handler. The stack could therefore grow down into the
mode info buffer before it was copied, which is a plausible cause of
the divide error in `CalcLastScanPtr` (a zero `VMI_scanSize`) seen after
switching to full screen in a DPI mode.

The driver now:

- allocates one DOS block for the buffer and a 4 KB real-mode stack
  (`VidGetVesaBuffer`), and frees it in `VidExit`. A 512-byte stack was
  not enough in tests.
- takes the mode info only if `int 10h/4F01h` returned `004Fh` and the
  scan size is not zero. Otherwise it keeps the previous mode info.
- reuses the selectors for the VESA window segments
  (`VidMapVesaWinSeg`) instead of creating new ones on every display
  change.

`SysFreeDOSBlock` expects the selector in `DX` (DPMI `0101h`), although
its header comment says `AX`.

These changes were tested only partially: the mode info was correct for
every switch in a traced run, but the emulator under test was too slow
at large DPI resolutions to tell a hang from a slow redraw.

### 1.14 Driver Buffers and Large Screens

`vga16` supports screen sizes chosen at run time (`MULT_RESOLUTIONS`). Some
of its buffers are nevertheless sized for a maximum screen:

- `lineMaskBuffer` (`vidcomVariable.def`) holds the clip mask for one
  scan line, one bit per pixel. `ValLineMask` generates the mask for the
  full current width (`VDI_pageW`).
- `polyEdge` (`vidcomPolygon.asm`) holds one word per scan line for
  polygon fills.

Their sizes come from `MAX_MASK_BUFFER` and `MAX_POLYGON_EDGE_TABLE` in
`vga16Constant.def`, which were 161 bytes (1280 pixels) and 768 lines.
In a DPI mode on a large host display, the driver asks basebox for up
to 2040×1536 pixels. The line mask then overran its buffer and
overwrote the driver variables behind it: `currentWin` (a protection
fault in `SlowGenClip` on `mov ds, fs:[currentWin]`), `drawMask`,
`stateFlags`, and others. The result was crashes in varying places after
switching to full screen. In real mode the same overrun mostly produced
garbage on screen.

Both buffers are now derived from `VGA16_MAX_WIDTH` and
`VGA16_MAX_HEIGHT` (2040×1536, basebox's limit). `VidSetVESA` clamps the
size it requests in a DPI mode to these values, so the buffers cannot be
overrun even if the host's limits change.
