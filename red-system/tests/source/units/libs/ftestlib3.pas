// ftestlib3      Divides a float by two
//
// Purpose:       Testing library calls in Red/System
//
// Author:        Peter W A Wood
//
// Date:          9-Jan-2012
//
// Version:       0.0.1
//
// Rights:        Copyright (C) 2012 Peter W A Wood.
//                All rights reserved.
//
// License:       BSD-3
//                https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt
//
// Notes:         Under Mac Xcode < 4.0 the library must be compiled with the 
//                  following option:
//                  -k-no_order_inits
//                (This is due to a bug in the Xcode 3 linker

library three;

function halve(f: double):double;cdecl;
begin
  halve := f / 2.0;
end;

{$ifndef Darwin}
exports  
  halve name 'halve';
{$else}
exports
  halve name '_halve';
{$endif}

begin
end.