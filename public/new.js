$('document').ready(() => {
  $('#create').submit(() => {
    $.ajax({
      type: 'POST',
      url: '/new',
      async: false,
      data: {
        name: $('#title').val().trim(),
        code: $('#code').val(),
        alt:  $('#other').is(':checked'),
        primary: Array(...$('#options li').map((i, e) => e.innerHTML))
      },
      success: () => {
        console.info('New poll made.');
      }
    });
    return false;
  });
  $('#submit-poll').click(() => {
    if (Array(...$('#options li').map((i, e) => e.innerHTML)).length === 0) {
      $('#addition').attr('placeholder', 'Add at least 1 option.').select().focus();
    } else {
      $('#create').submit();
      setTimeout(() => {
        window.location.href = '/share/' + $('#code').val();
      }, 10);
    }
    return false;
  });
});
