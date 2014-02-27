console.log("hello")

var ndx, all;
var yearlyBubbleChart = dc.bubbleChart("#chart");

d3.csv("data/ndx.csv", function (data) {
    /* since its a csv file we need to format the data a bit */
    var dateFormat = d3.time.format("%m/%d/%Y");
    var numberFormat = d3.format(".2f");

    data.forEach(function (d) {
        d.date = moment(d.date)
        d.close = +d.close; // coerce to number
        d.open = +d.open;
    });

    //### Create Crossfilter Dimensions and Groups
    //See the [crossfilter API](https://github.com/square/crossfilter/wiki/API-Reference) for reference.
    var ndx = crossfilter(data);

    var years = new YearBucket({target: 'date'});
    var dimension = years.create(ndx);
    var group = dimension.group()
    count = new CountValue();
    absGain = new SubtractionValue()
    fluctuation = new SubtractionValue({name: 'fluctuation', initialTarget: 'close', target: 'open'})
    avgIndex = new AverageValue({name: 'avgIndex', target: 'count', initialTarget: 'absGain'})
    percentageGain = new PercentageValue({name: 'percentageGain', initialTarget: 'absGain', target: 'avgIndex'})
    values = [count, absGain, fluctuation, avgIndex, percentageGain]
    var reducer = new GroupReducer({values: values})
    reducer.reduce(group)
    console.log('ndx', ndx)
    console.log(group.all())
    yearlyBubbleChart
        .width(990) // (optional) define chart width, :default = 200
        .height(250)  // (optional) define chart height, :default = 200
        .transitionDuration(1500) // (optional) define chart transition duration, :default = 750
        .margins({top: 10, right: 50, bottom: 30, left: 40})
        .dimension(dimension)
        //Bubble chart expect the groups are reduced to multiple values which would then be used
        //to generate x, y, and radius for each key (bubble) in the group
        .group(group)
        //##### Accessors
        //Accessor functions are applied to each value returned by the grouping
        //
        //* `.colorAccessor` The returned value will be mapped to an internal scale to determine a fill color
        //* `.keyAccessor` Identifies the `X` value that will be applied against the `.x()` to identify pixel location
        //* `.valueAccessor` Identifies the `Y` value that will be applied agains the `.y()` to identify pixel location
        //* `.radiusValueAccessor` Identifies the value that will be applied agains the `.r()` determine radius size, by default this maps linearly to [0,100]
        .colorAccessor(function (d) {
            return d.value.absGain;
        })
        .keyAccessor(function (p) {
            return p.value.absGain;
        })
        .valueAccessor(function (p) {
            return p.value.percentageGain;
        })
        .radiusValueAccessor(function (p) {
            return p.value.fluctuation;
        })
        .maxBubbleRelativeSize(0.3)
        .x(d3.scale.linear().domain([-2500, 2500]))
        .y(d3.scale.linear().domain([-100, 100]))
        .r(d3.scale.linear().domain([0, 4000]))
        //##### Elastic Scaling
        //`.elasticX` and `.elasticX` determine whether the chart should rescale each axis to fit data.
        //The `.yAxisPadding` and `.xAxisPadding` add padding to data above and below their max values in the same unit domains as the Accessors.
        .elasticY(true)
        .elasticX(true)
        .yAxisPadding(100)
        .xAxisPadding(500)
        .renderHorizontalGridLines(true) // (optional) render horizontal grid lines, :default=false
        .renderVerticalGridLines(true) // (optional) render vertical grid lines, :default=false
        .xAxisLabel('Index Gain') // (optional) render an axis label below the x axis
        .yAxisLabel('Index Gain %') // (optional) render a vertical axis lable left of the y axis
        //#### Labels and  Titles
        //Labels are displaed on the chart for each bubble. Titles displayed on mouseover.
        .renderLabel(true) // (optional) whether chart should render labels, :default = true
        .label(function (p) {
            return p.key;
        })
        .renderTitle(true) // (optional) whether chart should render titles, :default = false
        .title(function (p) {
            return [p.key,
                   "Index Gain: " + numberFormat(p.value.absGain),
                   "Index Gain in Percentage: " + numberFormat(p.value.percentageGain) + "%",
                   "Fluctuation / Index Ratio: " + numberFormat(p.value.fluctuationPercentage) + "%"]
                   .join("\n");
        })
        //#### Customize Axis
        //Set a custom tick format. Note `.yAxis()` returns an axis object, so any additional method chaining applies to the axis, not the chart.
        .yAxis().tickFormat(function (v) {
            return v + "%";
        })

        yearlyBubbleChart.render();


});