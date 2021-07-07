Highcharts.setOptions({colors: ['#FFDD00', '#444444', '#5CC8F3', '#0b65a2', '#1531AE', '#9B8600', '#9B8600', '#6F18FF', '#DDDF00', '#24CBE5', '#64E572', '#FF9655', '#FFF263', '#6AF9C4']});

window.graphCategory = 'Overall';
window.perCapita     = false;
window.keysMap       = {
  // map names of current results to historical results keys
  'Transportation'                              : 'transportation',
  'Transportation per Capita'                   : 'transportation_per_capita',
  'Overall'                                     : 'emissions_total',
  'Overall per Capita'                          : 'emissions_total_per_capita',
  'Food'                                        : 'emissions_food_total',
  'Food per Capita'                             : 'emissions_food_total_per_capita',
  'Home Energy'                                 : 'emissions_housing',
  'Home Energy per Capita'                      : 'emissions_housing_per_capita',
  'Electricity'                                 : 'emissions_electricity_total',
  'Electricity per Capita'                      : 'emissions_electricity_total_per_capita',
  'Heat'                                        : 'emissions_heating_total',
  'Heat per Capita'                             : 'emissions_heating_total_per_capita',
  'Waste'                                       : 'emissions_waste_total',
  'Waste per Capita'                            : 'emissions_waste_total_per_capita',
  'Transportation'                              : 'emissions_transportation',
  'Transportation per Capita'                   : 'emissions_transportation_per_capita',
  'Commuting & Public Transportation'           : 'emissions_commute_total',
  'Commuting & Public Transportation per Capita': 'emissions_commute_total_per_capita',
  'Personal Vehicles'                           : 'emissions_vehicles_sans_commuting',
  'Personal Vehicles per Capita'                : 'emissions_vehicles_sans_commuting_per_capita',
  'Trips'                                       : 'emissions_long_distance_travel',
  'Trips per Capita'                            : 'emissions_long_distance_travel_per_capita',
  'Offsets'                                     : 'offset_tons',
  'Offsets per Capita'                          : 'offset_tons_per_capita',
};

window.regionalAvgMap = {
  'Electricity'                           : 'emissions_electricity_total',
  'Other Fuels'                           : 'emissions_heating_total',
  'Housing Total'                         : 'emissions_housing',
  'Long Distance travel'                  : 'emissions_long_distance_travel',
  'Personal Vehicles Total (w/Commuting)' : 'emissions_transportation',
  'Personal Vehicles (w/out Commuting)'   : 'emissions_vehicles_sans_commuting',
  'Personal Vehicles (Commuting)'         : 'emissions_commute_total',
  'Food*'                                 : 'emissions_food_total',
  'Waste disposal*'                       : 'emissions_waste_total',
  'Trips'                                 : 'emissions_long_distance_travel',
  'Transportation Total'                  : 'emissions_transportation',
  'Total'                                 : 'emissions_total'
};

$.get(location.pathname + '/results.json?histograms=Overall,Home Energy,Transportation,Food and Waste,Overall per Capita,Home Energy per Capita,Transportation per Capita,Food and Waste per Capita,Heat').then(function(resp){
  /// normalize data for graphs
  if(window.resp = resp){
    // map results keys
    if(resp.data.survey.survey_year){
      newResultsObj = { year: resp.data.survey.survey_year }
    } else {
      newResultsObj = { year: (new Date()).getFullYear() - 1}
    }

    for(key in resp.data.current_results){
      newResultsObj[keysMap[key]] = parseFloat(parseFloat(resp.data.current_results[key]).toFixed(1))
    }

    resp.data.historical.push(newResultsObj)

    // find users location
    resp.usersLocation = resp.data.questions.filter(function(row){
      if(row.question.match(/work location/i)){
        return true
      }
    })[0].answer

    // map regional averages
    resp.regional_averages = resp.data.regional_averages[resp.usersLocation.toLowerCase()]
    newRegionalAvgObj = { year: resp.usersLocation }

    for(key in resp.regional_averages){
      newRegionalAvgObj[regionalAvgMap[key]] = parseFloat(resp.regional_averages[key])
      newRegionalAvgObj[regionalAvgMap[key]+'_per_capita'] = parseFloat(resp.regional_averages[key])/parseFloat(resp.regional_averages['Household Size'])
    }

    // map us averages
    resp.us_regional_averages = resp.data.regional_averages['united states of america']
    usAvgObj = { year: 'U.S.' }

    for(key in resp.us_regional_averages){
      usAvgObj[regionalAvgMap[key]] = parseFloat(resp.us_regional_averages[key])
      usAvgObj[regionalAvgMap[key]+'_per_capita'] = parseFloat(resp.us_regional_averages[key])/parseFloat(resp.regional_averages['Household Size'])
    }

    // map organization avg
    resp.organization_averages = resp.data.organization_averages
    orgAvg = { year: resp.organization_averages['year'] }

    resp.organization_averages.number_of_household_occupants
    for(key in resp.organization_averages){
        orgAvg[keysMap[key]] = parseFloat(parseFloat(resp.organization_averages[key]).toFixed(1))
    }

    historicalSeparatorCount = resp.data.historical.length-1

    resp.data.historical.push(orgAvg)
    resp.data.historical.push(newRegionalAvgObj)
    resp.data.historical.push(usAvgObj)

    $(document).trigger('dataLoaded')
  }
});

