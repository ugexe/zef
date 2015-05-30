use Zef::Test::Result;
use Zef::Utils::PathTools;

class Zef::Test {
    has $.path;
    has @.test-files;
    has @.includes;

    submethod BUILD(:$!path!, :@!test-files, :@!includes) {
        @!test-files = $!path.IO.ls(:r, :f).grep(/\.t$/);
        @!includes   = $*SPEC.catdir($!path, "blib"), $*SPEC.catdir($!path, "lib") unless @!includes.elems;
    }

    method test(Zef::Test:D: :$p6flags) {
        PRE   my $orig-cwd = $*CWD;
        ENTER chdir($!path);
        LEAVE chdir($orig-cwd);

        my $tests = Supply.from-list: @!test-files.map(-> $file {
            # Some modules fail tests when using an absolute path, hence the seemingly unnecessary abs2rel
            my $file-rel = $*SPEC.abs2rel($file, $!path);
            my $process  = Proc::Async.new("perl6", @!includes.map({ qqw/-I$_/ }), $file-rel);
            Zef::Test::Result.new( :$file, :$process ); # can probably ditch :$file and check $process.args
        });
    }
}

