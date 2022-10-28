## 2 Mouse Driver

Most GEOS platforms will use some kind of pointing device. On desktop
machines, this is most commonly a mouse; in any event, these pointing
devices share many similarities with mice. Accordingly, all these devices are
driven by drivers known collectively as mouse drivers.

### 2.1 Mouse Driver Basics
Most mouse drivers behave in very similar ways. For this reason, most GEOS
mouse drivers share a lot of code. This code is provided in the SDK in the files
\OMNIGO\DRIVER\DDK\MOUSE\MOUSECOM.ASM and
...\MOUSE\MOUSESER.ASM . That directory also contains several GEOS
mouse drivers; these demonstrate how the drivers actually use the common
code to perform such tasks as send mouse movements to the system, handle
strategy-routine requests, etc.

#### 2.1.1 Data Structures
All mouse drivers must be extended drivers, even if they support only one
kind of mouse. A mouse driver’s dgroup segment must begin with the
MouseDriverInfoStruct structure. This structure is based on the
DriverExtendedInfoStruct structure, but has some extra fields:
~~~
MouseDriverInfoStruct  struct
    MDIS_common        DriverExtendedInfoStruct
        <<0, mask DA_HAS_EXTENDED_INFO,
             DRIVER_TYPE_INPUT>,
        0>
    MDIS_numButtons    word                    ?
    MDIS_xRes          word                    ?
    MDIS_yRes          word                    ?
    MDIS_flags         MouseDriverInfoFlags    0
MouseDriverInfoStruct  ends
~~~

*MDIS _numButtons*  
This is the number of buttons the supported mouse has.

*MDIS _xRes, MDIS _yRes*  
This is the number of points per inch, of the points collected by
the pointing device. Mouse drivers generally have these set to
zero; the fields are used for other input devices that use mouse
drivers, such as pen-screens.

*MDIS _flags*  
A record of MouseDriverInfoFlags. These flags store
miscellaneous information about the mouse.

Each MouseDriverInfoStruct stores a word of MouseDriverInfoFlags.
This record has only a single flag:

``MDIF_KEYBOARD_ONLY``  
This driver is actually a keyboard-driven mouse driver, i.e. the
user doesn’t have a real mouse.

Every mouse driver must set up an extended information resource, as
described above in "Driver Basics," Chapter 1. This resource must contain a
DriverExtendedInfoTable, which (among other things) contains a pointer
to an array of data words, one word for each supported mouse. These data
words must contain a MouseExtendedInfo record. This record has the
following flags:

``MEI_SERIAL``  
Set if the device is a serial mouse, and needs a COM port to operate.

``MEI_GENERIC``  
Set if this is a generic mouse and needs a DOS -level driver.

``MEI_IRQ``  
This field is four bits wide. If it is set, the mouse needs to be told
at what interrupt level it is operating (i.e. it is a “bus” mouse).
This field should contain the factory-set default value.

``MEI_CALIBRATE``  
Set if this mouse can be calibrated within GEOS.

#### 2.1.2 Functions

Mouse drivers must be able to handle all four functions defined by
DriverFunction, and both functions defined by
DriverExtendedFunction. Furthermore, they must be able to handle the
functions defined by MouseFunction, a special enumerated type defined in
mousedr.def.

As usual, the first of these function names is an enumerated equal to 12 (or
two past the last DriverExtendedFunction), and the constants increase by
two thereafter.
___
+ ``DR_MOUSE_SET_RATE``  
The mouse should set the number of times it reports per second.

__Pass:__
  - cx -> The report rate the mouse should be set to, in number of
reports per second.

__Returns:__
  - cx -> The actual new report rate for the mouse, again in number of
reports per second.

__Destroyed:__  
  - Allowed to destroy di and ax.

__Include:__  
mousedr.def

___
+ ``DR_MOUSE_SET_ACCELERATION``  
The mouse should set its acceleration rate.

__Pass:__
  - Nothing.

__Returns:__
  - cx -> The threshold for acceleration (i.e. if the mouse moves this
many pixels in 1/30 second, acceleration should start).
  - dx -> Acceleration multiplier once threshold is met.

__Destroyed:__  
  - Nothing.

__Include:__  
mousedr.def

___
+ ``DR_MOUSE_GET_ACCELERATION``  
The mouse should return its current acceleration rate.


__Pass:__
  - Nothing.

__Returns:__
  - cx -> The threshold for acceleration (i.e. if the mouse moves this
many pixels in 1/30 second, acceleration should start).
  - dx -> Acceleration multiplier once threshold is met.

__Destroyed:__  
  - Nothing.

__Include:__  
mousedr.def

___
+ ``DR_MOUSE_COMBINE_MODE``  
The mouse should set the mode for combining mouse events. This is a
member of the (byte-sized) MouseCombineMode enumerated type:  
``MCM_ COMBINE``   
``MCM_NO_COMBINE``  
``MCM_COMBINE_COLINEAR_ONLY``

__Pass:__
  - cl --> MouseCombineMode to use.

__Returns:__  
  - Nothing.

__Destroyed:__  
  - Nothing.

__Include:__  
mousedr.def

___
+ ``DR_MOUSE_GET_COMBINE_MODE``  
The mouse should return the mode it uses for combining mouse events. This
is a member of the (byte-sized) MouseCombineMode enumerated type,
described above in DR_MOUSE_COMBINE_MODE.

__Pass:__  
Nothing.

__Returns:__
  - cl -> Current MouseCombineMode.

__Destroyed:__
Nothing.

___
+ ``DR_MOUSE_GET_CALIBRATION_POINTS``  
This instructs the mouse driver to return its current set of calibration points.


__Pass:__
  - dx:si -> Buffer to which to write calibration points. This buffer will be
long enough to hold nine i.e. ``MAX_NUM_CALIBRATION_POINTS``) calibration points.


__Returns:__
  - dx:si -> Pointer to same buffer, filled with calibration points
  - cx -> Number of calibration points

__Destroyed:__  
  - Nothing

___
+ ``DR_MOUSE_SET_CALIBRATION_POINTS``  
This instructs the mouse driver to set its calibration points.

__Pass:__
  - dx:si -> Buffer filled with adjusted calibration points.
  - cx -> Number of calibration points.

__Returns:__  
  - Nothing.

__Destroyed:__  
  - Nothing.

___
+ ``DR_MOUSE_GET_RAW_COORDINATE``  
This instructs the mouse driver to return the current calibrated and
non-calibrated mouse positions.

__Pass:__  
  - Nothing.

__Returns:__
  - CF -> Clear if point returned, set otherwise.
  - (ax,bx) -> Current raw (uncalibrated) mouse position, if CF = 0.
  - (cx,dx) -> Current adjusted (calibrated) mouse position, if CF = 0.

__Destroyed:__  
  - Nothing.
