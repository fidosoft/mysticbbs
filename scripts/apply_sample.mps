// ====================================================================
// Mystic BBS Software               Copyright 1997-2013 By James Coyle
// ====================================================================
//
// This file is part of Mystic BBS.
//
// Mystic BBS is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Mystic BBS is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Mystic BBS.  If not, see <http://www.gnu.org/licenses/>.
//
// ====================================================================

// ==========================================================================
// NEWUSERAPP.MPS : Sample new user process MPL program
//
// If newuserapp.mpx exists in the theme's script directory, it will be ran
// instead of the normal New User process.  You must make sure you scan for
// duplicate user names, and other things like that which the BBS would
// normally do during this process.  At the start of the program, you must
// call GetThisUser to load the new user data into the USER variables.
// Before exiting the program, you must call PutThisUser to store the USER
// variables back into the new user data.
//
// Note: To use this program, you must rename it to newuserapp.mps and
// compile it with MIDE or MPLC.
// ==========================================================================

Uses
  User

Procedure GetAlias;
Var
  Str : String[30];
Begin
  Repeat
    Write ('Enter your alias: ');

    Str := StripLow(StripB(Input(30, 30, 11, ''), ' '));

    If IsUser(Str) Then
      WriteLn ('Account already exists')
    Else
      Break;
  Until False;

  UserAlias := Str;
End;

Procedure GetRealName;
Var
  Str : String[30];
Begin
  Repeat
    Write ('Enter your real name: ');

    Str := StripLow(StripB(Input(30, 30, 11, ''), ' '));

    If Pos(' ', Str) = 0 Then
      WriteLn ('Enter first AND last name')
    Else
    If IsUser(Str) Then
      WriteLn ('Account already exists')
    Else
      Break;
  Until False;

  UserName := Str;
End;

Procedure GetPassword;
Var
  Str1 : String[20];
  Str2 : String[20];
Begin
  Repeat
    Repeat
      Write ('Enter your password: ');

      Str1 := Input(20, 20, 16, '');

      If Length(Str1) < 4 Then
        WriteLn ('Password must be at least 4 chars')
      Else
        Break;
    Until False;

    Write ('Verify your password: ');

    Str2 := Input(20, 20, 16, '');

    If Str1 <> Str2 Then
      WriteLn ('Passwords do not match.')
    Else
      Break;
  Until False;

  UserPassword := Str1;
End;

Begin
  GetThisUser;

  GetAlias;
  GetRealName;
  GetPassword;

  PutThisUser;
End.
