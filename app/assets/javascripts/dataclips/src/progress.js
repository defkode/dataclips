module.exports = Backbone.View.extend({
  el: "#progress",
  initialize: function(options){
    bg = this.$el.get(0);
    this.ctx = bg.getContext('2d');
    this.ctx.lineWidth = 10.0;

    this.ctx.beginPath();
    this.ctx.strokeStyle = '#6F5498';
    this.ctx.closePath();
    this.ctx.fill();
    this.imd = this.ctx.getImageData(0, 0, 240, 240);
  },
  moveProgressBar: function(percentLoaded){
    $("#modal, #progress").toggle(percentLoaded !== 1)
    this.draw(percentLoaded);
  },
  draw: function(percentLoaded) {
    this.ctx.putImageData(this.imd, 0, 0);
    this.ctx.beginPath();

    circ = Math.PI * 2;
    quart = Math.PI / 2;

    this.ctx.arc(120, 120, 70, -quart, (circ * percentLoaded) - quart, false);
    this.ctx.stroke();
  }
});
