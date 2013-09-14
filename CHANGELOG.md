# CHANGELOG

### v0.0.7

* Compares models by `id` by default. Other comparator options are available
  as well.
* Bug fix: An `in` event wasn't being called on the model for the collection
  it was being added to. 
* No longer relies on `model.collection` to determine the collection name. If a single
  model is part of two collections, this is unreliable. An error will be thrown if
  the collection name cannot be determined internally.

### v0.0.6

* When a `reset` event is triggered on a collection, it will only compare
  that collection using the compare by name feature in v0.0.5
  
### v0.0.5

* Added `names...` parameter to `#compare` to only compare the collection(s) 
  passed to `#compare`. Refactored a lot of the guts to make this work.
* The object passed to the comparator will have '0' and '1' properties on the 
  object. Likewise, you cannot add a collection named '0' or '1'. This is
  in preparation for a default comparator.
* Added a `#get` method to get a collection by name

### v0.0.4

* Added the `unset` method to remove a collection from a CoComp instance
* Changed the `compare: false` option `#set` to
  `silent: true` which is consistent with Backbone

### v0.0.3

* This is the starting version with very basic functionality

