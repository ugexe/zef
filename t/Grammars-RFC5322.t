use v6;
use Test;
plan 4;

use Zef::Grammars::HTTP::RFC5322;


subtest { # http://tools.ietf.org/html/rfc5322#appendix-A.1.1
    my $message = q:to/EOS/;
        From: John Doe <jdoe@machine.example>
        Sender: Michael Jones <mjones@machine.example>
        To: Mary Smith <mary@example.net>
        Subject: Saying Hello
        Date: Fri, 21 Nov 1997 09:55:06 -0600
        Message-ID: <1234@local.machine.example>

        This is a message just to say hello.
        So, "Hello".
        EOS

    my $parsed = Zef::Grammars::HTTP::RFC5322.parse($message);

    is $parsed.<message>.<fields>.<from>, 
        "From: John Doe <jdoe@machine.example>\n";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>, 
        " John Doe <jdoe@machine.example>";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>.<mailbox>, 
        " John Doe <jdoe@machine.example>";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>.<mailbox>.[0].<name>, 
        " John Doe ";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>.<mailbox>.[0].<addr>, 
        "<jdoe@machine.example>";

    is $parsed.<message>.<fields>.<sender>,
        "Sender: Michael Jones <mjones@machine.example>\n";
    is $parsed.<message>.<fields>.<sender>.[0].<mailbox>, 
        " Michael Jones <mjones@machine.example>";
    is $parsed.<message>.<fields>.<sender>.[0].<mailbox>.<name>,
        " Michael Jones ";
    is $parsed.<message>.<fields>.<sender>.[0].<mailbox>.<addr>,
        "<mjones@machine.example>";

    is $parsed.<message>.<fields>.<to>,
        "To: Mary Smith <mary@example.net>\n";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>, 
        " Mary Smith <mary@example.net>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>, 
        " Mary Smith <mary@example.net>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<mailbox>, 
        " Mary Smith <mary@example.net>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<mailbox>.<name>, 
        " Mary Smith ";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<mailbox>.<addr>, 
        "<mary@example.net>";

    is $parsed.<message>.<fields>.<subject>,
        "Subject: Saying Hello\n";
    is $parsed.<message>.<fields>.<subject>.[0].<value>,
        " Saying Hello";

    is $parsed.<message>.<fields>.<orig-date>, 
        "Date: Fri, 21 Nov 1997 09:55:06 -0600\n";
    is $parsed.<message>.<fields>.<orig-date>.[0].<date-time>, 
        " Fri, 21 Nov 1997 09:55:06 -0600";

    is $parsed.<message>.<fields>.<message-id>, 
        "Message-ID: <1234@local.machine.example>\n";
    is $parsed.<message>.<fields>.<message-id>.[0].<msg-id>, 
        " <1234@local.machine.example>";

    is $parsed.<message>.<body>, "This is a message just to say hello.\nSo, \"Hello\".\n";

}, 'A Message from One Person to Another with Simple Addressing';


