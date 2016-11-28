unit KeyWait;

interface

procedure WaitForKey;

implementation

procedure WaitForKey; external;
{$L KEYWAIT.OBJ}

end.