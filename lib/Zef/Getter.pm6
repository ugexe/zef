use Zef::Phase::Getting;
class Zef::Getter does Zef::Phase::Getting {
    has @.plugins;

    # TODO: load plugins if .does or .isa matches
    # so our code doesnt look like modules are
    # reloaded for every phase.
    submethod BUILD(:@!plugins?) {
        for @!plugins -> $plugin {    
            say $plugin;
            require ::($plugin);
            next unless ::($plugin).does(Zef::Phase::Getting);
            say "loaded $plugin";
            self does ::($plugin);
        }
    }
}