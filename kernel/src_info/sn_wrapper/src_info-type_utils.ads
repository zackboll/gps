-----------------------------------------------------------------------
--                              G P S                                --
--                                                                   --
--                     Copyright (C) 2001-2002                       --
--                            ACT-Europe                             --
--                                                                   --
-- GPS is free  software;  you can redistribute it and/or modify  it --
-- under the terms of the GNU General Public License as published by --
-- the Free Software Foundation; either version 2 of the License, or --
-- (at your option) any later version.                               --
--                                                                   --
-- This program is  distributed in the hope that it will be  useful, --
-- but  WITHOUT ANY WARRANTY;  without even the  implied warranty of --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU --
-- General Public License for more details. You should have received --
-- a copy of the GNU General Public License along with this library; --
-- if not,  write to the  Free Software Foundation, Inc.,  59 Temple --
-- Place - Suite 330, Boston, MA 02111-1307, USA.                    --
-----------------------------------------------------------------------

with DB_API; use DB_API;
with HTables;

with SN; use SN;
with GNAT.OS_Lib;
with SN.DB_Structures; use SN.DB_Structures;
with VFS;

package Src_Info.Type_Utils is

   type Module_Typedefs_List is private;
   --  Instances of this type are responsible to store hashed
   --  information about types in one module (file).

   procedure Init (Module_Typedefs : out Module_Typedefs_List);
   --  Initialzes list.

   procedure Free (Module_Typedefs : in out Module_Typedefs_List);
   --  Deallocates internal structures needed for resolving original
   --  type for the chain of typedefs. Must be called after processing
   --  of each file.

   type CType_Description is record
      Kind              : E_Kind;
      Is_Volatile       : Boolean := False;
      Is_Const          : Boolean := False;
      Is_Template       : Boolean := False;
      Parent_Point      : Point   := Invalid_Point;
      Parent_Filename   : VFS.Virtual_File := VFS.No_File;
      Ancestor_Point    : Point   := Invalid_Point;
      Ancestor_Filename : VFS.Virtual_File := VFS.No_File;
      Builtin_Name      : GNAT.OS_Lib.String_Access;
      Is_Typedef        : Boolean := False;
   end record;
   --  Contains C type description. Used in these procedures:
   --    Type_Name_To_Kind
   --    Original_Type
   --    Find_Class
   --
   --  Parent_xxx: the same as Ancestor_xxx (see below) but used for
   --  all other entities except typedefs. For builtin types Parent_Point is
   --  undefined (Invalid_Point).
   --
   --  Ancestor_xxx: location of the closest typedef in the chain of
   --  typedefs. Used only for typedefs. For builtin types Ancestor_Point is
   --  Predefined_Point
   --
   --  Builtin_Name is set for builtin type occurences. Also it is used
   --  (compared with null) in resolving typedef parent type (see
   --  Sym_T_Handler).
   --
   --  Is_Typedef is True if type is declared via typedef clause, False
   --  otherwise.

   type SN_Table_Array is array (Table_Type) of DB_File;

   procedure Builtin_Type_To_Kind
     (Type_Name : in String;
      Desc      : out CType_Description;
      Success   : out Boolean);
   --  Attempts to convert string into E_Kind assuming that the string
   --  is a builtin C type. If conversion fails returns False

   Invalid_FU_Table    : constant FU_Table := (
      Class               => Invalid_Segment,
      Name                => Invalid_Segment,
      File_Name           => Invalid_Segment,
      Start_Position      => Invalid_Point,
      End_Position        => Invalid_Point,
      Attributes          => 0,
      Return_Type         => Invalid_Segment,
      Arg_Types           => Invalid_Segment,
      Comments            => Invalid_Segment,
      Template_Parameters => Invalid_Segment,
      Buffer              => null,
      DBI                 => 0
   );

   Invalid_CL_Table    : constant CL_Table := (
      Name                => Invalid_Segment,
      File_Name           => Invalid_Segment,
      Start_Position      => Invalid_Point,
      End_Position        => Invalid_Point,
      Attributes          => 0,
      Template_Parameters => Invalid_Segment,
      Buffer              => null,
      DBI                 => 0
   );

   procedure Type_Name_To_Kind
     (Type_Name         : in String;
      SN_Table          : in SN_Table_Array;
      Module_Typedefs   : in Module_Typedefs_List;
      Desc              : out CType_Description;
      Success           : out Boolean;
      Symbol            : Symbol_Type := Undef;
      FU_Tab            : FU_Table := Invalid_FU_Table;
      CL_Tab            : CL_Table := Invalid_CL_Table);
   --  Attempts to convert type name into E_Kind.
   --  At the moment searches for
   --  the name in the class, typedef, enum tables
   --  and template arguments

   procedure Find_Original_Type
     (Type_Name         : in String;
      SN_Table          : in SN_Table_Array;
      Module_Typedefs   : in Module_Typedefs_List;
      Desc              : out CType_Description;
      Success           : out Boolean);
   --  Gets E_Kind of original type for specified typedef type.
   --  Sets Success to True if type found and fills Desc structure
   --  with appropriate information.
   --  Also supports Unresolved_Entity for such situations:
   --    typedef old_type new_type;
   --  where old_type is unresolved type.

   procedure Find_Class
     (Type_Name : in String;
      SN_Table  : in SN_Table_Array;
      Desc      : in out CType_Description;
      Class_Def : out CL_Table;
      Success   : out Boolean);
   --  Finds class and stores information about it in the
   --  Desc and Class_Def arguments
   --  Success returns error status

   procedure Find_Union
     (Type_Name : in String;
      SN_Table  : in SN_Table_Array;
      Desc      : in out CType_Description;
      Union_Def : out UN_Table;
      Success   : out Boolean);
   --  Finds union and stores information about it in the
   --  Desc and Union_Def arguments
   --  Success returns error status

   procedure Find_Enum
     (Type_Name : in String;
      SN_Table  : in SN_Table_Array;
      Desc      : in out CType_Description;
      Enum_Def  : out E_Table;
      Success   : out Boolean);
   --  Finds enum and stores information about it in the
   --  Desc and Enum_Def arguments
   --  Success returns error status

   procedure Find_Template_Argument
     (Type_Name       : String;
      SN_Table        : SN_Table_Array;
      Desc            : in out CType_Description;
      Symbol          : Symbol_Type;
      Scope           : String;
      File_Name       : String;
      Template_Args   : String;
      Class_Name      : String;
      Success         : out Boolean);
   --  Find template type argument and stores information about it
   --  in Desc. Success holds error status
   --  When symbol is MI or MD, Class_Name should contain method's class
   --  name. Otherwise it should be an empty string

   procedure Free (Desc : in out CType_Description);
   --  Frees memory used by access fields in given Desc structure.

   function Cmp_Arg_Types
     (Buffer_A, Buffer_B     : GNAT.OS_Lib.String_Access;
      Args_A, Args_B         : Segment;
      Strict                 : Boolean := False)
      return Boolean;
   --  Checks to see if argument types are the same.
   --  Strict controls how arguments with ellipsis are compared:
   --  If Strict is True then this function returns True if Args_A and Args_B
   --    have equal number of elements and for every position in Args_A
   --    argument type name is literally equal to argument type name in Args_B
   --    in the same position, and False otherwise.
   --  If Strict is False then ellipsis ('...') matches any number of arguments
   --  with arbitrary types starting from position of ellipsis.

   function Cmp_Prototypes
     (Buffer_A, Buffer_B     : GNAT.OS_Lib.String_Access;
      Args_A, Args_B         : Segment;
      Ret_Type_A, Ret_Type_B : Segment;
      Strict                 : Boolean := False)
      return Boolean;
   --  Checks to see if function prototypes are the same.
   --  Strict controls how arguments with ellipsis are compared
   --  (see Cmp_Arg_Types).

   function Is_Template (The_Class : CL_Table) return Boolean;
   --  Returns True if specified class is class template, False otherwise.

   function Is_Template (Func : FU_Table) return Boolean;
   --  Returns True if specified function has template attribute set,
   --  False otherwise.

   function Plain_Class_Name (Type_Name : String) return String;
   --  Returns plain class name in the templatized name. Returns the original
   --  type name, if type is not templatized.


private

   --------------------------------
   -- Type hash table defintions --
   --------------------------------

   Type_Table_Size : constant := 113;

   type String_Hash_Table_Range is range 1 .. Type_Table_Size;

   function Type_Hash_Function is
      new HTables.Hash (String_Hash_Table_Range);
   --  Hash function for keys

   type Type_Parse_State is (Incomplete, Complete, Unknown);

   procedure False_Free_Element (X : in out Type_Parse_State);

   package String_Hash_Table is new HTables.Simple_HTable
     (Header_Num   => String_Hash_Table_Range,
      Element      => Type_Parse_State,
      Free_Element => False_Free_Element,
      Key          => String,
      No_Element   => Unknown,
      Hash         => Type_Hash_Function,
      Equal        => "=");

   use String_Hash_Table;

   type Module_Typedefs_List is access HTable;

end Src_Info.Type_Utils;
