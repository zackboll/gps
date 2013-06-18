------------------------------------------------------------------------------
--                                  G P S                                   --
--                                                                          --
--                     Copyright (C) 2007-2013, AdaCore                     --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
------------------------------------------------------------------------------

--  This package defines the format of the tree used to represent the sources
--  internally. Semantic information and documentation retrieved from sources
--  are combined in this tree. There is no separate symbol table structure.

--  Each tree nodes is composed of two parts:

--    * Low level: This part contains the information retrieved directly from
--      the Xref database. This information should be fully reliable since it
--      is the information in the Sqlite database which is composed of the
--      information directly retrieved from the LI files generated by the
--      compiler. By contrast in some cases this information may not be
--      complete enough to have the full context of a given entity. The
--      low level information of a node is available through the routines
--      of package LL.

--    * High Level: This part complements the low level information. It is
--      composed of information synthesized from combinations of low level
--      attributes and information synthesized using the context of an
--      entity by the frontend of Docgen3. The high level information of a
--      node is directly available through the public routines of this
--      package (excluding the routines of package LL).

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with GNATCOLL.Symbols;        use GNATCOLL.Symbols;
with GNATCOLL.Xref;           use GNATCOLL.Xref;
with Language;                use Language;
with Docgen3.Comment;         use Docgen3.Comment;
with Xref.Docgen;             use Xref.Docgen;

