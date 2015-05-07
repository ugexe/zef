use v6;
use Test;
plan 4;

use Zef::Grammars::HTTP::RFC5322;


subtest { # http://tools.ietf.org/html/rfc5322#appendix-A.1.1
    my $message =  q{From: John Doe <jdoe@machine.example>}
        ~ "\r\n" ~ q{Sender: Michael Jones <mjones@machine.example>}
        ~ "\r\n" ~ q{To: Mary Smith <mary@example.net>}
        ~ "\r\n" ~ q{Subject: Saying Hello}
        ~ "\r\n" ~ q{Date: Fri, 21 Nov 1997 09:55:06 -0600}
        ~ "\r\n" ~ q{Message-ID: <1234@local.machine.example>}
        ~ "\r\n" ~ q{}
        ~ "\r\n" ~ q{This is a message just to say hello.}
        ~ "\r\n" ~ q{So, "Hello".};

    my $parsed = Zef::Grammars::HTTP::RFC5322.parse($message);

    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>.Str, 
        " John Doe <jdoe@machine.example>";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>.<mailbox>.Str, 
        " John Doe <jdoe@machine.example>";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>.<mailbox>.[0].<name-addr>.<display-name>.Str, 
        " John Doe ";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>.<mailbox>.[0].<name-addr>.<angle-addr>.Str, 
        "<jdoe@machine.example>";

    is $parsed.<message>.<fields>.<sender>.Str,
        "Sender: Michael Jones <mjones@machine.example>\r\n";
    is $parsed.<message>.<fields>.<sender>.[0].<mailbox>.Str, 
        " Michael Jones <mjones@machine.example>";
    is $parsed.<message>.<fields>.<sender>.[0].<mailbox>.<name-addr>.<display-name>.Str,
        " Michael Jones ";
    is $parsed.<message>.<fields>.<sender>.[0].<mailbox>.<name-addr>.<angle-addr>.Str,
        "<mjones@machine.example>";

    is $parsed.<message>.<fields>.<to>.Str,
        "To: Mary Smith <mary@example.net>\r\n";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.Str, 
        " Mary Smith <mary@example.net>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].Str, 
        " Mary Smith <mary@example.net>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<mailbox>.Str, 
        " Mary Smith <mary@example.net>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<mailbox>.<name-addr>.<display-name>.Str, 
        " Mary Smith ";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<mailbox>.<name-addr>.<angle-addr>.Str, 
        "<mary@example.net>";

    is $parsed.<message>.<fields>.<subject>.Str,
        "Subject: Saying Hello\r\n";
    is $parsed.<message>.<fields>.<subject>.[0].<value>.Str,
        " Saying Hello";

    is $parsed.<message>.<fields>.<orig-date>.Str, 
        "Date: Fri, 21 Nov 1997 09:55:06 -0600\r\n";
    is $parsed.<message>.<fields>.<orig-date>.[0].<date-time>.Str, 
        " Fri, 21 Nov 1997 09:55:06 -0600";

    is $parsed.<message>.<fields>.<message-id>.Str, 
        "Message-ID: <1234@local.machine.example>\r\n";
    is $parsed.<message>.<fields>.<message-id>.[0].<msg-id>.Str, 
        " <1234@local.machine.example>";

    is $parsed.<message>.<body>.Str, "This is a message just to say hello.\r\nSo, \"Hello\".";

}, 'A Message from One Person to Another with Simple Addressing';


subtest { # http://tools.ietf.org/html/rfc5322#appendix-A.1.2
    my $message =  q{From: "Joe Q. Public" <john.q.public@example.com>}
        ~ "\r\n" ~ q{To: Mary Smith <mary@x.test>, jdoe@example.org, Who? <one@y.test>}
        ~ "\r\n" ~ q{Cc: <boss@nil.test>, "Giant; \"Big\" Box" <sysservices@example.net>}
        ~ "\r\n" ~ q{Date: Tue, 1 Jul 2003 10:52:37 +0200}
        ~ "\r\n" ~ q{Message-ID: <5678.21-Nov-1997@example.com>}
        ~ "\r\n" ~ q{}
        ~ "\r\n" ~ q{Hi everyone.};

    my $parsed = Zef::Grammars::HTTP::RFC5322.parse($message);

    is $parsed.<message>.<fields>.<from>.Str, 
        "From: \"Joe Q. Public\" <john.q.public@example.com>\r\n";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>, 
        " \"Joe Q. Public\" <john.q.public@example.com>";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>.<mailbox>, 
        " \"Joe Q. Public\" <john.q.public@example.com>";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>.<mailbox>.[0].<name-addr>.<display-name>.Str, 
        " \"Joe Q. Public\" ";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>.<mailbox>.[0].<name-addr>.<angle-addr>.Str, 
        "<john.q.public@example.com>";


    is $parsed.<message>.<fields>.<to>.Str,
        "To: Mary Smith <mary@x.test>, jdoe@example.org, Who? <one@y.test>\r\n";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>, 
        " Mary Smith <mary@x.test>, jdoe@example.org, Who? <one@y.test>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0], 
        " Mary Smith <mary@x.test>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<mailbox>, 
        " Mary Smith <mary@x.test>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<mailbox>.<name-addr>.<display-name>, 
        " Mary Smith ";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<mailbox>.<name-addr>.<angle-addr>, 
        "<mary@x.test>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[1], 
        " jdoe@example.org";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[1].<mailbox>, 
        " jdoe@example.org";
    nok $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[1].<mailbox>.<name-addr>.<display-name>;
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[1].<mailbox>.<addr-spec>, 
        " jdoe@example.org";

    nok $parsed.<message>.<fields>.<subject>;

    is $parsed.<message>.<fields>.<orig-date>.Str, 
        "Date: Tue, 1 Jul 2003 10:52:37 +0200\r\n";
    is $parsed.<message>.<fields>.<orig-date>.[0].<date-time>.Str, 
        " Tue, 1 Jul 2003 10:52:37 +0200";

    is $parsed.<message>.<fields>.<message-id>.Str, 
        "Message-ID: <5678.21-Nov-1997@example.com>\r\n";
    is $parsed.<message>.<fields>.<message-id>.[0].<msg-id>, 
        " <5678.21-Nov-1997@example.com>";

    is $parsed.<message>.<body>.Str, "Hi everyone.";
}, 'Different Types of Mailboxes';


