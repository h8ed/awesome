-- {{{ Required libraries
local awesome, client, mouse, screen, tag = awesome, client, mouse, screen, tag
local ipairs, string, os, table, tostring, tonumber, type = ipairs, string, os, table, tostring, tonumber, type

local gears         = require("gears")
local awful         = require("awful")
                      require("awful.autofocus")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local lain          = require("lain")
--local menubar       = require("menubar")
local freedesktop   = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup").widget
                      require("awful.hotkeys_popup.keys")
local my_table      = awful.util.table or gears.table -- 4.{0,1} compatibility
local dpi           = require("beautiful.xresources").apply_dpi

ezconfig      = require("ezconfig")
-- }}}

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Autostart windowless processes

-- This function will run once every time Awesome is started
local function run_once(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        awful.spawn.with_shell(string.format("pgrep -u $USER -fx '%s' > /dev/null || (%s)", cmd, cmd))
    end
end

run_once({ "xset r rate 300 75", "unclutter -root", "picom", "xmodmap ~/.swap" }) -- entries must be separated by commas

-- This function implements the XDG autostart specification
--[[
awful.spawn.with_shell(
    'if (xrdb -query | grep -q "^awesome\\.started:\\s*true$"); then exit; fi;' ..
    'xrdb -merge <<< "awesome.started:true";' ..
    -- list each of your autostart commands, followed by ; inside single quotes, followed by ..
    'dex --environment Awesome --autostart --search-paths "$XDG_CONFIG_DIRS/autostart:$XDG_CONFIG_HOME/autostart"' -- https://github.com/jceb/dex
)
--]]

-- }}}

-- {{{ EZConfig
ezconfig.modkey = 'Mod4'
ezconfig.altkey = 'Mod1'


-- {{{ Variable definitions

local themes = {
    "blackburn",       -- 1
    "copland",         -- 2
    "dremora",         -- 3
    "holo",            -- 4
    "multicolor",      -- 5
    "powerarrow",      -- 6
    "powerarrow-dark", -- 7
    "rainbow",         -- 8
    "steamburn",       -- 9
    "vertex",          -- 10
}

local chosen_theme = themes[5]
local modkey       = "Mod4"
local altkey       = "Mod1"
local terminal     = "alacritty"
local editor       = os.getenv("EDITOR") or "nvim"
local gui_editor   = "emacs"
local browser      = "firefox"
local guieditor    = "emacs"
local scrlocker    = "i3-lock-fancy"

awful.util.terminal = terminal
awful.util.tagnames = { "dev", "web", "chat", "books", "media", "extra" }
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.magnifier,
    -- lain.layout.cascade.tile,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    --awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    --awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.corner.nw,
    --awful.layout.suit.corner.ne,
    --awful.layout.suit.corner.sw,
    --awful.layout.suit.corner.se,
    --lain.layout.cascade,
    -- lain.layout.centerwork,
    -- lain.layout.centerwork.horizontal,
    -- lain.layout.termfair,
    -- lain.layout.termfair.center,
}

awful.util.taglist_buttons = my_table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

awful.util.tasklist_buttons = my_table.join(
    awful.button({ }, 1, function (c)
        if c == client.focus then
            c.minimized = true
        else
            --c:emit_signal("request::activate", "tasklist", {raise = true})<Paste>

            -- Without this, the following
            -- :isvisible() makes no sense
            c.minimized = false
            if not c:isvisible() and c.first_tag then
                c.first_tag:view_only()
            end
            -- This will also un-minimize
            -- the client, if needed
            client.focus = c
            c:raise()
        end
    end),
    awful.button({ }, 2, function (c) c:kill() end),
    awful.button({ }, 3, function ()
        local instance = nil

        return function ()
            if instance and instance.wibox.visible then
                instance:hide()
                instance = nil
            else
                instance = awful.menu.clients({theme = {width = dpi(250)}})
            end
        end
    end),
    awful.button({ }, 4, function () awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function () awful.client.focus.byidx(-1) end)
)

-- lain.layout.termfair.nmaster           = 3
-- lain.layout.termfair.ncol              = 1
-- lain.layout.termfair.center.nmaster    = 3
-- lain.layout.termfair.center.ncol       = 1
-- lain.layout.cascade.tile.offset_x      = dpi(2)
-- lain.layout.cascade.tile.offset_y      = dpi(32)
-- lain.layout.cascade.tile.extra_padding = dpi(5)
-- lain.layout.cascade.tile.nmaster       = 5
-- lain.layout.cascade.tile.ncol          = 2

beautiful.init(string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme))
-- }}}

-- {{{ Menu
local myawesomemenu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end },
    { "manual", terminal .. " -e man awesome" },
    { "edit config", string.format("%s -e %s %s", terminal, editor, awesome.conffile) },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end }
}
awful.util.mymainmenu = freedesktop.menu.build({
    icon_size = beautiful.menu_height or dpi(16),
    before = {
        { "Awesome", myawesomemenu, beautiful.awesome_icon },
        -- other triads can be put here
    },
    after = {
        { "Open terminal", terminal },
        -- other triads can be put here
    }
})


-- No gaps when single window
-- beautiful.useless_gap = 10
beautiful.gap_single_client = false


-- hide menu when mouse leaves it
--awful.util.mymainmenu.wibox:connect_signal("mouse::leave", function() awful.util.mymainmenu:hide() end)

--menubar.utils.terminal = terminal -- Set the Menubar terminal for applications that require it
-- }}}

