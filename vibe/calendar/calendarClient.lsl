// Upcoming-events display on a prim face, driven by a notecard.
// Notecard format (one per line):   YYYY-MM-DD | Event name
// '#' lines and blank lines are ignored.

#include "Library/time_functions.lsl"
#include "Library/vibe_menu_messages.lsl"

integer FACE     = 2;
string  NOTECARD = "Vibe Calendar Notecard";   // name of the notecard dropped into this prim
integer MAXRAW   = 730;        // safety cap: keeps the page under the ~1024-byte data-URI limit

string MESSAGE_BG_COLOR = "#12122b";
string MESSAGE_FG_COLOR = "#eee";
string MESSAGE_FONT_TYPE = "sans-serif";
string MESSAGE_FONT_SIZE = "36px";
string HEADER_BG_COLOR = "#ff1929";
string HEADER_FG_COLOR = "#12122b";
string HEADER_FONT_TYPE = "sans-serif";
string HEADER_FONT_SIZE = "36px";
string LIST_BG_COLOR = "#12122b";
string LIST_FG_COLOR = "#976ad3";
string LIST_FONT_SIZE = "36px";
string LIST_FONT_TYPE = "sans-serif";
string LIST_BORDER_COLOR = "#333";

integer gSourceListenerHandle; // listener for source object force updates

list ABBR = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

list    gEvents;               // parsed as [ "YYYY-MM-DD", "Title", ... ]
integer gLine;
key     gQuery;
integer gRefresh;
integer gPW = 1024;   // current media buffer width
integer gPH = 1024;   // current media buffer height

string HEADER_PRIM    = "Header";   // name of the linked prim that shows the image
string gHeaderTexture;

integer po2(integer v)              // nearest power of two, 64..1024
{
    list ps = [64,128,256,512,1024];
    integer best = 1024; integer bd = 99999; integer i;
    for (i = 0; i < 5; i++)
    {
        integer p = llList2Integer(ps, i);
        integer d = p - v; if (d < 0) d = -d;
        if (d < bd) { bd = d; best = p; }
    }
    return best;
}

fitToFace()                         // match buffer ratio to the display face
{
    vector s = llGetScale();
    float w = s.y;                  // face WIDTH  (use s.y if your sign faces the X axis)
    float h = s.z;                  // face HEIGHT
    if (w >= h) { gPW = 1024; gPH = po2((integer)(1024.0 * h / w)); }
    else        { gPH = 1024; gPW = po2((integer)(1024.0 * w / h)); }
}

setHeader()
{
    // use the newest texture in inventory
    gHeaderTexture = findNewestInInventory(INVENTORY_TEXTURE);
    
    if (gHeaderTexture == "") return;
    integer i;
    integer n = llGetNumberOfPrims();
    for (i = 1; i <= n; i++)
    {
        if (llGetLinkName(i) == HEADER_PRIM)
        {
            llSetLinkTexture(i, gHeaderTexture,2);
            return;
        }
    }
}

integer dnum(string iso)       // "2026-07-25" -> 20260725
{
    return (integer)llGetSubString(iso,0,3) * 10000
         + (integer)llGetSubString(iso,5,6) * 100
         + (integer)llGetSubString(iso,8,9);
}

setPage(string body)
{
    string html = body + "<!--" + (string)(gRefresh++ % 10) + "-->";
    llSetPrimMediaParams(FACE, [
        PRIM_MEDIA_CURRENT_URL,    "data:text/html," + html,
        PRIM_MEDIA_HOME_URL,       "data:text/html," + html,
        PRIM_MEDIA_AUTO_PLAY,      TRUE,
        PRIM_MEDIA_AUTO_SCALE,     TRUE,
        PRIM_MEDIA_WIDTH_PIXELS,   gPW,
        PRIM_MEDIA_HEIGHT_PIXELS,  gPH,
        PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_NONE,
        PRIM_MEDIA_PERMS_CONTROL,  PRIM_MEDIA_PERM_NONE
    ]);
}

