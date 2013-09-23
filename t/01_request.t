use strict;
use warnings;
use utf8;
use Plack::Request::WithEncoding;
use Encode;

use Test::More;

subtest 'isa' => sub {
    my $req = build_request();
    isa_ok $req, 'Plack::Request';
    isa_ok $req, 'Plack::Request::WithEncoding';
};

subtest 'default encoding (utf-8)' => sub {
    my $req = build_request();

    subtest 'get encoding information' => sub {
        is $req->encoding, 'utf-8';
    };

    ok Encode::is_utf8($req->param('foo'));
    ok Encode::is_utf8($req->query_parameters->{'foo'});

    my $expected = decode('utf-8', encode('utf-8', 'ほげ'));
    is $req->param('foo'), $expected;

    my $expected1 = 'ふが1';
    my $expected2 = 'ふが2';
    is_deeply [$req->param('bar')], [$expected1, $expected2];
};

subtest 'custom encoding (cp932)' => sub {
    my $req = build_request();
    $req->env->{'plack.request.withencoding.encoding'} = 'cp932';

    subtest 'get encoding information' => sub {
        is $req->encoding, 'cp932';
    };

    ok Encode::is_utf8($req->param('foo'));
    ok Encode::is_utf8($req->query_parameters->{'foo'});

    my $expected = decode('cp932', encode('utf-8', 'ほげ'));
    is $req->query_parameters->{'foo'}, $expected;

    my $expected1 = decode('cp932', encode('utf-8', 'ふが1'));
    my $expected2 = decode('cp932', encode('utf-8', 'ふが2'));
    is_deeply [$req->param('bar')], [$expected1, $expected2];
};

subtest 'invalid encoding' => sub {
    my $req = build_request();
    $req->env->{'plack.request.withencoding.encoding'} = 'INVALID_ENCODING';

    eval{ $req->param };
    like $@, qr/Unknown encoding 'INVALID_ENCODING'\./, 'It must die.';
};

subtest 'accessor (not decoded)' => sub {
    my $req = build_request();

    ok !Encode::is_utf8($req->raw_param('foo'));
    ok !Encode::is_utf8($req->raw_query_parameters->{'foo'});
    ok !Encode::is_utf8($req->raw_body_parameters);
};

done_testing;

sub build_request {
    my $query = 'foo=%E3%81%BB%E3%81%92&bar=%E3%81%B5%E3%81%8C1&bar=%E3%81%B5%E3%81%8C2'; # <= foo=ほげ&bar=ふが1&bar=ふが2
    my $host  = 'example.com';
    my $path  = '/hoge/fuga';

    Plack::Request::WithEncoding->new({
        QUERY_STRING   => $query,
        REQUEST_METHOD => 'GET',
        HTTP_HOST      => $host,
        PATH_INFO      => $path,
    });
}
