package OpenAIAPI::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub index ($self) {
  my $thing = $self->param('thing') || '';
  my $stuff = $self->every_param('stuff');
  $stuff = [qw(abc 123 xyz 667)] unless @$stuff;
  $self->render(
    thing => $thing,
    stuff => $stuff,
  );
}

sub update ($self) {
  my $v = $self->validation;
  $v->required('thing')->size(0, 10);
  $v->required('thing', 'trim');
  my $thing = $v->param('thing');
  if ($v->error('thing')) {
    $self->flash(error => 'Invalid thing!');
    $thing = '';
  }
  $v->optional('stuff', 'trim');
  my $stuff = $v->every_param('stuff');
  $self->redirect_to(
    $self->url_for('index')->query(thing => $thing, stuff => $stuff)
  );
}

sub help ($self) { $self->render }

1;
