// Generated by CoffeeScript 1.6.3
/*! 
Backbone.CoComp v0.0.7
(c) 2013 David Biehl
Backbone.CoComp may be freely distributed under the MIT license.
For all details and documentation:
https://github.com/davidbiehl/backbone.cocomp
*/


(function() {
  var __slice = [].slice;

  Backbone.CoComp = (function() {
    _.extend(CoComp.prototype, Backbone.Events);

    function CoComp(opts) {
      var attr;
      if (opts == null) {
        opts = {};
      }
      this._collections = {};
      if (_.isFunction(opts.comparator)) {
        this.comparator = opts.comparator;
      } else {
        if (opts.comparator === "===") {
          this.comparator = function(obj) {
            return obj[0] === obj[1];
          };
        } else {
          attr = opts.comparator || "id";
          this.comparator = function(obj) {
            return obj[0].get(attr) === obj[1].get(attr);
          };
        }
      }
    }

    CoComp.prototype.set = function(name, collection, options) {
      var old;
      if (options == null) {
        options = {};
      }
      if (name === 0 || name === 1) {
        throw "" + name + " is a reserved collection name, please use a different name";
      }
      old = this.get(name);
      if (old) {
        this.stopListening(old);
      }
      this._collections[name] = collection;
      this.listenTo(collection, 'add remove', this._onChange);
      this.listenTo(collection, 'reset', function() {
        return this.compare(name);
      });
      if (!options.silent) {
        return this.compare(name);
      }
    };

    CoComp.prototype.get = function(name) {
      return this._collections[name];
    };

    CoComp.prototype.unset = function(name, options) {
      if (options == null) {
        options = {};
      }
      if (!this.get(name)) {
        return;
      }
      if (!options.silent) {
        this.compare(name, {
          reverse: true
        });
      }
      return delete this._collections[name];
    };

    CoComp.prototype.compare = function() {
      var a, aName, b, bName, comparable, compared, names, options, _i, _ref, _results;
      names = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), options = arguments[_i++];
      if (options == null) {
        options = {};
      }
      if (!_.isObject(options)) {
        names.push(options);
        options = {};
      }
      compared = [];
      comparable = function(aName, bName) {
        return aName !== bName && (names.length === 0 || _.contains(names, aName) || _.contains(names, bName)) && !(_.findWhere(compared, {
          aName: bName,
          bName: aName
        }));
      };
      _ref = this._collections;
      _results = [];
      for (aName in _ref) {
        a = _ref[aName];
        _results.push((function() {
          var _ref1, _results1;
          _ref1 = this._collections;
          _results1 = [];
          for (bName in _ref1) {
            b = _ref1[bName];
            if (comparable(aName, bName)) {
              compared.push({
                aName: aName,
                bName: bName
              });
              _results1.push(this._compareCollections(a, b, {
                aName: aName,
                bName: bName,
                reverse: options.reverse
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

    CoComp.prototype._compareCollections = function(a, b, options) {
      var aName, bName, event,
        _this = this;
      if (options == null) {
        options = {};
      }
      aName = options.aName || this._collectionName(a);
      bName = options.bName || this._collectionName(b);
      if (!_.has(options, 'invert')) {
        options.invert = true;
      }
      event = "in";
      if (options.reverse) {
        event = "out";
      }
      if (aName !== bName) {
        a.forEach(function(aModel) {
          return _this._compareModelToCollection(aModel, b, {
            modelCollectionName: aName,
            collectionName: bName,
            event: event
          });
        });
        if (options.invert) {
          return this._compareCollections(b, a, {
            aName: bName,
            bName: aName,
            invert: false
          });
        }
      }
    };

    CoComp.prototype._compareModelToCollection = function(aModel, b, options) {
      var aName, bName, event, inCollection,
        _this = this;
      if (options == null) {
        options = {};
      }
      aName = options.modelCollectionName || (function() {
        throw "modelCollectionName is required";
      })();
      bName = options.collectionName || this._collectionName(b);
      event = options.event || "in";
      if (aName !== bName) {
        inCollection = false;
        b.forEach(function(bModel) {
          var aExists, bExists;
          aExists = _this._compareOne(aModel, bModel, event, {
            aName: aName,
            bName: bName
          });
          if (options.invert) {
            bExists = _this._compareOne(bModel, aModel, event, {
              aName: bName,
              bName: aName
            });
          }
          return inCollection = inCollection || aExists || bExists;
        });
        if (!inCollection && event !== "out") {
          return this._trigger(aModel, "out", bName);
        }
      }
    };

    CoComp.prototype._trigger = function(model, event, name) {
      if (!_.contains(["in", "out"], event)) {
        throw "Invalid event: " + event;
      }
      model.trigger("cocomp:" + event + ":" + name);
      return model.trigger("cocomp:" + event);
    };

    CoComp.prototype._compareOne = function(a, b, event, options) {
      var aName, bName, obj;
      if (options == null) {
        options = {};
      }
      aName = options.aName || (function() {
        throw "aName is required";
      })();
      bName = options.bName || (function() {
        throw "bName is required";
      })();
      obj = {};
      obj[aName] = obj[0] = a;
      obj[bName] = obj[1] = b;
      if (this.comparator.call(this.comparator, obj)) {
        this._trigger(b, event, aName);
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

    CoComp.prototype._onChange = function(model, collection, e) {
      var aName, b, bName, event, _ref, _results;
      event = "in";
      if (!e.add) {
        event = "out";
      }
      aName = this._collectionName(collection);
      this._trigger(model, event, aName);
      _ref = this._collections;
      _results = [];
      for (bName in _ref) {
        b = _ref[bName];
        _results.push(this._compareModelToCollection(model, b, {
          modelCollectionName: aName,
          collectionName: bName,
          invert: true,
          event: event
        }));
      }
      return _results;
    };

    return CoComp;

  })();

}).call(this);
