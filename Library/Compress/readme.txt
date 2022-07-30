This implementation will replace the origial libraries as
used up to PC/GEOS 4.x but where not free license and not 
available as source code.

The new implementation will be based on an reimplementation of 
the DCL that is available as source code from here:

https://github.com/ladislav-zezula/StormLib/src/pklib

There is an alternative implementation available for the
exploder that seems more compact, but overall this is 
harder to integrate and we decided to us the source from 
StormLib repo.

The alternative implementation lives here:

https://github.com/madler/zlib/tree/master/contrib/blast

Original CRC32 lib part will be removed because it was not 
used or exported from the compress library.
