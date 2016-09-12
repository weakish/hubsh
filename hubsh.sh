#!/bin/sh

set -e  # errexit
set -u  # nounset


VERSION=0.0.0

hub_help() {
cat<<'END'
hubsh -- GitHub API client in sh

hubsh [ACTION]

Actions:
clone    supports clonning from `github_user/repo` and `repo` (your own repo)
whoami   show github username
version  show version
help     this help page

Files:
Auth token is stored in `$HOME/.config/hubsh`.
END
}

hub_debug() {
    set -x
    export isDebugging='on'
    local debuggingFunction="$1"
    shift 1
    $debuggingFunction "$@"
}

# Usage: eval `_valueOf variable function`
_conditionalAssign() {  # (Variable, Function) -> Variable
    local variable="$1"
    local f="$2"
    echo "$variable=\${$variable:=\$($f)}; echo \$$variable"
    # We do not combine the above two lines into one `echo ${variable:=$(f)}`
    # because we want to exit immediately if `variable` is empty (`set -u`).
}

_hubUser() {
    eval `_conditionalAssign github_user hub_whoami`
}

_authToken() {
    eval `_conditionalAssign github_token hub_auth`
}

_errorUnimplemented() {
    echo 'Not implemented yet. Pull request is welcome.'
    exit 70  # EX_SOFTWARE
}

# A wrapper of curl.
# Usage:
#
#     _request /api/path  # GET
#     _request /api/path POST '{"json": "value"}'
_request() {
    local path="$1"
    local method=${2:-GET}
    local param="${3:-{\}}"
    local verbosity

    GITHUB_API_ROOT='https://api.github.com'
    GITHUB_API_VERSION='Accept: application/vnd.github.v3+json'

    curlDebug=${curlDebug:-sS}
    path="$GITHUB_API_ROOT$path"

    case "$method" in
        HEAD | head) requestingHead=true; _errorUnimplemented ;;
        GET | get) requestingGet=true; _errorUnimplemented ;;
        POST | post) requestingPost=true; writable=true ;;
        PUT | put) requestingPut=true; writable=true; _errorUnimplemented ;;
        DELETE | delete) requestingDelete=true; _errorUnimplemented ;;
        CONNECT | connect) requestingConnect=true; _errorUnimplemented ;;
        OPTIONS | options) requestingOptions=true; _errorUnimplemented ;;
        TRACE | trace) requestingTrace=true; _errorUnimplemented ;;
        PATCH | patch) requestingPatch=true; writable=true; _errorUnimplemented ;;
    esac

    if [ $isDebugging = 'on' ]; then
        verbosity=-v
    else
        verbosity=-sS
    fi

    curl "$verbosity" \
        -H "$GITHUB_API_VERSION" \
        -H "Authorization: token $(_authToken)" \
        ${writable:+--data "$param"} \
        -X "$method" \
        "$path"
}

_getOriginalRepo() {
    ownerRepo=$(
        git remote -v |
            grep -m 1 -F origin |
            cut -f 2 | cut -d ' ' -f 1 |
            sed -e 's#https://github.com/##' |
            sed -e 's#git://github.com/##' |
            sed -e 's/git@github.com://'
    )
    ownerRepo=${ownerRepo%.git}
    echo $ownerRepo
}

_getOwnerRepo() {
    local githubUser=$(_hubUser)
    ownerRepo=$(
        git remote -v | grep -E "github\.com[:/]$githubUser/" |
            grep -E -o "$githubUser/[^ ]+"
    )
    ownerRepo=${ownerRepo%.git}
    echo ownerRepo
}

_getCurrentBranch() {
    git branch 2> /dev/null | grep -F '*' | sed 's/^\* //'
}

_currentBranch() {
    eval `_conditionalAssign currentBranch _getCurrentBranch`
}

_convertIssueToPullRequest() {
    _request $apiUrl POST\
        "{\"issue\": \"$issue\", \"base\": \"$base\", \"head\": \"$head\"}"
}

_newPullRequest() {
    local subject
    local body

    if [ -f "$message" ]; then
        subject=$(sed 1q "$message")
        body=$(seq -n '3,$p' "$message")
    else
        remoteBranch=$(echo $head | tr ':' '/')
        subject=$(git log -1 --format=%s $remoteBranch)
        body=$(git log -1 --format=body $remoteBranch)
    fi
    local diffStat=$(git diff --no-color -M --stat --summary $base $head)
    body=$(
        cat<<END
$body

---
$diffStat
END
    )"
    body=$(_jsonify "$body")
    _request $apiUrl POST \
        "{\"title\": \"$subject\", \"base\": \"$base\", \"head\": \"$head\", \"body\": \"$body\"}"
}

# Convert newline to `\n`.
_jsonify() {
    local inputString="$1"
    # Use `\t` (Tab) as intermediate character
    # because it is not used within HTML elements anyway.
    echo -n "$inputString" | tr '\n' '\t' | sed 's/\t/\\n/g'
}


hub_auth() {
    cat ${XDG_CONFIG_HOME:-$HOME/.config}/hubsh ||
    (
        cat<<'END' >&2
Error: OAuth token not found.
https://github.com/settings/tokens
And paste the token value in
~/.config/hubsh
END
        exit 77  # EX_NOPERM
    )
}

hub_clone() {
    if [ -d "$1" ]; then
        git clone "$1";
    else
        case "$1" in
            */*) git clone https://github.com/"$1".git ;;
            *) git clone git@github.com:$(_hubUser)/"$1".git ;;
        esac
    fi
}

# Usage: hub_create [name=NAME] [other=PARAMETER] ...
# Note: Give 'name=NAME' before any other parameters.
hub_create() {
    local name

    local apiUrl="/$(_hubUser)/repos"

    # `name` is required in GitHub API.
    if [ $# -eq 0 ]; then
        name=$(pwd)
    else
        case "$1" in
            name=*) name="${1:#name=}"
        esac
        name=${name:-$(pwd)}
    fi

    echo "name=$name $@" | _request $apiUrl post
}

hub_fork() {
    ownerRepo
    if [ $# -eq 0 ]; then
        ownerRepo=$(_getOwnerRepo)
    else
        ownerRepo="$1"
        hub_clone $ownerRepo
    fi
    local apiUrl="/repos/$ownerRepo/forks"

    _request $apiUrl post
}

# Usage: echo optional_message | hub_pull_request [-i issueNumber | -b master ]
hub_pull_request() {
    ownerRepo=$(_getOwnerRepo)
    local apiUrl="/repos/$ownerRepo/pulls"

    local base
    local head
    local message
    local issue
    while getopts b:h:m:i: option; do
        case "$option" in
            b) base="${OPTARG:-master}" ;;
            h) head="${OPTARG:-$(_hubUser):$(_currentBranch)}" ;;
            m) message="$OPTARG" ;;
            i) issue="$OPTARG" ;;
        esac
    done
    if [ -n $issue ]; then
        _newPullRequest
    else
        _convertIssueToPullRequest
    fi
}

hub_whoami() {
    git config --global github.user 2> /dev/null ||
    (
        echo 'We do not know your username on GitHub.' >&2
        echo 'Setup it via `git config --global github.user USERNAME.`' >&2
        exit 67  # EX_NOUSER
    )
}


export isDebugging=off
case "$1" in
    auth) hub_auth ;;
    clone) hub_clone "$2" ;;
    create) hub_create "$@" ;;
    fork) hub_fork ;;
    pull-request) hub_pull_request ;;
    whoami) hub_whoami ;;
    version) echo $VERSION;;
    help) hub_help ;;
    debug) shift 1; hub_debug "$@";;
    *) hub_help ;;
esac
