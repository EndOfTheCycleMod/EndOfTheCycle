# End of the Cycle

A strategy overhaul for XCOM 2: War of the Chosen.

## Status

This mod is currently in pre-alpha. Heavy development needed.

## Building

Checkout this repository with

```git clone --recurse-submodules https://github.com/EndOfTheCycleMod/EndOfTheCycle.git```

[Visual Studio Code](https://code.visualstudio.com/) is recommended to build the mod.  
There are a number of UnrealScript syntax highlighting plugins available.

You need to setup Visual Studio code settings to point to the Game and SDK directories:

    "xcom.highlander.gameroot": "E:\\SteamLibrary\\steamapps\\common\\XCOM 2\\XCom2-WarOfTheChosen",
    "xcom.highlander.sdkroot": "E:\\SteamLibrary\\steamapps\\common\\XCOM 2 War of the Chosen SDK"

Then, hit `Ctrl+Shift+B` and choose `buildHighlander` to build the Highlander submodule.  
Choose `build` to build the main mod.

### Building without VS Code

`.vscode/tasks.json` has the build commands.

## Other useful tips

Add keyboard shortcuts to the `debug` and `runUnrealEditor` tasks via `Ctrl+K, Ctrl+S` and clicking `keybindings.json`. A debug shortcut might look something like this:

    {
        "key": "ctrl+h",
        "command": "workbench.action.tasks.runTask",
        "args": "Run tests"
    }

## TODO

Everything. Contributions welcome.