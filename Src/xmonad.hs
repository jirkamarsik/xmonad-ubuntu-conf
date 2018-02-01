{-
  This is my xmonad configuration file.
  There are many like it, but this one is mine.

  If you want to customize this file, the easiest workflow goes
  something like this:
    1. Make a small change.
    2. Hit "super-q", which recompiles and restarts xmonad
    3. If there is an error, undo your change and hit "super-q" again to
       get to a stable place again.
    4. Repeat

  Author:     David Brewer
  Repository: https://github.com/davidbrewer/xmonad-ubuntu-conf
-}

import XMonad
import qualified XMonad.Hooks.EwmhDesktops as E
import XMonad.Hooks.SetWMName
import XMonad.Layout.Grid
import XMonad.Layout.ResizableTile
import XMonad.Layout.IM
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Layout.Fullscreen
import XMonad.Util.EZConfig
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.UrgencyHook
import qualified XMonad.StackSet as W
import Data.Ratio ((%))
import System.Taffybar.Hooks.PagerHints (pagerHints)

{-
  Xmonad configuration variables. These settings control some of the
  simpler parts of xmonad's behavior and are straightforward to tweak.
-}

myWorkspaces         = map show [1..9]
myModMask            = mod4Mask         -- changes the mod key to "super"
myFocusedBorderColor = "#ff0000"        -- color of focused border
myNormalBorderColor  = "#cccccc"        -- color of inactive border
myBorderWidth        = 1                -- width of border around windows
myTerminal           = "gnome-terminal" -- which terminal software to use
myIMRosterTitle      = "Buddy List"     -- title of roster on IM workspace
                                        -- use "Buddy List" for Pidgin, but
                                        -- "Contact List" for Empathy



{-
  Layout configuration. In this section we identify which xmonad
  layouts we want to use. I have defined a list of default
  layouts which are applied on every workspace, as well as
  special layouts which get applied to specific workspaces.

  Note that all layouts are wrapped within "avoidStruts". What this does
  is make the layouts avoid the status bar area at the top of the screen.
  Without this, they would overlap the bar. You can toggle this behavior
  by hitting "super-b" (bound to ToggleStruts in the keyboard bindings
  in the next section).
-}

-- Define group of default layouts used on most screens, in the
-- order they will appear.
-- "smartBorders" modifier makes it so the borders on windows only
-- appear if there is more than one visible window.
-- "avoidStruts" modifier makes it so that the layout provides
-- space for the status bar at the top of the screen.
defaultLayouts = smartBorders(avoidStruts(
  -- ResizableTall layout has a large master window on the left,
  -- and remaining windows tile on the right. By default each area
  -- takes up half the screen, but you can resize using "super-h" and
  -- "super-l".
  ResizableTall 1 (3/100) (1/2) []

  -- Mirrored variation of ResizableTall. In this layout, the large
  -- master window is at the top, and remaining windows tile at the
  -- bottom of the screen. Can be resized as described above.
  ||| Mirror (ResizableTall 1 (3/100) (1/2) [])

  -- Full layout makes every window full screen. When you toggle the
  -- active window, it will bring the active window to the front.
  ||| noBorders Full))


-- Here we define some layouts which will be assigned to specific
-- workspaces based on the functionality of that workspace.

-- The chat layout uses the "IM" layout. We have a roster which takes
-- up 1/7 of the screen vertically, and the remaining space contains
-- chat windows which are tiled using the grid layout. The roster is
-- identified using the myIMRosterTitle variable, and by default is
-- configured for Pidgin, so if you're using something else you
-- will want to modify that variable.
chatLayout = avoidStruts $
             withIM (1%7) (Title myIMRosterTitle) $
             GridRatio 1

-- Here we combine our default layouts with our specific, workspace-locked
-- layouts.
myLayouts =
  onWorkspace "7" chatLayout
  $ defaultLayouts


{-
  Custom keybindings. In this section we define a list of relatively
  straightforward keybindings. This would be the clearest place to
  add your own keybindings, or change the keys we have defined
  for certain functions.

  It can be difficult to find a good list of keycodes for use
  in xmonad. I have found this page useful -- just look
  for entries beginning with "xK":

  http://xmonad.org/xmonad-docs/xmonad/doc-index-X.html

  Note that in the example below, the last three entries refer
  to nonstandard keys which do not have names assigned by
  xmonad. That's because they are the volume and mute keys
  on my laptop, a Lenovo W520.

  If you have special keys on your keyboard which you
  want to bind to specific actions, you can use the "xev"
  command-line tool to determine the code for a specific key.
  Launch the command, then type the key in question and watch
  the output.
-}

