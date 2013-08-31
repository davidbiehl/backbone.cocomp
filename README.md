# Event Based Backbone Collection Comparison

Use events to compare the contents of two or more Backbone Collections.
A sample use case: You have a collection you are adding things to, we'll 
call it a box, and a collection for searching for things to add to the box.
Somehow, you want to indicate in the search results what is already in the
box. 

    # Setting up the CoComp object

    boxes = new Backbone.Collection
    searchResults = new Backbone.Collection
    
    cocomp = new Backbone.CoComp
      comparator: (obj)->
        obj.box.get('id') == obj.search.get('id')
        # this can really be anything you want

    cocomp.set "box", boxes
    cocomp.set "search", searchResults

    # The search result view

    SearchResultView = Backbone.View.extend
      initialize: ->
        # @model is a single search result in the searchResults collection

        @listenTo @model, 'cocomp:in:box', @onInBox
        @listenTo @model, 'cocomp:out:box', @onOutBox

      onInBox: ->
        @$el.addClass('faded')  

        # however you want to indicate that the search result is already 
        # in the box

      onOutBox: ->
        @$el.removeClass('faded')

        # the search result isn't in the box, return to normal

More than two collectiones can be `set` on the CoComp instance, just make 
sure the `comparator` knows how to compare them to each other. 

The CoComp object will listen for `reset`, `add`, and `remove` events on each
collection and trigger the appropriate events in the other collections set on
the instance.

If you need to trigger a comparison manually, simply call `compare()` on the
instance to perform the comparison and trigger the events on each collection.

When you `set` a collection, the `compare()` method will be executed
automatically, unless you specify `compare: false` as an option when
calling the `set` method.

## The Comparator

Each CoComp instance needs a `comparator`. This function should have one 
argument, a simple JavaScript Object, with two properties: the names of 
the collections that are currently being compared. Each property will have
a model from the collection that is being compared. 

It's difficult to explain, but simple to demonstrate. Using the example 
above, we `set` a collection named "box" and another collection named 
"search". Our `comparator` argument will be an object with a "box" property 
and a "search" property which have a model from each collection that should 
be compared. 

The `comparator` function should simply return a boolean value that indicates
if the two models are equal.

By using an object with properties, it allows you to get creative. Adding
another box to compare to search results our example is trivial.

    cocomp = new Backbone.CoComp
      comparator: (obj)->
        return false unless obj.search  # we don't want to compare box to another_box, so 
                                          we make sure there is a search model

        box = obj.box || obj.another_box  # we want to see if the result is in any box
        box.get('id') == obj.search.get('id')

    cocomp.set "box", boxes
    cocomp.set "another_box", moreBoxes
    cocomp.set "search", searchResults
    
    
