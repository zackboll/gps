-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                        Copyright (C) 2002                         --
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
-- a copy of the GNU General Public License along with this program; --
-- if not,  write to the  Free Software Foundation, Inc.,  59 Temple --
-- Place - Suite 330, Boston, MA 02111-1307, USA.                    --
-----------------------------------------------------------------------

with Glib; use Glib;
with Gtk; use Gtk;
with Gtk.Stock;       use Gtk.Stock;
with Gdk.Types;       use Gdk.Types;
with Gtk.Widget;      use Gtk.Widget;
with Gtk.Enums;       use Gtk.Enums;
with Gtkada.Handlers; use Gtkada.Handlers;
with Callbacks_Codefix_Interface; use Callbacks_Codefix_Interface;
with Glide_Intl;      use Glide_Intl;
with Final_Window_Pkg.Callbacks; use Final_Window_Pkg.Callbacks;

package body Final_Window_Pkg is

procedure Gtk_New (Final_Window : out Final_Window_Access) is
begin
   Final_Window := new Final_Window_Record;
   Final_Window_Pkg.Initialize (Final_Window);
end Gtk_New;

procedure Initialize (Final_Window : access Final_Window_Record'Class) is
   pragma Suppress (All_Checks);
begin
   Gtk.Dialog.Initialize (Final_Window);
   Set_Title (Final_Window, -"No more errors");
   Set_Policy (Final_Window, True, True, False);
   Set_Position (Final_Window, Win_Pos_Mouse);
   Set_Modal (Final_Window, True);

   Final_Window.Dialog_Vbox1 := Get_Vbox (Final_Window);
   Set_Homogeneous (Final_Window.Dialog_Vbox1, False);
   Set_Spacing (Final_Window.Dialog_Vbox1, 0);

   Final_Window.Dialog_Action_Area1 := Get_Action_Area (Final_Window);
   Set_Border_Width (Final_Window.Dialog_Action_Area1, 10);
   Set_Homogeneous (Final_Window.Dialog_Action_Area1, True);
   Set_Spacing (Final_Window.Dialog_Action_Area1, 5);

   Gtk_New (Final_Window.Hbuttonbox1);
   Set_Spacing (Final_Window.Hbuttonbox1, 30);
   Set_Layout (Final_Window.Hbuttonbox1, Buttonbox_Spread);
   Set_Child_Size (Final_Window.Hbuttonbox1, 85, 27);
   Set_Child_Ipadding (Final_Window.Hbuttonbox1, 7, 0);
   Pack_Start (Final_Window.Dialog_Action_Area1, Final_Window.Hbuttonbox1, True, True, 0);

   Gtk_New_From_Stock (Final_Window.Final_Validation, Stock_Yes);
   Set_Flags (Final_Window.Final_Validation, Can_Default);
   Widget_Callback.Object_Connect
     (Final_Window.Final_Validation, "clicked",
      On_Final_Validation_Clicked'Access, Final_Window);
   Add (Final_Window.Hbuttonbox1, Final_Window.Final_Validation);

   Gtk_New_From_Stock (Final_Window.Final_Cancel, Stock_No);
   Set_Flags (Final_Window.Final_Cancel, Can_Default);
   Widget_Callback.Object_Connect
     (Final_Window.Final_Cancel, "clicked",
      On_Final_Cancel_Clicked'Access, Final_Window);
   Add (Final_Window.Hbuttonbox1, Final_Window.Final_Cancel);

   Gtk_New (Final_Window.Label4, -("All fixable errors have been scanned. Confirm changes ?"));
   Set_Alignment (Final_Window.Label4, 0.5, 0.5);
   Set_Padding (Final_Window.Label4, 0, 0);
   Set_Justify (Final_Window.Label4, Justify_Center);
   Set_Line_Wrap (Final_Window.Label4, False);
   Pack_Start (Final_Window.Dialog_Vbox1, Final_Window.Label4, True, False, 0);

end Initialize;

end Final_Window_Pkg;
