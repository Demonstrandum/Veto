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
        primary: Array(...$('#options li span').map((i, e) => e.innerHTML))
      },
      success: () => {
        console.info('New poll made.');
      }
    });
    return false;
  });
  $('#submit-poll').click(() => {
    // Save all changes.
    if (!save()) {
      return false;
    }

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
    } else if (!$('#other').is(':checked') && Array(...$('#options li span').map((i, e) => e.innerHTML)).length === 0) {
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


let editing = NaN;

const add_list = option => {
  $('#addition').val('');
  let adder = $(".option").detach();
  $("#options")
    .append(`
      <li class="option-item">
        <span class="value">${option}</span>
        <div class="symbols">
          <i class="option-edit far fa-edit"></i>
          <i class="option-remove fas fa-times"></i>
        </div>
      </li>
    `)
    .append(adder);
  $('#addition').focus().select();
};


$('#options').on('click', '.option-remove', e => {
  const li = $(e.target).closest('li');
  li.slideUp(100, function() { $(this).remove(); });
  console.warn(li[0], 'Element been removed!');
});

const save = () => {
  const inputs = $('#options li').children('input');
  let values = Array(...$('#options li span')
                .filter((i, e) => e.style.display !== 'none')
                .map((i, e) => e.innerHTML));
  console.log(values);

  let bad_input = null;
  inputs.each(function() {
    const value = this.value;
    if (value.length === 0) {
      issue(ISSUE.FATAL, `Cannot leave new value empty. Delete it if you don't want it.`);
      bad_input = $(this);
      return;
    }
    if (values.includes(value)) {
      issue(ISSUE.FATAL, `Cannot have duplicate (primary) options/choices!`);
      bad_input = $(this);
      return;
    }

    $(this).parent('li').removeClass('dark-option');
    $(this).siblings('span').show().text(value);
    $(this).siblings('.symbols').find('.option-edit')
      .removeClass('fa-save')
      .addClass('fa-edit');
    this.remove();
  });

  if (bad_input !== null) {
    bad_input.attention();
    return false;
  }

  let value = $("#addition").val().trim();

  if (values.includes(value)) {
    issue(ISSUE.FATAL, `Cannot have duplicate (primary) options/choices!`);
    $('#addition').attention();
    return false;
  }


  if (value.length > 0) add_list(value);
  return true;
};

$(document).on('click', e => {
  if (!( $(e.target).hasClass('editor')
      || $(e.target).hasClass('option-item')
      || $(e.target).hasClass('fa-save')
      || $(e.target).hasClass('value')
    )) {
    save();
    editing = NaN;
  }
});

const edit_mode = li => {
  const span = li.find('span');
  span.hide();
  li.addClass('dark-option');
  li.find('.option-edit')
    .removeClass('fa-edit')
    .addClass('fa-save');
  li.prepend(`<input class="editor" type="text" value="${span.text()}" />`);
  li.find('input').focus().select();
};

$('#options').on('click', 'li', e => {
  if (e.target.nodeName === 'INPUT') return;
  let li = $(e.currentTarget);
  save();

  if (editing !== li.index()) {
    editing = li.index();
    edit_mode(li);
  } else {
    editing = NaN;
  }
});

$(document).on('keypress', '.editor', key => {
  if (key.which === 13 || key.which === 10) {
    key.preventDefault();
    save();
    editing = NaN;
  }
});

$("#addition").on('keypress', key => {
  let value = $("#addition").val().trim();
  if (key.which === 13 || key.which === 10) {
    if (value.length === 0) {
      return $('#addition').attention();
    }
    key.preventDefault();
    save();
  }
});
$('.add-option').click(() => {
  if ($('#addition').val().length === 0) {
    $('#addition').attention();
    return;
  }
  save();
});

$("#title").on('input', () => {
  $("#code").val(encodeURIComponent($("#title").val().toLowerCase().replace(/\s|\\|\//g, '-')));
});

$('#code')[0].addEventListener('keyup', e => {
  $("#code").val(encodeURIComponent($("#code").val().replace(/[^A-Za-z\d\-\.\!\']/g, '-')));
});
