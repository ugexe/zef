module Zef::App;
use Zef::Tester;

has %.opts is rw;

# we want this to be imported into bin/zef so the command:
# `zef test t/` gets pulled from here and works

sub MAIN('test', *@paths) {
    my $tester = Zef::Tester.new;
    $tester.test($_) for @paths;
    
    CATCH { 
        when X::Zef { say 'Try and handle these' }
        default     { say 'ERROR'                }
    }
}