function fetch(key){
  if(window.perCapita){
    key = key + '_per_capita'
  }
  return resp.data.historical.map(function(row){
    return parseFloat(parseFloat(row[key]).toFixed(1))
  })
}

// function togglePerCapita(){
//   window.perCapita = !(window.perCapita)
//   $(document).trigger('dataLoaded')
// }

// histogram
$(document).on('dataLoaded', function(){
  var histogramGraphCategoryKey = perCapita ? graphCategory + ' per Capita' : graphCategory
  histogramData = resp.data.histograms[histogramGraphCategoryKey];

  you = parseFloat(resp.data.results.filter(function(row){
    return row.key == histogramGraphCategoryKey
  })[0].value)


  var seriesData = [];
  seriesData = histogramData.map(function(item){
    color = '#ddd'
    value = parseFloat(item.freq)
    range = item.range.split(',').map(function(row){
      return Math.round(parseFloat(row.replace(/[^0-9\.]/, '')))
    })

    if(you >= range[0] && you < range[1]){
      color = 'gold'
    }

    return {
      name: item.range.replace('[', '').replace(')', '').replace(',', ' and '),
      data: [{color: color, y: value}]
    }
  })

  $('#histogram-chart').highcharts({
    chart: { type: 'column' },
    title: { text: "Distribution", useHTML: true },
    tooltip: {
        formatter: function () {
          str = ""+this.y+" people have between " + this.series.name + " tons GHG (tC02e)"
          return str;
        }
    },
    plotOptions: {
          series: {
              dataLabels:{
                  enabled:false,
                  formatter:function(){
                      if(this.y > 0)
                          return this.y;
                  }
              }
          }
      },
      legend: { enabled: false },
      xAxis: {
        lineWidth: 0,
        minorGridLineWidth: 0,
        lineColor: 'transparent',
        labels: {
          enabled: false
        },
        minorTickLength: 0,
        tickLength: 0
      },
      credits: { enabled: false },
      yAxis: {
        title: {
          text: "Number of reports"
        }
      },

    series: seriesData
  });

})

