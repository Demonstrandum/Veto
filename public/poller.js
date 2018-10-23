const POLL_CODE = window.location.pathname.split('/').slice(-1);

const get_votes = () => {
  let json = {error: "Couldn't get votes..."};
  $.ajax({
    url: POLL_CODE + '/votes.json',
    async: false,
    dataType: 'json',
    success: data => {
      json = data;
    },
  });
  return json;
};

const cast_button = name => {
  $('#vote').val(name);
  $('#cast').submit();
  setTimeout(update_votes, 70);
};

const update_votes = () => {
  let votes = get_votes(POLL_CODE);
  $('#live').empty();
  for (const name of Object.keys(votes))
    $('#live').append(`
      <li>
        ${name}: ${votes[name].number}
        <button name="${name}" onclick="cast_button('${name}')">Vote</button>
      </li>
    `);
};

$('document').ready(() => {
  update_votes();
  setInterval(update_votes, 1500);  // Live view of votes.

  $('#cast').submit(() => {
    $.ajax({
      type: 'POST',
      url: POLL_CODE + '/cast',
      async: false,
      data: {
        vote: $('#vote').val()
      },
      success: () => {
        get_votes(POLL_CODE);
      }
    });
    return false;
  });
  $('#submit').click(() => {
    $('#cast').submit();
    setTimeout(update_votes, 70);
    return false;
  });
});
