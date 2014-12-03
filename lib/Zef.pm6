use v6;
module Zef;

use Zef::Getter;
use Zef::Compiler;
use Zef::Tester;
use Zef::Installer;
use Zef::Reporter;



has $.getter    = Zef::Getter.new;
has $.compiler  = Zef::Compiler.new;
has $.tester    = Zef::Tester.new;
has $.installer = Zef::Installer.new;
has $.reporter  = Zef::Reporter.new;


multi method install(@install_us) {
    await do for @install_us -> $install_me {
        self.install($install_me);
    }
}

multi method install(IO::Path $source) {
    
}

multi method install(URI $source where {^git:\/\/}) {
    
}

multi method install(URI $source where {^https?:\/\/}) {
    
}



__END__



my $fetch = $.getter.HTTP($source);

$.compiler.build( IO::Path $fetch.path );

my $test_report = $.tester.test( IO::Path $fetch.path );

my $install_report = $.installer.to( IO::Path $module_file_path );

my %report = %( test => $test_report, install => $install_report);

#$.reporter.submit( :zef(%report) );
#$.reporter.submit( :feather(%test) );
#$.reporter.submit( :zef(%report), :feather(%report) );
$.reporter.submit( :all(%report) );

