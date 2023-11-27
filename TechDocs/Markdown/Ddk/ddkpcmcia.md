
## 3 PCMCIA Drivers

This chapter explains the fundamentals associated with writing a PCMCIA
driver for GEOS . Life for a PCMCIA driver— as with a human being— begins
and ends with traumatic events. The driver’s birth begins with the insertion
of a card into the device; its death is marked by the removal of that card.
When writing a PCMCIA driver, you may want to contemplate your own end
and handle the removal case elegantly, for the driver’s sake if not for your
own.

When a card is first inserted into a PCMCIA “socket” (or “slot”) GEOS will load
all drivers for that card that it finds, one after the other. Those that are found
to be compatible with the card remain loaded as long as the card remains
within the chosen socket. The removal of a card is the other big event in the
PCMCIA driver’s life. At that point, if anything is actively using the card, the
driver can raise an objection to that removal and attempt to resolve any
conflicts that arise.

A PCMCIA driver is a complex driver; there are many other events besides
insertion and removal that a typical driver will need to handle. These events
are usually functions of CardServices, a third-party library licensed to
Geoworks, and, more specifically, the GEOS PCMCIA library interface to
CardServices. This chapter is not meant to document all of these complex
cases because drivers, whether file system or serial, may exhibit vastly
different characteristrics. You will want to consult the pcmcia.def file on the
SDK for more information on handling these functions.

A PCMCIA sample driver that you may use as a template is available in
\OMNIGO\DRIVER\DDK\PCMCIA\SAMPLE . Other (functioning) drivers are
located within \OMNIGO\DRIVER\DDK\PCMCIA.

### 3.1 PCMCIA Drivers Basics
Writing a GEOS device driver for PCMCIA cards is somewhat different than
writing a driver for other devices. The driver acts not only with the device,
but with the PCMCIA library (a GEOS library) and CardServices.

A PCMCIA driver must handle the four basic DriverFunction calls and
must also handle the specific PCMCIAFunction calls defined in
pcmciaDr.def. PCMCIA drivers are not extended, so they do not need to
handle the DriverExtendedFunction calls.

Because your driver must interact with CardServices, it must also define a
callback routine handling the specific CardServicesEventCode types. It
will also need to send function calls to CardServices using the
CardServicesFunction type.

#### 3.1.1 State Information
A PCMCIA driver needs to maintain information about the card(s) and
socket(s) that it is driving. The “socket” refers to the physical slot of the
PCMCIA hardware interface. (This should not be confused with the GEOS
Socket library API .) Each driver should contain the capability to support
multiple sockets since hardware platforms may contain multiple PCMCIA
ports. Also, CardServices may map multiple logical sockets to a single
physical socket; this allows CardServices to mimic multi-function cards.

A driver should keep information about each socket in some structure table.
The information stored in this table is, of course, up to the driver. Examples
of information that may be necessary:
+ The socket number.
+ Whether the card was removed while it was in use.
+ How the card was configured. This depends on the requirements of the
device.

#### 3.1.2 Handling Basic Functions
``DR_INIT, DR_EXIT``  
Your PCMCIA driver will need to handle the basic DR_INIT and DR_EXIT
routines defined in driver.def. (There usually is not any need to handle
DR_SUSPEND and DR_UNSUSPEND .) Because PCMCIA drivers are not
extended, there is no need to handle DRE_TEST_DEVICE and
DRE_SET_DEVICE.

##### 3.1.2.1 Insertion
As noted, the insertion or removal of a PCMCIA card are the two most
important events in the driver’s life. When a driver is first loaded, it registers
with CardServices. Among other things, this registration allows the driver to
be told when a card is inserted. (Be patient; this is not as non-sensical as it
seems.)

Of course, inserting a card prompted the registration in the first place! This
only means that the driver is guaranteed to receive notification that at least
one card was inserted, after registration with CardServices is complete. Once
informed of this event (or additional insertion events), the driver must
examine the card (now within a “socket”) to discern whether it can support
the card. If the card is compatible, the driver configures the card according to
its own specifications and makes its devices and/or memory available to
GEOS.

##### 3.1.2.2 Removal
The removal of a PCMCIA card is a difficult event for a PCMCIA driver. The
driver may be writing a file to the card; it may be communicating something
over the serial line. No one wants to “go” when confronted with the tasks still
remaining, but unlike us, a PCMCIA driver has the option of objecting to its
removal.

If something is actively using the card, the driver must tell the PCMCIA
library to object to the card’s removal. The library will inform the user that
the removal was effected under hostile protest. The user then has the option
of reinserting the card and either leaving it in (and allowing whatever
objected to the removal finish its business) or force GEOS to stop accessing
the card (for example, by closing applications). The user always has the
option of rebooting the system if the card is no longer available.

The last thing a driver will do is unregister itself with CardServices.
Afterward, the socket is closed and the driver is unloaded.

