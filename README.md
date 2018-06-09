
> ## Class Halls Account Reporter

### _**[Project site](https://wow.curseforge.com/projects/class-halls-account-reporter)**_

This addon allows you to view all the needed information from each character's class hall such as missions, followers, troops, resources and more!

### _**Features:**_

This addon stores and displays the following information for each character you got! (Some information may not be shown if you don't meet the level requirement or a pre-quest has not been completed).

-   Character Level and ilvl
-   Character Gold
-   Some different character currencies (Such as blood of sargeras, hall resources, seals ...)
-   Cooking order information(Ready to start order, orders in progress....)
-   Troops info (Available, max to recruit and current troops been recruited)
-   Followers information
-   Class hall Available missions and In-progress Missions.
-   Mytics+ Best run, expected ilvl in the weekly chest, and if the weekly chest has collected or not.

### _**Usage:**_

To get to the report frame (where all the information is detailed), you simply need to click the icon located on a side of the minimap or you could also type the command "/char show" in chat.

Once you got the frame open you will be able to see all the different characters and some information about them. To refresh this information you can simply click "Refresh Data" (Note that the data is also refreshed every time you open the frame).  
![View of the frame ingame without having any character expanded](https://media-elerium.cursecdn.com/attachments/218/118/photo1.png)

You can then click on any character to see a little bit more information (missions in progress, missions ready to start and all the collected followers (and their respective status, for example, if they are on a mission, if they are assigned as combat ally...)). You can undo the expansion of info by clicking the character again.

![View of the expanded Character information](https://media-elerium.cursecdn.com/attachments/218/121/photo2.png)

You can actually also remove all the character information stored by pressing the "Delete All Data" button ( The same effect as the command "/char reset"), this will delete all the information stored and clean the frame. This tool is handy for example if any data got corrupted and you get Lua errors.

In case you only want to delete a single character you can simply press the "Delete Character" button in the extended info frame from the respective character.

### _**Commands:**_

-   /char help - Shows the help page with all the different commands in-game.
-   /char show - Shows the Report frame (same functionality as clicking the minimap icon).
-   /char reset - Deletes all the stored data of all characters (Normally used when something bugged and cannot get into the report frame).
-   /char debug - Enables debug mode, the chat will output messages such as when its updating etc etc.
-   /char toggleMinimapIcon -> Toggles the miniamp icon.
    
-   /char setsummary <cook/keystone/hallmissions> <this/character/all> -> Changes the summary frame to display nomies cooking order, the keystone information or hallmissions sumarry for this character, a specific character or all of them.
    

### _**ToDo List!**_

1.  List of all mytics+ completed with its complete information (Name, Level, Time to complete, Upgrade Levels, Team Composition).
    

### _**Issues & Suggestions:**_

If you found a bug (Any kind of bug even spelling mistakes!) or you want to tell me about a feature you would like to add to the addon simply visit the [Issues Page](https://wow.curseforge.com/projects/class-halls-account-reporter/issues) and create a ticket!

### _**Changelog:**_

I apology for all the update these days, people have been messaging me for bugs that I never encountered and I'm trying to fix them all asap!

If you still have any problems executing the addon let me know asap!

#### **_Version 1.4:_**

**_This version mainly includes features suggested by @christopher12824. Thanks for the feedback!_**

-   + We can remember now! The windows will now remember the last position you had it in! Yep no longer resets :O!
-   + We need to know! Added a new summary frame variant to show class halls mission quick summary to know if a character has active Misiones, the time for the next one to compleat, and if none are in progress how many are available.
-   + Buttons better than commands. Added 3 buttons to the frame to quickly change all the summary frame (the one that shows the cooking, mytic plus and class hall missions summary).
-   + I really got it. Commands are awful D:. Added buttons in each character frame to control the summary frame. Just as the new 3 main buttons but this one are intended for only one character.
-   + Added a new command to disable/activate the minimap icon: /char toggleMinimapIcon
-   + Added a new command to change the summary frame from the chat window: /char setsummary <cook/keystone/hallmissions> <this/character/all>
-   - Removed the old command for showing the kyestones: /char showKeyInfo <character>, /char showKeyInfo all <true/false>, /char showKeyInfo this

#### **_Version 1.3:_**

-   ! Fixed an error that could cause an error if your game crashed in the middle of a mytic +
-   ! Fixed an error that would cause you to be unable to open the reporter frame if any character has a key below lvl 10 (without 3 afixess). Now it works! (Sorry for not testing with a low-level stone T.T)

#### **_Version 1.2:_**

-   ! Fixed a bug that would cause the stored mytic + keystone to not reset and give you false indications.

More information about changes [here!](https://wow.curseforge.com/projects/class-halls-account-reporter/pages/changelog)
