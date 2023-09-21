# Computercraft
This is a fork from NPException´s Computercraft Querry pastebin.

pastebin run p9ZkrH1i

# Reddit Guide
NPException:
Yes I have! Last time I used it was 2 years ago, but it's written in a way that it should still work as it did back then.

I've written a small "installer" script a while ago that lets me download most of the programs and files I commonly use in CC. To use it, just execute pastebin run p9ZkrH1i on a turtle.

Here's the current list of programs/files it will offer to install, what they do, and if you might need them:

updater.lua (source): This is my auto-updater script. When installed, programs can use it to check if there is an updated version of themselves available on pastebin, and automatically download it. You probably don't need this unless you want to use the auto-update functionality in your own programs.

betterturtle.lua (source): This file adds a few convenience functions to a turtle when it starts up, which can then be used in code. You don't need this, but the added functions can be useful:

turtle.turnAround(): 180° turn

turtle.left()/turtle.right(): move one block to the left/right without changing orientation.

turtle.forceForward(): Will forcibly move forward by digging & attacking if the block in front is not empty. The command exists for all other directions too. (up, down, left, right, back)

Additional dig, detect, compare, inspect, place, drop, and suck directions, for example turtle.digLeft() and turtle.dropBack()

quarry.lua (source): This is my quarry program. It digs columns into the ground in such a pattern that the turtle only needs to move the minimum amount of blocks, and never looks at a block twice. It optionally uses an ignore-list or allow-list, so that it won't dig up stone, cobble, dirt and other things you might not need. The source code is quite large, and I still have not yet written a readme for it since I was the only one using it so far. I'll try to write something up in the next few days. If you want to check it's capabilities yourself, you can see what parameters the program accepts from line 134 to 239 of the code.

quarry-minion.lua (source): this is a small script which just runs the quarry for a 16x16 area, using a predefined ignore-list from my pastebin. You might want to use this and modify it to your liking. If you do, I suggest to change the true in lines 17 and 18 to false. This will prevent the script from re-downloading my ignore-list every time you run it. The turtle will remember all types of blocks it dug up, and store it in a file called mined-blocks.txt. You can check this file after you run the turtle, and add any blocks you don't want mined to the ignore.list file.

ignorelist-generator.lua (source): I recommend you install this. It let's you add blocks to the ignore.list file by just placing them in front of the turtle, while the ignorelist-generator program is running.

oredict-sorter.lua (source): Requires an "oreDictionary" peripheral from Peripherals++ to work. I don't fully remember how this program works, but I used it to convert f.e. copper ingots from different mods into one kind.

testcode.lua: This is just whatever code I was trying/editing at the time. Not needed.

ignore.list (source): This is the ignore.list file I used for my quarries the last time I played. You might want to grab it edit to fit your needs. (Or use the ignorelist-generator to add blocks to it)

oredict.config (source): The last configuration for the ore-dictionary functionality of the quarry/the oredict-sorter that I used. You don't need this, unless you happen to play with the exact same combination of mods that I was 2 years ago.

Feel free to ask me any questions about the quarry or my other programs (https://pastebin.com/u/npexception). I'll try to answer them as best I can. :)

# Credit
https://www.reddit.com/r/feedthebeast/comments/kiziih/anyone_know_of_a_good_mining_turtle_program_that/
https://www.reddit.com/user/NPException/
