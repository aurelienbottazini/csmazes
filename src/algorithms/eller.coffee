###
Author: Jamis Buck <jamis@jamisbuck.org>
License: Public domain, baby. Knock yourself out.

The original CoffeeScript sources are always available on GitHub:
http://github.com/jamis/csmazes
###

class Maze.Algorithms.Eller extends Maze.Algorithm
  IN:         0x20

  HORIZONTAL: 0
  VERTICAL:   1

  constructor: (maze, options) ->
    super

    @state = new Maze.Algorithms.Eller.State(@maze.width).populate()
    @row = 0
    @pending = true

    @initializeRow()

  initializeRow: ->
    @column = 0
    @mode = @HORIZONTAL

  isFinal: -> @row+1 == @maze.height

  isIn: (x, y) -> @maze.isValid(x, y) && @maze.isSet(x, y, @IN)

  horizontalStep: ->
    changed = false

    until changed || @column+1 >= @maze.width
      changed = true

      if !@state.isSame(@column, @column+1) && (@isFinal() || @rand.nextBoolean())
        @state.merge @column, @column+1

        @maze.carve @column, @row, Maze.Direction.E
        @callback @maze, @column, @row

        @maze.carve @column+1, @row, Maze.Direction.W
        @callback @maze, @column+1, @row
      else if @maze.isBlank(@column, @row)
        @maze.carve @column, @row, @IN
        @callback @maze, @column, @row
      else
        changed = false

      @column += 1

    if @column+1 >= @maze.width
      if @maze.isBlank(@column, @row)
        @maze.carve @column, @row, @IN
        @callback @maze, @column, @row

      if @isFinal()
        @pending = false
      else
        @mode = @VERTICAL
        @next_state = @state.next()
        @verticals = @computeVerticals()

  computeVerticals: ->
    verts = []

    @state.foreach (id, set) =>
      countFromThisSet = 1 + @rand.nextInteger(set.length-1)
      cellsToConnect = @rand.randomizeList(set).slice(0, countFromThisSet)
      verts = verts.concat(cellsToConnect)

    verts.sort (a, b) -> a - b

  verticalStep: ->
    cell = @verticals.pop()

    @next_state.add cell, @state.setFor(cell)

    @maze.carve cell, @row, Maze.Direction.S
    @callback @maze, cell, @row

    @maze.carve cell, @row+1, Maze.Direction.N
    @callback @maze, cell, @row+1

    if @verticals.length == 0
      @state = @next_state.populate()
      @row += 1
      @initializeRow()

  step: ->
    switch @mode
      when @HORIZONTAL then @horizontalStep()
      when @VERTICAL   then @verticalStep()

    @pending

class Maze.Algorithms.Eller.State
  constructor: (@width, @counter) ->
    @counter ?= 0
    @sets = {}
    @cells = []

  next: ->
    new Maze.Algorithms.Eller.State(@width, @counter)

  populate: ->
    cell = 0
    while cell < @width
      unless @cells[cell]
        set = (@counter += 1)
        (@sets[set] ?= []).push(cell)
        @cells[cell] = set
      cell += 1
    this

  merge: (sink, target) ->
    sink_set = @cells[sink]
    target_set = @cells[target]

    @sets[sink_set] = @sets[sink_set].concat(@sets[target_set])
    for cell in @sets[target_set]
      @cells[cell] = sink_set
    delete @sets[target_set]

  isSame: (a, b) ->
    @cells[a] == @cells[b]

  add: (cell, set) ->
    @cells[cell] = set
    (@sets[set] ?= []).push(cell)
    this

  setFor: (cell) -> @cells[cell]

  foreach: (fn) ->
    for id, set of @sets
      fn id, set