___
+ ``DR_INIT``  
This function is sent to the driver by the kernel when the driver is first
loaded. A PCMCIA device driver should handle this call by registering as a
CardServices client. It does this by invoking the CardServicesFunction
CSF_REGISTER_CLIENT event. (See “PCMCIA Library Functions” on page
49.) This registration is a separate issue than registration with the PCMCIA
library itself; that should take place in your DR_PCMCIA_CHECK_SOCKET
routine. (At that time, the driver will know into which socket the card was
inserted.)  
The driver should return carry set (failure) only if it is incompatible with
CardServices or the current environment in some way. The driver cannot
consult the card to see if it supports it yet; it does not yet know into what
socket the card was inserted. (That information is provided at a later time by
the CSEC_CARD_INSERTION event from CardServices.)  
This function is guaranteed to occur before a DR_PCMCIA_CHECK_SOCKET
event; that function must wait for the registration (initiated by this handler)
to be complete before checking whether the card is supported.

__Pass:__
  - di -> DR_INIT (= 0).
  - cx -> value of di passed to GeodeLoad. If the driver was not
loaded through GeodeLoad, the value in this register is
undefined.
  - dx -> value of bp passed to GeodeLoad. If the driver was not
loaded through GeodeLoad, the value in this register is
undefined.

__Returns:__
  - CF -> Set if initialization failed; the system will then automatically
unload the driver.

 __Destroyed:__  
  - Allowed to destroy ax, cx, dx, ds, es, di, si, bp

__Include:__  
driver.def

Code Display 3-1 Sample DR_INIT Routine
~~~
SampleInit     proc            far
       .enter

       ; If you will need another driver to get your work done, retrieve its
       ; strategy routine here and store it. Fetching the strategy routine of
       ; another driver involves loading in the core block, which we can’t do at
       ; interrupt time.

       ; Register as a CardServices client. We do this by retrieving the address
       ; of the callback routine (which must be in fixed memory) and sending
       ; CSF_REGISTER_CLIENT to CardServices.

       mov     di, segment     SampCardServicesCallback
       mov     si, offset      SampCardServicesCallback 
       mov     cx, size        regArgList
       segmov  es, cs
       mov     bx, offset      regArgList
       CallCS  CSF_REGISTER_CLIENT
       jc      fail

       ;
       ; ds is assumed loaded by the strategy routine ...
       ;

       mov     ds:[csHandle], CS_HANDLE_REG
       clc

done:
       .leave
       ret
fail:
       stc
       jmp     done
SampleInit     endp

; 
; Set this thing up appropriate to the card you’re driving.
; In some cases, your driver may manage an I/O device but register as
; a memory client to make sure the automatic configuration client
; gets called to configure the card before this driver gets called.
; It depends on who does the actual configuration for the cards you
; manage.
;

regArgList     CSRegisterClientArgs <
       mask CSRCAA_ARTIFICIAL_EXCLUSIVE or mask CSRCAA_ARTIFICIAL_SHARED or \
               mask CSRCAA_MCD,
       mask CSEM_CARD_DETECT_CHANGE,
       < 0, segment dgroup, 0, 0>,
       0201h


Init   ends
~~~

___
+ ``DR_EXIT``  
This function is sent to a driver by the kernel when it is being unloaded. A
PCMCIA device driver should handle this call by at least de-registering as a
CardServices client. It does this by sending the CSF_DEREGISTER_CLIENT
event defined in the PCMCIA library. The driver should also release any
resources it may have requested from CardServices.

__Pass:__
  - di -> DR_EXIT (= 2).

__Returns:__  
  - Nothing.

__Destroyed:__  
  - Allowed to destroy ax, bx, cx, dx, ds, es, di, si.

__Include:__  
driver.def

Code Display 3-2 Sample DR_EXIT Routine
~~~
SampleExit     proc    far
               uses    ax, cx, dx

        .enter

        clr    cx
        mov    dx, ds:[csHandle]
        CallCS CSF_DEREGISTER_CLIENT

        clc
        .leave
        ret
SampleExit     endp
~~~

#### 3.1.3 PCMCIA Driver Functions
``DR_PCMCIA_CHECK_SOCKET, DR_PCMCIA_OBJECTION_RESOLVED,
DR_PCMCIA_CLOSE_SOCKET, DR_PCMCIA_DEVICE_ON, DR_PCMCIA_DEVICE_OFF``

In addition to handling the basic functions, a PCMCIA driver must be able to
handle the functions defined by PCMCIAFunction, a special enumerated
type defined in pcmciaDr.def.  
The first of these function names is an enumerated value equal to 8 (or two
past the last DriverFunction), and the constants increase by two
thereafter.
___
+ ``DR_PCMCIA_CHECK_SOCKET``  
The PCMCIA library calls this function when a card has been inserted into the
device. This function will only occur after a DR_INIT has already occurred;
that function should register the socket as a CardServices client.  
In your handler for this function, make sure to wait for the registration with
CardServices to complete. (This is typically done with a wait loop; the loop
checks the state of a driver flag indicating whether notification has been
completed.) After this has occurred, the PCMCIA driver should also check the
socket for compatibility with the card inserted.  
This function typically takes place after a CSEC_CARD_INSERTION event has
occurred. Drivers should respond to a CSEC_CARD_INSERTION event by
setting a driver flag indicating whether the indicated driver supports the
card.  
A driver responding to a DR_PCMCIA_CHECK_SOCKET should wait until
registration is complete (by receipt of a CSEC_REGISTRATION_COMPLETE
event). At that point, they can test whether the CSEC_CARD_INSERTION
event occurred smoothly.  
If the card is supported, the driver should then register with the PCMCIA
library using PCMCIARegisterDriver. This will register your driver with
the PCMCIA library for the particular card in the particular socket . Note that
this is a separate registration than that with CardServices.

