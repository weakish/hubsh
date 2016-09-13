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

Copy `bin/hubsh` to `$PATH`.

Usage
------

```sh
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
Auth token is stored in `$HOME/.config/hubsh`.
```

The `Auth token` is a GitHub personal access token.
You need to get it from GitHub > Settings.
`hubsh auth` will print out a short instruction for getting the token.

You can add alias in `.gitconfig`, e.g. point `git pr` to `hubsh pull-request`.

hubsh v.s. hub
--------------

hub is in Go, so it is supported on any platform supporting Go.
hubsh is in sh, so it is supported on any platform supporting curl and sh.

hubsh only implemented a small subset of hub features.
But there is one new feature `git-to-https`:
If some repository is cloned via `git://`, `git-to-https` will convert it to `https`.
(Useful for insecure network.)

`hubsh pull-request` is different to `hub pull-request`:

- A diffstat is appended to pull request message.
- hubsh will never bring you to an editor,
  it either use a file given by `-m`, or just the most recent (single) commit.
- hubsh's `-m` is equivalent to hub's `-F`, and hubsh has no option for `-m MESSAGE` in hub.
- hubsh does not support `-o` and `-f` in hub.

License
--------

0BSD
