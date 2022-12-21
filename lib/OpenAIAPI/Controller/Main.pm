package OpenAIAPI::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub index ($self) {
  my $prompt = $self->param('prompt') || '';
  $self->render(
    prompt => $prompt,
  );
}

sub update ($self) {
  my $v = $self->validation;
  $v->required('prompt')->size(0, 10);
  $v->required('prompt', 'trim');
  my $prompt = $v->param('prompt');
  if ($v->error('prompt')) {
    $self->flash(error => 'Invalid prompt!');
    $prompt = '';
  }
  $self->redirect_to(
    $self->url_for('index')->query(prompt => $prompt)
  );
}

sub help ($self) { $self->render }

1;
