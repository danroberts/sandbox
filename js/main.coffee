class @Value
  constructor: (attributes) ->
    attrs = attributes or {}
    _.extend this, attributes

  attachReduce: (group) ->
    @reduceWithContext(group, this)

  reduceWithContext: (group, context) ->
    group.reduce _.bind(@add, context), _.bind(@remove, context), _.bind(@initial, context)

class @BasicMathValue extends Value
  name: 'absGain'
  initialTarget: 'open'
  target: 'close'
  add: (p, v) ->
    p[@name] += @doMath(p, v)
    return p

  remove: (p, v) ->
    p[@name] -= @doMath(p, v)
    return p

  initial: ->
    obj = {}
    obj[@name] = 0
    return obj

  mathFunction: (initial, target) ->
    return initial + target

  doMath: (p, v) ->
    initial = v[@initialTarget] || p[@initialTarget]
    target = v[@target] || p[@target]

    @mathFunction(initial, target)

class @AdditionValue extends BasicMathValue

class @SubtractionValue extends BasicMathValue
  mathFunction: (initial, target) ->
    return initial - target

class @AbsoluteMathValue extends BasicMathValue
  add: (p, v) ->
    p[@name] = @doMath(p, v)
    return p

  remove: (p, v) ->
    p[@name] = @doMath(p, v)
    return p

class @AverageValue extends AbsoluteMathValue
  mathFunction: (initial, target) ->
    (initial / target)

class @PercentageValue extends AverageValue
  mathFunction: (initial, target) ->
    super * 100

class @CountValue extends Value
  add: (p, v) ->
    p.count++

  remove: (p, v) ->
    p.count--

  initial: ->
    {count: 0}

class @GroupReducer
  values: [new CountValue, new SubtractionValue]
  constructor: (attributes) ->
    attrs = attributes or {}
    _.extend this, attributes

  reduce: (group) ->
    add = (p,v) =>
      _.each @values, (value) ->
        value.add(p,v)

      return p

    remove = (p,v) ->
    initial = =>
      obj = {}
      _.each @values, (value) ->
        obj = _.extend(obj, value.initial())
      return obj

    group.reduce(_.bind(add, this), _.bind(remove, this), _.bind(initial, this))

    return

class @Bucket
  constructor: (attributes) ->
    attrs = attributes or {}
    _.extend this, attributes

  target: 'close'
  create: (crossfilter) ->
    crossfilter.dimension (d) =>
      @comparator(d)

  comparator: (d) ->
    return d[@target]

class @StringBucket extends Bucket

class @IfElseBucket extends Bucket
  if_statement: (d) ->
    d.open > d.close
  true_value: 'Gain'
  false_value: 'Loss'

  comparator: (d) ->
    return if @if_statement(d) then @true_value else @false_value

class @PercentageChangeBucket extends Bucket
  target: 'close'
  percentage: 'open'

  comparator: (d) ->
    target = d[@target]
    percentage = d[@percentage]
    return Math.round((target - percentage) / percentage * 100)

class @TimeBucket extends Bucket
  target: 'Date'

class @YearBucket extends TimeBucket
  comparator: (d) ->
    return d[@target].year()

class @MonthBucket extends TimeBucket
  comparator: (d) ->
    return d[@target].month()

class @DayOfTheWeekBucket extends TimeBucket
  day_name = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
  comparator: (d) ->
    day = d[@target].day()
    return day_name[day]

class @QuarterBucket extends TimeBucket
  comparator: (d) ->
    month = d[@target].month()

    if(month <=2)
      return 'Q1'
    else if(month > 3 && month <= 5)
      return 'Q2'
    else if(month >5 && month <=8)
      return 'Q3'
    else
      return 'Q4'
