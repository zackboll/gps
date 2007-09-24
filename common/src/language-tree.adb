-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                 Copyright (C) 2006-2007, AdaCore                  --
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

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;

with Language.Documentation; use Language.Documentation;
with Language.Unknown;       use Language.Unknown;

with String_Utils; use String_Utils;

with Glib.Convert; use Glib.Convert;

package body Language.Tree is

   --------------
   -- Contains --
   --------------

   function Contains (Scope, Item : Construct_Access) return Boolean is
   begin
      return Scope.Sloc_Start <= Item.Sloc_Start
        and then Scope.Sloc_End >= Item.Sloc_End;
   end Contains;

   ----------
   -- Free --
   ----------

   procedure Free (Tree : in out Construct_Tree) is
      procedure Internal is new Ada.Unchecked_Deallocation
        (Construct_Tree_Record, Construct_Tree);
   begin
      if Tree /= null then
         for J in Tree.Contents'Range loop
            GNAT.Strings.Free (Tree.Contents (J).Construct.Name);
         end loop;

         Free (Tree.Unit_Name);
         Internal (Tree);
      end if;
   end Free;

   -----------------------
   -- To_Construct_Tree --
   -----------------------

   function To_Construct_Tree
     (List : access Construct_List; Free_List : Boolean := False)
      return Construct_Tree
   is
      Size              : Natural := 0;
      Current_Construct : Construct_Access;
   begin
      Current_Construct := List.First;

      while Current_Construct /= null loop
         Size := Size + 1;
         Current_Construct := Current_Construct.Next;
      end loop;

      if Size = 0 then
         return new Construct_Tree_Record (0);
      end if;

      declare
         Tree       : constant Construct_Tree :=
           new Construct_Tree_Record (Size);
         Tree_Index : Positive := Size + 1;

         procedure Analyze_Construct;

         procedure Analyze_Construct is
            Parent         : constant Construct_Access := Current_Construct;
            Start_Index    : constant Positive := Tree_Index;
            Previous_Index : Positive;
         begin
            Current_Construct := Current_Construct.Prev;

            while Current_Construct /= null
              and then Contains (Parent, Current_Construct)
            loop
               Previous_Index := Tree_Index;
               pragma Warnings (Off);
               --  We know that we don't have an infinite recursion here
               Analyze_Construct;
               pragma Warnings (On);

               if Previous_Index in Tree.Contents'Range then
                  --  This is false when we are on the root node
                  Tree.Contents (Previous_Index).Previous_Sibling_Index :=
                    Tree_Index;
               end if;
            end loop;

            Tree_Index := Tree_Index - 1;

            if Free_List then
               --  In this case, since we are going to free the list, we can
               --  just get a handle on the name, and set null to the construct
               --  name since we are not going to need it anyway.

               To_Simple_Construct_Information
                 (Parent.all, Tree.Contents (Tree_Index).Construct, False);
               Parent.Name := null;
            else
               To_Simple_Construct_Information
                 (Parent.all, Tree.Contents (Tree_Index).Construct, True);
            end if;

            Tree.Contents (Tree_Index).Sub_Nodes_Length :=
              Start_Index - Tree_Index - 1;

            for J in Tree_Index + 1
              .. Tree_Index + Tree.Contents (Tree_Index).Sub_Nodes_Length
            loop
               if Tree.Contents (J).Parent_Index = 0 then
                  Tree.Contents (J).Parent_Index := Tree_Index;
               end if;
            end loop;
         end Analyze_Construct;

      begin
         Current_Construct := List.Last;

         while Current_Construct /= null loop
            Analyze_Construct;
         end loop;

         if Free_List then
            Free (List.all);
         end if;

         return Tree;
      end;
   end To_Construct_Tree;

   -----------------------
   -- To_Construct_Tree --
   -----------------------

   function To_Construct_Tree
     (Buffer : String;
      Lang   : access Language_Root'Class)
      return Construct_Tree
   is
      List : aliased Construct_List;
   begin
      Parse_Constructs (Lang, Buffer, List);

      return To_Construct_Tree (List'Access, True);
   end To_Construct_Tree;

   -----------
   -- First --
   -----------

   function First (Tree : Construct_Tree) return Construct_Tree_Iterator is
   begin
      if Tree.Contents'Length > 0 then
         return (Tree.Contents (1), 1);
      else
         return Null_Construct_Tree_Iterator;
      end if;
   end First;

   ----------
   -- Last --
   ----------

   function Last (Tree : Construct_Tree) return Construct_Tree_Iterator is
   begin
      if Tree.Contents'Length > 0 then
         return (Tree.Contents (Tree.Contents'Last), Tree.Contents'Last);
      else
         return Null_Construct_Tree_Iterator;
      end if;
   end Last;

   ----------------------
   -- Get_Parent_Scope --
   ----------------------

   function Get_Parent_Scope
     (Tree : Construct_Tree; Iter : Construct_Tree_Iterator)
     return Construct_Tree_Iterator
   is
   begin
      if Iter.Node.Parent_Index /= 0 then
         return
           (Tree.Contents (Iter.Node.Parent_Index), Iter.Node.Parent_Index);
      else
         return Null_Construct_Tree_Iterator;
      end if;
   end Get_Parent_Scope;

   -------------------
   -- Get_Construct --
   -------------------

   function Get_Construct (Iter : Construct_Tree_Iterator)
      return Simple_Construct_Information
   is
   begin
      return Iter.Node.Construct;
   end Get_Construct;

   ----------------------
   -- Get_Child_Number --
   ----------------------

   function Get_Child_Number (Iter : Construct_Tree_Iterator) return Natural is
   begin
      return Iter.Node.Sub_Nodes_Length;
   end Get_Child_Number;

   ---------
   -- "=" --
   ---------

   function "="
     (Left : Text_Location; Right : Source_Location) return Boolean is
   begin
      case Left.Absolute_Offset is
         when True =>
            return Left.Offset = Right.Index;
         when False =>
            return Left.Line = Right.Line
              and then Left.Line_Offset = Right.Column;
      end case;
   end "=";

   ---------
   -- "<" --
   ---------

   function "<"
     (Left : Text_Location; Right : Source_Location) return Boolean is
   begin
      case Left.Absolute_Offset is
         when True =>
            return Left.Offset < Right.Index;
         when False =>
            return Left.Line < Right.Line
              or else (Left.Line = Right.Line
                       and then Left.Line_Offset < Right.Column);
      end case;
   end "<";

   ----------
   -- "<=" --
   ----------

   function "<="
     (Left : Text_Location; Right : Source_Location) return Boolean is
   begin
      return Left = Right or else Left < Right;
   end "<=";

   ---------
   -- ">" --
   ---------

   function ">"
     (Left : Text_Location; Right : Source_Location) return Boolean is
   begin
      case Left.Absolute_Offset is
         when True =>
            return Left.Offset > Right.Index;
         when False =>
            return Left.Line > Right.Line
              or else (Left.Line = Right.Line
                       and then Left.Line_Offset > Right.Column);
      end case;
   end ">";

   ----------
   -- ">=" --
   ----------

   function ">="
     (Left : Text_Location; Right : Source_Location) return Boolean is
   begin
      return Left = Right or else Left > Right;
   end ">=";

   -----------------
   -- To_Location --
   -----------------

   function To_Location (Offset : Integer) return Text_Location is
   begin
      return (True, Offset);
   end To_Location;

   -----------------
   -- To_Location --
   -----------------

   function To_Location (Line, Line_Offset : Natural) return Text_Location is
   begin
      return (False, Line, Line_Offset);
   end To_Location;

   ---------------------
   -- Get_Iterator_At --
   ---------------------

   function Get_Iterator_At
     (Tree              : Construct_Tree;
      Location          : Text_Location;
      From_Type         : Position_Type := Start_Construct;
      Position          : Relative_Position := Specified;
      Categories_Seeked : Category_Array := Null_Category_Array)
      return Construct_Tree_Iterator
   is
      function Match_Category (Cat : Language_Category) return Boolean;
      --  Return true if the category given in parameter is the one we expect

      function Is_After
        (Construct : Simple_Construct_Information) return Boolean;
      --  Return true if the position is strictly after the expected position

      function Is_On_Or_After
        (Construct : Simple_Construct_Information) return Boolean;
      --  Return true is the construct given in parameter is on or after the
      --  expected position.

      function Is_On (Construct : Simple_Construct_Information) return Boolean;
      --  Return true is the construct is on the specified position

      function Is_Enclosing
        (Construct : Simple_Construct_Information) return Boolean;
      --  Return true if the construct encloses the specified position

      --------------------
      -- Match_Category --
      --------------------

      function Match_Category (Cat : Language_Category) return Boolean is
      begin
         if Categories_Seeked'Length = 0 then
            return True;
         else
            for J in Categories_Seeked'Range loop
               if Categories_Seeked (J) = Cat then
                  return True;
               end if;
            end loop;

            return False;
         end if;
      end Match_Category;

      --------------
      -- Is_After --
      --------------

      function Is_After
        (Construct : Simple_Construct_Information) return Boolean is
      begin
         if From_Type = Start_Construct then
            return Location < Construct.Sloc_Start;
         elsif From_Type = Start_Name then
            return Location < Construct.Sloc_Entity;
         else
            raise Constraint_Error;
         end if;
      end Is_After;

      --------------------
      -- Is_On_Or_After --
      --------------------

      function Is_On_Or_After
        (Construct : Simple_Construct_Information) return Boolean
      is
      begin
         if From_Type = Start_Construct then
            return Location <= Construct.Sloc_Start;
         elsif From_Type = Start_Name then
            return Location <= Construct.Sloc_Entity;
         else
            raise Constraint_Error;
         end if;
      end Is_On_Or_After;

      -----------
      -- Is_On --
      -----------

      function Is_On
        (Construct : Simple_Construct_Information) return Boolean is
      begin
         if From_Type = Start_Construct then
            return Location = Construct.Sloc_Start;
         elsif From_Type = Start_Name then
            return Location = Construct.Sloc_Entity;
         else
            raise Constraint_Error;
         end if;
      end Is_On;

      ------------------
      -- Is_Enclosing --
      ------------------

      function Is_Enclosing
        (Construct : Simple_Construct_Information) return Boolean
      is
      begin
         return Location >= Construct.Sloc_Start
           and then Location <= Construct.Sloc_End;
      end Is_Enclosing;

      Last_Matched : Construct_Tree_Iterator :=
        Null_Construct_Tree_Iterator;

   begin
      if Tree.Contents'Length = 0 then
         return Null_Construct_Tree_Iterator;
      end if;

      if Position = Before then
         if Match_Category (Tree.Contents (1).Construct.Category) then
            Last_Matched := (Tree.Contents (1), 1);
         end if;

         for J in 2 .. Tree.Contents'Last loop
            if Is_After (Tree.Contents (J).Construct) then
               return Last_Matched;
            end if;

            if Match_Category (Tree.Contents (J).Construct.Category) then
               Last_Matched := (Tree.Contents (J), J);
            end if;
         end loop;

         return Last_Matched;
      elsif Position = After then
         for J in 1 .. Tree.Contents'Last loop
            if Is_On_Or_After (Tree.Contents (J).Construct)
              and then Match_Category (Tree.Contents (J).Construct.Category)
            then
               return (Tree.Contents (J), J);
            end if;
         end loop;
      elsif Position = Specified then
         for J in 1 .. Tree.Contents'Last loop
            if Is_On (Tree.Contents (J).Construct)
              and then Match_Category (Tree.Contents (J).Construct.Category)
            then
               return (Tree.Contents (J), J);
            elsif Is_After (Tree.Contents (J).Construct) then
               return Null_Construct_Tree_Iterator;
            end if;
         end loop;
      elsif Position = Enclosing then
         for J in 1 .. Tree.Contents'Last loop
            if Is_Enclosing (Tree.Contents (J).Construct)
              and then Match_Category (Tree.Contents (J).Construct.Category)
            then
               Last_Matched := (Tree.Contents (J), J);
            end if;

            exit when Is_After (Tree.Contents (J).Construct);
         end loop;

         return Last_Matched;
      end if;

      return Null_Construct_Tree_Iterator;
   end Get_Iterator_At;

   ----------
   -- Next --
   ----------

   function Next
     (Tree         : Construct_Tree;
      Iter         : Construct_Tree_Iterator;
      Scope_Policy : Scope_Navigation := Jump_Into)
      return Construct_Tree_Iterator
   is
      Next_Index : Positive;
   begin
      if Scope_Policy = Jump_Into then
         Next_Index := Iter.Index + 1;
      else
         Next_Index := Iter.Index + Iter.Node.Sub_Nodes_Length + 1;
      end if;

      if Next_Index > Tree.Contents'Last then
         return Null_Construct_Tree_Iterator;
      else
         return (Tree.Contents (Next_Index), Next_Index);
      end if;
   end Next;

   ----------
   -- Prev --
   ----------

   function Prev
     (Tree         : Construct_Tree;
      Iter         : Construct_Tree_Iterator;
      Scope_Policy : Scope_Navigation := Jump_Into)
      return Construct_Tree_Iterator
   is
      Next_Index : Natural;
   begin
      if Scope_Policy = Jump_Into then
         Next_Index := Iter.Index - 1;
      else
         if Iter.Node.Previous_Sibling_Index /= 0 then
            Next_Index := Iter.Node.Previous_Sibling_Index;
         else
            Next_Index := Iter.Index - 1;
         end if;
      end if;

      if Next_Index = 0 then
         return Null_Construct_Tree_Iterator;
      else
         return (Tree.Contents (Next_Index), Next_Index);
      end if;
   end Prev;

   ------------------
   -- Has_Children --
   ------------------

   function Has_Children (Iter : Construct_Tree_Iterator) return Boolean is
   begin
      return Iter.Node.Sub_Nodes_Length > 0;
   end Has_Children;

   --------------------
   -- Get_Last_Child --
   --------------------

   function Get_Last_Child
     (Tree : Construct_Tree; Iter : Construct_Tree_Iterator)
      return Construct_Tree_Iterator
   is
      Last_Index : constant Natural := Iter.Index + Iter.Node.Sub_Nodes_Length;
      It : Construct_Tree_Iterator := (Tree.Contents (Last_Index), Last_Index);
   begin
      while It /= Iter and then Get_Parent_Scope (Tree, It) /= Iter loop
         It := Prev (Tree, It, Jump_Over);
      end loop;

      return It;
   end Get_Last_Child;

   -------------------
   -- Is_Same_Scope --
   -------------------

   function Is_Same_Entity
     (Tree : Construct_Tree; Iter1, Iter2 : Construct_Tree_Iterator)
      return Boolean
   is
   begin
      if Iter1.Node.Construct.Name.all = Iter2.Node.Construct.Name.all
        and then Iter1.Node.Construct.Category = Iter2.Node.Construct.Category
      then
         if Iter1.Node.Parent_Index = 0
           and then Iter2.Node.Parent_Index = 0
         then
            return True;
         elsif Iter1.Node.Parent_Index = 0
           and then Iter2.Node.Parent_Index /= 0
         then
            return False;
         else
            return Is_Same_Entity
              (Tree,
               (Tree.Contents
                  (Iter1.Node.Parent_Index), Iter1.Node.Parent_Index),
               (Tree.Contents
                  (Iter2.Node.Parent_Index), Iter2.Node.Parent_Index));
         end if;
      else
         return False;
      end if;
   end Is_Same_Entity;

   ------------------------------
   -- Get_Last_Relevant_Entity --
   ------------------------------

   function Get_Last_Relevant_Construct
     (Tree : Construct_Tree; Offset : Natural)
     return Construct_Tree_Iterator
   is
      Last_Relevant_Construct : Construct_Tree_Iterator :=
        Null_Construct_Tree_Iterator;
      It                      : Construct_Tree_Iterator;
   begin

      for J in reverse 1 .. Tree.Contents'Last loop
         if Tree.Contents (J).Construct.Sloc_Start.Index <= Offset then
            Last_Relevant_Construct := (Tree.Contents (J), J);
            It := Last_Relevant_Construct;

            while It /= Null_Construct_Tree_Iterator loop
               --  If we found the enclosing construct, nothing more to get.

               if Get_Construct (It).Sloc_End.Index >= Offset then
                  exit;
               end if;

               --  If the iterator is not anymore on the same scope, we have
               --  jumped in an enclosing scope, and therefore the last
               --  construct found is in fact unreacheable. It is the actual
               --  one.

               if Get_Parent_Scope (Tree, It)
                 /= Get_Parent_Scope (Tree, Last_Relevant_Construct)
               then
                  Last_Relevant_Construct := It;
               end if;

               It := Prev (Tree, It, Jump_Over);
            end loop;

            exit;
         end if;
      end loop;

      return Last_Relevant_Construct;
   end Get_Last_Relevant_Construct;

   --------------
   -- Encloses --
   --------------

   function Encloses
     (Tree : Construct_Tree; Scope, Iter : Construct_Tree_Iterator)
      return Boolean
   is
   begin
      if Iter.Node.Parent_Index = 0 then
         return False;
      elsif Is_Same_Entity
        (Tree,
         (Tree.Contents (Iter.Node.Parent_Index), Iter.Node.Parent_Index),
         Scope)
      then
         return True;
      else
         return Encloses
           (Tree,
            Scope,
            (Tree.Contents (Iter.Node.Parent_Index), Iter.Node.Parent_Index));
      end if;
   end Encloses;

   --------------
   -- Encloses --
   --------------

   function Encloses
     (Tree              : Construct_Tree;
      Scope             : Construct_Tree_Iterator;
      Line, Line_Offset : Positive)
      return Boolean
   is
      Last_Relevant_Entity : Natural := 0;
   begin
      --  Find the closest scope

      for J in 1 .. Tree.Contents'Last loop
         if (Tree.Contents (J).Construct.Sloc_Start.Line < Line
           or else
             (Tree.Contents (J).Construct.Sloc_Start.Line = Line
              and then Tree.Contents (J).Construct.Sloc_Start.Column
              < Line_Offset))
           and then
             (Tree.Contents (J).Construct.Sloc_End.Line > Line
              or else
                (Tree.Contents (J).Construct.Sloc_End.Line = Line
                 and then Tree.Contents (J).Construct.Sloc_End.Column
                 > Line_Offset))
         then
            Last_Relevant_Entity := J;
         end if;
      end loop;

      if Last_Relevant_Entity = 0 then
         --  ??? See why we get a warning here !
         pragma Warnings (Off);
         return Encloses
           (Tree,
            Scope,
            (Tree.Contents (Last_Relevant_Entity), Last_Relevant_Entity))
           or else Is_Same_Entity
             (Tree,
              Scope,
              (Tree.Contents (Last_Relevant_Entity), Last_Relevant_Entity));
         pragma Warnings (On);
      else
         return False;
      end if;
   end Encloses;

   --------------
   -- Encloses --
   --------------

   function Encloses
     (Tree   : Construct_Tree;
      Scope  : Construct_Tree_Iterator;
      Offset : Positive)
      return Boolean
   is
      Last_Relevant_Entity : constant Construct_Tree_Iterator :=
        Get_Last_Relevant_Construct (Tree, Offset);
   begin
      if Last_Relevant_Entity /= Null_Construct_Tree_Iterator then
         return Encloses
           (Tree, Scope, Last_Relevant_Entity)
           or else Is_Same_Entity
             (Tree,
              Scope,
              Last_Relevant_Entity);
      else
         return False;
      end if;
   end Encloses;

   -------------------
   -- Get_Full_Name --
   -------------------

   --  ??? This is language dependent, to be either moved into a language
   --  dependent package or made language indepenend
   function Get_Full_Name
     (Tree : Construct_Tree; It : Construct_Tree_Iterator)
      return String
   is
      Length  : Integer;
      Current : Construct_Tree_Iterator := Get_Parent_Scope (Tree, It);
   begin
      if Get_Construct (It).Name = null then
         return "";
      end if;

      Length := Get_Construct (It).Name.all'Length;

      while Current /= Null_Construct_Tree_Iterator
        and then Get_Construct (Current).Category = Cat_Package
      loop
         Length := Length + 1 + Get_Construct (Current).Name.all'Length;
         Current := Get_Parent_Scope (Tree, Current);
      end loop;

      declare
         Name  : String (1 .. Length);
         Index : Natural := Length;
      begin
         Name (Index - Get_Construct (It).Name.all'Length + 1 .. Index) :=
           Get_Construct (It).Name.all;

         Index := Index - Get_Construct (It).Name.all'Length;
         Current := Get_Parent_Scope (Tree, It);

         while Current /= Null_Construct_Tree_Iterator
           and then Get_Construct (Current).Category = Cat_Package
         loop
            Name (Index - Get_Construct (Current).Name.all'Length .. Index)
              := Get_Construct (Current).Name.all & ".";

            Index := Index - 1 - Get_Construct (Current).Name.all'Length;
            Current := Get_Parent_Scope (Tree, Current);
         end loop;

         return Name;
      end;
   end Get_Full_Name;

   -------------------------
   -- To_Construct_Access --
   -------------------------

   function To_Construct_Access
     (Tree : Construct_Tree; Iterator : Construct_Tree_Iterator)
      return Construct_Cell_Access
   is
   begin
      return (Tree, Iterator.Index);
   end To_Construct_Access;

   --------------------------------
   -- To_Construct_Tree_Iterator --
   --------------------------------

   function To_Construct_Tree_Iterator
     (Construct : Construct_Cell_Access) return Construct_Tree_Iterator is
   begin
      return (Construct.Tree.Contents (Construct.Index), Construct.Index);
   end To_Construct_Tree_Iterator;

   --------------
   -- Get_Tree --
   --------------

   function Get_Tree
     (Construct : Construct_Cell_Access) return Construct_Tree is
   begin
      return Construct.Tree;
   end Get_Tree;

   -----------------------
   -- Is_Same_Construct --
   -----------------------

   function Is_Same_Construct
     (Left, Right : Construct_Cell_Access) return Boolean
   is
      function Equals (C1, C2 : Simple_Construct_Information) return Boolean;

      function Equals (C1, C2 : Simple_Construct_Information) return Boolean is
      begin
         return C1.Category = C2.Category
           and then C1.Is_Declaration = C2.Is_Declaration
           and then C1.Visibility = C2.Visibility
           and then C1.Attributes = C2.Attributes
           and then C1.Name.all = C2.Name.all;
      end Equals;

      It_Left, It_Right : Construct_Tree_Iterator;
   begin
      It_Left := (Left.Tree.Contents (Left.Index), Left.Index);
      It_Right := (Right.Tree.Contents (Right.Index), Right.Index);

      while It_Left /= Null_Construct_Tree_Iterator
        and then It_Right /= Null_Construct_Tree_Iterator
      loop
         if not Equals (Get_Construct (It_Left), Get_Construct (It_Right)) then
            return False;
         end if;

         It_Left := Get_Parent_Scope (Left.Tree, It_Left);
         It_Right := Get_Parent_Scope (Right.Tree, It_Right);
      end loop;

      return It_Left = Null_Construct_Tree_Iterator
        and then It_Right = Null_Construct_Tree_Iterator;
   end Is_Same_Construct;

   ----------
   -- Free --
   ----------

   procedure Free (This : in out Composite_Identifier_Access) is
      procedure Internal_Free is new Ada.Unchecked_Deallocation
        (Composite_Identifier, Composite_Identifier_Access);
   begin
      Internal_Free (This);
   end Free;

   ------------
   -- Length --
   ------------

   function Length (Id : Composite_Identifier) return Natural is
   begin
      return Id.Number_Of_Elements;
   end Length;

   --------------
   -- Get_Item --
   --------------

   function Get_Item (Id : Composite_Identifier; Number : Natural)
     return String is
   begin
      if Number = 0 then
         return "";
      else
         return Id.Identifier
           (Id.Position_Start (Number) .. Id.Position_End (Number));
      end if;
   end Get_Item;

   -------------
   -- Prepend --
   -------------

   function Prepend
     (Id         : Composite_Identifier;
      Word_Begin : Natural;
      Word_End   : Natural)
      return Composite_Identifier
   is
      Result : Composite_Identifier
        (Id.String_Length, Id.Number_Of_Elements + 1);
   begin
      Result.Identifier := Id.Identifier;
      Result.Position_Start (1) := Word_Begin;
      Result.Position_End (1) := Word_End;
      Result.Position_Start (2 .. Result.Position_Start'Last)
        := Id.Position_Start;
      Result.Position_End (2 .. Result.Position_End'Last)
        := Id.Position_End;

      return Result;
   end Prepend;

   -----------------------------
   -- To_Composite_Identifier --
   -----------------------------

   function To_Composite_Identifier (Identifier : String)
     return Composite_Identifier
   is
      Index : Natural;

      function Internal_To_Composite_Identifier return Composite_Identifier;
      --  Internal function, analyzing recursively the various parts of the
      --  composite identifier

      --------------------------------------
      -- Internal_To_Composite_Identifier --
      --------------------------------------

      function Internal_To_Composite_Identifier return Composite_Identifier is
         Word_Begin, Word_End : Natural;
      begin
         Skip_Blanks (Identifier, Index);

         Word_Begin := Index;
         Word_End := Word_Begin;

         if Identifier (Word_Begin) = '"' then
            Word_End := Word_End + 1;
            Skip_To_Char (Identifier, Word_End, '"');
            Word_End := Word_End + 1;
         else
            Skip_Word (Identifier, Word_End);
         end if;

         Index := Word_End;
         Word_End := Word_End - 1;

         Skip_Blanks (Identifier, Index);

         if Index > Identifier'Last or else Identifier (Index) /= '.' then
            declare
               Id : Composite_Identifier (Word_End - Identifier'First + 1, 1);
            begin
               Id.Identifier := Identifier (Identifier'First .. Word_End);
               Id.Position_Start (1) := Word_Begin - Identifier'First + 1;
               Id.Position_End (1) := Word_End - Identifier'First + 1;

               return Id;
            end;
         end if;

         if Index < Identifier'Last then
            Index := Index + 1;
         end if;

         return Prepend
           (Internal_To_Composite_Identifier,
            Word_Begin - Identifier'First + 1,
            Word_End - Identifier'First + 1);
      end Internal_To_Composite_Identifier;

   begin
      if Identifier = "" then
         return (0, 0, "", (others => 0), (others => 0));
      end if;

      Index := Identifier'First;

      return Internal_To_Composite_Identifier;
   end To_Composite_Identifier;

   ---------------
   -- To_String --
   ---------------

   function To_String (Identifier : Composite_Identifier) return String is
      Buffer     : String (1 .. Identifier.Identifier'Length);
      Buffer_Ind : Natural := 0;
   begin
      for J in 1 .. Length (Identifier) loop
         declare
            Part : constant String := Get_Item (Identifier, J);
         begin
            if J > 1 then
               Buffer (Buffer_Ind + 1) := '.';
               Buffer_Ind := Buffer_Ind + 1;
            end if;

            Buffer (Buffer_Ind + 1 .. Buffer_Ind + Part'Length) := Part;
            Buffer_Ind := Buffer_Ind + Part'Length;
         end;
      end loop;

      return Buffer (1 .. Buffer_Ind);
   end To_String;

   ---------------
   -- Get_Slice --
   ---------------

   function Get_Slice
     (Identifier : Composite_Identifier; From : Natural; To : Natural)
      return Composite_Identifier
   is
      Result : Composite_Identifier
        (Identifier.Position_End (To) - Identifier.Position_Start (From) + 1,
         To - From + 1);
   begin
      for J in From .. To loop
         Result.Position_Start (J - From + 1) :=
           Identifier.Position_Start (J)
           - Identifier.Position_Start (From) + 1;
         Result.Position_End (J - From + 1) :=
           Identifier.Position_End (J)
           - Identifier.Position_Start (From) + 1;
      end loop;

      Result.Identifier := Identifier.Identifier
        (Identifier.Position_Start (From) .. Identifier.Position_End (To));

      return Result;
   end Get_Slice;

   -------------------------
   -- Full_Construct_Path --
   -------------------------

   function Full_Construct_Path
     (Cell : Construct_Cell_Access) return Construct_Tree_Iterator_Array
   is
      It   : Construct_Tree_Iterator := To_Construct_Tree_Iterator (Cell);
      Size : Integer := 0;
   begin
      while It /= Null_Construct_Tree_Iterator loop
         It := Get_Parent_Scope (Get_Tree (Cell), It);

         Size := Size + 1;
      end loop;

      declare
         Result : Construct_Tree_Iterator_Array (1 .. Size);
         Ind    : Integer := Result'Length;
      begin
         It := To_Construct_Tree_Iterator (Cell);

         while It /= Null_Construct_Tree_Iterator loop
            Result (Ind) := It;

            It := Get_Parent_Scope (Get_Tree (Cell), It);

            Ind := Ind - 1;
         end loop;

         return Result;
      end;
   end Full_Construct_Path;

   ---------------------
   -- Get_Parent_Tree --
   ---------------------

   function Get_Parent_Tree
     (Lang       : access Tree_Language;
      Left_Tree  : Construct_Tree;
      Right_Tree : Construct_Tree)
      return Get_Parent_Tree_Result
   is
      pragma Unreferenced (Lang, Left_Tree, Right_Tree);
   begin
      return None;
   end Get_Parent_Tree;

   ---------------------
   -- Get_Public_Tree --
   ---------------------

   function Get_Public_Tree
     (Lang      : access Tree_Language;
      Full_Tree : access Construct_Tree;
      Free_Tree : Boolean) return Construct_Tree
   is
      pragma Unreferenced (Lang);

      New_Tree : Construct_Tree;
   begin
      if Free_Tree then
         New_Tree := Full_Tree.all;
      else
         --  Since we're not supposed to free the orininal tree, the new one
         --  has to be a copy.
         New_Tree := new Construct_Tree_Record'(Full_Tree.all.all);

         for J in New_Tree.Contents'Range loop
            New_Tree.Contents (J).Construct.Name :=
              new String'(New_Tree.Contents (J).Construct.Name.all);
         end loop;
      end if;

      return New_Tree;
   end Get_Public_Tree;

   ------------------------
   -- Get_Unit_Construct --
   ------------------------

   function Get_Unit_Construct
     (Lang : access Tree_Language;
      Tree : Construct_Tree) return Construct_Tree_Iterator
   is
      pragma Unreferenced (Lang, Tree);
   begin
      return Null_Construct_Tree_Iterator;
   end Get_Unit_Construct;

   -------------------
   -- Get_Unit_Name --
   -------------------

   function Get_Unit_Name
     (Lang : access Tree_Language;
      Tree : Construct_Tree) return Composite_Identifier
   is
      pragma Unreferenced (Lang, Tree);
   begin
      return To_Composite_Identifier ("");
   end Get_Unit_Name;

   --------------------
   -- Get_Name_Index --
   --------------------

   function Get_Name_Index
     (Lang      : access Tree_Language;
      Construct : Simple_Construct_Information) return String
   is
      pragma Unreferenced (Lang);
   begin
      return Construct.Name.all;
   end Get_Name_Index;

   ----------------------
   -- Compare_Entities --
   ----------------------

   function Compare_Entities
     (Lang                      : access Tree_Language;
      Left_Iter, Right_Iter     : Construct_Tree_Iterator;
      Left_Tree, Right_Tree     : Construct_Tree;
      Left_Buffer, Right_Buffer : GNAT.Strings.String_Access)
      return General_Order
   is
      pragma Unreferenced (Lang, Left_Buffer, Right_Buffer);

      Left_Name  : String := Get_Full_Name (Left_Tree, Left_Iter);
      Right_Name : String := Get_Full_Name (Right_Tree, Right_Iter);
   begin
      if Left_Name < Right_Name then
         return Lower_Than;
      elsif Left_Name > Right_Name then
         return Greater_Than;
      else
         return Equals;
      end if;
   end Compare_Entities;

   -----------------------
   -- Get_Documentation --
   -----------------------

   function Get_Documentation
     (Lang   : access Tree_Language;
      Buffer : String;
      Tree   : Construct_Tree;
      Node   : Construct_Tree_Iterator) return String
   is
      Beginning, Current   : Natural;
      Result               : Unbounded_String;

      Type_Start, Type_End : Source_Location;
      Success              : Boolean;
      Language             : constant Language_Access :=
        Get_Language (Tree_Language'Class (Lang.all)'Access);
      Add_New_Line         : Boolean := False;
   begin
      Get_Documentation_Before
        (Context       => Get_Language_Context (Language).all,
         Buffer        => Buffer,
         Decl_Index    => Get_Construct (Node).Sloc_Start.Index,
         Comment_Start => Beginning,
         Comment_End   => Current);

      if Beginning = 0 then
         Get_Documentation_After
           (Context       => Get_Language_Context (Language).all,
            Buffer        => Buffer,
            Decl_Index    => Get_Construct (Node).Sloc_End.Index,
            Comment_Start => Beginning,
            Comment_End   => Current);
      end if;

      if Beginning /= 0 then
         Append
           (Result,
            Escape_Text
              (Comment_Block
                 (Language,
                  Buffer (Beginning .. Current),
                  Comment => False,
                  Clean   => True)));

         Add_New_Line := True;
      end if;

      if Get_Construct (Node).Category in Subprogram_Category then
         declare
            Sub_Iter               : Construct_Tree_Iterator :=
                                       Next (Tree, Node, Jump_Into);
            Has_Parameter          : Boolean := False;
            Biggest_Parameter_Name : Integer := 0;
         begin
            while Get_Parent_Scope (Tree, Sub_Iter) = Node loop
               if Get_Construct (Sub_Iter).Category = Cat_Parameter then
                  Add_New_Line := True;

                  if Get_Construct (Sub_Iter).Name'Length >
                    Biggest_Parameter_Name
                  then
                     Biggest_Parameter_Name :=
                       Get_Construct (Sub_Iter).Name'Length;
                  end if;
               end if;

               Sub_Iter := Next (Tree, Sub_Iter, Jump_Over);
            end loop;

            Sub_Iter := Next (Tree, Node, Jump_Into);

            while Get_Parent_Scope (Tree, Sub_Iter) = Node loop
               if Get_Construct (Sub_Iter).Category = Cat_Parameter then
                  if not Has_Parameter then
                     if Add_New_Line then
                        Append (Result, ASCII.LF & ASCII.LF);
                     end if;

                     Append
                       (Result, "<b>Parameters:</b>");
                     Has_Parameter := True;
                     Add_New_Line := True;
                  end if;

                  Append (Result, ASCII.LF);

                  Get_Referenced_Entity
                    (Language,
                     Buffer,
                     Get_Construct (Sub_Iter),
                     Type_Start,
                     Type_End,
                     Success);

                  Append
                    (Result, Escape_Text (Get_Construct (Sub_Iter).Name.all));

                  for J in Get_Construct (Sub_Iter).Name'Length + 1
                    .. Biggest_Parameter_Name
                  loop
                     Append (Result, " ");
                  end loop;

                  if Success then
                     Append
                       (Result,
                        " : " & Escape_Text
                          (Buffer (Type_Start.Index .. Type_End.Index)));
                  else
                     Append (Result, " : ???");
                  end if;
               end if;

               Sub_Iter := Next (Tree, Sub_Iter, Jump_Over);
            end loop;
         end;

         Get_Referenced_Entity
           (Language,
            Buffer,
            Get_Construct (Node),
            Type_Start,
            Type_End,
            Success);

         if Success then
            if Add_New_Line then
               Append (Result, ASCII.LF & ASCII.LF);
            end if;

            Append
              (Result,
               "<b>Return:</b>"
               & ASCII.LF
               & Escape_Text (Buffer (Type_Start.Index .. Type_End.Index)));
         end if;

      elsif Get_Construct (Node).Category in Data_Category then
         declare
            Var_Start, Var_End : Source_Location;
         begin
            Get_Referenced_Entity
              (Language,
               Buffer,
               Get_Construct (Node),
               Var_Start,
               Var_End,
               Success);

            if Success then
               if Add_New_Line then
                  Append (Result, ASCII.LF & ASCII.LF);
               end if;

               Append
                 (Result,
                  "<b>Type: </b>"
                  & Escape_Text (Buffer (Var_Start.Index .. Var_End.Index)));
            end if;
         end;
      end if;

      return To_String (Result);
   end Get_Documentation;

   ------------------
   -- Get_Language --
   ------------------

   function Get_Language
     (Tree : access Unknown_Tree_Language) return Language_Access
   is
      pragma Unreferenced (Tree);
   begin
      return Unknown_Lang;
   end Get_Language;

end Language.Tree;
