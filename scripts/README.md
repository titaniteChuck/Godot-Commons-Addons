# Addons synchronizer

## What it does
From the admitted way of handling addons as submodules, I use the following folder structure:
```bash
project
    |- addons_submodules
        |- .gdscript         # to hide it from godot
        |- addon1-repo       # cloned as git submodule, can be updated, commited, change branch
                |- addons
                    |- addon1
                        |- project.cfg
    |- addons
        |- addon1 -> ../addons_submodules/addon1-repo/addons/addon1 # symbolic link

    |- scripts
        |- sync_addons.bash # script that does it all
    
    |- .gitignore
            |+ addons/adon1 # ignores the symlink so that a fresh checkout of the project does not embed them 
```

The script `scripts/sync_addons.bash` does the following actions:
- `git submodule init`: in case you already have submodules defined in .gitmodules, but you just checkout'ed the repo, this command must be ran once
- **Remove submodules not in the list**: By iterating over folders in `addons_submodule/`, we can clean those that are not in the list
- `git submodule update`: Now all remaining folders are wanted, I update the sources
- **Add new submodules**: 
    - `git submodule add <git_repo_url>`: to add a new repo as git submodule
    - `find` the folder containing the `.cfg` file, thus supporting any repository structure. Some develop in root, others create an `addons` folder
    - Create the symbolic link `addons/<symlink>` -> `addons_submodules/...` for godot to detect the addon
    - Add an entry to .gitignore for only this addon, so if you have some of your own, they won't be ignored 

> ### **/!\ Important to note**:
> This script also supports multiple plugins being present in the same repository. It will link them all seemlessly in godot addons folder 

## How to use

### Prerequisites
- Be able to do a `git clone` from the command line, this script does not handle authentication
- Windows: I have succesfully tested this script using [Git bash](https://gitforwindows.org/)
    - HOWEVER, you MUST have enabled the "enable symlink" option. See [this issue](https://github.com/orgs/community/discussions/23591#discussioncomment-3241019)

> ### **/!\ Important to note**:
> running the script with WSL WILL NOT WORK as expected because symlinks created by wsl are not recognized by windows. See [this article](https://blog.trailofbits.com/2024/02/12/why-windows-cant-follow-wsl-symlinks/)

### Run the tool
1. Edit the `scripts/sync_addons.bash` file, and list your plugins in the `ADDONS_LIST` list.
```bash
ADDONS_LIST=(
    git@github.com:poohcom1/godot-run-configs.git   # will be synced
    # git@github.com:rylydou/godot-run-preset.git   # will be ignored / removed if present
)
```
2. From anywhere, for example in root project, run the script
```bash
./scripts/sync_addons.bash
``` 