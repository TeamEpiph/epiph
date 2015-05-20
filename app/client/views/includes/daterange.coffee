Template.daterange.rendered = ->
  format = "DD.MM.YYYY"
  #$('.daterange').val(moment().format(format)) 
  $('.daterange').daterangepicker 
    format: format
    startDate: moment()
    endDate: moment()
    ranges:
      'Tomorrow': [
        moment().add(1, 'days')
        moment().add(1, 'days')
      ]
      'Today': [
        moment()
        moment()
      ]
      'Yesterday': [
        moment().subtract(1, 'days')
        moment().subtract(1, 'days')
      ]
      'Last 7 Days': [
        moment().subtract(6, 'days')
        moment()
      ]
      'Last 30 Days': [
        moment().subtract(29, 'days')
        moment()
      ]
      'This Month': [
        moment().startOf('month')
        moment().endOf('month')
      ]
      'Last Month': [
        moment().subtract(1, 'month').startOf('month')
        moment().subtract(1, 'month').endOf('month')
      ]
  daterangepicker = $('.daterange').data('daterangepicker')
  daterangepicker.setStartDate(moment())
  daterangepicker.setEndDate(moment())
  #trigger apply.daterangepicker event
  daterangepicker.clickApply()
  return
