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
    # Path actions could be declared from "greedy" matching to "most exact"
    # matching conditions
    sub any : Path Args {
        $_[1]->res->body('any #1');
    }

    sub path : Path('path') Args {
        $_[1]->res->body('path #1');
    }

    sub path_zero : Path('path') Args(0) {
        $_[1]->res->body('path zero #1');
    }

    sub path_one : Path('path') Args(1) {
        $_[1]->res->body('path one #1');
    }

    sub path_one_post : POST Path('path') Args(1) {
        $_[1]->res->body('path one post #1');
    }



    # But also "any" (or default) path could be defined at the end
    #
    # Override actions
    sub path_one_post2 : POST Path('path') Args(1) {
        $_[1]->res->body('path one post');
    }

    # GET is needed to skip POST matching
    sub path_one2 : GET Path('path') Args(1) {
        $_[1]->res->body('path one');
    }

    sub path_zero2 : Path('path') Args(0) {
        $_[1]->res->body('path zero');
    }

    sub path2 : Path('path') Args {
        $_[1]->res->body('path');
    }

    sub any2 : Path Args {
        $_[1]->res->body('any');
    }


    #
    # Chained
    #

    sub base : Chained('/') PathPart('chain') CaptureArgs(0) { }

    # Chained with CaptureArgs should be declared with most greedy - at the top
    sub chain_any :        Chained('base') PathPart('')      CaptureArgs(0) { }
    sub chain_del : DELETE Chained('base') PathPart('')      CaptureArgs(0) { }


    sub chained_any : Chained('chain_any') PathPart('') Args {
        $_[1]->res->body('chained any');
    }

    sub chained_any_get : GET Chained('chain_any') PathPart('') Args {
        $_[1]->res->body('chained any get');
    }



    # Now (since 5.90085) too...

    sub chained_zero : Chained('chain_any') PathPart('') Args(0) {
        $_[1]->res->body('chained zero #1');
    }

    sub chained_zero1 : Chained('chain_any') PathPart('') Args(0) {
        $_[1]->res->body('chained zero');
    }

    sub chained_zero_post : POST Chained('chain_any') PathPart('') Args(0) {
        $_[1]->res->body('chained zero post');
    }

    sub chained_zero_get : GET Chained('chain_any') PathPart('') Args(0) {
        $_[1]->res->body('chained zero get');
    }




    # XXX
    # Chained actions with Args(N), where N>0, should be declared like Path:
    # most greedy - first!

    sub chained_one1 : Chained('chain_any') PathPart('') Args(1) {
        $_[1]->res->body('chained one #1');
    }

    sub chained_one : Chained('chain_any') PathPart('') Args(1) {
        $_[1]->res->body('chained one');
    }

    sub chained_one_post : POST Chained('chain_any') PathPart('') Args(1) {
        $_[1]->res->body('chained one post');
    }

    sub chained_one_get : GET Chained('chain_any') PathPart('') Args(1) {
        $_[1]->res->body('chained one get');
    }

    # XXX
    # You can't declare "default" Chained (with Args) at the end.
    # MUST be defined at the top of controller
    #
#    sub chained_any2 : Chained('chain_any') PathPart('') Args {
#        $_[1]->res->body('chained any second');
#    }


    sub chained_any_del : Chained('chain_del') PathPart('') Args(1) {
        $_[1]->res->body('chained any delete');
    }
};


package MyApp {
    use Catalyst;

    MyApp->setup();
};
use Catalyst::Test 'MyApp';


subtest 'Path' => sub {
    is( request( GET '/' )->content, 'index' );

    is( request( GET '/any/location' )->content,             'any' );
    is( request( GET '/path/a/n/y/_/n/u/m/b/e/r' )->content, 'path' );
    is( request( GET '/path' )->content,                     'path zero' );
    is( request( GET '/path/one' )->content,                 'path one' );
    is( request( POST '/path/one' )->content,                'path one post' );

};


subtest 'Chained' => sub {
    is( request( GET  '/chain/a/n/y' )->content,    'chained any get' );
    is( request( POST '/chain/a/n/y' )->content,   'chained any' );

    is( request( DELETE '/chain/1' )->content, 'chained any delete' );

    is( request( GET '/chain/1' )->content,  'chained one get' );
    is( request( POST '/chain/1' )->content, 'chained one post' );
    is( request( PUT '/chain/1' )->content,  'chained one' );

    is( request( GET '/chain' )->content,  'chained zero get' );
    is( request( POST '/chain' )->content, 'chained zero post' );
    is( request( PUT '/chain' )->content,  'chained zero' );
};

done_testing;
