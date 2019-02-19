# The array of all plugin repo comamnds.
_DO_SPHINX_REPO_CMDS=( "help" "clean" "build" "start" "watch" "stop" "status" "web" )


# Displays helps about how to run a repository sphinx commands.
#
function _do_sphinx_repo_help() {
    local proj_dir=$1
    local repo=$2

    echo "  
  ${repo}-sphinx-help: 
    See sphinx command helps

  ${repo}-sphinx-clean: 
    Cleans sphinx build output

  ${repo}-sphinx-build: 
    Builds sphinx documentation. The result is stored in doc/_build.

  ${repo}-sphinx-start: 
    Starts the sphinx web server as daemon, with live-reloading.

  ${repo}-sphinx-watch: 
    Watches the sphinx web server, with live-reloading.

  ${repo}-sphinx-stop: 
    Stops the sphinx web server, with live-reloading.

  ${repo}-sphinx-status: 
    Displays the sphinx status.

  ${repo}-sphinx-web: 
    Opens the sphinx web page.
"
}


# Cleans the repository sphinx output.
#
function _do_sphinx_repo_clean() {
    local proj_dir=$1
    local repo=$2

    local title="$repo: cleans sphinx build result"
    _do_print_header_2 $title

    if _do_sphinx_is_running; then 
        _do_print_error "Sphinx is running. ${repo}-sphinx-stop to stop the server first."
        return 1
    fi    

    _do_sphinx_build_ensured

    _do_sphinx_repo_cmd $proj_dir $repo "clean.sh"

    local err=$?
    _do_error_report $err "$title"
    return $err
}


# Builds the sphinx repository.
#
function _do_sphinx_repo_build() {
    local proj_dir=$1
    local repo=$2

    local title="$repo: Build html documentation with sphinx"
    _do_print_header_2 $title

    if _do_sphinx_is_running; then 
        _do_print_error "Sphinx is running. ${repo}-sphinx-stop to stop the server first."
        return 1
    fi    


    _do_sphinx_build_ensured


    _do_sphinx_repo_cmd $proj_dir $repo "build.sh"

    local err=$?
    _do_error_report $err "$title"
    return $err
}


# Starts the sphinx web server.
#
function _do_sphinx_repo_start() {
    local proj_dir=$1
    local repo=$2
    local opts=$3

    _do_log_info "sphinx" "start"
    
    _do_sphinx_build_ensured

    local title="$repo: Starts sphinx web server at http://localhost:${DO_SPHINX_PORT}"
    _do_print_header_2 $title

    _do_sphinx_repo_cmd $proj_dir $repo "--daemon" "start.sh"

    local err=$?
    _do_error_report $err "$title"
    return $err
}


# Watchs the sphinx web server. This will start the web server or 
# attach into the running sphinx daemon.
#
function _do_sphinx_repo_watch() {
    local proj_dir=$1
    local repo=$2

    _do_log_info "sphinx" "watch"
    
    if _do_sphinx_is_running; then 
        docker attach ${_DO_SPHINX_DOCKER_CONTAINER_NAME}

    else 
        _do_sphinx_build_ensured

        local title="$repo: Starts sphinx web server with live reloading at http://localhost:${DO_SPHINX_PORT}"
        _do_print_header_2 $title

        _do_sphinx_repo_cmd $proj_dir $repo "start.sh"
        return $?
    fi
}


# Stops the sphinx web server.
#
function _do_sphinx_repo_stop() {
    local proj_dir=$1
    local repo=$2
    
    local title="$repo: Sphinx stop"
    _do_print_header_2 $title 

    if _do_sphinx_is_running; then 
        docker kill ${_DO_SPHINX_DOCKER_CONTAINER_NAME} &> /dev/null
        local err=$?
        _do_error_report $err $title 
        return $err
    else 
        _do_print_warn "Already stopped"
    fi    
}


# Reports the sphinx web server status.
#
function _do_sphinx_repo_status() {
    local proj_dir=$1
    local repo=$2
    _do_print_header_2 "$repo: Sphinx status"

    if _do_sphinx_is_running; then 
        docker logs ${_DO_SPHINX_DOCKER_CONTAINER_NAME}    
        _do_print_finished "Sphinx is running at http://localhost:${DO_SPHINX_PORT}"
    else
        _do_print_warn "Sphinx is not running"
        return 0
    fi    
}


# Opens the web browser
#
function _do_sphinx_repo_web() {
    _do_log_info "sphinx" "web"

    if _do_sphinx_warn_not_running; then 
        return 1
    fi

    _do_print_header_2 "$repo: Open sphinx web at http://localhost:${DO_SPHINX_PORT}"

    _do_browser_open "http://localhost:${DO_SPHINX_PORT}"
}


# Determines if the specified directory has sphinx enabled.
# Arguments:
#   1. dir: A directory.
# 
# Returns: 
#   0 if sphinx enabled, 1 otherwise.
#
function _do_sphinx_repo_enabled() {
    local proj_dir=$1
    local repo=$2

    local doc_dir="$proj_dir/$repo/doc/"
    if [ -f "$doc_dir/conf.py" ] && [ -f "$doc_dir/index.rst" ]; then 
        return 0
        
    else 
        # Sphinx is enabled for the specified directory
        return 1
    fi 
}


# Initializes sphinx support for a repository.
#
function _do_sphinx_repo_init() {
    local proj_dir=$(_do_arg_required $1)
    local repo=$(_do_arg_required $2)

    if ! _do_sphinx_repo_enabled ${proj_dir} ${repo}; then 
        _do_log_debug "sphinx" "Skips sphinx support for '$repo'"
        # This directory does not have sphinx support.
        return
    fi 

    # Sets up the alias for showing the repo sphinx status
    _do_log_info "sphinx" "Initialize sphinx for '$repo'"

    # Register hooks for command repo life cycle command.
    _do_repo_plugin "${proj_dir}" "${repo}" "sphinx" _DO_SPHINX_REPO_CMDS 
}


# Runs any sphinx command in docker.
# Arguments:
#   1. repo: The repository name.
#
function _do_sphinx_repo_cmd() {
    local proj_dir=$1
    shift

    local repo=$1
    shift

    local daemon_opts=""

    if [ "$1" == "--daemon" ]; then 
        daemon_opts="-d"
        shift
    fi 

    local cmd=$@

    local repo_dir=${proj_dir}/${repo}

    docker run --rm ${daemon_opts} \
        --name="${_DO_SPHINX_DOCKER_CONTAINER_NAME}"\
        -p=${DO_SPHINX_PORT}:${DO_SPHINX_PORT} \
        -e DO_ENVIRONMENT=${DO_ENVIRONMENT} \
        -v ${repo_dir}/doc:/app/src \
        -w=/app/src \
        -it ${_DO_SPHINX_DOCKER_IMG} ${cmd}
    
    return $?
}
