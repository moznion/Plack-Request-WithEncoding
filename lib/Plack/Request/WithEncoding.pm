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
    my $self = shift;

    my $encoding_key = KEY_BASE_NAME . '.encoding';
    $self->env->{$encoding_key} = defined $self->env->{$encoding_key} ? $self->env->{$encoding_key}
                                                                      : DEFAULT_ENCODING;
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

sub body_parameters_raw {
    shift->SUPER::body_parameters;
}

sub query_parameters_raw {
    shift->SUPER::query_parameters;
}

sub parameters_raw {
    shift->SUPER::parameters;
}

sub param_raw {
    my $self = shift;

    return keys %{ $self->parameters_raw } if @_ == 0;

    my $key = shift;
    return $self->parameters_raw->{$key} unless wantarray;
    return $self->parameters_raw->get_all($key);
}

sub _decode_parameters {
    my ($self, $stuff) = @_;

    my $encoding = $self->encoding;
    unless (Encode::find_encoding($encoding)) {
        my $warning = sprintf("Unknown encoding '%s'. It will use '%s'.", $encoding, DEFAULT_ENCODING);
        Carp::carp($warning);
        $encoding = DEFAULT_ENCODING;
    }

    my @flatten  = $stuff->flatten;
    my @decoded;
    while ( my ($k, $v) = splice @flatten, 0, 2 ) {
        push @decoded, Encode::decode($encoding, $k), Encode::decode($encoding, $v);
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
