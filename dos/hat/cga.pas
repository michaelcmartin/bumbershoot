unit Cga;

{ 100% Pascal implementation of a simple CGA driver. }

{ It is not even remotely optimized and is by a large factor the
  slowest of the implementations tested in this project. }

interface

procedure CgaStart; { Enter CGA mode, 320x200x4 }
procedure CgaEnd;   { Return to text mode }
procedure CgaPixel(x, y, c:integer); { Turn pixel (x, y) color c }

implementation

uses Dos;

procedure CgaStart;
var regs: Registers;
begin
    regs.ax := $0004;
    Intr($10, regs)
end;

procedure CgaEnd;
var regs: Registers;
begin
    regs.ax := $0003;
    Intr($10, regs)
end;

procedure CgaPixel(x, y, c:integer);
var evens:array[0..3999] of byte absolute $B800:$0000;
    odds:array[0..3999] of byte absolute $B800:$2000;
    offset:integer;
    mask:byte;
begin
    if (x >= 0) and (x < 320) and (y >= 0) and (y < 200) then begin
        offset := 80 * (y div 2) + (x div 4);
        mask := not (3 shl (2 * (3 - (x mod 4))));
        c := (c and 3) shl (2 * (3 - (x mod 4)));
        if (y mod 2) = 1 then
            odds[offset] := (odds[offset] and mask) or c
        else
            evens[offset] := (evens[offset] and mask) or c
    end
end;

begin
end.
