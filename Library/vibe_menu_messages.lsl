integer CHANNEL_VIBE_SOURCE_OBJECT = -13562;

// separators
list VIBE_MESSAGE_SEPARATORS = [",", ":"];

// commands
string VIBE_ANNOUNCE_UPDATE = "VIBE_ANNOUNCE_UPDATE";       // source object's way to announce to clients that they should update their content
string VIBE_REQUEST_NOTECARD = "VIBE_REQUEST_NOTECARD";     // client request for a specific notecard from the source
string VIBE_REQUEST_TEXTURE = "VIBE_REQUEST_TEXTURE";       // client request for a specific texture from the source

// available objects
string VIBE_PRICES_NOTECARD = "Vibe Prices Notecard";
string VIBE_CALENDAR_NOTECARD = "Vibe Calendar Notecard";
string VIBE_CALENDAR_TEXTURE = "Vibe Calendar Texture";

//
// common functions
//

integer gPrintDebugMessages = 0;

debugSay( string msg )
{
    
    if( gPrintDebugMessages == 1 )
    {
        llOwnerSay(llGetScriptName() + ": " + msg);
    }
}
