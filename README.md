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

The CoComp object will listen for `reset`, `add`, and `remove` events on eachi
collection and trigger the appropriate events in the other collections set on
the instance.

If you need to trigger a comparison manually, simply call `compare()` on the
instance to perform the comparison and trigger the events on each collection.