-- {{{ Screen
-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", function(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end)
-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s) beautiful.at_screen_connect(s) end)
-- }}}

-- {{{ Mouse bindings
root.buttons(my_table.join(
    awful.button({ }, 3, function () awful.util.mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ key bindings

    -- Layout Manipulation

globalkeys = ezconfig.keytable.join({
	-- ['A-p'] = function() os.execute("maimpick") end,

	['M-k'] = function() awful.client.focus.byidx( 1) end,

	['M-l'] = function() awful.client.focus.byidx(-1) end,

	['M-S-k'] = function() awful.client.swap.byidx( 1) end,

	['M-S-l'] = function() awful.client.swap.byidx(-1) end,

	['M-C-k'] = function() awful.screen.focus_relative( 1) end,

	['M-C-l'] = function() awful.screen.focus_relative(-1) end,

	['M-;'] = function() awful.tag.incmwfact( 0.05) end,

	['M-j'] = function() awful.tag.incmwfact(-0.05) end,

	['M-S-;'] = function() awful.tag.incmaster(-1, nil, true) end,

	['M-S-j'] = function() awful.tag.incmaster( 1, nil, true) end,

	['M-<space>'] = function() awful.layout.inc( 1) end,
	
	['M-C-<space>'] = function() awful.layout.inc(-1) end,

	['M-C-n'] = function()
		local c = awful.client.restore()
		if c then
			client.focus = c
			c:raise()
		end
	end,
	
	['M-b'] = function()
		for s in screen do
			s.mywibox.visible = not s.mywibox.visible
		end
	end,

	-- ['M-<Return>'] = function() awful.spawn(terminal) end,

	['M-C-r'] = awesome.restart,

	['M-S-q'] = awesome.quit,

	-- ['<XF86MonBrightnessUp>'] = function() os.execute("xbacklight -inc 10") end,
	
	-- ['<XF86MonBrightnessDown>'] = function() os.execute("xbacklight -dec 10") end,

	-- ['A-<Up>'] = function()
	-- 	os.execute(string.format("amixer -q set 5%%+", beautiful.volume.control))
	-- 	beautiful.volume.update()
	-- end,
	
	-- ['A-<Down>'] = function()
	-- 	os.execute(string.format("amixer -q set 5%%-", beautiful.volume.control))
	-- 	beautiful.volume.update()
	-- end,

	-- ['A-m'] = function()
	-- 	os.execute(string.format("amixer -q set %s toggle", beautiful.volume.togglechannel or beautiful.volume.channel))
	-- 	beautiful.volume.update()
	-- end,

	-- ['M-w'] = function() awful.spawn(browser) end,
	
	-- ['M-a'] = function() awful.spawn(guieditor) end,

	-- ['M-d'] = function()
	-- 	os.execute(string.format("rofi -show run",
	-- 	beautiful.bg_normal, beautiful.fg_normal, beautiful.bg_focus, beautiful.fg_focus))
	-- end,
})

clientkeys = ezconfig.keytable.join({
	['A-S-m'] = lain.util.magnify_client,

	['M-f'] = function(c)
		c.fullscreen = not c.fullscreen
		c:raise()
	end,

	-- ['M-q'] = function(c) c:kill() end,

	['M-S-<space>'] = awful.client.floating.toggle,

	['M-C-<Return>'] = function(c) c:swap(awful.client.getmaster()) end,

	['M-o'] = function(c) c:move_to_screen() end,

	['M-t'] = function(c) c.ontop = not c.ontop end,

	['M-n'] = function(c) c.minimized = true end,

	-- ['M-S-m'] = function(c)
	-- 	c.maximized = not c.maximized
	-- 	c:raise()
	-- end,
})

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    -- Hack to only show tags 1 and 9 in the shortcut window (mod+s)
    local descr_view, descr_toggle, descr_move, descr_toggle_focus
    if i == 1 or i == 9 then
        descr_view = {description = "view tag #", group = "tag"}
        descr_toggle = {description = "toggle tag #", group = "tag"}
        descr_move = {description = "move focused client to tag #", group = "tag"}
        descr_toggle_focus = {description = "toggle focused client on tag #", group = "tag"}
    end
    globalkeys = my_table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  descr_view),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  descr_toggle),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  descr_move),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  descr_toggle_focus)
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                     size_hints_honor = false
     }
    },

    -- Start windows as slaves, not master.
    { rule = { }, properties = { }, callback = awful.client.setslave },

    -- -- Titlebars
    { rule_any = { type = { "floating" } }, -- "dialog", "normal"
      properties = { titlebars_enabled = false } },

    -- -- Set Firefox to always map on the first tag on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = awful.util.tagnames[1] } },

    -- { rule = { class = "Gimp", role = "gimp-image-window" },
    --     properties = { maximized = true } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- Custom
    if beautiful.titlebar_fun then
        beautiful.titlebar_fun(c)
        return
    end

    -- Default
    -- buttons for the titlebar
    local buttons = my_table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 2, function() c:kill() end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c, {size = dpi(16)}) : setup {
        { -- Left
            awful.titlebar.widget.closebutton    (c),
            awful.titlebar.widget.maximizedbutton(c),
            -- buttons = buttons,
            layout  = wibox.layout.fixed.horizontal()
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            -- awful.titlebar.widget.maximizedbutton(c),
            -- awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            -- awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.align.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
-- client.connect_signal("mouse::enter", function(c)
--     c:emit_signal("request::activate", "mouse_enter", {raise = false})
-- end)

-- Titlebars only on floating windows
client.connect_signal("property::layout", function(c)
    if c.floating == false and c.first_tag.layout.name == "floating" then
        c.border_width = beautiful.border_width
    end
end)

client.connect_signal("property::floating", function(c)
    local b = false;
    if c.first_tag ~= nil then
        b = c.first_tag.layout.name == "floating"
    end
    if c.floating or b then
        awful.titlebar.show(c)
    else
        awful.titlebar.hide(c)
    end
end)

function dynamic_title(c)
    if c.floating or c.first_tag.layout.name == "floating" then
        awful.titlebar.show(c)
    else
        awful.titlebar.hide(c)
    end
end

tag.connect_signal("property::layout", function(t)
    local clients = t:clients()
    for k,c in pairs(clients) do
        if c.floating or c.first_tag.layout.name == "floating" then
            awful.titlebar.show(c)
        else
            awful.titlebar.hide(c)
        end
    end
end)

-- No borders if only one tiled client -- always borders on floating
screen.connect_signal("arrange", function(s)
    for _, c in pairs(s.clients) do
        if c.first_tag.layout.name == "max" or #s.tiled_clients == 1 and c.floating == false and c.first_tag.layout.name ~= "floating" then
            c.border_width = 0
        elseif #s.tiled_clients > 1 or c.floating or c.first_tag.layout.name == "floating" then
            c.border_width = beautiful.border_width
        end
    end
end)

client.connect_signal("manage", dynamic_title)
client.connect_signal("tagged", dynamic_title)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)

-- possible workaround for tag preservation when switching back to default screen:
-- https://github.com/lcpz/awesome-copycats/issues/251
-- }}}
