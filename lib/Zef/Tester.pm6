class Zef::Tester {
    use Zef::Phase::Testing;
    
    has @.plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $plugin {
            require ::($plugin);
            my $loaded = ::($plugin).new;
            $loaded:delete andthen next unless $loaded.isa(::('Zef::Phase::Testing'));
            self does $loaded;
        }
    }
}