#!/bin/bash
set -e # script fails at first error
# set -x # prints every line evaluated

SCRIPT_ARGS=$@

export MSYS=winsymlinks:nativestrict #for git bash windows to make proper ln. Note: Git bash must have been installed with "enabled symlinks" ticked

SCRIPT_DIR=$(dirname "${0}")
PROJECT_ROOT="${SCRIPT_DIR}/.."
GIT_SUBMODULE_FOLDER=$(realpath --relative-to=$PWD ${PROJECT_ROOT}/addons_submodules)
GODOT_ADDONS_FOLDER=$(realpath --relative-to=$PWD ${PROJECT_ROOT}/addons)
GITIGNORE=$(realpath --relative-to=$PWD ${PROJECT_ROOT}/.gitignore)

ADDONS_LIST=(
    git@github.com:huwpascoe/godot_resource_path.git # used to store resources UIDs, that follow file move
    git@github.com:EiTaNBaRiBoA/JsonClassConverter.git # used by the save_maager to convert to/from json
    # git@github.com:jhlothamer/godot_game_state_saver_plugin.git
)

main() {
    echo "(1/5) Creating the folders structure if not present..."
    _init_directories

    echo -e "\n(2/5) Exec 'git submodule init' in case it had not been done before... "
    git submodule init

    echo -e "\n(3/5) Start removal of all installed addons that are not on the list..."
    remove_unused_submodules

    echo -e "\n(4/5) Exec 'git submodule update' to get the latest versions branches... "
    git submodule update

    echo -e "\n(5/5) Start installation of all wanted addons..."
    install_new_modules
}

_init_directories() {
    mkdir -p $GIT_SUBMODULE_FOLDER
    mkdir -p $GODOT_ADDONS_FOLDER
    ([[ $(tail -c1 $GITIGNORE) && -f $GITIGNORE ]] && echo '' >> $GITIGNORE) || true # ensures gitignore ends with a newline
}


remove_unused_submodules() {
    for submodule_path in ${GIT_SUBMODULE_FOLDER}/*/; do
        local present_submodule_name=$(basename ${submodule_path})
        if [[ "${present_submodule_name}" == "*" ]]; then
            continue
        fi
        
        if ! $(_array_contains "$ADDONS_LIST" "${present_submodule_name}"); then
            echo "--------------------------------------------------------------------------"
            echo -e "Removing submodule [$submodule_path]"
            echo "--------------------------------------------------------------------------"
            
            local addons_in_submodule=($(find ${submodule_path} -name plugin.cfg -exec dirname {} \;))
            for addon_folder_in_submodule in "${addons_in_submodule[@]}" ; do
                echo -e "\nAddon detected: [$(basename $addon_folder_in_submodule)]"
                _delete_symlink $addon_folder_in_submodule
                _remove_entry_from_gitignore $addon_folder_in_submodule
            done

            _uninstall_submodule $submodule_path
        fi
    done
}

install_new_modules() {
    for addon_git_path in "${ADDONS_LIST[@]}" ; do
        
        local submodule_path=$(_install_submodule $addon_git_path)
        echo "--------------------------------------------------------------------------"
        echo -e "Installing submodule [$submodule_path]"
        echo "--------------------------------------------------------------------------"

        local addons_in_submodule=($(find ${submodule_path} -name plugin.cfg -exec dirname {} \;))
        for addon_folder_in_submodule in "${addons_in_submodule[@]}" ; do
            echo -e "\nAddon detected: [$(basename $addon_folder_in_submodule)]"
            _create_symlink $addon_folder_in_submodule
            _add_entry_to_gitignore $addon_folder_in_submodule
        done

    done
}

#######################################

_array_contains() {
    array=$1 ; to_find=$2
    for visitor in "${array[@]}" ; do
        if [[ ${visitor} == *"${to_find}"* ]]; then
            echo true
            return
        fi
    done
    echo false
}

#######################################

_install_submodule() {
    git_repo_full_url=$1 
    git_repo_project_name=$(basename ${git_repo_full_url})
    git_repo_project_name="${git_repo_project_name%.*}"
    git_repo_clone_folder=${GIT_SUBMODULE_FOLDER}/${git_repo_project_name}

    if ! test -d "${git_repo_clone_folder}"; then
        git submodule add --force ${git_repo_full_url} ${git_repo_clone_folder} > /dev/null
    fi
    echo ${git_repo_clone_folder}
}
_uninstall_submodule() {
    uninstall_path=$1
    git rm $SCRIPT_ARGS ${uninstall_path} > /dev/null
}

#######################################

_create_symlink() {
    addon_folder_in_submodule_dir=$1
    addon_folder_name=$(basename ${addon_folder_in_submodule_dir})
    addon_folder_in_godot_addons_dir=${GODOT_ADDONS_FOLDER}/${addon_folder_name}

    echo "Creating symlink [${addon_folder_in_submodule_dir}] <-> [${addon_folder_in_godot_addons_dir}]"
    if ! test -L "${addon_folder_in_godot_addons_dir}"; then
        ln -s ${PWD}/${addon_folder_in_submodule_dir} ${addon_folder_in_godot_addons_dir}
    fi
}
_delete_symlink() {
    addon_folder_in_submodule_dir=$1
    addon_folder_name=$(basename ${addon_folder_in_submodule_dir})
    addon_folder_in_godot_addons_dir=${GODOT_ADDONS_FOLDER}/${addon_folder_name}
    echo "Deleting symlink [${addon_folder_in_godot_addons_dir}]"
    rm -f ${addon_folder_in_godot_addons_dir}
}

#######################################

_add_entry_to_gitignore() {
    addon_gitignore_entry=addons/$(basename $1)
    echo "Adding entry [$addon_gitignore_entry] to .gitignore"
    if ! grep -Fxq "${addon_gitignore_entry}" ${GITIGNORE}; then
        echo $addon_gitignore_entry >> ${GITIGNORE}
    fi
}
_remove_entry_from_gitignore() {
    addon_gitignore_entry=addons/$(basename $1)
    echo "Removing entry [$addon_gitignore_entry] from .gitignore"
    sed -i "\\|$addon_gitignore_entry|d" ${GITIGNORE}
}

#######################################

main