// testlib1       Adds or subtracts one to/from an integer
//
// Purpose:       Testing library calls in Red/System
//
// Author:        Peter W A Wood
//
// Date:          27-Jun-2011
//
// Version:       See {$define} below
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

{$macro on}
{$define CurrentVersion:='1.0.2'}

library one;

uses sysutils;

function addone(i: integer):integer;cdecl;
begin
  addone := i + 1;
end;

function subtractone(i: integer):integer;cdecl;
begin
  subtractone := i - 1;
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