subtest { # http://tools.ietf.org/html/rfc5322#appendix-A.1.2
    my $message = q:to/EOS/;
        From: "Joe Q. Public" <john.q.public@example.com>
        To: Mary Smith <mary@x.test>, jdoe@example.org, Who? <one@y.test>
        Cc: <boss@nil.test>, "Giant; \"Big\" Box" <sysservices@example.net>
        Date: Tue, 1 Jul 2003 10:52:37 +0200
        Message-ID: <5678.21-Nov-1997@example.com>

        Hi everyone.
        EOS

    my $parsed = Zef::Grammars::HTTP::RFC5322.parse($message);

    is $parsed.<message>.<fields>.<from>, 
        "From: \"Joe Q. Public\" <john.q.public@example.com>\n";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>, 
        " \"Joe Q. Public\" <john.q.public@example.com>";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>.<mailbox>, 
        " \"Joe Q. Public\" <john.q.public@example.com>";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>.<mailbox>.[0].<name>, 
        " \"Joe Q. Public\" ";
    is $parsed.<message>.<fields>.<from>.[0].<mailbox-list>.<mailbox>.[0].<addr>, 
        "<john.q.public@example.com>";


    is $parsed.<message>.<fields>.<to>,
        "To: Mary Smith <mary@x.test>, jdoe@example.org, Who? <one@y.test>\n";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>, 
        " Mary Smith <mary@x.test>, jdoe@example.org, Who? <one@y.test>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0], 
        " Mary Smith <mary@x.test>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<mailbox>, 
        " Mary Smith <mary@x.test>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<mailbox>.<name>, 
        " Mary Smith ";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<mailbox>.<addr>, 
        "<mary@x.test>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[1], 
        " jdoe@example.org";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[1].<mailbox>, 
        " jdoe@example.org";
    nok $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[1].<mailbox>.<name>;
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[1].<mailbox>.<addr>, 
        " jdoe@example.org";

    nok $parsed.<message>.<fields>.<subject>;

    is $parsed.<message>.<fields>.<orig-date>, 
        "Date: Tue, 1 Jul 2003 10:52:37 +0200\n";
    is $parsed.<message>.<fields>.<orig-date>.[0].<date-time>, 
        " Tue, 1 Jul 2003 10:52:37 +0200";

    is $parsed.<message>.<fields>.<message-id>, 
        "Message-ID: <5678.21-Nov-1997@example.com>\n";
    is $parsed.<message>.<fields>.<message-id>.[0].<msg-id>, 
        " <5678.21-Nov-1997@example.com>";

    is $parsed.<message>.<body>, "Hi everyone.\n";
}, 'Different Types of Mailboxes';


subtest { # http://tools.ietf.org/html/rfc5322#appendix-A.1.3
    my $message = q:to/EOS/;
        From: Pete <pete@silly.example>
        To: A Group:Ed Jones <c@a.test>,joe@where.test,John <jdoe@one.test>;
        Cc: Undisclosed recipients:;
        Date: Thu, 13 Feb 1969 23:32:54 -0330
        Message-ID: <testabcd.1234@silly.example>

        Testing.
        EOS

    my $parsed = Zef::Grammars::HTTP::RFC5322.parse($message);


    is $parsed.<message>.<fields>.<to>,
        "To: A Group:Ed Jones <c@a.test>,joe@where.test,John <jdoe@one.test>;\n";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<group>.<display-name>, 
        " A Group";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<group>.<group-list>.<mailbox-list>.<mailbox>.[0].<name>, 
        "Ed Jones ";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<group>.<group-list>.<mailbox-list>.<mailbox>.[0].<addr>, 
        "<c@a.test>";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<group>.<group-list>.<mailbox-list>.<mailbox>.[1].<addr>, 
        "joe@where.test";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<group>.<group-list>.<mailbox-list>.<mailbox>.[2].<name>, 
        "John ";
    is $parsed.<message>.<fields>.<to>.[0].<address-list>.<address>.[0].<group>.<group-list>.<mailbox-list>.<mailbox>.[2].<addr>, 
        "<jdoe@one.test>";

    is $parsed.<message>.<fields>.<cc>.[0].<address-list>.<address>.[0].<group>.<display-name>, 
        " Undisclosed recipients";

    is $parsed.<message>.<body>, "Testing.\n";

}, 'Group Addresses';


subtest { # http://tools.ietf.org/html/rfc5322#appendix-A.4
    my $message = q:to/EOS/;
        Received: from x.y.test
            by example.net
            via TCP
            with ESMTP
            id ABC12345
            for <mary@example.net>;  21 Nov 1997 10:05:43 -0600
        Received: from node.example by x.y.test; 21 Nov 1997 10:01:22 -0600
        From: John Doe <jdoe@node.example>
        To: Mary Smith <mary@example.net>
        Subject: Saying Hello
        Date: Fri, 21 Nov 1997 09:55:06 -0600
        Message-ID: <1234@local.node.example>

        This is a message just to say hello.
        So, "Hello".
        EOS

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
