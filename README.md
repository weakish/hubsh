hubsh is a command line GitHub API client in sh

Features
--------

- clone `[USER/]REPO`
- create
- fork and pull-request

Install
--------

### Dependencies

- curl
- git
- sh

### With `make`

```sh
; git clone https://github.com/weakish/hubsh
; cd hubsh
; make
```

Files will be installed to `/usr/local/bin`.
If you want to install other place, edit `config.mk` before running `make`.

Makefile is compatible with both GNU make and BSD make.

### With basher

```sh
; basher install weakish/gister
```

### Manually

Copy `bin/hubsh` and `bin/gogsh` to `$PATH`.

Usage
------

```
; hubsh --help
hubsh -- GitHub API client in sh

hubsh [ACTION]

Actions:
auth         check if github acess token is available
clone        supports clonning from `github_user/repo` and `repo` (your own repo)
create       create this repository on GitHub and add GitHub as origin
fork         make a fork of a remote repository on GitHub and add as remote
git-to-https convert github original from `git://` to `https://`
pull-request send a pull request at GitHub
whoami       show github username
version      show version
help         this help page

Options for sub commands:
clone        [USER/]REPO
create       [-n NAME] [-d DESCRIPTION] [-u HOMEPAGE] [-p] [-I] [-W] [-D]
             (p: private, I: disable issue, W: disable wiki, D: disable download)
git-to-https [-u BRANCH] (also change BRANCH tracking, BRANCH defaults to `master`)
pull-request [-b BASE_BRANCH] [-h HEAD_BRANCH] [[-m MESSAGE_FILE] | [-i ISSUE]]
             (If `-m` is supplied, the first line of the file will become the subject,
             the third line to end of file will become the description. If `-m` is not
             supplied, message will use the most recent (single) commit message.)

Files:

Auth token is queried in the following order:

- Environment variable `$GITHUB_OAUTH_TOKEN`
- content of file `$GITHUB_OAUTH_FILE`
- content of file `~/.config/hubsh`
- content of file `~/.config/hub`

`hubsh install` will install the following aliases:
create fork git-to-https get pull-request pr
If you have already defined aliases above, `hubsh` will keep the original one.
```

The `Auth token` is a GitHub personal access token.
You need to get it from GitHub > Settings.
`hubsh auth` will print out a short instruction for getting the token.

You can add alias in `.gitconfig`, e.g. point `git pr` to `hubsh pull-request`.

hubsh versus hub
----------------

hub is in Go, so it is supported on any platform supporting Go.
hubsh is in sh, so it is supported on any platform supporting curl and sh.

hubsh only implemented a small subset of hub features.
But there is one new feature `git-to-https`:
If some repository is cloned via `git://`, `git-to-https` will convert it to `https`.
(Useful for insecure network.)

`hubsh pull-request` is different to `hub pull-request`:

- A diffstat is appended to pull request message.
- hubsh will never bring you to an editor,
  it either use a file given by `-m`, or just the most recent (single) commit message.
- hubsh's `-m` is equivalent to hub's `-F`, and hubsh has no option for `-m MESSAGE` in hub.
- hubsh does not support `-o` and `-f` in hub.

`hubsh create` is also different:

- Instead of `hub create [NAME]`, use `hubsh [-n NAME]`.
- hubsh has `-I`, `-W`, `-D` to disable issue, wiki, and downloads.
- If `-d` is not given, `hubsh` will use first line of README.
- hubsh does not support create repo under organization yet (pull request welcome).

gogsh
-----

There is also a client to gogs server -- `gogsh`.
`gogsh` is a simplified brother of `hubsh`.
It supports fewer actions and options.

gh
--

hubsh was written years before GitHub introduced [gh] as its official command line tool.
Previously, the official tool for GitHub is `hub`, first written in Ruby, then in Go.
I do not use hubsh anymore.
I switched to [gh].

[gh]: https://github.com/cli/cli

### Usage

```
gogsh -- Gogs API client in sh

gogsh [ACTION]

Actions:
auth         check if gogs acess token is available
clone        supports clonning from `gogs_user/repo` and `repo` (your own repo)
create       create this repository on GitHub and add GitHub as origin
whoami       show gogsh username (specified in `$GOGS_USER`)
version      show version
help         this help page

gogs server is specified in `$GOGS_SERVER`.
If not specified, it defaults to `http://127.0.0.1:3000`.

Auth token is queried in the following order:

- Environment variable `$GOGS_OAUTH_TOKEN`
- content of file `$GOGS_OAUTH_FILE`
- content of file `~/.config/gogsh`
```

License
--------

0BSD
