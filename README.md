# Event Based Backbone Collection Comparison

Use events to compare the contents of two or more Backbone Collections.

## Installation

Simply include the 
[backbone.cocomp.js](https://raw.github.com/davidbiehl/backbone.cocomp/master/backbone.cocomp.js) 
file in your asset pipeline, `<script>` tag, or wherever your JavaScript assets are served.

### The State of Things

This library is pretty stable as of version 0.0.7. 
CoComp is being developed using Test Driven Development practices to ensure
that new bugs aren't introduced as the project progresses. 


### Requirements

CoComp requires Backbone.js v0.9.9 or higher. 
The passing test suite runs against Backbone v1.0.0.

## Usage

*See Backbon.CoComp in action on [jsfiddle](http://jsfiddle.net/davidbiehl/WQ9uc/)*

A sample use case: You have a collection you are adding things to, we'll 
call it a box, and a collection for searching for things to add to the box.
Somehow, you want to indicate in the search results what is already in the
box. 


### Step by Step

#### Setup

The first thing to do is to create an instance of `Backbone.CoComp`. By
default it will compare the models in each collection with the `id` attribute.

    cocomp = new Backbone.CoComp()

Next the collections that will be compared need to be `set` on our
CoComp instance. Each collection is set with a name. This will
become important when setting up event listeners on the models.

    cocomp.set("box", boxes)
    cocomp.set("search", searchResults)

As soon as the collections are `set`, the CoComp events will immediately
be triggered on the models in each collection. (More on the events in a
minute) If you don't want the events to trigger automatically, pass 
a `silent: true` option when calling `set`. This would only apply 
when setting the collection, and future `add`, `remove` and `reset`
events on the collection would not be silent. 

    cocomp.set("box", boxes, {silent: true})

#### Events

The events are named like so: `cocomp:in:<collection_name>` 
and `cocomp:out:<collection_name>`. 
CoComp will respond to `add`, `remove` and `reset` events on each collection.
The events will also be triggered when `set`ting a new collection on a 
CoComp instance (unless you use the `silent: true` option.

Let's walk through this. If a model is added to the `searchResults` collection, 
the model will receive two events.

    model = new Backbone.Model({id: 1})
    searchResults.add(model)
    
    # cocomp:in:search
    # cocomp:out:box

These events can by understood semantically by saying 
"the model is in the search collection"
and "the model is out of the box collection".
Notice that the collection name when calling `set` is used in the event.

Now the same model is added to the collection named `box`. This will trigger 
a `cocomp:in` event on the `box` collection (`cocomp:in:box`).

   boxes.add(model)  # cocomp:in:box

Now that our box has a model, let's `reset` the `searchResults` simulating
receiving data from the server.

    searchResults.reset({id: 1, id: 2, id: 3})  # this could be a `fetch(reset: true)`

    # Triggered on our model in the box collection (remember, it does have an id of 1)
    #
    # cocomp:in:search

    # Triggered on each model in search results 
    #
    # id: 1  =>  cocomp:in:box
    # id: 2  =>  cocomp:out:box
    # id: 3  =>  cocomp:out:box

If we remove the model from the `boxes` collection, it would receive a `cocomp:out` event
from the `box` collection (`cocomp:out:box`). The corresponding model in the `searchResults`
collection would also receive this event.

    boxes.remove(model)  # cocomp:out:box

If, at any time, we want CoComp to compare the collection manually, simply call the `compare`
method on the CoComp instance.

    cocomp.compare()

#### Setting up Event Listeners in a View

Now we just need to setup an event listener in our view to respond to the events. 
We're going to do this in a `SearchResult` view. Basically, if the search result
is already in the `box` collection, we want it to appear faded.

    # In our SearchResult view

    initialize: function() {
      this.listenTo(this.model, 'cocomp:in:box', this.onInBox)
      this.listenTo(this.model, 'cocomp:out:box', this.onOutBox)
    }
    
    onInBox: function() {
      this.$el.addClass('faded')  # or hide it, or whatever
    }

    onOutBox: function() {
      this.$el.removeClass('faded')  # or show it
    }

### All Together Now!

Here is the final result, in one piece of CoffeeScript.

    # Setting up some Collections 

    boxes = new Backbone.Collection()
    searchResults = new Backbone.Collection()
    

    # Setting up the Backbone.CoComp Instance

    cocomp = new Backbone.CoComp()

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

## Advanced

CoComp can be handily customized to suit your needs. There are several
advanced behaviors that can help you get the most out of CoComp.

### The Comparator

By default, the models in each collection are compared by their `id`
attribute.

    modelA.get('id') === modelB.get('id')

#### Using a Different Attribute

If you need to compare a different attribute, let the 
CoComp instance know during instanciation.

    cocomp = new Backbone.CoComp({comparator: "name"})

    # modelA.get("name") === modelB.get("name")

#### Comparing with Eqaulity

If you need to CoComp to compare the exact model instance, use the
`===` comparator

    cocomp = new Backbone.CoComp({comparator: "==="})

    # modelA === modelB

#### Providing a Custom Comparator

If you really need to get crazy, you can specify the comparator function
yourself. The function should receive a single argument, and return true
if the two models are equal (which would trigger a `cocomp:in` event) or
false if they are not (which would trigger a `cocomp:out` event). 

#### The Comparator Argument

The models being compared can be accessed on the comparator's argument
in two different ways depending on the symmetry of the objects being
compared.

##### Symmetrical Access

The easiest way to access each model is by the `[0]` and `[1]` indexes
of the argument. 

    comparator = function(obj) {
      obj[0].someMethod() === obj[1].someMethod()
    }

This will work when the models in each collection are symmetrical,
meaning that it doesn't matter if `obj[0]` is from the boxes collection
of the search results collection.

##### Asymmetrical Access

The models in the argument can also be accessed by the collection name
it belongs to. This is the only way to compare asymmetical models. 
In other words, you need to know which collection the model comes from.

    comparator = function(obj) {
      obj.box.get('id') === obj.search.get('product_id')
    }

This is also a good way to compare more than two collections. Using the
box and search result example above, we could compare the search results
to multiple boxes. (CoffeeScript)

    cocomp.set("box1", boxes)
    cocomp.set("box2", moreBoxes)
    cocomp.set("search", searchResults)

    comparator = (obj)->
      return unless obj.search  # won't compare box1 to box2

      boxModel = obj.box1 || obj.box2  # we'll either have a box1 or a box2, but not both
      boxModel.get('id') == obj.search.get('product_id')

## Contributing

Pull requests are welcome. Please be aware of the following:

* CoComp is written in CoffeeScript, which compiles into JavaScript. 
  Please change the *.coffee files only, and make sure that the files you
  change are compiled to JavaScript before submitting a pull request.

  I will usually run the following while working on CoComp: `coffee -wc .`
  This will compile the .coffee source into .js as you work.

* Jasmine specs are included with this project. 
  To run the test suite, open `spec/index.html` in your browser. 
  Pull requests with passing tests are preferred :)

##### License

Copyright (c) 2013 David Biehl. This software is licensed under the MIT License.    
