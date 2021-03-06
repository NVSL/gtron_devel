function banner () {
    echo
    echo "========================================================"
    builtin echo "$@" 
    echo "========================================================"

}

function request () {
    echo
    echo "===================== TAKE ACTION! ====================="
    builtin echo "$@"
    echo "========================================================"

}

function error () {
    echo
    echo "===================== FAILURE: ========================="
    builtin echo "$@"
    echo "========================================================"
    exit 1
}

function verify_success() {
    if ! [ ${PIPESTATUS[0]} -eq 0 ]; then
	error "Command failed"
	exit 1
    fi
}

function do_cmd() {
    if [ "$dry_run." = "yes." ]; then
	echo
	echo "$@"
    else
	$@
    fi
}

function save_log () {
    mkdir -p ../logs
    if [ "$verbose." = "yes." ]; then
	if [ ".$1" = ".-a" ];then
	    tee -a ../logs/$2.gtron-log.txt
	else
	    tee ../logs/$1.gtron-log.txt
	fi
    else
	if [ ".$1" = ".-a" ];then
	    cat >> ../logs/$2.gtron-log.txt
	else
	    cat > ../logs/$1.gtron-log.txt
	fi
    fi
}

function redirect () {
    if [ "$verbose." = "yes." ]; then
	if [ ".$1" = ".-a" ];then
	    tee -a $2
	else
	    tee $1
	fi
    else
	if [ ".$1" = ".-a" ];then
	    cat >> $2
	else
	    cat > $1
	fi
    fi
}

function get_rcs_proto() {
    if echo $1 | grep -q 'svn+ssh'; then
	echo "SVN"
    elif echo $1 | grep -q 'git@'; then
	echo "GIT"
    else
	echo "UNKNOWN"
    fi
}

function do_checkout() {
    echo Deprecated
    RCS=$(get_rcs_proto $1)
    if [ "$RCS" = "GIT" ]; then
	do_cmd git clone $1
    elif [ "$RCS" = "SVN" ]; then
	do_cmd svn co $1
    fi
}

function get_rcs_dir() {
    dir=${1%.git}
    dir=${dir##*/}
    echo $dir
}

function do_update() {
    echo Deprecated
    RCS=$(get_rcs_dir $1)
    if [ -d $RCS/.git ]; then
	(do_cmd cd $RCS; do_cmd git pull $1)
	return 0
    elif [ -d $RCS/.svn ]; then
	(do_cmd cd $RCS; do_cmd svn update)
	return 0
    else
	echo "$RCS doesn't exist"
	return 1;
    fi
}

function get_or_update() {
    echo Deprecated
    p=$1
    dir=$(get_rcs_dir $1)

    do_cmd rm -f update.log
    (if [ -d "$dir" ]; then
	 do_update $p 
     else
	 do_checkout $p
     fi) 2>&1 | redirect get_or_update.log
    
    RET=${PIPESTATUS[0]}
    if [ "$RET" != 0 ]; then
	print_failure FAIL
    else
	print_success PASS
    fi	

    do_cmd mv get_or_update.log $dir
    
}

function run_make() {
    echo Deprecated
    d=$1
    if [ -f "$d/Makefile" -o -f "$d/makefile" ]; then
	if [ -f "${d}/NO_CLEAN" ]; then
	    (do_cmd cd "${d}"; do_cmd make)
	    return $?
	else
	    (do_cmd cd "${d}"; do_cmd make clean; do_cmd make) 
	    return $?
	fi
    else
	echo "Nothing to build"
	RET="nobuild"
	return 255
    fi 2>&1
}

function position_cursor() {
    # "Carriage return" followed by "Cursor forward 60".
    # This sets cursor to column 60. tput hpa 60 should do the same, but I
    # couldn't get it to work.

    if [ "`uname`" != "Linux" ]; then
	tput cr; tput cuf 60
    else
	tput hpa 60
    fi
}

function print_failure() {
    position_cursor
    echo -n '['
    tput setaf 1 # Set foreground color to red, using ANSI escapes
    echo -n $@
    tput sgr0
    echo ']'
}

function print_success() {
    position_cursor
    echo -n '['
    tput setaf 2 # Set foreground color to green, using ANSI escapes
    echo -n $@
    tput sgr0
    echo ']'
}

function build () {
    echo Deprecated
    d=$(get_rcs_dir $1)
    if [ "$1" == "--nobuild" ]; then
	shift
	echo "Nothing to build" | redirect $d/build.log
	RET=255 
    else
	run_make $d | redirect $d/build.log
	RET=${PIPESTATUS[0]}
    fi
    
    if [ "$RET" = '255' ]; then
	print_success  'NO BUILD'
    elif [ "$RET" != 0 ]; then
	print_failure "FAIL"
    else
	print_success "PASS"
    fi
}

function confirm_venv() {
    if ! gtron.py sanity_check; then
	error "Not in \$GADGETRON_VENV virtual env.  Quiting."
	exit 1
    fi
}

function confirm_gadgetron() {
    if [ "$GADGETRON_ROOT." = "." ]; then
	error "\$GADGETRON_ROOT not set.  Quiting."
	exit 1
    fi
}

function start_ssh_agent() {
    eval `ssh-agent`
    ssh-add
}