subtest { # http://tools.ietf.org/html/rfc5322#appendix-A.1.3
    my $message =  q{From: Pete <pete@silly.example>}
        ~ "\r\n" ~ q{To: A Group:Ed Jones <c@a.test>,joe@where.test,John <jdoe@one.test>;}
        ~ "\r\n" ~ q{Cc: Undisclosed recipients:;}
        ~ "\r\n" ~ q{Date: Thu, 13 Feb 1969 23:32:54 -0330}
        ~ "\r\n" ~ q{Message-ID: <testabcd.1234@silly.example>}
        ~ "\r\n" ~ q{}
        ~ "\r\n" ~ q{Testing.};

    my $parsed = Zef::Grammars::HTTP::RFC5322.parse($message);


    is $parsed.<message>.<fields>.<to>.Str,
        "To: A Group:Ed Jones <c@a.test>,joe@where.test,John <jdoe@one.test>;\r\n";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<group>.<display-name>, 
        " A Group";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<group>.<group-list>.<mailbox-list>.<mailbox>.[0].<name-addr>.<display-name>, 
        "Ed Jones ";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<group>.<group-list>.<mailbox-list>.<mailbox>.[0].<name-addr>.<angle-addr>, 
        "<c@a.test>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<group>.<group-list>.<mailbox-list>.<mailbox>.[1].<addr-spec>.Str, 
        "joe@where.test";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<group>.<group-list>.<mailbox-list>.<mailbox>.[2].<name-addr>.<display-name>, 
        "John ";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<group>.<group-list>.<mailbox-list>.<mailbox>.[2].<name-addr>.<angle-addr>, 
        "<jdoe@one.test>";

    is $parsed.<message>.<fields>.<cc>.[0].<address-list>.<address>.[0].<group>.<display-name>, 
        " Undisclosed recipients";

    is $parsed.<message>.<body>.Str, "Testing.";

}, 'Group Addresses';


subtest { # http://tools.ietf.org/html/rfc5322#appendix-A.4
    my $message = q{Received: from x.y.test}
        ~ "\r\n" ~ q{     by example.net}
        ~ "\r\n" ~ q{    via TCP}
        ~ "\r\n" ~ q{    with ESMTP}
        ~ "\r\n" ~ q{    id ABC12345}
        ~ "\r\n" ~ q{    for <mary@example.net>;  21 Nov 1997 10:05:43 -0600}
        ~ "\r\n" ~ q{Received: from node.example by x.y.test; 21 Nov 1997 10:01:22 -0600}
        ~ "\r\n" ~ q{From: John Doe <jdoe@node.example>}
        ~ "\r\n" ~ q{To: Mary Smith <mary@example.net>}
        ~ "\r\n" ~ q{Subject: Saying Hello}
        ~ "\r\n" ~ q{Date: Fri, 21 Nov 1997 09:55:06 -0600}
        ~ "\r\n" ~ q{Message-ID: <1234@local.node.example>}
        ~ "\r\n" ~ q{}
        ~ "\r\n" ~ q{This is a message just to say hello.}
        ~ "\r\n" ~ q{So, "Hello".};

    my $parsed = Zef::Grammars::HTTP::RFC5322.parse($message);


    is $parsed.<message>.<fields>.<optional-field>.[0].<field>, 
        "Received";
    ok $parsed.<message>.<fields>.<optional-field>.[0].<value> 
        ~~ /' from x.y.test'\n\s+'by example.net'\n\s+'via TCP'\n\s+'with ESMTP'\n\s+'id ABC12345'\n\s+'for <mary@example.net>;  21 Nov 1997 10:05:43 -0600'/;
    is $parsed.<message>.<fields>.<optional-field>.[1].<field>, 
        "Received";
    is $parsed.<message>.<fields>.<optional-field>.[1].<value>, 
        " from node.example by x.y.test; 21 Nov 1997 10:01:22 -0600";

}, 'Messages with Trace Fields';


done();
