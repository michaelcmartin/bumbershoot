unit CgaAsm;

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
