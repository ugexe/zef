use v6;
use Test;
plan 1;

use Zef;
use Zef::Logger;

subtest 'Zef::Logger::get-logger' => {

    subtest 'logger is singleton' => {
        my $a = Zef::Logger::get-logger;
        my $b = Zef::Logger::get-logger;
        ok $a === $b;
    }

    subtest 'logger can send a message' => {
        my $logger = Zef::Logger::get-logger;
        my @log-entry;
        Zef::Logger::register-listener({@log-entry = @_;});
        $logger.emit({
            level   => DEBUG,
            stage   => TEST,
            phase   => LIVE,
            message => "A debug message",
        });
        ok @log-entry = (DEBUG, TEST, LIVE, "A debug message");
    }

    subtest 'logger can send another message' => {
        my $logger = Zef::Logger::get-logger;
        my @log-entry;
        Zef::Logger::register-listener({
            @log-entry = @_;
        });
        $logger.emit({
            level   => WARN,
            stage   => RESOLVE,
            phase   => BEFORE,
            message => "Hark, a warning message",
        });
        ok @log-entry = (WARN, RESOLVE, BEFORE, "Hark, a warning message");
    }

}

done-testing;
