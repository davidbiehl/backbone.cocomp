describe "Backbone.CoComp", ->
  it "needs a comparator", ->
    instanciate = ->
      new Backbone.CoComp
     expect(instanciate).toThrow()
  
  describe "the event system", ->
    cocomp = box1 = box2 = foo = null
    
    beforeEach ->
      foo = {
        callback: ->
      }
      spyOn foo, 'callback'
      cocomp = new Backbone.CoComp
        comparator: (obj)->
          obj.box1.get('id') == obj.box2.get('id')
    
      box1 = new Backbone.Collection
      box2 = new Backbone.Collection
    
      cocomp.set "box1", box1
      cocomp.set "box2", box2
    
    it "fires an out event when the other box is empty", ->
      model = new Backbone.Model(id: 3)
      model.on 'cocomp:out:box2', foo.callback
      
      box1.add model
      expect(foo.callback).toHaveBeenCalled()
      
    it "fires an in event when the model is in both boxes", ->
      model = new Backbone.Model(id: 3)
      box2.add model
      
      model.on 'cocomp:in:box2', foo.callback
      box1.add model
      expect(foo.callback).toHaveBeenCalled()
      
    it "fires an out event when the model has been removed", ->
      model = new Backbone.Model(id: 9)
      box1.add model
      box2.add model
      
      model.on 'cocomp:out:box2', foo.callback
      box2.remove model
      
      expect(foo.callback).toHaveBeenCalled()
      
    it "fires the events when compare() is called", ->
      model = new Backbone.Model(id: 1)
      box1.add model
      box2.add model
      
      model.on 'cocomp:in:box1', foo.callback
      model.on 'cocomp:in:box2', foo.callback
      cocomp.compare()
      
      expect(foo.callback.calls.length).toEqual(2)
      