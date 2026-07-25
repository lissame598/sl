default
{
    state_entry()
    {
        llSay(0, "Hello, Avatar!");
    }

    touch_start(integer total_number)
    {
        key avatarKey;
        
        avatarKey = llDetectedKey(0);

        llDialog(avatarKey, "Hello world", ["Yes", "No"], -1234);
    }
}
