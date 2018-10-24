const ISSUE = Object.freeze({
  "FATAL": 'Error',
  "WARN":  'Warning',
  "INFO":  'Information'
});

let issue_n = 0;
const issue = (type, message) => {
  issue_n++;
  if ($('body').has('.issues').length > 0) {
    $('.issues').append(`
      <div class="issue ${type.toLowerCase()}">
        <h3>${type}</h3>
        <p>${message}</p>
      </div>
    `);
    const added = $($('.issues .issue').get(-1));

    setTimeout((cont = added) => {
      cont.addClass('show');
    }, 10);

    setTimeout((cont = added) => {
      cont.fadeOut(700, () => cont.remove());
    }, 5000);
  } else {
    $('body').append(`<div class="issues"></div>`);
    issue(type, message);
  }
};

jQuery.fn.attention = function() {
    this.each(function(i) {
      $(this).select().focus().addClass('problem').effect('shake');
      setTimeout(() => $(this).removeClass('problem'), 1000);
    });
    return this;
};