// radar chart
$(document).on('dataLoaded', function(){

  function getAvg(key){
    if(window.perCapita){ key = key + ' per Capita' }

    return parseFloat(parseFloat(resp.data.population.filter(function(row){
      return row.key == key
    })[0].avg).toFixed(1))
  }
  function getCurrent(key){
    if(window.perCapita){
      key = key + ' per Capita'
    }
    value = parseFloat(parseFloat(resp.data.current_results[key]).toFixed(1))
    return value
  }

  // categories = ['Home Energy', 'Electricity', 'Heat', 'Food', 'Waste', 'Transportation', 'Commuting & Public Transportation', 'Personal Vehicles', 'Trips', 'Offsets']
  // categories = ['Electricity', 'Heat', 'Food', 'Waste', 'Commuting & Public Transportation','Personal Vehicles', 'Trips']
  categories = ['Food', 'Electricity', 'Heat', 'Waste', 'Commuting & Public Transportation', 'Personal Vehicles', 'Trips']
  dataSeries = [
    {
      name: 'Your Results',
      data: categories.map(function(category){
        return getCurrent(category)
      })
    },
    {
      name: 'Organization Averages',
      data: categories.map(function(category){
        return getAvg(category)
      })
    }
  ]

  $('#radar-chart').highcharts({
      chart: {
        polar: true,
        type: 'line'
      },

      title: {
        text: 'By Category',
        // x: -80
      },

      pane: {
          size: '80%'
      },

      xAxis: {
          categories: categories,
          tickmarkPlacement: 'on',
          lineWidth: 0
      },

      yAxis: {
          gridLineInterpolation: 'polygon',
          lineWidth: 0,
          min: 0
      },

      tooltip: {
          shared: true,
          pointFormat: '<span style="">{series.name}: <b>{point.y:,.1f}</b><br/>'
      },

      legend: {
          align: 'center',
          verticalAlign: 'bottom',
          y: 0,
          layout: 'vertical'
      },

      series: dataSeries
  });
})

// stacked bar chart
$(document).on('dataLoaded', function(){

  overallSeries = [
    {
      name: 'Home Energy',
      data: fetch('emissions_housing')
    },
    {
      name: 'Transportation',
      data: fetch('emissions_transportation')
    },
    {
      name: 'Food and Waste',
      data: fetch('emissions_food_total')
    },
    {
      name: 'Offsets',
      data: fetch('offset_tons')
    }
  ]

  foodSeries = [
    {
      name: 'Food',
      data: fetch('emissions_food_total')
    },
    {
      name: 'Waste',
      data: fetch('emissions_waste_total')
    }
  ]

  homeEnergySeries = [
    {
      name: 'Electricity',
      data: fetch('emissions_electricity_total')
    },
    {
      name: 'Other Fuels',
      data: fetch('emissions_heating_total')
    }
  ]

  transportationSeries = [
    {
      name: 'Commuting & Public Transportation',
      data: fetch('emissions_commute_total')
    },
    {
      name: 'Personal Vehicles',
      data: fetch('emissions_vehicles_sans_commuting')

    },
    {
      name: 'Trips',
      data: fetch('emissions_long_distance_travel')
    }
  ]

  dataSeries = {
    'Overall': overallSeries,
    'Home Energy': homeEnergySeries,
    'Food and Waste': foodSeries,
    'Transportation': transportationSeries
  }
  categories = resp.data.historical.map(function(row){
    return row.year
  })
  $('#stackedbar-chart').highcharts({
      chart: {
        type: 'column'
      },
      title: {
          text: 'Your ' + graphCategory + ' Emissions',
          useHTML: true
      },
      xAxis: {
          categories: categories,
            plotBands: [{}],
  plotLines: [
    {label:{text: "Your Historical Results", x: -15, y: 50, style: {color: "#CCC"} },  color: '#ccc', dashStyle: 'longdashdot', value: historicalSeparatorCount-0.4, width: 2 },
    {label:{text: "Other Averages",style:{color:"#CCC"},x:10,y:50}, color: '#ccc', dashStyle: 'longdashdot',  value: historicalSeparatorCount+0.4, width: 2 }]
      },
      yAxis: {
          min: 0,
          title: {
              text: ''
          },
          stackLabels: {
              enabled: true,
              style: {
                  fontWeight: 'bold',
                  color: (Highcharts.theme && Highcharts.theme.textColor) || 'gray'
              }
          }
      },
      legend: {
          align: 'right',
          x: -30,
          verticalAlign: 'top',
          y: 25,
          floating: true,
          backgroundColor: (Highcharts.theme && Highcharts.theme.background2) || 'white',
          borderColor: '#CCC',
          borderWidth: 1,
          shadow: false
      },
      tooltip: {
          formatter: function () {
              return '<b>' + this.x + '</b><br/>' +
                  this.series.name + ': ' + this.y + '<br/>' +
                  'Total: ' + this.point.stackTotal;
          }
      },
      plotOptions: {
          column: {
            minPointLength: 3,
              stacking: 'normal',
              dataLabels: {
                  enabled: true,
                  color: (Highcharts.theme && Highcharts.theme.dataLabelsColor) || 'white',
                  style: {
                      textShadow: '0 0 3px black'
                  }
              }
          }
      },
      series: dataSeries[graphCategory],
      credits: {
        enabled: false
    }
  })
})

