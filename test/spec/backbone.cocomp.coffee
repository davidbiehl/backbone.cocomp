describe "Backbone.CoComp", ->
  comparator = (obj)->
    obj.box1.get('id') == obj.box2.get('id')

  box1 = box2 = cocomp = model = spy = null

  beforeEach ->
    box1 = new Backbone.Collection
    box2 = new Backbone.Collection

    cocomp = new Backbone.CoComp
      comparator: comparator

    model = new Backbone.Model(id: 1)

    spy = {
      callback: ->
    }
    spyOn spy, 'callback'

  describe "#constructor", ->
    it "requires a `comparator`", ->
      instanciate = ->
        new Backbone.CoComp
      expect(instanciate).toThrow()

  describe "#unset", ->
    it "removes the collection", ->
      cocomp.set "box1", box1
      expect(cocomp._collections.box1).toBeDefined()
      cocomp.unset "box1"
      expect(cocomp._collections.box1).toBeUndefined()

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
  
  describe "the event system", ->
    beforeEach ->
      cocomp.set "box1", box1
      cocomp.set "box2", box2
    
    it "triggers an `out` event when the other box is empty", ->
      model.on 'cocomp:out:box2', spy.callback
      
      box1.add model
      expect(spy.callback).toHaveBeenCalled()
      
    it "triggers an `in` event when the model is in both boxes", ->
      box2.add model
      
      model.on 'cocomp:in:box2', spy.callback
      box1.add model
      expect(spy.callback).toHaveBeenCalled()
      
    it "triggers an `out` event when the model has been removed", ->
      box1.add model
      box2.add model
      
      model.on 'cocomp:out:box2', spy.callback
      box2.remove model
      
      expect(spy.callback).toHaveBeenCalled()
      
    it "triggers the events when `compare()` is called", ->
      box1.add model
      box2.add model
      
      model.on 'cocomp:in:box1', spy.callback
      model.on 'cocomp:in:box2', spy.callback
      cocomp.compare()
      
      expect(spy.callback.calls.length).toEqual(2)
      
