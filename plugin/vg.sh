_do_plugin "proj"

# Docker Supports
_do_log_level_warn "vg"


# ==============================================================================
# Proj plugin integration
# ==============================================================================

# If the specified repository has a file "Dockerfile", vg is enabled for 
# the repository. 
#
function _do_vg_repo_enabled() {
    local proj_dir=$1
    local repo=$2

    if [ -f "${proj_dir}/${repo}/Vagrantfile" ]; then 
        # Vagrant integration is enabled for this repository.
        return 0
    else
        return 1
    fi
}
 
# Initializes vg support for a repository.
#
function _do_vg_repo_init() {
    local proj_dir=$1
    local repo=$2

    if ! _do_vg_repo_enabled "${proj_dir}" "${repo}"; then 
        return
    fi

    _do_log_debug "vg" "Initializes vg integration for $repo"

    _do_repo_alias_add $proj_dir $repo "vg" "help start stop ssh destroy" 
}


# Displays helps for vg supports.
#
function _do_vg_repo_help() {
    local proj_dir=$1
    local repo=$2
    local mode=$3

    if ! _do_vg_repo_enabled "${proj_dir}" "${repo}"; then 
        return
    fi

    if [ "${mode}" = "--short" ]; then 
        echo "  ${repo}-vg-help: See vg command helps"
        return
    fi 

    echo -e "Vagrant Helps
    ${repo}-vg-help:
        Prints this help.

    ${repo}-vg-start:
        Vagrant up the machine.

    ${repo}-vg-stop:
        Vagrant down the machine.

    ${repo}-vg-ssh:
        Ssh into the vagrant machine.

    ${repo}-vg-destroy:
        Destroy the vagrant machine.
    "
}

# Starts vagrant machine.
function _do_vg_repo_start() {

    if ! _do_vg_repo_enabled "${proj_dir}" "${repo}"; then 
        return
    fi

    _do_repo_cmd $@ "vagrant up"
}

# Stops vagrant machine.
function _do_vg_repo_stop() {

    if ! _do_vg_repo_enabled "${proj_dir}" "${repo}"; then 
        return
    fi

    _do_repo_cmd $@ "vagrant halt"
}

# Ssh to vagrant machine.
function _do_vg_repo_ssh() {

    if ! _do_vg_repo_enabled "${proj_dir}" "${repo}"; then 
        return
    fi    
    
    _do_repo_cmd $@ "vagrant ssh"
}

# Destroy vagrant machine.
function _do_vg_repo_destroy() {

    if ! _do_vg_repo_enabled "${proj_dir}" "${repo}"; then 
        return
    fi

    _do_repo_cmd $@ "vagrant destroy"
}

# ==============================================================================
# Plugin Init
# ==============================================================================
function _do_vg_plugin_init() {
    _do_log_info "vg" "Initialize plugin"
    _do_repo_cmd_hook_add "vg" "init help"
}