angular.module('app', [])

.filter('ordinal', function() {
  return function(input) {
    var s=["th","st","nd","rd"],
    v=input%100;
    return input+(s[(v-20)%10]||s[v]||s[0]);
  }
})

.filter('orderObjectBy', function() {
  return function(items, field, reverse) {
    var filtered = [];
    angular.forEach(items, function(item) {
      filtered.push(item);
    });
    filtered.sort(function (a, b) {
      return (a[field] > b[field] ? 1 : -1);
    });
    if(reverse) filtered.reverse();
    return filtered;
  };
})

.controller('MyMainController', function($scope, $http){
  var listVariables = ['Food', 'Electricity', 'Heat', 'Waste', 'Personal Vehicles', 'Trips']
  var variables = [
    'Food', 'Electricity', 'Heat', 'Waste',
    'Personal Vehicles', 'Trips', 'Overall',
    'Overall per Capita',
    'Food and Waste per Capita',
    'Home Energy per Capita',
    'Transportation', 'Transportation per Capita',
    'Food and Waste',
    'Food and Waste per Capita',
    'Home Energy', 'Home Energy per Capita',
  ]

  $http.get(location.pathname + '/results.json?histograms='+variables.join(',')).success(function(resp){
    $scope.data = resp.data
    $scope.survey = resp.data.survey

    $scope.myPercentiles = {}
    variables.forEach(function(key){
      // select user's percentile
      me = Math.round(parseFloat(resp.data.current_results[key]))
      mep = resp.data.percentiles[key].filter(function(row){
        return me == Math.round(parseFloat(row.max_value))
      })[0]

      // console.log(me, mep)
      if(!mep){
        mep = { cume: 0, max_value: 0}
      }

      // select user's per capita percentile
      me_pc = Math.round(parseFloat(resp.data.current_results[key + ' per Capita']))
      mep_pc = resp.data.percentiles[key + ' per Capita'].filter(function(row){
        return me_pc == Math.round(parseFloat(row.max_value))
      })[0]

      if(!mep_pc){
        mep_pc = { cume: 0, max_value: 0}
      }

      mep['percentile'] = 100 - mep.cume
      mep['me'] = parseFloat(resp.data.current_results[key]).toFixed(1)

      mep['me_per_capita'] = parseFloat(resp.data.current_results[key+ ' per Capita']).toFixed(1)
      try { mep['percentile_per_capita'] = 100 - mep_pc.cume } catch(e) { }

      mep['title'] = key
      $scope.myPercentiles[key] = mep

      $scope.myPercentile = perCapita ? mep.cume : me.cume
    })

    // setup variables for
    drawVariables = function(){
      key = perCapita ? graphCategory + ' per Capita' : graphCategory

      $scope.survey = resp.data.survey
      $scope.graphCategory = graphCategory
      $scope.graphCategoryScore = parseFloat(resp.data.current_results[key]).toFixed(1)
      $scope.perCapita = perCapita ? ' per Capita' : ''
      $scope.organizationAVG = (parseFloat(resp.data.population.filter(function(row){
        return row.key === graphCategory
      })[0].avg)).toFixed(2)


      $scope.myPercentile = 100 - $scope.myPercentiles[key].cume

      $scope.percentilesList = []
      for(obj in $scope.myPercentiles){
        if(listVariables.indexOf(obj)>=0){
          $scope.percentilesList.push($scope.myPercentiles[obj])
        }
      }

      $scope.readyToRender=true
    }

    $scope.graphVariables=function(category, _this){
      window.graphCategory = category
      $scope.graphCategory = category
      $('a.active').removeClass('active')
      $(_this).addClass('active')
      $(document).trigger('dataLoaded')

      drawVariables()
    }

    drawVariables()
  })

  $scope.togglePerCapita = function(){
    window.perCapita = !(window.perCapita)
    $(document).trigger('dataLoaded')
    drawVariables()
  }

})
