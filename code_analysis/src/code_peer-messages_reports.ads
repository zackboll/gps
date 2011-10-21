-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                  Copyright (C) 2008-2011, AdaCore                 --
--                                                                   --
-- GPS is Free  software;  you can redistribute it and/or modify  it --
-- under the terms of the GNU General Public License as published by --
-- the Free Software Foundation; either version 2 of the License, or --
-- (at your option) any later version.                               --
--                                                                   --
-- This program is  distributed in the hope that it will be  useful, --
-- but  WITHOUT ANY WARRANTY;  without even the  implied warranty of --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU --
-- General Public License for more details. You should have received --
-- a copy of the GNU General Public License along with this program; --
-- if not,  write to the  Free Software Foundation, Inc.,  59 Temple --
-- Place - Suite 330, Boston, MA 02111-1307, USA.                    --
-----------------------------------------------------------------------

with Glib;
with Gtk.Box;
private with Gtk.Tree_Model_Filter;
private with Gtk.Tree_Model_Sort;
private with Gtk.Tree_View;

with GPS.Kernel.Modules;

with Code_Analysis;
private with Code_Peer.Entity_Messages_Models;
private with Code_Peer.Messages_Summary_Models;
private with Code_Peer.Categories_Criteria_Editors;

package Code_Peer.Messages_Reports is

   type Messages_Report_Record is new Gtk.Box.Gtk_Vbox_Record with private;

   type Messages_Report is access all Messages_Report_Record'Class;

   procedure Gtk_New
     (Report : out Messages_Report;
      Kernel : GPS.Kernel.Kernel_Handle;
      Module : GPS.Kernel.Modules.Module_ID;
      Tree   : Code_Analysis.Code_Analysis_Tree);

   procedure Initialize
     (Self   : access Messages_Report_Record'Class;
      Kernel : GPS.Kernel.Kernel_Handle;
      Module : GPS.Kernel.Modules.Module_ID;
      Tree   : Code_Analysis.Code_Analysis_Tree);

   function Get_Selected_Project
     (Self : access Messages_Report_Record'Class)
      return Code_Analysis.Project_Access;

   function Get_Selected_File
     (Self : access Messages_Report_Record'Class)
      return Code_Analysis.File_Access;

   function Get_Selected_Subprogram
     (Self : access Messages_Report_Record'Class)
      return Code_Analysis.Subprogram_Access;

   procedure Update_Criteria
     (Self     : access Messages_Report_Record'Class;
      Criteria : in out Code_Peer.Message_Filter_Criteria);

   procedure Update (Self : access Messages_Report_Record'Class);

   Signal_Activated        : constant Glib.Signal_Name;
   Signal_Criteria_Changed : constant Glib.Signal_Name;

private

   type Messages_Report_Record is new Gtk.Box.Gtk_Vbox_Record with record
      Kernel              : GPS.Kernel.Kernel_Handle;
      Tree                : Code_Analysis.Code_Analysis_Tree;
      Analysis_Model      :
        Code_Peer.Messages_Summary_Models.Messages_Summary_Model;
      Analysis_Sort_Model : Gtk.Tree_Model_Sort.Gtk_Tree_Model_Sort;
      Analysis_View       : Gtk.Tree_View.Gtk_Tree_View;
      Messages_Model      :
        Code_Peer.Entity_Messages_Models.Entity_Messages_Model;
      Messages_Filter     : Gtk.Tree_Model_Filter.Gtk_Tree_Model_Filter;
      Messages_View       : Gtk.Tree_View.Gtk_Tree_View;
      General_Categories_Editor :
        Code_Peer.Categories_Criteria_Editors.Categories_Criteria_Editor;
      Warning_Categories_Editor :
        Code_Peer.Categories_Criteria_Editors.Categories_Criteria_Editor;
      Check_Categories_Editor :
        Code_Peer.Categories_Criteria_Editors.Categories_Criteria_Editor;

      Show_Lifeage        : Lifeage_Kinds_Flags;
      Show_Ranking        : Message_Ranking_Level_Flags;
   end record;

   Signal_Activated        : constant Glib.Signal_Name := "activated";
   Signal_Criteria_Changed : constant Glib.Signal_Name := "criteria_changed";

end Code_Peer.Messages_Reports;