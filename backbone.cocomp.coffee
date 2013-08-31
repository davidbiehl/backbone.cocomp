# An event based collection comparison utility
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
    @comparator = opts.comparator || throw "The CoComp requires a comparator"

  # Public: Set a collection that will be compared to the other collections
  #
  # Adds the collection to the collection that will be compared.
  # If a collection with the same name exists, it will be replaced with
  # the new collection
  #
  # name - the name of the collection for CoComp purposes
  # collection - the backbone collection
  # options
  #   compare - a boolean value indicating whether or not a comparison should
  #             be executed immediately. Defaults to true
  set: (name, collection, options = {})->
    options.compare = true unless _.has(options, "compare")

    @stopListening @_collections[name] if @_collections[name]
    @_collections[name] = collection

    @listenTo @_collections[name], 'reset', @compare
    @listenTo @_collections[name], 'add', @_onAdd
    @listenTo @_collections[name], 'remove', @_onRemove

    @compare() if options.compare

  # Public: Compare all of the models in all of the collections
  #
  # This will trigger either `cocomp-in` or `cocomp-out` events
  # for each model in each collection
  compare: ->
    for aName, a of @_collections
      for bName, b of @_collections
        if aName != bName
          a.forEach (aModel)=>
            @_compareToCollection(aModel, b, modelCollectionName: aName, collectionName: bName)

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
  #   modelCollectionName - the name of the collection the model belongs to
  #   collectionName      - the name of the that should be fired with the event
  #                         if not provided, the collection name will be looked
  #                         up from aModel
  #   reverse             - reverse the events. cocomp-out would be fired if the 
  #                         comparator results in true. This is probably only needed
  #                         when removing something from a list
  _compareToCollection: (aModel, b, options = {})->
    aName = options.modelCollectionName || @_collectionName(aModel.collection)
    bName = options.collectionName || @_collectionName(b)
    
    if aName != bName
      if options.reverse
        inEvent = "cocomp:out"
      else
        inEvent = "cocomp:in"

      inCollection = false
      b.forEach (bModel)=>
        exists = @_compareOne(aModel, bModel, inEvent, aName: aName, bName: bName)
        inCollection = inCollection || exists

      unless inCollection
        aModel.trigger "cocomp:out:#{bName}"
        aModel.trigger "cocomp:out"


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
  #   aName - the name of the collection for the `a` model
  #   bName - the name of the collection for the `b` model
  #
  _compareOne: (a, b, event, options = {})=>
    aName = options.aName || @_collectionName(a.collection)
    bName = options.bName || @_collectionName(b.collection)
    
    obj = {}
    obj[aName] = a
    obj[bName] = b

    if @comparator.call(@comparator, obj)
      b.trigger "#{event}:#{aName}", a
      b.trigger "#{event}", a
      true
    else
      false

  # Private: Returns the name of a collection
  #
  # collection - the collection you need the name for
  _collectionName: (collection)->
    for cName, c of @_collections
      return cName if c == collection

  # Private: An event handler when a model is added to a list
  _onAdd: (aModel)->
    for bName, b of @_collections
      @_compareToCollection(aModel, b, collectionName: bName)

  # Private: An event handler when a model is removed from a list
  _onRemove: (aModel)->
    for bName, b of @_collections
      @_compareToCollection(aModel, b, collectionName: bName, reverse: true)
