describe 'A Group', ->
  ndx = null
  assertKeys = (result, expected) ->
    keys = _.pluck(result, 'key')
    expect(keys).toEqual(expected)

  beforeEach ->
    json = [
      {Date: moment("06/18/2012"), open: 2570.98, close: 2593.52, change: 21.52, volume: 15407330},
      {Date: moment("06/19/2012"), open: 2606.43, close: 2620.83, change: 14.40, volume: 17714840}
      {Date: moment("06/20/2012"), open: 2640.43, close: 2620.83, change: 14.40, volume: 17714840},
      {Date: moment("06/20/2013"), open: 2640.43, close: 2620.83, change: 14.40, volume: 17714840}
    ]
    ndx = crossfilter(json)

  it 'can create a date bucket', ->
    bucket = new TimeBucket
    dimension = bucket.create(ndx)
    result = dimension.group().all()

    expected = [
      moment("06/18/2012")
      moment('06/19/2012')
      moment('06/20/2012')
      moment('06/20/2013')
    ]

    assertKeys(result, expected)

  it 'can create a year bucket', ->
    bucket = new YearBucket
    result = bucket.create(ndx).group().all()
    expected = [
      2012
      2013
    ]

    assertKeys(result, expected)

  it 'can return a day of the week bucket', ->
    bucket = new DayOfTheWeekBucket
    result = bucket.create(ndx).group().all()
    assertKeys(result, ['Mon', 'Thu', 'Tue', 'Wed'])

  it 'returns fluctuation', ->
    bucket = new PercentageChangeBucket
    result = bucket.create(ndx).group().all()
    assertKeys(result, [-1, 1])

  it 'can calculate an if/else bucket', ->
    bucket = new IfElseBucket
    result = bucket.create(ndx).group().all()
    assertKeys(result, ["Gain", "Loss"])

  it 'can calculate a value', ->
    bucket = new YearBucket
    group = bucket.create(ndx).group()
    value = new SubtractionValue
    value.attachReduce(group)
    expect(group.all()[1].value.absGain).toBe(19.59999999999991)


  describe 'A Value', ->
    it 'can accept attributes', ->
      value = new Value(target: 'target')
      expect(value.target).toBe('target')

  it 'can calculate more than one value', ->
    bucket = new YearBucket
    group = bucket.create(ndx).group()
    reducer = new GroupReducer
    reducer.reduce(group)
    point = group.all()[1]
    values = _.keys(point.value)
    expect(values).toEqual(["count", "absGain"])

  it 'can use a previous value in a new value calulation', ->
    bucket = new YearBucket
    values = [new CountValue, new SubtractionValue, new AverageValue(name: 'test', initialTarget: 'absGain', target: 'count')]
    group = bucket.create(ndx).group()
    reducer = new GroupReducer(values: values)

    reducer.reduce(group)
    point = group.all()[0]
    console.log(point)
    expect(point.value.test).toBe(-5.780000000000048)