__Pass:__
  - cx -> Socket number.
  - di -> DR_PCMCIA_CHECK_SOCKET
  
__Returns:__
  - CF -> Set if PCMCIA card in the socket is supported by the driver.

__Destroyed:__
  - di

__Include:__  
pcmciaDr.def

Code Display 3-3 Sample DR_PCMCIA_CHECK_SOCKET Routine
~~~
SampIeCheckSocket      proc    far
socket         local   word    push cx
       uses    ax, bx, cx, dx, si
       .enter
       ;
       ; Wait to make sure we’ve received all the artificial insertion
       ; events so we know whether we support the card.
       ;

waitForRegistrationLoop:
       tst     ds:[amRegistered]
       jz      waitForRegistrationLoop

       ;
       ; See if we support the thing.
       ;

       call    SampUDerefSocket
               CheckHack <SCS_NO eq 0>
       tst     ds:[bx].SSI_support
       jnz     processIt
fail:
       clc     ; not our card

done:
       .leave
ret

processIt:
       ;
       ; If the card has been configured by someone outside of this driver,
       ; here’s where you’d fetch the configuration info from Card Services
       ; and tell other people about it so the thing can be used within
       ; GEOS.
       ;

       PrintMessage <INSERT CODE HERE>

       ;
       ; Register with the library, finally.
       ; bx <- geode handle
       ; cx <- socket
       ; dx <- cs handle
       ; es:di <- CSRegisterClientArgs
       ; ax:si <- cs callback
       ;

       mov     bx, vseg regArgList
       call    MemLockFixedOrMovable
       mov     es, ax
       mov     di, offset regArgList

       mov     bx, handle 0

       mov     cx, ss:[socket]

       segmov  ds, dgroup, ax
       mov     dx, ds:[csHandle]

       mov     ax, segment SampCardServicesCallback
       mov     si, offset SampCardServicesCallback
       call    PCMCIARegisterDriver

       mov     bx, vseg regArgList
       call    MemUnlockFixedOrMovable

       stc             ; happy happy happy
       jmp     done

SampIeCheckSocket endp
~~~

____
+ ``DR_PCMCIA_OBJECTION_RESOLVED''  
The PCMCIA library calls this function when the user has answered an
objection raised to the removal of a card. The function passes a
PCMCIAObjectionResolution type in dx indicating the nature of the
resolution. If that value is PCMOR_CLEAN_UP , then the user has asked that
the card be ejected. The driver should attempt to remove any references to
the card.
~~~
PCMCIAObjectionResolution      etype word, 0, 1
PCMOR_CLEAN_UP                 enum PCMCIAObjectionResolution
PCMOR_USER_CANCELED            enum PCMCIAObjectionResolution
PCMOR_SYSTEM_CANCELED          enum PCMCIAObjectionResolution
~~~
If the user of system cancelled the removal, the driver should simply note
that the objection has been resolved.  
A driver should always respond to the PCMOR_CLEAN_UP event, even if it
did not raise an objection, as the user may not have actually removed the
card. This allows the driver to clean up before a card is removed (for example
if the user is initiating an ejection of the card through software control).

__Pass:__
  - cx -> Socket number.
  - dx -> PCMCIAObjectionResolution.
  - di -> DR_PCMCIA_OBJECTION_RESOLVED

__Returns:__
  - CF -> (Only meaningful if PCMOR_CLEAN_UP was passed)
Clear if the driver was able to remove all references to the
card; set otherwise.

__Destroyed:__
  - di

__Include:__  
pcmciaDr.def

___
Code Display 3-4 Sample DR_PCMCIA_OBJECTION_RESOLVED Routine
~~~
SampleObjectionResolved        proc    far
       .enter
               CheckHack       <PCMOR_CLEAN_UP eq 0>
       tst_clc dx
       jz      attemptCleanUp

       ;
       ; In theory, since the removal was canceled and the card is back, we’d
       ; release any access blocks we might have placed, allowing the card to
       ; be reached again.... we currently set no blocks, though, so this
       ; is a nop.
       ;

       PrintMessage    <MAYBE INSERT CODE HERE>

done:
       .leave
       ret

attemptCleanUp:
;
; Here’s where you’d try to get the things that are using the card to
; stop using them. Sometimes you can’t do that, in which case you
; return carry set if the card is still in-use. If you can, though,
; try for a bit and occasionally call SampCSCheckCardInUse to see if
; the card’s still in use.
;

       PrintMessage    <INSERT CODE HERE>
       call            SampCSCheckCardInUse
       jmp             done

SampleObjectionResolved endp
~~~

___
+ ``DR_PCMCIA_CLOSE_SOCKET``  
The PCMCIA library calls this function when it is about to close a socket; the
driver should respond by cleaning up any auxiliary structures created during
DR_PCMCIA_CHECK_SOCKET . The PCMCIA library only sends this function
if no one has objected to the removal of the card. The driver, at this point, is
about to be unloaded.

