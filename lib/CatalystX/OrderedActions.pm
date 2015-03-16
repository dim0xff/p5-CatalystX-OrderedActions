package CatalystX::OrderedActions;

# ABSTRACT: role for L<Catalyst> controller to "correct" actions order

use Moose::Role;
use namespace::autoclean;

use Carp;
use Scalar::Util 'looks_like_number';
use List::MoreUtils 'uniq';

use Data::Dumper;

after setup_actions => sub {
    my $self = shift;

    my $ns = ref $self;
    for my $dt ( @{ $self->dispatcher->dispatch_types } ) {
        my $type = ref $dt;

        $type =~ s/^Catalyst::DispatchType:://;

        if ( $type eq 'Path' ) {
            $self->log->debug("Reorder Path actions...") if $self->debug;

            # warn Dumper($dt);

            for my $actions ( values %{ $dt->_paths } ) {
                croak "Not array" unless ref $actions eq 'ARRAY';

                $actions
                    = [ sort { $self->compare_actions( $a, $b ) } @{$actions} ];
            }

            # warn Dumper($dt);
        }
        elsif ( $type eq 'Chained' ) {
            $self->log->debug("Reorder Chained actions...") if $self->debug;

            # warn Dumper( $dt->_children_of );

            for my $paths ( values %{ $dt->_children_of } ) {
                croak "Not hash" unless ref $paths eq 'HASH';

                for my $actions ( values %{$paths} ) {
                    croak "Not array" unless ref $actions eq 'ARRAY';

                    #<<< no tidy
                    my @zero_actions =
                        sort { $self->compare_actions( $a, $b ) }
                        grep {
                            0 == (
                                exists $_->attributes->{Args}
                                    ? ( $_->attributes->{Args} || [] )->[0] // -1
                                    : -1
                            )
                        } @{$actions};

                    my @undef_actions =
                        sort { $self->compare_actions( $a, $b ) }
                        grep {
                            not defined(
                                exists $_->attributes->{Args}
                                    ? ( $_->attributes->{Args} || [] )->[0]
                                    : undef
                            )
                        } reverse @{$actions};

                    my @args_actions =
                        sort { $self->compare_actions( $a, $b ) }
                        grep {
                            0 < (
                                exists $_->attributes->{Args}
                                    ? ( $_->attributes->{Args} || [] )->[0] // -1
                                    : -1
                            )
                        } reverse @{$actions};

                    $actions = [
                        reverse(@args_actions),
                        reverse(@zero_actions),
                        reverse @undef_actions,
                    ];
                    #>>>
                }
            }

            # warn Dumper( $dt->_children_of );
        }
        elsif ( $self->debug ) {
            $self->log->debug("Don't know how to reorder $type actions...");
        }
    }
};


# Compare rules to future compare sort order.
# HASH with rules:
# (
#   RULE => DEFINITION
# )
# RULE := string
# DEFINITION:= -1 | 0 | 1 | coderef
#
# Default rule (no sorting): * => 0
#
# When DEFINITION is integer, then RULE is being used
# as action attribute key to get values:
# $self->attributes->{RULE} * DEFINITION
#
# When DEFINITION is coderef, then rule value is
# result of calling DEFINITION->($self)

sub _compare_rules {
    my %rules = (
        '*'  => 0,
        Args => sub {
            my $action = shift;

            my ($val) = @{ $action->attributes->{Args} || [] };

            return looks_like_number($val) ? $val : ( ~0 >> 4 );
        },
        Scheme   => -1,
        Method   => -1,
        Consumes => -1,

    );
    $rules{CaptureArgs} = $rules{Args};

    return %rules;
}

# Rules keys. Order of keys is equal to compare order checks
sub _action_compare_keys {
    my ( $self, $action ) = @_;
    my @known = ( 'Args', 'CaptureArgs', 'Scheme', 'Method', 'Consumes' );

    my @available;
    for my $key (@known) {
        next unless exists $action->attributes->{$key};
        push( @available, $key );

        shift(@available) if $key eq 'CaptureArgs' && $available[0] eq 'Args';
    }

    return @available;
}

# rule definition for specified rule
sub _compare_rule {
    my ( $self, $attr ) = @_;

    my %rules = $self->_compare_rules;

    return ( $rules{$attr} // $rules{'*'} );
}

# rule value for specified rule
sub _action_compare_value {
    my ( $self, $action, $attr ) = @_;

    my $rule = $self->_compare_rule($attr);

    if ( ref $rule eq 'CODE' ) {
        return $rule->($action);
    }
    else {
        return 0 unless exists $action->attributes->{$attr};
        return $rule * @{ $action->attributes->{$attr} || [] };
    }
}

sub compare_actions {
    my ( $self, $a1, $a2 ) = @_;

    my %cmp = (
        a1 => {},
        a2 => {},
    );

    my @a1keys = $self->_action_compare_keys($a1);
    my @a2keys = $self->_action_compare_keys($a2);

    for my $attr ( uniq( @a1keys, @a2keys ) ) {
        $cmp{a1}{$attr} = $self->_action_compare_value( $a1, $attr ) * @a1keys;
        $cmp{a2}{$attr} = $self->_action_compare_value( $a2, $attr ) * @a2keys;
    }

    my $cmp = 0;
    $cmp ||= $cmp{a1}{$_} <=> $cmp{a2}{$_} for uniq( @a1keys, @a2keys );

    return $cmp;
}

1;

__END__

=head1 SYNOPSIS

    package MyApp;
    use Catalyst qw(+CatalystX::OrderedActions);


    package MyApp::Controller::Resource;

    use base qw(Catalyst::Controller);
    use Moose;
    with 'CatalystX::TraitFor::Controller::OrderedActions';

    sub show    : GET     Path('/res') Args(1) { ... }
    sub modify  :         Path('/res') Args(1) { ... }
    sub options : OPTIONS Path('/res') Args(1) { ... }

=head1 DESCRIPTION

This role tries to add actions matching order based on priorities into
L<Path|Catalyst::DispatchType::Path>
and L<Chained|Catalyst::DispatchType::Chained> dispatch types.

=head1 MATCHING PRIORITY

Path and Chained actions should respect addition matching logic.

Dispatcher should match path to action with some priority (matching order).

Each matching order position should depends on Args and fact of existing addition
matching (in group, like SQL ORDER BY by several fields).

=head2 Path

...

=head2 Chained

...

=head1 SEE ALSO

For discussion you could refer to github pull request
L<#87|https://github.com/perl-catalyst/catalyst-runtime/pull/87>.
