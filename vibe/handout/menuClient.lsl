// This function is meant to be included on an object that an avatar clicks on to receive a 
// copy of the "Vibe Prices Menu" from the VibeMenuSourceObject.
// It sends out a region-wide request for a copy of the master menu. If it receives one, it
// passes it along to the avatar that clicked on it, then deletes it from its own inventory.
//

#include "Library/time_functions.lsl"
#include "Library/vibe_menu_messages.lsl"

integer dialogChannel;          // randomized channel for creating dialog box for requesting avatar
integer avListenerHandle;       // listener for dialog response
integer sourceListenerHandle;   // listener for source object force updates
key avatarKey;

// Cleans up listeners to prevent sim lag
closeListener()
{
    llListenRemove(avListenerHandle);
    llSetTimerEvent(0.0);   // 0.0 cancels the timer
    avatarKey = NULL_KEY;
}

// Cleans up extra notecards which can remain on the object if, e.g., the avatar ignores the dialog box
/*
deleteNotecards()
{
    integer count;
    integer i;

    count = llGetInventoryNumber(INVENTORY_NOTECARD);
    for( i=0; i<count; i++ )
    {
        llRemoveInventory(llGetInventoryName(INVENTORY_NOTECARD, i));
    }
}
*/

default
{
    state_entry()
    {
        // Clear out particle effects on this object and any linked ones
        integer totalLinks = llGetNumberOfPrims();
        integer i;

        for( i=0; i<totalLinks; ++i )
        {
            llLinkParticleSystem(i, []);
        }

        // open up a listener for source object updates
        sourceListenerHandle = llListen(CHANNEL_VIBE_SOURCE_OBJECT, "", "", "");
    }

    // When this object is rezzed, we should request what we need from the menu source
    on_rez(integer start_param)
    {
        llRegionSay(CHANNEL_VIBE_SOURCE_OBJECT, "VIBE_MENU_REQUEST:" + VIBE_PRICES_NOTECARD);
    }

    touch_start(integer total_number)
    {
        // give out the notecard in our inventory with current prices when touched
        avatarKey = llDetectedKey(0);
        string displayName = llGetDisplayName(avatarKey);
        debugSay("Touched by " + displayName + " (UUID: " + (string)avatarKey + ")");

        // check to see if we have the object we hand out
        string item = llGetInventoryKey(VIBE_PRICES_NOTECARD);

        if( item != NULL_KEY )
        {
            // generate a random channel number
            dialogChannel = (integer)(llFrand(-1000000.0) - 1000000.0);

            // trigger the blue pop-up menu
            string dialogText = "Would you like a copy of the Vibe Menu?";
            list buttons = ["Yes", "No"];

            // opening dialog box
            debugSay("Opening dialog box. Listening on " + (string)dialogChannel);
            llDialog(avatarKey, dialogText, buttons, dialogChannel);

            // open a temporary listener for the avatar that clicked
            avListenerHandle = llListen(dialogChannel, "", avatarKey, "");

            // set a 60 second timeout timer
            llSetTimerEvent(60.0);
        }
        else 
        {
            debugSay("Item requested does not exist in inventory.");
        }
    }
    
    listen(integer channel, string name, key id, string message)
    {
        string card_to_give = "";

        // Note will need to update this if any client objects need to hold more than one
        // kind of notecard
        card_to_give = findNewestInInventory(INVENTORY_NOTECARD);

        if( channel == dialogChannel )
        {
            if( message == "Yes")
            {
                if( card_to_give != "" )
                {
                    llRegionSayTo(avatarKey, dialogChannel, "Sending you the Vibe calendar!");
                    llGiveInventory(avatarKey, card_to_give);
                }
                else
                {
                    debugSay("Requested notecard does not exist in inventory.");
                }
            }
            else
            {
                llRegionSayTo(avatarKey, dialogChannel, "Delivery canceled.");
            }
        }
        else if( channel == CHANNEL_VIBE_SOURCE_OBJECT )
        {
            list msgList = llParseString2List(message, VIBE_MESSAGE_SEPARATORS, []);
            string cmd = llList2String(msgList, 0);

            if( cmd == VIBE_ANNOUNCE_UPDATE )
            {
                // the source object is asking us to update, so delete our current notecard and request
                // a new one from the source
                llRemoveInventory(card_to_give);
                llRegionSay(CHANNEL_VIBE_SOURCE_OBJECT, VIBE_REQUEST_NOTECARD + ":" + VIBE_PRICES_NOTECARD);
            }
        }
    }

    timer()
    {
        // auto-close channel if they ignore the menu for 60 seconds
        closeListener();
    }
}
