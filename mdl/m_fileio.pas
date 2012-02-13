{
  Mystic Software Development Library
  ===========================================================================
  File    | M_FILEIO.PAS
  Desc    | File IO related functions
  Created | August 22, 2002
  ---------------------------------------------------------------------------
}

{$I M_OPS.PAS}

Unit m_FileIO;

Interface

{ FILE ACCESS FUNCTIONS }

Function ioReset      (Var F: File; RecSize: Word; Mode: Byte) : Boolean;
Function ioReWrite    (Var F: File; RecSize: Word; Mode: Byte) : Boolean;
Function ioSeek       (Var F: File; FPos: LongInt) : Boolean;
Function ioRead       (Var F: File; Var Rec) : Boolean;
Function ioWrite      (Var F: File; Var Rec) : Boolean;
Function ioBlockRead  (Var F: File; Var Rec; dSize: LongInt; Var Res: LongInt) : Boolean;
Function ioBlockWrite (Var F: File; Var Rec; dSize: LongInt; Var Res: LongInt) : Boolean;

{ FILE MANIPULATION FUNCTIONS }

Function  FileExist       (Str: String) : Boolean;
Function  FileErase       (Str: String) : Boolean;
Function  FileDirExists   (Str: String) : Boolean;
Function  JustFileName    (Str: String) : String;
Function  JustFile        (Str: String) : String;
Function  JustFileExt     (Str: String) : String;
Function  JustPath        (Str: String) : String;
Function  DirSlash        (Str: String) : String;

{ GLOBAL FILEIO VARIABLES AND CONSTANTS }

Var
  ioCode : LongInt;

Const
  fmReadOnly  = 0;
  fmWriteOnly = 1;
  fmReadWrite = 2;
  fmDenyAll   = 16;
  fmDenyWrite = 32;
  fmDenyRead  = 48;
  fmDenyNone  = 64;
  fmNoInherit = 128;
  fmRWDN      = 66;
  fmRWDR      = 50;
  fmRWDW      = 34;

{ BUFFERED FILE IO CLASS DEFINITION }

Const
  TMaxBufferSize = 64 * 1024 - 1;   // Maximum of 64KB buffer for IO class

Type
  TBufFileOpenType = (
    fmOpen,
    fmOpenCreate,
    fmCreate
  );

  PBufFileBuffer = ^TBufFileBuffer;
  TBufFileBuffer = Array[0..TMaxBufferSize] of Byte;

  TBufFile = Class
  Private
    BufFile    : File;
    Buffer     : PBufFileBuffer;
    Opened     : Boolean;
    BufDirty   : Boolean;
    BufFilePos : Longint;
    RecordSize : LongInt;
    BufSize    : LongInt;
    BufPos     : LongInt;
    BufTop     : LongInt;

    Procedure   FillBuffer;
    Procedure   FlushBuffer;
  Public
    IOResult : Integer;

    Constructor Create (BS: Word);
    Destructor  Destroy; Override;
    Function    Open (FN: String; OM: TBufFileOpenType; FM: Byte; RS: Word) : Boolean;
    Procedure   Close;
    Procedure   Reset;
    Function    EOF : Boolean;
    Function    FilePos : LongInt;
    Function    FileSize : LongInt;
    Procedure   Seek (Pos : LongInt);
    Procedure   Read (Var V);
    Procedure   Write (Var V);
    Procedure   BlockRead (Var V; Count: LongInt; Var Result: LongInt);
    Procedure   BlockWrite (Var V; Count: LongInt; Var Result: LongInt);
    Procedure   RecordInsert (RecNum: LongInt);
    Procedure   RecordDelete (RecNum: LongInt);
  End;

Implementation

Uses
  DOS,
  m_Types,
  m_DateTime;

Const
  ioRetries    = 20;
  ioWaitTime   = 100;

Function ioReset (Var F: File; RecSize: Word; Mode: Byte) : Boolean;
Var
  Count : Word;
Begin
  FileMode := Mode;
  Count    := 0;
  ioCode   := 5;

  While (Count < ioRetries) and (ioCode = 5) Do Begin
    Reset (F, RecSize);
    ioCode := IoResult;
    Inc (Count);
    If ioCode = 5 Then WaitMS(ioWaitTime);
  End;

  ioReset := (ioCode = 0);