private package Docgen3.Atree is

   type Entity_Info_Record is private;
   type Entity_Id is access all Entity_Info_Record;

   procedure Initialize;
   --  Initialize internal state used to associate unique identifiers to all
   --  the tree nodes.

   function No (E : Entity_Id) return Boolean;
   --  Return true if E is null

   function Present (E : Entity_Id) return Boolean;
   --  Return true if E is not null

   -----------------
   -- Entity_Info --
   -----------------

   type Entity_Kind is
     (E_Unknown,
      E_Abstract_Function,
      E_Abstract_Procedure,
      E_Abstract_Record_Type,
      E_Access_Type,
      E_Array_Type,
      E_Boolean_Type,
      E_Class_Wide_Type,
      E_Decimal_Fixed_Point_Type,
      E_Entry,
      E_Enumeration_Type,
      E_Enumeration_Literal,
      E_Exception,
      E_Fixed_Point_Type,
      E_Floating_Point_Type,
      E_Function,
      E_Generic_Function,
      E_Generic_Package,
      E_Generic_Procedure,
      E_Interface,
      E_Integer_Type,
      E_Named_Number,
      E_Package,
      E_Private_Object,
      E_Procedure,
      E_Protected_Type,
      E_Record_Type,
      E_String_Type,
      E_Task,
      E_Task_Type,
      E_Variable,

      --  Synthesized Ada values

      E_Access_Subprogram_Type,
      E_Discriminant,
      E_Component,
      E_Formal,
      E_Generic_Formal,
      E_Tagged_Record_Type,

      --  C/C++
      E_Macro,
      E_Function_Macro,
      E_Class,
      E_Class_Instance,
      E_Include_File,

      --  Synthesized C++ values

      E_Attribute);

   ----------------
   -- EInfo_List --
   ----------------

   package EInfo_List is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Entity_Id);
   procedure Free (List : in out EInfo_List.Vector);

   function Less_Than_Loc (Left, Right : Entity_Id) return Boolean;
   package EInfo_Vector_Sort_Loc is new EInfo_List.Generic_Sorting
     ("<" => Less_Than_Loc);

   function Less_Than_Short_Name (Left, Right : Entity_Id) return Boolean;
   package EInfo_Vector_Sort_Short is new EInfo_List.Generic_Sorting
     ("<" => Less_Than_Short_Name);

   function Less_Than_Full_Name (Left, Right : Entity_Id) return Boolean;
   package EInfo_Vector_Sort_Full is new EInfo_List.Generic_Sorting
     ("<" => Less_Than_Full_Name);

   procedure Append_Unique_Elmt
     (Container : in out EInfo_List.Vector;
      Entity    : Entity_Id);
   --  Append Entity to the Container only if the container has no entity
   --  whose location matches the location of Entity.

   procedure For_All
     (Vector  : in out EInfo_List.Vector;
      Process : access procedure (E_Info : Entity_Id));
   --  Call subprogram Process for all the elements of Vector

   ---------------------------
   -- Entity_Id subprograms --
   ---------------------------

   function New_Entity
     (Context  : access constant Docgen_Context;
      Language : Language_Access;
      E        : General_Entity;
      Loc      : General_Location) return Entity_Id;
   function New_Internal_Entity
     (Context  : access constant Docgen_Context;
      Language : Language_Access;
      Name     : String) return Entity_Id;
   --  Tree node constructors

   procedure Free (E : in out Entity_Id);
   --  Tree node destructor

   procedure Append_Child_Type
     (E : Entity_Id; Value : Entity_Id);
   procedure Append_Entity
     (E : Entity_Id; Value : Entity_Id);
   --  Append Value to the list of entities in the scope of E
   procedure Append_Discriminant
     (E : Entity_Id; Value : Entity_Id);
   procedure Append_Method
     (E : Entity_Id; Value : Entity_Id);
   procedure Append_Parent_Type
     (E : Entity_Id; Value : Entity_Id);

   function Get_Child_Types
     (E : Entity_Id) return access EInfo_List.Vector;
   function Get_Comment
     (E : Entity_Id) return Structured_Comment;
   function Get_Discriminants
     (E : Entity_Id) return access EInfo_List.Vector;
   function Get_Doc
     (E : Entity_Id) return Comment_Result;
   function Get_Entities
     (E : Entity_Id) return access EInfo_List.Vector;
   function Get_Error_Msg
     (E : Entity_Id) return Unbounded_String;
   function Get_Full_Name
     (E : Entity_Id) return String;
   function Get_Full_View_Comment
     (E : Entity_Id) return Structured_Comment;
   function Get_Full_View_Doc
     (E : Entity_Id) return Comment_Result;
   function Get_Full_View_Src
     (E : Entity_Id) return Unbounded_String;
   function Get_Kind
     (E : Entity_Id) return Entity_Kind;
   function Get_Language
     (E : Entity_Id) return Language_Access;
   function Get_Methods
     (E : Entity_Id) return access EInfo_List.Vector;
   function Get_Parent_Types
     (E : Entity_Id) return access EInfo_List.Vector;
   function Get_Ref_File
     (E : Entity_Id) return Virtual_File;
   function Get_Scope
     (E : Entity_Id) return Entity_Id;
   function Get_Short_Name
     (E : Entity_Id) return String;
   function Get_Src
     (E : Entity_Id) return Unbounded_String;
   function Get_Unique_Id
     (E : Entity_Id) return Natural;

   function Has_Formals
     (E : Entity_Id) return Boolean;

   function In_Ada_Language
     (E : Entity_Id) return Boolean;
   function In_C_Language
     (E : Entity_Id) return Boolean;
   function In_CPP_Language
     (E : Entity_Id) return Boolean;

   function Is_Incomplete_Or_Private_Type
     (E : Entity_Id) return Boolean;
   function Is_Package
     (E : Entity_Id) return Boolean;
   function Is_Partial_View
     (E : Entity_Id) return Boolean;
   function Is_Full_View
     (E : Entity_Id) return Boolean;
   function Is_Private
     (E : Entity_Id) return Boolean;
   function Is_Class_Or_Record_Type
     (E : Entity_Id) return Boolean;
   --  Return True for Ada record types (including tagged types), C structs
   --  and C++ classes
   function Is_Tagged
     (E : Entity_Id) return Boolean;

   function Kind_In
     (K  : Entity_Kind;
      V1 : Entity_Kind;
      V2 : Entity_Kind) return Boolean;
   function Kind_In
     (K  : Entity_Kind;
      V1 : Entity_Kind;
      V2 : Entity_Kind;
      V3 : Entity_Kind) return Boolean;

   procedure Set_Comment
     (E : Entity_Id; Value : Structured_Comment);
   procedure Set_Doc
     (E : Entity_Id; Value : Comment_Result);
   procedure Set_Error_Msg
     (E : Entity_Id; Value : Unbounded_String);
   procedure Set_Full_View_Comment
     (E : Entity_Id; Value : Structured_Comment);
   procedure Set_Full_View_Doc
     (E : Entity_Id; Value : Comment_Result);
   procedure Set_Full_View_Src
     (E : Entity_Id; Value : Unbounded_String);
   procedure Set_Is_Partial_View
     (E : Entity_Id);
   procedure Set_Is_Private
     (E : Entity_Id);
   procedure Set_Is_Tagged
     (E : Entity_Id);
   procedure Set_Kind
     (E : Entity_Id; Value : Entity_Kind);
   procedure Set_Ref_File
     (E : Entity_Id; Value : Virtual_File);
   procedure Set_Scope
     (E : Entity_Id; Value : Entity_Id);
   procedure Set_Src
     (E : Entity_Id; Value : Unbounded_String);

   type Traverse_Result is (OK, Skip);

   procedure Traverse_Tree
     (Root    : Entity_Id;
      Process : access function
                         (Entity      : Entity_Id;
                          Scope_Level : Natural) return Traverse_Result);

   --  Given the parent node for a subtree, traverses all nodes of this tree,
   --  calling the given function Process on each one, in pre order (i.e.
   --  top-down). The order of traversing subtrees follows their order in the
   --  attribute Entities. The traversal is controlled as follows by the result
   --  returned by Process:

   --    OK       The traversal continues normally with the children of the
   --             node just processed.

   --    Skip     The children of the node just processed are skipped and
   --             excluded from the traversal, but otherwise processing
   --             continues elsewhere in the tree.

   -----------------------------------
   -- Low-Level abstraction package --
   -----------------------------------

   --  This local package provides the information retrieved directly from the
   --  Xref database when the entity is created. It is named LL (Low Level)
   --  instead of Xref to avoid having a third package in the GPS project
   --  named Xref (the other packages are Xref and GNATCOLL.Xref).

   package LL is
      function Get_Body_Loc     (E : Entity_Id) return General_Location;
      function Get_Entity       (E : Entity_Id) return General_Entity;
      function Get_Full_View    (E : Entity_Id) return General_Entity;
      function Get_Kind         (E : Entity_Id) return Entity_Kind;
      function Get_Location     (E : Entity_Id) return General_Location;
      function Get_Pointed_Type (E : Entity_Id) return General_Entity;
      function Get_Scope        (E : Entity_Id) return General_Entity;
      function Get_Scope_Loc    (E : Entity_Id) return General_Location;
      function Get_Type         (E : Entity_Id) return General_Entity;

      function Get_Ekind
        (Db          : General_Xref_Database;
         E           : General_Entity;
         In_Ada_Lang : Boolean) return Entity_Kind;
      --  In_Ada_Lang is used to enable an assertion since in Ada we are not
      --  processing bodies yet???

      function Has_Methods      (E : Entity_Id) return Boolean;

      function Is_Abstract      (E : Entity_Id) return Boolean;
      function Is_Access        (E : Entity_Id) return Boolean;
      function Is_Array         (E : Entity_Id) return Boolean;
      function Is_Container     (E : Entity_Id) return Boolean;
      function Is_Generic       (E : Entity_Id) return Boolean;
      function Is_Global        (E : Entity_Id) return Boolean;
      function Is_Predef        (E : Entity_Id) return Boolean;
      function Is_Primitive     (E : Entity_Id) return Boolean;
      function Is_Type          (E : Entity_Id) return Boolean;
      function Is_Subprogram    (E : Entity_Id) return Boolean;

      function Is_Self_Referenced_Type
        (Db   : General_Xref_Database;
         E    : General_Entity;
         Lang : Language_Access) return Boolean;
      --  Return true if Lang is C or C++ and the scope of E is itself. Used to
      --  identify the second second entity generated by the C/C++ compiler for
      --  named typedef structs (the compiler generates two entites in the LI
      --  file with the same name).

   private

      pragma Inline (Get_Body_Loc);
      pragma Inline (Get_Entity);
      pragma Inline (Get_Full_View);
      pragma Inline (Get_Kind);
      pragma Inline (Get_Location);
      pragma Inline (Get_Pointed_Type);
      pragma Inline (Get_Scope);
      pragma Inline (Get_Type);

      pragma Inline (Is_Abstract);
      pragma Inline (Is_Access);
      pragma Inline (Is_Array);
      pragma Inline (Is_Container);
      pragma Inline (Is_Generic);
      pragma Inline (Is_Global);
      pragma Inline (Is_Predef);
      pragma Inline (Is_Primitive);
      pragma Inline (Is_Subprogram);
      pragma Inline (Is_Type);
   end LL;

   ------------------------------------------
   --  Debugging routines (for use in gdb) --
   ------------------------------------------

   procedure Register_Database (Database : General_Xref_Database);
   --  Routine called by docgen3.adb to register in this package the database
   --  and thus simplify the use of subprogram "pn" from gdb.

   procedure pl (E : Entity_Id);
   --  (gdb) Prints the list of entities defined in the scope of E

   procedure pn (E : Entity_Id);
   --  (gdb) Prints a single tree node (full output), without printing
   --  descendants.

   procedure pns (E : Entity_Id);
   --  (gdb) Print a single tree node (short output), without printing
   --  descendants.

   function To_String
     (E             : Entity_Id;
      Prefix        : String := "";
      With_Full_Loc : Boolean := False;
      With_Src      : Boolean := False;
      With_Doc      : Boolean := False;
      With_Errors   : Boolean := False) return String;
   --  Returns a string containing all the information associated with E.
   --  Prefix is used by routines of package Docgen3.Treepr to generate the
   --  bar which represents the enclosing scopes. If With_Full_Loc is true then
   --  the full path of the location of the file is added to the output; if
   --  With_Src is true then the source retrieved from the sources is added to
   --  the output; if With_Doc is true then the documentation retrieved from
   --  sources is added to the output; if With_Errors is true then the errors
   --  reported on the node are added to the output.

