// testlib3       Passes an integer from Red/System to a lib and back to itself
//                  via a callback  
//
// Purpose:       Testing library calls in Red/System
//
// Author:        Peter W A Wood
//
// Date:          3-Feb-2011
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

library four;
{$mode objfpc}
uses Classes;

type
  TCallBack = function(i: integer): integer;cdecl;
  
function passitback(i: integer; f: TCallBack):integer;cdecl;
begin
  passitback := f(i);
end;

{$ifndef Darwin}
exports  
  passitback name 'passitback';
{$else}
exports
  passitback name '_passitback';
{$endif}

begin
end.