End;

Function ioReWrite (Var F: File; RecSize: Word; Mode: Byte) : Boolean;
Var
  Count : Word;
Begin
  FileMode := Mode;
  Count    := 0;
  ioCode   := 5;

  While (Count < ioRetries) and (ioCode = 5) Do Begin
    ReWrite (F, RecSize);
    ioCode := IoResult;
    Inc (Count);
    If ioCode = 5 Then WaitMS(ioWaitTime);
  End;

  ioReWrite := (ioCode = 0);
End;

Function ioSeek (Var F: File; FPos: LongInt) : Boolean;
Var
  Count : Word;
Begin
  Count  := 0;
  ioCode := 5;

  While (Count < ioRetries) and (ioCode = 5) Do Begin
    Seek (F, FPos);
    ioCode := IoResult;
    Inc (Count);
    If ioCode = 5 Then WaitMS(ioWaitTime);
  End;

  ioSeek := (ioCode = 0);
End;

Function ioBlockRead (Var F: File; Var Rec; dSize: LongInt; Var Res: LongInt) : Boolean;
Var
  Count : Word;
Begin
  Count  := 0;
  ioCode := 5;

  While (Count < ioRetries) and (ioCode = 5) Do Begin
    BlockRead (F, Rec, dSize, Res);
    ioCode := IoResult;
    Inc (Count);
    If ioCode = 5 Then WaitMS(ioWaitTime);
  End;

  ioBlockRead := (ioCode = 0);
End;

Function ioBlockWrite (Var F: File; Var Rec; dSize: LongInt; Var Res: LongInt) : Boolean;
Var
  Count : Word;
Begin
  Count  := 0;
  ioCode := 5;

  While (Count < ioRetries) and (ioCode = 5) Do Begin
    BlockWrite (F, Rec, dSize, Res);
    ioCode := IoResult;
    Inc (Count);
    If ioCode = 5 Then WaitMS(ioWaitTime);
  End;

  ioBlockWrite := (ioCode = 0);
End;

Function ioRead (Var F: File; Var Rec) : Boolean;
Var
  Count : Word;
Begin
  Count  := 0;
  ioCode := 5;

  While (Count < ioRetries) and (ioCode = 5) Do Begin
    BlockRead (F, Rec, 1);
    ioCode := IoResult;
    Inc (Count);
    If ioCode = 5 Then WaitMS(ioWaitTime);
  End;

  ioRead := (ioCode = 0);
End;

Function ioWrite (Var F: File; Var Rec) : Boolean;
Var
  Count : Word;
Begin
  Count  := 0;
  ioCode := 5;

  While (Count < ioRetries) and (ioCode = 5) Do Begin
    BlockWrite (F, Rec, 1);
    ioCode := IoResult;
    Inc (Count);
    If ioCode = 5 Then WaitMS(ioWaitTime);
  End;

  ioWrite := (ioCode = 0);
End;

Function DirSlash (Str: String) : String;
Begin
  If Copy(Str, Length(Str), 1) <> PathSep Then
    Str := Str + PathSep;

  Result := Str;
End;

Function JustPath (Str: String) : String;
Var
  Count : Byte;