private
   type Xref_Info is
      record
         Entity        : General_Entity;
         Full_View     : General_Entity;
         Loc           : General_Location;
         Body_Loc      : General_Location;
         Ekind         : Entity_Kind;
         Scope_E       : General_Entity;
         Scope_Loc     : General_Location;
         Etype         : General_Entity;
         Pointed_Type  : General_Entity;

         Has_Methods   : Boolean;

         Is_Abstract   : Boolean;
         Is_Access     : Boolean;
         Is_Array      : Boolean;
         Is_Container  : Boolean;
         Is_Global     : Boolean;
         Is_Predef     : Boolean;
         Is_Type       : Boolean;
         Is_Subprogram : Boolean;
         Is_Primitive  : Boolean;
         Is_Generic    : Boolean;
      end record;

   type Entity_Info_Record is
      record
         Id : Natural;
         --  Internal unique identifier associated with each entity. Given
         --  that Docgen3 routines are executed by a single thread, and given
         --  that their behavior is deterministic, this unique identifier
         --  facilitates setting breakpoints in the debugger using this Id.
         --
         --  This unique identifier may be also used by the backend to
         --  generate unique labels in the ReST output (to avoid problems
         --  with overloaded entities). For examples see Backend.Simple.

         Language : Language_Access;
         --  Language associated with the entity. It can be used by the backend
         --  to generate full or short names depending on the language. For
         --  examples see Backend.Simple.

         Ref_File : Virtual_File;
         --  File associated with this entity for backend references.
         --  * For Ada entities this value is the same of Loc.File.
         --  * For C/C++ entities defined in header files, the value of
         --    Loc.File references the .h file, which is a file for which the
         --    compiler does not generate LI files). Hence the frontend stores
         --    in this field the file which must be referenced by the backend.
         --    (that is, the corresponding .c or .cpp file). For entities
         --    defined in the .c (or .cpp) files the values of Loc.File and
         --    File are identical.

         --       Warning: The values of Id and Ref_File are used by the
         --       backend to generate valid and unique cross references
         --       between generated reST files.

         Xref            : Xref_Info;
         --  Information retrieved directly from the Xref database.

         Kind            : Entity_Kind;
         --  When the entity is created the fields Kind and Xref.Ekind are
         --  initialized with the same values. However, Kind may be decorated
         --  with other values by the frontend at later stages based on the
         --  context (for example, an E_Variable entity may be redecorated
         --  as E_Formal (see docgen3-frontend.adb)

         Scope           : Entity_Id;

         Full_Name       : GNATCOLL.Symbols.Symbol;
         Short_Name      : GNATCOLL.Symbols.Symbol;

         Is_Incomplete_Or_Private_Type : Boolean;
         Is_Partial_View : Boolean;
         Is_Private      : Boolean;
         Is_Tagged       : Boolean;

         Doc               : Comment_Result;
         Comment           : aliased Structured_Comment;
         --  Doc is a temporary buffer used to store the block of comments
         --  retrieved from the source file. After processed, it is cleaned and
         --  its contents is stored in the structured comment, which identifies
         --  tags and attributes.

         Full_View_Doc     : Comment_Result;
         Full_View_Comment : aliased Structured_Comment;
         --  Same as before but applicable to the documentation and structured
         --  comment associated with the full-view.

         Src             : Unbounded_String;
         Full_View_Src   : Unbounded_String;
         --  Source code associated with this entity (and its full-view)

         Discriminants   : aliased EInfo_List.Vector;
         --  Record type discriminants (if any)

         Entities        : aliased EInfo_List.Vector;
         --  Entities defined in the scope of this entity. For example, all
         --  the entities defined in the scope of a package, all the components
         --  of a record, etc.

         Methods         : aliased EInfo_List.Vector;
         --  Primitives of tagged types (or methods of C++ classes)

         Parent_Types    : aliased EInfo_List.Vector;
         --  Parent types of tagged types (or base classes of C++ classes)

         Child_Types     : aliased EInfo_List.Vector;
         --  Derivations of tagged types (or C++ classes)

         Error_Msg       : Unbounded_String;
         --  Errors reported on this entity
      end record;

   pragma Inline (Append_Child_Type);
   pragma Inline (Append_Discriminant);
   pragma Inline (Append_Entity);
   pragma Inline (Append_Method);
   pragma Inline (Append_Parent_Type);
   pragma Inline (Get_Child_Types);
   pragma Inline (Get_Comment);
   pragma Inline (Get_Discriminants);
   pragma Inline (Get_Doc);
   pragma Inline (Get_Entities);
   pragma Inline (Get_Error_Msg);
   pragma Inline (Get_Full_Name);
   pragma Inline (Get_Full_View_Comment);
   pragma Inline (Get_Full_View_Doc);
   pragma Inline (Get_Full_View_Src);
   pragma Inline (Get_Kind);
   pragma Inline (Get_Language);
   pragma Inline (Get_Methods);
   pragma Inline (Get_Parent_Types);
   pragma Inline (Get_Ref_File);
   pragma Inline (Get_Scope);
   pragma Inline (Get_Short_Name);
   pragma Inline (Get_Src);
   pragma Inline (Get_Unique_Id);
   pragma Inline (Has_Formals);
   pragma Inline (In_Ada_Language);
   pragma Inline (In_C_Language);
   pragma Inline (In_CPP_Language);
   pragma Inline (Is_Incomplete_Or_Private_Type);
   pragma Inline (Is_Package);
   pragma Inline (Is_Partial_View);
   pragma Inline (Is_Full_View);
   pragma Inline (Is_Private);
   pragma Inline (Is_Class_Or_Record_Type);
   pragma Inline (Is_Tagged);
   pragma Inline (Kind_In);
   pragma Inline (No);
   pragma Inline (Present);
   pragma Inline (Set_Comment);
   pragma Inline (Set_Doc);
   pragma Inline (Set_Error_Msg);
   pragma Inline (Set_Full_View_Comment);
   pragma Inline (Set_Full_View_Doc);
   pragma Inline (Set_Full_View_Src);
   pragma Inline (Set_Is_Partial_View);
   pragma Inline (Set_Is_Private);
   pragma Inline (Set_Is_Tagged);
   pragma Inline (Set_Kind);
   pragma Inline (Set_Ref_File);
   pragma Inline (Set_Scope);
   pragma Inline (Set_Src);
end Docgen3.Atree;
