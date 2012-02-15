// ftestlib1       Adds or subtracts one to/from an integer
//
// Purpose:       Testing library calls with float args in Red/System
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

library one;

function addone(f: double):double;cdecl;
begin
  addone := f + 1.0;
end;

function subtractone(f: double):double;cdecl;
begin
  subtractone := f - 1.0;
end;

{$ifndef Darwin}
exports  
  addone name 'addone',
  subtractone name 'subtractone';
{$else}
exports
  addone name '_addone',
  subtractone name '_subtractone';
{$endif}

begin
end.