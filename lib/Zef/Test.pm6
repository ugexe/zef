use Zef::Test::Result;
use Zef::Utils::PathTools;

# Zef::Test should have $!path set to the base of a module's repo/directory. This is used for 2 things:
# 1) Automatically grepping all `.t` files recursively.
# 2) Setting the $CWD to run the tests in the directory they expect.
# - :@test-files: Skip search for test files and run only these instead.
# - :@includes: add `lib`s via `-I$include`. Defaults to `("$!path/blib", $!path/lib")`
# 
# method test
# Create a supply of Zef::Test::Result objects. Each Zef::Test::Result object has a `.promise` attribute
# that may be inspected for completion, output, and exit status. 

class Zef::Test {
    has $.path;
    has @.test-files;
    has @.includes;
    has $.results;

    submethod BUILD(:$!path!, :@!test-files, :@!includes) {
        @!test-files = $!path.IO.ls(:r, :f).grep(/\.t$/) unless @!test-files.elems;
    }

    method test(Zef::Test:D: :$p6flags) {
        # (Related to comment below in @!test-files.map) 
        # We often need to use a relative path for some tests to pass. Ideally the tests 
        # themselves would be improved, but changing directories will suffice for now.
        $!results = Supply.from-list: @!test-files.map(-> $file {
            # Some modules fail tests when using an absolute path, hence the seemingly unnecessary abs2rel
            my $file-rel = $*SPEC.abs2rel($file, $!path);
            my @includes-as-args = @!includes.map({ qqw/-I$_/ });
            my $process  = Proc::Async.new($*EXECUTABLE, @includes-as-args, $file-rel, :CWD($!path));

            # Can probably ditch :$file and check $process.args
            Zef::Test::Result.new(:$file, :$process); 
        });
    }
}

