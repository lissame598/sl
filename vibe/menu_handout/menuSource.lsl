// This script is meant to be a single source for the items that objects can request within
// the Vibe club.
//
// It listens on VIBE_SOURCE_REQUEST_CHANNEL and will supply whatever matches the string
// in the "item" argument.
//
// When left-clicked, it sends out a VIBE_SOURCE_PUSH message, which is meant to trigger
// any objects listening on that channel to request new copies of whatever inventory objects
// they implement.
//
#include "Library/vibe_menu_messages.lsl"

// Sender Object
key requestor_uuid;

default
{
    // open up a listener so we can respond to requests
    state_entry()
    {
        printDebugMessages = 0;         // 1 to get debug messages, 0 to suppress them

        // open the listener so we can respond to requests
        debugSay("Opening listener on channel " + (string)CHANNEL_VIBE_SOURCE_OBJECT);
        llListen(CHANNEL_VIBE_SOURCE_OBJECT, "", NULL_KEY, "");
    }

    // push out a request for updates when clicked
    touch_start(integer num_detected) {
        debugSay("Sending out " + (string)VIBE_ANNOUNCE_UPDATE + " on channel " + (string)CHANNEL_VIBE_SOURCE_OBJECT);
        llRegionSay(CHANNEL_VIBE_SOURCE_OBJECT, VIBE_ANNOUNCE_UPDATE);
    }

    // respond to objects who broadcast on the CHANNEL_VIBE_SOURCE_OBJECT channel
    listen(integer channel, string name, key id, string message)
    {
        // exit if for some reason we receive something on an errant channel
        if( channel != CHANNEL_VIBE_SOURCE_OBJECT )
        {
            debugSay("Received message on incorrect channel: " + (string)channel);
            return;
        }
        debugSay("Received message from '" + name + "' (UUID: " + (string)id + ") msg: '" + message);

        // parse the message
        list msgList = llParseString2List(message, VIBE_MESSAGE_SEPARATORS, []);
        string cmd = llList2String( msgList, 0 );
        if( cmd == VIBE_REQUEST_NOTECARD )
        {
            debugSay("Received " + VIBE_REQUEST_NOTECARD);
            if( llGetListLength(msgList) < 2 )
            {
                debugSay("Error: (" + VIBE_REQUEST_NOTECARD + "). No name argument included.");
                return;
            }
            // there's an argument, grab that as the name of the notecard the requesting object wants
            string itemName = llList2String( msgList, 1 );

            if( llGetInventoryType(itemName) != INVENTORY_NONE )
            {
                debugSay("Giving inventory item " + itemName);
                llGiveInventory(id, itemName);
            }
            else 
            {
                debugSay(VIBE_REQUEST_NOTECARD + " failed: Item '" + itemName + "' is not in inventory: " + message);
            }
        }
        else if( cmd == VIBE_REQUEST_TEXTURE )
        {
            debugSay("Received " + VIBE_REQUEST_TEXTURE);
            if( llGetListLength(msgList) < 2 )
            {
                debugSay("Error: (" + VIBE_REQUEST_TEXTURE + "). No name argument included.");
                return;
            }
            string itemName = llList2String(msgList, 1);

            if( llGetInventoryType(itemName) != INVENTORY_NONE )
            {
                debugSay("Giving inventory item " + itemName);
                llGiveInventory(id, itemName);
            }
            else
            {
                debugSay(VIBE_REQUEST_TEXTURE + " failed: Item '" + itemName + "' is not in inventory: " + message);
            }
        }
        else
        {
            debugSay("Message (" + cmd + ") not supported by source object.");
        }
    }
}    
