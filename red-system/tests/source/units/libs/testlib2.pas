// testlib2       Multiplies an integer by two
//
// Purpose:       Testing library calls in Red/System
//
// Author:        Peter W A Wood
//
// Date:          10-Aug-2011
//
// Version:       0.0.1
//
// Rights:        Copyright (C) 2011 Peter W A Wood.
//                All rights reserved.
//
// License:       BSD-3
//                https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt
//
// Notes:         Under Mac Xcode < 4.0 the library must be compiled with the 
//                  following option:
//                  -k-no_order_inits
//                (This is due to a bug in the Xcode 3 linker

library two;

function twice(i: integer):integer;cdecl;
begin
  twice := i * 2;
end;

{$ifndef Darwin}
exports  
  twice name 'twice';
{$else}
exports
  twice name '_twice';
{$endif}

begin
end.