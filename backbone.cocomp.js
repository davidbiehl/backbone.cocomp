// Generated by CoffeeScript 1.6.3
/*! Backbone.CoComp 
(c) 2013 David Biehl
Backbone.CoComp may be freely distributed under the MIT license.
For all details and documentation:
https://github.com/davidbiehl/backbone.cocomp
*/


(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Backbone.CoComp = (function() {
    _.extend(CoComp.prototype, Backbone.Events);

    function CoComp(opts) {
      if (opts == null) {
        opts = {};
      }
      this._compareOne = __bind(this._compareOne, this);
      this._collections = {};
      this.comparator = opts.comparator || (function() {
        throw "The CoComp requires a comparator";
      })();
    }

    CoComp.prototype.set = function(name, collection, options) {
      if (options == null) {
        options = {};
      }
      if (!_.has(options, "compare")) {
        options.compare = true;
      }
      if (this._collections[name]) {
        this.stopListening(this._collections[name]);
      }
      this._collections[name] = collection;
      this.listenTo(this._collections[name], 'reset', this.compare);
      this.listenTo(this._collections[name], 'add', this._onAdd);
      this.listenTo(this._collections[name], 'remove', this._onRemove);
      if (options.compare) {
        return this.compare();
      }
    };

    CoComp.prototype.compare = function() {
      var a, aName, b, bName, _ref, _results;
      _ref = this._collections;
      _results = [];
      for (aName in _ref) {
        a = _ref[aName];
        _results.push((function() {
          var _ref1, _results1,
            _this = this;
          _ref1 = this._collections;
          _results1 = [];
          for (bName in _ref1) {
            b = _ref1[bName];
            if (aName !== bName) {
              _results1.push(a.forEach(function(aModel) {
                return _this._compareToCollection(aModel, b, {
                  modelCollectionName: aName,
                  collectionName: bName
                });
              }));
            } else {
              _results1.push(void 0);
            }
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    CoComp.prototype._compareToCollection = function(aModel, b, options) {
      var aName, bName, inCollection, inEvent,
        _this = this;
      if (options == null) {
        options = {};
      }
      aName = options.modelCollectionName || this._collectionName(aModel.collection);
      bName = options.collectionName || this._collectionName(b);
      if (aName !== bName) {
        if (options.reverse) {
          inEvent = "cocomp:out";
        } else {
          inEvent = "cocomp:in";
        }
        inCollection = false;
        b.forEach(function(bModel) {
          var exists;
          exists = _this._compareOne(aModel, bModel, inEvent, {
            aName: aName,
            bName: bName
          });
          return inCollection = inCollection || exists;
        });
        if (!inCollection) {
          aModel.trigger("cocomp:out:" + bName);
          return aModel.trigger("cocomp:out");
        }
      }
    };

    CoComp.prototype._compareOne = function(a, b, event, options) {
      var aName, bName, obj;
      if (options == null) {
        options = {};
      }
      aName = options.aName || this._collectionName(a.collection);
      bName = options.bName || this._collectionName(b.collection);
      obj = {};
      obj[aName] = a;
      obj[bName] = b;
      if (this.comparator.call(this.comparator, obj)) {
        b.trigger("" + event + ":" + aName, a);
        b.trigger("" + event, a);
        return true;
      } else {
        return false;
      }
    };

    CoComp.prototype._collectionName = function(collection) {
      var c, cName, _ref;
      _ref = this._collections;
      for (cName in _ref) {
        c = _ref[cName];
        if (c === collection) {
          return cName;
        }
      }
    };

    CoComp.prototype._onAdd = function(aModel) {
      var b, bName, _ref, _results;
      _ref = this._collections;
      _results = [];
      for (bName in _ref) {
        b = _ref[bName];
        _results.push(this._compareToCollection(aModel, b, {
          collectionName: bName
        }));
      }
      return _results;
    };

    CoComp.prototype._onRemove = function(aModel) {
      var b, bName, _ref, _results;
      _ref = this._collections;
      _results = [];
      for (bName in _ref) {
        b = _ref[bName];
        _results.push(this._compareToCollection(aModel, b, {
          collectionName: bName,
          reverse: true
        }));
      }
      return _results;
    };

    return CoComp;

  })();

}).call(this);
