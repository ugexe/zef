## Zef

Raku / Perl6 Module Management

# Installation

#### Manual

    $ git clone https://github.com/ugexe/zef.git
    $ cd zef
    $ raku -I. bin/zef install .

#### Rakubrew

To install via rakubrew, please use the following command:

    $ rakubrew build-zef

# USAGE

    zef --help
    zef --version

    # install the CSV::Parser distribution
    zef install CSV::Parser

    # search for distribution names matching `CSV`
    zef search CSV

    # detailed information for a matching distribution
    zef info CSV::Parser

    # list all available distributions
    zef list

    # list reverse dependencies of an identity
    zef rdepends HTTP::UserAgent

    # test project in current directory
    zef test .

    # fetch a specific module only
    zef fetch CSV::Parser

    # fetch a module, then shell into its local path
    zef look CSV::Parser

    # smoke test modules from all repositories
    zef smoke

    # run Build.pm if one exists in given path
    zef build .

    # update Repository package lists
    zef update

    # upgrade all distributions (BETA)
    zef upgrade

    # upgrade specific distribution (BETA)
    zef upgrade CSV::Parser

    # lookup module info by name/path/sha1
    zef --sha1 locate 9FA0AC28824EE9E5A9C0F99951CA870148AE378E

    # launch browser to named support urls from meta data
    zef browse zef bugtracker

## More CLI

#### **install** \[\*@identities\]

Note: The install process does not install anything until all phases have completed. So, if the user requested to
`install A`, and A required module B: both would be downloaded, potentially built, tested, and installed -- but only
if both passed all their tests. For example: if module A failed its tests, then module B would not be installed
(even if it passed its own tests) unless forced.