// print a message if calendar content is not available
message(string msg)
{
    setPage("<style>body{margin:0;font:" + MESSAGE_FONT_SIZE + " " + MESSAGE_FONT_TYPE + ";background:" + MESSAGE_BG_COLOR + ";color:" + MESSAGE_FG_COLOR + ";"
        + "display:flex;align-items:center;justify-content:center;height:100vh;"
        + "text-align:center;padding:12px;box-sizing:border-box}</style><div>" + msg + "</div>");
}

showAgenda()
{
    string  ts    = llGetTimestamp();
    integer today = (integer)llGetSubString(ts,0,3)*10000
                  + (integer)llGetSubString(ts,5,6)*100
                  + (integer)llGetSubString(ts,8,9);

    string head =
          "<style>body{margin:0;font:" + LIST_FONT_SIZE + " " + LIST_FONT_TYPE + ";background:" + LIST_BG_COLOR + ";color:" + LIST_FG_COLOR + ";}"
        + ".n{background:" + HEADER_BG_COLOR + ";color:" + HEADER_FG_COLOR + ";padding:10px}.n b{font-size:" + HEADER_FONT_SIZE + ";}"
        + "ul{list-style:none;margin:0;padding:6px 10px}"
        + "li{display:flex;justify-content:space-between;padding:5px 0;border-bottom:1px solid" + LIST_BORDER_COLOR + "}"
        + ".d{color:" + LIST_FG_COLOR + ";font-weight:bold}</style>";

    integer n = llGetListLength(gEvents);
    integer i;
    integer shown = 0;
    string  items = "";
    string  html  = "";

    for (i = 0; i < n && shown < 5; i += 2)
    {
        string dt = llList2String(gEvents, i);
        if (dnum(dt) >= today)
        {
            string ti    = llList2String(gEvents, i+1);
            string label = llList2String(ABBR, (integer)llGetSubString(dt,5,6) - 1)
                         + " " + (string)((integer)llGetSubString(dt,8,9)) + ", " + (string)llGetSubString(dt, 11, -1);
            string li    = "<li><span class=d>" + label + "</span><span>" + ti + "</span>";

            if (shown == 0)
            {
                html = head + "<div class=n>NEXT: <b>" + ti + "</b><br>" + label + "</div><ul>";
                items = li;
                shown++;
            }
            else if (llStringLength(html + items + li) <= MAXRAW)
            {
                items += li;
                shown++;
            }
            else i = n;   // budget reached — stop
        }
    }

    if (shown == 0)
        message("No upcoming events.<br>Edit the '" + NOTECARD + "' notecard on the source object to add some.");
    else
        setPage(html + items + "</ul>");
}

parseLine(string line)
{
    // trim whitespace front and back of string
    line = llStringTrim(line, STRING_TRIM);

    // ignore blank lines
    if (line == "") return;
    
    // ignore comment lines
    if (llGetSubString(line, 0, 0) == "#") return;

    integer p = llSubStringIndex(line, "|");

    // ignore any lines that have no date listed before the first |
    if (p < 1) return;

    // separate the string into d (date) and t (title)
    string d = llStringTrim(llGetSubString(line, 0, p-1), STRING_TRIM);
    string t = llStringTrim(llGetSubString(line, p+1, -1), STRING_TRIM);

    // sanity check that the date is valid. Must, at minimum have YYYY-MM-DD, which is 10 characters
    // characters at position 4 and 7 must be "-" characters if the date is less than 10 and if there
    // aren't "-" characters in the expected places, ignore this line
    if( llStringLength(d) < 10 || llGetSubString(d, 4, 4) != "-" || llGetSubString(d, 7, 7) != "-" ) return;

    // As long as the title isn't empty, return this as a date and title for the next event
    if (t != "") gEvents += [d, t];
}

readNotecard()
{
    gEvents = [];
    gLine   = 0;
    if (llGetInventoryType(NOTECARD) != INVENTORY_NOTECARD)
    {
        message("Drop a notecard named '" + NOTECARD + "' into this object.");
        return;
    }
    gQuery = llGetNotecardLine(NOTECARD, gLine);
}

