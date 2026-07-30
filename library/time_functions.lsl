// Returns 1 if timeA is more recent (later) than timeB, otherwise returns 0
integer isTimeMoreRecent(string timeA, string timeB)
{
    // Parse "HH:MM:SS" strings into lists of chunks
    list listA = llParseString2List(timeA, [":"], []);
    list listB = llParseString2List(timeB, [":"], []);
    
    // Extract hours, minutes, and seconds as integers
    integer hoursA   = llList2Integer(listA, 0);
    integer minsA    = llList2Integer(listA, 1);
    integer secsA    = llList2Integer(listA, 2);
    
    integer hoursB   = llList2Integer(listB, 0);
    integer minsB    = llList2Integer(listB, 1);
    integer secsB    = llList2Integer(listB, 2);
    
    // Convert both times completely into total seconds past midnight
    integer totalSecsA = (hoursA * 3600) + (minsA * 60) + secsA;
    integer totalSecsB = (hoursB * 3600) + (minsB * 60) + secsB;
    
    // Compare mathematically
    if (totalSecsA > totalSecsB)
    {
        return 1; // timeA is newer/later
    }
    return 0; // timeB is newer or they are equal
}

// Returns the most recently received inventory item of type 'type' from the inventory list
string findNewestInInventory(integer type)
{
    integer count = llGetInventoryNumber(type);
    integer i = 0;
    string newest_item = "";
    string newest_time = "";
    
    for( i=0; i < count; i++ )
    {
        string current_item = llGetInventoryName(type, i);
        string current_time = llGetInventoryAcquireTime(current_item);
        
        if( isTimeMoreRecent(current_time, newest_time ) )
        {
            newest_time = current_time;
            newest_item = current_item;
        }
    }
    return newest_item;
}