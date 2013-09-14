###! 
Backbone.CoComp v0.0.7
(c) 2013 David Biehl
Backbone.CoComp may be freely distributed under the MIT license.
For all details and documentation:
https://github.com/davidbiehl/backbone.cocomp
###

# An event based collection comparison utility
#
#
# The need to synchronize two different backbone collections
# came about when we had search results, and a category a user
# could add any of the results to. The requirement was to indicate
# which of the search results already appeared in the category.
# The two collections needed to know about each other, but each
# collection was part of a separate backbone view. An event based
# comparison object seemed like the most reasonable way to let the 
# two collections communicate their state between each view.
#
# There are (essentially) two events that are fired:
#
# cocomp:in              - triggered on a model when it exists in another list
# cocomp:in:<list_name>  - with the list name
#
# cocomp:out             - triggered on a foreign model when it is removed
# cocomp:out:<list_name>   or doesn't exist in another list.
#
# Constructor Arguments
#
# comparator - a method that will be executed to compare the models to each other.
#              It should receive a single argument, which will be an simple object.  
#              The object will have two properties, which are the names of the
#              collections being compared. The value of each property will be the
#              model that should be compared.
#
# Here is an example of a comparator, and how it relates to the collection names
# We want to compare the `id` of the models in the `resultsCollection` to the
# `item_id` of the models in the `categoryItems` collection
#
#     comp = new CoComp
#       comparator: (obj)->
#         obj.results.get('id') == obj.category_items.get('item_id')
#
#     comp.set("results", resultsCollection)
#     comp.set("category_items", categoryItems)
class Backbone.CoComp
  _.extend @prototype, Backbone.Events

  constructor: (opts = {})->
    @_collections = {}

    if _.isFunction(opts.comparator)
      @comparator = opts.comparator
    else
      if opts.comparator == "==="
        @comparator = (obj)->
          obj[0] == obj[1]
      else
        attr = opts.comparator || "id"
        @comparator = (obj)->
          obj[0].get(attr) == obj[1].get(attr)

  # Public: Set a collection that will be compared to the other collections
  #
  # Adds the collection to the collection that will be compared.
  # If a collection with the same name exists, it will be replaced with
  # the new collection
  #
  # name - the name of the collection for CoComp purposes
  # collection - the backbone collection
  # options
  #   silent - a boolean value indicating whether or not a comparison should
  #             be executed immediately. Defaults to false
  set: (name, collection, options = {})->
    if name == 0 || name == 1
      throw "#{name} is a reserved collection name, please use a different name"

    old = @get(name)
    @stopListening old if old

    @_collections[name] = collection

    @listenTo collection, 'add remove', @_onChange
    @listenTo collection, 'reset', ->
      @compare(name)

    @compare(name) unless options.silent

  # Public: Get a collection by name
  # 
  # name - the name of the collection you want to get
  get: (name)->
    @_collections[name]

  # Public: Remove a collection from the comparisons
  # 
  # name - the name of the collection to remove
  unset: (name, options = {})->
    return unless @get(name)

    @compare name, reverse: true unless options.silent

    delete @_collections[name]

  # Public: Compare all of the models in all of the collections
  #
  # names... - the names of the collctions that should be compared
  # options - 
  #   reverse - trigger the `out` event on a match
  #
  # This will trigger either `cocomp-in` or `cocomp-out` events
  # for each model in each collection
  compare: (names..., options = {})->
    unless _.isObject(options)
      names.push(options) 
      options = {}

    compared = []

    comparable = (aName, bName)->
      # can't be the same collection
      aName != bName &&  
      # no names passed, or one of the collections needs to be in the names passed
      (names.length == 0 || _.contains(names, aName) || _.contains(names, bName)) &&  
      # can't have already been compared
      !(_.findWhere(compared, aName: bName, bName: aName))  

    for aName, a of @_collections
      for bName, b of @_collections
        if comparable(aName, bName)
          compared.push aName: aName, bName: bName
          @_compareCollections(a, b, aName: aName, bName: bName, reverse: options.reverse) 

  # Private: Compare the models in two collections
  # 
  # a - the first collection to compare
  # b - the collection that should be compared to a
  # options
  #   aName - the name of the a collection
  #   bName - the name of the b collection
  #   reverse - trigger the `out` event on a match
  #   invert - compare the models in both collections to each-other. 
  #            Set to false to do a one-way comparison. Used to stop
  #            recursion
  _compareCollections: (a, b, options = {})->
    aName = options.aName || @_collectionName(a)
    bName = options.bName || @_collectionName(b)
    options.invert = true unless _.has(options, 'invert')
    event = "in"
    event = "out" if options.reverse

    if aName != bName
      a.forEach (aModel)=>
        @_compareModelToCollection aModel, b,
          modelCollectionName: aName
          collectionName: bName
          event: event

      if options.invert
        @_compareCollections b, a,
          aName: bName,
          bName: aName,
          invert: false

  # Private: Compare a single model to all of the models in another collection
  #
  # This will only run the comparison if the aModel's collection is not the 
  # collection being compared to
  #
  # A `cocomp-out` event will be triggere on the aModel if it is not found
  # in the b collection
  #
  # aModel - the model that should be compared
  # b      - the collection to compare aModel against
  # options
  #   modelCollectionName - Required. The name of the collection the model belongs to
  #   collectionName      - the name of the that should be fired with the event
  #                         if not provided, the collection name will be looked
  #                         up from aModel
  #   event               - the event that should be triggered on a match.
  #                         Defaults to "in"
  #   invert              - call the events on both models. Defaults to false.
  #                         Only set this to true if the collections aren't already
  #                         being compared in both directions
  _compareModelToCollection: (aModel, b, options = {})->
    aName = options.modelCollectionName || throw "modelCollectionName is required" 
    bName = options.collectionName || @_collectionName(b)
    event = options.event || "in"
    
    if aName != bName
      inCollection = false
      b.forEach (bModel)=>
        aExists = @_compareOne(aModel, bModel, event, aName: aName, bName: bName)
        bExists = @_compareOne(bModel, aModel, event, aName: bName, bName: aName) if options.invert

        inCollection = inCollection || aExists || bExists

      if !inCollection && event != "out"
        @_trigger aModel, "out", bName

  _trigger: (model, event, name)->
    throw "Invalid event: #{event}" unless _.contains(["in", "out"], event)
    model.trigger "cocomp:#{event}:#{name}"
    model.trigger "cocomp:#{event}"


  # Private: Compare two models and trigger the event specified if
  #          the comparison is true 
  #
  # a     - the first model for comparison
  # b     - the second model for comparison. The events will be triggered
  #         on this model
  # event - the event that should be triggered on the b model.
  #         The event will be triggered as the stand along event
  #         name, and also with `event:aName` so the receiving
  #         model knows the name of the collection it is being
  #         compared to
  # options
  #   aName - Required. The name of the collection for the `a` model
  #   bName - Required. The name of the collection for the `b` model
  #
  _compareOne: (a, b, event, options = {})->
    aName = options.aName || throw "aName is required"
    bName = options.bName || throw "bName is required"
    
    obj = {}
    obj[aName] = obj[0] = a
    obj[bName] = obj[1] = b

    if @comparator.call(@comparator, obj)
      @_trigger b, event, aName
      true
    else
      false

  # Private: Returns the name of a collection
  #
  # collection - the collection you need the name for
  _collectionName: (collection)->
    for cName, c of @_collections
      return cName if c == collection

  # Private: An event handler for `add` and `remove` events.
  # 
  # Triggers the `in` or `out` events depending on whether or not
  # the model is being added or removed from the collection
  #
  # model - the model being added/removed
  # collection - the collection that received the event
  # e - information about the event
  _onChange: (model, collection, e)->
    event = "in"
    event = "out" unless e.add

    aName = @_collectionName(collection)
    @_trigger model, event, aName

    for bName, b of @_collections
      @_compareModelToCollection model, b, 
        modelCollectionName: aName, 
        collectionName: bName, 
        invert: true, 
        event: event
