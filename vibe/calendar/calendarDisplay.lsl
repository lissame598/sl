integer FACE = 2;
string  URL  = "https://lissame598.github.io/sl/vibe/calendar/calendar.html";
integer count;

set_page()
{
    string u = URL + "?t=" + (string)llGetUnixTime();
    integer st = llSetPrimMediaParams(FACE, [
        PRIM_MEDIA_CURRENT_URL,          u,
        PRIM_MEDIA_HOME_URL,             u,
        PRIM_MEDIA_AUTO_PLAY,            TRUE,
        PRIM_MEDIA_AUTO_SCALE,           TRUE,
        PRIM_MEDIA_WIDTH_PIXELS,         1024,
        PRIM_MEDIA_HEIGHT_PIXELS,        1024,
        PRIM_MEDIA_FIRST_CLICK_INTERACT, FALSE,
        PRIM_MEDIA_PERMS_INTERACT,       PRIM_MEDIA_PERM_NONE,
        PRIM_MEDIA_PERMS_CONTROL,        PRIM_MEDIA_PERM_NONE,
        PRIM_MEDIA_CONTROLS,             PRIM_MEDIA_CONTROLS_MINI
    ]);
    ++count;
   //  llOwnerSay("reload #" + (string)count + "  status=" + (string)st + "  " + u);
}

default
{
    state_entry()      { set_page(); llSetTimerEvent(60.0); }
    timer()            { set_page(); }
    on_rez(integer p)  { set_page(); }
}