\[`@identities`\] can take the form of a file path (starting with **.** or **/**), URLs, paths, or identities:

    # IDENTITY
    zef install CSV::Parser
    zef install "CSV::Parser:auth<tony-o>:ver<0.1.2>"
    zef install "CSV::Parser:ver<0.1.2>"

    # PATH
    zef install ./Perl6-Net--HTTP

    # URL
    zef -v install https://github.com/ugexe/zef.git
    zef -v install https://github.com/ugexe/zef/archive/master.tar.gz
    zef -v install https://github.com/ugexe/zef.git@v0.1.22

A request may contain any number and combination of these. Paths and URLs will be resolved first so they are available
to fulfill any dependencies of other requested identities.

**Options**

    # Install to a custom locations
    --install-to=<id> # site/home/vendor/perl, or
    -to=<id>          # inst#/home/some/path/custom

    # Install all transitive and direct dependencies
    # even if they are already installed globally (BETA)
    --contained

    # Load a specific Zef config file
    --config-path=/some/path/config.json

    # Install only the dependency chains of the requested distributions
    --deps-only

    # Ignore errors occuring during the corresponding phase
    --force-resolve
    --force-fetch
    --force-extract
    --force-build
    --force-test
    --force-install

    # or set the default to all unset --force-* flags to True
    --force

    # Set the timeout for corresponding phases
    --fetch-timeout=600
    --extract-timeout=3600
    --build-timeout=3600
    --test-timeout=3600
    --install-timeout=3600

    # Number of simultaneous distributions/jobs to process for the corresponding phases
    --fetch-degree=5
    --test-degree=1

    # or set the default to all unset --*-timeout flags to 0
    --timeout=0

    # Do everything except the actual installations
    --dry

    # Build/Test/Install each dependency serially before proceeding to Build/Test/Install the next
    --serial

    # Disable testing
    --/test

    # Disable build phase
    --/build

    # Disable fetching dependencies
    --/depends
    --/build-depends
    --/test-depends

    # Force a refresh for all module index indexes
    --update

    # Force a refresh for a specific ecosystem module index
    --update=[ecosystem]

    # Skip refreshing all module index indexes
    --/update

    # Skip refreshing for a specific ecosystem module index
    --/update=[ecosystem]

**ENV Options**

    # Number of simultaneous distributions/jobs to process for the corresponding phases (see: --[phase]-degree options)
    ZEF_FETCH_DEGREE=5
    ZEF_TEST_DEGREE=1

    # Set the timeout for corresponding phases (see: --[phase]-timeout options)
    ZEF_FETCH_TIMEOUT=600
    ZEF_EXTRACT_TIMEOUT=3600
    ZEF_BUILD_TIMEOUT=3600
    ZEF_TEST_TIMEOUT=3600
    ZEF_INSTALL_TIMEOUT=3600

    # Path to config file (see: --config-path option)
    ZEF_CONFIG_PATH=$PWD/resources/config.json

#### **uninstall** \[\*@identities\]

Uninstall the specified distributions

Note: Requires a bleeding edge rakudo (not available in 6.c)

#### **update**

Update the package indexes for all `Repository` backends

Note: Some `Repository` backends, like the default Ecosystems, have an `auto-update` option
in `resources/config.json` that can be enabled. This should be the number of hours until it should
auto update based on the file system last modified time of the ecosystem json file location.

#### **upgrade** \[\*@identities\] _BETA_

Upgrade specified identities. If no identities are provided, zef attempts to upgrade all installed distributions.

#### **search** \[$identity\]

How these are handled depends on the `Repository` engine used, which by default is `Zef::Repository::Ecosystems>p6c<`

    $ zef -v search URI
    ===> Found 4 results
    -------------------------------------------------------------------------
    ID|From                              |Package             |Description
    -------------------------------------------------------------------------
    1 |Zef::Repository::LocalCache       |URI:ver<0.1.1>    |A URI impleme...
    2 |Zef::Repository::Ecosystems<p6c>  |URI:ver<0.1.1>    |A URI impleme...
    3 |Zef::Repository::Ecosystems<cpan> |URI:ver<0.1.1>    |A URI impleme...
    4 |Zef::Repository::Ecosystems<cpan> |URI:ver<0.000.001>|A URI impleme...
    -------------------------------------------------------------------------

#### **info** \[$identity\]

View meta information of a distribution

    $ zef -v info HTTP::UserAgent
    - Info for: HTTP::UserAgent
    - Identity: HTTP::UserAgent:ver<1.1.16>:auth<github:sergot>
    - Recommended By: Zef::Repository::LocalCache
    Author:  github:sergot
    Description:     Web user agent
    Source-url:      https://github.com/sergot/http-useragent.git
    Provides: 11 modules
    #       HTTP::Cookie
    #       HTTP::Header
    #       HTTP::Cookies
    #       HTTP::Message
    #       HTTP::Request
    #       HTTP::Response
    #       HTTP::MediaType
    #       HTTP::UserAgent
    #       HTTP::Header::Field
    #       HTTP::Request::Common
    #       HTTP::UserAgent::Common
    Depends: 7 items
    ---------------------------------
    ID|Identity           |Installed?
    ---------------------------------
    1 |HTTP::Status       |✓
    2 |File::Temp         |✓
    3 |DateTime::Parse    |✓
    4 |Encode             |✓
    5 |MIME::Base64       |✓
    6 |URI                |✓
    7 |IO::Capture::Simple|✓
    ---------------------------------

**Options**

    # Extra details (eg, list dependencies and which ones are installed)
    -v

#### **list** \[\*@from\]

List known available distributions

    $ zef --installed list
    ===> Found via /home/foo/.rakubrew/moar-master/install/share/perl6/site
    CSV::Parser:ver<0.1.2>:auth<github:tony-o>
    Zef:auth<github:ugexe>
    ===> Found via /home/foo/.rakubrew/moar-master/install/share/perl6
    CORE:ver<6.c>:auth<perl>

Note that not every Repository may provide such a list, and such lists may only
be a subset. For example: We may not be able to get a list of every distribution
on cpan, but we \*can\* get the $x most recent additions (we use 100 for now).

\[`@from`\] allows you to show results from specific repositories only:

    zef --installed list perl   # Only list modules installed by rakudo itself

    zef list cpan               # Only show available modules from the repository
    zef list p6c                # with a name field matching the arguments to `list`
    zef list cached             # (be sure the repository is enabled in config)

Otherwise results from all enabled repositories will be returned.

**Options**

    # Only list installed distributions
    --installed

    # Additionally list the modules of discovered distributions
    -v

#### **depends** \[$identity\]

List direct and transitive dependencies to the first successful build graph for `$identity`

    $ zef depends Cro::SSL
    Cro::Core:ver<0.7>
    IO::Socket::Async::SSL:ver<0.3>
    OpenSSL:ver<0.1.14>:auth<github:sergot>

#### **rdepends** \[$identity\]

List available distributions that directly depend on `$identity`

    $ zef rdepends Net::HTTP
    Minecraft-Tools:ver<0.1.0>
    LendingClub:ver<0.1.0>

#### **fetch** \[\*@identities\]

Fetches candidates for given identities

#### **test** \[\*@paths\]

Run tests on each distribution located at \[`@paths`\]

#### **build** \[\*@paths\]

Run the Build.pm file located in the given \[`@paths`\]

If you want to create a build hook, put the following dependency-free boilerplate
in a file named `Build.pm` at the root of your distribution:

    class Build {
        method build($dist-path) {
            # do build stuff to your module
            # which is located at $dist-path
        }
    }

Set the env variable **ZEF\_BUILDPM\_DEBUG=1** or use the _--debug_ flag for additional debugging information.

_Note: In the future, a more appropriate hooking solution will replace this._

#### **look** \[$identity\]

Fetches the requested distribution and any dependencies (if requested), changes the directory to that of the fetched
distribution, and then stops program execution. This allows you modify or look at the source code before manually
continuing the install via `zef install .`

Note that the path to any dependencies that needed to be fetched will be set in env at **RAKULIB**, so you should
be able to run any build scripts, tests, or complete a manual install without having to specify their locations.

#### **browse** $identity \[bugtracker | homepage | source\]

**Options**

    # disables launching a browser window (just shows url)
    --/open

Output the url and launch a browser to open it.

    # also opens browser
    $ zef browse Net::HTTP bugtracker
    https://github.com/ugexe/Perl6-Net--HTTP/issues

    # only outputs the url
    $ zef browse Net::HTTP bugtracker --/open
    https://github.com/ugexe/Perl6-Net--HTTP/issues

#### **locate** \[$identity, $name-path, $sha1-id\]

**Options**

    # The argument is a sha1-id (otherwise assumed to be an identity or name-path)
    --sha1

Lookup a locally installed module by $identity, $name-path, or $sha1-id

    $ zef --sha1 locate A9948E7371E0EB9AFDF1EEEB07B52A1B75537C31
    ===> From Distribution: zef:ver<*>:auth<github:ugexe>:api<>
    lib/Zef/CLI.rakumod => ~/rakudo/install/share/perl6/site/sources/A9948E7371E0EB9AFDF1EEEB07B52A1B75537C31

    $ zef locate Zef::CLI
    ===> From Distribution: zef:ver<*>:auth<github:ugexe>:api<>
    lib/Zef/CLI.rakumod => ~/rakudo/install/share/perl6/site/sources/A9948E7371E0EB9AFDF1EEEB07B52A1B75537C31

    $ zef locate lib/Zef/CLI.rakumod
    ===> From Distribution: zef:ver<*>:auth<github:ugexe>:api<>
    Zef::CLI => ~/rakudo/install/share/perl6/site/sources/A9948E7371E0EB9AFDF1EEEB07B52A1B75537C31

#### **nuke** \[RootDir | TempDir | StoreDir\]

Deletes all paths in the specific configuration directory

#### **nuke** \[site | home\]

Deletes all paths that are rooted in the prefix of the matching CompUnit::Repository name

    # uninstall all modules
    $ zef nuke site home

## Output Verbosity

You can control the logging level using the following flags:

    # More/less detailed output
    --error, --warn, --info (default), --verbose (-v), --debug

# Global Configuration

### Finding the configuration file

You can always see the configuration file that will be used by running:

    $ zef --help

In most cases the default configuration combined with command line options should be enough for most users.

If you are most users (e.g. not: power users, packagers, zef plugin developers) you hopefully don't care about this section! 

### How the configuration file is chosen

The configuration file will be chosen at runtime from one of two (technically four) locations, and one can affect the others (this is not really a design decision and suggestions and PRs are welcome).

First, and the most precise way, is to specify the config file by passing `--config-path="..."` to any zef command.

Second, third, and fourth we look at the path pointed to by `%?RESOURCES<config.json>`. This will point to `$zef-dir/resources/config.json`, where `$zef-dir` will be either:

- The prefix of a common configuration directory, such as `$XDG_CONFIG_HOME`  or `$HOME/.config`.
- The prefix of a rakudo installation location - This is the case if the modules loaded for bin/zef come from an installation CompUnit::Repository.
- The current working directory `$*CWD` - This is the case when modules loaded for bin/zef come from a non-installation CompUnit::Repository (such as `-I $dist-path`).

    To understand how this is chosen, consider:

        # Modules not loaded from an ::Installation,
        # so %?RESOURCES is $*CWD/resources
        $ raku -I. bin/zef --help
        ...
        CONFIGURATION /home/user/raku/zef/resources/config.json
        ...

        # Installed zef script loads modules from an ::Installation,
        # so %?RESOURCES is $raku-share-dir/site/resources
        $ zef --help
        ...
        CONFIGURATION /home/user/raku/install/share/perl6/site/resources/EE5DBAABF07682ECBE72BEE98E6B95E5D08675DE.json
        ...

This config is loaded, but it is not yet the chosen config! We check that temporary config's `%config<RootDir>` for valid json in a file named `config.json` (i.e. `%config<RootDir>/config.json`). This can be confusing (so it may go away or be refined - PRs welcome) but for most cases it just means `$*HOME/.zef/config.json` will override an installed zef configuration file.

To summarize:

- You can edit the `resources/config.json` file before you install zef.

    When you `raku -I. bin/zef install .` that configuration file be be used to install zef and will also be installed with zef such that it will be the default.

- You can create a `%config<RootDir>/config.json` file.

    Where `%config<RootDir>`
    comes from the previously mentioned `%?RESOURCES<config.json>`'s `RootDir` field (`$*HOME/.zef` in most cases), to allow overriding zef config behavior on a per user basis (allows setting different `--install-to` targets for, say, a root user and a regular user). Since this new config file could have a different `RootDir` than the default config (used to find the new one in the first place) this behavior may be changed in the future to be less confusing.

- You can override both of the previous entries by passing `zef --config-path="$path" <any command>`

### Configuration fields

#### Basic Settings

- **RootDir** - Where zef will look for a custom config.json file
- **TempDir** - A staging area for items that have been fetched and need to be extracted/moved
- **StoreDir** - Where zef caches distributions, package lists, etc after they've been fetched and extracted
- **DefaultCUR** - This sets the default value for `--install-to="..."`. The default value of `auto` means it will first try installing to rakudo's installation prefix, and if its not writable by the current user it will install to `$*HOME/.raku`. These directories are not chosen by zef - they are actually represented by the magic strings `site` and `home` (which, like `auto`, are valid values despite not being paths along with `vendor` and `perl`)

#### Phases / Plugins Settings

These consist of an array of hashes that describe how to instantiate some class that fulfills the appropriate interface from _Zef.pm_ (`Repository` `Fetcher` `Extractor` `Builder` `Tester` `Reporter`)

The descriptions follow this format:

    {
        "short-name" : "p6c",
        "enabled" : 1,
        "module" : "Zef::Repository::Ecosystems",
        "options" : { }
    }

and are instantiated via

    ::($hash<module>).new(|($hash<options>)

- **short-name** - This adds an enable and disable flag by the same name to the CLI (e.g. `--p6c` and `--/p6c`) and is used when referencing which object took some action.
- **enabled** - Set to 0 to skip over the object during consideration (it will never be loaded). If omitted or if the value is non 0 then it will be enabled for use.
- **module** - The name of the class to instantiate. While it doesn't technically have to be a module it _does_ need to be a known namespace to `require`.
- **options** - These are passed to the objects `new` method and may not be consistent between modules as they are free to implement their own requirements.

See the configuration file in [resources/config.json](https://github.com/ugexe/zef/blob/master/resources/config.json) for a
little more information on how plugins are invoked.

You can see debug output related to chosing and loading plugins by setting the env variable **ZEF\_PLUGIN\_DEBUG=1**

# FAQ

### Proxy support?

All the default fetching plugins have proxy support, but you'll need to refer to the backend program's
(wget, curl, git, etc) docs. You may need to set an _ENV_ variable, or you may need to add a command line
option for that specific plugin in _resources/config.json_

### Custom installation locations?

Pass a path to the _-to_ / _--install-to_ option and prefix the path with `inst#` (unless you know what you're doing)

    $ zef -to="inst#/home/raku/custom" install Text::Table::Simple
    ===> Searching for: Text::Table::Simple
    ===> Testing: Text::Table::Simple:ver<0.0.3>:auth<github:ugexe>
    ===> Testing [OK] for Text::Table::Simple:ver<0.0.3>:auth<github:ugexe>
    ===> Installing: Text::Table::Simple:ver<0.0.3>:auth<github:ugexe>

To make the custom location discoverable:

    # Set the RAKULIB env:
    $ RAKULIB="inst#/home/raku/custom" raku -e "use Text::Table::Simple; say 'ok'"
    ok

    # or simply include it as needed
    $ raku -Iinst#/home/raku/custom -e "use Text::Table::Simple; say 'ok'"
    ok
