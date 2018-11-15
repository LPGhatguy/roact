return function()
	local createSpy = require(script.Parent.createSpy)
	local assertDeepEqual = require(script.Parent.assertDeepEqual)

	local SingleEventManager = require(script.Parent.SingleEventManager)

	describe("new", function()
		it("should create a SingleEventManager", function()
			local manager = SingleEventManager.new()

			expect(manager).to.be.ok()
		end)
	end)

	describe("connectEvent", function()
		it("should connect to events", function()
			local instance = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(instance)
			local eventSpy = createSpy()

			manager:connectEvent("Event", eventSpy.value)
			manager:resume()

			instance:Fire("foo")
			expect(eventSpy.callCount).to.equal(1)
			eventSpy:assertCalledWith(instance, "foo")

			instance:Fire("bar")
			expect(eventSpy.callCount).to.equal(2)
			eventSpy:assertCalledWith(instance, "bar")

			manager:connectEvent("Event", nil)

			instance:Fire("baz")
			expect(eventSpy.callCount).to.equal(2)
		end)

		it("should drop events until resumed initially", function()
			local target = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(target)
			local eventSpy = createSpy()

			manager:connectEvent("Event", eventSpy.value)

			target:Fire("foo")
			expect(eventSpy.callCount).to.equal(0)

			manager:resume()

			target:Fire("bar")
			expect(eventSpy.callCount).to.equal(1)
			eventSpy:assertCalledWith(target, "bar")
		end)

		it("should invoke suspended events when resumed", function()
			local target = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(target)
			local eventSpy = createSpy()

			manager:connectEvent("Event", eventSpy.value)

			manager:resume()

			target:Fire("foo")
			expect(eventSpy.callCount).to.equal(1)
			eventSpy:assertCalledWith(target, "foo")

			manager:suspend()

			target:Fire("bar")
			expect(eventSpy.callCount).to.equal(1)

			manager:resume()
			expect(eventSpy.callCount).to.equal(2)
			eventSpy:assertCalledWith(target, "bar")
		end)

		it("should invoke events triggered during resumption in the correct order", function()
			local instance = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(instance)

			local recordedValues = {}
			local eventSpy = createSpy(function(_, value)
				table.insert(recordedValues, value)

				if value == 2 then
					instance:Fire(3)
				elseif value == 3 then
					instance:Fire(4)
				end
			end)

			manager:connectEvent("Event", eventSpy.value)
			manager:suspend()

			instance:Fire(1)
			instance:Fire(2)

			manager:resume()
			expect(eventSpy.callCount).to.equal(4)
			assertDeepEqual(recordedValues, {1, 2, 3, 4})
		end)

		-- TODO: Test that events fired during suspension and disconnected
		-- before resume aren't fired
		-- TODO: Test that events that yield don't yield through the manager
		-- TODO: Test that events that throw don't throw through the manager
		-- TODO: Test that manager:resume() fired from a suspended event
		-- listener won't double-fire events.
	end)

	describe("connectPropertyChange", function()
		it("should connect to property changes", function()
			local instance = Instance.new("Folder")
			local manager = SingleEventManager.new(instance)
			local eventSpy = createSpy()

			manager:connectPropertyChange("Name", eventSpy.value)
			manager:resume()

			instance.Name = "foo"
			expect(eventSpy.callCount).to.equal(1)
			eventSpy:assertCalledWith(instance)

			instance.Name = "bar"
			expect(eventSpy.callCount).to.equal(2)
			eventSpy:assertCalledWith(instance)

			manager:connectPropertyChange("Name")

			instance.Name = "baz"
			expect(eventSpy.callCount).to.equal(2)
		end)
	end)
end