__Pass:__
  - cx -> Socket nuber.
  - di -> DR_PCMCIA_CLOSE_SOCKET

__Returns:__
  - Nothing

__Destroyed:__
  - di

__Include:__
  - pcmciaDr.def

Code Display 3-5 Handling DR_PCMCIA_CLOSE_SOCKET
~~~
SampleCloseSocket      proc    far
       uses    ax, di, ds, bx, cx
       .enter

       ;
       ; Here you’d tell the rest of the world that the thing no longer
       ; exists. At this point, we know the card wasn’t being used, and
       ; things should have been done in SampleHandleRemoval to ensure that
       ; no one could start using the card after that routine returned.
       ;

       PrintMessage <INSERT CODE HERE>
       .leave
       ret

SampleCloseSocket      endp
~~~

___
+ ``DR_PCMCIA_DEVICE_ON``  
The PCMCIA library calls this function in response to a request (by the power
management driver) to turn power on to an indicated socket. This may occur
when someone wishes to turn on a socket and the library believes that power
is off (for example, after a DR_PCMCIA_DEVICE_OFF function or a
CSEC_CARD_INSERTION event). The driver may either call
PCMCIASocketOn or its own custom function in response to this request.  
Only drivers that invoke the Card Services CSF_REQUEST_CONFIGURATION
function will receive this function. (Drivers may also steal configuration
ownership through PCMCIAChangeConfigurationOwner.)

__Pass:__
  - cx -> Socket number.
  - di -> DR_PCMCIA_DEVICE_ON
  
__Returns:__
  - Nothing.

__Destroyed:__
  - di

__Include:__
pcmciaDr.def

___
+ ``DR_PCMCIA_DEVICE_OFF``  
The PCMCIA library calls this function in response to a request to turn power
off to the indicated socket. (The library ensures that a sufficient time elapses
without a subsequent request to turn the power on.) The driver may either
call PCMCIASocketOff or its own custom function in response to this
request.  
Only drivers that invoke the Card Services CSF_REQUEST_CONFIGURATION
function will receive this function. (Drivers may also steal configuration
ownership through PCMCIAChangeConfigurationOwner.)

__Pass:__
  - cx -> Socket number.
  - di -> DR_PCMCIA_DEVICE_OFF
  
__Returns:__
  - Nothing.

__Destroyed:__
  - di

__Include:__
pcmciaDr.def

### 3.2 PCMCIA Library Functions
As noted, a PCMCIA driver will interact with both a PCMCIA library and,
through that library, CardServices. The PCMCIA library provides a number
of routines to aid in communicating with CardServices.
___
+ ``PCMCIARegisterDriver``  
This routine registers a PCMCIA device driver in the indicated socket. This
routine is usually called after the driver is first called with
DR_PCMCIA_CHECK_SOCKET for each supported card.

__Pass:__
  - cx -> The socket number.
  - bx -> The driver’s GeodeHandle.
  - es:di -> CSRegisterClientArgs passed to CardServices.
  - ax:si -> The CardServices callback routine.
  - dx -> The CardServices client handle for the driver.

__Returns:__
  - Nothing.

__Destroyed:__
  - ax

__Include:__
pcmcia.def
  
___
+  ``PCMCIAObjectToRemoval``  
This routine notes a driver’s objection to the removal of a card from the
device. In calling this routine, the driver is dedicated to wait for a
DR_PCMCIA_OBJECTION_RESOLVED function before taking further action
with the card.

__Pass:__
  - cx -> The socket number.
  - dx -> Set (non-zero) if the card is non-removable.
  - bp -> Handle of the driver.

__Returns:__
  - Nothing.

__Destroyed:__
  - ax, di

__Include:__
pcmcia.def

___
+ ``PCMCIAExclusiveGranted``  
This routine should be called to acknowledge that a driver has received a
CSEC_EXCLUSIVE_COMPLETE.

__Pass:__
  - bx -> Handle of the driver geode.

__Returns:__
  - Nothing.

__Destroyed:__
  - Nothing.

__Include:__
pcmcia.def

### 3.3 CardServices Functions
A driver must contact CardServices through use of CardServicesFunction
types defined in pcmcia.def. Consult that file for a complete list of all
possible function calls, as well as pass and return information for those calls.  
The following definitions are for those function types that a driver must use
in registering and deregistering your driver with CardServices. Registration
with CardServices should be accomplished in your driver’s DR_INIT handler.
Deregistration should be performed within your driver’s DR_EXIT handler.  
All CardServicesFunction types return the carry flag set if they encounter
an error and return a CardServicesReturnCode in ax. These return codes
are enumerated below:
~~~
CardServicesReturnCode         etype   word, 0, 1
CSRC_SUCCESS                   enum    CardServicesReturnCode
CSRC_BAD_ADATPER               enum    CardServicesReturnCode
         ; (sic)
