use v6;
use Test;
plan 2;

subtest {
    use-ok("Zef");
    use-ok("Zef::App");
    use-ok("Zef::Distribution");
    use-ok("Zef::Distribution::DependencySpecification");
    use-ok("Zef::Distribution::Local");
    use-ok("Zef::Config");
    use-ok("Zef::ContentStorage");
    use-ok("Zef::Extract");
    use-ok("Zef::Fetch");
    use-ok("Zef::Shell");
    use-ok("Zef::Test");
    use-ok("Zef::Utils::SystemInfo");
}, 'Core';

subtest {
    use-ok("Zef::Shell::Test");
    use-ok("Zef::Shell::prove");
    use-ok("Zef::Shell::prove6");
    use-ok("Zef::Shell::unzip");
    use-ok("Zef::Shell::tar");
    use-ok("Zef::Shell::curl");
    use-ok("Zef::Shell::git");
    use-ok("Zef::Shell::wget");
    use-ok("Zef::Shell::PowerShell");
    use-ok("Zef::Shell::PowerShell::download");
    use-ok("Zef::Shell::PowerShell::unzip");
    use-ok("Zef::Shell::PowerShell::tar");
}, 'Plugins';
