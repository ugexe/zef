use v6;
use Test;
plan 2;

subtest {
    use-ok("Zef");
    # Just `use Zef::CLI` will make it output usage
    # use-ok("Zef::CLI");
    use-ok("Zef::Client");
    use-ok("Zef::Config");
    use-ok("Zef::Extract");
    use-ok("Zef::Identity");
    use-ok("Zef::Shell");
    use-ok("Zef::Test");

    use-ok("Zef::ContentStorage");
    use-ok("Zef::ContentStorage::CPAN");
    use-ok("Zef::ContentStorage::LocalCache");
    use-ok("Zef::ContentStorage::P6C");

    use-ok("Zef::Distribution");
    use-ok("Zef::Distribution::DependencySpecification");
    use-ok("Zef::Distribution::Local");

    use-ok("Zef::Fetch");
    use-ok("Zef::Fetch::Path");

    use-ok("Zef::Utils::FileSystem");
    use-ok("Zef::Utils::SystemInfo");
    use-ok("Zef::Utils::URI");
}, 'Core';

subtest {
    use-ok("Zef::Shell::Test");
    use-ok("Zef::Shell::prove");
    use-ok("Zef::Shell::prove6");
    use-ok("Zef::Shell::unzip");
    use-ok("Zef::Shell::tar");
    use-ok("Zef::Shell::p5tar");
    use-ok("Zef::Shell::curl");
    use-ok("Zef::Shell::git");
    use-ok("Zef::Shell::wget");
    use-ok("Zef::Shell::PowerShell");
    use-ok("Zef::Shell::PowerShell::download");
    use-ok("Zef::Shell::PowerShell::unzip");
}, 'Plugins';
