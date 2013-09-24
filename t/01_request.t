use strict;
use warnings;
use utf8;
use Encode qw/encode is_utf8/;
use Hash::MultiValue;

use Plack::Request::WithEncoding;

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

    subtest 'Decoded rightly' => sub {
        ok is_utf8($req->param('foo'));
        ok is_utf8($req->query_parameters->{'foo'});
        ok is_utf8($req->body_parameters->{'buz'});
    };

    is $req->param('foo'), 'ほげ',           'get query value of parameter';
    is $req->param('buz'), 'こんにちは世界', 'get body value of parameter';

    my $got = $req->param('bar');
    is $got, 'ふが2', 'get tail of value when context requires the scalar';
    is_deeply [$req->param('bar')], ['ふが1', 'ふが2'], 'get all value as array when context requires the array';

    is_deeply [sort {$a cmp $b} $req->param], ['bar', 'buz', 'foo'], 'get keys of all params when it with no arguments';
};

subtest 'custom encoding (cp932)' => sub {
    my $req = build_request('cp932');
    $req->env->{'plack.request.withencoding.encoding'} = 'cp932';

    subtest 'get encoding information' => sub {
        is $req->encoding, 'cp932';
    };

    subtest 'Decoded rightly' => sub {
        ok is_utf8($req->param('foo'));
        ok is_utf8($req->query_parameters->{'foo'});
        ok is_utf8($req->body_parameters->{'buz'});
    };

    is $req->param('foo'), 'ほげ',           'get query value of parameter';
    is $req->param('buz'), 'こんにちは世界', 'get body value of parameter';

    my $got = $req->param('bar');
    is $got, 'ふが2', 'get tail of value when context requires the scalar';
    is_deeply [$req->param('bar')], ['ふが1', 'ふが2'], 'get all value as array when context requires the array';

    is_deeply [sort {$a cmp $b} $req->param], ['bar', 'buz', 'foo'], 'get keys of all params when it with no arguments';
};

subtest 'invalid encoding' => sub {
    my $req = build_request();
    $req->env->{'plack.request.withencoding.encoding'} = 'INVALID_ENCODING';

    eval{ $req->param };
    like $@, qr/Unknown encoding 'INVALID_ENCODING'\./, 'It must die.';
};

subtest 'accessor (not decoded)' => sub {
    my $req = build_request();

    subtest 'Should be not decoded' => sub {
        ok !is_utf8($req->raw_param('foo'));
        ok !is_utf8($req->raw_query_parameters->{'foo'});
        ok !is_utf8($req->raw_body_parameters->{'buz'});
    };

    is $req->raw_param('foo'), encode('utf-8', 'ほげ'), 'get query value of parameter';
    is $req->raw_param('buz'), encode('utf-8', 'こんにちは世界'), 'get body value of parameter';

    my $got = $req->raw_param('bar');
    is $got, encode('utf-8', 'ふが2'), 'get tail of value when context requires the scalar';
    is_deeply [$req->raw_param('bar')], [encode('utf-8', 'ふが1'), encode('utf-8', 'ふが2')], 'get all value as array when context requires the array';

    is_deeply [sort {$a cmp $b} $req->raw_param], ['bar', 'buz', 'foo'], 'get keys of all params when it with no arguments';
};

done_testing;

sub build_request {
    my $encoding = shift || 'utf-8';

    # raw param: foo=ほげ&bar=ふが1&bar=ふが2
    my $query;
    if ($encoding eq 'utf-8') {
        $query = 'foo=%e3%81%bb%e3%81%92&bar=%e3%81%b5%e3%81%8c1&bar=%e3%81%b5%e3%81%8c2';
    }
    elsif ($encoding eq 'cp932') {
        $query = 'foo=%82%d9%82%b0&bar=%82%d3%82%aa1&bar=%82%d3%82%aa2';
    }
    else {
        die 'Specified encoding is unknown.';
    }

    my $host  = 'example.com';
    my $path  = '/hoge/fuga';

    my $req = Plack::Request::WithEncoding->new({
        QUERY_STRING   => $query,
        REQUEST_METHOD => 'GET',
        HTTP_HOST      => $host,
        PATH_INFO      => $path,
    });

    $req->env->{'plack.request.body'} = Hash::MultiValue->from_mixed({
        buz => encode($encoding, 'こんにちは世界'),
    });

    return $req;
}
