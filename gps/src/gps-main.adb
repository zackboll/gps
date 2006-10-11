-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                     Copyright (C) 2001-2006                       --
--                             AdaCore                               --
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

with Ada.Exceptions;            use Ada.Exceptions;
with Ada.Strings.Fixed;         use Ada.Strings.Fixed;
with Ada.Text_IO;               use Ada.Text_IO;
with GNAT.Command_Line;         use GNAT.Command_Line;
with GNAT.Directory_Operations; use GNAT.Directory_Operations;
pragma Warnings (Off);
with GNAT.Expect.TTY.Remote;    use GNAT.Expect.TTY.Remote;
pragma Warnings (On);
with GNAT.OS_Lib;               use GNAT.OS_Lib;

with Gdk.Pixbuf;                use Gdk.Pixbuf;

with Glib.Error;                use Glib.Error;
with Glib.Messages;             use Glib.Messages;
with Glib.Object;               use Glib.Object;
with Glib.Properties;           use Glib.Properties;
with Glib.Values;               use Glib.Values;

with Gtk;                       use Gtk;
with Gtk.Arguments;             use Gtk.Arguments;
with Gtk.Enums;                 use Gtk.Enums;
with Gtk.Handlers;              use Gtk.Handlers;
with Gtk.Image;                 use Gtk.Image;
with Gtk.Main;                  use Gtk.Main;
with Gtk.Rc;
with Gtk.Window;                use Gtk.Window;

with Gtk_Utils;                 use Gtk_Utils;
with Gtkada.Dialogs;            use Gtkada.Dialogs;
with Gtkada.Intl;
with GPS.Intl;                  use GPS.Intl;
with Gtkada.MDI;                use Gtkada.MDI;

with Config;                    use Config;
with DDE;
with File_Utils;
with GPS.Kernel;                use GPS.Kernel;
with GPS.Kernel.Console;        use GPS.Kernel.Console;
with GPS.Kernel.Contexts;       use GPS.Kernel.Contexts;
with GPS.Kernel.Custom;         use GPS.Kernel.Custom;
with GPS.Kernel.Hooks;          use GPS.Kernel.Hooks;
with GPS.Kernel.MDI;            use GPS.Kernel.MDI;
with GPS.Kernel.Modules;        use GPS.Kernel.Modules;
with GPS.Kernel.Preferences;    use GPS.Kernel.Preferences;
with GPS.Kernel.Project;        use GPS.Kernel.Project;
with GPS.Kernel.Remote;
with GPS.Kernel.Scripts;        use GPS.Kernel.Scripts;
with GPS.Kernel.Standard_Hooks; use GPS.Kernel.Standard_Hooks;
with GPS.Kernel.Task_Manager;   use GPS.Kernel.Task_Manager;
with GPS.Kernel.Timeout;        use GPS.Kernel.Timeout;
with GPS.Main_Window;
with GPS.Menu;
with OS_Utils;                  use OS_Utils;
with Projects.Editor;           use Projects.Editor;
with Projects.Registry;         use Projects;
with Remote_Servers;            use Remote_Servers;
with Remote_Views;
with Src_Editor_Box;            use Src_Editor_Box;
with String_Utils;
with Task_Manager;
with Traces;                    use Traces;
with VFS;                       use VFS;
with Welcome;                   use Welcome;
with Welcome_Page;              use Welcome_Page;

--  Modules registered by GPS

with Action_Editor;
with Ada_Module;
with Aliases_Module;
with Aunit_Module;
with Bookmark_Views;
with Browsers.Call_Graph;
with Browsers.Dependency_Items;
with Browsers.Entities;
with Browsers.Projects;
with Revision_Views;
with Buffer_Views;
with Builder_Module;
with Call_Graph_Views;
with Casing_Exceptions;
with Clipboard_Views;
with Codefix_Module;
with Cpp_Module;
with Custom_Module;
with Docgen_Module;
with External_Editor_Module;
with GPS.Location_View;
with GVD_Module;
with Help_Module;
with KeyManager_Module;
with Navigation_Module;
with Outline_View;
with Project_Explorers;
with Project_Explorers_Files;
with Project_Properties;
with Project_Viewers;
with Python_Module;
with Refactoring_Module;
with Remote_Sync_Module;
with Scenario_Views;
with Shell_Script;
with Socket_Module;
with Src_Editor_Module;
with Theme_Manager_Module;
with VCS.ClearCase;
with VCS_Module;
with VFS_Module;
with Vdiff2_Module;
with Vdiff_Module;
with Vsearch;

