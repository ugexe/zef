use Zef;

use Zef::Proc::wget;
use Zef::Proc::curl;

use Zef::Proc::PowerShell;
use Zef::Proc::PowerShell::download;
use Zef::Proc::PowerShell::unzip;

subtest {
    ok 1, 'SKIP: wget not available'

}, 'Zef::Proc::wget';

https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/p6c.json