Begin
  For Count := Ord(Str[0]) DownTo 1 Do
    If (Str[Count] = '/') or (Str[Count] = '\') Then Begin
      Delete (Str, Count + 1, 255);
      Break;
    End;

  Result := Str;
End;

Function JustFile (Str: String) : String;
Var
  Count : Byte;
Begin
  For Count := Ord(Str[0]) DownTo 1 Do
    If (Str[Count] = '/') or (Str[Count] = '\') Then Begin
      Delete (Str, 1, Count);
      Break;
    End;

  Result := Str;
End;

Function JustFileName (Str: String) : String;
Var
  Temp : Byte;
Begin
  Temp := Pos ('.', Str);

  If Temp > 0 Then
    Delete (Str, Temp, Ord(Str[0]));

  Result := Str;
End;

Function JustFileExt (Str: String) : String;
Var
  Temp : Byte;
Begin
  Result := '';

  For Temp := Length(Str) DownTo 1 Do
    If Str[Temp] = '.' Then Begin
      Result := Copy(Str, Temp + 1, Length(Str));
      Exit;
    End;
End;

Function FileErase (Str: String) : Boolean;
Var
  F : File;
Begin
  Assign   (F, Str);
  SetFAttr (F, Archive);
  Erase    (F);

  Result := (IoResult = 0);
End;

Function FileExist (Str: String) : Boolean;
Var
  DF   : File;
  Attr : Word;
Begin
  Assign   (DF, Str);
  GetFattr (DF, Attr);

  Result := (DosError = 0) and (Attr And Directory = 0);
End;

Function FileDirExists (Str: String) : Boolean;
Var
  F    : File;
  Attr : Word;
Begin
  Result := False;

  If Str = '' Then Exit;

  While Str[Length(Str)] = PathSep Do Dec(Str[0]);
  Str := Str + PathSep + '.';

  Assign   (F, Str);
  GetFAttr (F, Attr);

  Result := ((Attr And Directory) = Directory);
End;

{ BEGIN BUFFERED FILE IO CLASS HERE ======================================= }

Constructor TBufFile.Create (BS: Word);
Begin
  Inherited Create;

  Opened     := False;
  BufDirty   := False;
  BufFilePos := 0;
  RecordSize := 0;
  BufSize    := BS;
  BufPos     := 0;
  BufTop     := 0;

  If BufSize > TMaxBufferSize + 1 Then Fail;

  GetMem (Buffer, BufSize);

  If Buffer = Nil Then Fail;
End;

Destructor TBufFile.Destroy;
Begin
  If Opened Then Close;

  If Buffer <> Nil Then FreeMem (Buffer, BufSize);

  Inherited Destroy;
End;

Function TBufFile.Open (FN: String; OM: TBufFileOpenType; FM: Byte; RS: Word) : Boolean;
Begin
  If Opened Then Close;

  Result     := False;
  RecordSize := RS;
  BufFilePos := 0;
  BufPos     := 0;
  BufTop     := 0;

  System.Assign (BufFile, FN);

  If System.IoResult <> 0 Then Exit;

  System.FileMode := FM;

  Case OM of
    fmOpen      : Begin
                    System.Reset(BufFile, 1);
                    If System.IoResult <> 0 Then Exit;
                    FillBuffer;
                  End;
    fmOpenCreate: Begin
                    System.Reset(BufFile, 1);
                    If System.IoResult <> 0 Then Begin
                      System.ReWrite(BufFile, 1);
                      If System.IoResult <> 0 Then Exit;
                    End Else
                      FillBuffer;
                  End;
    fmCreate    : Begin
                    System.ReWrite(BufFile, 1);
                    If IoResult <> 0 Then Exit;
                  End;
  End;

  Result := True;
  Opened := True;
End;

Procedure TBufFile.Close;
Begin
  If BufDirty Then FlushBuffer;

  System.Close(BufFile);

  IOResult := System.IoResult;
  Opened   := False;
End;

Function TBufFile.EOF : Boolean;
Begin
  Result := FilePos >= FileSize;
End;

Function TBufFile.FileSize : Longint;
Begin
  Result := System.FileSize(BufFile) DIV RecordSize;
End;

Function TBufFile.FilePos : Longint;
Begin
  Result := (BufFilePos + BufPos) DIV RecordSize;
End;

Procedure TBufFile.Reset;
Begin
  If BufDirty Then FlushBuffer;

  System.Seek(BufFile, 0);

  BufFilePos := 0;
  BufPos     := 0;

  FillBuffer;
End;

Procedure TBufFile.Seek (Pos: Longint);
Begin
  Pos := Pos * RecordSize;

  If (Pos >= BufFilePos + BufSize) or (Pos < BufFilePos) Then Begin
    If BufDirty Then FlushBuffer;

    System.Seek(BufFile, Pos);

    BufFilePos := Pos;
    BufPos     := 0;

    FillBuffer;
  End Else
    BufPos := Pos - BufFilePos;

  IoResult := System.IoResult;
End;

Procedure TBufFile.Read (Var V);
Var
  Offset : Word;
Begin
  If BufPos + RecordSize > BufTop Then Begin
    Offset := BufSize - BufPos;

    Move(Buffer^[BufPos], V, Offset);

    Inc(BufFilePos, BufSize);

    BufPos:= 0;

    FillBuffer;

    Move(Buffer^[BufPos], TBufFileBuffer(V)[Offset], RecordSize - Offset);

    BufPos:= BufPos + RecordSize - Offset;
  End Else Begin
    Move(Buffer^[BufPos], V, RecordSize);
    Inc(BufPos, RecordSize);
  End;

  IoResult := System.IoResult;
End;

Procedure TBufFile.BlockRead (Var V; Count: LongInt; Var Result: LongInt);
Begin
  Result := 0;

  While (Result < Count) and (IoResult = 0) And Not EOF Do Begin
    Read (TBufFileBuffer(V)[Result * RecordSize]);
    Inc  (Result);
  End;
End;

Procedure TBufFile.Write (Var V);
Var
  Offset : Word;
Begin
  BufDirty := True;

  If BufPos + RecordSize > BufSize Then Begin
    Offset := BufSize - BufPos;

    If Offset > 0 Then
      Move(V, Buffer^[BufPos], Offset);

    BufTop := BufSize;

    FlushBuffer;

    Inc(BufFilePos, BufSize);

    BufPos:= 0;

    FillBuffer;

    Move (TBufFileBuffer(V)[Offset], Buffer^[BufPos], RecordSize - Offset);

    BufPos := BufPos + RecordSize - Offset;
  End Else Begin
    Move (V, Buffer^[BufPos], RecordSize);
    Inc  (BufPos, RecordSize);
  End;

  If BufTop < BufPos Then BufTop := BufPos;

  IoResult := System.IoResult;
End;

Procedure TBufFile.BlockWrite (Var V; Count: LongInt; Var Result: LongInt);
Begin
  Result := 0;

  While (Result < Count) And (IoResult = 0) Do Begin
    Write (TBufFileBuffer(V)[Result * RecordSize]);
    Inc   (Result);
  End;
End;

Procedure TBufFile.FillBuffer;
Begin
  System.Seek (BufFile, BufFilePos);
  System.BlockRead (BufFile, Buffer^, BufSize, BufTop);

  IoResult := System.IoResult;

  If IoResult = 0 Then BufDirty := False;
End;

Procedure TBufFile.FlushBuffer;
Begin
  System.Seek (BufFile, BufFilePos);
  System.BlockWrite (BufFile, Buffer^, BufTop, BufTop);
  IoResult := System.IoResult;

//  BufPos   := 0;
End;

Procedure TBufFile.RecordInsert (RecNum: LongInt);
Var
  TempBuf : PBufFileBuffer;
  Count   : LongInt;
Begin
  If (RecNum < 1) or (RecNum > FileSize + 1) Then Exit;

  GetMem (TempBuf, RecordSize);
  Dec    (RecNum);

  Reset;

  For Count := FileSize - 1 DownTo RecNum Do Begin
    System.Seek       (BufFile, Count * RecordSize);
    System.BlockRead  (BufFile, TempBuf^, RecordSize);
    System.BlockWrite (BufFile, TempBuf^, RecordSize);
  End;

  Seek (RecNum);

  FreeMem (TempBuf, RecordSize);
End;

Procedure TBufFile.RecordDelete (RecNum: LongInt);
Var
  TempBuf : PBufFileBuffer;
  Count   : LongInt;
Begin
  If (RecNum < 1) or (RecNum > FileSize) Then Exit;

  GetMem (TempBuf, RecordSize);
  Dec    (RecNum);

  Reset;

  For Count := RecNum To FileSize - 2 Do Begin
    System.Seek       (BufFile, Succ(Count) * RecordSize);
    System.BlockRead  (BufFile, TempBuf^, RecordSize);
    System.Seek       (BufFile, Count * RecordSize);
    System.BlockWrite (BufFile, TempBuf^, RecordSize);
  End;

  System.Seek     (BufFile, Pred(FileSize) * RecordSize);
  System.Truncate (BufFile);

  Seek (RecNum);

  FreeMem (TempBuf, RecordSize);
End;

End.