procedure GPS.Main is
   use GPS.Main_Window;

   Me        : constant Debug_Handle := Create ("GPS");
   Gtk_Trace : constant Debug_Handle := Create ("Gtk+");
   Pid_Image : constant String := String_Utils.Image (Get_Process_Id);

   Docgen_Trace           : constant Debug_Handle :=
                              Create ("MODULE.Docgen", On);
   Refactor_Trace         : constant Debug_Handle :=
                              Create ("MODULE.Refactor", On);
   Python_Trace           : constant Debug_Handle :=
                              Create ("MODULE.Python", On);
   Call_Graph_Trace       : constant Debug_Handle :=
                              Create ("MODULE.Call_Graph", On);
   Dependency_Trace       : constant Debug_Handle :=
                              Create ("MODULE.Dependency", On);
   Project_Browser_Trace  : constant Debug_Handle :=
                              Create ("MODULE.Project_Browser", On);
   Entities_Browser_Trace : constant Debug_Handle :=
                              Create ("MODULE.Entities_Browser", On);
   Revision_Views_Trace   : constant Debug_Handle :=
                               Create ("MODULE.Revision_Views", On);
   Aliases_Trace          : constant Debug_Handle :=
                              Create ("MODULE.Aliases", On);
   Project_Explorer_Trace : constant Debug_Handle :=
                              Create ("MODULE.Project_Explorer", On);
   Files_Explorer_Trace   : constant Debug_Handle :=
                              Create ("MODULE.Files_Explorer", On);
   External_Editor_Trace  : constant Debug_Handle :=
                              Create ("MODULE.External_Editor", On);
   VCS_Trace              : constant Debug_Handle := Create ("MODULE.VCS", On);
   Custom_Trace           : constant Debug_Handle :=
                              Create ("MODULE.Custom", On);
   Action_Editor_Trace    : constant Debug_Handle :=
                              Create ("MODULE.Action_Editor", Off);
   Codefix_Trace          : constant Debug_Handle :=
                                       Create ("MODULE.Codefix", On);
   Builder_Trace          : constant Debug_Handle :=
                                       Create ("MODULE.Builder", On);
   GVD_Trace              : constant Debug_Handle :=
                                       Create ("MODULE.GVD", On);
   Aunit_Trace            : constant Debug_Handle :=
                                       Create ("MODULE.Aunit", On);
   VFS_Trace              : constant Debug_Handle := Create ("MODULE.VFS", On);
   Help_Trace             : constant Debug_Handle :=
                                       Create ("MODULE.Help", On);
   Scenario_View_Trace    : constant Debug_Handle :=
                              Create ("MODULE.SCENARIO", On);
   Project_Viewer_Trace   : constant Debug_Handle :=
                              Create ("MODULE.Project_Viewer", On);
   Project_Properties_Trace : constant Debug_Handle :=
                                Create ("MODULE.Project_Properties", On);
   CPP_Trace              : constant Debug_Handle := Create ("MODULE.CPP", On);
   Outline_View_Trace     : constant Debug_Handle :=
                              Create ("MODULE.Outline", On);
   Call_Graph_View_Trace  : constant Debug_Handle :=
                              Create ("MODULE.Call_Graph_View", On);
   Clipboard_View_Trace   : constant Debug_Handle :=
                              Create ("MODULE.Clipboard_Vview", On);
   Remote_View_Trace      : constant Debug_Handle :=
                              Create ("MODULE.Remote_View", On);

   GPS_Started_Hook       : constant String := "gps_started";

   --  If any of these debug handles is active, the correponding module
   --  is loaded.

   subtype String_Access is GNAT.OS_Lib.String_Access;

   GPS_Main               : GPS_Window;
   Directory              : Dir_Type;
   Str                    : String (1 .. 1024);
   Last                   : Natural;
   Home                   : String_Access;
   Project_Name           : Virtual_File := VFS.No_File;
   Prefix                 : String_Access;
   Dir                    : String_Access;
   Batch_File             : String_Access;
   Batch_Script           : String_Access;
   Tools_Host             : String_Access;
   Target                 : String_Access;
   Protocol               : String_Access;
   Debugger_Name          : String_Access;
   Startup_Dir            : String_Access;
   About_Contents         : GNAT.OS_Lib.String_Access;
   Splash                 : Gtk_Window;
   User_Directory_Existed : Boolean;
   Cleanup_Needed         : Boolean := False;
   Unexpected_Exception   : Boolean := False;
   Splash_Timeout         : Glib.Guint32 := 1000;
   Server_Mode            : Boolean := False;
   Port_Number            : Natural := 0;
   Hide_GPS               : Boolean := False;
   Program_Args           : String_Access;

   Started                : Boolean := False;
   --  Whether the main loop is started

   Exiting                : Boolean := False;
   --  Whether GPS is exiting

   Button                 : Message_Dialog_Buttons;
   Result                 : Boolean;
   Timeout_Id             : Timeout_Handler_Id;
   pragma Unreferenced (Button, Result, Timeout_Id);

   procedure Init_Settings;
   --  Set up environment for GPS

   procedure Main_Processing;
   --  Main GPS processing (launches a gtk+ main loop and handle unexpected
   --  exceptions).

   procedure Do_Cleanups;
   --  Perform clean ups and automatic saving before exiting.

   procedure Parse_Switches;
   --  Parse command line switches

   procedure Display_Splash_Screen;
   --  Display the GPS splash screen

   function Finish_Setup (Data : Process_Data) return Boolean;
   --  Finish the set up of GPS, while the main loop is running.

   function On_GPS_Started return Boolean;
   --  Called when GPS is started and visible on the screen

   procedure Help;
   --  Display help on the standard output

   procedure Ctrl_C_Handler;
   --  Handler for Ctrl-C events

   function Clean_Parameter return String;
   --  Return a clean version of the parameter for command line switches, ie
   --  return the same thing as GNAT.Command_Line.Parameter, but strips the
   --  leading '=' if any, so that users can say '--log-level=4' for instance.

   procedure Set_Main_Title
     (Kernel : access Kernel_Handle_Record'Class;
      Child  : MDI_Child);
   --  Set the title of the main window

   procedure Child_Selected
     (Mdi    : access GObject_Record'Class;
      Params : Glib.Values.GValues;
      Kernel : Kernel_Handle);
   --  Called when a new child is selected

   procedure Title_Changed
     (MDI    : access GObject_Record'Class;
      Child  : Gtk_Args;
      Kernel : Kernel_Handle);
   --  Called when the title of an MDI child has changed

   procedure Execute_Batch (Batch : String; As_File : Boolean);
   --  Execute a batch command (either loading the file Batch if As_File is
   --  true, or as a standard command otherwise).

   procedure Gtk_Log
     (Log_Domain : String;
      Log_Level  : Log_Level_Flags;
      Message    : String);
   --  Log level glib handler for redirecting Gtk+ messages to our log file.

   ---------------------
   -- Clean_Parameter --
   ---------------------

   function Clean_Parameter return String is
      P : constant String := Parameter;
   begin
      if P'Length > 0 and then P (P'First) = '=' then
         return P (P'First + 1 .. P'Last);
      else
         return P;
      end if;
   end Clean_Parameter;

   ---------------------------
   -- Display_Splash_Screen --
   ---------------------------

   procedure Display_Splash_Screen is
      File   : constant String := Format_Pathname
                 (Prefix.all & "/share/gps/gps-splash.png");
      Image  : Gtk_Image;
      Pixbuf : Gdk_Pixbuf;
      Error  : GError;
      FD     : File_Descriptor;

   begin
      if not Hide_GPS
        and then Get_Pref (Splash_Screen)
        and then Is_Regular_File (File)
      then
         FD := Open_Read (File, Binary);

         if About_Contents.all /= "" then
            Splash_Timeout := 4000;
         end if;

         Close (FD);
         Gtk_New (Splash, Window_Popup);
         Set_Property (Splash, Allow_Shrink_Property, False);
         Set_Property (Splash, Allow_Grow_Property, False);
         Set_Position (Splash, Win_Pos_Center);
         Gdk_New_From_File (Pixbuf, File, Error);
         Gtk_New (Image, Pixbuf);
         Unref (Pixbuf);
         Add (Splash, Image);
         Show_All (Splash);
      end if;
   end Display_Splash_Screen;

   -------------
   -- Gtk_Log --
   -------------

   procedure Gtk_Log
     (Log_Domain : String;
      Log_Level  : Log_Level_Flags;
      Message    : String) is
   begin
      if Log_Domain = "" then
         --  Ignore this message, to avoid generating too much noise
         return;
      end if;

      if (Log_Level and Log_Level_Critical) /= 0 then
         Trace (Gtk_Trace, Log_Domain & "-CRITICAL: " & Message);
      elsif (Log_Level and Log_Level_Warning) /= 0 then
         Trace (Gtk_Trace, Log_Domain & "-WARNING: " & Message);
      else
         Trace (Gtk_Trace, Log_Domain & "-MISC: " & Message);
      end if;
   end Gtk_Log;

   -------------------
   -- Init_Settings --
   -------------------

   procedure Init_Settings is
      Dir_Created : Boolean := False;
      File        : File_Type;
      Charset     : String_Access;
      Make_Root   : String_Access;
      Python_Home : String_Access;
      Tmp         : String_Access;
      Ignored     : Log_Handler_Id;
      pragma Unreferenced (Ignored);

   begin
      OS_Utils.Install_Ctrl_C_Handler (Ctrl_C_Handler'Unrestricted_Access);
      Projects.Registry.Initialize;

      --  Reset the environment that was set before GPS was started (since
      --  starting GPS will generally imply a change in LD_LIBRARY_PATH and
      --  PATH to point to the right libraries

      Tmp := Getenv ("GPS_STARTUP_LD_LIBRARY_PATH");
      if Tmp.all /= "" then
         Setenv ("LD_LIBRARY_PATH", Tmp.all);
      end if;
      Free (Tmp);

      Tmp := Getenv ("GPS_STARTUP_PATH");
      if Tmp.all /= "" then
         Setenv ("PATH", Tmp.all);
      end if;
      Free (Tmp);

      --  Reset any artificial memory limit

      Setenv ("GNAT_MEMORY_LIMIT", "");

      Charset := Getenv ("CHARSET");

      if Charset.all = "" then
         --  Gtk+ does not like if CHARSET is not defined.
         --  Need to set CHARSET *before* calling Gtk.Main.Init, so cannot
         --  use Get_Pref here

         Setenv ("CHARSET", "ISO-8859-1");
      end if;

      Free (Charset);
      Startup_Dir := new String'(Get_Current_Dir);

      --  Set the TERM variable to a dummy value, since we only know how to
      --  handle simple terminals

      Setenv ("TERM", "dumb");

      Home := Getenv ("GPS_HOME");

      if Home.all = "" then
         Free (Home);
         Home := Getenv ("HOME");
      end if;

      if Home.all = "" then
         Free (Home);
         Home := Getenv ("USERPROFILE");
      end if;

      if Home'Length > 2
        and then Home (Home'First) = '%'
        and then Home (Home'Last) = '%'
      then
         --  Some Windows systems set %HOME% to another env variable, e.g.
         --  %USERPROFILE%

         Tmp := Home;
         Home := Getenv (Tmp (Tmp'First + 1 .. Tmp'Last - 1));
         Free (Tmp);
      end if;

      if Home.all = "" then
         Free (Home);

         if Directory_Separator = '\' then
            Home := new String'("c:\");
         else
            Home := new String'("/");
         end if;
      end if;

      Dir := new String'(File_Utils.Name_As_Directory (Home.all) & ".gps");

      Prefix := Getenv ("GPS_ROOT");

      if Prefix.all = "" then
         Free (Prefix);
         Prefix := new String'(Executable_Location);

         if Prefix.all = "" then
            Free (Prefix);
            Prefix := new String'(Config.Prefix);
         end if;
      end if;

      --  Parse the config files
      Gtk.Rc.Add_Default_File
        (Format_Pathname (Prefix.all & "/etc/gps/gtkrc"));
      Gtk.Rc.Add_Default_File
        (File_Utils.Name_As_Directory (Dir.all) & "gtkrc");

      Gtk.Main.Init;

      --  Define MAKE_ROOT if needed, so that the generated makefiles can find
      --  Makefile.prolog and Makefile.generic

      Make_Root := Getenv ("MAKE_ROOT");

      if Make_Root.all = "" then
         Setenv ("MAKE_ROOT", Prefix.all);
         Free (Make_Root);
      end if;

      Python_Home := Getenv ("PYTHONHOME");

      if Python_Home.all = "" then
         Setenv ("PYTHONHOME", Prefix.all);
         Free (Python_Home);
      end if;

      --  Python startup path

      Tmp := Getenv ("PYTHONPATH");
      if Tmp.all = "" then
         Setenv ("PYTHONPATH",
                 Format_Pathname (Prefix.all & "/share/gps/python"));
      else
         Setenv ("PYTHONPATH", Tmp.all & Path_Separator &
                 Format_Pathname (Prefix.all & "/share/gps/python"));
      end if;

      Free (Tmp);

      Gtkada.Intl.Setlocale;
      Gtkada.Intl.Bind_Text_Domain
        ("gps", Format_Pathname (Prefix.all & "/share/locale"));
      Gtkada.Intl.Text_Domain ("gps");

      --  Redirect all default Gtk+ logs to our own trace mechanism

      Ignored := Log_Set_Handler
        ("", Log_Level_Mask, Gtk_Log'Unrestricted_Access);
      Ignored := Log_Set_Handler
        ("GLib", Log_Level_Mask, Gtk_Log'Unrestricted_Access);
      Ignored := Log_Set_Handler
        ("GLib-GObject", Log_Level_Mask, Gtk_Log'Unrestricted_Access);
      Ignored := Log_Set_Handler
        ("Pango", Log_Level_Mask, Gtk_Log'Unrestricted_Access);
      Ignored := Log_Set_Handler
        ("Atk", Log_Level_Mask, Gtk_Log'Unrestricted_Access);
      Ignored := Log_Set_Handler
        ("GdkPixbuf", Log_Level_Mask, Gtk_Log'Unrestricted_Access);
      Ignored := Log_Set_Handler
        ("Gdk", Log_Level_Mask, Gtk_Log'Unrestricted_Access);
      Ignored := Log_Set_Handler
        ("Gtk", Log_Level_Mask, Gtk_Log'Unrestricted_Access);

      declare
         Plug_Ins : constant String :=
                      File_Utils.Name_As_Directory (Dir.all) & "plug-ins";
      begin
         User_Directory_Existed := Is_Directory (Dir.all);

         if not User_Directory_Existed then
            Make_Dir (Dir.all);
            Button := Message_Dialog
              ((-"Created config directory ") & Dir.all,
               Information, Button_OK, Justification => Justify_Left);
            Dir_Created := True;

            --  Create a default configuration file for the traces.
            --  This should be left while GPS is considered as not fully
            --  stable.

            Create
              (File,
               Name => File_Utils.Name_As_Directory (Dir.all)
                 & "traces.cfg");
            Put_Line (File, ">log.$$");
            Put_Line (File, "+");
            Put_Line (File, "DEBUG.COLORS=no");
            Put_Line (File, "DEBUG.ABSOLUTE_TIME=yes");
            Put_Line (File, "DEBUG.ELAPSED_TIME=no");
            Put_Line (File, "DEBUG.STACK_TRACE=no");
            Put_Line (File, "DEBUG.LOCATION=no");
            Put_Line (File, "DEBUG.ENCLOSING_ENTITY=no");
            Close (File);
         end if;

         if not Is_Directory (Plug_Ins) then
            Make_Dir (Plug_Ins);

            if not Dir_Created then
               Button := Message_Dialog
                 ((-"Created plug-ins directory ") & Plug_Ins,
                  Information, Button_OK, Justification => Justify_Left);
            end if;
         end if;

      exception
         when Directory_Error =>
            Button := Message_Dialog
              ((-"Cannot create config directory ") & Dir.all & ASCII.LF &
               (-"Exiting..."),
               Error, Button_OK,
               Justification => Justify_Left);
            OS_Exit (1);
      end;

      if not Is_Directory (Get_Tmp_Dir) then
         Button := Message_Dialog
           ((-"Cannot access temporary directory ") & Get_Tmp_Dir,
            Error, Button_OK, Justification => Justify_Left);
         OS_Exit (1);
      end if;

      --  Initialize the traces

      Traces.Parse_Config_File
        (Default => File_Utils.Name_As_Directory (Dir.all) & "traces.cfg");
      Trace (Me, "GPS " & Config.Version & " (" & Config.Source_Date &
             ") hosted on " & Config.Target);
      Trace (Me, "Gtk+ static version: "
             & String_Utils.Image (Integer (Gtk.Major_Version)) & '.'
             & String_Utils.Image (Integer (Gtk.Minor_Version)) & '.'
             & String_Utils.Image (Integer (Gtk.Micro_Version)));
      Trace (Me, "Gtk+ dynamic version: "
             & String_Utils.Image (Gtk_Major_Version) & '.'
             & String_Utils.Image (Gtk_Minor_Version) & '.'
             & String_Utils.Image (Gtk_Micro_Version));

      Gtk_New (GPS_Main, Dir.all, Prefix.all);

      About_Contents := Read_File
        (Format_Pathname (Prefix.all & "/share/gps/about.txt"));

      if About_Contents = null then
         About_Contents := new String'("");
      end if;

      if Is_Regular_File
        (Format_Pathname (Prefix.all & "/share/gps/gps-pro.txt"))
      then
         GPS_Main.Public_Version := False;
      end if;

      Reset_Title (GPS_Main);

      GPS.Menu.Register_Common_Menus (GPS_Main.Kernel);

      Kernel_Callback.Connect
        (Get_MDI (GPS_Main.Kernel), "child_selected",
         Child_Selected'Unrestricted_Access, GPS_Main.Kernel);
      Kernel_Callback.Connect
        (Get_MDI (GPS_Main.Kernel), "child_title_changed",
         Title_Changed'Unrestricted_Access, GPS_Main.Kernel);

      DDE.Register_DDE_Server (GPS_Main.Kernel);
      Parse_Switches;
      Display_Splash_Screen;

      if Splash = null then
         Timeout_Id := Process_Timeout.Add
           (1, Finish_Setup'Unrestricted_Access,
            (GPS_Main.Kernel, null, null, null, null, null, False));
      else
         Timeout_Id := Process_Timeout.Add
           (Splash_Timeout, Finish_Setup'Unrestricted_Access,
            (GPS_Main.Kernel, null, null, null, null, null, False));
      end if;
   end Init_Settings;

   --------------------
   -- Parse_Switches --
   --------------------

   procedure Parse_Switches is
   begin
      Initialize_Option_Scan;
      loop
         case Getopt ("-version -help P: -server= -hide " &
                      "-debug? -debugger= -host= -target= -load= -eval= " &
                      "-readonly -traceoff= -traceon= -tracefile= -tracelist")
         is
            -- long option names --
            when '-' =>
               case Full_Switch (Full_Switch'First + 1) is
                  --  --version
                  when 'v' =>
                     if Config.Can_Output then
                        Put_Line (GPS_Name (GPS_Main) & " version " &
                                  Config.Version & " (" &
                                  Config.Source_Date & ") hosted on " &
                                  Config.Target);
                     else
                        Button := Message_Dialog
                          (GPS_Name (GPS_Main) & " version " &
                           Config.Version & " (" &
                           Config.Source_Date & ") hosted on " & Config.Target,
                           Information, Button_OK,
                           Title         => -"Version",
                           Justification => Justify_Left);
                     end if;

                     OS_Exit (0);

                  when 'h' =>
                     if Full_Switch = "-help" then
                        --  --help
                        Help;
                        OS_Exit (0);

                     elsif Full_Switch = "-host" then
                        --  --host
                        Free (Tools_Host);
                        Tools_Host := new String'(Parameter);

                     else
                        --  --hide

                        Hide_GPS := True;
                     end if;

                  --  --load

                  when 'l' =>
                     Free (Batch_File);
                     Batch_File := new String'(Parameter);

                  when 'd' =>
                     --  --debug
                     if Full_Switch = "-debug" then
                        Free (Program_Args);
                        Program_Args := new String'(Clean_Parameter);

                     else
                        --  --debugger
                        Free (Debugger_Name);
                        Debugger_Name := new String'(Parameter);

                        if Program_Args = null then
                           --  --debugger implies --debug
                           Program_Args := new String'("");
                        end if;
                     end if;

                  --  --eval

                  when 'e' =>
                     Free (Batch_Script);
                     Batch_Script := new String'(Parameter);

                  --  --readonly

                  when 'r' =>
                     Src_Editor_Box.Read_Only_By_Default;

                  --  --server

                  when 's' =>
                     begin
                        Port_Number := Natural'Value (Parameter);
                        Server_Mode := True;
                     exception
                        when Constraint_Error =>
                           raise Invalid_Switch;
                     end;

                  when 't' =>
                     if Full_Switch = "-target" then
                        declare
                           Param  : constant String := Parameter;
                           Column : constant Natural :=
                             Ada.Strings.Fixed.Index
                               (Param, ":", Ada.Strings.Backward);

                        begin
                           --  Param should be of the form target:protocol

                           if Column = 0 then
                              raise Invalid_Switch;
                           end if;

                           Free (Target);
                           Free (Protocol);
                           Target   :=
                             new String '(Param (Param'First .. Column - 1));
                           Protocol :=
                             new String '(Param (Column + 1 .. Param'Last));
                        end;

                     elsif Full_Switch = "-traceon" then
                        Set_Active (Create (Parameter), True);

                     elsif Full_Switch = "-traceoff" then
                        Set_Active (Create (Parameter), False);

                     elsif Full_Switch = "-tracefile" then
                        Traces.Parse_Config_File (Filename => Parameter);

                     elsif Full_Switch = "-tracelist" then
                        Traces.Show_Configuration
                          (Ada.Text_IO.Put_Line'Access);
                        OS_Exit (0);
                     end if;

                  when others =>
                     null;
               end case;

            when 'P' =>
               Project_Name := Create (Normalize_Pathname (Parameter));

               if not Is_Regular_File (Project_Name) then
                  if Is_Regular_File
                    (Full_Name (Project_Name).all & Project_File_Extension)
                  then
                     Project_Name := Create
                       (Full_Name (Project_Name).all & Project_File_Extension);
                  else
                     Project_Name := VFS.No_File;
                  end if;
               end if;

               if Project_Name /= VFS.No_File then
                  Trace (Me, "Found project: " & Full_Name (Project_Name).all);
               end if;

            when ASCII.NUL =>
               exit;

            when others =>
               null;
         end case;
      end loop;

   exception
      when Invalid_Switch | GNAT.Command_Line.Invalid_Parameter =>
         if Config.Can_Output then
            Put_Line ("Invalid command line");
         end if;

         Help;
         OS_Exit (1);
   end Parse_Switches;

   ----------
   -- Help --
   ----------

   procedure Help is
      use ASCII;
      Help_String : constant String :=
        GPS_Name (GPS_Main) & " " & Config.Version & " (" &
        Config.Source_Date & ")" &
        (-", the GNAT Programming Studio.") & LF
        & (-"Usage:") & LF
        & (-"   gps [options] [-Pproject-file] [source1] [source2] ...") & LF
        & ("source1, source2,...") & LF
        & (-"    Name of files to load. Start with '=' to load from project")
        & LF
        & (-"Options:") & LF
        & (-"   --help              Show this help message and exit") & LF
        & (-"   --version           Show the GPS version and exit") & LF
        & (-"   --debug[=program]   Start a debug session") & LF
        & (-"   --debugger debugger Specify the debugger's command line") & LF
        & (-"   --hide              Hide GPS main window") & LF
        & (-"   --host=tools_host   Use tools_host to launch tools (e.g. gdb)")
        & LF
        & (-("   --target=TARG:PRO   Load program on machine TARG using"
             & " protocol PRO")) & LF
        & (-"   --load=lang:file    Execute an external file written") & LF
        & (-"                       in the language lang") & LF
        & (-"   --eval=lang:cmd     Execute a command written in the") & LF
        & (-"                       language lang. This is executed") & LF
        & (-"                       before the --load command") & LF
        & (-"   --readonly          Open all files in read-only mode") & LF
        & (-"   --server=port       Start GPS in server mode, opening a") & LF
        & (-"                       socket on the given port") & LF
        & (-"   --traceon=stream    Activate traces for a specific") & LF
        & (-"                       debug stream") & LF
        & (-"   --traceoff=stream   Disable traces for a specific") & LF
        & (-"                       debug stream") & LF
        & (-"   --tracefile=file    Load traces configuration from file");

   begin
      if Config.Can_Output then
         Put_Line (Help_String);
      else
         Button := Message_Dialog
           (Help_String,
            Information, Button_OK,
            Title         => -"Help",
            Justification => Justify_Left);
      end if;
   end Help;

   --------------------
   -- Ctrl_C_Handler --
   --------------------

   procedure Ctrl_C_Handler is
   begin
      --  Ignore Ctrl-C events

      null;
   end Ctrl_C_Handler;

   -------------------
   -- Execute_Batch --
   -------------------

   procedure Execute_Batch (Batch : String; As_File : Boolean) is
      Executed : Boolean := False;
      Script   : Scripting_Language;
      Errors   : Boolean;
   begin
      Trace (Me, "Execute_Batch: " & Batch);
      for J in Batch'Range loop
         if Batch (J) = ':' then
            Script := Lookup_Scripting_Language
              (GPS_Main.Kernel, Batch (Batch'First .. J - 1));

            if Script = null then
               exit;
            end if;

            if As_File then
               Execute_File
                 (Script   => Script,
                  Filename => Normalize_Pathname
                    (Batch (J + 1 .. Batch'Last), Startup_Dir.all),
                  Errors   => Errors);
            else
               GPS.Kernel.Scripts.Execute_Command
                 (Script   => Script,
                  Command  => Batch (J + 1 .. Batch'Last),
                  Errors   => Errors);
            end if;

            Executed := True;
            exit;
         end if;
      end loop;

      if not Executed then
         if As_File then
            Insert
              (GPS_Main.Kernel,
               -"Language unknown for --load command line switch",
               Mode => Error);
         else
            Insert
              (GPS_Main.Kernel,
               -"Language unknown for --script command line switch",
               Mode => Error);
         end if;
      end if;

   exception
      when E : others =>
         if As_File then
            Insert (GPS_Main.Kernel,
                    -"Error when executing the script for -batch switch",
                    Mode => Error);
         else
            Insert (GPS_Main.Kernel,
                    -"Error when executing the script for --script switch",
                    Mode => Error);
         end if;
         Trace (Exception_Handle,
                "Exception was " & Exception_Information (E));
   end Execute_Batch;

   --------------------
   -- On_GPS_Started --
   --------------------

   function On_GPS_Started return Boolean is
   begin
      Run_Hook (GPS_Main.Kernel, GPS_Started_Hook);
      return False;
   exception
      when E : others =>
         Trace (Exception_Handle,
                "Unexpected exception: " & Exception_Information (E));
         return False;
   end On_GPS_Started;

   ------------------
   -- Finish_Setup --
   ------------------

   function Finish_Setup (Data : Process_Data) return Boolean is
      Auto_Load_Project : Boolean := True;
      File_Opened       : Boolean := False;
      Idle_Id           : Idle_Handler_Id;
      Project           : Projects.Project_Type;
      Screen            : Welcome_Screen;
      Icon              : Gdk_Pixbuf;
      pragma Unreferenced (Data, Idle_Id);

      procedure Setup_Debug;
      --  Load appropriate debugger project and set up debugger-related
      --  properties

      function Setup_Project return Boolean;
      --  When no project has been specified explicitely by the user,
      --  look for a project on the current directory, or use the welcome
      --  dialog
      --  Return False if set up was aborted and GPS should exit.

      procedure Load_Sources;
      --  Load all the source files given on the command line

      -----------------
      -- Setup_Debug --
      -----------------

      procedure Setup_Debug is
      begin
         File_Opened := True;
         Auto_Load_Project := False;

         if Is_Regular_File (Project_Name) then
            --  Do not clear to keep the welcome message on kernel's console
            Load_Project (GPS_Main.Kernel, Project_Name, Clear => False);
            Project := Get_Project (GPS_Main.Kernel);
         else
            Load_Empty_Project (GPS_Main.Kernel);
            Project := Get_Project (GPS_Main.Kernel);
            Set_Status (Project, From_Executable);
         end if;

         --  Project will be overriden when the executable is loaded
         Load_Sources;

         if Debugger_Name /= null then
            Update_Attribute_Value_In_Scenario
              (Project            => Project,
               Scenario_Variables => No_Scenario,
               Attribute          => Debugger_Command_Attribute,
               Value              => Debugger_Name.all);
         end if;

         --  ??? re-enable this...
--           if Tools_Host /= null then
--              Update_Attribute_Value_In_Scenario
--                (Project            => Project,
--                 Scenario_Variables => No_Scenario,
--                 Attribute          => Remote_Host_Attribute,
--                 Value              => Tools_Host.all);
--           end if;

         if Target /= null then
            Update_Attribute_Value_In_Scenario
              (Project            => Project,
               Scenario_Variables => No_Scenario,
               Attribute          => Program_Host_Attribute,
               Value              => Target.all);
         end if;

         if Protocol /= null then
            Update_Attribute_Value_In_Scenario
              (Project            => Project,
               Scenario_Variables => No_Scenario,
               Attribute          => Protocol_Attribute,
               Value              => Protocol.all);
         end if;

         Update_Attribute_Value_In_Scenario
           (Project            => Project,
            Scenario_Variables => No_Scenario,
            Attribute          => Languages_Attribute,
            Values             =>
              (new String'("ada"), new String'("c"), new String'("c++")));

         Set_Project_Modified (Project, False);
         Recompute_View (GPS_Main.Kernel);
      end Setup_Debug;

      -------------------
      -- Setup_Project --
      -------------------

      function Setup_Project return Boolean is
      begin
         Auto_Load_Project := False;
         Open (Directory, Get_Current_Dir);

         loop
            Read (Directory, Str, Last);

            exit when Last = 0;

            if File_Extension (Str (1 .. Last)) = Project_File_Extension then
               if Project_Name = VFS.No_File then
                  Auto_Load_Project := True;
                  Project_Name := Create
                    (Normalize_Pathname (Str (1 .. Last),
                     Resolve_Links => False));
               else
                  Auto_Load_Project := False;
                  exit;
               end if;
            end if;
         end loop;

         Close (Directory);

         --  If only one project file was found in the current directory, do
         --  not open the welcome dialog. Likewise if we are loading a script,
         --  or if source files have been specified on the command line.

         if Auto_Load_Project then
            return True;
         end if;

         Load_Sources;

         if File_Opened then
            return True;
         end if;

         if Batch_File /= null then
            Load_Default_Project
              (GPS_Main.Kernel, Get_Current_Dir,
               Load_Default_Desktop => True,
               Clear                => False);
            return True;
         end if;

         --  Load the project selected by the user

         Gtk_New (Screen, GPS_Main.Kernel, Project_Name);

         --  Remove the splash screen, since it conflicts with the
         --  welcome dialog.

         if Splash /= null then
            Destroy (Splash);
            Splash := null;
         end if;

         --  If the user wants to quit immediately, so be it

         case Run_Welcome (Screen) is
            when Quit_GPS =>
               Destroy (Screen);
               Gtk.Main.Main_Quit;
               return False;

            when Project_Loaded =>
               --  Desktop was already loaded when the project itself
               --  was loaded.
               null;
         end case;

         Destroy (Screen);
         return True;
      end Setup_Project;

      ------------------
      -- Load_Sources --
      ------------------

      procedure Load_Sources is
         New_Dir : constant String := Get_Current_Dir;
      begin
         --  Temporarily restore start-up dir, so that relative paths are
         --  properly computed

         Change_Dir (Startup_Dir.all);

         loop
            declare
               S : constant String := Get_Argument (Do_Expansion => True);
            begin
               exit when S = "";

               --  If no project has been loaded yet, load a default project
               --  and desktop before opening source editors.

               if not Auto_Load_Project and then not File_Opened then
                  Load_Default_Project
                    (GPS_Main.Kernel, Get_Current_Dir,
                     Load_Default_Desktop => True,
                     Clear                => False);
               end if;

               if S (S'First) = '=' then
                  Open_File_Editor
                    (GPS_Main.Kernel,
                     Create (S (S'First + 1 .. S'Last),
                             GPS_Main.Kernel,
                             Use_Source_Path => True,
                             Use_Object_Path => False));
               else
                  Open_File_Editor
                    (GPS_Main.Kernel,
                     Create (S,
                             GPS_Main.Kernel,
                             Use_Source_Path => False,
                             Use_Object_Path => False));
               end if;

               File_Opened := True;
            end;
         end loop;

         Change_Dir (New_Dir);

         --  Load a dummy project, in case the wizard needs to be launched.

         if not Auto_Load_Project and then not File_Opened then
            Load_Empty_Project (GPS_Main.Kernel);
         end if;
      end Load_Sources;

   begin
      Cleanup_Needed := True;

      --  Register the default filters, so that other modules can create
      --  contextual menus

      GPS.Kernel.Contexts.Register_Default_Filters (GPS_Main.Kernel);

      --  Register this module first, in case someone needs to print a message
      --  in the console right away

      GPS.Kernel.Console.Register_Module (GPS_Main.Kernel);

      --  Register this very early so that other modules can access remote
      --  files

      GPS.Kernel.Remote.Register_Module (GPS_Main.Kernel);
      Remote_Sync_Module.Register_Module (GPS_Main.Kernel);

      if Active (Remote_View_Trace) then
         Remote_Views.Register_Module (GPS_Main.Kernel);
      end if;

      --  Register the locations view before all the modules that register a
      --  highlighting category. Otherwise, when loading the desktop, the
      --  locations view might create highligthting with categories that don't
      --  exist.

      GPS.Location_View.Register_Module (GPS_Main.Kernel);

      --  Register all modules (scripting languages must be registered first)

      Shell_Script.Register_Module (GPS_Main.Kernel);

      if Active (Python_Trace) then
         Python_Module.Register_Module (GPS_Main.Kernel);
      end if;

      Register_Default_Script_Commands (GPS_Main.Kernel);

      GPS.Location_View.Register_Commands (GPS_Main.Kernel);

      --  We then must register the keymanager, so that other modules can
      --  register their keys

      KeyManager_Module.Register_Module (GPS_Main.Kernel);
      Register_Keys (GPS_Main);

      --  Register the standard hooks. Other modules were able to connect to
      --  these earlier anyway, but these add shell commands, and therefore
      --  must be loaded after the script modules

      Register_Action_Hooks (GPS_Main.Kernel);
      Register_Standard_Hooks (GPS_Main.Kernel);

      --  Load the theme manager module immediately, so that any customization
      --  file or module can provide its own themes.

      Theme_Manager_Module.Register_Module (GPS_Main.Kernel);

      Vsearch.Register_Module (GPS_Main.Kernel);

      if Active (Help_Trace) then
         Help_Module.Register_Module (GPS_Main.Kernel);
      end if;

      --  Initialize Src_Editor_Module early, since many modules depend
      --  on the editor API, and also during finalization, modules may need
      --  to access marks that are handled by this module.

      Src_Editor_Module.Register_Module (GPS_Main.Kernel);

      if Active (Call_Graph_Trace) then
         Browsers.Call_Graph.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Call_Graph_View_Trace) then
         Call_Graph_Views.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Clipboard_View_Trace) then
         Clipboard_Views.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Dependency_Trace) then
         Browsers.Dependency_Items.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Files_Explorer_Trace) then
         Project_Explorers_Files.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Project_Browser_Trace) then
         Browsers.Projects.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Entities_Browser_Trace) then
         Browsers.Entities.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Revision_Views_Trace) then
         Revision_Views.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Project_Viewer_Trace) then
         Project_Viewers.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Outline_View_Trace) then
         Outline_View.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Project_Explorer_Trace) then
         Project_Explorers.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Project_Properties_Trace) then
         Project_Properties.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Aunit_Trace) then
         Aunit_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Aliases_Trace) then
         Aliases_Module.Register_Module (GPS_Main.Kernel);
      end if;

      KeyManager_Module.Register_Key_Menu (GPS_Main.Kernel);

      if Active (External_Editor_Trace) then
         External_Editor_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Builder_Trace) then
         Builder_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (GVD_Trace) then
         GVD_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Get_Pref (Old_Vdiff) then
         Vdiff_Module.Register_Module (GPS_Main.Kernel);
      else
         Vdiff2_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Scenario_View_Trace) then
         Scenario_Views.Register_Module (GPS_Main.Kernel);
      end if;

      GPS.Kernel.Task_Manager.Register_Module (GPS_Main.Kernel);

      if Active (VCS_Trace) then
         VCS_Module.Register_Module (GPS_Main.Kernel);
         VCS.ClearCase.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (VFS_Trace) then
         VFS_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Codefix_Trace) then
         Codefix_Module.Register_Module (GPS_Main.Kernel);
      end if;

      GPS.Kernel.Preferences.Register_Module (GPS_Main.Kernel);

      if Active (Custom_Trace) then
         Custom_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Refactor_Trace) then
         Refactoring_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Docgen_Trace) then
         Docgen_Module.Register_Module (GPS_Main.Kernel);
      end if;

      --  Register the supported languages and their associated LI handlers

      Ada_Module.Register_Module (GPS_Main.Kernel);

      if Active (CPP_Trace) then
         Cpp_Module.Register_Module (GPS_Main.Kernel);
      end if;

      Casing_Exceptions.Register_Module (GPS_Main.Kernel);

      --  Load these last, since this requires the collaboration of other
      --  modules

      Bookmark_Views.Register_Module (GPS_Main.Kernel);

      Buffer_Views.Register_Module (GPS_Main.Kernel);

      --  Load system files.
      --  This must be done before loading the Navigation module, since that
      --  module relies on icons defined in custom files.

      if Active (Custom_Trace) then
         Load_All_Custom_Files (GPS_Main.Kernel);
      end if;

      Navigation_Module.Register_Module (GPS_Main.Kernel);

      --  Do this after the custom files, since this will override other
      --  The comment above is unfinished ???

      if Active (Action_Editor_Trace) then
         Action_Editor.Register_Module (GPS_Main.Kernel);
      end if;

      if Server_Mode then
         Socket_Module.Register_Module (GPS_Main.Kernel, Port_Number);
      end if;

      --  Load preferences, but only after loading custom files, to make sure
      --  the themes loaded at startup are still overriden by the user's
      --  local choices.

      Load_Preferences (GPS_Main.Kernel);

      --  Create a hook for when GPS is started

      Register_Hook_No_Args (GPS_Main.Kernel, GPS_Started_Hook);

      --  Load the customization files before loading the actual projects,
      --  so that the usual hooks are taken into account right from the
      --  beginning

      if Active (Python_Trace) then
         Python_Module.Load_Python_Startup_Files (GPS_Main.Kernel);
      end if;

      --  Load the custom keys last, so that they override everything else set
      --  so far.
      KeyManager_Module.Load_Custom_Keys (GPS_Main.Kernel);

      --  Set default icon for dialogs and windows
      --  ??? as soon as gdk_pixbuf is modified to derive from Glib.GObject
      --   construct an icon list from gps-icon-16, gps-icon-32 and gps-icon-48
      --   and call Set_Default_Icon_List

      Icon := Render_Icon (GPS_Main, "gps-icon-32", -1);

      if Icon /= null then
         Set_Default_Icon (Icon);
      end if;

      --  Print a welcome message in the console, but before parsing the error
      --  messages, so that these are visible

      Console.Insert
        (GPS_Main.Kernel,
         -"Welcome to " & GPS_Name (GPS_Main) & " " & Config.Version &
         " (" & Config.Source_Date &
         (-") hosted on ") & Config.Target & ASCII.LF &
         (-"the GNAT Programming Studio") & ASCII.LF & About_Contents.all &
         "(c) 2001-2006 AdaCore" & ASCII.LF);
      Free (About_Contents);

      --  We now make sure we have a project loaded, so that opening editors
      --  will work correctly.

      --  If no project has been specified on the command line, try to open
      --  the first one in the current directory (if any).

      if Program_Args /= null then
         --  --debug has been specified
         --  Load project, and set debugger-related project properties

         Setup_Debug;

      elsif Project_Name = VFS.No_File then
         if Server_Mode then
            Auto_Load_Project := True;
            Load_Empty_Project (GPS_Main.Kernel);
            Load_Sources;

         else
            if not Setup_Project then
               return False;
            end if;
         end if;
      end if;

      if Auto_Load_Project and then Project_Name /= VFS.No_File then
         --  Do not clear to keep the welcome message on kernel's console
         Load_Project (GPS_Main.Kernel, Project_Name, Clear => False);
         Load_Sources;
      end if;

      if not File_Opened
        and then not Has_User_Desktop (GPS_Main.Kernel)
      then
         Display_Welcome_Page (GPS_Main.Kernel);
      end if;

      if Splash /= null then
         Destroy (Splash);
      end if;

      --  After loading the project, force remote host assignment if
      --  Tools_Host is not null

      if Tools_Host /= null then
         for S in Distant_Server_Type'Range loop
            GPS.Kernel.Remote.Assign
              (GPS_Main.Kernel, S, Tools_Host.all, Reload_Prj => True);
         end loop;
      end if;

      --  Execute the startup scripts now, even though it is recommended that
      --  they connect to the GPS_Started_Hook if they have graphical actions
      --  to do

      if Batch_Script /= null then
         Execute_Batch (Batch_Script.all, As_File => False);
      end if;

      if Batch_File /= null then
         Execute_Batch (Batch_File.all, As_File => True);
      end if;

      if Program_Args /= null then
         --  Initialize the debugger after having executed scripts if any,
         --  so that it is possible to set up the environment before starting
         --  a debug session.
         GVD_Module.Initialize_Debugger (GPS_Main.Kernel, Program_Args.all);
      end if;

      --  Load the preferences set when creating the kernel.
      --  This needs to be done after all the graphical elements have been
      --  created, to be sure they are realized and will take the preferences
      --  into account.

      Run_Hook (GPS_Main.Kernel, Preferences_Changed_Hook);

      if not Hide_GPS then
         Show (GPS_Main);
      end if;

      Started := True;

      --  Set the title of the GPS window.
      Set_Main_Title
        (GPS_Main.Kernel, Get_Focus_Child (Get_MDI (GPS_Main.Kernel)));

      Idle_Id := Idle_Add (On_GPS_Started'Unrestricted_Access);
      return False;
   end Finish_Setup;

   -------------------
   -- Title_Changed --
   -------------------

   procedure Title_Changed
     (MDI    : access GObject_Record'Class;
      Child  : Gtk_Args;
      Kernel : Kernel_Handle)
   is
      pragma Unreferenced (MDI);
      C : constant MDI_Child := MDI_Child (To_Object (Child, 1));
   begin
      if not Exiting then
         Set_Main_Title (Kernel, C);
      end if;
   end Title_Changed;

   --------------------
   -- Set_Main_Title --
   --------------------

   procedure Set_Main_Title
     (Kernel : access Kernel_Handle_Record'Class;
      Child  : MDI_Child) is
   begin
      if Started then
         if Child = null then
            Reset_Title (GPS_Window (Get_Main_Window (Kernel)));
         else
            Reset_Title
              (GPS_Window (Get_Main_Window (Kernel)),
               Get_Short_Title (Child));
         end if;
      end if;
   end Set_Main_Title;

   --------------------
   -- Child_Selected --
   --------------------

   procedure Child_Selected
     (Mdi    : access GObject_Record'Class;
      Params : Glib.Values.GValues;
      Kernel : Kernel_Handle)
   is
      pragma Unreferenced (Mdi);
      Child : constant MDI_Child := MDI_Child (To_Object (Params, 1));
   begin
      if Exiting then
         return;
      end if;

      Set_Main_Title (Kernel, Child);

      if Started then
         Context_Changed (Kernel);
      end if;

   exception
      when E : others =>
         Trace (Exception_Handle,
                "Unhandled exception: " & Exception_Information (E));
   end Child_Selected;

   ---------------------
   -- Main_Processing --
   ---------------------

   procedure Main_Processing is
      Log_File : aliased String := Get_Home_Dir (GPS_Main.Kernel) & "log";
      Pid_File : aliased String := Log_File & "." & Pid_Image;
      Str      : String_Access;

   begin
      Gtk.Main.Main;
   exception
      when E : others =>
         Unexpected_Exception := True;
         Trace (Exception_Handle,
                "Unhandled exception: " & Exception_Information (E));

         if Is_Regular_File (Pid_File) then
            Str := Pid_File'Unchecked_Access;
         else
            Str := Log_File'Unchecked_Access;
         end if;

         Button := Message_Dialog
           ("Unexpected fatal error, GPS is in an inconsistent state" &
            ASCII.LF & "Please report with contents of " & Str.all &
            ASCII.LF & ASCII.LF &
            "You will be asked to save modified files before GPS exits",
            Error, Button_OK,
            Title         => -"Fatal Error",
            Justification => Justify_Left);
         Result := Save_MDI_Children (GPS_Main.Kernel, Force => False);
   end Main_Processing;

   -----------------
   -- Do_Cleanups --
   -----------------

   procedure Do_Cleanups is
      Kernel   : constant Kernel_Handle := GPS_Main.Kernel;
      Log_File : constant String := Get_Home_Dir (Kernel) & "log";
      Project  : constant Project_Type := Get_Project (Kernel);
      Success  : Boolean;

   begin
      if not Cleanup_Needed then
         return;
      end if;

      Cleanup_Needed := False;
      Exiting := True;

      if Started and then Get_Pref (Save_Desktop_On_Exit) then
         Save_Desktop (Kernel);
      end if;

      if Status (Project) = Default then
         Trace (Me, "Remove default project on disk, no longer used");
         Delete (Project_Path (Project), Success);
      end if;

      --  All tasks should be interrupted before the main window is closed
      --  since they may need to access their consoles.

      Task_Manager.Interrupt_All_Tasks (Get_Task_Manager (Kernel));

      --  Destroy the GUI before the modules, otherwise if some package tries
      --  to access their local module_id, they will generate storage_error.
      --  No module should need to access its GUI anyway when it is destroyed,
      --  since the desktop has already been saved, histories and properties
      --  are handled separately,...
      --  Since the call to destroy below will free the animation at some
      --  point, we no longer want to access/update it past this point.

      GPS_Main.Animation_Image := null;

      Destroy (GPS_Main);

      Free_Modules (Kernel);

      --  Call Handlers_Destroy after Free_Modules and Destroy (GPS),
      --  since some handlers are already disconnected by these functions, and
      --  only Handlers_Destroy know what handlers are still left and need to
      --  be disconnected.

      --  ??? Is this still needed, since we are destroying Kernel anyway
      Handlers_Destroy (Kernel);

      Destroy (Kernel);

      Projects.Registry.Finalize;
      Traces.Finalize;

      GNAT.Expect.TTY.Remote.Close_All;

      --  In case of a normal exit, rename log.<pid> as log to avoid
      --  generating a new log file for each session; this way we still
      --  keep the log file in case of post mortem analysis.
      --  In case of unexpected exit, keep the log file under its original
      --  name, so that it does not get erased by the next session and can
      --  be reported.

      if not Unexpected_Exception
        and then Is_Regular_File (Log_File & "." & Pid_Image)
      then
         Delete_File (Log_File, Success);
         Rename_File (Log_File & "." & Pid_Image, Log_File, Success);
      end if;

      Free (Home);
      Free (Dir);
      Free (Prefix);
      Free (Startup_Dir);
   end Do_Cleanups;

begin
   Init_Settings;
   Main_Processing;
   Do_Cleanups;

exception
   when E : others =>
      Trace (Exception_Handle,
             "Unexpected exception: " & Exception_Information (E));
end GPS.Main;
