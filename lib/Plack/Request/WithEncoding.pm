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

sub param {
    my $self = shift;

    my $parameters = $self->parameters;
    return keys %{ $parameters } if @_ == 0;

    my $key = shift;
    return $parameters->{$key} unless wantarray;
    return $parameters->get_all($key);
}

sub raw_body_parameters {
    shift->SUPER::body_parameters;
}

sub raw_query_parameters {
    shift->SUPER::query_parameters;
}

sub raw_parameters {
    shift->SUPER::parameters;
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

    my @flatten  = $stuff->flatten;
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

Plack::Request::WithEncoding - It's new $module

=head1 SYNOPSIS

    use Plack::Request::WithEncoding;

=head1 DESCRIPTION

Plack::Request::WithEncoding is ...

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut
