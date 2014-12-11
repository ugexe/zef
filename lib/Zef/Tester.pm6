use Zef::Phase::Testing;
class Zef::Tester does Zef::Phase::Testing {
    has @.plugins;

    submethod BUILD(:@!plugins?) {
        for @!plugins -> $plugin {
            require ::($plugin);
            self does ::($plugin);
        }
    }
}