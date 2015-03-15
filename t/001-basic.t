use strict;
use warnings;

use Test::Most;
use lib 't/lib';

use HTTP::Request::Common qw(GET POST DELETE PUT);

package MyApp::Controller::Root {
    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    __PACKAGE__->config( namespace => '' );

    sub index : Index {
        $_[1]->res->body('index');
    }


    # Path
    sub any : Path Args {
        $_[1]->res->body('any');
    }

    sub loc : Local Args(0) {
        $_[1]->res->body('loc');
    }

    sub path_get_any : GET Path('loc') Args {
        $_[1]->res->body('GET path any');
    }

    sub path_get_zero : GET Path('loc') Args(0) {
        $_[1]->res->body('GET path zero');
    }

    sub path_get_one : GET Path('loc') Args(1) {
        $_[1]->res->body('GET path one');
    }

    sub another_loc : Path('loc') Args(0) {
        $_[1]->res->body('another loc');
    }

    sub another_path_get_any : GET Path('loc') Args {
        $_[1]->res->body('GET another path any');
    }

    sub another_any : Path Args {
        $_[1]->res->body('another any');
    }


    # Chained
    sub base      :        Chained('/')    PathPart('chain') CaptureArgs(0) { }
    sub chain_any :        Chained('base') PathPart('')      CaptureArgs(0) { }
    sub chain_del : DELETE Chained('base') PathPart('')      CaptureArgs(0) { }



    sub chained_any_get : GET Chained('chain_any') PathPart('') Args {
        $_[1]->res->body('chained any get');
    }

    sub chained_any1 : Chained('chain_any') PathPart('') Args {
        $_[1]->res->body('chained any first');
    }



    sub chained_zero_get : GET Chained('chain_any') PathPart('') Args(0) {
        $_[1]->res->body('chained zero get');
    }

    sub chained_zero1 : Chained('chain_any') PathPart('') Args(0) {
        $_[1]->res->body('chained zero first');
    }

    sub chained_zero2 : Chained('chain_any') PathPart('') Args(0) {
        $_[1]->res->body('chained zero second');
    }

    sub chained_zero_post : POST Chained('chain_any') PathPart('') Args(0) {
        $_[1]->res->body('chained zero post');
    }



    sub chained_one_get : GET Chained('chain_any') PathPart('') Args(1) {
        $_[1]->res->body('chained one get');
    }

    sub chained_one1 : Chained('chain_any') PathPart('') Args(1) {
        $_[1]->res->body('chained one first');
    }

    sub chained_one2 : Chained('chain_any') PathPart('') Args(1) {
        $_[1]->res->body('chained one second');
    }

    sub chained_one_post : POST Chained('chain_any') PathPart('') Args(1) {
        $_[1]->res->body('chained one post');
    }



    sub chained_any2 : Chained('chain_any') PathPart('') Args {
        $_[1]->res->body('chained any second');
    }

    sub chained_any_post : POST Chained('chain_any') PathPart('') Args {
        $_[1]->res->body('chained any post');
    }

    sub chained_any_del : Chained('chain_del') PathPart('') Args {
        $_[1]->res->body('chained any delete');
    }
};


package MyApp {
    use Catalyst qw(+CatalystX::OrderedActions);

    #MyApp->config(show_internal_actions => 1);
    MyApp->setup();
};
use Catalyst::Test 'MyApp';


subtest 'Path' => sub {
    is( request( GET '/' )->content,         'index' );
    is( request( GET '/loc/1' )->content,    'GET path one' );
    is( request( GET '/loc/1/2' )->content,  'GET another path any' );
    is( request( POST '/loc/1/2' )->content, 'another any' );
    is( request( POST '/loc/1' )->content,   'another any' );
    is( request( GET '/loc' )->content,      'GET path zero' );
    is( request( POST '/loc' )->content,     'another loc' );
};


subtest 'Chained' => sub {
    is( request( GET '/chain/1/2' )->content,  'chained any get' );
    is( request( POST '/chain/1/2' )->content, 'chained any post' );
    is( request( PUT '/chain/1/2' )->content,  'chained any second' );
    is( request( DELETE '/chain/1/2' )->content,  'chained any delete' );

    is( request( GET '/chain/1' )->content,  'chained one get' );
    is( request( POST '/chain/1' )->content, 'chained one post' );
    is( request( PUT '/chain/1' )->content,  'chained one second' );

    is( request( GET '/chain' )->content,  'chained zero get' );
    is( request( POST '/chain' )->content, 'chained zero post' );
    is( request( PUT '/chain' )->content,  'chained zero second' );
};

done_testing;
