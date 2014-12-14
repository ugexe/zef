use Zef::Phase::Getting;
class Zef::Getter does Zef::Phase::Getting {

    has @.plugins;

    # TODO: load plugins if .does or .isa matches
    # so our code doesnt look like modules are
    # reloaded for every phase.
    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            self does ::($p) if do { require ::($p); ::($p).does(Zef::Phase::Getting) };
        }
    }
}