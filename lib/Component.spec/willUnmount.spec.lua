return function()
	local createElement = require(script.Parent.Parent.createElement)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local createSpy = require(script.Parent.Parent.createSpy)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)
	local Type = require(script.Parent.Parent.Type)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should be invoked when mounted", function()
		local MyComponent = Component:extend("MyComponent")

		local willUnmountSpy = createSpy(function(props)
			return nil
		end)

		MyComponent.willUnmount = willUnmountSpy.value

		function MyComponent:render()
			return nil
		end

		local element = createElement(MyComponent)
		local hostParent = nil
		local key = "Test"

		local node = noopReconciler.mountNode(element, hostParent, key)
		noopReconciler.unmountNode(node)

		expect(willUnmountSpy.callCount).to.equal(1)

		local values = willUnmountSpy:captureValues("self")

		expect(Type.of(values.self)).to.equal(Type.StatefulComponentInstance)
	end)
end