$('document').ready(() => {
  $('.url').text(`${window.location.protocol}//${window.location.host}/poll/`)

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
    let polls = [];
    $.ajax({
      async: false,
      type: 'GET',
      url: '/polls.json',
      success: data => {
        polls = data;
        console.info(polls);
      }
    });

    // Verify inputs!
    if ($('#title').val().trim().length === 0) {
      $('#title').attention();
      issue(ISSUE.WARN, `
        The title of your poll cannot be left blank.
      `);
    } else if ($('#code').val().trim().length === 0) {
      $('#code').attention();
      issue(ISSUE.FATAL, `
        The poll link name (the name in the URL) cannot be left blank.
      `);
    } else if (!$('#other').is(':checked') && Array(...$('#options li').map((i, e) => e.innerHTML)).length === 0) {
      $('#addition').attr('placeholder', 'Add at least 1 option.').attention();
      issue(ISSUE.WARN, `
        Unless you allow for 'other' options,
        you need to add at least one primary option.
      `);
    } else if (polls.includes($('#code').val())) {
      issue(ISSUE.FATAL, `
        The poll URL: '${$('#code').val()}' has already been taken.
      `);
      $('#code').attention();
    } else {  // All checks passed
      $('#create').submit();
      setTimeout(() => {
        window.location.href = '/share/' + $('#code').val();
      }, 10);
    }
    return false;
  });
});