myKeyBindings =
  [
    ((myModMask, xK_b), sendMessage ToggleStruts)
    , ((myModMask, xK_a), sendMessage MirrorShrink)
    , ((myModMask, xK_z), sendMessage MirrorExpand)
    , ((myModMask, xK_u), focusUrgent)
    , ((myModMask, xK_p), spawn "albert show")
    , ((myModMask .|. shiftMask, xK_z), spawn "lock")
    , ((0, 0x1008FF12), spawn "pulse-volume.sh toggle")
    , ((0, 0x1008FF11), spawn "pulse-volume.sh decrease")
    , ((0, 0x1008FF13), spawn "pulse-volume.sh increase")
  ] ++
  [
    ((myModMask,               xK_KP_Enter), windows W.swapMaster),
    ((myModMask .|. shiftMask, xK_KP_Enter), spawn myTerminal)
  ] ++
  [
    ((m .|. myModMask, key), screenWorkspace sc
      >>= flip whenJust (windows . f))
      | (key, sc) <- [(xK_w, 1), (xK_e, 0), (xK_r, 2)]
      , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
  ] ++
  [
    ((m .|. myModMask, k), windows $ f i)
       | (i, k) <- [("7", xK_KP_Home), ("8", xK_KP_Up),    ("9", xK_KP_Page_Up),
                    ("4", xK_KP_Left), ("5", xK_KP_Begin), ("6", xK_KP_Right),
                    ("1", xK_KP_End),  ("2", xK_KP_Down),  ("3", xK_KP_Page_Down)]
       , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
  ]


{-
  Management hooks. You can use management hooks to enforce certain
  behaviors when specific programs or windows are launched. This is
  useful if you want certain windows to not be managed by xmonad,
  or sent to a specific workspace, or otherwise handled in a special
  way.

  Each entry within the list of hooks defines a way to identify a
  window (before the arrow), and then how that window should be treated
  (after the arrow).

  To figure out how to identify your window, you will need to use a
  command-line tool called "xprop". When you run xprop, your cursor
  will temporarily change to crosshairs; click on the window you
  want to identify. In the output that is printed in your terminal,
  look for a couple of things:
    - WM_CLASS(STRING): values in this list of strings can be compared
      to "className" to match windows.
    - WM_NAME(STRING): this value can be compared to "resource" to match
      windows.

  The className values tend to be generic, and might match any window or
  dialog owned by a particular program. The resource values tend to be
  more specific, and will be different for every dialog. Sometimes you
  might want to compare both className and resource, to make sure you
  are matching only a particular window which belongs to a specific
  program.

  Once you've pinpointed the window you want to manipulate, here are
  a few examples of things you might do with that window:
    - doIgnore: this tells xmonad to completely ignore the window. It will
      not be tiled or floated. Useful for things like launchers and
      trays.
    - doFloat: this tells xmonad to float the window rather than tiling
      it. Handy for things that pop up, take some input, and then go away,
      such as dialogs, calculators, and so on.
    - doF (W.shift "Workspace"): this tells xmonad that when this program
      is launched it should be sent to a specific workspace. Useful
      for keeping specific tasks on specific workspaces. In the example
      below I have specific workspaces for chat, development, and
      editing images.
-}

myManagementHooks :: [ManageHook]
myManagementHooks =
  , appName =? "stalonetray" --> doIgnore
  , className =? "Pidgin" --> doShift "7"
  ]


{-
  Here we actually stitch together all the configuration settings
  and run xmonad. We also spawn an instance of xmobar and pipe
  content into it via the logHook.
-}

main = do
  xmonad $
    withUrgencyHook NoUrgencyHook $
    E.ewmh $
    pagerHints $
    def {
    focusedBorderColor = myFocusedBorderColor
  , normalBorderColor = myNormalBorderColor
  , terminal = myTerminal
  , borderWidth = myBorderWidth
  , layoutHook = myLayouts
  , modMask = myModMask
  , handleEventHook = mconcat [ docksEventHook
                              , fullscreenEventHook ]
  , startupHook = do
      setWMName "LG3D" -- fix for Java Swing apps
      spawn "~/.xmonad/startup-hook"
  , manageHook = manageHook def
      <+> composeAll myManagementHooks
      <+> manageDocks
  }
    `additionalKeys` myKeyBindings