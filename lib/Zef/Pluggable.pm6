BEGIN my $ZVER = $?DISTRIBUTION.meta<version>;
use Zef:ver($ZVER);
use Zef::Identity:ver($ZVER);

role Pluggable {
    has $!plugins;
    has @.backends;

    sub DEBUG($plugin, $message) {
        say "[Plugin - {$plugin<short-name> // $plugin<module> // qq||}] $message"\
            if ?%*ENV<ZEF_PLUGIN_DEBUG>;
    }

    method plugins(*@names) {
        +@names ?? self!list-plugins.grep({@names.contains(.short-name)}) !! self!list-plugins;
    }

    method !list-plugins {
        gather for @!backends -> $plugin {
            my $identity        = Zef::Identity.new($plugin<module>);
            my $short-name      = $identity.name;
            my $version-matcher = $identity.version || do { $?DISTRIBUTION.meta<provides>{$short-name}.?chars ?? $?DISTRIBUTION.meta<version> !! '*' }; # auto-version zef provided plugins
            my $dep-spec        = CompUnit::DependencySpecification.new(:$short-name, :$version-matcher);
            DEBUG($plugin, "Checking: {$short-name}");

            # default to enabled unless `"enabled" : 0`
            next() R, DEBUG($plugin, "\t(SKIP) Not enabled")\
                if $plugin<enabled>:exists && (!$plugin<enabled> || $plugin<enabled> eq "0");

            next() R, DEBUG($plugin, "\t(SKIP) Plugin could not be loaded")\
                unless try $*REPO.need($dep-spec);

            DEBUG($plugin, "\t(OK) Plugin loaded successful");

            if ::($ = $short-name).^find_method('probe') {
                ::($ = $short-name).probe
                    ?? DEBUG($plugin, "\t(OK) Probing successful")
                    !! (next() R, DEBUG($plugin, "\t(SKIP) Probing failed"))
            }

            # add plugin attribute `short-name` here to make filtering by name slightly easier
            # until a more elegant solution can be integrated into plugins themselves. Also
            # note this is not related in any way to $short-name.
            my $class = ::($ = $short-name).new(|($plugin<options> // []))\
                but role :: { has $.short-name = $plugin<short-name> // '' };

            next() R, DEBUG($plugin, "(SKIP) Plugin unusable: initialization failure")\
                unless ?$class;

            DEBUG($plugin, "(OK) Plugin is now usable: {$short-name}");
            take $class;
        }
    }
}