deleteLocalFiles()
{
    // delete our calendar texture and notecard -- also delete any extras that may be appended with 1, 2, etc.
    integer count;
    integer i;
    string itemName;

    debugSay("Deleting local notecards whose beginning matches: " + VIBE_CALENDAR_NOTECARD );
    count = llGetInventoryNumber(INVENTORY_NOTECARD);
    // iterate backwards because deleting things from the end of the list will not shift
    // indices on items earlier in the list
    for( i=count-1; i>=0; i-- )
    {
        itemName = llGetInventoryName( INVENTORY_NOTECARD, i );
        if( llSubStringIndex( llToLower(itemName), llToLower(VIBE_CALENDAR_NOTECARD) ) == 0 )
        {
            debugSay( "Removing: " + itemName );
            llRemoveInventory( itemName );
        }
        else
        {
            debugSay( "No match on: " + itemName );
        }
    }

    debugSay("Deleting local textures whose beginning matches: " + VIBE_CALENDAR_TEXTURE);
    count = llGetInventoryNumber(INVENTORY_TEXTURE);

    for( i=count-1; i>=0; i-- )
    {
        itemName = llGetInventoryName( INVENTORY_TEXTURE, i );
        if( llSubStringIndex(llToLower(itemName), llToLower(VIBE_CALENDAR_TEXTURE) ) == 0 )
        {
            debugSay( "Removing: " + itemName );
            llRemoveInventory( itemName );
        }
        else
        {
            debugSay( "No match on: " + itemName );
        }
    }

}

default
{
    state_entry()     
    { 
        gPrintDebugMessages = 1;
        setHeader(); 
        fitToFace(); 
        gSourceListenerHandle = llListen(CHANNEL_VIBE_SOURCE_OBJECT, "", "", "");
        readNotecard(); 
    }
    
    on_rez(integer p) 
    {
        // Delete any local copies of notecard(s) and texture(s) we might have on the object
        deleteLocalFiles();
        
        // Request new notecard and texture from the source object
        llRegionSay(CHANNEL_VIBE_SOURCE_OBJECT, VIBE_REQUEST_NOTECARD + ":" + VIBE_CALENDAR_NOTECARD);
        llRegionSay(CHANNEL_VIBE_SOURCE_OBJECT, VIBE_REQUEST_TEXTURE + ":" + VIBE_CALENDAR_TEXTURE);
        setHeader(); 
        fitToFace(); 
        readNotecard(); 
    }

    changed(integer c)
    {
        if (c & CHANGED_INVENTORY) { setHeader(); readNotecard(); } // notecard added or edited
        if (c & CHANGED_LINK) { setHeader(); } // re-apply after linking
        if (c & CHANGED_SCALE) { fitToFace(); showAgenda(); }
    }

    listen(integer channel, string name, key id, string message)
    {
        list msgList = llParseString2List(message, VIBE_MESSAGE_SEPARATORS, []);
        string cmd = llList2String(msgList, 0);

        if( cmd == VIBE_ANNOUNCE_UPDATE )
        {
            // delete any textures and notecards we may have before receiving the up-to-date one
            deleteLocalFiles();

            // request the latest notecard and image texture from the source object
            llRegionSay(CHANNEL_VIBE_SOURCE_OBJECT, VIBE_REQUEST_NOTECARD + ":" + VIBE_CALENDAR_NOTECARD);
            llRegionSay(CHANNEL_VIBE_SOURCE_OBJECT, VIBE_REQUEST_TEXTURE + ":" + VIBE_CALENDAR_TEXTURE);
        }
    }

    dataserver(key q, string data)
    {
        if (q != gQuery) return;
        if (data == EOF)
        {
            gEvents = llListSort(gEvents, 2, TRUE);   // sort by date (ISO sorts chronologically)
            showAgenda();
        }
        else
        {
            parseLine(data);
            gLine++;
            gQuery = llGetNotecardLine(NOTECARD, gLine);
        }
    }
}