// Generated by CoffeeScript 1.6.3
(function() {
  describe("Backbone.CoComp", function() {
    var box1, box2, box3, cocomp, comparator, model, model2, spy;
    comparator = function(obj) {
      return obj[1].get('id') === obj[0].get('id');
    };
    box1 = box2 = box3 = cocomp = model = model2 = spy = null;
    beforeEach(function() {
      box1 = new Backbone.Collection;
      box2 = new Backbone.Collection;
      box3 = new Backbone.Collection;
      cocomp = new Backbone.CoComp({
        comparator: comparator
      });
      model = new Backbone.Model({
        id: 1
      });
      model2 = new Backbone.Model({
        id: 2
      });
      spy = {
        callback: function() {}
      };
      return spyOn(spy, 'callback');
    });
    describe("#constructor", function() {
      return it("doesn't require a `comparator`", function() {
        var instanciate;
        instanciate = function() {
          return new Backbone.CoComp;
        };
        return expect(instanciate).not.toThrow();
      });
    });
    describe("#unset", function() {
      it("removes the collection", function() {
        cocomp.set("box1", box1);
        cocomp.unset("box1");
        return expect(cocomp.get("box1")).toBeUndefined();
      });
      return describe("the `out` event", function() {
        beforeEach(function() {
          cocomp.set("box1", box1);
          cocomp.set("box2", box2);
          box1.add(model);
          box2.add(model);
          return box2.on('cocomp:out:box1', spy.callback);
        });
        it("is triggered", function() {
          cocomp.unset("box1");
          return expect(spy.callback).toHaveBeenCalled();
        });
        return it("isn't triggered when called with `silent: true`", function() {
          cocomp.unset("box1", {
            silent: true
          });
          return expect(spy.callback).not.toHaveBeenCalled();
        });
      });
    });
    describe("#set", function() {
      it("adds the collection", function() {
        cocomp.set("box1", box1);
        return expect(cocomp.get("box1")).toBe(box1);
      });
      it("can't be named 0", function() {
        var trySet;
        trySet = function() {
          return cocomp.set(0, box1);
        };
        return expect(trySet).toThrow();
      });
      it("can't be named 1", function() {
        var trySet;
        trySet = function() {
          return cocomp.set(1, box1);
        };
        return expect(trySet).toThrow();
      });
      return describe("the event", function() {
        beforeEach(function() {
          cocomp.set("box1", box1);
          box1.add(model);
          return model.on('cocomp:out:box2', spy.callback);
        });
        it("is triggered", function() {
          cocomp.set("box2", box2);
          return expect(spy.callback).toHaveBeenCalled();
        });
        return it("isn't triggered when called with `silent: true`", function() {
          cocomp.set("box2", box2, {
            silent: true
          });
          return expect(spy.callback).not.toHaveBeenCalled();
        });
      });
    });
    describe("#compare", function() {
      beforeEach(function() {
        cocomp.set("box1", box1);
        cocomp.set("box2", box2);
        return box1.add(model);
      });
      it("triggers the events", function() {
        model.on('cocomp:out:box2', spy.callback);
        cocomp.compare();
        return expect(spy.callback).toHaveBeenCalled();
      });
      return describe("called with a box name", function() {
        beforeEach(function() {
          cocomp.set("box3", box3);
          return box3.add(model2);
        });
        it("triggers the events on the models in the named collection", function() {
          model.on('cocomp:out:box2', spy.callback);
          cocomp.compare("box1");
          return expect(spy.callback).toHaveBeenCalled();
        });
        it("doesn't trigger the event in boxes that aren't named", function() {
          model2.on('cocomp:out:box2', spy.callback);
          cocomp.compare("box1");
          return expect(spy.callback).not.toHaveBeenCalled();
        });
        return it("triggers with multiple names", function() {
          model2.on('cocomp:out:box2', spy.callback);
          cocomp.compare(["box1", "box2"]);
          return expect(spy.callback).toHaveBeenCalled();
        });
      });
    });
    describe("the `add` event", function() {
      beforeEach(function() {
        cocomp.set("box1", box1);
        return cocomp.set("box2", box2);
      });
      it("triggers an `out` event for the box the model isn't in", function() {
        model.on('cocomp:out:box2', spy.callback);
        box1.add(model);
        return expect(spy.callback.calls.length).toEqual(1);
      });
      it("triggers an `in` event for the box the model is being added to", function() {
        model.on('cocomp:in:box1', spy.callback);
        box1.add(model);
        return expect(spy.callback.calls.length).toEqual(1);
      });
      it("triggers an `in` event for the box the model is already in", function() {
        box1.add(model);
        model.on('cocomp:in:box1', spy.callback);
        box2.add(model);
        return expect(spy.callback.calls.length).toEqual(1);
      });
      return it("doesn't trigger events on other models", function() {
        box1.add(model2);
        box2.add(model2);
        model2.on('cocomp:in:box1', spy.callback);
        box1.add(model);
        return expect(spy.callback).not.toHaveBeenCalled();
      });
    });
    describe("the `remove` event", function() {
      beforeEach(function() {
        cocomp.set("box1", box1);
        return cocomp.set("box2", box2);
      });
      it("triggers an `out` event for the box the model is removed from", function() {
        box1.add(model);
        model.on('cocomp:out:box1', spy.callback);
        box1.remove(model);
        return expect(spy.callback.calls.length).toEqual(1);
      });
      it("triggers an `out` event for the other boxes the model is in", function() {
        box1.add(model);
        box2.add(model);
        model.on('cocomp:out:box1', spy.callback);
        box1.remove(model);
        return expect(spy.callback.calls.length).toEqual(2);
      });
      return it("doesn't trigger events on other models", function() {
        box1.add(model2);
        box2.add(model2);
        box1.add(model);
        model2.on('cocomp:in:box1', spy.callback);
        box1.remove(model);
        return expect(spy.callback).not.toHaveBeenCalled();
      });
    });
    describe("the event system", function() {
      beforeEach(function() {
        cocomp.set("box1", box1);
        return cocomp.set("box2", box2);
      });
      it("triggers the events when `compare()` is called", function() {
        box1.add(model);
        box2.add(model);
        model.on('cocomp:in:box1', spy.callback);
        model.on('cocomp:in:box2', spy.callback);
        cocomp.compare();
        return expect(spy.callback.calls.length).toEqual(2);
      });
      return it("triggers the events on `reset`", function() {
        box1.add(model);
        model.on('cocomp:out:box2', spy.callback);
        box2.trigger('reset');
        return expect(spy.callback).toHaveBeenCalled();
      });
    });
    return describe("default comparators", function() {
      var bert, compare, ernie;
      bert = new Backbone.Model({
        id: 1,
        name: "bert",
        type: "puppet"
      });
      ernie = new Backbone.Model({
        id: 2,
        name: "ernie",
        type: "puppet"
      });
      compare = function(a, b) {
        var obj;
        obj = {};
        obj["a"] = obj[0] = a;
        obj["b"] = obj[1] = b;
        return comparator(obj);
      };
      it("will compare by id", function() {
        cocomp = new Backbone.CoComp;
        comparator = cocomp.comparator;
        expect(compare(bert, bert)).toBe(true);
        return expect(compare(bert, ernie)).toBe(false);
      });
      describe("compare equality", function() {
        beforeEach(function() {
          cocomp = new Backbone.CoComp({
            comparator: "==="
          });
          return comparator = cocomp.comparator;
        });
        it("returns true when comparing the same object", function() {
          return expect(compare(bert, bert)).toBe(true);
        });
        return it("returns false when comparing different objects", function() {
          return expect(compare(bert, ernie)).toBe(false);
        });
      });
      return describe("compare by an attribute", function() {
        it("returns true when the attribute values are the same", function() {
          cocomp = new Backbone.CoComp({
            comparator: "type"
          });
          comparator = cocomp.comparator;
          return expect(compare(bert, ernie)).toBe(true);
        });
        return it("returns false when the attribute values are different", function() {
          cocomp = new Backbone.CoComp({
            comparator: "name"
          });
          comparator = cocomp.comparator;
          return expect(compare(bert, ernie)).toBe(false);
        });
      });
    });
  });

}).call(this);
