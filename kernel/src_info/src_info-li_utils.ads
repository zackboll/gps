-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                     Copyright (C) 2001-2002                       --
--                            ACT-Europe                             --
--                                                                   --
-- GPS is free  software; you can  redistribute it and/or modify  it --
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

with SN;
with Src_Info.CPP;

private package Src_Info.LI_Utils is

   procedure Insert_Declaration
     (Handler               : access Src_Info.CPP.CPP_LI_Handler_Record'Class;
      File                  : in out LI_File_Ptr;
      List                  : in out LI_File_List;
      Symbol_Name           : String;
      Source_Filename       : String;
      Location              : SN.Point;
      Parent_Filename       : String := "";
      Parent_Location       : SN.Point := SN.Invalid_Point;
      Kind                  : E_Kind;
      Scope                 : E_Scope;
      End_Of_Scope_Location : SN.Point := SN.Invalid_Point;
      Rename_Location       : SN.Point := SN.Invalid_Point;
      Declaration_Info      : out E_Declaration_Info_List);
   --  Insert a new entity declaration in File. File is created if needed, as
   --  well as the entry for Source_Filename (Body_Part).
   --  The newly created declaration is returned in Declaration_Info.
   --  (Parent_Filename, Parent_Location) points to the declaration of the
   --  parent entity, when available (classes, subtypes, ...), and should be
   --  left to the default value if not available.
   --
   --  ??? Rename_Location is currently ignored.
   --
   --  This subprogram raises Parent_Not_Available if the LI_Structure for the
   --  parent entity could not be found.
   --  ??? Shouldn't we create a stub LI file for the parent instead.

   procedure Insert_Dependency
     (Handler              : access Src_Info.CPP.CPP_LI_Handler_Record'Class;
      File                 : in out LI_File_Ptr;
      List                 : in out LI_File_List;
      Source_Filename      : String;
      Referred_Filename    : String);
   --  Create a new dependency, from the files described in File to the source
   --  file Referred_Filename.

   procedure Insert_Dependency_Declaration
     (Handler                : access Src_Info.CPP.CPP_LI_Handler_Record'Class;
      File                    : in out LI_File_Ptr;
      LI_Full_Filename        : String;
      List                    : in out LI_File_List;
      Symbol_Name             : String;
      Referred_Filename       : String;
      Location                : SN.Point;
      Parent_Filename         : String := "";
      Parent_Location         : SN.Point := SN.Invalid_Point;
      Kind                    : E_Kind;
      Scope                   : E_Scope;
      End_Of_Scope_Location   : SN.Point := SN.Invalid_Point;
      Rename_Location         : SN.Point := SN.Invalid_Point;
      Declaration_Info        : out E_Declaration_Info_List);
   --  Inserts new dependency declaration with specified parameters
   --  to given LI structure tree.
   --  Throws Parent_Not_Available exception if LI_Structure for the
   --  file with parent is not created yet.
   --  (Parent_Filename, Parent_Location) is the location of the declaration
   --  for the parent entity, if available.

   procedure Add_Parent
     (Declaration_Info : in out E_Declaration_Info_List;
      Handler          : Src_Info.CPP.CPP_LI_Handler;
      List             : in out LI_File_List;
      Parent_Filename  : String;
      Parent_Location  : SN.Point);
   --  Add a new parent entity to the list of parents for
   --  Declaration_Info. This is mostly used for multiple-inheritance.

   procedure Set_End_Of_Scope
     (Declaration_Info        : in out E_Declaration_Info_List;
      Location                : SN.Point;
      Kind                    : Reference_Kind := End_Of_Body);
   --  Sets given value for End_Of_Scope attribute of specified declaration

   procedure Insert_Reference
     (Declaration_Info        : in out E_Declaration_Info_List;
      File                    : LI_File_Ptr;
      Source_Filename         : String;
      Location                : SN.Point;
      Kind                    : Reference_Kind);
   --  Inserts new reference to declaration. Declaration here is specified
   --  by pointer to appropriate E_Declaration_Info_Node object

   No_Kind : E_Kind := Task_Type;
   --  This constant is used to represent the absence of Kind.
   --  Task_Type is used here because it can never occur in C/CPP program.
   --  ??? Could it be replaced with Unresolved_Entity ?

   function Find_Declaration
     (File                    : LI_File_Ptr;
      Symbol_Name             : String := "";
      Class_Name              : String := "";
      Kind                    : E_Kind := No_Kind;
      Location                : SN.Point := SN.Invalid_Point)
      return E_Declaration_Info_List;
   --  Finds declaration in LI tree by it's Name, Location or (and) Kind
   --  If value for some attribute is not given then this attribute doesn't
   --  affect on searching.
   --  Return null if not found.

   function Find_Dependency_Declaration
     (File                    : LI_File_Ptr;
      Symbol_Name             : String := "";
      Class_Name              : String := "";
      Filename                : String := "";
      Kind                    : E_Kind := No_Kind;
      Location                : SN.Point := SN.Invalid_Point)
      return E_Declaration_Info_List;
   --  Finds declaration in File by it's Name and Location.
   --  If value for some attribute is not given then this attribute doesn't
   --  affect on searching.
   --  Return null if not found.

   procedure Create_File_Info
     (FI_Ptr         : out File_Info_Ptr;
      Full_Filename  : String;
      Set_Time_Stamp : Boolean := True;
      Unit_Name      : String := "");
   --  Creates an empty File_Info (without declarations)
   --  If Set_Time_Stamp is True, then the timestamp is computed by reading
   --  Full_Filename.

   procedure Create_LI_File
     (File               : out LI_File_Ptr;
      List               : in out LI_File_List;
      LI_Full_Filename   : String;
      Handler            : LI_Handler;
      Parsed             : Boolean;
      Compilation_Errors : Boolean := False);
   --  Creates an empty LI_File structure.
   --  File is set to null if it couldn't be added to the global list of LI
   --  files.

end Src_Info.LI_Utils;
