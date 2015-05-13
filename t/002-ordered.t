use strict;
use warnings;

use Test::Most;
use lib 't/lib';

use HTTP::Request::Common qw(GET POST DELETE PUT);

package MyApp::Controller::Root {
    use Moose;
    use MooseX::MethodAttributes;
    use MooseX::Types::Moose qw(Int Num);

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
        $_[1]->res->body('loc zero');
    }

    sub path_get_any : GET Path('loc') Args {
        $_[1]->res->body('GET path any');
    }

    sub path_get_zero : GET Path('loc') Args(0) {
        $_[1]->res->body('GET path zero');
    }

    sub path_get_int : GET Path('loc') Args(Int) {
        $_[1]->res->body('GET path int');
    }

    sub path_get_one : GET Path('loc') Args(1) {
        $_[1]->res->body('GET path one');
    }

    sub another_loc : Path('loc') Args(0) {
        $_[1]->res->body('another zero');
    }

    sub another_path_get_any : GET Path('loc') Args {
        $_[1]->res->body('GET another path any');
    }

    sub another_any : Path Args {
        $_[1]->res->body('another any');
    }

    sub path_put_zero : PUT Path('loc') Args(0) {
        $_[1]->res->body('PUT path zero');
    }



    # Chained Args
    sub base_a    :        Chained('/')      PathPart('a') CaptureArgs(0) { }
    sub chain_del : DELETE Chained('base_a') PathPart('')      CaptureArgs(0) { }
    sub chain_any :        Chained('base_a') PathPart('')      CaptureArgs(0) { }


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



    # Chained CaptureArgs
    sub base_ca      :        Chained('/')       PathPart('ca') CaptureArgs(0) { }

    sub zero_del     : DELETE Chained('base_ca') PathPart('')   CaptureArgs(0) { }
    sub zero_any     :        Chained('base_ca') PathPart('')   CaptureArgs(0) { }
    sub zero_get     : GET    Chained('base_ca') PathPart('')   CaptureArgs(0) { }

    sub one_del_int : DELETE Chained('base_ca') PathPart('')   CaptureArgs(Int) { }
    sub one_del     : DELETE Chained('base_ca') PathPart('')   CaptureArgs(1)   { }
    sub one_any_num :        Chained('base_ca') PathPart('')   CaptureArgs(Num) { }
    sub one_any     :        Chained('base_ca') PathPart('')   CaptureArgs(1)   { }
    sub one_any_int :        Chained('base_ca') PathPart('')   CaptureArgs(Int) { }
    sub one_get     : GET    Chained('base_ca') PathPart('')   CaptureArgs(1)   { }
    sub one_get_int : GET    Chained('base_ca') PathPart('')   CaptureArgs(Int) { }


    sub chained_zero_del : Chained('zero_del') PathPart('') Args {
        $_[1]->res->body('chained zero del');
    }

    sub chained_zero_any : Chained('zero_any') PathPart('') Args {
        $_[1]->res->body('chained zero any');
    }

    sub chained_ca__zero_get : Chained('zero_get') PathPart('') Args {
        $_[1]->res->body('chained zero get');
    }

    sub chained_one_del_int : Chained('one_del_int') PathPart('') Args {
        $_[1]->res->body('chained one del int');
    }

    sub chained_one_del : Chained('one_del') PathPart('') Args {
        $_[1]->res->body('chained one del');
    }

    sub chained_one_any_num : Chained('one_any_num') PathPart('') Args {
        $_[1]->res->body('chained one any num');
    }

    sub chained_one_any : Chained('one_any') PathPart('') Args {
        $_[1]->res->body('chained one any');
    }

    sub chained_one_any_int : Chained('one_any_int') PathPart('') Args {
        $_[1]->res->body('chained one any int');
    }

    sub chained_ca_one_get : Chained('one_get') PathPart('') Args {
        $_[1]->res->body('chained one get');
    }

    sub chained_one_get_ca_int : Chained('one_get_int') PathPart('') Args {
        $_[1]->res->body('chained one get int');
    }
};


package MyApp {
    use Catalyst qw(+CatalystX::OrderedActions);

    MyApp->setup();
};
use Catalyst::Test 'MyApp';


subtest 'Path' => sub {
    is( request( GET '/' )->content,         'index' );
    is( request( GET '/loc/1' )->content,    'GET path int' );
    is( request( GET '/loc/one' )->content,  'GET path one' );
    is( request( GET '/loc/1/2' )->content,  'GET another path any' );
    is( request( POST '/loc/1/2' )->content, 'another any' );
    is( request( POST '/loc/1' )->content,   'another any' );
    is( request( GET '/loc' )->content,      'GET path zero' );
    is( request( POST '/loc' )->content,     'another zero' );
    is( request( PUT '/loc' )->content,      'PUT path zero' );
};


subtest 'Chained Args' => sub {
    is( request( GET '/a/1/2' )->content,    'chained any get' );
    is( request( POST '/a/1/2' )->content,   'chained any post' );
    is( request( PUT '/a/1/2' )->content,    'chained any second' );
    is( request( DELETE '/a/1/2' )->content, 'chained any delete' );

    is( request( GET '/a/1' )->content,  'chained one get' );
    is( request( POST '/a/1' )->content, 'chained one post' );
    is( request( PUT '/a/1' )->content,  'chained one second' );

    is( request( GET '/a' )->content,  'chained zero get' );
    is( request( POST '/a' )->content, 'chained zero post' );
    is( request( PUT '/a' )->content,  'chained zero second' );
};


subtest 'Chained CaptureArgs' => sub {
    is( request( DELETE '/ca/' )->content, 'chained zero del' );
    is( request( POST   '/ca/' )->content, 'chained zero any' );
    is( request( GET    '/ca/' )->content, 'chained zero get' );

    is( request( DELETE '/ca/1' )->content, 'chained one del int' );
    is( request( DELETE '/ca/a' )->content, 'chained one del' );

    is( request( POST '/ca/1.2' )->content, 'chained one any num' );
    is( request( POST '/ca/a'   )->content, 'chained one any' );
    is( request( POST '/ca/1'   )->content, 'chained one any int' );

    is( request( GET '/ca/a' )->content, 'chained one get' );
    is( request( GET '/ca/1' )->content, 'chained one get int' );
};

done_testing;
