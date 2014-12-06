module Zef::Exception;

class X::Zef is Exception {
    has $.stage;
    has $.reason;

    method new($stage, $reason is copy) {
        if $reason ~~ Failure {
            $.reason = $reason.exception.message;
        }
        self.bless(:$stage, :$reason)
    }

    method message {
        say "$.stage stage failed: $.reason";
    }
}