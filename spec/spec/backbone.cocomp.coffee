describe "Backbone.CoComp", ->
  comparator = (obj)->
    obj[1].get('id') == obj[0].get('id')

  box1 = box2 = box3 = cocomp = model = model2 = spy = null

  beforeEach ->
    box1 = new Backbone.Collection
    box2 = new Backbone.Collection
    box3 = new Backbone.Collection

    cocomp = new Backbone.CoComp
      comparator: comparator

    model = new Backbone.Model(id: 1)
    model2 = new Backbone.Model(id: 2)

    spy = {
      callback: ->
    }
    spyOn spy, 'callback'

  describe "#constructor", ->
    it "doesn't require a `comparator`", ->
      instanciate = ->
        new Backbone.CoComp
      expect(instanciate).not.toThrow()


  describe "#unset", ->
    it "removes the collection", ->
      cocomp.set "box1", box1
      cocomp.unset "box1"
      expect(cocomp.get("box1")).toBeUndefined()

    describe "the `out` event", ->
      beforeEach ->
        cocomp.set "box1", box1
        cocomp.set "box2", box2

        box1.add model
        box2.add model

        box2.on 'cocomp:out:box1', spy.callback

      it "is triggered", ->
        cocomp.unset "box1"
        expect(spy.callback).toHaveBeenCalled()

      it "isn't triggered when called with `silent: true`", ->
        cocomp.unset "box1", silent: true
        expect(spy.callback).not.toHaveBeenCalled()
  

  describe "#set", ->
    it "adds the collection", ->
      cocomp.set "box1", box1
      expect(cocomp.get("box1")).toBe(box1)

    it "can't be named 0", ->
      trySet = ->
        cocomp.set(0, box1)

      expect(trySet).toThrow()
      
    it "can't be named 1", ->
      trySet = ->
        cocomp.set(1, box1)

      expect(trySet).toThrow()


    describe "the event", ->
      beforeEach ->
        cocomp.set "box1", box1
        box1.add model
        model.on 'cocomp:out:box2', spy.callback

      it "is triggered", ->
        cocomp.set "box2", box2
        expect(spy.callback).toHaveBeenCalled()

      it "isn't triggered when called with `silent: true`", ->
        cocomp.set "box2", box2, silent: true
        expect(spy.callback).not.toHaveBeenCalled()

  describe "#compare", ->
    beforeEach ->
      cocomp.set "box1", box1
      cocomp.set "box2", box2

      box1.add model

    it "triggers the events", ->
      model.on 'cocomp:out:box2', spy.callback
      cocomp.compare()
      expect(spy.callback).toHaveBeenCalled()

    describe "called with a box name", ->
      beforeEach ->
        cocomp.set "box3", box3
        box3.add model2

      it "triggers the events on the models in the named collection", ->
        model.on 'cocomp:out:box2', spy.callback
        cocomp.compare("box1")
        expect(spy.callback).toHaveBeenCalled()

      it "doesn't trigger the event in boxes that aren't named", ->
        model2.on 'cocomp:out:box2', spy.callback
        cocomp.compare("box1")
        expect(spy.callback).not.toHaveBeenCalled()

      it "triggers with multiple names", ->
        model2.on 'cocomp:out:box2', spy.callback
        cocomp.compare(["box1", "box2"])
        expect(spy.callback).toHaveBeenCalled()

  describe "the `add` event", ->
    beforeEach ->
      cocomp.set "box1", box1
      cocomp.set "box2", box2

    it "triggers an `out` event for the box the model isn't in", ->
      model.on 'cocomp:out:box2', spy.callback
      
      box1.add model
      expect(spy.callback.calls.length).toEqual(1)

    it "triggers an `in` event for the box the model is being added to", ->
      model.on 'cocomp:in:box1', spy.callback

      box1.add model
      expect(spy.callback.calls.length).toEqual(1)

    it "triggers an `in` event for the box the model is already in", ->
      box1.add model
      model.on 'cocomp:in:box1', spy.callback

      box2.add model
      expect(spy.callback.calls.length).toEqual(1)

    it "doesn't trigger events on other models", ->
      box1.add model2
      box2.add model2

      model2.on 'cocomp:in:box1', spy.callback
      box1.add model
      expect(spy.callback).not.toHaveBeenCalled()

  describe "the `remove` event", ->
    beforeEach ->
      cocomp.set "box1", box1
      cocomp.set "box2", box2

    it "triggers an `out` event for the box the model is removed from", ->
      box1.add model
      model.on 'cocomp:out:box1', spy.callback

      box1.remove model
      expect(spy.callback.calls.length).toEqual(1)

    it "triggers an `out` event for the other boxes the model is in", ->
      box1.add model
      box2.add model
      model.on 'cocomp:out:box1', spy.callback

      box1.remove model
      expect(spy.callback.calls.length).toEqual(2)

    it "doesn't trigger events on other models", ->
      box1.add model2
      box2.add model2
      box1.add model

      model2.on 'cocomp:in:box1', spy.callback
      box1.remove model
      expect(spy.callback).not.toHaveBeenCalled()

  describe "the event system", ->
    beforeEach ->
      cocomp.set "box1", box1
      cocomp.set "box2", box2
      
    it "triggers the events when `compare()` is called", ->
      box1.add model
      box2.add model
      
      model.on 'cocomp:in:box1', spy.callback
      model.on 'cocomp:in:box2', spy.callback
      cocomp.compare()
      
      expect(spy.callback.calls.length).toEqual(2)

    it "triggers the events on `reset`", ->
      box1.add model
      model.on 'cocomp:out:box2', spy.callback
      box2.trigger 'reset'
      expect(spy.callback).toHaveBeenCalled()

  describe "default comparators", ->
    bert = new Backbone.Model({id: 1, name: "bert", type: "puppet"})
    ernie = new Backbone.Model({id: 2, name: "ernie", type: "puppet"})

    compare = (a, b)->
      obj = {}
      obj["a"] = obj[0] = a
      obj["b"] = obj[1] = b

      comparator(obj)

    it "will compare by id", ->
      cocomp = new Backbone.CoComp
      comparator = cocomp.comparator

      expect(compare(bert, bert)).toBe(true)
      expect(compare(bert, ernie)).toBe(false)
      
    describe "compare equality", ->
      beforeEach ->
        cocomp = new Backbone.CoComp comparator: "==="
        comparator = cocomp.comparator

      it "returns true when comparing the same object", ->
        expect(compare(bert, bert)).toBe(true)

      it "returns false when comparing different objects", ->
        expect(compare(bert, ernie)).toBe(false)

    describe "compare by an attribute", ->
      it "returns true when the attribute values are the same", ->
        cocomp = new Backbone.CoComp comparator: "type"
        comparator = cocomp.comparator

        expect(compare(bert, ernie)).toBe(true)

      it "returns false when the attribute values are different", ->
        cocomp = new Backbone.CoComp comparator: "name"
        comparator = cocomp.comparator

        expect(compare(bert, ernie)).toBe(false)




