use Zef::Phase::Testing;
class Zef::Tester does Zef::Phase::Testing {
    has @.plugins;

    submethod BUILD(:@!plugins?) {
        for @!plugins -> $plugin {
            require ::($plugin);
            say "require $plugin";
            my $mod = ::($plugin);
            self does ::($plugin);
        }
    }
}