const POLL_CODE = window.location.pathname.split('/').slice(-1);
let has_voted = false;

const dp = (number, places = 2) => {
  return Number.parseFloat(number).toFixed(2);
}

const disable_vote = () => {
  has_voted = true;
  $('#vote')
    .addClass('disabled')
    .val("You've already voted.")
    .prop('disabled', true)
    .css({
      background: "#eee",
      padding: "0 10px"
    });
  $('#submit')
    .addClass('disabled')
    .prop('disabled', true)
    .css({
      background: '#eee',
      color: "#888",
      border: "2px solid #aaa"
    });
};

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

const total_vote = votes => (
  Object.values(votes)
    .reduce((acc, v) => acc + v.number, 0.00001)
);

const total_primary = votes => (
  Object.values(votes)
    .filter(v => v.primary)
    .reduce((acc, v) => acc + v.number, 0.00001)
);

const total_other = votes => (
  Object.values(votes)
    .filter(v => !v.primary)
    .reduce((acc, v) => acc + v.number, 0.00001)
);

const update_votes = () => {
  const votes = get_votes(POLL_CODE);
  $('#primary').empty();
  $('#primary').append(`
    <tr>
      <th>Primary Options</th>
      <th>№</th>
      <th>%</th>
      <th>Cast</th>
    </tr>
  `);
  $('#other').empty();
  $('#other').append(`
    <tr>
      <th>Other Options</th>
      <th>№</th>
      <th>%</th>
      <th>Agree</th>
    </tr>
  `);
  for (const name of Object.keys(votes)) {
    if (votes[name].primary) {
      $('#primary').append(`
        <tr>
          <td class="vote-name">${name}</td>
          <td class="number" >${votes[name].number}</td>
          <td class="precent">${dp(100 * votes[name].number / total_vote(votes))}</td>
          <td class="cast"><button class="caster" name="${name}" onclick="cast_button('${name}')">Vote</button></td>
        </tr>
      `);
    } else {
      $('#other').append(`
        <tr>
          <td class="vote-name">${name}</td>
          <td class="number" >${votes[name].number}</td>
          <td class="precent">${dp(100 * votes[name].number / total_vote(votes))}</td>
          <td class="cast"><button class="caster" name="${name}" onclick="cast_button('${name}')">Vote</button></td>
        </tr>
      `)
    }
  }
};

const cast_button = name => {
  if (has_voted)
    issue(ISSUE.WARN, "You've already had your vote.");
  $('#vote').val(name);
  $('#cast').submit();
  disable_vote();
  setTimeout(update_votes, 70);
};

$('document').ready(() => {
  update_votes();
  setInterval(update_votes, 1500);  // Live view of votes.

  $.ajax({
    url: POLL_CODE + '/has-voted',
    async: false,
    success: data => {
      console.info('Has already voted?: ', data);
      if (data === "true") disable_vote();
    }
  });

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
        disable_vote();
        $('#submit').blur();
      },
      error: e => {
        issue(ISSUE.FATAL, `
          An erro occured while casting your vote.\n
          More Information:\n
          ${e}
        `);
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
