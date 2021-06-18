const ALPHA_RANGE = {
  min: 0.08,
  max: 1
}

const chart_colors = chart => {
  const range = ALPHA_RANGE;
  const N = chart.data.datasets[0].data.length;
  backgrounds = Array(N);
  for (let mono = range.min; mono <= range.max; mono += range.max / (N + 1))
    backgrounds[Math.round((mono - range.min) * N / range.max)] = `rgba(${BASE},${mono})`;
  chart.data.datasets[0].backgroundColor = backgrounds;
  return backgrounds;
};

const chart_empty = chart => {
  chart.data.labels = [];
  chart.data.datasets[0].data = [];
};

const push_data = (chart, label, data) => {
  chart.data.labels.push(label);
  chart.data.datasets.forEach((dataset) => {
    dataset.data.push(data);
  });
}

$(document).ready(() => {
  $('.home').click(() => {
    window.location.href = '/';
  })
  for (const canvas of ['#pie', '#bar']) {
    const context = $(canvas)[0];
    const dimension = $(canvas).closest('div').innerWidth() - 22;
    context.height = dimension;
    context.width = dimension;
  }
});


// CHARTS:
let pie;
let bar;  // Make sure they're global.
$(document).ready(() => {
  const pie_context = $('#pie');

  pie = new Chart(pie_context[0], {
    type: 'pie',
    data: {
      labels: [],
      datasets: [{
        label: '№	of Votes',
        data: [],
        backgroundColor: [],
      }]
    },
    options: {}
  });

  const bar_context = $('#bar')
  bar = new Chart(bar_context[0], {
    type: 'horizontalBar',
    data: {
      labels: [],
      datasets: [{
        label: '№	of Votes',
        data: [],
        backgroundColor: `rgba(${BASE}, 0.05)`,
      }]
    },
    options: {
      title: {
        display: true,
        color: '#fff',
        text: 'Distribution of alternative/other votes.'
      },
      scales: {
        yAxes: [{
          gridLines: {
            color: `rgba(${BASE}, 0.1)`,
          },
          categoryPercentage: 0.9,
          barPercentage: 1.0,
          ticks: {
            mirror: true,
            padding: -10,
          }
        }],
        xAxes: [{
          gridLines: {
            color: `rgba(${BASE}, 0.1)`,
          },
          ticks: {
            stepSize: 1
          }
        }]
      },
      legend: {
        display: false,
      }
    }
  });
});
