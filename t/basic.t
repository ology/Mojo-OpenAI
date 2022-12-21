use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('OpenAIAPI');

$t->ua->max_redirects(1);

subtest index => sub {
  $t->get_ok($t->app->url_for('index'))
    ->status_is(200)
    ->content_like(qr/Prompt:/)
    ->element_exists('label[for=prompt]')
    ->element_exists('textarea[name=prompt]')
    ->element_exists('input[type=submit]');
  ;
};

subtest update => sub {
  $t->post_ok($t->app->url_for('update'), form => { prompt => 'xyz' })
    ->status_is(200)
    ->element_exists('textarea[name=prompt]')
  ;

  $t->post_ok($t->app->url_for('update'), form => { prompt => 'x' x 2000 })
    ->status_is(200)
    ->content_like(qr/Invalid/)
  ;
};

subtest help => sub {
  $t->get_ok($t->app->url_for('help'))
    ->status_is(200)
  ;
};

done_testing();
