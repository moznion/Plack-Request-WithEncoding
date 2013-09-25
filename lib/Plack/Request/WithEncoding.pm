package Plack::Request::WithEncoding;
use 5.008_001;
use strict;
use warnings;
use parent qw/Plack::Request/;
use Encode ();
use Carp ();
use Hash::MultiValue;

our $VERSION = "0.01";

use constant KEY_BASE_NAME    => 'plack.request.withencoding';
use constant DEFAULT_ENCODING => 'utf-8';

sub encoding {
    $_[0]->env->{KEY_BASE_NAME . '.encoding'} ||= DEFAULT_ENCODING;
}

sub body_parameters {
    my $self = shift;
    $self->env->{KEY_BASE_NAME . '.body'} ||= $self->_decode_parameters($self->SUPER::body_parameters);
}

sub query_parameters {
    my $self = shift;
    $self->env->{KEY_BASE_NAME . '.query'} ||= $self->_decode_parameters($self->SUPER::query_parameters);
}

sub parameters {
    my $self = shift;
    $self->env->{KEY_BASE_NAME . '.merged'} ||= do {
        my $query = $self->query_parameters;
        my $body  = $self->body_parameters;
        Hash::MultiValue->new($query->flatten, $body->flatten);
    }
}

sub raw_body_parameters {
    shift->SUPER::body_parameters;
}

sub raw_query_parameters {
    shift->SUPER::query_parameters;
}

sub raw_parameters {
    my $self = shift;

    $self->env->{'plack.request.merged'} ||= do {
        my $query = $self->SUPER::query_parameters();
        my $body  = $self->SUPER::body_parameters();
        Hash::MultiValue->new( $query->flatten, $body->flatten );
    };
}

sub raw_param {
    my $self = shift;

    my $raw_parameters = $self->raw_parameters;
    return keys %{ $raw_parameters } if @_ == 0;

    my $key = shift;
    return $raw_parameters->{$key} unless wantarray;
    return $raw_parameters->get_all($key);
}

sub _decode_parameters {
    my ($self, $stuff) = @_;

    my $encoding = Encode::find_encoding($self->encoding);
    unless ($encoding) {
        my $invalid_encoding = $self->encoding;
        Carp::croak("Unknown encoding '$invalid_encoding'.");
    }

    my @flatten = $stuff->flatten;
    my @decoded;
    while ( my ($k, $v) = splice @flatten, 0, 2 ) {
        push @decoded, $encoding->decode($k), $encoding->decode($v);
    }
    return Hash::MultiValue->new(@decoded);
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Request::WithEncoding - Subclass of L<Plack::Request> which supports encoding.

=head1 SYNOPSIS

    use Plack::Request::WithEncoding;

    my $app_or_middleware = sub {
        my $env = shift; # PSGI env

        # Example of $env
        #
        # $env = {
        #     QUERY_STRING   => 'query=%82%d9%82%b0', # <= encoded by 'cp932'
        #     REQUEST_METHOD => 'GET',
        #     HTTP_HOST      => 'example.com',
        #     PATH_INFO      => '/foo/bar',
        # };

        my $req = Plack::Request::WithEncoding->new($env);

        $req->env->{'plack.request.withencoding.encoding'} = 'cp932'; # <= specify the encoding method.

        # If `$req->env->{'plack.request.withencoding.encoding'}` is undef (namely, the encoding method is not specified),
        # then this library will use `utf-8` as encoding method.

        my $query = $req->param('query'); # <= get parameters of 'query' that is decoded by 'cp932'.

        my $res = $req->new_response(200); # new Plack::Response
        $res->finalize;
    };

=head1 DESCRIPTION

Plack::Request::WithEncoding is the subclass of L<Plack::Request>.
This module supports the encoding for requests, the following attributes will return decoded request values.

=head1 ATTRIBUTES

=over 4

=item * encoding

Returns a encoding method to use to decode parameters.

=item * query_parameters

Returns a reference to a hash containing B<decoded> query string (GET)
parameters. This hash reference is L<Hash::MultiValue> object.

=item * body_parameters

Returns a reference to a hash containing B<decoded> posted parameters in the
request body (POST). As with C<query_parameters>, the hash
reference is a L<Hash::MultiValue> object.

=item * parameters

Returns a L<Hash::MultiValue> hash reference containing B<decoded> (and merged) GET
and POST parameters.

=item * param

Returns B<decoded> GET and POST parameters with a CGI.pm-compatible param
method. This is an alternative method for accessing parameters in
$req->parameters. Unlike CGI.pm, it does I<not> allow
setting or modifying query parameters.

    $value  = $req->param( 'foo' );
    @values = $req->param( 'foo' );
    @params = $req->param;

=item * raw_query_parameters

This attribute is the same as C<query_parameters> of L<Plack::Request>.

=item * raw_body_parameters

This attribute is the same as C<body_parameters> of L<Plack::Request>.

=item * raw_parameters

This attribute is the same as C<parameters> of L<Plack::Request>.

=item * raw_param

This attribute is the same as C<param> of L<Plack::Request>.

=back

=head1 REQUEST ENVIRONMENTS of Plack

You can specify the encoding method, like so;

    $req->env->{'plack.request.withencoding.encoding'} = 'utf-7'; # <= set utf-7

And this encoding method will be used to decode.

Default encoding method is B<utf-8>. If C<< $req->env->{'plack.request.withencoding.encoding'} >> is undef
then default encoding method will be used.

=head1 SEE ALSO

L<Plack::Request>

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut
