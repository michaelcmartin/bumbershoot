unit CgaAsm;

{ This binds CGAEXT.OBJ into Pascal, providing an assembly-language
  based implementation of the same interface as CGA.PAS. }

interface

procedure CgaStart;
procedure CgaEnd;
procedure CgaPixel(x, y, c:integer);

implementation

procedure CgaStart; external;
procedure CgaEnd; external;
procedure CgaPixel(x, y, c:integer); external;

{$L CGAEXT.OBJ}

end.
