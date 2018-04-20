use v6;
use Test;
plan 1;

use Zef::Distribution::Local;
use Zef;


sub list-deps(*@candis) {
  my $deps := gather for @candis -> $candi {
    take $_ for grep *.defined,
      $candi.dist.depends-specs.Slip,
  }
  $deps.unique(:as(*.identity));
}

subtest {
    subtest {
      my $path = 't/test-meta-files/xyz.json';
      my Candidate $new-meta = Candidate.new(
        :as($path),
        :uri($path.IO.absolute),
        :dist(Zef::Distribution::Local.new($path)),
      );
      my @deps = list-deps($new-meta);
      ok @deps.grep(*.spec eq 'Zef::Test' && *.dist-type eq 'test'), '<test> dist-type contains Zef::Test';
      ok @deps.grep(*.spec eq 'Zef::Build' && *.dist-type eq 'build'), '<build> dist-type contains Zef::Build';
      ok @deps.grep(*.spec eq 'Zef::Client' && *.dist-type eq 'runtime'), '<runtime> dist-type contains Zef::Client';

      my @build-deps = $new-meta.dist.build-depends-specs;
      ok @build-deps.elems == 1, 'should have only one element from .dist.test-depends-specs';
      ok @build-deps[0].spec eq 'Zef::Build', 'one element spec should be Zef::Build';

      my @test-deps = $new-meta.dist.test-depends-specs;
      ok @test-deps.elems == 1, 'should have only one element from .dist.test-depends-specs';
      ok @test-deps[0].spec eq 'Zef::Test', 'one element spec should be Zef::Test';

      my @native    = @deps.grep(*.dist-type eq 'native');
      ok @native.elems == 1, 'should have only one native depends';
      ok @native[0].spec ~~ any(qw<mac win linux unknown>), 'native spec should be one of mac, win, linux, unknown';
    }, 'native depends';
}, 'dependency breakdown';
