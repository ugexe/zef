use Zef::Phase::Testing;
class Zef::Tester does Zef::Phase::Testing {

    has @.plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            self does ::($p) if do { require ::($p); ::($p).does(Zef::Phase::Testing) };
        }
    }
}