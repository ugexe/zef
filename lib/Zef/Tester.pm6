use Zef::Phase::Testing;
class Zef::Tester does Zef::Phase::Testing {
    has @.plugins;

    submethod BUILD(:@!plugins?) {
        for @!plugins -> $plugin {
            require ::($plugin);
            next unless ::($plugin).does(Zef::Phase::Testing);
            self does ::($plugin);
        }
    }
}