CSRC_BAD_ATTRIBUTE             enum    CardServicesReturnCode
CSRC_BAD_BASE                  enum    CardServicesReturnCode
CSRC_BAD_EDC                   enum    CardServicesReturnCode
CSRC_RESERVED_1                enum    CardServicesReturnCode
CSRC_BAD_IRQ                   enum    CardServicesReturnCode
CSRC_BAD_OFFSET                enum    CardServicesReturnCode
CSRC_BAD_PAGE                  enum    CardServicesReturnCode
CSRC_READ_FAILURE              enum    CardServicesReturnCode
CSRC_BAD_SIZE                  enum    CardServicesReturnCode
CSRC_BAD_SOCKET                enum    CardServicesReturnCode
CSRC_RESERVED_2                enum    CardServicesReturnCode
CSRC_BAD_TYPE                  enum    CardServicesReturnCode
CSRC_BAD_VCC                   enum    CardServicesReturnCode
CSRC_BAD_VPP                   enum    CardServicesReturnCode
CSRC_RESERVED_3                enum    CardServicesReturnCode
CSRC_BAD_WINDOW                enum    CardServicesReturnCode
CSRC_WRITE_FAILURE             enum    CardServicesReturnCode
CSRC_RESERVED_4                enum    CardServicesReturnCode
CSRC_NO_CARD                   enum    CardServicesReturnCode
CSRC_UNSUPPORTED_FUNCTION      enum    CardServicesReturnCode
CSRC_UNSUPPORTED_MODE          enum    CardServicesReturnCode
CSRC_BAD_SPEED                 enum    CardServicesReturnCode
CSRC_BUSY                      enum    CardServicesReturnCode
CSRC_GENERAL_FAILURE           enum    CardServicesReturnCode
CSRC_WRITE_PROTECTED           enum    CardServicesReturnCode
CSRC_BAD_ARG_LENGTH            enum    CardServicesReturnCode
CSRC_BAD_ARGS                  enum    CardServicesReturnCode
CSRC_CONFIGURATION_LOCKED      enum    CardServicesReturnCode
CSRC_IN_USE                    enum    CardServicesReturnCode
CSRC_NO_MORE_ITEMS             enum    CardServicesReturnCode
CSRC_OUT_OF_RESOURCE           enum    CardServicesReturnCode
CSRC_BAD_HANDLE                enum    CardServicesReturnCode
~~~
___
+ ``CSF_REGISTER_CLIENT``  
This function instructs CardServices to register the driver. This function
must be passed a structure of CSRegisterClientArgs containing (among
other things) the address of the callback routine with which CardServices
should contact the driver. CardServices will send CardServicesEventCode
types to this callback routine. (For more information on defining your
callback routine see [“CardServices Events”](#34-CardService-Events).)  
This registration should occur when the driver is first loaded, upon receipt of
DR_INIT.
~~~
CSRegisterClientArgs   struct
       CSRCA_attributes        CSRegisterClientArgsAttributes
       CSRCA_eventMask         CSEventMask
       CSRCA_clientData        CSClientData
       CSRCA_version           word
CSRegisterClientArgs   ends

CSRegisterClientArgsAttributes record
       :11
       CSRCAA_ARTIFICIAL_EXCLUSIVE:1   ; want artificial INSERTION events
                                       ; after exclusive access released
       CSRCAA_ARTIFICIAL_SHARED:1      ; want artificial INSERTION events for all
                                       ; cards resident when client registers
       CSRCAA_IO:1                     ; I/O cards
       CSRCAA_MTD:1                    ; Memory Technologie Driver
       CSRCAA_MCD:1                    ; Memory cards
CSRegisterClientArgsAttributes

CSEventMask            record
       :5
       CSEM_SOCKET_SERVICES_UPDATED:1
       CSEM_RESET:1
       CSEM_POWER_MANAGEMENT_CHANGE:1
       CSEM_CARD_DETECT_CHANGE:1
       CSEM_READY_CHANGE:1
       CSEM_BATTERY_LOW:1
       CSEM_BATTERY_DEAD:1
       CSEM_INSERTION_REQUEST:1
       CSEM_EJECTION_REQUEST:1
       CSEM_CARD_LOCK_CHANGE:1
       CSEM_WRITE_PROTECT_CHANGE:1
CSEventMask    end

CSClientData   struct
       CSCD_data       word    ; DI for callback
       CSCD_segment    word    ; DS for callback
       CSCD_offset     word    ; SI for callback
       CSCD_extra      word    ; reserved word that’s not
                               ; loaded into anything...
CSClientData   ends
~~~
__Pass:__
  - al -> CSF_REGISTER_CLIENT
  - cx -> Argument length
  - es:bx -> CSRegisterClientArgs
  - di:si -> Entry point (callback routine) of the driver

__Returns:__
  - CF -> Set if failure
  - ax -> CardServicesReturnCode
  - dx -> Client handle

__Include:__
pcmcia.def

___
+ ``CSF_DEREGISTER_CLIENT``  
This function instructs CardServices to deregister the driver. This function
must be passed the client handle returned when the driver first registered
with CardServices.  
This deregistration should occur when the driver is unloaded, upon receipt of
DR_EXIT.

__Pass:__
  - al -> CSF_DEREGISTER_CLIENT
  - dx -> Client handle.
  - cx -> No arguments.

__Returns:__
  - CF -> Set if failure
  - ax -> CardServicesReturnCode

__Include:__
pcmcia.def

___
+ ``CallCS``  
``CallCS <command, options>``  
This macro issues a call to CardServices. It must be passed a
CardServicesFunction to invoke.  
Due to interrupt timing concerns, if the macro is called from within a
CardServices callback procedure (or from a routine that is called by such a
procedure), DONT_LOCK_BIOS must be passed as an option. At all other
times you must not pass DONT_LOCK_BIOS (unless you call SysLockBIOS
yourself) as CardServices is not re-entrant.

### 3.4 CardServices Events
The interface between CardServices and your driver occurs not only through
use of the PCMCIA library; your driver must also handle events sent by
CardServices as well. This is performed through use of a callback routine.
CardServices will send these events using either a timer interrupt or a
status-change interrupt (such as a physical card insertion or removal).  
When your driver registers with CardServices, it must pass the address of a
callback routine. Your driver should respond to CardServicesEventCode
types sent to this callback routine and return appropriate
CardServicesReturnCode types.  
The CardServicesEventCode functions pass the following arguments to
your callback routine:

  - al -> CardServicesEventCode
  - cx -> Socket number
  - dx -> Info
  - di -> di register for callback routine
  - ds -> ds register for callback routine
  - si -> si register for callback routine
  - ss -> MTD request segment
  - bp -> MTD request offset
  - es -> Buffer segment
  - bx -> Buffer offset or miscellaneous register

As with any CardServices functions, you should return the carry flag set if
you encounter an error and a CardServicesReturnCode in ax.

___
+ ``CSEC_CARD_INSERTION``  
A driver receives this event when CardServices determines that a card has
been inserted in a PCMCIA socket. The driver should respond by configuring
its card in whatever way it sees fit. A driver may also receive this event if
some other client received exclusive access to the card and is now
relinquishing it. This is transparent to the driver receiving this event.  
If a driver receives this event while an unresolved objection to a previous
removal is currently active, it should reconfigure the card to its previous
state before the objection to removal was noted, if possible; it must also wait
to release any blocks (containing the “unresolved” information) until a
DR_PCMCIA_OBJECTION_RESOLVED function is received.

Code Display 3-6 Sample CSEC_CARD_INSERTION Handler
~~~
SampleHandleInsertion  proc    near
       uses    bx, dx
       .enter

       ;
       ; Point to our data record for the socket.
       ;

       call   SampUDerefSocket

       ;
       ; Here’s where you’d examine the card’s CIS to see if it’s something
       ; you support, then attempt to set it to one of its configurations.
       ; If all that succeeds, you’d set ds:[bx].SSI_support to SCS_YES.
       ; If any of that fails, you’d set ds:[bx].SSI_support to SCS_NO.
       ;

       PrintMessage   <INSERT CODE HERE>

setYes:
       mov     ds:[bx].SSI_support, SCS_YES

       ;
       ; See if the card was removed under protest.
       ;

       tst     ds:[bx].SSI_conflict
       jz      clearConflict

       ;
       ; If this card is coming back in after having been removed while
       ; in-use you may need to tell another driver to restore the state of the
       ; card (this is what happens in the CIDSer driver, for example, where the
       ; baud rate and other parameters need to be restored here).
       ;
       ; If you block people’s access to the card while it’s in conflict,
       ; this is the time to wake them all up using code like this:
       ;
       ;       call    SysEnterCritical
       ;       VAllSem ds, [bx].SSI_conflictSem
       ;       mov     ds:[bx].SSI_conflictSem.Sem_value, 0
       ;       call    SysEnterCritical
       ;
       ; The Enter/ExitCritical prevents other threads from running so we can
       ; reliably set the Sem_value to 0 (it ends up at 1) to cause people
       ; to block immediately the next time the card is in conflict.
       ;

       PrintMessage <INSERT CODE HERE>

clearConflict:
       mov     ds:[bx].SSI_conflict, 0

done:
       .leave
       ret

setNo:
       mov     ds:[bx].SSI_support, SCS_NO
       jmp     done

SampleHandleInsertion  endp
~~~

___
+ ``CSEC_CARD_REMOVAL``  
A driver receives this event when Card Services determines that the card has
been removed. If this removal is acceptable, the driver should release all
Card Services-related resources that it had allocated and make sure not to
access the card in the future.  
A client may also receive this event if another client has been granted
exclusive access to the card. When the other driver relinquishes exclusive
access, the previously contacted drivers will receive CSEC_CARD_INSERTION
events.  
If a driver has been granted exclusive access to a card and receives a
CSEC_CARD_REMOVAL event, it should call
PCMCIAExclusiveCardRemoved. If instead, the driver wishes to raise an
objection to this card removal (for example, a serial port was in use or a file
is currently open on the card) it should call the PCMCIAObjectToRemoval
library utility routine. The driver must then wait for the objection to be
resolved (through a DR_PCMCIA_OBJECTION_RESOLVED event). If the
driver receives a fresh CSEC_CARD_INSERTION event, it should reconfigure
the card if it is able. It should not grant access to the card until
DR_PCMCIA_OBJECTION_RESOLVED is received.  

Code Display 3-7 Sample CSEC_CARD_REMOVAL Handler
~~~
SampleHandleRemoval    proc    near
       uses            bx, dx, bp
       .enter

       call            SampUDerefSocket

       ;
       ; If card not supported, we’re happy to see it go (why are we here?)
       ;

       tst     ds:[bx].SSI_support
       jz      resetSupport

       ;
       ; See if the card is being used by GEOS using whatever means are
       ; available/appropriate.
       ;

       PrintMessage <INSERT CODE HERE>
       call    SampCSCheckInUse
       jne     resetSupport

       ;
       ; It is in-use, so mark the port conflicted and tell the PCMCIA library
       ; of our objections.
       ;

       mov     ds:[bx].SSI_conflict, TRUE

       mov     dx, TRUE        ; card may NOT be removed
       mov     bp, handle 0
       call    PCMCIAObjectToRemoval

resetSupport:
       ;
       ; Always set SSI_support back to SCS_NO, as it reflects our opinion of
       ; the current state of the socket.
       ;

       mov     ds:[bx].SSI_support, SCS_NO
       clc
       mov     ax, CSRC_SUCCESS
       .leave
       ret

SampleHandleRemoval endp
~~~
___
+ ``CSEC_EXCLUSIVE_COMPLETE``  
A driver receives this event when CardServices grants a client driver
exclusive access to the PCMCIA socket. The driver should acknowledge that
it has received the event by calling PCMCIAExclusiveGranted.

___
+ ``CSEC_EXCLUSIVE_REQUEST``  
A driver receives this event when CardServices requests, at the behest of
another driver, exclusive access to the card. The driver should react
negatively to this event if it objects to this exclusive access. The criteria for
this objection should be much the same as if it had received a
CSEC_CARD_REMOVAL event.

Code Display 3-8 Sample CSEC_EXCLUSIVE_REQUEST Handler
~~~
SampCSHandleExclusiveRequest   proc    near
       uses    bx, di
       .enter

       call    SampCSCheckCardInUse
       jnc     done

       ;
       ; Card is in use - don’t allow the exclusive access.
       ;

       mov     ax, CSRC_IN_USE
       stc

done:
       .leave
       ret
SampCSHandleExclusiveRequest endp
~~~
___
+ ``CSEC_CLIENT_INFO``  
A driver receives this event when CardServices requests standard client
information.

Code Display 3-9 Sample CSEC_CLIENT_INFO Handler
~~~
;
; Remember that this is not a complete routine.
;

doInfo:
       test    es:[bx].CSGCIA_attributes, mask CSGCIAA_INFO_SUBFUNCTION
       jnz     unsupported ; only handle function 0

       ;
       ; Return info about this client to whomever is asking.
       ;

       mov     cx, cs:[clientInfo].CSGCIA_infoLen
       cmp     cx, es:[bx].CSGCIA_maxLen
       jbe     copyInfo
       mov     cx, es:[bx].CSGCIA_maxLen

copyInfo:
       segmov  ds, cs
       mov     si, offset clientInfo.CSGCIA_infoLen
       lea     di, es:[bx].CSGCIA_infoLen
       sub     cx, offset CSGCIA_infoLen       ; not copying all stuff
                                               ; up to here
       rep     movsb
       jmp     success
~~~

The following is a complete list of CardServicesEventCode routines
defined in pcmcia.def.
~~~
CardServicesEventCode          etype   word
CSEC_PM_BATTERY_DEAD           (001h)
CSEC_PM_BATTERY_LOW            (002h)
CSEC_CARD_LOCK                 (003h)
CSEC_CARD_READY                (004h)
CSEC_CARD_REMOVAL              (005h)
CSEC_CARD_UNLOCK               (006h)
CSEC_EJECTION_COMPLETE         (007h)
CSEC_EJECTION_REQUEST          (008h)
CSEC_INSERTION_COMPLETE        (009h)
CSEC_INSERTION_REQUEST         (00ah)
CSEC_PM_RESUME                 (00bh)
CSEC_PM_SUSPEND                (00ch)
CSEC_EXCLUSIVE_COMPLETE        (00dh)
CSEC_EXCLUSIVE_REQUEST         (00eh)
CSEC_RESET_PHYSICAL            (00fh)
CSEC_RESET_REQUEST             (010h)
CSEC_CARD_RESET                (011h)
CSEC_MTD_REQUEST               (012h)
CSEC_RESERVED_1                (013h)
CSEC_CLIENT_INFO               (014h)
CSEC_TIMER_EXPIRED             (015h)
CSEC_SS_UPDATED                (016h)

CSEC_CARD_INSERTION            (040h)

CSEC_RESET_COMPLETE            (080h)
CSEC_ERASE_COMPLETE            (081h)
CSEC_REGISTRATION_COMPLETE     (082h) 
~~~
Your driver will need to create a table to map these event codes to the
handlers to invoke for each.

Note that the CSEC_CARD_INSERTION , CSEC_RESET_COMPLETE ,
CSEC_ERASE_COMPLETE and CSEC_REGISTRATION_COMPLETE events do
not follow the simple incremental numbering of the previous events. You will
need to check for these events individually, rather than through a simple
jump table.

Your handler should respond with an appropriate CardServicesReturnCode.

For example, the sample PCMCIA driver included on the SDK defines the
following table:

Code Display 3-10 A Sample CardServices Event Table
~~~
      ; It is usually convenient to define such a table within the Callback
      ; routine itself.

DefCSEvent     macro           event, handler
       .assert ($-eventRoutineTable)/2 eq (event-1)
       nptr.near               handler
endm

eventRoutineTable      label   nptr
DefCSEvent     CSEC_PM_BATTERY_DEAD,     doIgnore
DefCSEvent     CSEC_PM_BATTERY_LOW,      doIgnore
DefCSEvent     CSEC_CARD_LOCK,           doIgnore
DefCSEvent     CSEC_CARD_READY,          doIgnore
DefCSEvent     CSEC_CARD_REMOVAL,        doRemoval
DefCSEvent     CSEC_CARD_UNLOCK,         doIgnore
DefCSEvent     CSEC_EJECTION_COMPLETE,   doIgnore
DefCSEvent     CSEC_EJECTION_REQUEST,    doIgnore
DefCSEvent     CSEC_INSERTION_COMPLETE,  doIgnore
DefCSEvent     CSEC_INSERTION_REQUEST,   doIgnore
DefCSEvent     CSEC_PM_RESUME,           doIgnore
DefCSEvent     CSEC_PM_SUSPEND,          doIgnore
DefCSEvent     CSEC_EXCLUSIVE_COMPLETE,  doIgnore
DefCSEvent     CSEC_EXCLUSIVE_REQUEST,   doExclusiveReq
DefCSEvent     CSEC_RESET_PHYSICAL,      doIgnore
DefCSEvent     CSEC_RESET_REQUEST,       doIgnore
DefCSEvent     CSEC_CARD_RESET,          doIgnore
DefCSEvent     CSEC_MTD_REQUEST,         unsupported
DefCSEvent     CSEC_RESERVED_1,          unsupported
DefCSEvent     CSEC_CLIENT_INFO,         doInfo
DefCSEvent     CSEC_TIMER_EXPIRED,       doIgnore
DefCSEvent     CSEC_SS_UPDATED,          doIgnore
endEventRoutineTable           label     nptr
~~~
Code Display 3-11 A Sample PCMCIA CardServices Callback Routine
~~~
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SampCardServicesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:      Callback routine for Card Services events

CALLED BY:     Card Services

PASS:          al      -> function
               cx      -> socket
               dx      -> info
               di      -> 1st word in RegisterClient
               ds      -> dgroup (2nd word in RegisterClient)
               si      -> 3rd word in RegisterClient
               ss:bp   -> MTDRequest
               es:bx   -> buffer
               bx      -> Misc (when no buffer returned)

RETURN:        ax      <- status to return
               carry set on error,
               carry clear on success.

DESTROYED:     nothing

SIDE EFFECTS:
               None

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SampCardServicesCallback       proc    far
       uses    cx, dx
       .enter

       ; We need to check for the events which can’t be included in a linear
       ; sequential jump table

       cmp     al, CSEC_CARD_INSERTION
       je      doInsertion

       cmp     al, CSEC_REGISTRATION_COMPLETE
       jne     handleEvent

       ; We’re registered, so we should note this in our driver’s state variable

       mov     ds:[amRegistered], TRUE
       jmp     success

       ; Now we handle the other events

handleEvent:

       clr     ah
       mov     di, ax
       shl     di
       cmp     di, endEventRoutineTable - eventRoutineTable
       ja      unsupported

       ; We need to subtract 2 from the value of di since the events are
       ; one-based, not zero-based.

       jmp     cs:[eventRoutineTable][di-2]

       ; For each “routine” mentioned in the table, a label should appear
       ; following this jump
       ;
       ; Example:

doExclusiveReq:
       call    SampCSHandleExclusiveRequest
       jmp     done

       ;--------------------
doInsertion:
       call    SampHandleInsertion
       jmp     success

doIgnore:

success:
      mov      ax, CSRC_SUCCESS
      clc

done:
       .leave
       ret

       ;--------------------
       ;
       ; The description of what this client supports, when it was created,
       ; etc.
       ;

clientInfo     CSGetClientInfoArgs <
       0,                              ; CSGCIA_maxLen
       size clientInfo,
       mask CSGCIAA_EXCLUSIVE_CARDS or \
               mask CSGCIAA_SHARABLE_CARDS or \
               mask CSGCIAA_MEMORY_CLIENT_DEVICE_DRIVER,
       <                                       ; CSGCIA_clientInfo
               0100h,                          ; CSCI_revision
               0201h,                          ; CSCI_csLevel
               <
                       29,                     ; CSDI_YEAR
                       9,                      ; CSDI_MONTH
                       22                      ; CSDI_DAY
               >,                              ; CSCI_revDate
               clientInfoName - clientInfo,    ; CSCI_nameOffset
               length clientInfoName,          ; CSCI_nameLength
               vendorString - clientInfo,      ; CSCI_vStringOffset
               length vendorString             ; CSCI_vStringLength
       >
>
org    clientInfo.CSGCIA_clientInfo.CSCI_data  ; go back into the
                                               ; middle of the struct
                                               ; to place these
                                               ; strings in the right
                                               ; place

clientInfoName char    “Sample PCMCIA Driver”, 0
vendorString   char    “Geoworks”, 0

       ; Your event table should appear here...

SampCardServicesCallback       endp
~~~